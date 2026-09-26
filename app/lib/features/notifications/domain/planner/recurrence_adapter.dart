import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Expands §8.1 recurrence rules for `schedule` and `digest` triggers.
abstract interface class RecurrenceExpander {
  /// Instants (UTC, ascending) of [rule] in [zone] within `[fromUtc, toUtc]`.
  List<DateTime> instantsBetween(
    Map<String, Object?> rule, {
    required String zone,
    required DateTime fromUtc,
    required DateTime toUtc,
    required ZoneResolver zones,
  });

  /// Validation error codes (empty = valid).
  List<String> validate(Map<String, Object?> rule);
}

/// [RecurrenceExpander] backed by `packages/everslot_recurrence`'s [RecurrenceEngine].
///
/// A standalone reminder schedule has no owning series, so its anchor comes from the additive
/// `start` key of the rule JSON (`YYYY-MM-DD` or `YYYY-MM-DDTHH:mm`, default 2024-01-01 — a
/// Monday — at the first `times` entry or 09:00). The rule is floating: it is evaluated in the
/// zone passed by the planner (target zone or device zone).
class EngineRecurrenceExpander implements RecurrenceExpander {
  EngineRecurrenceExpander();

  /// Shared instance used when a planning context doesn't provide one.
  static final shared = EngineRecurrenceExpander();

  static const _validator = RuleValidator();
  static const _maxPerCall = 5000;

  final Expando<RecurrenceEngine> _engines = Expando('engines');

  RecurrenceEngine _engineFor(ZoneResolver zones) => _engines[zones] ??=
      RecurrenceEngine(zones, maxOccurrencesPerCall: _maxPerCall);

  static (RecurrenceRule, RecurrenceAnchor)? _parse(Map<String, Object?> json) {
    try {
      final rule = RecurrenceRule.fromJson({
        for (final e in json.entries)
          if (e.key != 'start') e.key: e.value,
      });
      final startRaw = asString(json['start']);
      final times = asStringList(json['times']) ?? const <String>[];
      final firstTime = times.isEmpty ? null : LocalTime.tryParse(times.first);
      final start =
          (startRaw == null ? null : LocalDateTime.tryParse(startRaw)) ??
          LocalDateTime(
            (startRaw == null ? null : LocalDate.tryParse(startRaw)) ??
                LocalDate(2024, 1, 1),
            firstTime ?? LocalTime(9, 0),
          );
      return (rule, RecurrenceAnchor(start, null));
    } on Object {
      return null;
    }
  }

  @override
  List<String> validate(Map<String, Object?> rule) {
    final parsed = _parse(rule);
    if (parsed == null) return const ['invalid'];
    final result = _validator.validate(parsed.$1, anchor: parsed.$2);
    return [for (final e in result.errors) e.code.name];
  }

  @override
  List<DateTime> instantsBetween(
    Map<String, Object?> rule, {
    required String zone,
    required DateTime fromUtc,
    required DateTime toUtc,
    required ZoneResolver zones,
  }) {
    final parsed = _parse(rule);
    if (parsed == null ||
        !_validator.validate(parsed.$1, anchor: parsed.$2).isValid)
      return const [];
    try {
      final occurrences = _engineFor(zones).betweenInstants(
        parsed.$1,
        parsed.$2,
        fromUtc,
        toUtc.add(const Duration(minutes: 1)),
        evalZone: zone,
        limit: _maxPerCall,
        durationMinutes: 0,
      );
      return [
        for (final o in occurrences)
          if (!o.startUtc.isBefore(fromUtc) && !o.startUtc.isAfter(toUtc))
            o.startUtc,
      ]..sort();
    } on Object {
      return const [];
    }
  }
}
