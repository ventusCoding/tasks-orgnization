import 'package:everslot/features/notifications/application/in_app_banners.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/in_app_banner_host.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

void main() {
  late TestHarness h;
  late InAppBannerController banners;
  setUp(() {
    h = TestHarness.create();
    banners = h.read(inAppBannerControllerProvider);
  });
  tearDown(() => h.dispose());

  Future<void> pumpHost(WidgetTester tester, {bool reduceMotion = false}) =>
      pumpInApp(
        tester,
        h,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: const Scaffold(body: Stack(children: [InAppBannerHost()])),
          ),
        ),
      );

  void show(
    String key,
    String title, {
    String? body,
    List<String> actions = const [],
    String? link,
  }) => banners.show(
    BannerItem(
      key: key,
      title: title,
      body: body,
      actions: actions,
      link: link,
      section: NotificationSection.planner,
    ),
  );

  testWidgets(
    'one banner at a time; auto-dismissed after 5 s; announced to screen readers',
    (tester) async {
      await pumpHost(tester);
      show('a', 'Gym', body: 'Starts in 10 min');
      banners.flushNow();
      await tester.pumpAndSettle();
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Starts in 10 min'), findsOneWidget);
      expect(
        tester.takeAnnouncements().map((a) => a.message),
        contains('Gym. Starts in 10 min'),
      );

      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Gym'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Gym'), findsNothing);
    },
  );

  testWidgets('banners with actions stay 8 s', (tester) async {
    await pumpHost(tester);
    show('a', 'Push-ups', actions: const ['done', 'snooze']);
    banners.flushNow();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Done'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Push-ups'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Push-ups'), findsNothing);
  });

  testWidgets('a burst collapses into one banner; duplicates are ignored', (
    tester,
  ) async {
    await pumpHost(tester);
    show('a', 'Gym');
    show('b', 'Call Sam');
    show('c', 'Water');
    show('a', 'Gym');
    banners.flushNow();
    await tester.pumpAndSettle();
    expect(find.text('3 reminders'), findsOneWidget);
    expect(find.text('Gym, Call Sam, Water'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('close shows the next queued banner', (tester) async {
    await pumpHost(tester);
    show('a', 'Gym');
    banners.flushNow();
    await tester.pumpAndSettle();
    show('b', 'Water');
    banners.flushNow();
    await tester.pumpAndSettle();
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Water'), findsNothing);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Gym'), findsNothing);
    expect(find.text('Water'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'tapping a banner opens its link; reduce motion fades instead of sliding',
    (tester) async {
      final events = <NotificationUiEvent>[];
      final sub = h
          .read(notificationUiEventsProvider)
          .stream
          .listen(events.add);
      addTearDown(sub.cancel);
      await pumpHost(tester, reduceMotion: true);
      show('a', 'Weekly review', link: '/insights');
      banners.flushNow();
      await tester.pump();
      // Reduce motion: no slide-in, the switcher only fades.
      final switcher = tester.widget<AnimatedSwitcher>(
        find.descendant(
          of: find.byType(InAppBannerHost),
          matching: find.byType(AnimatedSwitcher),
        ),
      );
      final transition = switcher.transitionBuilder(
        const SizedBox(),
        const AlwaysStoppedAnimation(1),
      );
      expect(transition, isA<FadeTransition>());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weekly review'));
      await tester.pumpAndSettle();
      expect(events.whereType<OpenLinkEvent>().map((e) => e.link), [
        '/insights',
      ]);
      expect(find.text('Weekly review'), findsNothing);
    },
  );

  testWidgets(
    'on the target screen the banner is compact: no actions, gone after 3 s',
    (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/task/gym',
              routes: [
                GoRoute(
                  path: '/task/:id',
                  builder: (_, _) => const Scaffold(
                    body: Stack(
                      children: [Text('task page'), InAppBannerHost()],
                    ),
                  ),
                ),
              ],
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      show(
        'a',
        'Gym',
        body: 'Starts in 10 min',
        actions: const ['done', 'snooze'],
        link: '/task/gym?occ=2026-09-22T08%3A00',
      );
      banners.flushNow();
      await tester.pumpAndSettle();
      expect(find.text('Gym'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Gym'), findsNothing);
    },
  );

  testWidgets('haptic by importance: none for Gentle, stronger for high', (
    tester,
  ) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate')
          haptics.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpHost(tester);
    for (final (key, importance) in [
      ('low', NotificationImportance.low),
      ('normal', NotificationImportance.normal),
      ('high', NotificationImportance.high),
    ]) {
      banners.show(BannerItem(key: key, title: key, importance: importance));
      banners.flushNow();
      await tester.pumpAndSettle();
      banners.dismissCurrent();
      await tester.pumpAndSettle();
    }
    expect(haptics, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.mediumImpact',
    ]);
  });

  testWidgets(
    'with the keyboard up and a focused field at the top, the banner sits above the keyboard',
    (tester) async {
      await pumpInApp(
        tester,
        h,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
            // Like the app's root overlay: the host is outside any Scaffold (which would strip
            // the keyboard inset from its body).
            child: const Stack(
              children: [
                Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: SizedBox(
                      width: 200,
                      child: TextField(autofocus: true),
                    ),
                  ),
                ),
                InAppBannerHost(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      show('a', 'Gym');
      banners.flushNow();
      await tester.pumpAndSettle();
      final align = tester.widget<Align>(
        find
            .descendant(
              of: find.byType(InAppBannerHost),
              matching: find.byType(Align),
            )
            .first,
      );
      expect(align.alignment, AlignmentDirectional.bottomCenter);
      banners.dismissCurrent();
      await tester.pumpAndSettle();
    },
  );
}
