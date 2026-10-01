import 'package:everslot/design_system/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Density setting (comfortable | compact).
enum AppDensity { comfortable, compact }

/// Everslot themes (T1.3.08): Material 3 + Everslot tokens.
abstract final class AppTheme {
  static const seed = Color(0xFF3B5BDB);

  static ThemeData light({AppDensity density = AppDensity.comfortable, Color? seedOverride}) =>
      _build(Brightness.light, density, seedOverride);

  static ThemeData dark({AppDensity density = AppDensity.comfortable, Color? seedOverride}) =>
      _build(Brightness.dark, density, seedOverride);

  static ThemeData _build(Brightness brightness, AppDensity density, Color? seedOverride) {
    final scheme = ColorScheme.fromSeed(seedColor: seedOverride ?? seed, brightness: brightness);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      visualDensity: density == AppDensity.compact ? VisualDensity.compact : VisualDensity.standard,
      extensions: [brightness == Brightness.dark ? AppColors.dark : AppColors.light],
    );
    final textTheme = base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      listTileTheme: const ListTileThemeData(minVerticalPadding: Space.sm),
    );
  }

  /// Tabular figures for times/numbers so columns align (T1.3.09).
  static const tabular = [FontFeature.tabularFigures()];
}
