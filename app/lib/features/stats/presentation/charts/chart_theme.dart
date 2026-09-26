/// Chart theme tokens (T6.2.01): an 8-color Okabe–Ito series palette (light/dark variants), the
/// status tones of the design system, category colors, grid/axis colors and pattern fills so series
/// stay distinguishable without color.
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:material_ui/material_ui.dart';

/// Pattern fills used on top of colors (color is never the only channel).
enum ChartPattern { none, diagonal, dots, crossHatch }

@immutable
class ChartTheme extends ThemeExtension<ChartTheme> {
  const ChartTheme({
    required this.series,
    required this.grid,
    required this.axis,
    required this.label,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.appColors,
    required this.brightness,
    this.strokeWidth = 2,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  /// Okabe–Ito (color-blind safe), tuned for contrast on light surfaces.
  static const _okabeLight = <Color>[
    Color(0xFF0072B2), // blue
    Color(0xFFD55E00), // vermillion
    Color(0xFF009E73), // bluish green
    Color(0xFFCC79A7), // reddish purple
    Color(0xFFB8860B), // dark yellow (orange-ish, ≥ 3:1 on white)
    Color(0xFF56B4E9), // sky blue
    Color(0xFF6B4E00), // brown
    Color(0xFF444444), // neutral
  ];

  /// Okabe–Ito lightened for dark surfaces.
  static const _okabeDark = <Color>[
    Color(0xFF56B4E9),
    Color(0xFFFF8A4C),
    Color(0xFF3CCFA0),
    Color(0xFFE4A3C8),
    Color(0xFFF0E442),
    Color(0xFF9FD7F5),
    Color(0xFFE69F00),
    Color(0xFFBBBBBB),
  ];

  /// Theme derived from the ambient [ThemeData] (used when no extension is registered).
  factory ChartTheme.fallback(ThemeData theme) {
    final dark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    return ChartTheme(
      series: dark ? _okabeDark : _okabeLight,
      grid: scheme.outlineVariant.withValues(alpha: dark ? 0.35 : 0.5),
      axis: scheme.outline,
      label: scheme.onSurfaceVariant,
      surface: scheme.surface,
      onSurface: scheme.onSurface,
      muted: scheme.outline.withValues(alpha: 0.6),
      appColors: theme.extension<AppColors>() ?? (dark ? AppColors.dark : AppColors.light),
      brightness: theme.brightness,
    );
  }

  static ChartTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<ChartTheme>() ?? ChartTheme.fallback(theme);
  }

  final List<Color> series;
  final Color grid;
  final Color axis;
  final Color label;
  final Color surface;
  final Color onSurface;
  final Color muted;
  final AppColors appColors;
  final Brightness brightness;
  final double strokeWidth;
  final Duration animationDuration;

  bool get isDark => brightness == Brightness.dark;

  Color seriesColor(int index) => series[index % series.length];

  /// Color of a semantic tone.
  Color tone(ChartTone tone) {
    final c = appColors;
    return switch (tone) {
      ChartTone.done || ChartTone.completed || ChartTone.positive => c.success,
      ChartTone.late => isDark ? const Color(0xFF9BD67F) : const Color(0xFF4D7C0F),
      ChartTone.partial => isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1),
      ChartTone.failed || ChartTone.negative => c.danger,
      ChartTone.missed => c.missed,
      ChartTone.skipped => c.skipped,
      ChartTone.excused => isDark ? const Color(0xFFA5B4FC) : const Color(0xFF6366F1),
      ChartTone.paused => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ChartTone.frozen => isDark ? const Color(0xFF67E8F9) : const Color(0xFF0891B2),
      ChartTone.pending => c.info,
      ChartTone.notDue => muted.withValues(alpha: 0.35),
      ChartTone.todo => c.todo,
      ChartTone.ongoing => c.ongoing,
      ChartTone.waiting => c.waiting,
      ChartTone.blocked => c.blocked,
      ChartTone.cancelled => c.cancelled,
      ChartTone.warning => c.warning,
      ChartTone.neutral => label,
      ChartTone.muted => muted,
      ChartTone.primary => seriesColor(0),
    };
  }

  /// Pattern of a tone (grayscale distinguishability of statuses).
  ChartPattern patternOf(ChartTone tone) => switch (tone) {
    ChartTone.partial || ChartTone.late => ChartPattern.diagonal,
    ChartTone.skipped || ChartTone.excused || ChartTone.waiting => ChartPattern.dots,
    ChartTone.frozen || ChartTone.paused || ChartTone.blocked => ChartPattern.crossHatch,
    _ => ChartPattern.none,
  };

  /// Resolves a [ChartColor] token.
  Color resolve(ChartColor color) => switch (color) {
    SeriesColor(:final index) => seriesColor(index),
    ToneColor(tone: final t) => tone(t),
    ArgbColor(:final argb) => CategoryColors.accent(argb, brightness),
  };

  ChartPattern patternOfColor(ChartColor color) => color is ToneColor ? patternOf(color.tone) : ChartPattern.none;

  @override
  ChartTheme copyWith({List<Color>? series}) => ChartTheme(
    series: series ?? this.series,
    grid: grid,
    axis: axis,
    label: label,
    surface: surface,
    onSurface: onSurface,
    muted: muted,
    appColors: appColors,
    brightness: brightness,
    strokeWidth: strokeWidth,
    animationDuration: animationDuration,
  );

  @override
  ChartTheme lerp(ThemeExtension<ChartTheme>? other, double t) => t < 0.5 || other is! ChartTheme ? this : other;
}

/// Paints a pattern over [rect] (used by bars, calendar cells, streak frozen units).
void paintPattern(Canvas canvas, Rect rect, ChartPattern pattern, Color color) {
  if (pattern == ChartPattern.none || rect.isEmpty) return;
  final paint = Paint()
    ..color = color
    ..strokeWidth = 1;
  canvas
    ..save()
    ..clipRect(rect);
  switch (pattern) {
    case ChartPattern.diagonal:
      for (var x = rect.left - rect.height; x < rect.right; x += 5) {
        canvas.drawLine(Offset(x, rect.bottom), Offset(x + rect.height, rect.top), paint);
      }
    case ChartPattern.dots:
      for (var y = rect.top + 2; y < rect.bottom; y += 4) {
        for (var x = rect.left + 2; x < rect.right; x += 4) {
          canvas.drawCircle(Offset(x, y), 0.8, paint);
        }
      }
    case ChartPattern.crossHatch:
      for (var x = rect.left - rect.height; x < rect.right; x += 6) {
        canvas
          ..drawLine(Offset(x, rect.bottom), Offset(x + rect.height, rect.top), paint)
          ..drawLine(Offset(x, rect.top), Offset(x + rect.height, rect.bottom), paint);
      }
    case ChartPattern.none:
      break;
  }
  canvas.restore();
}

/// Readable text color on a filled cell.
Color onColor(Color background) => CategoryColors.onBackground(background);
