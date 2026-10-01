import 'dart:async';
import 'dart:io';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/presentation/attachment_ui.dart';
import 'package:everslot/features/attachments/presentation/attachment_viewer.dart';
import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/presentation/status_sheet.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Which items a kanban shows (T4.5.03).
enum KanbanScope { leaves, all, children }

/// Kanban by status (T4.5.03). Dragging a card to another column runs the status transition;
/// waiting/blocked open the reason sheet. Order within a column follows the outline.
class KanbanView extends ConsumerStatefulWidget {
  const KanbanView({required this.checklistId, required this.onOpenItem, super.key});

  final String checklistId;
  final ValueChanged<ChecklistItem> onOpenItem;

  @override
  ConsumerState<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends ConsumerState<KanbanView> {
  KanbanScope _scope = KanbanScope.leaves;
  bool _showCancelled = false;
  final _pages = PageController(viewportFraction: 0.86);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<String> _scopeIds(ChecklistTree t, String? root) {
    final scope = root == null ? t.order : t.descendants(root);
    return switch (_scope) {
      KanbanScope.leaves => [
        for (final id in scope)
          if (t.isLeaf(id)) id,
      ],
      KanbanScope.all => scope,
      KanbanScope.children => t.childIds(root),
    };
  }

  Future<void> _drop(ChecklistItem item, ItemStatus to) async {
    if (item.status == to) return;
    final settings = ref.read(checklistProvider(widget.checklistId)).value?.settings ?? ChecklistSettings.defaults;
    String? note;
    DateTime? followUp;
    if (to.promptsReason || settings.requiresReason(to)) {
      final reason = await showReasonSheet(context, ref, status: to, required: settings.requiresReason(to));
      if (reason == null) return;
      note = reason.note;
      followUp = reason.followUpAt;
    }
    unawaited(HapticFeedback.selectionClick());
    await ref
        .read(checklistEditorProvider(widget.checklistId).notifier)
        .setStatus([item.id], to, note: note, setNote: note != null, followUpAt: followUp);
    if (mounted) announce(context, context.l10n.statusMarked(StatusStyle.label(context, to)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tree = ref.watch(checklistTreeProvider(widget.checklistId));
    final root = ref.watch(checklistEditorProvider(widget.checklistId).select((s) => s.focusRootId));
    final rollups = ref.watch(checklistRollupsProvider(widget.checklistId));
    if (tree == null) return const LoadingState();
    final ids = _scopeIds(tree, root);
    final columns = [
      ItemStatus.todo,
      ItemStatus.ongoing,
      ItemStatus.waiting,
      ItemStatus.blocked,
      ItemStatus.completed,
      if (_showCancelled) ItemStatus.cancelled,
    ];
    final now = ref.read(clockProvider).nowUtc();
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    Widget column(ItemStatus s) {
      final cards = [
        for (final id in ids)
          if (tree[id]!.status == s) tree[id]!,
      ];
      return DragTarget<String>(
        onWillAcceptWithDetails: (d) => tree[d.data]?.status != s,
        onAcceptWithDetails: (d) {
          final item = tree[d.data];
          if (item != null) unawaited(_drop(item, s));
        },
        builder: (context, candidates, _) => Container(
          margin: const EdgeInsets.all(Space.xs),
          decoration: BoxDecoration(
            color: candidates.isNotEmpty ? context.colors.primaryContainer : context.colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Row(
                  children: [
                    Icon(StatusStyle.icon(s), size: 18, color: StatusStyle.color(context, s)),
                    const SizedBox(width: Space.xs),
                    Expanded(child: Text(StatusStyle.label(context, s), style: context.text.titleSmall)),
                    Text('${cards.length}', style: context.text.labelMedium),
                  ],
                ),
              ),
              Expanded(
                child: cards.isEmpty
                    ? Center(child: Text(l.kanbanEmptyColumn, style: context.text.bodySmall))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                        itemCount: cards.length,
                        itemBuilder: (_, i) {
                          final item = cards[i];
                          final card = _KanbanCard(
                            item: item,
                            path: [for (final a in tree.ancestors(item.id)) tree[a]!.text],
                            now: now,
                            childDone: rollups[item.id]?.leafCompleted ?? 0,
                            childTotal: tree.hasChildren(item.id) ? rollups[item.id]?.leafCountable ?? 0 : 0,
                            onTap: () => widget.onOpenItem(item),
                          );
                          return LongPressDraggable<String>(
                            data: item.id,
                            onDragStarted: () => unawaited(HapticFeedback.mediumImpact()),
                            feedback: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(Radii.sm),
                              child: SizedBox(width: 240, child: card),
                            ),
                            childWhenDragging: Opacity(opacity: 0.3, child: card),
                            child: card,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.md, vertical: Space.xs),
          child: Row(
            children: [
              SegmentedButton<KanbanScope>(
                segments: [
                  ButtonSegment(value: KanbanScope.leaves, label: Text(l.kanbanLeaves)),
                  ButtonSegment(value: KanbanScope.all, label: Text(l.kanbanAll)),
                  ButtonSegment(value: KanbanScope.children, label: Text(l.kanbanChildren)),
                ],
                selected: {_scope},
                onSelectionChanged: (s) => setState(() => _scope = s.first),
              ),
              const SizedBox(width: Space.sm),
              FilterChip(
                label: Text(l.kanbanShowCancelled),
                selected: _showCancelled,
                onSelected: (v) => setState(() => _showCancelled = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: wide
              ? Row(children: [for (final s in columns) Expanded(child: column(s))])
              : PageView(controller: _pages, padEnds: false, children: [for (final s in columns) column(s)]),
        ),
      ],
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    required this.item,
    required this.path,
    required this.now,
    required this.childDone,
    required this.childTotal,
    required this.onTap,
  });

  final ChecklistItem item;
  final List<String> path;
  final DateTime now;
  final int childDone;
  final int childTotal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: Space.xs),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (path.isNotEmpty)
              Text(
                path.join(' › '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            Text(
              item.text.isEmpty ? context.l10n.checklistItemHint : item.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.hasNote || item.statusNote != null)
              Text(
                item.statusNote ?? item.note!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                if (item.statusSince != null)
                  Text(formatAge(context, item.statusSince!, now), style: context.text.labelSmall),
                const Spacer(),
                if (childTotal > 0)
                  Text(context.l10n.listsCardProgress(childDone, childTotal), style: context.text.labelSmall),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Grid of attachments (shared by the attachments gallery and the gallery view, T4.4.07/T4.5.04).
class AttachmentGrid extends ConsumerWidget {
  const AttachmentGrid({required this.attachments, required this.onTap, super.key, this.captionOf});

  final List<Attachment> attachments;
  final void Function(int index) onTap;
  final String? Function(Attachment a)? captionOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SliverGrid.builder(
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 180,
      mainAxisSpacing: Space.sm,
      crossAxisSpacing: Space.sm,
    ),
    itemCount: attachments.length,
    itemBuilder: (context, i) =>
        _GridTile(attachment: attachments[i], caption: captionOf?.call(attachments[i]), onTap: () => onTap(i)),
  );
}

class _GridTile extends ConsumerWidget {
  const _GridTile({required this.attachment, required this.onTap, this.caption});

  final Attachment attachment;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.watch(attachmentLocalProvider(attachment.id)).value;
    final path = local?.displayPath;
    return Semantics(
      button: true,
      label: caption ?? attachment.caption ?? attachment.fileName,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: context.colors.surfaceContainerHighest,
                child: attachment.isImage && path != null
                    ? Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        cacheWidth: 360,
                        errorBuilder: (_, _, _) => const SizedBox(),
                      )
                    : Center(child: Icon(attachmentIcon(attachment.kind), size: 40, color: context.colors.primary)),
              ),
              if (caption != null)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(Space.xs),
                    color: Colors.black54,
                    child: Text(
                      caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gallery view (T4.5.04): items with images as cards (first image as cover + text + status).
class GalleryView extends ConsumerStatefulWidget {
  const GalleryView({required this.checklistId, required this.onOpenItem, super.key});

  final String checklistId;
  final ValueChanged<ChecklistItem> onOpenItem;

  @override
  ConsumerState<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends ConsumerState<GalleryView> {
  bool _onlyImages = true;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tree = ref.watch(checklistTreeProvider(widget.checklistId));
    final atts = ref.watch(checklistAttachmentsProvider(widget.checklistId)).value ?? const <Attachment>[];
    if (tree == null) return const LoadingState();
    final firstImage = <String, Attachment>{};
    for (final a in atts) {
      if (a.ownerType == AttachmentOwnerType.checklistItem && a.isImage) firstImage.putIfAbsent(a.ownerId, () => a);
    }
    final items = [
      for (final id in tree.order)
        if (!_onlyImages || firstImage.containsKey(id)) tree[id]!,
    ];
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg, vertical: Space.xs),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilterChip(
                label: Text(l.galleryOnlyImages),
                selected: _onlyImages,
                onSelected: (v) => setState(() => _onlyImages = v),
              ),
            ),
          ),
        ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(icon: Icons.photo_library_outlined, title: l.galleryEmpty),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(Space.md),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.78,
                mainAxisSpacing: Space.sm,
                crossAxisSpacing: Space.sm,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final cover = firstImage[item.id];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => widget.onOpenItem(item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: cover == null
                              ? ColoredBox(
                                  color: context.colors.surfaceContainerHighest,
                                  child: Icon(Icons.notes, color: context.colors.outline, size: 36),
                                )
                              : _GridTile(attachment: cover, onTap: () => widget.onOpenItem(item)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(Space.sm),
                          child: Row(
                            children: [
                              Icon(
                                StatusStyle.icon(item.status),
                                size: 16,
                                color: StatusStyle.color(context, item.status),
                              ),
                              const SizedBox(width: Space.xs),
                              Expanded(
                                child: Text(
                                  item.text.isEmpty ? l.checklistItemHint : item.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Every attachment of a checklist grouped by item with breadcrumbs, filterable by type
/// (T4.4.07). Tapping opens the viewer with *Go to item*.
class ChecklistAttachmentsScreen extends ConsumerStatefulWidget {
  const ChecklistAttachmentsScreen({required this.checklistId, required this.onGoToItem, super.key});

  final String checklistId;
  final ValueChanged<String?> onGoToItem;

  @override
  ConsumerState<ChecklistAttachmentsScreen> createState() => _ChecklistAttachmentsScreenState();
}

enum _TypeFilter { all, images, pdfs, other }

class _ChecklistAttachmentsScreenState extends ConsumerState<ChecklistAttachmentsScreen> {
  _TypeFilter _filter = _TypeFilter.all;

  bool _matches(Attachment a) => switch (_filter) {
    _TypeFilter.all => true,
    _TypeFilter.images => a.isImage,
    _TypeFilter.pdfs => a.kind == AttachmentKind.pdf,
    _TypeFilter.other => !a.isImage && a.kind != AttachmentKind.pdf,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tree = ref.watch(checklistTreeProvider(widget.checklistId));
    final all = (ref.watch(checklistAttachmentsProvider(widget.checklistId)).value ?? const <Attachment>[])
        .where(_matches)
        .toList();
    final groups = <String?, List<Attachment>>{};
    for (final a in all) {
      (groups[a.ownerType == AttachmentOwnerType.checklist ? null : a.ownerId] ??= []).add(a);
    }
    final order = [
      if (groups.containsKey(null)) null,
      if (tree != null)
        for (final id in tree.order)
          if (groups.containsKey(id)) id,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.checklistAllAttachments)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: SegmentedButton<_TypeFilter>(
                segments: [
                  ButtonSegment(value: _TypeFilter.all, label: Text(l.attachmentsFilterAll)),
                  ButtonSegment(value: _TypeFilter.images, label: Text(l.attachmentsFilterImages)),
                  ButtonSegment(value: _TypeFilter.pdfs, label: Text(l.attachmentsFilterPdfs)),
                  ButtonSegment(value: _TypeFilter.other, label: Text(l.attachmentsFilterOther)),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
            ),
          ),
          if (all.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(icon: Icons.attach_file, title: l.attachmentsEmpty),
            ),
          for (final owner in order) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                owner == null
                    ? l.attachmentsChecklistLevel
                    : [for (final a in tree!.ancestors(owner)) tree[a]!.text, tree[owner]!.text].join(' › '),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.md),
              sliver: AttachmentGrid(
                attachments: groups[owner]!,
                onTap: (i) => openAttachmentViewer(
                  context,
                  groups[owner]!,
                  i,
                  onGoToOwner: () {
                    Navigator.of(context).pop();
                    widget.onGoToItem(owner);
                  },
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
        ],
      ),
    );
  }
}
