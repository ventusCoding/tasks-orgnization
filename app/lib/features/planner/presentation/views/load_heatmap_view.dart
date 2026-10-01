import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/planner/presentation/grid/engine/load_matrix.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/heat_calendar.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

/// Weeks of the load heatmap (`options.weeks`: 1, 2, 4, 8 or 12).
const loadHeatmapWeeks = [1, 2, 4, 8, 12];

/// Fill of a load level 0–5 (5 = over capacity).
Color loadFill(BuildContext context, int level) => level >= 5
    ? Color.alphaBlend(context.appColors.danger.withValues(alpha: 0.85), context.colors.surface)
    : heatFill(context, level);

/// Load heatmap (T3.6.16, punch-card style): a 7 × 24 grid (weekday × hour) of planned or tracked
/// minutes (`options.metric`) over the selected weeks (`options.weeks`), each cell colored by its
/// load against capacity (60 min per week), plus per-day tints against work-hours capacity
/// (Timepage). Tap a cell → the items behind it; tap a day → Day list.
class LoadHeatmapView extends ConsumerStatefulWidget {
  const LoadHeatmapView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<LoadHeatmapView> createState() => _LoadHeatmapViewState();
}

class _LoadHeatmapViewState extends ConsumerState<LoadHeatmapView> {
  late LocalDate _anchor;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    _anchor =
        widget.args.date ??
        ref.read(plannerAnchorProvider) ??
        ref.read(plannerViewStateProvider(_key))?.anchor ??
        ref.read<LocalDate>(plannerTodayProvider);
  }

  Weekday get _weekStart =>
      weekStartFor(ref.read(plannerViewConfigProvider(_key)), ref.read(userPreferencesProvider).weekStart);

  void _go(LocalDate date) {
    final start = date.startOfWeek(_weekStart);
    setState(() => _anchor = start);
    ref.read(plannerAnchorProvider.notifier).set(start);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: start));
  }

  Future<void> _pick() async {
    final picked = await showMiniMonth(context, initial: _anchor, weekStart: _weekStart, highlight: [_anchor]);
    if (picked != null) _go(picked);
  }

  Future<void> _showCell(Weekday w, int hour, List<PlannerItem> items) async {
    final f = context.plannerFormat(use24h: ref.read(userPreferencesProvider).use24h);
    final config = ref.read(plannerViewConfigProvider(_key));
    await showAppSheet<void>(
      context,
      title: '${f.weekdayLong(w)} · ${f.time(LocalTime(hour, 0))}–${f.time(LocalTime((hour + 1) % 24, 0))}',
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final colors = viewColors(ctx, ref, config);
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Space.md),
            children: [
              if (items.isEmpty) Text(ctx.l10n.pvNoTasks),
              for (final i in dayListOrder(items))
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: PlannerItemChip(viewKey: _key, item: i, colors: colors.of(i), showDate: true, dense: true),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final work = ref.watch(plannerWorkSettingsProvider);
    final weekStart = weekStartFor(config, prefs.weekStart);
    final today = ref.watch(plannerTodayProvider);
    final weeks = config.option<int>('weeks', 4).clamp(1, 12);
    final metric = LoadMetric.parse(config.option<String>('metric', 'planned'));
    final start = _anchor.startOfWeek(weekStart);
    final days = weeks * 7;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final f = context.plannerFormat(use24h: prefs.use24h);
    final items = filteredItems(ref, DayRange(start, days), config).value ?? const <PlannerItem>[];
    final matrix = loadMatrix(items, start: start, days: days, metric: metric);
    final notifier = ref.read(plannerViewConfigProvider(_key).notifier);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: rangeTitle(locale, start, start.plusDays(days - 1)),
        onPrevious: () => _go(start.plusDays(-days)),
        onNext: () => _go(start.plusDays(days)),
        onToday: () => _go(today),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: l.pvPrevious,
        nextLabel: l.pvNext,
        trailing: [
          PopupMenuButton<int>(
            key: const Key('load-weeks'),
            tooltip: l.pvWeeksCount(weeks),
            icon: const Icon(Icons.date_range),
            onSelected: (w) => notifier.change((c) => c.withOption('weeks', w)),
            itemBuilder: (_) => [
              for (final w in loadHeatmapWeeks)
                CheckedPopupMenuItem(value: w, checked: w == weeks, child: Text(l.pvWeeksCount(w))),
            ],
          ),
          PopupMenuButton<LoadMetric>(
            key: const Key('load-metric'),
            tooltip: l.pvHeatMetric,
            icon: const Icon(Icons.insights_outlined),
            onSelected: (m) => notifier.change((c) => c.withOption('metric', m.name)),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: LoadMetric.planned,
                checked: metric == LoadMetric.planned,
                child: Text(l.pvPlanColumn),
              ),
              CheckedPopupMenuItem(
                value: LoadMetric.tracked,
                checked: metric == LoadMetric.tracked,
                child: Text(l.pvActualColumn),
              ),
            ],
          ),
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.calendar),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => _go(start.plusDays(-days)),
        onNext: () => _go(start.plusDays(days)),
        onToday: () => _go(today),
        child: Column(
          children: [
            ActiveFilterBar(viewKey: _key),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() < 300) return;
                  _go(start.plusDays((rtl ? v > 0 : v < 0) ? days : -days));
                },
                child: ListView(
                  key: ValueKey('load-${start.toIso()}-$weeks-${metric.name}'),
                  padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, Space.sm, Space.sm, 96),
                  children: [
                    _PunchGrid(
                      matrix: matrix,
                      weekStart: weekStart,
                      format: f,
                      onTap: (w, h) => unawaited(_showCell(w, h, matrix.itemsByCell[(w.iso, h)] ?? const [])),
                    ),
                    const SizedBox(height: Space.sm),
                    const _LoadLegend(),
                    const SizedBox(height: Space.lg),
                    Text(l.pvCapacity, style: context.text.titleSmall),
                    const SizedBox(height: Space.xs),
                    _DayTints(
                      start: start,
                      weeks: weeks,
                      weekStart: weekStart,
                      matrix: matrix,
                      work: work,
                      today: today,
                      format: f,
                      onTap: (d) => ref.read(plannerNavProvider).openView(context, 'day_list', date: d),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 7 rows (weekdays in week-start order) × 24 hour cells.
class _PunchGrid extends StatelessWidget {
  const _PunchGrid({required this.matrix, required this.weekStart, required this.format, required this.onTap});

  final LoadMatrix matrix;
  final Weekday weekStart;
  final AppFormat format;
  final void Function(Weekday w, int hour) onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final narrow = DateFormat.E(locale);
    return LayoutBuilder(
      builder: (context, box) {
        const labelWidth = 34.0;
        final cell = math.max<double>(12, (box.maxWidth - labelWidth) / 24);
        final grid = Column(
          key: const Key('load-grid'),
          children: [
            Row(
              children: [
                const SizedBox(width: labelWidth),
                for (var h = 0; h < 24; h++)
                  SizedBox(
                    width: cell,
                    child: h % 3 == 0
                        ? Text(
                            '$h',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(fontSize: 9, color: c.onSurfaceVariant),
                          )
                        : null,
                  ),
              ],
            ),
            for (final w in Weekday.ordered(weekStart))
              Semantics(
                label:
                    '${format.weekdayLong(w)}, ${l.pvPlanned}: '
                    '${format.duration(matrix.cells[w.iso - 1].fold<double>(0, (a, v) => a + v).round())}',
                child: Row(
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Text(
                        narrow.format(DateTime.utc(2024, 1, w.iso)),
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(fontSize: 10, color: w.isWeekend ? c.outline : c.onSurfaceVariant),
                      ),
                    ),
                    for (var h = 0; h < 24; h++)
                      GestureDetector(
                        key: ValueKey('load-cell-${w.iso}-$h'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(w, h),
                        child: Padding(
                          padding: const EdgeInsets.all(1),
                          child: Container(
                            width: cell - 2,
                            height: cell - 2,
                            decoration: BoxDecoration(
                              color: loadFill(context, loadLevel(matrix.cellLoad(w, h))),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
        return labelWidth + cell * 24 > box.maxWidth
            ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: grid)
            : grid;
      },
    );
  }
}

class _LoadLegend extends StatelessWidget {
  const _LoadLegend();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final style = context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant);
    return Semantics(
      excludeSemantics: true,
      label: '${l.pvLess} – ${l.pvMoreLegend}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l.pvLess, style: style),
          const SizedBox(width: Space.xs),
          for (var i = 0; i <= 5; i++)
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(color: loadFill(context, i), borderRadius: BorderRadius.circular(3)),
            ),
          const SizedBox(width: Space.xs),
          Text(l.pvMoreLegend, style: style),
        ],
      ),
    );
  }
}

/// Days of the range as week rows tinted by planned ÷ work-hours capacity (Timepage style).
class _DayTints extends StatelessWidget {
  const _DayTints({
    required this.start,
    required this.weeks,
    required this.weekStart,
    required this.matrix,
    required this.work,
    required this.today,
    required this.format,
    required this.onTap,
  });

  final LocalDate start;
  final int weeks;
  final Weekday weekStart;
  final LoadMatrix matrix;
  final WorkSettings work;
  final LocalDate today;
  final AppFormat format;
  final ValueChanged<LocalDate> onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final capacity = math.max(1, work.minutesPerDay);
    return Column(
      children: [
        for (var w = 0; w < weeks; w++)
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final d = start.plusDays(w * 7 + i);
                      final minutes = matrix.days[d] ?? 0;
                      final level = loadLevel(minutes / capacity);
                      return AspectRatio(
                        aspectRatio: 1.6,
                        child: HeatCell(
                          key: ValueKey('load-day-${d.toIso()}'),
                          day: d,
                          level: level.clamp(0, 4),
                          fill: level >= 5 ? loadFill(context, level) : null,
                          isToday: d == today,
                          label: '${format.dayLong(d)}, ${l.pvPlanned}: ${format.duration(minutes.round())}',
                          onTap: () => onTap(d),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
