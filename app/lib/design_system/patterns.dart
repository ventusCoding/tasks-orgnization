import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/design_system/tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Texture drawn over category-colored surfaces so categories stay distinguishable without
/// color vision (T2.3.04 "color-blind-safe pattern option for the time grid").
enum CategoryPattern { diagonal, antiDiagonal, horizontal, vertical, dots, crossHatch, grid, zigzag }

/// The appearance setting `categoryPatterns` (off by default).
final categoryPatternsEnabledProvider = Provider<bool>((ref) {
  final appearance = ref.watch(settingsProvider(SettingsNs.appearance)).value ?? const {};
  return appearance['categoryPatterns'] == true;
});

/// A pattern + density per stored color: the 16 palette colors get 16 distinct textures
/// (8 patterns × sparse/dense, in palette order); custom colors get a stable hashed one.
abstract final class CategoryPatterns {
  static ({CategoryPattern pattern, bool dense}) forColor(int argb) {
    final index = CategoryPalette.colors.indexOf(argb);
    final i = index >= 0 ? index : (argb & 0x7FFFFFFF) % 16;
    const patterns = CategoryPattern.values;
    return (pattern: patterns[i % patterns.length], dense: i >= patterns.length);
  }
}

/// Paints a [CategoryPattern] in [color] (use a low-alpha foreground over the tile color).
class CategoryPatternPainter extends CustomPainter {
  const CategoryPatternPainter({
    required this.pattern,
    required this.color,
    this.dense = false,
    this.strokeWidth = 1.2,
  });

  /// Painter for a stored category color on [tile].
  factory CategoryPatternPainter.forCategory(int argb, Color tile) {
    final p = CategoryPatterns.forColor(argb);
    return CategoryPatternPainter(
      pattern: p.pattern,
      dense: p.dense,
      color: CategoryColors.onBackground(tile).withValues(alpha: 0.22),
    );
  }

  final CategoryPattern pattern;
  final Color color;
  final bool dense;
  final double strokeWidth;

  double get spacing => dense ? 6 : 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    final w = size.width;
    final h = size.height;
    final s = spacing;
    switch (pattern) {
      case CategoryPattern.diagonal:
        for (var x = -h; x < w; x += s) {
          canvas.drawLine(Offset(x, h), Offset(x + h, 0), paint);
        }
      case CategoryPattern.antiDiagonal:
        for (var x = 0.0; x < w + h; x += s) {
          canvas.drawLine(Offset(x, h), Offset(x - h, 0), paint);
        }
      case CategoryPattern.horizontal:
        for (var y = s / 2; y < h; y += s) {
          canvas.drawLine(Offset(0, y), Offset(w, y), paint);
        }
      case CategoryPattern.vertical:
        for (var x = s / 2; x < w; x += s) {
          canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
        }
      case CategoryPattern.dots:
        final fill = Paint()..color = color;
        for (var y = s / 2; y < h; y += s) {
          for (var x = s / 2; x < w; x += s) {
            canvas.drawCircle(Offset(x, y), strokeWidth, fill);
          }
        }
      case CategoryPattern.crossHatch:
        for (var x = -h; x < w; x += s) {
          canvas.drawLine(Offset(x, h), Offset(x + h, 0), paint);
        }
        for (var x = 0.0; x < w + h; x += s) {
          canvas.drawLine(Offset(x, h), Offset(x - h, 0), paint);
        }
      case CategoryPattern.grid:
        for (var y = s / 2; y < h; y += s) {
          canvas.drawLine(Offset(0, y), Offset(w, y), paint);
        }
        for (var x = s / 2; x < w; x += s) {
          canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
        }
      case CategoryPattern.zigzag:
        final amplitude = s / 3;
        for (var y = s / 2; y < h + s; y += s) {
          final path = Path()..moveTo(0, y);
          for (var x = 0.0; x < w; x += s / 2) {
            path.lineTo(x + s / 2, y + (((x / (s / 2)).round().isEven) ? -amplitude : amplitude));
          }
          canvas.drawPath(path, paint);
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CategoryPatternPainter old) =>
      old.pattern != pattern || old.color != color || old.dense != dense || old.strokeWidth != strokeWidth;
}
