import 'package:everslot/features/checklists/domain/builtin_templates.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/import_export.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/reset.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'checklist_test_support.dart';

/// `text[:status]` outline of import nodes (2 spaces per level).
String show(List<NodeSpec> nodes, {int depth = 0}) {
  final out = StringBuffer();
  for (final n in nodes) {
    out.writeln('${'  ' * depth}${n.text}${n.status == ItemStatus.todo ? '' : ':${n.status.name}'}');
    final kids = show(n.children, depth: depth + 1);
    if (kids.isNotEmpty) out.writeln(kids);
  }
  return out.toString().trimRight();
}

void main() {
  group('import parser fixtures', () {
    test('Workflowy OPML (_note, _complete)', () {
      const opml = '''
<?xml version="1.0"?>
<opml version="2.0"><head><title>Trip &amp; plans</title></head><body>
  <outline text="Book flights" _complete="true"/>
  <outline text="Hotel" _note="near the station">
    <outline text="Compare prices"/>
    <outline text="Pay deposit &lt;50%&gt;"/>
  </outline>
</body></opml>''';
      final r = ChecklistImport.parse(opml);
      expect(r.title, 'Trip & plans');
      expect(show(r.nodes), 'Book flights:completed\nHotel\n  Compare prices\n  Pay deposit <50%>');
      expect(r.nodes[1].note, 'near the station');
    });

    test('Dynalist OPML with single quotes and nested self-closing outlines', () {
      const opml =
          "<opml version='1.0'><body><outline text='A'><outline text='A1' complete='true'/></outline></body></opml>";
      expect(show(ChecklistImport.parse(opml).nodes), 'A\n  A1:completed');
    });

    test('Checkvist / plain indented text (tabs, 2 or 4 spaces, mixed)', () {
      const text = 'Project\n\tDesign\n\t\tWireframes\n    Build\nLaunch\n  Announce';
      expect(show(ChecklistImport.parse(text).nodes), 'Project\n  Design\n    Wireframes\n  Build\nLaunch\n  Announce');
    });

    test('Keep text export (☐/☑)', () {
      const keep = 'Groceries\n☐ Milk\n☑ Bread\n☐ Eggs';
      expect(show(ChecklistImport.parse(keep).nodes), 'Groceries\nMilk\nBread:completed\nEggs');
    });

    test('Obsidian Markdown: headings become parents, task lists, numbered bullets, notes', () {
      const md = '''
## Home
- [ ] Fix sink
  call the plumber first
- [x] Paint wall
## Work
1. Write report
2) Send invoice
''';
      final r = ChecklistImport.parse(md);
      expect(show(r.nodes), 'Home\n  Fix sink\n  Paint wall:completed\nWork\n  Write report\n  Send invoice');
      expect(r.nodes.first.children.first.note, 'call the plumber first');
    });

    test('Arabic text keeps order and nesting', () {
      const ar = '- التسوق\n  - حليب\n  - [x] خبز';
      expect(show(ChecklistImport.parse(ar).nodes), 'التسوق\n  حليب\n  خبز:completed');
    });

    test('malformed / empty input never throws', () {
      expect(ChecklistImport.parse('').warnings, [ImportWarning.emptyInput]);
      expect(ChecklistImport.parse('<opml><body><outline text="x"').nodes, isEmpty);
      expect(ChecklistImport.parse('   \n\n  ').isEmpty, isTrue);
      final many = List.generate(ChecklistImport.maxLines + 5, (i) => 'line $i').join('\n');
      final r = ChecklistImport.parse(many);
      expect(r.count, ChecklistImport.maxLines);
      expect(r.warnings, contains(ImportWarning.tooManyLines));
    });
  });

  group('export', () {
    final items = outline(
      'Pack:ongoing\n  Passport:completed\n  Charger:waiting\nCall mum:blocked\nOld idea:cancelled',
    );
    final t = ChecklistTree.build([
      for (final i in items)
        switch (i.id) {
          'Charger' => i.copyWith(statusNote: 'from Ali'),
          'Pack' => i.copyWith(note: 'small bag\nno liquids'),
          _ => i,
        },
    ]);

    test('Markdown golden', () {
      expect(
        ChecklistExport.markdown(
          t,
          title: 'Trip',
          attachmentNames: {
            'Passport': ['scan.pdf'],
          },
        ),
        '# Trip\n\n'
        '- [ ] ▶ Pack\n'
        '  small bag\n'
        '  no liquids\n'
        '  - [x] Passport\n'
        '    📎 scan.pdf\n'
        '  - [ ] ⏳ Charger — waiting: from Ali\n'
        '- [ ] ⛔ Call mum\n'
        '- [ ] ✖ Old idea\n',
      );
    });

    test('round trips (Markdown, OPML, plain) keep structure, statuses and notes', () {
      for (final format in ['md', 'opml', 'txt']) {
        final text = switch (format) {
          'md' => ChecklistExport.markdown(t, title: 'Trip'),
          'opml' => ChecklistExport.opml(t, title: 'Trip'),
          _ => ChecklistExport.plainText(t, title: 'Trip'),
        };
        final r = ChecklistImport.parse(text);
        expect(r.title, 'Trip', reason: format);
        expect(
          show(r.nodes),
          'Pack:ongoing\n  Passport:completed\n  Charger:waiting\nCall mum:blocked\nOld idea:cancelled',
          reason: format,
        );
        expect(r.nodes.first.children[1].statusNote, 'from Ali', reason: format);
        if (format != 'txt') expect(r.nodes.first.note, 'small bag\nno liquids', reason: format);
      }
    });

    test('branch export and copy-as-text', () {
      expect(ChecklistExport.plainText(t, rootId: 'Pack'), '[x] Passport\n⏳ Charger — waiting: from Ali\n');
      expect(ChecklistExport.subtreesAsText(t, ['Charger']), '- [ ] ⏳ Charger — waiting: from Ali\n');
    });
  });

  test('built-in templates parse in every locale with nesting', () {
    for (final template in BuiltinTemplates.all) {
      for (final locale in ['en', 'fr', 'ar']) {
        final r = template.parse(locale);
        expect(r.title, isNotEmpty, reason: '${template.code}/$locale');
        expect(r.nodes.any((n) => n.children.isNotEmpty), isTrue, reason: '${template.code}/$locale');
        expect(r.count, template.parse('en').count, reason: '${template.code}/$locale');
      }
    }
  });

  group('reset planner', () {
    setUpAll(tzdata.initializeTimeZones);
    final engine = RecurrenceEngine(TzZoneResolver());
    final daily = ResetSchedule.preset(ResetPreset.daily, anchorStart: LocalDateTime.of(2026, 9, 1, 5));

    test('schedule JSON keeps the anchor in the rule', () {
      final back = ResetSchedule.fromJson(daily.toJson())!;
      expect(back.anchorStart, daily.anchorStart);
      expect(back.preset, ResetPreset.daily);
      final weekly = ResetSchedule.preset(
        ResetPreset.weekly,
        anchorStart: LocalDateTime.of(2026, 9, 6, 5),
        zone: 'Europe/Paris',
      );
      expect(ResetSchedule.fromJson(weekly.toJson())!.zone, 'Europe/Paris');
      expect(ResetSchedule.fromJson(weekly.toJson())!.preset, ResetPreset.weekly);
    });

    test('latest due key after the last reset; only the latest after missed periods', () {
      final now = DateTime.utc(2026, 9, 23, 9);
      final plan = ResetPlanner.due(engine, daily, lastResetKey: '2026-09-20T05:00', now: now, evalZone: 'UTC')!;
      expect(plan.key, '2026-09-23T05:00');
      expect(plan.at, DateTime.utc(2026, 9, 23, 5));
      expect(plan.previousAt, DateTime.utc(2026, 9, 22, 5));
      expect(ResetPlanner.due(engine, daily, lastResetKey: '2026-09-23T05:00', now: now, evalZone: 'UTC'), isNull);
      expect(ResetPlanner.initialKey(engine, daily, now: now, evalZone: 'UTC'), '2026-09-23T05:00');
      expect(ResetPlanner.next(engine, daily, now: now, evalZone: 'UTC'), DateTime.utc(2026, 9, 24, 5));
    });

    test('DST: the 05:00 reset follows local wall time in Paris', () {
      final paris = ResetSchedule.preset(
        ResetPreset.daily,
        anchorStart: LocalDateTime.of(2026, 10, 20, 5),
        zone: 'Europe/Paris',
      );
      final before = ResetPlanner.due(
        engine,
        paris,
        lastResetKey: null,
        now: DateTime.utc(2026, 10, 24, 12),
        evalZone: 'UTC',
      )!;
      final after = ResetPlanner.due(
        engine,
        paris,
        lastResetKey: null,
        now: DateTime.utc(2026, 10, 26, 12),
        evalZone: 'UTC',
      )!;
      expect(before.at, DateTime.utc(2026, 10, 24, 3)); // CEST (UTC+2)
      expect(after.at, DateTime.utc(2026, 10, 26, 4)); // CET (UTC+1)
    });

    test('apply: run snapshot, statuses per mode, last key, backdated clock', () {
      final t = tree('A:completed\nB:waiting\nC');
      const checklist = Checklist(id: 'c1', sortKey: 'a0');
      final at = DateTime.utc(2026, 9, 23, 5);
      final all = ResetPlanner.apply(
        t,
        checklist,
        runId: 'run1',
        key: 'k',
        at: at,
        startedAt: at.subtract(const Duration(days: 1)),
        mode: ResetMode.allToTodo,
      );
      expect(all.scheduledAt, at);
      expect(all.cause, 'reset');
      final run = all.valuesFor('run1', table: 'checklist_runs')!;
      expect((run['total_items'], run['completed_items']), (3, 1));
      expect((run['snapshot']! as List).length, 3);
      expect(all.valuesFor('A')!['status'], 'todo');
      expect(all.valuesFor('B')!['status'], 'todo');
      expect(all.valuesFor('C'), isNull);
      expect(all.valuesFor('c1', table: 'checklists'), {'last_reset_key': 'k'});
      final completedOnly = ResetPlanner.apply(
        t,
        checklist,
        runId: 'run2',
        key: 'k2',
        at: at,
        startedAt: at,
        mode: ResetMode.completedToTodo,
      );
      expect(completedOnly.valuesFor('B'), isNull);
      expect(completedOnly.valuesFor('A')!['status'], 'todo');
    });
  });
}
