import 'package:everslot/app/command_palette.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/search/presentation/search_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/today/today_test_support.dart';
import '../support/test_app.dart';

/// Command palette (T8.1.18): navigation, actions, dated task creation, search `>` and ⌘K.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 10)));
  tearDown(() => h.dispose());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 2000) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => PaletteShortcut(
            child: Scaffold(
              body: Builder(
                builder: (context) =>
                    TextButton(onPressed: () => showCommandPalette(context), child: const Text('open')),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (_, _) => SearchScreen(onCommandPalette: (c, q) => showCommandPalette(c, initialQuery: q)),
        ),
      ],
      errorBuilder: (_, s) => Scaffold(body: Text('opened ${s.uri}')),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> openPalette(WidgetTester tester, String query) async {
    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('palette-field')), query);
    await tester.pump();
  }

  testWidgets('a navigation command runs: "next week" opens the week after', (tester) async {
    await pump(tester);
    await openPalette(tester, 'next week');
    expect(find.byKey(const ValueKey('palette-cmd-next_week')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('palette-cmd-next_week')));
    await settle(tester);
    expect(find.text('opened /plan/week?date=2026-09-29'), findsOneWidget);
  });

  testWidgets('Enter runs the best match; insights scopes match "insights habits"', (tester) async {
    await pump(tester);
    await openPalette(tester, 'insights habits');
    expect(find.text('Open Insights › Habits'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await settle(tester);
    expect(find.text('opened /insights/habits'), findsOneWidget);
  });

  testWidgets('"pause" pauses notifications for an hour, then offers resume', (tester) async {
    await pump(tester);
    await openPalette(tester, 'pause 1');
    await tester.tap(find.byKey(const ValueKey('palette-cmd-pause_1h')));
    await settle(tester);
    final settings = await tester.runAsync(
      () => until(h.container, notificationSettingsProvider, (s) => s.pausedUntil != null),
    );
    expect(settings!.pausedUntil, DateTime.utc(2026, 9, 22, 11));
    expect(find.text('Notifications paused'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await openPalette(tester, 'notif');
    expect(find.byKey(const ValueKey('palette-cmd-resume')), findsOneWidget);
    expect(find.byKey(const ValueKey('palette-cmd-pause_1h')), findsNothing);
  });

  testWidgets('a dated phrase becomes "New task … at …"', (tester) async {
    await pump(tester);
    await openPalette(tester, 'Call Bob tomorrow 9am');
    expect(find.text('New task “Call Bob” · Sep 23, 2026 09:00'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('palette-cmd-new_task_at')));
    await settle(tester);
    final tasks = await tester.runAsync(
      () => h.read(plannerQueriesProvider).tasksForRange(at(2026, 9, 23), at(2026, 9, 24)),
    );
    expect(tasks!.single.title, 'Call Bob');
    expect(tasks.single.startLocal, LocalDateTime.of(2026, 9, 23, 9));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('no match shows a message', (tester) async {
    await pump(tester);
    await openPalette(tester, 'qqqqzz');
    expect(find.text('No matching command'), findsOneWidget);
  });

  testWidgets('Ctrl+K opens the palette; search hands ">" queries to it', (tester) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(find.byKey(const ValueKey('palette-field')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // dismiss
    await settle(tester);

    GoRouter.of(tester.element(find.text('open'))).go('/search');
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('search-field')), '>trash');
    await settle(tester);
    expect(find.byKey(const ValueKey('palette-cmd-trash')), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('palette-field'))).controller!.text, 'trash');
  });
}
