import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// T1.3.11: pickers — typed times in 12/24 h, wheels, week-start-aware dates with quick chips,
/// localized durations, time ranges across midnight, custom colors with a contrast warning.
void main() {
  group('parseTimeInput', () {
    const ok = <String, (int, int)>{
      '07:03': (7, 3),
      '7:03': (7, 3),
      '703': (7, 3),
      '0703': (7, 3),
      '7.03': (7, 3),
      '7h03': (7, 3),
      '19': (19, 0),
      '0': (0, 0),
      '23:59': (23, 59),
      '7:03 pm': (19, 3),
      '7:03PM': (19, 3),
      '7pm': (19, 0),
      '12am': (0, 0),
      '12 p.m.': (12, 0),
      '١٩:٠٥': (19, 5),
      '7 م': (19, 0),
      '7 ص': (7, 0),
    };
    for (final e in ok.entries) {
      test('"${e.key}"', () => expect(parseTimeInput(e.key), LocalTime(e.value.$1, e.value.$2)));
    }
    for (final bad in ['', 'abc', '24:00', '7:60', '13pm', '0am', '12345', '7:3', ':30']) {
      test('rejects "$bad"', () => expect(parseTimeInput(bad), isNull));
    }
    test('format round-trips', () {
      for (final t in [LocalTime(0, 0), LocalTime(7, 3), LocalTime(12, 0), LocalTime(23, 59)]) {
        expect(parseTimeInput(formatTimeInput(t, use24h: true)), t);
        expect(parseTimeInput(formatTimeInput(t, use24h: false)), t);
      }
      expect(formatTimeInput(LocalTime(19, 3), use24h: false), '7:03 PM');
      expect(formatTimeInput(LocalTime(0, 5), use24h: false), '12:05 AM');
      expect(formatTimeInput(LocalTime(7, 3), use24h: true), '07:03');
    });
  });

  test('parseHexColor', () {
    expect(parseHexColor('#3B82F6'), 0xFF3B82F6);
    expect(parseHexColor('3b82f6'), 0xFF3B82F6);
    expect(parseHexColor('#3B82F'), isNull);
    expect(parseHexColor('zzzzzz'), isNull);
  });

  /// Pumps a button that runs [open] and keeps its result.
  Future<List<Object?>> host(
    WidgetTester tester,
    Future<Object?> Function(BuildContext) open, {
    String locale = 'en',
  }) async {
    final results = <Object?>[];
    tester.view
      ..physicalSize = const Size(500, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () async => results.add(await open(context)), child: const Text('open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  group('pickTime', () {
    for (final use24h in [true, false]) {
      testWidgets('typing 07:03 works (${use24h ? 24 : 12} h)', (tester) async {
        final r = await host(tester, (c) => pickTime(c, initial: LocalTime(9, 0), use24h: use24h));
        await tester.enterText(find.byKey(const ValueKey('time-input')), '07:03');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('time-apply')));
        await tester.pumpAndSettle();
        expect(r, [LocalTime(7, 3)]);
      });
    }

    testWidgets('12 h: "7:03 pm" is 19:03; an invalid entry blocks Apply', (tester) async {
      final r = await host(tester, (c) => pickTime(c, initial: LocalTime(9, 0), use24h: false));
      expect(find.text('9:00 AM'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('time-input')), '25:99');
      await tester.pumpAndSettle();
      expect(find.text('Enter a time like 07:03'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const ValueKey('time-apply'))).onPressed, isNull);
      await tester.enterText(find.byKey(const ValueKey('time-input')), '7:03 pm');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('time-apply')));
      await tester.pumpAndSettle();
      expect(r, [LocalTime(19, 3)]);
    });

    testWidgets('scrolling the minute wheel moves one minute at a time and updates the field', (tester) async {
      final r = await host(tester, (c) => pickTime(c, initial: LocalTime(9, 0), use24h: true));
      await tester.drag(find.byKey(const ValueKey('wheel-minutes')), const Offset(0, -40 * 3));
      await tester.pumpAndSettle();
      expect(find.text('09:03'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('time-apply')));
      await tester.pumpAndSettle();
      expect(r, [LocalTime(9, 3)]);
    });
  });

  group('pickDate', () {
    testWidgets('the grid starts on the week start; quick chips and days return dates', (tester) async {
      final r = await host(tester, (c) => pickDate(c, initial: LocalDate(2026, 10, 14), weekStart: Weekday.sunday));
      final headers = tester.widgetList<Text>(find.descendant(of: find.byType(Row), matching: find.byType(Text)));
      expect(headers.map((t) => t.data), containsAllInOrder(['Sun', 'Mon', 'Tue']));
      expect(find.text('October 2026'), findsOneWidget);
      // 1 Oct 2026 is a Thursday → the grid starts on Sunday 27 Sep.
      expect(find.byKey(const ValueKey('date-2026-09-27')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('date-2026-10-20')));
      await tester.pumpAndSettle();
      expect(r, [LocalDate(2026, 10, 20)]);
    });

    testWidgets('Monday week start, month navigation and range limits', (tester) async {
      final r = await host(
        tester,
        (c) => pickDate(
          c,
          initial: LocalDate(2026, 10, 14),
          weekStart: Weekday.monday,
          first: LocalDate(2026, 10, 10),
          last: LocalDate(2026, 11, 30),
        ),
      );
      expect(find.byKey(const ValueKey('date-2026-09-28')), findsOneWidget, reason: 'Monday before 1 Oct');
      await tester.tap(find.byKey(const ValueKey('date-2026-10-05')));
      await tester.pumpAndSettle();
      expect(r, isEmpty, reason: 'before `first`: disabled');
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left)).onPressed, isNull);
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right)).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('date-2026-11-02')));
      await tester.pumpAndSettle();
      expect(r, [LocalDate(2026, 11, 2)]);
    });

    testWidgets('day cells are labelled for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await host(tester, (c) => pickDate(c, initial: LocalDate(2026, 10, 14)));
      expect(find.bySemanticsLabel('Wednesday, October 14'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('quick chip "Tomorrow" returns the day after today', (tester) async {
      final r = await host(tester, pickDate);
      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();
      final now = DateTime.now();
      expect(r, [LocalDate(now.year, now.month, now.day).plusDays(1)]);
    });
  });

  group('pickDuration', () {
    testWidgets('presets are labelled per locale and steppers add minutes', (tester) async {
      final r = await host(tester, (c) => pickDuration(c, initialMinutes: 30), locale: 'fr');
      expect(find.byKey(const ValueKey('duration-90')), findsOneWidget);
      final fr = lookupAppLocalizations(const Locale('fr'));
      expect(find.text(fr.durationHoursMinutesShort(1, 30)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('duration-90')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('${fr.pickerMinutes} +1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('duration-apply')));
      await tester.pumpAndSettle();
      expect(r, [91]);
    });
  });

  group('pickTimeRange', () {
    testWidgets('a duration preset or an end time sets the length; ends after midnight wrap', (tester) async {
      final r = await host(tester, (c) => pickTimeRange(c, start: LocalTime(23, 0), minutes: 30, use24h: true));
      expect(find.text('23:30'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('range-end')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('time-input')), '01:15');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('time-apply')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('range-apply')));
      await tester.pumpAndSettle();
      expect(r, [(start: LocalTime(23, 0), minutes: 135)]);
    });
  });

  group('pickColor', () {
    testWidgets('custom hex with a low-contrast warning; palette taps return at once', (tester) async {
      final r = await host(tester, pickColor);
      await tester.enterText(find.byKey(const ValueKey('color-hex')), 'FFF9C4');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('color-low-contrast')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('color-hex')), '1D4ED8');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('color-low-contrast')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('color-apply')));
      await tester.pumpAndSettle();
      expect(r, [0xFF1D4ED8]);
    });

    testWidgets('an invalid hex disables Apply', (tester) async {
      await host(tester, pickColor);
      await tester.enterText(find.byKey(const ValueKey('color-hex')), '12');
      await tester.pumpAndSettle();
      expect(find.text('Use 6 hex digits, like 3B82F6'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const ValueKey('color-apply'))).onPressed, isNull);
    });
  });
}
