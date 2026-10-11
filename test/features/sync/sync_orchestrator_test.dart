import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/sync/services/discovery_service.dart';
import 'package:dailydesk/features/sync/services/sync_orchestrator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';

import '../../test_database.dart';

void main() {
  test('成功同步使用单调的 synced_at，并把旧 checkpoint 作为 push 基线', () async {
    final database = createTestDatabase();
    addTearDown(database.close);

    await database.into(database.syncDevices).insert(
          SyncDevicesCompanion.insert(
            deviceId: 'peer-device',
            deviceName: 'Peer',
            platform: 'windows',
            ipAddress: '127.0.0.1',
            pairingKeyHash: 'hash',
            lastSyncedAt: const Value(5000),
            isTrusted: const Value(true),
          ),
        );

    int? pushedBase;
    int? pushedSyncedAt;
    final orchestrator = SyncOrchestrator(
      database: database,
      clock: () => 1000,
      diffFetcher: (_) async => {
        'v': 1,
        'generated_at': 900,
        'tables': <String, dynamic>{},
      },
      diffPusher: (_, __, base, syncedAt) async {
        pushedBase = base;
        pushedSyncedAt = syncedAt;
      },
    );
    addTearDown(orchestrator.dispose);

    final outcome = await orchestrator.runSync(
      Beacon(
        deviceId: 'peer-device',
        deviceName: 'Peer',
        platform: 'windows',
        ip: '127.0.0.1',
        port: 53317,
      ),
      5000,
    );

    expect(outcome.state, SyncState.completed);
    expect(pushedBase, 5000);
    expect(pushedSyncedAt, 5001);

    final stored = await (database.select(database.syncDevices)
          ..where((row) => row.deviceId.equals('peer-device')))
        .getSingle();
    expect(stored.lastSyncedAt, 5001);
  });

  test('同步时间戳不采信远端未来时间戳', () async {
    final database = createTestDatabase();
    addTearDown(database.close);

    int? pushedSyncedAt;
    final orchestrator = SyncOrchestrator(
      database: database,
      clock: () => 1000,
      diffFetcher: (_) async => {
        'v': 1,
        'generated_at': 9000,
        'tables': <String, dynamic>{
          'todos': <Map<String, dynamic>>[
            {
              'id': 'remote-todo',
              'title': 'Remote',
              'description': null,
              'priority': 1,
              'status': 'pending',
              'due_date': null,
              'due_time': null,
              'category_id': null,
              'is_top': false,
              'estimated_pomodoros': 1,
              'actual_pomodoros': 0,
              'created_at': 9000,
              'updated_at': 9000,
              'deleted_at': null,
            },
          ],
        },
      },
      diffPusher: (_, __, ___, syncedAt) async {
        pushedSyncedAt = syncedAt;
      },
    );
    addTearDown(orchestrator.dispose);

    final outcome = await orchestrator.runSync(
      Beacon(
        deviceId: 'peer-device',
        deviceName: 'Peer',
        platform: 'windows',
        ip: '127.0.0.1',
        port: 53317,
      ),
      0,
    );

    expect(outcome.state, SyncState.completed);
    expect(pushedSyncedAt, 1000);
  });

  test('推送失败时不持久化本次 synced_at', () async {
    final database = createTestDatabase();
    addTearDown(database.close);

    await database.into(database.syncDevices).insert(
          SyncDevicesCompanion.insert(
            deviceId: 'peer-device',
            deviceName: 'Peer',
            platform: 'windows',
            ipAddress: '127.0.0.1',
            pairingKeyHash: 'hash',
            lastSyncedAt: const Value(5000),
            isTrusted: const Value(true),
          ),
        );

    final orchestrator = SyncOrchestrator(
      database: database,
      clock: () => 6000,
      diffFetcher: (_) async => {
        'v': 1,
        'generated_at': 6000,
        'tables': <String, dynamic>{},
      },
      diffPusher: (_, __, ___, ____) async {
        throw StateError('push failed');
      },
    );
    addTearDown(orchestrator.dispose);

    final outcome = await orchestrator.runSync(
      Beacon(
        deviceId: 'peer-device',
        deviceName: 'Peer',
        platform: 'windows',
        ip: '127.0.0.1',
        port: 53317,
      ),
      5000,
    );

    expect(outcome.state, SyncState.failed);
    final stored = await (database.select(database.syncDevices)
          ..where((row) => row.deviceId.equals('peer-device')))
        .getSingle();
    expect(stored.lastSyncedAt, 5000);
  });

  test('合并远端 diff 后，PUSH 不回显刚拉取的远端行', () async {
    final database = createTestDatabase();
    addTearDown(database.close);

    Map<String, dynamic>? pushedDiff;
    final orchestrator = SyncOrchestrator(
      database: database,
      clock: () => 1000,
      diffFetcher: (_) async => {
        'v': 1,
        'generated_at': 1000,
        'tables': <String, dynamic>{
          'todos': <Map<String, dynamic>>[
            {
              'id': 'remote-todo',
              'title': 'Remote',
              'description': null,
              'priority': 1,
              'status': 'pending',
              'due_date': null,
              'due_time': null,
              'category_id': null,
              'is_top': false,
              'estimated_pomodoros': 1,
              'actual_pomodoros': 0,
              'created_at': 1000,
              'updated_at': 1000,
              'deleted_at': null,
            },
          ],
        },
      },
      diffPusher: (_, diff, __, ___) async {
        pushedDiff = diff;
      },
    );
    addTearDown(orchestrator.dispose);

    final outcome = await orchestrator.runSync(
      Beacon(
        deviceId: 'peer-device',
        deviceName: 'Peer',
        platform: 'windows',
        ip: '127.0.0.1',
        port: 53317,
      ),
    );

    expect(outcome.state, SyncState.completed);
    expect((pushedDiff!['tables'] as Map)['todos'], isEmpty);
  });
}
