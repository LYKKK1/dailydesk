import 'package:dailydesk/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

AppDatabase createTestDatabase() {
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}
