import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot/design_system/theme.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

/// A resolved occurrence for pure tests (UTC zone: local = UTC).
PlannerItem occ(
  String title, {
  required LocalDateTime start,
  int minutes = 60,
  OccurrenceStatus status = OccurrenceStatus.scheduled,
  bool allDay = false,
  TrackingMode mode = TrackingMode.check,
  bool recurring = false,
  int priority = 0,
  String? key,
  bool quotaSlot = false,
}) {
  final startUtc = start.toDateTimeUtc();
  return PlannerItem(
    taskId: 'task-$title',
    seriesId: 'task-$title',
    occurrenceKey: key ?? (allDay ? start.date.toIso() : start.toIso()),
    title: title,
    startLocal: start,
    durationMinutes: allDay ? 1440 : minutes,
    startUtc: startUtc,
    endUtc: startUtc.add(Duration(minutes: allDay ? 1440 : minutes)),
    status: status,
    allDay: allDay,
    trackingMode: mode,
    isRecurring: recurring,
    priority: priority,
    isQuotaSlot: quotaSlot,
  );
}

LocalDateTime at(int y, int m, int d, [int h = 0, int min = 0]) => LocalDateTime.of(y, m, d, h, min);

/// Today seeding helpers on top of [TestHarness] (application-layer APIs only).
extension TodayHarness on TestHarness {
  /// Creates a task through the planner service; returns its id.
  Future<String> task(
    String title, {
    LocalDateTime? start,
    int duration = 60,
    RecurrenceRule? rule,
    String? zone,
    bool allDay = false,
    TrackingMode mode = TrackingMode.check,
    int priority = 0,
  }) async {
    final result = await read(plannerServiceProvider).createTask(
      Task(
        id: '',
        seriesId: '',
        title: title,
        startLocal: start == null ? null : (allDay ? start.date.atStartOfDay : start),
        durationMinutes: start == null ? null : (allDay ? 1440 : duration),
        isAllDay: allDay,
        recurrence: rule,
        timeZone: zone,
        trackingMode: mode,
        priority: priority,
      ),
    );
    return result.taskId;
  }

  /// Creates a daily yes/no (or measurable) build habit starting [start].
  Future<String> habit(
    String name, {
    required LocalDate start,
    RecurrenceRule? schedule,
    HabitTarget goal = const HabitTarget.check(),
    String id = '',
  }) async {
    final habitId = id.isEmpty ? 'habit-$name' : id;
    await read(habitServiceProvider).create(
      BuildHabit(
        id: habitId,
        name: name,
        startDate: start,
        sortKey: '',
        goal: goal,
        schedule: schedule ?? RecurrenceRule(),
      ),
    );
    return habitId;
  }

  /// Creates an abstain quit tracker started at [quitAt].
  Future<String> quitTracker(String name, {required DateTime quitAt, required LocalDate start, String? id}) async {
    final habitId = id ?? 'quit-$name';
    await read(habitServiceProvider).create(
      QuitHabit(
        id: habitId,
        name: name,
        startDate: start,
        sortKey: '',
        mode: QuitMode.abstain,
        quitStartedAt: quitAt,
        baselinePerDay: 10,
      ),
    );
    return habitId;
  }

  /// Creates a checklist with top-level [items]; returns its id.
  Future<String> checklist(String title, {List<String> items = const [], bool pinned = false}) async =>
      (await read(checklistsRepositoryProvider).create(
        title: title,
        isPinned: pinned,
        items: [for (final t in items) NodeSpec(text: t)],
      )).id;

  /// Id of the item with [text] in [checklistId].
  Future<String> itemId(String checklistId, String text) async =>
      (await read(checklistItemsRepositoryProvider).items(checklistId)).firstWhere((i) => i.text == text).id;

  Future<void> setItemFields(String checklistId, String itemId, Map<String, Object?> fields) async {
    await read(checklistServiceProvider).setFields(checklistId, itemId, fields);
  }

  Future<void> setItemStatus(String checklistId, String itemId, ItemStatus status, {DateTime? followUpAt}) async {
    await read(checklistServiceProvider).changeStatus(checklistId, [itemId], status, followUpAt: followUpAt);
  }
}

/// Lets Drift streams and provider chains settle (real async I/O in widget tests).
Future<void> settle(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Waits (in plain tests) until [provider] yields a value matching [test].
Future<T> until<T>(
  ProviderContainer container,
  ProviderListenable<T> provider,
  bool Function(T value) test, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final completer = Completer<T>();
  final sub = container.listen<T>(provider, (_, next) {
    if (!completer.isCompleted && test(next)) completer.complete(next);
  }, fireImmediately: true);
  try {
    return await completer.future.timeout(timeout);
  } finally {
    sub.close();
  }
}

/// Pumps [child] with the app themes, a locale, dark mode and a text scale.
Future<void> pumpToday(
  WidgetTester tester,
  TestHarness h,
  Widget child, {
  Locale locale = const Locale('en'),
  bool dark = false,
  double textScale = 1,
  Size size = const Size(400, 900),
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: child,
      ),
    ),
  );
}

/// The current user id of the harness.
String userOf(TestHarness h) => h.read(currentUserIdProvider);
