import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/task_tile.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/features/settings/presentation/pages/accessibility_page.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../today/today_test_support.dart';

void main() {
  group('high-contrast category palette (T8.3.12)', () {
    test('accents reach 4.5:1 on the surface; tiles keep more hue', () {
      for (final b in Brightness.values) {
        final surface = b == Brightness.dark ? const Color(0xFF121212) : Colors.white;
        for (final argb in CategoryPalette.colors) {
          final hc = CategoryColors.accent(argb, b, highContrast: true);
          expect(CategoryColors.contrastRatio(hc, surface), greaterThanOrEqualTo(4.5), reason: '$argb $b');
          final bg = CategoryColors.background(argb, b, highContrast: true);
          expect(CategoryColors.contrastRatio(CategoryColors.onBackground(bg), bg), greaterThanOrEqualTo(4.5));
        }
      }
      final soft = CategoryColors.background(CategoryPalette.colors.first, Brightness.light);
      final strong = CategoryColors.background(CategoryPalette.colors.first, Brightness.light, highContrast: true);
      expect(strong.computeLuminance(), lessThan(soft.computeLuminance()));
    });
  });

  group('options travel through the theme', () {
    Widget tileApp(AccessibilityPrefs prefs, {OccurrenceStatus status = OccurrenceStatus.done}) => MaterialApp(
      theme: prefs.applyTo(AppTheme.light()),
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 140,
            height: 90,
            child: TaskTile(
              item: occ('Standup', start: at(2026, 9, 22, 9), status: status),
              colors: const TileColors(Colors.white, Colors.blue, Colors.black),
              timeText: '09:00',
              semanticsLabel: 'Standup',
            ),
          ),
        ),
      ),
    );

    double titleSize(WidgetTester tester) => tester.widget<Text>(find.text('Standup')).style!.fontSize!;

    testWidgets('larger week-table text and status words', (tester) async {
      await tester.pumpWidget(tileApp(AccessibilityPrefs.defaults));
      final normal = titleSize(tester);
      expect(find.byKey(const ValueKey('tile-status-label')), findsNothing);

      await tester.pumpWidget(tileApp(const AccessibilityPrefs(largeWeekTableText: true, statusPillLabels: true)));
      await tester.pumpAndSettle();
      expect(titleSize(tester), normal + 2);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('a scheduled tile never gets a status word', (tester) async {
      await tester.pumpWidget(
        tileApp(const AccessibilityPrefs(statusPillLabels: true), status: OccurrenceStatus.scheduled),
      );
      expect(find.byKey(const ValueKey('tile-status-label')), findsNothing);
    });

    test('applyTo replaces an earlier value and keeps the other extensions', () {
      final theme = const AccessibilityPrefs(statusPillLabels: true)
          .applyTo(const AccessibilityPrefs(largeWeekTableText: true).applyTo(AppTheme.light()));
      expect(theme.extension<AccessibilityPrefs>(), const AccessibilityPrefs(statusPillLabels: true));
      expect(theme.extension<AppColors>(), isNotNull);
    });
  });

  testWidgets('Settings › Accessibility writes the appearance namespace', (tester) async {
    final h = TestHarness.create();
    await pumpInApp(tester, h, const AccessibilityPage());
    await settle(tester);
    for (final key in ['a11y-high-contrast', 'a11y-large-table', 'a11y-status-labels', 'a11y-reduce-motion']) {
      await tester.ensureVisible(find.byKey(ValueKey(key)));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey(key)));
      await settle(tester, rounds: 10);
    }
    final s = h.read(appearanceSettingsProvider);
    expect(
      (s.highContrastCategories, s.largeWeekTableText, s.statusPillLabels, s.reduceMotion),
      (true, true, true, true),
    );
    final raw = await tester.runAsync(() => h.read(settingsRepositoryProvider).read(SettingsNs.appearance));
    expect(raw, containsPair('statusPillLabels', true));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(h.dispose);
  });
}
