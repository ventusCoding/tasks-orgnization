import 'dart:math';

import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/planner/domain/planner_item.dart' show OccurrenceStatus;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Sample data for screenshots, demos and manual stats testing (T8.3.16). Pure and deterministic:
/// the same seed and day give the same dataset.

/// Texts of the generated items, in the user's language (provided by the application layer).
@immutable
class DemoTexts {
  const DemoTexts({
    required this.tasks,
    required this.lists,
    required this.habits,
    required this.quitName,
    required this.cravingTriggers,
  });

  /// Keyed by [DemoGenerator.taskKeys].
  final Map<String, String> tasks;

  /// Lists: title + indented outline (parsed by the application).
  final List<({String title, List<DemoNode> nodes})> lists;

  /// Keyed by [DemoGenerator.habitKeys].
  final Map<String, String> habits;
  final String quitName;
  final List<String> cravingTriggers;
}

@immutable
class DemoNode {
  const DemoNode(this.text, {this.status = ItemStatus.todo, this.statusNote, this.children = const []});

  final String text;
  final ItemStatus status;
  final String? statusNote;
  final List<DemoNode> children;

  int get size => 1 + children.fold(0, (a, c) => a + c.size);
}

@immutable
class DemoTask {
  const DemoTask({
    required this.key,
    required this.title,
    required this.start,
    required this.durationMinutes,
    this.rule,
    this.weekdays,
    this.categoryKey,
    this.priority = 0,
    this.history = const [],
  });

  final String key;
  final String title;
  final LocalDateTime start;
  final int durationMinutes;
  final RecurrenceRule? rule;

  /// Days the rule falls on (null = every day), for [history].
  final Set<Weekday>? weekdays;

  /// Default category key (`work`, `health`, …).
  final String? categoryKey;
  final int priority;

  /// Past occurrences with an explicit status (others stay as the resolver derives them).
  final List<({String key, LocalDateTime start, OccurrenceStatus status})> history;
}

@immutable
class DemoHabit {
  const DemoHabit({
    required this.key,
    required this.name,
    required this.preset,
    required this.goal,
    required this.days,
  });

  final String key;
  final String name;
  final SchedulePreset preset;
  final HabitTarget goal;

  /// First day with history (the habit starts then).
  LocalDate? get start => days.isEmpty ? null : days.first.date;

  /// Check-ins: a done day, or an amount for measurable habits.
  final List<({LocalDate date, double? value})> days;
}

@immutable
class DemoCraving {
  const DemoCraving(this.at, {required this.intensity, required this.resisted, this.trigger});

  final LocalDateTime at;
  final int intensity;
  final bool resisted;
  final String? trigger;
}

@immutable
class DemoQuit {
  const DemoQuit({required this.name, required this.quitAt, required this.relapses, required this.cravings});

  final String name;
  final LocalDateTime quitAt;
  final List<LocalDateTime> relapses;
  final List<DemoCraving> cravings;
}

@immutable
class DemoDataset {
  const DemoDataset({required this.tasks, required this.lists, required this.habits, required this.quit});

  final List<DemoTask> tasks;
  final List<({String title, List<DemoNode> nodes})> lists;
  final List<DemoHabit> habits;
  final DemoQuit quit;

  int get occurrenceCount => tasks.fold(0, (a, t) => a + t.history.length);
  int get checkInCount => habits.fold(0, (a, h) => a + h.days.length);
}

abstract final class DemoGenerator {
  static const days = 182;

  static const taskKeys = [
    'standup',
    'deepWork',
    'gym',
    'emails',
    'planWeek',
    'callParents',
    'dentist',
    'groceries',
    'laundry',
    'review',
  ];

  static const habitKeys = ['water', 'meditate', 'read', 'walk', 'pushUps'];

  static DemoDataset generate({required int seed, required LocalDate today, required DemoTexts texts}) {
    final r = Random(seed);
    final from = today.plusDays(-days);
    LocalDateTime at(LocalDate d, int h, [int m = 0]) => LocalDateTime(d, LocalTime(h, m));
    const weekdays = {Weekday.monday, Weekday.tuesday, Weekday.wednesday, Weekday.thursday, Weekday.friday};

    // ---- Plan: recurring series with ~6 months of history, plus one-offs around today.
    DemoTask series(
      String key, {
      required int hour,
      int minute = 0,
      required int minutes,
      Set<Weekday>? on,
      String? category,
      int priority = 0,
      double doneRate = 0.8,
    }) {
      final rule = on == null
          ? RecurrenceRule()
          : RecurrenceRule(freq: Frequency.weekly, byWeekday: [for (final d in on) WeekdayRule(d)]);
      final history = <({String key, LocalDateTime start, OccurrenceStatus status})>[];
      for (var d = from; d.isBefore(today); d = d.plusDays(1)) {
        if (on != null && !on.contains(d.weekday)) continue;
        final start = at(d, hour, minute);
        final roll = r.nextDouble();
        // Fridays and the holiday weeks are a bit worse; the habit improves over time.
        final progress = d.epochDay - from.epochDay;
        final rate = (doneRate - (d.weekday == Weekday.friday ? 0.1 : 0) + progress / days * 0.08).clamp(0.0, 0.97);
        if (roll < rate) {
          history.add((key: start.toIso(), start: start, status: OccurrenceStatus.done));
        } else if (roll < rate + 0.08) {
          history.add((key: start.toIso(), start: start, status: OccurrenceStatus.skipped));
        }
      }
      return DemoTask(
        key: key,
        title: texts.tasks[key] ?? key,
        start: at(from, hour, minute),
        durationMinutes: minutes,
        rule: rule,
        weekdays: on,
        categoryKey: category,
        priority: priority,
        history: history,
      );
    }

    DemoTask oneOff(String key, int dayOffset, int hour, int minutes, {String? category, int priority = 0}) => DemoTask(
      key: key,
      title: texts.tasks[key] ?? key,
      start: at(today.plusDays(dayOffset), hour),
      durationMinutes: minutes,
      categoryKey: category,
      priority: priority,
    );

    final tasks = [
      series('standup', hour: 9, minutes: 15, on: weekdays, category: 'work', doneRate: 0.86),
      series('deepWork', hour: 10, minutes: 120, on: weekdays, category: 'work', priority: 3, doneRate: 0.7),
      series(
        'gym',
        hour: 18,
        minute: 30,
        minutes: 60,
        on: {Weekday.monday, Weekday.wednesday, Weekday.friday},
        category: 'health',
        doneRate: 0.65,
      ),
      series('emails', hour: 16, minutes: 30, on: weekdays, category: 'work', doneRate: 0.75),
      series('planWeek', hour: 19, minutes: 30, on: {Weekday.sunday}, category: 'personal', doneRate: 0.72),
      series('callParents', hour: 20, minutes: 30, on: {Weekday.saturday}, category: 'social', doneRate: 0.6),
      oneOff('dentist', 3, 14, 45, category: 'health', priority: 2),
      oneOff('groceries', 1, 17, 45, category: 'home'),
      oneOff('laundry', 0, 20, 60, category: 'home', priority: 1),
      oneOff('review', 2, 11, 90, category: 'work', priority: 4),
    ];

    // ---- Lists: statuses spread over the items.
    final lists = [
      for (final l in texts.lists) (title: l.title, nodes: [for (final n in l.nodes) _withStatuses(n, r)]),
    ];

    // ---- Habits: streaky behaviour (yesterday's success makes today's more likely).
    DemoHabit habit(String key, SchedulePreset preset, HabitTarget goal, {double base = 0.75, int? startOffset}) {
      final start = today.plusDays(-(startOffset ?? days));
      final checks = <({LocalDate date, double? value})>[];
      var streak = false;
      for (var d = start; d.isBefore(today); d = d.plusDays(1)) {
        if (preset.kind == SchedulePresetKind.weekdays && !weekdays.contains(d.weekday)) continue;
        final weekend = d.weekday == Weekday.saturday || d.weekday == Weekday.sunday;
        final p = (streak ? base + 0.15 : base - 0.2) - (weekend ? 0.08 : 0);
        streak = r.nextDouble() < p;
        if (!streak) continue;
        final target = goal.target;
        checks.add((
          date: d,
          value: goal.isMeasurable && target != null ? (target * (0.6 + r.nextDouble() * 0.6)).roundToDouble() : null,
        ));
      }
      return DemoHabit(key: key, name: texts.habits[key] ?? key, preset: preset, goal: goal, days: checks);
    }

    final habits = [
      habit(
        'water',
        const SchedulePreset.daily(),
        const HabitTarget(type: HabitGoalType.count, target: 8, unit: 'glasses'),
        base: 0.8,
      ),
      habit('meditate', const SchedulePreset.daily(), const HabitTarget.check(), base: 0.7),
      habit(
        'read',
        const SchedulePreset.daily(),
        const HabitTarget(type: HabitGoalType.count, target: 20, unit: 'pages'),
        base: 0.65,
        startOffset: 120,
      ),
      habit('walk', const SchedulePreset(SchedulePresetKind.weekdays), const HabitTarget.check(), base: 0.75),
      habit(
        'pushUps',
        const SchedulePreset.daily(),
        const HabitTarget(type: HabitGoalType.count, target: 15, unit: 'reps'),
        base: 0.6,
        startOffset: 60,
      ),
    ];

    // ---- Quit smoking 150 days ago, two slips, cravings fading out.
    final quitDay = today.plusDays(-150);
    final relapses = [at(quitDay.plusDays(18), 22, 10), at(quitDay.plusDays(71), 21, 40)];
    final cravings = <DemoCraving>[];
    for (var d = quitDay; d.isBefore(today.plusDays(1)); d = d.plusDays(1)) {
      final age = d.epochDay - quitDay.epochDay;
      final expected = 4 * exp(-age / 35) + 0.25;
      var n = 0;
      // Poisson-ish count.
      final limit = exp(-expected);
      var product = r.nextDouble();
      while (product > limit && n < 8) {
        n++;
        product *= r.nextDouble();
      }
      for (var i = 0; i < n; i++) {
        final hour = 8 + r.nextInt(14);
        cravings.add(
          DemoCraving(
            at(d, hour, r.nextInt(60)),
            intensity: (9 - age / 25 + r.nextInt(3) - 1).round().clamp(1, 10),
            resisted: r.nextDouble() < 0.85 + min(age, 100) / 1000,
            trigger: texts.cravingTriggers.isEmpty
                ? null
                : texts.cravingTriggers[r.nextInt(texts.cravingTriggers.length)],
          ),
        );
      }
    }
    cravings.sort((a, b) => a.at.compareTo(b.at));
    final now = today.atStartOfDay;
    return DemoDataset(
      tasks: tasks,
      lists: lists,
      habits: habits,
      quit: DemoQuit(
        name: texts.quitName,
        quitAt: at(quitDay, 8),
        relapses: relapses,
        cravings: [
          for (final c in cravings)
            if (c.at.compareTo(now) < 0) c,
        ],
      ),
    );
  }

  static DemoNode _withStatuses(DemoNode n, Random r) {
    final roll = r.nextDouble();
    final status = n.children.isNotEmpty
        ? ItemStatus.todo
        : roll < 0.45
        ? ItemStatus.completed
        : roll < 0.55
        ? ItemStatus.ongoing
        : roll < 0.62
        ? ItemStatus.waiting
        : roll < 0.66
        ? ItemStatus.blocked
        : ItemStatus.todo;
    return DemoNode(n.text, status: status, children: [for (final c in n.children) _withStatuses(c, r)]);
  }
}
