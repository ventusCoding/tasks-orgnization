import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:everslot/features/attachments/domain/waveform.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/painting.dart';
import 'package:meta/meta.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

/// Duration and size of a clip.
@immutable
class MediaInfo {
  const MediaInfo({this.durationMs, this.width, this.height});

  final int? durationMs;
  final int? width;
  final int? height;
}

/// Native media inspection (behind an interface so tests and isolates can fake it).
abstract class MediaProbe {
  /// Duration (and frame size for videos) of a local video or audio file; null when unreadable.
  Future<MediaInfo?> inspect(String path);

  /// Writes a JPEG poster frame (long edge ≤ [edge]) of a video to [destPath]; false when none.
  Future<bool> videoPoster(String path, String destPath, {required int edge});
}

/// `video_player` (duration/size, also plays audio) + `fc_native_video_thumbnail` (poster frame).
class NativeMediaProbe implements MediaProbe {
  const NativeMediaProbe();

  @override
  Future<MediaInfo?> inspect(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize().timeout(const Duration(seconds: 10));
      final v = controller.value;
      final size = v.size;
      return MediaInfo(
        durationMs: v.duration.inMilliseconds,
        width: size.width > 0 ? size.width.round() : null,
        height: size.height > 0 ? size.height.round() : null,
      );
    } on Object {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  @override
  Future<bool> videoPoster(String path, String destPath, {required int edge}) async {
    try {
      await File(destPath).parent.create(recursive: true);
      return await FcNativeVideoThumbnail().saveThumbnailToFile(
        srcFile: path,
        destFile: destPath,
        width: edge,
        height: edge,
        format: 'jpeg',
        quality: 75,
      );
    } on Object {
      return false;
    }
  }
}

/// Draws a waveform preview image (the voice note's thumbnail).
abstract class WaveformRenderer {
  /// PNG bytes of [levels] (0..1) as rounded bars; null when rendering is unavailable.
  Future<Uint8List?> render(List<double> levels);
}

/// `dart:ui` renderer: neutral bars on a light card, legible on both themes.
class CanvasWaveformRenderer implements WaveformRenderer {
  const CanvasWaveformRenderer({this.width = 512, this.height = 160});

  final int width;
  final int height;

  static const _background = Color(0xFFF1F3F6); // color-ok: baked into a shared thumbnail image
  static const _bar = Color(0xFF4A5568); // color-ok: baked into a shared thumbnail image

  @override
  Future<Uint8List?> render(List<double> levels) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = width.toDouble();
    final h = height.toDouble();
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = _background);
    if (levels.isNotEmpty) {
      final slot = w / levels.length;
      final barWidth = slot * 0.6;
      final paint = Paint()..color = _bar;
      for (var i = 0; i < levels.length; i++) {
        final barHeight = (levels[i].clamp(0.0, 1.0) * (h * 0.8)).clamp(4.0, h * 0.8);
        final left = i * slot + (slot - barWidth) / 2;
        final top = (h - barHeight) / 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(left, top, barWidth, barHeight), Radius.circular(barWidth / 2)),
          paint,
        );
      }
    }
    final image = await recorder.endRecording().toImage(width, height);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}

/// Voice-note recorder (T2.2.13) behind an interface so the sheet can be tested.
abstract class VoiceRecorder {
  /// Asks for (or checks) the microphone permission.
  Future<bool> hasPermission();

  /// Starts recording AAC to [path].
  Future<void> start(String path);

  /// Live input level in dBFS (≤ 0) while recording.
  Stream<double> get levels;

  /// Stops and returns the file path (null when nothing was recorded).
  Future<String?> stop();

  /// Stops and deletes the recording.
  Future<void> cancel();

  Future<void> dispose();
}

/// `record` (AAC-LC mono 64 kb/s in an `.m4a` container).
class NativeVoiceRecorder implements VoiceRecorder {
  NativeVoiceRecorder() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;

  static const config = RecordConfig(bitRate: 64000, numChannels: 1, noiseSuppress: true, echoCancel: true);

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String path) async {
    await File(path).parent.create(recursive: true);
    await _recorder.start(config, path: path);
  }

  @override
  Stream<double> get levels => _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).map((a) => a.current);

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Future<void> dispose() => _recorder.dispose();
}

/// Turns recorder levels into the stored waveform.
List<double> waveformOf(List<double> dbfs) => Waveform.fromAmplitudes(dbfs);
