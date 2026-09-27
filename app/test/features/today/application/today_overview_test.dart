import 'package:everslot/core/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/today/application/day_boundary_ticker.dart';
import 'package:everslot/features/today/application/today_overview_provider.dart';
import 'package:everslot/features/today/domain/day_window.dart';
import 'package:everslot/features/today/domain/today_overview.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../today_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness h;
  tearDown(() => h.dispose());

  /// Reads the overview once every section has loaded.
  Future<TodayOverview> overview({bool Function(TodayOverview o)? where}) => until(
    h.container,
    todayOverviewProvider,
    (o) =>
        !o.isLoading(TodaySection.planner) &&
        !o.isLoading(TodaySection.overdue) &&
        !o.isLoading(TodaySection.habits) &&
        !o.isLoading(TodaySection.checklists) &&
        !o.isLoading(TodaySection.inbox) &&
        (where?.call(o) ?? true),
  );

  test('assembles the day from every section', () async {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 10));
    final today = LocalDate(2026, 9, 22);
    await h.task('Standup', start: at(2026, 9, 22, 9, 30), duration: 60);
    await h.task('Review', start: at(2026, 9, 22, 14));
    await h.task('Holiday', start: at(2026, 9, 22), allDay: true);
    await h.task('Tomorrow', start: at(2026, 9, 23, 8));
    await h.task('Forgotten', start: at(2026, 9, 21, 9));
    await h.habit('Read', start: LocalDate(2026, 9, 1));
    await h.quitTracker('Smoking', quitAt: DateTime.utc(2026, 9, 20, 8), start: LocalDate(2026, 9, 20));
    final pinned = await h.checklist('Groceries', items: ['Milk', 'Eggs', 'Bread'], pinned: true);
    await h.setItemStatus(pinned, await h.itemId(pinned, 'Milk'), ItemStatus.completed);
    await h.setItemFields(pinned, await h.itemId(pinned, 'Eggs'), {'due_local': at(2026, 9, 22, 18)});
    final work = await h.checklist('Work', items: ['Invoice', 'Contract']);
    await h.setItemStatus(
      work,
      await h.itemId(work, 'Contract'),
      ItemStatus.waiting,
      followUpAt: DateTime.utc(2026, 9, 21, 12),
    );

    final o = await overview(where: (o) => (o.habits?.isNotEmpty ?? false) && (o.dueItems?.isNotEmpty ?? false));
    expect(o.date, today);
    expect(o.agenda!.map((i) => i.title), ['Holiday', 'Standup', 'Review']);
    expect(o.upcoming!.map((i) => i.title), ['Tomorrow']);
    expect(o.overdue!.map((i) => i.title), ['Forgotten']);
    expect(o.habits!.single.habit.name, 'Read');
    expect(o.habits!.single.checkInKey, '2026-09-22');
    expect(o.quits!.single.abstinenceStart, DateTime.utc(2026, 9, 20, 8));
    expect(o.quits!.single.nextMilestone?.id, 'day_3');
    expect(o.pinned!.single.title, 'Groceries');
    expect(o.pinned!.single.done, 1);
    expect(o.pinned!.single.total, 3);
    expect(o.dueItems!.map((i) => i.text), ['Eggs']);
    expect(o.followUps!.map((i) => i.text), ['Contract']);
    expect(o.unreadInbox, 0);
    expect(o.errors, isEmpty);
  });

  test('edits update the overview without a manual refresh', () async {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 10));
    await h.task('Write report', start: at(2026, 9, 22, 11));
    var o = await overview(where: (o) => o.agenda!.isNotEmpty);
    final item = o.agenda!.single;
    expect(item.status, OccurrenceStatus.scheduled);

    await h.read(plannerServiceProvider).markDone(item);
    o = await overview(where: (o) => o.agenda!.single.status == OccurrenceStatus.done);
    expect(o.agenda!.single.title, 'Write report');

    final habitId = await h.habit('Stretch', start: LocalDate(2026, 9, 1));
    o = await overview(where: (o) => o.habits!.any((e) => e.habit.id == habitId));
    expect(o.habits!.single.resolved, isFalse);
  });

  test('switches to the new day at local midnight', () async {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 21, 59), zone: 'Europe/Paris');
    await h.task('Late', start: at(2026, 9, 22, 23, 30), duration: 20);
    await h.task('Early', start: at(2026, 9, 23, 7));
    var o = await overview(where: (o) => o.agenda!.isNotEmpty);
    expect(o.date, LocalDate(2026, 9, 22));
    expect(o.agenda!.map((i) => i.title), ['Late']);
    expect(o.upcoming!.map((i) => i.title), ['Early']);

    h.clock.set(DateTime.utc(2026, 9, 22, 22, 0, 30)); // 00:00:30 in Paris
    h.read(todayWindowProvider.notifier).check();
    o = await overview(where: (o) => o.date == LocalDate(2026, 9, 23) && o.agenda!.isNotEmpty);
    expect(o.agenda!.map((i) => i.title), ['Early']);
    expect(o.window.startUtc, DateTime.utc(2026, 9, 22, 22));
  });

  test('a zone change recomputes today for floating vs fixed-zone tasks', () async {
    // 20:00 UTC = 22:00 in Paris (22 Sep) = 08:00 in Auckland (23 Sep, NZST +12).
    h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 20), zone: 'Europe/Paris');
    await h.task('Floating', start: at(2026, 9, 22, 9));
    await h.task('New York call', start: at(2026, 9, 22, 9), zone: 'America/New_York'); // 13:00 UTC
    var o = await overview(where: (o) => o.agenda!.length == 2);
    expect(o.date, LocalDate(2026, 9, 22));
    final ny = o.agenda!.firstWhere((i) => i.title == 'New York call');
    expect(ny.startLocal, at(2026, 9, 22, 15)); // shown in Paris time

    h.read(deviceZoneProvider.notifier).debugSet('Pacific/Auckland');
    o = await overview(where: (o) => o.date == LocalDate(2026, 9, 23));
    // The fixed-zone call keeps its instant: 01:00 on the 23rd in Auckland — today there.
    expect(o.agenda!.map((i) => i.title), ['New York call']);
    expect(o.agenda!.single.startLocal, at(2026, 9, 23, 1));
    // The floating task keeps its wall clock (09:00 on the 22nd): yesterday in Auckland.
    expect(o.overdue!.map((i) => i.title), contains('Floating'));
  });

  test('performance: today with 200 tasks resolves within budget', () async {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6));
    for (var i = 0; i < 200; i++) {
      await h.task(
        'Task $i',
        start: at(2026, 9, 22).plusMinutes(360 + i * 4),
        duration: 15,
        rule: i.isEven ? RecurrenceRule() : null,
      );
    }
    // Warm-up (JIT), then measure the provider chain: range resolution + split + assembly.
    await overview(where: (o) => o.agenda!.length == 200);
    h.read(todayWindowProvider.notifier).check();
    final watch = Stopwatch()..start();
    h.container.invalidate(todayRangeProvider);
    final o = await overview(where: (o) => o.agenda!.length == 200);
    watch.stop();
    expect(o.agenda, hasLength(200));
    // Budget 50 ms in release builds; debug/JIT test runs get headroom.
    expect(watch.elapsedMilliseconds, lessThan(250), reason: 'took ${watch.elapsedMilliseconds} ms');
    // ignore: avoid_print
    print('Today overview with 200 tasks: ${watch.elapsedMilliseconds} ms');
  });

  group('DayBoundaryTicker', () {
    test('fires at the next boundary with the new day, and on check()', () {
      fakeAsync((async) {
        var now = DateTime.utc(2026, 9, 22, 21, 59, 50); // 23:59:50 in Paris
        final zones = TzZoneResolver();
        final seen = <LocalDate>[];
        final ticker = DayBoundaryTicker(
          compute: () => DayWindow.at(now, 'Europe/Paris', zones),
          now: () => now,
          onChange: (w) => seen.add(w.date),
        );
        expect(ticker.start().date, LocalDate(2026, 9, 22));
        now = now.add(const Duration(seconds: 5));
        async.elapse(const Duration(seconds: 5));
        expect(seen, isEmpty);
        now = now.add(const Duration(seconds: 6)); // 00:00:01
        async.elapse(const Duration(seconds: 6));
        expect(seen, [LocalDate(2026, 9, 23)]);
        // The clock jumps (device time changed) → check() re-evaluates at once.
        now = DateTime.utc(2026, 9, 25, 10);
        ticker.check();
        expect(seen.last, LocalDate(2026, 9, 25));
        ticker.dispose();
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('long gaps are re-checked at least hourly', () {
      fakeAsync((async) {
        var now = DateTime.utc(2026, 9, 22, 1);
        final seen = <LocalDate>[];
        final ticker = DayBoundaryTicker(
          compute: () => DayWindow.at(now, 'UTC', TzZoneResolver()),
          now: () => now,
          onChange: (w) => seen.add(w.date),
        )..start();
        expect(async.pendingTimers.single.duration, const Duration(hours: 1));
        now = DateTime.utc(2026, 9, 24, 1);
        async.elapse(const Duration(hours: 1));
        expect(seen, [LocalDate(2026, 9, 24)]);
        ticker.dispose();
      });
    });
  });
}
