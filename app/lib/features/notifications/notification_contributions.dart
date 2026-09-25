import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:everslot/features/notifications/application/notification_registry.dart'
    show CallbackActionHandler, NotificationActionContext, NotificationActionHandler, NotificationActionResult;
export 'package:everslot/features/notifications/domain/notification_target.dart';

typedef NotificationSourceFactory = NotificationTargetSource Function(Ref ref);
typedef NotificationActionHandlerFactory = NotificationActionHandler Function(Ref ref);

/// What one feature contributes to the notification system.
class NotificationContribution {
  const NotificationContribution({this.sources = const [], this.actionHandlers = const []});

  final List<NotificationSourceFactory> sources;
  final List<NotificationActionHandlerFactory> actionHandlers;
}

/// FEATURE REGISTRATION POINT (see `features/notifications/README.md`).
///
/// Each feature appends ONE entry, e.g.
/// ```dart
/// NotificationContribution(
///   sources: [(ref) => PlannerNotificationSource(ref)],
///   actionHandlers: [(ref) => PlannerNotificationActions(ref)],
/// ),
/// ```
/// This list is read by the main isolate **and** by the background isolate that handles
/// notification actions while the app is killed, so registrations must not depend on widgets.
final List<NotificationContribution> notificationContributions = [];
