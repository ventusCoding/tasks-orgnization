import 'dart:async';

import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/presentation/diagnostics_screen.dart';
import 'package:everslot/features/notifications/presentation/notifications_settings_page.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The notification page a link points at ([NotificationLinks]), or null for app routes.
Widget? notificationPageFor(String link) => switch (Uri.tryParse(link)?.path) {
  NotificationLinks.settings => const NotificationsSettingsPage(),
  NotificationLinks.diagnostics => const NotificationDiagnosticsScreen(),
  _ => null,
};

/// Opens a notification deep link: the module's own pages directly (the app shell doesn't route
/// them yet), everything else through the router.
void openNotificationLink(
  NavigatorState navigator,
  String link, {
  GoRouter? router,
}) {
  final page = notificationPageFor(link);
  if (page != null) {
    unawaited(navigator.push<void>(MaterialPageRoute(builder: (_) => page)));
    return;
  }
  final r = router ?? GoRouter.maybeOf(navigator.context);
  if (r != null) unawaited(r.push<void>(link));
}
