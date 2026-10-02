import 'package:everslot/core/providers.dart';
import 'package:everslot/features/search/data/global_search_queries.dart';
import 'package:everslot/features/search/data/search_recents_store.dart';
import 'package:everslot/features/search/domain/search_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global search over the FTS index, enriched for the search screen (T8.1.14).
final globalSearchQueriesProvider = Provider<GlobalSearchQueries>((ref) {
  final zones = ref.watch(zoneResolverProvider);
  final zone = ref.watch(deviceZoneProvider);
  return GlobalSearchQueries(
    ref.watch(appDatabaseProvider),
    ref.watch(searchIndexProvider),
    (utc) => zones.toLocal(utc, zone).date,
  );
});

final searchRecentsStoreProvider = Provider<SearchRecentsStore>(
  (ref) => SearchRecentsStore(ref.watch(appDatabaseProvider)),
);

/// Recent searches, newest first (T8.1.15; local only).
final searchRecentsProvider = AsyncNotifierProvider<SearchRecentsController, List<String>>(SearchRecentsController.new);

class SearchRecentsController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() => ref.watch(searchRecentsStoreProvider).load();

  Future<void> add(String query) async => _set(addRecent(await future, query));

  Future<void> remove(String query) async => _set([
    for (final r in await future)
      if (r != query) r,
  ]);

  Future<void> clear() => _set(const <String>[]);

  Future<void> _set(List<String> next) async {
    state = AsyncData(next);
    await ref.read(searchRecentsStoreProvider).save(next);
  }
}
