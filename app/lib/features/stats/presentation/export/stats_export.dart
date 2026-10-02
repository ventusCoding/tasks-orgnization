/// Export of metric series (T6.7.12, GL-12): any chart's table, or every metric of a screen, as CSV
/// (one file per metric) or JSON. Machine-friendly by default — ISO dates, dot decimals, percents
/// as on screen (75 for 75 %) — with a locale-formatted option and a UTF-8 BOM for Excel. A `#`
/// header lists the metric definitions and the period. Files are written to the temporary
/// directory and handed to the share sheet; nothing is uploaded.
library;

import 'dart:convert';
import 'dart:io';

import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show NotApplicable, Value, toCsv;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// One exported file.
final class ExportFile {
  const ExportFile(this.name, this.text, {required this.mimeType});

  final String name;
  final String text;
  final String mimeType;
}

/// Hands exported files to the platform share sheet.
abstract interface class StatsFileSharer {
  Future<void> share(List<ExportFile> files, {required String title});
}

final class PlatformStatsFileSharer implements StatsFileSharer {
  const PlatformStatsFileSharer();

  @override
  Future<void> share(List<ExportFile> files, {required String title}) async {
    final dir = await getTemporaryDirectory();
    final out = <XFile>[];
    for (final f in files) {
      final file = File('${dir.path}/${f.name}');
      await file.writeAsString(f.text, flush: true);
      out.add(XFile(file.path, mimeType: f.mimeType));
    }
    await SharePlus.instance.share(ShareParams(files: out, subject: title));
  }
}

/// The share target of exports (tests replace it).
StatsFileSharer statsFileSharer = const PlatformStatsFileSharer();

/// Export options.
final class ExportOptions {
  const ExportOptions({this.localeFormatted = false, this.bom = false});

  /// Locale-formatted numbers and dates (as on screen) instead of machine-friendly values.
  final bool localeFormatted;

  /// UTF-8 byte-order mark so Excel opens the file as UTF-8.
  final bool bom;
}

/// Machine value of a number as displayed: percent-like units are scaled like the screen (75 for
/// 75 %), everything else is the plotted number.
double machineValue(double v, StatUnit unit) => switch (unit) {
  StatUnit.percent || StatUnit.score => v * 100,
  _ => v,
};

/// One cell of an export: a number (machine or formatted) or a label (ISO date for dates).
Object? exportCell(ChartCell c, StatFormat f, ExportOptions o) {
  if (c.label case final l?) {
    if (!o.localeFormatted && l is DateLabel) return l.date.toIso();
    return f.label(l);
  }
  final v = c.value;
  if (v == null || !v.isFinite) return null;
  if (o.localeFormatted) return f.value(v, c.unit);
  if (c.unit == StatUnit.date) return LocalDateCell.fromEpochDay(v);
  return machineValue(v, c.unit);
}

/// ISO date of an epoch-day number (scatter-by-date axes).
abstract final class LocalDateCell {
  static String fromEpochDay(double v) =>
      DateTime.utc(1970).add(Duration(days: v.round())).toIso8601String().substring(0, 10);
}

/// Header lines of an export: metric definition(s) and period.
List<String> exportHeader(AppLocalizations l, List<String> metricIds, {String? period}) => [
  for (final id in metricIds) ...[
    '$id — ${metricTitle(l, id) ?? id}',
    if (metricFormula(l, id) case final formula?) '  $formula',
  ],
  if (period != null) period,
];

/// CSV of one chart table.
String chartCsv(
  ChartTable table,
  StatFormat f, {
  List<String> header = const [],
  ExportOptions options = const ExportOptions(),
}) => toCsv(
  [for (final c in table.columns) f.label(c)],
  [
    for (final r in table.rows) [for (final c in r) exportCell(c, f, options)],
  ],
  headerComments: header,
  bom: options.bom,
);

/// JSON object of one metric result (value, unit, Δ and the chart table).
Map<String, Object?> metricJson(
  MetricResult r,
  StatFormat f,
  AppLocalizations l, {
  ExportOptions options = const ExportOptions(),
}) {
  final table = r.chart?.toTable();
  return {
    'metric': r.metricId,
    'title': metricTitle(l, r.metricId),
    'unit': r.unit.name,
    if (r.currency != null) 'currency': r.currency,
    'value': switch (r.value) {
      Value<double>(:final value) => options.localeFormatted ? f.value(value, r.unit) : machineValue(value, r.unit),
      NotApplicable<double>(:final reasonKey) => {'notApplicable': reasonKey},
      _ => null,
    },
    if (r.comparison?.delta.valueOrNull case final d?) 'delta': d,
    if (table != null && !table.isEmpty)
      'table': {
        'columns': [for (final c in table.columns) f.label(c)],
        'rows': [
          for (final row in table.rows) [for (final c in row) exportCell(c, f, options)],
        ],
      },
  };
}

/// Files of a chart export.
List<ExportFile> chartExportFiles(
  String metricId,
  ChartData data,
  StatFormat f,
  AppLocalizations l, {
  required bool json,
  String? period,
  ExportOptions options = const ExportOptions(),
}) {
  final table = data.toTable();
  final base = 'everslot_${metricId.toLowerCase()}';
  if (json) {
    return [
      ExportFile(
        '$base.json',
        const JsonEncoder.withIndent('  ').convert({
          'metric': metricId,
          'title': metricTitle(l, metricId),
          'period': ?period,
          'columns': [for (final c in table.columns) f.label(c)],
          'rows': [
            for (final r in table.rows) [for (final c in r) exportCell(c, f, options)],
          ],
        }),
        mimeType: 'application/json',
      ),
    ];
  }
  return [
    ExportFile(
      '$base.csv',
      chartCsv(
        table,
        f,
        header: exportHeader(l, [metricId], period: period),
        options: options,
      ),
      mimeType: 'text/csv',
    ),
  ];
}

/// Files of a whole-screen export: one CSV per metric with a chart (KPI-only metrics go to a
/// summary CSV), or one JSON document.
List<ExportFile> scopeExportFiles(
  Map<String, MetricResult> results,
  StatFormat f,
  AppLocalizations l, {
  required String scopeKey,
  required bool json,
  String? period,
  ExportOptions options = const ExportOptions(),
}) {
  final ids = results.keys.toList()..sort();
  if (json) {
    return [
      ExportFile(
        'everslot_$scopeKey.json',
        const JsonEncoder.withIndent('  ').convert({
          'scope': scopeKey,
          'period': ?period,
          'metrics': [for (final id in ids) metricJson(results[id]!, f, l, options: options)],
        }),
        mimeType: 'application/json',
      ),
    ];
  }
  final summary = <List<Object?>>[];
  final files = <ExportFile>[];
  for (final id in ids) {
    final r = results[id]!;
    if (r.value case Value<double>(:final value)) {
      summary.add([
        id,
        metricTitle(l, id),
        options.localeFormatted ? f.value(value, r.unit) : machineValue(value, r.unit),
        r.unit.name,
      ]);
    }
    final chart = r.chart;
    if (chart != null && !chart.isEmpty && !chart.toTable().isEmpty) {
      files.add(
        ExportFile(
          'everslot_${id.toLowerCase()}.csv',
          chartCsv(
            chart.toTable(),
            f,
            header: exportHeader(l, [id], period: period),
            options: options,
          ),
          mimeType: 'text/csv',
        ),
      );
    }
  }
  return [
    ExportFile(
      'everslot_${scopeKey}_summary.csv',
      toCsv(
        const ['metric', 'title', 'value', 'unit'],
        summary,
        headerComments: exportHeader(l, ids, period: period),
        bom: options.bom,
      ),
      mimeType: 'text/csv',
    ),
    ...files,
  ];
}
