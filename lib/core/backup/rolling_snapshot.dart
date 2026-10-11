import 'dart:io';

/// Daily rolling SQLite snapshots with a bounded retention window.
class RollingSnapshot {
  RollingSnapshot({
    required this.backupDir,
    this.keepDays = 14,
    this.databaseFile,
  }) : assert(keepDays > 0);

  final String backupDir;
  final int keepDays;

  /// Optional live database file used by [restore] when no target is supplied.
  final File? databaseFile;

  static final RegExp _snapshotNamePattern =
      RegExp(r'^db-(\d{4})-(\d{2})-(\d{2})\.db$');

  String _ymd(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  File _snapshotFor(DateTime date) => File(
        '${Directory(backupDir).path}${Platform.pathSeparator}'
        'db-${_ymd(date)}.db',
      );

  /// Copies [sourceDb] into the rolling backup directory.
  ///
  /// The caller should close or checkpoint the SQLite connection first so the
  /// source file contains all committed pages.
  Future<File> writeSnapshot(
    File sourceDb, {
    DateTime Function()? now,
  }) async {
    if (!await sourceDb.exists()) {
      throw FileSystemException('Database file does not exist', sourceDb.path);
    }

    final directory = Directory(backupDir);
    await directory.create(recursive: true);

    final target = _snapshotFor((now ?? DateTime.now)());
    final temporary = File('${target.path}.tmp');

    try {
      await sourceDb.copy(temporary.path);
      if (await target.exists()) {
        await target.delete();
      }
      return temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  /// Writes at most one snapshot for the current day and then sweeps old files.
  Future<File> writeDailySnapshotIfNeeded(
    File sourceDb, {
    DateTime Function()? now,
  }) async {
    final current = (now ?? DateTime.now)();
    final target = _snapshotFor(current);

    if (!await target.exists()) {
      await writeSnapshot(sourceDb, now: () => current);
    }
    await sweepExpired(now: () => current);
    return target;
  }

  /// Returns snapshots newest-first.
  Future<List<File>> listSnapshots() async {
    final directory = Directory(backupDir);
    if (!await directory.exists()) {
      return const <File>[];
    }

    final snapshots = await directory
        .list()
        .where((entity) =>
            entity is File &&
            _snapshotNamePattern.hasMatch(entity.uri.pathSegments.last))
        .cast<File>()
        .toList();
    snapshots.sort((a, b) => b.path.compareTo(a.path));
    return snapshots;
  }

  /// Deletes snapshots older than the configured retention window.
  Future<void> sweepExpired({DateTime Function()? now}) async {
    final today = (now ?? DateTime.now)();
    final cutoff = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: keepDays));

    for (final snapshot in await listSnapshots()) {
      final snapshotDate =
          _snapshotDate(snapshot) ?? (await snapshot.stat()).modified;
      if (snapshotDate.isBefore(cutoff)) {
        await snapshot.delete();
      }
    }
  }

  /// Restores [snapshot] to [targetDb] or the constructor's [databaseFile].
  ///
  /// Confirmation belongs to the UI layer. The database connection must be
  /// closed before calling this method.
  Future<void> restore(
    File snapshot, {
    File? targetDb,
  }) async {
    if (!await snapshot.exists()) {
      throw FileSystemException('Snapshot does not exist', snapshot.path);
    }

    final target = targetDb ?? databaseFile;
    if (target == null) {
      throw StateError('No restore target was supplied');
    }
    if (snapshot.absolute.path == target.absolute.path) {
      throw ArgumentError.value(
        snapshot.path,
        'snapshot',
        'Snapshot and target must be different files',
      );
    }

    await target.parent.create(recursive: true);

    final temporary = File('${target.path}.restore.tmp');
    final previous = File('${target.path}.pre-restore');
    try {
      await snapshot.copy(temporary.path);
      if (await previous.exists()) {
        await previous.delete();
      }
      if (await target.exists()) {
        await target.rename(previous.path);
      }

      try {
        await temporary.rename(target.path);
        await _deleteSidecars(target);
        if (await previous.exists()) {
          await previous.delete();
        }
      } catch (_) {
        if (await target.exists()) {
          await target.delete();
        }
        if (await previous.exists()) {
          await previous.rename(target.path);
        }
        rethrow;
      }
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  DateTime? _snapshotDate(File snapshot) {
    final match =
        _snapshotNamePattern.firstMatch(snapshot.uri.pathSegments.last);
    if (match == null) {
      return null;
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    return DateTime(year, month, day);
  }

  Future<void> _deleteSidecars(File database) async {
    for (final suffix in const ['-wal', '-shm']) {
      final sidecar = File('${database.path}$suffix');
      if (await sidecar.exists()) {
        await sidecar.delete();
      }
    }
  }
}
