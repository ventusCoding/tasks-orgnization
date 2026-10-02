import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart' show notificationTextsProvider;
import 'package:everslot/features/notifications/notification_contributions.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/occurrence_resolver.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/planner_notification_targets.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

/// Makes task occurrences notifiable (`features/notifications/README.md` §2): one target per
/// occurrence whose anchors fall in the replan window, resolved with the same resolver as the
/// views (overrides, moves, cancellations, derived statuses). Registered statically in
/// `notification_contributions.dart`, so it also runs in the background isolate — it only reads
/// database-backed providers, lazily.
class PlannerNotificationSource implements NotificationTargetSource, DigestFactsSource {
  PlannerNotificationSource(this._ref);

  final Ref _ref;

  @override
  String get section => NotificationSection.planner.wire;

  /// Writes to `tasks`, `task_occurrences` and `time_entries` already trigger replans; targets
  /// depend on nothing else.
  @override
  Stream<void> get changes => const Stream<void>.empty();

  /// Unscheduled (backlog) tasks for *Plan tomorrow*.
  @override
  Future<Map<String, int>> digestFacts() async => {
    'backlog': (await _ref.read(plannerQueriesProvider).unscheduled()).length,
  };

  @override
  Future<List<NotificationTarget>> targetsBetween(DateTime fromUtc, DateTime toUtc) async {
    final zones = _ref.read(zoneResolverProvider);
    final zone = _ref.read(deviceZoneProvider);
    final queries = _ref.read(plannerQueriesProvider);
    // The window is in instants; the resolver works on the viewer's wall clock. One extra day
    // on each side covers zone offsets; the anchor filter below trims the result.
    final from = zones.toLocal(fromUtc, zone).date.minusDays(1).atStartOfDay;
    final to = zones.toLocal(toUtc, zone).date.plusDays(2).atStartOfDay;
    final data = await queries.loadRange(from, to);
    if (data.tasks.isEmpty) return const [];
    final result = _ref
        .read(occurrenceResolverProvider)
        .resolve(
          tasks: data.tasks,
          records: data.records,
          from: from,
          to: to,
          viewerZone: zone,
          now: _ref.read(clockProvider).nowUtc(),
          settings: _ref.read(plannerSettingsProvider).resolver,
        );
    bool inWindow(DateTime? t) => t != null && !t.isBefore(fromUtc) && !t.isAfter(toUtc);
    final relevant = [
      for (final o in result.occurrences)
        if (inWindow(o.startInstant) || inWindow(o.endInstant)) o,
    ];
    if (relevant.isEmpty) return const [];
    return PlannerNotificationTargets.build(
      relevant,
      zones: zones,
      viewerZone: zone,
      categoryNames: await queries.categoryNames(),
      missedGraceMinutes: _ref.read(plannerSettingsProvider).missedGraceMinutes,
      neighbours: result.occurrences,
    );
  }

  /// Open = the task is live and active and the occurrence is neither done, skipped nor
  /// cancelled (same rule as the server guard `task_occurrence_open`).
  @override
  Future<bool> guardOpen(NotificationTarget t) async {
    if (t.type != NotificationTargetType.task) return true;
    final key = t.occurrenceKey;
    final task = await _ref.read(plannerQueriesProvider).task(t.id);
    if (task == null || task.status != TaskStatus.active) return false;
    if (key == null) return true;
    final o = await PlannerNotificationActions.occurrence(_ref.read, t.id, key);
    return o != null && PlannerNotificationTargets.isOpen(o);
  }
}

/// Planner actions from notifications, banners and inbox rows (README §3): *Done*, *Skip*,
/// *Start* (timer tasks start their timer; others go in progress) and *Stop*. Writes go through
/// the same repositories as the occurrence sheet (`cause = notification`, `source =
/// notification`) and are idempotent: a done occurrence stays done, a running timer is not
/// started twice. Safe in the background isolate (database-backed providers only).
class PlannerNotificationActions implements NotificationActionHandler {
  PlannerNotificationActions(Ref _);

  @override
  Set<NotificationTargetType> get targetTypes => const {NotificationTargetType.task};

  @override
  Set<String> get actionIds => const {
    NotificationActionIds.done,
    NotificationActionIds.skip,
    NotificationActionIds.start,
    NotificationActionIds.stop,
    NotificationActionIds.reschedule,
    NotificationActionIds.extend,
  };

  static const cause = 'notification';
  static const source = 'notification';

  /// The resolved occurrence [key] of [taskId] in the device zone, or null when gone.
  static Future<ResolvedOccurrence?> occurrence(
    T Function<T>(ProviderListenable<T> provider) read,
    String taskId,
    String key,
  ) => lookupOccurrence(
    queries: read(plannerQueriesProvider),
    resolver: read(occurrenceResolverProvider),
    viewerZone: read(deviceZoneProvider),
    settings: read(plannerSettingsProvider).resolver,
    now: read(clockProvider).nowUtc(),
    taskId: taskId,
    key: key,
  );

  @override
  Future<NotificationActionResult> handle(NotificationActionContext c) async {
    final taskId = c.targetId;
    if (taskId == null) return const NotificationActionResult.failed(null);
    final key = c.occurrenceKey ?? await _oneOffKey(c, taskId);
    final l10n = c.read(notificationTextsProvider).l10n;
    if (key == null) return NotificationActionResult.failed(l10n.tasksNotifGone);
    final o = await occurrence(c.read, taskId, key);
    if (o == null || o.task.status != TaskStatus.active) {
      return NotificationActionResult.failed(l10n.tasksNotifGone);
    }
    final repo = c.read(occurrencesRepositoryProvider);
    final status = o.status;
    final cancelled = o.record?.isCancelled ?? false;
    final closed = cancelled || status == OccurrenceStatus.done || status == OccurrenceStatus.skipped;
    switch (c.actionId) {
      case NotificationActionIds.done:
        if (status == OccurrenceStatus.done && !cancelled) return NotificationActionResult.ok;
        if (cancelled) return NotificationActionResult.failed(l10n.tasksNotifGone);
        await repo.markDone(taskId, key, source: source, cause: cause);
      case NotificationActionIds.skip:
        if (closed) return NotificationActionResult.ok;
        await repo.skip(taskId, key, source: source, cause: cause);
      case NotificationActionIds.start:
        if (closed) return NotificationActionResult.failed(l10n.tasksNotifAlreadyClosed);
        await repo.start(
          taskId,
          key,
          policy: c.read(plannerSettingsProvider).timerPolicy,
          source: source,
          cause: cause,
        );
        // Starting does not finish the occurrence: its end reminders stay armed.
        return const NotificationActionResult(markActed: false);
      case NotificationActionIds.stop:
        if (closed) return NotificationActionResult.ok;
        await repo.stop(taskId, key, cause: cause);
      case NotificationActionIds.extend:
        // Timer-end alert: give the running occurrence 10 more minutes (the replan re-arms the alert).
        if (closed) return NotificationActionResult.ok;
        await c
            .read(tasksRepositoryProvider)
            .editOccurrence(taskId, key, duration: (o.durationMinutes) + 10, source: source);
        return const NotificationActionResult(markActed: false);
      case NotificationActionIds.reschedule:
        // Foreground action: the task opens on its quick-reschedule sheet (+1 h / tonight / tomorrow).
        if (closed) return NotificationActionResult.failed(l10n.tasksNotifAlreadyClosed);
        return NotificationActionResult(
          openLink: AppLinks.task(taskId, occurrenceKey: key, reschedule: true),
          markActed: false,
        );
      default:
        return NotificationActionResult(
          openLink: c.payload.deepLink ?? AppLinks.task(taskId, occurrenceKey: key),
          markActed: false,
        );
    }
    return NotificationActionResult.ok;
  }

  /// A one-off task's occurrence key is its start (task wall clock).
  static Future<String?> _oneOffKey(NotificationActionContext c, String taskId) async {
    final task = await c.read(plannerQueriesProvider).task(taskId);
    final start = task?.startLocal;
    if (task == null || start == null || task.isRecurring) return null;
    return task.isAllDay ? start.date.toIso() : start.toIso();
  }
}
