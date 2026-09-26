import 'package:meta/meta.dart';

/// Owner kinds an attachment can belong to (mirrors the `attachments.owner_type` CHECK, arch §7.3).
abstract final class AttachmentOwnerType {
  static const checklist = 'checklist';
  static const checklistItem = 'checklist_item';
  static const task = 'task';
  static const taskOccurrence = 'task_occurrence';
  static const habit = 'habit';
  static const habitLog = 'habit_log';
  static const goal = 'goal';

  static const all = {checklist, checklistItem, task, taskOccurrence, habit, habitLog, goal};

  static bool isValid(String value) => all.contains(value);
}

/// Coarse type of an attachment, derived from its MIME type (drives icons and viewers).
enum AttachmentKind {
  image,
  pdf,
  video,
  audio,
  text,
  document,
  spreadsheet,
  presentation,
  archive,
  other;

  static AttachmentKind fromMime(String mime) {
    final m = mime.toLowerCase();
    if (m.startsWith('image/')) return AttachmentKind.image;
    if (m == 'application/pdf') return AttachmentKind.pdf;
    if (m.startsWith('video/')) return AttachmentKind.video;
    if (m.startsWith('audio/')) return AttachmentKind.audio;
    if (m.startsWith('text/') || m == 'application/json' || m == 'application/rtf') {
      return AttachmentKind.text;
    }
    if (m.contains('wordprocessingml') || m == 'application/msword' || m.contains('opendocument.text')) {
      return AttachmentKind.document;
    }
    if (m.contains('spreadsheetml') || m == 'application/vnd.ms-excel' || m.contains('opendocument.spreadsheet')) {
      return AttachmentKind.spreadsheet;
    }
    if (m.contains('presentationml') ||
        m == 'application/vnd.ms-powerpoint' ||
        m.contains('opendocument.presentation')) {
      return AttachmentKind.presentation;
    }
    if (m == 'application/zip' ||
        m == 'application/x-7z-compressed' ||
        m == 'application/x-rar-compressed' ||
        m == 'application/vnd.rar' ||
        m == 'application/gzip' ||
        m == 'application/x-tar') {
      return AttachmentKind.archive;
    }
    return AttachmentKind.other;
  }
}

/// One file attached to an owner (checklist item, task, habit log…) — `app.attachments` (T2.2.01).
@immutable
class Attachment {
  const Attachment({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.byteSize,
    required this.sortKey,
    this.bucket = 'attachments',
    this.thumbPath,
    this.width,
    this.height,
    this.durationMs,
    this.sha256,
    this.caption,
    this.uploadedAt,
    this.createdAt,
  });

  final String id;
  final String ownerType;
  final String ownerId;
  final String bucket;

  /// Storage object path `{user_id}/{attachment_id}/{safe_name}`.
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
  final String sortKey;

  /// Set once the binary (and thumbnail) reached Storage.
  final DateTime? uploadedAt;
  final DateTime? createdAt;

  AttachmentKind get kind => AttachmentKind.fromMime(mimeType);
  bool get isImage => kind == AttachmentKind.image;
  bool get isUploaded => uploadedAt != null;

  Attachment copyWith({
    String? ownerType,
    String? ownerId,
    String? storagePath,
    String? thumbPath,
    String? caption,
    String? sortKey,
    DateTime? uploadedAt,
  }) => Attachment(
    id: id,
    ownerType: ownerType ?? this.ownerType,
    ownerId: ownerId ?? this.ownerId,
    bucket: bucket,
    storagePath: storagePath ?? this.storagePath,
    thumbPath: thumbPath ?? this.thumbPath,
    fileName: fileName,
    mimeType: mimeType,
    byteSize: byteSize,
    width: width,
    height: height,
    durationMs: durationMs,
    sha256: sha256,
    caption: caption ?? this.caption,
    sortKey: sortKey ?? this.sortKey,
    uploadedAt: uploadedAt ?? this.uploadedAt,
    createdAt: createdAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'ownerType': ownerType,
    'ownerId': ownerId,
    'bucket': bucket,
    'storagePath': storagePath,
    'thumbPath': thumbPath,
    'fileName': fileName,
    'mimeType': mimeType,
    'byteSize': byteSize,
    'width': width,
    'height': height,
    'durationMs': durationMs,
    'sha256': sha256,
    'caption': caption,
    'sortKey': sortKey,
    'uploadedAt': uploadedAt?.toIso8601String(),
  };

  factory Attachment.fromJson(Map<String, Object?> json) => Attachment(
    id: json['id']! as String,
    ownerType: json['ownerType']! as String,
    ownerId: json['ownerId']! as String,
    bucket: json['bucket'] as String? ?? 'attachments',
    storagePath: json['storagePath']! as String,
    thumbPath: json['thumbPath'] as String?,
    fileName: json['fileName']! as String,
    mimeType: json['mimeType']! as String,
    byteSize: (json['byteSize']! as num).toInt(),
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
    durationMs: (json['durationMs'] as num?)?.toInt(),
    sha256: json['sha256'] as String?,
    caption: json['caption'] as String?,
    sortKey: json['sortKey']! as String,
    uploadedAt: json['uploadedAt'] == null ? null : DateTime.parse(json['uploadedAt']! as String),
  );

  @override
  bool operator ==(Object other) =>
      other is Attachment &&
      other.id == id &&
      other.ownerType == ownerType &&
      other.ownerId == ownerId &&
      other.bucket == bucket &&
      other.storagePath == storagePath &&
      other.thumbPath == thumbPath &&
      other.fileName == fileName &&
      other.mimeType == mimeType &&
      other.byteSize == byteSize &&
      other.width == width &&
      other.height == height &&
      other.durationMs == durationMs &&
      other.sha256 == sha256 &&
      other.caption == caption &&
      other.sortKey == sortKey &&
      other.uploadedAt == uploadedAt;

  @override
  int get hashCode => Object.hash(
    id,
    ownerType,
    ownerId,
    storagePath,
    thumbPath,
    fileName,
    mimeType,
    byteSize,
    width,
    height,
    sha256,
    caption,
    sortKey,
    uploadedAt,
  );

  @override
  String toString() => 'Attachment($id, $fileName, $mimeType, $byteSize B)';
}

/// Storage paths for an attachment (arch §6.7): `{user_id}/{attachment_id}/{file}`.
abstract final class AttachmentPaths {
  static const thumbFileName = 'thumb.jpg';

  static String original(String userId, String attachmentId, String safeName) => '$userId/$attachmentId/$safeName';

  static String thumb(String userId, String attachmentId) => '$userId/$attachmentId/$thumbFileName';

  /// Re-roots a provisional path to [userId] (local-only data claimed by a cloud account).
  static String reroot(String path, String userId) {
    final slash = path.indexOf('/');
    if (slash < 0) return '$userId/$path';
    return '$userId${path.substring(slash)}';
  }
}
