import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';

/// Source chosen in the "add attachment" menu (T2.2.02, T2.2.12, T2.2.14). Voice notes have
/// their own recorder sheet (T2.2.13).
enum AttachmentSource { camera, photos, files, recordVideo, videos, scan }

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
}

/// `image_picker` (camera + system photo picker, no broad media permission), `file_picker` and the
/// platform document scanner (`cunning_document_scanner`: VisionKit / ML Kit, edge detection and
/// perspective correction, multi-page PDF).
class PlatformAttachmentPicker implements AttachmentPicker {
  PlatformAttachmentPicker({required this._clock, ImagePicker? imagePicker}) : _images = imagePicker ?? ImagePicker();

  final Clock _clock;
  final ImagePicker _images;

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
