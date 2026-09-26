import 'dart:async';

import 'package:everslot/features/notifications/notification_contributions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

/// Where an action came from.
enum ActionOrigin { system, systemBackground, banner, inbox, push }

/// Everything a feature action handler needs (T7.2.14).
class NotificationActionContext {
  NotificationActionContext({
    required this.actionId,
    required this.payload,
    required this.origin,
    required this.now,
    required this.read,
    this.input,
  });

  /// `done`, `skip`, `log_value`, … (see [NotificationActionIds]).
  final String actionId;

  /// Text typed in the notification (log value, craving intensity), if any.
  final String? input;
  final NotificationPayload payload;
  final ActionOrigin origin;
  final DateTime now;

  /// Reads providers (works in the main and the background isolate).
  final T Function<T>(ProviderListenable<T> provider) read;

  bool get fromBackground => origin == ActionOrigin.systemBackground;
  NotificationTargetType? get targetType => payload.targetType;
  String? get targetId => payload.targetId;
  String? get occurrenceKey => payload.occurrenceKey;
}

/// Outcome of a handled action.
class NotificationActionResult {
  const NotificationActionResult({this.success = true, this.message, this.openLink, this.markActed = true});

  static const ok = NotificationActionResult();

  /// Input invalid / target gone — a follow-up notification explains [message].
  const NotificationActionResult.failed(this.message) : success = false, openLink = null, markActed = false;

  final bool success;

  /// Localized, user-facing explanation (shown as a follow-up notification or snackbar).
  final String? message;

  /// Router path to open afterwards (foreground only).
  final String? openLink;

  /// Record `acted_at` / `action` on the inbox row (and stop the nag chain).
  final bool markActed;
}

/// Feature-specific action implementation (e.g. planner: `done`, `skip`, `start`; habits:
/// `log_value`). Register it in `notification_contributions.dart` (see README). Handlers MUST be
/// idempotent and write through `SyncWriter` with activity `source = 'notification'`.
abstract interface class NotificationActionHandler {
  /// Target types handled; null = any.
  Set<NotificationTargetType>? get targetTypes;

  /// Action ids handled.
  Set<String> get actionIds;

  Future<NotificationActionResult> handle(NotificationActionContext context);
}

/// A handler built from a closure (convenient for small features and tests).
class CallbackActionHandler implements NotificationActionHandler {
  CallbackActionHandler({required this.actionIds, required this.onHandle, this.targetTypes});

  @override
  final Set<String> actionIds;

  @override
  final Set<NotificationTargetType>? targetTypes;

  final Future<NotificationActionResult> Function(NotificationActionContext context) onHandle;

  @override
  Future<NotificationActionResult> handle(NotificationActionContext context) => onHandle(context);
}

/// Runtime registry (dynamic registration from startup code, tests, debug tools). Static
/// registration lives in `notificationContributions` so the background isolate sees it too.
class NotificationRegistry {
  final List<NotificationTargetSource> _sources = [];
  final List<NotificationActionHandler> _handlers = [];
  final _changes = StreamController<void>.broadcast();

  List<NotificationTargetSource> get sources => List.unmodifiable(_sources);
  List<NotificationActionHandler> get actionHandlers => List.unmodifiable(_handlers);

  /// Emits when sources/handlers are (un)registered.
  Stream<void> get changes => _changes.stream;

  void registerSource(NotificationTargetSource source) {
    _sources.add(source);
    _changes.add(null);
  }

  void unregisterSource(NotificationTargetSource source) {
    _sources.remove(source);
    _changes.add(null);
  }

  void registerActionHandler(NotificationActionHandler handler) {
    _handlers.add(handler);
    _changes.add(null);
  }

  void unregisterActionHandler(NotificationActionHandler handler) {
    _handlers.remove(handler);
    _changes.add(null);
  }

  void dispose() => unawaited(_changes.close());
}

final notificationRegistryProvider = Provider<NotificationRegistry>((ref) {
  final registry = NotificationRegistry();
  ref.onDispose(registry.dispose);
  return registry;
});

/// Sources of the static contributions — created once per container (stable instances, so
/// subscriptions to their `changes` stay valid).
final _contributedSourcesProvider = Provider<List<NotificationTargetSource>>(
  (ref) => [
    for (final c in notificationContributions)
      for (final factory in c.sources) factory(ref),
  ],
);

final _contributedHandlersProvider = Provider<List<NotificationActionHandler>>(
  (ref) => [
    for (final c in notificationContributions)
      for (final factory in c.actionHandlers) factory(ref),
  ],
);

/// Every registered target source: static contributions + runtime registry (recomputed when the
/// registry changes).
final notificationTargetSourcesProvider = Provider<List<NotificationTargetSource>>((ref) {
  final registry = ref.watch(notificationRegistryProvider);
  final sub = registry.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return [...ref.watch(_contributedSourcesProvider), ...registry.sources];
});

/// Every feature action handler: static contributions + runtime registry.
final notificationActionHandlersProvider = Provider<List<NotificationActionHandler>>((ref) {
  final registry = ref.watch(notificationRegistryProvider);
  final sub = registry.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return [...ref.watch(_contributedHandlersProvider), ...registry.actionHandlers];
});

/// Finds the handler for an action on a target type (most specific first).
NotificationActionHandler? findActionHandler(
  List<NotificationActionHandler> handlers,
  String actionId,
  NotificationTargetType? type,
) {
  NotificationActionHandler? generic;
  for (final h in handlers) {
    if (!h.actionIds.contains(actionId)) continue;
    if (h.targetTypes == null) {
      generic ??= h;
    } else if (type != null && h.targetTypes!.contains(type)) {
      return h;
    }
  }
  return generic;
}
