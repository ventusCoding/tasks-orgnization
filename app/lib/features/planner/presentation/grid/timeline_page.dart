import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot/features/planner/presentation/grid/engine/lane_packing.dart';
import 'package:everslot/features/planner/presentation/grid/engine/overlap_layout.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:everslot/features/planner/presentation/grid/engine/time_scale.dart';
import 'package:everslot/features/planner/presentation/grid/grid_painter.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/task_tile.dart';
import 'package:everslot/features/planner/presentation/grid/time_ruler.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Lays out one day column; the default is the overlap layout, views can swap it (swimlanes).
typedef TileLayoutStrategy = DayLayout Function(DaySlice slice, int laneCap, int minDuration);

DayLayout overlapStrategy(DaySlice slice, int laneCap, int minDuration) => layoutDay(
  [for (final (i, s) in slice.timed.indexed) LayoutInput(i, s.tStart, s.tEnd)],
  laneCap: laneCap,
  minDuration: minDuration,
);

/// Per-day layout memo keyed by slice identity (unchanged days are never re-laid out).
class ColumnLayoutCache {
  final Expando<(int, int, TileLayoutStrategy, DayLayout)> _memo = Expando();

  DayLayout of(DaySlice slice, {required int laneCap, required int minDuration, TileLayoutStrategy strategy = overlapStrategy}) {
    final hit = _memo[slice];
    if (hit != null && hit.$1 == laneCap && hit.$2 == minDuration && identical(hit.$3, strategy)) return hit.$4;
    final layout = strategy(slice, laneCap, minDuration);
    _memo[slice] = (laneCap, minDuration, strategy, layout);
    return layout;
  }
}

@immutable
class TileGeom {
  const TileGeom({required this.segment, required this.dayIndex, required this.rect, required this.variant});

  final DaySegment segment;
  final int dayIndex;

  /// Page coordinates (content y).
  final Rect rect;
  final TileVariant variant;

  PlannerItem get item => segment.item;
}

@immutable
class OverflowGeom {
  const OverflowGeom({required this.dayIndex, required this.rect, required this.items, required this.wallStart});

  final int dayIndex;
  final Rect rect;
  final List<PlannerItem> items;
  final int wallStart;
}

/// Positions of everything in one page (shared by rendering and the grid's hit testing).
@immutable
class PageGeometry {
  const PageGeometry({
    required this.days,
    required this.width,
    required this.tiles,
    required this.overflow,
    required this.hiddenCounts,
  });

  static const minTileHeight = 18.0;

  final List<LocalDate> days;
  final double width;
  final List<TileGeom> tiles;
  final List<OverflowGeom> overflow;
  final Map<(int, int), int> hiddenCounts;

  double get columnWidth => days.isEmpty ? width : width / days.length;

  static double yOfT(PageAxis axis, DayTimeline tl, int t, double ppm, {bool end = false}) {
    final (w, r) = end ? tl.wallAtEnd(t) : tl.wallAt(t);
    return axis.yOf(w, repeat: r, ppm: ppm, end: end);
  }

  factory PageGeometry.compute({
    required List<LocalDate> days,
    required Map<LocalDate, DaySlice> slices,
    required PageAxis axis,
    required double ppm,
    required double width,
    required bool rtl,
    required int laneCap,
    required ColumnLayoutCache layouts,
    TileLayoutStrategy strategy = overlapStrategy,
  }) {
    final n = days.length;
    final colW = n == 0 ? width : width / n;
    final minDur = math.max(1, (minTileHeight / ppm).ceil());
    final tiles = <TileGeom>[];
    final overflow = <OverflowGeom>[];
    final hidden = <(int, int), int>{};
    for (var i = 0; i < n; i++) {
      final slice = slices[days[i]];
      if (slice == null || slice.timed.isEmpty) continue;
      final layout = layouts.of(slice, laneCap: laneCap, minDuration: minDur, strategy: strategy);
      final colX = columnX(i, n, width, rtl: rtl);
      for (final t in layout.tiles) {
        final seg = slice.timed[t.index];
        final top = axis.yOf(seg.wallStart, repeat: seg.repeatStart, ppm: ppm);
        var bottom = seg.tEnd == seg.tStart ? top : axis.yOf(seg.wallEnd, repeat: seg.repeatEnd, ppm: ppm, end: true);
        if (bottom < top + minTileHeight) bottom = top + minTileHeight;
        final leftFrac = rtl ? (t.columns - t.column - t.span) / t.columns : t.column / t.columns;
        final rect = Rect.fromLTWH(colX + leftFrac * colW + 1, top + 0.5, math.max(2, t.span / t.columns * colW - 2), bottom - top - 1);
        tiles.add(TileGeom(segment: seg, dayIndex: i, rect: rect, variant: tileVariantFor(rect.width, rect.height)));
      }
      for (final g in layout.overflow) {
        final top = yOfT(axis, slice.timeline, g.start, ppm);
        final bottom = math.max(yOfT(axis, slice.timeline, g.end, ppm, end: true), top + 20);
        final w = math.min(28.0, math.max(16.0, colW * 0.4));
        final x = rtl ? colX + 1 : colX + colW - w - 1;
        overflow.add(OverflowGeom(
          dayIndex: i,
          rect: Rect.fromLTWH(x, top + 1, w, math.min(24, bottom - top - 2)),
          items: [for (final idx in g.indices) slice.timed[idx].item],
          wallStart: slice.timed[g.indices.first].wallStart,
        ));
      }
      for (var b = 0; b < axis.bands.length; b++) {
        final band = axis.bands[b];
        if (band.kind != AxisBandKind.hidden) continue;
        var count = 0;
        for (final s in slice.timed) {
          final inside = band.pieces.any((p) => s.wallStart < p.wallEnd && (s.wallEnd > p.wallStart || (s.tEnd == s.tStart && s.wallStart >= p.wallStart)));
          if (inside) count++;
        }
        if (count > 0) hidden[(b, i)] = count;
      }
    }
    return PageGeometry(days: days, width: width, tiles: tiles, overflow: overflow, hiddenCounts: hidden);
  }

  /// Topmost tile at [p] (page coordinates, content y) with vertical touch slop.
  TileGeom? tileAt(Offset p, {double slop = 4}) {
    for (var i = tiles.length - 1; i >= 0; i--) {
      final r = tiles[i].rect;
      final hit = Rect.fromLTRB(r.left, r.top - slop, r.right, math.max(r.bottom, r.top + 24) + slop);
      if (hit.contains(p)) return tiles[i];
    }
    return null;
  }

  OverflowGeom? overflowAt(Offset p) {
    for (final o in overflow) {
      if (o.rect.inflate(6).contains(p)) return o;
    }
    return null;
  }
}

/// Builds only the tiles inside the visible window ± one viewport (T3.3.11) and rebuilds when the
/// scroll position crosses a window boundary (not every frame).
class CulledTileLayer extends StatefulWidget {
  const CulledTileLayer({
    required this.geometry,
    required this.vertical,
    required this.viewportHeight,
    required this.tileBuilder,
    required this.overflowBuilder,
    super.key,
  });

  final PageGeometry geometry;
  final ScrollController vertical;
  final double viewportHeight;
  final Widget Function(TileGeom g) tileBuilder;
  final Widget Function(OverflowGeom g) overflowBuilder;

  @override
  State<CulledTileLayer> createState() => _CulledTileLayerState();
}

class _CulledTileLayerState extends State<CulledTileLayer> {
  int _window = 0;

  int _windowOf() {
    final vh = math.max(1.0, widget.viewportHeight);
    final offset = widget.vertical.hasClients ? widget.vertical.offset : 0.0;
    return (offset / vh).floor();
  }

  void _onScroll() {
    final w = _windowOf();
    if (w != _window) setState(() => _window = w);
  }

  @override
  void initState() {
    super.initState();
    _window = _windowOf();
    widget.vertical.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(CulledTileLayer old) {
    super.didUpdateWidget(old);
    if (!identical(old.vertical, widget.vertical)) {
      old.vertical.removeListener(_onScroll);
      widget.vertical.addListener(_onScroll);
    }
    _window = _windowOf();
  }

  @override
  void dispose() {
    widget.vertical.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vh = math.max(1.0, widget.viewportHeight);
    final top = (_window - 1) * vh;
    final bottom = (_window + 2) * vh;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final g in widget.geometry.tiles)
          if (g.rect.bottom >= top && g.rect.top <= bottom)
            Positioned.fromRect(
              key: ValueKey('${g.item.key}|${g.dayIndex}|${g.segment.tStart}'),
              rect: g.rect,
              child: widget.tileBuilder(g),
            ),
        for (final o in widget.geometry.overflow)
          if (o.rect.bottom >= top && o.rect.top <= bottom) Positioned.fromRect(rect: o.rect, child: widget.overflowBuilder(o)),
      ],
    );
  }
}

/// Background/foreground decoration of a page supplied by an overlay (T3.3.23).
typedef OverlayPainterBuilder = CustomPainter? Function(PageOverlayContext context);

@immutable
class PageOverlayContext {
  const PageOverlayContext({
    required this.days,
    required this.slices,
    required this.axis,
    required this.ppm,
    required this.rtl,
    required this.style,
  });

  final List<LocalDate> days;
  final Map<LocalDate, DaySlice> slices;
  final PageAxis axis;
  final double ppm;
  final bool rtl;
  final GridStyle style;
}

/// The vertically scrolled body of one page: painter layers + culled tiles + now line.
class TimelinePageBody extends StatelessWidget {
  const TimelinePageBody({
    required this.geometry,
    required this.axis,
    required this.scale,
    required this.timelines,
    required this.today,
    required this.rtl,
    required this.style,
    required this.vertical,
    required this.viewportHeight,
    required this.nowUtc,
    required this.tileBuilder,
    required this.overflowBuilder,
    this.shadeWeekends = true,
    this.workWindow,
    this.workDays = const {1, 2, 3, 4, 5},
    this.overlayPainters = const [],
    this.foreground = const [],
    super.key,
  });

  final PageGeometry geometry;
  final PageAxis axis;
  final TimeScale scale;
  final List<DayTimeline> timelines;
  final LocalDate today;
  final bool rtl;
  final GridStyle style;
  final ScrollController vertical;
  final double viewportHeight;
  final ValueListenable<DateTime> nowUtc;
  final Widget Function(TileGeom g) tileBuilder;
  final Widget Function(OverflowGeom g) overflowBuilder;
  final bool shadeWeekends;
  final DayWindow? workWindow;
  final Set<int> workDays;
  final List<CustomPainter> overlayPainters;

  /// Extra positioned widgets in content coordinates (overlay markers).
  final List<Widget> foreground;

  @override
  Widget build(BuildContext context) {
    final ppm = scale.pxPerMinute;
    return ScrolledContent(
      vertical: vertical,
      contentHeight: axis.height(ppm),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: GridPainter(
                  axis: axis,
                  scale: scale,
                  days: geometry.days,
                  timelines: timelines,
                  today: today,
                  rtl: rtl,
                  style: style,
                  shadeWeekends: shadeWeekends,
                  workWindow: workWindow,
                  workDays: workDays,
                  hiddenCounts: geometry.hiddenCounts,
                  badgeStyle: context.text.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          for (final p in overlayPainters) Positioned.fill(child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: p)))),
          Positioned.fill(
            child: RepaintBoundary(
              child: CulledTileLayer(
                geometry: geometry,
                vertical: vertical,
                viewportHeight: viewportHeight,
                tileBuilder: tileBuilder,
                overflowBuilder: overflowBuilder,
              ),
            ),
          ),
          ...foreground,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: NowLinePainter(
                    now: nowUtc,
                    axis: axis,
                    ppm: ppm,
                    days: geometry.days,
                    timelines: timelines,
                    rtl: rtl,
                    color: style.nowLine,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// All-day / multi-day lane model of one page (T3.3.18).
@immutable
class LaneModel {
  const LaneModel({required this.items, required this.packing});

  factory LaneModel.compute(List<LocalDate> days, Map<LocalDate, DaySlice> slices, {int? maxRows}) {
    final items = <PlannerItem>[];
    final seen = <String>{};
    for (final d in days) {
      for (final i in slices[d]?.lane ?? const <PlannerItem>[]) {
        if (seen.add(i.key)) items.add(i);
      }
    }
    final inputs = <LaneInput>[];
    for (final (idx, item) in items.indexed) {
      final start = item.startLocal.date;
      final end = laneEndDate(item);
      var s = -1;
      var e = -1;
      for (var c = 0; c < days.length; c++) {
        if (!days[c].isBefore(start) && !days[c].isAfter(end)) {
          if (s == -1) s = c;
          e = c + 1;
        }
      }
      if (s == -1) continue;
      inputs.add(LaneInput(idx, s, e, continuesBefore: start.isBefore(days[s]), continuesAfter: end.isAfter(days[e - 1])));
    }
    return LaneModel(items: items, packing: packLane(inputs, days.length, maxRows: maxRows));
  }

  final List<PlannerItem> items;
  final LanePacking packing;

  /// Item of the bar at column [col] and row [row].
  PlannerItem? itemAt(int col, int row) {
    for (final b in packing.bars) {
      if (b.row == row && col >= b.startCol && col < b.endCol) return items[b.index];
    }
    return null;
  }
}

/// The lane under the day headers (bars span columns; continuation arrows across page edges).
class AllDayLane extends StatelessWidget {
  const AllDayLane({
    required this.model,
    required this.width,
    required this.height,
    required this.rowExtent,
    required this.rtl,
    required this.colorsOf,
    required this.semanticsOf,
    required this.moreLabel,
    this.onTapItem,
    this.draggingKey,
    super.key,
  });

  final LaneModel model;
  final double width;
  final double height;
  final double rowExtent;
  final bool rtl;
  final TileColors Function(PlannerItem) colorsOf;
  final String Function(PlannerItem) semanticsOf;
  final String Function(int count) moreLabel;
  final void Function(PlannerItem)? onTapItem;
  final String? draggingKey;

  @override
  Widget build(BuildContext context) {
    final n = model.packing.hiddenPerColumn.length;
    final colW = n == 0 ? width : width / n;
    return SizedBox(
      height: height,
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.colors.outlineVariant))),
        child: Stack(
          children: [
            // Columns run from the reading start: PositionedDirectional mirrors them in RTL.
            for (final bar in model.packing.bars)
              PositionedDirectional(
                start: bar.startCol * colW + 1,
                top: bar.row * rowExtent + 2,
                width: bar.span * colW - 2,
                height: rowExtent - 3,
                child: _LaneBar(
                  item: model.items[bar.index],
                  colors: colorsOf(model.items[bar.index]),
                  continuesBefore: bar.continuesBefore,
                  continuesAfter: bar.continuesAfter,
                  semanticsLabel: semanticsOf(model.items[bar.index]),
                  faded: model.items[bar.index].key == draggingKey,
                  onTap: onTapItem == null ? null : () => onTapItem!(model.items[bar.index]),
                ),
              ),
            for (var c = 0; c < n; c++)
              if (model.packing.hiddenPerColumn[c] > 0)
                PositionedDirectional(
                  start: c * colW,
                  width: colW,
                  bottom: 0,
                  height: 14,
                  child: Center(
                    child: Text(
                      moreLabel(model.packing.hiddenPerColumn[c]),
                      style: context.text.labelSmall?.copyWith(fontSize: 10, color: context.colors.primary),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _LaneBar extends StatelessWidget {
  const _LaneBar({
    required this.item,
    required this.colors,
    required this.continuesBefore,
    required this.continuesAfter,
    required this.semanticsLabel,
    this.faded = false,
    this.onTap,
  });

  final PlannerItem item;
  final TileColors colors;
  final bool continuesBefore;
  final bool continuesAfter;
  final String semanticsLabel;
  final bool faded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = item.status == OccurrenceStatus.done;
    return Semantics(
      button: true,
      label: semanticsLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: faded ? 0.35 : (done ? 0.6 : 1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadiusDirectional.horizontal(
                start: Radius.circular(continuesBefore ? 0 : Radii.sm),
                end: Radius.circular(continuesAfter ? 0 : Radii.sm),
              ),
              border: BorderDirectional(start: BorderSide(color: colors.accent, width: continuesBefore ? 0 : 3)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  if (continuesBefore) Icon(Icons.chevron_left, size: 12, color: colors.foreground, textDirection: Directionality.of(context)),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (continuesAfter) Icon(Icons.chevron_right, size: 12, color: colors.foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
