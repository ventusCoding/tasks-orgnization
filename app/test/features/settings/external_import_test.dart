import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/settings/application/external_import_service.dart';
import 'package:everslot/features/settings/application/import_service.dart' show importScratchDirectoryProvider;
import 'package:everslot/features/settings/domain/external_import.dart';
import 'package:everslot/features/settings/presentation/pages/data_page.dart';
import 'package:everslot/features/settings/presentation/pages/import_section.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitGoalType, TargetOp;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/test_app.dart';

const _fixtures = 'test/features/settings/fixtures/external';

String _read(String name) => File('$_fixtures/$name').readAsStringSync();

/// Zips [dir] (paths relative to it).
List<int> _zip(String dir) {
  final archive = Archive();
  for (final f in Directory(dir).listSync(recursive: true).whereType<File>()) {
    archive.add(ArchiveFile.bytes(p.relative(f.path, from: dir), f.readAsBytesSync()));
  }
  return ZipEncoder().encodeBytes(archive);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(tzdata.initializeTimeZones);

  group('CsvReader', () {
    test('quotes, doubled quotes, embedded line breaks, BOM and CRLF', () {
      final rows = CsvReader.parse('﻿a,"b,1","say ""hi"""\r\n"multi\nline",,x\n');
      expect(rows, [
        ['a', 'b,1', 'say "hi"'],
        ['multi\nline', '', 'x'],
      ]);
    });
  });

  group('Loop Habit Tracker', () {
    Map<String, String> csvFiles({bool withTop = true}) => {
      'Loop Habits CSV 2026-09-22/Habits.csv': _read('loop/Habits.csv'),
      if (withTop) 'Loop Habits CSV 2026-09-22/Checkmarks.csv': _read('loop/Checkmarks.csv'),
      'Loop Habits CSV 2026-09-22/001 Meditate/Checkmarks.csv': _read('loop/001 Meditate/Checkmarks.csv'),
    };

    test('CSV export: frequencies, numerical goals, manual check-ins and skips', () {
      final plan = LoopImport.fromCsv(csvFiles());
      expect(plan.habits.map((h) => h.name), ['Meditate', 'Run', 'Water', 'Floss']);
      final byName = {for (final h in plan.habits) h.name: h};
      expect(byName['Meditate']!.preset.kind, SchedulePresetKind.daily);
      expect(byName['Meditate']!.description, 'Did you meditate today?\n10 minutes is enough');
      expect(byName['Meditate']!.checks.map((c) => c.date.toIso()), ['2026-09-21', '2026-09-22']);
      expect(byName['Meditate']!.color?.argb, 0xFF4CAF50);
      final run = byName['Run']!;
      expect((run.preset.kind, run.preset.n), (SchedulePresetKind.timesPerWeek, 3));
      expect(run.checks, hasLength(1), reason: '1 = implied by the frequency, not a check-in');
      final water = byName['Water']!;
      expect(
        (water.goal.type, water.goal.target, water.goal.unit, water.goal.op),
        (HabitGoalType.numeric, 8.0, 'glasses', TargetOp.gte),
      );
      expect(water.checks.map((c) => c.value), [6.0, 8.0]);
      final floss = byName['Floss']!;
      expect(floss.archived, isTrue);
      expect(floss.color?.paletteIndex, 8);
      expect(floss.checks.map((c) => (c.date.toIso(), c.kind)), [
        ('2026-09-20', ExternalCheckKind.done),
        ('2026-09-21', ExternalCheckKind.skip),
      ]);
      expect(plan.notes[ImportNote.frequencyApproximated], 1, reason: '2 times in 5 days');
      expect(plan.checkCount, 7);
    });

    test('per-habit files are used when the combined file is missing', () {
      final plan = LoopImport.fromCsv(csvFiles(withTop: false));
      expect(plan.habits.first.checks, hasLength(2));
      expect(plan.habits[1].checks, isEmpty);
    });

    test('a .db backup', () {
      final db = sqlite3.openInMemory()..execute(_read('loop_backup.sql'));
      List<Map<String, Object?>> rows(String sql) => [
        for (final r in db.select(sql)) {for (final c in r.keys) c: r[c]},
      ];
      final plan = LoopImport.fromDatabase(
        habits: rows('SELECT * FROM Habits'),
        repetitions: rows('SELECT * FROM Repetitions'),
      );
      db.close();
      expect(plan.habits.map((h) => h.name), ['Read', 'Weekly call']);
      expect(plan.habits.first.checks.map((c) => c.kind), [
        ExternalCheckKind.skip,
        ExternalCheckKind.done,
        ExternalCheckKind.done,
      ]);
      expect((plan.habits[1].preset.kind, plan.habits[1].preset.n), (SchedulePresetKind.everyNDays, 7));
    });
  });

  test('Google Keep notes: lists, text notes, labels, colours, archive and trash', () {
    final notes = {
      for (final name in ['Groceries', 'Plumber', 'Old'])
        'Takeout/Keep/$name.json': jsonDecode(_read('keep/Takeout/Keep/$name.json')) as Map<String, Object?>,
    };
    final plan = KeepImport.fromNotes(notes);
    expect(plan.lists.map((l) => l.title), ['Groceries', 'Plumber'], reason: 'newest first, trash skipped');
    final groceries = plan.lists.first;
    expect(groceries.items.map((i) => (i.text, i.checked)), [('Milk', false), ('Eggs', true)]);
    expect((groceries.pinned, groceries.color?.paletteIndex), (true, 3));
    expect(groceries.labels, ['Home']);
    final plumber = plan.lists[1];
    expect((plumber.body, plumber.archived), ('Call the plumber\nabout the sink', true));
    expect(plumber.files, ['Takeout/Keep/sink.png', 'Takeout/Keep/missing.jpg']);
    expect(plan.notes[ImportNote.trashedSkipped], 1);
  });

  test('Todoist CSV: natural-language dates, repeats, priorities, labels, comments', () {
    final now = LocalDateTime.of(2026, 9, 22, 10, 0);
    final plan = TodoistImport.parse(_read('todoist.csv'), now: now);
    expect(plan.tasks.map((t) => t.title), ['Buy milk', 'Weekly review', 'Someday thing']);
    final milk = plan.tasks.first;
    expect((milk.start, milk.allDay, milk.priority), (LocalDateTime.of(2026, 9, 23, 0, 0), true, 4));
    expect(milk.labels, ['shopping', 'Errands']);
    expect(milk.notes, 'Semi-skimmed\n\nAsk for the organic one, please');
    final review = plan.tasks[1];
    expect(review.rule?.freq, Frequency.weekly);
    expect(review.rule?.byWeekday?.map((w) => w.day), [Weekday.friday]);
    expect((review.start?.time, review.durationMinutes, review.priority), (LocalTime(17, 0), 30, 3));
    expect(plan.tasks[2].start, isNull);
  });

  test('TickTick CSV: zoned instants, RRULE, all-day, completed tasks skipped', () {
    final plan = TickTickImport.parse(_read('ticktick.csv'), resolver: TzZoneResolver());
    expect(plan.tasks.map((t) => t.title), ['Standup', 'Pay rent']);
    final standup = plan.tasks.first;
    expect(standup.start, LocalDateTime.of(2026, 9, 22, 9, 0), reason: '07:00Z in Paris (CEST)');
    expect((standup.durationMinutes, standup.rule?.freq, standup.priority), (15, Frequency.daily, 2));
    expect(standup.labels, ['team', 'Work']);
    final rent = plan.tasks[1];
    expect((rent.allDay, rent.start, rent.priority), (true, LocalDateTime.of(2026, 10, 1, 0, 0), 3));
    expect(plan.notes[ImportNote.completedSkipped], 1);
  });

  group('ExternalImportService', () {
    late Directory tmp;
    late TestHarness h;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('everslot_ext_');
      h = TestHarness.create(
        overrides: [
          importScratchDirectoryProvider.overrideWithValue(() async => Directory('${tmp.path}/scratch')),
          attachmentFileStoreProvider.overrideWithValue(
            AttachmentFileStore(() async => Directory('${tmp.path}/attachments')),
          ),
        ],
      );
    });

    tearDown(() async {
      await h.dispose();
      tmp.deleteSync(recursive: true);
    });

    File write(String name, List<int> bytes) => File('${tmp.path}/$name')..writeAsBytesSync(bytes);

    test('Loop zip → habits with their history (source import)', () async {
      final service = h.read(externalImportServiceProvider);
      final bundle = await service.open(write('loop.zip', _zip('$_fixtures/loop')), ExternalSource.loop);
      final result = await service.apply(bundle);
      expect((result.habits, result.checks), (4, 7));
      final habits = await h.db.select(h.db.habits).get();
      expect(habits.map((x) => x.name).toSet(), {'Meditate', 'Run', 'Water', 'Floss'});
      expect(habits.firstWhere((x) => x.name == 'Floss').archivedAt, isNotNull);
      final logs = await h.db.select(h.db.habitLogs).get();
      expect(logs, hasLength(7));
      expect(logs.every((l) => l.source == 'import'), isTrue);
      expect(logs.where((l) => l.kind == 'progress').map((l) => l.value).toSet(), {6.0, 8.0});
    });

    test('Loop .db backup', () async {
      final path = '${tmp.path}/loop.db';
      sqlite3.open(path)
        ..execute(_read('loop_backup.sql'))
        ..close();
      final service = h.read(externalImportServiceProvider);
      final result = await service.apply(await service.open(File(path), ExternalSource.loop));
      expect((result.habits, result.checks), (2, 4));
    });

    test('Keep Takeout zip → lists with items, labels and image attachments', () async {
      final service = h.read(externalImportServiceProvider);
      final bundle = await service.open(write('takeout.zip', _zip('$_fixtures/keep')), ExternalSource.keep);
      expect(bundle.plan.notes[ImportNote.attachmentMissing], 1);
      final result = await service.apply(bundle);
      expect((result.lists, result.items), (2, 2));
      final lists = await h.db.select(h.db.checklists).get();
      final plumber = lists.firstWhere((l) => l.title == 'Plumber');
      expect(plumber.archivedAt, isNotNull);
      final attachments = await h.db.select(h.db.attachments).get();
      expect(attachments.map((a) => (a.ownerId, a.fileName)), [(plumber.id, 'sink.png')]);
      final tags = await h.db.select(h.db.tags).get();
      expect(tags.map((t) => t.name), ['Home']);
    });

    test('Todoist → tasks with tags; text outline → nested list; wrong files are refused', () async {
      final service = h.read(externalImportServiceProvider);
      await service.apply(await service.open(File('$_fixtures/todoist.csv'), ExternalSource.todoist));
      final tasks = await h.db.select(h.db.tasks).get();
      expect(tasks.map((t) => t.title).toSet(), {'Buy milk', 'Weekly review', 'Someday thing'});
      // shopping + the Errands section on all three tasks.
      expect((await h.db.select(h.db.entityTags).get()).length, 4);

      final outline = await service.open(File('$_fixtures/outline.md'), ExternalSource.text);
      expect(outline.plan.itemCount, 3);
      await service.apply(outline);
      final items = await h.db.select(h.db.checklistItems).get();
      expect(items.map((i) => i.itemText).toSet(), {'Book flights', 'Compare prices', 'Renew passport'});

      await expectLater(service.open(File('$_fixtures/todoist.csv'), ExternalSource.loop), throwsFormatException);
      await expectLater(service.open(File('$_fixtures/todoist.csv'), ExternalSource.keep), throwsFormatException);
    });
  });

  testWidgets('UI: pick a source and a file, preview, import', (tester) async {
    late TestHarness h;
    final tmp = Directory.systemTemp.createTempSync('everslot_ext_ui_');
    h = TestHarness.create(
      overrides: [
        importScratchDirectoryProvider.overrideWithValue(() async => Directory('${tmp.path}/scratch')),
        externalFilePickerProvider.overrideWithValue(() async => File('$_fixtures/todoist.csv')),
      ],
    );
    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await pumpInApp(tester, h, const DataPage());
    await settle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('import-external')), 200);
    await tester.ensureVisible(find.byKey(const ValueKey('import-external')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('import-external')));
    await settle();
    await tester.ensureVisible(find.byKey(const ValueKey('ext-source-todoist')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ext-source-todoist')));
    await settle();
    expect(find.text('3 tasks'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ext-run')));
    await settle();
    expect(find.text('3 things imported'), findsOneWidget);
    expect(await tester.runAsync(() => h.db.select(h.db.tasks).get()), hasLength(3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(h.dispose);
    tmp.deleteSync(recursive: true);
  });
}
