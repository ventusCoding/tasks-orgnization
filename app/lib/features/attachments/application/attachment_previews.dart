import 'package:everslot/features/attachments/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local image previews of an owner's attachments for other features (rich notifications,
/// T7.2.26). Only files already on the device are returned — nothing is downloaded.
class AttachmentPreviews {
  AttachmentPreviews(this._ref);

  final Ref _ref;

  /// The first image attachment of the owner whose thumbnail (or original) is cached locally.
  Future<String?> cachedImage(String ownerType, String ownerId) async {
    final cache = _ref.read(attachmentCacheStoreProvider);
    final files = _ref.read(attachmentFileStoreProvider);
    for (final a in await _ref.read(attachmentsRepositoryProvider).listFor(ownerType, ownerId)) {
      if (!a.isImage) continue;
      final local = await AttachmentLocal.resolve(await cache.get(a.id), files);
      if (local.displayPath != null) return local.displayPath;
    }
    return null;
  }
}

final attachmentPreviewsProvider = Provider<AttachmentPreviews>(AttachmentPreviews.new);
