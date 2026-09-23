import 'dart:io';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/attachments/presentation/attachment_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

/// Opens the full-screen viewer at [index] (T2.2.06).
Future<void> openAttachmentViewer(
  BuildContext context,
  List<Attachment> attachments,
  int index, {
  VoidCallback? onGoToOwner,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => AttachmentViewerScreen(
      ownerType: attachments.first.ownerType,
      ownerId: attachments.first.ownerId,
      initialIndex: index.clamp(0, attachments.length - 1),
      initial: attachments,
      onGoToOwner: onGoToOwner,
    ),
  ),
);

/// Gallery across an owner's attachments: swipe (RTL-aware), pinch/double-tap zoom, captions,
/// share, delete; PDFs in `pdfrx`; other types → share / open with.
class AttachmentViewerScreen extends ConsumerStatefulWidget {
  const AttachmentViewerScreen({
    required this.ownerType,
    required this.ownerId,
    required this.initialIndex,
    super.key,
    this.initial = const [],
    this.onGoToOwner,
  });

  final String ownerType;
  final String ownerId;
  final int initialIndex;
  final List<Attachment> initial;
  final VoidCallback? onGoToOwner;

  @override
  ConsumerState<AttachmentViewerScreen> createState() => _AttachmentViewerScreenState();
}

class _AttachmentViewerScreenState extends ConsumerState<AttachmentViewerScreen> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(attachmentsForOwnerProvider((type: widget.ownerType, id: widget.ownerId)));
    final items = live.value ?? widget.initial;
    final l = context.l10n;
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(title: l.attachmentsEmpty, icon: Icons.attach_file),
      );
    }
    final index = _index.clamp(0, items.length - 1);
    final current = items[index];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.attachmentsViewerPosition(index + 1, items.length)),
        actions: [
          if (widget.onGoToOwner != null)
            IconButton(
              tooltip: l.attachmentsGoToItem,
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                Navigator.pop(context);
                widget.onGoToOwner!();
              },
            ),
          IconButton(
            tooltip: l.attachmentsEditCaption,
            icon: const Icon(Icons.short_text),
            onPressed: () => runAttachmentAction(context, ref, 'caption', items, index),
          ),
          IconButton(
            tooltip: l.actionShare,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => shareAttachment(ref, current),
          ),
          IconButton(
            tooltip: l.attachmentsRemove,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await runAttachmentAction(context, ref, 'remove', items, index);
              if (items.length <= 1 && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _AttachmentPage(attachment: items[i]),
            ),
          ),
          if (current.caption != null || !current.isImage)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Text(
                  current.caption ?? '${current.fileName} · ${formatBytes(context, current.byteSize)}',
                  style: context.text.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentPage extends ConsumerStatefulWidget {
  const _AttachmentPage({required this.attachment});

  final Attachment attachment;

  @override
  ConsumerState<_AttachmentPage> createState() => _AttachmentPageState();
}

class _AttachmentPageState extends ConsumerState<_AttachmentPage> {
  final _transform = TransformationController();
  Future<String?>? _original;

  @override
  void initState() {
    super.initState();
    _original = ref
        .read(attachmentDownloaderProvider)
        .ensureOriginal(widget.attachment)
        .then<String?>((p) => p, onError: (Object _) => null);
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom(TapDownDetails details) {
    if (_transform.value.getMaxScaleOnAxis() > 1) {
      _transform.value = Matrix4.identity();
    } else {
      final p = details.localPosition;
      _transform.value = Matrix4.identity()
        ..translateByDouble(-p.dx, -p.dy, 0, 1)
        ..scaleByDouble(2.5, 2.5, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    final local = ref.watch(attachmentLocalProvider(a.id)).value ?? const AttachmentLocal();
    return FutureBuilder<String?>(
      future: _original,
      builder: (context, snap) {
        final path = snap.data ?? local.originalPath;
        if (path == null) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingState();
          // Offline and not cached: show the thumbnail when available.
          return _Unavailable(attachment: a, thumbPath: local.thumbPath);
        }
        if (a.isImage) {
          return GestureDetector(
            onDoubleTapDown: _toggleZoom,
            onDoubleTap: () {},
            child: InteractiveViewer(
              transformationController: _transform,
              maxScale: 6,
              child: Center(
                child: HeroMode(
                  enabled: !context.reduceMotion,
                  child: Hero(
                    tag: 'attachment-${a.id}',
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      semanticLabel: a.caption ?? a.fileName,
                      errorBuilder: (_, _, _) => _Unavailable(attachment: a),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        if (a.kind == AttachmentKind.pdf) return PdfViewer.file(path);
        return _Unavailable(attachment: a, available: true);
      },
    );
  }
}

class _Unavailable extends ConsumerWidget {
  const _Unavailable({required this.attachment, this.thumbPath, this.available = false});

  final Attachment attachment;
  final String? thumbPath;
  final bool available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (thumbPath != null)
              Image.file(File(thumbPath!), height: 200, fit: BoxFit.contain)
            else
              Icon(attachmentIcon(attachment.kind), size: 72, color: context.colors.primary),
            const SizedBox(height: Space.lg),
            Text(attachment.fileName, style: context.text.titleMedium, textAlign: TextAlign.center),
            Text(formatBytes(context, attachment.byteSize), style: context.text.bodySmall),
            const SizedBox(height: Space.md),
            Text(
              available ? l.attachmentsNoPreview : l.attachmentsDownloadWhenOnline,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (available) ...[
              const SizedBox(height: Space.md),
              FilledButton.tonalIcon(
                onPressed: () => shareAttachment(ref, attachment),
                icon: const Icon(Icons.open_in_new),
                label: Text(l.attachmentsOpenWith),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
