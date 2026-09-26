import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/data/notification_rules_repository.dart';
import 'package:everslot/features/notifications/domain/default_rules.dart';
import 'package:everslot/features/notifications/domain/inbox_item.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6)));
  tearDown(() => h.dispose());

  group('NotificationRulesRepository', () {
    test('creates rules through the sync writer with outbox patches and activity events', () async {
      final repo = h.read(notificationRulesRepositoryProvider);
      await repo.create(const [
        RuleDraft(
          targetType: RuleTargetType.task,
          targetId: 't1',
          section: NotificationSection.planner,
          spec: NotificationRuleSpec(
            trigger: RelativeTrigger(
              anchor: TriggerAnchor.start,
              offsetMinutes: -10,
            ),
          ),
        ),
        RuleDraft(
          targetType: RuleTargetType.task,
          targetId: 't1',
          section: NotificationSection.planner,
          spec: NotificationRuleSpec(
            trigger: RelativeTrigger(
              anchor: TriggerAnchor.start,
              offsetMinutes: 0,
            ),
          ),
        ),
      ]);
      final rules = await repo.forTarget(RuleTargetType.task, 't1');
      expect(rules, hasLength(2));
      expect(rules.first.sortKey.compareTo(rules.last.sortKey), lessThan(0));
      final outbox = await h.db.select(h.db.syncOutbox).get();
      expect(
        outbox.where((o) => o.tableName_ == 'notification_rules'),
        hasLength(2),
      );
      final events = await h.db.select(h.db.activityEvents).get();
      expect(
        events.where(
          (e) =>
              e.entityType == 'notification_rule' && e.eventType == 'created',
        ),
        hasLength(2),
      );
      // One user command = one operation group.
      expect(outbox.map((o) => o.opId).toSet(), hasLength(1));
    });

    test('rejects invalid specs and target id mismatches', () async {
      final repo = h.read(notificationRulesRepositoryProvider);
      expect(
        () => repo.create(const [
          RuleDraft(
            targetType: RuleTargetType.task,
            targetId: 't1',
            section: NotificationSection.planner,
            spec: NotificationRuleSpec(
              trigger: OverdueTrigger(),
              repeat: RepeatSpec(everyMinutes: 5, maxTimes: 20),
            ),
          ),
        ]),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => repo.create(const [
          RuleDraft(
            targetType: RuleTargetType.section,
            targetId: 'x',
            section: NotificationSection.planner,
            spec: NotificationRuleSpec(trigger: OverdueTrigger()),
          ),
        ]),
        throwsA(isA<ValidationException>()),
      );
    });

    test('update, delete and cascade from a deleted item', () async {
      final repo = h.read(notificationRulesRepositoryProvider);
      await repo.create(const [
        RuleDraft(
          targetType: RuleTargetType.habit,
          targetId: 'h',
          section: NotificationSection.habits,
          spec: NotificationRuleSpec(trigger: OverdueTrigger()),
        ),
      ]);
      final rule = (await repo.forTarget(RuleTargetType.habit, 'h')).single;
      await repo.update(
        rule.id,
        enabled: false,
        spec: rule.spec.copyWith(delivery: const DeliverySpec(sound: 'none')),
      );
      final updated = (await repo.byId(rule.id))!;
      expect(updated.enabled, isFalse);
      expect(updated.spec.delivery.sound, 'none');
      await h
          .read(syncWriterProvider)
          .run(
            (tx) => repo.softDeleteForTargetInTx(tx, RuleTargetType.habit, 'h'),
          );
      expect(await repo.forTarget(RuleTargetType.habit, 'h'), isEmpty);
    });

    test('bulk copy is one undoable command', () async {
      final repo = h.read(notificationRulesRepositoryProvider);
      final rule = NotificationRule(
        id: 'src',
        targetType: RuleTargetType.task,
        targetId: 'a',
        section: NotificationSection.planner,
        spec: const NotificationRuleSpec(
          trigger: RelativeTrigger(
            anchor: TriggerAnchor.start,
            offsetMinutes: -30,
          ),
        ),
      );
      final record = await repo.copyRules(
        from: [rule],
        type: RuleTargetType.task,
        targetIds: ['b', 'c'],
      );
      expect(await repo.forTarget(RuleTargetType.task, 'b'), hasLength(1));
      expect(await repo.forTarget(RuleTargetType.task, 'c'), hasLength(1));
      await h.read(syncWriterProvider).revert(record);
      expect(await repo.forTarget(RuleTargetType.task, 'b'), isEmpty);
    });
  });

  group('seeding (T7.1.07)', () {
    test('built-in profiles and default rules are seeded idempotently with deterministic ids', () async {
      await seedNotificationDefaults(h.read);
      await seedNotificationDefaults(h.read);
      final profiles = await h
          .read(notificationProfilesRepositoryProvider)
          .all();
      expect(profiles.map((p) => p.code), containsAll(BuiltinProfiles.codes));
      expect(profiles, hasLength(BuiltinProfiles.codes.length));
      expect(
        profiles.firstWhere((p) => p.code == 'standard').id,
        Ids.builtinProfile('user-1', 'standard'),
      );
      final rules = await h.read(notificationRulesRepositoryProvider).all();
      expect(rules, hasLength(DefaultRules.seeds.length));
      expect(
        rules.every(
          (r) => r.isDefault && r.targetType == RuleTargetType.section,
        ),
        isTrue,
      );
      // A fresh account: a new timed task gets exactly two reminders (10 min before + at start).
      final timed = rules.where(
        (r) =>
            r.section == NotificationSection.planner &&
            r.spec.conditions.itemKind == 'timed',
      );
      expect(timed, hasLength(2));
      expect(timed.first.profileId, Ids.builtinProfile('user-1', 'standard'));
    });

    test('two devices seeding offline converge on the same ids', () async {
      final other = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6));
      addTearDown(other.dispose);
      await seedNotificationDefaults(h.read);
      await seedNotificationDefaults(other.read);
      final a = {
        for (final r in await h.read(notificationRulesRepositoryProvider).all())
          r.id,
      };
      final b = {
        for (final r
            in await other.read(notificationRulesRepositoryProvider).all())
          r.id,
      };
      expect(a, b);
    });
  });

  group('NotificationProfilesRepository', () {
    test('importance or sound change bumps the channel version; built-ins cannot be deleted', () async {
      await seedNotificationDefaults(h.read);
      final repo = h.read(notificationProfilesRepositoryProvider);
      await repo.create(
        name: 'Loud',
        spec: const ProfileSpec(delivery: DeliverySpec(importance: 'high')),
      );
      final custom = (await repo.all()).firstWhere((p) => !p.isBuiltin);
      await repo.update(
        custom.id,
        spec: const ProfileSpec(delivery: DeliverySpec(importance: 'low')),
      );
      expect(
        (await repo.all())
            .firstWhere((p) => p.id == custom.id)
            .spec
            .channelVersion,
        2,
      );
      await repo.update(custom.id, name: 'Quiet');
      expect(
        (await repo.all())
            .firstWhere((p) => p.id == custom.id)
            .spec
            .channelVersion,
        2,
      );
      final standard = (await repo.all()).firstWhere(
        (p) => p.code == 'standard',
      );
      expect(
        () => repo.delete(standard.id),
        throwsA(isA<ValidationException>()),
      );
    });

    test('deleting a profile moves its rules', () async {
      final repo = h.read(notificationProfilesRepositoryProvider);
      await repo.create(name: 'Custom', spec: const ProfileSpec());
      final custom = (await repo.all()).single;
      await h.read(notificationRulesRepositoryProvider).create([
        RuleDraft(
          targetType: RuleTargetType.task,
          targetId: 't',
          section: NotificationSection.planner,
          profileId: custom.id,
          spec: const NotificationRuleSpec(trigger: OverdueTrigger()),
        ),
      ]);
      expect(await repo.rulesUsing(custom.id), 1);
      await repo.delete(custom.id, moveRulesTo: 'other');
      final rule =
          (await h
                  .read(notificationRulesRepositoryProvider)
                  .forTarget(RuleTargetType.task, 't'))
              .single;
      expect(rule.profileId, 'other');
      expect(await repo.all(), isEmpty);
    });
  });

  group('NotificationMutesRepository', () {
    test('mute, list, unmute and purge expired', () async {
      final repo = h.read(notificationMutesRepositoryProvider);
      await repo.mute(
        targetType: 'checklist',
        targetId: 'L',
        until: DateTime.utc(2026, 9, 30),
      );
      await repo.mute(
        targetType: 'section',
        section: 'habits',
        until: DateTime.utc(2026, 9, 21),
      );
      expect(await repo.all(), hasLength(2));
      await repo.purgeExpired(DateTime.utc(2026, 9, 22));
      final left = await repo.all();
      expect(left.single.targetId, 'L');
      await repo.unmuteTarget('checklist', 'L');
      expect(await repo.all(), isEmpty);
    });
  });

  group('InboxRepository (T7.3.01 convergence rules)', () {
    InboxDelivery delivery(
      String key, {
      String via = 'local',
      DateTime? at,
      bool late = false,
    }) => InboxDelivery(
      dedupeKey: key,
      category: InboxCategory.reminder,
      title: 'Gym',
      body: 'Starts in 10 min',
      fireAt: DateTime.utc(2026, 9, 22, 5, 50),
      section: NotificationSection.planner,
      sourceType: 'task',
      sourceId: 't1',
      via: via,
      deliveredAt: at,
      late: late,
      payload: const {'dk': 'k1', 'link': '/task/t1'},
    );

    test('same dedupe key → one row; delivery fields merge (earliest, union, late sticky)', () async {
      final repo = h.read(inboxRepositoryProvider);
      expect(
        await repo.upsertDelivered(
          delivery('k1', at: DateTime.utc(2026, 9, 22, 5, 51)),
        ),
        isTrue,
      );
      expect(
        await repo.upsertDelivered(
          delivery(
            'k1',
            via: 'push',
            at: DateTime.utc(2026, 9, 22, 5, 50),
            late: true,
          ),
        ),
        isFalse,
      );
      final rows = await repo.inbox();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.id, Ids.inbox('k1'));
      expect(row.deliveredVia, ['local', 'push']);
      expect(row.deliveredAt, DateTime.utc(2026, 9, 22, 5, 50));
      expect(row.late, isTrue);
    });

    test(
      'automatic inserts are stamped at the fire instant so user edits win',
      () async {
        final repo = h.read(inboxRepositoryProvider);
        await repo.upsertDelivered(delivery('k1'));
        final outbox = await h.db.select(h.db.syncOutbox).get();
        expect(
          outbox.single.clock,
          contains(
            DateTime.utc(
              2026,
              9,
              22,
              5,
              50,
            ).millisecondsSinceEpoch.toString().padLeft(15, '0'),
          ),
        );
      },
    );

    test('unread count honours read, dismissed and snoozed rows; dismiss is undoable', () async {
      final repo = h.read(inboxRepositoryProvider);
      await repo.upsertDelivered(delivery('a'));
      await repo.upsertDelivered(delivery('b'));
      await repo.upsertDelivered(delivery('c'));
      expect(await repo.watchUnreadCount().first, 3);
      await repo.markRead([Ids.inbox('a')]);
      final dismissed = await repo.dismiss(Ids.inbox('b'));
      await repo.setSnoozedUntil(Ids.inbox('c'), DateTime.utc(2026, 9, 22, 7));
      expect(await repo.watchUnreadCount().first, 0);
      expect(await repo.watchSnoozed().first, hasLength(1));
      await h.read(syncWriterProvider).revert(dismissed);
      expect(await repo.watchUnreadCount().first, 1);
      await repo.markUnread(Ids.inbox('a'));
      expect(await repo.watchUnreadCount().first, 2);
      await repo.markAllRead();
      expect(await repo.watchUnreadCount().first, 0);
    });

    test('acknowledged keys include acted, opened and dismissed rows (by chain base key)', () async {
      final repo = h.read(inboxRepositoryProvider);
      await repo.upsertDelivered(delivery('base'));
      await repo.upsertDelivered(
        InboxDelivery(
          dedupeKey: 'nag1',
          category: InboxCategory.nag,
          title: 'Gym',
          fireAt: DateTime.utc(2026, 9, 22, 5, 55),
          payload: const {'dk': 'nag1', 'bk': 'base'},
        ),
      );
      await repo.markActed(Ids.inbox('nag1'), 'done');
      final keys = await repo.acknowledgedKeys(
        since: DateTime.utc(2026, 9, 21),
      );
      expect(keys, {'base'});
      final filtered = await repo.inbox(
        filter: const InboxFilter(category: InboxCategory.nag),
      );
      expect(filtered.single.dedupeKey, 'nag1');
    });

    test('history per source and local retention cleanup', () async {
      final repo = h.read(inboxRepositoryProvider);
      await repo.upsertDelivered(delivery('old'));
      expect(await repo.watchForSource('task', 't1').first, hasLength(1));
      h.clock.advance(const Duration(days: 91));
      expect(await repo.purgeOlderThan(const Duration(days: 90)), 1);
      expect(await repo.inbox(), isEmpty);
    });
  });
}
