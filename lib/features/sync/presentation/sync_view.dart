import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/sync/controllers/sync_api_controller.dart';
import 'package:dailydesk/features/sync/presentation/widgets/pairing_dialog.dart';
import 'package:dailydesk/features/sync/services/discovery_service.dart';
import 'package:dailydesk/features/sync/services/sync_orchestrator.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pretty_qr_code/pretty_qr_code.dart';

class SyncView extends StatefulWidget {
  const SyncView({
    super.key,
    this.database,
    this.deviceName = 'DailyDesk',
    this.port = DiscoveryService.multicastPort,
    this.embedded = false,
  });

  final AppDatabase? database;
  final String deviceName;
  final int port;
  final bool embedded;

  @override
  State<SyncView> createState() => _SyncViewState();
}

Future<Beacon?> findTrustedPeerByAddress(
  AppDatabase database, {
  required String ip,
  required int port,
}) async {
  final devices = await (database.select(database.syncDevices)
        ..where(
          (row) =>
              row.ipAddress.equals(ip) &
              row.port.equals(port) &
              row.isTrusted.equals(true),
        ))
      .get();
  if (devices.isEmpty) {
    return null;
  }

  final device = devices.first;
  return Beacon(
    deviceId: device.deviceId,
    deviceName: device.deviceName,
    platform: device.platform,
    ip: device.ipAddress,
    port: device.port,
  );
}

Future<void> showSyncView(
  BuildContext context, {
  AppDatabase? database,
  String deviceName = 'DailyDesk',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 760),
        child: SyncView(
          database: database,
          deviceName: deviceName,
          embedded: true,
        ),
      ),
    ),
  );
}

class _SyncViewState extends State<SyncView> {
  final DiscoveryService _discovery = DiscoveryService();
  final TextEditingController _manualAddressController =
      TextEditingController();
  final Map<String, int> _latencyMs = {};
  final Set<String> _latencyProbes = {};

  StreamSubscription<List<Beacon>>? _peerSubscription;
  SyncApiController? _apiController;
  LocalHttpServer? _httpServer;
  List<Beacon> _peers = const [];
  String _localIp = '0.0.0.0';
  String? _error;
  bool _starting = true;
  bool _syncing = false;
  Beacon? _lastPairedPeer;

  String get _platform =>
      kIsWeb ? 'web' : Platform.operatingSystem.toLowerCase();

  @override
  void initState() {
    super.initState();
    unawaited(_startServices());
  }

  @override
  void dispose() {
    _manualAddressController.dispose();
    unawaited(_peerSubscription?.cancel());
    unawaited(_httpServer?.stop() ?? Future<void>.value());
    unawaited(_discovery.stop());
    super.dispose();
  }

  Future<void> _startServices() async {
    try {
      _localIp = await _findLocalIp();
      _peerSubscription = _discovery.watchPeers().listen((peers) {
        if (!mounted) {
          return;
        }
        setState(() => _peers = peers);
        for (final peer in peers) {
          unawaited(_probeLatency(peer));
        }
      });

      final database = widget.database;
      var advertisedPort = widget.port;
      if (database != null) {
        _apiController = SyncApiController(
          db: database,
          localDeviceId: _discovery.selfDeviceId,
          localDeviceName: widget.deviceName,
          localPlatform: _platform,
          localIp: _localIp,
          localPort: widget.port,
        );
        _httpServer =
            LocalHttpServer(_apiController!, defaultPort: widget.port);
        try {
          await _httpServer!.start();
          advertisedPort = _httpServer!.port ?? widget.port;
        } catch (error) {
          _httpServer = null;
          throw StateError('同步服务启动失败，未广播不可用端口：$error');
        }
      }

      await _discovery.start(
        deviceName: widget.deviceName,
        platform: _platform,
        ip: _localIp,
        port: advertisedPort,
      );
      if (mounted) {
        setState(() => _error = null);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '局域网发现暂不可用：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  Future<String> _findLocalIp() async {
    if (kIsWeb) {
      return '127.0.0.1';
    }

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback && !address.isLinkLocal) {
            return address.address;
          }
        }
      }
    } catch (_) {
      // Fall through to loopback for isolated or test environments.
    }
    return '127.0.0.1';
  }

  Future<void> _probeLatency(Beacon peer) async {
    if (_latencyProbes.contains(peer.deviceId)) {
      return;
    }
    _latencyProbes.add(peer.deviceId);

    final stopwatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        peer.ip,
        peer.port,
        timeout: const Duration(milliseconds: 800),
      );
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _latencyMs[peer.deviceId] = stopwatch.elapsedMilliseconds;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _latencyMs.remove(peer.deviceId);
        });
      }
    } finally {
      socket?.destroy();
      _latencyProbes.remove(peer.deviceId);
    }
  }

  Future<void> _openPairing(
    Beacon peer, {
    bool syncAfterPairing = true,
  }) async {
    final apiController = _apiController;
    if (widget.database == null || apiController == null) {
      _showMessage('请先注入 AppDatabase 后再使用配对');
      return;
    }

    _lastPairedPeer = null;
    final paired = await showDialog<bool>(
      context: context,
      builder: (context) => PairingDialog(
        localPin: apiController.pin,
        remoteDeviceName: peer.deviceName,
        onSubmit: (pin) => _pairPeer(peer, pin),
      ),
    );
    if (paired == true && syncAfterPairing && mounted) {
      // Manual IP peers have a synthetic deviceId. Use the identity returned
      // by the pairing endpoint for the first sync instead of looking up the
      // synthetic ID again.
      await _syncPeer(_lastPairedPeer ?? peer);
    }
  }

  Future<void> _pairPeer(Beacon peer, String pin) async {
    final database = widget.database;
    if (database == null) {
      throw StateError('database unavailable');
    }

    final response = await http
        .post(
          _endpoint(peer, '/api/v1/pair'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'pin': pin,
            'deviceId': _discovery.selfDeviceId,
            'deviceName': widget.deviceName,
            'platform': _platform,
            'ip': _localIp,
            'port': widget.port,
          }),
        )
        .timeout(const Duration(seconds: 4));
    final body = _decodeResponse(response);
    if (response.statusCode != HttpStatus.ok) {
      throw StateError(body['error']?.toString() ?? '配对失败');
    }

    final pairingKey = body['pairing_key'] ?? body['pairingKey'];
    if (pairingKey is! String || pairingKey.isEmpty) {
      throw const FormatException('响应缺少 pairing_key');
    }

    final remoteDeviceId = body['device_id'] as String? ??
        body['deviceId'] as String? ??
        peer.deviceId;
    final pairedPeer = Beacon(
      deviceId: remoteDeviceId,
      deviceName: body['device_name'] as String? ??
          body['deviceName'] as String? ??
          peer.deviceName,
      platform: body['platform'] as String? ?? peer.platform,
      ip: body['ip'] as String? ?? peer.ip,
      port: (body['port'] as num?)?.toInt() ?? peer.port,
    );
    await _apiController!.storePairing(
      deviceId: remoteDeviceId,
      deviceName: pairedPeer.deviceName,
      platform: pairedPeer.platform,
      ip: pairedPeer.ip,
      port: pairedPeer.port,
      pairingKey: pairingKey,
    );
    _lastPairedPeer = pairedPeer;
  }

  Future<void> _syncPeer(Beacon peer) async {
    final database = widget.database;
    if (database == null) {
      _showMessage('数据库尚未就绪');
      return;
    }

    final device = await (database.select(database.syncDevices)
          ..where((row) => row.deviceId.equals(peer.deviceId)))
        .getSingleOrNull();
    if (device == null || !device.isTrusted) {
      await _openPairing(peer, syncAfterPairing: true);
      return;
    }

    setState(() => _syncing = true);
    SyncOrchestrator? orchestrator;
    try {
      orchestrator = SyncOrchestrator(
        database: database,
        diffFetcher: (lastSyncedAt) => _fetchDiff(peer, device, lastSyncedAt),
        diffPusher: _pushDiff,
      );
      final outcome = await orchestrator.runSync(peer, device.lastSyncedAt);
      if (!mounted) {
        return;
      }
      if (outcome.state == SyncState.completed) {
        final conflictText =
            outcome.conflicts > 0 ? '，备份 ${outcome.conflicts} 条冲突便签' : '';
        _showMessage(
          '同步完成，更新 ${outcome.appliedTodos} 项待办，'
          '${outcome.appliedMemos} 条便签$conflictText',
        );
      } else {
        _showMessage('同步超时，请确认设备在同一局域网');
      }
    } finally {
      await orchestrator?.dispose();
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<Map<String, dynamic>> _fetchDiff(
    Beacon peer,
    SyncDevice device,
    int lastSyncedAt,
  ) async {
    final response = await http
        .post(
          _endpoint(peer, '/api/v1/sync/diff-request'),
          headers: _authHeaders(peer, device),
          body: jsonEncode({'last_synced_at': lastSyncedAt}),
        )
        .timeout(const Duration(seconds: 4));
    final body = _decodeResponse(response);
    if (response.statusCode == HttpStatus.unauthorized) {
      throw StateError('设备尚未配对');
    }
    if (response.statusCode != HttpStatus.ok) {
      throw StateError(body['error']?.toString() ?? '同步请求失败');
    }
    return body;
  }

  Future<void> _pushDiff(
    Beacon peer,
    Map<String, dynamic> diff,
    int lastSyncedAt,
    int syncedAt,
  ) async {
    final database = widget.database;
    if (database == null) {
      return;
    }
    final device = await (database.select(database.syncDevices)
          ..where((row) => row.deviceId.equals(peer.deviceId)))
        .getSingleOrNull();
    if (device == null || !device.isTrusted) {
      throw StateError('设备尚未配对');
    }

    final response = await http
        .post(
          _endpoint(peer, '/api/v1/sync/diff-request'),
          headers: _authHeaders(peer, device),
          body: jsonEncode({
            ...diff,
            'last_synced_at': lastSyncedAt,
            'synced_at': syncedAt,
          }),
        )
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != HttpStatus.ok) {
      throw StateError('推送同步数据失败');
    }
  }

  Map<String, String> _authHeaders(Beacon peer, SyncDevice device) => {
        'content-type': 'application/json',
        'x-device-id': _discovery.selfDeviceId,
        'x-sync-token': SyncAuth.tokenForPairingKeyHash(
          _discovery.selfDeviceId,
          device.pairingKeyHash,
        ),
      };

  Uri _endpoint(Beacon peer, String path) =>
      Uri(scheme: 'http', host: peer.ip, port: peer.port, path: path);

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('服务响应格式错误');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _connectManualAddress() async {
    final raw = _manualAddressController.text.trim();
    if (raw.isEmpty) {
      return;
    }

    try {
      const localHttpScheme = 'http';
      final uri = Uri.parse(
        raw.contains('://') ? raw : '$localHttpScheme://$raw',
      );
      if (uri.host.isEmpty) {
        throw const FormatException('请输入 ip:port');
      }
      final port = uri.hasPort ? uri.port : DiscoveryService.multicastPort;
      final pairedPeer = widget.database == null
          ? null
          : await findTrustedPeerByAddress(
              widget.database!,
              ip: uri.host,
              port: port,
            );
      if (pairedPeer != null) {
        await _syncPeer(pairedPeer);
        return;
      }
      final peer = Beacon(
        deviceId: 'manual:${uri.host}:$port',
        deviceName: '${uri.host}:$port',
        platform: 'unknown',
        ip: uri.host,
        port: port,
      );
      await _openPairing(peer, syncAfterPairing: true);
    } catch (error) {
      _showMessage('地址格式无效：$error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (widget.embedded) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设备互联'),
        actions: [
          IconButton(
            tooltip: '刷新设备',
            onPressed: _starting
                ? null
                : () {
                    setState(() {});
                    for (final peer in _peers) {
                      unawaited(_probeLatency(peer));
                    }
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final devices = _buildDevicesPanel(context);
        final side = _buildConnectionPanel(context);
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusHeader(context),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 14),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: devices),
                          const SizedBox(width: 14),
                          SizedBox(width: 300, child: side),
                        ],
                      )
                    : ListView(
                        children: [
                          SizedBox(height: 420, child: devices),
                          const SizedBox(height: 14),
                          side,
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _starting
                ? scheme.outline
                : (_peers.isEmpty ? scheme.tertiary : const Color(0xFF2EAD6B)),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _starting ? '正在发现设备' : '${_peers.length} 台设备在线',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (_starting)
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildDevicesPanel(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
            child: Text(
              '附近设备',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: _peers.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildLocalDeviceCard(context);
                }
                final peer = _peers[index - 1];
                return _buildPeerCard(context, peer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalDeviceCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.computer_rounded, color: scheme.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.deviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_localIp:${widget.port}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const _OnlineBadge(),
        ],
      ),
    );
  }

  Widget _buildPeerCard(BuildContext context, Beacon peer) {
    final scheme = Theme.of(context).colorScheme;
    final latency = _latencyMs[peer.deviceId];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: scheme.secondaryContainer,
            child: Icon(
              peer.platform == 'windows' ||
                      peer.platform == 'macos' ||
                      peer.platform == 'linux'
                  ? Icons.computer_rounded
                  : Icons.smartphone_rounded,
              color: scheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.deviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${peer.ip}:${peer.port}'
                  '${latency == null ? '' : ' · $latency ms'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _syncing
                ? null
                : () {
                    unawaited(_syncPeer(peer));
                  },
            icon: _syncing
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('同步'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionPanel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final token =
        '$_localIp:${widget.port}:${_apiController?.pin ?? _discovery.selfDeviceId}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '手动连接',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 9),
            TextField(
              key: const Key('sync-manual-address'),
              controller: _manualAddressController,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => unawaited(_connectManualAddress()),
              decoration: const InputDecoration(
                hintText: '192.168.1.20:53317',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 9),
            FilledButton.icon(
              onPressed: () => unawaited(_connectManualAddress()),
              icon: const Icon(Icons.cable_rounded),
              label: const Text('连接'),
            ),
            const Divider(height: 30),
            Text(
              '二维码',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 190,
                height: 190,
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: PrettyQrView.data(
                  data: token,
                  errorCorrectLevel: QrErrorCorrectLevel.M,
                ),
              ),
            ),
            const SizedBox(height: 9),
            SelectableText(
              token,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_apiController != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  _apiController!.refreshPin();
                  setState(() {});
                },
                icon: const Icon(Icons.pin_rounded),
                label: const Text('刷新配对码'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2EAD6B).withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '本机',
        style: TextStyle(
          color: Color(0xFF1F8752),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
