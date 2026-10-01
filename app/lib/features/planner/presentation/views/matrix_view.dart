import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_actions.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/eisenhower.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Days ahead whose occurrences the matrix considers (plus the backlog).
const matrixHorizonDays = 14;

/// Rules of a matrix config.
MatrixRules matrixRules(PlannerViewConfig c) => MatrixRules(
  importanceThreshold: c.option<int>('importanceThreshold', 3).clamp(1, 4),
  urgencyDays: c.option<int>('urgencyDays', 2).clamp(0, 30),
);

/// Eisenhower matrix (T3.7.09, TickTick style): open items of the next two weeks (next occurrence
/// per series) and the backlog in Do / Schedule / Delegate / Eliminate by importance (priority ≥
/// threshold) and urgency (deadline or start within N days). Rules are editable; dragging a card
/// to another quadrant adjusts its priority and / or deadline.
class MatrixView extends ConsumerWidget {
  const MatrixView({required this.args, super.key});

  final PlannerViewArgs args;

  String get _key => args.viewKey;

  Future<void> _editRules(BuildContext context, WidgetRef ref, MatrixRules rules) async {
    final result = await showAppSheet<MatrixRules>(
      context,
      title: context.l10n.pvRules,
      builder: (ctx) => _RulesSheet(initial: rules),
    );
    if (result == null) return;
    ref
        .read(plannerViewConfigProvider(_key).notifier)
        .change(
          (c) => c
              .withOption('importanceThreshold', result.importanceThreshold)
              .withOption('urgencyDays', result.urgencyDays),
        );
  }

  Future<void> _move(BuildContext context, WidgetRef ref, PlannerItem item, Quadrant to, MatrixRules rules) async {
    final today = ref.read(plannerTodayProvider);
    final move = matrixMove(item, to, rules, today);
    if (move.isEmpty) return;
    final edit = BacklogEdit(priority: move.priority, deadline: move.deadline, clearDeadline: move.clearDeadline);
    final commands = PlannerCommands(context, ref);
    final l = context.l10n;
    if (item.isBacklog) {
      await commands.runExtra(l.tasksUpdated, (a) => a.editBacklog(item, edit));
      return;
    }
    final scope = await commands.askScope(item);
    if (scope == null || !context.mounted) return;
    await commands.runExtra(l.tasksUpdated, (a) => a.editFields(item, edit, scope: scope));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final rules = matrixRules(config);
    final today = ref.watch(plannerTodayProvider);
    final upcoming = filteredItems(ref, DayRange(today, matrixHorizonDays), config).value ?? const <PlannerItem>[];
    final backlog = viewItemFilter(ref, config).apply(ref.watch(viewBacklogProvider).value ?? const <PlannerItem>[]);
    final seen = <String>{};
    final items = [
      for (final i in dayListOrder(upcoming))
        if (i.isOpen && !(i.isQuotaSlot && i.allDay) && seen.add(i.seriesId)) i,
      ...backlog,
    ];
    final byQuadrant = {for (final q in Quadrant.values) q: <PlannerItem>[]};
    for (final i in items) {
      byQuadrant[quadrantOf(i, rules, today)]!.add(i);
    }
    final colors = viewColors(context, ref, config);
    Widget quadrant(Quadrant q) => _QuadrantBox(
      key: ValueKey('quadrant-${q.name}'),
      viewKey: _key,
      quadrant: q,
      title: switch (q) {
        Quadrant.doNow => l.pvQuadDo,
        Quadrant.schedule => l.pvQuadSchedule,
        Quadrant.delegate => l.pvQuadDelegate,
        Quadrant.eliminate => l.pvQuadEliminate,
      },
      items: byQuadrant[q]!,
      colors: colors,
      onDrop: (item) => unawaited(_move(context, ref, item, q, rules)),
    );
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: SizedBox(
        height: 48,
        child: Row(
          children: [
            const SizedBox(width: Space.md),
            Expanded(
              child: Text(
                '${l.pvImportanceRule(PriorityStyle.label(context, rules.importanceThreshold))} · '
                '${l.pvUrgencyRule(rules.urgencyDays)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium,
              ),
            ),
            IconButton(
              key: const Key('matrix-rules'),
              tooltip: l.pvRules,
              icon: const Icon(Icons.tune),
              onPressed: () => unawaited(_editRules(context, ref, rules)),
            ),
            PlannerFilterButton(viewKey: _key),
            PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
          ],
        ),
      ),
      body: Column(
        children: [
          ActiveFilterBar(viewKey: _key),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Space.xs),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: quadrant(Quadrant.doNow)),
                        Expanded(child: quadrant(Quadrant.schedule)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: quadrant(Quadrant.delegate)),
                        Expanded(child: quadrant(Quadrant.eliminate)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      fab: PlannerFab(start: () => null),
    );
  }
}

class _QuadrantBox extends StatelessWidget {
  const _QuadrantBox({
    required this.viewKey,
    required this.quadrant,
    required this.title,
    required this.items,
    required this.colors,
    required this.onDrop,
    super.key,
  });

  final String viewKey;
  final Quadrant quadrant;
  final String title;
  final List<PlannerItem> items;
  final ItemColorResolver colors;
  final ValueChanged<PlannerItem> onDrop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = switch (quadrant) {
      Quadrant.doNow => context.appColors.danger,
      Quadrant.schedule => c.primary,
      Quadrant.delegate => context.appColors.warning,
      Quadrant.eliminate => c.outline,
    };
    return DragTarget<PlannerItem>(
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) => Container(
        margin: const EdgeInsets.all(Space.xxs),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? tint.withValues(alpha: 0.18) : tint.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: tint.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              label: '$title, ${context.l10n.pvItemsCount(items.length)}',
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.all(Space.xs),
                  child: Text(
                    '$title · ${items.length}',
                    style: context.text.titleSmall?.copyWith(color: tint, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Space.xxs),
                children: [
                  for (final i in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xxs),
                      child: LongPressDraggable<PlannerItem>(
                        data: i,
                        feedback: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(Radii.sm),
                          child: SizedBox(
                            width: 180,
                            child: PlannerItemChip(viewKey: viewKey, item: i, colors: colors.of(i), dense: true),
                          ),
                        ),
                        child: PlannerItemChip(
                          key: ValueKey('matrix-card-${i.key}'),
                          viewKey: viewKey,
                          item: i,
                          colors: colors.of(i),
                          dense: true,
                          showDate: !i.isBacklog,
                          longPressMenu: false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesSheet extends StatefulWidget {
  const _RulesSheet({required this.initial});

  final MatrixRules initial;

  @override
  State<_RulesSheet> createState() => _RulesSheetState();
}

class _RulesSheetState extends State<_RulesSheet> {
  late int _threshold = widget.initial.importanceThreshold;
  late int _days = widget.initial.urgencyDays;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.pvImportanceRule(PriorityStyle.label(context, _threshold))),
          Slider(
            key: const Key('rule-importance'),
            value: _threshold.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            label: PriorityStyle.label(context, _threshold),
            onChanged: (v) => setState(() => _threshold = v.round()),
          ),
          Text(l.pvUrgencyRule(_days)),
          Slider(
            key: const Key('rule-urgency'),
            value: _days.toDouble(),
            max: 14,
            divisions: 14,
            label: '$_days',
            onChanged: (v) => setState(() => _days = v.round()),
          ),
          FilledButton(
            key: const Key('rules-save'),
            onPressed: () => Navigator.pop(context, MatrixRules(importanceThreshold: _threshold, urgencyDays: _days)),
            child: Text(l.actionSave),
          ),
        ],
      ),
    );
  }
}
