import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_change.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Reset schedule of a recurring checklist: a recurrence rule (arch §8.1) plus its anchor.
///
/// Stored in `checklists.reset_rule`; the anchor lives in the rule's extra keys (`anchor`,
/// `anchorZone`), which `RecurrenceRule` preserves verbatim. A null zone means floating (the
/// device's current zone).
@immutable
class ResetSchedule {
  const ResetSchedule({required this.rule, required this.anchorStart, this.zone});

  final RecurrenceRule rule;
  final LocalDateTime anchorStart;
  final String? zone;

  RecurrenceAnchor get anchor => RecurrenceAnchor(anchorStart, zone);

  static ResetSchedule? fromJson(Map<String, Object?>? json) {
    if (json == null) return null;
    try {
      final rule = RecurrenceRule.fromJson(json);
      final anchor = LocalDateTime.tryParse(json['anchor'] as String? ?? '');
      if (anchor == null) return null;
      return ResetSchedule(rule: rule, anchorStart: anchor, zone: json['anchorZone'] as String?);
    } on Object {
      return null;
    }
  }

  Map<String, Object?> toJson() {
    final base = Map<String, Object?>.from(rule.toJson())
      ..['anchor'] = anchorStart.toIso()
      ..remove('anchorZone');
    if (zone != null) base['anchorZone'] = zone;
    return base;
  }

  /// Presets offered until the shared recurrence picker lands (daily / weekdays / weekly / monthly).
  factory ResetSchedule.preset(ResetPreset preset, {required LocalDateTime anchorStart, String? zone}) {
    final rule = switch (preset) {
      ResetPreset.daily => RecurrenceRule(),
      ResetPreset.weekdays => RecurrenceRule(
        freq: Frequency.weekly,
        byWeekday: [
          for (final d in [Weekday.monday, Weekday.tuesday, Weekday.wednesday, Weekday.thursday, Weekday.friday])
            WeekdayRule(d),
        ],
      ),
      ResetPreset.weekly => RecurrenceRule(freq: Frequency.weekly, byWeekday: [WeekdayRule(anchorStart.date.weekday)]),
      ResetPreset.monthly => RecurrenceRule(freq: Frequency.monthly, byMonthDay: [anchorStart.day]),
    };
    return ResetSchedule(rule: rule, anchorStart: anchorStart, zone: zone);
  }

  /// Best-effort preset detection for the settings UI.
  ResetPreset? get preset {
    final r = rule;
    if (r.type != RuleType.fixed || r.interval != 1) return null;
    if (r.freq == Frequency.daily && (r.byWeekday?.isEmpty ?? true)) return ResetPreset.daily;
    if (r.freq == Frequency.weekly && (r.byWeekday?.length ?? 0) == 5) return ResetPreset.weekdays;
    if (r.freq == Frequency.weekly && (r.byWeekday?.length ?? 0) == 1) return ResetPreset.weekly;
    if (r.freq == Frequency.monthly) return ResetPreset.monthly;
    return null;
  }
}

enum ResetPreset { daily, weekdays, weekly, monthly }

/// A due reset (occurrence `key` at instant `at`).
@immutable
class ResetPlan {
  const ResetPlan({required this.key, required this.at, this.previousAt});

  final String key;
  final DateTime at;

  /// Previous reset instant (start of the finished run), when known.
  final DateTime? previousAt;
}

/// Pure reset planning (T4.5.06).
abstract final class ResetPlanner {
  /// Latest due occurrence `k` with `k > lastResetKey` (only the latest after missed periods).
  static ResetPlan? due(
    RecurrenceEngine engine,
    ResetSchedule schedule, {
    required String? lastResetKey,
    required DateTime now,
    required String evalZone,
  }) {
    final Occurrence? occ;
    try {
      occ = engine.previousBefore(schedule.rule, schedule.anchor, now, evalZone: evalZone, inclusive: true);
    } on Object {
      return null;
    }
    if (occ == null) return null;
    if (lastResetKey != null && !lastResetKey.startsWith('manual:') && occ.key.compareTo(lastResetKey) <= 0) {
      return null;
    }
    Occurrence? previous;
    try {
      previous = engine.previousBefore(schedule.rule, schedule.anchor, occ.startUtc, evalZone: evalZone);
    } on Object {
      previous = null;
    }
    return ResetPlan(key: occ.key, at: occ.startUtc, previousAt: previous?.startUtc);
  }

  /// Key to store when a schedule is (re)configured so past occurrences don't reset immediately.
  static String? initialKey(RecurrenceEngine engine, ResetSchedule schedule, {required DateTime now, required String evalZone}) {
    try {
      return engine.previousBefore(schedule.rule, schedule.anchor, now, evalZone: evalZone, inclusive: true)?.key;
    } on Object {
      return null;
    }
  }

  /// Next reset instant after [now] (for "next in 3 h").
  static DateTime? next(RecurrenceEngine engine, ResetSchedule schedule, {required DateTime now, required String evalZone}) {
    try {
      return engine.nextAfter(schedule.rule, schedule.anchor, now, evalZone: evalZone)?.startUtc;
    } on Object {
      return null;
    }
  }

  /// One reset as a single change (run the builder result with `scheduledAt = plan.at`):
  /// run snapshot row, item statuses per [mode] (order untouched), `last_reset_key`, events.
  static TreeChange apply(
    ChecklistTree tree,
    Checklist checklist, {
    required String runId,
    required String key,
    required DateTime at,
    required DateTime startedAt,
    required ResetMode mode,
    bool updateLastKey = true,
  }) {
    final b = TreeChangeBuilder(cause: 'reset');
    final items = tree.items.toList();
    final countable = items.where((i) => i.status.isCountable).length;
    final done = items.where((i) => i.status == ItemStatus.completed).length;
    b.insert(runId, {
      'checklist_id': checklist.id,
      'occurrence_key': key,
      'started_at': startedAt,
      'ended_at': at,
      'total_items': countable,
      'completed_items': done,
      'snapshot': [
        for (final i in items)
          RunSnapshotEntry(itemId: i.id, status: i.status, completedAt: i.completedAt, statusNote: i.statusNote).toJson(),
      ],
    }, table: 'checklist_runs');
    for (final i in items) {
      final reset = switch (mode) {
        ResetMode.allToTodo => i.status != ItemStatus.todo,
        ResetMode.completedToTodo => i.status == ItemStatus.completed,
      };
      if (!reset) continue;
      b
        ..update(i.id, {
          'status': ItemStatus.todo.name,
          'status_note': null,
          'status_changed_at': at,
          'completed_at': null,
          'follow_up_at': null,
        })
        ..event(
          EventSpec(
            entityType: 'checklist_item',
            entityId: i.id,
            parentId: checklist.id,
            eventType: 'status_changed',
            payload: {'from': i.status.name, 'to': ItemStatus.todo.name, 'note': null, 'followUpAt': null, 'runKey': key},
          ),
        );
    }
    if (updateLastKey) b.update(checklist.id, {'last_reset_key': key}, table: 'checklists');
    b.event(
      EventSpec(
        entityType: 'checklist',
        entityId: checklist.id,
        eventType: 'reset',
        payload: {'key': key, 'runId': runId, 'total': countable, 'completed': done},
      ),
    );
    return b.build(scheduledAt: at);
  }
}
