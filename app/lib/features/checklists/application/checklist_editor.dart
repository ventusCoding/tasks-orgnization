import 'dart:async';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/core/undo/undo_stack.dart';
import 'package:everslot/features/checklists/application/checklist_service.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/data/checklist_ui_state_store.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/import_export.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/status_engine.dart';
import 'package:everslot/features/checklists/domain/tree_change.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ask the user before completing open descendants ("Also complete 5 open sub-items?").
/// Returns true/false, or null to cancel the whole command.
typedef CascadeQuestion = Future<bool?> Function(int openCount);

/// Where the caret should go next (consumed by the row with [itemId]).
@immutable
class FocusRequest {
  const FocusRequest(this.itemId, {this.cursor, this.seq = 0});

  final String itemId;
  final int? cursor;
  final int seq;

  @override
  bool operator ==(Object other) =>
      other is FocusRequest && other.itemId == itemId && other.cursor == cursor && other.seq == seq;

  @override
  int get hashCode => Object.hash(itemId, cursor, seq);
}

/// View + interaction state of one open checklist (T4.2.06/T4.2.07).
@immutable
class EditorState {
  const EditorState({
    this.ready = false,
    this.preview = false,
    this.focusRootId,
    this.viewType = ChecklistViewType.outline,
    this.filter = ItemFilter.none,
    this.sort = ItemSort.manual,
    this.selection = const {},
    this.selecting = false,
    this.focusRequest,
    this.activeItemId,
    this.canUndo = false,
    this.canRedo = false,
    this.initialScroll,
    this.highlightId,
  });

  final bool ready;
  final bool preview;
  final String? focusRootId;
  final ChecklistViewType viewType;
  final ItemFilter filter;
  final ItemSort sort;
  final Set<String> selection;
  final bool selecting;
  final FocusRequest? focusRequest;

  /// Row whose text field has focus (edit mode).
  final String? activeItemId;
  final bool canUndo;
  final bool canRedo;
  final double? initialScroll;

  /// Row to highlight briefly (search / smart views).
  final String? highlightId;

  bool get isFiltered => filter.isActive || filter.hideCompleted;
  bool get isSorted => !sort.isManual;

  /// Drag & drop and swipe-to-indent need the stored order.
  bool get canRestructure => !filter.isActive && sort.isManual;

  EditorState copyWith({
    bool? ready,
    bool? preview,
    String? focusRootId,
    bool clearFocusRoot = false,
    ChecklistViewType? viewType,
    ItemFilter? filter,
    ItemSort? sort,
    Set<String>? selection,
    bool? selecting,
    FocusRequest? focusRequest,
    bool clearFocusRequest = false,
    String? activeItemId,
    bool clearActive = false,
    bool? canUndo,
    bool? canRedo,
    double? initialScroll,
    String? highlightId,
    bool clearHighlight = false,
  }) => EditorState(
    ready: ready ?? this.ready,
    preview: preview ?? this.preview,
    focusRootId: clearFocusRoot ? null : (focusRootId ?? this.focusRootId),
    viewType: viewType ?? this.viewType,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
    selection: selection ?? this.selection,
    selecting: selecting ?? this.selecting,
    focusRequest: clearFocusRequest ? null : (focusRequest ?? this.focusRequest),
    activeItemId: clearActive ? null : (activeItemId ?? this.activeItemId),
    canUndo: canUndo ?? this.canUndo,
    canRedo: canRedo ?? this.canRedo,
    initialScroll: initialScroll ?? this.initialScroll,
    highlightId: clearHighlight ? null : (highlightId ?? this.highlightId),
  );
}

/// Controller of one open checklist: drafts, structure ops, statuses, undo/redo, selection.
///
/// Text: drafts live in memory and are written with a 400 ms debounce, on blur and on app pause;
/// one `updated` event and one undo step per editing session. Structure: every command is one
/// pure [TreeChange] = one op group = one undo step. Undo stacks are per checklist and cleared
/// when the screen closes.
class ChecklistEditor extends Notifier<EditorState> {
  ChecklistEditor(this.checklistId);

  final String checklistId;
  static const debounce = Duration(milliseconds: 400);

  late UndoStack _undo;
  late ChecklistService _service;
  late ChecklistUiStateStore _store;
  final Map<String, String> _drafts = {};
  final Map<String, Timer> _timers = {};
  String? _sessionItem;
  int _sessionToken = 0;
  bool _sessionLogged = false;
  final List<OpRecord> _sessionRecords = [];
  int _focusSeq = 0;
  StreamSubscription<void>? _pauseSub;

  /// Record on top of the undo stack when it was pushed by this editor (snackbar undo).
  OpRecord? _lastPushed;

  UndoStack get undoStack => _undo;

  @override
  EditorState build() {
    _service = ref.read(checklistServiceProvider);
    _store = ref.read(checklistUiStateStoreProvider);
    _undo = UndoStack(ref.read(syncWriterProvider))..addListener(_onUndoChanged);
    try {
      _pauseSub = ref.read(lifecycleProvider).onPause.listen((_) => unawaited(flushAll()));
    } on Object {
      _pauseSub = null;
    }
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
      final pending = Map.of(_drafts);
      _drafts.clear();
      for (final e in pending.entries) {
        unawaited(_service.setText(checklistId, e.key, e.value, logEvent: true));
      }
      _undo
        ..removeListener(_onUndoChanged)
        ..dispose();
      unawaited(_pauseSub?.cancel());
    });
    return const EditorState();
  }

  void _push(String label, OpRecord record) {
    // Late writes (drafts flushed while the screen closes) are kept but no longer undoable.
    if (record.isEmpty || !ref.mounted) return;
    _undo.push(label, record);
    _lastPushed = record;
  }

  void _onUndoChanged() {
    if (!ref.mounted) return;
    state = state.copyWith(canUndo: _undo.canUndo, canRedo: _undo.canRedo);
  }

  DateTime get _now => ref.read(clockProvider).nowUtc();

  ChecklistTree? get tree => ref.read(checklistTreeProvider(checklistId));

  /// Loads the per-device view state; route params win (T4.2.07, T4.2.13).
  Future<void> init({bool preview = false, String? focusItemId, bool forceEdit = false}) async {
    final saved = await _store.get(checklistId);
    final checklist = await ref.read(checklistsRepositoryProvider).byId(checklistId);
    if (!ref.mounted) return;
    final mode = forceEdit
        ? OpenMode.edit
        : preview
        ? OpenMode.preview
        : (saved.mode ?? checklist?.settings.defaultOpenMode ?? OpenMode.edit);
    final focus = focusItemId ?? saved.focusItemId;
    state = state.copyWith(
      ready: true,
      preview: mode == OpenMode.preview,
      focusRootId: focus,
      clearFocusRoot: focus == null,
      viewType: saved.viewType,
      filter: saved.filter,
      sort: saved.sort,
      initialScroll: focusItemId == null ? saved.scrollOffset : null,
      highlightId: focusItemId,
    );
    await _store.save(checklistId, mode: mode, openedAt: _now, focusItemId: focus, clearFocus: focus == null);
  }

  // ------------------------------------------------------------------ view state

  Future<void> setPreview(bool preview) async {
    await flushAll();
    _endSession();
    state = state.copyWith(preview: preview, selecting: false, selection: const {}, clearFocusRequest: true, clearActive: true);
    await _store.save(checklistId, mode: preview ? OpenMode.preview : OpenMode.edit);
  }

  Future<void> setViewType(ChecklistViewType type) async {
    state = state.copyWith(viewType: type);
    await _store.save(checklistId, viewType: type);
  }

  Future<void> zoomTo(String? itemId) async {
    await flushAll();
    _endSession();
    state = state.copyWith(focusRootId: itemId, clearFocusRoot: itemId == null, clearFocusRequest: true, clearHighlight: true);
    await _store.save(checklistId, focusItemId: itemId, clearFocus: itemId == null);
  }

  /// Back gesture in focus mode: one level up.
  Future<bool> zoomOut() async {
    final root = state.focusRootId;
    if (root == null) return false;
    await zoomTo(tree?.parentOf(root));
    return true;
  }

  Future<void> setFilter(ItemFilter filter) async {
    state = state.copyWith(filter: filter);
    await _store.save(checklistId, filter: filter);
  }

  Future<void> setSort(ItemSort sort) async {
    state = state.copyWith(sort: sort);
    await _store.save(checklistId, sort: sort);
  }

  void saveScroll(double offset) => unawaited(_store.save(checklistId, scrollOffset: offset));

  void clearHighlight() => state = state.copyWith(clearHighlight: true);

  // ------------------------------------------------------------------ collapse (T4.2.12)

  Future<void> toggleCollapse(String id) async {
    final collapsed = ref.read(collapsedNodesProvider(checklistId)).value ?? const {};
    await _store.setCollapsed(checklistId, [id], collapsed: !collapsed.contains(id), at: _now);
  }

  Future<void> setSubtreeCollapsed(String id, {required bool collapsed}) async {
    final t = tree;
    if (t == null) return;
    final ids = [id, ...t.descendants(id)].where(t.hasChildren);
    await _store.setCollapsed(checklistId, ids, collapsed: collapsed, at: _now);
  }

  Future<void> collapseAll() async {
    final t = tree;
    if (t == null) return;
    await _store.replaceCollapsed(checklistId, VisibleListBuilder.allParents(t, focusRootId: state.focusRootId), at: _now);
  }

  Future<void> expandAll() => _store.replaceCollapsed(checklistId, const {}, at: _now);

  Future<void> expandToLevel(int level) async {
    final t = tree;
    if (t == null) return;
    await _store.replaceCollapsed(
      checklistId,
      VisibleListBuilder.collapsedForLevel(t, level, focusRootId: state.focusRootId),
      at: _now,
    );
  }

  // ------------------------------------------------------------------ text (T4.2.09)

  String? draftOf(String id) => _drafts[id];

  void onTextChanged(String id, String text) {
    if (_sessionItem != id) {
      _endSession();
      _sessionItem = id;
      _sessionToken++;
    }
    _drafts[id] = text;
    _timers[id]?.cancel();
    _timers[id] = Timer(debounce, () => unawaited(flush(id)));
  }

  void _cancelDraft(String id) {
    _timers.remove(id)?.cancel();
    _drafts.remove(id);
  }

  Future<void> flush(String id) async {
    _timers.remove(id)?.cancel();
    final text = _drafts.remove(id);
    if (text == null) return;
    final token = _sessionToken;
    final inSession = _sessionItem == id;
    final record = await _service.setText(checklistId, id, text, logEvent: !(inSession && _sessionLogged));
    if (record == null) return;
    if (inSession && token == _sessionToken && _sessionItem == id) {
      _sessionLogged = true;
      _sessionRecords.add(record);
    } else {
      _push('text', record);
    }
  }

  /// Writes pending drafts without touching the undo stack (the screen is closing).
  Future<void> flushForClose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    final pending = Map.of(_drafts);
    _drafts.clear();
    return Future.wait([
      for (final e in pending.entries) _service.setText(checklistId, e.key, e.value, logEvent: true),
    ]);
  }

  Future<void> flushAll() async {
    for (final id in _drafts.keys.toList()) {
      await flush(id);
    }
  }

  void _endSession() {
    if (_sessionRecords.isNotEmpty) _push('text', mergeRecords(List.of(_sessionRecords)));
    _sessionRecords.clear();
    _sessionItem = null;
    _sessionLogged = false;
    _sessionToken++;
  }

  Future<void> onFocusChanged(String id, {required bool focused}) async {
    if (focused) {
      if (_sessionItem != id) {
        _endSession();
        _sessionItem = id;
        _sessionToken++;
      }
      if (state.activeItemId != id) state = state.copyWith(activeItemId: id);
      return;
    }
    await flush(id);
    if (_sessionItem == id) _endSession();
    if (ref.mounted && state.activeItemId == id) state = state.copyWith(clearActive: true);
  }

  void requestFocus(String itemId, {int? cursor}) =>
      state = state.copyWith(focusRequest: FocusRequest(itemId, cursor: cursor, seq: ++_focusSeq));

  void consumeFocusRequest(FocusRequest request) {
    if (state.focusRequest == request) state = state.copyWith(clearFocusRequest: true);
  }

  // ------------------------------------------------------------------ ops

  /// Runs one command: flush drafts, end the text session, apply, push one undo step, focus.
  Future<OpRecord?> run(
    String label,
    ChangeBuilder build, {
    String cause = 'user',
    bool focusResult = true,
  }) async {
    await flushAll();
    _endSession();
    final result = await _service.run(checklistId, build, cause: cause);
    if (result == null) return null;
    _push(label, result.record);
    final f = result.change.focus;
    if (focusResult && f != null && !state.preview && ref.mounted) requestFocus(f.itemId, cursor: f.cursor);
    return result.record;
  }

  Future<OpRecord?> addItem({String? parentId, String text = ''}) => run(
    'add',
    (t, ctx, _) => TreeOps.appendChild(t, ctx, t.contains(parentId) ? parentId : state.focusRootId, text: text),
  );

  Future<OpRecord?> insertAfter(String id, {String text = ''}) =>
      run('add', (t, ctx, _) => TreeOps.insertAfter(t, ctx, id, text: text));

  Future<OpRecord?> addChild(String id) => run('add', (t, ctx, _) => TreeOps.appendChild(t, ctx, id));

  Future<OpRecord?> enter(String id, {required String text, required int cursor}) {
    _cancelDraft(id);
    final collapsed = ref.read(collapsedNodesProvider(checklistId)).value ?? const {};
    return run(
      'add',
      (t, ctx, _) => t.contains(id)
          ? TreeOps.enter(t, ctx, id, text: text, cursor: cursor, expanded: !collapsed.contains(id))
          : TreeChange.none,
    );
  }

  Future<OpRecord?> backspaceAtStart(String id, {required String text, required String? previousVisibleId}) {
    _cancelDraft(id);
    return run(
      'merge',
      (t, ctx, _) => TreeOps.backspaceAtStart(
        t,
        ctx,
        id,
        text: text,
        previousVisibleId: previousVisibleId,
        focusRootId: state.focusRootId,
      ),
    );
  }

  Future<OpRecord?> indent(Iterable<String> ids) => run('indent', (t, ctx, _) => TreeOps.indent(t, ctx, ids));

  Future<OpRecord?> outdent(Iterable<String> ids) =>
      run('outdent', (t, ctx, _) => TreeOps.outdent(t, ctx, ids, focusRootId: state.focusRootId));

  Future<OpRecord?> moveUp(Iterable<String> ids) => run('move', (t, ctx, _) => TreeOps.moveUp(t, ctx, ids));

  Future<OpRecord?> moveDown(Iterable<String> ids) => run('move', (t, ctx, _) => TreeOps.moveDown(t, ctx, ids));

  Future<OpRecord?> moveTo(Iterable<String> ids, {required String? parentId, String? afterId}) => run(
    'move',
    (t, ctx, _) => TreeOps.moveTo(t, ctx, ids, newParentId: parentId, afterId: afterId),
    focusResult: false,
  );

  Future<OpRecord?> delete(Iterable<String> ids) {
    for (final id in ids) {
      _cancelDraft(id);
    }
    return run('delete', (t, ctx, _) => TreeOps.deleteSubtrees(t, ctx, ids), focusResult: false);
  }

  Future<OpRecord?> duplicate(Iterable<String> ids, {bool resetStatuses = false}) =>
      run('duplicate', (t, ctx, _) => TreeOps.duplicateSubtrees(t, ctx, ids, resetStatuses: resetStatuses));

  Future<OpRecord?> sortChildren(String? parentId, ItemSortBy by, {bool descending = false}) => run(
    'sort',
    (t, ctx, _) => TreeOps.sortChildren(t, ctx, parentId, by, descending: descending),
    focusResult: false,
  );

  Future<OpRecord?> insertNodes(List<NodeSpec> nodes, {String? parentId, String? afterId, String cause = 'import'}) =>
      run(
        'import',
        (t, ctx, _) => TreeOps.insertNodes(
          t,
          ctx,
          nodes,
          parentId: t.contains(parentId) ? parentId : state.focusRootId,
          afterId: afterId,
          atEnd: afterId == null,
        ),
        cause: cause,
        focusResult: false,
      );

  Future<OpRecord?> setFields(String id, Map<String, Object?> fields, {String label = 'edit'}) =>
      run(label, (t, ctx, _) => TreeOps.setFields(t, ctx, id, fields), focusResult: false);

  /// Promote to its own checklist (T4.2.04): new list titled with the item text (color and
  /// category inherited) + children moved + attachments made checklist-level, in ONE op group.
  Future<String?> promote(String itemId, {bool keepOriginal = false}) async {
    final newId = Ids.v7();
    final key = await ref.read(checklistsRepositoryProvider).topSortKey();
    final record = await run('promote', (t, ctx, c) {
      final item = t[itemId];
      if (item == null) return TreeChange.none;
      return TreeChange(
        writes: [
          RowWrite.insert('checklists', newId, {
            'title': ChecklistTitle(item.text).value,
            'body': item.note,
            'color': c.color,
            'category_id': c.categoryId,
            'sort_key': key,
            'settings': c.settings.toJson(),
          }),
        ],
        events: [
          EventSpec(entityType: 'checklist', entityId: newId, eventType: 'created', payload: {'promotedFrom': itemId}),
        ],
      ).merge(TreeOps.promote(t, ctx, itemId, newChecklistId: newId, keepOriginal: keepOriginal));
    }, focusResult: false);
    return record == null ? null : newId;
  }

  /// Moves subtrees to another checklist under [targetParentId] (appended, T4.1.15).
  Future<OpRecord?> moveToChecklist(Iterable<String> ids, {required String targetChecklistId, String? targetParentId}) async {
    if (targetChecklistId == checklistId) {
      final t = tree;
      final last = t == null ? null : (t.childIds(targetParentId).isEmpty ? null : t.childIds(targetParentId).last);
      return moveTo(ids, parentId: targetParentId, afterId: last);
    }
    final targetItems = await ref.read(checklistItemsRepositoryProvider).items(targetChecklistId);
    final target = ChecklistTree.build(targetItems);
    final siblings = target.childIds(target.contains(targetParentId) ? targetParentId : null);
    final afterKey = siblings.isEmpty ? null : target[siblings.last]!.sortKey;
    return run(
      'move',
      (t, ctx, _) => TreeOps.moveToChecklist(
        t,
        ctx,
        ids,
        targetChecklistId: targetChecklistId,
        targetParentId: target.contains(targetParentId) ? targetParentId : null,
        afterKey: afterKey,
      ),
      focusResult: false,
    );
  }

  /// Pastes the internal clipboard after [afterId] (sibling) or at the end of the focus root.
  /// Cut = move (across checklists too); copy = new rows with attachments by reference.
  Future<OpRecord?> paste(ClipboardContent content, {String? afterId}) async {
    final t = tree;
    final parent = afterId != null && t != null && t.contains(afterId) ? t.parentOf(afterId) : state.focusRootId;
    if (content.isCut) {
      final record = content.sourceChecklistId == checklistId
          ? await moveTo(content.cutIds, parentId: parent, afterId: afterId)
          : await _moveIn(content, parent);
      ref.read(checklistClipboardProvider.notifier).clear();
      return record;
    }
    return run(
      'paste',
      (tree, ctx, _) => TreeOps.insertNodes(tree, ctx, content.nodes, parentId: parent, afterId: afterId, atEnd: afterId == null),
    );
  }

  Future<OpRecord?> _moveIn(ClipboardContent content, String? parent) async {
    final t = tree;
    final siblings = t?.childIds(parent) ?? const <String>[];
    final afterKey = siblings.isEmpty ? null : t![siblings.last]!.sortKey;
    final result = await _service.run(
      content.sourceChecklistId,
      (src, ctx, _) => TreeOps.moveToChecklist(
        src,
        ctx,
        content.cutIds,
        targetChecklistId: checklistId,
        targetParentId: parent,
        afterKey: afterKey,
      ),
    );
    if (result == null) return null;
    _push('move', result.record);
    return result.record;
  }

  // ------------------------------------------------------------------ statuses (T4.3)

  Future<OpRecord?> setStatus(
    Iterable<String> ids,
    ItemStatus to, {
    String? note,
    bool setNote = true,
    DateTime? followUpAt,
    bool keepFollowUp = false,
    bool? completeOpenDescendants,
    String cause = 'user',
  }) => run(
    'status',
    (t, ctx, c) => StatusEngine.apply(
      t,
      c.settings,
      ids: ids,
      to: to,
      now: ctx.now,
      note: note,
      setNote: setNote,
      followUpAt: followUpAt,
      keepFollowUp: keepFollowUp,
      completeOpenDescendants: completeOpenDescendants,
      cause: cause,
    ),
    cause: cause,
    focusResult: false,
  );

  /// Checkbox tap: open → completed (asking about open sub-items when configured), completed → todo.
  Future<OpRecord?> toggleComplete(String id, {CascadeQuestion? ask}) async {
    final t = tree;
    final item = t?[id];
    if (t == null || item == null) return null;
    if (item.status == ItemStatus.completed) return setStatus([id], ItemStatus.todo, setNote: false);
    final checklist = ref.read(checklistProvider(checklistId)).value;
    final choice = checklist?.settings.completeChildrenWithParent ?? CascadeChoice.ask;
    bool? cascade;
    final open = StatusEngine.openDescendantCount(t, id);
    if (open > 0 && choice == CascadeChoice.ask && ask != null) {
      cascade = await ask(open);
      if (cascade == null) return null;
    }
    return setStatus([id], ItemStatus.completed, setNote: false, completeOpenDescendants: cascade);
  }

  // ------------------------------------------------------------------ list commands (T4.3.09)

  Future<OpRecord?> uncheckAll() =>
      run('uncheckAll', (t, ctx, c) => ListCommands.uncheckAll(t, c.settings, now: ctx.now), cause: 'bulk', focusResult: false);

  Future<OpRecord?> resetAllStatuses() =>
      run('resetAll', (t, ctx, _) => ListCommands.resetAll(t, now: ctx.now), cause: 'bulk', focusResult: false);

  Future<OpRecord?> deleteCompleted() => run(
    'deleteCompleted',
    (t, ctx, _) => TreeOps.deleteSubtrees(t, ctx, ListCommands.completedSubtrees(t)),
    cause: 'bulk',
    focusResult: false,
  );

  Future<OpRecord?> updateSettings(ChecklistSettings Function(ChecklistSettings) edit) async {
    final c = await ref.read(checklistsRepositoryProvider).byId(checklistId);
    if (c == null) return null;
    final record = await ref.read(checklistsRepositoryProvider).update(checklistId, settings: edit(c.settings));
    _push('settings', record);
    return record;
  }

  // ------------------------------------------------------------------ selection (T4.2.16)

  void startSelection(String id) => state = state.copyWith(selecting: true, selection: {id});

  /// Selection mode with nothing selected yet (menu entry).
  void enterSelection() => state = state.copyWith(selecting: true, selection: const {});

  /// Toggles one row; selection mode stays on until [clearSelection] (close button / back).
  void toggleSelected(String id) {
    final s = {...state.selection};
    if (!s.remove(id)) s.add(id);
    state = state.copyWith(selection: s, selecting: true);
  }

  void selectSubtree(String id) {
    final t = tree;
    if (t == null) return;
    state = state.copyWith(selecting: true, selection: {...state.selection, id, ...t.descendants(id)});
  }

  /// Selects every visible row between [fromId] and [toId] (drag along the handles).
  void selectRange(List<VisibleRow> rows, String fromId, String toId) {
    final a = rows.indexWhere((r) => r.id == fromId);
    final b = rows.indexWhere((r) => r.id == toId);
    if (a < 0 || b < 0) return;
    final lo = a < b ? a : b;
    final hi = a < b ? b : a;
    state = state.copyWith(selecting: true, selection: {...state.selection, for (final r in rows.sublist(lo, hi + 1)) r.id});
  }

  void selectAll(List<VisibleRow> rows) =>
      state = state.copyWith(selecting: true, selection: {for (final r in rows) r.id});

  void clearSelection() => state = state.copyWith(selecting: false, selection: const {});

  // ------------------------------------------------------------------ undo (T4.2.14)

  Future<bool> undo() async {
    await flushAll();
    _endSession();
    _lastPushed = null;
    return _undo.undo();
  }

  Future<bool> redo() async {
    await flushAll();
    _endSession();
    _lastPushed = null;
    return _undo.redo();
  }

  /// Undo from a snackbar: pops the undo stack when [record] is still on top of it, otherwise
  /// reverts the record directly (never undoes an unrelated later edit).
  Future<void> undoRecord(OpRecord record) async {
    if (identical(record, _lastPushed) && _undo.canUndo) {
      await undo();
    } else {
      await ref.read(syncWriterProvider).revert(record);
    }
  }

  /// Registers an operation made elsewhere on this screen (attachments, header) as an undo step.
  void pushUndo(String label, OpRecord record) => _push(label, record);

  /// Briefly highlights a row (search hits, smart views, "next open item").
  void highlight(String? id) => state = id == null ? state.copyWith(clearHighlight: true) : state.copyWith(highlightId: id);
}

final checklistEditorProvider = NotifierProvider.autoDispose.family<ChecklistEditor, EditorState, String>(
  ChecklistEditor.new,
);

/// Rows the outline renders for a checklist (T4.2.05).
final visibleRowsProvider = Provider.autoDispose.family<List<VisibleRow>, String>((ref, id) {
  final tree = ref.watch(checklistTreeProvider(id));
  if (tree == null) return const [];
  final view = ref.watch(checklistEditorProvider(id).select((s) => (s.focusRootId, s.filter, s.sort)));
  final collapsed = ref.watch(collapsedNodesProvider(id)).value ?? const <String>{};
  final sortCompletedToBottom = ref.watch(
    checklistProvider(id).select((c) => c.value?.settings.sortCompletedToBottom ?? false),
  );
  final withAttachments = view.$2.hasAttachments
      ? (ref.watch(itemAttachmentCountsProvider(id)).value?.keys.toSet() ?? const <String>{})
      : const <String>{};
  final now = ref.read(clockProvider).nowUtc();
  final zone = ref.watch(deviceZoneProvider);
  LocalDate? today;
  try {
    today = ref.read(zoneResolverProvider).toLocal(now, zone).date;
  } on Object {
    today = LocalDate.fromDateTime(now);
  }
  return VisibleListBuilder.build(
    tree,
    focusRootId: view.$1,
    collapsed: collapsed,
    filter: view.$2,
    sort: view.$3,
    sortCompletedToBottom: sortCompletedToBottom,
    withAttachments: withAttachments,
    today: today,
  );
});

/// Internal clipboard for subtrees (T4.2.17): structure, statuses, attachments by reference.
@immutable
class ClipboardContent {
  const ClipboardContent({required this.nodes, required this.sourceChecklistId, this.cutIds = const []});

  final List<NodeSpec> nodes;
  final String sourceChecklistId;

  /// Non-empty for "cut": pasting moves these items instead of copying.
  final List<String> cutIds;

  bool get isCut => cutIds.isNotEmpty;
}

class ChecklistClipboard extends Notifier<ClipboardContent?> {
  @override
  ClipboardContent? build() => null;

  void copy(ChecklistTree tree, String checklistId, Iterable<String> ids) => state = ClipboardContent(
    nodes: [for (final id in tree.topMost(ids)) NodeSpec.fromTree(tree, id)],
    sourceChecklistId: checklistId,
  );

  void cut(ChecklistTree tree, String checklistId, Iterable<String> ids) => state = ClipboardContent(
    nodes: [for (final id in tree.topMost(ids)) NodeSpec.fromTree(tree, id)],
    sourceChecklistId: checklistId,
    cutIds: tree.topMost(ids),
  );

  /// Plain text for the system clipboard.
  static String asText(ChecklistTree tree, Iterable<String> ids) => ChecklistExport.subtreesAsText(tree, ids.toList());

  void clear() => state = null;
}

final checklistClipboardProvider = NotifierProvider<ChecklistClipboard, ClipboardContent?>(ChecklistClipboard.new);
