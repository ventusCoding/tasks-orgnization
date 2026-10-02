import 'dart:async';

import 'package:everslot/features/habits/application/habit_providers.dart' show habitLogsRepositoryProvider;
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/application/integration_providers.dart';
import 'package:everslot/features/integrations/data/quick_actions_source.dart';
import 'package:everslot/features/integrations/domain/app_shortcuts.dart';
import 'package:everslot/features/planner/application/planner_service.dart' show plannerL10nProvider;
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
}
