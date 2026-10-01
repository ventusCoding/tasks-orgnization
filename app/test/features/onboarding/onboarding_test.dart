import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/onboarding/application/onboarding_controller.dart';
import 'package:everslot/features/onboarding/presentation/onboarding_screen.dart';
import 'package:everslot/features/profile/application/device_locale.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/profile/domain/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../auth/support/widget_helpers.dart';

TestHarness _harness({Locale locale = const Locale('en', 'US'), bool device24h = false}) => TestHarness.create(
  zone: 'America/New_York',
  overrides: [deviceLocaleProvider.overrideWithValue(locale), device24hProvider.overrideWithValue(device24h)],
);

Future<void> _waitDraft(TestHarness h) async {
  final sub = h.container.listen(onboardingControllerProvider, (_, _) {});
  for (var i = 0; i < 20 && h.read(onboardingControllerProvider).draft == null; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  addTearDown(sub.close);
}

void main() {
  group('first-run defaults (T1.5.05)', () {
    test('a fresh profile gets the device zone and the locale conventions', () async {
      final h = _harness();
      addTearDown(h.dispose);
      await h.read(profileRepositoryProvider).update(homeTimeZone: 'UTC');
      await _waitDraft(h);
      final draft = h.read(onboardingControllerProvider).draft!;
      expect(draft.zone, 'America/New_York');
      expect(draft.weekStart, 7);
      expect(draft.use24h, isFalse);
    });

    test('French (France) → Monday and 24 h; Arabic (Egypt) → Saturday', () async {
      final fr = _harness(locale: const Locale('fr', 'FR'));
      addTearDown(fr.dispose);
      await _waitDraft(fr);
      expect(fr.read(onboardingControllerProvider).draft!.weekStart, 1);
      expect(fr.read(onboardingControllerProvider).draft!.use24h, isTrue);
      final ar = _harness(locale: const Locale('ar', 'EG'), device24h: true);
      addTearDown(ar.dispose);
      await _waitDraft(ar);
      expect(ar.read(onboardingControllerProvider).draft!.weekStart, 6);
      expect(ar.read(onboardingControllerProvider).draft!.use24h, isTrue, reason: 'device switch wins');
    });

    test('finishing writes the essentials and completes onboarding', () async {
      final h = _harness();
      addTearDown(h.dispose);
      await _waitDraft(h);
      final c = h.read(onboardingControllerProvider.notifier)
        ..setZone('Africa/Tunis')
        ..setWeekStart(1)
        ..setUse24h(true);
      await c.finish();
      final p = (await h.read(profileRepositoryProvider).read())!;
      expect(p.homeTimeZone, 'Africa/Tunis');
      expect(p.currentTimeZone, 'America/New_York');
      expect(p.weekStart, 1);
      expect(p.timeFormat, TimeFormat.h24);
      expect(p.onboardingCompletedAt, h.clock.nowUtc());
      expect(h.read(onboardingControllerProvider).done, isTrue);
    });

    test('a profile finished on another device skips onboarding and keeps its values', () async {
      final h = _harness();
      addTearDown(h.dispose);
      await h
          .read(profileRepositoryProvider)
          .update(
            homeTimeZone: 'Europe/Paris',
            weekStart: 1,
            timeFormat: TimeFormat.h24,
            onboardingCompletedAt: DateTime.utc(2026, 9, 1),
          );
      final sub = h.container.listen(needsOnboardingProvider, (_, _) {});
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.read(needsOnboardingProvider), isFalse);
      await _waitDraft(h);
      expect(
        h.read(onboardingControllerProvider).draft,
        const EssentialsDraft(zone: 'Europe/Paris', weekStart: 1, use24h: true),
      );
    });

    test('a profile without completion needs onboarding', () async {
      final h = _harness();
      addTearDown(h.dispose);
      await h.read(profileRepositoryProvider).update(homeTimeZone: 'Europe/Paris');
      final sub = h.container.listen(needsOnboardingProvider, (_, _) {});
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.read(needsOnboardingProvider), isTrue);
    });
  });

  testWidgets('confirmation screen: change the week start, then get started', (tester) async {
    final h = _harness();
    await tester.runAsync(() => h.read(profileRepositoryProvider).update(homeTimeZone: 'UTC'));
    await pumpInApp(tester, h, const OnboardingScreen());
    await settle(tester);
    expect(find.text('Your week, your clock'), findsOneWidget);
    expect(find.text('Sunday'), findsOneWidget);
    expect(find.textContaining('New York'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-week-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choice-1')));
    await tester.pumpAndSettle();
    expect(find.text('Monday'), findsOneWidget);

    await tester.ensureVisible(find.text('24-hour\n13:30'));
    await tester.pump();
    await tester.tap(find.text('24-hour\n13:30'));
    await tester.pump();
    expect(h.read(onboardingControllerProvider).draft!.use24h, isTrue);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await settle(tester);
    expect(h.read(onboardingControllerProvider).done, isTrue);
    final p = (await tester.runAsync(() => h.read(profileRepositoryProvider).read()))!;
    expect(p.weekStart, 1);
    expect(p.use24h, isTrue);
    expect(p.onboardingDone, isTrue);
    await finish(tester, h);
  });

  testWidgets('Arabic layout renders without overflow', (tester) async {
    final h = _harness(locale: const Locale('ar', 'TN'));
    await pumpInApp(tester, h, const OnboardingScreen(), locale: const Locale('ar'));
    await settle(tester);
    expect(find.text('أسبوعك وساعتك'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester, h);
  });

  test('ProviderContainer keeps the controller consistent across profile updates', () async {
    final h = _harness();
    addTearDown(h.dispose);
    await _waitDraft(h);
    h.read(onboardingControllerProvider.notifier).setWeekStart(3);
    await h.read(profileRepositoryProvider).update(displayName: 'Z');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.read(onboardingControllerProvider).draft!.weekStart, 3, reason: 'edits are not reset');
    expect(h.container, isA<ProviderContainer>());
  });
}
