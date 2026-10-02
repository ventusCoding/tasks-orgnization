import 'package:drift/drift.dart';

// Local-only tables (never synced) — arch §6.5.

/// Pending per-field patches waiting to be pushed (arch §6.6).
@DataClassName('OutboxRow')
class SyncOutbox extends Table {
  /// UUIDv7 change id (idempotency key on the server).
  TextColumn get changeId => text()();

  /// Operation group id: all changes of one user command (pushed atomically).
  TextColumn get opId => text()();
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get rowId => text()();

  /// insert | patch
  TextColumn get op => text()();

  /// JSON map column → value (server representation).
  TextColumn get fields => text()();

  /// JSON map column → HLC.
  TextColumn get clock => text()();
  IntColumn get entryVersion => integer().withDefault(const Constant(1))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  /// pending | inflight | failed
  TextColumn get state => text().withDefault(const Constant('pending'))();
  DateTimeColumn get enqueuedAt => dateTime()();
}

@DataClassName('SyncStateRow')
class SyncState extends Table {
  TextColumn get userId => text()();
  IntColumn get cursor => integer().withDefault(const Constant(0))();
  TextColumn get hlc => text().nullable()();
  DateTimeColumn get lastPushAt => dateTime().nullable()();
  DateTimeColumn get lastPullAt => dateTime().nullable()();
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();
  IntColumn get purgeWatermarkSeen => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

/// What this device has scheduled with the OS (arch §6.13).
@DataClassName('LocalNotificationScheduleRow')
class LocalNotificationSchedule extends Table {
  TextColumn get dedupeKey => text()();
  IntColumn get platformId => integer()();
  DateTimeColumn get fireAt => dateTime()();
  TextColumn get targetKey => text()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  BoolColumn get repeating => boolean().withDefault(const Constant(false))();
  DateTimeColumn get scheduledAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {dedupeKey};
}

@DataClassName('UiNodeStateRow')
class UiNodeState extends Table {
  TextColumn get nodeId => text()();
  TextColumn get checklistId => text()();
  BoolColumn get collapsed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {nodeId};
}

@DataClassName('UiChecklistStateRow')
class UiChecklistState extends Table {
  TextColumn get checklistId => text()();

  /// edit | preview
  TextColumn get mode => text().withDefault(const Constant('edit'))();
  TextColumn get focusItemId => text().nullable()();
  TextColumn get viewType => text().nullable()();
  TextColumn get sortJson => text().nullable()();
  TextColumn get filterJson => text().nullable()();
  RealColumn get scrollOffset => real().nullable()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {checklistId};
}

@DataClassName('UiViewStateRow')
class UiViewState extends Table {
  TextColumn get viewId => text()();
  TextColumn get json => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {viewId};
}

@DataClassName('HabitTimerStateRow')
class HabitTimerState extends Table {
  TextColumn get habitId => text()();
  TextColumn get occurrenceKey => text()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get accumulatedSeconds => integer().withDefault(const Constant(0))();
  BoolColumn get running => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {habitId, occurrenceKey};
}

@DataClassName('AttachmentCacheRow')
class AttachmentCache extends Table {
  TextColumn get attachmentId => text()();
  TextColumn get localOriginalPath => text().nullable()();
  TextColumn get localThumbPath => text().nullable()();
  IntColumn get bytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAccessAt => dateTime().nullable()();

  /// none | downloading | done | failed
  TextColumn get downloadState => text().withDefault(const Constant('none'))();

  /// pending | uploading | done | failed (for locally created attachments)
  TextColumn get uploadState => text().withDefault(const Constant('done'))();
  IntColumn get uploadAttempts => integer().withDefault(const Constant(0))();
  TextColumn get uploadError => text().nullable()();
  TextColumn get tusUploadUrl => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {attachmentId};
}

@DataClassName('InsightStateRow')
class InsightState extends Table {
  TextColumn get key => text()();
  DateTimeColumn get firedAt => dateTime().nullable()();
  DateTimeColumn get dismissedAt => dateTime().nullable()();

  /// The fired insight (trigger, entity, args, target) as JSON, so the feed shows it even after
  /// the data that produced it changed (schema v4, T6.7.08).
  TextColumn get payload => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('StatsCacheRow')
class StatsCache extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get json => text()();
  IntColumn get dataVersion => integer()();
  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

/// Simple local key/value store for device-level preferences and flags.
@DataClassName('LocalKvRow')
class LocalKv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
