// Checklist ↔ planner task links (T4.5.12): Schedule as task, Link to existing task…, header chips
// that open the task; the link lives only on `tasks.linked_checklist_id`.
import 'package:drift/drift.dart' show Variable;
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/application/task_links.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<String> newList(String title) async =>
      (await h
              .read(checklistsRepositoryProvider)
              .create(
                title: title,
                items: const [NodeSpec(text: 'a')],
              ))
          .id;

  Future<String> newTask(String title) async =>
      (await h
              .read(plannerServiceProvider)
              .createTask(
                Task(id: '', seriesId: '', title: title),
                source: 'test',
              ))
          .taskId;

  /// Waits until [provider] satisfies [ok] (the planner streams deliver asynchronously).
  Future<T> until<T>(ProviderListenable<T> provider, bool Function(T value) ok) async {
    final sub = h.container.listen(provider, (_, _) {});
    try {
      for (var i = 0; i < 400; i++) {
        final v = h.read(provider);
        if (ok(v)) return v;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      fail('condition never met');
    } finally {
      sub.close();
    }
  }

  test('Schedule as task creates an unscheduled task named after the list and linked to it', () async {
    final list = await newList('Quarterly report');
    final links = h.read(checklistTaskLinksProvider);
    final c = (await h.read(checklistsRepositoryProvider).byId(list))!;
    final taskId = await links.scheduleAsTask(c, fallbackTitle: 'Untitled');
    final linked = await until(linkedTasksProvider(list), (v) => v.isNotEmpty);
    expect(linked.single, LinkedTask(id: taskId, title: 'Quarterly report', linkedChecklistId: list));
    final row = await h.db
        .customSelect(
          'SELECT linked_checklist_id AS l, start_local AS s FROM tasks WHERE id = ?',
          variables: [Variable<String>(taskId)],
        )
        .getSingle();
    expect(row.read<String>('l'), list);
    expect(row.readNullable<String>('s'), isNull, reason: 'the user schedules it in the task editor');
  });

  test('linking an existing task moves the single link; unlinking removes it', () async {
    final a = await newList('A');
    final b = await newList('B');
    final task = await newTask('Buy gifts');
    final links = h.read(checklistTaskLinksProvider);

    await links.link(task, a);
    expect((await until(linkedTasksProvider(a), (v) => v.isNotEmpty)).single.title, 'Buy gifts');
    await links.link(task, b);
    await until(linkedTasksProvider(a), (v) => v.isEmpty);
    expect((await until(linkedTasksProvider(b), (v) => v.isNotEmpty)).single.id, task);
    await links.unlink(task);
    await until(linkedTasksProvider(b), (v) => v.isEmpty);
    final candidates = await until(plannerTasksForLinksProvider, (v) => v.any((t) => t.id == task));
    expect(candidates.firstWhere((t) => t.id == task).linkedChecklistId, isNull);
  });

  group('screen', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<GoRouter> pumpRouter(WidgetTester tester, String id) async {
      final router = GoRouter(
        initialLocation: '/lists/$id',
        routes: [
          GoRoute(
            path: '/lists/:id',
            builder: (_, s) => ChecklistScreen(checklistId: s.pathParameters['id']!, preview: true),
          ),
          GoRoute(
            path: '/task/:id',
            builder: (_, s) => Scaffold(body: Text('task ${s.pathParameters['id']}')),
          ),
          GoRoute(
            path: '/task/:id/edit',
            builder: (_, s) => Scaffold(body: Text('edit ${s.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp.router(
            routerConfig: router,
            supportedLocales: const [Locale('en')],
            localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          ),
        ),
      );
      await settle(tester);
      return router;
    }

    Future<void> menu(WidgetTester tester, String label) async {
      await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byTooltip('More')));
      await settle(tester);
      await tester.ensureVisible(find.text(label));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text(label));
      await settle(tester);
    }

    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 10));
    }

    testWidgets('Schedule as task opens the task editor; the header then shows the task chip', (tester) async {
      late String list;
      await tester.runAsync(() async => list = await newList('Move house'));
      final router = await pumpRouter(tester, list);
      await menu(tester, 'Schedule as task');
      expect(find.textContaining('edit '), findsOneWidget);

      router.pop();
      await settle(tester);
      final chip = find.widgetWithText(ActionChip, 'Move house');
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await settle(tester);
      expect(find.textContaining('task '), findsOneWidget);
      await close(tester);
    });

    testWidgets('Link to existing task… lists planner tasks and links the chosen one', (tester) async {
      late String list;
      await tester.runAsync(() async {
        list = await newList('Party');
        await newTask('Buy balloons');
      });
      await pumpRouter(tester, list);
      await menu(tester, 'Link to existing task…');
      await tester.tap(find.text('Buy balloons'));
      await settle(tester);
      expect(find.widgetWithText(ActionChip, 'Buy balloons'), findsOneWidget);
      await close(tester);
    });
  });
}
