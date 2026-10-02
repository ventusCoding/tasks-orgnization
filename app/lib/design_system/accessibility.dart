import 'package:material_ui/material_ui.dart';

/// In-app accessibility options (T8.3.12) carried by the theme so every widget reads them the
/// same way: `context.a11y`. Reduce motion and haptics have their own channels
/// (`ReduceMotionScope`, `Haptics`).
@immutable
class AccessibilityPrefs extends ThemeExtension<AccessibilityPrefs> {
  const AccessibilityPrefs({
    this.highContrastCategories = false,
    this.largeWeekTableText = false,
    this.statusPillLabels = false,
  });

  static const defaults = AccessibilityPrefs();

  /// Stronger category tiles and accents (≥ 4.5:1 text, ≥ 3:1 accents).
  final bool highContrastCategories;

  /// Bigger text in week / day table tiles.
  final bool largeWeekTableText;

  /// Status words next to icon-only status marks (week tiles, completed list items).
  final bool statusPillLabels;

  /// Extra points added to the table tiles' font size.
  double get tileTextBoost => largeWeekTableText ? 2 : 0;

  @override
  AccessibilityPrefs copyWith({bool? highContrastCategories, bool? largeWeekTableText, bool? statusPillLabels}) =>
      AccessibilityPrefs(
        highContrastCategories: highContrastCategories ?? this.highContrastCategories,
        largeWeekTableText: largeWeekTableText ?? this.largeWeekTableText,
        statusPillLabels: statusPillLabels ?? this.statusPillLabels,
      );

  @override
  AccessibilityPrefs lerp(ThemeExtension<AccessibilityPrefs>? other, double t) =>
      other is AccessibilityPrefs && t >= 0.5 ? other : this;

  /// [theme] carrying these options.
  ThemeData applyTo(ThemeData theme) => theme.copyWith(
    extensions: [
      for (final e in theme.extensions.values)
        if (e is! AccessibilityPrefs) e,
      this,
    ],
  );

  @override
  bool operator ==(Object other) =>
      other is AccessibilityPrefs &&
      other.highContrastCategories == highContrastCategories &&
      other.largeWeekTableText == largeWeekTableText &&
      other.statusPillLabels == statusPillLabels;

  @override
  int get hashCode => Object.hash(highContrastCategories, largeWeekTableText, statusPillLabels);
}

extension AccessibilityX on BuildContext {
  AccessibilityPrefs get a11y => Theme.of(this).extension<AccessibilityPrefs>() ?? AccessibilityPrefs.defaults;
}
