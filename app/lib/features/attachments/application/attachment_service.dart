import 'dart:io';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/attachments/application/attachment_picker.dart';
import 'package:everslot/features/attachments/application/attachment_processor.dart';
import 'package:everslot/features/attachments/application/attachment_transfers.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/attachments/domain/attachment.dart';
import 'package:everslot/features/attachments/domain/attachment_limits.dart';
import 'package:everslot/features/attachments/domain/transfer.dart';
import 'package:meta/meta.dart';

/// Outcome of adding files to an owner.
@immutable
class AddAttachmentsResult {
  const AddAttachmentsResult({required this.added, required this.rejected, this.record});

  final List<String> added;

  /// File name → reason.
  final Map<String, AttachmentRejection> rejected;
  final OpRecord? record;

  bool get hasRejections => rejected.isNotEmpty;
}

/// The reusable attachment API other features call (T2.2.02–T2.2.09).
class AttachmentService {
  AttachmentService({
    required AttachmentsRepository repository,
    required this._cache,
    required this._files,
    required this._processor,
    required this._queue,
    required this._userId,
    required this._newId,
    this._limits = AttachmentLimits.defaults,
  }) : _repo = repository;

  final AttachmentsRepository _repo;
  final AttachmentCacheStore _cache;
  final AttachmentFileStore _files;
  final AttachmentProcessor _processor;
  final AttachmentUploadQueue _queue;
  final String Function() _userId;
  final String Function() _newId;
  final AttachmentLimits _limits;

  AttachmentLimits get limits => _limits;

  /// Validates, processes, stores locally and inserts [files] for an owner in ONE operation,
  /// then enqueues the uploads. Works fully offline.
  Future<AddAttachmentsResult> addFiles(String ownerType, String ownerId, List<PickedFileRef> files) async {
    var count = await _repo.countFor(ownerType, ownerId);
    final digests = await _repo.digestsFor(ownerType, ownerId);
    final rejected = <String, AttachmentRejection>{};
    final processed = <ProcessedAttachment>[];
    for (final f in files) {
      final file = File(f.path);
      if (!file.existsSync()) {
        rejected[f.name] = AttachmentRejection.unreadable;
        continue;
      }
      final int size;
      final String mime;
      try {
        size = f.size ?? await file.length();
        mime = AttachmentProcessor.sniffMime(f.name, await AttachmentProcessor.readHead(file, 64), hint: f.mimeType);
      } on FileSystemException {
        // Exists but cannot be read (permissions of a shared file, T8.2.07).
        rejected[f.name] = AttachmentRejection.unreadable;
        continue;
      }
      final reason = _limits.validate(byteSize: size, mimeType: mime, existingCount: count);
      if (reason != null) {
        rejected[f.name] = reason;
        continue;
      }
      final id = _newId();
      final ProcessedAttachment result;
      try {
        result = await _processor.process(f, attachmentId: id);
      } on Object {
        await _files.deleteAll(id);
        rejected[f.name] = AttachmentRejection.unreadable;
        continue;
      }
      final tooLong = _limits.validateDuration(mimeType: result.mimeType, durationMs: result.durationMs);
      if (tooLong != null) {
        await _files.deleteAll(id);
        rejected[f.name] = tooLong;
        continue;
      }
      if (!digests.add(result.sha256)) {
        await _files.deleteAll(id);
        rejected[f.name] = AttachmentRejection.duplicate;
        continue;
      }
      processed.add(result);
      count++;
    }
    if (processed.isEmpty) return AddAttachmentsResult(added: const [], rejected: rejected);
    final userId = _userId();
    final record = await _repo.insertAll([
      for (final p in processed)
        NewAttachment(
          id: p.attachmentId,
          ownerType: ownerType,
          ownerId: ownerId,
          storagePath: AttachmentPaths.original(userId, p.attachmentId, p.storageName),
          thumbPath: p.relThumb == null ? null : AttachmentPaths.thumb(userId, p.attachmentId),
          fileName: p.fileName,
          mimeType: p.mimeType,
          byteSize: p.byteSize,
          width: p.width,
          height: p.height,
          durationMs: p.durationMs,
          sha256: p.sha256,
        ),
    ]);
    for (final p in processed) {
      await _cache.putLocal(
        p.attachmentId,
        originalRel: p.relOriginal,
        thumbRel: p.relThumb,
        bytes: p.byteSize,
        uploadState: UploadState.pending,
      );
    }
    _queue.kick();
    return AddAttachmentsResult(added: [for (final p in processed) p.attachmentId], rejected: rejected, record: record);
  }

  Future<OpRecord> remove(String attachmentId) => _repo.remove(attachmentId);

  Future<OpRecord> setCaption(String attachmentId, String? caption) => _repo.setCaption(attachmentId, caption);

  Future<OpRecord> move(String attachmentId, {String? afterKey, String? beforeKey}) =>
      _repo.move(attachmentId, afterKey: afterKey, beforeKey: beforeKey);

  Future<void> retryUpload(String attachmentId) => _queue.retry(attachmentId);
}

/// Device-local attachment preferences (Wi-Fi only uploads, cache cap, permission primer) in `local_kv`.
class AttachmentPrefs {
  AttachmentPrefs(this._db);

  final AppDatabase _db;

  static const wifiOnlyKey = 'attachments.wifiOnly';
  static const cacheCapKey = 'attachments.cacheCapBytes';
  static const cameraPrimerKey = 'attachments.cameraPrimerShown';
  static const micPrimerKey = 'attachments.micPrimerShown';

  Future<String?> _get(String key) async =>
      (await (_db.select(_db.localKv)..where((k) => k.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _set(String key, String value) =>
      _db.into(_db.localKv).insertOnConflictUpdate(LocalKvCompanion.insert(key: key, value: value));

  Future<bool> wifiOnly() async => await _get(wifiOnlyKey) == 'true';
  Future<void> setWifiOnly({required bool value}) => _set(wifiOnlyKey, '$value');

  Future<int> cacheCapBytes() async => int.tryParse(await _get(cacheCapKey) ?? '') ?? LruPolicy.defaultCapBytes;
  Future<void> setCacheCapBytes(int bytes) => _set(cacheCapKey, '$bytes');

  Future<bool> cameraPrimerShown() async => await _get(cameraPrimerKey) == 'true';
  Future<void> markCameraPrimerShown() => _set(cameraPrimerKey, 'true');

  Future<bool> micPrimerShown() async => await _get(micPrimerKey) == 'true';
  Future<void> markMicPrimerShown() => _set(micPrimerKey, 'true');

  Stream<bool> watchWifiOnly() => (_db.select(
    _db.localKv,
  )..where((k) => k.key.equals(wifiOnlyKey))).watchSingleOrNull().map((r) => r?.value == 'true');
}

/// Helper for owners that just need to know whether they have attachments (filters, badges).
extension AttachmentOwnerQueries on AppDatabase {
  /// Owner ids (of [ownerType]) that have at least one live attachment, among [ownerIds].
  Stream<Set<String>> watchOwnersWithAttachments(String ownerType, String userId) => customSelect(
    'SELECT DISTINCT owner_id FROM attachments WHERE owner_type = ? AND user_id = ? AND deleted_at IS NULL',
    variables: [Variable<String>(ownerType), Variable<String>(userId)],
    readsFrom: {attachments},
  ).watch().map((rows) => {for (final r in rows) r.read<String>('owner_id')});
}
