import 'dart:async';

import 'package:everslot/features/habits/application/habit_providers.dart' show habitLogsRepositoryProvider;
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart' show LogSource;
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/application/integration_providers.dart';
import 'package:everslot/features/integrations/data/quick_actions_source.dart';
import 'package:everslot/features/integrations/domain/app_shortcuts.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart' show plannerL10nProvider;
import 'package:everslot/features/planner/domain/planner_item.dart' show TrackingMode;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../today/today_test_support.dart';
import 'external_links_service_test.dart' show FakeLinkSource;

class FakeShortcuts implements ShortcutPlatform {
  void Function(String type)? onSelected;
  List<(String, String)> items = [];

  @override
  Future<void> initialize(void Function(String type) onSelected) async => this.onSelected = onSelected;

  @override
  Future<void> setShortcuts(List<(String, String)> shortcuts) async => items = shortcuts;
}

/// T8.2.06: app icon shortcuts → deep links / commands.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  late FakeShortcuts platform;
  late List<IntegrationUiEvent> events;
  late StreamSubscription<IntegrationUiEvent> sub;

  setUp(() async {
    platform = FakeShortcuts();
    h = TestHarness.create(
      now: DateTime.utc(2026, 9, 22, 10),
      overrides: [
        shortcutPlatformProvider.overrideWithValue(platform),
        linkSourceProvider.overrideWithValue(FakeLinkSource()),
      ],
    );
    events = [];
    sub = h.read(integrationUiEventsProvider).stream.listen(events.add);
    await h.read(appShortcutsServiceProvider).start(h.read(plannerL10nProvider));
  });
  tearDown(() async {
    await sub.cancel();
    await h.dispose();
  });

  Future<void> tap(String type) async {
    // Repeated links within 3 s are de-duplicated (initial link replay): taps are seconds apart.
    h.clock.advance(const Duration(seconds: 10));
    platform.onSelected!(type);
    await pumpEventQueue();
  }

  test('each shortcut type maps to its deep link', () {
    expect(
      {for (final s in AppShortcut.values) s.type: s.link},
      {
        'new_task': 'everslot://do/new-task',
        'log_habit': 'everslot://habits',
        'log_craving': 'everslot://do/craving',
        'today': 'everslot://today',
      },
    );
    expect(AppShortcut.tryParse('nope'), isNull);
  });

  test('localized titles are registered', () {
    expect(platform.items, [
      ('new_task', 'New task'),
      ('log_habit', 'Log habit'),
      ('log_craving', 'Log craving'),
      ('today', 'Today'),
    ]);
  });

  test('Today and Log habit open their screens; New task opens quick add', () async {
    await tap('today');
    await tap('log_habit');
    await tap('new_task');
    await tap('unknown');
    expect(events, [
      const OpenPathUiEvent('/today', asRoot: true),
      const OpenPathUiEvent('/habits', asRoot: true),
      const QuickAddUiEvent(),
    ]);
  });

  test('Log craving: none → create one; one → logged with a notice; several → Habits', () async {
    await tap('log_craving');
    expect(events.last, const OpenPathUiEvent('/habit-new?kind=quit'));

    await h.quitTracker('Smoking', quitAt: DateTime.utc(2026, 9, 20), start: LocalDate(2026, 9, 20));
    await tap('log_craving');
    await pumpEventQueue();
    expect(events.last, const NoticeUiEvent(IntegrationNotice.cravingLogged, detail: 'Smoking'));
    final logs = await h.read(habitLogsRepositoryProvider).forHabit('quit-Smoking');
    expect(logs.single.kind.name, 'craving');

    await h.quitTracker('Sugar', quitAt: DateTime.utc(2026, 9, 20), start: LocalDate(2026, 9, 20));
    await tap('log_craving');
    await pumpEventQueue();
    expect(events.last, const OpenPathUiEvent('/habits', asRoot: true));
  });

  test('timer-stop command (iOS Live Activity Stop): stops the timer and opens the occurrence', () async {
    final taskId = await h.task('Deep work', start: at(2026, 9, 22, 9), mode: TrackingMode.timer);
    await h.read(occurrencesRepositoryProvider).start(taskId, '2026-09-22T09:00');
    h.clock.advance(const Duration(minutes: 25));
    await h
        .read(externalLinksServiceProvider)
        .handle(Uri.parse('everslot://do/timer-stop?task=$taskId&occ=2026-09-22T09:00'));
    await pumpEventQueue();
    final running = await h.read(plannerQueriesProvider).watchRunningEntries().first;
    expect(running, isEmpty);
    expect(events.last, OpenPathUiEvent('/task/$taskId?occ=2026-09-22T09%3A00'));
    // Bad parameters are rejected before anything runs.
    await h.read(externalLinksServiceProvider).handle(Uri.parse('everslot://do/timer-stop?task=x&occ=y'));
    await pumpEventQueue();
    expect(events.last, const NoticeUiEvent(IntegrationNotice.linkNotFound));
  });

  group('voice commands (T8.2.15)', () {
    Future<void> link(String uri) async {
      h.clock.advance(const Duration(seconds: 10));
      await h.read(externalLinksServiceProvider).handle(Uri.parse(uri));
      await pumpEventQueue();
    }

    test('habit-log: by spoken name (accents / partial), with an amount for counted habits', () async {
      await h.habit(
        'Pompes',
        start: LocalDate(2026, 9, 1),
        goal: const HabitTarget(type: HabitGoalType.count, target: 50, unit: 'reps'),
      );
      await h.habit('Méditation', start: LocalDate(2026, 9, 1));
      await link('everslot://do/habit-log?name=pompes&value=15');
      await link('everslot://do/habit-log?name=meditation');
      final reps = await h.read(habitLogsRepositoryProvider).forHabit('habit-Pompes');
      expect((reps.single.value, reps.single.source), (15, LogSource.voice));
      final med = await h.read(habitLogsRepositoryProvider).forHabit('habit-Méditation');
      expect(med.single.kind.name, 'done');
      expect(events.last, const NoticeUiEvent(IntegrationNotice.habitLogged, detail: 'Méditation'));
      await link('everslot://do/habit-log?name=juggling');
      expect(events.last, const NoticeUiEvent(IntegrationNotice.habitNotFound, detail: 'juggling'));
    });

    test('next opens the running or next task; focus starts its timer', () async {
      await link('everslot://do/next');
      expect(events.last, const NoticeUiEvent(IntegrationNotice.nothingNext));
      final taskId = await h.task('Write report', start: at(2026, 9, 22, 11), mode: TrackingMode.timer);
      await link('everslot://do/next');
      expect(events.last, OpenPathUiEvent('/task/$taskId?occ=2026-09-22T11%3A00'));
      await link('everslot://do/focus');
      final running = await h.read(plannerQueriesProvider).watchRunningEntries().first;
      expect(running.single.taskId, taskId);
    });
  });
}
