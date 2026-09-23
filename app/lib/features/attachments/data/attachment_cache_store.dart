import 'dart:io';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/features/attachments/domain/transfer.dart';
import 'package:path/path.dart' as p;

/// Local-only `attachment_cache` rows (T2.2.01/T2.2.05): where this device keeps the files of an
/// attachment and the state of its upload/download. Never synced.
class AttachmentCacheStore {
  AttachmentCacheStore(this._db);

  final AppDatabase _db;

  Future<AttachmentCacheRow?> get(String id) =>
      (_db.select(_db.attachmentCache)..where((c) => c.attachmentId.equals(id))).getSingleOrNull();

  Stream<AttachmentCacheRow?> watch(String id) =>
      (_db.select(_db.attachmentCache)..where((c) => c.attachmentId.equals(id))).watchSingleOrNull();

  Stream<Map<String, AttachmentCacheRow>> watchMany(List<String> ids) {
    if (ids.isEmpty) return Stream.value(const {});
    return (_db.select(
      _db.attachmentCache,
    )..where((c) => c.attachmentId.isIn(ids))).watch().map((rows) => {for (final r in rows) r.attachmentId: r});
  }

  Future<List<AttachmentCacheRow>> all() => _db.select(_db.attachmentCache).get();

  /// Records the files of a locally created attachment (upload pending).
  Future<void> putLocal(
    String id, {
    required String? originalRel,
    required String? thumbRel,
    required int bytes,
    required UploadState uploadState,
    DateTime? accessedAt,
  }) => _db
      .into(_db.attachmentCache)
      .insertOnConflictUpdate(
        AttachmentCacheCompanion.insert(
          attachmentId: id,
          localOriginalPath: Value(originalRel),
          localThumbPath: Value(thumbRel),
          bytes: Value(bytes),
          lastAccessAt: Value(accessedAt),
          downloadState: Value(originalRel != null ? 'done' : 'none'),
          uploadState: Value(uploadState.name),
        ),
      );

  Future<void> _patch(String id, AttachmentCacheCompanion changes) async {
    final updated = await (_db.update(_db.attachmentCache)..where((c) => c.attachmentId.equals(id))).write(changes);
    if (updated == 0) {
      await _db.into(_db.attachmentCache).insert(changes.copyWith(attachmentId: Value(id)));
    }
  }

  Future<void> setUploadState(
    String id,
    UploadState state, {
    int? attempts,
    String? error,
    bool clearError = false,
    String? tusUrl,
    bool clearTusUrl = false,
  }) => _patch(
    id,
    AttachmentCacheCompanion(
      uploadState: Value(state.name),
      uploadAttempts: attempts == null ? const Value.absent() : Value(attempts),
      uploadError: clearError ? const Value(null) : (error == null ? const Value.absent() : Value(error)),
      tusUploadUrl: clearTusUrl ? const Value(null) : (tusUrl == null ? const Value.absent() : Value(tusUrl)),
    ),
  );

  Future<void> setDownloadState(String id, DownloadState state) =>
      _patch(id, AttachmentCacheCompanion(downloadState: Value(state.name)));

  Future<void> setLocalOriginal(String id, String rel, int bytes) => _patch(
    id,
    AttachmentCacheCompanion(localOriginalPath: Value(rel), bytes: Value(bytes), downloadState: const Value('done')),
  );

  Future<void> setLocalThumb(String id, String rel) => _patch(id, AttachmentCacheCompanion(localThumbPath: Value(rel)));

  Future<void> clearOriginal(String id) => _patch(
    id,
    const AttachmentCacheCompanion(localOriginalPath: Value(null), bytes: Value(0), downloadState: Value('none')),
  );

  Future<void> touch(String id, DateTime at) => _patch(id, AttachmentCacheCompanion(lastAccessAt: Value(at)));

  Future<List<AttachmentCacheRow>> uploadQueue() =>
      (_db.select(_db.attachmentCache)
            ..where((c) => c.uploadState.isIn(const ['pending', 'uploading', 'failed']))
            ..orderBy([(c) => OrderingTerm.asc(c.attachmentId)]))
          .get();

  /// Number of attachments not uploaded yet (global indicator, T2.2.09).
  Stream<int> watchPendingUploadCount() {
    final count = _db.attachmentCache.attachmentId.count();
    return (_db.selectOnly(_db.attachmentCache)
          ..addColumns([count])
          ..where(_db.attachmentCache.uploadState.isIn(const ['pending', 'uploading', 'failed'])))
        .watchSingle()
        .map((r) => r.read(count) ?? 0);
  }

  Stream<int> watchCacheBytes() {
    final sum = _db.attachmentCache.bytes.sum();
    return (_db.selectOnly(_db.attachmentCache)..addColumns([sum])).watchSingle().map((r) => r.read(sum) ?? 0);
  }

  Future<void> remove(String id) => (_db.delete(_db.attachmentCache)..where((c) => c.attachmentId.equals(id))).go();
}

/// Files of attachments on this device, under `<app documents>/attachments/<id>/…` (arch §6.7).
///
/// Paths are stored **relative** to the root: iOS changes the container path between updates.
class AttachmentFileStore {
  AttachmentFileStore(this._root);

  final Future<Directory> Function() _root;
  Directory? _resolved;

  Future<Directory> root() async => _resolved ??= await _root();

  Future<String> absolute(String relative) async => p.join((await root()).path, relative);

  static String relOriginal(String attachmentId, String safeName) => p.join(attachmentId, safeName);
  static String relThumb(String attachmentId) => p.join(attachmentId, 'thumb.jpg');

  Future<File> file(String relative) async => File(await absolute(relative));

  Future<bool> exists(String? relative) async => relative != null && File(await absolute(relative)).existsSync();

  /// Writes [bytes] atomically (temp file + rename).
  Future<File> writeBytes(String relative, Uint8List bytes) async {
    final target = await file(relative);
    await target.parent.create(recursive: true);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    return tmp.rename(target.path);
  }

  /// Copies [source] into the store atomically.
  Future<File> copyFrom(String relative, File source) async {
    final target = await file(relative);
    await target.parent.create(recursive: true);
    final tmp = File('${target.path}.tmp');
    await source.copy(tmp.path);
    return tmp.rename(target.path);
  }

  Future<void> deleteFile(String? relative) async {
    if (relative == null) return;
    final f = await file(relative);
    if (f.existsSync()) await f.delete();
  }

  Future<void> deleteAll(String attachmentId) async {
    final dir = Directory(p.join((await root()).path, attachmentId));
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  Future<int> sizeOf(String? relative) async {
    if (relative == null) return 0;
    final f = await file(relative);
    return f.existsSync() ? f.lengthSync() : 0;
  }
}
