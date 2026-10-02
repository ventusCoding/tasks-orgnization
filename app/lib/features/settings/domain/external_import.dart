import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/planner/domain/quick_parse.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Apps Everslot imports from (T8.3.14).
enum ExternalSource { loop, keep, todoist, tickTick, text }

/// Something an importer could not carry over exactly.
enum ImportNote {
  /// A habit frequency approximated by the nearest Everslot schedule.
  frequencyApproximated,

  /// A repeat text that could not be understood (the task is imported once).
  repeatNotUnderstood,

  /// Completed tasks are not imported.
  completedSkipped,

  /// Notes in the trash are not imported.
  trashedSkipped,

  /// Attachment files that were not in the archive.
  attachmentMissing,
}

// ---------------------------------------------------------------------------------------------
// Neutral records

enum ExternalCheckKind { done, skip, fail }

/// A colour from the source: an index of the Everslot palette or an explicit ARGB value.
@immutable
class ExternalColor {
  const ExternalColor.palette(int this.paletteIndex) : argb = null;
  const ExternalColor.argb(int this.argb) : paletteIndex = null;

  final int? paletteIndex;
  final int? argb;
}

@immutable
class ExternalCheck {
  const ExternalCheck(this.date, this.kind, {this.value});

  final LocalDate date;
  final ExternalCheckKind kind;

  /// Amount of a measurable habit.
  final double? value;
}

@immutable
class ExternalHabit {
  const ExternalHabit({
    required this.name,
    required this.preset,
    this.goal = const HabitTarget.check(),
    this.description,
    this.archived = false,
    this.color,
    this.checks = const [],
  });

  final String name;
  final String? description;
  final SchedulePreset preset;
  final HabitTarget goal;
  final bool archived;
  final ExternalColor? color;
  final List<ExternalCheck> checks;
}

@immutable
class ExternalItem {
  const ExternalItem(this.text, {this.checked = false, this.children = const []});

  final String text;
  final bool checked;
  final List<ExternalItem> children;

  int get size => 1 + children.fold(0, (a, c) => a + c.size);
}

@immutable
class ExternalList {
  const ExternalList({
    required this.title,
    this.body,
    this.items = const [],
    this.pinned = false,
    this.archived = false,
    this.color,
    this.labels = const [],
    this.files = const [],
  });

  final String title;

  /// Free text of a text note.
  final String? body;
  final List<ExternalItem> items;
  final bool pinned;
  final bool archived;
  final ExternalColor? color;
  final List<String> labels;

  /// Attachment paths relative to the archive / folder.
  final List<String> files;
}

@immutable
class ExternalTask {
  const ExternalTask({
    required this.title,
    this.notes,
    this.start,
    this.allDay = false,
    this.durationMinutes,
    this.timeZone,
    this.rule,
    this.priority = 0,
    this.labels = const [],
  });

  final String title;
  final String? notes;
  final LocalDateTime? start;
  final bool allDay;
  final int? durationMinutes;
  final String? timeZone;
  final RecurrenceRule? rule;

  /// Everslot priority 0 (none) … 4 (urgent).
  final int priority;
  final List<String> labels;
}

/// Everything read from one export, before anything is written.
@immutable
class ExternalImportPlan {
  const ExternalImportPlan({
    required this.source,
    this.habits = const [],
    this.lists = const [],
    this.tasks = const [],
    this.notes = const {},
  });

  final ExternalSource source;
  final List<ExternalHabit> habits;
  final List<ExternalList> lists;
  final List<ExternalTask> tasks;

  /// How many records each note concerns.
  final Map<ImportNote, int> notes;

  int get checkCount => habits.fold(0, (a, h) => a + h.checks.length);
  int get itemCount => lists.fold(0, (a, l) => a + l.items.fold(0, (b, i) => b + i.size));
  bool get isEmpty => habits.isEmpty && lists.isEmpty && tasks.isEmpty;
}

// ---------------------------------------------------------------------------------------------
// CSV

/// RFC 4180 reader: quoted fields with doubled quotes and line breaks, CRLF or LF, optional BOM.
abstract final class CsvReader {
  static List<List<String>> parse(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    var i = input.startsWith('﻿') ? 1 : 0;
    void endField() {
      row.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      if (!(row.length == 1 && row.first.isEmpty)) rows.add(row);
      row = <String>[];
    }

    for (; i < input.length; i++) {
      final c = input[i];
      if (quoted) {
        if (c == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          field.write(c);
        }
      } else if (c == '"') {
        quoted = true;
      } else if (c == ',') {
        endField();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
        endRow();
      } else {
        field.write(c);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) endRow();
    return rows;
  }

  /// Rows as maps keyed by the header row (case-insensitive, trimmed).
  static List<Map<String, String>> records(List<List<String>> rows, {int headerRow = 0}) {
    if (rows.length <= headerRow) return const [];
    final header = [for (final h in rows[headerRow]) h.trim().toLowerCase()];
    return [
      for (final r in rows.skip(headerRow + 1))
        {for (var i = 0; i < header.length && i < r.length; i++) header[i]: r[i]},
    ];
  }
}

// ---------------------------------------------------------------------------------------------
// Loop Habit Tracker

/// Loop Habit Tracker (CSV export zip or `.db` backup) → habits + check-ins.
abstract final class LoopImport {
  /// From the CSV export: `Habits.csv` + the top-level `Checkmarks.csv` (falling back to each
  /// habit folder's `Checkmarks.csv`, keyed by the folder's position prefix).
  static ExternalImportPlan fromCsv(Map<String, String> files) {
    // The export may sit in a folder of its own; per-habit folders are one level below it.
    final habitsPath = files.keys
        .where((k) => k.split('/').last.toLowerCase() == 'habits.csv')
        .fold<String?>(null, (best, k) => best == null || k.length < best.length ? k : best);
    if (habitsPath == null) throw const FormatException('loop_missing_habits');
    final root = habitsPath.substring(0, habitsPath.length - 'habits.csv'.length);
    final habitsCsv = files[habitsPath]!;
    String? top(String name) {
      for (final e in files.entries) {
        if (e.key.toLowerCase() == '$root$name'.toLowerCase()) return e.value;
      }
      return null;
    }

    final rows = CsvReader.records(CsvReader.parse(habitsCsv));
    final notes = <ImportNote, int>{};
    final meta = <_LoopHabit>[];
    for (final r in rows) {
      final name = (r['name'] ?? '').trim();
      if (name.isEmpty) continue;
      final num = int.tryParse(r['frequencynumerator'] ?? r['numrepetitions'] ?? '') ?? 1;
      final den = int.tryParse(r['frequencydenominator'] ?? r['interval'] ?? '') ?? 1;
      meta.add(
        _LoopHabit(
          position: int.tryParse(r['position'] ?? '') ?? meta.length + 1,
          name: name,
          question: r['question'],
          description: r['description'],
          numerical: (r['type'] ?? '0').trim() == '1' || (r['type'] ?? '').toLowerCase().contains('numer'),
          freqNum: num,
          freqDen: den,
          color: _loopColor(r['color']),
          unit: r['unit'],
          atMost: (r['target type'] ?? '0').trim() == '1' || (r['target type'] ?? '').toLowerCase().contains('most'),
          targetValue: double.tryParse(r['target value'] ?? ''),
          archived: (r['archived?'] ?? r['archived'] ?? '').toLowerCase().startsWith('t'),
        ),
      );
    }

    final checks = <String, List<ExternalCheck>>{for (final h in meta) h.name: []};
    final topCheckmarks = top('Checkmarks.csv');
    if (topCheckmarks != null) {
      final table = CsvReader.parse(topCheckmarks);
      if (table.isNotEmpty) {
        final header = table.first;
        for (final row in table.skip(1)) {
          final date = row.isEmpty ? null : LocalDate.tryParse(row.first.trim());
          if (date == null) continue;
          for (var c = 1; c < header.length && c < row.length; c++) {
            final habit = meta.where((h) => h.name == header[c].trim()).firstOrNull;
            if (habit == null) continue;
            final check = _loopCheck(date, row[c], numerical: habit.numerical);
            if (check != null) checks[habit.name]!.add(check);
          }
        }
      }
    } else {
      for (final e in files.entries) {
        final parts = e.key.split('/');
        if (parts.length < 2 || parts.last.toLowerCase() != 'checkmarks.csv') continue;
        final position = int.tryParse(parts[parts.length - 2].split(' ').first);
        final habit = meta.where((h) => h.position == position).firstOrNull;
        if (habit == null) continue;
        for (final row in CsvReader.parse(e.value)) {
          final date = row.isEmpty ? null : LocalDate.tryParse(row.first.trim());
          if (date == null || row.length < 2) continue;
          final check = _loopCheck(date, row[1], numerical: habit.numerical);
          if (check != null) checks[habit.name]!.add(check);
        }
      }
    }
    return ExternalImportPlan(
      source: ExternalSource.loop,
      habits: [for (final h in meta) h.toHabit(checks[h.name]!, notes)],
      notes: notes,
    );
  }

  /// From a `.db` backup: rows of its `Habits` and `Repetitions` tables (read by the data layer).
  static ExternalImportPlan fromDatabase({
    required List<Map<String, Object?>> habits,
    required List<Map<String, Object?>> repetitions,
  }) {
    final notes = <ImportNote, int>{};
    final byId = <Object?, _LoopHabit>{};
    for (final r in habits) {
      final name = '${r['name'] ?? ''}'.trim();
      if (name.isEmpty) continue;
      byId[r['id']] = _LoopHabit(
        position: (r['position'] as num?)?.toInt() ?? byId.length,
        name: name,
        question: r['question'] as String?,
        description: r['description'] as String?,
        numerical: (r['type'] as num?)?.toInt() == 1,
        freqNum: (r['freq_num'] as num?)?.toInt() ?? 1,
        freqDen: (r['freq_den'] as num?)?.toInt() ?? 1,
        color: _loopColor('${r['color'] ?? ''}'),
        unit: r['unit'] as String?,
        atMost: (r['target_type'] as num?)?.toInt() == 1,
        targetValue: (r['target_value'] as num?)?.toDouble(),
        archived: (r['archived'] as num?)?.toInt() == 1,
      );
    }
    final checks = <Object?, List<ExternalCheck>>{for (final id in byId.keys) id: []};
    for (final r in repetitions) {
      final habit = byId[r['habit']];
      final ms = (r['timestamp'] as num?)?.toInt();
      if (habit == null || ms == null) continue;
      final day = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      final check = _loopCheck(
        LocalDate(day.year, day.month, day.day),
        '${r['value'] ?? ''}',
        numerical: habit.numerical,
      );
      if (check != null) checks[r['habit']]!.add(check);
    }
    final sorted = byId.entries.toList()..sort((a, b) => a.value.position.compareTo(b.value.position));
    return ExternalImportPlan(
      source: ExternalSource.loop,
      habits: [for (final e in sorted) e.value.toHabit(checks[e.key]!, notes)],
      notes: notes,
    );
  }

  // Loop values: 2 = done (manual), 1 = implied by the frequency, 0 = not done, 3 = skipped,
  // -1 = unknown; numerical habits store the amount × 1000.
  static ExternalCheck? _loopCheck(LocalDate date, String raw, {required bool numerical}) {
    final v = raw.trim().toUpperCase();
    if (v.isEmpty) return null;
    if (numerical) {
      final n = double.tryParse(v);
      if (n == null || n <= 0) return null;
      return ExternalCheck(date, ExternalCheckKind.done, value: n / 1000);
    }
    return switch (v) {
      '2' || 'YES_MANUAL' || 'YES' => ExternalCheck(date, ExternalCheckKind.done),
      '3' || 'SKIP' => ExternalCheck(date, ExternalCheckKind.skip),
      _ => null,
    };
  }

  static ExternalColor? _loopColor(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.startsWith('#') && v.length == 7) {
      final argb = int.tryParse('FF${v.substring(1)}', radix: 16);
      return argb == null ? null : ExternalColor.argb(argb);
    }
    final index = int.tryParse(v);
    return index == null ? null : ExternalColor.palette(index);
  }
}

class _LoopHabit {
  _LoopHabit({
    required this.position,
    required this.name,
    required this.numerical,
    required this.freqNum,
    required this.freqDen,
    required this.atMost,
    required this.archived,
    this.question,
    this.description,
    this.color,
    this.unit,
    this.targetValue,
  });

  final int position;
  final String name;
  final String? question;
  final String? description;
  final bool numerical;
  final int freqNum;
  final int freqDen;
  final ExternalColor? color;
  final String? unit;
  final bool atMost;
  final double? targetValue;
  final bool archived;

  ExternalHabit toHabit(List<ExternalCheck> checks, Map<ImportNote, int> notes) {
    final (preset, exact) = numerical ? (const SchedulePreset.daily(), freqDen <= 1) : _preset(freqNum, freqDen);
    if (!exact) notes[ImportNote.frequencyApproximated] = (notes[ImportNote.frequencyApproximated] ?? 0) + 1;
    final text = [
      if ((question ?? '').trim().isNotEmpty) question!.trim(),
      if ((description ?? '').trim().isNotEmpty) description!.trim(),
    ].join('\n');
    // Numerical targets are per Loop period; Everslot measures them per day.
    final perDay = (targetValue ?? 1) / (freqDen < 1 ? 1 : freqDen);
    return ExternalHabit(
      name: name,
      description: text.isEmpty ? null : text,
      preset: preset,
      goal: numerical
          ? HabitTarget(
              type: HabitGoalType.numeric,
              target: double.parse(perDay.toStringAsFixed(2)),
              op: atMost ? TargetOp.lte : TargetOp.gte,
              unit: (unit ?? '').trim().isEmpty ? null : unit!.trim(),
            )
          : const HabitTarget.check(),
      archived: archived,
      color: color,
      checks: checks..sort((a, b) => a.date.compareTo(b.date)),
    );
  }

  /// Loop's "N times in D days" → (preset, exact).
  static (SchedulePreset, bool) _preset(int n, int d) {
    if (n <= 0 || d <= 0) return (const SchedulePreset.daily(), false);
    if (n == d) return (const SchedulePreset.daily(), true);
    if (n == 1) return (SchedulePreset(SchedulePresetKind.everyNDays, n: d), true);
    if (d == 7) return (SchedulePreset(SchedulePresetKind.timesPerWeek, n: n), true);
    if (d == 30 || d == 31) return (SchedulePreset(SchedulePresetKind.timesPerMonth, n: n), true);
    final perWeek = (n * 7 / d).round().clamp(1, 7);
    return (
      perWeek >= 7 ? const SchedulePreset.daily() : SchedulePreset(SchedulePresetKind.timesPerWeek, n: perWeek),
      false,
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Google Keep

/// Google Keep (Takeout `Keep/*.json`) → lists (checklists, or a body for text notes).
abstract final class KeepImport {
  static const _colors = {
    'RED': 1,
    'ORANGE': 8,
    'YELLOW': 3,
    'GREEN': 2,
    'TEAL': 10,
    'BLUE': 0,
    'CERULEAN': 14,
    'PURPLE': 4,
    'PINK': 6,
    'BROWN': 15,
    'GRAY': 12,
  };

  /// [notes]: decoded note files (path → JSON object).
  static ExternalImportPlan fromNotes(Map<String, Map<String, Object?>> notes) {
    final counts = <ImportNote, int>{};
    final lists = <ExternalList>[];
    final entries = notes.entries.toList()
      ..sort(
        (a, b) => ((b.value['userEditedTimestampUsec'] as num?) ?? 0).compareTo(
          (a.value['userEditedTimestampUsec'] as num?) ?? 0,
        ),
      );
    for (final e in entries) {
      final n = e.value;
      if (n['isTrashed'] == true) {
        counts[ImportNote.trashedSkipped] = (counts[ImportNote.trashedSkipped] ?? 0) + 1;
        continue;
      }
      final dir = e.key.contains('/') ? e.key.substring(0, e.key.lastIndexOf('/') + 1) : '';
      final items = [
        for (final i in (n['listContent'] as List?) ?? const [])
          if (i is Map && '${i['text'] ?? ''}'.trim().isNotEmpty)
            ExternalItem('${i['text']}'.trim(), checked: i['isChecked'] == true),
      ];
      final text = '${n['textContent'] ?? ''}'.trim();
      final title = '${n['title'] ?? ''}'.trim();
      if (title.isEmpty && text.isEmpty && items.isEmpty) continue;
      lists.add(
        ExternalList(
          title: title,
          body: text.isEmpty ? null : text,
          items: items,
          pinned: n['isPinned'] == true,
          archived: n['isArchived'] == true,
          color: switch (_colors['${n['color'] ?? ''}'.toUpperCase()]) {
            final int i => ExternalColor.palette(i),
            null => null,
          },
          labels: [
            for (final l in (n['labels'] as List?) ?? const [])
              if (l is Map && '${l['name'] ?? ''}'.trim().isNotEmpty) '${l['name']}'.trim(),
          ],
          files: [
            for (final a in (n['attachments'] as List?) ?? const [])
              if (a is Map && a['filePath'] is String) '$dir${a['filePath']}',
          ],
        ),
      );
    }
    return ExternalImportPlan(source: ExternalSource.keep, lists: lists, notes: counts);
  }
}

// ---------------------------------------------------------------------------------------------
// Todoist / TickTick

abstract final class TodoistImport {
  /// Todoist project CSV (`TYPE,CONTENT,DESCRIPTION,PRIORITY,INDENT,…,DATE,…`). Dates are natural
  /// language and go through the quick-add parser, best effort.
  static ExternalImportPlan parse(String csv, {required LocalDateTime now, Weekday weekStart = Weekday.monday}) {
    final notes = <ImportNote, int>{};
    final tasks = <ExternalTask>[];
    final records = CsvReader.records(CsvReader.parse(csv));
    if (records.isNotEmpty && !records.first.containsKey('content')) throw const FormatException('todoist_header');
    String? section;
    for (final r in records) {
      final type = (r['type'] ?? '').trim().toLowerCase();
      final content = (r['content'] ?? '').trim();
      if (type == 'section') {
        section = content.isEmpty ? null : content;
        continue;
      }
      if (type == 'note' && tasks.isNotEmpty && content.isNotEmpty) {
        final last = tasks.removeLast();
        tasks.add(_withNotes(last, [?last.notes, content].join('\n\n')));
        continue;
      }
      if (type != 'task' || content.isEmpty) continue;
      // Inline @labels of the content.
      final labels = [for (final m in RegExp(r'(?:^|\s)@([\p{L}\p{N}_-]+)', unicode: true).allMatches(content)) m[1]!];
      final title = content.replaceAll(RegExp(r'(?:^|\s)@[\p{L}\p{N}_-]+', unicode: true), '').trim();
      final dateText = (r['date'] ?? '').trim();
      LocalDateTime? start;
      RecurrenceRule? rule;
      var allDay = false;
      int? minutes;
      if (dateText.isNotEmpty) {
        final q = QuickParser.parse(dateText, now: now, weekStart: weekStart);
        rule = q.rule;
        if (q.date != null) {
          allDay = q.time == null;
          start = LocalDateTime(q.date!, q.time ?? LocalTime.midnight);
        } else if (rule != null) {
          allDay = q.time == null;
          start = LocalDateTime(now.date, q.time ?? LocalTime.midnight);
        }
        if (start == null || (dateText.toLowerCase().startsWith('every') && rule == null)) {
          notes[ImportNote.repeatNotUnderstood] = (notes[ImportNote.repeatNotUnderstood] ?? 0) + 1;
        }
      }
      final duration = int.tryParse((r['duration'] ?? '').trim());
      if (duration != null && duration > 0 && !allDay) {
        minutes = (r['duration_unit'] ?? '').toLowerCase().startsWith('day') ? duration * 1440 : duration;
      }
      final description = (r['description'] ?? '').trim();
      tasks.add(
        ExternalTask(
          title: title.isEmpty ? content : title,
          notes: description.isEmpty ? null : description,
          start: start,
          allDay: allDay,
          durationMinutes: minutes,
          timeZone: (r['timezone'] ?? '').trim().isEmpty ? null : r['timezone']!.trim(),
          rule: rule,
          // Todoist: 1 = P1 (highest) … 4 = P4 (none).
          priority: switch ((r['priority'] ?? '').trim()) {
            '1' => 4,
            '2' => 3,
            '3' => 2,
            _ => 0,
          },
          labels: [...labels, ?section],
        ),
      );
    }
    return ExternalImportPlan(source: ExternalSource.todoist, tasks: tasks, notes: notes);
  }

  static ExternalTask _withNotes(ExternalTask t, String notes) => ExternalTask(
    title: t.title,
    notes: notes,
    start: t.start,
    allDay: t.allDay,
    durationMinutes: t.durationMinutes,
    timeZone: t.timeZone,
    rule: t.rule,
    priority: t.priority,
    labels: t.labels,
  );
}

abstract final class TickTickImport {
  /// TickTick backup CSV: a few metadata lines, then `"Folder Name","List Name","Title",…`.
  /// Open tasks only; RRULE repeats are kept when the recurrence engine reads them.
  static ExternalImportPlan parse(String csv, {ZoneResolver? resolver}) {
    final rows = CsvReader.parse(csv);
    final headerAt = rows.indexWhere((r) => r.map((c) => c.trim().toLowerCase()).contains('title'));
    if (headerAt < 0) throw const FormatException('ticktick_header');
    final notes = <ImportNote, int>{};
    final tasks = <ExternalTask>[];
    for (final r in CsvReader.records(rows, headerRow: headerAt)) {
      final title = (r['title'] ?? '').trim();
      if (title.isEmpty) continue;
      final status = (r['status'] ?? '0').trim();
      if (status != '0' && status.isNotEmpty) {
        notes[ImportNote.completedSkipped] = (notes[ImportNote.completedSkipped] ?? 0) + 1;
        continue;
      }
      final allDay = (r['is all day'] ?? '').trim().toLowerCase() == 'true';
      final zone = (r['timezone'] ?? '').trim();
      final startRaw = (r['start date'] ?? '').trim().isNotEmpty ? r['start date']! : (r['due date'] ?? '');
      final start = _instant(startRaw.trim(), zone.isEmpty ? null : zone, resolver);
      final due = _instant((r['due date'] ?? '').trim(), zone.isEmpty ? null : zone, resolver);
      RecurrenceRule? rule;
      final repeat = (r['repeat'] ?? '').trim();
      if (repeat.isNotEmpty && start != null) {
        try {
          rule = RRuleCodec.parse(repeat.startsWith('RRULE:') ? repeat : 'RRULE:$repeat', resolver: resolver).rule;
        } on FormatException {
          notes[ImportNote.repeatNotUnderstood] = (notes[ImportNote.repeatNotUnderstood] ?? 0) + 1;
        }
      }
      final minutes = start != null && due != null && !allDay
          ? due.toDateTimeUtc().difference(start.toDateTimeUtc()).inMinutes
          : null;
      final content = (r['content'] ?? '').trim();
      tasks.add(
        ExternalTask(
          title: title,
          notes: content.isEmpty ? null : content,
          start: start == null ? null : (allDay ? start.date.atStartOfDay : start),
          allDay: allDay,
          durationMinutes: minutes != null && minutes > 0 ? minutes : null,
          timeZone: zone.isEmpty ? null : zone,
          rule: rule,
          priority: switch ((r['priority'] ?? '').trim()) {
            '5' => 3,
            '3' => 2,
            '1' => 1,
            _ => 0,
          },
          labels: [
            for (final t in (r['tags'] ?? '').split(','))
              if (t.trim().isNotEmpty) t.trim(),
            if ((r['list name'] ?? '').trim().isNotEmpty) r['list name']!.trim(),
          ],
        ),
      );
    }
    return ExternalImportPlan(source: ExternalSource.tickTick, tasks: tasks, notes: notes);
  }

  // `2026-09-22T09:00:00+0000` → wall clock in [zone] (UTC when unknown).
  static LocalDateTime? _instant(String raw, String? zone, ZoneResolver? resolver) {
    if (raw.isEmpty) return null;
    final normalized = raw.replaceFirstMapped(RegExp(r'([+-]\d\d)(\d\d)$'), (m) => '${m[1]}:${m[2]}');
    final t = DateTime.tryParse(normalized);
    if (t == null) return null;
    final utc = t.toUtc();
    if (zone != null && resolver != null) {
      try {
        return resolver.toLocal(utc, zone);
      } on Object {
        // unknown zone → UTC wall clock
      }
    }
    return LocalDateTime(LocalDate(utc.year, utc.month, utc.day), LocalTime(utc.hour, utc.minute));
  }
}
