/// Calendar heatmap & year grid (T6.2.06), one `CustomPainter`: month calendars (7 columns in
/// week-start order with day numbers) for short ranges and a GitHub-style year grid (weeks × 7) with
/// month labels for long ones. Discrete status mode (color + pattern per status, legend) or
/// continuous intensity mode (5 bins, quantiles or fixed thresholds). Today is outlined, future days
/// are dimmed, taps return the ISO date; RTL mirrors the columns.
library;

import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:everslot/features/stats/presentation/charts/chart_theme.dart';
import 'package:everslot/features/stats/presentation/format/stat_format.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate, Weekday;
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap(this.data, {super.key, this.onTap, this.forceYearGrid = false});

  final CalendarData data;
  final void Function(ChartTap tap)? onTap;

  /// Shows the year grid even for short ranges.
  final bool forceYearGrid;

  @override
  Widget build(BuildContext context) {
    final theme = ChartTheme.of(context);
    final f = statFormatOf(context);
    final weekStart = chartWeekStart(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final bins = _bins(data);
    Color colorOf(CalendarCell? c) {
      if (c == null) return theme.grid.withValues(alpha: 0.35);
      if (data.mode == CalendarMode.status) return c.tone == null ? theme.grid : theme.tone(c.tone!);
      final v = c.value;
      if (v == null) return theme.grid.withValues(alpha: 0.35);
      var bin = 0;
      while (bin < bins.length && v > bins[bin]) {
        bin++;
      }
      return theme.seriesColor(2).withValues(alpha: 0.2 + 0.8 * bin / math.max(1, bins.length));
    }

    final monthMode = !forceYearGrid && data.from.daysUntil(data.to) <= 45;
    final legend = _legend(context, theme, f);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (monthMode)
          for (final month in _months(data.from, data.to))
            _MonthGrid(
              month: month,
              data: data,
              weekStart: weekStart,
              colorOf: colorOf,
              theme: theme,
              format: f,
              rtl: rtl,
              onTap: onTap,
            )
        else
          _YearGrid(
            data: data,
            weekStart: weekStart,
            colorOf: colorOf,
            theme: theme,
            format: f,
            rtl: rtl,
            onTap: onTap,
          ),
        if (legend != null) ...[const SizedBox(height: Space.sm), legend],
      ],
    );
  }

  static List<LocalDate> _months(LocalDate from, LocalDate to) {
    final result = <LocalDate>[];
    for (var m = from.firstDayOfMonth; !m.isAfter(to); m = m.plusMonths(1)) {
      result.add(m);
    }
    return result;
  }

  /// Upper bounds of the intensity bins (fixed thresholds or quantiles).
  static List<double> _bins(CalendarData data) {
    if (data.mode != CalendarMode.intensity) return const [];
    if (data.thresholds != null) return data.thresholds!;
    final values = [for (final c in data.cells.values) ?c.value]..sort();
    if (values.isEmpty) return const [];
    return [
      for (final q in const [0.2, 0.4, 0.6, 0.8]) values[((values.length - 1) * q).round()],
    ];
  }

  Widget? _legend(BuildContext context, ChartTheme theme, StatFormat f) {
    if (data.mode == CalendarMode.status) {
      final tones = <ChartTone, ChartLabel?>{};
      for (final c in data.cells.values) {
        if (c.tone != null) tones.putIfAbsent(c.tone!, () => c.label);
      }
      if (tones.isEmpty) return null;
      return Wrap(
        spacing: Space.md,
        runSpacing: Space.xs,
        children: [
          for (final e in tones.entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CustomPaint(painter: _SwatchPainter(theme.tone(e.key), theme.patternOf(e.key))),
                ),
                const SizedBox(width: Space.xs),
                Text(e.value == null ? '' : f.label(e.value!), style: context.text.labelSmall),
              ],
            ),
        ],
      );
    }
    return null;
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.color, this.pattern);

  final Color color;
  final ChartPattern pattern;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = color);
    paintPattern(canvas, r, pattern, onColor(color).withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(_SwatchPainter old) => old.color != color || old.pattern != pattern;
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.data,
    required this.weekStart,
    required this.colorOf,
    required this.theme,
    required this.format,
    required this.rtl,
    required this.onTap,
  });

  final LocalDate month;
  final CalendarData data;
  final Weekday weekStart;
  final Color Function(CalendarCell? c) colorOf;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final void Function(ChartTap tap)? onTap;

  @override
  Widget build(BuildContext context) {
    final first = month.startOfWeek(weekStart);
    final last = month.lastDayOfMonth;
    final weeks = (first.daysUntil(last) ~/ 7) + 1;
    final order = Weekday.ordered(weekStart);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            format.digits(DateFormat.yMMMM(format.locale).format(month.toDateTimeUtc())),
            style: context.text.labelMedium,
          ),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              for (final w in order)
                Expanded(
                  child: Center(
                    child: Text(format.weekday(w), style: context.text.labelSmall?.copyWith(color: theme.label)),
                  ),
                ),
            ],
          ),
          for (var row = 0; row < weeks; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: () {
                      final day = first.plusDays(row * 7 + col);
                      if (day.month != month.month) return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
                      final cell = data.cells[day];
                      final inRange = !day.isBefore(data.from) && !day.isAfter(data.to);
                      final future = data.today != null && day.isAfter(data.today!);
                      final color = colorOf(inRange ? cell : null);
                      final label = [
                        format.date(day),
                        if (cell?.label != null) format.label(cell!.label!),
                        if (cell?.value != null) format.value(cell!.value!, data.unit),
                      ].join(', ');
                      return Padding(
                        padding: const EdgeInsets.all(1.5),
                        child: Semantics(
                          label: label,
                          button: onTap != null && cell != null,
                          child: GestureDetector(
                            onTap: onTap == null || cell == null
                                ? null
                                : () {
                                    chartSelectionFeedback(context);
                                    onTap!(ChartTap(drillKey: day.toIso(), label: DateLabel(day), value: cell.value));
                                  },
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: CustomPaint(
                                painter: _CellPainter(
                                  color: future ? color.withValues(alpha: 0.35) : color,
                                  pattern: cell?.tone == null ? ChartPattern.none : theme.patternOf(cell!.tone!),
                                  today: data.today == day,
                                  outline: theme.onSurface,
                                ),
                                child: Center(
                                  child: Text(
                                    format.digits('${day.day}'),
                                    style: context.text.labelSmall?.copyWith(
                                      color: cell == null ? theme.label : onColor(color),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }(),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CellPainter extends CustomPainter {
  _CellPainter({required this.color, required this.pattern, required this.today, required this.outline});

  final Color color;
  final ChartPattern pattern;
  final bool today;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = color);
    paintPattern(canvas, r, pattern, onColor(color).withValues(alpha: 0.45));
    if (today) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_CellPainter old) => old.color != color || old.pattern != pattern || old.today != today;
}

class _YearGrid extends StatelessWidget {
  const _YearGrid({
    required this.data,
    required this.weekStart,
    required this.colorOf,
    required this.theme,
    required this.format,
    required this.rtl,
    required this.onTap,
  });

  final CalendarData data;
  final Weekday weekStart;
  final Color Function(CalendarCell? c) colorOf;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final void Function(ChartTap tap)? onTap;

  @override
  Widget build(BuildContext context) {
    final first = data.from.startOfWeek(weekStart);
    final weeks = (first.daysUntil(data.to) ~/ 7) + 1;
    return LayoutBuilder(
      builder: (context, c) {
        const labelWidth = 26.0;
        final cell = math.max(9.0, math.min(16.0, (c.maxWidth - labelWidth) / weeks));
        final width = labelWidth + cell * weeks;
        final painter = _YearPainter(
          data: data,
          first: first,
          weeks: weeks,
          cell: cell,
          labelWidth: labelWidth,
          weekStart: weekStart,
          colorOf: colorOf,
          theme: theme,
          format: format,
          rtl: rtl,
          labelStyle: context.text.labelSmall!.copyWith(color: theme.label, fontSize: 9),
        );
        final grid = Semantics(
          label: format.l10n.chartsSummaryCalendar('', '${data.cells.length}'),
          child: GestureDetector(
            onTapUp: onTap == null
                ? null
                : (d) {
                    final day = painter.dayAt(d.localPosition);
                    if (day == null || data.cells[day] == null) return;
                    chartSelectionFeedback(context);
                    onTap!(ChartTap(drillKey: day.toIso(), label: DateLabel(day), value: data.cells[day]!.value));
                  },
            child: CustomPaint(size: Size(width, cell * 7 + 16), painter: painter),
          ),
        );
        if (width <= c.maxWidth) return grid;
        return SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: !rtl, child: grid);
      },
    );
  }
}

class _YearPainter extends CustomPainter {
  _YearPainter({
    required this.data,
    required this.first,
    required this.weeks,
    required this.cell,
    required this.labelWidth,
    required this.weekStart,
    required this.colorOf,
    required this.theme,
    required this.format,
    required this.rtl,
    required this.labelStyle,
  });

  final CalendarData data;
  final LocalDate first;
  final int weeks;
  final double cell;
  final double labelWidth;
  final Weekday weekStart;
  final Color Function(CalendarCell? c) colorOf;
  final ChartTheme theme;
  final StatFormat format;
  final bool rtl;
  final TextStyle labelStyle;

  double _x(int week, double width) => rtl ? width - labelWidth - (week + 1) * cell : labelWidth + week * cell;

  LocalDate? dayAt(Offset p) {
    final width = labelWidth + cell * weeks;
    final y = p.dy - 14;
    if (y < 0) return null;
    final row = (y / cell).floor();
    if (row < 0 || row > 6) return null;
    final week = rtl ? ((width - labelWidth - p.dx) / cell).floor() : ((p.dx - labelWidth) / cell).floor();
    if (week < 0 || week >= weeks) return null;
    final day = first.plusDays(week * 7 + row);
    return day.isBefore(data.from) || day.isAfter(data.to) ? null : day;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final order = Weekday.ordered(weekStart);
    void text(String t, Offset at) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: labelStyle),
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      )..layout(maxWidth: 60);
      tp.paint(canvas, Offset(at.dx - (rtl ? tp.width : 0), at.dy));
    }

    // Weekday labels (every other row).
    for (var r = 0; r < 7; r += 2) {
      text(format.weekday(order[r]), Offset(rtl ? size.width - 2 : 0, 14 + r * cell));
    }
    var lastMonth = -1;
    for (var w = 0; w < weeks; w++) {
      for (var r = 0; r < 7; r++) {
        final day = first.plusDays(w * 7 + r);
        if (day.isBefore(data.from) || day.isAfter(data.to)) continue;
        if (r == 0 && day.month != lastMonth) {
          lastMonth = day.month;
          text(
            format.digits(DateFormat.MMM(format.locale).format(day.toDateTimeUtc())),
            Offset(_x(w, size.width) + (rtl ? cell : 0), 0),
          );
        }
        final c = data.cells[day];
        final future = data.today != null && day.isAfter(data.today!);
        final color = colorOf(c);
        final rect = Rect.fromLTWH(_x(w, size.width) + 1, 14 + r * cell + 1, cell - 2, cell - 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          Paint()..color = future ? color.withValues(alpha: 0.35) : color,
        );
        if (c?.tone != null)
          paintPattern(canvas, rect, theme.patternOf(c!.tone!), onColor(color).withValues(alpha: 0.45));
        if (data.today == day) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            Paint()
              ..color = theme.onSurface
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_YearPainter old) =>
      old.data != data || old.cell != cell || old.rtl != rtl || old.theme != theme || old.weekStart != weekStart;
}
