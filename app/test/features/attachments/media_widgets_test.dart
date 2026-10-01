import 'dart:io';

import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/attachments/data/attachments_repository.dart';
import 'package:everslot/features/attachments/domain/transfer.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/attachments/presentation/attachment_ui.dart';
import 'package:everslot/features/attachments/presentation/media_playback.dart';
import 'package:everslot/features/attachments/presentation/voice_note_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'attachment_test_support.dart';

/// Player that only records calls (no platform channel).
class FakeMediaPlayback implements MediaPlayback {
  FakeMediaPlayback(this.log);

  final List<String> log;
  final _state = ValueNotifier(const PlaybackState());

  @override
  ValueListenable<PlaybackState> get state => _state;

  void finish() => _state.value = PlaybackState(
    ready: true,
    completed: true,
    duration: _state.value.duration,
    position: _state.value.duration,
  );

  @override
  Future<void> open(String path) async {
    log.add('open ${path.split('/').last}');
    _state.value = const PlaybackState(ready: true, duration: Duration(seconds: 12));
  }

  @override
  Future<void> play() async {
    log.add('play');
    _state.value = PlaybackState(ready: true, playing: true, duration: _state.value.duration);
  }

  @override
  Future<void> pause() async {
    log.add('pause');
    _state.value = PlaybackState(ready: true, duration: _state.value.duration, position: const Duration(seconds: 3));
  }

  @override
  Future<void> seek(Duration position) async => log.add('seek ${position.inSeconds}');

  @override
  Widget surface() => const ColoredBox(key: ValueKey('video-surface'), color: Colors.black);

  @override
  Future<void> dispose() async => log.add('dispose');
}

/// T2.2.12 / T2.2.13 / T2.2.14 UI: the add menu, the voice-note recorder, media tiles with inline
/// voice playback, and the clip player.
void main() {
  late TestHarness h;
  late Directory root;
  late FakeVoiceRecorder recorder;
  late List<String> playerLog;
  late List<FakeMediaPlayback> players;

  setUp(() {
    root = Directory.systemTemp.createTempSync('media_w');
    recorder = FakeVoiceRecorder();
    playerLog = [];
    players = [];
    h = TestHarness.create(
      overrides: [
        attachmentFileStoreProvider.overrideWithValue(tempFileStore(root)),
        voiceRecorderFactoryProvider.overrideWithValue(() => recorder),
        mediaPlaybackFactoryProvider.overrideWithValue(() {
          final p = FakeMediaPlayback(playerLog);
          players.add(p);
          return p;
        }),
      ],
    );
  });

  tearDown(() async {
    await h.dispose();
    root.deleteSync(recursive: true);
  });

  Future<void> settle(WidgetTester tester, {int rounds = 10}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester, rounds: 3);
  }

  testWidgets('the add menu offers video, voice note and document scan', (tester) async {
    AddAttachmentChoice? chosen;
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: Builder(
          builder: (context) =>
              TextButton(onPressed: () async => chosen = await pickAttachmentSource(context), child: const Text('add')),
        ),
      ),
    );
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    for (final label in [
      'Take photo',
      'Choose photos',
      'Record a video',
      'Choose a video',
      'Voice note',
      'Scan a document',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tester.tap(find.text('Scan a document'));
    await tester.pumpAndSettle();
    expect(chosen, AddAttachmentChoice.scan);
    expect(chosen!.source, AttachmentSource.scan);
    expect(AddAttachmentChoice.voiceNote.source, isNull);
  });

  group('voice note recorder', () {
    Future<Future<PickedFileRef?> Function()> openSheet(WidgetTester tester) async {
      PickedFileRef? result;
      var done = false;
      await pumpInApp(
        tester,
        h,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await recordVoiceNote(context);
                done = true;
              },
              child: const Text('record'),
            ),
          ),
        ),
      );
      return () async {
        for (var i = 0; i < 50 && !done; i++) {
          await settle(tester, rounds: 1);
        }
        return result;
      };
    }

    testWidgets('record, see the timer, stop, attach with duration and waveform', (tester) async {
      final result = await openSheet(tester);
      await tester.tap(find.text('record'));
      await tester.pumpAndSettle();
      expect(find.text('Tap the microphone and speak.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('voice-note-record')));
      await settle(tester);
      for (final db in <double>[-40, -12, -6, -30]) {
        recorder.emit(db);
      }
      await tester.pump(const Duration(milliseconds: 1000));
      await settle(tester, rounds: 2);
      expect(find.byKey(const ValueKey('voice-note-stop')), findsOneWidget);
      final timer = tester.widget<Text>(find.byKey(const ValueKey('voice-note-timer'))).data!;
      expect(timer, matches(RegExp(r'^00:0[01]$')));

      await tester.tap(find.byKey(const ValueKey('voice-note-stop')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('voice-note-save')));
      await settle(tester);
      final note = (await result())!;
      expect(note.name, endsWith('.m4a'));
      expect(note.name, startsWith('Voice note'));
      expect(note.mimeType, 'audio/mp4');
      expect(note.durationMs, greaterThanOrEqualTo(1000));
      expect(note.waveform, hasLength(48));
      expect(note.waveform!.reduce((a, b) => a > b ? a : b), closeTo(0.88, 1e-9));
      expect(File(note.path).existsSync(), isTrue, reason: 'kept for processing');
      await unmount(tester);
      expect(recorder.disposed, isTrue);
    });

    testWidgets('discard deletes the recording', (tester) async {
      final result = await openSheet(tester);
      await tester.tap(find.text('record'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('voice-note-record')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('voice-note-stop')));
      await settle(tester);
      final path = recorder.path!;
      await tester.tap(find.byKey(const ValueKey('voice-note-discard')));
      await settle(tester);
      expect(await result(), isNull);
      await settle(tester);
      expect(File(path).existsSync(), isFalse);
      await unmount(tester);
    });

    testWidgets('closing the sheet while recording cancels it', (tester) async {
      await openSheet(tester);
      await tester.tap(find.text('record'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('voice-note-record')));
      await settle(tester);
      await tester.tapAt(const Offset(10, 10)); // outside the sheet
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      expect(recorder.cancelled, isTrue);
      await unmount(tester);
    });

    testWidgets('microphone denied: the permission help shows', (tester) async {
      recorder.permission = false;
      await openSheet(tester);
      await tester.tap(find.text('record'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('voice-note-record')));
      await settle(tester);
      expect(find.text('Open settings'), findsOneWidget);
      expect(recorder.path, isNull);
      await unmount(tester);
    });
  });

  group('media tiles and player', () {
    Future<(Attachment, Attachment)> seed(WidgetTester tester) async {
      late Attachment video;
      late Attachment voice;
      await tester.runAsync(() async {
        final repo = h.read(attachmentsRepositoryProvider);
        final cache = h.read(attachmentCacheStoreProvider);
        final files = h.read(attachmentFileStoreProvider);
        Future<void> local(String id, String name) async {
          await files.writeBytes(AttachmentFileStore.relOriginal(id, name), Uint8List.fromList(List.filled(32, 1)));
          await cache.putLocal(
            id,
            originalRel: AttachmentFileStore.relOriginal(id, name),
            thumbRel: null,
            bytes: 32,
            uploadState: UploadState.pending,
          );
        }

        await repo.insertAll([
          const NewAttachment(
            id: 'vid',
            ownerType: AttachmentOwnerType.task,
            ownerId: 't1',
            storagePath: 'user-1/vid/clip.mp4',
            fileName: 'clip.mp4',
            mimeType: 'video/mp4',
            byteSize: 32,
            durationMs: 12400,
          ),
          const NewAttachment(
            id: 'voc',
            ownerType: AttachmentOwnerType.task,
            ownerId: 't1',
            storagePath: 'user-1/voc/note.m4a',
            fileName: 'note.m4a',
            mimeType: 'audio/mp4',
            byteSize: 32,
            durationMs: 65000,
          ),
        ]);
        await local('vid', 'clip.mp4');
        await local('voc', 'note.m4a');
        final list = await repo.listFor(AttachmentOwnerType.task, 't1');
        video = list.firstWhere((a) => a.id == 'vid');
        voice = list.firstWhere((a) => a.id == 'voc');
      });
      return (video, voice);
    }

    testWidgets('clip lengths are shown and spoken; tapping a voice note plays it inline', (tester) async {
      final handle = tester.ensureSemantics();
      await seed(tester);
      await pumpInApp(
        tester,
        h,
        const Scaffold(
          body: Center(
            child: AttachmentStrip(ownerType: AttachmentOwnerType.task, ownerId: 't1'),
          ),
        ),
      );
      await settle(tester);
      expect(find.bySemanticsLabel(RegExp(r'Video 1 of 2, clip\.mp4, Length 0:12')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Audio 2 of 2, note\.m4a, Length 1:05')), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill), findsNWidgets(2));

      await tester.tap(find.bySemanticsLabel(RegExp('^Audio 2 of 2')));
      await settle(tester);
      expect(h.read(voicePlaybackProvider), 'voc');
      expect(playerLog, ['open note.m4a', 'play']);
      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);

      players.single.finish();
      await settle(tester);
      expect(h.read(voicePlaybackProvider), isNull, reason: 'stops at the end');
      expect(playerLog.last, 'dispose');
      handle.dispose();
      await unmount(tester);
    });

    testWidgets('the viewer player: video surface, play/pause, seek label', (tester) async {
      final (video, _) = await seed(tester);
      await pumpInApp(
        tester,
        h,
        Scaffold(
          body: MediaPlayerView(attachment: video, path: '${root.path}/clip.mp4'),
        ),
      );
      await settle(tester);
      expect(find.byKey(const ValueKey('video-surface')), findsOneWidget);
      expect(find.text('0:00 / 0:12'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('media-play')));
      await settle(tester);
      expect(playerLog, ['open clip.mp4', 'play']);
      expect(find.byTooltip('Pause'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('media-play')));
      await settle(tester);
      expect(find.text('0:03 / 0:12'), findsOneWidget);
      await unmount(tester);
      expect(playerLog.last, 'dispose');
    });
  });
}
