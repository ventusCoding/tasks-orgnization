import 'package:everslot/app/app.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/day_utils.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../auth/support/widget_helpers.dart';
import 'support/settings_app.dart';

void main() {
  group('root screen (T8.3.01)', () {
    testWidgets('lists every settings area and opens them', (tester) async {
      final h = TestHarness.create();
      await pumpSettingsApp(tester, h);
      await settle(tester);
      for (final title in [
        'Account',
        'Appearance',
        'Regional',
        'Accessibility',
        'Plan',
        'Lists',
        'Habits',
        'Insights',
        'Notifications',
        'Categories',
        'Tags',
        'Sync & data',
        'Privacy & security',
        'Trash',
        'About',
      ]) {
        await tester.scrollUntilVisible(find.text(title).first, 80, scrollable: find.byType(Scrollable).first);
        expect(find.text(title), findsWidgets, reason: title);
      }
      await tester.scrollUntilVisible(find.text('Appearance'), -80, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      expect(find.text('Theme'), findsOneWidget);
      await finish(tester, h);
    });

    testWidgets('local-only account row and unknown pages', (tester) async {
      final h = TestHarness.create();
      final router = await pumpSettingsApp(tester, h);
      await settle(tester);
      expect(find.text('On this device only'), findsOneWidget);
      router.go('/settings/nope');
      await tester.pumpAndSettle();
      expect(find.text("This settings page doesn't exist."), findsOneWidget);
      await finish(tester, h);
    });

    testWidgets('Arabic root renders right-to-left without overflow', (tester) async {
      final h = TestHarness.create();
      await pumpSettingsApp(tester, h, locale: const Locale('ar'));
      await settle(tester);
      expect(find.text('الإعدادات'), findsOneWidget);
      expect(Directionality.of(tester.element(find.text('الإعدادات'))), TextDirection.rtl);
      expect(tester.takeException(), isNull);
      await finish(tester, h);
    });
  });

  group('appearance & language (T8.3.02)', () {
    testWidgets('theme and density are saved; language goes to the profile', (tester) async {
      final h = TestHarness.create();
      await pumpSettingsApp(tester, h, initial: '/settings/appearance');
      await settle(tester);
      await tester.tap(find.text('Dark'));
      await settle(tester);
      await tester.tap(find.text('Compact'));
      await settle(tester);
      expect(h.read(appearanceSettingsProvider).theme, ThemePreference.dark);
      expect(h.read(appearanceSettingsProvider).density, DensityPreference.compact);

      await tester.tap(find.byKey(const ValueKey('appearance-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choice-fr')));
      await settle(tester);
      final profile = await tester.runAsync(() => h.read(profileRepositoryProvider).read());
      expect(profile!.locale, 'fr');
      await finish(tester, h);
    });

    testWidgets('the app switches theme, language and direction without restart', (tester) async {
      final h = TestHarness.create();
      await tester.pumpWidget(UncontrolledProviderScope(container: h.container, child: const EverslotApp()));
      await settle(tester);
      MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app().themeMode, ThemeMode.system);
      await tester.runAsync(() async {
        await h.read(settingsWriterProvider).update(AppearanceSettings.codec, (s) => s.copyWith(theme: ThemePreference.dark));
        await h.read(profileRepositoryProvider).update(locale: 'ar');
      });
      await settle(tester);
      expect(app().themeMode, ThemeMode.dark);
      expect(app().locale, const Locale('ar'));
      expect(Directionality.of(tester.element(find.byType(Navigator).first)), TextDirection.rtl);
      await tester.runAsync(() => h.read(profileRepositoryProvider).update(locale: null));
      await settle(tester);
      expect(app().locale, isNull, reason: 'back to the system language');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(h.dispose);
    });
  });

  group('regional (T8.3.03)', () {
    testWidgets('week start and currency pickers write the profile / settings', (tester) async {
      final h = TestHarness.create(zone: 'Africa/Tunis');
      await tester.runAsync(() => h.read(profileRepositoryProvider).update(homeTimeZone: 'Africa/Tunis', weekStart: 1));
      await pumpSettingsApp(tester, h, initial: '/settings/regional');
      await settle(tester);
      expect(find.text('Monday'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('regional-week-start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choice-6')));
      await settle(tester);
      expect((await tester.runAsync(() => h.read(profileRepositoryProvider).read()))!.weekStart, 6);
      expect(h.read(userPreferencesProvider).weekStart, Weekday.saturday);

      await tester.scrollUntilVisible(find.byKey(const ValueKey('regional-currency')), 80, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(const ValueKey('regional-currency')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choice-TND')));
      await settle(tester);
      expect(h.read(regionalSettingsProvider).currency, 'TND');
      expect(h.read(userPreferencesProvider).currency, 'TND');
      await finish(tester, h);
    });

    testWidgets('following the device makes the device zone home', (tester) async {
      final h = TestHarness.create(zone: 'Asia/Tokyo');
      await tester.runAsync(() => h.read(profileRepositoryProvider).update(homeTimeZone: 'Europe/Paris'));
      await pumpSettingsApp(tester, h, initial: '/settings/regional');
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('regional-home-auto')));
      await settle(tester);
      expect(h.read(regionalSettingsProvider).homeZoneAuto, isTrue);
      expect((await tester.runAsync(() => h.read(profileRepositoryProvider).read()))!.homeTimeZone, 'Asia/Tokyo');
      await finish(tester, h);
    });

    testWidgets('changing the day start only writes habits.dayStartMinutes', (tester) async {
      final h = TestHarness.create();
      await tester.runAsync(
        () => h.read(settingsWriterProvider).update(HabitsDefaults.codec, (s) => s.copyWith(dayStartMinutes: 240)),
      );
      await pumpSettingsApp(tester, h, initial: '/settings/regional');
      await settle(tester);
      expect(find.textContaining('04:00'), findsOneWidget);
      expect(h.read(userPreferencesProvider).dayStartMinutes, 240);
      await finish(tester, h);
    });

    test('week computations for each week start', () {
      final wed = LocalDate(2026, 9, 23); // a Wednesday
      expect(DayUtils.weekOf(wed, Weekday.monday).first, LocalDate(2026, 9, 21));
      expect(DayUtils.weekOf(wed, Weekday.saturday).first, LocalDate(2026, 9, 19));
      expect(DayUtils.weekOf(wed, Weekday.sunday).first, LocalDate(2026, 9, 20));
      for (final start in Weekday.values) {
        final week = DayUtils.weekOf(wed, start);
        expect(week, hasLength(7));
        expect(week.first.weekday, start);
        expect(week, contains(wed));
      }
    });
  });
}
