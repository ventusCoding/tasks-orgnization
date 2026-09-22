import 'package:drift/drift.dart';
import 'package:everslot/core/database/tables/synced_columns.dart';

@DataClassName('CategoryRow')
class Categories extends Table with SyncedColumns {
  TextColumn get name => text()();
  IntColumn get color => integer()();
  TextColumn get icon => text().nullable()();
  TextColumn get sortKey => text()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  BoolColumn get countsAsUnavailable => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TagRow')
class Tags extends Table with SyncedColumns {
  TextColumn get name => text()();
  IntColumn get color => integer().nullable()();
  TextColumn get sortKey => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EntityTagRow')
class EntityTags extends Table with SyncedColumns {
  TextColumn get tagId => text()();

  /// task | checklist | checklist_item | habit
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SavedViewRow')
class SavedViews extends Table with SyncedColumns {
  /// planner | checklists | habits | stats
  TextColumn get section => text()();
  TextColumn get name => text()();
  TextColumn get viewType => text()();

  /// View config JSON (arch §8.3).
  TextColumn get config => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  TextColumn get sortKey => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivityEventRow')
class ActivityEvents extends Table with SyncedColumns {
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get eventType => text()();

  /// JSON payload; always contains `opId` and `cause` (arch §7.3).
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  DateTimeColumn get occurredAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AttachmentRow')
class Attachments extends Table with SyncedColumns {
  /// checklist | checklist_item | task | task_occurrence | habit | habit_log | goal
  TextColumn get ownerType => text()();
  TextColumn get ownerId => text()();
  TextColumn get bucket => text().withDefault(const Constant('attachments'))();
  TextColumn get storagePath => text()();
  TextColumn get thumbPath => text().nullable()();
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get byteSize => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get sha256 => text().nullable()();
  TextColumn get caption => text().nullable()();
  TextColumn get sortKey => text()();
  DateTimeColumn get uploadedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GoalRow')
class Goals extends Table with SyncedColumns {
  /// habit | series | category | checklist | global
  TextColumn get scopeType => text()();
  TextColumn get scopeId => text().nullable()();
  TextColumn get metric => text()();
  RealColumn get target => real()();

  /// all_time | year | quarter | month | week | custom
  TextColumn get period => text()();
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get reward => text().nullable()();
  DateTimeColumn get achievedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AchievementRow')
class Achievements extends Table with SyncedColumns {
  TextColumn get code => text()();
  TextColumn get scopeType => text().nullable()();
  TextColumn get scopeId => text().nullable()();
  DateTimeColumn get unlockedAt => dateTime()();
  TextColumn get payload => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DashboardRow')
class Dashboards extends Table with SyncedColumns {
  TextColumn get name => text()();
  TextColumn get sortKey => text()();

  /// JSON `[{metricId, scopeType, scopeId, period, chartVariant, span}]`.
  TextColumn get layout => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
