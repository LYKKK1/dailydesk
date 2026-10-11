import 'dart:convert';
import 'dart:io';

import 'package:dailydesk/features/sync/controllers/sync_api_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../test_database.dart';

void main() {
  test('配对只持久化 pairing_key_hash，认证只接受 hash 派生 token', () async {
    final database = createTestDatabase();
    final controller = SyncApiController(
      db: database,
      localDeviceId: 'server-device',
      localDeviceName: 'Server',
      localPlatform: 'windows',
      localIp: '127.0.0.1',
    );
    final server = LocalHttpServer(controller);
    await server.start(port: 0);

    addTearDown(() async {
      await server.stop();
      await database.close();
    });

    final pairResponse = await http.post(
      Uri.parse('http://127.0.0.1:${server.port}/api/v1/pair'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'pin': controller.pin,
        'deviceId': 'client-device',
        'deviceName': 'Client',
        'platform': 'android',
        'ip': '127.0.0.1',
        'port': 53317,
      }),
    );

    expect(pairResponse.statusCode, 200);
    final pairBody = jsonDecode(pairResponse.body) as Map<String, dynamic>;
    final pairingKey = pairBody['pairing_key'] as String;
    final stored = await (database.select(database.syncDevices)
          ..where((row) => row.deviceId.equals('client-device')))
        .getSingle();

    expect(stored.pairingKeyHash, SyncAuth.hashPairingKey(pairingKey));
    expect(stored.pairingKeyHash, isNot(pairingKey));

    final validToken = SyncAuth.tokenForPairingKeyHash(
      'client-device',
      stored.pairingKeyHash,
    );
    final validResponse = await http.post(
      Uri.parse(
        'http://127.0.0.1:${server.port}/api/v1/sync/diff-request',
      ),
      headers: {
        'content-type': 'application/json',
        'x-device-id': 'client-device',
        'x-sync-token': validToken,
      },
      body: jsonEncode({'last_synced_at': 0, 'synced_at': 100}),
    );
    expect(validResponse.statusCode, 200);

    final rawKeyToken = SyncAuth.tokenForPairingKeyHash(
      'client-device',
      pairingKey,
    );
    final invalidResponse = await http.post(
      Uri.parse(
        'http://127.0.0.1:${server.port}/api/v1/sync/diff-request',
      ),
      headers: {
        'content-type': 'application/json',
        'x-device-id': 'client-device',
        'x-sync-token': rawKeyToken,
      },
      body: jsonEncode({'last_synced_at': 0}),
    );
    expect(invalidResponse.statusCode, 401);
  });

  test('服务端 synced_at 单调更新，不接受陈旧时间戳', () async {
    final database = createTestDatabase();
    final controller = SyncApiController(
      db: database,
      localDeviceId: 'server-device',
      localDeviceName: 'Server',
      localPlatform: 'windows',
      localIp: '127.0.0.1',
    );
    const pairingKey = 'pairing-key-for-test';
    await controller.storePairing(
      deviceId: 'client-device',
      deviceName: 'Client',
      platform: 'android',
      ip: '127.0.0.1',
      port: 53317,
      pairingKey: pairingKey,
    );
    final server = LocalHttpServer(controller);
    await server.start(port: 0);

    addTearDown(() async {
      await server.stop();
      await database.close();
    });

    final uri = Uri.parse(
      'http://127.0.0.1:${server.port}/api/v1/sync/diff-request',
    );
    final headers = {
      'content-type': 'application/json',
      'x-device-id': 'client-device',
      'x-sync-token': SyncAuth.tokenForPairingKeyHash(
        'client-device',
        SyncAuth.hashPairingKey(pairingKey),
      ),
    };

    Future<http.Response> send(int syncedAt) => http.post(
          uri,
          headers: headers,
          body: jsonEncode({
            'last_synced_at': 0,
            'synced_at': syncedAt,
          }),
        );

    expect((await send(5000)).statusCode, 200);
    expect((await send(1000)).statusCode, 200);

    final stored = await (database.select(database.syncDevices)
          ..where((row) => row.deviceId.equals('client-device')))
        .getSingle();
    expect(stored.lastSyncedAt, 5000);
  });

  test('服务端拒绝明显超前的客户端 checkpoint', () async {
    final database = createTestDatabase();
    final controller = SyncApiController(
      db: database,
      localDeviceId: 'server-device',
      localDeviceName: 'Server',
      localPlatform: 'windows',
      localIp: '127.0.0.1',
    );
    const pairingKey = 'pairing-key-for-future-checkpoint';
    await controller.storePairing(
      deviceId: 'client-device',
      deviceName: 'Client',
      platform: 'android',
      ip: '127.0.0.1',
      port: 53317,
      pairingKey: pairingKey,
    );
    final server = LocalHttpServer(controller);
    await server.start(port: 0);

    addTearDown(() async {
      await server.stop();
      await database.close();
    });

    final response = await http.post(
      Uri.parse(
        'http://127.0.0.1:${server.port}/api/v1/sync/diff-request',
      ),
      headers: {
        'content-type': 'application/json',
        'x-device-id': 'client-device',
        'x-sync-token': SyncAuth.tokenForPairingKeyHash(
          'client-device',
          SyncAuth.hashPairingKey(pairingKey),
        ),
      },
      body: jsonEncode({
        'last_synced_at': 0,
        'synced_at': DateTime.now().millisecondsSinceEpoch + 60 * 60 * 1000,
      }),
    );

    expect(response.statusCode, 400);
    expect(jsonDecode(response.body)['error'], 'invalid_synced_at');
  });

  test('PIN 失败次数达到上限后锁定，过期或刷新后才可继续配对', () async {
    final database = createTestDatabase();
    var now = 1000000;
    final controller = SyncApiController(
      db: database,
      localDeviceId: 'server-device',
      localDeviceName: 'Server',
      localPlatform: 'windows',
      localIp: '127.0.0.1',
      pin: '1234',
      pinTtl: const Duration(seconds: 1),
      maxPinAttempts: 2,
      clock: () => now,
    );
    final server = LocalHttpServer(controller);
    await server.start(port: 0);

    addTearDown(() async {
      await server.stop();
      await database.close();
    });

    Future<http.Response> pair(String pin) => http.post(
          Uri.parse('http://127.0.0.1:${server.port}/api/v1/pair'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'pin': pin,
            'deviceId': 'client-device',
            'deviceName': 'Client',
            'platform': 'android',
            'ip': '127.0.0.1',
            'port': 53317,
          }),
        );

    final firstWrong = await pair('0000');
    expect(firstWrong.statusCode, HttpStatus.forbidden);
    expect(jsonDecode(firstWrong.body)['attempts_remaining'], 1);

    final secondWrong = await pair('0000');
    expect(secondWrong.statusCode, HttpStatus.tooManyRequests);
    expect(jsonDecode(secondWrong.body)['error'], 'pin_locked');

    final lockedCorrect = await pair('1234');
    expect(lockedCorrect.statusCode, HttpStatus.tooManyRequests);

    now += 1001;
    final expiredCorrect = await pair('1234');
    expect(expiredCorrect.statusCode, HttpStatus.gone);
    expect(jsonDecode(expiredCorrect.body)['error'], 'pin_expired');

    controller.refreshPin('1234');
    final refreshed = await pair('1234');
    expect(refreshed.statusCode, HttpStatus.ok);
  });
}
