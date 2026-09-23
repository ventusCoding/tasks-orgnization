import 'package:meta/meta.dart';

/// Why a file was refused (T2.2.08). Mapped to localized messages in the presentation layer.
enum AttachmentRejection { tooLarge, typeNotAllowed, tooMany, empty, duplicate, unreadable }

/// Configurable limits (arch §6.7 item 6), mirrored by the Storage bucket
/// (`file_size_limit`, `allowed_mime_types`).
@immutable
class AttachmentLimits {
  const AttachmentLimits({
    this.maxBytes = 25 * 1024 * 1024,
    this.maxPerOwner = 50,
    this.allowVideo = false,
    this.allowAudio = false,
  });

  final int maxBytes;
  final int maxPerOwner;
  final bool allowVideo;
  final bool allowAudio;

  /// Resumable (TUS) uploads are used above this size (arch §6.7 item 3).
  static const resumableThreshold = 6 * 1024 * 1024;

  /// TUS chunk size required by Supabase Storage.
  static const tusChunkSize = 6 * 1024 * 1024;

  static const defaults = AttachmentLimits();

  static const _imageTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/heic',
    'image/heif',
    'image/bmp',
  };

  static const _documentTypes = {
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.spreadsheet',
    'application/vnd.oasis.opendocument.presentation',
    'application/rtf',
    'application/json',
    'application/zip',
    'application/x-7z-compressed',
    'application/vnd.rar',
    'application/x-rar-compressed',
    'application/gzip',
    'application/x-tar',
  };

  /// MIME allow-list for this configuration.
  bool isAllowedMime(String mime) {
    final m = mime.toLowerCase();
    if (_imageTypes.contains(m)) return true;
    if (_documentTypes.contains(m)) return true;
    if (m.startsWith('text/')) return true;
    if (allowVideo && m.startsWith('video/')) return true;
    if (allowAudio && m.startsWith('audio/')) return true;
    return false;
  }

  /// Validates one candidate file. [existingCount] is the number of live attachments of the owner
  /// plus files already accepted in the same batch.
  AttachmentRejection? validate({required int byteSize, required String mimeType, required int existingCount}) {
    if (existingCount >= maxPerOwner) return AttachmentRejection.tooMany;
    if (byteSize <= 0) return AttachmentRejection.empty;
    if (byteSize > maxBytes) return AttachmentRejection.tooLarge;
    if (!isAllowedMime(mimeType)) return AttachmentRejection.typeNotAllowed;
    return null;
  }
}

/// Safe, portable file names (T2.2.03): no path separators or control characters, NFC-ish
/// (combining marks kept), bounded length, extension preserved.
abstract final class SafeFileName {
  static const maxLength = 120;

  static String of(String input, {String fallback = 'file'}) {
    var name = input.split(RegExp(r'[\\/]')).last.trim();
    name = name.replaceAll(RegExp(r'[\x00-\x1F\x7F<>:"|?*]'), '_');
    name = name.replaceAll(RegExp(r'\s+'), ' ');
    while (name.startsWith('.')) {
      name = name.substring(1);
    }
    if (name.isEmpty || name == '_') name = fallback;
    if (name.length > maxLength) {
      final dot = name.lastIndexOf('.');
      final ext = dot > 0 && name.length - dot <= 10 ? name.substring(dot) : '';
      name = name.substring(0, maxLength - ext.length) + ext;
    }
    return name;
  }

  /// Replaces the extension (e.g. HEIC → JPEG after conversion).
  static String withExtension(String name, String extension) {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    return '$base.$extension';
  }

  /// Storage object keys must be ASCII-safe: non-ASCII characters are replaced (the display
  /// name keeps the original).
  static String storageKey(String name) {
    final ascii = name.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');
    return ascii.replaceAll(RegExp('_+'), '_');
  }
}
