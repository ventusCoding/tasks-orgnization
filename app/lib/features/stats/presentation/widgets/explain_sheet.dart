/// "ⓘ Explain" sheet (T6.1.16): what the metric measures, its formula in plain words, the value,
/// previous value, sample size, interval and exclusions of the current view, the minimum-data rule
/// and sources (health content).
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/quit_health_content.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:everslot/features/stats/presentation/stats_navigation.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show Value;
import 'package:material_ui/material_ui.dart';

/// Localized text of an exclusion key with its count.
String? exclusionText(AppLocalizations l, String key, int count) => switch (key) {
  'skipped' => l.statsExclusionSkipped(count),
  'excused' => l.statsExclusionExcused(count),
  'paused' => l.statsExclusionPaused(count),
  'cancelled' => l.statsExclusionCancelled(count),
  'frozen' => l.statsExclusionFrozen(count),
  'unplanned' => l.statsExclusionUnplanned(count),
  'unknown' => l.statsExclusionUnknown(count),
  _ => null,
};

/// Opens the explain sheet of [def] with the values of the current view.
Future<void> showExplainSheet(
  BuildContext context, {
  required MetricDefinition def,
  MetricResult? result,
  String? periodText,
  VoidCallback? onGlossary,
}) => showAppSheet<void>(
  context,
  builder: (sheet) => ExplainSheet(
    def: def,
    result: result,
    periodText: periodText,
    // Every explain sheet links to the glossary (T6.1.21); the caller's context outlives the sheet.
    onGlossary:
        onGlossary ??
        () {
          Navigator.of(sheet).pop();
          if (context.mounted) openGlossary(context, query: def.id);
        },
  ),
);

class ExplainSheet extends StatelessWidget {
  const ExplainSheet({required this.def, super.key, this.result, this.periodText, this.onGlossary});

  final MetricDefinition def;
  final MetricResult? result;
  final String? periodText;
  final VoidCallback? onGlossary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = statFormatOf(context);
    final r = result;
    final v = r?.value;
    final rule = def.minSample;
    final exclusions = [
      for (final e in (r?.exclusions ?? const <String, num>{}).entries)
        if (exclusionText(l, e.key, e.value.round()) case final text?) text,
    ];
    final note = r?.note == null ? null : f.note(r!.note);
    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsetsDirectional.only(top: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: Space.xs),
          ...children,
        ],
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(metricTitle(l, def.id) ?? def.id, style: context.text.titleLarge),
            Text(
              l.statsExplainId(def.id),
              style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            section(l.statsExplainWhat, [Text(metricDescription(l, def.id) ?? '')]),
            section(l.statsExplainFormula, [Text(metricFormula(l, def.id) ?? '')]),
            if (r != null)
              section(l.statsExplainThisView, [
                if (periodText != null) Text(periodText!, style: context.text.labelMedium),
                Text(l.statsExplainValue(f.headline(r))),
                if (r.previous case final prev? when r.comparison != null)
                  Text(l.statsExplainPrevious(f.stat(prev, r.unit, currency: r.currency, estimate: r.estimate))),
                if (v is Value<double> && v.sampleSize != null) Text(l.statsExplainSample(v.sampleSize!.round())),
                if (v is Value<double> && v.interval != null && def.isRate)
                  Text(l.statsExplainInterval(f.percent(v.interval!.lower), f.percent(v.interval!.upper))),
                if (note != null)
                  Text(note, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                const SizedBox(height: Space.xs),
                Text(l.statsExplainExcluded, style: context.text.labelMedium),
                if (exclusions.isEmpty) Text(l.statsExplainNothingExcluded, style: context.text.bodySmall),
                for (final e in exclusions) Text('• $e', style: context.text.bodySmall),
              ]),
            if (rule != null)
              section(l.statsExplainMinData(rule.hiddenBelow.round().toString()), [
                if (rule.intervalBelow != null)
                  Text(l.statsExplainIntervalRule(rule.intervalBelow!.round().toString())),
              ]),
            if (def.estimate || (r?.estimate ?? false))
              section(l.statsExplainEstimate, [
                if (def.unit == StatUnit.minutes && def.hasSources) Text(l.statsExplainPopulation),
              ]),
            if (def.hasSources)
              section(l.statsExplainSources, [
                for (final s in _sourcesOf(def.id))
                  Text('${sourceName(l, s.name) ?? s.name} — ${s.url}', style: context.text.bodySmall),
              ]),
            if (onGlossary != null) ...[
              const SizedBox(height: Space.lg),
              TextButton.icon(
                onPressed: onGlossary,
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(l.statsExplainGlossary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static List<HealthSource> _sourcesOf(String id) => switch (id) {
    'QT-10' => const [HealthSource.jackson2025, HealthSource.bmj2000],
    'QT-11' => const [HealthSource.who, HealthSource.nhs, HealthSource.cdc, HealthSource.acs, HealthSource.hse],
    'QT-16' => const [HealthSource.hse],
    'QT-25' => const [HealthSource.nci],
    _ => const [],
  };
}
