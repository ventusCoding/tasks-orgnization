// In-list sort & filter (T4.5.11): view-level sorting inside each sibling group (the stored order
// never changes), filters, the "Sorted by … · Reset" banner and per-list persistence.
import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:everslot/features/checklists/presentation/checklist_header.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'checklist_test_support.dart' show t0;

ChecklistItem _item(
  String id,
  String key, {
  String? parent,
  ItemStatus status = ItemStatus.todo,
  LocalDateTime? due,
  int priority = 0,
  DateTime? changed,
}) => ChecklistItem(
  id: id,
  checklistId: 'c1',
  parentId: parent,
  sortKey: key,
  text: id,
  status: status,
  dueLocal: due,
  priority: priority,
  statusChangedAt: changed,
  createdAt: t0,
);

/// Roots: Zeta (with children z2, z1), alpha, Mid — varied statuses, due dates, priorities and
/// change dates.
final _tree = ChecklistTree.build([
  _item('Zeta', 'a', status: ItemStatus.completed, priority: 1, changed: t0.subtract(const Duration(days: 3))),
  _item('z2', 'a', parent: 'Zeta', due: LocalDateTime.of(2026, 9, 30)),
  _item('z1', 'b', parent: 'Zeta', status: ItemStatus.blocked, due: LocalDateTime.of(2026, 9, 25)),
  _item('alpha', 'b', status: ItemStatus.waiting, due: LocalDateTime.of(2026, 10, 2), priority: 3, changed: t0),
  _item('Mid', 'c', status: ItemStatus.ongoing, due: LocalDateTime.of(2026, 9, 28), priority: 2),
]);

List<String> _ids(List<VisibleRow> rows) => [for (final r in rows) '${'  ' * r.depth}${r.id}'];

List<String> _sorted(ItemSortBy by, {bool descending = false}) => _ids(
  VisibleListBuilder.build(
    _tree,
    sort: ItemSort(by: by, descending: descending),
  ),
);

void main() {
  group('sorting inside sibling groups', () {
    test('manual keeps the outline order', () {
      expect(_sorted(ItemSortBy.manual), ['Zeta', '  z2', '  z1', 'alpha', 'Mid']);
    });

    test('alphabetical ignores case; children sort within their parent only', () {
      expect(_sorted(ItemSortBy.alphabetical), ['alpha', 'Mid', 'Zeta', '  z1', '  z2']);
    });

    test('status: most urgent first (blocked, waiting, ongoing, to do, completed)', () {
      expect(_sorted(ItemSortBy.status), ['alpha', 'Mid', 'Zeta', '  z1', '  z2']);
    });

    test('due date: soonest first, undated last — in both directions', () {
      expect(_sorted(ItemSortBy.due), ['Mid', 'alpha', 'Zeta', '  z1', '  z2']);
      expect(_sorted(ItemSortBy.due, descending: true), ['alpha', 'Mid', 'Zeta', '  z2', '  z1']);
    });

    test('priority: highest first; recent: latest change first, never-changed last', () {
      expect(_sorted(ItemSortBy.priority), ['alpha', 'Mid', 'Zeta', '  z2', '  z1']);
      expect(_sorted(ItemSortBy.recent), ['alpha', 'Zeta', '  z2', '  z1', 'Mid']);
      expect(_sorted(ItemSortBy.recent, descending: true), ['Zeta', '  z2', '  z1', 'alpha', 'Mid']);
    });

    test('sorting never touches the stored order', () {
      final keys = {for (final id in _tree.order) id: _tree[id]!.sortKey};
      for (final by in ItemSortBy.values) {
        VisibleListBuilder.build(_tree, sort: ItemSort(by: by));
      }
      expect({for (final id in _tree.order) id: _tree[id]!.sortKey}, keys);
      expect(_tree.order, ['Zeta', 'z2', 'z1', 'alpha', 'Mid']);
    });

    test('filters combine with a sort (status set + text)', () {
      final rows = VisibleListBuilder.build(
        _tree,
        sort: const ItemSort(by: ItemSortBy.alphabetical),
        filter: const ItemFilter(statuses: {ItemStatus.blocked, ItemStatus.waiting}),
      );
      // Matches keep their ancestors as context rows.
      expect(_ids(rows), ['alpha', 'Zeta', '  z1']);
      expect(rows.firstWhere((r) => r.id == 'Zeta').isContext, isTrue);
      expect(_ids(VisibleListBuilder.build(_tree, filter: const ItemFilter(text: 'mi'))), ['Mid']);
    });
  });

  group('banner and persistence', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create());
    tearDown(() => h.dispose());

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('"Sorted by … · Filtered view" shows while active; Reset restores the plain outline', (tester) async {
      late String id;
      await tester.runAsync(() async {
        id =
            (await h
                    .read(checklistsRepositoryProvider)
                    .create(
                      title: 'Errands',
                      items: const [
                        NodeSpec(text: 'Post office'),
                        NodeSpec(text: 'Bank', status: ItemStatus.blocked),
                      ],
                    ))
                .id;
      });
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle(tester);
      expect(find.byType(MaterialBanner), findsNothing);

      final editor = h.read(checklistEditorProvider(id).notifier);
      await tester.runAsync(() async {
        await editor.setSort(const ItemSort(by: ItemSortBy.status));
        await editor.setFilter(const ItemFilter(text: 'b'));
      });
      await settle(tester);
      expect(find.text('Sorted by Status · Filtered view'), findsOneWidget);
      expect(find.text('Post office'), findsNothing, reason: 'filtered out');

      // Reopening the list restores its view (local, per list).
      await pumpInApp(tester, h, const SizedBox());
      await settle(tester);
      await pumpInApp(tester, h, ChecklistScreen(checklistId: id, preview: true));
      await settle(tester);
      expect(find.text('Sorted by Status · Filtered view'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(ViewBanner), matching: find.text('Reset')));
      await settle(tester);
      expect(find.byType(MaterialBanner), findsNothing);
      expect(find.text('Post office'), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
