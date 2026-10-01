/// Chart gallery (T6.2.24, dev flavor only — opened from the debug menu): every chart of the kit with
/// fixture data, with toggles for dark theme, right-to-left, large text (2.0) and color-vision
/// deficiency simulation (Machado et al. 2009 matrices, severity 1.0).
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_frame.dart';
import 'package:everslot/features/stats/presentation/charts/chart_samples.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/kpi_tile.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show NotApplicable, PeriodComparison, Value;
import 'package:material_ui/material_ui.dart';

/// Simulated color vision.
enum ColorVision { normal, protanopia, deuteranopia, tritanopia }

/// RGB color matrix of [vision] (null = unchanged).
List<double>? colorVisionMatrix(ColorVision vision) => switch (vision) {
  ColorVision.normal => null,
  ColorVision.protanopia => const [
    0.152286, 1.052583, -0.204868, 0, 0, //
    0.114503, 0.786281, 0.099216, 0, 0,
    -0.003882, -0.048116, 1.051998, 0, 0,
    0, 0, 0, 1, 0,
  ],
  ColorVision.deuteranopia => const [
    0.367322, 0.860646, -0.227968, 0, 0, //
    0.280085, 0.672501, 0.047413, 0, 0,
    -0.011820, 0.042940, 0.968881, 0, 0,
    0, 0, 0, 1, 0,
  ],
  ColorVision.tritanopia => const [
    1.255528, -0.076749, -0.178779, 0, 0, //
    -0.078411, 0.930809, 0.147602, 0, 0,
    0.004733, 0.691367, 0.303900, 0, 0,
    0, 0, 0, 1, 0,
  ],
};

class ChartGalleryScreen extends StatefulWidget {
  const ChartGalleryScreen({super.key});

  @override
  State<ChartGalleryScreen> createState() => _ChartGalleryScreenState();
}

class _ChartGalleryScreenState extends State<ChartGalleryScreen> {
  bool _dark = false;
  bool _rtl = false;
  bool _largeText = false;
  ColorVision _vision = ColorVision.normal;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final base = _dark ? AppTheme.dark() : AppTheme.light();
    final matrix = colorVisionMatrix(_vision);
    Widget charts = Theme(
      data: base,
      child: Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_largeText ? 2 : 1)),
          child: ColoredBox(
            color: base.colorScheme.surface,
            child: ChartPrefs(
              child: ListView(
                key: const ValueKey('chart-gallery-list'),
                padding: const EdgeInsets.all(Space.md),
                children: [
                  const KpiTile(
                    title: 'Adherence',
                    result: MetricResult(
                      'PL-S-03',
                      value: Value<double>(0.8, sampleSize: 5),
                      unit: StatUnit.percent,
                      comparison: PeriodComparison(
                        Value<double>(0.8),
                        Value<double>(0.75),
                        delta: Value<double>(5),
                        deltaPct: NotApplicable<double>('rateUsesPp'),
                        isRate: true,
                      ),
                      spark: [0.5, 0.6, 0.7, 0.8],
                    ),
                  ),
                  for (final s in allChartSamples())
                    Padding(
                      key: ValueKey('gallery-${s.kind.name}-${s.title}'),
                      padding: const EdgeInsetsDirectional.only(top: Space.lg),
                      child: ChartFrame(title: s.title, subtitle: s.kind.name, data: s.data, chartHeight: 180),
                    ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: Space.lg),
                    child: ChartFrame(title: l.chartsGalleryEmptyState, status: ChartFrameStatus.empty),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: Space.lg),
                    child: ChartFrame(
                      title: l.chartsGalleryEmptyState,
                      status: ChartFrameStatus.insufficient,
                      missing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (matrix != null) charts = ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: charts);
    return Scaffold(
      appBar: AppBar(title: Text(l.chartsGalleryTitle)),
      body: Column(
        children: [
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              FilterChip(
                label: Text(l.chartsGalleryDark),
                selected: _dark,
                onSelected: (v) => setState(() => _dark = v),
              ),
              FilterChip(label: Text(l.chartsGalleryRtl), selected: _rtl, onSelected: (v) => setState(() => _rtl = v)),
              FilterChip(
                label: Text(l.chartsGalleryTextScale),
                selected: _largeText,
                onSelected: (v) => setState(() => _largeText = v),
              ),
              DropdownButton<ColorVision>(
                value: _vision,
                hint: Text(l.chartsGalleryVision),
                onChanged: (v) => setState(() => _vision = v ?? ColorVision.normal),
                items: [
                  for (final v in ColorVision.values)
                    DropdownMenuItem(
                      value: v,
                      child: Text(switch (v) {
                        ColorVision.normal => l.chartsVisionNormal,
                        ColorVision.protanopia => l.chartsVisionProtanopia,
                        ColorVision.deuteranopia => l.chartsVisionDeuteranopia,
                        ColorVision.tritanopia => l.chartsVisionTritanopia,
                      }),
                    ),
                ],
              ),
            ],
          ),
          Expanded(child: charts),
        ],
      ),
    );
  }
}
