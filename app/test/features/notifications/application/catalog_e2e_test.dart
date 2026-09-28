import 'package:decimal/decimal.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/default_rules.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../../planner/planner_test_support.dart';

/// The 7.5 catalog end to end with the REAL feature sources (planner, checklists, habits, quit)
/// plus digests: seeded defaults → pipeline → fake OS port, then the global controls
/// (per-section switch, mute until, pause all, quiet hours) — T7.5.01/02/05/06/10/11/13/15/16/18.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  late InMemoryLocalNotificationsPort port;
  late String listId;

  // Tuesday 2026-09-22 06:00 UTC = 08:00 in Paris (CEST, UTC+2).
  final now = DateTime.utc(2026, 9, 22, 6);
  DateTime utc(int day, int hour, [int minute = 0]) =>
      DateTime.utc(2026, 9, day, hour, minute);

  setUp(() async {
    h = TestHarness.create(now: now, zone: 'Europe/Paris');
    port = h.read(
      localNotificationsPortProvider,
    ) as InMemoryLocalNotificationsPort;
    await seedNotificationDefaults(h.read);

    // Planner: a timed task today 10:00 and an all-day task on Thursday.
    await h.createTask(
      title: 'Standup',
      start: '2026-09-22T10:00',
      duration: 15,
    );
    await h.createTask(
      title: 'Birthday',
      start: '2026-09-24T00:00',
      duration: 1440,
      allDay: true,
    );

    // Checklists: an item waiting with a follow-up, another with a due time.
    listId =
        (await h
                .read(checklistsRepositoryProvider)
                .create(
                  title: 'Trip',
                  items: [
                    const NodeSpec(text: 'Visa'),
                    NodeSpec(
                      text: 'Passport',
                      dueLocal: LocalDate(2026, 9, 23).atTime(LocalTime(10, 0)),
                    ),
                  ],
                ))
            .id;
    final items = await h.read(checklistItemsRepositoryProvider).items(listId);
    final visa = items.firstWhere((i) => i.text == 'Visa').id;
    await h
        .read(checklistServiceProvider)
        .changeStatus(
          listId,
          [visa],
          ItemStatus.waiting,
          note: 'embassy',
          followUpAt: utc(22, 9),
        );

    // Habits: an untimed daily habit; quit: a smoke-free tracker started yesterday 22:00.
    await h
        .read(habitsRepositoryProvider)
        .create(
          BuildHabit(
            id: Ids.v7(),
            name: 'Meditate',
            startDate: LocalDate(2026, 9, 1),
            sortKey: '',
            goal: const HabitTarget.check(),
            schedule: const SchedulePreset.daily().toRule(
              weekStart: Weekday.monday,
            ),
          ),
        );
    await h
        .read(habitsRepositoryProvider)
        .create(
          QuitHabit(
            id: Ids.v7(),
            name: 'Stop smoking',
            startDate: LocalDate(2026, 9, 21),
            sortKey: '',
            mode: QuitMode.abstain,
            quitStartedAt: utc(21, 20),
            substance: QuitSubstance.cigarettes,
            baselinePerDay: 20,
            unitCost: Decimal.parse('0.5'),
            currency: 'EUR',
            unit: HabitUnits.cigarettes,
          ),
        );

    // Digests: the morning agenda at the off-peak 07:07.
    await h.read(notificationSettingsWriterProvider)({
      'digest': {'enabled': true},
    });
    await h
        .read(notificationRulesRepositoryProvider)
        .setDigest(
          kind: 'daily_agenda',
          enabled: true,
          spec: DefaultRules.digestSpec('daily_agenda', LocalTime(7, 7)),
        );
  });
  tearDown(() => h.dispose());

  Future<void> replan() => h.read(notificationPipelineProvider).run('test');

  /// Section of an OS request from its channel (`dl.<section>.<profile>.v<n>`, `dl.digest.v1`).
  String sectionOf(OsNotificationRequest r) => r.channelId.split('.')[1];

  Set<String> sections() => {
    for (final r in port.scheduled.values) sectionOf(r),
  };

  /// Local firings of [section] from the plan (per instance: same-minute instances of
  /// different sections are merged into one OS notification).
  List<DateTime> firesIn(String section) => [
    for (final p in h.read(notificationPipelineProvider).lastPlan!.planned)
      if (p.channelId.split('.')[1] == section &&
          p.scheduleLocally &&
          p.deliverSystem)
        p.fireAt,
  ]..sort();

  Future<void> settings(Map<String, Object?> patch) => h
      .read(settingsRepositoryProvider)
      .update(SettingsNs.notifications, patch);

  test('every section and the digest are planned from the seeded defaults', () async {
    await replan();
    expect(
      sections(),
      containsAll(['planner', 'checklists', 'habits', 'quit', 'digest']),
    );

    // Planner: 10 min before + at start (the user's example); all-day on the day at 09:00.
    final planner = firesIn('planner');
    expect(planner, containsAll([utc(22, 7, 50), utc(22, 8), utc(24, 7)]));
    // Checklists: follow-up of the waiting item, due reminder of the other one.
    expect(firesIn('checklists'), containsAll([utc(22, 9), utc(23, 8)]));
    // Habits: untimed daily habit at 09:00 local.
    expect(firesIn('habits'), contains(utc(22, 7)));
    // Quit: the 24 h milestone is projected from the quit time.
    expect(firesIn('quit'), contains(utc(22, 20)));
    // Digest: morning agenda at 07:07 local, off-peak.
    expect(firesIn('digest'), contains(utc(23, 5, 7)));
  });

  test('turning Habits off cancels every habit notification only', () async {
    await replan();
    expect(sections(), contains('habits'));
    await settings({
      'perSection': {
        'habits': {'enabled': false},
      },
    });
    await replan();
    expect(sections(), isNot(contains('habits')));
    expect(
      sections(),
      containsAll(['planner', 'checklists', 'quit', 'digest']),
    );
  });

  test('muting a checklist silences its reminders until the date, then they resume', () async {
    await h
        .read(notificationMutesRepositoryProvider)
        .mute(targetType: 'checklist', targetId: listId, until: utc(23, 0));
    await replan();
    // The follow-up (22nd) is muted; the due reminder (23rd) is after the mute.
    expect(firesIn('checklists'), [utc(23, 8)]);
    expect(sections(), containsAll(['planner', 'habits']));
  });

  test('pause all suppresses system notifications until it ends; the inbox keeps them', () async {
    await settings({'pausedUntil': utc(22, 9, 30).toIso8601String()});
    await replan();
    // Nothing fires as an OS notification before 09:30 UTC…
    for (final r in port.scheduled.values) {
      expect(
        r.fireAt!.isBefore(utc(22, 9, 30)),
        isFalse,
        reason: '${r.fireAt}',
      );
    }
    // …but the paused firings stay tracked for the inbox.
    final tracked = await h.read(localScheduleStoreProvider).all();
    expect(
      tracked.where((e) => !e.os && e.fireAt.isBefore(utc(22, 9, 30))),
      isNotEmpty,
    );
    // Later reminders are untouched.
    expect(firesIn('checklists'), contains(utc(23, 8)));
  });

  test('quiet hours defer a reminder to the end of the window', () async {
    // Quiet 20:00 → 10:30 every day (local): both standup reminders (09:50, 10:00) move to
    // 10:30 local = 08:30 UTC.
    await settings({
      'quietHours': [
        {
          'days': [1, 2, 3, 4, 5, 6, 7],
          'from': '20:00',
          'to': '10:30',
          'mode': 'defer',
        },
      ],
    });
    await replan();
    final planner = firesIn('planner');
    expect(planner, isNot(contains(utc(22, 7, 50))));
    expect(planner, isNot(contains(utc(22, 8))));
    expect(planner, contains(utc(22, 8, 30)));
    // The 22:00 local quit milestone is deferred to 09:00 the next morning.
    expect(firesIn('quit'), isNot(contains(utc(22, 20))));
  });
}
