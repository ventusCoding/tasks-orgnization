import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/tag.dart';
import 'package:everslot/features/planner/application/planner_contract.dart';
import 'package:everslot/features/planner/application/view_config/view_actions.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/view_config/planner_view_config.dart';
import 'package:everslot/features/planner/presentation/grid/data/demo_planner_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

// View-side data wiring (T3.3.14). Views read the planner CONTRACT (`plannerItemsProvider`,
// `backlogItemsProvider`, `plannerActionsProvider`) through these adapters so a dev-only demo data
// set can stand in until the planner data layer lands.

/// DEV-ONLY: demo data instead of the planner data layer (`planner_demo` flag or the view menu).
final plannerDemoModeProvider = NotifierProvider<PlannerDemoModeController, bool>(PlannerDemoModeController.new);

class PlannerDemoModeController extends Notifier<bool> {
  @override
  bool build() {
    final env = ref.watch(envProvider);
    return env.isDev && env.featureFlags.contains('planner_demo');
  }

  // ignore: use_setters_to_change_properties
  void set(bool enabled) => state = enabled;
}

/// Increments every minute while a time-based view is visible (drives "now" and "today").
final plannerMinuteTickProvider = NotifierProvider<PlannerMinuteTick, int>(PlannerMinuteTick.new);

class PlannerMinuteTick extends Notifier<int> {
  @override
  int build() => 0;

  void tick() => state++;
}

/// Display zone of the planner (items are resolved in the user's current zone).
final plannerZoneProvider = Provider<String>((ref) => ref.watch(deviceZoneProvider));

/// Wall-clock now in the display zone.
final plannerNowProvider = Provider<LocalDateTime>((ref) {
  ref.watch(plannerMinuteTickProvider);
  final now = ref.watch(clockProvider).nowUtc();
  return ref.watch(zoneResolverProvider).toLocal(now, ref.watch(plannerZoneProvider));
});

final plannerTodayProvider = Provider<LocalDate>((ref) => ref.watch(plannerNowProvider).date);

final timelineCacheProvider = Provider<DayTimelineCache>((ref) => DayTimelineCache(ref.watch(zoneResolverProvider)));

final demoPlannerDataProvider = Provider<DemoPlannerData>(
  (ref) => DemoPlannerData(zone: ref.watch(plannerZoneProvider), resolver: ref.watch(zoneResolverProvider)),
);

final demoPlannerStoreProvider = NotifierProvider<DemoPlannerStore, DemoPlannerState>(DemoPlannerStore.new);

class DemoPlannerStore extends Notifier<DemoPlannerState> {
  @override
  DemoPlannerState build() => DemoPlannerState(
    backlog: DemoPlannerData.defaultBacklog(ref.read(demoPlannerDataProvider), ref.read(plannerTodayProvider)),
  );

  // ignore: use_setters_to_change_properties
  void set(DemoPlannerState next) => state = next;

  /// Number of recorded demo edits (undo depth).
  int get historyLength => state.history.length;

  bool undo() {
    if (state.history.isEmpty) return false;
    final previous = state.history.last;
    state = DemoPlannerState(
      edits: previous.edits,
      created: previous.created,
      backlog: previous.backlog,
      history: state.history.sublist(0, state.history.length - 1),
    );
    return true;
  }
}

/// Occurrences of a day range (contract or demo).
final viewItemsProvider = Provider.autoDispose.family<AsyncValue<List<PlannerItem>>, DayRange>((ref, range) {
  if (ref.watch(plannerDemoModeProvider)) {
    final data = ref.watch(demoPlannerDataProvider);
    return AsyncData(demoItemsIn(data, ref.watch(demoPlannerStoreProvider), range, ref.watch(plannerTodayProvider)));
  }
  return ref.watch(plannerItemsProvider(range));
});

/// Unscheduled tasks (contract or demo).
final viewBacklogProvider = Provider.autoDispose<AsyncValue<List<PlannerItem>>>((ref) {
  if (ref.watch(plannerDemoModeProvider)) return AsyncData(ref.watch(demoPlannerStoreProvider).backlog);
  return ref.watch(backlogItemsProvider);
});

/// Mutations (contract or demo).
final viewActionsProvider = Provider<PlannerActions>((ref) {
  if (ref.watch(plannerDemoModeProvider)) {
    final store = ref.read(demoPlannerStoreProvider.notifier);
    return DemoPlannerActions(() => ref.read(demoPlannerStoreProvider), store.set, ref.watch(demoPlannerDataProvider));
  }
  return ref.watch(plannerActionsProvider);
});

/// Extra mutations beyond the contract (delete, duplicate, manual order, unschedule, timers).
final viewExtraActionsProvider = Provider<PlannerViewActions>((ref) {
  if (ref.watch(plannerDemoModeProvider)) {
    final store = ref.read(demoPlannerStoreProvider.notifier);
    return DemoPlannerActions(() => ref.read(demoPlannerStoreProvider), store.set, ref.watch(demoPlannerDataProvider));
  }
  return ref.watch(plannerViewActionsProvider);
});

/// The item filter of a view: its config filters plus tag filters resolved to task ids.
ItemFilter viewItemFilter(WidgetRef ref, PlannerViewConfig config) {
  final base = config.itemFilter;
  final tags = config.filters.tags;
  if (tags.isEmpty) return base;
  final byTask = ref.watch(tagsByEntityProvider(TaggableType.task)).value ?? const <String, List<Tag>>{};
  final wanted = tags.toSet();
  return base.withTaskIds({
    for (final e in byTask.entries)
      if (e.value.any((t) => wanted.contains(t.id))) e.key,
  });
}

/// Key of a sliced range.
@immutable
class SliceKey {
  const SliceKey(this.range, {this.filter = const ItemFilter(), this.longAsLane = true});

  final DayRange range;
  final ItemFilter filter;
  final bool longAsLane;

  @override
  bool operator ==(Object other) =>
      other is SliceKey && other.range == range && other.filter == filter && other.longAsLane == longAsLane;

  @override
  int get hashCode => Object.hash(range, filter, longAsLane);

  @override
  String toString() => 'SliceKey($range)';
}

/// Last slice per (zone, filter, date) so unchanged days keep their instance across rebuilds and
/// neighbouring ranges (per-day layout caches then only recompute affected days).
class DaySliceMemo {
  final Map<(String, int, bool, LocalDate), DaySlice> _byDay = {};

  Map<LocalDate, DaySlice> lookup(String zone, SliceKey key, List<LocalDate> days) => {
    for (final d in days)
      if (_byDay[(zone, key.filter.hashCode, key.longAsLane, d)] case final s?) d: s,
  };

  void store(String zone, SliceKey key, List<DaySlice> slices) {
    if (_byDay.length > 2000) _byDay.clear();
    for (final s in slices) {
      _byDay[(zone, key.filter.hashCode, key.longAsLane, s.date)] = s;
    }
  }
}

final daySliceMemoProvider = Provider<DaySliceMemo>((ref) {
  ref.watch(plannerZoneProvider);
  return DaySliceMemo();
});

/// Per-day slices of a range (filtered, split at midnight, DST-aware).
final daySlicesProvider = Provider.autoDispose.family<AsyncValue<List<DaySlice>>, SliceKey>((ref, key) {
  final items = ref.watch(viewItemsProvider(key.range));
  final zone = ref.watch(plannerZoneProvider);
  final cache = ref.watch(timelineCacheProvider);
  final memo = ref.watch(daySliceMemoProvider);
  return items.whenData((list) {
    final days = [for (var i = 0; i < key.range.days; i++) key.range.start.plusDays(i)];
    final slices = sliceItems(
      items: key.filter.apply(list),
      days: days,
      timelineOf: (d) => cache.of(d, zone),
      longTimedAsLane: key.longAsLane,
      previous: memo.lookup(zone, key, days),
    );
    memo.store(zone, key, slices);
    return slices;
  });
});
