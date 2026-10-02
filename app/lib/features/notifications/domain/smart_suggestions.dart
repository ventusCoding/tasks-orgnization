import 'dart:math' as math;

import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// "You usually do push-ups around 07:45 — move the reminder to 07:30?" (T7.5.19).
@immutable
class ReminderSuggestion {
  const ReminderSuggestion({
    required this.ruleId,
    required this.targetKey,
    required this.usual,
    required this.current,
    required this.proposed,
    required this.samples,
    required this.concentration,
  });

  final String ruleId;

  /// `habit:id` / `task:id`.
  final String targetKey;

  /// Circular mean of the user's check-in / start times.
  final LocalTime usual;
  final LocalTime current;
  final LocalTime proposed;
  final int samples;

  /// Mean resultant length (0 = spread over the day, 1 = always the same minute).
  final double concentration;

  String get id => '$ruleId@${proposed.toIso()}';

  @override
  bool operator ==(Object other) =>
      other is ReminderSuggestion && other.ruleId == ruleId && other.proposed == proposed && other.usual == usual;

  @override
  int get hashCode => Object.hash(ruleId, proposed, usual);
}

abstract final class SmartSuggestions {
  static const minSamples = 5;
  static const minConcentration = 0.6;

  /// Reminders land this long before the usual time.
  static const lead = Duration(minutes: 15);

  /// Smaller moves aren't worth suggesting.
  static const minShift = Duration(minutes: 15);

  /// Circular mean of minutes of day (0–1439) and its concentration; null without samples.
  static (int minute, double concentration)? circularMean(List<int> minutes) {
    if (minutes.isEmpty) return null;
    var sx = 0.0;
    var sy = 0.0;
    for (final m in minutes) {
      final a = 2 * math.pi * m / 1440;
      sx += math.cos(a);
      sy += math.sin(a);
    }
    sx /= minutes.length;
    sy /= minutes.length;
    final r = math.sqrt(sx * sx + sy * sy);
    var angle = math.atan2(sy, sx);
    if (angle < 0) angle += 2 * math.pi;
    return ((angle / (2 * math.pi) * 1440).round() % 1440, r);
  }

  /// The fixed time of [trigger] a suggestion may move: a relative trigger at a time of day, or a
  /// daily schedule with one time; null otherwise.
  static LocalTime? adjustableTime(NotificationTrigger trigger) => switch (trigger) {
    RelativeTrigger(:final atTime?) => atTime,
    ScheduleTrigger(:final recurrence) when _dailyTimes(recurrence)?.length == 1 => LocalTime.tryParse(
      '${_dailyTimes(recurrence)!.single}',
    ),
    _ => null,
  };

  static List<Object?>? _dailyTimes(Map<String, Object?> r) =>
      r['freq'] == 'daily' && (r['interval'] ?? 1) == 1 && r['times'] is List ? r['times']! as List : null;

  /// [trigger] firing at [time] instead.
  static NotificationTrigger withTime(NotificationTrigger trigger, LocalTime time) => switch (trigger) {
    RelativeTrigger(:final anchor, :final offsetMinutes, :final dayOffset) => RelativeTrigger(
      anchor: anchor,
      offsetMinutes: offsetMinutes,
      dayOffset: dayOffset,
      atTime: time,
    ),
    ScheduleTrigger(:final recurrence) => ScheduleTrigger(
      recurrence: {
        ...recurrence,
        'times': [time.toIso()],
      },
    ),
    _ => trigger,
  };

  /// A suggestion for [rule] of target [targetKey] from the local minutes of day the user did it,
  /// or null when the data is thin, scattered, or the reminder already fits.
  static ReminderSuggestion? suggest({
    required NotificationRule rule,
    required String targetKey,
    required List<int> minutes,
  }) {
    final current = adjustableTime(rule.spec.trigger);
    if (current == null || minutes.length < minSamples) return null;
    final mean = circularMean(minutes);
    if (mean == null || mean.$2 < minConcentration) return null;
    final target = (mean.$1 - lead.inMinutes) % 1440;
    final rounded = ((target / 5).round() * 5) % 1440;
    final proposed = LocalTime.fromMinuteOfDay(rounded);
    final diff = (rounded - current.minuteOfDay).abs();
    if (math.min(diff, 1440 - diff) < minShift.inMinutes) return null;
    return ReminderSuggestion(
      ruleId: rule.id,
      targetKey: targetKey,
      usual: LocalTime.fromMinuteOfDay(mean.$1),
      current: current,
      proposed: proposed,
      samples: minutes.length,
      concentration: mean.$2,
    );
  }
}
