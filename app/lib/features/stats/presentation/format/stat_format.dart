/// Locale-aware display of metric values, deltas and chart labels (T6.1.07).
///
/// Durations come in two forms (long "1 h 25 min", compact "1:25") plus "3 d 4 h" for live
/// counters; rates show as percentages and rate deltas in percentage points; money uses the
/// tracker's currency; estimates carry "≈". Western vs Arabic-Indic digits follow the user's
/// preference. Pure presentation helper (no widgets) so it is unit-testable per locale.
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show Granularity, Insufficient, NotApplicable, Stat, Value;
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, LocalTime, Weekday;
import 'package:intl/intl.dart';

/// Direction of a delta arrow.
enum DeltaArrow { up, down, flat }

/// A formatted delta: text, arrow and whether the change is good, bad or neutral.
class DeltaView {
  const DeltaView({required this.text, required this.arrow, required this.good, required this.semantics});

  final String text;
  final DeltaArrow arrow;

  /// true = good, false = bad, null = neutral (color is never the only signal).
  final bool? good;
  final String semantics;
}

class StatFormat {
  StatFormat(this.l10n, this.locale, {this.use24h = true, this.arabicDigits = false})
    : _app = AppFormat(locale, use24h: use24h, l10n: l10n);

  final AppLocalizations l10n;
  final String locale;
  final bool use24h;
  final bool arabicDigits;
  final AppFormat _app;

  static const _eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  /// Applies the digit preference to any formatted text.
  String digits(String s) {
    final b = StringBuffer();
    for (final ch in s.runes) {
      final c = String.fromCharCode(ch);
      if (arabicDigits && ch >= 0x30 && ch <= 0x39) {
        b.write(_eastern[ch - 0x30]);
      } else if (!arabicDigits && ch >= 0x660 && ch <= 0x669) {
        b.write(ch - 0x660);
      } else {
        b.write(c);
      }
    }
    return b.toString();
  }

  // ------------------------------------------------------------------------------------------
  // Numbers

  String number(double v, {int? decimals}) {
    final d = decimals ?? (v == v.roundToDouble() ? 0 : (v.abs() < 10 ? 1 : 0));
    return digits(NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: d).format(v));
  }

  /// 12.3 k, 4.5 M.
  String compact(double v) {
    final a = v.abs();
    if (a >= 1e6) return l10n.chartsMega(number(v / 1e6, decimals: 1));
    if (a >= 1e4) return l10n.chartsKilo(number(v / 1e3, decimals: a >= 1e5 ? 0 : 1));
    return number(v);
  }

  String percent(double ratio, {int? decimals}) {
    final d = decimals ?? (ratio.abs() < 0.1 && ratio != 0 ? 1 : 0);
    return digits(NumberFormat.decimalPercentPattern(locale: locale, decimalDigits: d).format(ratio));
  }

  String currency(double v, String? code) {
    final c = (code == null || code.isEmpty) ? 'EUR' : code;
    return digits(NumberFormat.simpleCurrency(locale: locale, name: c).format(v));
  }

  String bytes(double v) {
    if (v >= 1 << 30) return l10n.chartsBytesGb(number(v / (1 << 30), decimals: 1));
    if (v >= 1 << 20) return l10n.chartsBytesMb(number(v / (1 << 20), decimals: 1));
    return l10n.chartsBytesKb(number(math.max(1, v / 1024), decimals: 0));
  }

  // ------------------------------------------------------------------------------------------
  // Durations

  /// "1 h 25 min", "45 min", "3 d 4 h", "20 s". Negative values keep their sign.
  String duration(double minutes) {
    final sign = minutes < 0 ? '−' : '';
    final total = minutes.abs();
    if (total < 1) return sign + digits(l10n.chartsSecondsOnly((total * 60).round().toString()));
    final whole = total.round();
    final days = whole ~/ 1440;
    final hours = (whole % 1440) ~/ 60;
    final mins = whole % 60;
    final String text;
    if (days > 0) {
      text = hours == 0 ? l10n.chartsDaysOnly(days) : l10n.chartsDaysHours('$days', '$hours');
    } else if (hours > 0) {
      text = mins == 0 ? l10n.chartsHoursOnly('$hours') : l10n.chartsHoursMinutes('$hours', '$mins');
    } else {
      text = l10n.chartsMinutesOnly('$mins');
    }
    return sign + digits(text);
  }

  /// Compact "1:25" (hours:minutes); days prefix "3 d 04:12".
  String durationCompact(double minutes) {
    final whole = minutes.abs().round();
    final days = whole ~/ 1440;
    final h = (whole % 1440) ~/ 60;
    final m = (whole % 60).toString().padLeft(2, '0');
    final core = days > 0 ? '${l10n.chartsDaysOnly(days)} ${h.toString().padLeft(2, '0')}:$m' : '$h:$m';
    return (minutes < 0 ? '−' : '') + digits(core);
  }

  /// Live counter "3 d 04:12:09".
  String counter(Duration d) => digits(AppFormat.counter(d));

  // ------------------------------------------------------------------------------------------
  // Dates & labels

  String date(LocalDate d) => digits(_app.dateMedium(d));

  String dayShort(LocalDate d) => digits(_app.dayShort(d));

  String weekday(Weekday w) => _app.weekdayShort(w);

  String weekdayLong(Weekday w) => _app.weekdayLong(w);

  String clock(double minuteOfDay) {
    final m = minuteOfDay.round() % 1440;
    return digits(_app.time(LocalTime.fromMinuteOfDay(m < 0 ? m + 1440 : m)));
  }

  String hour(int h) => digits(_app.time(LocalTime(h % 24, 0)));

  String dateTime(DateTime instant) => digits(DateFormat.yMMMd(locale).add_Hm().format(instant.toLocal()));

  /// Short bucket label for axes.
  String bucket(LocalDate d, Granularity g) => digits(switch (g) {
    Granularity.day => DateFormat('d MMM', locale).format(d.toDateTimeUtc()),
    Granularity.week => DateFormat('d MMM', locale).format(d.toDateTimeUtc()),
    Granularity.month => DateFormat.MMM(locale).format(d.toDateTimeUtc()),
    Granularity.quarter => 'Q${(d.month - 1) ~/ 3 + 1} ${d.year}',
    Granularity.year => '${d.year}',
  });

  String label(ChartLabel label) => switch (label) {
    TextLabel(:final text) => text,
    TokenLabel(:final token) => labelTokenText(l10n, token),
    DateLabel(:final date, :final granularity) => bucket(date, granularity),
    WeekdayLabel(:final weekday) => this.weekday(weekday),
    HourLabel(:final hour) => this.hour(hour),
    InstantLabel(:final instant) => dateTime(instant),
    NumberLabel(:final value, :final unit) => this.value(value, unit),
    RangeLabel(:final lower, :final upper, :final unit) => l10n.chartsRange(value(lower, unit), value(upper, unit)),
    OrdinalLabel(:final kind, :final n) => digits(switch (kind) {
      OrdinalKind.week => l10n.chartsOrdinalWeek('$n'),
      OrdinalKind.run => l10n.chartsOrdinalRun('$n'),
      OrdinalKind.level => l10n.chartsOrdinalLevel('$n'),
      OrdinalKind.priority => l10n.chartsOrdinalPriority('$n'),
      OrdinalKind.depth => l10n.chartsOrdinalDepth('$n'),
      OrdinalKind.attempt => l10n.chartsOrdinalAttempt('$n'),
      OrdinalKind.month => l10n.chartsOrdinalMonth('$n'),
      OrdinalKind.year => l10n.chartsOrdinalYear('$n'),
    }),
  };

  // ------------------------------------------------------------------------------------------
  // Values

  /// A value in [unit] ([currency] for money; [estimate] prefixes "≈").
  String value(double v, StatUnit unit, {String? currency, bool estimate = false}) {
    final text = switch (unit) {
      StatUnit.count => v.abs() >= 1e4 ? compact(v) : number(v),
      StatUnit.minutes => duration(v),
      StatUnit.hours => duration(v * 60),
      StatUnit.days => v == v.roundToDouble() ? digits(l10n.chartsDaysOnly(v.round())) : duration(v * 1440),
      StatUnit.percent => percent(v),
      StatUnit.pp => digits(l10n.chartsPp(_signed(number(v, decimals: v.abs() < 10 ? 1 : 0), v))),
      StatUnit.ratio => digits(l10n.chartsRatio(number(v, decimals: 2))),
      StatUnit.currency => this.currency(v, currency),
      StatUnit.score => number((v * 100).roundToDouble()),
      StatUnit.perDay => digits(l10n.chartsPerDay(number(v, decimals: v.abs() < 10 ? 1 : 0))),
      StatUnit.perWeek => digits(l10n.chartsPerWeek(number(v, decimals: v.abs() < 10 ? 1 : 0))),
      StatUnit.clock => clock(v),
      StatUnit.date => date(LocalDate.fromEpochDay(v.round())),
      StatUnit.seconds => v.abs() >= 60 ? duration(v / 60) : digits(l10n.chartsSecondsOnly(number(v))),
      StatUnit.bytes => bytes(v),
    };
    return estimate ? l10n.chartsEstimate(text) : text;
  }

  String _signed(String text, double v) =>
      v > 0 ? '+$text' : (v < 0 && !text.startsWith('-') && !text.startsWith('−') ? '−$text' : text);

  /// Headline text of a result: the value, "Needs N more…" or "—".
  String headline(MetricResult r) => stat(r.value, r.unit, currency: r.currency, estimate: r.estimate);

  String stat(Stat<double> s, StatUnit unit, {String? currency, bool estimate = false}) => switch (s) {
    Value<double>(:final value) => this.value(value, unit, currency: currency, estimate: estimate),
    Insufficient<double>() => l10n.chartsNeedsMore(s.missing.ceil()),
    NotApplicable<double>() => l10n.chartsNotApplicable,
  };

  /// "± 7 pp" half-width of a rate interval (shown below 20 units).
  String? intervalHalfWidth(MetricResult r) {
    final v = r.value;
    if (v is! Value<double> || v.interval == null) return null;
    final half = (v.interval!.upper - v.interval!.lower) / 2;
    return l10n.chartsPlusMinus(digits(l10n.chartsPp(number(half * 100, decimals: 0))));
  }

  /// Delta vs the previous period, colored by [direction].
  DeltaView? delta(MetricResult r, MetricDirection direction) {
    final c = r.comparison;
    if (c == null) return null;
    final d = c.delta;
    if (d is! Value<double>) {
      if (d case NotApplicable<double>(reasonKey: 'new')) {
        return DeltaView(text: l10n.chartsDeltaNew, arrow: DeltaArrow.up, good: null, semantics: l10n.chartsDeltaNew);
      }
      return null;
    }
    final v = d.value;
    final isNew = c.previous is Value<double> && (c.previous as Value<double>).value == 0 && v > 0 && !c.isRate;
    if (isNew) {
      return DeltaView(text: l10n.chartsDeltaNew, arrow: DeltaArrow.up, good: null, semantics: l10n.chartsDeltaNew);
    }
    final flat = v.abs() < 1e-9;
    final arrow = flat ? DeltaArrow.flat : (v > 0 ? DeltaArrow.up : DeltaArrow.down);
    final unit = c.isRate ? StatUnit.pp : r.unit;
    final magnitude = c.isRate
        ? digits(l10n.chartsPp(number(v.abs(), decimals: v.abs() < 10 ? 1 : 0)))
        : value(v.abs(), unit == StatUnit.score ? StatUnit.count : unit, currency: r.currency);
    final shown = unit == StatUnit.score ? number((v.abs() * 100).roundToDouble()) : magnitude;
    final text = flat ? l10n.chartsDeltaFlat : '${v > 0 ? '+' : '−'}$shown';
    final good = flat || direction == MetricDirection.neutral
        ? null
        : (direction == MetricDirection.higherIsBetter) == (v > 0);
    final spoken = c.isRate ? digits(l10n.chartsPpSpoken(number(v.abs(), decimals: v.abs() < 10 ? 1 : 0))) : shown;
    final semantics = flat ? l10n.chartsDeltaFlat : (v > 0 ? l10n.chartsDeltaUp(spoken) : l10n.chartsDeltaDown(spoken));
    return DeltaView(text: text, arrow: arrow, good: good, semantics: semantics);
  }

  /// Text of a note / reason key.
  String? note(String? key) => key == null ? null : noteText(l10n, key);
}
