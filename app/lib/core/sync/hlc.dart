import 'package:everslot/core/time/clock.dart';

/// Hybrid logical clock (T1.4.03): physical milliseconds + counter + device id, encoded as a
/// fixed-width string that sorts correctly byte-by-byte (SQLite BINARY, Postgres `COLLATE "C"`):
///
///     "<15-digit unix ms>:<5-digit counter>:<device id>"
///
/// `now()` never goes backwards and never goes below the highest timestamp observed from the
/// server, so a device with a slow clock stops losing conflicts after one sync.
class Hlc {
  Hlc({required this.deviceId, required Clock clock, String? initialState})
    : _clock = clock {
    if (initialState != null && initialState.isNotEmpty) {
      final parsed = tryParse(initialState);
      if (parsed != null) {
        _lastMs = parsed.ms;
        _counter = parsed.counter;
      }
    }
  }

  final String deviceId;
  final Clock _clock;
  int _lastMs = 0;
  int _counter = 0;

  /// Next timestamp for a local edit.
  String now() {
    final physical = _clock.nowUtc().millisecondsSinceEpoch;
    if (physical > _lastMs) {
      _lastMs = physical;
      _counter = 0;
    } else {
      _counter++;
      if (_counter > 99999) {
        _lastMs++;
        _counter = 0;
      }
    }
    return format(_lastMs, _counter, deviceId);
  }

  /// Timestamp for an automatic write triggered at [scheduledAt] (arch §6.6 automatic writes).
  /// Does not advance the clock: later user edits always win.
  String at(DateTime scheduledAt) =>
      format(scheduledAt.toUtc().millisecondsSinceEpoch, 0, deviceId);

  /// Merge a timestamp seen from the server.
  void observe(String remote) {
    final parsed = tryParse(remote);
    if (parsed == null) return;
    final nowMs = _clock.nowUtc().millisecondsSinceEpoch;
    // Ignore absurd future values (the server clamps to +5 min anyway).
    if (parsed.ms > nowMs + const Duration(minutes: 5).inMilliseconds) return;
    if (parsed.ms > _lastMs || (parsed.ms == _lastMs && parsed.counter > _counter)) {
      _lastMs = parsed.ms;
      _counter = parsed.counter;
    }
  }

  /// Serializable state (persisted in `sync_state.hlc`).
  String get state => format(_lastMs, _counter, deviceId);

  static String format(int ms, int counter, String deviceId) =>
      '${ms.toString().padLeft(15, '0')}:${counter.toString().padLeft(5, '0')}:$deviceId';

  static ({int ms, int counter, String device})? tryParse(String value) {
    final parts = value.split(':');
    if (parts.length < 3) return null;
    final ms = int.tryParse(parts[0]);
    final counter = int.tryParse(parts[1]);
    if (ms == null || counter == null) return null;
    return (ms: ms, counter: counter, device: parts.sublist(2).join(':'));
  }
}
