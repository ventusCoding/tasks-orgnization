import 'dart:io';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:everslot/features/checklists/presentation/markdown_lite.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:everslot/features/organization/domain/tag.dart';
import 'package:everslot/features/organization/presentation/tag_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Card background derived from the stored ARGB color (tonal light/dark variants, T4.1.08).
Color cardBackground(BuildContext context, int? argb) =>
    argb == null ? context.colors.surfaceContainerLow : CategoryColors.background(argb, Theme.of(context).brightness);

/// Status-split segments of a roll-up (progress bars on cards, headers, collapsed rows).
List<BarSegment> statusSegments(BuildContext context, Rollup r) => [
  BarSegment(
    r.completed.toDouble(),
    StatusStyle.color(context, ItemStatus.completed),
    StatusStyle.label(context, ItemStatus.completed),
  ),
  BarSegment(
    r.ongoing.toDouble(),
    StatusStyle.color(context, ItemStatus.ongoing),
    StatusStyle.label(context, ItemStatus.ongoing),
  ),
  BarSegment(
    r.waiting.toDouble(),
    StatusStyle.color(context, ItemStatus.waiting),
    StatusStyle.label(context, ItemStatus.waiting),
  ),
  BarSegment(
    r.blocked.toDouble(),
    StatusStyle.color(context, ItemStatus.blocked),
    StatusStyle.label(context, ItemStatus.blocked),
  ),
  BarSegment(r.todo.toDouble(), context.colors.outlineVariant, StatusStyle.label(context, ItemStatus.todo)),
];

/// A Keep-like board card (T4.1.08): title, body excerpt, first rows, progress, badges, thumbnail.
class ChecklistCard extends ConsumerWidget {
  const ChecklistCard({
    required this.checklist,
    required this.summary,
    super.key,
    this.thumbnail,
    this.showBody = true,
    this.maxRows = 6,
    this.onTap,
    this.onMenu,
    this.hasReminders = false,
    this.labels = const [],
  });

  final Checklist checklist;
  final CardSummary summary;
  final Attachment? thumbnail;
  final bool showBody;
  final int maxRows;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  /// The list has its own reminder rules (bell, T4.1.08).
  final bool hasReminders;

  /// Labels shown as chips at the bottom of the card (T4.1.12).
  final List<Tag> labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final bg = cardBackground(context, checklist.color);
    final fg = checklist.color == null ? context.colors.onSurface : CategoryColors.onBackground(bg);
    final muted = fg.withValues(alpha: 0.72);
    final rollup = summary.rollup;
    final hideBoxes = checklist.settings.hideCheckboxes;
    final title = checklist.title.trim();
    final progress = rollup.leafCountable == 0 ? '' : l.listsCardProgress(rollup.leafCompleted, rollup.leafCountable);
    final rows = summary.rows.take(maxRows).toList();
    final more = summary.itemCount - rows.length;
    return Semantics(
      button: true,
      label: l.listsCardSemantics(title.isEmpty ? l.listsUntitled : title, progress),
      child: Card(
        color: bg,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: checklist.color == null ? BorderSide(color: context.colors.outlineVariant) : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (thumbnail != null) _Thumb(attachment: thumbnail!),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.md, Space.sm, 0, Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(top: Space.sm),
                            child: title.isEmpty
                                ? const SizedBox.shrink()
                                : Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        if (hasReminders)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: Space.sm, start: Space.xs),
                            child: Icon(
                              Icons.notifications_active_outlined,
                              size: 16,
                              color: muted,
                              semanticLabel: l.checklistHasReminders,
                            ),
                          ),
                        if (checklist.isRecurring)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: Space.sm, start: Space.xs),
                            child: Icon(Icons.repeat, size: 16, color: muted, semanticLabel: l.listsRepeats),
                          ),
                        if (onMenu != null)
                          IconButton(
                            tooltip: l.listsCardActions,
                            icon: Icon(Icons.more_vert, color: muted),
                            onPressed: onMenu,
                          )
                        else
                          const SizedBox(width: Space.md),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: Space.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showBody && checklist.hasBody) ...[
                            const SizedBox(height: Space.xs),
                            Text(
                              stripMarkdown(checklist.body!),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodyMedium?.copyWith(color: fg),
                            ),
                          ],
                          if (rows.isNotEmpty) const SizedBox(height: Space.xs),
                          for (final r in rows) _CardRowView(row: r, fg: fg, muted: muted, bullet: hideBoxes),
                          if (more > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: Space.xxs),
                              child: Text(
                                l.listsCardMore(more),
                                style: context.text.labelSmall?.copyWith(color: muted),
                              ),
                            ),
                          if (!hideBoxes && rollup.leafCountable > 0) ...[
                            const SizedBox(height: Space.sm),
                            Row(
                              children: [
                                Text(progress, style: context.text.labelMedium?.copyWith(color: fg)),
                                const SizedBox(width: Space.sm),
                                Expanded(child: SegmentedBar(segments: statusSegments(context, rollup), height: 4)),
                              ],
                            ),
                          ],
                          if (rollup.blockedBelow + rollup.waitingBelow + summary.staleCount > 0) ...[
                            const SizedBox(height: Space.sm),
                            Wrap(
                              spacing: Space.xs,
                              runSpacing: Space.xs,
                              children: [
                                if (rollup.blockedBelow > 0)
                                  StatusPill(
                                    label: l.listsBadgeBlocked(rollup.blockedBelow),
                                    color: StatusStyle.color(context, ItemStatus.blocked),
                                    icon: StatusStyle.icon(ItemStatus.blocked),
                                    dense: true,
                                  ),
                                if (rollup.waitingBelow > 0)
                                  StatusPill(
                                    label: l.listsBadgeWaiting(rollup.waitingBelow),
                                    color: StatusStyle.color(context, ItemStatus.waiting),
                                    icon: StatusStyle.icon(ItemStatus.waiting),
                                    dense: true,
                                  ),
                                if (summary.staleCount > 0)
                                  StatusPill(
                                    label: l.listsBadgeStale(summary.staleCount),
                                    color: context.appColors.skipped,
                                    icon: Icons.hourglass_empty,
                                    dense: true,
                                  ),
                              ],
                            ),
                          ],
                          if (labels.isNotEmpty) ...[
                            const SizedBox(height: Space.sm),
                            Wrap(
                              spacing: Space.xs,
                              runSpacing: Space.xs,
                              children: [for (final t in labels) TagChip(tag: t)],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardRowView extends StatelessWidget {
  const _CardRowView({required this.row, required this.fg, required this.muted, required this.bullet});

  final CardRow row;
  final Color fg;
  final Color muted;
  final bool bullet;

  @override
  Widget build(BuildContext context) {
    final done = row.status == ItemStatus.completed || row.status == ItemStatus.cancelled;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: row.depth * 14.0, top: 1, bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: bullet
                ? Padding(
                    padding: const EdgeInsets.all(5),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: muted, shape: BoxShape.circle),
                    ),
                  )
                : Icon(
                    StatusStyle.icon(row.status),
                    size: 15,
                    color: row.status == ItemStatus.todo ? muted : StatusStyle.color(context, row.status),
                  ),
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(
              row.text.isEmpty ? ' ' : row.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(
                color: done ? muted : fg,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends ConsumerWidget {
  const _Thumb({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.watch(attachmentLocalProvider(attachment.id)).value;
    final path = local?.displayPath;
    if (path == null) return const SizedBox.shrink();
    final ratio = (attachment.width ?? 4) / ((attachment.height ?? 3) == 0 ? 3 : (attachment.height ?? 3));
    return AspectRatio(
      aspectRatio: ratio.clamp(0.75, 2.2),
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        cacheWidth: 600,
        semanticLabel: attachment.caption ?? attachment.fileName,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
