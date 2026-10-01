import 'dart:math' as math;
import 'dart:typed_data';

import 'package:everslot/features/attachments/domain/attachment.dart';
import 'package:everslot/features/attachments/domain/attachment_limits.dart';
import 'package:everslot/features/attachments/domain/image_header.dart';
import 'package:everslot/features/attachments/domain/transfer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal PNG header (signature + IHDR) with optional tRNS chunk.
Uint8List pngBytes(int w, int h, {int colorType = 2, bool trns = false}) {
  final b = BytesBuilder()
    ..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..add([0, 0, 0, 13])
    ..add('IHDR'.codeUnits)
    ..add([(w >> 24) & 255, (w >> 16) & 255, (w >> 8) & 255, w & 255])
    ..add([(h >> 24) & 255, (h >> 16) & 255, (h >> 8) & 255, h & 255])
    ..add([8, colorType, 0, 0, 0])
    ..add([0, 0, 0, 0]);
  if (trns) {
    b
      ..add([0, 0, 0, 2])
      ..add('tRNS'.codeUnits)
      ..add([0, 0])
      ..add([0, 0, 0, 0]);
  }
  b
    ..add([0, 0, 0, 0])
    ..add('IDAT'.codeUnits)
    ..add([0, 0, 0, 0]);
  return b.toBytes();
}

/// Minimal JPEG: SOI, APP1 EXIF (orientation + fake GPS pointer), COM, SOF0, SOS, data, EOI.
Uint8List jpegBytes(int w, int h, {int orientation = 1}) {
  // TIFF header (big endian) + IFD with 2 entries: orientation (0x0112) and GPS IFD (0x8825).
  final tiff = <int>[
    0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, //
    0x00, 0x02,
    0x01,
    0x12,
    0x00,
    0x03,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    orientation,
    0x00,
    0x00,
    0x88, 0x25, 0x00, 0x04, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x26,
    0x00, 0x00, 0x00, 0x00,
    ...'GPS-LAT-36.8'.codeUnits,
  ];
  final exif = [...'Exif'.codeUnits, 0, 0, ...tiff];
  final app1Len = exif.length + 2;
  const comment = 'secret';
  return Uint8List.fromList([
    0xFF, 0xD8, //
    0xFF, 0xE1, app1Len >> 8, app1Len & 255, ...exif,
    0xFF, 0xFE, 0x00, comment.length + 2, ...comment.codeUnits,
    0xFF, 0xC0, 0x00, 0x11, 0x08, h >> 8, h & 255, w >> 8, w & 255, 0x03,
    1, 0x22, 0, 2, 0x11, 1, 3, 0x11, 1,
    0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00,
    0x12, 0x34, 0x56,
    0xFF, 0xD9,
  ]);
}

void main() {
  group('AttachmentLimits', () {
    const limits = AttachmentLimits.defaults;

    test('accepts allowed types under the size cap', () {
      expect(limits.validate(byteSize: 1000, mimeType: 'image/jpeg', existingCount: 0), isNull);
      expect(limits.validate(byteSize: 1000, mimeType: 'application/pdf', existingCount: 49), isNull);
      expect(limits.validate(byteSize: 1000, mimeType: 'text/markdown', existingCount: 0), isNull);
    });

    test('rejects oversized, disallowed, empty and over-count files', () {
      expect(
        limits.validate(byteSize: 26 * 1024 * 1024, mimeType: 'image/jpeg', existingCount: 0),
        AttachmentRejection.tooLarge,
      );
      expect(
        limits.validate(byteSize: 10, mimeType: 'application/x-msdownload', existingCount: 0),
        AttachmentRejection.typeNotAllowed,
      );
      expect(
        const AttachmentLimits(allowVideo: false).validate(byteSize: 10, mimeType: 'video/mp4', existingCount: 0),
        AttachmentRejection.typeNotAllowed,
      );
      expect(limits.validate(byteSize: 0, mimeType: 'image/png', existingCount: 0), AttachmentRejection.empty);
      expect(limits.validate(byteSize: 10, mimeType: 'image/png', existingCount: 50), AttachmentRejection.tooMany);
    });

    test('video and audio are allowed; clips get 50 MB and 60 s (T2.2.12)', () {
      expect(limits.validate(byteSize: 10, mimeType: 'video/mp4', existingCount: 0), isNull);
      expect(limits.validate(byteSize: 10, mimeType: 'audio/aac', existingCount: 0), isNull);
      expect(limits.validate(byteSize: 40 * 1024 * 1024, mimeType: 'video/quicktime', existingCount: 0), isNull);
      expect(
        limits.validate(byteSize: 51 * 1024 * 1024, mimeType: 'video/mp4', existingCount: 0),
        AttachmentRejection.tooLarge,
      );
      expect(
        limits.validate(byteSize: 40 * 1024 * 1024, mimeType: 'audio/mp4', existingCount: 0),
        AttachmentRejection.tooLarge,
        reason: 'only videos get the larger limit',
      );
      expect(limits.validateDuration(mimeType: 'video/mp4', durationMs: 60400), isNull, reason: 'rounding');
      expect(limits.validateDuration(mimeType: 'video/mp4', durationMs: 61500), AttachmentRejection.tooLong);
      expect(limits.validateDuration(mimeType: 'audio/mp4', durationMs: 600000), isNull);
      expect(limits.validateDuration(mimeType: 'video/mp4', durationMs: null), isNull);
      const off = AttachmentLimits(allowVideo: false, allowAudio: false);
      expect(off.validate(byteSize: 10, mimeType: 'audio/aac', existingCount: 0), AttachmentRejection.typeNotAllowed);
    });
  });

  group('SafeFileName', () {
    test('strips path parts and forbidden characters', () {
      expect(SafeFileName.of('../../etc/passwd'), 'passwd');
      expect(SafeFileName.of(r'C:\photos\a:b?.jpg'), 'a_b_.jpg');
      expect(SafeFileName.of('.hidden'), 'hidden');
      expect(SafeFileName.of(''), 'file');
    });

    test('keeps unicode names and bounds the length with the extension', () {
      expect(SafeFileName.of('صورة العائلة.jpg'), 'صورة العائلة.jpg');
      final long = '${'a' * 300}.pdf';
      final safe = SafeFileName.of(long);
      expect(safe.length, SafeFileName.maxLength);
      expect(safe, endsWith('.pdf'));
    });

    test('storage keys are ASCII', () {
      expect(SafeFileName.storageKey('Été à Paris.jpg'), '_t_Paris.jpg');
      expect(SafeFileName.withExtension('IMG_1.HEIC', 'jpg'), 'IMG_1.jpg');
    });
  });

  group('AttachmentKind / paths', () {
    test('kind from MIME', () {
      expect(AttachmentKind.fromMime('image/heic'), AttachmentKind.image);
      expect(AttachmentKind.fromMime('application/pdf'), AttachmentKind.pdf);
      expect(
        AttachmentKind.fromMime('application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
        AttachmentKind.document,
      );
      expect(AttachmentKind.fromMime('application/zip'), AttachmentKind.archive);
      expect(AttachmentKind.fromMime('application/octet-stream'), AttachmentKind.other);
    });

    test('paths are prefixed with user and attachment id; reroot swaps the user', () {
      expect(AttachmentPaths.original('u1', 'a1', 'x.jpg'), 'u1/a1/x.jpg');
      expect(AttachmentPaths.thumb('u1', 'a1'), 'u1/a1/thumb.jpg');
      expect(AttachmentPaths.reroot('local-1/a1/x.jpg', 'cloud-9'), 'cloud-9/a1/x.jpg');
    });

    test('json round trip', () {
      final a = Attachment(
        id: 'a1',
        ownerType: AttachmentOwnerType.checklistItem,
        ownerId: 'i1',
        storagePath: 'u/a1/x.jpg',
        fileName: 'x.jpg',
        mimeType: 'image/jpeg',
        byteSize: 10,
        sortKey: 'a0',
        width: 4,
        height: 3,
        uploadedAt: DateTime.utc(2026),
      );
      expect(Attachment.fromJson(a.toJson()), a);
    });
  });

  group('ImageHeaderParser', () {
    test('PNG dimensions and alpha', () {
      final opaque = ImageHeaderParser.parse(pngBytes(640, 480))!;
      expect((opaque.format, opaque.width, opaque.height, opaque.hasAlpha), ('png', 640, 480, false));
      expect(ImageHeaderParser.parse(pngBytes(10, 20, colorType: 6))!.hasAlpha, isTrue);
      expect(ImageHeaderParser.parse(pngBytes(10, 20, colorType: 3, trns: true))!.hasAlpha, isTrue);
    });

    test('JPEG dimensions and every EXIF orientation 1–8', () {
      for (var o = 1; o <= 8; o++) {
        final h = ImageHeaderParser.parse(jpegBytes(4000, 3000, orientation: o))!;
        expect((h.format, h.width, h.height, h.exifOrientation), ('jpeg', 4000, 3000, o));
        expect(h.orientedSize, o >= 5 ? (3000, 4000) : (4000, 3000));
      }
    });

    test('GIF, WebP and garbage', () {
      final gif = Uint8List.fromList([...'GIF89a'.codeUnits, 32, 0, 16, 0, 0, 0, 0, 0]);
      expect(ImageHeaderParser.parse(gif)!.width, 32);
      final vp8l = Uint8List(30)
        ..setAll(0, 'RIFF'.codeUnits)
        ..setAll(8, 'WEBPVP8L'.codeUnits);
      const bits = 99 | (49 << 14) | (1 << 28);
      vp8l.setAll(21, [bits & 255, (bits >> 8) & 255, (bits >> 16) & 255, (bits >> 24) & 255]);
      final webp = ImageHeaderParser.parse(vp8l)!;
      expect((webp.width, webp.height, webp.hasAlpha), (100, 50, true));
      expect(ImageHeaderParser.parse(Uint8List.fromList(List.filled(40, 7))), isNull);
    });
  });

  test('stripJpegMetadata removes EXIF (incl. GPS) and comments but keeps image data', () {
    final original = jpegBytes(40, 30, orientation: 6);
    final stripped = stripJpegMetadata(original);
    String ascii(Uint8List b) => String.fromCharCodes(b);
    expect(ascii(original), contains('GPS-LAT'));
    expect(ascii(stripped), isNot(contains('GPS-LAT')));
    expect(ascii(stripped), isNot(contains('Exif')));
    expect(ascii(stripped), isNot(contains('secret')));
    final header = ImageHeaderParser.parse(stripped)!;
    expect((header.width, header.height, header.exifOrientation), (40, 30, 1));
    expect(stripped.sublist(stripped.length - 5), original.sublist(original.length - 5));
    // Non-JPEG input is returned untouched.
    final png = pngBytes(1, 1);
    expect(stripJpegMetadata(png), same(png));
  });

  group('upload state machine & backoff', () {
    test('valid transitions', () {
      var s = UploadState.pending;
      s = UploadStateMachine.next(s, UploadEvent.start);
      expect(s, UploadState.uploading);
      s = UploadStateMachine.next(s, UploadEvent.fail);
      expect(s, UploadState.failed);
      s = UploadStateMachine.next(s, UploadEvent.retry);
      expect(s, UploadState.pending);
      s = UploadStateMachine.next(UploadStateMachine.next(s, UploadEvent.start), UploadEvent.succeed);
      expect(s, UploadState.done);
      // done is terminal
      expect(UploadStateMachine.next(s, UploadEvent.enqueue), UploadState.done);
      expect(UploadStateMachine.next(UploadState.pending, UploadEvent.succeed), UploadState.pending);
      expect(UploadStateMachine.canAutoRetry(3), isTrue);
      expect(UploadStateMachine.canAutoRetry(8), isFalse);
    });

    test('backoff grows exponentially with jitter and a cap', () {
      final r = math.Random(1);
      final d1 = Backoff.delay(1, random: r);
      expect(d1.inMilliseconds, inInclusiveRange(1000, 2000));
      final d4 = Backoff.delay(4, random: r);
      expect(d4.inMilliseconds, inInclusiveRange(8000, 16000));
      final d30 = Backoff.delay(30, random: r);
      expect(d30.inMilliseconds, lessThanOrEqualTo(const Duration(minutes: 10).inMilliseconds));
      expect(d30.inMilliseconds, greaterThanOrEqualTo(const Duration(minutes: 5).inMilliseconds));
    });
  });

  group('LRU policy', () {
    test('evicts least recently used unpinned entries until under cap', () {
      final t = DateTime.utc(2026);
      final entries = [
        CacheEntry(attachmentId: 'old', bytes: 400, pinned: false, lastAccessAt: t),
        CacheEntry(
          attachmentId: 'pending',
          bytes: 400,
          pinned: true,
          lastAccessAt: t.subtract(const Duration(days: 9)),
        ),
        CacheEntry(attachmentId: 'new', bytes: 400, pinned: false, lastAccessAt: t.add(const Duration(days: 1))),
        const CacheEntry(attachmentId: 'never', bytes: 100, pinned: false),
      ];
      expect(LruPolicy.evict(entries, 2000), isEmpty);
      expect(LruPolicy.evict(entries, 900), ['never', 'old']);
      // Pinned never goes, even if the cap can't be met.
      expect(LruPolicy.evict(entries, 0), ['never', 'old', 'new']);
    });

    test('storage used is deduplicated by path', () {
      expect(
        storageUsedBytes([
          (storagePath: 'u/a/x', byteSize: 10),
          (storagePath: 'u/a/x', byteSize: 10),
          (storagePath: 'u/b/y', byteSize: 5),
        ]),
        15,
      );
    });
  });

  group('transfer status', () {
    AttachmentTransfer status({
      UploadState upload = UploadState.done,
      DownloadState download = DownloadState.none,
      bool uploaded = true,
      bool original = true,
      bool thumb = true,
      bool online = true,
      bool configured = true,
    }) => AttachmentTransfer(
      status: AttachmentTransfer.derive(
        upload: upload,
        download: download,
        isUploadedRemotely: uploaded,
        hasLocalOriginal: original,
        hasLocalThumb: thumb,
        online: online,
        storageConfigured: configured,
      ),
    );

    test('each state', () {
      expect(status().status, TransferStatus.ready);
      expect(status(upload: UploadState.pending, uploaded: false).status, TransferStatus.uploading);
      expect(
        status(upload: UploadState.pending, uploaded: false, online: false).status,
        TransferStatus.waitingForNetwork,
      );
      expect(status(upload: UploadState.pending, uploaded: false, configured: false).status, TransferStatus.ready);
      expect(status(upload: UploadState.failed, uploaded: false).status, TransferStatus.failed);
      expect(status(original: false, thumb: false).status, TransferStatus.notDownloaded);
      expect(status(download: DownloadState.downloading, original: false).status, TransferStatus.downloading);
    });
  });
}
