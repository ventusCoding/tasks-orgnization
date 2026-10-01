// Synthetic datasets of the stats performance suite (T6.1.23), streamed into an in-memory Drift
// database with multi-row INSERTs. Every dataset is deterministic (hash-based, no `Random`) and scales
// with a factor: 1.0 is the arch §9.6 reference size, smaller factors keep the default test run fast.
import 'dart:convert';
import 'dart:math' as math;

import 'package:everslot/core/database/app_database.dart';

/// Row counts of a seeded dataset (recorded in the perf report).
typedef PerfCounts = Map<String, int>;

const perfUserId = 'user-1';
const perfZone = 'Europe/Paris';

/// Deterministic pseudo-random 0…99 from two integers.
int hash100(int a, int b) => ((((a + 1) * 73856093) ^ ((b + 1) * 19349663)) & 0x7fffffff) % 100;

int hashInt(int a, int b) => (((a + 1) * 73856093) ^ ((b + 1) * 19349663)) & 0x7fffffff;

String _p2(int n) => n.toString().padLeft(2, '0');

String isoDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_p2(d.month)}-${_p2(d.day)}';

String isoInstant(DateTime d) => d.toUtc().toIso8601String();

String isoLocal(DateTime day, int minuteOfDay) => '${isoDay(day)}T${_p2(minuteOfDay ~/ 60)}:${_p2(minuteOfDay % 60)}';

Object? _sql(Object? v) => switch (v) {
  final bool b => b ? 1 : 0,
  final DateTime d => isoInstant(d),
  final Map<Object?, Object?> m => jsonEncode(m),
  final List<Object?> l => jsonEncode(l),
  _ => v,
};

/// Streams [rows] into [table] (values aligned with [columns]) in one transaction, [chunk] rows per
/// statement (SQLite allows 32 766 variables). Returns the number of rows written.
Future<int> bulkInsert(
  AppDatabase db,
  String table,
  List<String> columns,
  Iterable<List<Object?>> rows, {
  int chunk = 250,
}) async {
  var count = 0;
  final tuple = '(${List.filled(columns.length, '?').join(',')})';
  final head = 'INSERT INTO $table (${columns.join(',')}) VALUES ';
  final args = <Object?>[];
  var inChunk = 0;
  await db.transaction(() async {
    Future<void> flush() async {
      if (inChunk == 0) return;
      await db.customStatement('$head${List.filled(inChunk, tuple).join(',')}', List<Object?>.of(args));
      args.clear();
      inChunk = 0;
    }

    for (final row in rows) {
      assert(row.length == columns.length, '$table row has ${row.length} values for ${columns.length} columns');
      for (final v in row) {
        args.add(_sql(v));
      }
      inChunk++;
      count++;
      if (inChunk == chunk) await flush();
    }
    await flush();
  });
  return count;
}

/// The synced columns every row carries.
List<Object?> _base(String id, DateTime created) => [id, perfUserId, created, created];

const _syncedColumns = ['id', 'user_id', 'created_at', 'updated_at'];

// ---------------------------------------------------------------------------------------------
// Habits: 30 habits × 5 years of daily logs (~50 k logs at scale 1)
// ---------------------------------------------------------------------------------------------

const _dailyScheduleJson = '{"v": 1, "type": "fixed", "freq": "daily", "interval": 1}';
const _weekdaysScheduleJson =
    '{"v": 1, "type": "fixed", "freq": "weekly", "interval": 1, "byWeekday": '
    '[{"day": "MO"}, {"day": "TU"}, {"day": "WE"}, {"day": "TH"}, {"day": "FR"}]}';
const _quotaScheduleJson =
    '{"v": 1, "type": "quota", "freq": "weekly", "interval": 1, "quota": {"times": 3, "per": "week", "minGapDays": 0}}';

/// Seeds [30 × scale] habits with [1826 × scale] days of logs each (a mix of yes/no, count, duration,
/// limit, weekday and weekly-quota habits).
Future<PerfCounts> seedHabitPerf(AppDatabase db, {required DateTime now, required double scale}) async {
  final habitCount = math.max(3, (30 * scale).round());
  final days = math.max(60, (1826 * scale).round());
  final today = DateTime.utc(now.year, now.month, now.day);
  final start = today.subtract(Duration(days: days));
  final created = start.subtract(const Duration(days: 1));

  ({String goal, String op, num? target, String schedule}) kind(int h) => switch (h % 6) {
    0 => (goal: 'check', op: 'gte', target: null, schedule: _dailyScheduleJson),
    1 => (goal: 'count', op: 'gte', target: 8, schedule: _dailyScheduleJson),
    2 => (goal: 'check', op: 'gte', target: null, schedule: _weekdaysScheduleJson),
    3 => (goal: 'count', op: 'lte', target: 2, schedule: _dailyScheduleJson),
    4 => (goal: 'duration', op: 'gte', target: 30, schedule: _dailyScheduleJson),
    _ => (goal: 'check', op: 'gte', target: null, schedule: _quotaScheduleJson),
  };

  final habits = await bulkInsert(
    db,
    'habits',
    [
      ..._syncedColumns,
      'kind',
      'name',
      'sort_key',
      'goal_type',
      'target_op',
      'target_value',
      'schedule',
      'start_date',
      'time_zone',
      'auto_success',
    ],
    [
      for (var h = 0; h < habitCount; h++)
        [
          ..._base('h$h', created),
          'build',
          'Habit $h',
          'h${h.toString().padLeft(3, '0')}',
          kind(h).goal,
          kind(h).op,
          kind(h).target,
          kind(h).schedule,
          isoDay(start),
          perfZone,
          h % 6 == 3,
        ],
    ],
  );

  Iterable<List<Object?>> logs() sync* {
    var n = 0;
    for (var h = 0; h < habitCount; h++) {
      final k = kind(h);
      for (var d = 0; d < days; d++) {
        final day = start.add(Duration(days: d));
        final skip = switch (h % 6) {
          2 => day.weekday > 5 || hash100(h, d) >= 92,
          5 => (day.weekday != 1 && day.weekday != 3 && day.weekday != 5) || hash100(h, d) >= 88,
          _ => hash100(h, d) >= 92,
        };
        if (skip) continue;
        final at = DateTime.utc(day.year, day.month, day.day, 17);
        final progress = k.goal == 'count' || k.goal == 'duration';
        final value = switch (h % 6) {
          1 => 4 + hash100(h, d + 7) % 7,
          3 => hash100(h, d + 11) % 5,
          4 => 10 + hash100(h, d + 13) % 60,
          _ => null,
        };
        yield [..._base('l${n++}', at), 'h$h', progress ? 'progress' : 'done', at, isoDay(day), isoDay(day), value];
      }
    }
  }

  final logCount = await bulkInsert(db, 'habit_logs', [
    ..._syncedColumns,
    'habit_id',
    'kind',
    'logged_at',
    'local_date',
    'occurrence_key',
    'value',
  ], logs());
  return {'habits': habits, 'habit_logs': logCount};
}

// ---------------------------------------------------------------------------------------------
// Planner: 2 000 tasks with 3 years of occurrences
// ---------------------------------------------------------------------------------------------

/// Seeds [200 × scale] recurring series (daily, weekdays, Mon/Wed/Fri, weekly) and [1 800 × scale]
/// one-off tasks spread over [1 095 × scale] days, with done/skipped occurrence rows (about 80 % of
/// the past occurrences) and one timer session per finished timer occurrence.
Future<PerfCounts> seedPlannerPerf(AppDatabase db, {required DateTime now, required double scale}) async {
  final seriesCount = math.max(4, (200 * scale).round());
  final oneOffCount = math.max(30, (1800 * scale).round());
  final days = math.max(90, (1095 * scale).round());
  final today = DateTime.utc(now.year, now.month, now.day);
  final start = today.subtract(Duration(days: days));

  final categories = await bulkInsert(
    db,
    'categories',
    [..._syncedColumns, 'name', 'color', 'sort_key', 'counts_as_unavailable'],
    [
      for (var c = 0; c < 8; c++) [..._base('c$c', start), 'Category $c', 0xFF000000 + c * 0x203040, 'c$c', false],
    ],
  );

  String mode(int i) => switch (hash100(i, 3)) {
    < 60 => 'check',
    < 85 => 'timer',
    _ => 'event',
  };
  int startMinute(int i) => 360 + (hash100(i, 5) % 32) * 30;
  int duration(int i) => const [15, 30, 45, 60, 90, 120][hash100(i, 9) % 6];

  bool onDay(int s, DateTime day) => switch (s % 4) {
    0 => true,
    1 => day.weekday <= 5,
    2 => day.weekday == 1 || day.weekday == 3 || day.weekday == 5,
    _ => day.weekday == 1 + s % 7,
  };
  String recurrence(int s) => switch (s % 4) {
    0 => _dailyScheduleJson,
    1 => _weekdaysScheduleJson,
    2 =>
      '{"v": 1, "type": "fixed", "freq": "weekly", "interval": 1, "byWeekday": '
          '[{"day": "MO"}, {"day": "WE"}, {"day": "FR"}]}',
    _ =>
      '{"v": 1, "type": "fixed", "freq": "weekly", "interval": 1, "byWeekday": '
          '[{"day": "${const ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'][s % 7]}"}]}',
  };

  const taskColumns = [
    ..._syncedColumns,
    'series_id',
    'title',
    'category_id',
    'priority',
    'tracking_mode',
    'is_all_day',
    'start_local',
    'duration_minutes',
    'time_zone',
    'recurrence',
    'status',
  ];
  Iterable<List<Object?>> tasks() sync* {
    for (var s = 0; s < seriesCount; s++) {
      final first = start.add(Duration(days: hash100(s, 1) % 60));
      yield [
        ..._base('s$s', start),
        's$s',
        'Series $s',
        'c${s % 8}',
        s % 4,
        mode(s),
        false,
        isoLocal(first, startMinute(s)),
        duration(s),
        perfZone,
        recurrence(s),
        'active',
      ];
    }
    for (var o = 0; o < oneOffCount; o++) {
      final i = seriesCount + o;
      final day = start.add(Duration(days: hashInt(i, 2) % (days + 30)));
      yield [
        ..._base('t$o', start),
        't$o',
        'Task $o',
        'c${o % 8}',
        o % 4,
        mode(i),
        false,
        isoLocal(day, startMinute(i)),
        duration(i),
        perfZone,
        null,
        'active',
      ];
    }
  }

  final taskCount = await bulkInsert(db, 'tasks', taskColumns, tasks());

  var timeEntries = 0;
  final entryRows = <List<Object?>>[];
  Iterable<List<Object?>> occurrences() sync* {
    var n = 0;
    void entry(String taskId, String key, DateTime from, int minutes) {
      entryRows.add([..._base('e${timeEntries++}', from), taskId, key, from, from.add(Duration(minutes: minutes))]);
    }

    List<Object?> row(String taskId, String key, DateTime at, String status) => [
      ..._base('o${n++}', at),
      taskId,
      key,
      status,
      status == 'done' ? at : null,
      at,
    ];

    for (var s = 0; s < seriesCount; s++) {
      final first = start.add(Duration(days: hash100(s, 1) % 60));
      final minute = startMinute(s);
      final timer = mode(s) == 'timer';
      for (var day = first; day.isBefore(today); day = day.add(const Duration(days: 1))) {
        if (!onDay(s, day)) continue;
        final r = hash100(s, day.difference(start).inDays);
        if (r >= 85) continue; // open / missed
        final key = isoLocal(day, minute);
        final at = DateTime.utc(
          day.year,
          day.month,
          day.day,
          minute ~/ 60,
          minute % 60,
        ).subtract(const Duration(hours: 1));
        final done = r < 80;
        yield row('s$s', key, at.add(Duration(minutes: duration(s))), done ? 'done' : 'skipped');
        if (done && timer) entry('s$s', key, at, duration(s) - 5 + r % 11);
      }
    }
    for (var o = 0; o < oneOffCount; o++) {
      final i = seriesCount + o;
      final day = start.add(Duration(days: hashInt(i, 2) % (days + 30)));
      if (!day.isBefore(today)) continue;
      final r = hash100(i, 4);
      if (r >= 78) continue;
      final minute = startMinute(i);
      final key = isoLocal(day, minute);
      final at = DateTime.utc(
        day.year,
        day.month,
        day.day,
        minute ~/ 60,
        minute % 60,
      ).subtract(const Duration(hours: 1));
      final done = r < 70;
      yield row('t$o', key, at.add(Duration(minutes: duration(i))), done ? 'done' : 'skipped');
      if (done && mode(i) == 'timer') entry('t$o', key, at, duration(i));
    }
  }

  final occurrenceCount = await bulkInsert(db, 'task_occurrences', [
    ..._syncedColumns,
    'task_id',
    'occurrence_key',
    'status',
    'completed_at',
    'status_changed_at',
  ], occurrences());
  final entryCount = await bulkInsert(db, 'time_entries', [
    ..._syncedColumns,
    'task_id',
    'occurrence_key',
    'started_at',
    'ended_at',
  ], entryRows);
  return {
    'categories': categories,
    'tasks': taskCount,
    'task_occurrences': occurrenceCount,
    'time_entries': entryCount,
  };
}

// ---------------------------------------------------------------------------------------------
// Checklists: 50 lists (the largest with 5 000 items) and ~100 k status events
// ---------------------------------------------------------------------------------------------

/// Item counts of the seeded lists: list k holds `5 000 × scale / (k + 1)^0.9` items (at least 20), so the
/// largest list is the 5 000-item stress case and the 50 lists total about 30 000 items.
List<int> checklistSizes(double scale, {int lists = 50}) => [
  for (var k = 0; k < math.max(2, (lists * scale.clamp(0.1, 1)).round()); k++)
    math.max(20, (5000 * scale / math.pow(k + 1, 0.9)).round()),
];

/// Seeds the lists of [checklistSizes]: items nested up to 12 levels with 1–4 status events each
/// (created, todo → ongoing → completed, waiting / blocked detours) spread over the last two years.
Future<PerfCounts> seedChecklistPerf(AppDatabase db, {required DateTime now, required double scale}) async {
  final sizes = checklistSizes(scale);
  final today = DateTime.utc(now.year, now.month, now.day);
  final origin = today.subtract(const Duration(days: 730));

  final lists = await bulkInsert(
    db,
    'checklists',
    [..._syncedColumns, 'title', 'sort_key'],
    [
      for (var k = 0; k < sizes.length; k++) [..._base('L$k', origin), 'List $k', 'l${k.toString().padLeft(3, '0')}'],
    ],
  );

  var eventNo = 0;
  final events = <List<Object?>>[];
  Iterable<List<Object?>> items() sync* {
    for (var k = 0; k < sizes.length; k++) {
      final depths = <int>[];
      final n = sizes[k];
      for (var i = 0; i < n; i++) {
        final created = origin.add(Duration(minutes: (i * 730 * 24 * 60 / n).floor() + hash100(k, i) % 600));
        // Nesting: half of the items hang under a recent item, at most 12 levels deep.
        var parent = -1;
        if (i > 0 && hash100(k, i + 1000) < 50) {
          parent = math.max(0, i - 1 - hash100(k, i + 2000) % 4);
          if (depths[parent] >= 11) parent = -1;
        }
        depths.add(parent < 0 ? 0 : depths[parent] + 1);
        final path = switch (hash100(k, i + 3000)) {
          < 40 => 'todo>ongoing>completed',
          < 55 => 'todo>ongoing>waiting>ongoing>completed',
          < 65 => 'todo>blocked>ongoing>completed',
          < 75 => 'todo>completed',
          < 85 => 'todo>ongoing>blocked>ongoing>waiting>ongoing>completed',
          < 93 => 'todo>ongoing',
          _ => 'todo',
        };
        final steps = path.split('>');
        var at = created;
        void event(String type, Map<String, Object?> payload) => events.add([
          ..._base('v${eventNo++}', at),
          'checklist_item',
          'i$k-$i',
          'L$k',
          type,
          {...payload, 'opId': 'op$eventNo', 'cause': 'user'},
          at,
        ]);
        event('created', {'to': 'todo'});
        var last = 'todo';
        for (var s = 1; s < steps.length; s++) {
          final next = at.add(Duration(hours: 6 + hashInt(k * 7 + s, i) % 24 * 9));
          if (next.isAfter(now)) break;
          at = next;
          event('status_changed', {
            'from': last,
            'to': steps[s],
            'note': steps[s] == 'waiting' || steps[s] == 'blocked' ? 'reason ${i % 5}' : null,
          });
          last = steps[s];
        }
        yield [
          ..._base('i$k-$i', created),
          'L$k',
          parent < 0 ? null : 'i$k-$parent',
          'k${i.toString().padLeft(6, '0')}',
          'Item $i',
          last,
          at,
          last == 'completed' ? at : null,
        ];
      }
    }
  }

  final itemCount = await bulkInsert(db, 'checklist_items', [
    ..._syncedColumns,
    'checklist_id',
    'parent_id',
    'sort_key',
    'text',
    'status',
    'status_changed_at',
    'completed_at',
  ], items());
  final eventCount = await bulkInsert(db, 'activity_events', [
    ..._syncedColumns,
    'entity_type',
    'entity_id',
    'parent_id',
    'event_type',
    'payload',
    'occurred_at',
  ], events);
  return {'checklists': lists, 'checklist_items': itemCount, 'activity_events': eventCount};
}
