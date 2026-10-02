import 'package:everslot/features/notifications/domain/inbox_item.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:meta/meta.dart';

/// How statistics rows are grouped (T7.5.17).
enum StatsGroup { rule, section, target }

/// Counters of one group over a period. Ignored = never opened, acted on, read or dismissed
/// (and older than an hour); effectiveness = a habit check-in or task start within an hour of a
/// reminder, over the reminders of habits and tasks.
@immutable
class NotificationStatsRow {
  const NotificationStatsRow({
    required this.key,
    this.label,
    this.delivered = 0,
    this.local = 0,
    this.push = 0,
    this.inboxOnly = 0,
    this.opened = 0,
    this.acted = 0,
    this.actions = const {},
    this.snoozed = 0,
    this.dismissed = 0,
    this.ignored = 0,
    this.late = 0,
    this.deferred = 0,
    this.medianActionMinutes,
    this.effective = 0,
    this.effectivenessBase = 0,
  });

  factory NotificationStatsRow.fromJson(String key, Map<String, Object?> json) => NotificationStatsRow(
    key: key,
    delivered: _int(json['del']),
    local: _int(json['loc']),
    push: _int(json['psh']),
    inboxOnly: _int(json['inb']),
    opened: _int(json['opn']),
    acted: _int(json['act']),
    actions: {for (final e in ((json['acts'] as Map?) ?? const {}).entries) '${e.key}': _int(e.value)},
    snoozed: _int(json['snz']),
    dismissed: _int(json['dis']),
    ignored: _int(json['ign']),
    late: _int(json['late']),
    deferred: _int(json['def']),
    effective: _int(json['eff']),
    effectivenessBase: _int(json['effBase']),
  );

  static int _int(Object? v) => v is num ? v.toInt() : 0;

  /// rule id / section wire / `type:id`.
  final String key;

  /// Item title for [StatsGroup.target] rows.
  final String? label;
  final int delivered;
  final int local;
  final int push;
  final int inboxOnly;
  final int opened;
  final int acted;
  final Map<String, int> actions;
  final int snoozed;
  final int dismissed;
  final int ignored;
  final int late;

  /// Deferred by quiet hours.
  final int deferred;

  /// Median minutes from firing to an action (null without actions; not kept in rollups).
  final double? medianActionMinutes;
  final int effective;
  final int effectivenessBase;

  double? get ignoreRate => delivered == 0 ? null : ignored / delivered;
  double? get lateRate => delivered == 0 ? null : late / delivered;
  double? get effectiveness => effectivenessBase == 0 ? null : effective / effectivenessBase;

  Map<String, Object?> toJson() => {
    'del': delivered,
    'loc': local,
    'psh': push,
    'inb': inboxOnly,
    'opn': opened,
    'act': acted,
    if (actions.isNotEmpty) 'acts': actions,
    'snz': snoozed,
    'dis': dismissed,
    'ign': ignored,
    'late': late,
    'def': deferred,
    'eff': effective,
    'effBase': effectivenessBase,
  };

  /// Sum of two periods (medians can't be merged: the newer one wins).
  NotificationStatsRow operator +(NotificationStatsRow o) => NotificationStatsRow(
    key: key,
    label: label ?? o.label,
    delivered: delivered + o.delivered,
    local: local + o.local,
    push: push + o.push,
    inboxOnly: inboxOnly + o.inboxOnly,
    opened: opened + o.opened,
    acted: acted + o.acted,
    actions: {
      for (final k in {...actions.keys, ...o.actions.keys}) k: (actions[k] ?? 0) + (o.actions[k] ?? 0),
    },
    snoozed: snoozed + o.snoozed,
    dismissed: dismissed + o.dismissed,
    ignored: ignored + o.ignored,
    late: late + o.late,
    deferred: deferred + o.deferred,
    medianActionMinutes: medianActionMinutes ?? o.medianActionMinutes,
    effective: effective + o.effective,
    effectivenessBase: effectivenessBase + o.effectivenessBase,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationStatsRow && other.key == key && _mapEq(other.toJson(), toJson());

  @override
  int get hashCode => Object.hash(key, delivered, opened, acted, ignored);

  static bool _mapEq(Map<String, Object?> a, Map<String, Object?> b) => a.toString() == b.toString();
}

/// A rule the user mostly ignores: "You ignore 90 % of this reminder — mute or change it?".
@immutable
class NoisyRule {
  const NoisyRule(this.ruleId, this.delivered, this.ignoreRate);

  final String ruleId;
  final int delivered;
  final double ignoreRate;
}

abstract final class NotificationStats {
  static const effectivenessWindow = Duration(minutes: 60);
  static const ignoredAfter = Duration(hours: 1);

  static String? keyOf(InboxItem r, StatsGroup by) => switch (by) {
    StatsGroup.rule => r.ruleId,
    StatsGroup.section => r.section?.wire,
    StatsGroup.target => r.sourceType == null || r.sourceId == null ? null : '${r.sourceType}:${r.sourceId}',
  };

  /// Statistics of [rows] (delivered inbox rows), grouped [by], most delivered first.
  /// [activity]: completion instants per target key (`habit:id`, `task:id`) for effectiveness.
  static List<NotificationStatsRow> compute(
    List<InboxItem> rows, {
    required StatsGroup by,
    required DateTime now,
    Map<String, List<DateTime>> activity = const {},
  }) {
    final groups = <String, List<InboxItem>>{};
    for (final r in rows) {
      if (r.fireAt.isAfter(now)) continue;
      final key = keyOf(r, by);
      if (key == null) continue;
      (groups[key] ??= []).add(r);
    }
    final out = [for (final e in groups.entries) _row(e.key, e.value, now, activity, label: by == StatsGroup.target)];
    out.sort((a, b) => b.delivered != a.delivered ? b.delivered - a.delivered : a.key.compareTo(b.key));
    return out;
  }

  static NotificationStatsRow _row(
    String key,
    List<InboxItem> rows,
    DateTime now,
    Map<String, List<DateTime>> activity, {
    required bool label,
  }) {
    var local = 0;
    var push = 0;
    var inboxOnly = 0;
    var opened = 0;
    var acted = 0;
    var snoozed = 0;
    var dismissed = 0;
    var ignored = 0;
    var late = 0;
    var deferred = 0;
    var effective = 0;
    var base = 0;
    final actions = <String, int>{};
    final minutes = <double>[];
    for (final r in rows) {
      final via = r.deliveredVia;
      if (via.contains('local')) local++;
      if (via.contains('push')) push++;
      if (!via.contains('local') && !via.contains('push')) inboxOnly++;
      if (r.openedAt != null) opened++;
      if (r.actedAt != null) {
        acted++;
        final a = r.action;
        if (a != null) actions[a] = (actions[a] ?? 0) + 1;
        minutes.add(r.actedAt!.difference(r.fireAt).inSeconds / 60);
      }
      if (r.action == 'snooze' || r.snoozedUntil != null) snoozed++;
      if (r.dismissedAt != null) dismissed++;
      if (!r.acknowledged && r.readAt == null && now.difference(r.fireAt) >= ignoredAfter) ignored++;
      if (r.late) late++;
      final adjustments = r.payload['adj'];
      if (adjustments is List && adjustments.contains('deferredQuietHours')) deferred++;
      final type = r.sourceType;
      if (type == 'habit' || type == 'task') {
        base++;
        final times = activity['$type:${r.sourceId}'] ?? const <DateTime>[];
        final until = r.fireAt.add(effectivenessWindow);
        if (times.any((t) => !t.isBefore(r.fireAt) && !t.isAfter(until))) effective++;
      }
    }
    minutes.sort();
    final median = minutes.isEmpty
        ? null
        : (minutes.length.isOdd
              ? minutes[minutes.length ~/ 2]
              : (minutes[minutes.length ~/ 2 - 1] + minutes[minutes.length ~/ 2]) / 2);
    return NotificationStatsRow(
      key: key,
      label: label ? rows.first.title : null,
      delivered: rows.length,
      local: local,
      push: push,
      inboxOnly: inboxOnly,
      opened: opened,
      acted: acted,
      actions: actions,
      snoozed: snoozed,
      dismissed: dismissed,
      ignored: ignored,
      late: late,
      deferred: deferred,
      medianActionMinutes: median,
      effective: effective,
      effectivenessBase: base,
    );
  }

  /// Rules delivered at least [minDelivered] times and ignored at least [threshold] of the time.
  static List<NoisyRule> noisyRules(
    List<NotificationStatsRow> byRule, {
    int minDelivered = 10,
    double threshold = 0.9,
  }) => [
    for (final r in byRule)
      if (r.delivered >= minDelivered && (r.ignoreRate ?? 0) >= threshold) NoisyRule(r.key, r.delivered, r.ignoreRate!),
  ];

  /// Section of a rule-less row (system notices) — kept for grouping labels.
  static NotificationSection? sectionOf(String wire) => NotificationSection.tryParse(wire);
}

/// Daily per-rule / per-section counters kept beyond the 90-day inbox retention (`local_kv`
/// `notifications.statsRollup`): `{"through": "2026-06-30", "days": {"2026-06-30": {"rule": {id:
/// counters}, "section": {wire: counters}}}}`.
@immutable
class StatsRollup {
  const StatsRollup({this.through, this.days = const {}});

  factory StatsRollup.fromJson(Map<String, Object?> json) => StatsRollup(
    through: json['through'] is String ? DateTime.tryParse(json['through']! as String) : null,
    days: {
      for (final e in ((json['days'] as Map?) ?? const {}).entries)
        '${e.key}': {
          for (final g in ((e.value as Map?) ?? const {}).entries)
            '${g.key}': {
              for (final k in ((g.value as Map?) ?? const {}).entries)
                '${k.key}': NotificationStatsRow.fromJson(
                  '${k.key}',
                  Map<String, Object?>.from((k.value as Map?) ?? const {}),
                ),
            },
        },
    },
  );

  /// Rolled up until this UTC day start (exclusive); rows before it come from here.
  final DateTime? through;

  /// day (yyyy-mm-dd) → group (`rule` | `section`) → key → counters.
  final Map<String, Map<String, Map<String, NotificationStatsRow>>> days;

  Map<String, Object?> toJson() => {
    if (through != null) 'through': through!.toIso8601String(),
    'days': {
      for (final d in days.entries)
        d.key: {
          for (final g in d.value.entries) g.key: {for (final r in g.value.entries) r.key: r.value.toJson()},
        },
    },
  };

  static String dayKey(DateTime utcDay) => utcDay.toIso8601String().substring(0, 10);

  /// Rolls up every whole UTC day before [cutoff] not rolled yet, from [rows]; days older than
  /// [keep] are dropped.
  StatsRollup rollUp(
    List<InboxItem> rows, {
    required DateTime cutoff,
    required DateTime now,
    Duration keep = const Duration(days: 400),
  }) {
    final end = DateTime.utc(cutoff.year, cutoff.month, cutoff.day);
    final start = through;
    final next = {for (final e in days.entries) e.key: e.value};
    final byDay = <String, List<InboxItem>>{};
    for (final r in rows) {
      if (!r.fireAt.isBefore(end)) continue;
      if (start != null && r.fireAt.isBefore(start)) continue;
      (byDay[dayKey(r.fireAt.toUtc())] ??= []).add(r);
    }
    for (final e in byDay.entries) {
      next[e.key] = {
        for (final g in const [StatsGroup.rule, StatsGroup.section])
          g.name: {for (final r in NotificationStats.compute(e.value, by: g, now: now)) r.key: r},
      };
    }
    final oldest = dayKey(now.subtract(keep));
    next.removeWhere((k, _) => k.compareTo(oldest) < 0);
    return StatsRollup(through: end, days: next);
  }

  /// Rolled-up rows of [by] (rule / section) for days in `[from, to)`.
  List<NotificationStatsRow> rowsBetween(StatsGroup by, DateTime from, DateTime to) {
    final out = <String, NotificationStatsRow>{};
    final a = dayKey(from.toUtc());
    final b = dayKey(to.toUtc());
    for (final d in days.entries) {
      if (d.key.compareTo(a) < 0 || d.key.compareTo(b) >= 0) continue;
      for (final r in (d.value[by.name] ?? const <String, NotificationStatsRow>{}).values) {
        out[r.key] = out[r.key] == null ? r : out[r.key]! + r;
      }
    }
    return out.values.toList();
  }
}
