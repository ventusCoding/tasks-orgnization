import 'package:everslot/core/errors/app_exception.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';

/// Source chosen in the "add attachment" menu (T2.2.02).
enum AttachmentSource { camera, photos, files }

/// A file picked from the platform, not processed yet.
@immutable
class PickedFileRef {
  const PickedFileRef({required this.path, required this.name, this.size, this.mimeType});

  final String path;
  final String name;
  final int? size;
  final String? mimeType;
}

/// Platform pickers behind an interface so tests and other features can fake them.
abstract class AttachmentPicker {
  /// Returns picked files (empty on cancel). Throws [PermissionException] when access is denied.
  Future<List<PickedFileRef>> pick(AttachmentSource source, {int? limit});
}

/// `image_picker` (camera + system photo picker, no broad media permission) and `file_picker`.
class PlatformAttachmentPicker implements AttachmentPicker {
  PlatformAttachmentPicker({ImagePicker? imagePicker}) : _images = imagePicker ?? ImagePicker();

  final ImagePicker _images;

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
        case AttachmentSource.files:
          final files = await FilePicker.pickFiles();
          return [
            for (final f in files)
              if (f.path != null) PickedFileRef(path: f.path!, name: f.name, size: f.lengthSync()),
          ];
      }
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
