import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:everslot/features/planner/presentation/grid/engine/time_scale.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_ruler.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// x of column [i] of [n] columns in a page of [width] (mirrored in RTL).
double columnX(int i, int n, double width, {required bool rtl}) {
  final w = width / n;
  return rtl ? width - (i + 1) * w : i * w;
}

/// Hidden-band badge labels, shared by every page painter.
final _badgeLabels = LabelCache(capacity: 64);

/// One painter per page (T3.3.07): slot lines by hierarchy, weekend / off-hours / today shading,
/// hidden-hour bands with badges and DST markers. It paints the full content height; the page
/// translates it, so scrolling never repaints (only scale, days or data changes do).
class GridPainter extends CustomPainter {
  GridPainter({
    required this.axis,
    required this.scale,
    required this.days,
    required this.timelines,
    required this.today,
    required this.rtl,
    required this.style,
    this.shadeWeekends = true,
    this.workWindow,
    this.workDays = const {1, 2, 3, 4, 5},
    this.hiddenCounts = const {},
    this.badgeStyle,
  });

  final PageAxis axis;
  final TimeScale scale;
  final List<LocalDate> days;
  final List<DayTimeline> timelines;
  final LocalDate today;
  final bool rtl;
  final GridStyle style;
  final bool shadeWeekends;

  /// Work hours (off-hours shading) — null = no shading.
  final DayWindow? workWindow;
  final Set<int> workDays;

  /// Items inside hidden bands: (band index, day index) → count.
  final Map<(int, int), int> hiddenCounts;
  final TextStyle? badgeStyle;

  double get ppm => scale.pxPerMinute;

  @override
  void paint(Canvas canvas, Size size) {
    final n = days.length;
    if (n == 0) return;
    final colW = size.width / n;
    final height = axis.height(ppm);
    final fill = Paint();

    for (var i = 0; i < n; i++) {
      final x = columnX(i, n, size.width, rtl: rtl);
      final day = days[i];
      if (shadeWeekends && day.weekday.isWeekend) {
        canvas.drawRect(Rect.fromLTWH(x, 0, colW, height), fill..color = style.weekend);
      }
      if (day == today) {
        canvas.drawRect(Rect.fromLTWH(x, 0, colW, height), fill..color = style.today);
      }
      final work = workWindow;
      if (work != null && !work.isFull) {
        fill.color = style.offHours;
        if (!workDays.contains(day.weekday.iso)) {
          canvas.drawRect(Rect.fromLTWH(x, 0, colW, height), fill);
        } else {
          final top = axis.yOf(work.startMinute, ppm: ppm);
          final bottom = axis.yOf(work.endMinute, ppm: ppm, end: true);
          if (top > 0) canvas.drawRect(Rect.fromLTWH(x, 0, colW, top), fill);
          if (bottom < height) canvas.drawRect(Rect.fromLTRB(x, bottom, x + colW, height), fill);
        }
      }
      if (i < timelines.length) {
        for (final (a, b) in axis.unavailableRanges(timelines[i], ppm)) {
          _hatch(canvas, Rect.fromLTRB(x, a, x + colW, b));
        }
      }
    }

    // Horizontal lines per band.
    final major = Paint()
      ..color = style.major
      ..strokeWidth = 1;
    final minor = Paint()
      ..color = style.minor
      ..strokeWidth = 1;
    final faint = Paint()
      ..color = style.faint
      ..strokeWidth = 0.5;
    for (var b = 0; b < axis.bands.length; b++) {
      final band = axis.bands[b];
      final top = band.top(ppm);
      if (band.kind != AxisBandKind.normal) {
        final rect = Rect.fromLTWH(0, top, size.width, band.fixedExtent);
        canvas.drawRect(rect, fill..color = band.kind == AxisBandKind.gap ? style.unavailable : style.hiddenBand.withValues(alpha: 0.7));
        canvas
          ..drawLine(Offset(0, rect.top), Offset(size.width, rect.top), major)
          ..drawLine(Offset(0, rect.bottom), Offset(size.width, rect.bottom), major);
        if (band.kind == AxisBandKind.hidden) _badges(canvas, b, rect, colW, n, size.width);
        continue;
      }
      for (final piece in band.pieces) {
        if (piece.repeat == 1) {
          final y = axis.yOf(piece.wallStart, repeat: 1, ppm: ppm);
          _dashed(canvas, y, size.width, major);
        }
        for (final (m, level) in scale.lines(piece.wallStart, piece.wallEnd)) {
          final y = axis.yOf(m, repeat: piece.repeat, ppm: ppm).roundToDouble() + 0.5;
          final paint = switch (level) {
            GridLineLevel.hour => major,
            GridLineLevel.slot => minor,
            GridLineLevel.quarter || GridLineLevel.minute => faint,
          };
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      }
    }

    // Column separators.
    for (var i = 1; i < n; i++) {
      final x = (i * colW).roundToDouble() + 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, height), minor);
    }
  }

  void _badges(Canvas canvas, int band, Rect rect, double colW, int n, double width) {
    final textStyle = badgeStyle;
    if (textStyle == null) return;
    for (var i = 0; i < n; i++) {
      final count = hiddenCounts[(band, i)] ?? 0;
      if (count == 0) continue;
      final x = columnX(i, n, width, rtl: rtl) + colW / 2;
      // Cached layout (T3.3.25: no text layout inside paint once warmed up).
      final tp = _badgeLabels.get('$count', textStyle.copyWith(color: style.onPrimary), TextDirection.ltr);
      final r = math.max(tp.width, tp.height) / 2 + 3;
      final center = Offset(x, rect.center.dy);
      canvas.drawCircle(center, math.min(r, rect.height / 2 + 2), Paint()..color = style.primary);
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _hatch(Canvas canvas, Rect rect) {
    if (rect.height <= 0) return;
    canvas
      ..save()
      ..clipRect(rect);
    final p = Paint()
      ..color = style.unavailable
      ..strokeWidth = 1;
    canvas.drawRect(rect, Paint()..color = style.unavailable.withValues(alpha: style.unavailable.a * 0.6));
    for (var d = -rect.height; d < rect.width; d += 8) {
      canvas.drawLine(Offset(rect.left + d, rect.bottom), Offset(rect.left + d + rect.height, rect.top), p);
    }
    canvas.restore();
  }

  void _dashed(Canvas canvas, double y, double width, Paint paint) {
    for (var x = 0.0; x < width; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, width), y), paint);
    }
  }

  static const _listEq = ListEquality<Object?>();
  static const _mapEq = MapEquality<(int, int), int>();

  @override
  bool shouldRepaint(GridPainter old) =>
      old.axis != axis ||
      old.scale != scale ||
      !_listEq.equals(old.days, days) ||
      !_listEq.equals(old.timelines, timelines) ||
      old.today != today ||
      old.rtl != rtl ||
      old.style != style ||
      old.shadeWeekends != shadeWeekends ||
      old.workWindow != workWindow ||
      !setEquals(old.workDays, workDays) ||
      !_mapEq.equals(old.hiddenCounts, hiddenCounts);
}

/// The now line (T3.3.07): red with a dot on today, faint across other days. Repaints once a minute
/// through [now] — never on scroll.
class NowLinePainter extends CustomPainter {
  NowLinePainter({
    required this.now,
    required this.axis,
    required this.ppm,
    required this.days,
    required this.timelines,
    required this.rtl,
    required this.color,
  }) : super(repaint: now);

  final ValueListenable<DateTime> now;
  final PageAxis axis;
  final double ppm;
  final List<LocalDate> days;
  final List<DayTimeline> timelines;
  final bool rtl;
  final Color color;

  /// y of the current instant, or null when today is not on this page.
  static (int, double)? locate(DateTime nowUtc, PageAxis axis, double ppm, List<DayTimeline> timelines) {
    for (var i = 0; i < timelines.length; i++) {
      final tl = timelines[i];
      final t = tl.tOfInstant(nowUtc);
      if (t >= 0 && t < tl.lengthMinutes) {
        final (wall, repeat) = tl.wallAt(t);
        return (i, axis.yOf(wall, repeat: repeat, ppm: ppm));
      }
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final hit = locate(now.value, axis, ppm, timelines);
    if (hit == null || days.isEmpty) return;
    final (index, y) = hit;
    final n = days.length;
    final colW = size.width / n;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1);
    final x = columnX(index, n, size.width, rtl: rtl);
    final strong = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas
      ..drawLine(Offset(x, y), Offset(x + colW, y), strong)
      ..drawCircle(Offset(rtl ? x + colW : x, y), 4, strong);
  }

  @override
  bool shouldRepaint(NowLinePainter old) =>
      old.axis != axis || old.ppm != ppm || old.rtl != rtl || old.color != color || !const ListEquality<LocalDate>().equals(old.days, days);
}
