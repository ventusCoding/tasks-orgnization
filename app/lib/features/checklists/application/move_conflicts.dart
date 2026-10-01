import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A pushed checklist move the server rejected because another device moved the tree first
/// (`checklist_cycle` / `checklist_parent_mismatch`, T4.1.05). The sync engine already dropped the
/// group's outbox entries and overwrote the local rows with the server state.
bool isChecklistMoveConflict(SyncRejection r) =>
    r.rows.containsKey('checklist_items') && (r.mentions('checklist_cycle') || r.mentions('checklist_parent_mismatch'));

/// Checklist move conflicts of the running sync engine (none in local-only mode).
final checklistMoveConflictsProvider = StreamProvider<SyncRejection>((ref) {
  final service = ref.watch(syncServiceProvider);
  if (service == null) return const Stream.empty();
  return service.rejections.where(isChecklistMoveConflict);
});
