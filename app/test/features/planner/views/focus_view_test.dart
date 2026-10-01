import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/view_config/checklist_steps.dart';
import 'package:everslot/features/planner/application/view_config/screen_awake.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/focus_view.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fake_view_actions.dart';
import 'support/items.dart';
import 'support/planner_harness.dart';

class _FakeChecklistActions implements ChecklistStepActions {
  final calls = <String>[];

  @override
  Future<void> setDone(String checklistId, String itemId, {required bool done}) async =>
      calls.add('done $checklistId $itemId $done');

  @override
  Future<void> completeMany(String checklistId, Iterable<String> itemIds) async =>
      calls.add('many $checklistId ${itemIds.join(',')}');
}

class _FakeAwake implements ScreenAwake {
  final calls = <bool>[];

  @override
  Future<void> keepOn({required bool on}) async => calls.add(on);
}

// Now / Next focus view (T3.7.01). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  test('focus clock formats minutes:seconds, hours and the seconds-free reduced-motion face', () {
    expect(focusClock(const Duration(minutes: 5, seconds: 7)), '05:07');
    expect(focusClock(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    expect(focusClock(const Duration(minutes: -3)), '00:00');
    expect(focusClock(const Duration(minutes: 30), seconds: false), '0:30');
    expect(focusClock(const Duration(hours: 2, minutes: 5), seconds: false), '2:05');
  });

  final deep = item(
    'Deep work',
    at(2026, 9, 23, 9),
    60,
    id: 'dw',
    trackingMode: TrackingMode.timer,
    notes: 'No email, phone away',
  );
  final lunch = item('Lunch', at(2026, 9, 23, 12), 60, id: 'lunch');

  Future<({PlannerHarness h, FakeViewActions extra})> pump(
    WidgetTester tester, {
    List<PlannerItem>? items,
    List<Override> overrides = const [],
    DateTime? now,
    Widget Function(Widget child)? wrap,
  }) async {
    final extra = FakeViewActions();
    final h = PlannerHarness.create(
      items: items ?? [deep, lunch],
      now: now,
      overrides: [viewExtraActionsProvider.overrideWithValue(extra), ...overrides],
    );
    addTearDown(h.dispose);
    const screen = PlannerScreen(view: 'focus');
    await pumpPlanner(tester, h, wrap == null ? screen : wrap(screen));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(); // streams subscribed during the first frames deliver their first value
    return (h: h, extra: extra);
  }

  String clock(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('focus-clock'))).data!;

  testWidgets('shows the current item with time left, elapsed time and a next-up countdown', (tester) async {
    await pump(tester);
    expect(find.text('Deep work'), findsOneWidget);
    expect(clock(tester), '30:00');
    expect(find.text('30 min left'), findsOneWidget);
    expect(find.text('30 min elapsed'), findsOneWidget, reason: 'no tracked entries yet: time since the planned start');
    expect(find.text('No email, phone away'), findsOneWidget);
    expect(find.byKey(const Key('focus-next-card')), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('focus-next-clock'))).data, '2:30:00');
  });

  testWidgets('the countdown follows the clock', (tester) async {
    final r = await pump(tester);
    r.h.clock.advance(const Duration(minutes: 1, seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(clock(tester), '28:59');
  });

  testWidgets('a running item past its planned end keeps the focus and counts overtime up', (tester) async {
    final running = item(
      'Deep work',
      at(2026, 9, 23, 9),
      60,
      id: 'dw',
      trackingMode: TrackingMode.timer,
      status: OccurrenceStatus.inProgress,
    );
    final r = await pump(tester, items: [running]);
    r.h.clock.set(DateTime.utc(2026, 9, 23, 10, 2));
    await tester.pump(const Duration(seconds: 1));
    expect(clock(tester), '+02:00', reason: 'overtime counts up');
    expect(find.textContaining('Overran 2 min'), findsOneWidget);
  });

  testWidgets('reopening later shows the right remaining and elapsed time (state comes from clock and data)', (
    tester,
  ) async {
    await pump(
      tester,
      now: DateTime.utc(2026, 9, 23, 9, 45),
      overrides: [
        timeEntriesProvider.overrideWith(
          (ref, o) => Stream.value([
            TimeEntry(
              id: 'e1',
              taskId: 'dw',
              occurrenceKey: o.key,
              startedAt: DateTime.utc(2026, 9, 23, 9),
              endedAt: DateTime.utc(2026, 9, 23, 9, 10),
            ),
            TimeEntry(id: 'e2', taskId: 'dw', occurrenceKey: o.key, startedAt: DateTime.utc(2026, 9, 23, 9, 30)),
          ]),
        ),
      ],
    );
    expect(clock(tester), '15:00');
    expect(find.text('25 min elapsed'), findsOneWidget, reason: '10 min stopped + 15 min running');
    expect(find.byKey(const Key('focus-pause')), findsOneWidget, reason: 'a timer is running');
    expect(find.byKey(const Key('focus-start')), findsNothing);
    expect(find.byKey(const Key('focus-stop')), findsOneWidget);
  });

  testWidgets('start, pause and stop drive the timer of a timer item', (tester) async {
    final r = await pump(tester);
    await tester.tap(find.byKey(const Key('focus-start')));
    await tester.pump();
    expect(r.extra.calls, ['start Deep work']);
    expect(find.byKey(const Key('focus-stop')), findsNothing, reason: 'nothing tracked yet');
  });

  testWidgets('extend +15 writes one reschedule of this occurrence only and the countdown grows', (tester) async {
    final r = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('focus-extend-15')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(r.h.backend.calls, ['reschedule Deep work 2026-09-23T09:00 75 allDay=false thisOccurrence']);
    await tester.pump(const Duration(seconds: 1));
    expect(clock(tester), '45:00');
    expect(find.text('Extended by 15 min'), findsOneWidget);
  });

  testWidgets('done marks the occurrence done and the focus moves on to nothing-now with the next card', (
    tester,
  ) async {
    final r = await pump(tester);
    await tester.tap(find.byKey(const Key('focus-done')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(r.h.backend.calls, ['status Deep work done']);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('focus-nothing')), findsOneWidget);
    expect(find.text('Nothing scheduled right now'), findsOneWidget);
    expect(find.byKey(const Key('focus-next-card')), findsOneWidget);
  });

  testWidgets('skip skips; next pins the following occurrence with its own start countdown', (tester) async {
    final r = await pump(tester);
    await tester.tap(find.byKey(const Key('focus-next')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('focus-current-lunch|2026-09-23T12:00')), findsOneWidget);
    expect(clock(tester), '2:30:00', reason: 'not started yet: counts down to the start');
    expect(find.text('Starts at 12:00'), findsWidgets);
    expect(find.byKey(const Key('focus-next-card')), findsNothing, reason: 'nothing follows lunch');
    await tester.tap(find.byKey(const Key('focus-skip')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(r.h.backend.calls, ['status Lunch skipped']);
    await tester.pump(const Duration(seconds: 5)); // let the snackbar time out
  });

  testWidgets('the linked checklist is tickable inline', (tester) async {
    final actions = _FakeChecklistActions();
    await pump(
      tester,
      items: [item('Deep work', at(2026, 9, 23, 9), 60, id: 'dw', linkedChecklistId: 'cl1')],
      overrides: [
        checklistStepsProvider.overrideWith(
          (ref, q) => const [
            ChecklistStep(id: 's1', text: 'Open the doc', done: false),
            ChecklistStep(id: 's2', text: 'Write intro', done: true),
          ],
        ),
        checklistStepActionsProvider.overrideWithValue(actions),
      ],
    );
    expect(find.byKey(const Key('focus-checklist')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('focus-step-s1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('focus-step-s2')));
    await tester.pump();
    expect(actions.calls, ['done cl1 s1 true', 'done cl1 s2 false']);
  });

  testWidgets('nothing on now: an empty state plus the next occurrence', (tester) async {
    await pump(tester, items: [lunch]);
    expect(find.text('Nothing scheduled right now'), findsOneWidget);
    expect(find.byKey(const Key('focus-next-card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('focus-next-card')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('focus-nothing')), findsNothing, reason: 'tapping the card focuses it');
  });

  testWidgets('reduced motion hides seconds and slows the ticker to 15 s', (tester) async {
    await pump(
      tester,
      wrap: (child) => Builder(
        builder: (context) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child),
      ),
    );
    expect(clock(tester), '0:30');
  });

  testWidgets('keep screen on toggles the wake lock adapter and is released on leaving', (tester) async {
    final awake = _FakeAwake();
    final r = await pump(tester, overrides: [screenAwakeProvider.overrideWithValue(awake)]);
    await tester.tap(find.byKey(const Key('focus-keep-awake')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(awake.calls, [true]);
    expect(r.h.read(plannerViewConfigProvider('focus')).option<bool>('keepScreenOn', false), isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(awake.calls, [true, false]);
  });
}
