import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/planner/presentation/grid/engine/free_slots.dart';
import 'package:everslot/features/planner/presentation/grid/engine/plan_summary.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The range of consecutive days from [days] (first → last).
DayRange rangeOfDays(List<LocalDate> days) => DayRange(days.first, days.first.daysUntil(days.last) + 1);

String _categoryName(WidgetRef ref, BuildContext context, String? id) =>
    id == null ? context.l10n.pvNoCategory : (ref.watch(categoryByIdProvider(id))?.name ?? context.l10n.pvNoCategory);

/// Week summary footer (T3.4.17): planned and tracked hours, completion and top categories of the
/// visible days; collapsible (remembered per view); tap → Planner insights for the range.
class PlanSummaryFooter extends ConsumerWidget {
  const PlanSummaryFooter({required this.viewKey, required this.days, super.key});

  final String viewKey;
  final List<LocalDate> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (days.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final range = rangeOfDays(days);
    final items = ref.watch(viewItemsProvider(range)).value;
    if (items == null) return const SizedBox.shrink();
    final collapsed = ref.watch(plannerViewStateProvider(viewKey).select((s) => s?.extra['summaryCollapsed'] == true));
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final s = PlanSummary.of(items, range);
    void toggle() => ref.read(plannerViewStateProvider(viewKey).notifier).update((v) => v.withExtra('summaryCollapsed', !collapsed));
    final colors = context.colors;
    final label = [
      l.pvWeekSummary,
      '${l.pvPlanned} ${f.duration(s.plannedMinutes)}',
      '${l.pvTracked} ${f.duration(s.trackedMinutes)}',
      if (s.completion case final c?) '${l.pvCompletion} ${f.percent(c)}',
    ].join(', ');
    return Material(
      color: colors.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: InkWell(
          key: const Key('week-summary'),
          onTap: () => ref.read(plannerNavProvider).openInsights(context, from: range.start, days: range.days),
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Space.md, Space.xs, Space.xs, Space.xs),
              child: Row(
                children: [
                  Icon(Icons.insights_outlined, size: 18, color: colors.primary),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: collapsed
                        ? Text(l.pvWeekSummary, style: context.text.labelLarge)
                        : Wrap(
                            spacing: Space.md,
                            runSpacing: Space.xxs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _Stat(label: l.pvPlanned, value: f.duration(s.plannedMinutes)),
                              _Stat(label: l.pvTracked, value: f.duration(s.trackedMinutes)),
                              _Stat(label: l.pvCompletion, value: s.completion == null ? '—' : f.percent(s.completion!)),
                              if (s.topCategories.isNotEmpty)
                                _Stat(
                                  label: l.pvTopCategories,
                                  value: [for (final (id, _) in s.topCategories) _categoryName(ref, context, id)].join(' · '),
                                ),
                            ],
                          ),
                  ),
                  IconButton(
                    key: const Key('week-summary-toggle'),
                    tooltip: collapsed ? l.pvExpand : l.pvCollapse,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(collapsed ? Icons.expand_less : Icons.expand_more),
                    onPressed: toggle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: '$label ', style: TextStyle(color: context.colors.onSurfaceVariant)),
        TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
    style: context.text.labelMedium,
  );
}

/// Day summary header (T3.5.12): planned time, free time within work hours, done / total and
/// tracked time of [day]; tap → Planner insights for that day.
class DaySummaryCard extends ConsumerWidget {
  const DaySummaryCard({required this.day, required this.items, super.key});

  final LocalDate day;
  final List<PlannerItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final work = ref.watch(plannerWorkSettingsProvider);
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(plannerZoneProvider);
    final s = PlanSummary.of(
      items,
      DayRange(day, 1),
      work: FreeSlotOptions(window: work.hours, workDays: work.days),
      elapsed: (a, b) => elapsedMinutes(zones, zone, a, b),
    );
    final free = s.freeMinutes ?? 0;
    final stats = [
      (l.pvPlanned, f.duration(s.plannedMinutes)),
      (l.pvFreeInWorkHours, f.duration(free)),
      (l.pvDoneTotal, '${f.number(s.done)}/${f.number(s.total)}'),
      (l.pvTracked, f.duration(s.trackedMinutes)),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, Space.xs, Space.sm, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          key: const Key('day-summary'),
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () => ref.read(plannerNavProvider).openInsights(context, from: day, days: 1),
          child: Semantics(
            button: true,
            label: [l.pvDaySummary, for (final (k, v) in stats) '$k $v'].join(', '),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
              child: Row(
                children: [
                  for (final (k, v) in stats)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            k,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
