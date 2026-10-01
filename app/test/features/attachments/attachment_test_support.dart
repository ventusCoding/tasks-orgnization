import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:everslot/features/attachments/application/attachment_processor.dart';
import 'package:everslot/features/attachments/application/attachment_transfers.dart';
import 'package:everslot/features/attachments/application/media.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/attachments/data/attachment_remote_storage.dart';

/// Fake native codec: returns a tiny JPEG-looking payload sized from the target dimensions.
class FakeImageCodec implements ImageCodec {
  final calls = <({int w, int h, ImageOutputFormat format})>[];

  @override
  Future<Uint8List?> encode(
    String sourcePath, {
    required int targetWidth,
    required int targetHeight,
    required int quality,
    required ImageOutputFormat format,
  }) async {
    calls.add((w: targetWidth, h: targetHeight, format: format));
    // SOI + SOF0 with the target size + EOI (no EXIF).
    return Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xC0, 0x00, 0x11, 0x08, //
      targetHeight >> 8,
      targetHeight & 255,
      targetWidth >> 8,
      targetWidth & 255,
      0x03,
      1, 0x22, 0, 2, 0x11, 1, 3, 0x11, 1,
      0xFF,
      0xDA,
      0x00,
      0x08,
      0x01,
      0x01,
      0x00,
      0x00,
      0x3F,
      0x00,
      1,
      2,
      3,
      ...sourcePath.codeUnits,
      0xFF,
      0xD9,
      ...List.filled(quality, 7),
    ]);
  }
}

/// In-memory remote storage with scriptable failures.
class FakeRemoteStorage implements AttachmentRemoteStorage {
  final Map<String, Uint8List> objects = {};
  int failNext = 0;
  int uploads = 0;

  @override
  Future<void> upload({
    required String bucket,
    required String path,
    required File file,
    required String mimeType,
    TransferProgress? onProgress,
    String? resumeUrl,
    void Function(String url)? onResumeUrl,
  }) async {
    uploads++;
    if (failNext > 0) {
      failNext--;
      throw Exception('network down');
    }
    final bytes = await file.readAsBytes();
    onProgress?.call(bytes.length ~/ 2, bytes.length);
    objects['$bucket/$path'] = bytes;
    onProgress?.call(bytes.length, bytes.length);
  }

  @override
  Future<Uint8List> download({required String bucket, required String path}) async {
    final o = objects['$bucket/$path'];
    if (o == null) throw Exception('404');
    return o;
  }
}

class FakeConnectivity implements ConnectivityProbe {
  FakeConnectivity([this.kind = NetworkKind.wifi]);

  NetworkKind kind;
  final _changes = StreamController<NetworkKind>.broadcast();

  void set(NetworkKind k) {
    kind = k;
    _changes.add(k);
  }

  @override
  Future<NetworkKind> current() async => kind;

  @override
  Stream<NetworkKind> get changes => _changes.stream;
}

AttachmentFileStore tempFileStore(Directory dir) => AttachmentFileStore(() async => dir);

/// Writes a source file for picking.
File writeSource(Directory dir, String name, List<int> bytes) => File('${dir.path}/$name')..writeAsBytesSync(bytes);

/// Media probe with a scripted duration/size; writes a small JPEG poster for videos.
class FakeMediaProbe implements MediaProbe {
  FakeMediaProbe({this.durationMs = 12000, this.width = 1920, this.height = 1080, this.poster = true});

  int? durationMs;
  int? width;
  int? height;
  bool poster;
  final inspected = <String>[];

  @override
  Future<MediaInfo?> inspect(String path) async {
    inspected.add(path);
    return MediaInfo(durationMs: durationMs, width: width, height: height);
  }

  @override
  Future<bool> videoPoster(String path, String destPath, {required int edge}) async {
    if (!poster) return false;
    File(destPath)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
    return true;
  }
}

/// Waveform renderer returning a fixed PNG-ish payload and recording the levels it drew.
class FakeWaveformRenderer implements WaveformRenderer {
  final rendered = <List<double>>[];

  @override
  Future<Uint8List?> render(List<double> levels) async {
    rendered.add(levels);
    return Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, ...List.filled(16, 1)]);
  }
}

/// Microphone recorder that writes a small file and emits scripted levels.
class FakeVoiceRecorder implements VoiceRecorder {
  FakeVoiceRecorder({this.permission = true});

  bool permission;
  final _levels = StreamController<double>.broadcast();
  String? path;
  bool cancelled = false;
  bool disposed = false;

  void emit(double db) => _levels.add(db);

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start(String path) async {
    this.path = path;
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(List.filled(64, 3));
  }

  @override
  Stream<double> get levels => _levels.stream;

  @override
  Future<String?> stop() async => path;

  @override
  Future<void> cancel() async {
    cancelled = true;
    if (path != null && File(path!).existsSync()) File(path!).deleteSync();
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _levels.close();
  }
}
