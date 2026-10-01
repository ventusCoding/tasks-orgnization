import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reactive notification capabilities (T7.2.04): re-checked on every resume; permission requests
/// always go through a primer first (T7.2.05, presentation layer).
final notificationCapabilitiesProvider = NotifierProvider<NotificationCapabilitiesController, NotificationCapabilities>(
  NotificationCapabilitiesController.new,
);

class NotificationCapabilitiesController extends Notifier<NotificationCapabilities> {
  LocalNotificationsPort get _port => ref.read(localNotificationsPortProvider);

  /// Primers already shown this session (never twice per session).
  final Set<String> primersShown = {};

  @override
  NotificationCapabilities build() {
    final sub = ref.watch(lifecycleProvider).onResume.listen((_) => unawaited(refresh()));
    ref.onDispose(sub.cancel);
    unawaited(Future<void>.microtask(refresh));
    return NotificationCapabilities.unknown;
  }

  Future<NotificationCapabilities> refresh() async {
    if (!ref.mounted) return NotificationCapabilities.unknown;
    try {
      final caps = await _port.capabilities();
      // The provider may have been disposed (sign-out, tests) while the OS answered.
      if (!ref.mounted) return caps;
      if (caps != state) state = caps;
    } on Object {
      // keep the previous value
    }
    return ref.mounted ? state : NotificationCapabilities.unknown;
  }

  /// OS permission prompt (call only after a primer). Android 13+ POST_NOTIFICATIONS / iOS
  /// alert+badge+sound (optionally provisional).
  Future<bool> requestNotifications({bool provisional = false}) async {
    final granted = await _port.requestPermission(provisional: provisional);
    await refresh();
    return granted;
  }

  /// Android 14+: opens the exact-alarm settings page (in context, after the precise primer).
  Future<bool> requestExactAlarms() async {
    final granted = await _port.requestExactAlarms();
    await refresh();
    return granted;
  }

  Future<bool> openSettings() => _port.openSettings();
}
