import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Persistent upload state stored in `attachment_cache.upload_state` (T2.2.04).
enum UploadState {
  pending,
  uploading,
  done,
  failed;

  static UploadState parse(String? value) => switch (value) {
    'pending' => UploadState.pending,
    'uploading' => UploadState.uploading,
    'failed' => UploadState.failed,
    _ => UploadState.done,
  };
}

/// Persistent download state stored in `attachment_cache.download_state` (T2.2.05).
enum DownloadState {
  none,
  downloading,
  done,
  failed;

  static DownloadState parse(String? value) => switch (value) {
    'downloading' => DownloadState.downloading,
    'done' => DownloadState.done,
    'failed' => DownloadState.failed,
    _ => DownloadState.none,
  };
}

/// Events driving the upload state machine.
enum UploadEvent { enqueue, start, progress, succeed, fail, retry, cancel }

/// Pure upload state machine (T2.2.04). Invalid transitions keep the current state.
abstract final class UploadStateMachine {
  /// Attempts after which automatic retries stop (the user can still tap *Retry*).
  static const maxAutomaticAttempts = 8;

  static UploadState next(UploadState current, UploadEvent event) => switch ((current, event)) {
    (_, UploadEvent.enqueue) when current != UploadState.done => UploadState.pending,
    (UploadState.pending, UploadEvent.start) => UploadState.uploading,
    (UploadState.failed, UploadEvent.start) => UploadState.uploading,
    (UploadState.uploading, UploadEvent.progress) => UploadState.uploading,
    (UploadState.uploading, UploadEvent.succeed) => UploadState.done,
    (UploadState.uploading, UploadEvent.fail) => UploadState.failed,
    (UploadState.failed, UploadEvent.retry) => UploadState.pending,
    (UploadState.uploading, UploadEvent.cancel) => UploadState.pending,
    _ => current,
  };

  /// Whether a failed upload with [attempts] may be retried automatically.
  static bool canAutoRetry(int attempts) => attempts < maxAutomaticAttempts;
}

/// Exponential backoff with jitter (T2.2.04): `base · 2^(attempt-1)`, capped, then scaled by a
/// random factor in [0.5, 1.0] so many devices don't retry in lockstep.
abstract final class Backoff {
  static Duration delay(
    int attempt, {
    Duration base = const Duration(seconds: 2),
    Duration max = const Duration(minutes: 10),
    math.Random? random,
  }) {
    final n = attempt < 1 ? 1 : attempt;
    final exp = base.inMilliseconds * math.pow(2, math.min(n - 1, 20));
    final capped = math.min(exp.toDouble(), max.inMilliseconds.toDouble());
    final jitter = 0.5 + (random ?? math.Random()).nextDouble() * 0.5;
    return Duration(milliseconds: (capped * jitter).round());
  }
}

/// What the UI shows for one attachment (T2.2.09).
enum TransferStatus {
  /// Local file present, uploaded (or local-only mode): nothing to show.
  ready,
  processing,
  waitingForNetwork,
  uploading,
  failed,
  notDownloaded,
  downloading,
}

/// Combined local transfer info for one attachment.
@immutable
class AttachmentTransfer {
  const AttachmentTransfer({
    required this.status,
    this.progress,
    this.error,
    this.hasLocalOriginal = false,
    this.hasLocalThumb = false,
  });

  static const ready = AttachmentTransfer(status: TransferStatus.ready);

  final TransferStatus status;

  /// 0..1 for uploading/downloading.
  final double? progress;
  final String? error;
  final bool hasLocalOriginal;
  final bool hasLocalThumb;

  /// Derives the visible status from persisted states and connectivity.
  static TransferStatus derive({
    required UploadState upload,
    required DownloadState download,
    required bool isUploadedRemotely,
    required bool hasLocalOriginal,
    required bool hasLocalThumb,
    required bool online,
    required bool storageConfigured,
    bool processing = false,
  }) {
    if (processing) return TransferStatus.processing;
    switch (upload) {
      case UploadState.uploading:
        return TransferStatus.uploading;
      case UploadState.failed:
        return TransferStatus.failed;
      case UploadState.pending:
        // Local-only mode: files simply live on this device; nothing is "waiting".
        if (!storageConfigured) return TransferStatus.ready;
        return online ? TransferStatus.uploading : TransferStatus.waitingForNetwork;
      case UploadState.done:
        break;
    }
    if (download == DownloadState.downloading) return TransferStatus.downloading;
    if (!hasLocalOriginal && !hasLocalThumb && isUploadedRemotely) return TransferStatus.notDownloaded;
    return TransferStatus.ready;
  }

  @override
  bool operator ==(Object other) =>
      other is AttachmentTransfer &&
      other.status == status &&
      other.progress == progress &&
      other.error == error &&
      other.hasLocalOriginal == hasLocalOriginal &&
      other.hasLocalThumb == hasLocalThumb;

  @override
  int get hashCode => Object.hash(status, progress, error, hasLocalOriginal, hasLocalThumb);
}

/// One entry considered by the cache eviction policy.
@immutable
class CacheEntry {
  const CacheEntry({required this.attachmentId, required this.bytes, required this.pinned, this.lastAccessAt});

  final String attachmentId;
  final int bytes;

  /// Not yet uploaded → never evicted (it's the only copy).
  final bool pinned;
  final DateTime? lastAccessAt;
}

/// Least-recently-used eviction (T2.2.05): returns the ids to evict so the total size fits under
/// [capBytes]. Pinned entries are never evicted; never-accessed entries go first.
abstract final class LruPolicy {
  static const defaultCapBytes = 1024 * 1024 * 1024;

  static List<String> evict(List<CacheEntry> entries, int capBytes) {
    var total = entries.fold<int>(0, (a, e) => a + e.bytes);
    if (total <= capBytes) return const [];
    final candidates = entries.where((e) => !e.pinned).toList()
      ..sort((a, b) {
        final ta = a.lastAccessAt;
        final tb = b.lastAccessAt;
        if (ta == null && tb == null) return a.attachmentId.compareTo(b.attachmentId);
        if (ta == null) return -1;
        if (tb == null) return 1;
        final c = ta.compareTo(tb);
        return c != 0 ? c : a.attachmentId.compareTo(b.attachmentId);
      });
    final result = <String>[];
    for (final e in candidates) {
      if (total <= capBytes) break;
      result.add(e.attachmentId);
      total -= e.bytes;
    }
    return result;
  }
}

/// Storage used, deduplicated by storage path (duplicated rows share one object, T2.2.11).
int storageUsedBytes(Iterable<({String storagePath, int byteSize})> rows) {
  final seen = <String>{};
  var total = 0;
  for (final r in rows) {
    if (seen.add(r.storagePath)) total += r.byteSize;
  }
  return total;
}
