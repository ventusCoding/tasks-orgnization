import 'package:everslot/features/stats/charts.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show Insufficient, NotApplicable, PeriodComparison, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

Future<StatFormat> formatFor(String locale, {bool arabicDigits = false}) async {
  await initializeDateFormatting(locale);
  final l10n = await AppLocalizations.delegate.load(Locale(locale));
  return StatFormat(l10n, locale, arabicDigits: arabicDigits);
}

/// Formatter output snapshot per locale (the "golden" of T6.1.07).
Map<String, String> snapshot(StatFormat f) => {
  'minutes85': f.value(85, StatUnit.minutes),
  'minutes45': f.value(45, StatUnit.minutes),
  'minutes120': f.value(120, StatUnit.minutes),
  'minutesDays': f.value(1440 * 3 + 240, StatUnit.minutes),
  'compact85': f.durationCompact(85),
  'percent': f.value(0.8, StatUnit.percent),
  'percentSmall': f.value(0.053, StatUnit.percent),
  'pp': f.value(5, StatUnit.pp),
  'compactCount': f.value(12345, StatUnit.count),
  'currency': f.value(748.2, StatUnit.currency, currency: 'EUR'),
  'estimate': f.value(23940, StatUnit.minutes, estimate: true),
  'days1': f.value(1, StatUnit.days),
  'days5': f.value(5, StatUnit.days),
  'score': f.value(0.798, StatUnit.score),
  'perDay': f.value(2.5, StatUnit.perDay),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('EN snapshot', () async {
    final f = await formatFor('en');
    expect(snapshot(f), {
      'minutes85': '1 h 25 min',
      'minutes45': '45 min',
      'minutes120': '2 h',
      'minutesDays': '3 d 4 h',
      'compact85': '1:25',
      'percent': '80%',
      'percentSmall': '5.3%',
      'pp': '+5.0 pp',
      'compactCount': '12.3 k',
      'currency': '€748.20',
      'estimate': '≈ 16 d 15 h',
      'days1': '1 day',
      'days5': '5 days',
      'score': '80',
      'perDay': '2.5/day',
    });
  });

  test('FR snapshot', () async {
    final f = await formatFor('fr');
    // French uses (narrow) no-break spaces before units and symbols.
    final s = {for (final e in snapshot(f).entries) e.key: e.value.replaceAll(RegExp('[\u00a0\u202f]'), ' ')};
    expect(s['minutes85'], '1 h 25 min');
    expect(s['minutesDays'], '3 j 4 h');
    expect(s['percent'], '80 %');
    expect(s['days5'], '5 jours');
    expect(s['currency'], '748,20 €');
    expect(s['perDay'], '2,5/jour');
    expect(s['pp'], '+5,0 pts');
  });

  test('AR snapshot and digit preference', () async {
    final western = snapshot(await formatFor('ar'));
    expect(western['minutes85'], '1 س 25 د');
    expect(western['days5'], contains('5'));
    final eastern = snapshot(await formatFor('ar', arabicDigits: true));
    expect(eastern['minutes85'], '١ س ٢٥ د');
    expect(eastern['score'], '٨٠');
  });

  test('deltas: rates in pp, direction colors, "new" when the previous value was 0', () async {
    final f = await formatFor('en');
    MetricResult r(double cur, double prev, {bool rate = false, StatUnit unit = StatUnit.count}) => MetricResult(
      'X',
      value: Value<double>(cur),
      unit: unit,
      comparison: PeriodComparison(
        Value<double>(cur),
        Value<double>(prev),
        delta: Value<double>(rate ? (cur - prev) * 100 : cur - prev),
        deltaPct: prev == 0 ? const NotApplicable<double>('new') : Value<double>((cur - prev) / prev),
        isRate: rate,
      ),
    );
    final up = f.delta(r(0.8, 0.75, rate: true, unit: StatUnit.percent), MetricDirection.higherIsBetter)!;
    expect(up.text, '+5.0 pp');
    expect(up.arrow, DeltaArrow.up);
    expect(up.good, isTrue);
    expect(up.semantics, 'up 5.0 percentage points');
    final down = f.delta(r(2, 5), MetricDirection.lowerIsBetter)!;
    expect(down.arrow, DeltaArrow.down);
    expect(down.good, isTrue);
    expect(f.delta(r(3, 0), MetricDirection.higherIsBetter)!.text, 'new');
    expect(f.delta(r(3, 3), MetricDirection.higherIsBetter)!.arrow, DeltaArrow.flat);
    expect(f.delta(r(90, 30, unit: StatUnit.minutes), MetricDirection.neutral)!.text, '+1 h');
  });

  test('headline of insufficient and not-applicable stats', () async {
    final f = await formatFor('en');
    expect(f.headline(const MetricResult('X', value: Insufficient<double>(20, 17))), 'Needs 3 more data points');
    expect(f.headline(const MetricResult('X', value: NotApplicable<double>('zeroDenominator'))), '—');
    expect(f.note('usedPlanned'), startsWith('Planned time shown'));
  });

  test('labels: tokens, dates, ranges, ordinals', () async {
    final f = await formatFor('en');
    expect(f.label(const TokenLabel(LabelToken.doneOnTime)), 'On time');
    expect(f.label(const OrdinalLabel(OrdinalKind.week, 3)), 'Week 3');
    expect(f.label(const RangeLabel(0, 15, StatUnit.minutes)), '1 s–15 min'.replaceFirst('1 s', '0 s'));
  });
}
