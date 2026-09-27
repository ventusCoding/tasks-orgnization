import 'package:everslot/features/checklists/application/checklist_notifications.dart';
import 'package:everslot/features/habits/application/habit_notifications.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/planner/application/planner_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:everslot/features/notifications/application/notification_registry.dart'
    show
        ActionOrigin,
        CallbackActionHandler,
        NotificationActionContext,
        NotificationActionHandler,
        NotificationActionResult,
        notificationRegistryProvider;
export 'package:everslot/features/notifications/domain/notification_actions.dart'
    show NotificationActionIds, NotificationPayload;
export 'package:everslot/features/notifications/domain/notification_target.dart';

typedef NotificationSourceFactory = NotificationTargetSource Function(Ref ref);
typedef NotificationActionHandlerFactory = NotificationActionHandler Function(
  Ref ref,
);

/// What one feature contributes to the notification system.
class NotificationContribution {
  const NotificationContribution({
    this.sources = const [],
    this.actionHandlers = const [],
  });

  /// One factory per section the feature feeds (`planner`, `checklists`, `habits`, `quit`).
  final List<NotificationSourceFactory> sources;

  /// Handlers of the feature's actions (`done`, `skip`, `log_value`, …).
  final List<NotificationActionHandlerFactory> actionHandlers;
}

/// FEATURE REGISTRATION POINT (see `features/notifications/README.md`).
///
/// Each feature appends ONE entry (and one import), e.g.
/// ```dart
/// NotificationContribution(
///   sources: [PlannerNotificationSource.new],
///   actionHandlers: [PlannerNotificationActions.new],
/// ),
/// ```
/// This list is read by the main isolate **and** by the background isolate that handles
/// notification actions while the app is killed, so registrations must not depend on widgets.
/// Factories receive the `Ref` of a long-lived provider: keep it and use `ref.read` lazily inside
/// `targetsBetween` / `handle` (never `ref.watch` in the factory).
final List<NotificationContribution> notificationContributions = [
  NotificationContribution(
    sources: [ChecklistsNotificationSource.new],
    actionHandlers: [ChecklistNotificationActions.new],
  ),
  NotificationContribution(
    sources: [HabitsNotificationSource.new, QuitNotificationSource.new],
    actionHandlers: [HabitNotificationActions.new],
  ),
  NotificationContribution(
    sources: [PlannerNotificationSource.new],
    actionHandlers: [PlannerNotificationActions.new],
  ),
];
