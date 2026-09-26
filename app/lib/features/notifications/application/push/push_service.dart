import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/notifications/application/push/push_messaging_port.dart';

/// Debounced `app.report_device_state` (T7.2.11 / T7.4.02). Keys (supabase/README.md):
/// `push_token, push_enabled, local_notifications_enabled, local_coverage_until, schedule_rev,
/// local_repeating_rules, capabilities, last_seen_at, time_zone`. Offline: the pending state is
/// kept and sent on the next successful flush.
class DeviceStateReporter {
  DeviceStateReporter({
    required this.api,
    required this.deviceId,
    required this.clock,
    this.debounce = const Duration(seconds: 30),
    this.onRevoked,
  });

  static final _log = AppLog.get('notifications.device');

  /// Null in local-only mode (state is still tracked for diagnostics).
  final SyncApi? Function() api;
  final String deviceId;
  final Clock clock;
  final Duration debounce;
  final void Function()? onRevoked;

  final Map<String, Object?> _pending = {};
  Map<String, Object?> lastSent = const {};
  DateTime? lastSentAt;
  Timer? _timer;

  Map<String, Object?> get pending => Map.unmodifiable(_pending);

  void report(Map<String, Object?> state, {bool immediate = false}) {
    _pending.addAll(state);
    _timer?.cancel();
    if (immediate) {
      unawaited(flush());
    } else {
      _timer = Timer(debounce, () => unawaited(flush()));
    }
  }

  Future<bool> flush() async {
    _timer?.cancel();
    final client = api();
    if (client == null || _pending.isEmpty) return false;
    final state = Map<String, Object?>.from(_pending);
    try {
      final revoked = await client.reportDeviceState(deviceId, state);
      for (final k in state.keys) {
        if (_pending[k] == state[k]) _pending.remove(k);
      }
      lastSent = {...lastSent, ...state};
      lastSentAt = clock.nowUtc();
      if (revoked) onRevoked?.call();
      return true;
    } on Object catch (e) {
      _log.info('device state report deferred: $e');
      return false;
    }
  }

  void dispose() => _timer?.cancel();
}

/// Device-side FCM handling (T7.4.01 / T7.4.10) — only started when Firebase and Supabase are
/// configured. Foreground messages become in-app banners + inbox rows (no OS banner on iOS when
/// banners are on), `{"type":"sync"}` data messages trigger a pull, taps open the deep link.
class PushService {
  PushService({
    required this.port,
    required this.reporter,
    required this.onSync,
    required this.onForegroundReminder,
    required this.onOpened,
  });

  static final _log = AppLog.get('notifications.push');

  final PushMessagingPort port;
  final DeviceStateReporter reporter;
  final void Function() onSync;
  final Future<void> Function(PushMessage message) onForegroundReminder;
  final Future<void> Function(PushMessage message) onOpened;

  final List<StreamSubscription<Object?>> _subs = [];
  String? token;
  bool started = false;

  Future<void> start({required bool bannerInApp}) async {
    if (started) return;
    started = true;
    try {
      await port.setForegroundPresentation(
        alert: !bannerInApp,
        badge: true,
        sound: !bannerInApp,
      );
      token = await port.getToken();
      if (token != null)
        reporter.report({
          'push_token': token,
          'push_enabled': true,
        }, immediate: true);
    } on Object catch (e) {
      _log.warning('FCM token unavailable', e);
    }
    _subs
      ..add(
        port.onTokenRefresh.listen((t) {
          token = t;
          reporter.report({
            'push_token': t,
            'push_enabled': true,
          }, immediate: true);
        }),
      )
      ..add(
        port.onMessage.listen((m) => unawaited(handle(m, foreground: true))),
      )
      ..add(port.onMessageOpenedApp.listen((m) => unawaited(onOpened(m))));
    final initial = await port.getInitialMessage();
    if (initial != null) await onOpened(initial);
  }

  /// Routes one message by `data.type`.
  Future<void> handle(PushMessage m, {required bool foreground}) async {
    switch (m.type) {
      case 'sync':
        onSync();
      case 'cancel':
        break; // local notifications are cancelled by the replan triggered by the sync pull
      default:
        if (foreground) await onForegroundReminder(m);
    }
  }

  /// Sign-out / account deletion: delete the token and null it server-side (T7.4.01).
  Future<void> signOut() async {
    try {
      await port.deleteToken();
    } on Object catch (e) {
      _log.fine('deleteToken failed', e);
    }
    token = null;
    reporter.report({
      'push_token': null,
      'push_enabled': false,
    }, immediate: true);
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    started = false;
  }
}
