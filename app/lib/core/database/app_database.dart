import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:everslot/core/database/search_index.dart';
import 'package:everslot/core/database/tables/tables.dart';

part 'app_database.g.dart';

/// The single local SQLite database — the source of truth for the UI (arch §6.5).
///
/// Feature repositories query it directly (`db.select(db.tasks)…`). Never write synced tables
/// directly: always go through `SyncWriter` so the outbox and activity log stay consistent.
@DriftDatabase(
  tables: [
    // identity & settings
    Profiles,
    UserSettings,
    // organization & shared
    Categories,
    Tags,
    EntityTags,
    SavedViews,
    ActivityEvents,
    Attachments,
    Goals,
    Achievements,
    Dashboards,
    // planner
    Tasks,
    TaskOccurrences,
    TimeEntries,
    // checklists
    Checklists,
    ChecklistItems,
    ChecklistRuns,
    // habits
    Habits,
    HabitSections,
    HabitVocab,
    HabitLogs,
    HabitPauses,
    HabitRevisions,
    // notifications
    NotificationProfiles,
    NotificationRules,
    Notifications,
    NotificationMutes,
    // local-only
    SyncOutbox,
    SyncState,
    LocalNotificationSchedule,
    UiNodeState,
    UiChecklistState,
    UiViewState,
    HabitTimerState,
    AttachmentCache,
    InsightState,
    StatsCache,
    LocalKv,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// In-memory database for tests.
  factory AppDatabase.forTesting(QueryExecutor executor) => AppDatabase(executor);

  static QueryExecutor _openConnection() =>
      driftDatabase(name: 'everslot', native: const DriftNativeOptions(shareAcrossIsolates: true));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      for (final statement in localIndexes) {
        await customStatement(statement);
      }
      for (final statement in searchIndexStatements) {
        await customStatement(statement);
      }
    },
    onUpgrade: (m, from, to) async {
      // v2: planner P2 columns (T3.1.21, T3.7.07, T3.7.11–T3.7.13).
      if (from < 2) {
        await m.addColumn(tasks, tasks.linkedItemId);
        await m.addColumn(tasks, tasks.horizonKey);
        await m.addColumn(tasks, tasks.countdownMode);
        await m.addColumn(tasks, tasks.locationLat);
        await m.addColumn(tasks, tasks.locationLng);
        await m.addColumn(checklistItems, checklistItems.estimateMinutes);
      }
      // v3: live item mirrors (T4.5.16).
      if (from < 3) {
        await m.addColumn(checklistItems, checklistItems.mirrorOfId);
      }
      // v4: fired insights keep their payload (T6.7.08).
      if (from < 4) {
        await m.addColumn(insightState, insightState.payload);
      }
      // v5: inbox entries join the search index (T8.1.14).
      if (from < 5) {
        for (final statement in [...searchIndexStatements, ...SearchIndexSchema.rebuildStatements]) {
          await customStatement(statement);
        }
      }
      // v6: imported calendar events keep their UID (T8.2.12).
      if (from < 6 && !await _hasColumn('tasks', 'external_uid')) {
        await m.addColumn(tasks, tasks.externalUid);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = OFF');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Future<bool> _hasColumn(String table, String column) async =>
      (await customSelect('PRAGMA table_info($table)').get()).any((r) => r.read<String>('name') == column);

  /// Secondary indexes for the hot queries of each feature.
  static const localIndexes = <String>[
    'CREATE INDEX IF NOT EXISTS idx_tasks_start ON tasks (start_local)',
    'CREATE INDEX IF NOT EXISTS idx_tasks_series ON tasks (series_id)',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_occ_task_key ON task_occurrences (task_id, occurrence_key)',
    'CREATE INDEX IF NOT EXISTS idx_time_entries_task ON time_entries (task_id, occurrence_key)',
    'CREATE INDEX IF NOT EXISTS idx_items_checklist ON checklist_items (checklist_id, parent_id)',
    'CREATE INDEX IF NOT EXISTS idx_habit_logs_habit_date ON habit_logs (habit_id, local_date)',
    'CREATE INDEX IF NOT EXISTS idx_activity_entity ON activity_events (entity_type, entity_id, occurred_at)',
    'CREATE INDEX IF NOT EXISTS idx_attachments_owner ON attachments (owner_type, owner_id)',
    'CREATE INDEX IF NOT EXISTS idx_notifications_fire ON notifications (fire_at)',
    'CREATE INDEX IF NOT EXISTS idx_entity_tags_entity ON entity_tags (entity_type, entity_id)',
    'CREATE INDEX IF NOT EXISTS idx_rules_target ON notification_rules (target_type, target_id)',
    'CREATE INDEX IF NOT EXISTS idx_outbox_state ON sync_outbox (state, seq)',
    'CREATE INDEX IF NOT EXISTS idx_outbox_row ON sync_outbox (table_name, row_id)',
  ];

  /// Global full-text search index (T2.3.11), maintained by triggers so rows arriving from sync
  /// are indexed too (see [SearchIndexSchema]).
  static List<String> get searchIndexStatements => SearchIndexSchema.statements;
}
