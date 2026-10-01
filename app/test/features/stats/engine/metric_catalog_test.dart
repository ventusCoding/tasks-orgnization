// Registry lint and catalog generation (T6.1.21). The lint fails when a metric lacks a unique id,
// EN/FR/AR texts (title, description, formula), a chart mapping, a minimum-data policy, or — for P0
// metrics — at least one fixture expectation. The catalog `docs/generated/metrics_catalog.md` is
// generated from the registry; regenerate with
// `UPDATE_STATS_SNAPSHOTS=1 fvm flutter test test/features/stats/engine/metric_catalog_test.dart`.
import 'dart:convert';
import 'dart:io';

import 'package:everslot/features/stats/application/metric_registry.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> arb(String locale) =>
    jsonDecode(File('lib/l10n/parts/stats_$locale.arb').readAsStringSync()) as Map<String, Object?>;

/// Metric ids with at least one expectation in the table fixtures.
Set<String> fixtureCoverage() => {
  for (final f in Directory('test/features/stats/fixtures').listSync().whereType<File>())
    if (f.path.endsWith('.json'))
      for (final e in ((jsonDecode(f.readAsStringSync()) as Map<String, Object?>)['expect']! as List))
        (e as Map<String, Object?>)['metricId']! as String,
};

String catalogMarkdown(MetricRegistry registry, Map<String, Object?> en) {
  String text(String key) => ((en[key] as String?) ?? '').replaceAll('|', r'\|').replaceAll('\n', ' ');
  final b = StringBuffer()
    ..writeln('# Metrics catalog')
    ..writeln()
    ..writeln('Generated from the metric registry (`app/lib/features/stats/application/catalog/`) by')
    ..writeln('`app/test/features/stats/engine/metric_catalog_test.dart` — do not edit by hand.')
    ..writeln()
    ..writeln('${registry.all.length} metrics.')
    ..writeln();
  for (final scope in MetricScope.values) {
    final defs = registry.byScope(scope);
    if (defs.isEmpty) continue;
    b
      ..writeln('## ${scope.name}')
      ..writeln()
      ..writeln('| ID | Name | Formula (EN) | Priority | Chart | Unit |')
      ..writeln('|---|---|---|---|---|---|');
    for (final d in defs) {
      b.writeln(
        '| ${d.id} | ${text(d.titleKey)} | ${text(d.formulaKey)} | ${d.priority.name.toUpperCase()} | '
        '${d.chart.name} | ${d.unit.name} |',
      );
    }
    b.writeln();
  }
  return b.toString();
}

void main() {
  final registry = MetricRegistry.instance;
  final locales = {
    for (final l in ['en', 'fr', 'ar']) l: arb(l),
  };

  test('lint: every metric is complete', () {
    final problems = <String>[];
    final seen = <String>{};
    for (final d in registry.all) {
      if (!seen.add(d.id)) problems.add('${d.id}: duplicate id');
      for (final key in [d.titleKey, d.descriptionKey, d.formulaKey]) {
        for (final e in locales.entries) {
          final v = e.value[key];
          if (v is! String || v.trim().isEmpty) problems.add('${d.id}: $key missing in ${e.key}');
        }
      }
      if (!metricIdsWithTexts.contains(d.id)) problems.add('${d.id}: no text mapping in stats_l10n.dart');
      if (d.minDataGuard == null) problems.add('${d.id}: no minimum-data policy');
      if (!ChartKind.values.contains(d.chart)) problems.add('${d.id}: no chart mapping');
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('lint: every P0 metric has at least one fixture expectation', () {
    final covered = fixtureCoverage();
    final missing = [
      for (final d in registry.all)
        if (d.priority == MetricPriority.p0 && !covered.contains(d.id)) d.id,
    ];
    expect(missing, isEmpty, reason: 'P0 metrics without a fixture: ${missing.join(', ')}');
  });

  test('the generated catalog is up to date', () {
    final file = File('../docs/generated/metrics_catalog.md');
    final actual = catalogMarkdown(registry, locales['en']!);
    if (Platform.environment['UPDATE_STATS_SNAPSHOTS'] == '1' || !file.existsSync()) {
      file
        ..createSync(recursive: true)
        ..writeAsStringSync(actual);
    }
    expect(file.readAsStringSync(), actual);
  });
}
