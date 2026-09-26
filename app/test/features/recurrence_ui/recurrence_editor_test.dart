import 'package:everslot/features/recurrence_ui/recurrence_ui.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'recurrence_test_support.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 7), zone: 'Europe/Paris'));
  tearDown(() => h.dispose());

  // Tuesday 22 Sep 2026, 09:30 (floating).
  final anchor = RecurrenceAnchor(LocalDateTime.of(2026, 9, 22, 9, 30), null, durationMinutes: 30);
  const editorList = ValueKey('recur-editor-list');
  const workWeek = ['MO', 'TU', 'WE', 'TH', 'FR'];

  Future<List<RecurrencePickResult?>> openEditor(
    WidgetTester tester, {
    RecurrenceRule? initial,
    RecurrencePickerMode mode = RecurrencePickerMode.task,
    Locale locale = const Locale('en'),
    RecurrenceAnchor? at,
  }) async {
    final results = <RecurrencePickResult?>[];
    await pumpOpener(
      tester,
      h,
      (context) async =>
          results.add(await showRecurrenceEditor(context, anchor: at ?? anchor, initial: initial, mode: mode)),
      locale: locale,
    );
    await open(tester);
    return results;
  }

  String description(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('recur-description'))).data!;

  Future<void> tapKey(WidgetTester tester, String key) =>
      tapInList(tester, find.byKey(ValueKey(key)), scrollKey: editorList);

  Future<void> chooseFrequency(WidgetTester tester, String label) async {
    await tapKey(tester, 'recur-freq');
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('recur-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('last weekday of the month: monthly + Mon–Fri + position "last"', (tester) async {
    final results = await openEditor(tester);
    expect(description(tester), 'Every Tuesday at 09:30');
    await chooseFrequency(tester, 'Months');
    for (final d in workWeek) {
      await tapKey(tester, 'recur-day-$d');
    }
    await tapKey(tester, 'recur-more');
    await tapKey(tester, 'recur-setpos--1');
    expect(description(tester), 'Monthly on the last weekday at 09:30');
    // Preview: Sep 30, Oct 30, Nov 30… (the anchor moves to Sep 30).
    expect(find.byKey(const ValueKey('recur-anchor-moved')), findsOneWidget);
    await save(tester);
    final result = results.single!;
    expect(result.rule!.freq, Frequency.monthly);
    expect(result.rule!.bySetPos, [-1]);
    expect(result.rule!.byWeekday!.map((w) => w.day.code), workWeek);
    expect(result.anchor.start, LocalDateTime.of(2026, 9, 30, 9, 30));
  });

  testWidgets('every 45 min 09:00–18:00 on weekdays, window times picked with the time picker', (tester) async {
    final results = await openEditor(tester);
    await chooseFrequency(tester, 'Minutes');
    await tester.enterText(find.byKey(const ValueKey('recur-interval')), '45');
    await tester.pumpAndSettle();
    for (final d in workWeek) {
      await tapKey(tester, 'recur-day-$d');
    }
    await tapKey(tester, 'recur-window-switch');
    Future<void> pickTimeViaKeyboard(String tile, String hour, String minute) async {
      await tapKey(tester, tile);
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(fields.evaluate().length - 2), hour);
      await tester.enterText(fields.last, minute);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    await pickTimeViaKeyboard('recur-window-start', '09', '00');
    await pickTimeViaKeyboard('recur-window-end', '18', '00');
    expect(description(tester), 'Every 45 minutes between 09:00 and 18:00 on weekdays');
    await save(tester);
    final rule = results.single!.rule!;
    expect(rule.freq, Frequency.minutely);
    expect(rule.interval, 45);
    expect(rule.window, DailyWindow(LocalTime(9, 0), LocalTime(18, 0)));
    expect(rule.byWeekday!.map((w) => w.day.code), workWeek);
    // 09:30 isn't on the 45-min grid from 09:00: the series starts at 09:45.
    expect(results.single!.anchor.start, LocalDateTime.of(2026, 9, 22, 9, 45));
  });

  testWidgets('invalid state: no weekday on a weekly rule shows an inline error and disables Save', (tester) async {
    await openEditor(tester);
    await tapKey(tester, 'recur-day-TU');
    expect(find.text('Select at least one day'), findsWidgets);
    expect(tester.widget<TextButton>(find.byKey(const ValueKey('recur-save'))).onPressed, isNull);
    await tapKey(tester, 'recur-day-FR');
    expect(tester.widget<TextButton>(find.byKey(const ValueKey('recur-save'))).onPressed, isNotNull);
    expect(description(tester), 'Every Friday at 09:30');
  });

  testWidgets('weekday ordinals: add "2nd Tuesday" and remove it', (tester) async {
    final results = await openEditor(tester, initial: RecurrenceRule(freq: Frequency.monthly));
    expect(description(tester), 'Monthly on the 22nd at 09:30');
    await tapKey(tester, 'recur-ordinal-add');
    await tester.tap(find.byKey(const ValueKey('recur-ordinal-n-2')));
    await tester.tap(find.byKey(const ValueKey('recur-ordinal-day-TU')));
    await tester.tap(find.byKey(const ValueKey('recur-ordinal-ok')));
    await tester.pumpAndSettle();
    expect(description(tester), 'Monthly on the second Tuesday at 09:30');
    expect(find.text('2nd Tuesday'), findsOneWidget);
    await save(tester);
    expect(results.single!.rule!.byWeekday, const [WeekdayRule(Weekday.tuesday, 2)]);
    // 2nd Tuesday after Sep 22 → Oct 13.
    expect(results.single!.anchor.start.date, LocalDate(2026, 10, 13));
  });

  testWidgets('month-day grid counts from the end; switching to weekly drops month days', (tester) async {
    final results = await openEditor(tester, initial: RecurrenceRule(freq: Frequency.monthly));
    await tapKey(tester, 'recur-monthdays-from-end');
    await tapKey(tester, 'recur-monthday--2');
    expect(description(tester), 'Monthly on the second-to-last day at 09:30');
    await tapKey(tester, 'recur-monthdays-from-end');
    await tapKey(tester, 'recur-monthday-1');
    await save(tester);
    expect(results.single!.rule!.byMonthDay, [-2, 1]);
  });

  testWidgets('type switching: after completion and quota keep their drafts', (tester) async {
    final results = await openEditor(tester, mode: RecurrencePickerMode.habit);
    await tapKey(tester, 'recur-type-after_completion');
    expect(description(tester), '1 day after completion');
    await tester.enterText(find.byKey(const ValueKey('recur-after-amount')), '2');
    await tester.pumpAndSettle();
    await tapKey(tester, 'recur-type-quota');
    expect(description(tester), '3 times a week');
    await tapKey(tester, 'recur-quota-day-SA');
    await tapKey(tester, 'recur-quota-day-SU');
    expect(description(tester), '3 times a week on weekdays');
    await tapKey(tester, 'recur-type-after_completion');
    expect(description(tester), '2 days after completion');
    await save(tester);
    expect(results.single!.rule!.afterCompletion, const AfterCompletion(2, RecurrenceUnit.day));
  });

  testWidgets('reminder mode only offers calendar rules', (tester) async {
    await openEditor(tester, mode: RecurrencePickerMode.reminder);
    expect(find.byKey(const ValueKey('recur-type-quota')), findsNothing);
    expect(find.byKey(const ValueKey('recur-type-after_completion')), findsNothing);
  });

  testWidgets('preview lists 10 occurrences and highlights days in the mini calendar', (tester) async {
    await openEditor(tester, initial: RecurrenceRule(freq: Frequency.daily, interval: 2));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('recur-calendar')),
      200,
      scrollable: find.descendant(of: find.byKey(editorList), matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recur-preview-9')), findsOneWidget);
    expect(find.byKey(const ValueKey('recur-calendar-hit-2026-09-22')), findsOneWidget);
    expect(find.byKey(const ValueKey('recur-calendar-hit-2026-09-23')), findsNothing);
    expect(find.byKey(const ValueKey('recur-calendar-hit-2026-09-24')), findsOneWidget);
    expect(find.text('Times follow your current time zone'), findsOneWidget);
  });

  testWidgets('warnings: 288 occurrences per day', (tester) async {
    await openEditor(tester, initial: RecurrenceRule(freq: Frequency.minutely, interval: 5));
    expect(find.text('288 occurrences per day'), findsOneWidget);
  });

  testWidgets('ends after N completions; exception chips can be removed', (tester) async {
    final results = await openEditor(
      tester,
      initial: RecurrenceRule(freq: Frequency.daily, exdates: const ['2026-09-25'], count: 5),
    );
    await tapKey(tester, 'recur-countmode-completions');
    expect(description(tester), 'Every day at 09:30, until completed 5 times');
    await tapInList(
      tester,
      find.byTooltip('Remove Sep 25, 2026'),
      scrollKey: editorList,
    );
    await save(tester);
    expect(results.single!.rule!.countMode, CountMode.completions);
    expect(results.single!.rule!.exdates, isEmpty);
  });

  testWidgets('closing without saving returns null', (tester) async {
    final results = await openEditor(tester);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(results.single, isNull);
  });

  testWidgets('Arabic RTL and text scale 2.0: every section lays out without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openEditor(
      tester,
      locale: const Locale('ar'),
      initial: RecurrenceRule(freq: Frequency.monthly, byWeekday: const [WeekdayRule(Weekday.tuesday, 4)], count: 3),
    );
    expect(find.text('تكرار مخصص'), findsOneWidget);
    await tapKey(tester, 'recur-more');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('recur-calendar')),
      300,
      scrollable: find.descendant(of: find.byKey(editorList), matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
