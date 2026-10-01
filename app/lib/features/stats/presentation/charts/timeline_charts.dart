/// Timeline charts (T6.2.13): the planned-vs-actual Gantt — one row per day or task, the planned bar
/// as an outline and the tracked sessions as fills colored by variance (early, on time, late,
/// overrun); overlapping sessions get their own sub-lanes so none hides another; tapping a row reads
/// out its minutes — and the move timeline (one dot per reschedule with an arrow from the old date to
/// the new one). Time runs right-to-left in RTL.
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/charts/plot_support.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDateTime;
import 'package:material_ui/material_ui.dart';

/// Variance tone of a session against its planned span (5-minute grace).
ChartTone sessionTone(TimeSpan session, TimeSpan? planned, {Duration grace = const Duration(minutes: 5)}) {
  if (planned == null) return ChartTone.primary;
  if (session.end.isAfter(planned.end.add(grace))) return ChartTone.negative; // overrun
  if (session.start.isAfter(planned.start.add(grace))) return ChartTone.late;
  if (session.start.isBefore(planned.start.subtract(grace))) return ChartTone.pending; // early
  return ChartTone.done;
}

/// Greedy lane assignment so overlapping spans never share a lane (returns the lane of each span).
List<int> assignLanes(List<TimeSpan> spans) {
  final order = [for (var i = 0; i < spans.length; i++) i]..sort((a, b) => spans[a].start.compareTo(spans[b].start));
  final laneEnds = <DateTime>[];
  final lanes = List<int>.filled(spans.length, 0);
  for (final i in order) {
    var lane = laneEnds.indexWhere((end) => !spans[i].start.isBefore(end));
    if (lane < 0) {
      lane = laneEnds.length;
      laneEnds.add(spans[i].end);
    } else {
      laneEnds[lane] = spans[i].end;
    }
    lanes[i] = lane;
  }
  return lanes;
}

class GanttChart extends StatefulWidget {
  const GanttChart(this.data, {super.key, this.onRef});

  final GanttData data;
  final void Function(DrillRef ref)? onRef;

  @override
  State<GanttChart> createState() => _GanttChartState();
}

class _GanttChartState extends State<GanttChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final data = widget.data;
    final lanes = [for (final r in data.rows) assignLanes(r.actual)];
    final heights = [for (final l in lanes) 14.0 + 10.0 * (l.isEmpty ? 1 : l.reduce(math.max) + 1)];
    final total = heights.fold<double>(0, (a, b) => a + b) + 20;
    final selected = _selected;
    return LayoutBuilder(
      builder: (context, c) {
        final painter = _GanttPainter(
          data,
          lanes: lanes,
          heights: heights,
          theme: theme,
          format: f,
          rtl: rtl,
          selected: selected,
          labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 10),
        );
        return Stack(
          children: [
            GestureDetector(
              onTapUp: (d) {
                final row = painter.rowAt(d.localPosition.dy);
                setState(() => _selected = row);
                if (row == null) return;
                chartSelectionFeedback(context);
                final ref = data.rows[row].ref;
                if (ref != null) widget.onRef?.call(ref);
              },
              child: CustomPaint(size: Size(c.maxWidth, total), painter: painter),
            ),
            if (selected != null && selected < data.rows.length)
              PositionedDirectional(top: 0, end: 0, child: ChartReadout(lines: _readout(f, data.rows[selected]))),
          ],
        );
      },
    );
  }

  List<String> _readout(StatFormat f, GanttRow row) {
    final planned = row.planned;
    final actual = row.actual.fold<double>(0, (a, s) => a + s.end.difference(s.start).inSeconds / 60);
    return [
      f.label(row.label),
      if (planned != null)
        '${f.label(const TokenLabel(LabelToken.planned))}: ${f.value(planned.end.difference(planned.start).inMinutes.toDouble(), StatUnit.minutes)}',
      '${f.label(const TokenLabel(LabelToken.actual))}: ${f.value(actual, StatUnit.minutes)}',
      if (planned != null && row.actual.isNotEmpty)
        '${f.label(const TokenLabel(LabelToken.late))}: ${f.value(row.actual.first.start.difference(planned.start).inMinutes.toDouble(), StatUnit.minutes)}',
    ];
  }
}

class _GanttPainter extends CustomPainter {
  _GanttPainter(
    this.data, {
    required this.lanes,
    required this.heights,
    required this.theme,
    required this.format,
    required this.rtl,
    required this.selected,
    required this.labelStyle,
  });

  final GanttData data;
  final List<List<int>> lanes;
  final List<double> heights;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final int? selected;
  final TextStyle labelStyle;

  static const _labelWidth = 76.0;

  int? rowAt(double dy) {
    var y = 0.0;
    for (var r = 0; r < heights.length; r++) {
      if (dy >= y && dy < y + heights[r]) return r;
      y += heights[r];
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final span = data.to.difference(data.from).inSeconds;
    if (span <= 0 || data.rows.isEmpty) return;
    final trackLeft = rtl ? 4.0 : _labelWidth;
    final trackRight = rtl ? size.width - _labelWidth : size.width - 4;
    final width = trackRight - trackLeft;
    double tx(DateTime t) {
      final f = (t.difference(data.from).inSeconds / span).clamp(0.0, 1.0);
      return rtl ? trackRight - f * width : trackLeft + f * width;
    }

    final direction = rtl ? TextDirection.rtl : TextDirection.ltr;
    var y = 0.0;
    for (var r = 0; r < data.rows.length; r++) {
      final row = data.rows[r];
      final h = heights[r];
      if (r == selected) {
        canvas.drawRect(Rect.fromLTWH(0, y, size.width, h), Paint()..color = theme.grid.withValues(alpha: 0.4));
      }
      paintLabel(
        canvas,
        format.label(row.label),
        Offset(rtl ? size.width - 2 : 2, y + h / 2),
        labelStyle,
        anchor: rtl ? TextAnchor.rightEdge : TextAnchor.leftEdge,
        maxWidth: _labelWidth - 6,
        direction: direction,
      );
      final planned = row.planned;
      if (planned != null) {
        final a = tx(planned.start);
        final b = tx(planned.end);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(math.min(a, b), y + 3, math.max(a, b), y + h - 3),
            const Radius.circular(3),
          ),
          Paint()
            ..color = theme.axis
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
      for (var s = 0; s < row.actual.length; s++) {
        final session = row.actual[s];
        final a = tx(session.start);
        final b = tx(session.end);
        final top = y + 7 + lanes[r][s] * 10.0;
        final rect = Rect.fromLTRB(math.min(a, b), top, math.max(math.max(a, b), math.min(a, b) + 2), top + 8);
        final tone = sessionTone(session, planned);
        final color = theme.tone(tone);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), Paint()..color = color);
        paintPattern(canvas, rect, theme.patternOf(tone), onColor(color).withValues(alpha: 0.45));
      }
      canvas.drawLine(Offset(0, y + h), Offset(size.width, y + h), Paint()..color = theme.grid);
      y += h;
    }
    // Time ticks.
    final days = data.to.difference(data.from).inHours > 48;
    for (var k = 0; k <= 4; k++) {
      final t = data.from.add(Duration(seconds: span * k ~/ 4));
      paintLabel(
        canvas,
        days ? format.dateTime(t) : format.clock((t.toLocal().hour * 60 + t.toLocal().minute).toDouble()),
        Offset(tx(t), y + 10),
        labelStyle,
        maxWidth: width / 4,
      );
    }
  }

  @override
  bool shouldRepaint(_GanttPainter old) =>
      old.data != data || old.selected != selected || old.rtl != rtl || old.theme != theme;
}

class MoveTimelineChart extends StatelessWidget {
  const MoveTimelineChart(this.data, {super.key, this.maxRows = 12});

  final MoveTimelineData data;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final moves = data.moves.take(maxRows).toList();
    return Semantics(
      label: context.l10n.chartsSummaryList(
        statFormatOf(context).label(const TokenLabel(LabelToken.moved)),
        '${moves.length}',
      ),
      child: SizedBox(
        height: 16.0 * moves.length + 24,
        width: double.infinity,
        child: CustomPaint(
          painter: _MovesPainter(
            moves,
            theme: theme,
            format: statFormatOf(context),
            rtl: Directionality.of(context) == TextDirection.rtl,
            labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 10),
          ),
        ),
      ),
    );
  }
}

class _MovesPainter extends CustomPainter {
  _MovesPainter(this.moves, {required this.theme, required this.format, required this.rtl, required this.labelStyle});

  final List<MoveEvent> moves;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (moves.isEmpty) return;
    var lo = moves.first.fromEpochMinute;
    var hi = moves.first.toEpochMinute;
    for (final m in moves) {
      lo = math.min(lo, math.min(m.fromEpochMinute, m.toEpochMinute));
      hi = math.max(hi, math.max(m.fromEpochMinute, m.toEpochMinute));
    }
    if (hi == lo) hi = lo + 60;
    const pad = 10.0;
    double tx(int minute) {
      final f = (minute - lo) / (hi - lo);
      return rtl ? size.width - pad - f * (size.width - 2 * pad) : pad + f * (size.width - 2 * pad);
    }

    for (var i = 0; i < moves.length; i++) {
      final m = moves[i];
      final y = 8 + i * 16.0;
      final a = Offset(tx(m.fromEpochMinute), y);
      final b = Offset(tx(m.toEpochMinute), y);
      final tone = m.deltaMinutes > 0 ? ChartTone.late : (m.deltaMinutes < 0 ? ChartTone.pending : ChartTone.muted);
      final paint = Paint()
        ..color = theme.tone(tone)
        ..strokeWidth = 1.6;
      canvas
        ..drawCircle(a, 3.5, Paint()..color = theme.onSurface)
        ..drawLine(a, b, paint);
      if ((b - a).distance > 4) arrowHead(canvas, b, (b - a).direction, Paint()..color = theme.tone(tone));
    }
    final axisY = size.height - 8;
    for (final minute in [lo, hi]) {
      // Move payloads carry wall-clock minutes (planned local times).
      final local = LocalDateTime.fromEpochMinute(minute);
      paintLabel(
        canvas,
        '${format.dayShort(local.date)} ${format.clock(local.time.minuteOfDay.toDouble())}',
        Offset(tx(minute), axisY),
        labelStyle,
        anchor: (tx(minute) < size.width / 2) ? TextAnchor.leftEdge : TextAnchor.rightEdge,
      );
    }
  }

  @override
  bool shouldRepaint(_MovesPainter old) => old.moves != moves || old.rtl != rtl || old.theme != theme;
}
