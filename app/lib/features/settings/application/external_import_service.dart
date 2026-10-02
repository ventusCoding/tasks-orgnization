import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/tokens.dart' show CategoryPalette;
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/import_export.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart' show DefaultSections;
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/settings/application/import_service.dart' show importScratchDirectoryProvider;
import 'package:everslot/features/settings/data/loop_backup_reader.dart';
import 'package:everslot/features/settings/domain/external_import.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// What an applied import created.
typedef ExternalImportResult = ({int habits, int checks, int lists, int items, int tasks});

/// Opened source: the plan plus the folder holding files it references (Keep images).
class ExternalBundle {
  const ExternalBundle(this.plan, {this.root});

  final ExternalImportPlan plan;
  final String? root;
}

final externalImportServiceProvider = Provider<ExternalImportService>(ExternalImportService.new);

/// Import from other apps (T8.3.14): Loop Habit Tracker, Google Keep, Todoist, TickTick and plain
/// indented text / Markdown. Everything is written through the regular feature services.
class ExternalImportService {
  ExternalImportService(this._ref);

  final Ref _ref;

  /// Parses [file] as [source] (zip / json / csv / db / txt). Throws [FormatException] when the
  /// file is not what the source exports.
  Future<ExternalBundle> open(File file, ExternalSource source) async {
    final scratch = p.join((await _ref.read(importScratchDirectoryProvider)()).path, 'external');
    final now = _ref
        .read(zoneResolverProvider)
        .toLocal(_ref.read(clockProvider).nowUtc(), _ref.read(deviceZoneProvider));
    final weekStart = _ref.read(userPreferencesProvider).weekStart;
    // Time-zone data lives in this isolate: TickTick's zoned dates are read here.
    if (source == ExternalSource.tickTick) {
      final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      return ExternalBundle(TickTickImport.parse(text, resolver: _ref.read(zoneResolverProvider)));
    }
    return Isolate.run(() => _open(file.path, source, scratch, now, weekStart));
  }

  static ExternalBundle _open(
    String path,
    ExternalSource source,
    String scratch,
    LocalDateTime now,
    Weekday weekStart,
  ) {
    final bytes = File(path).readAsBytesSync();
    final zip = bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4b;
    final sqlite = bytes.length > 16 && ascii.decode(bytes.sublist(0, 15), allowInvalid: true) == 'SQLite format 3';
    String text() => utf8.decode(bytes, allowMalformed: true);
    switch (source) {
      case ExternalSource.loop:
        if (sqlite) {
          final rows = LoopBackupReader.read(path);
          return ExternalBundle(LoopImport.fromDatabase(habits: rows.habits, repetitions: rows.repetitions));
        }
        if (!zip) throw const FormatException('loop_missing_habits');
        final files = <String, String>{
          for (final f in ZipDecoder().decodeBytes(bytes).files)
            if (f.isFile && f.name.toLowerCase().endsWith('.csv')) f.name: utf8.decode(f.content, allowMalformed: true),
        };
        return ExternalBundle(LoopImport.fromCsv(files));
      case ExternalSource.keep:
        final notes = <String, Map<String, Object?>>{};
        String? root;
        if (zip) {
          final archive = ZipDecoder().decodeBytes(bytes);
          final dir = Directory(scratch);
          if (dir.existsSync()) dir.deleteSync(recursive: true);
          for (final f in archive.files) {
            if (!f.isFile) continue;
            final name = f.name;
            if (name.toLowerCase().endsWith('.json')) {
              final json = _tryJson(utf8.decode(f.content, allowMalformed: true));
              if (json != null && _isKeepNote(json)) notes[name] = json;
            } else if (!name.split('/').any((s) => s == '..' || s.startsWith('.'))) {
              final out = File(p.join(scratch, name))..parent.createSync(recursive: true);
              out.writeAsBytesSync(f.content);
            }
          }
          root = scratch;
        } else {
          final json = _tryJson(text());
          if (json != null && _isKeepNote(json)) notes[p.basename(path)] = json;
        }
        if (notes.isEmpty) throw const FormatException('keep_no_notes');
        final plan = KeepImport.fromNotes(notes);
        final missing = [
          for (final l in plan.lists)
            for (final f in l.files)
              if (root == null || !File(p.join(root, f)).existsSync()) f,
        ].length;
        return ExternalBundle(
          missing == 0
              ? plan
              : ExternalImportPlan(
                  source: plan.source,
                  lists: plan.lists,
                  notes: {...plan.notes, ImportNote.attachmentMissing: missing},
                ),
          root: root,
        );
      case ExternalSource.todoist:
        return ExternalBundle(TodoistImport.parse(text(), now: now, weekStart: weekStart));
      case ExternalSource.tickTick:
        return ExternalBundle(TickTickImport.parse(text()));
      case ExternalSource.text:
        final parsed = ChecklistImport.parseText(text());
        if (parsed.isEmpty) throw const FormatException('text_empty');
        return ExternalBundle(
          ExternalImportPlan(
            source: ExternalSource.text,
            lists: [ExternalList(title: parsed.title ?? p.basenameWithoutExtension(path), items: _items(parsed.nodes))],
          ),
        );
    }
  }

  static List<ExternalItem> _items(List<NodeSpec> nodes) => [
    for (final n in nodes)
      ExternalItem(n.text, checked: n.status == ItemStatus.completed, children: _items(n.children)),
  ];

  static Map<String, Object?>? _tryJson(String s) {
    try {
      final v = jsonDecode(s);
      return v is Map<String, Object?> ? v : null;
    } on FormatException {
      return null;
    }
  }

  static bool _isKeepNote(Map<String, Object?> j) =>
      j.containsKey('textContent') || j.containsKey('listContent') || j.containsKey('userEditedTimestampUsec');

  static int? _color(ExternalColor? c) => c == null ? null : (c.argb ?? CategoryPalette.at(c.paletteIndex!));

  /// Creates everything in [bundle].
  Future<ExternalImportResult> apply(ExternalBundle bundle, {void Function(double progress)? onProgress}) async {
    final plan = bundle.plan;
    final total = plan.habits.length + plan.lists.length + plan.tasks.length;
    var done = 0;
    void step() => onProgress?.call(total == 0 ? 1 : ++done / total);
    var checks = 0;
    var items = 0;
    final tagIds = <String, String>{};
    Future<Set<String>> tags(List<String> names) async {
      final repo = _ref.read(tagsRepositoryProvider);
      final ids = <String>{};
      for (final n in names) {
        final key = n.toLowerCase();
        ids.add(tagIds[key] ??= (await repo.findByName(n))?.id ?? (await repo.create(name: n)).id);
      }
      return ids;
    }

    final today = _ref
        .read(zoneResolverProvider)
        .toLocal(_ref.read(clockProvider).nowUtc(), _ref.read(deviceZoneProvider))
        .date;
    final weekStart = _ref.read(userPreferencesProvider).weekStart;
    for (final h in plan.habits) {
      final habit = BuildHabit(
        id: Ids.v7(),
        name: h.name,
        description: h.description,
        startDate: h.checks.isEmpty ? today : h.checks.first.date,
        sortKey: '',
        color: _color(h.color),
        goal: h.preset.adaptGoal(h.goal),
        schedule: h.preset.toRule(weekStart: weekStart),
        sectionId: _ref.read(habitSectionsRepositoryProvider).defaultId(DefaultSections.anytime),
      );
      await _ref.read(habitServiceProvider).create(habit);
      checks += await _ref.read(checkInServiceProvider).importHistory(habit, [
        for (final c in h.checks)
          (
            date: c.date,
            state: switch (c.kind) {
              ExternalCheckKind.done => CheckInState.done,
              ExternalCheckKind.skip => CheckInState.skip,
              ExternalCheckKind.fail => CheckInState.notDone,
            },
            value: c.value,
          ),
      ]);
      if (h.archived) await _ref.read(habitServiceProvider).setArchived(habit.id, archived: true);
      step();
    }

    final lists = _ref.read(checklistsRepositoryProvider);
    for (final l in plan.lists) {
      List<NodeSpec> nodes(List<ExternalItem> items) => [
        for (final i in items)
          NodeSpec(
            text: i.text,
            status: i.checked ? ItemStatus.completed : ItemStatus.todo,
            children: nodes(i.children),
          ),
      ];
      final created = await lists.create(
        title: l.title,
        body: l.body,
        color: _color(l.color),
        isPinned: l.pinned,
        items: nodes(l.items),
      );
      items += l.items.fold(0, (a, i) => a + i.size);
      if (l.labels.isNotEmpty) {
        await _ref.read(tagsRepositoryProvider).setTags('checklist', created.id, await tags(l.labels));
      }
      final root = bundle.root;
      if (root != null && l.files.isNotEmpty) {
        final files = [
          for (final f in l.files)
            if (File(p.join(root, f)).existsSync()) PickedFileRef(path: p.join(root, f), name: p.basename(f)),
        ];
        if (files.isNotEmpty) await _ref.read(attachmentServiceProvider).addFiles('checklist', created.id, files);
      }
      if (l.archived) await lists.setArchived(created.id, archived: true);
      step();
    }

    final planner = _ref.read(plannerServiceProvider);
    for (final t in plan.tasks) {
      await planner.createTask(
        Task(
          id: '',
          seriesId: '',
          title: t.title,
          notes: t.notes,
          startLocal: t.start,
          durationMinutes: t.start == null ? null : (t.allDay ? 1440 : (t.durationMinutes ?? 60)),
          isAllDay: t.allDay,
          timeZone: t.timeZone,
          recurrence: t.rule,
          priority: t.priority,
        ),
        source: 'import',
        tagIds: t.labels.isEmpty ? const {} : await tags(t.labels),
      );
      step();
    }
    return (
      habits: plan.habits.length,
      checks: checks,
      lists: plan.lists.length,
      items: items,
      tasks: plan.tasks.length,
    );
  }
}
