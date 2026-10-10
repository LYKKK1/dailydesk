import 'package:drift/drift.dart';

class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get dueDate => text().nullable()();
  TextColumn get dueTime => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get isTop => boolean().withDefault(const Constant(false))();
  IntColumn get estimatedPomodoros =>
      integer().withDefault(const Constant(1))();
  IntColumn get actualPomodoros => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Subtasks extends Table {
  TextColumn get id => text()();
  TextColumn get todoId => text()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get todoId => text().nullable()();
  TextColumn get title => text()();
  IntColumn get startTime => integer()();
  IntColumn get endTime => integer()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  TextColumn get colorHex =>
      text().withDefault(const Constant('#4A90E2'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Memos extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  TextColumn get colorHex =>
      text().withDefault(const Constant('#F9F9FB'))();
  TextColumn get tag => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PomodoroLogs extends Table {
  TextColumn get id => text()();
  TextColumn get todoId => text().nullable()();
  IntColumn get durationMinutes => integer()();
  TextColumn get mode => text().withDefault(const Constant('pomodoro'))();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get frequencyType => text()();
  IntColumn get targetDaysPerWeek => integer().nullable()();
  TextColumn get iconName =>
      text().withDefault(const Constant('check_circle'))();
  TextColumn get colorHex =>
      text().withDefault(const Constant('#52C41A'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class HabitRecords extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text()();
  TextColumn get recordDate => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {habitId, recordDate},
      ];
}

class SyncDevices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();
  TextColumn get platform => text()();
  TextColumn get ipAddress => text()();
  IntColumn get port => integer().withDefault(const Constant(53317))();
  IntColumn get lastSyncedAt => integer().withDefault(const Constant(0))();
  TextColumn get pairingKeyHash => text()();
  BoolColumn get isTrusted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

class WidgetLayouts extends Table {
  TextColumn get id => text()();
  TextColumn get pageId => text()();
  TextColumn get kind => text()();
  IntColumn get w => integer()();
  IntColumn get h => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get config => text().withDefault(const Constant('{}'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
