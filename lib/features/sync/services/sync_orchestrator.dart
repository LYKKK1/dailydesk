import 'dart:async';

import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/features/sync/services/diff_packager.dart';
import 'package:dailydesk/features/sync/services/discovery_service.dart';
import 'package:dailydesk/features/sync/services/merge_engine.dart';
import 'package:drift/drift.dart';

enum SyncState {
  idle,
  discovered,
  unpaired,
  pullDiff,
  localMerge,
  pushDiff,
  completed,
  failed,
}

class SyncOutcome {
  SyncOutcome(
    this.state, {
    this.appliedTodos = 0,
    this.appliedMemos = 0,
    this.conflicts = 0,
  });

  final SyncState state;
  final int appliedTodos;
  final int appliedMemos;
  final int conflicts;
}

typedef DiffFetcher = Future<Map<String, dynamic>> Function(
  int lastSyncedAt,
);

typedef DiffPusher = Future<void> Function(
  Beacon peer,
  Map<String, dynamic> diff,
  int lastSyncedAt,
  int syncedAt,
);

class SyncOrchestrator {
  SyncOrchestrator({
    required this.diffFetcher,
    this.database,
    this.diffPusher,
    this.timeout = const Duration(milliseconds: 4000),
    int Function()? clock,
  }) : now = clock ?? nowMs;

  final DiffFetcher diffFetcher;
  final AppDatabase? database;
  final DiffPusher? diffPusher;
  final Duration timeout;
  final int Function() now;

  final StreamController<SyncState> _states =
      StreamController<SyncState>.broadcast();

  SyncState _state = SyncState.idle;

  SyncState get state => _state;
  Stream<SyncState> get states => _states.stream;

  Future<SyncOutcome> runSync(
    Beacon peer, [
    int lastSyncedAt = 0,
  ]) async {
    try {
      _emit(SyncState.pullDiff);
      final remoteDiff = await _fetchWithRetry(lastSyncedAt);
      if (remoteDiff == null) {
        return SyncOutcome(SyncState.failed);
      }

      final db = database;
      // Capture local changes before applying the remote diff. Otherwise the
      // just-merged remote rows would be echoed back during PUSH.
      final localDiff =
          db == null ? null : await buildDiff(db, lastSyncedAt, clock: now);

      MergeResult? mergeResult;
      if (db != null) {
        _emit(SyncState.localMerge);
        mergeResult = await applyDiff(db, remoteDiff);
      }

      _emit(SyncState.pushDiff);
      final syncedAt = _syncTimestamp(
        lastSyncedAt: lastSyncedAt,
        localDiff: localDiff,
      );
      if (db != null && diffPusher != null) {
        await diffPusher!(
          peer,
          localDiff!,
          lastSyncedAt,
          syncedAt,
        ).timeout(timeout);
      }
      if (db != null) {
        await _updateCheckpoint(db, peer.deviceId, syncedAt);
      }

      final tables = remoteDiff['tables'] as Map? ?? const {};
      final outcome = SyncOutcome(
        SyncState.completed,
        appliedTodos: ((tables['todos'] as List?) ?? const []).length,
        appliedMemos: ((tables['memos'] as List?) ?? const []).length,
        conflicts: mergeResult?.conflictsCopied ?? 0,
      );
      _emit(SyncState.completed);
      return outcome;
    } on TimeoutException {
      _emit(SyncState.failed);
      return SyncOutcome(SyncState.failed);
    } catch (_) {
      _emit(SyncState.failed);
      return SyncOutcome(SyncState.failed);
    }
  }

  Future<Map<String, dynamic>?> _fetchWithRetry(int lastSyncedAt) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await diffFetcher(lastSyncedAt).timeout(timeout);
      } on TimeoutException {
        if (attempt == 1) {
          return null;
        }
      }
    }
    return null;
  }

  Future<void> _updateCheckpoint(
    AppDatabase db,
    String peerDeviceId,
    int value,
  ) async {
    await (db.update(db.syncDevices)
          ..where(
            (row) =>
                row.deviceId.equals(peerDeviceId) &
                row.lastSyncedAt.isSmallerThanValue(value),
          ))
        .write(SyncDevicesCompanion(lastSyncedAt: Value(value)));
  }

  int _syncTimestamp({
    required int lastSyncedAt,
    Map<String, dynamic>? localDiff,
  }) {
    var timestamp = lastSyncedAt + 1;
    timestamp = _maxTimestamp(timestamp, now());
    if (localDiff != null) {
      timestamp = _maxTimestamp(timestamp, localDiff['generated_at']);
      timestamp = _maxTimestamp(timestamp, _maxUpdatedAt(localDiff));
    }
    return timestamp;
  }

  int _maxTimestamp(int current, dynamic candidate) {
    return candidate is num && candidate.toInt() > current
        ? candidate.toInt()
        : current;
  }

  int _maxUpdatedAt(Map<String, dynamic> diff) {
    var latest = 0;
    final tables = diff['tables'];
    if (tables is! Map) {
      return latest;
    }
    for (final rows in tables.values) {
      if (rows is! List) {
        continue;
      }
      for (final row in rows) {
        if (row is Map) {
          latest = _maxTimestamp(latest, row['updated_at']);
          latest = _maxTimestamp(latest, row['updatedAt']);
        }
      }
    }
    return latest;
  }

  void _emit(SyncState next) {
    _state = next;
    if (!_states.isClosed) {
      _states.add(next);
    }
  }

  Future<SyncOutcome> runSyncForTest() => runSync(
        Beacon(
          deviceId: 't',
          deviceName: 't',
          platform: 't',
          ip: '0.0.0.0',
          port: 0,
        ),
        0,
      );

  Future<void> dispose() => _states.close();
}
