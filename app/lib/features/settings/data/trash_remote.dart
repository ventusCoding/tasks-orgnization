import 'package:everslot/core/sync/sync_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Server side of "Delete forever" (T8.3.06): `app.purge_now(entity_type, ids)` hard-deletes the
/// caller's own tombstones (security definer) and queues their storage objects for deletion.
abstract interface class TrashRemote {
  /// Returns the number of purged rows. Throws [SyncApiException] (or a network error).
  Future<int> purge(String entityType, List<String> ids);
}

class SupabaseTrashRemote implements TrashRemote {
  SupabaseTrashRemote(this._client);

  final SupabaseClient _client;

  @override
  Future<int> purge(String entityType, List<String> ids) async {
    try {
      final res = await _client
          .schema('app')
          .rpc<dynamic>('purge_now', params: {'p_entity_type': entityType, 'p_ids': ids});
      return res is Map ? ((res['purged'] as num?)?.toInt() ?? 0) : 0;
    } on PostgrestException catch (e) {
      throw SupabaseSyncApi.mapPostgrestError(e);
    }
  }
}
