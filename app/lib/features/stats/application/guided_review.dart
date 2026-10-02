/// Guided weekly review (T6.7.03): a GTD-style flow over the weekly report — wins, overdue tasks,
/// waiting / blocked items, stale lists, habits at risk, next week's overbooked days. Every action
/// is a normal entity change through the feature services (one undo entry each). The current step
/// is kept in the device-local store so the flow resumes after the app is killed; finishing
/// records `activity_events` (`entity_type = 'review'`, `entity_id = uuidv5(user|week)`,
/// `event_type = 'completed'`, `payload.week`) — the GL-04 streak counts those weeks.
library;

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/data/stats_local_store.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, LocalDateTime;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Steps of the guided review, in order.
enum GuidedReviewStep { wins, overdue, waiting, stale, habits, rebalance }

/// Saved position of an unfinished review.
typedef GuidedReviewProgress = ({String week, int step});

final guidedReviewServiceProvider = Provider<GuidedReviewService>(GuidedReviewService.new);

class GuidedReviewService {
  GuidedReviewService(this._ref);

  final Ref _ref;

  StatsLocalStore get _store => _ref.read(statsLocalStoreProvider);
  SyncWriter get _writer => _ref.read(syncWriterProvider);

  /// The planner service without its own undo registration (the flow registers each action).
  late final PlannerService _planner = PlannerService(_ref, registerUndo: false);

  static const _weekKey = 'review.week';
  static const _stepKey = 'review.step';

  /// Saved progress for [week] (null when none or for another week).
  Future<int?> savedStep(LocalDate week) async {
    final all = await _store.readAll();
    if (all[_weekKey] != week.toIso()) return null;
    return int.tryParse(all[_stepKey] ?? '');
  }

  Future<void> saveStep(LocalDate week, int step) async {
    await _store.write(_weekKey, week.toIso());
    await _store.write(_stepKey, '$step');
  }

  /// Records the completed review of [week] (idempotent: deterministic ids per user and week).
  Future<void> complete(LocalDate week) async {
    final user = _ref.read(currentUserIdProvider);
    final weekKey = week.toIso();
    await _writer.run(
      (tx) => tx.logEvent(
        entityType: 'review',
        entityId: Ids.v5('$user|$weekKey'),
        eventType: 'completed',
        payload: {'week': weekKey},
        id: Ids.v5('$user|$weekKey|completed'),
      ),
    );
    await _store.write(_stepKey, '${GuidedReviewStep.values.length}');
  }

  // -- Step actions (each returns the operation for its undo entry) -------------------------------

  /// Overdue task → tomorrow at the same time.
  Future<OpRecord> moveToTomorrow(PlannerItem item, LocalDate today) {
    final start = item.startLocal;
    return _planner.reschedule(item, newStart: LocalDateTime(today.plusDays(1), start.time), source: 'review');
  }

  Future<OpRecord> skip(PlannerItem item) => _planner.skip(item);

  Future<OpRecord> drop(PlannerItem item) => _planner.setStatus(item, OccurrenceStatus.cancelled);

  /// Waiting item → follow up tomorrow (status kept).
  Future<OpRecord?> followUpTomorrow(String checklistId, String itemId, DateTime tomorrow) => _ref
      .read(checklistServiceProvider)
      .changeStatus(checklistId, [itemId], ItemStatus.waiting, setNote: false, followUpAt: tomorrow);

  /// Waiting / blocked item → ongoing.
  Future<OpRecord?> unblock(String checklistId, String itemId) =>
      _ref.read(checklistServiceProvider).changeStatus(checklistId, [itemId], ItemStatus.ongoing, setNote: false);

  Future<OpRecord> archiveList(String checklistId) =>
      _ref.read(checklistsRepositoryProvider).setArchived(checklistId, archived: true);

  /// Habit at risk → paused for a week from today.
  Future<OpRecord> pauseWeek(String habitId, LocalDate today) =>
      _ref.read(habitServiceProvider).pause(habitId: habitId, start: today, end: today.plusDays(6));
}
