import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:everslot/features/attachments/application/attachment_picker.dart';
import 'package:everslot/features/attachments/application/media.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/attachments/domain/attachment_limits.dart';
import 'package:everslot/features/attachments/domain/image_header.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';

/// Output encoding for re-encoded images.
enum ImageOutputFormat { jpeg, png, webp }

/// Native image re-encoder (behind an interface so tests can fake it).
///
/// Implementations must apply the EXIF orientation and drop all metadata (GPS included).
abstract class ImageCodec {
  Future<Uint8List?> encode(
    String sourcePath, {
    required int targetWidth,
    required int targetHeight,
    required int quality,
    required ImageOutputFormat format,
  });
}

/// `flutter_image_compress` (runs natively, off the UI thread).
class NativeImageCodec implements ImageCodec {
  const NativeImageCodec();

  @override
  Future<Uint8List?> encode(
    String sourcePath, {
    required int targetWidth,
    required int targetHeight,
    required int quality,
    required ImageOutputFormat format,
  }) => FlutterImageCompress.compressWithFile(
    sourcePath,
    minWidth: targetWidth,
    minHeight: targetHeight,
    quality: quality,
    format: switch (format) {
      ImageOutputFormat.jpeg => CompressFormat.jpeg,
      ImageOutputFormat.png => CompressFormat.png,
      ImageOutputFormat.webp => CompressFormat.webp,
    },
  );
}

/// A processed file stored under the attachment's local folder.
@immutable
class ProcessedAttachment {
  const ProcessedAttachment({
    required this.attachmentId,
    required this.fileName,
    required this.storageName,
    required this.mimeType,
    required this.byteSize,
    required this.relOriginal,
    required this.sha256,
    this.relThumb,
    this.width,
    this.height,
    this.durationMs,
  });

  final String attachmentId;

  /// Display name (safe, may contain unicode).
  final String fileName;

  /// ASCII-safe object name used in the Storage path.
  final String storageName;
  final String mimeType;
  final int byteSize;
  final String relOriginal;
  final String? relThumb;
  final String sha256;
  final int? width;
  final int? height;

  /// Length of a video or audio file.
  final int? durationMs;
}

/// On-device processing pipeline (T2.2.03): copy, orientation, metadata strip, compression,
/// thumbnail, hash, dimensions, MIME sniffing.
///
/// Videos and audio (T2.2.12, T2.2.13) are copied as-is (transcoding is left to the OS picker);
/// their duration (and frame size) comes from [MediaProbe]; the thumbnail is a poster frame for
/// videos and the waveform for voice notes.
class AttachmentProcessor {
  AttachmentProcessor({required this._files, required this._codec, this._media, this._waveforms});

  final AttachmentFileStore _files;
  final ImageCodec _codec;
  final MediaProbe? _media;
  final WaveformRenderer? _waveforms;

  static const maxEdge = 2560;
  static const thumbEdge = 512;
  static const quality = 85;
  static const _reencodable = {'image/jpeg', 'image/png', 'image/heic', 'image/heif', 'image/webp', 'image/bmp'};

  /// Sniffs the MIME type from the name and the first bytes.
  static String sniffMime(String name, Uint8List head, {String? hint}) {
    final sniffed = lookupMimeType(name, headerBytes: head);
    if (sniffed != null) return sniffed == 'image/jpg' ? 'image/jpeg' : sniffed;
    if (hint != null && hint.contains('/')) return hint;
    return 'application/octet-stream';
  }

  static Future<Uint8List> readHead(File f, [int length = 64 * 1024]) async {
    final raf = await f.open();
    try {
      return await raf.read(length);
    } finally {
      await raf.close();
    }
  }

  /// Scales `(w, h)` so the long edge is at most [edge].
  static (int, int) fit(int w, int h, int edge) {
    final long = w > h ? w : h;
    if (long <= edge || long == 0) return (w, h);
    final scale = edge / long;
    return ((w * scale).round().clamp(1, edge), (h * scale).round().clamp(1, edge));
  }

  static Future<String> sha256Of(File f) async {
    final length = await f.length();
    if (length < 2 * 1024 * 1024) return sha256.convert(await f.readAsBytes()).toString();
    final path = f.path;
    return Isolate.run(() async => (await sha256.bind(File(path).openRead()).first).toString());
  }

  Future<ProcessedAttachment> process(PickedFileRef source, {required String attachmentId}) async {
    final src = File(source.path);
    final head = await readHead(src);
    final mime = sniffMime(source.name, head, hint: source.mimeType);
    var name = SafeFileName.of(source.name);
    if (mime.startsWith('image/') && _reencodable.contains(mime)) {
      final header = ImageHeaderParser.parse(head);
      final keepPng = mime == 'image/png' && (header?.hasAlpha ?? false);
      final format = keepPng ? ImageOutputFormat.png : ImageOutputFormat.jpeg;
      final outMime = keepPng ? 'image/png' : 'image/jpeg';
      if (!keepPng && mime != 'image/jpeg') name = SafeFileName.withExtension(name, 'jpg');
      final (tw, th) = header == null ? (maxEdge, maxEdge) : fit(header.width, header.height, maxEdge);
      Uint8List? encoded;
      try {
        encoded = await _codec.encode(src.path, targetWidth: tw, targetHeight: th, quality: quality, format: format);
      } on Object {
        encoded = null;
      }
      if (encoded == null || encoded.isEmpty) {
        // Fallback: keep the original bytes but never leak location metadata.
        final raw = await src.readAsBytes();
        final safe = mime == 'image/jpeg' ? stripJpegMetadata(raw) : raw;
        return _finish(attachmentId, SafeFileName.of(source.name), mime, safe, thumbFrom: src.path);
      }
      return _finish(attachmentId, name, outMime, encoded, thumbFrom: src.path);
    }
    if (mime.startsWith('video/') || mime.startsWith('audio/')) {
      return _processMedia(source, attachmentId, name, mime, src);
    }
    // Non-image (or GIF): copied as-is; the thumbnail is the type icon.
    final rel = AttachmentFileStore.relOriginal(attachmentId, SafeFileName.storageKey(name));
    final copied = await _files.copyFrom(rel, src);
    Uint8List? thumb;
    if (mime == 'image/gif') {
      thumb = await _thumb(src.path, ImageHeaderParser.parse(head));
    }
    String? relThumb;
    if (thumb != null) {
      relThumb = AttachmentFileStore.relThumb(attachmentId);
      await _files.writeBytes(relThumb, thumb);
    }
    final header = mime.startsWith('image/') ? ImageHeaderParser.parse(head) : null;
    return ProcessedAttachment(
      attachmentId: attachmentId,
      fileName: name,
      storageName: SafeFileName.storageKey(name),
      mimeType: mime,
      byteSize: await copied.length(),
      relOriginal: rel,
      relThumb: relThumb,
      sha256: await sha256Of(copied),
      width: header?.width,
      height: header?.height,
    );
  }

  Future<ProcessedAttachment> _processMedia(PickedFileRef source, String id, String name, String mime, File src) async {
    final storageName = SafeFileName.storageKey(name);
    final rel = AttachmentFileStore.relOriginal(id, storageName);
    final copied = await _files.copyFrom(rel, src);
    final isVideo = mime.startsWith('video/');
    MediaInfo? info;
    try {
      info = await _media?.inspect(copied.path);
    } on Object {
      info = null;
    }
    String? relThumb;
    final thumbRel = AttachmentFileStore.relThumb(id);
    if (isVideo) {
      final made = await _media?.videoPoster(copied.path, await _files.absolute(thumbRel), edge: thumbEdge) ?? false;
      if (made && await _files.exists(thumbRel)) relThumb = thumbRel;
    } else if (source.waveform case final levels? when _waveforms != null) {
      relThumb = await _waveformThumb(levels, thumbRel);
    }
    return ProcessedAttachment(
      attachmentId: id,
      fileName: name,
      storageName: storageName,
      mimeType: mime,
      byteSize: await copied.length(),
      relOriginal: rel,
      relThumb: relThumb,
      sha256: await sha256Of(copied),
      width: isVideo ? info?.width : null,
      height: isVideo ? info?.height : null,
      durationMs: info?.durationMs ?? source.durationMs,
    );
  }

  /// Renders the waveform to PNG, then re-encodes it as the JPEG thumbnail every device downloads.
  Future<String?> _waveformThumb(List<double> levels, String thumbRel) async {
    try {
      final png = await _waveforms!.render(levels);
      if (png == null || png.isEmpty) return null;
      final pngRel = '$thumbRel.png';
      final pngFile = await _files.writeBytes(pngRel, png);
      final jpeg = await _codec.encode(
        pngFile.path,
        targetWidth: thumbEdge,
        targetHeight: thumbEdge,
        quality: 80,
        format: ImageOutputFormat.jpeg,
      );
      await _files.deleteFile(pngRel);
      if (jpeg == null || jpeg.isEmpty) return null;
      await _files.writeBytes(thumbRel, jpeg);
      return thumbRel;
    } on Object {
      return null;
    }
  }

  Future<ProcessedAttachment> _finish(
    String id,
    String name,
    String mime,
    Uint8List bytes, {
    required String thumbFrom,
  }) async {
    final storageName = SafeFileName.storageKey(name);
    final rel = AttachmentFileStore.relOriginal(id, storageName);
    await _files.writeBytes(rel, bytes);
    final header = ImageHeaderParser.parse(bytes);
    final thumb = await _thumb(thumbFrom, header);
    String? relThumb;
    if (thumb != null) {
      relThumb = AttachmentFileStore.relThumb(id);
      await _files.writeBytes(relThumb, thumb);
    }
    return ProcessedAttachment(
      attachmentId: id,
      fileName: name,
      storageName: storageName,
      mimeType: mime,
      byteSize: bytes.length,
      relOriginal: rel,
      relThumb: relThumb,
      sha256: sha256.convert(bytes).toString(),
      width: header?.orientedSize.$1,
      height: header?.orientedSize.$2,
    );
  }

  Future<Uint8List?> _thumb(String path, ImageHeader? header) async {
    final (tw, th) = header == null ? (thumbEdge, thumbEdge) : fit(header.width, header.height, thumbEdge);
    try {
      final t = await _codec.encode(
        path,
        targetWidth: tw,
        targetHeight: th,
        quality: 75,
        format: ImageOutputFormat.jpeg,
      );
      return t == null || t.isEmpty ? null : t;
    } on Object {
      return null;
    }
  }
}
