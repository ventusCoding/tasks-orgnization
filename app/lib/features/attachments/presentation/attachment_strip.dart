import 'dart:async';
import 'dart:io';

import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/domain/transfer.dart';
import 'package:everslot/features/attachments/presentation/attachment_ui.dart';
import 'package:everslot/features/attachments/presentation/attachment_viewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Called after an attachment operation so hosts can put it on their own undo stack.
typedef AttachmentOpCallback = void Function(String label, OpRecord record);

/// Reusable horizontal attachment strip (T2.2.07): thumbnails / file chips with status badges,
/// "+ add", tap → viewer, long-press menu (caption, share, move, remove with undo).
///
/// Used unchanged by checklist items, tasks and habit logs:
/// `AttachmentStrip(ownerType: AttachmentOwnerType.checklistItem, ownerId: item.id)`.
class AttachmentStrip extends ConsumerWidget {
  const AttachmentStrip({
    required this.ownerType,
    required this.ownerId,
    super.key,
    this.editable = true,
    this.compact = false,
    this.maxVisible = 4,
    this.showAddButton = true,
    this.onOperation,
    this.onGoToOwner,
  });

  final String ownerType;
  final String ownerId;
  final bool editable;

  /// Smaller tiles (edit-mode rows).
  final bool compact;

  /// Tiles shown before a "+N" chip.
  final int maxVisible;
  final bool showAddButton;
  final AttachmentOpCallback? onOperation;
  final VoidCallback? onGoToOwner;

  double get _size => compact ? 44 : 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(attachmentsForOwnerProvider((type: ownerType, id: ownerId))).value ?? const [];
    if (attachments.isEmpty && !(editable && showAddButton)) return const SizedBox.shrink();
    final visible = attachments.length > maxVisible ? attachments.sublist(0, maxVisible) : attachments;
    final hidden = attachments.length - visible.length;
    // The horizontal list forces its full height on children: center them so tiles keep their
    // own (square) size.
    return SizedBox(
      height: (_size < 48 ? 48 : _size) + (compact ? 0 : Space.xs),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [for (final child in _tiles(context, ref, attachments, visible, hidden)) Center(child: child)],
      ),
    );
  }

  List<Widget> _tiles(
    BuildContext context,
    WidgetRef ref,
    List<Attachment> attachments,
    List<Attachment> visible,
    int hidden,
  ) => [
    for (var i = 0; i < visible.length; i++)
      Padding(
        padding: const EdgeInsetsDirectional.only(end: Space.sm),
        child: AttachmentTile(
          attachment: visible[i],
          index: i,
          total: attachments.length,
          size: _size,
          onTap: () => openAttachmentViewer(context, attachments, i, onGoToOwner: onGoToOwner),
          onLongPress: editable ? () => _menu(context, ref, attachments, i) : null,
        ),
      ),
    if (hidden > 0)
      Padding(
        padding: const EdgeInsetsDirectional.only(end: Space.sm),
        child: _MoreChip(
          count: hidden,
          size: _size,
          onTap: () => openAttachmentViewer(context, attachments, maxVisible, onGoToOwner: onGoToOwner),
        ),
      ),
    if (editable && showAddButton)
      _AddTile(
        size: _size,
        onTap: () async {
          final result = await pickAndAddAttachments(context, ref, ownerType: ownerType, ownerId: ownerId);
          final record = result?.record;
          if (record != null && context.mounted) onOperation?.call(context.l10n.attachmentsAdd, record);
        },
      ),
  ];

  Future<void> _menu(BuildContext context, WidgetRef ref, List<Attachment> all, int index) async {
    final a = all[index];
    final l = context.l10n;
    final action = await showAppSheet<String>(
      context,
      title: a.caption ?? a.fileName,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.short_text),
            title: Text(l.attachmentsEditCaption),
            onTap: () => Navigator.pop(ctx, 'caption'),
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text(l.actionShare),
            onTap: () => Navigator.pop(ctx, 'share'),
          ),
          if (index > 0)
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: Text(l.attachmentsMoveEarlier),
              onTap: () => Navigator.pop(ctx, 'earlier'),
            ),
          if (index < all.length - 1)
            ListTile(
              leading: const Icon(Icons.arrow_forward),
              title: Text(l.attachmentsMoveLater),
              onTap: () => Navigator.pop(ctx, 'later'),
            ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: ctx.colors.error),
            title: Text(l.attachmentsRemove),
            onTap: () => Navigator.pop(ctx, 'remove'),
          ),
          const SizedBox(height: Space.md),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    await runAttachmentAction(context, ref, action, all, index, onOperation: onOperation);
  }
}

/// Executes a strip/viewer menu action.
Future<void> runAttachmentAction(
  BuildContext context,
  WidgetRef ref,
  String action,
  List<Attachment> all,
  int index, {
  AttachmentOpCallback? onOperation,
}) async {
  final a = all[index];
  final l = context.l10n;
  final service = ref.read(attachmentServiceProvider);
  switch (action) {
    case 'caption':
      final caption = await promptText(context, title: l.attachmentsEditCaption, initial: a.caption, allowEmpty: true);
      if (caption == null) return;
      final record = await service.setCaption(a.id, caption);
      onOperation?.call(l.attachmentsEditCaption, record);
    case 'share':
      await shareAttachment(ref, a);
    case 'earlier':
      final before = index - 2 >= 0 ? all[index - 2].sortKey : null;
      final record = await service.move(a.id, afterKey: before, beforeKey: all[index - 1].sortKey);
      onOperation?.call(l.attachmentsMoveEarlier, record);
    case 'later':
      final after = index + 2 < all.length ? all[index + 2].sortKey : null;
      final record = await service.move(a.id, afterKey: all[index + 1].sortKey, beforeKey: after);
      onOperation?.call(l.attachmentsMoveLater, record);
    case 'remove':
      final record = await service.remove(a.id);
      if (!context.mounted) return;
      if (onOperation != null) {
        onOperation(l.attachmentsRemoved, record);
      } else {
        showUndoSnackBar(context, ref, message: l.attachmentsRemoved, record: record);
      }
  }
}

/// Shares the original file through the platform share sheet ("open with", T2.2.06).
Future<void> shareAttachment(WidgetRef ref, Attachment a) async {
  final path = await ref.read(attachmentDownloaderProvider).ensureOriginal(a);
  if (path == null) return;
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: a.mimeType, name: a.fileName)],
      title: a.caption ?? a.fileName,
    ),
  );
}

/// One thumbnail (image) or file chip with its transfer badge.
class AttachmentTile extends ConsumerStatefulWidget {
  const AttachmentTile({
    required this.attachment,
    required this.index,
    required this.total,
    super.key,
    this.size = 64,
    this.onTap,
    this.onLongPress,
  });

  final Attachment attachment;
  final int index;
  final int total;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  ConsumerState<AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends ConsumerState<AttachmentTile> {
  bool _requested = false;

  void _ensureThumb(AttachmentLocal local) {
    if (_requested || local.displayPath != null) return;
    _requested = true;
    final downloader = ref.read(attachmentDownloaderProvider);
    if (!downloader.isConfigured) return;
    unawaited(downloader.ensureThumb(widget.attachment).then<void>((_) {}, onError: (Object _) {}));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    final local = ref.watch(attachmentLocalProvider(a.id)).value ?? const AttachmentLocal();
    final transfer = ref.watch(attachmentTransferProvider(a));
    if (a.isImage) _ensureThumb(local);
    final status = transferLabel(context, transfer);
    final label = [
      context.l10n.attachmentsSemantics(attachmentKindLabel(context, a.kind), widget.index + 1, widget.total),
      a.caption ?? a.fileName,
      ?status,
    ].join(', ');
    final radius = BorderRadius.circular(Radii.sm);
    final image = local.displayPath;
    Widget content;
    if (a.isImage && image != null) {
      final cache = (widget.size * MediaQuery.devicePixelRatioOf(context)).round();
      content = Image.file(
        File(image),
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        cacheWidth: cache,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _FileFace(attachment: a, size: widget.size),
      );
    } else {
      content = _FileFace(attachment: a, size: widget.size);
    }
    final onTap = transfer.status == TransferStatus.failed
        ? () => unawaited(ref.read(attachmentServiceProvider).retryUpload(a.id))
        : widget.onTap;
    // One accessible node: the label already says kind, position, name and status (file chips'
    // inner texts would repeat the name).
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      onLongPress: widget.onLongPress,
      excludeSemantics: true,
      child: Tooltip(
        message: a.caption ?? a.fileName,
        excludeFromSemantics: true,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          onLongPress: widget.onLongPress,
          child: ClipRRect(
            borderRadius: radius,
            child: SizedBox(
              width: a.isImage ? widget.size : widget.size * fileChipWidthFactor(context),
              height: widget.size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HeroMode(
                    enabled: !context.reduceMotion,
                    child: Hero(
                      tag: 'attachment-${a.id}',
                      child: ColoredBox(color: context.colors.surfaceContainerHighest, child: content),
                    ),
                  ),
                  PositionedDirectional(
                    end: 2,
                    bottom: 2,
                    child: TransferBadge(transfer: transfer, size: widget.size < 50 ? 14 : 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Width factor of a file chip: grows (bounded) with the text scale so large text keeps showing
/// a useful part of the file name.
double fileChipWidthFactor(BuildContext context) =>
    2.2 * (MediaQuery.textScalerOf(context).scale(10) / 10).clamp(1.0, 1.6);

class _FileFace extends StatelessWidget {
  const _FileFace({required this.attachment, required this.size});

  final Attachment attachment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final compact = size < 50;
    return Padding(
      padding: const EdgeInsets.all(Space.xs),
      child: Row(
        children: [
          Icon(attachmentIcon(attachment.kind), size: compact ? 18 : 24, color: context.colors.primary),
          if (!attachment.isImage) ...[
            const SizedBox(width: Space.xs),
            Expanded(
              // The chip has a fixed height: show as many lines as fit at the current text scale
              // (name first, then size) so text scale 2.0 never overflows. The tooltip and the
              // semantics label always carry the full name.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final style = DefaultTextStyle.of(context).style.merge(context.text.labelSmall);
                  final painter = TextPainter(
                    text: TextSpan(text: 'Ag', style: style),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    maxLines: 1,
                  )..layout();
                  final lineHeight = painter.height;
                  painter.dispose();
                  final fit = lineHeight <= 0 ? 3 : (constraints.maxHeight / lineHeight).floor();
                  if (fit < 1) return const SizedBox.shrink();
                  final showSize = !compact && fit >= 2;
                  final nameLines = (fit - (showSize ? 1 : 0)).clamp(1, compact ? 1 : 2);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.fileName,
                        maxLines: nameLines,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelSmall,
                      ),
                      if (showSize)
                        Text(
                          formatBytes(context, attachment.byteSize),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small corner badge for a transfer status (T2.2.09 / T4.4.03).
class TransferBadge extends StatelessWidget {
  const TransferBadge({required this.transfer, super.key, this.size = 18});

  final AttachmentTransfer transfer;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget? icon;
    switch (transfer.status) {
      case TransferStatus.ready:
        return const SizedBox.shrink();
      case TransferStatus.uploading:
      case TransferStatus.downloading:
      case TransferStatus.processing:
        icon = SizedBox(
          width: size - 4,
          height: size - 4,
          child: CircularProgressIndicator(strokeWidth: 2, value: transfer.progress),
        );
      case TransferStatus.waitingForNetwork:
        icon = Icon(Icons.cloud_upload_outlined, size: size - 4, color: colors.warning);
      case TransferStatus.failed:
        icon = Icon(Icons.error_outline, size: size - 4, color: colors.danger);
      case TransferStatus.notDownloaded:
        icon = Icon(Icons.cloud_download_outlined, size: size - 4, color: colors.info);
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.colors.surface.withValues(alpha: 0.9), shape: BoxShape.circle),
      child: icon,
    );
  }
}

class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.count, required this.size, required this.onTap});

  final int count;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.l10n.attachmentsCount(count),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: ExcludeSemantics(child: Text(context.l10n.attachmentsMore(count), style: context.text.titleSmall)),
      ),
    ),
  );
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.l10n.attachmentsAdd,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Container(
        width: size < 48 ? 48 : size,
        height: size < 48 ? 48 : size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outlineVariant),
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Icon(Icons.add_photo_alternate_outlined, color: context.colors.primary),
      ),
    ),
  );
}

/// Paperclip + count (collapsed rows, T4.4.02).
class AttachmentCountBadge extends StatelessWidget {
  const AttachmentCountBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Semantics(
      label: context.l10n.attachmentsCount(count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.attach_file, size: 14, color: context.colors.onSurfaceVariant),
            Text('$count', style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
