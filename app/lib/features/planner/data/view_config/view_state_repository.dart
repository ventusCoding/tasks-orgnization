import 'dart:convert';

import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/planner/domain/view_config/view_state.dart';

/// Reads/writes [ViewState] rows of the local-only table `ui_view_state` (never synced, T3.3.02).
class ViewStateRepository {
  ViewStateRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  Future<ViewState?> read(String viewId) async {
    final row = await (_db.select(_db.uiViewState)..where((s) => s.viewId.equals(viewId))).getSingleOrNull();
    if (row == null) return null;
    try {
      final decoded = jsonDecode(row.json);
      return decoded is Map ? ViewState.fromJson(Map<String, Object?>.from(decoded)) : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String viewId, ViewState state) => _db
      .into(_db.uiViewState)
      .insertOnConflictUpdate(
        UiViewStateCompanion.insert(viewId: viewId, json: jsonEncode(state.toJson()), updatedAt: _clock.nowUtc()),
      );

  Future<void> update(String viewId, ViewState Function(ViewState current) change) async {
    final current = await read(viewId) ?? const ViewState();
    await write(viewId, change(current));
  }
}
