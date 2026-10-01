import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/gantt_layout.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/month_view.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

const double _laneHeight = 28;
const double _axisHeight = 36;
const double _labelWidth = 112;

/// Timeline / Gantt view (T3.6.14, TickTick / Notion / ClickUp style): a horizontal time axis whose
/// scale (`options.scale`: hours → days → weeks → months) changes with a horizontal pinch or the
/// menu; rows grouped by task/series, category or priority (`options.groupBy`); bars sized by
/// duration — drag a bar to move it, drag its end edge to resize (snapped to the scale); a today line.
class TimelineView extends ConsumerStatefulWidget {
  const TimelineView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  late LocalDate _anchor;
  final _horizontal = ScrollController();
  final _labels = ScrollController();
  final _rows = ScrollController();
  bool _syncing = false;
  bool _scrolledToNow = false;

  // Horizontal pinch: one scale step per 40 % span change (spread = finer).
  final Map<int, Offset> _pointers = {};
  double? _pinchStart;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    _anchor =
        widget.args.date ??
        ref.read(plannerAnchorProvider) ??
        ref.read(plannerViewStateProvider(_key))?.anchor ??
        ref.read<LocalDate>(plannerTodayProvider);
    _labels.addListener(() => _sync(_labels, _rows));
    _rows.addListener(() => _sync(_rows, _labels));
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _labels.dispose();
    _rows.dispose();
    super.dispose();
  }

  void _sync(ScrollController from, ScrollController to) {
    if (_syncing || !to.hasClients || !from.hasClients) return;
    _syncing = true;
    to.jumpTo(from.offset.clamp(0, to.position.maxScrollExtent));
    _syncing = false;
  }

  Weekday get _weekStart =>
      weekStartFor(ref.read(plannerViewConfigProvider(_key)), ref.read(userPreferencesProvider).weekStart);

  GanttScale get _scale => GanttScale.parse(ref.read(plannerViewConfigProvider(_key)).option<String>('scale', 'days'));

  void _go(LocalDate date) {
    setState(() {
      _anchor = date;
      _scrolledToNow = false;
    });
    ref.read(plannerAnchorProvider.notifier).set(date);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: date));
  }

  void _page(int dir) {
    final start = _scale.pageStart(_anchor, _weekStart);
    _go(_scale == GanttScale.months ? addMonths(start, 12 * dir) : start.plusDays(_scale.pageDays * dir));
  }

  void _setScale(GanttScale scale) {
    ref.read(plannerViewConfigProvider(_key).notifier).change((c) => c.withOption('scale', scale.name));
    setState(() => _scrolledToNow = false);
  }

  Future<void> _pick() async {
    final picked = await showMiniMonth(context, initial: _anchor, weekStart: _weekStart, highlight: [_anchor]);
    if (picked != null) _go(picked);
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) setState(() => _pinchStart = _span());
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    final start = _pinchStart;
    if (_pointers.length != 2 || start == null || start <= 0) return;
    final ratio = _span() / start;
    if (ratio > 1.4 || ratio < 1 / 1.4) {
      final next = _scale.step(ratio > 1 ? 1 : -1);
      if (next != _scale) _setScale(next);
      _pinchStart = _span();
    }
  }

  void _onPointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2 && _pinchStart != null) setState(() => _pinchStart = null);
  }

  double _span() {
    final p = _pointers.values.toList();
    return p.length < 2 ? 0 : (p[0].dx - p[1].dx).abs();
  }

  /// Scrolls so the anchor (or now, on today's page) sits near the leading edge once laid out.
  void _scrollToAnchor(LocalDate start, GanttScale scale, LocalDateTime now) {
    if (_scrolledToNow) return;
    _scrolledToNow = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_horizontal.hasClients) return;
      final target = _anchor == now.date ? now : _anchor.atStartOfDay;
      final x = start.atStartOfDay.minutesUntil(target) * scale.pxPerMinute - 48;
      _horizontal.jumpTo(x.clamp(0, _horizontal.position.maxScrollExtent));
    });
  }

  String _rowLabel(BuildContext context, GanttGroupBy groupBy, GanttRow row, Map<String, String> categoryNames) =>
      switch (groupBy) {
        GanttGroupBy.task => row.title ?? '',
        GanttGroupBy.category =>
          row.key.isEmpty ? context.l10n.pvGroupNone : (categoryNames[row.key] ?? context.l10n.pvGroupNone),
        GanttGroupBy.priority => PriorityStyle.label(context, int.parse(row.key)),
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final weekStart = weekStartFor(config, prefs.weekStart);
    final today = ref.watch(plannerTodayProvider);
    final now = ref.watch(plannerNowProvider);
    final scale = GanttScale.parse(config.option<String>('scale', 'days'));
    final groupBy = GanttGroupBy.parse(config.option<String>('groupBy', 'task'));
    final start = scale.pageStart(_anchor, weekStart);
    final range = DayRange(start, scale.pageDays);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final categories = ref.watch(allCategoriesProvider).value ?? const [];
    final categoryNames = {for (final c in categories) c.id: c.name};
    final items = filteredItems(ref, range, config).value ?? const <PlannerItem>[];
    final rows = ganttRows(
      items.where((i) => !i.allDay || scale != GanttScale.hours),
      start: start,
      scale: scale,
      groupBy: groupBy,
      categoryOrder: [for (final c in categories) c.id],
    );
    final width = ganttPageWidth(start, scale);
    final ticks = ganttTicks(start, scale, weekStart);
    final nowX = start.atStartOfDay.minutesUntil(now) * scale.pxPerMinute;
    final colors = viewColors(context, ref, config);
    final notifier = ref.read(plannerViewConfigProvider(_key).notifier);
    _scrollToAnchor(start, scale, now);
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: rangeTitle(locale, start, start.plusDays(scale.pageDays - 1)),
        onPrevious: () => _page(-1),
        onNext: () => _page(1),
        onToday: () => _go(today),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: l.pvPrevious,
        nextLabel: l.pvNext,
        trailing: [
          PopupMenuButton<GanttScale>(
            key: const Key('timeline-scale'),
            tooltip: l.pvScale,
            icon: const Icon(Icons.straighten),
            onSelected: _setScale,
            itemBuilder: (_) => [
              for (final (s, label) in [
                (GanttScale.hours, l.pvScaleHours),
                (GanttScale.days, l.pvScaleDays),
                (GanttScale.weeks, l.pvScaleWeeks),
                (GanttScale.months, l.pvScaleMonths),
              ])
                CheckedPopupMenuItem(value: s, checked: s == scale, child: Text(label)),
            ],
          ),
          PopupMenuButton<GanttGroupBy>(
            key: const Key('timeline-group'),
            tooltip: l.pvGroupBy,
            icon: const Icon(Icons.segment),
            onSelected: (g) => notifier.change((c) => c.withOption('groupBy', g.name)),
            itemBuilder: (_) => [
              for (final (g, label) in [
                (GanttGroupBy.task, l.pvGroupTask),
                (GanttGroupBy.category, l.pvGroupCategory),
                (GanttGroupBy.priority, l.pvGroupPriority),
              ])
                CheckedPopupMenuItem(value: g, checked: g == groupBy, child: Text(label)),
            ],
          ),
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.calendar),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => _page(-1),
        onNext: () => _page(1),
        onToday: () => _go(today),
        child: Column(
          children: [
            ActiveFilterBar(viewKey: _key),
            Expanded(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerUp,
                child: rows.isEmpty
                    ? EmptyState(icon: Icons.view_timeline_outlined, title: l.pvNoTasks)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: _labelWidth,
                            child: Column(
                              children: [
                                const SizedBox(height: _axisHeight),
                                Expanded(
                                  child: ListView(
                                    controller: _labels,
                                    padding: const EdgeInsets.only(bottom: 88),
                                    children: [
                                      for (final r in rows)
                                        _RowLabel(
                                          height: r.lanes * _laneHeight + 8,
                                          text: _rowLabel(context, groupBy, r, categoryNames),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: SingleChildScrollView(
                              key: ValueKey('timeline-${start.toIso()}-${scale.name}'),
                              controller: _horizontal,
                              scrollDirection: Axis.horizontal,
                              physics: _pinchStart != null ? const NeverScrollableScrollPhysics() : null,
                              child: SizedBox(
                                width: width,
                                child: Column(
                                  children: [
                                    _Axis(ticks: ticks, scale: scale, width: width, nowX: nowX, locale: locale),
                                    Expanded(
                                      child: ListView(
                                        controller: _rows,
                                        padding: const EdgeInsets.only(bottom: 88),
                                        children: [
                                          for (final r in rows)
                                            _GanttRowView(
                                              viewKey: _key,
                                              row: r,
                                              scale: scale,
                                              ticks: ticks,
                                              nowX: nowX,
                                              colors: colors,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      fab: PlannerFab(start: () => suggestedStart(today, ref.read(plannerNowProvider))),
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel({required this.height, required this.text});

  final double height;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    alignment: AlignmentDirectional.centerStart,
    padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.sm),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.colors.outlineVariant.withValues(alpha: 0.6), width: 0.5)),
    ),
    child: Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
      style: context.text.labelMedium,
    ),
  );
}

/// The time axis: one label per tick (hour, day, week or month) and the today marker.
class _Axis extends StatelessWidget {
  const _Axis({
    required this.ticks,
    required this.scale,
    required this.width,
    required this.nowX,
    required this.locale,
  });

  final List<(double, LocalDateTime)> ticks;
  final GanttScale scale;
  final double width;
  final double nowX;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final format = switch (scale) {
      GanttScale.hours => DateFormat.j(locale),
      GanttScale.days => DateFormat('E d', locale),
      GanttScale.weeks => DateFormat.MMMd(locale),
      GanttScale.months => DateFormat.MMM(locale),
    };
    return SizedBox(
      height: _axisHeight,
      width: width,
      child: Stack(
        children: [
          for (final (i, (x, t)) in ticks.indexed)
            PositionedDirectional(
              start: x,
              top: 0,
              bottom: 0,
              width: i + 1 < ticks.length ? ticks[i + 1].$1 - x : width - x,
              child: Container(
                padding: const EdgeInsetsDirectional.only(start: Space.xxs),
                alignment: AlignmentDirectional.centerStart,
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(color: c.outlineVariant),
                    bottom: BorderSide(color: c.outlineVariant),
                  ),
                ),
                child: Text(
                  scale == GanttScale.hours && t.time.hour == 0
                      ? DateFormat('E d', locale).format(t.date.toDateTimeUtc())
                      : format.format(t.toDateTimeUtc()),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  textScaler: TextScaler.noScaling,
                  style: context.text.labelSmall?.copyWith(color: c.onSurfaceVariant),
                ),
              ),
            ),
          if (nowX >= 0 && nowX <= width)
            PositionedDirectional(
              key: const Key('timeline-today'),
              start: nowX - 1,
              top: 0,
              bottom: 0,
              width: 2,
              child: ColoredBox(color: context.appColors.nowLine),
            ),
        ],
      ),
    );
  }
}

class _GanttRowView extends StatelessWidget {
  const _GanttRowView({
    required this.viewKey,
    required this.row,
    required this.scale,
    required this.ticks,
    required this.nowX,
    required this.colors,
  });

  final String viewKey;
  final GanttRow row;
  final GanttScale scale;
  final List<(double, LocalDateTime)> ticks;
  final double nowX;
  final ItemColorResolver colors;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: row.lanes * _laneHeight + 8,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.outlineVariant.withValues(alpha: 0.6), width: 0.5)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (x, _) in ticks)
            PositionedDirectional(
              start: x,
              top: 0,
              bottom: 0,
              width: 0.5,
              child: ColoredBox(color: c.outlineVariant.withValues(alpha: 0.4)),
            ),
          if (nowX >= 0)
            PositionedDirectional(
              start: nowX - 1,
              top: 0,
              bottom: 0,
              width: 2,
              child: ColoredBox(color: context.appColors.nowLine.withValues(alpha: 0.7)),
            ),
          for (final b in row.bars) _Bar(viewKey: viewKey, bar: b, scale: scale, colors: colors.of(b.item)),
        ],
      ),
    );
  }
}

/// A draggable bar: drag the body to move, the end edge to resize; tap opens, long-press = menu.
class _Bar extends ConsumerStatefulWidget {
  const _Bar({required this.viewKey, required this.bar, required this.scale, required this.colors});

  final String viewKey;
  final GanttBar bar;
  final GanttScale scale;
  final TileColors colors;

  @override
  ConsumerState<_Bar> createState() => _BarState();
}

class _BarState extends ConsumerState<_Bar> {
  double _move = 0;
  double _resize = 0;

  double _dir(BuildContext context) => Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  Future<void> _commitMove() async {
    final dx = _move;
    setState(() => _move = 0);
    final item = widget.bar.item;
    final start = ganttMovedStart(item, dx, widget.scale);
    if (start == item.startLocal) return;
    final l = context.l10n;
    final f = context.plannerFormat(use24h: ref.read(userPreferencesProvider).use24h);
    await PlannerCommands(
      context,
      ref,
    ).reschedule(item, start: start, message: l.pvMovedSnack('${f.dayShort(start.date)} ${f.timeOf(start)}'));
  }

  Future<void> _commitResize() async {
    final dx = _resize;
    setState(() => _resize = 0);
    final item = widget.bar.item;
    final minutes = ganttResizedDuration(item, dx, widget.scale);
    if (minutes == item.durationMinutes) return;
    final f = context.plannerFormat(use24h: ref.read(userPreferencesProvider).use24h);
    await PlannerCommands(context, ref).reschedule(
      item,
      start: item.startLocal,
      duration: minutes,
      message: context.l10n.pvResizedSnack(f.duration(minutes)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bar;
    final item = b.item;
    final colors = widget.colors;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final commands = PlannerCommands(context, ref);
    final width = (b.width + _resize).clamp(ganttMinBarWidth, double.infinity);
    final faded = item.isDone || item.status == OccurrenceStatus.skipped || item.status == OccurrenceStatus.cancelled;
    return PositionedDirectional(
      start: b.x + _move,
      top: 4 + b.lane * _laneHeight,
      width: width,
      height: _laneHeight - 4,
      child: Semantics(
        button: true,
        label:
            '${item.title}, ${f.dayShort(item.startLocal.date)} ${f.timeRange(item.startLocal, item.endLocal)}, '
            '${context.statusLabel(item.status)}',
        onTap: () => ref.read(plannerNavProvider).openTask(context, item),
        onLongPress: () => unawaited(commands.showTileMenu(item)),
        child: ExcludeSemantics(
          child: Opacity(
            opacity: faded ? 0.55 : 1,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    key: ValueKey('timeline-bar-${item.key}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref.read(plannerNavProvider).openTask(context, item),
                    onLongPress: () => unawaited(commands.showTileMenu(item)),
                    onHorizontalDragUpdate: (d) => setState(() => _move += d.delta.dx * _dir(context)),
                    onHorizontalDragEnd: (_) => unawaited(_commitMove()),
                    onHorizontalDragCancel: () => setState(() => _move = 0),
                    child: Container(
                      padding: const EdgeInsetsDirectional.only(start: Space.xxs),
                      alignment: AlignmentDirectional.centerStart,
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(Radii.sm),
                        border: BorderDirectional(start: BorderSide(color: colors.accent, width: 3)),
                      ),
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.foreground,
                          decoration: item.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ),
                ),
                if (width >= 24)
                  GestureDetector(
                    key: ValueKey('timeline-resize-${item.key}'),
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (d) => setState(() => _resize += d.delta.dx * _dir(context)),
                    onHorizontalDragEnd: (_) => unawaited(_commitResize()),
                    onHorizontalDragCancel: () => setState(() => _resize = 0),
                    child: SizedBox(
                      width: 10,
                      child: Center(child: Container(width: 2, height: 12, color: colors.accent)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
