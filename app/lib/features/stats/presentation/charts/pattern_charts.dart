/// Streak bars & streak timeline (T6.2.08) and the weekday × hour punch card (T6.2.09).
///
/// - Streak bars: Loop-style horizontal bars of the top streaks (ordered by length, then recency),
///   each with its length and date range; the current streak is highlighted and frozen units are
///   drawn with a pattern. The timeline lane shows streak segments along the calendar.
/// - Punch card: rows are weekdays in week-start order, columns hours (12/24 h labels, mirrored in
///   RTL), rotated to the day-start hour; bubble or color-intensity encoding; taps return
///   `weekday:hour`; an empty matrix shows the empty state.
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show Weekday;
import 'package:material_ui/material_ui.dart';

class StreakChart extends StatelessWidget {
  const StreakChart(this.data, {super.key, this.onTap});

  final StreakData data;
  final void Function(ChartTap tap)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    if (data.timeline) return _StreakTimeline(data: data, theme: theme, format: f);
    final longest = data.streaks.isEmpty ? 1 : data.streaks.map((s) => s.length).reduce(math.max);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in data.streaks)
          Semantics(
            label:
                '${f.value(s.length.toDouble(), data.unit)}, ${context.l10n.chartsRange(f.date(s.start), f.date(s.end))}'
                '${s.current ? ', ${context.l10n.chartsStreakCurrent}' : ''}',
            child: InkWell(
              onTap: onTap == null
                  ? null
                  : () => onTap!(
                      ChartTap(drillKey: s.start.toIso(), label: DateLabel(s.start), value: s.length.toDouble()),
                    ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        context.l10n.chartsRange(f.dayShort(s.start), f.dayShort(s.end)),
                        style: context.text.labelSmall?.copyWith(color: theme.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final w = math.max<double>(24, c.maxWidth * s.length / longest);
                          final barColor = s.current
                              ? theme.tone(ChartTone.done)
                              : theme.seriesColor(0).withValues(alpha: 0.75);
                          return Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: SizedBox(
                              width: w,
                              height: 22,
                              child: CustomPaint(
                                painter: _StreakBarPainter(
                                  color: barColor,
                                  frozenShare: s.length == 0 ? 0 : s.frozenUnits / s.length,
                                  frozenColor: theme.tone(ChartTone.frozen),
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.xs),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      f.number(s.length.toDouble()),
                                      style: context.text.labelSmall?.copyWith(
                                        color: onColor(barColor),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (s.frozenUnits > 0) ...[
                      const SizedBox(width: Space.xs),
                      Icon(Icons.ac_unit, size: 14, color: theme.tone(ChartTone.frozen)),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StreakBarPainter extends CustomPainter {
  _StreakBarPainter({required this.color, required this.frozenShare, required this.frozenColor});

  final Color color;
  final double frozenShare;
  final Color frozenColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4));
    canvas.drawRRect(r, Paint()..color = color);
    if (frozenShare > 0) {
      final w = size.width * frozenShare.clamp(0.0, 1.0);
      paintPattern(canvas, Rect.fromLTWH(size.width - w, 0, w, size.height), ChartPattern.crossHatch, frozenColor);
    }
  }

  @override
  bool shouldRepaint(_StreakBarPainter old) => old.color != color || old.frozenShare != frozenShare;
}

class _StreakTimeline extends StatelessWidget {
  const _StreakTimeline({required this.data, required this.theme, required this.format});

  final StreakData data;
  final ChartTheme theme;
  final StatFormat format;

  @override
  Widget build(BuildContext context) {
    if (data.streaks.isEmpty) return const SizedBox.shrink();
    final first = data.streaks.map((s) => s.start).reduce((a, b) => a.isBefore(b) ? a : b);
    final last = data.streaks.map((s) => s.end).reduce((a, b) => a.isAfter(b) ? a : b);
    final span = math.max(1, first.daysUntil(last) + 1);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: 24,
      child: CustomPaint(
        size: Size.infinite,
        painter: _TimelinePainter(
          [
            for (final s in data.streaks)
              (first.daysUntil(s.start) / span, (first.daysUntil(s.end) + 1) / span, s.current, s.frozenUnits > 0),
          ],
          theme,
          rtl: rtl,
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter(this.segments, this.theme, {required this.rtl});

  final List<(double, double, bool, bool)> segments;
  final ChartTheme theme;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, size.height / 2 - 1, size.width, 2), Paint()..color = theme.grid);
    for (final (a, b, current, frozen) in segments) {
      final x0 = (rtl ? 1 - b : a) * size.width;
      final x1 = (rtl ? 1 - a : b) * size.width;
      final rect = Rect.fromLTRB(x0, 4, math.max(x0 + 2, x1), size.height - 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = current ? theme.tone(ChartTone.done) : theme.seriesColor(0),
      );
      if (frozen) paintPattern(canvas, rect, ChartPattern.crossHatch, theme.tone(ChartTone.frozen));
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter old) => true;
}

class PunchCardChart extends StatelessWidget {
  const PunchCardChart(this.data, {super.key, this.onTap});

  final PunchCardData data;
  final void Function(ChartTap tap)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final prefs = ChartPrefs.maybeOf(context);
    final weekStart = prefs?.weekStart ?? Weekday.monday;
    final startHour = ((prefs?.dayStartMinutes ?? 0) ~/ 60) % 24;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (data.isEmpty) {
      return Padding(padding: const EdgeInsets.all(Space.lg), child: Text(context.l10n.chartsEmpty));
    }
    final order = Weekday.ordered(weekStart);
    final maxV = data.max;
    return LayoutBuilder(
      builder: (context, c) {
        const labelWidth = 36.0;
        final cell = math.max<double>(10, (c.maxWidth - labelWidth) / 24);
        final width = labelWidth + cell * 24;
        final painter = _PunchPainter(
          data: data,
          order: order,
          startHour: startHour,
          maxV: maxV,
          cell: cell,
          labelWidth: labelWidth,
          theme: theme,
          format: f,
          rtl: rtl,
          labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 9),
        );
        final grid = GestureDetector(
          onTapUp: onTap == null
              ? null
              : (d) {
                  final hit = painter.cellAt(d.localPosition, width);
                  if (hit == null) return;
                  chartSelectionFeedback(context);
                  onTap!(
                    ChartTap(
                      drillKey: 'weekday:${hit.$1.iso}:${hit.$2}',
                      label: WeekdayLabel(hit.$1),
                      value: data.values[hit.$1.iso - 1][hit.$2],
                    ),
                  );
                },
          child: CustomPaint(size: Size(width, cell * 7 + 18), painter: painter),
        );
        return width > c.maxWidth
            ? SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: rtl, child: grid)
            : grid;
      },
    );
  }
}

class _PunchPainter extends CustomPainter {
  _PunchPainter({
    required this.data,
    required this.order,
    required this.startHour,
    required this.maxV,
    required this.cell,
    required this.labelWidth,
    required this.theme,
    required this.format,
    required this.rtl,
    required this.labelStyle,
  });

  final PunchCardData data;
  final List<Weekday> order;
  final int startHour;
  final double maxV;
  final double cell;
  final double labelWidth;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final TextStyle labelStyle;

  /// Hour shown in column [col] (rotated to the day start).
  int _hour(int col) => (startHour + col) % 24;

  double _x(int col, double width) => rtl ? width - labelWidth - (col + 1) * cell : labelWidth + col * cell;

  (Weekday, int)? cellAt(Offset p, double width) {
    final row = ((p.dy - 16) / cell).floor();
    if (row < 0 || row > 6) return null;
    final col = rtl ? ((width - labelWidth - p.dx) / cell).floor() : ((p.dx - labelWidth) / cell).floor();
    if (col < 0 || col > 23) return null;
    return (order[row], _hour(col));
  }

  void _text(Canvas canvas, String t, Offset at, {bool center = true}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: labelStyle),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    )..layout(maxWidth: 48);
    tp.paint(canvas, Offset(center ? at.dx - tp.width / 2 : at.dx - (rtl ? tp.width : 0), at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final every = cell >= 18 ? 3 : 6;
    for (var col = 0; col < 24; col += every) {
      _text(canvas, format.hour(_hour(col)), Offset(_x(col, size.width) + cell / 2, 7));
    }
    for (var r = 0; r < 7; r++) {
      final w = order[r];
      _text(canvas, format.weekday(w), Offset(rtl ? size.width - 2 : 0, 16 + r * cell + cell / 2), center: false);
      for (var col = 0; col < 24; col++) {
        final v = data.values[w.iso - 1][_hour(col)];
        final center = Offset(_x(col, size.width) + cell / 2, 16 + r * cell + cell / 2);
        if (data.bubbles) {
          canvas.drawCircle(center, 1, Paint()..color = theme.grid);
          if (v > 0) {
            canvas.drawCircle(
              center,
              math.max(1.5, (cell / 2 - 1) * math.sqrt(v / maxV)),
              Paint()..color = theme.seriesColor(0),
            );
          }
        } else {
          final rect = Rect.fromCenter(center: center, width: cell - 2, height: cell - 2);
          final t = maxV <= 0 ? 0.0 : v / maxV;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            Paint()
              ..color = v <= 0
                  ? theme.grid.withValues(alpha: 0.35)
                  : theme.seriesColor(0).withValues(alpha: 0.18 + 0.82 * t),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PunchPainter old) =>
      old.data != data || old.rtl != rtl || old.startHour != startHour || old.cell != cell || old.theme != theme;
}
