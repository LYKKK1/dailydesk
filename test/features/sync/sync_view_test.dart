import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/sync/presentation/sync_view.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../test_database.dart';

void main() {
  test('按手动 IP 和端口复用已配对的真实设备 ID', () async {
    final database = createTestDatabase();
    addTearDown(database.close);

    await database.into(database.syncDevices).insert(
          SyncDevicesCompanion.insert(
            deviceId: 'real-peer-id',
            deviceName: 'Peer',
            platform: 'android',
            ipAddress: '192.168.1.8',
            port: const Value(53317),
            pairingKeyHash: 'hash',
            isTrusted: const Value(true),
          ),
        );

    final peer = await findTrustedPeerByAddress(
      database,
      ip: '192.168.1.8',
      port: 53317,
    );

    expect(peer?.deviceId, 'real-peer-id');
    expect(peer?.deviceName, 'Peer');
  });

  test('未配对地址不返回 synthetic peer', () async {
    final database = createTestDatabase();
    addTearDown(database.close);

    expect(
      await findTrustedPeerByAddress(
        database,
        ip: '192.168.1.9',
        port: 53317,
      ),
      isNull,
    );
  });
}
