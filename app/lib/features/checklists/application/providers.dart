import 'package:everslot/core/providers.dart';
import 'package:everslot/features/attachments/application/providers.dart' show Attachment;
import 'package:everslot/features/checklists/application/checklist_service.dart';
import 'package:everslot/features/checklists/data/checklist_items_repository.dart';
import 'package:everslot/features/checklists/data/checklist_ui_state_store.dart';
import 'package:everslot/features/checklists/data/checklists_repository.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final checklistsRepositoryProvider = Provider<ChecklistsRepository>(
  (ref) => ChecklistsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final checklistItemsRepositoryProvider = Provider<ChecklistItemsRepository>(
  (ref) => ChecklistItemsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
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
  return ref
      .watch(checklistsRepositoryProvider)
      .watchCardSummaries([for (final c in lists) c.id], now: ref.read(clockProvider).nowUtc());
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

/// Tree of the open checklist (null while loading). Rebuilt only when the rows change.
final checklistTreeProvider = Provider.autoDispose.family<ChecklistTree?, String>((ref, id) {
  final items = ref.watch(checklistItemsProvider(id)).value;
  return items == null ? null : ChecklistTree.build(items);
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
final checklistAttachmentsProvider = StreamProvider.autoDispose.family<List<Attachment>, String>(
  (ref, id) => ref.watch(checklistItemsRepositoryProvider).watchChecklistAttachments(id),
);

final itemStatusEventsProvider = StreamProvider.autoDispose.family<List<StatusEvent>, String>(
  (ref, itemId) => ref.watch(checklistItemsRepositoryProvider).watchStatusEvents(itemId),
);

final checklistRunsProvider = StreamProvider.autoDispose.family<List<ChecklistRun>, String>(
  (ref, id) => ref.watch(checklistsRepositoryProvider).watchRuns(id),
);
