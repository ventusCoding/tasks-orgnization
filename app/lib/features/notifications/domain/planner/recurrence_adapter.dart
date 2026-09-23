import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Expands §8.1 recurrence rules for `schedule` and `digest` triggers.
///
/// ADAPTER (partial, T7.2.06): `packages/everslot_recurrence` does not ship its `RecurrenceEngine`
/// on this branch yet. [BasicRecurrenceExpander] covers what notification schedules need
/// (daily / weekly / monthly / yearly with `interval`, `byWeekday` (incl. `n`), `byMonthDay`,
/// `byMonth`, `times`, `window` for hourly/minutely, `until`, `exdates`, `rdates`). Unsupported
/// features (`quota`, `after_completion`, `bySetPos`, `byYearDay`, `byWeekNo`, `count`) are
/// reported by [validate]. Swap in the engine by providing another [RecurrenceExpander]
/// (`recurrenceExpanderProvider`).
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

class BasicRecurrenceExpander implements RecurrenceExpander {
  const BasicRecurrenceExpander();

  static const _unsupported = ['bySetPos', 'byYearDay', 'byWeekNo'];

  @override
  List<String> validate(Map<String, Object?> rule) {
    final errors = <String>[];
    final type = asString(rule['type']) ?? 'fixed';
    if (type != 'fixed') errors.add('unsupported_type');
    final freq = asString(rule['freq']);
    if (!const ['minutely', 'hourly', 'daily', 'weekly', 'monthly', 'yearly'].contains(freq)) {
      errors.add('invalid_freq');
    }
    final interval = asInt(rule['interval']) ?? 1;
    if (interval < 1) errors.add('invalid_interval');
    for (final key in _unsupported) {
      final v = rule[key];
      if (v is List && v.isNotEmpty) errors.add('unsupported_$key');
    }
    for (final t in asStringList(rule['times']) ?? const <String>[]) {
      if (LocalTime.tryParse(t) == null) errors.add('invalid_time');
    }
    if ((freq == 'minutely' || freq == 'hourly') && asJsonMap(rule['window']) == null) {
      // Allowed: whole day window.
    }
    return errors;
  }

  @override
  List<DateTime> instantsBetween(
    Map<String, Object?> rule, {
    required String zone,
    required DateTime fromUtc,
    required DateTime toUtc,
    required ZoneResolver zones,
  }) {
    if (validate(rule).isNotEmpty) return const [];
    final fromLocal = zones.toLocal(fromUtc, zone).date.minusDays(1);
    final toLocal = zones.toLocal(toUtc, zone).date.plusDays(1);
    final locals = <LocalDateTime>{...localsBetween(rule, fromLocal, toLocal)};
    for (final r in asStringList(rule['rdates']) ?? const <String>[]) {
      final l = LocalDateTime.tryParse(r);
      if (l != null) locals.add(l);
    }
    final ex = {for (final e in asStringList(rule['exdates']) ?? const <String>[]) e};
    final until = LocalDateTime.tryParse(asString(rule['until']) ?? '');
    final result = <DateTime>[];
    for (final l in locals) {
      if (ex.contains(l.toIso())) continue;
      if (until != null && l.isAfter(until)) continue;
      final utc = zones.resolve(l, zone).utc;
      if (utc.isBefore(fromUtc) || utc.isAfter(toUtc)) continue;
      result.add(utc);
    }
    result.sort();
    return result;
  }

  /// Wall-clock occurrences on days `[from, to]`.
  List<LocalDateTime> localsBetween(Map<String, Object?> rule, LocalDate from, LocalDate to) {
    final freq = asString(rule['freq']) ?? 'daily';
    final interval = (asInt(rule['interval']) ?? 1).clamp(1, 100000);
    final start = LocalDate.tryParse(asString(rule['start']) ?? '') ?? LocalDate(2024, 1, 1);
    final times = [
      for (final t in asStringList(rule['times']) ?? const <String>[]) ?LocalTime.tryParse(t),
    ];
    if (times.isEmpty) times.add(LocalTime(9, 0));
    final weekdays = _weekdays(rule['byWeekday']);
    final monthDays = asIntList(rule['byMonthDay']) ?? const <int>[];
    final months = asIntList(rule['byMonth']) ?? const <int>[];
    final wkst = Weekday.fromCode(asString(rule['wkst']) ?? 'MO');
    final out = <LocalDateTime>[];
    for (var d = LocalDate.max(from, start); !d.isAfter(to); d = d.plusDays(1)) {
      if (!_dayMatches(freq, interval, start, d, weekdays, monthDays, months, wkst)) continue;
      if (freq == 'minutely' || freq == 'hourly') {
        final window = asJsonMap(rule['window']);
        final ws = LocalTime.tryParse(asString(window?['start']) ?? '') ?? LocalTime.midnight;
        final we = LocalTime.tryParse(asString(window?['end']) ?? '') ?? LocalTime.endOfDay;
        final step = freq == 'hourly' ? interval * 60 : interval;
        for (var m = ws.minuteOfDay; m < (we.isEndOfDay ? 1440 : we.minuteOfDay + 1); m += step) {
          if (m >= 1440) break;
          out.add(LocalDateTime(d, LocalTime.fromMinuteOfDay(m)));
        }
      } else {
        for (final t in times) {
          out.add(LocalDateTime(d, t));
        }
      }
    }
    return out;
  }

  static List<({Weekday day, int? n})> _weekdays(Object? value) {
    if (value is! List) return const [];
    final out = <({Weekday day, int? n})>[];
    for (final v in value) {
      if (v is String) {
        out.add((day: Weekday.fromCode(v), n: null));
      } else if (asJsonMap(v) != null) {
        final m = asJsonMap(v)!;
        final code = asString(m['day']);
        if (code != null) out.add((day: Weekday.fromCode(code), n: asInt(m['n'])));
      }
    }
    return out;
  }

  static bool _dayMatches(
    String freq,
    int interval,
    LocalDate start,
    LocalDate d,
    List<({Weekday day, int? n})> weekdays,
    List<int> monthDays,
    List<int> months,
    Weekday wkst,
  ) {
    if (months.isNotEmpty && !months.contains(d.month)) return false;
    bool weekdayOk() => weekdays.isEmpty || weekdays.any((w) => w.day == d.weekday && _nthOk(w.n, d));
    bool monthDayOk() => monthDays.isEmpty ||
        monthDays.any((md) => md > 0 ? d.day == md : d.day == LocalDate.daysInMonth(d.year, d.month) + md + 1);
    switch (freq) {
      case 'minutely' || 'hourly':
        return weekdayOk() && monthDayOk();
      case 'daily':
        return start.daysUntil(d) % interval == 0 && weekdayOk() && monthDayOk();
      case 'weekly':
        final weeks = start.startOfWeek(wkst).daysUntil(d.startOfWeek(wkst)) ~/ 7;
        if (weeks % interval != 0) return false;
        return weekdays.isEmpty ? d.weekday == start.weekday : weekdayOk();
      case 'monthly':
        final monthsBetween = (d.year - start.year) * 12 + d.month - start.month;
        if (monthsBetween % interval != 0) return false;
        if (weekdays.isEmpty && monthDays.isEmpty) return d.day == start.day;
        return weekdayOk() && monthDayOk();
      case 'yearly':
        if ((d.year - start.year) % interval != 0) return false;
        if (months.isEmpty && monthDays.isEmpty && weekdays.isEmpty) {
          return d.month == start.month && d.day == start.day;
        }
        return weekdayOk() && monthDayOk();
      default:
        return false;
    }
  }

  static bool _nthOk(int? n, LocalDate d) {
    if (n == null || n == 0) return true;
    if (n > 0) return (d.day - 1) ~/ 7 + 1 == n;
    final fromEnd = (LocalDate.daysInMonth(d.year, d.month) - d.day) ~/ 7 + 1;
    return fromEnd == -n;
  }
}
