import 'dart:isolate';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/attachments/application/providers.dart' show Attachment;
import 'package:everslot/features/checklists/application/checklist_service.dart';
import 'package:everslot/features/checklists/data/checklist_cascades.dart';
import 'package:everslot/features/checklists/data/checklist_items_repository.dart';
import 'package:everslot/features/checklists/data/checklist_ui_state_store.dart';
import 'package:everslot/features/checklists/data/checklists_repository.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:everslot/features/notifications/application/notification_host_api.dart'
    show NotificationHostApi, notificationHostApiProvider;
import 'package:everslot/features/notifications/application/notification_providers.dart' show notificationRulesProvider;
import 'package:everslot/features/notifications/domain/notification_types.dart'
    show NotificationTargetType, RuleTargetType;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reminder rules and mutes follow item / checklist deletes and copies in the same operation
/// (notifications host API, [7.1] cascades).
class ReminderCascades implements ChecklistCascades {
  ReminderCascades(this._api);

  final NotificationHostApi _api;

  @override
  Future<void> itemsDeleted(WriteTx tx, Iterable<String> itemIds) async {
    for (final id in itemIds) {
      await _api.deleteForTargetInTx(tx, NotificationTargetType.checklistItem, id);
    }
  }

  @override
  Future<void> itemsCopied(WriteTx tx, Map<String, String> idMap) async {
    for (final e in idMap.entries) {
      await _api.copyRulesInTx(tx, NotificationTargetType.checklistItem, fromId: e.key, toId: e.value);
    }
  }

  @override
  Future<void> checklistDeleted(WriteTx tx, String checklistId) =>
      _api.deleteForTargetInTx(tx, NotificationTargetType.checklist, checklistId);

  @override
  Future<void> checklistCopied(WriteTx tx, {required String fromId, required String toId}) =>
      _api.copyRulesInTx(tx, NotificationTargetType.checklist, fromId: fromId, toId: toId);
}

final checklistCascadesProvider = Provider<ChecklistCascades>(
  (ref) => ReminderCascades(ref.watch(notificationHostApiProvider)),
);

final checklistsRepositoryProvider = Provider<ChecklistsRepository>(
  (ref) => ChecklistsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
    cascades: ref.watch(checklistCascadesProvider),
  ),
);

final checklistItemsRepositoryProvider = Provider<ChecklistItemsRepository>(
  (ref) => ChecklistItemsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
    cascades: ref.watch(checklistCascadesProvider),
  ),
);

final checklistUiStateStoreProvider = Provider<ChecklistUiStateStore>(
  (ref) => ChecklistUiStateStore(ref.watch(appDatabaseProvider)),
);

final boardConfigStoreProvider = Provider<BoardConfigStore>(
  (ref) => BoardConfigStore(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final checklistServiceProvider = Provider<ChecklistService>(
  (ref) => ChecklistService(
    ref.watch(checklistsRepositoryProvider),
    ref.watch(checklistItemsRepositoryProvider),
    ref.watch(clockProvider),
  ),
);

/// Active board cards (not archived, not templates).
final boardChecklistsProvider = StreamProvider<List<Checklist>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(checklistsRepositoryProvider).watchBoard();
});

final archivedChecklistsProvider = StreamProvider.autoDispose<List<Checklist>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(checklistsRepositoryProvider).watchBoard(archived: true);
});

final templatesProvider = StreamProvider.autoDispose<List<Checklist>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(checklistsRepositoryProvider).watchBoard(templates: true);
});

/// Card summaries of the active (false) or archived (true) board, in one batch.
final cardSummariesProvider = StreamProvider.autoDispose.family<Map<String, CardSummary>, bool>((ref, archived) {
  final lists = ref.watch(archived ? archivedChecklistsProvider : boardChecklistsProvider).value ?? const [];
  return ref.watch(checklistsRepositoryProvider).watchCardSummaries([
    for (final c in lists) c.id,
  ], now: ref.read(clockProvider).nowUtc());
});

final cardThumbnailsProvider = StreamProvider.autoDispose.family<Map<String, Attachment>, bool>((ref, archived) {
  final lists = ref.watch(archived ? archivedChecklistsProvider : boardChecklistsProvider).value ?? const [];
  return ref.watch(checklistsRepositoryProvider).watchCardThumbnails([for (final c in lists) c.id]);
});

final boardConfigProvider = StreamProvider<BoardConfig>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(boardConfigStoreProvider).watch();
});

final smartCountsProvider = StreamProvider<SmartCounts>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(checklistsRepositoryProvider).watchSmartCounts(now: ref.read(clockProvider).nowUtc());
});

final smartItemsProvider = StreamProvider.autoDispose.family<List<SmartItem>, SmartKind>((ref, kind) {
  ref.watch(currentUserIdProvider);
  return ref.watch(checklistsRepositoryProvider).watchSmartItems(kind, now: ref.read(clockProvider).nowUtc());
});

/// One checklist (tombstones included so the screen can offer Trash).
final checklistProvider = StreamProvider.autoDispose.family<Checklist?, String>((ref, id) {
  ref.watch(currentUserIdProvider);
  return ref.watch(checklistsRepositoryProvider).watchChecklist(id);
});

/// Live items of the open checklist (only the open one is watched, T4.2.19).
final checklistItemsProvider = StreamProvider.autoDispose.family<List<ChecklistItem>, String>((ref, id) {
  ref.watch(currentUserIdProvider);
  return ref.watch(checklistItemsRepositoryProvider).watchItems(id);
});

/// Lists above this size build their tree in a background isolate (T4.2.19, arch §9.6).
const treeIsolateThreshold = 10000;

/// Builds a tree off the UI isolate; only [items] travel to the worker (the result comes back
/// without a copy through `Isolate.exit`).
Future<ChecklistTree> buildTreeInBackground(List<ChecklistItem> items) =>
    Isolate.run(() => ChecklistTree.build(items), debugName: 'checklist-tree');

final _backgroundTreeProvider = FutureProvider.autoDispose.family<ChecklistTree, String>((ref, id) {
  final items = ref.watch(checklistItemsProvider(id)).value ?? const <ChecklistItem>[];
  return buildTreeInBackground(items);
});

/// Tree of the open checklist (null while loading). Rebuilt only when the rows change; huge lists
/// build it in an isolate and keep showing the previous tree until the new one arrives.
final checklistTreeProvider = Provider.autoDispose.family<ChecklistTree?, String>((ref, id) {
  final items = ref.watch(checklistItemsProvider(id)).value;
  if (items == null) return null;
  if (items.length <= treeIsolateThreshold) return ChecklistTree.build(items);
  return ref.watch(_backgroundTreeProvider(id)).value;
});

final checklistRollupsProvider = Provider.autoDispose.family<Map<String, Rollup>, String>((ref, id) {
  final tree = ref.watch(checklistTreeProvider(id));
  return tree == null ? const {} : RollupCalculator.compute(tree);
});

final collapsedNodesProvider = StreamProvider.autoDispose.family<Set<String>, String>(
  (ref, id) => ref.watch(checklistUiStateStoreProvider).watchCollapsed(id),
);

/// Attachment counts per item of a checklist (badges, "has attachments" filter).
final itemAttachmentCountsProvider = StreamProvider.autoDispose.family<Map<String, int>, String>(
  (ref, id) => ref.watch(checklistItemsRepositoryProvider).watchAttachmentCounts(id),
);

/// Every attachment of a checklist (items + checklist-level).
/// Every item of the active lists with its list and path (flat all-items table, T4.5.15).
final allItemsProvider = StreamProvider.autoDispose<List<SmartItem>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(checklistsRepositoryProvider).watchAllItems();
});

/// Attachment counts of every item of the active lists (all-items table).
final allItemAttachmentCountsProvider = StreamProvider.autoDispose<Map<String, int>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(checklistsRepositoryProvider).watchAllItemAttachmentCounts();
});

final checklistAttachmentsProvider = StreamProvider.autoDispose.family<List<Attachment>, String>(
  (ref, id) => ref.watch(checklistItemsRepositoryProvider).watchChecklistAttachments(id),
);

final itemStatusEventsProvider = StreamProvider.autoDispose.family<List<StatusEvent>, String>(
  (ref, itemId) => ref.watch(checklistItemsRepositoryProvider).watchStatusEvents(itemId),
);

final checklistRunsProvider = StreamProvider.autoDispose.family<List<ChecklistRun>, String>(
  (ref, id) => ref.watch(checklistsRepositoryProvider).watchRuns(id),
);

/// Checklists and items with their own enabled reminder rules (bell icons on rows and cards,
/// T4.2.08 / T4.1.08). Rules themselves are edited through the notifications section.
final ownReminderTargetsProvider = Provider<Set<String>>((ref) {
  final rules = ref.watch(notificationRulesProvider).value ?? const [];
  return {
    for (final r in rules)
      if (r.enabled &&
          !r.isDefault &&
          r.targetId != null &&
          (r.targetType == RuleTargetType.checklist || r.targetType == RuleTargetType.checklistItem))
        r.targetId!,
  };
});
