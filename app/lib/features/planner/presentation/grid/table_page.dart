import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/bucketing.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:everslot/features/planner/presentation/grid/grid_painter.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_ruler.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

// Bucketed *table* renderer and *week-list* mode (T3.3.12): rows are slots of the page axis,
// columns are days; cells list chips (full chip where an item starts, a continuation marker in
// later rows) with "+N" when they don't fit. At 1 440-minute slots each day is one ordered list.

/// Row geometry shared by the table ruler and every page.
@immutable
class TableRowsLayout {
  const TableRowsLayout._(this.rows, this.tops, this.heights, this.height);

  factory TableRowsLayout.build({
    required PageAxis axis,
    required int slotMinutes,
    required double rowExtent,
    required double chipExtent,
    required int maxChipsPerCell,
    List<int>? maxCountPerRow,
    bool autoFit = true,
  }) {
    final rows = axis.slotRows(slotMinutes);
    final counts = maxCountPerRow == null || maxCountPerRow.length != rows.length ? List.filled(rows.length, 0) : maxCountPerRow;
    final sizing = sizeRows(
      maxCountPerRow: counts,
      autoFit: autoFit,
      rowExtent: rowExtent,
      chipExtent: chipExtent,
      maxChipsPerCell: maxChipsPerCell,
    );
    final tops = <double>[];
    final heights = <double>[];
    var y = 0.0;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final h = row.kind == AxisBandKind.normal ? sizing.heights[i] : axis.bands[row.bandIndex].fixedExtent;
      tops.add(y);
      heights.add(h);
      y += h;
    }
    return TableRowsLayout._(List.unmodifiable(rows), List.unmodifiable(tops), List.unmodifiable(heights), y);
  }

  final List<AxisRow> rows;
  final List<double> tops;
  final List<double> heights;
  final double height;

  int get length => rows.length;

  double bottom(int i) => tops[i] + heights[i];

  /// Row at content y (clamped).
  int indexAt(double y) {
    if (rows.isEmpty) return 0;
    var lo = 0;
    var hi = rows.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (tops[mid] <= y) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// Row containing wall minute [wall] on pass [repeat] (first normal row at or after it).
  int rowOfWall(int wall, {int repeat = 0}) {
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      if (r.repeat == repeat && wall >= r.wallStart && wall < r.wallEnd) return i;
    }
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].wallStart >= wall) return i;
    }
    return math.max(0, rows.length - 1);
  }

  /// Content y of the top of the row holding [wall].
  double yOfWall(int wall, {int repeat = 0}) => rows.isEmpty ? 0 : tops[rowOfWall(wall, repeat: repeat)];

  @override
  bool operator ==(Object other) =>
      other is TableRowsLayout &&
      const ListEquality<AxisRow>().equals(other.rows, rows) &&
      const ListEquality<double>().equals(other.heights, heights);

  @override
  int get hashCode => Object.hash(Object.hashAll(rows), Object.hashAll(heights));
}

/// Elapsed-minute ranges of [rows] on the day of [timeline] (monotonic; rows missing that day are
/// empty so nothing lands in them).
List<(int, int)> rowRangesFor(DayTimeline timeline, List<AxisRow> rows) {
  final result = <(int, int)>[];
  var prev = 0;
  for (final r in rows) {
    final exists = r.repeat == 0 || timeline.hasWall(r.wallStart, repeat: 1);
    if (!exists) {
      result.add((prev, prev));
      continue;
    }
    final a = math.max(prev, timeline.tOfWall(r.wallStart, repeat: r.repeat));
    final b = math.max(a, r.wallEnd >= 1440 ? timeline.lengthMinutes : timeline.tOfWallEnd(r.wallEnd, repeat: r.repeat));
    result.add((a, b));
    prev = b;
  }
  return result;
}

/// Buckets of one day for [rows] (T3.3.06).
List<List<BucketEntry>> tableBuckets(DaySlice slice, List<AxisRow> rows) => bucketDay(
  [
    for (final (i, s) in slice.timed.indexed)
      BucketInput(i, s.tStart, s.tEnd, priority: s.item.priority, continuesFromPreviousDay: s.continuesBefore),
  ],
  rowRangesFor(slice.timeline, rows),
);

/// A hit in the table renderer.
@immutable
class TableHit {
  const TableHit({required this.dayIndex, required this.row, this.item, this.isStart = false, this.overflow});

  final int dayIndex;
  final int row;
  final PlannerItem? item;
  final bool isStart;

  /// Items hidden behind a "+N" chip.
  final List<PlannerItem>? overflow;
}

/// Positions of one table page (rendering and hit testing).
@immutable
class TablePageGeometry {
  const TablePageGeometry({
    required this.days,
    required this.width,
    required this.rtl,
    required this.rows,
    required this.slices,
    required this.buckets,
    required this.chipExtent,
  });

  static const cellPadding = 2.0;

  final List<LocalDate> days;
  final double width;
  final bool rtl;
  final TableRowsLayout rows;
  final List<DaySlice?> slices;

  /// Per day, per row.
  final List<List<List<BucketEntry>>> buckets;
  final double chipExtent;

  double get columnWidth => days.isEmpty ? width : width / days.length;

  Rect cellRect(int day, int row) =>
      Rect.fromLTWH(columnX(day, days.length, width, rtl: rtl), rows.tops[row], columnWidth, rows.heights[row]);

  /// Chips that fit in [cell] of [count] entries: all, or capacity − 1 plus a "+N" chip.
  int shownIn(Rect cell, int count) {
    final capacity = math.max(0, ((cell.height - cellPadding * 2) / chipExtent).floor());
    return count <= capacity ? count : math.max(0, capacity - 1);
  }

  Rect chipRect(Rect cell, int i) => Rect.fromLTWH(
    cell.left + cellPadding,
    cell.top + cellPadding + i * chipExtent,
    math.max(2, cell.width - cellPadding * 2),
    chipExtent - 2,
  );

  List<BucketEntry> entries(int day, int row) =>
      day < buckets.length && row < buckets[day].length ? buckets[day][row] : const [];

  PlannerItem itemOf(int day, BucketEntry e) => slices[day]!.timed[e.index].item;

  TableHit? hit(Offset p) {
    if (days.isEmpty || rows.length == 0 || p.dy < 0 || p.dy >= rows.height || p.dx < 0 || p.dx >= width) return null;
    final physical = (p.dx / columnWidth).floor().clamp(0, days.length - 1);
    final day = rtl ? days.length - 1 - physical : physical;
    final row = rows.indexAt(p.dy);
    final cell = cellRect(day, row);
    final list = entries(day, row);
    final shown = shownIn(cell, list.length);
    final i = ((p.dy - cell.top - cellPadding) / chipExtent).floor();
    if (i >= 0 && i < shown) return TableHit(dayIndex: day, row: row, item: itemOf(day, list[i]), isStart: list[i].isStart);
    if (i == shown && list.length > shown) {
      return TableHit(dayIndex: day, row: row, overflow: [for (final e in list.skip(shown)) itemOf(day, e)]);
    }
    return TableHit(dayIndex: day, row: row);
  }
}

/// Rebuilds its children only when the vertical window (one viewport) changes (culling).
class WindowedLayer extends StatefulWidget {
  const WindowedLayer({required this.vertical, required this.viewportHeight, required this.builder, super.key});

  final ScrollController vertical;
  final double viewportHeight;

  /// Children for content y in [top, bottom).
  final List<Widget> Function(double top, double bottom) builder;

  @override
  State<WindowedLayer> createState() => _WindowedLayerState();
}

class _WindowedLayerState extends State<WindowedLayer> {
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
  void didUpdateWidget(WindowedLayer old) {
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
    return Stack(clipBehavior: Clip.none, children: widget.builder((_window - 1) * vh, (_window + 2) * vh));
  }
}

/// Grid lines and shading of the table renderer.
class TableGridPainter extends CustomPainter {
  TableGridPainter({
    required this.rows,
    required this.days,
    required this.today,
    required this.rtl,
    required this.style,
    this.shadeWeekends = true,
    this.workDays = const {1, 2, 3, 4, 5},
    this.shadeOffDays = false,
  });

  final TableRowsLayout rows;
  final List<LocalDate> days;
  final LocalDate today;
  final bool rtl;
  final GridStyle style;
  final bool shadeWeekends;
  final Set<int> workDays;
  final bool shadeOffDays;

  @override
  void paint(Canvas canvas, Size size) {
    final n = days.length;
    if (n == 0) return;
    final colW = size.width / n;
    final fill = Paint();
    for (var i = 0; i < n; i++) {
      final x = columnX(i, n, size.width, rtl: rtl);
      final d = days[i];
      if (shadeWeekends && d.weekday.isWeekend) canvas.drawRect(Rect.fromLTWH(x, 0, colW, rows.height), fill..color = style.weekend);
      if (shadeOffDays && !workDays.contains(d.weekday.iso)) {
        canvas.drawRect(Rect.fromLTWH(x, 0, colW, rows.height), fill..color = style.offHours);
      }
      if (d == today) canvas.drawRect(Rect.fromLTWH(x, 0, colW, rows.height), fill..color = style.today);
    }
    final major = Paint()
      ..color = style.major
      ..strokeWidth = 1;
    final minor = Paint()
      ..color = style.minor
      ..strokeWidth = 1;
    for (var r = 0; r < rows.length; r++) {
      final row = rows.rows[r];
      final top = rows.tops[r];
      if (row.kind != AxisBandKind.normal) {
        canvas.drawRect(
          Rect.fromLTWH(0, top, size.width, rows.heights[r]),
          fill..color = row.kind == AxisBandKind.gap ? style.unavailable : style.hiddenBand.withValues(alpha: 0.7),
        );
      }
      final y = top.roundToDouble() + 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), row.wallStart % 60 == 0 || row.kind != AxisBandKind.normal ? major : minor);
    }
    for (var i = 1; i < n; i++) {
      final x = (i * colW).roundToDouble() + 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, rows.height), minor);
    }
  }

  @override
  bool shouldRepaint(TableGridPainter old) =>
      old.rows != rows ||
      !const ListEquality<LocalDate>().equals(old.days, days) ||
      old.today != today ||
      old.rtl != rtl ||
      old.style != style ||
      old.shadeWeekends != shadeWeekends ||
      old.shadeOffDays != shadeOffDays ||
      !setEquals(old.workDays, workDays);
}

/// Tints the current slot row of today's column (repaints once a minute through [now]).
class TableNowPainter extends CustomPainter {
  TableNowPainter({required this.now, required this.rows, required this.days, required this.timelines, required this.rtl, required this.color})
    : super(repaint: now);

  final ValueListenable<DateTime> now;
  final TableRowsLayout rows;
  final List<LocalDate> days;
  final List<DayTimeline> timelines;
  final bool rtl;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final n = days.length;
    for (var i = 0; i < timelines.length && i < n; i++) {
      final tl = timelines[i];
      final t = tl.tOfInstant(now.value);
      if (t < 0 || t >= tl.lengthMinutes) continue;
      final (wall, repeat) = tl.wallAt(t);
      final r = rows.rowOfWall(wall, repeat: repeat);
      final x = columnX(i, n, size.width, rtl: rtl);
      final rect = Rect.fromLTWH(x, rows.tops[r], size.width / n, rows.heights[r]);
      canvas
        ..drawRect(rect, Paint()..color = color.withValues(alpha: 0.10))
        ..drawRect(
          rect.deflate(0.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = color.withValues(alpha: 0.6),
        );
    }
  }

  @override
  bool shouldRepaint(TableNowPainter old) =>
      old.rows != rows || old.rtl != rtl || old.color != color || !const ListEquality<LocalDate>().equals(old.days, days);
}

/// A chip in a table cell or a week-list column.
class CellChip extends StatelessWidget {
  const CellChip({
    required this.item,
    required this.colors,
    required this.label,
    required this.semanticsLabel,
    this.continuation = false,
    this.past = false,
    this.dimPast = true,
    this.selected = false,
    this.fontSize = 11,
    super.key,
  });

  final PlannerItem item;
  final TileColors colors;
  final String label;
  final String semanticsLabel;
  final bool continuation;
  final bool past;
  final bool dimPast;
  final bool selected;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final done = item.status == OccurrenceStatus.done;
    final struck = done || item.status == OccurrenceStatus.cancelled;
    final faded = done || item.status == OccurrenceStatus.skipped || item.status == OccurrenceStatus.cancelled;
    final missed = item.status == OccurrenceStatus.missed;
    final check = item.trackingMode == TrackingMode.check && !continuation;
    return Semantics(
      button: true,
      label: semanticsLabel,
      checked: check ? done : null,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: continuation ? 0.55 : (faded ? 0.55 : (past && dimPast ? 0.75 : 1)),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.sm / 2),
              border: selected ? Border.all(color: context.colors.primary, width: 1.5) : null,
            ),
            child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(Radii.sm / 2),
              border: BorderDirectional(
                start: BorderSide(color: missed ? context.appColors.missed : colors.accent, width: missed ? 3 : 2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 3, end: 2),
              child: Row(
                children: [
                  if (continuation)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 2),
                      child: Icon(Icons.more_vert, size: fontSize, color: colors.foreground),
                    )
                  else if (check)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 2),
                      child: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: fontSize + 2, color: colors.foreground),
                    ),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.1,
                        fontWeight: continuation ? FontWeight.w400 : FontWeight.w600,
                        color: colors.foreground,
                        decoration: struck ? TextDecoration.lineThrough : null,
                        decorationColor: colors.foreground,
                      ),
                    ),
                  ),
                  if (item.isRecurring && !continuation) Icon(Icons.repeat, size: fontSize - 1, color: colors.foreground),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

/// The vertically scrolled body of one table page.
class TablePageBody extends StatelessWidget {
  const TablePageBody({
    required this.geometry,
    required this.vertical,
    required this.viewportHeight,
    required this.style,
    required this.today,
    required this.timelines,
    required this.nowUtc,
    required this.chipBuilder,
    required this.moreBuilder,
    this.shadeWeekends = true,
    this.workDays = const {1, 2, 3, 4, 5},
    this.hiddenCounts = const {},
    super.key,
  });

  final TablePageGeometry geometry;
  final ScrollController vertical;
  final double viewportHeight;
  final GridStyle style;
  final LocalDate today;
  final List<DayTimeline> timelines;
  final ValueListenable<DateTime> nowUtc;
  final Widget Function(PlannerItem item, bool isStart, int dayIndex) chipBuilder;
  final Widget Function(int count) moreBuilder;
  final bool shadeWeekends;
  final Set<int> workDays;

  /// Items inside hidden rows: (row, day) → count.
  final Map<(int, int), int> hiddenCounts;

  @override
  Widget build(BuildContext context) {
    final g = geometry;
    return ScrolledContent(
      vertical: vertical,
      contentHeight: g.rows.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: TableGridPainter(
                  rows: g.rows,
                  days: g.days,
                  today: today,
                  rtl: g.rtl,
                  style: style,
                  shadeWeekends: shadeWeekends,
                  workDays: workDays,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: TableNowPainter(now: nowUtc, rows: g.rows, days: g.days, timelines: timelines, rtl: g.rtl, color: style.nowLine),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: WindowedLayer(
                vertical: vertical,
                viewportHeight: viewportHeight,
                builder: (top, bottom) {
                  final children = <Widget>[];
                  if (g.rows.length == 0) return children;
                  final first = g.rows.indexAt(top);
                  for (var r = first; r < g.rows.length && g.rows.tops[r] <= bottom; r++) {
                    for (var d = 0; d < g.days.length; d++) {
                      final cell = g.cellRect(d, r);
                      if (g.rows.rows[r].kind != AxisBandKind.normal) {
                        final count = hiddenCounts[(r, d)] ?? 0;
                        if (count > 0) {
                          children.add(Positioned.fromRect(
                            key: ValueKey('hidden|$r|$d'),
                            rect: cell,
                            child: Center(child: _Badge(count: count, style: style)),
                          ));
                        }
                        continue;
                      }
                      final list = g.entries(d, r);
                      if (list.isEmpty) continue;
                      final shown = g.shownIn(cell, list.length);
                      for (var i = 0; i < shown; i++) {
                        final item = g.itemOf(d, list[i]);
                        children.add(Positioned.fromRect(
                          key: ValueKey('${item.key}|$r|$d'),
                          rect: g.chipRect(cell, i),
                          child: chipBuilder(item, list[i].isStart, d),
                        ));
                      }
                      if (list.length > shown) {
                        children.add(Positioned.fromRect(
                          key: ValueKey('more|$r|$d'),
                          rect: g.chipRect(cell, shown),
                          child: moreBuilder(list.length - shown),
                        ));
                      }
                    }
                  }
                  return children;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.style});

  final int count;
  final GridStyle style;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: style.primary, borderRadius: BorderRadius.circular(Radii.pill)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text('$count', style: TextStyle(color: style.onPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
    ),
  );
}

/// Ruler of the table renderer: a label at the top of each slot row (skipped when too close).
class TableRulerPainter extends CustomPainter {
  TableRulerPainter({
    required this.rows,
    required this.formatMinute,
    required this.textStyle,
    required this.textDirection,
    required this.cache,
    this.hiddenLabel,
    this.gapLabel,
    this.offsetLabel,
  });

  final TableRowsLayout rows;
  final String Function(int minute, int repeat) formatMinute;
  final String Function(int from, int to)? hiddenLabel;
  final String? gapLabel;
  final String Function(int minute)? offsetLabel;
  final TextStyle textStyle;
  final TextDirection textDirection;
  final LabelCache cache;

  @override
  void paint(Canvas canvas, Size size) {
    var lastBottom = double.negativeInfinity;
    final small = textStyle.copyWith(fontSize: (textStyle.fontSize ?? 11) - 2);
    for (var i = 0; i < rows.length; i++) {
      final row = rows.rows[i];
      final top = rows.tops[i];
      if (row.kind != AxisBandKind.normal) {
        final text = row.kind == AxisBandKind.gap ? gapLabel : hiddenLabel?.call(row.wallStart, row.wallEnd);
        if (text != null) {
          final tp = cache.get(text, small, textDirection);
          if (tp.height <= rows.heights[i] + 4) {
            tp.paint(canvas, Offset((size.width - tp.width) / 2, top + (rows.heights[i] - tp.height) / 2));
          }
        }
        lastBottom = top + rows.heights[i];
        continue;
      }
      final tp = cache.get(formatMinute(row.wallStart, row.repeat), textStyle, textDirection);
      final labelTop = top + 2;
      if (labelTop < lastBottom + 1) continue;
      tp.paint(canvas, Offset((size.width - tp.width) / 2, labelTop));
      var bottom = labelTop + tp.height;
      if (row.repeat == 1 && offsetLabel != null) {
        final sub = cache.get(offsetLabel!(row.wallStart), small, textDirection);
        sub.paint(canvas, Offset((size.width - sub.width) / 2, bottom));
        bottom += sub.height;
      }
      lastBottom = bottom;
    }
  }

  @override
  bool shouldRepaint(TableRulerPainter old) =>
      old.rows != rows || old.textStyle != textStyle || old.textDirection != textDirection || old.formatMinute != formatMinute;
}

/// Pinned ruler column of the table renderer.
class TableRuler extends StatelessWidget {
  const TableRuler({
    required this.vertical,
    required this.rows,
    required this.width,
    required this.formatMinute,
    required this.style,
    required this.cache,
    this.hiddenLabel,
    this.gapLabel,
    this.offsetLabel,
    this.onDoubleTap,
    this.semanticsLabel,
    super.key,
  });

  final ScrollController vertical;
  final TableRowsLayout rows;
  final double width;
  final String Function(int minute, int repeat) formatMinute;
  final String Function(int from, int to)? hiddenLabel;
  final String? gapLabel;
  final String Function(int minute)? offsetLabel;
  final GridStyle style;
  final LabelCache cache;
  final VoidCallback? onDoubleTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final textStyle = (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
      color: style.label,
      fontSize: 11,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      label: semanticsLabel,
      button: onDoubleTap != null,
      onTap: onDoubleTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: onDoubleTap,
        child: SizedBox(
          width: width,
          child: ScrolledContent(
            vertical: vertical,
            contentHeight: rows.height,
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(width, rows.height),
                painter: TableRulerPainter(
                  rows: rows,
                  formatMinute: formatMinute,
                  hiddenLabel: hiddenLabel,
                  gapLabel: gapLabel,
                  offsetLabel: offsetLabel,
                  textStyle: textStyle,
                  textDirection: Directionality.of(context),
                  cache: cache,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------ week list --

/// One chip of a week-list column.
@immutable
class WeekListEntry {
  const WeekListEntry(this.item, {this.continuation = false});

  final PlannerItem item;

  /// A multi-day timed item that started on an earlier day.
  final bool continuation;
}

/// Ordered entries of a day (T3.4.07): all-day items first (manual order, then title), then timed
/// items by start.
List<WeekListEntry> weekListEntries(DaySlice slice) {
  final seen = <String>{};
  final lane = [
    for (final i in slice.lane)
      if (seen.add(i.key)) i,
  ]..sort((a, b) {
      final ka = a.manualSortKey;
      final kb = b.manualSortKey;
      if (ka != null && kb != null && ka != kb) return ka.compareTo(kb);
      if (ka != null && kb == null) return -1;
      if (ka == null && kb != null) return 1;
      return a.title.compareTo(b.title);
    });
  return [
    for (final i in lane) WeekListEntry(i),
    for (final s in slice.timed)
      if (seen.add(s.item.key)) WeekListEntry(s.item, continuation: s.continuesBefore),
  ];
}

/// Positions of a week-list page.
@immutable
class WeekListGeometry {
  const WeekListGeometry({
    required this.days,
    required this.width,
    required this.rtl,
    required this.columns,
    required this.chipExtent,
  });

  static const gap = 3.0;
  static const topPadding = 6.0;

  /// Space kept below the last chip so an empty area stays tappable ("add to this day").
  static const tailExtent = 56.0;

  final List<LocalDate> days;
  final double width;
  final bool rtl;
  final List<List<WeekListEntry>> columns;
  final double chipExtent;

  double get columnWidth => days.isEmpty ? width : width / days.length;

  double get contentHeight =>
      topPadding + columns.fold<int>(0, (m, c) => math.max(m, c.length)) * (chipExtent + gap) + tailExtent;

  Rect chipRect(int day, int i) => Rect.fromLTWH(
    columnX(day, days.length, width, rtl: rtl) + 2,
    topPadding + i * (chipExtent + gap),
    math.max(2, columnWidth - 4),
    chipExtent,
  );

  /// (day index, entry index or null for empty space) at [p].
  (int, int?)? hit(Offset p) {
    if (days.isEmpty || p.dx < 0 || p.dx >= width || p.dy < 0) return null;
    final physical = (p.dx / columnWidth).floor().clamp(0, days.length - 1);
    final day = rtl ? days.length - 1 - physical : physical;
    final i = ((p.dy - topPadding) / (chipExtent + gap)).floor();
    if (i >= 0 && i < columns[day].length && chipRect(day, i).inflate(1).contains(p)) return (day, i);
    return (day, null);
  }

  /// Insertion index in [day] for content y (drag reorder).
  int insertionIndex(int day, double y) =>
      ((y - topPadding + (chipExtent + gap) / 2) / (chipExtent + gap)).floor().clamp(0, columns[day].length);
}

/// The vertically scrolled body of a week-list page.
class WeekListPageBody extends StatelessWidget {
  const WeekListPageBody({
    required this.geometry,
    required this.vertical,
    required this.viewportHeight,
    required this.style,
    required this.today,
    required this.chipBuilder,
    this.shadeWeekends = true,
    this.dropIndicator,
    super.key,
  });

  final WeekListGeometry geometry;
  final ScrollController vertical;
  final double viewportHeight;
  final GridStyle style;
  final LocalDate today;
  final Widget Function(WeekListEntry entry, int dayIndex) chipBuilder;
  final bool shadeWeekends;

  /// (day, insertion index) of an in-progress reorder.
  final (int, int)? dropIndicator;

  @override
  Widget build(BuildContext context) {
    final g = geometry;
    final height = math.max(viewportHeight, g.contentHeight);
    final drop = dropIndicator;
    return ScrolledContent(
      vertical: vertical,
      contentHeight: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _WeekListPainter(days: g.days, today: today, rtl: g.rtl, style: style, shadeWeekends: shadeWeekends),
              ),
            ),
          ),
          for (var d = 0; d < g.days.length; d++)
            for (var i = 0; i < g.columns[d].length; i++)
              Positioned.fromRect(
                key: ValueKey('${g.columns[d][i].item.key}|$d'),
                rect: g.chipRect(d, i),
                child: chipBuilder(g.columns[d][i], d),
              ),
          if (drop != null)
            Positioned.fromRect(
              rect: Rect.fromLTWH(
                columnX(drop.$1, g.days.length, g.width, rtl: g.rtl) + 2,
                WeekListGeometry.topPadding + drop.$2 * (g.chipExtent + WeekListGeometry.gap) - 2,
                g.columnWidth - 4,
                2,
              ),
              child: ColoredBox(color: style.primary),
            ),
        ],
      ),
    );
  }
}

class _WeekListPainter extends CustomPainter {
  _WeekListPainter({required this.days, required this.today, required this.rtl, required this.style, required this.shadeWeekends});

  final List<LocalDate> days;
  final LocalDate today;
  final bool rtl;
  final GridStyle style;
  final bool shadeWeekends;

  @override
  void paint(Canvas canvas, Size size) {
    final n = days.length;
    if (n == 0) return;
    final colW = size.width / n;
    final fill = Paint();
    for (var i = 0; i < n; i++) {
      final x = columnX(i, n, size.width, rtl: rtl);
      if (shadeWeekends && days[i].weekday.isWeekend) canvas.drawRect(Rect.fromLTWH(x, 0, colW, size.height), fill..color = style.weekend);
      if (days[i] == today) canvas.drawRect(Rect.fromLTWH(x, 0, colW, size.height), fill..color = style.today);
    }
    final line = Paint()
      ..color = style.minor
      ..strokeWidth = 1;
    for (var i = 1; i < n; i++) {
      final x = (i * colW).roundToDouble() + 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
  }

  @override
  bool shouldRepaint(_WeekListPainter old) =>
      !const ListEquality<LocalDate>().equals(old.days, days) ||
      old.today != today ||
      old.rtl != rtl ||
      old.style != style ||
      old.shadeWeekends != shadeWeekends;
}
