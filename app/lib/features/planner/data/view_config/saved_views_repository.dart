import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/planner/domain/view_config/planner_view_config.dart';
import 'package:everslot/features/planner/domain/view_config/saved_view.dart';
import 'package:everslot/shared/views/application/saved_views_providers.dart';

/// Codec of planner view configs (arch §8.3): versioned, unknown keys kept in `extra`.
class PlannerViewCodec extends ViewConfigCodec<PlannerViewConfig> {
  const PlannerViewCodec();

  @override
  String get section => ViewSections.planner;

  @override
  int get currentVersion => PlannerViewConfig.currentVersion;

  @override
  String viewTypeOf(PlannerViewConfig config) => config.type.id;

  @override
  PlannerViewConfig decode(Map<String, Object?> json, {String? viewType}) =>
      PlannerViewConfig.fromJson(json, fallbackType: viewType == null ? null : PlannerViewType.tryParse(viewType));

  @override
  Map<String, Object?> encode(PlannerViewConfig config) => config.toJson();
}

/// Saved views of the planner (T3.3.01 / T3.6.02) on the shared [SavedViewsStore] (T2.3.08).
class SavedViewsRepository {
  SavedViewsRepository(AppDatabase db, SyncWriter writer, String Function() userId)
    : store = SavedViewsStore(db, writer, userId, const PlannerViewCodec());

  static const section = ViewSections.planner;

  final SavedViewsStore<PlannerViewConfig> store;

  /// Deterministic id of the built-in view of a registry entry (converges across devices).
  static String entryViewId(String userId, String entryId) => SavedViewsStore.builtInId(userId, section, entryId);

  static SavedView _map(StoredView<PlannerViewConfig> v) =>
      SavedView(id: v.id, name: v.name, config: v.config, isDefault: v.isDefault, sortKey: v.sortKey);

  Stream<List<SavedView>> watchAll() => store.watchAll().map((views) => views.map(_map).toList());

  Future<List<SavedView>> all() async => (await store.all()).map(_map).toList();

  Future<SavedView?> byId(String id) async {
    final view = await store.byId(id);
    return view == null ? null : _map(view);
  }

  static Map<String, BuiltInView<PlannerViewConfig>> _entries(Map<String, (PlannerViewConfig, String)> entries) => {
    for (final e in entries.entries) e.key: (config: e.value.$1, name: e.value.$2),
  };

  /// First run: one built-in view per MVP type (week table = default). Idempotent.
  Future<void> ensureDefaults(Map<String, (PlannerViewConfig, String)> entries, {String defaultEntry = 'week_table'}) =>
      store.ensureDefaults(_entries(entries), defaultEntry: defaultEntry);

  /// Deletes the user's own views and restores every built-in (one undoable operation).
  Future<OpRecord> resetToDefaults(
    Map<String, (PlannerViewConfig, String)> entries, {
    String defaultEntry = 'week_table',
  }) => store.resetToDefaults(_entries(entries), defaultEntry: defaultEntry);

  /// Creates or updates the built-in view of a registry entry.
  Future<OpRecord> saveEntry(String entryId, String name, PlannerViewConfig config) =>
      store.saveBuiltIn(entryId, name, config);

  Future<OpRecord> saveConfig(String id, PlannerViewConfig config) => store.saveConfig(id, config);

  /// "Save view as…" — returns the new id.
  Future<String> create(String name, PlannerViewConfig config) => store.create(name, config);

  Future<OpRecord> rename(String id, String name) => store.rename(id, name);

  Future<String?> duplicate(String id, String name) => store.duplicate(id, name);

  Future<OpRecord> delete(String id) => store.delete(id);

  /// Marks [id] as the planner default (clears the flag elsewhere in the same operation).
  Future<OpRecord> setDefault(String id) => store.setDefault(id);

  /// Moves [id] between two neighbours (fractional order).
  Future<OpRecord> move(String id, {String? afterKey, String? beforeKey}) =>
      store.move(id, afterKey: afterKey, beforeKey: beforeKey);
}
