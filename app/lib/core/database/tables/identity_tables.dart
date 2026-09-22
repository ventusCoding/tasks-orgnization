import 'package:drift/drift.dart';
import 'package:everslot/core/database/tables/synced_columns.dart';

@DataClassName('ProfileRow')
class Profiles extends Table with SyncedColumns {
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get homeTimeZone => text().withDefault(const Constant('UTC'))();
  TextColumn get currentTimeZone => text().nullable()();
  TextColumn get locale => text().nullable()();
  IntColumn get weekStart => integer().withDefault(const Constant(1))();
  TextColumn get timeFormat => text().withDefault(const Constant('h24'))();
  DateTimeColumn get onboardingCompletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('UserSettingRow')
class UserSettings extends Table with SyncedColumns {
  TextColumn get namespace => text()();

  /// Versioned JSON (arch §8.5).
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
