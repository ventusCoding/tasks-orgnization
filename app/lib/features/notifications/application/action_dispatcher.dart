import 'dart:async';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/notifications/application/capabilities_service.dart';
import 'package:everslot/features/notifications/application/channel_catalog.dart';
import 'package:everslot/features/notifications/application/inbox_reconciler.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_pipeline.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// What the UI should do after an action / tap.
@immutable
class ActionDispatchResult {
  const ActionDispatchResult({
    this.openLink,
    this.alreadyDone = false,
    this.message,
    this.duplicate = false,
    this.snoozedUntil,
  });

  static const none = ActionDispatchResult();

  final String? openLink;

  /// The target is already done / deleted ("Already done", T7.2.16).
  final bool alreadyDone;
  final String? message;
  final bool duplicate;
  final DateTime? snoozedUntil;
}

/// One handler for OS responses (foreground callback and the background isolate), in-app banner
/// buttons, inbox row actions and pushes — identical behaviour everywhere (T7.2.14, T7.3.04).
class NotificationActionDispatcher {
  NotificationActionDispatcher(
    this.read, {
    this.onReplanNeeded,
    this.onTargetsDirty,
  });

  final ProviderReader read;

  /// Foreground: debounced replan request. Background: null → the pipeline runs directly.
  final void Function(String reason)? onReplanNeeded;

  /// Marks target keys dirty for the next server job upload (P1, [7.4]).
  final void Function(Set<String> targetKeys)? onTargetsDirty;

  static final _log = AppLog.get('notifications.actions');

  /// OS response → tap or action.
  Future<ActionDispatchResult> handleResponse(OsResponse response) async {
    final payload = NotificationPayload.tryDecode(response.payload);
    if (payload == null) return ActionDispatchResult.none;
    final origin = response.background
        ? ActionOrigin.systemBackground
        : ActionOrigin.system;
    if (response.isTap) return handleTap(payload, origin: origin);
    // iOS custom dismiss action.
    final action =
        response.actionId == 'com.apple.UNNotificationDismissActionIdentifier'
        ? NotificationActionIds.dismiss
        : response.actionId!;
    return handleAction(action, payload, input: response.input, origin: origin);
  }

  /// Tap on a notification / banner / inbox row: mark opened (acknowledges nags), open the target.
  Future<ActionDispatchResult> handleTap(
    NotificationPayload p, {
    ActionOrigin origin = ActionOrigin.system,
  }) async {
    if (p.kind == ScheduleKind.merged ||
        p.kind == ScheduleKind.sentinel ||
        p.kind == ScheduleKind.test) {
      if (p.kind == ScheduleKind.merged) await _reconcile(p.members.toSet());
      return ActionDispatchResult(openLink: p.deepLink ?? AppLinks.inbox());
    }
    await _reconcile({p.dedupeKey});
    final inbox = read(inboxRepositoryProvider);
    await inbox.markOpened(Ids.inbox(p.dedupeKey));
    await read(localSchedulerProvider).cancelChain(p.chainKey);
    final open = await guardOpen(p);
    _afterWrite(p, 'tap');
    return ActionDispatchResult(openLink: p.deepLink, alreadyDone: !open);
  }

  /// Action button (OS, banner, inbox) — idempotent per `(dedupeKey, action)`.
  Future<ActionDispatchResult> handleAction(
    String actionId,
    NotificationPayload p, {
    String? input,
    ActionOrigin origin = ActionOrigin.system,
    int? snoozeMinutes,
  }) async {
    if (actionId == NotificationActionIds.open ||
        actionId == NotificationActionIds.tap) {
      return handleTap(p, origin: origin);
    }
    await _reconcile({p.dedupeKey});
    final inbox = read(inboxRepositoryProvider);
    final inboxId = Ids.inbox(p.dedupeKey);
    final row = await inbox.byId(inboxId);
    if (row != null &&
        row.actedAt != null &&
        row.action == actionId &&
        actionId != NotificationActionIds.snooze) {
      return const ActionDispatchResult(duplicate: true);
    }
    final now = read(clockProvider).nowUtc();
    switch (actionId) {
      case NotificationActionIds.snooze:
        return snooze(p, minutes: snoozeMinutes);
      case NotificationActionIds.markRead:
        await inbox.markRead([inboxId]);
        return ActionDispatchResult.none;
      case NotificationActionIds.dismiss:
        await inbox.markActed(inboxId, NotificationActionIds.dismiss);
        await read(localSchedulerProvider).cancelChain(p.chainKey);
        _afterWrite(p, 'dismiss');
        return ActionDispatchResult.none;
      case NotificationActionIds.muteRule:
        if (p.ruleId != null) {
          await read(notificationMutesRepositoryProvider).mute(
            targetType: 'rule',
            targetId: p.ruleId,
            until: _tomorrowMidnight(now),
            reason: 'notification',
          );
        }
        await inbox.markActed(inboxId, actionId);
        await read(localSchedulerProvider).cancelChain(p.chainKey);
        _afterWrite(p, 'mute');
        return ActionDispatchResult(
          message: read(notificationTextsProvider).l10n.notifMutedSnack,
        );
    }
    final handler = findActionHandler(
      read(notificationActionHandlersProvider),
      actionId,
      p.targetType,
    );
    if (handler == null) {
      // No feature handler yet: open the target so the user can act in the app.
      await inbox.markOpened(inboxId);
      return ActionDispatchResult(openLink: p.deepLink);
    }
    NotificationActionResult result;
    try {
      result = await handler.handle(
        NotificationActionContext(
          actionId: actionId,
          payload: p,
          origin: origin,
          now: now,
          read: read,
          input: input,
        ),
      );
    } on Object catch (e, st) {
      _log.warning('action $actionId failed', e, st);
      result = const NotificationActionResult.failed(null);
    }
    if (result.markActed) {
      await inbox.markActed(inboxId, actionId);
      await read(localSchedulerProvider).cancelChain(p.chainKey);
    }
    if (!result.success &&
        result.message != null &&
        origin == ActionOrigin.systemBackground) {
      await _followUp(p, result.message!);
    }
    _afterWrite(p, 'action');
    return ActionDispatchResult(
      openLink: result.openLink,
      message: result.message,
    );
  }

  /// Snooze (T7.2.15): first preset from the notification, any preset from the app. The snooze
  /// is a new local instance in the reserved budget; the inbox row gets `snoozed_until`.
  Future<ActionDispatchResult> snooze(
    NotificationPayload p, {
    int? minutes,
    DateTime? until,
  }) async {
    final settings = read(notificationSettingsProvider);
    final now = read(clockProvider).nowUtc();
    final chosen =
        minutes ??
        (p.snoozeOptions.isNotEmpty
            ? p.snoozeOptions.first
            : (settings.snoozePresets.isNotEmpty
                  ? settings.snoozePresets.first
                  : 10));
    final at = until ?? now.add(Duration(minutes: chosen));
    await _reconcile({p.dedupeKey});
    final inbox = read(inboxRepositoryProvider);
    final inboxId = Ids.inbox(p.dedupeKey);
    final row = await inbox.byId(inboxId);
    final entry = await read(localScheduleStoreProvider).byKey(p.dedupeKey);
    final scheduler = read(localSchedulerProvider);
    final l = read(notificationTextsProvider).l10n;
    if (await scheduler.snoozeCount(p.dedupeKey) >= settings.maxSnoozes) {
      return ActionDispatchResult(message: l.notifSnoozeLimit);
    }
    await scheduler.cancelChain(p.chainKey);
    final caps = read(notificationCapabilitiesProvider);
    final scheduled = await scheduler.scheduleSnooze(
      originalKey: p.dedupeKey,
      until: at,
      title: row?.title ?? asString(entry?.content['t']) ?? l.notifBodySnoozed,
      body: row?.body ?? asString(entry?.content['b']),
      content: entry?.content ?? const {},
      payload: p,
      channelId: entry?.channelId ?? ChannelCatalog.system,
      maxSnoozes: settings.maxSnoozes,
      exactAllowed: caps.exactAlarm || !caps.determined,
      presentInForeground: !settings.bannerInApp,
    );
    if (scheduled == null)
      return ActionDispatchResult(message: l.notifSnoozeLimit);
    if (row != null) {
      await inbox.setSnoozedUntil(inboxId, at);
      await inbox.markActed(inboxId, NotificationActionIds.snooze);
    }
    _afterWrite(p, 'snooze');
    return ActionDispatchResult(snoozedUntil: at);
  }

  /// Wake a snoozed row now (cancels the snooze instance, T7.3.08).
  Future<void> wakeNow(String dedupeKey) async {
    final inbox = read(inboxRepositoryProvider);
    await inbox.setSnoozedUntil(Ids.inbox(dedupeKey), null);
    final store = read(localScheduleStoreProvider);
    final port = read(localNotificationsPortProvider);
    for (final e in await store.all()) {
      if (e.kind == ScheduleKind.snooze &&
          asString(e.content['orig']) == dedupeKey) {
        await port.cancel(e.platformId, tag: e.dedupeKey);
        await store.remove([e.dedupeKey]);
      }
    }
  }

  /// Re-checks a target with its source (false when done / deleted).
  Future<bool> guardOpen(NotificationPayload p) async {
    final type = p.targetType;
    final id = p.targetId;
    if (type == null || id == null) return true;
    final section = p.section ?? NotificationSection.system;
    for (final source in read(notificationTargetSourcesProvider)) {
      if (source.section != section.wire) continue;
      try {
        return await source.guardOpen(
          NotificationTarget(
            type: type,
            id: id,
            section: section,
            title: '',
            occurrenceKey: p.occurrenceKey,
          ),
        );
      } on Object {
        return true;
      }
    }
    return true;
  }

  Future<void> _reconcile(Set<String> keys) async {
    final reconciler = InboxReconciler(
      store: read(localScheduleStoreProvider),
      inbox: read(inboxRepositoryProvider),
      clock: read(clockProvider),
    );
    await reconciler.reconcile(onlyKeys: keys);
  }

  Future<void> _followUp(NotificationPayload p, String message) async {
    try {
      final key = 'err:${p.dedupeKey}';
      await read(localNotificationsPortProvider).show(
        OsNotificationRequest(
          id: PlatformIds.hash(key),
          title: message,
          channelId: ChannelCatalog.system,
          payload: NotificationPayload(
            dedupeKey: key,
            deepLink: p.deepLink,
            kind: ScheduleKind.test,
          ).encode(),
        ),
      );
    } on Object catch (e) {
      _log.fine('follow-up notification failed', e);
    }
  }

  void _afterWrite(NotificationPayload p, String reason) {
    final key = p.targetKey;
    if (key != null) onTargetsDirty?.call({key});
    onReplanNeeded?.call('action:$reason');
  }

  DateTime _tomorrowMidnight(DateTime now) {
    final zones = read(zoneResolverProvider);
    final zone = read(deviceZoneProvider);
    final tomorrow = zones.toLocal(now, zone).date.plusDays(1);
    return zones.resolve(LocalDateTime(tomorrow, LocalTime.midnight), zone).utc;
  }
}
