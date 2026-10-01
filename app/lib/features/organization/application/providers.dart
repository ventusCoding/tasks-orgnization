import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/data/categories_repository.dart';
import 'package:everslot/features/organization/data/tags_repository.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:everslot/features/organization/domain/tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

/// Active (non-archived) categories, ordered.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(categoriesRepositoryProvider).watchAll();
});

/// All categories including archived (management screen).
final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(categoriesRepositoryProvider).watchAll(includeArchived: true);
});

/// Lookup by id (null when missing / no category).
final categoryByIdProvider = Provider.family<Category?, String?>((ref, id) {
  if (id == null) return null;
  final all = ref.watch(allCategoriesProvider).value ?? const <Category>[];
  for (final c in all) {
    if (c.id == id) return c;
  }
  return null;
});

/// Number of live tasks, habits and checklists per category id (management screen, delete
/// reassignment prompt).
final categoryUsageCountsProvider = StreamProvider.autoDispose<Map<String, int>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(categoriesRepositoryProvider).watchUsageCounts();
});

// ------------------------------------------------------------------------------------ tags --

/// Tags & entity tags (T2.3.10) — other features use this provider (never the data class).
final tagsRepositoryProvider = Provider<TagsRepository>(
  (ref) => TagsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

/// All tags, ordered.
final tagsProvider = StreamProvider<List<Tag>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(tagsRepositoryProvider).watchAll();
});

/// Lookup by id (null when missing).
final tagByIdProvider = Provider.family<Tag?, String?>((ref, id) {
  if (id == null) return null;
  for (final t in ref.watch(tagsProvider).value ?? const <Tag>[]) {
    if (t.id == id) return t;
  }
  return null;
});

/// Live tags of one entity (chips on tasks, checklists, items, habits).
final entityTagsProvider = StreamProvider.autoDispose.family<List<Tag>, TaggedEntity>((ref, e) {
  ref.watch(currentUserIdProvider);
  return ref.watch(tagsRepositoryProvider).watchForEntity(e.type, e.id);
});

/// Tags of every entity of a type (entity id → tags) for boards and lists.
final tagsByEntityProvider = StreamProvider.autoDispose.family<Map<String, List<Tag>>, String>((ref, entityType) {
  ref.watch(currentUserIdProvider);
  return ref.watch(tagsRepositoryProvider).watchByEntity(entityType);
});

/// Number of live tagged entities per tag id (management screen).
final tagUsageCountsProvider = StreamProvider.autoDispose<Map<String, int>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(tagsRepositoryProvider).watchUsageCounts();
});
