import 'package:everslot/core/providers.dart';
import 'package:everslot/shared/views/data/saved_views_store.dart';
import 'package:everslot/shared/views/domain/saved_view_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:everslot/shared/views/data/saved_views_store.dart' show BuiltInView, SavedViewsStore;
export 'package:everslot/shared/views/domain/saved_view_config.dart';

/// Codecs of the sections whose presets are JSON maps (the planner has its typed codec).
const sectionViewCodecs = <String, JsonViewCodec>{
  ViewSections.checklists: JsonViewCodec(ViewSections.checklists, defaultType: 'board'),
  ViewSections.habits: JsonViewCodec(ViewSections.habits, defaultType: 'today'),
  ViewSections.stats: JsonViewCodec(ViewSections.stats, defaultType: 'overview'),
};

/// View presets store of a section (T2.3.08): Lists, Habits or Insights.
final sectionViewsStoreProvider = Provider.family<SavedViewsStore<JsonViewConfig>, String>(
  (ref, section) => SavedViewsStore(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
    sectionViewCodecs[section] ?? (throw ArgumentError.value(section, 'section', 'no JSON view codec')),
  ),
);

/// Live presets of a section, ordered.
final sectionViewsProvider = StreamProvider.family<List<StoredView<JsonViewConfig>>, String>((ref, section) {
  ref.watch(currentUserIdProvider);
  return ref.watch(sectionViewsStoreProvider(section)).watchAll();
});
