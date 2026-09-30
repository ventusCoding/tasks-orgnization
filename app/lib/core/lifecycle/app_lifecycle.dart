import 'dart:async';

import 'package:everslot/core/time/clock.dart';
import 'package:flutter/widgets.dart';

/// App lifecycle events (T1.3.04). Sync, notification re-planning, Today and the app lock listen here.
///
///  * [onResume] fires when the app returns to the foreground, at most once per [resumeDebounce]
///    (iOS/Android emit several `resumed` events around dialogs and permission prompts);
///  * [onPause] fires when it goes to the background (`paused`), [onDetached] when the engine detaches;
///  * [states] carries every distinct raw state (`inactive` and `hidden` too — the app-switcher
///    privacy cover of T8.3.09 needs them);
///  * [onReturn] fires at every return to the foreground (not debounced) with how long the app was
///    away — the app-lock timeout of T8.3.09 reads it.
class AppLifecycleService with WidgetsBindingObserver {
  AppLifecycleService({
    Clock? clock,
    WidgetsBinding? binding,
    this.resumeDebounce = const Duration(seconds: 2),
  }) : _clock = clock ?? const SystemClock(),
       _binding = binding ?? WidgetsBinding.instance {
    _binding.addObserver(this);
    _state = _binding.lifecycleState ?? AppLifecycleState.resumed;
  }

  final Clock _clock;
  final WidgetsBinding _binding;
  final Duration resumeDebounce;

  final _resumed = StreamController<void>.broadcast();
  final _paused = StreamController<void>.broadcast();
  final _detached = StreamController<void>.broadcast();
  final _states = StreamController<AppLifecycleState>.broadcast();
  final _returned = StreamController<Duration>.broadcast();

  DateTime? _lastResume;
  DateTime? _backgroundedAt;
  late AppLifecycleState _state;

  /// Emits when the app returns to the foreground (at most once per [resumeDebounce]).
  Stream<void> get onResume => _resumed.stream;

  /// Emits when the app moves to the background.
  Stream<void> get onPause => _paused.stream;

  Stream<void> get onDetached => _detached.stream;

  /// Emits how long the app was in the background each time it comes back ([Duration.zero] when it
  /// was only `inactive`, e.g. behind a system dialog).
  Stream<Duration> get onReturn => _returned.stream;

  /// Every distinct lifecycle state, in order.
  Stream<AppLifecycleState> get states => _states.stream;

  AppLifecycleState get state => _state;

  bool get isForeground => _state == AppLifecycleState.resumed;

  /// When the app last left the foreground (`hidden`/`paused`), or null while it is in the
  /// foreground (`inactive` alone — a system dialog — does not count as leaving).
  DateTime? get backgroundedAt => _backgroundedAt;

  /// How long the app has been in the background so far; [Duration.zero] in the foreground.
  Duration get awayFor {
    final since = _backgroundedAt;
    return since == null ? Duration.zero : _clock.nowUtc().difference(since);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == _state) return;
    _state = state;
    _states.add(state);
    switch (state) {
      case AppLifecycleState.resumed:
        final now = _clock.nowUtc();
        final away = awayFor;
        _backgroundedAt = null;
        _returned.add(away);
        final last = _lastResume;
        if (last == null || now.difference(last) >= resumeDebounce) {
          _lastResume = now;
          _resumed.add(null);
        }
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        _backgroundedAt ??= _clock.nowUtc();
        if (state == AppLifecycleState.paused) _paused.add(null);
      case AppLifecycleState.detached:
        _detached.add(null);
      case AppLifecycleState.inactive:
        break;
    }
  }

  void dispose() {
    _binding.removeObserver(this);
    unawaited(_resumed.close());
    unawaited(_paused.close());
    unawaited(_detached.close());
    unawaited(_states.close());
    unawaited(_returned.close());
  }
}
