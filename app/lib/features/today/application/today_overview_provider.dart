import 'dart:async';

import 'package:collection/collection.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/notifications/application/inbox_providers.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/domain/inbox_item.dart';
import 'package:everslot/features/planner/application/planner_contract.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/today/application/day_boundary_ticker.dart';
import 'package:everslot/features/today/data/today_checklist_queries.dart';
import 'package:everslot/features/today/domain/agenda.dart';
import 'package:everslot/features/today/domain/checklist_due.dart';
import 'package:everslot/features/today/domain/habits_due.dart';
import 'package:everslot/features/today/domain/today_layout.dart';
import 'package:everslot/features/today/domain/today_overview.dart';
import 'package:everslot/features/today/domain/today_progress.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show defaultDayMilestones, milestoneProgress;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Today overview (T8.1.01): one application-layer provider assembling everything Today needs for
// the current logical day. Every source is a live Drift-backed provider of its feature, so any
// edit (from Today, another tab, a notification action or a sync pull) updates the overview; the
// day window moves at midnight / `dayStartsAt` and on zone changes.

/// Today customization (T8.1.12), live from the synced `today` settings namespace.
final todayLayoutProvider = Provider<TodayLayout>((ref) {
  final map = ref.watch(settingsProvider(SettingsNs.today)).value;
  if (map == null || map.isEmpty) return TodayLayout.defaults;
  return TodayLayout.fromJson(Map<String, Object?>.from(map));
});

/// Read-only checklist queries of Today.
final todayChecklistQueriesProvider = Provider<TodayChecklistQueries>(
  (ref) => TodayChecklistQueries(ref.watch(appDatabaseProvider), () => ref.read(currentUserIdProvider)),
);

/// Occurrences resolved for Today: the logical day plus the next one (the day may run past
/// midnight with a day start, and Now/Next looks ahead). Only this bounded range is expanded.
final todayRangeProvider = Provider.autoDispose<DayRange>((ref) => DayRange(ref.watch(todayWindowProvider).date, 2));

/// The day's agenda and the occurrences after it.
final todayPlannerProvider = Provider.autoDispose<AsyncValue<({List<PlannerItem> agenda, List<PlannerItem> upcoming})>>(
  (ref) {
    final window = ref.watch(todayWindowProvider);
    return ref
        .watch(plannerItemsProvider(ref.watch(todayRangeProvider)))
        .whenData((items) => splitAgenda(items, window));
  },
);

/// Overdue look-back in days: the Today setting, else `planner.overdueLookbackDays`.
final todayOverdueLookbackProvider = Provider<int>(
  (ref) => ref.watch(todayLayoutProvider).overdueLookbackDays ?? ref.watch(plannerSettingsProvider).overdueLookbackDays,
);

/// Unresolved past occurrences within the look-back (T8.1.05).
final todayOverdueProvider = Provider.autoDispose<AsyncValue<List<PlannerItem>>>((ref) {
  final window = ref.watch(todayWindowProvider);
  final lookback = ref.watch(todayOverdueLookbackProvider);
  final includeRecurring = ref.watch(todayLayoutProvider.select((l) => l.overdueIncludeRecurring));
  if (lookback <= 0) return const AsyncValue.data([]);
  final range = DayRange(window.date.minusDays(lookback), lookback);
  return ref
      .watch(plannerItemsProvider(range))
      .whenData(
        (items) => selectOverdue(items, today: window.date, lookbackDays: lookback, includeRecurring: includeRecurring),
      );
});

/// Whether [todayHabitsProvider] has produced a complete result once (lives as long as it does).
class _LoadedOnce {
  bool value = false;
}

final _todayHabitsLoadedProvider = Provider.autoDispose<_LoadedOnce>((ref) => _LoadedOnce());

/// Habits due today and active quit trackers, from the habits feature's snapshots (the same
/// evaluation as the Habits tab, T8.1.06 / T8.1.07). A snapshot computed before its habit's day
/// boundary is refreshed by bumping `habitTickProvider` (the Habits tab's re-evaluation signal).
///
/// The first result waits for every snapshot (no half-loaded section); afterwards a habit whose
/// snapshot is still loading (just created) is skipped until it arrives, so the block never
/// flickers back to its loading state.
final todayHabitsProvider =
    Provider.autoDispose<AsyncValue<({List<TodayHabitEntry> habits, List<TodayQuitEntry> quits})>>((ref) {
      final loadedOnce = ref.watch(_todayHabitsLoadedProvider);
      // A new day window re-runs the staleness check below.
      ref.watch(todayWindowProvider);
      final now = ref.read(clockProvider).nowUtc();
      final habitsAsync = ref.watch(habitsProvider);
      final habits = habitsAsync.value;
      if (habits == null) {
        return habitsAsync.hasError
            ? AsyncValue.error(habitsAsync.error!, habitsAsync.stackTrace ?? StackTrace.current)
            : const AsyncValue.loading();
      }
      final entries = <TodayHabitEntry>[];
      final quits = <TodayQuitEntry>[];
      var loading = false;
      var stale = false;
      for (final h in habits) {
        if (h.isArchived) continue;
        final snapshotAsync = ref.watch(habitSnapshotProvider(h.id));
        final s = snapshotAsync.value;
        if (s == null) {
          if (!snapshotAsync.hasError) loading = true;
          continue;
        }
        if (s.boundaries.dateOf(now) != s.today) stale = true;
        switch (s.habit) {
          case final BuildHabit b:
            final evaluation = s.evaluation;
            if (evaluation == null) continue;
            final entry = todayHabitEntry(
              habit: b,
              evaluation: evaluation,
              today: s.today,
              now: s.now,
              currentStreak: s.summary?.currentStreak ?? 0,
              stateOf: (key) => s.stateOf(key)?.kind,
            );
            if (entry != null) entries.add(entry);
          case final QuitHabit q:
            final calc = s.quit;
            if (calc == null) continue;
            final start = calc.currentAbstinenceStart;
            final next = milestoneProgress(
              defaultDayMilestones,
              abstinenceStart: start,
              now: s.now,
            ).firstWhereOrNull((m) => m.isNext);
            final today = calc.days.lastOrNull;
            quits.add(
              TodayQuitEntry(
                habit: q,
                abstinenceStart: start,
                moneySaved: q.unitCost == null ? null : calc.moneySaved,
                currency: q.currency,
                nextMilestone: next?.milestone,
                dayStreak: calc.dayStreak,
                usedToday: q.isReduce ? today?.used : null,
              ),
            );
        }
      }
      if (stale) {
        // Never modify another provider while building: bump once the build is over.
        unawaited(
          Future.microtask(() {
            if (ref.mounted) ref.read(habitTickProvider.notifier).bump();
          }),
        );
      }
      if (loading && !loadedOnce.value) return const AsyncValue.loading();
      loadedOnce.value = true;
      return AsyncValue.data((habits: entries, quits: quits));
    });

/// Pinned checklists with their progress (T8.1.08), in board order.
final todayPinnedProvider = Provider.autoDispose<AsyncValue<List<TodayPinnedChecklist>>>((ref) {
  final listsAsync = ref.watch(boardChecklistsProvider);
  final lists = listsAsync.value;
  if (lists == null) {
    return listsAsync.hasError
        ? AsyncValue.error(listsAsync.error!, listsAsync.stackTrace ?? StackTrace.current)
        : const AsyncValue.loading();
  }
  final pinned = [
    for (final c in lists)
      if (c.isPinned) c,
  ];
  if (pinned.isEmpty) return const AsyncValue.data([]);
  final summariesAsync = ref.watch(cardSummariesProvider(false));
  final summaries = summariesAsync.value;
  if (summaries == null) return const AsyncValue.loading();
  return AsyncValue.data([
    for (final c in pinned)
      () {
        final rollup = summaries[c.id]?.rollup;
        return TodayPinnedChecklist(
          id: c.id,
          title: c.title,
          color: c.color,
          done: rollup?.done(ProgressMode.leaves) ?? 0,
          total: rollup?.total(ProgressMode.leaves) ?? 0,
          blocked: rollup?.countOf(ItemStatus.blocked) ?? 0,
          waiting: rollup?.countOf(ItemStatus.waiting) ?? 0,
        );
      }(),
  ]);
});

/// Checklist items due today (or overdue) and follow-ups to check (T8.1.08).
final todayChecklistItemsProvider =
    StreamProvider.autoDispose<({List<TodayChecklistItem> due, List<TodayChecklistItem> followUps})>((ref) {
      ref.watch(currentUserIdProvider);
      final window = ref.watch(todayWindowProvider);
      final zones = ref.watch(zoneResolverProvider);
      return ref
          .watch(todayChecklistQueriesProvider)
          // Wall-clock prefilter with a 2-day margin for fixed-zone items; exact rules below.
          .watch(dueBefore: window.date.plusDays(2), followUpBefore: window.endUtc)
          .map((rows) => partitionChecklistItems(rows, window, zones));
    });

/// The newest unread inbox entries (Inbox highlights block).
final todayInboxHighlightsProvider = StreamProvider.autoDispose<List<InboxItem>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(inboxRepositoryProvider).watchInbox(filter: const InboxFilter(unreadOnly: true), limit: 3);
});

/// Everything Today shows for the current logical day (T8.1.01). Sections load independently: a
/// null list in the overview means "still loading" and failed sources are listed in `errors`.
final todayOverviewProvider = Provider.autoDispose<TodayOverview>((ref) {
  final window = ref.watch(todayWindowProvider);
  final planner = ref.watch(todayPlannerProvider);
  final overdue = ref.watch(todayOverdueProvider);
  final habits = ref.watch(todayHabitsProvider);
  final pinned = ref.watch(todayPinnedProvider);
  final items = ref.watch(todayChecklistItemsProvider);
  final unread = ref.watch(inboxUnreadCountProvider);
  final highlights = ref.watch(todayInboxHighlightsProvider);
  final errors = <TodaySection, Object>{
    if (planner.hasError && !planner.hasValue) TodaySection.planner: planner.error!,
    if (overdue.hasError && !overdue.hasValue) TodaySection.overdue: overdue.error!,
    if (habits.hasError && !habits.hasValue) TodaySection.habits: habits.error!,
    if (pinned.hasError && !pinned.hasValue) TodaySection.checklists: pinned.error!,
    if (items.hasError && !items.hasValue) TodaySection.checklists: items.error!,
    if (unread.hasError && !unread.hasValue) TodaySection.inbox: unread.error!,
  };
  return TodayOverview(
    window: window,
    now: ref.read(clockProvider).nowUtc(),
    agenda: planner.value?.agenda,
    upcoming: planner.value?.upcoming,
    overdue: overdue.value,
    habits: habits.value?.habits,
    quits: habits.value?.quits,
    pinned: pinned.value,
    dueItems: items.value?.due,
    followUps: items.value?.followUps,
    unreadInbox: unread.value,
    inboxHighlights: highlights.value ?? (unread.hasValue ? const [] : null),
    errors: errors,
  );
});

/// Checklist items completed during the logical day (T8.1.11).
final todayCompletedItemsProvider = StreamProvider.autoDispose<int>((ref) {
  final window = ref.watch(todayWindowProvider);
  return ref.watch(todayChecklistQueriesProvider).watchCompletedBetween(window.startUtc, window.endUtc);
});

/// The progress header's numbers (T8.1.11).
final todayProgressProvider = Provider.autoDispose<TodayProgress>(
  (ref) => TodayProgress.of(
    ref.watch(todayOverviewProvider),
    itemsCompleted: ref.watch(todayCompletedItemsProvider).value ?? 0,
  ),
);

/// Saves the Today layout (synced `user_settings.today`, T8.1.12).
final todayLayoutWriterProvider = Provider<Future<void> Function(TodayLayout layout)>(
  (ref) =>
      (layout) => ref.read(settingsRepositoryProvider).update(SettingsNs.today, layout.toJson()),
);
