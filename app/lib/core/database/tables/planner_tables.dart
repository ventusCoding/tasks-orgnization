import 'package:drift/drift.dart';
import 'package:everslot/core/database/tables/synced_columns.dart';

/// Wall-clock values (`*Local`) are ISO text `YYYY-MM-DDTHH:mm`; JSON columns are text.
@DataClassName('TaskRow')
class Tasks extends Table with SyncedColumns {
  TextColumn get seriesId => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get color => integer().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// check | event | timer
  TextColumn get trackingMode => text().withDefault(const Constant('check'))();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();
  TextColumn get startLocal => text().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get timeZone => text().nullable()();

  /// Recurrence rule JSON (arch §8.1); null = one-off.
  TextColumn get recurrence => text().nullable()();
  TextColumn get recurrenceUntilLocal => text().nullable()();
  IntColumn get estimateMinutes => integer().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get deadlineLocal => text().nullable()();
  TextColumn get linkedChecklistId => text().nullable()();
  TextColumn get manualSortKey => text().nullable()();
  BoolColumn get isTemplate => boolean().withDefault(const Constant(false))();

  /// inherit | custom | inherit_plus | off
  TextColumn get notifyMode => text().withDefault(const Constant('inherit'))();

  /// active | paused | archived
  TextColumn get status => text().withDefault(const Constant('active'))();

  // P2 columns (schema v2): scheduled checklist item (T3.1.21), horizon (T3.7.11), countdown
  // (T3.7.12) and map coordinates (T3.7.13).
  TextColumn get linkedItemId => text().nullable()();
  TextColumn get horizonKey => text().nullable()();

  /// until | since
  TextColumn get countdownMode => text().nullable()();
  RealColumn get locationLat => real().nullable()();
  RealColumn get locationLng => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TaskOccurrenceRow')
class TaskOccurrences extends Table with SyncedColumns {
  TextColumn get taskId => text()();
  TextColumn get occurrenceKey => text()();
  TextColumn get overrideStartLocal => text().nullable()();
  IntColumn get overrideDurationMinutes => integer().nullable()();
  TextColumn get overrideTitle => text().nullable()();
  TextColumn get overrideNotes => text().nullable()();
  BoolColumn get isCancelled => boolean().withDefault(const Constant(false))();

  /// scheduled | in_progress | done | skipped | missed | cancelled
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
  DateTimeColumn get statusChangedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get actualStartAt => dateTime().nullable()();
  DateTimeColumn get actualEndAt => dateTime().nullable()();
  IntColumn get trackedSeconds => integer().nullable()();
  IntColumn get completionPercent => integer().nullable()();
  TextColumn get skipReason => text().nullable()();
  IntColumn get rating => integer().nullable()();
  TextColumn get outcomeNote => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TimeEntryRow')
class TimeEntries extends Table with SyncedColumns {
  TextColumn get taskId => text()();
  TextColumn get occurrenceKey => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
