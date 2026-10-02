import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// The alarm screen's own ring (T7.2.25): a generated two-tone beep looped on the alarm stream,
/// its volume rising from [startVolume] to full over [rampDuration]. Used while a mission keeps
/// the alarm going (the notification's own sound stops when it is opened).
abstract interface class AlarmSound {
  Future<void> start({required bool ramp});
  Future<void> stop();
}

/// One alarm beep cycle as a 16-bit mono PCM WAV (880 Hz / 660 Hz, 0.2 s each, 0.4 s silence).
Uint8List alarmBeepWav({int sampleRate = 16000}) {
  final samples = <int>[];
  void tone(double hz, double seconds) {
    final n = (sampleRate * seconds).round();
    for (var i = 0; i < n; i++) {
      final fade = math.min(1, math.min(i, n - i) / (sampleRate * 0.01)); // 10 ms edges, no clicks
      samples.add((math.sin(2 * math.pi * hz * i / sampleRate) * 0.8 * fade * 32767).round());
    }
  }

  tone(880, 0.2);
  tone(660, 0.2);
  tone(0, 0.4);
  final data = ByteData(44 + samples.length * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

/// Volume after [elapsed] of a ramp from [start] to 1 over [duration].
double rampVolumeAt(Duration elapsed, {double start = 0.1, Duration duration = const Duration(seconds: 30)}) {
  if (elapsed >= duration) return 1;
  return start + (1 - start) * elapsed.inMilliseconds / duration.inMilliseconds;
}

class PlayerAlarmSound implements AlarmSound {
  AudioPlayer? _player;
  Timer? _ramp;

  @override
  Future<void> start({required bool ramp}) async {
    if (_player != null) return;
    final player = _player = AudioPlayer();
    final file = File('${(await getTemporaryDirectory()).path}/everslot_alarm.wav');
    if (!file.existsSync()) await file.writeAsBytes(alarmBeepWav());
    await player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.alarm,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.gainTransient,
          stayAwake: true,
        ),
        iOS: AudioContextIOS(),
      ),
    );
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(ramp ? rampVolumeAt(Duration.zero) : 1);
    await player.play(DeviceFileSource(file.path));
    if (ramp) {
      final started = DateTime.now();
      _ramp = Timer.periodic(const Duration(seconds: 1), (t) {
        final v = rampVolumeAt(DateTime.now().difference(started));
        unawaited(player.setVolume(v));
        if (v >= 1) t.cancel();
      });
    }
  }

  @override
  Future<void> stop() async {
    _ramp?.cancel();
    _ramp = null;
    final player = _player;
    _player = null;
    await player?.stop();
    await player?.dispose();
  }
}

/// Tests override it with a silent fake.
final alarmSoundProvider = Provider<AlarmSound>((ref) {
  final sound = PlayerAlarmSound();
  ref.onDispose(() => unawaited(sound.stop()));
  return sound;
});
