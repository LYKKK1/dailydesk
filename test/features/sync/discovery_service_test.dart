import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsd/nsd.dart' as nsd;

import 'package:dailydesk/features/sync/services/discovery_service.dart';

void main() {
  test('信标 round-trip 编解码', () {
    final beacon = Beacon(
      deviceId: 'dev-1',
      deviceName: '工作台PC',
      platform: 'windows',
      ip: '192.168.1.5',
      port: 53317,
    );

    final decoded = decodeBeacon(encodeBeacon(beacon));

    expect(decoded!.deviceName, '工作台PC');
    expect(decoded.port, 53317);
    expect(decoded.platform, 'windows');
  });

  test('损坏信标容错返回 null', () {
    expect(decodeBeacon('garbage'), isNull);
    expect(decodeBeacon('{"partial": true}'), isNull);
  });

  test('缺失必填字段的信标拒绝', () {
    expect(decodeBeacon('{"deviceName": "x"}'), isNull);
  });

  test('mDNS 浏览使用显式解析，并在 found/lost 时维护 peer 生命周期', () async {
    final backend = _FakeDiscoveryBackend();
    final service = DiscoveryService(
      backend: backend,
      enableUdp: false,
      deviceId: 'self-device',
    );
    final snapshots = <List<Beacon>>[];
    final subscription = service.watchPeers().listen(snapshots.add);
    addTearDown(service.stop);
    addTearDown(subscription.cancel);

    await service.start(
      deviceName: '本机',
      platform: 'windows',
      ip: '192.168.1.2',
      port: 53317,
    );

    expect(backend.registeredService?.type, DiscoveryService.mdnsServiceType);
    expect(backend.discoveryServiceType, DiscoveryService.mdnsServiceType);
    expect(backend.discoveryAutoResolve, isTrue);
    expect(backend.discoveryIpLookupType, nsd.IpLookupType.any);

    const announced = nsd.Service(
      name: 'DD-peer',
      type: DiscoveryService.mdnsServiceType,
      port: 53317,
      host: 'peer.local',
    );
    backend.resolvedService = nsd.Service(
      name: announced.name,
      type: announced.type,
      port: announced.port,
      host: announced.host,
      txt: {
        'deviceId': _txt('peer-device'),
        'device': _txt('另一台设备'),
        'platform': _txt('android'),
        'ip': _txt('192.168.1.8'),
      },
    );

    backend.emitFound(announced);
    await _flushAsyncCallbacks();

    expect(snapshots.last.single.deviceId, 'peer-device');
    expect(backend.resolveCalls, 1);

    backend.emitLost(announced);
    await _flushAsyncCallbacks();

    expect(snapshots.last, isEmpty);

    await service.stop();
    expect(backend.stopped, isTrue);
    expect(backend.unregistered, isTrue);
  });

  test('UDP peer 在离线窗口后被清扫，mDNS 不依赖真实局域网', () async {
    final service = DiscoveryService(
      backend: _FakeDiscoveryBackend(),
      enableUdp: false,
      deviceId: 'self-device',
    );
    final snapshots = <List<Beacon>>[];
    final subscription = service.watchPeers().listen(snapshots.add);
    addTearDown(() async {
      await subscription.cancel();
      await service.stop();
    });

    final seenAt = DateTime(2026, 10, 11, 12);
    service.acceptUdpBeacon(
      Beacon(
        deviceId: 'peer-device',
        deviceName: '另一台设备',
        platform: 'android',
        ip: '192.168.1.8',
        port: 53317,
      ),
      seenAt: seenAt,
    );
    await _flushAsyncCallbacks();
    expect(snapshots.last, hasLength(1));

    service.sweepOffline(
      at: seenAt
          .add(DiscoveryService.offlineAfter + const Duration(seconds: 1)),
    );
    await _flushAsyncCallbacks();
    expect(snapshots.last, isEmpty);
  });

  test('mDNS 注册失败时仍保留浏览通道', () async {
    final backend = _FakeDiscoveryBackend(registerError: StateError('no mdns'));
    final service = DiscoveryService(
      backend: backend,
      enableUdp: false,
      deviceId: 'self-device',
    );

    await service.start(
      deviceName: '本机',
      platform: 'windows',
      ip: '192.168.1.2',
      port: 53317,
    );
    addTearDown(service.stop);

    expect(backend.discoveryStarted, isTrue);
    expect(backend.registeredService, isNull);
  });

  test('同一设备的多个 mDNS 实例只有全部丢失后才移除 peer', () async {
    final backend = _FakeDiscoveryBackend();
    final service = DiscoveryService(
      backend: backend,
      enableUdp: false,
      deviceId: 'self-device',
    );
    final snapshots = <List<Beacon>>[];
    final subscription = service.watchPeers().listen(snapshots.add);
    addTearDown(subscription.cancel);
    addTearDown(service.stop);

    await service.start(
      deviceName: '本机',
      platform: 'windows',
      ip: '192.168.1.2',
      port: 53317,
    );

    const first = nsd.Service(
      name: 'DD-peer-1',
      type: DiscoveryService.mdnsServiceType,
      port: 53317,
    );
    const second = nsd.Service(
      name: 'DD-peer-2',
      type: DiscoveryService.mdnsServiceType,
      port: 53317,
    );
    backend.resolvedService = nsd.Service(
      name: first.name,
      type: first.type,
      port: first.port,
      txt: {
        'deviceId': _txt('peer-device'),
        'device': _txt('另一台设备'),
        'platform': _txt('android'),
        'ip': _txt('192.168.1.8'),
      },
    );

    backend.emitFound(first);
    backend.emitFound(second);
    await _flushAsyncCallbacks();
    expect(snapshots.last, hasLength(1));

    backend.emitLost(first);
    await _flushAsyncCallbacks();
    expect(snapshots.last, hasLength(1));

    backend.emitLost(second);
    await _flushAsyncCallbacks();
    expect(snapshots.last, isEmpty);
  });

  test('旧的异步 mDNS resolve 结果不会覆盖同一 service 的新结果', () async {
    final backend = _FakeDiscoveryBackend();
    final service = DiscoveryService(
      backend: backend,
      enableUdp: false,
      deviceId: 'self-device',
    );
    final snapshots = <List<Beacon>>[];
    final subscription = service.watchPeers().listen(snapshots.add);
    addTearDown(subscription.cancel);
    addTearDown(service.stop);

    await service.start(
      deviceName: '本机',
      platform: 'windows',
      ip: '192.168.1.2',
      port: 53317,
    );

    final firstResolve = Completer<nsd.Service>();
    final secondResolve = Completer<nsd.Service>();
    const firstAnnounced = nsd.Service(
      name: 'DD-peer',
      type: DiscoveryService.mdnsServiceType,
      port: 53317,
      host: 'peer-old.local',
    );
    const secondAnnounced = nsd.Service(
      name: 'DD-peer',
      type: DiscoveryService.mdnsServiceType,
      port: 53317,
      host: 'peer-new.local',
    );
    final oldResult = nsd.Service(
      name: firstAnnounced.name,
      type: firstAnnounced.type,
      port: firstAnnounced.port,
      txt: {
        'deviceId': _txt('peer-device'),
        'device': _txt('Peer'),
        'platform': _txt('android'),
        'ip': _txt('192.168.1.8'),
      },
    );
    final newResult = nsd.Service(
      name: secondAnnounced.name,
      type: secondAnnounced.type,
      port: secondAnnounced.port,
      txt: {
        'deviceId': _txt('peer-device'),
        'device': _txt('Peer'),
        'platform': _txt('android'),
        'ip': _txt('192.168.1.9'),
      },
    );
    backend.resolveByHost[firstAnnounced.host!] = firstResolve;
    backend.resolveByHost[secondAnnounced.host!] = secondResolve;

    backend.emitFound(firstAnnounced);
    await _flushAsyncCallbacks();
    expect(backend.resolveCalls, 1);
    backend.emitLost(firstAnnounced);
    await _flushAsyncCallbacks();
    backend.emitFound(secondAnnounced);
    await _flushAsyncCallbacks();
    expect(backend.resolveCalls, 2);
    secondResolve.complete(newResult);
    await _flushAsyncCallbacks();
    expect(snapshots.last.single.ip, '192.168.1.9');

    firstResolve.complete(oldResult);
    await _flushAsyncCallbacks();
    expect(snapshots.last.single.ip, '192.168.1.9');
  });
}

Uint8List _txt(String value) => Uint8List.fromList(value.codeUnits);

Future<void> _flushAsyncCallbacks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeDiscoveryBackend implements DiscoveryBackend {
  _FakeDiscoveryBackend({this.registerError});

  final Object? registerError;
  final nsd.Discovery discovery = nsd.Discovery('fake-discovery');
  nsd.Service? registeredService;
  nsd.Service? resolvedService;
  String? discoveryServiceType;
  bool? discoveryAutoResolve;
  nsd.IpLookupType? discoveryIpLookupType;
  bool discoveryStarted = false;
  int resolveCalls = 0;
  final Map<String, Completer<nsd.Service>> resolveByHost = {};
  bool stopped = false;
  bool unregistered = false;

  @override
  Future<nsd.Registration> register(nsd.Service service) async {
    if (registerError != null) {
      throw registerError!;
    }
    registeredService = service;
    return nsd.Registration('fake-registration', service);
  }

  @override
  Future<void> unregister(nsd.Registration registration) async {
    unregistered = true;
  }

  @override
  Future<nsd.Discovery> startDiscovery(
    String serviceType, {
    bool autoResolve = true,
    nsd.IpLookupType ipLookupType = nsd.IpLookupType.none,
  }) async {
    discoveryStarted = true;
    discoveryServiceType = serviceType;
    discoveryAutoResolve = autoResolve;
    discoveryIpLookupType = ipLookupType;
    return discovery;
  }

  @override
  Future<void> stopDiscovery(nsd.Discovery discovery) async {
    stopped = true;
  }

  @override
  Future<nsd.Service> resolve(nsd.Service service) async {
    resolveCalls++;
    final host = service.host;
    final completer = host == null ? null : resolveByHost[host];
    if (completer != null) {
      return completer.future;
    }
    return resolvedService ?? service;
  }

  void emitFound(nsd.Service service) => discovery.add(service);

  void emitLost(nsd.Service service) => discovery.remove(service);
}
