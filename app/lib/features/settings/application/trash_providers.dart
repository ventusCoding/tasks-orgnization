import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/settings/data/trash_remote.dart';
import 'package:everslot/features/settings/data/trash_repository.dart';
import 'package:everslot/features/settings/domain/trash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final trashRepositoryProvider = Provider<TrashRepository>(
  (ref) => TrashRepository(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider)),
);

/// `app.purge_now` client, or null on a local-only device (purge is local only).
final trashRemoteProvider = Provider<TrashRemote?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(sessionProvider);
  if (client == null || session == null || !session.isCloud) return null;
  return SupabaseTrashRemote(client);
});

/// Live trash of the current user (deleted in the last 30 days).
final trashEntriesProvider = StreamProvider.autoDispose<List<TrashEntry>>((ref) {
  ref.watch(currentUserIdProvider);
  final clock = ref.watch(clockProvider);
  return ref.watch(trashRepositoryProvider).watch(since: () => clock.nowUtc().subtract(trashRetention));
});

enum TrashFailure {
  /// "Delete forever" needs the server on a synced account.
  offline,

  /// The deletion itself hasn't reached the server yet (and couldn't be pushed now).
  notSynced,
}

class TrashException implements Exception {
  const TrashException(this.failure);

  final TrashFailure failure;

  @override
  String toString() => 'TrashException(${failure.name})';
}

final trashServiceProvider = Provider<TrashService>(TrashService.new);

/// Trash actions (T8.3.06): restore (the entry and what was deleted with it, one synced
/// operation) and delete forever (`app.purge_now` on synced accounts, then the local rows,
/// outbox entries and attachment files).
class TrashService {
  TrashService(this._ref);

  final Ref _ref;
  static final _log = AppLog.get('trash');

  TrashRepository get _repo => _ref.read(trashRepositoryProvider);

  Future<int> restore(TrashEntry entry) => _repo.restore(entry);

  Future<void> deleteForever(TrashEntry entry) async {
    final repo = _repo;
    final remote = _ref.read(trashRemoteProvider);
    if (remote != null) {
      if (await repo.hasPendingChanges(entry)) {
        // The server must hold the tombstone first, otherwise the row would survive there.
        try {
          await _ref.read(syncServiceProvider)?.syncNow(manual: true).timeout(const Duration(seconds: 20));
        } on Object catch (e) {
          _log.info('push before purge failed: $e');
        }
        if (await repo.hasPendingChanges(entry)) throw const TrashException(TrashFailure.notSynced);
      }
      try {
        await remote.purge(entry.kind.entityType, [entry.id]);
      } on SyncApiException {
        rethrow;
      } on Object catch (e) {
        _log.info('purge_now unreachable: $e');
        throw const TrashException(TrashFailure.offline);
      }
    }
    final plan = await repo.purgePlan(entry);
    final attachmentIds = await repo.purgeLocal(plan);
    await _deleteFiles(attachmentIds);
  }

  /// Deletes every entry forever; returns how many were purged (stops at the first failure).
  Future<int> emptyTrash(List<TrashEntry> entries) async {
    var n = 0;
    for (final e in entries) {
      await deleteForever(e);
      n++;
    }
    return n;
  }

  Future<void> _deleteFiles(List<String> attachmentIds) async {
    for (final id in attachmentIds) {
      try {
        await _ref.read(attachmentFileStoreProvider).deleteAll(id);
        await _ref.read(attachmentCacheStoreProvider).remove(id);
      } on Object catch (e) {
        _log.fine('attachment files already gone ($id): $e');
      }
    }
  }
}
