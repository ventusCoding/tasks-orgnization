import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

void main() {
  final week = DayRange(LocalDate(2026, 9, 21), 7);
  final nextWeek = DayRange(LocalDate(2026, 9, 28), 7);

  test('slices come from the contract provider and follow edits per day', () async {
    final gym = item('Gym', at(2026, 9, 21, 7), 60);
    final read = item('Read', at(2026, 9, 23, 21), 30);
    final h = PlannerHarness.create(items: [gym, read]);
    addTearDown(h.dispose);
    final key = SliceKey(week);
    final sub = h.container.listen(daySlicesProvider(key), (_, _) {});
    await pumpEventQueue();
    final first = sub.read().value!;
    expect(first[0].timed.single.item.title, 'Gym');
    expect(first[2].timed.single.item.title, 'Read');

    await h.backend.setStatus(read, OccurrenceStatus.done);
    await pumpEventQueue();
    final second = sub.read().value!;
    expect(identical(second[0], first[0]), isTrue, reason: 'unaffected day keeps its slice');
    expect(identical(second[2], first[2]), isFalse);
    expect(second[2].timed.single.item.status, OccurrenceStatus.done);
    sub.close();
  });

  test('paging back to a watched neighbour does not re-resolve it', () async {
    final h = PlannerHarness.create(items: [item('A', at(2026, 9, 22, 9), 30)]);
    addTearDown(h.dispose);
    final current = h.container.listen(daySlicesProvider(SliceKey(week)), (_, _) {});
    final neighbour = h.container.listen(daySlicesProvider(SliceKey(nextWeek)), (_, _) {});
    await pumpEventQueue();
    expect(h.backend.resolved, [week, nextWeek]);
    // "Page" forward: the old page becomes the neighbour and stays subscribed.
    final after = h.container.listen(daySlicesProvider(SliceKey(DayRange(LocalDate(2026, 10, 5), 7))), (_, _) {});
    await pumpEventQueue();
    expect(h.backend.resolved.where((r) => r == week), hasLength(1));
    current.close();
    neighbour.close();
    after.close();
  });

  test('demo mode serves generated items and mutates them through demo actions', () async {
    final h = PlannerHarness.create();
    addTearDown(h.dispose);
    h.read(plannerDemoModeProvider.notifier).set(true);
    final items = h.read(viewItemsProvider(week)).value!;
    expect(items, isNotEmpty);
    final target = items.firstWhere((i) => !i.allDay);
    await h.read(viewActionsProvider).reschedule(target, newStart: at(2026, 9, 27, 10), newDurationMinutes: 45);
    final moved = h.read(viewItemsProvider(week)).value!.firstWhere((i) => i.key == target.key);
    expect(moved.startLocal, at(2026, 9, 27, 10));
    expect(moved.durationMinutes, 45);
    expect(h.read(demoPlannerStoreProvider.notifier).undo(), isTrue);
    final restored = h.read(viewItemsProvider(week)).value!.firstWhere((i) => i.key == target.key);
    expect(restored.startLocal, target.startLocal);
    expect(h.read(viewBacklogProvider).value, isNotEmpty);
  });

  test('now/today follow the clock in the display zone', () {
    final h = PlannerHarness.create(now: DateTime.utc(2026, 9, 23, 23, 30), zone: 'Europe/Paris');
    addTearDown(h.dispose);
    expect(h.read(plannerTodayProvider), LocalDate(2026, 9, 24));
    expect(h.read(plannerNowProvider), at(2026, 9, 24, 1, 30));
  });

  test('provider container type sanity', () {
    expect(ProviderContainer.new, isNotNull);
  });
}
