import 'dart:convert';

import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/habits/application/habit_providers.dart' show habitLogsRepositoryProvider;
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart' show LogSource;
import 'package:everslot/features/planner/application/planner_service.dart' show plannerL10nProvider;
import 'package:everslot/features/widgets_home/application/widget_actions_runner.dart';
import 'package:everslot/features/widgets_home/application/widget_providers.dart';
import 'package:everslot/features/widgets_home/application/widget_snapshot_writer.dart';
import 'package:everslot/features/widgets_home/data/home_widget_bridge.dart';
import 'package:everslot/features/widgets_home/domain/widget_snapshot.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../support/test_app.dart';
import '../today/today_test_support.dart';

class FakeBridge implements WidgetBridge {
  final saved = <String>[];
  int reloads = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> registerActions(Future<void> Function(Uri? uri) callback) async {}

  @override
  Future<void> save(String snapshotJson) async => saved.add(snapshotJson);

  @override
  Future<void> reloadAll() async => reloads++;

  final pinned = <String>[];

  @override
  Future<bool> canPin() async => true;

  @override
  Future<void> pin(String kind) async => pinned.add(kind);

  List<(String, DateTime)> queue = [];

  @override
  Future<List<(String, DateTime)>> takeQueuedActions() async {
    final taken = queue;
    queue = [];
    return taken;
  }
}

/// T8.2.02 (bridge), T8.2.04 / T8.2.08 (actions): snapshot content, size cap, localization,
/// debounced writes and background actions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);
  late TestHarness h;
  late FakeBridge bridge;
  final now = DateTime.utc(2026, 9, 22, 10);

  setUp(() {
    bridge = FakeBridge();
    h = TestHarness.create(now: now, overrides: [widgetBridgeProvider.overrideWithValue(bridge)]);
  });
  tearDown(() => h.dispose());

  Future<WidgetSnapshot> snapshot([bool Function(WidgetSnapshot s)? test]) =>
      until(h.container, widgetSnapshotProvider, (s) => s != null && (test?.call(s) ?? true)).then((s) => s!);

  Future<String> seed() async {
    await h.task('Standup', start: at(2026, 9, 22, 9, 30), duration: 60);
    await h.task('Review', start: at(2026, 9, 22, 14));
    await h.task('Holiday', start: at(2026, 9, 22), allDay: true);
    await h.habit('Read', start: LocalDate(2026, 9, 1));
    await h.habit(
      'Push-ups',
      start: LocalDate(2026, 9, 1),
      goal: const HabitTarget(type: HabitGoalType.count, target: 20, unit: 'reps'),
    );
    await h.quitTracker('Smoking', quitAt: DateTime.utc(2026, 9, 20, 8), start: LocalDate(2026, 9, 20));
    final list = await h.checklist('Groceries', items: ['Milk', 'Eggs', 'Bread'], pinned: true);
    await h.setItemStatus(list, await h.itemId(list, 'Bread'), ItemStatus.completed);
    return list;
  }

  test('snapshot: agenda (all-day first), habits, quit counter and the pinned list', () async {
    final list = await seed();
    final s = await snapshot((s) => s.agenda.length == 3 && s.checklist != null);
    expect([for (final r in s.agenda) r.title], ['Holiday', 'Standup', 'Review']);
    expect(s.agenda.first.allDay, isTrue);
    expect(s.agenda[1].timeLabel, '09:30 – 10:30');
    expect(s.agenda[1].start, DateTime.utc(2026, 9, 22, 9, 30), reason: 'native timelines need instants');
    expect(s.agenda[1].link, startsWith('everslot://'));
    expect(s.progressLabel, '0/3 tasks');
    final pushUps = s.habits.firstWhere((x) => x.name == 'Push-ups');
    expect((pushUps.counter, pushUps.label, pushUps.done), (true, '0/20', false));
    expect(WidgetActions.parse(Uri.parse(pushUps.action)), const WidgetAction.habitCheck('habit-Push-ups'));
    expect(s.quits.single.since, DateTime.utc(2026, 9, 20, 8));
    expect(s.checklist!.items.map((i) => i.text), ['Milk', 'Eggs'], reason: 'open items only');
    expect(s.checklist!.done, 1);
    expect(
      WidgetActions.parse(Uri.parse(s.checklist!.items.first.action)),
      WidgetAction.itemComplete(list, await h.itemId(list, 'Milk')),
    );
    expect(s.strings['stale'], 'Open Everslot to refresh');
    final json = jsonDecode(s.encode()) as Map<String, Object?>;
    expect(json['v'], 1);
    expect(json['day'], '2026-09-22');
  });

  test('size cap: hundreds of long rows still fit in 50 KB', () {
    final row = WidgetAgendaRow(key: 'k', title: 'x' * 120, timeLabel: '09:00 – 10:00', link: 'everslot://task/x');
    final big = WidgetSnapshot(
      generatedAt: now,
      locale: 'en',
      rtl: false,
      day: '2026-09-22',
      dayLabel: 'Tuesday',
      progressLabel: '',
      strings: const {},
      agenda: List.filled(2000, row),
      checklist: WidgetChecklist(
        id: 'c',
        title: 't',
        done: 0,
        total: 0,
        link: 'l',
        items: List.filled(500, const WidgetChecklistItem(id: 'i', text: 'item', depth: 0, action: 'a')),
      ),
    ).bounded(agendaCap: 2000, itemsCap: 500);
    expect(utf8.encode(big.encode()).length, lessThanOrEqualTo(WidgetSnapshot.maxBytes));
    expect(big.agenda, isNotEmpty);
    expect(WidgetSnapshot.clip('a' * 200).length, 120);
    expect(big.isStale(now.add(const Duration(hours: 25))), isTrue);
    expect(big.isStale(now.add(const Duration(hours: 23))), isFalse);
  });

  test('strings are pre-rendered in the user language', () async {
    await h.dispose();
    h = TestHarness.create(
      now: now,
      overrides: [
        widgetBridgeProvider.overrideWithValue(bridge),
        plannerL10nProvider.overrideWithValue(lookupAppLocalizations(const Locale('fr'))),
      ],
    );
    await seed();
    final s = await snapshot((s) => s.locale == 'fr' && s.agenda.isNotEmpty);
    expect(s.strings['stale'], 'Ouvrez Everslot pour actualiser');
    expect(s.strings['allDay'], isNot('All day'));
  });

  test('writer: debounced, unchanged content skipped, rewritten once old', () {
    fakeAsync((async) {
      var clock = now;
      final writer = WidgetSnapshotWriter(bridge, now: () => clock);
      WidgetSnapshot snap(String day, DateTime at) => WidgetSnapshot(
        generatedAt: at,
        locale: 'en',
        rtl: false,
        day: day,
        dayLabel: day,
        progressLabel: '',
        strings: const {},
      );
      writer
        ..schedule(snap('a', now))
        ..schedule(snap('b', now));
      async.elapse(const Duration(milliseconds: 1900));
      expect(bridge.saved, isEmpty, reason: 'still debouncing');
      async.elapse(const Duration(milliseconds: 200));
      expect(bridge.saved, hasLength(1));
      expect(
        (jsonDecode(bridge.saved.single) as Map<String, Object?>)['day'],
        'b',
        reason: 'bursts coalesce to the latest',
      );
      expect(bridge.reloads, 1);

      writer.schedule(snap('b', now.add(const Duration(minutes: 5))));
      async.elapse(const Duration(seconds: 3));
      expect(bridge.saved, hasLength(1), reason: 'same content');

      clock = now.add(const Duration(hours: 7));
      writer.schedule(snap('b', clock));
      async.elapse(const Duration(seconds: 3));
      expect(bridge.saved, hasLength(2), reason: 'refreshed so widgets never look stale');
      writer.dispose();
    });
  });

  test('actions: habit check-in and +1 (source widget), item completion, unknown targets', () async {
    final list = await seed();
    final runner = WidgetActionRunner(h.container);
    expect(await runner.run(const WidgetAction.habitCheck('habit-Read')), isTrue);
    expect(await runner.run(const WidgetAction.habitCheck('habit-Push-ups')), isTrue);
    final read = await h.read(habitLogsRepositoryProvider).forHabit('habit-Read');
    expect((read.single.kind.name, read.single.source), ('done', LogSource.widget));
    final reps = await h.read(habitLogsRepositoryProvider).forHabit('habit-Push-ups');
    expect((reps.single.value, reps.single.source), (1, LogSource.widget));
    final milk = await h.itemId(list, 'Milk');
    expect(await runner.run(WidgetAction.itemComplete(list, milk)), isTrue);
    expect(await runner.run(const WidgetAction.habitCheck('missing')), isFalse);
    expect(await runner.run(const WidgetAction.habitCheck('quit-Smoking')), isFalse, reason: 'quit trackers');

    await refreshWidgetSnapshot(h.container);
    final written = jsonDecode(bridge.saved.last) as Map<String, Object?>;
    final items = ((written['checklist']! as Map)['items']! as List).map((i) => (i as Map)['text']);
    expect(items, ['Eggs'], reason: 'the fresh snapshot confirms the optimistic tap');
  });

  test('iOS queue: taps apply in order at their tap time; malformed entries are skipped', () async {
    await seed();
    final yesterday = now.subtract(const Duration(days: 1));
    bridge.queue = [
      (WidgetActions.habitCheck('habit-Read'), yesterday),
      ('not a uri', now),
      (WidgetActions.habitCheck('habit-Push-ups'), now),
    ];
    expect(await drainQueuedWidgetActions(h.container), 2);
    final read = await h.read(habitLogsRepositoryProvider).forHabit('habit-Read');
    expect(read.single.localDate, LocalDate(2026, 9, 21), reason: 'the tap happened yesterday');
    expect(await drainQueuedWidgetActions(h.container), 0, reason: 'the queue was cleared');
    expect(HomeWidgetBridge.parseQueuedActions('[{"uri":"a","at":"2026-09-22T10:00:00.000Z"},{"uri":1},{"at":"x"}]'), [
      ('a', DateTime.utc(2026, 9, 22, 10)),
    ]);
    expect(HomeWidgetBridge.parseQueuedActions('{oops'), isEmpty);
  });

  test('action URIs round-trip; foreign URIs are ignored', () {
    expect(WidgetActions.parse(Uri.parse(WidgetActions.habitCheck('h 1'))), const WidgetAction.habitCheck('h 1'));
    expect(WidgetActions.parse(Uri.parse(WidgetActions.refresh())), const WidgetAction.refresh());
    expect(WidgetActions.parse(Uri.parse('everslot://habit/check?id=x')), isNull);
    expect(WidgetActions.parse(Uri.parse('everslot-widget://item/complete?id=x')), isNull);
    expect(WidgetActions.parse(null), isNull);
  });
}
