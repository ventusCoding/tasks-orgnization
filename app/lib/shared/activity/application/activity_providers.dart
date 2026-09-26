import 'package:everslot/core/providers.dart';
import 'package:everslot/shared/activity/data/activity_repository.dart';
import 'package:everslot/shared/activity/domain/activity_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:everslot/shared/activity/application/activity_logger.dart';
export 'package:everslot/shared/activity/domain/activity_event.dart';

/// Activity log reads (T2.3.05) — other features use these providers, never the data class.
final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(
    ref.watch(appDatabaseProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

/// Key of an entity history query.
typedef ActivityQuery = ({
  String entityType,
  String entityId,
  bool includeChildren,
});

/// History of one entity, newest first (timeline widget, status/reschedule history).
final entityActivityProvider = StreamProvider.autoDispose
    .family<List<ActivityEvent>, ActivityQuery>((ref, q) {
      ref.watch(currentUserIdProvider);
      return ref
          .watch(activityRepositoryProvider)
          .watchForEntity(
            q.entityType,
            q.entityId,
            includeChildren: q.includeChildren,
          );
    });

/// Delete operations of the last 30 days (Trash grouping, arch §9.3).
final deleteOperationsProvider =
    StreamProvider.autoDispose<List<ActivityOperation>>((ref) {
      ref.watch(currentUserIdProvider);
      final since = ref
          .watch(clockProvider)
          .nowUtc()
          .subtract(const Duration(days: 30));
      return ref
          .watch(activityRepositoryProvider)
          .watchDeleteOperations(since: since);
    });
