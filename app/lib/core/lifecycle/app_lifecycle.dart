import 'dart:async';

import 'package:flutter/widgets.dart';

/// Debounced app lifecycle events (T1.3.04). Sync, notification re-planning and Today listen here.
class AppLifecycleService with WidgetsBindingObserver {
  AppLifecycleService() {
    WidgetsBinding.instance.addObserver(this);
  }

  final _resumed = StreamController<void>.broadcast();
  final _paused = StreamController<void>.broadcast();
  DateTime? _lastResume;

  /// Emits when the app returns to the foreground (at most once per 2 s).
  Stream<void> get onResume => _resumed.stream;
  Stream<void> get onPause => _paused.stream;

  AppLifecycleState _state = AppLifecycleState.resumed;
  bool get isForeground => _state == AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _state = state;
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastResume == null || now.difference(_lastResume!) > const Duration(seconds: 2)) {
        _lastResume = now;
        _resumed.add(null);
      }
    } else if (state == AppLifecycleState.paused) {
      _paused.add(null);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_resumed.close());
    unawaited(_paused.close());
  }
}
