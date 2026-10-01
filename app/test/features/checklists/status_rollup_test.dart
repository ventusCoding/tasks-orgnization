import 'dart:math' as math;

import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/drop_target.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:everslot/features/checklists/domain/status_engine.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import 'checklist_test_support.dart';

void main() {
  final now = DateTime.utc(2026, 9, 23, 10);
  const noAuto = ChecklistSettings(autoCompleteParent: false);

  group('status transitions', () {
    test('all 36 from→to combinations produce correct fields and events', () {
      for (final from in ItemStatus.values) {
        for (final to in ItemStatus.values) {
          final items = outline('X:${from.name}');
          final follow = now.add(const Duration(days: 1));
          final ch = StatusEngine.apply(
            ChecklistTree.build(items),
            noAuto,
            ids: ['X'],
            to: to,
            now: now,
            note: 'why',
            followUpAt: follow,
          );
          final v = ch.valuesFor('X');
          if (from == to) {
            // Same status + new note → status_note_changed.
            expect(ch.events.single.eventType, 'status_note_changed', reason: '$from→$to');
            expect(v!['status_note'], 'why');
            continue;
          }
          expect(v!['status'], to.name, reason: '$from→$to');
          expect(v['status_changed_at'], now);
          expect(v['completed_at'], to == ItemStatus.completed ? now : null, reason: '$from→$to');
          expect(v['status_note'], 'why');
          expect(v['follow_up_at'], to.keepsFollowUp ? follow : null, reason: '$from→$to');
          final e = ch.events.single;
          expect(e.eventType, 'status_changed');
          expect(e.payload['from'], from.name);
          expect(e.payload['to'], to.name);
          expect(e.payload['note'], 'why');
          expect(e.cause, isNull, reason: 'uses the operation cause');
          // completed_at is never left set on a non-completed item.
          final after = applyChange(items, ch).single;
          expect(after.completedAt != null, after.status == ItemStatus.completed);
        }
      }
    });

    test('follow-up is kept for waiting/blocked, cleared elsewhere unless kept', () {
      final follow = now.add(const Duration(days: 2));
      var items = applyChange(
        outline('X'),
        StatusEngine.apply(tree('X'), noAuto, ids: ['X'], to: ItemStatus.waiting, now: now, followUpAt: follow),
      );
      items = applyChange(
        items,
        StatusEngine.apply(ChecklistTree.build(items), noAuto, ids: ['X'], to: ItemStatus.blocked, now: now),
      );
      expect(items.single.followUpAt, follow);
      final kept = StatusEngine.apply(
        ChecklistTree.build(items),
        noAuto,
        ids: ['X'],
        to: ItemStatus.ongoing,
        now: now,
        keepFollowUp: true,
      );
      expect(applyChange(items, kept).single.followUpAt, follow);
      final cleared = StatusEngine.apply(
        ChecklistTree.build(items),
        noAuto,
        ids: ['X'],
        to: ItemStatus.ongoing,
        now: now,
      );
      expect(applyChange(items, cleared).single.followUpAt, isNull);
    });

    test('same status without a note change writes nothing', () {
      final ch = StatusEngine.apply(
        tree('X:waiting'),
        noAuto,
        ids: ['X'],
        to: ItemStatus.waiting,
        now: now,
        setNote: false,
      );
      expect(ch.isEmpty, isTrue);
    });
  });

  group('cascades', () {
    test('completing the last countable child completes parents recursively (auto_rollup)', () {
      final items = outline('''
L0
  L1
    L2
      L3
        L4
          L5
            L6
              L7
                L8
                  L9
                    leaf
                    gone:cancelled''');
      final ch = StatusEngine.apply(
        ChecklistTree.build(items),
        ChecklistSettings.defaults,
        ids: ['leaf'],
        to: ItemStatus.completed,
        now: now,
      );
      final after = ChecklistTree.build(applyChange(items, ch));
      for (final id in ['L0', 'L5', 'L9', 'leaf']) {
        expect(after[id]!.status, ItemStatus.completed, reason: id);
      }
      expect(ch.events.where((e) => e.cause == 'auto_rollup'), hasLength(10));
      // Reopening the leaf reopens the whole chain (cascade).
      final reopen = StatusEngine.apply(
        after,
        ChecklistSettings.defaults,
        ids: ['leaf'],
        to: ItemStatus.waiting,
        now: now,
      );
      final reopened = ChecklistTree.build(applyChange(applyChange(items, ch), reopen));
      expect(reopened['L0']!.status, ItemStatus.todo);
      expect(reopen.events.where((e) => e.cause == 'cascade'), hasLength(10));
    });

    test('a parent whose children are all cancelled never auto-completes', () {
      final items = outline('P\n  a:cancelled\n  b');
      final ch = StatusEngine.apply(
        ChecklistTree.build(items),
        ChecklistSettings.defaults,
        ids: ['b'],
        to: ItemStatus.cancelled,
        now: now,
      );
      expect(ChecklistTree.build(applyChange(items, ch))['P']!.status, ItemStatus.todo);
    });

    test('completeChildrenWithParent: always / explicit yes / never', () {
      final t = tree('P\n  a\n  b:completed\n  c:waiting');
      expect(StatusEngine.openDescendantCount(t, 'P'), 2);
      final always = StatusEngine.apply(
        t,
        const ChecklistSettings(completeChildrenWithParent: CascadeChoice.always),
        ids: ['P'],
        to: ItemStatus.completed,
        now: now,
      );
      expect(always.valuesFor('a')!['status'], 'completed');
      expect(always.valuesFor('c')!['status'], 'completed');
      expect(always.events.where((e) => e.cause == 'cascade'), hasLength(2));
      final never = StatusEngine.apply(
        t,
        const ChecklistSettings(completeChildrenWithParent: CascadeChoice.never),
        ids: ['P'],
        to: ItemStatus.completed,
        now: now,
      );
      expect(never.valuesFor('a'), isNull);
      final asked = StatusEngine.apply(
        t,
        ChecklistSettings.defaults,
        ids: ['P'],
        to: ItemStatus.completed,
        now: now,
        completeOpenDescendants: true,
      );
      expect(asked.valuesFor('c')!['status'], 'completed');
    });

    test('list commands: uncheck all, reset all, completed subtrees', () {
      final t = tree('A:completed\n  A1:completed\nB:waiting\nC\n  C1:completed');
      expect(ListCommands.uncheckAllCount(t), 3);
      final un = ListCommands.uncheckAll(t, ChecklistSettings.defaults, now: now);
      expect(un.writes.map((w) => w.id).toSet(), {'A', 'A1', 'C1'});
      expect(un.cause, 'bulk');
      final reset = ListCommands.resetAll(t, now: now);
      expect(reset.writes.map((w) => w.id).toSet(), {'A', 'A1', 'B', 'C1'});
      expect(ListCommands.completedSubtrees(t), ['A', 'C1']);
    });
  });

  group('roll-ups', () {
    test('leaves vs children mode, cancelled excluded, badges below', () {
      final t = tree('''
P
  a:completed
  b:cancelled
  Q
    q1:completed
    q2:blocked
    q3:waiting
''');
      final r = RollupCalculator.compute(t);
      final p = r['P']!;
      expect((p.leafCompleted, p.leafCountable), (2, 4));
      expect((p.childCompleted, p.childCountable), (1, 2));
      expect(p.progress(ProgressMode.leaves), 0.5);
      expect(p.progress(ProgressMode.children), 0.5);
      expect((p.blockedBelow, p.waitingBelow, p.descendants), (1, 1, 6));
      expect(p.cancelled, 1);
      expect(r['q2']!.leafCountable, 1);
      final root = RollupCalculator.root(t, r);
      expect(root.leafCountable, 4);
    });

    test('empty and all-cancelled parents have zero progress', () {
      final t = tree('P\n  a:cancelled\nE');
      final r = RollupCalculator.compute(t);
      expect(r['P']!.total(ProgressMode.leaves), 0);
      expect(r['P']!.progress(ProgressMode.leaves), 0);
      expect(r['E']!.leafCountable, 1);
    });

    test('property: incremental path update equals full recomputation', () {
      final rnd = math.Random(7);
      var items = outline('A\n  A1\n  A2\nB\n  B1\n    B1a');
      for (var i = 0; i < 40; i++) {
        final t = ChecklistTree.build(items);
        items = applyChange(items, TreeOps.appendChild(t, ctx(), t.order[rnd.nextInt(t.length)]));
      }
      var t = ChecklistTree.build(items);
      final rollups = RollupCalculator.compute(t);
      for (var step = 0; step < 200; step++) {
        final id = t.order[rnd.nextInt(t.length)];
        final status = ItemStatus.values[rnd.nextInt(ItemStatus.values.length)];
        items = applyChange(items, StatusEngine.apply(t, noAuto, ids: [id], to: status, now: now));
        t = ChecklistTree.build(items);
        RollupCalculator.recomputePath(t, rollups, id);
        expect(rollups, RollupCalculator.compute(t));
      }
    });

    test('5 000 items roll up quickly', () {
      final rnd = math.Random(1);
      final items = [
        for (var i = 0; i < 5000; i++)
          ChecklistItem(
            id: 'n$i',
            checklistId: 'c',
            sortKey: 'a${rnd.nextInt(9) + 1}',
            parentId: i < 5 ? null : 'n${rnd.nextInt(i)}',
            status: ItemStatus.values[rnd.nextInt(6)],
          ),
      ];
      final t = ChecklistTree.build(items);
      final sw = Stopwatch()..start();
      RollupCalculator.compute(t);
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(200));
    });
  });

  group('visible list', () {
    final t = tree('''
A
  A1:completed
  A2
    A2a:waiting
B:completed
  B1:completed
C''');

    List<String> ids(List<VisibleRow> rows) => [
      for (final r in rows) '${'  ' * r.depth}${r.id}${r.isContext ? '*' : ''}',
    ];

    test('collapse hides descendants; focus re-roots with relative depth', () {
      expect(ids(VisibleListBuilder.build(t, collapsed: {'A2'})), ['A', '  A1', '  A2', 'B', '  B1', 'C']);
      final focused = VisibleListBuilder.build(t, focusRootId: 'A');
      expect(ids(focused), ['A1', 'A2', '  A2a']);
      expect(VisibleListBuilder.build(t, collapsed: {'A'}).first.collapsed, isTrue);
    });

    test('filters show matches plus dimmed ancestors, temporarily expanded', () {
      final rows = VisibleListBuilder.build(
        t,
        collapsed: {'A', 'A2'},
        filter: const ItemFilter(statuses: {ItemStatus.waiting}),
      );
      expect(ids(rows), ['A*', '  A2*', '    A2a']);
      final text = VisibleListBuilder.build(t, filter: const ItemFilter(text: 'b1'));
      expect(ids(text), ['B*', '  B1']);
      final inFocus = VisibleListBuilder.build(
        t,
        focusRootId: 'A',
        filter: const ItemFilter(text: 'a2a'),
      );
      expect(ids(inFocus), ['A2*', '  A2a']);
    });

    test('hide completed prunes finished subtrees but keeps parents of open work', () {
      final rows = VisibleListBuilder.build(
        tree('P:completed\n  x\nD:completed\n  y:completed'),
        filter: const ItemFilter(hideCompleted: true),
      );
      expect(ids(rows), ['P*', '  x']);
    });

    test('attachments / due-soon filters and view-level sort', () {
      final items = outline('b\na\nc');
      final withDue = [for (final i in items) i.id == 'c' ? i.copyWith(dueLocal: LocalDateTime.of(2026, 9, 24)) : i];
      final t2 = ChecklistTree.build(withDue);
      expect(
        ids(VisibleListBuilder.build(t2, filter: const ItemFilter(hasAttachments: true), withAttachments: {'a'})),
        ['a'],
      );
      expect(
        ids(VisibleListBuilder.build(t2, filter: const ItemFilter(dueSoon: true), today: LocalDate(2026, 9, 23))),
        ['c'],
      );
      expect(ids(VisibleListBuilder.build(t2, sort: const ItemSort(by: ItemSortBy.alphabetical))), ['a', 'b', 'c']);
      expect(ids(VisibleListBuilder.build(t)).length, 7);
      expect(ids(VisibleListBuilder.build(t, sortCompletedToBottom: true)), [
        'A',
        '  A2',
        '    A2a',
        '  A1',
        'C',
        'B',
        '  B1',
      ]);
    });

    test('expand to level N / collapse all', () {
      final level1 = VisibleListBuilder.collapsedForLevel(t, 1);
      expect(ids(VisibleListBuilder.build(t, collapsed: level1)), ['A', 'B', 'C']);
      final level2 = VisibleListBuilder.collapsedForLevel(t, 2);
      expect(ids(VisibleListBuilder.build(t, collapsed: level2)), ['A', '  A1', '  A2', 'B', '  B1', 'C']);
      expect(VisibleListBuilder.allParents(t), {'A', 'A2', 'B'});
    });

    test('filter JSON round trip', () {
      const f = ItemFilter(text: 'x', statuses: {ItemStatus.blocked}, hideCompleted: true, dueSoon: true);
      expect(ItemFilter.fromJson(f.toJson()), f);
      const s = ItemSort(by: ItemSortBy.due, descending: true);
      expect(ItemSort.fromJson(s.toJson()), s);
    });
  });

  group('drop resolver', () {
    final rows = VisibleListBuilder.build(tree('A\n  A1\nB\nC'));

    test('gap from pointer and depth from horizontal offset (RTL mirrored)', () {
      expect(DropResolver.gapAt([40, 40, 40], 10), 0);
      expect(DropResolver.gapAt([40, 40, 40], 50), 1);
      expect(DropResolver.gapAt([40, 40, 40], 200), 3);
      expect(DropResolver.desiredDepth(1, 60, 24), 4);
      expect(DropResolver.desiredDepth(1, 60, 24, rtl: true), -2);
    });

    test('depth is clamped between next row depth and previous row depth + 1', () {
      // Gap after A1 (before B): allowed depths 0..2.
      expect(DropResolver.resolve(rows, 2, 5), const DropTarget(parentId: 'A1', afterId: null, depth: 2, gap: 2));
      expect(DropResolver.resolve(rows, 2, 1), const DropTarget(parentId: 'A', afterId: 'A1', depth: 1, gap: 2));
      expect(DropResolver.resolve(rows, 2, -3), const DropTarget(parentId: null, afterId: 'A', depth: 0, gap: 2));
      // Gap between A and A1: only depth 1 (first child of A).
      expect(DropResolver.resolve(rows, 1, 0), const DropTarget(parentId: 'A', afterId: null, depth: 1, gap: 1));
      // Top of list.
      expect(DropResolver.resolve(rows, 0, 3), const DropTarget(parentId: null, afterId: null, depth: 0, gap: 0));
      // Under a focus root.
      expect(DropResolver.resolve(rows, 4, 0, focusRootId: 'F').parentId, 'F');
    });
  });

  group('due, staleness, history', () {
    final nowLocal = LocalDateTime.of(2026, 9, 23, 10, 30);

    test('due states across midnight and date-only values', () {
      expect(ItemTimeRules.classifyDue(LocalDateTime.of(2026, 9, 22), nowLocal), DueState.overdue);
      expect(ItemTimeRules.classifyDue(LocalDateTime.of(2026, 9, 23), nowLocal), DueState.today);
      expect(ItemTimeRules.classifyDue(LocalDateTime.of(2026, 9, 23, 9), nowLocal), DueState.overdue);
      expect(ItemTimeRules.classifyDue(LocalDateTime.of(2026, 9, 23, 23, 59), nowLocal), DueState.today);
      expect(ItemTimeRules.classifyDue(LocalDateTime.of(2026, 9, 24, 0, 1), nowLocal), DueState.tomorrow);
      expect(ItemTimeRules.classifyDue(LocalDateTime.of(2026, 10, 1), nowLocal), DueState.later);
    });

    test('stale and escalation thresholds', () {
      final old = ChecklistItem(
        id: 'x',
        checklistId: 'c',
        sortKey: 'a0',
        updatedAt: now.subtract(const Duration(days: 15)),
      );
      expect(ItemTimeRules.isStale(old, now, 14), isTrue);
      expect(ItemTimeRules.isStale(old.copyWith(status: ItemStatus.completed), now, 14), isFalse);
      final waiting = ChecklistItem(
        id: 'w',
        checklistId: 'c',
        sortKey: 'a0',
        status: ItemStatus.waiting,
        statusChangedAt: now.subtract(const Duration(days: 4)),
      );
      expect(ItemTimeRules.escalation(waiting, now), AgeLevel.warn);
      expect(ItemTimeRules.escalation(waiting, now.add(const Duration(days: 3))), AgeLevel.alert);
      expect(ItemTimeRules.age(now.subtract(const Duration(hours: 5)), now), (5, 'h'));
    });

    test('status intervals include the open current interval', () {
      final created = now.subtract(const Duration(days: 10));
      final events = [
        StatusEvent(
          at: created.add(const Duration(days: 2)),
          from: ItemStatus.todo,
          to: ItemStatus.waiting,
          note: 'supplier',
        ),
        StatusEvent(at: created.add(const Duration(days: 5)), from: ItemStatus.waiting, to: ItemStatus.ongoing),
        StatusEvent(
          at: created.add(const Duration(days: 6)),
          to: ItemStatus.ongoing,
          type: 'status_note_changed',
          note: 'x',
        ),
      ];
      final intervals = StatusHistory.intervals(events, createdAt: created, currentStatus: ItemStatus.ongoing);
      expect(intervals.map((i) => i.status), [ItemStatus.todo, ItemStatus.waiting, ItemStatus.ongoing]);
      expect(intervals.last.end, isNull);
      final totals = StatusHistory.totals(intervals, now);
      expect(totals[ItemStatus.waiting], const Duration(days: 3));
      expect(totals[ItemStatus.ongoing], const Duration(days: 5));
      expect(StatusHistory.recentReasons(events, ItemStatus.waiting), ['supplier']);
    });
  });
}
