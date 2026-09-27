import 'package:everslot/features/planner/application/planner_providers.dart' show RunningTimer;
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planning_rules.dart';
import 'package:everslot/features/planner/presentation/running_timer_chip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Running-timer chip (T3.2.19): hidden when idle, title + live elapsed, +N under the
/// `multiple` policy, tap opens the occurrence.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 9)));
  tearDown(() => h.dispose());

  Finder chip() => find.byKey(const ValueKey('running-timer-chip'));

  testWidgets('hidden when no timer runs; shows the running timer; tap opens it', (tester) async {
    RunningTimer? opened;
    await pumpInApp(
      tester,
      h,
      Scaffold(
        appBar: AppBar(actions: [RunningTimerChip(onOpen: (_, t) => opened = t)]),
      ),
    );
    await settle(tester);
    expect(chip(), findsNothing);

    final id = (await tester.runAsync(() async {
      final id = await h.createTask(title: 'Deep work', start: '2026-09-22T09:00', mode: TrackingMode.timer);
      await h.occurrences.start(id, '2026-09-22T09:00');
      return id;
    }))!;
    h.clock.advance(const Duration(minutes: 3, seconds: 5));
    await settle(tester);
    expect(chip(), findsOneWidget);
    expect(find.text('Deep work'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('03:0'), findsOneWidget);

    await tester.tap(chip());
    await pumpFor(tester);
    expect(opened!.entry.taskId, id);
    expect(opened!.entry.occurrenceKey, '2026-09-22T09:00');

    // Stopping the timer hides the chip.
    await tester.runAsync(() => h.occurrences.stop(id, '2026-09-22T09:00'));
    await settle(tester);
    expect(chip(), findsNothing);
  });

  testWidgets('single policy pauses the previous timer; multiple keeps both (+1)', (tester) async {
    // Timers are seeded before the chip subscribes (test 1 covers live updates).
    await tester.runAsync(() async {
      final a = await h.createTask(title: 'A', start: '2026-09-22T09:00', mode: TrackingMode.timer);
      final b = await h.createTask(title: 'B', start: '2026-09-22T09:30', mode: TrackingMode.timer);
      await h.occurrences.start(a, '2026-09-22T09:00');
      h.clock.advance(const Duration(minutes: 1));
      await h.occurrences.start(b, '2026-09-22T09:30');
      // A direct query: a watch stream here would share the widget's (FakeAsync) stream.
      final running = await h.db
          .customSelect('SELECT COUNT(*) AS c FROM time_entries WHERE ended_at IS NULL AND deleted_at IS NULL')
          .getSingle();
      expect(running.read<int>('c'), 1, reason: 'the single policy paused A');
      h.clock.advance(const Duration(minutes: 1));
      await h.occurrences.start(a, '2026-09-22T09:00', policy: TimerPolicy.multiple);
    });
    await pumpInApp(tester, h, const Scaffold(body: Center(child: RunningTimerChip())));
    await settle(tester);
    expect(find.text('A'), findsOneWidget, reason: 'the most recently started timer');
    expect(find.text(' +1'), findsOneWidget);
  });
}
