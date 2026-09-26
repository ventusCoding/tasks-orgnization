import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Variable;
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/attachments/domain/attachment.dart';
import 'package:everslot/features/checklists/application/checklist_service.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/data/checklist_items_repository.dart';
import 'package:everslot/features/checklists/data/checklists_repository.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:everslot/features/notifications/application/notification_host_api.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  late TestHarness h;
  late ChecklistsRepository lists;
  late ChecklistItemsRepository items;
  late ChecklistService service;

  setUp(() {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 23, 9));
    lists = h.read(checklistsRepositoryProvider);
    items = h.read(checklistItemsRepositoryProvider);
    service = h.read(checklistServiceProvider);
  });
  tearDown(() => h.dispose());

  NodeSpec n(String text, [List<NodeSpec> kids = const [], ItemStatus status = ItemStatus.todo]) =>
      NodeSpec(text: text, children: kids, status: status);

  Future<String> create(List<NodeSpec> nodes, {String title = 'List'}) async =>
      (await lists.create(title: title, items: nodes)).id;

  Future<ChecklistTree> treeOf(String id) async => ChecklistTree.build(await items.items(id));

  String render(ChecklistTree t) =>
      t.order.map((id) => '${'  ' * t.depthOf(id)}${t[id]!.text}').join('\n');

  group('items repository', () {
    test('apply writes rows, outbox patches and events under ONE op id', () async {
      final id = await create([n('A'), n('B')]);
      final t = await treeOf(id);
      final a = t.order.first;
      final result = await service.run(id, (tree, ctx, _) => TreeOps.indent(tree, ctx, [t.order[1]]));
      expect(render(await treeOf(id)), 'A\n  B');
      final opId = result!.record.opId;
      final outbox = await h.db
          .customSelect('SELECT DISTINCT op_id FROM sync_outbox WHERE op_id = ?', variables: [Variable<String>(opId)])
          .get();
      expect(outbox, hasLength(1));
      final events = await (h.db.select(h.db.activityEvents)..where((e) => e.eventType.equals('moved'))).get();
      expect(events.single.entityId, t.order[1]);
      final payload = jsonDecode(events.single.payload) as Map<String, dynamic>;
      expect(payload['opId'], opId);
      expect(payload['toParentId'], a);
      expect(payload['cause'], 'user');
    });

    test('status cascades carry their own cause inside a user operation', () async {
      final id = await create([
        n('P', [n('a'), n('b', const [], ItemStatus.completed)]),
      ]);
      final t = await treeOf(id);
      await service.changeStatus(id, [t.childIds(t.order.first).first], ItemStatus.completed);
      final t2 = await treeOf(id);
      expect(t2[t2.order.first]!.status, ItemStatus.completed);
      expect(t2[t2.order.first]!.completedAt, h.clock.nowUtc());
      final causes = [
        for (final e in await (h.db.select(h.db.activityEvents)..where((e) => e.eventType.equals('status_changed'))).get())
          (jsonDecode(e.payload) as Map)['cause'],
      ];
      expect(causes, unorderedEquals(['user', 'auto_rollup']));
      final history = await items.watchStatusEvents(t.order.first).first;
      expect(history.single.to, ItemStatus.completed);
    });

    test('delete subtree tombstones attachments; undo restores them; duplicate copies by reference', () async {
      final id = await create([
        n('A', [n('A1')]),
      ]);
      final t = await treeOf(id);
      final a1 = t.order[1];
      final attRepo = AttachmentsRepository(h.db, h.read(syncWriterProvider), () => 'user-1');
      await attRepo.insertAll([
        NewAttachment(
          id: 'att',
          ownerType: AttachmentOwnerType.checklistItem,
          ownerId: a1,
          storagePath: 'user-1/att/x.jpg',
          fileName: 'x.jpg',
          mimeType: 'image/jpeg',
          byteSize: 3,
        ),
      ]);
      final dup = await service.run(id, (tree, ctx, _) => TreeOps.duplicateSubtrees(tree, ctx, [t.order.first]));
      final t2 = await treeOf(id);
      expect(t2.length, 4);
      final copyOfA1 = dup!.change.copiedItemIds[a1]!;
      final copied = await attRepo.listFor(AttachmentOwnerType.checklistItem, copyOfA1);
      expect(copied.single.storagePath, 'user-1/att/x.jpg');
      expect(copied.single.id, isNot('att'));
      final del = await service.run(id, (tree, ctx, _) => TreeOps.deleteSubtrees(tree, ctx, [t.order.first]));
      expect((await treeOf(id)).length, 2);
      expect(await attRepo.listFor(AttachmentOwnerType.checklistItem, a1), isEmpty);
      await h.read(syncWriterProvider).revert(del!.record);
      expect((await treeOf(id)).length, 4);
      expect(await attRepo.listFor(AttachmentOwnerType.checklistItem, a1), hasLength(1));
    });

    test('reminder rules follow item copies and deletes in the same operation; undo restores them', () async {
      final id = await create([
        n('A', [n('A1')]),
      ]);
      final t = await treeOf(id);
      final a = t.order.first;
      final a1 = t.childIds(a).first;
      final spec = NotificationRuleSpec.fromJson(const {
        'v': 1,
        'trigger': {'type': 'relative', 'anchor': 'start'},
      });
      await h
          .read(syncWriterProvider)
          .run(
            (tx) => h
                .read(notificationHostApiProvider)
                .saveDraftInTx(
                  tx,
                  NotificationRulesDraft(
                    rules: [
                      RuleDraft(
                        targetType: RuleTargetType.checklistItem,
                        section: NotificationSection.checklists,
                        spec: spec,
                      ),
                    ],
                  ),
                  type: NotificationTargetType.checklistItem,
                  targetId: a1,
                ),
          );
      Future<int> rulesOf(String itemId) async => (await h.db
              .customSelect(
                'SELECT COUNT(*) AS n FROM notification_rules WHERE target_id = ? AND deleted_at IS NULL',
                variables: [Variable<String>(itemId)],
              )
              .getSingle())
          .read<int>('n');
      expect(await rulesOf(a1), 1);

      final dup = await service.run(id, (tree, ctx, _) => TreeOps.duplicateSubtrees(tree, ctx, [a]));
      expect(await rulesOf(dup!.change.copiedItemIds[a1]!), 1);

      final del = await service.run(id, (tree, ctx, _) => TreeOps.deleteSubtrees(tree, ctx, [a]));
      expect(await rulesOf(a1), 0);
      await h.read(syncWriterProvider).revert(del!.record);
      expect(await rulesOf(a1), 1);
    });

    test('subtreeIds for a depth-50 chain; watchItems on 5 000 rows', () async {
      final id = await create([]);
      var parent = 'root';
      final chain = [n('leaf')];
      var node = chain.single;
      for (var i = 0; i < 49; i++) {
        node = n('lvl$i', [node]);
      }
      await service.run(id, (tree, ctx, _) => TreeOps.insertNodes(tree, ctx, [node]));
      final t = await treeOf(id);
      parent = t.order.first;
      expect(await items.subtreeIds(parent), hasLength(50));
      // 5 000 rows.
      await service.run(
        id,
        (tree, ctx, _) => TreeOps.insertNodes(tree, ctx, [for (var i = 0; i < 4950; i++) n('row $i')]),
      );
      final sw = Stopwatch()..start();
      final rows = await items.watchItems(id).first;
      sw.stop();
      expect(rows, hasLength(5000));
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('property: random commands then undo all returns every row to its original state', () async {
      final id = await create([
        n('A', [n('A1'), n('A2')]),
        n('B'),
        n('C', [n('C1')]),
      ]);
      Future<Map<String, String>> snapshot() async => {
        for (final r in await h.db
            .customSelect(
              "SELECT id, parent_id, sort_key, text, status, deleted_at FROM checklist_items WHERE checklist_id = ?",
              variables: [Variable<String>(id)],
            )
            .get())
          r.read<String>('id'): jsonEncode(r.data..remove('id')),
      };
      final before = await snapshot();
      final rnd = math.Random(5);
      final records = <OpRecord>[];
      for (var step = 0; step < 50; step++) {
        final t = await treeOf(id);
        final pick = t.order[rnd.nextInt(t.length)];
        final result = await service.run(id, (tree, ctx, c) {
          switch (rnd.nextInt(7)) {
            case 0:
              return TreeOps.indent(tree, ctx, [pick]);
            case 1:
              return TreeOps.outdent(tree, ctx, [pick]);
            case 2:
              return TreeOps.insertAfter(tree, ctx, pick, text: 'new $step');
            case 3:
              return TreeOps.moveUp(tree, ctx, [pick]);
            case 4:
              return tree.length > 4 ? TreeOps.deleteSubtrees(tree, ctx, [pick]) : TreeOps.duplicateSubtrees(tree, ctx, [pick]);
            case 5:
              return TreeOps.setFields(tree, ctx, pick, {'text': 'edited $step'});
            default:
              return TreeOps.moveTo(tree, ctx, [pick], newParentId: null);
          }
        });
        if (result != null) records.add(result.record);
      }
      final writer = h.read(syncWriterProvider);
      for (final r in records.reversed) {
        await writer.revert(r);
      }
      final after = await snapshot();
      // Rows inserted by the random ops are tombstoned; the original rows are identical.
      for (final e in before.entries) {
        expect(after[e.key], e.value, reason: e.key);
      }
      expect(after.keys.toSet().difference(before.keys.toSet()).every((k) => jsonDecode(after[k]!)['deleted_at'] != null), isTrue);
    });
  });

  group('checklists repository', () {
    test('new cards go to the top of their section; pin keeps order; archive filters', () async {
      final first = await create([], title: 'first');
      final second = await create([], title: 'second');
      var board = await lists.watchBoard().first;
      expect(board.map((c) => c.title), ['second', 'first']);
      await lists.setPinned(first, pinned: true);
      board = await lists.watchBoard().first;
      expect(board.firstWhere((c) => c.id == first).isPinned, isTrue);
      await lists.setArchived(second, archived: true);
      expect((await lists.watchBoard().first).map((c) => c.id), [first]);
      expect((await lists.watchBoard(archived: true).first).map((c) => c.id), [second]);
    });

    test('delete of a 1 000-item list is one transaction; restore(opId) restores only that delete', () async {
      final id = await create([for (var i = 0; i < 1000; i++) n('i$i')]);
      final t = await treeOf(id);
      // An item deleted earlier must stay deleted.
      await service.run(id, (tree, ctx, _) => TreeOps.deleteSubtrees(tree, ctx, [t.order.first]));
      h.clock.advance(const Duration(minutes: 1));
      final sw = Stopwatch()..start();
      final record = await lists.delete(id);
      sw.stop();
      expect(await items.items(id), isEmpty);
      expect((await lists.byId(id))!.deletedAt, isNotNull);
      final ops = await h.db
          .customSelect(
            "SELECT COUNT(DISTINCT op_id) AS n FROM sync_outbox WHERE op_id = ?",
            variables: [Variable<String>(record.opId)],
          )
          .getSingle();
      expect(ops.read<int>('n'), 1);
      await lists.restore(record.opId);
      expect((await lists.byId(id))!.deletedAt, isNull);
      final restored = await items.items(id);
      expect(restored, hasLength(999));
      expect(restored.any((i) => i.id == t.order.first), isFalse);
    });

    test('duplicate copies items, attachments by reference and leaves the original untouched', () async {
      final id = await create([
        n('A', [n('A1', const [], ItemStatus.completed)]),
      ]);
      final copy = await lists.duplicate(id, title: 'Copy of List', resetStatuses: true);
      final t = await treeOf(copy.id);
      expect(render(t), 'A\n  A1');
      expect(t.items.every((i) => i.status == ItemStatus.todo), isTrue);
      expect((await treeOf(id)).items.last.status, ItemStatus.completed);
      expect((await lists.byId(copy.id))!.title, 'Copy of List');
    });

    test('card summaries: rollup, first rows at depth ≤ 2, more count, stale', () async {
      final id = await create([
        n('A', [
          n('A1', [
            n('A1a', [n('deep')]),
          ]),
          n('A2', const [], ItemStatus.completed),
        ]),
        n('B', const [], ItemStatus.blocked),
        n('C', const [], ItemStatus.waiting),
        n('D'),
        n('E'),
      ]);
      final summaries = await lists.watchCardSummaries([id], now: h.clock.nowUtc()).first;
      final s = summaries[id]!;
      expect(s.rows.map((r) => '${r.depth}${r.text}'), ['0A', '1A1', '2A1a', '1A2', '0B', '0C']);
      expect(s.itemCount, 9);
      expect(s.moreCount, 3);
      expect((s.rollup.leafCompleted, s.rollup.leafCountable), (1, 6));
      expect((s.rollup.blockedBelow, s.rollup.waitingBelow), (1, 1));
      final later = await lists.watchCardSummaries([id], now: h.clock.nowUtc().add(const Duration(days: 20))).first;
      expect(later[id]!.staleCount, 8);
    });

    test('smart views: counts and items with breadcrumbs; archived and deleted excluded', () async {
      final id = await create([
        n('Project', [n('Supplier quote')]),
        n('Other'),
      ]);
      final t = await treeOf(id);
      final quote = t.order[1];
      await service.changeStatus(
        id,
        [quote],
        ItemStatus.waiting,
        note: 'supplier reply',
        followUpAt: h.clock.nowUtc().subtract(const Duration(hours: 1)),
      );
      await service.changeStatus(id, [t.order[2]], ItemStatus.blocked);
      final counts = await lists.watchSmartCounts(now: h.clock.nowUtc()).first;
      expect(counts, const SmartCounts(waiting: 1, blocked: 1, followUps: 1));
      final waiting = await lists.watchSmartItems(SmartKind.waiting, now: h.clock.nowUtc()).first;
      expect(waiting.single.item.statusNote, 'supplier reply');
      expect(waiting.single.path, ['Project']);
      expect(waiting.single.checklistTitle, 'List');
      final follow = await lists.watchSmartItems(SmartKind.followUps, now: h.clock.nowUtc()).first;
      expect(follow.single.item.id, quote);
      await lists.setArchived(id, archived: true);
      expect((await lists.watchSmartCounts(now: h.clock.nowUtc()).first).isEmpty, isTrue);
    });

    test('card thumbnails prefer checklist-level images, then item images', () async {
      final id = await create([n('A')]);
      final t = await treeOf(id);
      final attRepo = AttachmentsRepository(h.db, h.read(syncWriterProvider), () => 'user-1');
      await attRepo.insertAll([
        NewAttachment(
          id: 'item-img',
          ownerType: AttachmentOwnerType.checklistItem,
          ownerId: t.order.first,
          storagePath: 'u/item-img/a.jpg',
          fileName: 'a.jpg',
          mimeType: 'image/jpeg',
          byteSize: 1,
        ),
      ]);
      expect((await lists.watchCardThumbnails([id]).first)[id]!.id, 'item-img');
      await attRepo.insertAll([
        NewAttachment(
          id: 'list-img',
          ownerType: AttachmentOwnerType.checklist,
          ownerId: id,
          storagePath: 'u/list-img/b.png',
          fileName: 'b.png',
          mimeType: 'image/png',
          byteSize: 1,
        ),
      ]);
      expect((await lists.watchCardThumbnails([id]).first)[id]!.id, 'list-img');
      await lists.update(id, coverAttachmentId: 'item-img');
      expect((await lists.watchCardThumbnails([id]).first)[id]!.id, 'item-img');
    });

    test('settings round-trip and header edits are undoable', () async {
      final id = await create([]);
      final record = await lists.update(
        id,
        title: 'Groceries',
        body: 'for the week',
        color: 0xFFF59E0B,
        settings: const ChecklistSettings(hideCheckboxes: true, requireReasonFor: {ItemStatus.blocked}),
      );
      final c = (await lists.byId(id))!;
      expect(c.settings.hideCheckboxes, isTrue);
      expect(c.settings.requiresReason(ItemStatus.blocked), isTrue);
      await h.read(syncWriterProvider).revert(record);
      final back = (await lists.byId(id))!;
      expect(back.title, 'List');
      expect(back.settings.hideCheckboxes, isFalse);
    });
  });

  group('local UI state', () {
    test('collapse set, view state and board config persist', () async {
      final store = h.read(checklistUiStateStoreProvider);
      await store.setCollapsed('c1', ['a', 'b'], collapsed: true, at: h.clock.nowUtc());
      await store.setCollapsed('c1', ['b'], collapsed: false, at: h.clock.nowUtc());
      expect(await store.collapsed('c1'), {'a'});
      await store.replaceCollapsed('c1', {'x', 'y'}, at: h.clock.nowUtc());
      expect(await store.watchCollapsed('c1').first, {'x', 'y'});
      await store.save(
        'c1',
        mode: OpenMode.preview,
        focusItemId: 'x',
        viewType: ChecklistViewType.kanban,
        filter: const ItemFilter(hideCompleted: true),
        sort: const ItemSort(by: ItemSortBy.status),
        scrollOffset: 120,
        openedAt: h.clock.nowUtc(),
      );
      final s = await store.get('c1');
      expect(s.mode, OpenMode.preview);
      expect(s.focusItemId, 'x');
      expect(s.viewType, ChecklistViewType.kanban);
      expect(s.filter.hideCompleted, isTrue);
      expect(s.sort.by, ItemSortBy.status);
      expect(s.scrollOffset, 120);
      final boardStore = h.read(boardConfigStoreProvider);
      await boardStore.save(const BoardConfig(layout: BoardLayout.list, sort: BoardSort.title));
      final cfg = await boardStore.watch().first;
      expect(cfg.layout, BoardLayout.list);
      expect(BoardConfig.fromJson(cfg.toJson()), cfg);
    });
  });
}
