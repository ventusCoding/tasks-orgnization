import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Everslot typography (T1.3.09): bundled Inter for Latin scripts, Noto Sans Arabic picked
/// automatically for Arabic glyphs (font fallback), tabular figures for times and numbers.
abstract final class AppTypography {
  static const latin = 'Inter';
  static const arabic = 'NotoSansArabic';

  /// Glyphs missing from [latin] (Arabic script) come from these families, in order.
  static const fallback = [arabic];

  /// Aligned digits for times, durations and counters (columns line up).
  static const tabularFigures = [FontFeature.tabularFigures()];

  static TextStyle? tabular(TextStyle? style) => style?.copyWith(fontFeatures: tabularFigures);

  /// The Material 3 type scale (display → label) on the bundled families.
  static TextTheme apply(TextTheme base) => base.apply(fontFamily: latin, fontFamilyFallback: fallback);

  static bool _licensesRegistered = false;

  /// Adds the fonts' OFL texts to the licenses page (About › Licenses). Idempotent.
  static void registerLicenses() {
    if (_licensesRegistered) return;
    _licensesRegistered = true;
    LicenseRegistry.addLicense(() async* {
      for (final (family, path) in const [
        ('Inter', 'assets/fonts/inter/OFL.txt'),
        ('Noto Sans Arabic', 'assets/fonts/noto_sans_arabic/OFL.txt'),
      ]) {
        yield LicenseEntryWithLineBreaks([family], await rootBundle.loadString(path));
      }
    });
  }
}
