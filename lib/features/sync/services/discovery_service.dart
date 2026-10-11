import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dailydesk/core/utils/ulid.dart';
import 'package:nsd/nsd.dart' as nsd;

class Beacon {
  Beacon({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.ip,
    required this.port,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
  final String ip;
  final int port;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        'ip': ip,
        'port': port,
      };

  @override
  String toString() => 'Beacon($deviceName, $ip:$port)';
}

String encodeBeacon(Beacon beacon) => jsonEncode(beacon.toJson());

Beacon? decodeBeacon(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }

    final deviceId = decoded['deviceId'];
    final deviceName = decoded['deviceName'];
    final platform = decoded['platform'];
    final ip = decoded['ip'];
    final port = decoded['port'];
    if (deviceId is! String ||
        deviceName is! String ||
        ip is! String ||
        port is! int) {
      return null;
    }

    return Beacon(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform is String ? platform : 'unknown',
      ip: ip,
      port: port,
    );
  } catch (_) {
    return null;
  }
}

/// The nsd surface used by [DiscoveryService].
///
/// Keeping the plugin behind this boundary makes the lifecycle testable without
/// changing the process-wide [nsd.NsdPlatformInterface] instance or touching a
/// real LAN.
abstract interface class DiscoveryBackend {
  Future<nsd.Registration> register(nsd.Service service);

  Future<void> unregister(nsd.Registration registration);

  Future<nsd.Discovery> startDiscovery(
    String serviceType, {
    bool autoResolve,
    nsd.IpLookupType ipLookupType,
  });

  Future<void> stopDiscovery(nsd.Discovery discovery);

  Future<nsd.Service> resolve(nsd.Service service);
}

class PlatformDiscoveryBackend implements DiscoveryBackend {
  const PlatformDiscoveryBackend();

  @override
  Future<nsd.Registration> register(nsd.Service service) =>
      nsd.register(service);

  @override
  Future<void> unregister(nsd.Registration registration) =>
      nsd.unregister(registration);

  @override
  Future<nsd.Discovery> startDiscovery(
    String serviceType, {
    bool autoResolve = true,
    nsd.IpLookupType ipLookupType = nsd.IpLookupType.none,
  }) =>
      nsd.startDiscovery(
        serviceType,
        autoResolve: autoResolve,
        ipLookupType: ipLookupType,
      );

  @override
  Future<void> stopDiscovery(nsd.Discovery discovery) =>
      nsd.stopDiscovery(discovery);

  @override
  Future<nsd.Service> resolve(nsd.Service service) => nsd.resolve(service);
}

typedef DatagramSocketFactory = Future<RawDatagramSocket> Function();

class DiscoveryService {
  static const multicastGroup = '224.0.0.167';
  static const multicastPort = 53317;
  static const mdnsServiceType = '_dailydesk._tcp';
  static const heartbeatPeriod = Duration(seconds: 1);
  static const offlineAfter = Duration(seconds: 3);

  DiscoveryService({
    DiscoveryBackend? backend,
    this.enableUdp = true,
    DatagramSocketFactory? socketFactory,
    DateTime Function()? now,
    Duration? heartbeatPeriod,
    Duration? offlineAfter,
    String? deviceId,
  })  : _backend = backend ?? const PlatformDiscoveryBackend(),
        _socketFactory = socketFactory,
        _now = now ?? DateTime.now,
        _heartbeatPeriod = heartbeatPeriod ?? DiscoveryService.heartbeatPeriod,
        _offlineAfter = offlineAfter ?? DiscoveryService.offlineAfter,
        selfDeviceId = deviceId ?? newUlid();

  final DiscoveryBackend _backend;
  final bool enableUdp;
  final DatagramSocketFactory? _socketFactory;
  final DateTime Function() _now;
  final Duration _heartbeatPeriod;
  final Duration _offlineAfter;
  final String selfDeviceId;

  final Map<String, (Beacon, DateTime)> _udpPeers = {};
  final Map<String, Beacon> _mdnsPeers = {};
  final Set<String> _activeMdnsServices = {};
  final Map<String, String> _mdnsServiceToDeviceId = {};
  final Map<String, Set<String>> _mdnsDeviceToServices = {};
  final Map<String, int> _mdnsResolveGenerations = {};
  final StreamController<List<Beacon>> _controller =
      StreamController<List<Beacon>>.broadcast();

  RawDatagramSocket? _socket;
  nsd.Registration? _mdnsRegistration;
  nsd.Discovery? _mdnsDiscovery;
  nsd.ServiceListener? _mdnsListener;
  Timer? _heartbeat;
  bool _started = false;
  bool _closed = false;
  int _lifecycleGeneration = 0;

  Beacon? _selfBeacon;

  Beacon? get selfBeacon => _selfBeacon;

  Stream<List<Beacon>> watchPeers() => _controller.stream;

  Future<void> start({
    required String deviceName,
    required String platform,
    required String ip,
    required int port,
  }) async {
    if (_closed) {
      throw StateError('DiscoveryService cannot be restarted after stop');
    }
    if (_started) {
      return;
    }

    _started = true;
    final generation = ++_lifecycleGeneration;
    _selfBeacon = Beacon(
      deviceId: selfDeviceId,
      deviceName: deviceName,
      platform: platform,
      ip: ip,
      port: port,
    );

    if (enableUdp) {
      try {
        await _startUdp(generation);
      } on SocketException {
        // mDNS remains available when UDP multicast is blocked or occupied.
      }
    }

    await _startMdns(generation);
  }

  Future<void> _startUdp(int generation) async {
    final socket = await (_socketFactory ?? _bindMulticastSocket)();
    if (!_started || _closed || generation != _lifecycleGeneration) {
      socket.close();
      return;
    }

    _socket = socket;
    socket.multicastLoopback = true;
    socket.joinMulticast(InternetAddress(multicastGroup));
    socket.listen(_handleSocketEvent);

    final payload = Uint8List.fromList(utf8.encode(encodeBeacon(_selfBeacon!)));
    _sendBeacon(payload);
    _heartbeat = Timer.periodic(_heartbeatPeriod, (_) {
      _sendBeacon(payload);
      sweepOffline();
    });
  }

  Future<void> _startMdns(int generation) async {
    final self = _selfBeacon!;
    final service = nsd.Service(
      name: 'DD-${self.deviceId.substring(0, 8)}',
      type: mdnsServiceType,
      port: self.port,
      txt: {
        'deviceId': _txt(self.deviceId),
        'device': _txt(self.deviceName),
        'platform': _txt(self.platform),
        'ip': _txt(self.ip),
      },
    );

    try {
      final registration = await _backend.register(service);
      if (!_started || _closed || generation != _lifecycleGeneration) {
        await _backend.unregister(registration);
        return;
      }
      _mdnsRegistration = registration;
    } catch (_) {
      // UDP is the fallback when mDNS registration is unavailable.
      _mdnsRegistration = null;
    }

    try {
      final discovery = await _backend.startDiscovery(
        mdnsServiceType,
        autoResolve: true,
        ipLookupType: nsd.IpLookupType.any,
      );
      if (!_started || generation != _lifecycleGeneration) {
        await _backend.stopDiscovery(discovery);
        return;
      }

      _mdnsDiscovery = discovery;
      void listener(nsd.Service service, nsd.ServiceStatus status) {
        _handleMdnsService(service, status, generation);
      }

      _mdnsListener = listener;
      discovery.addServiceListener(listener);

      // A platform may populate the collection before the listener is added.
      for (final discovered in discovery.services) {
        _handleMdnsService(discovered, nsd.ServiceStatus.found, generation);
      }
    } catch (_) {
      // UDP remains available when mDNS browsing is unsupported.
      _mdnsDiscovery = null;
    }
  }

  Future<RawDatagramSocket> _bindMulticastSocket() async {
    try {
      return await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        multicastPort,
        reuseAddress: true,
        reusePort: true,
      );
    } on SocketException {
      return RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        multicastPort,
        reuseAddress: true,
      );
    }
  }

  void _handleSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }

    final datagram = _socket?.receive();
    if (datagram == null) {
      return;
    }

    final beacon = decodeBeacon(
      utf8.decode(datagram.data, allowMalformed: true),
    );
    if (beacon != null) {
      acceptUdpBeacon(beacon);
    }
  }

  /// Accepts a decoded UDP beacon. This is also the deterministic seam used by
  /// tests that must not bind a multicast socket.
  void acceptUdpBeacon(Beacon beacon, {DateTime? seenAt}) {
    if (beacon.deviceId == selfDeviceId) {
      return;
    }

    _udpPeers[beacon.deviceId] = (beacon, seenAt ?? _now());
    _emit();
  }

  /// Sweeps UDP-only peers whose heartbeat has expired.
  void sweepOffline({DateTime? at}) {
    final cutoff = (at ?? _now()).subtract(_offlineAfter);
    final before = _udpPeers.length;
    _udpPeers.removeWhere((_, value) => value.$2.isBefore(cutoff));
    if (_udpPeers.length != before) {
      _emit();
    }
  }

  void _sendBeacon(Uint8List payload) {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    try {
      socket.send(payload, InternetAddress(multicastGroup), multicastPort);
    } on SocketException {
      // The next heartbeat retries after a transient network change.
    }
  }

  void _handleMdnsService(
    nsd.Service service,
    nsd.ServiceStatus status,
    int generation,
  ) {
    if (!_started || generation != _lifecycleGeneration) {
      return;
    }

    if (status == nsd.ServiceStatus.lost) {
      final key = _serviceKey(service);
      _activeMdnsServices.remove(key);
      _mdnsResolveGenerations[key] = (_mdnsResolveGenerations[key] ?? 0) + 1;
      _removeMdnsService(service);
      return;
    }

    final key = _serviceKey(service);
    _activeMdnsServices.add(key);
    final resolveGeneration = (_mdnsResolveGenerations[key] ?? 0) + 1;
    _mdnsResolveGenerations[key] = resolveGeneration;
    final resolvedBeacon = _beaconFromMdns(service);
    if (resolvedBeacon != null) {
      _acceptMdnsBeacon(service, resolvedBeacon, generation);
    } else {
      unawaited(
        _resolveMdnsService(
          service,
          generation,
          resolveGeneration,
        ),
      );
    }
  }

  Future<void> _resolveMdnsService(
    nsd.Service service,
    int generation,
    int resolveGeneration,
  ) async {
    try {
      final resolved = await _backend.resolve(service);
      final key = _serviceKey(service);
      if (!_started ||
          generation != _lifecycleGeneration ||
          !_activeMdnsServices.contains(key) ||
          _mdnsResolveGenerations[key] != resolveGeneration) {
        return;
      }

      final beacon = _beaconFromMdns(resolved);
      if (beacon == null) {
        return;
      }

      _acceptMdnsBeacon(service, beacon, generation);
    } catch (_) {
      // A transient resolve failure is retried by a future found event or UDP.
    }
  }

  void _acceptMdnsBeacon(
    nsd.Service service,
    Beacon beacon,
    int generation,
  ) {
    if (!_started ||
        _closed ||
        generation != _lifecycleGeneration ||
        beacon.deviceId == selfDeviceId ||
        !_activeMdnsServices.contains(_serviceKey(service))) {
      return;
    }

    final key = _serviceKey(service);
    final previousDeviceId = _mdnsServiceToDeviceId[key];
    if (previousDeviceId != null && previousDeviceId != beacon.deviceId) {
      final previousServices = _mdnsDeviceToServices[previousDeviceId];
      previousServices?.remove(key);
      if (previousServices == null || previousServices.isEmpty) {
        _mdnsDeviceToServices.remove(previousDeviceId);
        _mdnsPeers.remove(previousDeviceId);
      }
    }

    _mdnsServiceToDeviceId[key] = beacon.deviceId;
    (_mdnsDeviceToServices[beacon.deviceId] ??= <String>{}).add(key);
    _mdnsPeers[beacon.deviceId] = beacon;
    _emit();
  }

  Beacon? _beaconFromMdns(nsd.Service service) {
    final deviceId = _readTxt(service, 'deviceId');
    final deviceName = _readTxt(service, 'device') ?? service.name;
    final platform = _readTxt(service, 'platform') ?? 'unknown';
    final ip = _readTxt(service, 'ip') ??
        (service.addresses?.isNotEmpty == true
            ? service.addresses!.first.address
            : service.host);
    final port = service.port;

    if (deviceId == null ||
        deviceId.isEmpty ||
        deviceName == null ||
        deviceName.isEmpty ||
        ip == null ||
        ip.isEmpty ||
        port == null ||
        port <= 0) {
      return null;
    }

    return Beacon(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      ip: ip,
      port: port,
    );
  }

  String? _readTxt(nsd.Service service, String key) {
    final value = service.txt?[key];
    if (value == null) {
      return null;
    }
    return utf8.decode(value, allowMalformed: true);
  }

  void _removeMdnsService(nsd.Service service) {
    final key = _serviceKey(service);
    _activeMdnsServices.remove(key);
    final deviceId = _mdnsServiceToDeviceId.remove(key);
    if (deviceId == null) {
      return;
    }

    final serviceKeys = _mdnsDeviceToServices[deviceId];
    serviceKeys?.remove(key);
    if (serviceKeys == null || serviceKeys.isEmpty) {
      _mdnsDeviceToServices.remove(deviceId);
      if (_mdnsPeers.remove(deviceId) != null) {
        _emit();
      }
    }
  }

  String _serviceKey(nsd.Service service) =>
      '${service.name ?? ''}\u0000${service.type ?? ''}';

  Uint8List _txt(String value) => Uint8List.fromList(utf8.encode(value));

  void _emit() {
    if (_controller.isClosed) {
      return;
    }

    final peers = <String, Beacon>{
      ..._mdnsPeers,
      for (final entry in _udpPeers.entries) entry.key: entry.value.$1,
    }.values.toList()
      ..sort((a, b) {
        final byName = a.deviceName.compareTo(b.deviceName);
        return byName != 0 ? byName : a.deviceId.compareTo(b.deviceId);
      });
    _controller.add(peers);
  }

  Future<void> stop() async {
    if (_closed) {
      return;
    }

    _started = false;
    _closed = true;
    ++_lifecycleGeneration;
    _heartbeat?.cancel();
    _heartbeat = null;

    final discovery = _mdnsDiscovery;
    final listener = _mdnsListener;
    _mdnsDiscovery = null;
    _mdnsListener = null;
    if (discovery != null) {
      if (listener != null) {
        discovery.removeServiceListener(listener);
      }
      try {
        await _backend.stopDiscovery(discovery);
      } catch (_) {
        // Native discovery may already be gone during shutdown.
      }
    }

    final registration = _mdnsRegistration;
    _mdnsRegistration = null;
    if (registration != null) {
      try {
        await _backend.unregister(registration);
      } catch (_) {
        // Native registration may already be gone during shutdown.
      }
    }

    _socket?.close();
    _socket = null;
    _udpPeers.clear();
    _mdnsPeers.clear();
    _activeMdnsServices.clear();
    _mdnsServiceToDeviceId.clear();
    _mdnsDeviceToServices.clear();
    _mdnsResolveGenerations.clear();

    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
