import 'package:drift/drift.dart';
import 'package:everslot/core/database/tables/synced_columns.dart';

@DataClassName('ChecklistRow')
class Checklists extends Table with SyncedColumns {
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().nullable()();
  IntColumn get color => integer().nullable()();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  TextColumn get sortKey => text()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  TextColumn get coverAttachmentId => text().nullable()();
  TextColumn get dueLocal => text().nullable()();
  TextColumn get timeZone => text().nullable()();

  /// Recurrence JSON for resettable checklists.
  TextColumn get resetRule => text().nullable()();

  /// all_to_todo | completed_to_todo
  TextColumn get resetMode => text().nullable()();
  TextColumn get lastResetKey => text().nullable()();

  /// Checklist settings JSON (arch §8.6).
  TextColumn get settings => text().withDefault(const Constant('{}'))();
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();
  TextColumn get templateId => text().nullable()();
  TextColumn get notifyMode => text().withDefault(const Constant('inherit'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ChecklistItemRow')
class ChecklistItems extends Table with SyncedColumns {
  TextColumn get checklistId => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get sortKey => text()();
  TextColumn get itemText => text().named('text').withDefault(const Constant(''))();
  TextColumn get note => text().nullable()();

  /// todo | ongoing | waiting | blocked | completed | cancelled
  TextColumn get status => text().withDefault(const Constant('todo'))();
  TextColumn get statusNote => text().nullable()();
  DateTimeColumn get statusChangedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get followUpAt => dateTime().nullable()();
  TextColumn get dueLocal => text().nullable()();
  TextColumn get timeZone => text().nullable()();
  TextColumn get waitingOn => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get notifyMode => text().withDefault(const Constant('inherit'))();

  /// Routine step duration (T3.7.07, schema v2).
  IntColumn get estimateMinutes => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ChecklistRunRow')
class ChecklistRuns extends Table with SyncedColumns {
  TextColumn get checklistId => text()();
  TextColumn get occurrenceKey => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get totalItems => integer().nullable()();
  IntColumn get completedItems => integer().nullable()();

  /// JSON `[{itemId, status, completedAt}]`.
  TextColumn get snapshot => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
