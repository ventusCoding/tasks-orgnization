import 'package:material_ui/material_ui.dart';

/// Spacing scale (4-pt grid).
abstract final class Space {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

abstract final class Radii {
  static const sm = 6.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 360);
  static const curve = Curves.easeOutCubic;
}

/// Elevation levels (dp) for surfaces that are not Material components (drag ghosts, bubbles).
abstract final class Elevation {
  static const none = 0.0;
  static const low = 1.0;
  static const mid = 3.0;
  static const high = 6.0;
  static const overlay = 12.0;
}

/// Opacity steps (disabled content, scrims, hover/drag tints).
abstract final class Opacities {
  static const disabled = 0.38;
  static const muted = 0.6;
  static const scrim = 0.32;
  static const hover = 0.08;
  static const pressed = 0.12;
  static const dragged = 0.16;
}

/// Shadows of floating, non-Material surfaces (dragged tiles, tooltips drawn on the grid).
abstract final class AppShadows {
  static const lifted = [BoxShadow(blurRadius: 8, offset: Offset(0, 3), color: Color(0x33000000))];
  static const floating = [BoxShadow(blurRadius: 10, offset: Offset(0, 4), color: Color(0x40000000))];
  static const soft = [BoxShadow(blurRadius: 6, color: Color(0x33000000))];
}

/// Brand / tooling colors that are not part of the color scheme.
abstract final class BrandColors {
  /// The "DEV" corner banner of the dev flavor (T1.1.10).
  static const devBanner = Color(0xFFFF6B00);
}

/// Data-visualization palettes (T6.2): Okabe–Ito categorical series (color-blind safe) and the
/// semantic tones that have no status color.
abstract final class DataVizColors {
  /// Tuned for contrast on light surfaces.
  static const seriesLight = <Color>[
    Color(0xFF0072B2), // blue
    Color(0xFFD55E00), // vermillion
    Color(0xFF009E73), // bluish green
    Color(0xFFCC79A7), // reddish purple
    Color(0xFFB8860B), // dark yellow (orange-ish, ≥ 3:1 on white)
    Color(0xFF56B4E9), // sky blue
    Color(0xFF6B4E00), // brown
    Color(0xFF444444), // neutral
  ];

  /// Lightened for dark surfaces.
  static const seriesDark = <Color>[
    Color(0xFF56B4E9),
    Color(0xFFFF8A4C),
    Color(0xFF3CCFA0),
    Color(0xFFE4A3C8),
    Color(0xFFF0E442),
    Color(0xFF9FD7F5),
    Color(0xFFE69F00),
    Color(0xFFBBBBBB),
  ];

  static Color late(bool dark) => dark ? const Color(0xFF9BD67F) : const Color(0xFF4D7C0F);
  static Color partial(bool dark) => dark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1);
  static Color excused(bool dark) => dark ? const Color(0xFFA5B4FC) : const Color(0xFF6366F1);
  static Color paused(bool dark) => dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color frozen(bool dark) => dark ? const Color(0xFF67E8F9) : const Color(0xFF0891B2);
}

/// 16-color category palette (T1.3.08 / T2.3.04), ordered for color-blind distinguishability.
/// Stored as ARGB ints; light/dark variants are derived in [CategoryColors].
abstract final class CategoryPalette {
  static const colors = <int>[
    0xFF3B82F6, // blue
    0xFFEF4444, // red
    0xFF10B981, // emerald
    0xFFF59E0B, // amber
    0xFF8B5CF6, // violet
    0xFF06B6D4, // cyan
    0xFFEC4899, // pink
    0xFF84CC16, // lime
    0xFFF97316, // orange
    0xFF6366F1, // indigo
    0xFF14B8A6, // teal
    0xFFA855F7, // purple
    0xFF64748B, // slate
    0xFFE11D48, // rose
    0xFF0EA5E9, // sky
    0xFFA16207, // brown
  ];

  static int at(int index) => colors[index % colors.length];
}

/// Readable variants of a stored category color for the current theme.
abstract final class CategoryColors {
  /// Tile background for a category color.
  static Color background(int argb, Brightness brightness) {
    final base = Color(argb);
    return brightness == Brightness.dark
        ? Color.lerp(base, Colors.black, 0.45)!
        : Color.lerp(base, Colors.white, 0.78)!;
  }

  /// Strong accent (bars, dots, borders).
  static Color accent(int argb, Brightness brightness) {
    final base = Color(argb);
    return brightness == Brightness.dark ? Color.lerp(base, Colors.white, 0.15)! : base;
  }

  /// Foreground text color with ≥ 4.5:1 contrast on [background].
  static Color onBackground(Color background) =>
      contrastRatio(background, Colors.black) >= contrastRatio(background, Colors.white)
      ? const Color(0xFF111827)
      : Colors.white;

  /// [color] itself when it already reaches [minContrast] against [background], otherwise the
  /// closest darker (light backgrounds) or lighter (dark backgrounds) shade that does — for text
  /// and icons drawn in a user/priority color (T2.3.04, WCAG 1.4.3).
  static Color readableOn(Color color, Color background, {double minContrast = 4.5}) {
    if (contrastRatio(color, background) >= minContrast) return color;
    final towards = background.computeLuminance() > 0.18 ? Colors.black : Colors.white;
    var lo = 0.0;
    var hi = 1.0;
    for (var i = 0; i < 24; i++) {
      final mid = (lo + hi) / 2;
      if (contrastRatio(Color.lerp(color, towards, mid)!, background) >= minContrast) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return Color.lerp(color, towards, hi)!;
  }

  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }
}

/// Semantic colors not covered by the Material color scheme.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.todo,
    required this.ongoing,
    required this.waiting,
    required this.blocked,
    required this.completed,
    required this.cancelled,
    required this.missed,
    required this.skipped,
    required this.nowLine,
    required this.gridMajor,
    required this.gridMinor,
    required this.offHours,
    required this.today,
  });

  static const light = AppColors(
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    danger: Color(0xFFB91C1C),
    info: Color(0xFF1D4ED8),
    todo: Color(0xFF6B7280),
    ongoing: Color(0xFF2563EB),
    waiting: Color(0xFFB45309),
    blocked: Color(0xFFB91C1C),
    completed: Color(0xFF15803D),
    // Muted greys still reach 3:1 on surfaces (WCAG 1.4.11; status icons carry the meaning).
    cancelled: Color(0xFF858C99),
    missed: Color(0xFFDC2626),
    skipped: Color(0xFF858C99),
    nowLine: Color(0xFFE11D48),
    gridMajor: Color(0x1F000000),
    gridMinor: Color(0x0D000000),
    offHours: Color(0x08000000),
    today: Color(0x0F3B82F6),
  );

  static const dark = AppColors(
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
    todo: Color(0xFF9CA3AF),
    ongoing: Color(0xFF60A5FA),
    waiting: Color(0xFFFBBF24),
    blocked: Color(0xFFF87171),
    completed: Color(0xFF4ADE80),
    cancelled: Color(0xFF6B7280),
    missed: Color(0xFFF87171),
    skipped: Color(0xFF6B7280),
    nowLine: Color(0xFFFB7185),
    gridMajor: Color(0x29FFFFFF),
    gridMinor: Color(0x12FFFFFF),
    offHours: Color(0x0AFFFFFF),
    today: Color(0x1A60A5FA),
  );

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color todo;
  final Color ongoing;
  final Color waiting;
  final Color blocked;
  final Color completed;
  final Color cancelled;
  final Color missed;
  final Color skipped;
  final Color nowLine;
  final Color gridMajor;
  final Color gridMinor;
  final Color offHours;
  final Color today;

  @override
  AppColors copyWith({Color? success}) => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      info: l(info, other.info),
      todo: l(todo, other.todo),
      ongoing: l(ongoing, other.ongoing),
      waiting: l(waiting, other.waiting),
      blocked: l(blocked, other.blocked),
      completed: l(completed, other.completed),
      cancelled: l(cancelled, other.cancelled),
      missed: l(missed, other.missed),
      skipped: l(skipped, other.skipped),
      nowLine: l(nowLine, other.nowLine),
      gridMajor: l(gridMajor, other.gridMajor),
      gridMinor: l(gridMinor, other.gridMinor),
      offHours: l(offHours, other.offHours),
      today: l(today, other.today),
    );
  }
}

extension AppThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;
}
