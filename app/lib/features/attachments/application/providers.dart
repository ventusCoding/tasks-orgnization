import 'dart:async';
import 'dart:io';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/attachments/application/attachment_picker.dart';
import 'package:everslot/features/attachments/application/attachment_processor.dart';
import 'package:everslot/features/attachments/application/attachment_service.dart';
import 'package:everslot/features/attachments/application/attachment_transfers.dart';
import 'package:everslot/features/attachments/application/media.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/attachments/data/attachment_remote_storage.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/attachments/domain/attachment.dart';
import 'package:everslot/features/attachments/domain/attachment_limits.dart';
import 'package:everslot/features/attachments/domain/transfer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

export 'package:everslot/features/attachments/application/attachment_picker.dart'
    show AttachmentPicker, AttachmentSource, PickedFileRef;
export 'package:everslot/features/attachments/application/attachment_service.dart'
    show AddAttachmentsResult, AttachmentService;
export 'package:everslot/features/attachments/application/attachment_transfers.dart' show AttachmentLocal;
export 'package:everslot/features/attachments/application/media.dart' show VoiceRecorder, waveformOf;
export 'package:everslot/features/attachments/data/attachments_repository.dart' show AttachmentTx;
export 'package:everslot/features/attachments/domain/attachment.dart';

/// Owner key for family providers.
typedef AttachmentOwnerKey = ({String type, String id});

final attachmentFileStoreProvider = Provider<AttachmentFileStore>(
  (ref) => AttachmentFileStore(() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'attachments'));
  }),
);

final attachmentsRepositoryProvider = Provider<AttachmentsRepository>(
  (ref) => AttachmentsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final attachmentCacheStoreProvider = Provider<AttachmentCacheStore>(
  (ref) => AttachmentCacheStore(ref.watch(appDatabaseProvider)),
);

final attachmentPrefsProvider = Provider<AttachmentPrefs>((ref) => AttachmentPrefs(ref.watch(appDatabaseProvider)));

/// Remote storage, or null in local-only mode (Supabase not configured / local session).
final attachmentRemoteStorageProvider = Provider<AttachmentRemoteStorage?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(sessionProvider);
  if (client == null || session == null || session.isLocalOnly) return null;
  return SupabaseAttachmentStorage(client, supabaseUrl: ref.watch(envProvider).supabaseUrl);
});

final attachmentPickerProvider = Provider<AttachmentPicker>(
  (ref) => PlatformAttachmentPicker(clock: ref.watch(clockProvider)),
);

/// Video/audio inspection and poster frames (T2.2.12).
final mediaProbeProvider = Provider<MediaProbe>((ref) => const NativeMediaProbe());

/// Voice-note waveform thumbnails (T2.2.13).
final waveformRendererProvider = Provider<WaveformRenderer>((ref) => const CanvasWaveformRenderer());

/// A new microphone recorder per recording sheet (T2.2.13).
final voiceRecorderFactoryProvider = Provider<VoiceRecorder Function()>((ref) => NativeVoiceRecorder.new);

final imageCodecProvider = Provider<ImageCodec>((ref) => const NativeImageCodec());

final attachmentLimitsProvider = Provider<AttachmentLimits>((ref) => AttachmentLimits.defaults);

final connectivityProbeProvider = Provider<ConnectivityProbe>((ref) => PlatformConnectivityProbe());

final attachmentProcessorProvider = Provider<AttachmentProcessor>(
  (ref) => AttachmentProcessor(
    files: ref.watch(attachmentFileStoreProvider),
    codec: ref.watch(imageCodecProvider),
    media: ref.watch(mediaProbeProvider),
    waveforms: ref.watch(waveformRendererProvider),
  ),
);

final attachmentUploadQueueProvider = Provider<AttachmentUploadQueue>((ref) {
  final prefs = ref.watch(attachmentPrefsProvider);
  final queue = AttachmentUploadQueue(
    repository: ref.watch(attachmentsRepositoryProvider),
    cache: ref.watch(attachmentCacheStoreProvider),
    files: ref.watch(attachmentFileStoreProvider),
    storage: ref.watch(attachmentRemoteStorageProvider),
    clock: ref.watch(clockProvider),
    connectivity: ref.watch(connectivityProbeProvider),
    userId: () => ref.read(currentUserIdProvider),
    wifiOnly: prefs.wifiOnly,
  );
  ref.onDispose(() => unawaited(queue.dispose()));
  return queue;
});

final attachmentDownloaderProvider = Provider<AttachmentDownloader>((ref) {
  final prefs = ref.watch(attachmentPrefsProvider);
  return AttachmentDownloader(
    cache: ref.watch(attachmentCacheStoreProvider),
    files: ref.watch(attachmentFileStoreProvider),
    storage: ref.watch(attachmentRemoteStorageProvider),
    clock: ref.watch(clockProvider),
    capBytes: prefs.cacheCapBytes,
  );
});

final attachmentServiceProvider = Provider<AttachmentService>(
  (ref) => AttachmentService(
    repository: ref.watch(attachmentsRepositoryProvider),
    cache: ref.watch(attachmentCacheStoreProvider),
    files: ref.watch(attachmentFileStoreProvider),
    processor: ref.watch(attachmentProcessorProvider),
    queue: ref.watch(attachmentUploadQueueProvider),
    userId: () => ref.read(currentUserIdProvider),
    newId: Ids.v7,
    limits: ref.watch(attachmentLimitsProvider),
  ),
);

/// Live attachments of one owner, ordered.
final attachmentsForOwnerProvider = StreamProvider.autoDispose.family<List<Attachment>, AttachmentOwnerKey>((
  ref,
  owner,
) {
  ref.watch(currentUserIdProvider);
  return ref.watch(attachmentsRepositoryProvider).watchFor(owner.type, owner.id);
});

/// Local files and transfer states of one attachment.
final attachmentLocalProvider = StreamProvider.autoDispose.family<AttachmentLocal, String>((ref, id) {
  final files = ref.watch(attachmentFileStoreProvider);
  return ref.watch(attachmentCacheStoreProvider).watch(id).asyncMap((row) => AttachmentLocal.resolve(row, files));
});

/// Upload progress per attachment id (running jobs only).
final attachmentUploadProgressProvider = StreamProvider<Map<String, double>>((ref) {
  final queue = ref.watch(attachmentUploadQueueProvider);
  final controller = StreamController<Map<String, double>>();
  void listener() => controller.add(queue.progress.value);
  queue.progress.addListener(listener);
  controller.add(queue.progress.value);
  ref.onDispose(() {
    queue.progress.removeListener(listener);
    unawaited(controller.close());
  });
  return controller.stream;
});

/// Whether the device currently has a network connection (for "waiting for network" badges).
final attachmentOnlineProvider = StreamProvider<bool>((ref) async* {
  final probe = ref.watch(connectivityProbeProvider);
  yield await probe.current() != NetworkKind.offline;
  yield* probe.changes.map((k) => k != NetworkKind.offline);
});

/// Global "N uploads pending" indicator (T2.2.09). 0 in local-only mode (nothing is waiting).
final pendingUploadsCountProvider = StreamProvider<int>((ref) {
  if (ref.watch(attachmentRemoteStorageProvider) == null) return Stream.value(0);
  return ref.watch(attachmentCacheStoreProvider).watchPendingUploadCount();
});

/// Storage used by the account (sum of `byte_size`, deduplicated by path — T2.2.11).
final attachmentStorageUsedProvider = StreamProvider<int>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(attachmentsRepositoryProvider).watchStorageUsedBytes();
});

/// Local cache size on this device (T2.2.11).
final attachmentCacheBytesProvider = StreamProvider<int>(
  (ref) => ref.watch(attachmentCacheStoreProvider).watchCacheBytes(),
);

/// Visible transfer status of one attachment (T2.2.09).
final attachmentTransferProvider = Provider.autoDispose.family<AttachmentTransfer, Attachment>((ref, a) {
  final local = ref.watch(attachmentLocalProvider(a.id)).value ?? const AttachmentLocal();
  final configured = ref.watch(attachmentRemoteStorageProvider) != null;
  // Local-only mode never touches connectivity or the queue.
  final progressMap = configured ? ref.watch(attachmentUploadProgressProvider).value : null;
  final progress = progressMap?[a.id];
  final online = !configured || (ref.watch(attachmentOnlineProvider).value ?? true);
  final status = AttachmentTransfer.derive(
    upload: progress != null ? UploadState.uploading : local.upload,
    download: local.download,
    isUploadedRemotely: a.isUploaded,
    hasLocalOriginal: local.originalPath != null,
    hasLocalThumb: local.thumbPath != null,
    online: online,
    storageConfigured: configured,
  );
  return AttachmentTransfer(
    status: status,
    progress: progress,
    error: local.error,
    hasLocalOriginal: local.originalPath != null,
    hasLocalThumb: local.thumbPath != null,
  );
});

/// Startup hook: resumes interrupted uploads (no-op in local-only mode).
Future<void> startAttachmentUploads(ProviderContainer container) async {
  unawaited(container.read(attachmentUploadQueueProvider).start());
}
