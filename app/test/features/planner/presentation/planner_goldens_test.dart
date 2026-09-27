// Goldens of the planner's key screens: task editor (T3.1.06), occurrence sheet (T3.2.05) and
// task details (T3.1.09) — light/dark × LTR/RTL. Regenerate with `--update-goldens`.
@Tags(['golden'])
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/presentation/occurrence_panel.dart';
import 'package:everslot/features/planner/presentation/task_detail_screen.dart';
import 'package:everslot/features/planner/presentation/task_editor_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

void main() {
  late TestHarness h;
  // Monday 2026-09-21 06:00 UTC.
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 21, 6)));
  tearDown(() => h.dispose());

  /// 360 × 780 logical pixels at DPR 1 (small images), animations off.
  Future<void> pumpScreen(
    WidgetTester tester,
    Future<void> Function(BuildContext context) open, {
    required bool dark,
    required bool rtl,
  }) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: rtl ? const Locale('ar') : const Locale('en'),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(key: const ValueKey('open'), onPressed: () => open(context), child: const Text('open')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await openAndSettle(tester);
  }

  for (final dark in [false, true]) {
    for (final rtl in [false, true]) {
      final name = '${dark ? 'dark' : 'light'}_${rtl ? 'rtl' : 'ltr'}';

      testWidgets('task editor golden $name', (tester) async {
        await pumpScreen(
          tester,
          (context) => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => const TaskEditorScreen(
                initialStart: '2026-09-22T07:00',
                initialDurationMinutes: 60,
                initialTitle: 'Gym',
              ),
            ),
          ),
          dark: dark,
          rtl: rtl,
        );
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/task_editor_$name.png'));
      });

      testWidgets('occurrence sheet golden $name', (tester) async {
        final item = (await tester.runAsync(() async {
          final id = await h.createTask(
            title: 'Standup',
            start: '2026-09-20T09:30',
            duration: 15,
            rule: RecurrenceRule(),
            priority: 3,
          );
          return (await h.items(ld('2026-09-21'), 1)).firstWhere((i) => i.taskId == id);
        }))!;
        await pumpScreen(tester, (context) => showOccurrenceSheet(context, item), dark: dark, rtl: rtl);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/occurrence_sheet_$name.png'));
      });

      if (dark == rtl) {
        testWidgets('task details golden $name', (tester) async {
          final id = (await tester.runAsync(
            () => h.createTask(title: 'Standup', start: '2026-09-20T09:30', duration: 15, rule: RecurrenceRule()),
          ))!;
          await pumpScreen(
            tester,
            (context) => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: id))),
            dark: dark,
            rtl: rtl,
          );
          await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/task_details_$name.png'));
        });
      }
    }
  }
}
