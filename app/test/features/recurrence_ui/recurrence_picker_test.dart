import 'package:everslot/features/recurrence_ui/recurrence_ui.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'recurrence_test_support.dart';

void main() {
  late TestHarness h;
  // Tue 2026-09-22 07:00 UTC = 09:00 in Paris.
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 7), zone: 'Europe/Paris'));
  tearDown(() => h.dispose());

  // Anchor: Tuesday 22 Sep 2026, 09:30 (floating).
  final tuesday = RecurrenceAnchor(LocalDateTime.of(2026, 9, 22, 9, 30), null, durationMinutes: 30);

  /// Opens the detailed picker and records its result.
  Future<List<RecurrencePickResult?>> openDetailed(
    WidgetTester tester, {
    RecurrenceRule? initial,
    RecurrenceAnchor? anchor,
    RecurrencePickerMode mode = RecurrencePickerMode.task,
    Locale locale = const Locale('en'),
    bool dark = false,
  }) async {
    final results = <RecurrencePickResult?>[];
    await pumpOpener(
      tester,
      h,
      (context) async => results.add(
        await showRecurrencePickerDetailed(context, anchor: anchor ?? tuesday, initial: initial, mode: mode),
      ),
      locale: locale,
      dark: dark,
    );
    await open(tester);
    return results;
  }

  Finder preset(RecurrencePreset p) => find.byKey(ValueKey('recur-preset-${p.name}'));
  Future<void> done(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('recur-done')));
    await tester.pumpAndSettle();
  }

  String description(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('recur-description'))).data!;

  testWidgets('simple presets are labelled by their description and return their rule', (tester) async {
    final results = await openDetailed(tester);
    expect(find.text('Every day at 09:30'), findsOneWidget);
    expect(find.text('Every weekday at 09:30'), findsOneWidget);
    expect(find.text('Every Tuesday at 09:30'), findsOneWidget);
    expect(find.text('Monthly on the 22nd at 09:30'), findsOneWidget);
    expect(find.text('Monthly on the fourth Tuesday at 09:30'), findsOneWidget);
    expect(find.text('Yearly on September 22 at 09:30'), findsOneWidget);
    expect(description(tester), 'Does not repeat');

    await tapInList(tester, preset(RecurrencePreset.weekdays));
    expect(description(tester), 'Every weekday at 09:30');
    await done(tester);
    final result = results.single!;
    expect(result.rule!.freq, Frequency.weekly);
    expect(result.rule!.byWeekday!.map((w) => w.day), RecurrencePresets.workWeek);
    expect(result.anchor, tuesday);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every monthly/yearly preset returns a valid rule', (tester) async {
    for (final p in [
      RecurrencePreset.daily,
      RecurrencePreset.weekly,
      RecurrencePreset.monthlyOnDay,
      RecurrencePreset.monthlyOnNthWeekday,
      RecurrencePreset.lastDayOfMonth,
      RecurrencePreset.yearly,
    ]) {
      final results = await openDetailed(tester);
      await tapInList(tester, preset(p));
      await done(tester);
      final rule = results.single!.rule!;
      expect(RecurrencePresets.detect(rule, tuesday), p);
      expect(rule.validate(anchor: tuesday).isValid, isTrue);
    }
  });

  testWidgets('last day of month moves the anchor and shows a note', (tester) async {
    final results = await openDetailed(tester);
    await tapInList(tester, preset(RecurrencePreset.lastDayOfMonth));
    expect(find.byKey(const ValueKey('recur-anchor-moved')), findsOneWidget);
    expect(find.textContaining('First occurrence: Wed, Sep 30'), findsOneWidget);
    await done(tester);
    expect(results.single!.anchor.start, LocalDateTime.of(2026, 9, 30, 9, 30));
  });

  testWidgets('Gym every Monday and Tuesday: specific days in a few taps', (tester) async {
    final results = await openDetailed(tester);
    await tapInList(tester, preset(RecurrencePreset.specificDays));
    await tester.tap(find.byKey(const ValueKey('recur-day-MO')));
    await tester.pumpAndSettle();
    expect(description(tester), 'Every Monday and Tuesday at 09:30');
    await done(tester);
    final rule = results.single!.rule!;
    expect(rule.byWeekday, const [WeekdayRule(Weekday.monday), WeekdayRule(Weekday.tuesday)]);
  });

  testWidgets('specific days: no day selected disables Done; picking Mon+Thu moves the anchor', (tester) async {
    final results = await openDetailed(tester);
    await tapInList(tester, preset(RecurrencePreset.specificDays));
    await tester.tap(find.byKey(const ValueKey('recur-day-TU')));
    await tester.pumpAndSettle();
    expect(find.text('Select at least one day'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('recur-done'))).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('recur-day-MO')));
    await tester.tap(find.byKey(const ValueKey('recur-day-TH')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recur-anchor-moved')), findsOneWidget);
    await done(tester);
    expect(results.single!.anchor.start.date, LocalDate(2026, 9, 24));
  });

  testWidgets('Drink water every 90 min 08:00–20:00', (tester) async {
    final results = await openDetailed(tester);
    await tapInList(tester, preset(RecurrencePreset.intraday));
    await tapInList(tester, find.byKey(const ValueKey('recur-step-90')));
    expect(description(tester), 'Every 90 minutes between 08:00 and 20:00');
    await done(tester);
    final rule = results.single!.rule!;
    expect(rule.freq, Frequency.minutely);
    expect(rule.interval, 90);
    expect(rule.window, DailyWindow(LocalTime(8, 0), LocalTime(20, 0)));
    // 09:30 is on the 90-min grid from 08:00 (08:00, 09:30, 11:00…): the start is kept.
    expect(results.single!.anchor.start, LocalDateTime.of(2026, 9, 22, 9, 30));
  });

  testWidgets('every 2 hours 08:00–20:00 from 09:30 starts at 10:00 (anchor note)', (tester) async {
    final results = await openDetailed(tester);
    await tapInList(tester, preset(RecurrencePreset.intraday));
    await tapInList(tester, find.byKey(const ValueKey('recur-step-120')));
    expect(find.byKey(const ValueKey('recur-anchor-moved')), findsOneWidget);
    await done(tester);
    expect(results.single!.rule!.freq, Frequency.hourly);
    expect(results.single!.anchor.start, LocalDateTime.of(2026, 9, 22, 10));
  });

  testWidgets('intraday: custom step and whole-day chain', (tester) async {
    final results = await openDetailed(tester);
    await tapInList(tester, preset(RecurrencePreset.intraday));
    await tester.enterText(find.byKey(const ValueKey('recur-step-minutes')), '45');
    await tester.pumpAndSettle();
    await tapInList(tester, find.byKey(const ValueKey('recur-window-switch')));
    await done(tester);
    final rule = results.single!.rule!;
    expect(rule.interval, 45);
    expect(rule.window, isNull);
  });

  testWidgets('Review every 2 days', (tester) async {
    final results = await openDetailed(tester);
    await tapInList(tester, preset(RecurrencePreset.everyNDays));
    expect(description(tester), 'Every 2 days at 09:30');
    await tester.enterText(find.byKey(const ValueKey('recur-every-days')), '3');
    await tester.pumpAndSettle();
    await done(tester);
    expect(results.single!.rule!.interval, 3);
  });

  testWidgets('several times a day defaults to start and start + 12 h', (tester) async {
    final results = await openDetailed(tester);
    await tapInList(tester, preset(RecurrencePreset.timesPerDay));
    expect(description(tester), 'Every day at 09:30 and 21:30');
    await tapInList(tester, find.byTooltip('Remove 21:30'));
    expect(description(tester), 'Every day at 09:30');
    await done(tester);
    expect(results.single!.rule!.times, [LocalTime(9, 30)]);
  });

  testWidgets('after completion: 3 days', (tester) async {
    final results = await openDetailed(tester);
    await tapInList(tester, preset(RecurrencePreset.afterCompletion));
    await tester.enterText(find.byKey(const ValueKey('recur-after-amount')), '3');
    await tester.pumpAndSettle();
    expect(description(tester), '3 days after completion');
    await done(tester);
    expect(results.single!.rule!.afterCompletion, const AfterCompletion(3, RecurrenceUnit.day));
  });

  testWidgets('ends after N times and on a date', (tester) async {
    final results = await openDetailed(tester);
    await tapInList(tester, preset(RecurrencePreset.daily));
    await tapInList(tester, find.byKey(const ValueKey('recur-ends-afterCount')));
    expect(description(tester), 'Every day at 09:30, 10 times');
    await tester.enterText(find.byKey(const ValueKey('recur-ends-count')), '5');
    await tester.pumpAndSettle();
    await done(tester);
    expect(results.single!.rule!.count, 5);

    final second = await openDetailed(tester, initial: results.single!.rule);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('recur-ends-count')),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const ValueKey('recur-ends-count')), findsOneWidget, reason: 'reopens with its ends');
    await tapInList(tester, find.byKey(const ValueKey('recur-ends-onDate')));
    await done(tester);
    expect(second.single!.rule!.count, isNull);
    expect(second.single!.rule!.until, LocalDateTime.of(2026, 10, 22, 23, 59));
  });

  testWidgets('showRecurrencePicker: "does not repeat" returns null, dismissing returns the initial rule', (
    tester,
  ) async {
    final initial = RecurrenceRule(freq: Frequency.daily);
    final results = <RecurrenceRule?>[];
    await pumpOpener(
      tester,
      h,
      (context) async => results.add(await showRecurrencePicker(context, anchor: tuesday, initial: initial)),
    );
    await open(tester);
    expect(description(tester), 'Every day at 09:30');
    await tapInList(tester, preset(RecurrencePreset.none));
    await done(tester);
    expect(results.single, isNull);

    await open(tester);
    await tester.tap(find.byKey(const ValueKey('recur-cancel')));
    await tester.pumpAndSettle();
    expect(results.last, same(initial));

    await open(tester);
    await done(tester);
    expect(results.last, same(initial), reason: 'Done without changes keeps the exact initial rule');
  });

  testWidgets('habit mode: always repeats, quota preset "3 times a week"', (tester) async {
    final results = await openDetailed(tester, mode: RecurrencePickerMode.habit);
    expect(preset(RecurrencePreset.none), findsNothing);
    expect(description(tester), 'Every day at 09:30', reason: 'habits default to daily');
    await tapInList(tester, preset(RecurrencePreset.quota));
    expect(description(tester), '3 times a week');
    await tapInList(tester, find.byKey(const ValueKey('recur-quota-per-month')));
    await done(tester);
    expect(results.single!.rule!.quota, const Quota(3, PeriodUnit.month));
  });

  testWidgets('checklist reset and reminder modes hide quota and after completion', (tester) async {
    for (final mode in [RecurrencePickerMode.checklistReset, RecurrencePickerMode.reminder]) {
      await openDetailed(tester, mode: mode);
      expect(preset(RecurrencePreset.none), findsOneWidget);
      await tester.scrollUntilVisible(preset(RecurrencePreset.custom), 200, scrollable: find.byType(Scrollable).last);
      expect(preset(RecurrencePreset.afterCompletion), findsNothing);
      expect(preset(RecurrencePreset.quota), findsNothing);
      await tester.tap(find.byKey(const ValueKey('recur-cancel')));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('an existing custom rule is shown as Custom… with its description', (tester) async {
    final rule = RecurrenceRule(freq: Frequency.weekly, interval: 2, byWeekday: const [WeekdayRule(Weekday.tuesday)]);
    await openDetailed(tester, initial: rule);
    expect(description(tester), 'Every 2 weeks on Tuesday at 09:30');
    await tester.scrollUntilVisible(preset(RecurrencePreset.custom), 200, scrollable: find.byType(Scrollable).last);
    final tile = tester.widget<RadioListTile<RecurrencePreset>>(preset(RecurrencePreset.custom));
    expect((tile.subtitle! as Text).data, 'Every 2 weeks on Tuesday at 09:30');
  });

  testWidgets('Custom… opens the advanced editor; saving there closes the sheet', (tester) async {
    final results = await openDetailed(tester, initial: RecurrenceRule(freq: Frequency.daily));
    await tapInList(tester, preset(RecurrencePreset.custom));
    expect(find.text('Custom repeat'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('recur-interval')), '4');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recur-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recur-done')), findsNothing, reason: 'sheet closed');
    expect(results.single!.rule!.interval, 4);
  });

  testWidgets('Arabic RTL: labels are localized and the sheet lays out without overflow', (tester) async {
    final results = await openDetailed(tester, locale: const Locale('ar'));
    expect(find.text('لا يتكرر'), findsWidgets);
    expect(Directionality.of(tester.element(preset(RecurrencePreset.daily))), TextDirection.rtl);
    await tapInList(tester, preset(RecurrencePreset.specificDays));
    await tester.tap(find.byKey(const ValueKey('recur-day-MO')));
    await tester.pumpAndSettle();
    expect(description(tester), 'أسبوعيًا يومي الاثنين والثلاثاء في الساعة 09:30');
    await tapInList(tester, find.byKey(const ValueKey('recur-ends-afterCount')));
    expect(tester.takeException(), isNull);
    await done(tester);
    expect(results.single!.rule!.count, 10);
  });

  testWidgets('dark theme and text scale 2.0 lay out without overflow (EN and AR)', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final locale in const [Locale('en'), Locale('ar')]) {
      await openDetailed(tester, locale: locale, dark: true, mode: RecurrencePickerMode.habit);
      await tapInList(tester, preset(RecurrencePreset.intraday));
      await tapInList(tester, preset(RecurrencePreset.quota));
      await tapInList(tester, preset(RecurrencePreset.afterCompletion));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('recur-cancel')));
      await tester.pumpAndSettle();
    }
  });
}
