import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:meta/meta.dart';

/// Checklist views (T4.5.02).
enum ChecklistViewType {
  outline,
  kanban,
  gallery;

  static ChecklistViewType parse(String? v) => switch (v) {
    'kanban' => ChecklistViewType.kanban,
    'gallery' => ChecklistViewType.gallery,
    _ => ChecklistViewType.outline,
  };
}

/// Per-device view state of one checklist (`ui_checklist_state`, T4.2.06). Never synced.
@immutable
class ChecklistViewState {
  const ChecklistViewState({
    this.mode,
    this.focusItemId,
    this.viewType = ChecklistViewType.outline,
    this.sort = ItemSort.manual,
    this.filter = ItemFilter.none,
    this.scrollOffset,
    this.lastOpenedAt,
  });

  /// Null = never opened (use `settings.defaultOpenMode`).
  final OpenMode? mode;
  final String? focusItemId;
  final ChecklistViewType viewType;
  final ItemSort sort;
  final ItemFilter filter;
  final double? scrollOffset;
  final DateTime? lastOpenedAt;
}

/// Local-only UI state: `ui_node_state` (collapse) and `ui_checklist_state` (mode, focus, view,
/// sort/filter, scroll). Written directly (not through SyncWriter) because it never syncs.
class ChecklistUiStateStore {
  ChecklistUiStateStore(this._db);

  final AppDatabase _db;

  Stream<Set<String>> watchCollapsed(String checklistId) => (_db.select(_db.uiNodeState)
        ..where((n) => n.checklistId.equals(checklistId) & n.collapsed.equals(true)))
      .watch()
      .map((rows) => {for (final r in rows) r.nodeId});

  Future<Set<String>> collapsed(String checklistId) async => {
    for (final r in await (_db.select(_db.uiNodeState)
          ..where((n) => n.checklistId.equals(checklistId) & n.collapsed.equals(true)))
        .get())
      r.nodeId,
  };

  Future<void> setCollapsed(String checklistId, Iterable<String> nodeIds, {required bool collapsed, required DateTime at}) =>
      _db.batch((b) {
        for (final id in nodeIds) {
          b.insert(
            _db.uiNodeState,
            UiNodeStateCompanion.insert(nodeId: id, checklistId: checklistId, collapsed: Value(collapsed), updatedAt: at),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

  /// Replaces the collapsed set (collapse all / expand to level N).
  Future<void> replaceCollapsed(String checklistId, Set<String> nodeIds, {required DateTime at}) =>
      _db.transaction(() async {
        await (_db.delete(_db.uiNodeState)..where((n) => n.checklistId.equals(checklistId))).go();
        await setCollapsed(checklistId, nodeIds, collapsed: true, at: at);
      });

  static ChecklistViewState _map(UiChecklistStateRow? r) {
    if (r == null) return const ChecklistViewState();
    Map<String, Object?> dec(String? s) {
      if (s == null) return const {};
      try {
        return Map<String, Object?>.from(jsonDecode(s) as Map);
      } on Object {
        return const {};
      }
    }

    return ChecklistViewState(
      mode: r.lastOpenedAt == null ? null : OpenMode.parse(r.mode, fallback: OpenMode.edit),
      focusItemId: r.focusItemId,
      viewType: ChecklistViewType.parse(r.viewType),
      sort: r.sortJson == null ? ItemSort.manual : ItemSort.fromJson(dec(r.sortJson)),
      filter: r.filterJson == null ? ItemFilter.none : ItemFilter.fromJson(dec(r.filterJson)),
      scrollOffset: r.scrollOffset,
      lastOpenedAt: r.lastOpenedAt,
    );
  }

  Future<ChecklistViewState> get(String checklistId) async => _map(
    await (_db.select(_db.uiChecklistState)..where((s) => s.checklistId.equals(checklistId))).getSingleOrNull(),
  );

  Stream<ChecklistViewState> watch(String checklistId) =>
      (_db.select(_db.uiChecklistState)..where((s) => s.checklistId.equals(checklistId)))
          .watchSingleOrNull()
          .map(_map);

  Future<void> save(
    String checklistId, {
    OpenMode? mode,
    String? focusItemId,
    bool clearFocus = false,
    ChecklistViewType? viewType,
    ItemSort? sort,
    ItemFilter? filter,
    double? scrollOffset,
    DateTime? openedAt,
  }) async {
    final companion = UiChecklistStateCompanion(
      checklistId: Value(checklistId),
      mode: mode == null ? const Value.absent() : Value(mode.name),
      focusItemId: clearFocus ? const Value(null) : (focusItemId == null ? const Value.absent() : Value(focusItemId)),
      viewType: viewType == null ? const Value.absent() : Value(viewType.name),
      sortJson: sort == null ? const Value.absent() : Value(sort.isManual ? null : jsonEncode(sort.toJson())),
      filterJson: filter == null ? const Value.absent() : Value(filter == ItemFilter.none ? null : jsonEncode(filter.toJson())),
      scrollOffset: scrollOffset == null ? const Value.absent() : Value(scrollOffset),
      lastOpenedAt: openedAt == null ? const Value.absent() : Value(openedAt),
    );
    final updated = await (_db.update(_db.uiChecklistState)..where((s) => s.checklistId.equals(checklistId))).write(companion);
    if (updated == 0) await _db.into(_db.uiChecklistState).insert(companion);
  }
}

/// Board layout persisted as a synced saved view (`section = checklists`, `view_type = lists_board`, T4.1.16).
class BoardConfigStore {
  BoardConfigStore(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  String _id() => Ids.v5('${_userId()}|saved_view|lists_board');

  Stream<BoardConfig> watch() => (_db.select(_db.savedViews)..where((v) => v.id.equals(_id()) & v.deletedAt.isNull()))
      .watchSingleOrNull()
      .map((r) {
        if (r == null) return BoardConfig.defaults;
        try {
          return BoardConfig.fromJson(Map<String, Object?>.from(jsonDecode(r.config) as Map));
        } on Object {
          return BoardConfig.defaults;
        }
      });

  Future<OpRecord> save(BoardConfig config) => _writer.run(
    (tx) => tx.upsert('saved_views', _id(), {
      'section': 'checklists',
      'name': 'Lists board',
      'view_type': 'lists_board',
      'config': config.toJson(),
      'is_default': true,
      'sort_key': 'a0',
    }),
  );
}
