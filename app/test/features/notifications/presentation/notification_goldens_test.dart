// Goldens of the notification UI: the editor section (T7.1.09) and the inbox (T7.3.03) in
// light/dark × LTR/RTL, the permission recovery banner and primer in Arabic (T7.2.05).
// Regenerate with `--update-goldens`.
@Tags(['golden'])
library;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart'
    show seedNotificationDefaults;
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/inbox_screen.dart';
import 'package:everslot/features/notifications/presentation/notification_settings_section.dart';
import 'package:everslot/features/notifications/presentation/permission_primers.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

void main() {
  late TestHarness h;
  final now = DateTime.utc(2026, 9, 22, 9);
  setUp(() => h = TestHarness.create(now: now));
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// 360 × 780 logical pixels at DPR 1, app theme, the given locale / brightness.
  Future<void> pumpApp(
    WidgetTester tester, {
    required bool dark,
    required Locale locale,
    Widget? home,
    GoRouter? router,
  }) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const delegates = [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ];
    const locales = [Locale('en'), Locale('fr'), Locale('ar')];
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: router != null
            ? MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: router,
                locale: locale,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                supportedLocales: locales,
                localizationsDelegates: delegates,
              )
            : MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: locale,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                supportedLocales: locales,
                localizationsDelegates: delegates,
                home: home,
              ),
      ),
    );
    await settle(tester);
  }

  Future<void> seedTask(WidgetTester tester) => tester.runAsync(() async {
    await seedNotificationDefaults(h.read);
    await h
        .read(syncWriterProvider)
        .run(
          (tx) => tx.insert('tasks', 't1', {
            'series_id': 't1',
            'title': 'Gym',
            'notify_mode': 'inherit',
          }),
        );
  });

  Future<void> seedInbox(WidgetTester tester) => tester.runAsync(() async {
    final inbox = h.read(inboxRepositoryProvider);
    Future<void> put(
      String dk,
      String title,
      String body,
      Duration ago, {
      NotificationSection section = NotificationSection.planner,
      InboxCategory category = InboxCategory.reminder,
      bool late = false,
    }) => inbox.upsertDelivered(
      InboxDelivery(
        dedupeKey: dk,
        category: category,
        title: title,
        body: body,
        fireAt: now.subtract(ago),
        section: section,
        sourceType: 'task',
        sourceId: dk,
        payload: {
          'v': 1,
          'dk': dk,
          'acts': ['done', 'snooze'],
        },
        late: late,
      ),
    );
    await put(
      'gym',
      'Gym',
      'Starts in 10 min · 09:10–10:10',
      const Duration(minutes: 5),
    );
    await put(
      'plants',
      'Water the plants',
      'Home › Garden',
      const Duration(hours: 2),
      section: NotificationSection.checklists,
      late: true,
    );
    await put(
      'read',
      'Keep your 12-day streak alive',
      'Read 20 pages',
      const Duration(days: 1, hours: 2),
      section: NotificationSection.habits,
      category: InboxCategory.streak,
    );
    await inbox.markRead([
      ...(await inbox.inbox()).where((i) => i.title == 'Gym').map((i) => i.id),
    ]);
  });

  for (final dark in [false, true]) {
    for (final rtl in [false, true]) {
      final name = '${dark ? 'dark' : 'light'}_${rtl ? 'rtl' : 'ltr'}';
      final locale = rtl ? const Locale('ar') : const Locale('en');

      testWidgets('notification section golden $name', (tester) async {
        await seedTask(tester);
        await pumpApp(
          tester,
          dark: dark,
          locale: locale,
          home: Scaffold(
            body: ListView(
              children: const [
                NotificationSettingsSection(
                  targetType: NotificationTargetType.task,
                  targetId: 't1',
                  section: NotificationSection.planner,
                ),
              ],
            ),
          ),
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/notification_section_$name.png'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('inbox golden $name', (tester) async {
        await seedInbox(tester);
        await pumpApp(
          tester,
          dark: dark,
          locale: locale,
          router: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const InboxScreen()),
            ],
          ),
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/inbox_$name.png'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  group('text scale 2.0 does not overflow', () {
    Widget scaled(Widget child) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child,
      ),
    );

    for (final rtl in [false, true]) {
      final locale = rtl ? const Locale('ar') : const Locale('en');
      testWidgets('notification section (${locale.languageCode})', (
        tester,
      ) async {
        await seedTask(tester);
        await pumpApp(
          tester,
          dark: false,
          locale: locale,
          home: scaled(
            Scaffold(
              body: ListView(
                children: const [
                  NotificationSettingsSection(
                    targetType: NotificationTargetType.task,
                    targetId: 't1',
                    section: NotificationSection.planner,
                  ),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('inbox (${locale.languageCode})', (tester) async {
        await seedInbox(tester);
        await pumpApp(
          tester,
          dark: false,
          locale: locale,
          router: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => scaled(const InboxScreen()),
              ),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });

  testWidgets('permission banner and primer golden (Arabic)', (tester) async {
    (h.read(
      localNotificationsPortProvider,
    ) as InMemoryLocalNotificationsPort).caps = const NotificationCapabilities(
      platform: 'android',
    );
    await pumpApp(
      tester,
      dark: false,
      locale: const Locale('ar'),
      home: Scaffold(
        body: ListView(
          children: [
            const NotificationPermissionBanner(),
            Consumer(
              builder: (context, ref, _) => TextButton(
                key: const ValueKey('primer'),
                onPressed: () => showNotificationPrimer(context, ref),
                child: const Text('primer'),
              ),
            ),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/permission_banner_ar.png'),
    );
    await tester.tap(find.byKey(const ValueKey('primer')));
    await settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/permission_primer_ar.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
