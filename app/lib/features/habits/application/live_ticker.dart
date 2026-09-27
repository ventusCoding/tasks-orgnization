import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One shared ticker for every live counter (T5.3.04): a single timer that runs only while at least
/// one counter listens and the app is in the foreground. Each tick carries "now" read from the
/// injected clock — values are derived from instants, so there is no drift after time in the
/// background and nothing is written to the database.
class SharedTicker extends ChangeNotifier {
  SharedTicker(this._clock, {this.period = const Duration(seconds: 1), this.autoStart = true})
    : _now = _clock.nowUtc();

  final Clock _clock;
  final Duration period;

  /// When false the timer never starts (tests drive [tick] manually).
  final bool autoStart;

  DateTime _now;
  Timer? _timer;
  int _listeners = 0;
  bool _foreground = true;
  bool _disposed = false;

  DateTime get now => _now;

  /// Whether the timer is running (tests & diagnostics).
  bool get isRunning => _timer != null;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _listeners++;
    _now = _clock.nowUtc();
    _sync();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (_listeners > 0) _listeners--;
    _sync();
  }

  /// App lifecycle: no ticks in the background.
  void setForeground(bool foreground) {
    _foreground = foreground;
    if (foreground) tick();
    _sync();
  }

  /// Advances to the clock's current time and notifies listeners.
  void tick() {
    if (_disposed) return;
    _now = _clock.nowUtc();
    notifyListeners();
  }

  void _sync() {
    final shouldRun = autoStart && _listeners > 0 && _foreground && !_disposed;
    if (shouldRun && _timer == null) {
      _timer = Timer.periodic(period, (_) => tick());
    } else if (!shouldRun && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

final sharedTickerProvider = Provider<SharedTicker>((ref) {
  final ticker = SharedTicker(ref.watch(clockProvider));
  final lifecycle = ref.watch(lifecycleProvider);
  final subs = [
    lifecycle.onPause.listen((_) => ticker.setForeground(false)),
    lifecycle.onResume.listen((_) => ticker.setForeground(true)),
  ];
  ref.onDispose(() {
    for (final s in subs) {
      unawaited(s.cancel());
    }
    ticker.dispose();
  });
  return ticker;
});
