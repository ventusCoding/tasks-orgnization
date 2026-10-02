import 'package:everslot/core/env/env.dart';
import 'package:everslot/features/settings/application/export_service.dart' show appVersionLabelProvider;
import 'package:everslot/features/settings/application/review_service.dart';
import 'package:everslot/features/settings/domain/review_policy.dart';
import 'package:everslot/features/settings/presentation/pages/about_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

class FakeReviewPort implements ReviewPort {
  bool available = true;
  int requests = 0;
  int storeOpens = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requests++;

  @override
  Future<void> openStoreListing() async => storeOpens++;
}

const _env = Env(
  flavor: Flavor.dev,
  supabaseUrl: '',
  supabasePublishableKey: '',
  firebaseEnabled: false,
  featureFlags: {},
  siteUrl: 'https://everslot.example',
  supportEmail: 'help@everslot.example',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('review prompt throttling: at most one automatic prompt per 90 days', () {
    final t0 = DateTime.utc(2026, 10, 1);
    expect(ReviewPolicy.canAutoPrompt(now: t0, lastPromptAt: null), isTrue);
    expect(ReviewPolicy.canAutoPrompt(now: t0.add(const Duration(days: 89)), lastPromptAt: t0), isFalse);
    expect(ReviewPolicy.canAutoPrompt(now: t0.add(const Duration(days: 90)), lastPromptAt: t0), isTrue);
  });

  test('ReviewService: automatic prompts are throttled; Rate falls back to the store page', () async {
    final port = FakeReviewPort();
    final h = TestHarness.create(overrides: [reviewPortProvider.overrideWithValue(port)]);
    addTearDown(h.dispose);
    final service = h.read(reviewServiceProvider);
    expect(await service.maybeAutoPrompt(), isTrue);
    h.clock.advance(const Duration(days: 30));
    expect(await service.maybeAutoPrompt(), isFalse);
    expect(port.requests, 1);

    await service.rateFromSettings();
    expect(port.storeOpens, 1, reason: 'the OS would ignore a second sheet so soon');

    h.clock.advance(const Duration(days: 61));
    expect(await service.maybeAutoPrompt(), isTrue);
    expect(port.requests, 2);

    port.available = false;
    h.clock.advance(const Duration(days: 365));
    expect(await service.maybeAutoPrompt(), isFalse);
    await service.rateFromSettings();
    expect(port.storeOpens, 2);
  });

  group('About page (T8.3.13)', () {
    Future<(TestHarness, List<Uri>, FakeReviewPort)> pump(WidgetTester tester, {Env env = _env}) async {
      final opened = <Uri>[];
      final port = FakeReviewPort();
      final h = TestHarness.create(
        env: env,
        overrides: [
          appVersionLabelProvider.overrideWithValue(() async => '1.4.0+42'),
          externalLinkLauncherProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return true;
          }),
          reviewPortProvider.overrideWithValue(port),
        ],
      );
      await pumpInApp(tester, h, const AboutPage());
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      return (h, opened, port);
    }

    Future<void> done(WidgetTester tester, TestHarness h) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(h.dispose);
    }

    testWidgets('version, legal links, disclaimer, support, licenses and rating', (tester) async {
      final (h, opened, port) = await pump(tester);
      expect(find.text('Version 1.4.0+42'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('about-privacy')));
      await tester.tap(find.byKey(const ValueKey('about-terms')));
      expect(opened, [Uri.parse('https://everslot.example/privacy'), Uri.parse('https://everslot.example/terms')]);

      await tester.tap(find.byKey(const ValueKey('about-health')));
      await tester.pumpAndSettle();
      expect(find.textContaining('not medical advice'), findsOneWidget);

      await tester.scrollUntilVisible(find.byKey(const ValueKey('about-support')), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('about-support')));
      expect(opened.last, Uri(scheme: 'mailto', path: 'help@everslot.example'));

      await tester.scrollUntilVisible(find.byKey(const ValueKey('about-rate')), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('about-rate')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(port.requests, 1);

      await tester.scrollUntilVisible(find.byKey(const ValueKey('about-licenses')), -100);
      await tester.tap(find.byKey(const ValueKey('about-licenses')));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
      await done(tester, h);
    });

    testWidgets('placeholder site settings hide the legal links', (tester) async {
      const placeholder = Env(
        flavor: Flavor.dev,
        supabaseUrl: '',
        supabasePublishableKey: '',
        firebaseEnabled: false,
        featureFlags: {},
        siteUrl: 'https://YOUR_SITE_DOMAIN',
        supportEmail: 'support@YOUR_SITE_DOMAIN',
      );
      final (h, _, _) = await pump(tester, env: placeholder);
      expect(find.byKey(const ValueKey('about-privacy')), findsNothing);
      expect(find.byKey(const ValueKey('about-support')), findsNothing);
      expect(find.byKey(const ValueKey('about-licenses')), findsOneWidget);
      await done(tester, h);
    });
  });
}
