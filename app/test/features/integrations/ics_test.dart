import 'dart:io';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/integrations/application/ics_service.dart';
import 'package:everslot/features/integrations/domain/ics.dart';
import 'package:everslot/features/integrations/domain/ics_mapping.dart';
import 'package:everslot/features/integrations/presentation/ics_ui.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../today/today_test_support.dart';

String fixture(String name) => File('test/features/integrations/fixtures/ics/$name').readAsStringSync();

/// T8.2.11 / T8.2.12: ICS export and import.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IcsParser — real exports', () {
    test('Google: weekly series with EXDATE, a moved occurrence, all-day and UTC events, reminders', () {
      final r = IcsParser.parse(fixture('google.ics'));
      expect(r.calendarName, 'Work');
      final standup = r.events.firstWhere((e) => e.summary == 'Standup');
      expect(standup.start, LocalDateTime.of(2026, 9, 21, 9, 30));
      expect((standup.timeZone, standup.durationMinutes), ('Europe/Paris', 30));
      expect(standup.description, 'Daily sync\nBring the board notes');
      expect(standup.location, 'Room 4, Floor 2');
      expect(standup.alarmsMinutesBefore, [10]);
      expect(standup.recurrence, contains('RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR'));
      expect(standup.recurrence, contains('EXDATE;TZID=Europe/Paris:20260925T093000'));
      final moved = r.events.firstWhere((e) => e.recurrenceId != null);
      expect(
        (moved.uid, moved.recurrenceId, moved.start),
        (standup.uid, LocalDateTime.of(2026, 9, 23, 9, 30), LocalDateTime.of(2026, 9, 23, 10)),
      );
      final conf = r.events.firstWhere((e) => e.summary == 'Conference');
      expect((conf.allDay, conf.durationMinutes), (true, 2880));
      final call = r.events.firstWhere((e) => e.summary.startsWith('Call'));
      expect((call.timeZone, call.start), ('UTC', LocalDateTime.of(2026, 10, 1, 14)));
      expect(r.events.last.recurrenceId, isNotNull, reason: 'overrides come after their series');
    });

    test('Apple: folded lines, UNTIL in UTC, yearly all-day', () {
      final r = IcsParser.parse(fixture('apple.ics'));
      final gym = r.events.firstWhere((e) => e.summary == 'Gym');
      expect(gym.description, endsWith('access card for the new building on the corner.'));
      expect((gym.timeZone, gym.durationMinutes), ('Africa/Tunis', 60));
      expect(gym.alarmsMinutesBefore, [30]);
      final birthday = r.events.firstWhere((e) => e.summary == 'Birthday Léa');
      expect((birthday.allDay, birthday.recurrence), (true, 'DTSTART;VALUE=DATE:20261003\nRRULE:FREQ=YEARLY'));
    });

    test('Outlook: Windows zone names, quoted TZID, LANGUAGE params; broken events are skipped', () {
      final r = IcsParser.parse(fixture('outlook.ics'));
      expect(r.skipped, 1);
      final review = r.events.firstWhere((e) => e.summary == 'Q4 review');
      expect((review.timeZone, review.durationMinutes), ('Europe/Berlin', 120));
      expect(review.alarmsMinutesBefore, [15]);
      final planning = r.events.firstWhere((e) => e.summary == 'Morning planning');
      expect(planning.recurrence, contains('EXDATE;TZID=Europe/Berlin:20261007T083000'));
    });

    test('durations and escaping helpers', () {
      expect(IcsParser.parseDuration('-PT15M'), -15);
      expect(IcsParser.parseDuration('P1DT2H'), 1560);
      expect(IcsParser.parseDuration('P1W'), 10080);
      expect(IcsParser.parseDuration('nope'), isNull);
      expect(IcsWriter.escape('a,b;c\\d\ne'), r'a\,b\;c\\d\ne');
      expect(IcsParser.unescape(r'a\,b\;c\\d\ne'), 'a,b;c\\d\ne');
      final long = 'DESCRIPTION:${'é' * 60}';
      final folded = IcsWriter.fold(long);
      expect(folded.split('\r\n ').every((l) => l.codeUnits.isNotEmpty), isTrue);
      expect(folded.replaceAll('\r\n ', ''), long);
    });
  });

  group('IcsImport candidates', () {
    test('rules, overrides and duplicates', () {
      final h = TestHarness.create();
      addTearDown(h.dispose);
      final candidates = IcsImport.candidates(
        IcsParser.parse(fixture('google.ics')),
        existingUids: {'0q3hbvbq1n8m5ep7d4s0c9f2kk@google.com'},
        resolver: h.read(zoneResolverProvider),
      );
      expect(candidates, hasLength(3), reason: 'the moved occurrence belongs to its series');
      final standup = candidates.firstWhere((c) => c.task.title == 'Standup');
      expect(standup.task.recurrence!.freq, Frequency.weekly);
      expect(standup.task.recurrence!.exdates, ['2026-09-25T09:30']);
      expect(standup.overrides, hasLength(1));
      expect(standup.task.externalUid, '7kukuqrfedlm2f9t0vonm1k3ps@google.com');
      expect(candidates.firstWhere((c) => c.task.title == 'Conference').alreadyImported, isTrue);
    });
  });

  group('IcsService', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 20, 8)));
    tearDown(() => h.dispose());

    test('import: tasks with UID, zone, rule, reminder; the moved occurrence keeps its new time', () async {
      final service = h.read(icsServiceProvider);
      final candidates = await service.preview(fixture('google.ics'));
      expect(await service.import(candidates), 3);
      final tasks = await h.read(plannerQueriesProvider).tasksForRange(at(2026, 9, 1), at(2026, 12, 31));
      final standup = tasks.firstWhere((t) => t.title == 'Standup');
      expect(
        (standup.timeZone, standup.startLocal, standup.durationMinutes),
        ('Europe/Paris', LocalDateTime.of(2026, 9, 21, 9, 30), 30),
      );
      final records = await h.read(plannerQueriesProvider).records([standup.id]);
      expect(records.single.overrideStartLocal, LocalDateTime.of(2026, 9, 23, 10));
      expect(records.single.overrideTitle, 'Standup (moved)');
      final rules = await h.read(notificationRulesRepositoryProvider).all();
      expect(rules.where((r) => r.targetId == standup.id), hasLength(1));

      final again = await service.preview(fixture('google.ics'));
      expect(again.every((c) => c.alreadyImported), isTrue, reason: 'duplicate detection by UID');
    });

    test('Apple and Outlook files import', () async {
      final service = h.read(icsServiceProvider);
      expect(await service.import(await service.preview(fixture('apple.ics'))), 2);
      expect(await service.import(await service.preview(fixture('outlook.ics'))), 2);
      final tasks = await h.read(plannerQueriesProvider).tasksForRange(at(2026, 9, 1), at(2026, 12, 31));
      expect(tasks.map((t) => t.title), containsAll(['Gym', 'Birthday Léa', 'Q4 review', 'Morning planning']));
      final planning = tasks.firstWhere((t) => t.title == 'Morning planning');
      expect((planning.timeZone, planning.recurrence!.count), ('Europe/Berlin', 10));
    });

    test('export → import round trip keeps the series', () async {
      final taskId = await h.task(
        'Swim',
        start: at(2026, 9, 21, 7),
        rule: RecurrenceRule(freq: Frequency.weekly, byWeekday: const [WeekdayRule(Weekday.monday)]),
      );
      final service = h.read(icsServiceProvider);
      final ics = await service.exportTask(taskId);
      expect(ics, contains('RRULE:FREQ=WEEKLY;BYDAY=MO'));
      expect(ics, contains('UID:$taskId@everslot.app'));
      expect(ics, startsWith('BEGIN:VCALENDAR\r\n'));
      final h2 = TestHarness.create(now: DateTime.utc(2026, 9, 20, 8));
      addTearDown(h2.dispose);
      final s2 = h2.read(icsServiceProvider);
      await s2.import(await s2.preview(ics));
      final imported = (await h2.read(plannerQueriesProvider).tasksForRange(at(2026, 9, 1), at(2026, 10, 1))).single;
      expect((imported.title, imported.startLocal, imported.durationMinutes), ('Swim', at(2026, 9, 21, 7), 60));
      expect(imported.recurrence!.byWeekday!.single.day, Weekday.monday);
      expect(imported.externalUid, '$taskId@everslot.app');
      // Re-exporting the imported task keeps the original UID.
      expect(await s2.exportTask(imported.id), contains('UID:$taskId@everslot.app'));
    });

    test('golden: one-off, all-day, series with an exception and an override', () async {
      final task = Task(
        id: 'task-1',
        seriesId: 'task-1',
        title: 'Team lunch, Friday; bring cake',
        notes: 'Line one\nLine two',
        startLocal: LocalDateTime.of(2026, 9, 25, 12, 30),
        durationMinutes: 90,
        timeZone: 'Europe/Paris',
        location: 'Café du Coin',
      );
      final events = [
        ...IcsMapping.eventsForTask(task, encode: (_, _) => null, expand: () => const []),
        ...IcsMapping.eventsForTask(
          Task(
            id: 'task-2',
            seriesId: 'task-2',
            title: 'Holiday',
            startLocal: LocalDateTime.of(2026, 12, 24, 0, 0),
            durationMinutes: 2880,
            isAllDay: true,
          ),
          encode: (_, _) => null,
          expand: () => const [],
        ),
      ];
      final text = IcsWriter.calendar(events, stamp: DateTime.utc(2026, 9, 20, 8));
      final golden = File('test/features/integrations/fixtures/ics/export_golden.ics');
      if (Platform.environment['UPDATE_GOLDENS'] == '1' || !golden.existsSync()) golden.writeAsStringSync(text);
      expect(text, golden.readAsStringSync());
    });

    test('non-representable rules export expanded instances', () async {
      final taskId = await h.task(
        'Water plants',
        start: at(2026, 9, 21, 8),
        rule: RecurrenceRule.forAfterCompletion(3, RecurrenceUnit.day),
      );
      final ics = await h.read(icsServiceProvider).exportTask(taskId);
      expect(ics, isNot(contains('RRULE')));
      expect(RegExp('BEGIN:VEVENT').allMatches(ics).length, greaterThanOrEqualTo(1));
    });
  });

  testWidgets('import sheet: duplicates start unchecked; importing creates the checked events', (tester) async {
    final h = TestHarness.create(now: DateTime.utc(2026, 9, 20, 8));
    addTearDown(h.dispose);
    final service = h.read(icsServiceProvider);
    await tester.runAsync(() async => service.import((await service.preview(fixture('apple.ics'))).take(1).toList()));
    final candidates = (await tester.runAsync(() => service.preview(fixture('apple.ics'))))!;
    await pumpToday(tester, h, Scaffold(body: IcsImportSheet(candidates: candidates)));
    await settle(tester);
    expect(tester.widget<CheckboxListTile>(find.byKey(const ValueKey('ics-item-0'))).value, isFalse);
    expect(find.textContaining('Already imported'), findsOneWidget);
    expect(find.text('Import 1 event'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ics-import')));
    await settle(tester);
    final tasks = await tester.runAsync(
      () => h.read(plannerQueriesProvider).tasksForRange(at(2026, 9, 1), at(2026, 12, 31)),
    );
    expect(tasks!.map((t) => t.title).toSet(), {'Gym', 'Birthday Léa'});
  });
}
