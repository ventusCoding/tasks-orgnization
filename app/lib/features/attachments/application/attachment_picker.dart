import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/attachments/domain/image_header.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';

/// Source chosen in the "add attachment" menu (T2.2.02, T2.2.12, T2.2.14, T4.4.09 clipboard).
/// Voice notes have their own recorder sheet (T2.2.13).
enum AttachmentSource { camera, photos, files, recordVideo, videos, scan, clipboard }

/// A file picked from the platform, not processed yet.
@immutable
class PickedFileRef {
  const PickedFileRef({
    required this.path,
    required this.name,
    this.size,
    this.mimeType,
    this.durationMs,
    this.waveform,
  });

  final String path;
  final String name;
  final int? size;
  final String? mimeType;

  /// Known length of a recording (voice notes).
  final int? durationMs;

  /// Waveform levels 0..1 of a voice note (drawn on its thumbnail).
  final List<double>? waveform;
}

/// Platform pickers behind an interface so tests and other features can fake them.
abstract class AttachmentPicker {
  /// Returns picked files (empty on cancel). Throws [PermissionException] when access is denied.
  Future<List<PickedFileRef>> pick(AttachmentSource source, {int? limit});

  /// An image received as bytes (keyboard image insertion, T4.4.09) as a temporary file; null
  /// when the bytes are not an image.
  Future<PickedFileRef?> fromImageBytes(Uint8List bytes);
}

/// `image_picker` (camera + system photo picker, no broad media permission), `file_picker` and the
/// platform document scanner (`cunning_document_scanner`: VisionKit / ML Kit, edge detection and
/// perspective correction, multi-page PDF).
///
/// The clipboard source (T4.4.09) reads an image with `pasteboard` (iOS UIPasteboard, Android
/// ClipboardManager content URI) and writes it to a temporary file; no image → empty list.
class PlatformAttachmentPicker implements AttachmentPicker {
  PlatformAttachmentPicker({
    required this._clock,
    ImagePicker? imagePicker,
    Future<Uint8List?> Function()? readClipboardImage,
    Future<Directory> Function()? tempDir,
  }) : _images = imagePicker ?? ImagePicker(),
       _readClipboardImage = readClipboardImage ?? (() => Pasteboard.image),
       _tempDir = tempDir ?? getTemporaryDirectory;

  final Clock _clock;
  final ImagePicker _images;
  final Future<Uint8List?> Function() _readClipboardImage;
  final Future<Directory> Function() _tempDir;

  /// Writes image [bytes] (clipboard, keyboard image insertion) to a temporary file named
  /// "Pasted image 2026-09-22 14.05.png" (extension from the image header). Null when the bytes
  /// are not an image.
  static Future<PickedFileRef?> imageBytesToFile(
    Uint8List bytes, {
    required Directory dir,
    required DateTime nowUtc,
  }) async {
    final format = ImageHeaderParser.parse(bytes)?.format;
    if (format == null) return null;
    final ext = format == 'jpeg' ? 'jpg' : format;
    final t = nowUtc.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final name = 'Pasted image ${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}.${two(t.minute)}.$ext';
    final folder = Directory('${dir.path}/pasted-${Ids.v7()}');
    await folder.create(recursive: true);
    final file = File('${folder.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return PickedFileRef(path: file.path, name: name, size: bytes.length, mimeType: 'image/$format');
  }

  /// [imageBytesToFile] into the platform temporary directory.
  @override
  Future<PickedFileRef?> fromImageBytes(Uint8List bytes) async =>
      imageBytesToFile(bytes, dir: await _tempDir(), nowUtc: _clock.nowUtc());

  /// Longest clip offered by the camera (T2.2.12; longer picks are refused after processing).
  static const maxVideoDuration = Duration(seconds: 60);
  static const maxScanPages = 30;

  /// "Scan 2026-09-22 14.05.pdf" (device-local time of the scan).
  static String scanName(DateTime nowUtc) {
    final t = nowUtc.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'Scan ${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}.${two(t.minute)}.pdf';
  }

  @override
  Future<List<PickedFileRef>> pick(AttachmentSource source, {int? limit}) async {
    try {
      switch (source) {
        case AttachmentSource.camera:
          final shot = await _images.pickImage(source: ImageSource.camera, requestFullMetadata: false);
          return shot == null ? const [] : [await _fromXFile(shot)];
        case AttachmentSource.photos:
          final picked = await _images.pickMultiImage(
            requestFullMetadata: false,
            limit: limit != null && limit >= 2 ? limit : null,
          );
          return [for (final f in picked) await _fromXFile(f)];
        case AttachmentSource.recordVideo:
          final clip = await _images.pickVideo(source: ImageSource.camera, maxDuration: maxVideoDuration);
          return clip == null ? const [] : [await _fromXFile(clip)];
        case AttachmentSource.videos:
          final clip = await _images.pickVideo(source: ImageSource.gallery);
          return clip == null ? const [] : [await _fromXFile(clip)];
        case AttachmentSource.scan:
          final pdf = await CunningDocumentScanner.getPictures(noOfPages: maxScanPages, asPdf: true);
          if (pdf == null || pdf.isEmpty) return const [];
          final file = File(pdf.first);
          return [
            PickedFileRef(
              path: file.path,
              name: scanName(_clock.nowUtc()),
              size: await file.length(),
              mimeType: 'application/pdf',
            ),
          ];
        case AttachmentSource.clipboard:
          final bytes = await _readClipboardImage();
          if (bytes == null || bytes.isEmpty) return const [];
          final file = await fromImageBytes(bytes);
          return [?file];
        case AttachmentSource.files:
          final files = await FilePicker.pickFiles();
          return [
            for (final f in files)
              if (f.path != null) PickedFileRef(path: f.path!, name: f.name, size: f.lengthSync()),
          ];
      }
    } on CunningDocumentScannerException catch (e) {
      if (e.code == 'permission_denied') throw PermissionException(e.message, cause: e);
      rethrow;
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('denied') || code.contains('restricted') || code.contains('permission')) {
        throw PermissionException(e.message ?? e.code, cause: e);
      }
      rethrow;
    }
  }

  static Future<PickedFileRef> _fromXFile(XFile f) async =>
      PickedFileRef(path: f.path, name: f.name, size: await f.length(), mimeType: f.mimeType);
}
