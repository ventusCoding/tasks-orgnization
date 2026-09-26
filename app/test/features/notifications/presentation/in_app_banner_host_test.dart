import 'package:everslot/features/notifications/application/in_app_banners.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/in_app_banner_host.dart';
import 'package:flutter_test/flutter_test.dart';
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
      // Reduce motion: no slide-in, the switcher only fades (instantly).
      final switcher = tester.widget<AnimatedSwitcher>(
        find.descendant(
          of: find.byType(InAppBannerHost),
          matching: find.byType(AnimatedSwitcher),
        ),
      );
      expect(switcher.duration, Duration.zero);
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
}
