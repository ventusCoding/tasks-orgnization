import 'package:everslot/core/sync/sync_writer.dart';

/// Rows other features keep per checklist or item (reminder rules and mutes, …) that must follow
/// deletes and copies inside the SAME operation (T4.2.03, T4.1.14, [7.1] host cascades). The
/// repositories call it from their `SyncWriter.run`; the application layer provides the
/// implementation, so this layer never depends on another feature's data.
abstract interface class ChecklistCascades {
  Future<void> itemsDeleted(WriteTx tx, Iterable<String> itemIds);

  /// Source item id → copy id.
  Future<void> itemsCopied(WriteTx tx, Map<String, String> idMap);

  Future<void> checklistDeleted(WriteTx tx, String checklistId);

  Future<void> checklistCopied(WriteTx tx, {required String fromId, required String toId});
}
