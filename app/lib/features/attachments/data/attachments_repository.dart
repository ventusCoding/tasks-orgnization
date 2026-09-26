import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/attachments/domain/attachment.dart';

/// Values of a new attachment row (after processing).
class NewAttachment {
  const NewAttachment({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.byteSize,
    this.thumbPath,
    this.width,
    this.height,
    this.durationMs,
    this.sha256,
    this.caption,
  });

  final String id;
  final String ownerType;
  final String ownerId;
  final String storagePath;
  final String? thumbPath;
  final String fileName;
  final String mimeType;
  final int byteSize;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? sha256;
  final String? caption;
}

/// `attachments` rows (T2.2.01): read Drift streams, write through [SyncWriter].
class AttachmentsRepository {
  AttachmentsRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  static Attachment map(AttachmentRow r) => Attachment(
    id: r.id,
    ownerType: r.ownerType,
    ownerId: r.ownerId,
    bucket: r.bucket,
    storagePath: r.storagePath,
    thumbPath: r.thumbPath,
    fileName: r.fileName,
    mimeType: r.mimeType,
    byteSize: r.byteSize,
    width: r.width,
    height: r.height,
    durationMs: r.durationMs,
    sha256: r.sha256,
    caption: r.caption,
    sortKey: r.sortKey,
    uploadedAt: r.uploadedAt,
    createdAt: r.createdAt,
  );

  SimpleSelectStatement<$AttachmentsTable, AttachmentRow> _live() =>
      _db.select(_db.attachments)..where((a) => a.deletedAt.isNull() & a.userId.equals(_userId()));

  /// Live attachments of one owner ordered by `(sort_key, id)`.
  Stream<List<Attachment>> watchFor(String ownerType, String ownerId) =>
      (_live()
            ..where((a) => a.ownerType.equals(ownerType) & a.ownerId.equals(ownerId))
            ..orderBy([(a) => OrderingTerm.asc(a.sortKey), (a) => OrderingTerm.asc(a.id)]))
          .watch()
          .map((rows) => rows.map(map).toList());

  Future<List<Attachment>> listFor(String ownerType, String ownerId) async =>
      (await (_live()
                ..where((a) => a.ownerType.equals(ownerType) & a.ownerId.equals(ownerId))
                ..orderBy([(a) => OrderingTerm.asc(a.sortKey), (a) => OrderingTerm.asc(a.id)]))
              .get())
          .map(map)
          .toList();

  /// Attachments of many owners at once (one query, grouped by owner id).
  Stream<Map<String, List<Attachment>>> watchForOwners(String ownerType, List<String> ownerIds) {
    if (ownerIds.isEmpty) return Stream.value(const {});
    return (_live()
          ..where((a) => a.ownerType.equals(ownerType) & a.ownerId.isIn(ownerIds))
          ..orderBy([(a) => OrderingTerm.asc(a.sortKey), (a) => OrderingTerm.asc(a.id)]))
        .watch()
        .map((rows) {
          final out = <String, List<Attachment>>{};
          for (final r in rows) {
            (out[r.ownerId] ??= []).add(map(r));
          }
          return out;
        });
  }

  Stream<Attachment?> watchById(String id) =>
      (_live()..where((a) => a.id.equals(id))).watchSingleOrNull().map((r) => r == null ? null : map(r));

  Future<Attachment?> byId(String id) async {
    final r = await (_db.select(_db.attachments)..where((a) => a.id.equals(id))).getSingleOrNull();
    return r == null ? null : map(r);
  }

  Future<int> countFor(String ownerType, String ownerId) async {
    final count = _db.attachments.id.count();
    final q = _db.selectOnly(_db.attachments)
      ..addColumns([count])
      ..where(
        _db.attachments.deletedAt.isNull() &
            _db.attachments.userId.equals(_userId()) &
            _db.attachments.ownerType.equals(ownerType) &
            _db.attachments.ownerId.equals(ownerId),
      );
    return (await q.getSingle()).read(count) ?? 0;
  }

  /// SHA-256 digests already attached to an owner (duplicate detection, T2.2.03).
  Future<Set<String>> digestsFor(String ownerType, String ownerId) async =>
      (await listFor(ownerType, ownerId)).map((a) => a.sha256).whereType<String>().toSet();

  /// Inserts processed attachments (appended after existing ones) with `attachment_added` events,
  /// all in one operation.
  Future<OpRecord> insertAll(List<NewAttachment> items) => _writer.run((tx) async {
    final lastKeys = <String, String?>{};
    for (final a in items) {
      final ownerKey = '${a.ownerType}|${a.ownerId}';
      final last = lastKeys.containsKey(ownerKey)
          ? lastKeys[ownerKey]
          : await AttachmentTx.lastSortKey(tx, a.ownerType, a.ownerId);
      final key = FractionalIndex.between(last, null);
      lastKeys[ownerKey] = key;
      await tx.insert('attachments', a.id, {
        'owner_type': a.ownerType,
        'owner_id': a.ownerId,
        'bucket': 'attachments',
        'storage_path': a.storagePath,
        'thumb_path': a.thumbPath,
        'file_name': a.fileName,
        'mime_type': a.mimeType,
        'byte_size': a.byteSize,
        'width': a.width,
        'height': a.height,
        'duration_ms': a.durationMs,
        'sha256': a.sha256,
        'caption': a.caption,
        'sort_key': key,
      });
      await tx.logEvent(
        entityType: a.ownerType,
        entityId: a.ownerId,
        eventType: 'attachment_added',
        payload: {'attachmentId': a.id, 'fileName': a.fileName, 'mimeType': a.mimeType},
      );
    }
  });

  Future<OpRecord> setCaption(String id, String? caption) => _writer.run(
    (tx) => tx.update('attachments', id, {'caption': (caption?.trim().isEmpty ?? true) ? null : caption!.trim()}),
  );

  /// Moves [id] between two neighbours (fractional order, T2.2.07).
  Future<OpRecord> move(String id, {String? afterKey, String? beforeKey}) =>
      _writer.run((tx) => tx.update('attachments', id, {'sort_key': safeBetween(afterKey, beforeKey)}));

  /// Soft-deletes one attachment (T2.2.11) with an `attachment_removed` event.
  Future<OpRecord> remove(String id) => _writer.run((tx) async {
    final row = await tx.readRaw('attachments', id);
    if (row == null) return;
    await tx.softDelete('attachments', id);
    await tx.logEvent(
      entityType: row['owner_type']! as String,
      entityId: row['owner_id']! as String,
      eventType: 'attachment_removed',
      payload: {'attachmentId': id, 'fileName': row['file_name']},
    );
  });

  /// Marks the binary as uploaded (automatic write); re-roots provisional paths to the current
  /// cloud user so they satisfy the Storage path-prefix rule.
  Future<OpRecord> markUploaded(String id, {required String storagePath, String? thumbPath, required DateTime at}) =>
      _writer.run(
        (tx) =>
            tx.update('attachments', id, {'storage_path': storagePath, 'thumb_path': ?thumbPath, 'uploaded_at': at}),
        cause: 'auto',
      );

  /// Total Storage used by the current user, deduplicated by storage path (T2.2.11).
  Stream<int> watchStorageUsedBytes() => _db
      .customSelect(
        'SELECT COALESCE(SUM(byte_size), 0) AS total FROM ('
        'SELECT storage_path, MAX(byte_size) AS byte_size FROM attachments '
        'WHERE deleted_at IS NULL AND user_id = ? GROUP BY storage_path)',
        variables: [Variable<String>(_userId())],
        readsFrom: {_db.attachments},
      )
      .watchSingle()
      .map((r) => r.read<int>('total'));

  /// Key strictly between [a] and [b], tolerant of equal/invalid neighbour keys.
  static String safeBetween(String? a, String? b) {
    try {
      final va = a != null && FractionalIndex.isValid(a) ? a : null;
      final vb = b != null && FractionalIndex.isValid(b) ? b : null;
      if (va != null && vb != null && va.compareTo(vb) >= 0) return FractionalIndex.between(va, null);
      return FractionalIndex.between(va, vb);
    } on Object {
      return FractionalIndex.between(null, null);
    }
  }
}

/// Attachment row operations usable inside another feature's [SyncWriter.run] (arch §6.7,
/// T4.4.04): cascades for deletes, copies by reference for duplicates, re-owning for merges.
abstract final class AttachmentTx {
  /// Maps a Drift row (e.g. from another feature's custom query) to the domain entity.
  static Attachment fromRow(AttachmentRow r) => AttachmentsRepository.map(r);

  static Future<List<Map<String, Object?>>> _rowsFor(
    WriteTx tx,
    String ownerType,
    Iterable<String> ownerIds, {
    bool includeDeleted = false,
  }) async {
    final ids = ownerIds.toList();
    if (ids.isEmpty) return const [];
    final out = <Map<String, Object?>>[];
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      final rows = await tx.db
          .customSelect(
            'SELECT * FROM attachments WHERE owner_type = ? AND owner_id IN '
            '(${List.filled(chunk.length, '?').join(', ')})'
            '${includeDeleted ? '' : ' AND deleted_at IS NULL'} ORDER BY sort_key, id',
            variables: [Variable<String>(ownerType), for (final id in chunk) Variable<String>(id)],
          )
          .get();
      out.addAll(rows.map((r) => r.data));
    }
    return out;
  }

  static Future<String?> lastSortKey(WriteTx tx, String ownerType, String ownerId) async {
    final row = await tx.db
        .customSelect(
          'SELECT MAX(sort_key) AS k FROM attachments WHERE owner_type = ? AND owner_id = ? '
          'AND deleted_at IS NULL',
          variables: [Variable<String>(ownerType), Variable<String>(ownerId)],
        )
        .getSingle();
    return row.data['k'] as String?;
  }

  /// Tombstones every live attachment of the given owners (same operation group).
  static Future<int> softDeleteForOwners(WriteTx tx, String ownerType, Iterable<String> ownerIds) async {
    final rows = await _rowsFor(tx, ownerType, ownerIds);
    for (final r in rows) {
      await tx.softDelete('attachments', r['id']! as String);
    }
    return rows.length;
  }

  /// Copies attachment **rows** of `ownerIdMap.keys` to the mapped new owners; copies keep the
  /// same storage objects (arch §6.7). Returns old attachment id → new id.
  static Future<Map<String, String>> copyForOwners(
    WriteTx tx, {
    required String fromType,
    required Map<String, String> ownerIdMap,
    String? toType,
  }) async {
    final rows = await _rowsFor(tx, fromType, ownerIdMap.keys);
    final result = <String, String>{};
    for (final r in rows) {
      final newId = Ids.v7();
      result[r['id']! as String] = newId;
      await tx.insert('attachments', newId, {
        'owner_type': toType ?? fromType,
        'owner_id': ownerIdMap[r['owner_id']]!,
        'bucket': r['bucket'],
        'storage_path': r['storage_path'],
        'thumb_path': r['thumb_path'],
        'file_name': r['file_name'],
        'mime_type': r['mime_type'],
        'byte_size': r['byte_size'],
        'width': r['width'],
        'height': r['height'],
        'duration_ms': r['duration_ms'],
        'sha256': r['sha256'],
        'caption': r['caption'],
        'sort_key': r['sort_key'],
        'uploaded_at': r['uploaded_at'],
      });
    }
    return result;
  }

  /// Re-owns attachments (merge row into previous, promote item to checklist).
  static Future<int> reown(
    WriteTx tx, {
    required String fromType,
    required String fromId,
    required String toType,
    required String toId,
  }) async {
    final rows = await _rowsFor(tx, fromType, [fromId]);
    var last = await lastSortKey(tx, toType, toId);
    for (final r in rows) {
      final key = AttachmentsRepository.safeBetween(last, null);
      last = key;
      await tx.update('attachments', r['id']! as String, {'owner_type': toType, 'owner_id': toId, 'sort_key': key});
    }
    return rows.length;
  }
}
