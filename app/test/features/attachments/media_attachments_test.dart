import 'dart:io';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/attachments/application/attachment_picker.dart';
import 'package:everslot/features/attachments/application/attachment_processor.dart';
import 'package:everslot/features/attachments/application/attachment_service.dart';
import 'package:everslot/features/attachments/application/attachment_transfers.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/attachments/domain/attachment.dart';
import 'package:everslot/features/attachments/domain/attachment_limits.dart';
import 'package:everslot/features/attachments/domain/waveform.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import 'attachment_test_support.dart';

/// T2.2.12 / T2.2.13 / T2.2.14: videos (poster, duration, 50 MB / 60 s), voice notes (duration,
/// waveform thumbnail), scanned PDFs (name) through the same pipeline.
void main() {
  group('Waveform', () {
    test('peaks per bar mapped from −50 dBFS…0 to 0…1', () {
      final levels = Waveform.fromAmplitudes([-60, -50, -25, 0, -10, -40], bars: 3);
      expect(levels, hasLength(3));
      expect(levels[0], 0, reason: 'at or below the floor');
      expect(levels[1], 1, reason: 'peak of the slice');
      expect(levels[2], closeTo(0.8, 1e-9));
    });

    test('stretches short recordings and flattens empty ones', () {
      expect(Waveform.fromAmplitudes([-25], bars: 4), [0.5, 0.5, 0.5, 0.5]);
      expect(Waveform.fromAmplitudes(const [], bars: 3), [0, 0, 0]);
      expect(Waveform.fromAmplitudes(const [-10, double.nan], bars: 2), [0.8, 0]);
      expect(Waveform.fromAmplitudes(const [-10], bars: 0), isEmpty);
    });
  });

  test('scanned PDFs are named after the local scan time', () {
    final name = PlatformAttachmentPicker.scanName(DateTime.utc(2026, 9, 22, 12, 5));
    expect(name, matches(RegExp(r'^Scan 2026-09-2\d \d\d\.\d\d\.pdf$')));
  });

  group('pipeline', () {
    late TestHarness h;
    late Directory root;
    late Directory sources;
    late AttachmentsRepository repo;
    late AttachmentCacheStore cache;
    late AttachmentFileStore files;
    late FakeImageCodec codec;
    late FakeMediaProbe probe;
    late FakeWaveformRenderer waveforms;

    setUp(() async {
      h = TestHarness.create();
      root = await Directory.systemTemp.createTemp('media_root');
      sources = await Directory.systemTemp.createTemp('media_src');
      repo = AttachmentsRepository(h.db, h.read(syncWriterProvider), () => 'user-1');
      cache = AttachmentCacheStore(h.db);
      files = tempFileStore(root);
      codec = FakeImageCodec();
      probe = FakeMediaProbe();
      waveforms = FakeWaveformRenderer();
    });

    tearDown(() async {
      await h.dispose();
      await root.delete(recursive: true);
      await sources.delete(recursive: true);
    });

    AttachmentService service({AttachmentLimits limits = AttachmentLimits.defaults}) => AttachmentService(
      repository: repo,
      cache: cache,
      files: files,
      processor: AttachmentProcessor(files: files, codec: codec, media: probe, waveforms: waveforms),
      queue: AttachmentUploadQueue(
        repository: repo,
        cache: cache,
        files: files,
        storage: null,
        clock: h.clock,
        connectivity: FakeConnectivity(),
        userId: () => 'user-1',
      ),
      userId: () => 'user-1',
      newId: Ids.v7,
      limits: limits,
    );

    // ISO-BMFF header so MIME sniffing sees an MP4 / M4A.
    List<int> mp4(String brand, int size) => [
      0, 0, 0, 0x18, ...'ftyp'.codeUnits, ...brand.codeUnits, 0, 0, 0, 0, ...'isommp42'.codeUnits, //
      ...List.filled(size, 7),
    ];

    PickedFileRef pick(String name, List<int> bytes, {int? durationMs, List<double>? waveform, String? mime}) =>
        PickedFileRef(
          path: writeSource(sources, name, bytes).path,
          name: name,
          durationMs: durationMs,
          waveform: waveform,
          mimeType: mime,
        );

    test('a video is copied as-is with its poster frame, size and duration', () async {
      final result = await service().addFiles(AttachmentOwnerType.task, 't1', [
        pick('clip.mp4', mp4('mp42', 4096), mime: 'video/mp4'),
      ]);
      expect(result.rejected, isEmpty);
      final a = (await repo.listFor(AttachmentOwnerType.task, 't1')).single;
      expect(a.kind, AttachmentKind.video);
      expect(a.durationMs, 12000);
      expect((a.width, a.height), (1920, 1080));
      expect(a.thumbPath, 'user-1/${a.id}/thumb.jpg');
      final local = (await cache.get(a.id))!;
      expect(await files.exists(local.localThumbPath), isTrue);
      expect(await (await files.file(local.localOriginalPath!)).length(), a.byteSize);
      expect(codec.calls, isEmpty, reason: 'videos are never re-encoded');
    });

    test('videos longer than 60 s are refused and leave no files', () async {
      probe.durationMs = 75000;
      final result = await service().addFiles(AttachmentOwnerType.task, 't1', [
        pick('long.mp4', mp4('mp42', 64), mime: 'video/mp4'),
      ]);
      expect(result.rejected, {'long.mp4': AttachmentRejection.tooLong});
      expect(await repo.listFor(AttachmentOwnerType.task, 't1'), isEmpty);
      expect(root.listSync(recursive: true).whereType<File>(), isEmpty);
    });

    test('without a poster the video still attaches (type icon instead)', () async {
      probe.poster = false;
      await service().addFiles(AttachmentOwnerType.task, 't1', [
        pick('clip.mov', mp4('qt  ', 64), mime: 'video/quicktime'),
      ]);
      final a = (await repo.listFor(AttachmentOwnerType.task, 't1')).single;
      expect(a.thumbPath, isNull);
      expect(a.mimeType, 'video/quicktime');
    });

    test('a voice note keeps its duration and gets its waveform as the thumbnail', () async {
      probe
        ..durationMs = null
        ..width = null
        ..height = null;
      final waveform = Waveform.fromAmplitudes([-40, -20, -5, -30]);
      await service().addFiles(AttachmentOwnerType.habitLog, 'log-1', [
        pick('Voice note.m4a', mp4('M4A ', 512), durationMs: 4200, waveform: waveform, mime: 'audio/mp4'),
      ]);
      final a = (await repo.listFor(AttachmentOwnerType.habitLog, 'log-1')).single;
      expect(a.kind, AttachmentKind.audio);
      expect(a.durationMs, 4200, reason: 'recorder duration when the probe has none');
      expect(a.width, isNull);
      expect(waveforms.rendered.single, waveform);
      expect(a.thumbPath, isNotNull);
      final local = (await cache.get(a.id))!;
      expect(await files.exists(local.localThumbPath), isTrue);
      expect(await files.exists('${local.localThumbPath}.png'), isFalse, reason: 'intermediate PNG removed');
      expect(codec.calls.single.format, ImageOutputFormat.jpeg);
    });

    test('an audio file picked without a waveform has no thumbnail', () async {
      await service().addFiles(AttachmentOwnerType.task, 't1', [pick('song.m4a', mp4('M4A ', 64), mime: 'audio/mp4')]);
      final a = (await repo.listFor(AttachmentOwnerType.task, 't1')).single;
      expect(a.thumbPath, isNull);
      expect(a.durationMs, 12000, reason: 'probed');
    });

    test('a scanned PDF attaches like any document', () async {
      final name = PlatformAttachmentPicker.scanName(DateTime.utc(2026, 9, 22, 12));
      await service().addFiles(AttachmentOwnerType.checklistItem, 'i1', [
        pick(name, '%PDF-1.7\n1 0 obj\n'.codeUnits, mime: 'application/pdf'),
      ]);
      final a = (await repo.listFor(AttachmentOwnerType.checklistItem, 'i1')).single;
      expect(a.kind, AttachmentKind.pdf);
      expect(a.fileName, name);
      expect(probe.inspected, isEmpty);
    });
  });
}
