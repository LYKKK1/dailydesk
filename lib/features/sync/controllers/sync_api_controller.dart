import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/features/sync/services/diff_packager.dart';
import 'package:dailydesk/features/sync/services/merge_engine.dart';
import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

class SyncAuth {
  /// The raw pairing key is returned once by the pairing endpoint.
  /// Only its hash is persisted and used as HMAC key material afterwards.
  static String hashPairingKey(String pairingKey) =>
      sha256.convert(utf8.encode(pairingKey)).toString();

  static String generatePairingKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// X-Sync-Token: HMAC-SHA256(deviceId, pairingKeyHash).
  static String tokenForPairingKeyHash(
    String deviceId,
    String pairingKeyHash,
  ) {
    final hmac = Hmac(sha256, utf8.encode(pairingKeyHash));
    return hmac.convert(utf8.encode(deviceId)).toString();
  }

  static bool verifyTokenAgainstPairingKeyHash(
    String deviceId,
    String pairingKeyHash,
    String token,
  ) {
    final expected = tokenForPairingKeyHash(deviceId, pairingKeyHash);
    if (expected.length != token.length) {
      return false;
    }

    var difference = 0;
    for (var index = 0; index < expected.length; index++) {
      difference |= expected.codeUnitAt(index) ^ token.codeUnitAt(index);
    }
    return difference == 0;
  }

  static String generatePin() {
    final random = Random.secure();
    return (random.nextInt(9000) + 1000).toString();
  }

  static String hashPin(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();

  static bool verifyPin(String pin, String pinHash) {
    final expected = hashPin(pin);
    if (expected.length != pinHash.length) {
      return false;
    }

    var difference = 0;
    for (var index = 0; index < expected.length; index++) {
      difference |= expected.codeUnitAt(index) ^ pinHash.codeUnitAt(index);
    }
    return difference == 0;
  }
}

class SyncApiController {
  static const _maxFutureCheckpointSkewMs = 5 * 60 * 1000;
  static const defaultPinTtl = Duration(minutes: 5);
  static const defaultMaxPinAttempts = 5;

  SyncApiController({
    required this.db,
    required this.localDeviceId,
    required this.localDeviceName,
    required this.localPlatform,
    required this.localIp,
    this.localPort = 53317,
    String? pin,
    Duration pinTtl = defaultPinTtl,
    int maxPinAttempts = defaultMaxPinAttempts,
    int Function()? clock,
  })  : _pin = pin ?? SyncAuth.generatePin(),
        _pinTtl = pinTtl,
        _maxPinAttempts = maxPinAttempts,
        _clock = clock ?? nowMs {
    if (pinTtl <= Duration.zero) {
      throw ArgumentError.value(pinTtl, 'pinTtl', 'must be positive');
    }
    if (maxPinAttempts < 1) {
      throw ArgumentError.value(
        maxPinAttempts,
        'maxPinAttempts',
        'must be at least 1',
      );
    }
    _pinHash = SyncAuth.hashPin(_pin);
    _pinIssuedAtMs = _clock();
    router = Router()
      ..post('/api/v1/pair', _pair)
      ..post('/api/v1/sync/diff-request', _diff);
  }

  final AppDatabase db;
  final String localDeviceId;
  final String localDeviceName;
  final String localPlatform;
  final String localIp;
  final int localPort;

  late final Router router;
  String _pin;
  final Duration _pinTtl;
  final int _maxPinAttempts;
  final int Function() _clock;
  late String _pinHash;
  late int _pinIssuedAtMs;
  int _failedPinAttempts = 0;

  String get pin => _pin;
  int get pinExpiresAtMs => _pinIssuedAtMs + _pinTtl.inMilliseconds;
  int get pinAttemptsRemaining =>
      (_maxPinAttempts - _failedPinAttempts).clamp(0, _maxPinAttempts);

  Handler get handler =>
      const Pipeline().addMiddleware(_authMiddleware).addHandler(router.call);

  void refreshPin([String? pin]) {
    _pin = pin ?? SyncAuth.generatePin();
    _pinHash = SyncAuth.hashPin(_pin);
    _pinIssuedAtMs = _clock();
    _failedPinAttempts = 0;
  }

  Future<void> storePairing({
    required String deviceId,
    required String deviceName,
    required String platform,
    required String ip,
    required int port,
    required String pairingKey,
  }) async {
    final pairingKeyHash = SyncAuth.hashPairingKey(pairingKey);
    await db.into(db.syncDevices).insert(
          SyncDevicesCompanion.insert(
            deviceId: deviceId,
            deviceName: deviceName,
            platform: platform,
            ipAddress: ip,
            port: Value(port),
            pairingKeyHash: pairingKeyHash,
            isTrusted: const Value(true),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<Response> _pair(Request request) async {
    try {
      final body = await _jsonBody(request);
      final pin = body['pin'];
      final deviceId = body['deviceId'];
      final deviceName = body['deviceName'];
      final platform = body['platform'];
      final ip = body['ip'];
      final portValue = body['port'];
      if (pin is! String ||
          deviceId is! String ||
          deviceName is! String ||
          platform is! String ||
          ip is! String ||
          portValue is! num) {
        return _jsonResponse(
          HttpStatus.badRequest,
          {'error': 'invalid_pairing_request'},
        );
      }

      final pinStatus = _pinStatusResponse();
      if (pinStatus != null) {
        return pinStatus;
      }

      if (!SyncAuth.verifyPin(pin, _pinHash)) {
        _failedPinAttempts++;
        final locked = _failedPinAttempts >= _maxPinAttempts;
        return _jsonResponse(
          locked ? HttpStatus.tooManyRequests : HttpStatus.forbidden,
          {
            'error': locked ? 'pin_locked' : 'invalid_pin',
            'attempts_remaining': pinAttemptsRemaining,
            'pin_expires_at': pinExpiresAtMs,
          },
        );
      }
      _failedPinAttempts = 0;

      final pairingKey = SyncAuth.generatePairingKey();
      await storePairing(
        deviceId: deviceId,
        deviceName: deviceName,
        platform: platform,
        ip: ip,
        port: portValue.toInt(),
        pairingKey: pairingKey,
      );

      return _jsonResponse(
        HttpStatus.ok,
        {
          'pairing_key': pairingKey,
          'pairingKey': pairingKey,
          'device_id': localDeviceId,
          'deviceId': localDeviceId,
          'device_name': localDeviceName,
          'deviceName': localDeviceName,
          'platform': localPlatform,
          'ip': localIp,
          'port': localPort,
        },
      );
    } catch (error) {
      return _jsonResponse(
        HttpStatus.internalServerError,
        {'error': 'pairing_failed', 'detail': error.toString()},
      );
    }
  }

  Future<Response> _diff(Request request) async {
    try {
      final deviceId = request.context['syncDeviceId'] as String;
      final body = await _jsonBody(request);
      final lastSyncedAt = _readInt(
        body,
        snakeKey: 'last_synced_at',
        camelKey: 'lastSyncedAt',
      );
      final syncedAt = _readNullableInt(
        body,
        snakeKey: 'synced_at',
        camelKey: 'syncedAt',
      );
      final checkpointError = await _validateCheckpoints(
        deviceId,
        lastSyncedAt: lastSyncedAt,
        syncedAt: syncedAt,
      );
      if (checkpointError != null) {
        return checkpointError;
      }

      MergeResult? mergeResult;
      final pushedDiff = body['diff'];
      if (pushedDiff is Map) {
        mergeResult = await applyDiff(
          db,
          Map<String, dynamic>.from(pushedDiff),
        );
      } else if (body['tables'] is Map) {
        mergeResult = await applyDiff(db, body);
      }

      final diff = await buildDiff(db, lastSyncedAt);
      if (syncedAt != null) {
        await _updateLastSyncedAt(deviceId, syncedAt);
      }

      return _jsonResponse(
        HttpStatus.ok,
        {
          ...diff,
          if (mergeResult != null)
            'merge': {
              'applied': mergeResult.applied,
              'conflicts_copied': mergeResult.conflictsCopied,
            },
          if (syncedAt != null) 'synced_at': syncedAt,
        },
      );
    } catch (error) {
      return _jsonResponse(
        HttpStatus.internalServerError,
        {'error': 'sync_failed', 'detail': error.toString()},
      );
    }
  }

  Middleware get _authMiddleware => (innerHandler) {
        return (request) async {
          if (request.url.path != 'api/v1/sync/diff-request') {
            return innerHandler(request);
          }

          final deviceId = request.headers['x-device-id'];
          final token = request.headers['x-sync-token'];
          if (deviceId == null || token == null) {
            return _jsonResponse(
              HttpStatus.unauthorized,
              {'error': 'unpaired'},
            );
          }

          final device = await (db.select(db.syncDevices)
                ..where(
                  (row) =>
                      row.deviceId.equals(deviceId) &
                      row.isTrusted.equals(true),
                ))
              .getSingleOrNull();
          if (device == null) {
            return _jsonResponse(
              HttpStatus.unauthorized,
              {'error': 'unpaired'},
            );
          }

          final validStoredSecret = SyncAuth.verifyTokenAgainstPairingKeyHash(
            deviceId,
            device.pairingKeyHash,
            token,
          );
          if (!validStoredSecret) {
            return _jsonResponse(
              HttpStatus.unauthorized,
              {'error': 'unpaired'},
            );
          }

          return innerHandler(
            request.change(
              context: {...request.context, 'syncDeviceId': deviceId},
            ),
          );
        };
      };

  Future<void> _updateLastSyncedAt(String deviceId, int value) async {
    await (db.update(db.syncDevices)
          ..where(
            (row) =>
                row.deviceId.equals(deviceId) &
                row.lastSyncedAt.isSmallerThanValue(value),
          ))
        .write(SyncDevicesCompanion(lastSyncedAt: Value(value)));
  }

  Future<Response?> _validateCheckpoints(
    String deviceId, {
    required int lastSyncedAt,
    required int? syncedAt,
  }) async {
    final now = nowMs();
    if (lastSyncedAt < 0 || lastSyncedAt > now + _maxFutureCheckpointSkewMs) {
      return _jsonResponse(
        HttpStatus.badRequest,
        {'error': 'invalid_last_synced_at'},
      );
    }
    if (syncedAt == null) {
      return null;
    }
    if (syncedAt < lastSyncedAt ||
        syncedAt < 0 ||
        syncedAt > now + _maxFutureCheckpointSkewMs) {
      return _jsonResponse(
        HttpStatus.badRequest,
        {'error': 'invalid_synced_at'},
      );
    }

    final device = await (db.select(db.syncDevices)
          ..where((row) => row.deviceId.equals(deviceId)))
        .getSingleOrNull();
    if (device == null) {
      return _jsonResponse(
        HttpStatus.unauthorized,
        {'error': 'unpaired'},
      );
    }
    return null;
  }

  Future<Map<String, dynamic>> _jsonBody(Request request) async {
    final raw = await request.readAsString();
    if (raw.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('request body must be an object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  int _readInt(
    Map<String, dynamic> body, {
    required String snakeKey,
    required String camelKey,
  }) {
    final value = body[snakeKey] ?? body[camelKey] ?? 0;
    if (value is! num) {
      throw FormatException('$snakeKey must be a number');
    }
    return value.toInt();
  }

  int? _readNullableInt(
    Map<String, dynamic> body, {
    required String snakeKey,
    required String camelKey,
  }) {
    final value = body[snakeKey] ?? body[camelKey];
    if (value == null) {
      return null;
    }
    if (value is! num) {
      throw FormatException('$snakeKey must be a number');
    }
    return value.toInt();
  }

  Response? _pinStatusResponse() {
    if (_clock() >= pinExpiresAtMs) {
      return _jsonResponse(
        HttpStatus.gone,
        {
          'error': 'pin_expired',
          'pin_expires_at': pinExpiresAtMs,
        },
      );
    }
    if (_failedPinAttempts >= _maxPinAttempts) {
      return _jsonResponse(
        HttpStatus.tooManyRequests,
        {
          'error': 'pin_locked',
          'attempts_remaining': 0,
          'pin_expires_at': pinExpiresAtMs,
        },
      );
    }
    return null;
  }

  Response _jsonResponse(int statusCode, Map<String, dynamic> body) => Response(
        statusCode,
        body: jsonEncode(body),
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
}

class LocalHttpServer {
  LocalHttpServer(
    this.controller, {
    this.defaultPort = 53317,
  });

  final SyncApiController controller;
  final int defaultPort;

  HttpServer? _server;

  bool get isRunning => _server != null;
  int? get port => _server?.port;

  Future<HttpServer> start({int? port}) async {
    final existing = _server;
    if (existing != null) {
      return existing;
    }

    final server = await shelf_io.serve(
      controller.handler,
      InternetAddress.anyIPv4,
      port ?? defaultPort,
    );
    server.autoCompress = true;
    _server = server;
    return server;
  }

  Future<void> stop({bool force = true}) async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: force);
    }
  }
}
