import 'package:everslot/design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Color & icon system (T2.3.04, T2.3.03): every palette entry and priority is legible on its
/// tiles and on the app surfaces, in both themes.
void main() {
  final themes = {
    Brightness.light: AppTheme.light(),
    Brightness.dark: AppTheme.dark(),
  };

  double contrast(Color a, Color b) => CategoryColors.contrastRatio(a, b);

  test('palette has 16 distinct colors', () {
    expect(CategoryPalette.colors, hasLength(16));
    expect(CategoryPalette.colors.toSet(), hasLength(16));
    expect(CategoryPalette.at(16), CategoryPalette.colors.first);
  });

  for (final entry in themes.entries) {
    final brightness = entry.key;
    final scheme = entry.value.colorScheme;

    test('tile text is ≥ 4.5:1 on every palette tile ($brightness)', () {
      for (final argb in CategoryPalette.colors) {
        final tile = CategoryColors.background(argb, brightness);
        final text = CategoryColors.onBackground(tile);
        expect(
          contrast(text, tile),
          greaterThanOrEqualTo(4.5),
          reason:
              '0x${argb.toRadixString(16)} tile ${tile.toARGB32().toRadixString(16)}',
        );
      }
    });

    test(
      'readable text variant of any palette color is ≥ 4.5:1 ($brightness)',
      () {
        for (final argb in CategoryPalette.colors) {
          for (final surface in [scheme.surface, scheme.surfaceContainerLow]) {
            final text = CategoryColors.readableOn(Color(argb), surface);
            expect(contrast(text, surface), greaterThanOrEqualTo(4.5));
          }
        }
      },
    );

    test('priority labels and flags are ≥ 4.5:1 on surfaces ($brightness)', () {
      for (var p = 0; p <= 4; p++) {
        for (final surface in [scheme.surface, scheme.surfaceContainerLow]) {
          final fg = PriorityStyle.foreground(p, surface);
          expect(
            contrast(fg, surface),
            greaterThanOrEqualTo(4.5),
            reason: 'priority $p',
          );
        }
      }
    });
  }

  test('readableOn keeps a color that already contrasts and moves others minimally', () {
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    const navy = Color(0xFF1E3A8A);
    expect(CategoryColors.readableOn(navy, white), navy);
    final amber = CategoryColors.readableOn(const Color(0xFFF59E0B), white);
    expect(contrast(amber, white), greaterThanOrEqualTo(4.5));
    expect(
      contrast(amber, white),
      lessThan(6),
      reason: 'darkened only as needed',
    );
    final onDark = CategoryColors.readableOn(navy, black);
    expect(contrast(onDark, black), greaterThanOrEqualTo(4.5));
  });

  test('icon catalog keys are unique and searchable in EN, FR and AR', () {
    final keys = IconCatalog.all.map((i) => i.key).toList();
    expect(keys.toSet(), hasLength(keys.length));
    expect(IconCatalog.search('gym').map((i) => i.key), contains('fitness'));
    expect(IconCatalog.search('Travail').map((i) => i.key), contains('work'));
    expect(IconCatalog.search('نوم').map((i) => i.key), contains('sleep'));
    expect(IconCatalog.search(''), hasLength(IconCatalog.all.length));
    expect(IconCatalog.iconFor('missing'), Icons.label_outline);
  });
}
