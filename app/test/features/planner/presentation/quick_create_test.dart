import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/quick_create_sheet.dart';
import 'package:everslot/features/planner/presentation/task_editor_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Quick-create sheet (T3.1.08): slot-derived defaults, *Add*, *Add & new*, *More options*.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 21, 6)));
  tearDown(() => h.dispose());

  Finder key(String k) => find.byKey(ValueKey(k));

  Future<void> openQuick(
    WidgetTester tester, {
    String? tapped,
    int? slotMinutes,
    int? rangeMinutes,
    Locale locale = const Locale('en'),
  }) async {
    await pumpOpener(
      tester,
      h,
      (context) => showQuickCreateSheet(
        context,
        tapped: tapped == null ? null : ldt(tapped),
        slotMinutes: slotMinutes,
        rangeMinutes: rangeMinutes,
      ),
      locale: locale,
    );
    await openAndSettle(tester);
  }

  Future<List<Task>> tasks(WidgetTester tester) async {
    final all = (await tester.runAsync(h.liveTasks))!;
    return all..sort((a, b) => a.startLocal!.compareTo(b.startLocal!));
  }

  testWidgets('tap at 09:00 on a 30-min grid creates 09:00–09:30 and closes', (tester) async {
    await openQuick(tester, tapped: '2026-09-21T09:00', slotMinutes: 30);
    await tester.enterText(key('quick-title'), 'Call mum');
    await tester.tap(key('quick-add'));
    await settle(tester);
    final t = (await tasks(tester)).single;
    expect(t.title, 'Call mum');
    expect(t.startLocal, ldt('2026-09-21T09:00'));
    expect(t.durationMinutes, 30);
    expect(find.byType(QuickCreateSheet), findsNothing);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('a 2-h grid snaps to the slot start with the default duration', (tester) async {
    await openQuick(tester, tapped: '2026-09-21T09:00', slotMinutes: 120);
    await tester.enterText(key('quick-title'), 'Plan');
    await tester.tap(key('quick-add'));
    await settle(tester);
    final t = (await tasks(tester)).single;
    expect(t.startLocal, ldt('2026-09-21T08:00'));
    expect(t.durationMinutes, 30);
  });

  testWidgets('Add & new keeps the sheet open with the next slot prefilled', (tester) async {
    await openQuick(tester, tapped: '2026-09-21T09:00', slotMinutes: 30);
    await tester.enterText(key('quick-title'), 'First');
    await tester.tap(key('quick-add-new'));
    await settle(tester);
    expect(find.byType(QuickCreateSheet), findsOneWidget);
    expect(tester.widget<TextField>(key('quick-title')).controller!.text, isEmpty);
    await tester.enterText(key('quick-title'), 'Second');
    await tester.tap(key('quick-add'));
    await settle(tester);
    final all = await tasks(tester);
    expect(all.map((t) => t.title), ['First', 'Second']);
    expect(all.last.startLocal, ldt('2026-09-21T09:30'));
    expect(all.last.durationMinutes, 30);
  });

  testWidgets('a day in week-list mode gives an all-day task', (tester) async {
    await openQuick(tester, tapped: '2026-09-23T00:00', slotMinutes: 1440);
    await tester.enterText(key('quick-title'), 'Birthday');
    await tester.tap(key('quick-add'));
    await settle(tester);
    final t = (await tasks(tester)).single;
    expect(t.isAllDay, isTrue);
    expect(t.startLocal, ldt('2026-09-23T00:00'));
  });

  testWidgets('More options opens the full editor prefilled; nothing is saved yet', (tester) async {
    await openQuick(tester, tapped: '2026-09-21T14:00', rangeMinutes: 90);
    await tester.enterText(key('quick-title'), 'Workshop');
    await tester.tap(key('quick-more'));
    await settle(tester);
    expect(find.byType(TaskEditorScreen), findsOneWidget);
    final editor = tester.widget<TaskEditorScreen>(find.byType(TaskEditorScreen));
    expect(editor.initialStart, '2026-09-21T14:00');
    expect(editor.initialDurationMinutes, 90);
    expect(editor.initialTitle, 'Workshop');
    expect(await tasks(tester), isEmpty);
  });

  testWidgets('Arabic RTL and text scale 2.0 lay out without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openQuick(tester, tapped: '2026-09-21T09:00', slotMinutes: 30, locale: const Locale('ar'));
    expect(key('quick-title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
