import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/presentation/in_app_banner_host.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _wired = Expando<bool>('notifications-startup');

/// Startup task (registered in `startup/startup_tasks.dart`): seeds the built-in profiles and
/// default rules, starts every replan trigger, reconciles the inbox, handles a cold start from a
/// notification, starts push when configured, and installs the in-app banner overlay once the
/// root navigator exists. Fast: the engine starts unawaited. Account switches restart the engine.
Future<void> startNotifications(ProviderContainer container) async {
  final engine = container.read(notificationsEngineProvider);
  if (_wired[container] != true) {
    _wired[container] = true;
    container.listen<String>(currentUserIdProvider, (previous, next) {
      if (next.isNotEmpty && next != previous) unawaited(engine.start());
    });
    NotificationOverlay.install(container);
  }
  unawaited(engine.start());
}
