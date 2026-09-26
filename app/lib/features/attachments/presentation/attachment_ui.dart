import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/domain/attachment_limits.dart';
import 'package:everslot/features/attachments/domain/transfer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Human-readable byte size ("1.2 MB"), localized.
String formatBytes(BuildContext context, int bytes) {
  final l = context.l10n;
  final number = NumberFormat.decimalPatternDigits(locale: context.localeName, decimalDigits: 1);
  if (bytes < 1024) return l.attachmentsSizeB('$bytes');
  if (bytes < 1024 * 1024) return l.attachmentsSizeKb(number.format(bytes / 1024));
  if (bytes < 1024 * 1024 * 1024) return l.attachmentsSizeMb(number.format(bytes / (1024 * 1024)));
  return l.attachmentsSizeGb(number.format(bytes / (1024 * 1024 * 1024)));
}

IconData attachmentIcon(AttachmentKind kind) => switch (kind) {
  AttachmentKind.image => Icons.image_outlined,
  AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
  AttachmentKind.video => Icons.movie_outlined,
  AttachmentKind.audio => Icons.audiotrack_outlined,
  AttachmentKind.text => Icons.article_outlined,
  AttachmentKind.document => Icons.description_outlined,
  AttachmentKind.spreadsheet => Icons.table_chart_outlined,
  AttachmentKind.presentation => Icons.slideshow_outlined,
  AttachmentKind.archive => Icons.folder_zip_outlined,
  AttachmentKind.other => Icons.insert_drive_file_outlined,
};

String attachmentKindLabel(BuildContext context, AttachmentKind kind) {
  final l = context.l10n;
  return switch (kind) {
    AttachmentKind.image => l.attachmentsKindPhoto,
    AttachmentKind.pdf => l.attachmentsKindPdf,
    AttachmentKind.video => l.attachmentsKindVideo,
    AttachmentKind.audio => l.attachmentsKindAudio,
    _ => l.attachmentsKindFile,
  };
}

String? transferLabel(BuildContext context, AttachmentTransfer t) {
  final l = context.l10n;
  return switch (t.status) {
    TransferStatus.ready => null,
    TransferStatus.processing => l.attachmentsStatusProcessing,
    TransferStatus.waitingForNetwork => l.attachmentsStatusWaiting,
    TransferStatus.uploading =>
      t.progress == null
          ? l.attachmentsStatusUploadingShort
          : l.attachmentsStatusUploading((t.progress! * 100).round()),
    TransferStatus.failed => l.attachmentsStatusFailed,
    TransferStatus.notDownloaded => l.attachmentsStatusNotDownloaded,
    TransferStatus.downloading => l.attachmentsStatusDownloading,
  };
}

String rejectionMessage(BuildContext context, String name, AttachmentRejection reason, AttachmentLimits limits) {
  final l = context.l10n;
  return switch (reason) {
    AttachmentRejection.tooLarge => l.attachmentsRejectedTooLarge(name, formatBytes(context, limits.maxBytes)),
    AttachmentRejection.typeNotAllowed => l.attachmentsRejectedType(name),
    AttachmentRejection.tooMany => l.attachmentsRejectedTooMany(limits.maxPerOwner),
    AttachmentRejection.empty => l.attachmentsRejectedEmpty(name),
    AttachmentRejection.duplicate => l.attachmentsRejectedDuplicate(name),
    AttachmentRejection.unreadable => l.attachmentsRejectedUnreadable(name),
  };
}

/// Source menu (camera / photos / files). Returns null on cancel.
Future<AttachmentSource?> pickAttachmentSource(BuildContext context) => showAppSheet<AttachmentSource>(
  context,
  title: context.l10n.attachmentsAdd,
  builder: (ctx) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: const Icon(Icons.photo_camera_outlined),
        title: Text(ctx.l10n.attachmentsSourceCamera),
        onTap: () => Navigator.pop(ctx, AttachmentSource.camera),
      ),
      ListTile(
        leading: const Icon(Icons.photo_library_outlined),
        title: Text(ctx.l10n.attachmentsSourcePhotos),
        onTap: () => Navigator.pop(ctx, AttachmentSource.photos),
      ),
      ListTile(
        leading: const Icon(Icons.attach_file),
        title: Text(ctx.l10n.attachmentsSourceFiles),
        onTap: () => Navigator.pop(ctx, AttachmentSource.files),
      ),
      const SizedBox(height: Space.md),
    ],
  ),
);

/// Full "add attachments" flow for any owner (T2.2.02 + T2.2.08 feedback): source menu, camera
/// primer, pick, process, insert, then a snackbar summarizing added/rejected files.
///
/// Returns the op record so callers can push it on their own undo stack.
Future<AddAttachmentsResult?> pickAndAddAttachments(
  BuildContext context,
  WidgetRef ref, {
  required String ownerType,
  required String ownerId,
  AttachmentSource? source,
}) async {
  final chosen = source ?? await pickAttachmentSource(context);
  if (chosen == null || !context.mounted) return null;
  if (chosen == AttachmentSource.camera) {
    final prefs = ref.read(attachmentPrefsProvider);
    if (!await prefs.cameraPrimerShown()) {
      if (!context.mounted) return null;
      final ok = await confirmDialog(
        context,
        title: context.l10n.attachmentsCameraPrimerTitle,
        body: context.l10n.attachmentsCameraPrimerBody,
        confirmLabel: context.l10n.actionContinue,
      );
      if (!ok) return null;
      await prefs.markCameraPrimerShown();
    }
  }
  final List<PickedFileRef> picked;
  try {
    picked = await ref.read(attachmentPickerProvider).pick(chosen);
  } on PermissionException {
    if (context.mounted) await showPermissionHelp(context);
    return null;
  }
  if (picked.isEmpty || !context.mounted) return null;
  final service = ref.read(attachmentServiceProvider);
  final result = await service.addFiles(ownerType, ownerId, picked);
  if (!context.mounted) return result;
  final l = context.l10n;
  final messages = <String>[
    if (result.added.isNotEmpty) l.attachmentsAdded(result.added.length),
    for (final e in result.rejected.entries) rejectionMessage(context, e.key, e.value, service.limits),
  ];
  if (messages.isNotEmpty) showInfoSnackBar(context, messages.join('\n'));
  return result;
}

/// Denied/restricted permission help with a way to the system settings (T2.2.02).
Future<void> showPermissionHelp(BuildContext context) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(ctx.l10n.attachmentsPermissionTitle),
    content: Text(ctx.l10n.attachmentsPermissionBody),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.actionClose)),
      FilledButton(
        onPressed: () async {
          Navigator.pop(ctx);
          await launchUrl(Uri.parse('app-settings:'));
        },
        child: Text(ctx.l10n.attachmentsOpenSettings),
      ),
    ],
  ),
);

/// "N uploads pending" line for Settings › Sync and checklist headers (T2.2.09 / T4.4.03).
class PendingUploadsIndicator extends ConsumerWidget {
  const PendingUploadsIndicator({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingUploadsCountProvider).value ?? 0;
    if (count == 0) return const SizedBox.shrink();
    final text = context.l10n.attachmentsPendingUploads(count);
    if (dense) {
      return StatusPill(label: text, color: context.appColors.info, icon: Icons.cloud_upload_outlined, dense: true);
    }
    return ListTile(leading: const Icon(Icons.cloud_upload_outlined), title: Text(text));
  }
}

/// Settings section for attachments (Wi-Fi only, storage used, cache) — embeddable by Settings.
class AttachmentSettingsSection extends ConsumerWidget {
  const AttachmentSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.watch(attachmentPrefsProvider);
    final used = ref.watch(attachmentStorageUsedProvider).value ?? 0;
    final cache = ref.watch(attachmentCacheBytesProvider).value ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.attachmentsSettingsTitle),
        StreamBuilder<bool>(
          stream: prefs.watchWifiOnly(),
          builder: (context, snap) => SwitchListTile(
            value: snap.data ?? false,
            title: Text(l.attachmentsWifiOnly),
            onChanged: (v) => prefs.setWifiOnly(value: v),
          ),
        ),
        const PendingUploadsIndicator(),
        ListTile(
          leading: const Icon(Icons.cloud_outlined),
          title: Text(l.attachmentsStorageUsed(formatBytes(context, used))),
        ),
        ListTile(
          leading: const Icon(Icons.sd_storage_outlined),
          title: Text(l.attachmentsCacheSize(formatBytes(context, cache))),
          trailing: TextButton(
            onPressed: () async {
              await ref.read(attachmentDownloaderProvider).clearCache();
              if (context.mounted) showInfoSnackBar(context, l.attachmentsCacheCleared);
            },
            child: Text(l.attachmentsClearCache),
          ),
        ),
      ],
    );
  }
}
