import 'package:everslot/core/providers.dart';
import 'package:everslot/features/organization/data/categories_repository.dart';
import 'package:everslot/features/organization/domain/category.dart';
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
