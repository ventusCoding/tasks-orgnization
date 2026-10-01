import 'package:everslot/features/checklists/application/swipe_actions.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart' show ItemSortBy;
import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChecklistSettings (v1 JSON, arch §8.6)', () {
    test('missing keys fall back to defaults; defaults open in preview', () {
      final s = ChecklistSettings.fromJson(const {});
      expect(s, ChecklistSettings.defaults);
      expect(s.progressMode, ProgressMode.leaves);
      expect(s.autoCompleteParent, isTrue);
      expect(s.completeChildrenWithParent, CascadeChoice.ask);
      expect(s.requireReasonFor, isEmpty);
      expect(s.hideCheckboxes, isFalse);
      expect(s.defaultOpenMode, OpenMode.preview);
      expect(s.staleAfterDays, 14);
    });

    test('unknown keys survive a round trip; known keys are typed', () {
      final json = <String, Object?>{
        'v': 1,
        'progressMode': 'children',
        'autoCompleteParent': false,
        'completeChildrenWithParent': 'always',
        'requireReasonFor': ['blocked', 'waiting', 'bogus'],
        'hideCheckboxes': true,
        'defaultOpenMode': 'edit',
        'staleAfterDays': 30,
        'futureKey': {'nested': true},
      };
      final s = ChecklistSettings.fromJson(json);
      expect(s.progressMode, ProgressMode.children);
      expect(s.autoCompleteParent, isFalse);
      expect(s.completeChildrenWithParent, CascadeChoice.always);
      expect(s.requireReasonFor, {ItemStatus.blocked, ItemStatus.waiting});
      expect(s.requiresReason(ItemStatus.waiting), isTrue);
      expect(s.hideCheckboxes, isTrue);
      expect(s.defaultOpenMode, OpenMode.edit);
      final out = s.toJson();
      expect(out['futureKey'], {'nested': true});
      expect(out['v'], 1);
      expect(ChecklistSettings.fromJson(out), s);
      expect(s.copyWith(staleAfterDays: 7).toJson()['futureKey'], {'nested': true});
    });

    test('invalid values are tolerated', () {
      final s = ChecklistSettings.fromJson(const {
        'progressMode': 42,
        'autoCompleteParent': 'yes',
        'staleAfterDays': -5,
        'requireReasonFor': 'waiting',
        'defaultNewItemStatus': 'nope',
      });
      expect(s.progressMode, ProgressMode.leaves);
      expect(s.autoCompleteParent, isTrue);
      expect(s.staleAfterDays, 1);
      expect(s.requireReasonFor, isEmpty);
      expect(s.defaultNewItemStatus, ItemStatus.todo);
    });
  });

  group('value objects', () {
    test('ChecklistTitle trims trailing whitespace and enforces 500 characters', () {
      expect(ChecklistTitle('  Trip  \n').value, '  Trip');
      expect(ChecklistTitle('a' * 600).value.length, ChecklistTitle.maxLength);
    });

    test('ItemText keeps inner newlines, trims the end and enforces the limits', () {
      expect(ItemText('Line 1\nLine 2  \n').value, 'Line 1\nLine 2');
      expect(ItemText('x' * 20000).value.length, ItemText.maxLength);
      expect(ItemText.note('   \n'), isNull);
      expect(ItemText.note('Keep\nme '), 'Keep\nme');
      expect(ItemText.body('b' * 200000)!.length, ItemText.bodyMaxLength);
    });
  });

  group('board config (saved view v1, T4.1.16)', () {
    test('JSON round trip with unknown keys and defaults', () {
      final c = BoardConfig.fromJson(const {
        'v': 1,
        'layout': 'list',
        'rowsPerCard': 99,
        'sort': 'recently_edited',
        'showSmartChips': false,
        'extraKey': 3,
      });
      expect(c.layout, BoardLayout.list);
      expect(c.rowsPerCard, 20);
      expect(c.sort, BoardSort.recentlyEdited);
      expect(c.showSmartChips, isFalse);
      final back = BoardConfig.fromJson(c.toJson());
      expect(back, c);
      expect(c.toJson()['extraKey'], 3);
      expect(BoardConfig.fromJson(const {}), BoardConfig.defaults);
    });

    test('smart kinds parse route names', () {
      expect(SmartKind.parse('follow_ups'), SmartKind.followUps);
      expect(SmartKind.followUps.routeName, 'follow_ups');
      expect(SmartKind.parse('waiting')!.status, ItemStatus.waiting);
      expect(SmartKind.parse('x'), isNull);
    });
  });

  group('view state', () {
    test('view types parse with an outline fallback', () {
      expect(ChecklistViewType.parse('kanban'), ChecklistViewType.kanban);
      expect(ChecklistViewType.parse('gallery'), ChecklistViewType.gallery);
      expect(ChecklistViewType.parse(null), ChecklistViewType.outline);
    });

    test('sort JSON round trip', () {
      const sort = ItemSort(by: ItemSortBy.due, descending: true);
      expect(ItemSort.fromJson(sort.toJson()), sort);
      expect(ItemSort.fromJson(const {'by': 'nope'}), ItemSort.manual);
    });
  });

  group('swipe mappings (user_settings.checklists.swipeActions, T4.2.10)', () {
    test('defaults: edit right indents, preview right completes', () {
      const s = SwipeActions.defaults;
      expect(s.resolve(preview: false, towardEnd: true), SwipeAction.indent);
      expect(s.resolve(preview: false, towardEnd: false), SwipeAction.outdent);
      expect(s.resolve(preview: true, towardEnd: true), SwipeAction.complete);
      expect(s.resolve(preview: true, towardEnd: false), SwipeAction.menu);
    });

    test('settings override and round trip', () {
      final s = SwipeActions.fromSettings(const {
        'swipeActions': {
          'edit': {'right': 'complete', 'left': 'none'},
          'preview': {'right': 'menu', 'left': 'bogus'},
        },
      });
      expect(s.editRight, SwipeAction.complete);
      expect(s.editLeft, SwipeAction.none);
      expect(s.previewRight, SwipeAction.menu);
      expect(s.previewLeft, SwipeAction.menu, reason: 'unknown values fall back to the default');
      expect(SwipeActions.fromSettings({'swipeActions': s.toJson()}), s);
      expect(SwipeActions.fromSettings(const {}), SwipeActions.defaults);
    });
  });
}
