/// Drift table-update watching for stats invalidation (T6.1.13).
///
/// Each domain maps to the tables its facts read. `activity_events` is deliberately not watched:
/// every planner/checklist write that logs an event also touches its entity row in the same
/// transaction, so adding a habit log (which may log an event) invalidates habit metrics only.
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';

/// Tables whose updates bump [domain].
List<TableInfo<Table, Object?>> tablesOf(AppDatabase db, StatsDomain domain) => switch (domain) {
  StatsDomain.planner => [db.tasks, db.taskOccurrences, db.timeEntries, db.categories, db.entityTags],
  StatsDomain.checklists => [db.checklists, db.checklistItems, db.checklistRuns, db.attachments],
  StatsDomain.habits => [db.habits, db.habitLogs, db.habitPauses, db.habitRevisions, db.goals],
  StatsDomain.settings => [db.userSettings, db.profiles],
  StatsDomain.notifications => [db.notifications],
};

/// Emits the set of domains whose tables changed, debounced by [debounce] (default 300 ms) so a
/// burst of writes (sync pull, bulk edit) invalidates once.
Stream<Set<StatsDomain>> watchStatsDomains(AppDatabase db, {Duration debounce = const Duration(milliseconds: 300)}) {
  late StreamController<Set<StatsDomain>> controller;
  final subs = <StreamSubscription<Set<TableUpdate>>>[];
  final pending = <StatsDomain>{};
  Timer? timer;
  controller = StreamController<Set<StatsDomain>>(
    onListen: () {
      for (final domain in StatsDomain.values) {
        final query = TableUpdateQuery.onAllTables(tablesOf(db, domain));
        subs.add(
          db.tableUpdates(query).listen((_) {
            pending.add(domain);
            timer?.cancel();
            timer = Timer(debounce, () {
              if (pending.isEmpty) return;
              final changed = {...pending};
              pending.clear();
              controller.add(changed);
            });
          }),
        );
      }
    },
    onCancel: () async {
      timer?.cancel();
      for (final s in subs) {
        await s.cancel();
      }
      subs.clear();
    },
  );
  return controller.stream;
}
