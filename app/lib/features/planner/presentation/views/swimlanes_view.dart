import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/grid/engine/swimlanes.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/grid/timeline_page.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/time_grid_view.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Lane category ids of a swimlanes config: `options.lanes`, or every category in its order when
/// none are picked (at most six).
List<String> swimlaneIds(PlannerViewConfig config, List<Category> categories) {
  final picked = config.option<List<Object?>>('lanes', const []).whereType<String>().toList();
  if (picked.isNotEmpty) return picked;
  return [for (final c in categories.take(6)) c.id];
}

/// Category swimlanes (T3.6.15, Google side-by-side style): the time-grid engine with each day
/// column split into one sub-column per lane (`options.lanes`, plus "Other"). A legend above the
/// grid names the lanes; the menu picks and orders them, or opens the timeline with rows per
/// category.
class SwimlanesView extends ConsumerStatefulWidget {
  const SwimlanesView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<SwimlanesView> createState() => _SwimlanesViewState();
}

class _SwimlanesViewState extends ConsumerState<SwimlanesView> {
  List<String>? _lanes;
  TileLayoutStrategy _strategy = overlapStrategy;
  OverlayPainterBuilder? _dividers;

  String get _key => widget.args.viewKey;

  /// Keeps one strategy instance per lane list (the engine memoizes layouts by strategy identity).
  void _sync(List<String> lanes, Color divider) {
    if (_lanes != null && _listEquals(_lanes!, lanes)) return;
    _lanes = lanes;
    _strategy = (slice, laneCap, minDuration) => layoutSwimlanes(
      [for (final (i, s) in slice.timed.indexed) SwimlaneInput(i, s.tStart, s.tEnd, s.item.categoryId)],
      lanes,
      laneCap: laneCap,
      minDuration: minDuration,
    );
    final count = lanes.length + 1;
    _dividers = (ctx) => _LaneDividerPainter(days: ctx.days.length, lanes: count, color: divider);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _pickLanes(List<Category> categories, List<String> current) async {
    final result = await showAppSheet<List<String>>(
      context,
      title: context.l10n.pvLanes,
      builder: (ctx) => _LanePicker(categories: categories, initial: current),
    );
    if (result == null || !mounted) return;
    ref.read(plannerViewConfigProvider(_key).notifier).change((c) => c.withOption('lanes', result));
  }

  void _openTimeline() {
    ref.read(plannerViewConfigProvider('timeline').notifier).change((c) => c.withOption('groupBy', 'category'));
    ref.read(plannerNavProvider).openView(context, 'timeline', date: ref.read(plannerAnchorProvider));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final lanes = swimlaneIds(config, categories);
    _sync(lanes, context.colors.outline);
    final byId = {for (final c in categories) c.id: c};
    final legend = [for (final id in lanes) (byId[id]?.name ?? '?', byId[id]?.color), (l.pvLaneOther, null)];
    final use24h = ref.watch(userPreferencesProvider).use24h;
    return TimeGridView(
      args: widget.args,
      tileLayout: _strategy,
      overlays: [?_dividers],
      menuExtra: [
        ('lanes', l.pvLanes, () => unawaited(_pickLanes(categories, lanes))),
        ('timeline', l.pvShowAsTimeline, _openTimeline),
      ],
      header: (days) => _LaneLegend(
        days: days.length,
        lanes: legend,
        rulerWidth: timeRulerWidth(MediaQuery.textScalerOf(context), use24h: use24h),
      ),
    );
  }
}

/// Lane names (with their category color) repeated over each visible day column.
class _LaneLegend extends StatelessWidget {
  const _LaneLegend({required this.days, required this.lanes, required this.rulerWidth});

  final int days;
  final List<(String, int?)> lanes;
  final double rulerWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    return Semantics(
      label: [for (final (name, _) in lanes) name].join(', '),
      child: ExcludeSemantics(
        child: Container(
          key: const Key('swimlane-legend'),
          height: 22,
          color: c.surfaceContainerLow,
          padding: EdgeInsetsDirectional.only(start: rulerWidth),
          child: Row(
            children: [
              for (var d = 0; d < (days == 0 ? 1 : days); d++)
                for (final (name, color) in lanes)
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          color: color == null
                              ? c.outline
                              : CategoryColors.accent(
                                  color,
                                  brightness,
                                  highContrast: context.a11y.highContrastCategories,
                                ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            textScaler: TextScaler.noScaling,
                            style: context.text.labelSmall?.copyWith(fontSize: 10, color: c.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed separators between the lanes of every day column.
class _LaneDividerPainter extends CustomPainter {
  _LaneDividerPainter({required this.days, required this.lanes, required this.color});

  final int days;
  final int lanes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (days == 0 || lanes < 2) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final colW = size.width / days;
    for (var d = 0; d < days; d++) {
      for (var k = 1; k < lanes; k++) {
        final x = d * colW + colW * k / lanes;
        for (var y = 0.0; y < size.height; y += 8) {
          canvas.drawLine(Offset(x, y), Offset(x, y + 4), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LaneDividerPainter old) => old.days != days || old.lanes != lanes || old.color != color;
}

/// Picks lanes (checkboxes) and orders them (up / down).
class _LanePicker extends StatefulWidget {
  const _LanePicker({required this.categories, required this.initial});

  final List<Category> categories;
  final List<String> initial;

  @override
  State<_LanePicker> createState() => _LanePickerState();
}

class _LanePickerState extends State<_LanePicker> {
  late final List<String> _order = [
    ...widget.initial,
    for (final c in widget.categories)
      if (!widget.initial.contains(c.id)) c.id,
  ];
  late final Set<String> _on = {...widget.initial};

  void _move(int from, int to) => setState(() => _order.insert(to, _order.removeAt(from)));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final byId = {for (final c in widget.categories) c.id: c};
    final ids = [
      for (final id in _order)
        if (byId.containsKey(id)) id,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
          child: Text(l.pvLanesHint, style: context.text.bodySmall),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final (i, id) in ids.indexed)
                CheckboxListTile(
                  key: ValueKey('lane-$id'),
                  value: _on.contains(id),
                  title: Text(byId[id]!.name),
                  secondary: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l.pvMoveUp,
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: i == 0 ? null : () => _move(_order.indexOf(id), _order.indexOf(ids[i - 1])),
                      ),
                      IconButton(
                        tooltip: l.pvMoveDown,
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: i == ids.length - 1
                            ? null
                            : () => _move(_order.indexOf(id), _order.indexOf(ids[i + 1])),
                      ),
                    ],
                  ),
                  onChanged: (v) => setState(() => v == true ? _on.add(id) : _on.remove(id)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Space.md),
          child: FilledButton(
            key: const Key('lanes-save'),
            onPressed: () => Navigator.pop(context, [
              for (final id in ids)
                if (_on.contains(id)) id,
            ]),
            child: Text(l.actionSave),
          ),
        ),
      ],
    );
  }
}
