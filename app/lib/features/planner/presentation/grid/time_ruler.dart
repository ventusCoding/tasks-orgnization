import 'dart:collection';

import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:everslot/features/planner/presentation/grid/engine/time_scale.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Shows a [child] of [contentHeight] translated by the vertical scroll offset of [vertical]
/// (no rebuild of the child while scrolling — only the transform changes).
class ScrolledContent extends StatelessWidget {
  const ScrolledContent({required this.vertical, required this.contentHeight, required this.child, super.key});

  final ScrollController vertical;
  final double contentHeight;
  final Widget child;

  // The translation sits inside the viewport-sized OverflowBox so hit testing reaches content below
  // the first screen (RenderTransform skips its own bounds check; the full-height child is hit).
  @override
  Widget build(BuildContext context) => ClipRect(
    child: OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: contentHeight,
      maxHeight: contentHeight,
      child: AnimatedBuilder(
        animation: vertical,
        builder: (context, child) =>
            Transform.translate(offset: Offset(0, -(vertical.hasClients ? vertical.offset : 0.0)), child: child),
        child: child,
      ),
    ),
  );
}

/// Small LRU cache of laid-out labels (T3.3.25: cached TextPainters).
class LabelCache {
  LabelCache({this.capacity = 400});

  final int capacity;
  final LinkedHashMap<(String, TextStyle, TextDirection), TextPainter> _cache = LinkedHashMap();

  TextPainter get(String text, TextStyle style, TextDirection dir) {
    final key = (text, style, dir);
    final hit = _cache.remove(key);
    if (hit != null) return _cache[key] = hit;
    if (_cache.length >= capacity) _cache.remove(_cache.keys.first)?.dispose();
    return _cache[key] = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: dir,
    )..layout();
  }
}

/// One ruler column: labels for [scale] cadence on [axis].
class TimeRulerPainter extends CustomPainter {
  TimeRulerPainter({
    required this.axis,
    required this.scale,
    required this.formatMinute,
    required this.textStyle,
    required this.style,
    required this.textDirection,
    required this.cache,
    this.offsetLabel,
    this.hiddenLabel,
    this.gapLabel,
  });

  final PageAxis axis;
  final TimeScale scale;

  /// Label of a wall minute on pass (repeat) 0/1.
  final String Function(int minute, int repeat) formatMinute;

  /// Offset suffix of a repeated wall minute, e.g. "+01:00".
  final String Function(int minute)? offsetLabel;
  final String Function(int from, int to)? hiddenLabel;
  final String? gapLabel;
  final TextStyle textStyle;
  final GridStyle style;
  final TextDirection textDirection;
  final LabelCache cache;

  double get ppm => scale.pxPerMinute;

  @override
  void paint(Canvas canvas, Size size) {
    final every = scale.labelEveryMinutes();
    var lastY = double.negativeInfinity;
    final small = textStyle.copyWith(fontSize: (textStyle.fontSize ?? 11) - 2);
    for (final band in axis.bands) {
      final top = band.top(ppm);
      if (band.kind != AxisBandKind.normal) {
        final text = band.kind == AxisBandKind.gap ? gapLabel : hiddenLabel?.call(band.wallStart, band.wallEnd);
        if (text != null) {
          final tp = cache.get(text, small, textDirection);
          if (tp.height <= band.fixedExtent + 4) {
            tp.paint(canvas, Offset((size.width - tp.width) / 2, top + (band.fixedExtent - tp.height) / 2));
          }
        }
        lastY = top + band.fixedExtent;
        continue;
      }
      for (final piece in band.pieces) {
        var m = piece.wallStart % every == 0 ? piece.wallStart : (piece.wallStart ~/ every + 1) * every;
        if (piece.repeat == 1 && piece.wallStart % every != 0) m = piece.wallStart;
        for (; m < piece.wallEnd; m += every) {
          final y = axis.yOf(m, repeat: piece.repeat, ppm: ppm);
          final tp = cache.get(formatMinute(m, piece.repeat), textStyle, textDirection);
          final labelTop = y <= 0.5 ? 2.0 : y - tp.height / 2;
          if (labelTop < lastY + 2) continue;
          tp.paint(canvas, Offset((size.width - tp.width) / 2, labelTop));
          var bottom = labelTop + tp.height;
          if (piece.repeat == 1 && offsetLabel != null) {
            final sub = cache.get(offsetLabel!(m), small, textDirection);
            sub.paint(canvas, Offset((size.width - sub.width) / 2, bottom));
            bottom += sub.height;
          }
          lastY = bottom;
        }
      }
    }
  }

  @override
  bool shouldRepaint(TimeRulerPainter old) =>
      old.axis != axis ||
      old.scale != scale ||
      old.textStyle != textStyle ||
      old.style != style ||
      old.textDirection != textDirection ||
      old.formatMinute != formatMinute;
}

/// Highlights the current time on the ruler (repaints once a minute).
class RulerNowPainter extends CustomPainter {
  RulerNowPainter({
    required this.now,
    required this.axis,
    required this.ppm,
    required this.timeline,
    required this.format,
    required this.textStyle,
    required this.color,
    required this.onColor,
    required this.cache,
  }) : super(repaint: now);

  final ValueListenable<DateTime> now;
  final PageAxis axis;
  final double ppm;
  final DayTimeline? timeline;
  final String Function(int minute) format;
  final TextStyle textStyle;
  final Color color;
  final Color onColor;
  final LabelCache cache;

  @override
  void paint(Canvas canvas, Size size) {
    final tl = timeline;
    if (tl == null) return;
    final t = tl.tOfInstant(now.value);
    if (t < 0 || t >= tl.lengthMinutes) return;
    final (wall, repeat) = tl.wallAt(t);
    final y = axis.yOf(wall, repeat: repeat, ppm: ppm);
    final tp = cache.get(
      format(wall),
      textStyle.copyWith(color: onColor, fontWeight: FontWeight.w600),
      TextDirection.ltr,
    );
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, y), width: tp.width + 8, height: tp.height + 4),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = color);
    tp.paint(canvas, Offset(rect.left + 4, rect.top + 2));
  }

  @override
  bool shouldRepaint(RulerNowPainter old) => old.axis != axis || old.ppm != ppm || old.timeline != timeline;
}

/// The pinned ruler column (T3.3.08): labels per cadence, locale 12/24 h, current time highlight,
/// double-tap → slot-size sheet. Extra zone columns (T3.3.26) show the same instants elsewhere.
class TimeRuler extends StatelessWidget {
  const TimeRuler({
    required this.vertical,
    required this.axis,
    required this.scale,
    required this.width,
    required this.formatMinute,
    required this.style,
    required this.now,
    required this.todayTimeline,
    required this.cache,
    this.offsetLabel,
    this.hiddenLabel,
    this.gapLabel,
    this.onDoubleTap,
    this.semanticsLabel,
    super.key,
  });

  final ScrollController vertical;
  final PageAxis axis;
  final TimeScale scale;
  final double width;
  final String Function(int minute, int repeat) formatMinute;
  final String Function(int minute)? offsetLabel;
  final String Function(int from, int to)? hiddenLabel;
  final String? gapLabel;
  final GridStyle style;
  final ValueListenable<DateTime> now;
  final DayTimeline? todayTimeline;
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
    final height = axis.height(scale.pxPerMinute);
    return Semantics(
      label: semanticsLabel,
      button: onDoubleTap != null,
      onTap: onDoubleTap,
      child: GestureDetector(
        onDoubleTap: onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: width,
          child: ScrolledContent(
            vertical: vertical,
            contentHeight: height,
            child: Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(width, height),
                    painter: TimeRulerPainter(
                      axis: axis,
                      scale: scale,
                      formatMinute: formatMinute,
                      offsetLabel: offsetLabel,
                      hiddenLabel: hiddenLabel,
                      gapLabel: gapLabel,
                      textStyle: textStyle,
                      style: style,
                      textDirection: Directionality.of(context),
                      cache: cache,
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(width, height),
                    painter: RulerNowPainter(
                      now: now,
                      axis: axis,
                      ppm: scale.pxPerMinute,
                      timeline: todayTimeline,
                      format: (m) => formatMinute(m, 0),
                      textStyle: textStyle,
                      color: style.nowLine,
                      onColor: Colors.white,
                      cache: cache,
                    ),
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

/// Formats a minute of day for another [zone] using [reference] (the day whose instants are used).
String Function(int, int) zoneFormatter(DayTimeline reference, String Function(DateTime utc) formatUtc) =>
    (minute, repeat) => formatUtc(reference.instantAt(reference.tOfWall(minute, repeat: repeat)));
