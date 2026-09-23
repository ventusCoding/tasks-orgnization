import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/attachments/data/attachment_remote_storage.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/attachments/domain/attachment.dart';
import 'package:everslot/features/attachments/domain/transfer.dart';
import 'package:flutter/foundation.dart';

/// Network kinds relevant to uploads.
enum NetworkKind { offline, wifi, cellular, other }

/// Connectivity source (fake in tests).
abstract class ConnectivityProbe {
  Future<NetworkKind> current();
  Stream<NetworkKind> get changes;
}

class PlatformConnectivityProbe implements ConnectivityProbe {
  PlatformConnectivityProbe([Connectivity? connectivity]) : _c = connectivity ?? Connectivity();

  final Connectivity _c;

  static NetworkKind _kind(List<ConnectivityResult> r) {
    if (r.contains(ConnectivityResult.wifi) || r.contains(ConnectivityResult.ethernet)) return NetworkKind.wifi;
    if (r.contains(ConnectivityResult.mobile)) return NetworkKind.cellular;
    if (r.isEmpty || r.every((e) => e == ConnectivityResult.none)) return NetworkKind.offline;
    return NetworkKind.other;
  }

  @override
  Future<NetworkKind> current() async {
    try {
      return _kind(await _c.checkConnectivity());
    } on Object {
      return NetworkKind.other;
    }
  }

  @override
  Stream<NetworkKind> get changes => _c.onConnectivityChanged.map(_kind);
}

/// Persistent, single-flight upload queue (T2.2.04) — separate from row sync.
///
/// Jobs live in `attachment_cache.upload_state` so they survive restarts. With no remote storage
/// (local-only mode, Supabase not configured) jobs simply stay `pending`: files are fully usable
/// from local storage and upload once a cloud account exists.
class AttachmentUploadQueue {
  AttachmentUploadQueue({
    required AttachmentsRepository repository,
    required AttachmentCacheStore cache,
    required AttachmentFileStore files,
    required AttachmentRemoteStorage? storage,
    required Clock clock,
    required ConnectivityProbe connectivity,
    required String Function() userId,
    Future<bool> Function()? wifiOnly,
    this.concurrency = 2,
    math.Random? random,
  }) : _repo = repository,
       _cache = cache,
       _files = files,
       _storage = storage,
       _clock = clock,
       _connectivity = connectivity,
       _userId = userId,
       _wifiOnly = wifiOnly ?? (() async => false),
       _random = random ?? math.Random();

  final AttachmentsRepository _repo;
  final AttachmentCacheStore _cache;
  final AttachmentFileStore _files;
  final AttachmentRemoteStorage? _storage;
  final Clock _clock;
  final ConnectivityProbe _connectivity;
  final String Function() _userId;
  final Future<bool> Function() _wifiOnly;
  final math.Random _random;
  final int concurrency;
  final _log = AppLog.get('attachments.upload');

  /// Upload progress 0..1 per attachment id (only for running jobs).
  final ValueNotifier<Map<String, double>> progress = ValueNotifier(const {});

  final Set<String> _running = {};
  final Map<String, DateTime> _retryAt = {};
  StreamSubscription<NetworkKind>? _sub;
  Timer? _retryTimer;
  bool _pumping = false;
  bool _dirty = false;
  bool _disposed = false;

  bool get isConfigured => _storage != null;

  /// Starts listening to connectivity and resets jobs interrupted by an app kill.
  Future<void> start() async {
    if (_storage == null || _disposed) return;
    for (final row in await _cache.uploadQueue()) {
      if (row.uploadState == UploadState.uploading.name) {
        await _cache.setUploadState(row.attachmentId, UploadState.pending);
      }
    }
    _sub ??= _connectivity.changes.listen((kind) {
      if (kind != NetworkKind.offline) kick();
    });
    kick();
  }

  /// Requests a pass over the queue (debounced by single-flight).
  void kick() {
    if (_storage == null || _disposed) return;
    if (_pumping) {
      _dirty = true;
      return;
    }
    unawaited(_pump());
  }

  /// Manual retry (resets the attempt counter).
  Future<void> retry(String attachmentId) async {
    _retryAt.remove(attachmentId);
    await _cache.setUploadState(attachmentId, UploadState.pending, attempts: 0, clearError: true);
    kick();
  }

  /// Runs the queue until nothing more can be done right now (tests / background task).
  Future<void> drain() async {
    if (_storage == null) return;
    while (_pumping) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await _pump();
  }

  Future<bool> _networkAllowed() async {
    final kind = await _connectivity.current();
    if (kind == NetworkKind.offline) return false;
    if (kind == NetworkKind.cellular && await _wifiOnly()) return false;
    return true;
  }

  Future<void> _pump() async {
    _pumping = true;
    try {
      do {
        _dirty = false;
        if (!await _networkAllowed()) return;
        final now = _clock.nowUtc();
        final jobs = (await _cache.uploadQueue()).where((r) {
          if (_running.contains(r.attachmentId)) return false;
          final state = UploadState.parse(r.uploadState);
          if (state == UploadState.failed) {
            if (!UploadStateMachine.canAutoRetry(r.uploadAttempts)) return false;
            final at = _retryAt[r.attachmentId];
            return at == null || !at.isAfter(now);
          }
          return true;
        }).toList();
        if (jobs.isEmpty) break;
        for (var i = 0; i < jobs.length; i += concurrency) {
          final batch = jobs.sublist(i, math.min(i + concurrency, jobs.length));
          await Future.wait(batch.map(_runJob));
          if (_disposed) return;
        }
      } while (_dirty);
      _scheduleRetryTimer();
    } finally {
      _pumping = false;
    }
  }

  void _scheduleRetryTimer() {
    _retryTimer?.cancel();
    if (_retryAt.isEmpty || _disposed) return;
    final next = _retryAt.values.reduce((a, b) => a.isBefore(b) ? a : b);
    final delay = next.difference(_clock.nowUtc());
    _retryTimer = Timer(delay.isNegative ? Duration.zero : delay, kick);
  }

  void _setProgress(String id, double? value) {
    final map = {...progress.value};
    if (value == null) {
      map.remove(id);
    } else {
      map[id] = value.clamp(0, 1).toDouble();
    }
    progress.value = map;
  }

  Future<void> _runJob(AttachmentCacheRow job) async {
    final id = job.attachmentId;
    final storage = _storage!;
    _running.add(id);
    try {
      final attachment = await _repo.byId(id);
      if (attachment == null) return; // row not synced here / purged: nothing to upload
      if (attachment.isUploaded) {
        await _cache.setUploadState(id, UploadState.done, clearError: true, clearTusUrl: true);
        return;
      }
      if (job.localOriginalPath == null || !await _files.exists(job.localOriginalPath)) {
        await _cache.setUploadState(id, UploadState.failed, attempts: 999, error: 'missing_file');
        return;
      }
      await _cache.setUploadState(id, UploadState.uploading);
      _setProgress(id, 0);
      final userId = _userId();
      final storagePath = AttachmentPaths.reroot(attachment.storagePath, userId);
      final thumbPath = attachment.thumbPath == null ? null : AttachmentPaths.reroot(attachment.thumbPath!, userId);
      if (thumbPath != null && await _files.exists(job.localThumbPath)) {
        await storage.upload(
          bucket: attachment.bucket,
          path: thumbPath,
          file: await _files.file(job.localThumbPath!),
          mimeType: 'image/jpeg',
        );
      }
      await storage.upload(
        bucket: attachment.bucket,
        path: storagePath,
        file: await _files.file(job.localOriginalPath!),
        mimeType: attachment.mimeType,
        resumeUrl: job.tusUploadUrl,
        onResumeUrl: (url) => unawaited(_cache.setUploadState(id, UploadState.uploading, tusUrl: url)),
        onProgress: (sent, total) => _setProgress(id, total == 0 ? 1 : sent / total),
      );
      await _repo.markUploaded(id, storagePath: storagePath, thumbPath: thumbPath, at: _clock.nowUtc());
      await _cache.setUploadState(id, UploadState.done, clearError: true, clearTusUrl: true);
      _retryAt.remove(id);
    } on Object catch (e) {
      final attempts = job.uploadAttempts + 1;
      _log.info('upload of $id failed (attempt $attempts): $e');
      await _cache.setUploadState(id, UploadState.failed, attempts: attempts, error: e.toString());
      _retryAt[id] = _clock.nowUtc().add(Backoff.delay(attempts, random: _random));
    } finally {
      _running.remove(id);
      _setProgress(id, null);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    await _sub?.cancel();
    progress.dispose();
  }
}

/// Lazy downloads + LRU cache (T2.2.05): thumbnails when an owner is visible, originals on open.
class AttachmentDownloader {
  AttachmentDownloader({
    required AttachmentCacheStore cache,
    required AttachmentFileStore files,
    required AttachmentRemoteStorage? storage,
    required Clock clock,
    Future<int> Function()? capBytes,
  }) : _cache = cache,
       _files = files,
       _storage = storage,
       _clock = clock,
       _capBytes = capBytes ?? (() async => LruPolicy.defaultCapBytes);

  final AttachmentCacheStore _cache;
  final AttachmentFileStore _files;
  final AttachmentRemoteStorage? _storage;
  final Clock _clock;
  final Future<int> Function() _capBytes;
  final Map<String, Future<String?>> _inflight = {};

  bool get isConfigured => _storage != null;

  /// Absolute path of a local thumbnail (or original image), downloading it when possible.
  Future<String?> ensureThumb(Attachment a) async {
    final row = await _cache.get(a.id);
    if (await _files.exists(row?.localThumbPath)) return _files.absolute(row!.localThumbPath!);
    if (a.isImage && await _files.exists(row?.localOriginalPath)) return _files.absolute(row!.localOriginalPath!);
    if (a.thumbPath == null || _storage == null || !a.isUploaded) return null;
    return _once('thumb:${a.id}', () async {
      final bytes = await _storage.download(bucket: a.bucket, path: a.thumbPath!);
      final rel = AttachmentFileStore.relThumb(a.id);
      await _files.writeBytes(rel, bytes);
      await _cache.setLocalThumb(a.id, rel);
      return _files.absolute(rel);
    });
  }

  /// Absolute path of the local original, downloading it on demand.
  Future<String?> ensureOriginal(Attachment a) async {
    final row = await _cache.get(a.id);
    if (await _files.exists(row?.localOriginalPath)) {
      await _cache.touch(a.id, _clock.nowUtc());
      return _files.absolute(row!.localOriginalPath!);
    }
    if (_storage == null || !a.isUploaded) return null;
    return _once('orig:${a.id}', () async {
      await _cache.setDownloadState(a.id, DownloadState.downloading);
      try {
        final bytes = await _storage.download(bucket: a.bucket, path: a.storagePath);
        final rel = AttachmentFileStore.relOriginal(a.id, a.storagePath.split('/').last);
        await _files.writeBytes(rel, bytes);
        await _cache.setLocalOriginal(a.id, rel, bytes.length);
        await _cache.touch(a.id, _clock.nowUtc());
        unawaited(enforceCap());
        return await _files.absolute(rel);
      } on Object {
        await _cache.setDownloadState(a.id, DownloadState.failed);
        rethrow;
      }
    });
  }

  Future<String?> _once(String key, Future<String?> Function() body) {
    final existing = _inflight[key];
    if (existing != null) return existing;
    // Block body: returning the removed future would make whenComplete await itself.
    final future = body().whenComplete(() {
      _inflight.remove(key);
    });
    _inflight[key] = future;
    return future;
  }

  /// Evicts least-recently-used originals above the cap; never files that aren't uploaded.
  Future<List<String>> enforceCap() async {
    final rows = await _cache.all();
    final entries = [
      for (final r in rows)
        if (r.localOriginalPath != null)
          CacheEntry(
            attachmentId: r.attachmentId,
            bytes: r.bytes,
            pinned: UploadState.parse(r.uploadState) != UploadState.done,
            lastAccessAt: r.lastAccessAt,
          ),
    ];
    final victims = LruPolicy.evict(entries, await _capBytes());
    for (final id in victims) {
      final row = rows.firstWhere((r) => r.attachmentId == id);
      await _files.deleteFile(row.localOriginalPath);
      await _cache.clearOriginal(id);
    }
    return victims;
  }

  /// "Clear cache" (T2.2.11): drops every uploaded original; thumbnails and pending files stay.
  Future<int> clearCache() async {
    final rows = await _cache.all();
    var freed = 0;
    for (final r in rows) {
      if (r.localOriginalPath == null || UploadState.parse(r.uploadState) != UploadState.done) continue;
      freed += r.bytes;
      await _files.deleteFile(r.localOriginalPath);
      await _cache.clearOriginal(r.attachmentId);
    }
    return freed;
  }
}

/// Resolved local files + states for one attachment (UI).
@immutable
class AttachmentLocal {
  const AttachmentLocal({
    this.originalPath,
    this.thumbPath,
    this.upload = UploadState.done,
    this.download = DownloadState.none,
    this.error,
  });

  final String? originalPath;
  final String? thumbPath;
  final UploadState upload;
  final DownloadState download;
  final String? error;

  /// Best local image to display as a thumbnail.
  String? get displayPath => thumbPath ?? originalPath;

  static Future<AttachmentLocal> resolve(AttachmentCacheRow? row, AttachmentFileStore files) async {
    if (row == null) return const AttachmentLocal();
    Future<String?> abs(String? rel) async => rel == null
        ? null
        : File(await files.absolute(rel)).existsSync()
        ? files.absolute(rel)
        : null;
    return AttachmentLocal(
      originalPath: await abs(row.localOriginalPath),
      thumbPath: await abs(row.localThumbPath),
      upload: UploadState.parse(row.uploadState),
      download: DownloadState.parse(row.downloadState),
      error: row.uploadError,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AttachmentLocal &&
      other.originalPath == originalPath &&
      other.thumbPath == thumbPath &&
      other.upload == upload &&
      other.download == download &&
      other.error == error;

  @override
  int get hashCode => Object.hash(originalPath, thumbPath, upload, download, error);
}
