@Tags(['golden'])
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fonts.dart';

/// T1.3.08: the palette sheet — 16 category tiles (tile background, readable label, accent) and
/// every status color with its icon, in light and dark.
void main() {
  setUpAll(loadAppFonts);

  for (final dark in [false, true]) {
    testWidgets('golden palette sheet ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view
        ..physicalSize = const Size(420, 760)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: const Scaffold(body: _PaletteSheet()),
        ),
      );
      await expectLater(
        find.byType(_PaletteSheet),
        matchesGoldenFile('goldens/palette_${dark ? 'dark' : 'light'}.png'),
      );
    });
  }
}

class _PaletteSheet extends StatelessWidget {
  const _PaletteSheet();

  @override
  Widget build(BuildContext context) {
    final b = context.theme.brightness;
    final c = context.appColors;
    final statuses = <(String, Color, IconData)>[
      ('todo', c.todo, Icons.radio_button_unchecked),
      ('ongoing', c.ongoing, Icons.timelapse),
      ('waiting', c.waiting, Icons.hourglass_empty),
      ('blocked', c.blocked, Icons.block),
      ('completed', c.completed, Icons.check_circle),
      ('cancelled', c.cancelled, Icons.cancel_outlined),
      ('missed', c.missed, Icons.error_outline),
      ('skipped', c.skipped, Icons.redo),
    ];
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final (i, argb) in CategoryPalette.colors.indexed)
                Container(
                  width: 88,
                  height: 56,
                  padding: const EdgeInsets.all(Space.sm),
                  decoration: BoxDecoration(
                    color: CategoryColors.background(argb, b),
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: BorderDirectional(start: BorderSide(color: CategoryColors.accent(argb, b), width: 4)),
                  ),
                  child: Text(
                    'Cat ${i + 1}',
                    style: TextStyle(color: CategoryColors.onBackground(CategoryColors.background(argb, b))),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [for (final (label, color, icon) in statuses) StatusPill(label: label, color: color, icon: icon)],
          ),
        ],
      ),
    );
  }
}
