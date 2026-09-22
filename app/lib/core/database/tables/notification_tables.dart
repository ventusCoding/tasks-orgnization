import 'package:drift/drift.dart';
import 'package:everslot/core/database/tables/synced_columns.dart';

@DataClassName('NotificationProfileRow')
class NotificationProfiles extends Table with SyncedColumns {
  /// gentle | standard | nag | alarm (built-ins); null for custom.
  TextColumn get code => text().nullable()();
  TextColumn get name => text()();
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();
  TextColumn get spec => text()();
  TextColumn get sortKey => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('NotificationRuleRow')
class NotificationRules extends Table with SyncedColumns {
  /// task | checklist | checklist_item | habit | category | section | global
  TextColumn get targetType => text()();
  TextColumn get targetId => text().nullable()();

  /// planner | checklists | habits | quit | system
  TextColumn get section => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get name => text().nullable()();
  TextColumn get profileId => text().nullable()();

  /// Rule spec JSON (arch §8.2).
  TextColumn get spec => text()();
  TextColumn get sortKey => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// In-app inbox. `id = uuidv5(dedupeKey)`.
@DataClassName('NotificationRow')
class Notifications extends Table with SyncedColumns {
  TextColumn get dedupeKey => text()();
  TextColumn get ruleId => text().nullable()();
  TextColumn get sourceType => text().nullable()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get occurrenceKey => text().nullable()();

  /// reminder | nag | digest | milestone | streak | system
  TextColumn get category => text()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  TextColumn get section => text().nullable()();
  DateTimeColumn get fireAt => dateTime()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();

  /// JSON array: local | push | inbox
  TextColumn get deliveredVia => text().nullable()();
  BoolColumn get late => boolean().withDefault(const Constant(false))();
  DateTimeColumn get openedAt => dateTime().nullable()();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get dismissedAt => dateTime().nullable()();
  DateTimeColumn get actedAt => dateTime().nullable()();
  TextColumn get action => text().nullable()();
  DateTimeColumn get snoozedUntil => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('NotificationMuteRow')
class NotificationMutes extends Table with SyncedColumns {
  TextColumn get targetType => text()();
  TextColumn get targetId => text().nullable()();
  TextColumn get section => text().nullable()();
  DateTimeColumn get until => dateTime().nullable()();
  TextColumn get reason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
