/// Per-habit mini table of the Habits Insights screen (T6.5.17): score, current streak and 30-day
/// success rate; each row opens the habit's Insights.
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:everslot/features/stats/presentation/stats_navigation.dart';
import 'package:material_ui/material_ui.dart';

class HabitMiniTable extends StatelessWidget {
  const HabitMiniTable({required this.rows, super.key});

  /// `{id, name, color, score, streak, rate30}` rows (HB-X-01 args).
  final List<Map<String, Object?>> rows;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = statFormatOf(context);
    if (rows.isEmpty) return Text(l.statsEmptyHabits);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.statsSectionHabitTable, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: Space.xs),
        for (final r in rows)
          InkWell(
            onTap: () => openInsights(context, 'habit', r['id']! as String),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: Space.xs),
                child: Row(
                  children: [
                    ColorDot(
                      r['color'] is int
                          ? CategoryColors.accent(r['color']! as int, Theme.of(context).brightness)
                          : context.colors.primary,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(child: Text('${r['name']}', maxLines: 2, overflow: TextOverflow.ellipsis)),
                    _Cell(
                      label: metricTitle(l, 'HB-H-01') ?? '',
                      value: f.value((r['score'] as num?)?.toDouble() ?? 0, StatUnit.score),
                    ),
                    _Cell(
                      label: metricTitle(l, 'HB-H-02') ?? '',
                      value: f.number(((r['streak'] as num?) ?? 0).toDouble()),
                    ),
                    _Cell(
                      label: metricTitle(l, 'HB-H-05') ?? '',
                      value: r['rate30'] == null ? l.chartsNotApplicable : f.percent((r['rate30']! as num).toDouble()),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: SizedBox(
      width: 56,
      child: Text(
        value,
        textAlign: TextAlign.end,
        style: context.text.labelLarge?.copyWith(fontFeatures: AppTheme.tabular),
      ),
    ),
  );
}
