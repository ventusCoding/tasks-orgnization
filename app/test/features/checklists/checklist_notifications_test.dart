import 'dart:convert';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/checklists/application/checklist_notifications.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_notification_targets.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/notifications/application/action_dispatcher.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_pipeline.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('target projection (pure)', () {
    setUpAll(tzdata.initializeTimeZones);
    final zones = TzZoneResolver();
    final t0 = DateTime.utc(2026, 9, 22, 6);
    ChecklistItem item(
      String id, {
      String? parent,
      ItemStatus status = ItemStatus.todo,
      LocalDateTime? due,
      DateTime? followUp,
      String key = 'a0',
      DateTime? completedAt,
      String notifyMode = 'inherit',
    }) {
      final done = completedAt ?? (status == ItemStatus.completed ? t0.subtract(const Duration(hours: 1)) : null);
      return ChecklistItem(
        id: id,
        checklistId: 'L',
        parentId: parent,
        sortKey: key,
        text: id,
        status: status,
        statusChangedAt: done ?? t0.subtract(const Duration(days: 2)),
        completedAt: done,
        followUpAt: followUp,
        dueLocal: due,
        notifyMode: notifyMode,
        createdAt: t0.subtract(const Duration(days: 3)),
        updatedAt: t0.subtract(const Duration(days: 1)),
      );
    }

    List<NotificationTarget> build(List<ChecklistItem> items, {List<ItemStatusChange> changes = const []}) =>
        ChecklistNotificationTargets.build(
          lists: [
            Checklist(
              id: 'L',
              sortKey: 'a0',
              title: 'Trip',
              categoryId: 'cat',
              dueLocal: LocalDate(2026, 9, 25).atStartOfDay,
              notifyMode: 'custom',
            ),
          ],
          items: items,
          zones: zones,
          deviceZone: 'Europe/Paris',
          fromUtc: t0,
          toUtc: t0.add(const Duration(days: 7)),
          statusChanges: changes,
          untitled: 'Untitled',
        );

    test('items carry anchors, inheritance, guards, variables and default actions', () {
      final targets = build([
        item('Documents', key: 'a0'),
        item(
          'Visa',
          parent: 'Documents',
          key: 'a0',
          status: ItemStatus.waiting,
          followUp: DateTime.utc(2026, 9, 22, 9),
        ),
        item(
          'Passport',
          parent: 'Documents',
          key: 'a1',
          due: LocalDate(2026, 9, 23).atTime(LocalTime(10, 0)),
          notifyMode: 'off',
        ),
        item('Socks', key: 'a1', due: LocalDate(2026, 9, 24).atStartOfDay),
        item('Hat', key: 'a2', status: ItemStatus.completed, completedAt: t0.subtract(const Duration(days: 3))),
      ]);
      NotificationTarget of(String id) => targets.firstWhere((t) => t.id == id);

      final list = of('L');
      expect(list.type, NotificationTargetType.checklist);
      expect(list.notifyMode, NotifyMode.custom);
      expect(list.itemKind, ItemKind.dateOnly);
      expect(list.due, DateTime.utc(2026, 9, 24, 22), reason: 'start of Sept 25 in Paris (UTC+2)');
      expect(list.variables['total'], 4);
      expect(list.variables['done'], 1);
      expect(list.variables['open_items'], 4);
      expect(list.isOpen, isTrue);

      final visa = of('Visa');
      expect(visa.type, NotificationTargetType.checklistItem);
      expect(visa.section, NotificationSection.checklists);
      expect(visa.checklistId, 'L');
      expect(visa.categoryId, 'cat');
      expect(visa.ancestorItemIds, ['Documents']);
      expect(visa.followUp, DateTime.utc(2026, 9, 22, 9));
      expect(visa.itemKind, ItemKind.any);
      expect(visa.status, 'waiting');
      expect(visa.guard, NotificationGuard.checklistItemStatusIn('Visa', const ['waiting', 'blocked']));
      expect(visa.defaultActions, ChecklistNotificationTargets.followUpActions);
      expect(visa.variables['checklist_title'], 'Trip');
      expect(visa.variables['parent_path'], 'Documents');
      expect(visa.variables['progress'], 25);

      final passport = of('Passport');
      expect(passport.due, DateTime.utc(2026, 9, 23, 8), reason: 'floating 10:00 in the device zone');
      expect(passport.itemKind, ItemKind.timed);
      expect(passport.notifyMode, NotifyMode.off);
      expect(passport.guard, NotificationGuard.itemNotCompleted('Passport'));

      expect(of('Socks').itemKind, ItemKind.dateOnly);
      expect(targets.any((t) => t.id == 'Hat'), isFalse, reason: 'closed items without recent activity are left out');
    });

    test('events: status changes, children complete and child overdue', () {
      final targets = build(
        [
          item('P', key: 'a0'),
          item('C1', parent: 'P', key: 'a0', status: ItemStatus.completed),
          item('C2', parent: 'P', key: 'a1', status: ItemStatus.completed),
          item('Q', key: 'a1'),
          item('Q1', parent: 'Q', key: 'a0', due: LocalDate(2026, 9, 23).atStartOfDay),
          item('W', key: 'a2', status: ItemStatus.blocked),
        ],
        changes: [
          ItemStatusChange(itemId: 'W', from: ItemStatus.todo, to: ItemStatus.blocked, at: t0),
          ItemStatusChange(itemId: 'W', to: ItemStatus.waiting, at: t0.subtract(const Duration(days: 5))),
        ],
      );
      NotificationTarget of(String id) => targets.firstWhere((t) => t.id == id);
      expect(of('P').events.map((e) => e.kind), ['children_complete']);
      final overdue = of('Q').events.single;
      expect(overdue.kind, 'child_overdue');
      expect(overdue.data['childId'], 'Q1');
      expect(overdue.at, DateTime.utc(2026, 9, 23, 22), reason: 'a date-only due is overdue when its day ends');
      final w = of('W').events.single;
      expect(w.kind, 'status_change');
      expect(w.data, {'from': 'todo', 'to': 'blocked'});
      // Recently completed children are returned closed so replans cancel their reminders.
      expect(of('C1').isOpen, isFalse);
    });

    test('a fully completed list is closed', () {
      final targets = build([
        item('A', status: ItemStatus.completed),
        item('B', key: 'a1', status: ItemStatus.cancelled),
      ]);
      expect(targets.firstWhere((t) => t.id == 'L').isOpen, isFalse);
    });
  });

  group('source, pipeline and actions', () {
    late TestHarness h;
    late InMemoryLocalNotificationsPort port;
    late String listId;
    late String visa;
    late String passport;

    setUp(() async {
      h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6), zone: 'Europe/Paris');
      port = h.read(localNotificationsPortProvider) as InMemoryLocalNotificationsPort;
      await seedNotificationDefaults(h.read);
      listId =
          (await h
                  .read(checklistsRepositoryProvider)
                  .create(
                    title: 'Trip',
                    items: [
                      NodeSpec(
                        text: 'Documents',
                        children: [
                          const NodeSpec(text: 'Visa'),
                          NodeSpec(text: 'Passport', dueLocal: LocalDate(2026, 9, 23).atTime(LocalTime(10, 0))),
                        ],
                      ),
                    ],
                  ))
              .id;
      final items = await h.read(checklistItemsRepositoryProvider).items(listId);
      visa = items.firstWhere((i) => i.text == 'Visa').id;
      passport = items.firstWhere((i) => i.text == 'Passport').id;
      await h
          .read(checklistServiceProvider)
          .changeStatus(listId, [visa], ItemStatus.waiting, note: 'embassy', followUpAt: DateTime.utc(2026, 9, 22, 9));
    });
    tearDown(() => h.dispose());

    Future<void> replan() => h.read(notificationPipelineProvider).run('test');

    test('the source is registered statically and feeds the checklists section', () {
      final sources = h.read(notificationTargetSourcesProvider);
      expect(sources.whereType<ChecklistsNotificationSource>(), hasLength(1));
      expect(
        findActionHandler(
          h.read(notificationActionHandlersProvider),
          'mark_ongoing',
          NotificationTargetType.checklistItem,
        ),
        isA<ChecklistNotificationActions>(),
      );
    });

    test('seeded defaults schedule the follow-up and the due reminder with checklist actions', () async {
      await replan();
      final scheduled = port.scheduled.values.toList()..sort((a, b) => a.fireAt!.compareTo(b.fireAt!));
      expect(scheduled.map((r) => r.fireAt), [DateTime.utc(2026, 9, 22, 9), DateTime.utc(2026, 9, 23, 8)]);
      expect(scheduled.first.actions.map((a) => a.id), ['mark_ongoing', 'done', 'snooze']);
      expect(scheduled.first.channelId, 'dl.checklists.standard.v1');
      final payload = jsonDecode(scheduled.first.payload) as Map<String, Object?>;
      expect(payload['link'], '/lists/$listId?item=$visa');
    });

    test('actions update the item through the status service; repeats are ignored; guard follows', () async {
      await replan();
      final followUp = port.scheduled.values.firstWhere((r) => r.fireAt == DateTime.utc(2026, 9, 22, 9));
      h.clock.set(DateTime.utc(2026, 9, 22, 9, 1));
      final dispatcher = h.read(notificationActionDispatcherProvider);
      final response = OsResponse(id: followUp.id, actionId: 'mark_ongoing', payload: followUp.payload);
      await dispatcher.handleResponse(response);
      final second = await dispatcher.handleResponse(response);
      expect(second.duplicate, isTrue);
      final visaItem = (await h.read(checklistItemsRepositoryProvider).liveById(visa))!;
      expect(visaItem.status, ItemStatus.ongoing);
      final causes = await h.db
          .customSelect(
            r"SELECT json_extract(payload, '$.cause') AS cause FROM activity_events "
            "WHERE entity_id = '$visa' AND event_type = 'status_changed' ORDER BY occurred_at DESC LIMIT 1",
          )
          .getSingle();
      expect(causes.read<String>('cause'), 'notification');

      final due = port.scheduled.values.firstWhere((r) => r.fireAt == DateTime.utc(2026, 9, 23, 8));
      await dispatcher.handleResponse(OsResponse(id: due.id, actionId: 'done', payload: due.payload));
      final passportItem = (await h.read(checklistItemsRepositoryProvider).liveById(passport))!;
      expect(passportItem.status, ItemStatus.completed);

      final source = h.read(notificationTargetSourcesProvider).whereType<ChecklistsNotificationSource>().single;
      NotificationTarget ref(String id) => NotificationTarget(
        type: NotificationTargetType.checklistItem,
        id: id,
        section: NotificationSection.checklists,
        title: '',
      );
      expect(await source.guardOpen(ref(passport)), isFalse);
      expect(await source.guardOpen(ref(visa)), isTrue);
      await h.read(checklistsRepositoryProvider).setArchived(listId, archived: true);
      expect(await source.guardOpen(ref(visa)), isFalse, reason: 'archived lists never notify');
    });

    test('background isolate: a bare container completes the item and the replan drops its reminders', () async {
      await replan();
      final followUp = port.scheduled.values.firstWhere((r) => r.fireAt == DateTime.utc(2026, 9, 22, 9));
      h.clock.set(DateTime.utc(2026, 9, 22, 9, 1));
      // Exactly what NotificationBackground.run builds (env, database, device id — no UI and no
      // feature overrides) plus the fake clock; the database is shared like the WAL connection.
      final bg = ProviderContainer(
        overrides: [
          envProvider.overrideWithValue(h.read(envProvider)),
          appDatabaseProvider.overrideWithValue(h.db),
          clockProvider.overrideWithValue(h.clock),
          deviceIdProvider.overrideWithValue('device-test'),
        ],
      );
      addTearDown(bg.dispose);
      final result = await NotificationActionDispatcher(bg.read).handleResponse(
        OsResponse(id: followUp.id, actionId: 'complete_item', payload: followUp.payload, background: true),
      );
      expect(result.duplicate, isFalse);
      await NotificationPipeline(bg.read).run('background-action', foreground: false);

      final visaItem = (await h.read(checklistItemsRepositoryProvider).liveById(visa))!;
      expect(visaItem.status, ItemStatus.completed);
      expect(visaItem.completedAt, isNotNull);
      final cause = await h.db
          .customSelect(
            r"SELECT json_extract(payload, '$.cause') AS cause FROM activity_events "
            "WHERE entity_id = '$visa' AND event_type = 'status_changed' ORDER BY occurred_at DESC LIMIT 1",
          )
          .getSingle();
      expect(cause.read<String>('cause'), 'notification');
      // The background replan sees the statically registered checklists source: the other
      // item's future reminder survives, the completed item keeps none.
      final entries = await bg.read(localScheduleStoreProvider).all();
      final future = entries.where((e) => e.fireAt.isAfter(h.clock.nowUtc())).toList();
      expect(future.where((e) => e.content['tid'] == passport).map((e) => e.fireAt), [DateTime.utc(2026, 9, 23, 8)]);
      expect(future.where((e) => e.content['tid'] == visa), isEmpty);
    });

    test('an action on a deleted item fails with a localized message; list actions open the list', () async {
      final handler = h.read(notificationActionHandlersProvider).whereType<ChecklistNotificationActions>().single;
      NotificationActionContext ctx(String action, NotificationTargetType type, String id) => NotificationActionContext(
        actionId: action,
        payload: NotificationPayload(dedupeKey: 'k-$id', targetType: type, targetId: id),
        origin: ActionOrigin.inbox,
        now: h.clock.nowUtc(),
        read: h.container.read,
      );
      await h.read(checklistServiceProvider).run(listId, (tree, c, _) => TreeOps.deleteSubtrees(tree, c, [visa]));
      final gone = await handler.handle(ctx('complete_item', NotificationTargetType.checklistItem, visa));
      expect(gone.success, isFalse);
      expect(gone.message, 'This item no longer exists');

      final list = await handler.handle(ctx('done', NotificationTargetType.checklist, listId));
      expect(list.openLink, '/lists/$listId');
      expect((await h.read(checklistItemsRepositoryProvider).liveById(passport))!.status, ItemStatus.todo);
    });
  });
}
