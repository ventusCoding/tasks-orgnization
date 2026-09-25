import 'dart:convert';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/notifications/application/channel_catalog.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/data/local_schedule_store.dart';
import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/planner/planned_notification.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:meta/meta.dart';

/// Result of one scheduler run (diagnostics & coverage report).
@immutable
class SchedulerReport {
  const SchedulerReport({
    required this.osScheduled,
    required this.tracked,
    required this.cancelled,
    required this.scheduledNow,
    required this.platformCalls,
    required this.coverageUntil,
    required this.saturated,
    required this.budget,
  });

  static const empty = SchedulerReport(
    osScheduled: 0,
    tracked: 0,
    cancelled: 0,
    scheduledNow: 0,
    platformCalls: 0,
    coverageUntil: null,
    saturated: false,
    budget: ScheduleBudget.android,
  );

  /// OS requests alive after the run.
  final int osScheduled;
  final int tracked;
  final int cancelled;
  final int scheduledNow;
  final int platformCalls;
  final DateTime? coverageUntil;
  final bool saturated;
  final ScheduleBudget budget;
}

/// Makes the OS match the desired top-K of the plan with minimal platform calls (T7.2.09/10/17/19).
class LocalNotificationScheduler {
  LocalNotificationScheduler({
    required this.port,
    required this.store,
    required this.clock,
    required this.l10n,
    required this.handlers,
  });

  static final _log = AppLog.get('notifications.scheduler');

  final LocalNotificationsPort port;
  final LocalScheduleStore store;
  final Clock clock;
  final AppLocalizations Function() l10n;
  final List<NotificationActionHandler> Function() handlers;

  /// Window before firing in which the foreground silent channel replaces the normal one
  /// (Android, in-app banners on — T7.2.17).
  static const foregroundWindow = Duration(minutes: 15);

  Set<String> _registeredCategories = {};

  ScheduleBudget get budget => port.platform == 'ios' ? ScheduleBudget.ios : ScheduleBudget.android;

  /// Creates / refreshes Android channels for [profiles] (localized names; obsolete versions deleted).
  Future<void> ensureChannels(List<NotificationProfile> profiles) async {
    final l = l10n();
    final catalog = ChannelCatalog.channels(profiles, l);
    await port.ensureChannels(ChannelCatalog.groups(l), catalog.channels, delete: catalog.obsolete);
  }

  /// Registers iOS categories when the action combinations in use changed.
  Future<void> ensureCategories(Iterable<PlannedNotification> planned, {bool force = false}) async {
    final combos = {for (final p in planned) (p.actions, p.isNag)};
    final categories = ChannelCatalog.categories(combos, l10n(), handlers: handlers());
    final ids = {for (final c in categories) c.id};
    if (!force && ids.difference(_registeredCategories).isEmpty) return;
    _registeredCategories = ids;
    await port.setCategories(categories);
  }

  List<OsCategory> initialCategories() => ChannelCatalog.categories(const [], l10n(), handlers: handlers());

  /// Applies the plan. [exactAllowed]: Android exact alarms granted. [foreground] + [bannerInApp]:
  /// in-app banners replace system banners for imminent notifications.
  Future<SchedulerReport> apply(
    List<PlannedNotification> planned, {
    required bool exactAllowed,
    required bool foreground,
    required bool bannerInApp,
    required DateTime horizonEnd,
    bool authenticationRequired = false,
  }) async {
    final now = clock.nowUtc();
    final isAndroid = port.platform == 'android';
    final adjusted = [
      for (final p in planned)
        if (isAndroid && foreground && bannerInApp && p.fireAt.difference(now) < foregroundWindow)
          p.copyWith(channelId: ChannelCatalog.foregroundSilent)
        else
          p,
    ];
    await ensureCategories(adjusted);
    final l = l10n();
    final desired = ScheduleComputation.desired(
      adjusted,
      budget: budget,
      sentinelTitle: l.notifSaturationTitle,
      mergedTitle: l.notifMergedTitle,
    );
    final current = await store.all();
    final diff = ScheduleComputation.diff(current, desired, now);
    var calls = 0;
    var scheduledNow = 0;
    for (final e in diff.cancel) {
      try {
        await port.cancel(e.platformId, tag: e.dedupeKey);
        calls++;
      } on Object catch (err) {
        _log.warning('cancel failed', err);
      }
    }
    await store.remove([...diff.cancel.map((e) => e.dedupeKey), ...diff.remove.map((e) => e.dedupeKey)]);
    final existing = {for (final e in current) e.dedupeKey: e};
    final used = {
      for (final e in current)
        if (!diff.cancel.contains(e) && !diff.remove.contains(e)) e.platformId,
    };
    final entries = <ScheduleEntry>[];
    for (final d in diff.upsert) {
      final previous = existing[d.key];
      final id = previous?.platformId ?? PlatformIds.assign(d.key, used);
      used.add(id);
      final entry = ScheduleEntry(
        dedupeKey: d.key,
        platformId: id,
        fireAt: d.fireAt,
        targetKey: d.targetKey,
        kind: d.kind,
        os: d.os,
        hash: d.hash,
        scheduledAt: now,
        expiresAt: d.planned?.expiresAt,
        channelId: d.planned?.channelId,
        members: [for (final m in d.members) m.dedupeKey],
        reconciledAt: previous?.reconciledAt,
        inbox: d.planned?.deliverInbox ?? false,
        banner: d.planned?.deliverBanner ?? false,
        content: d.content,
      );
      if (d.os) {
        final request = _request(
          d,
          id,
          exactAllowed: exactAllowed,
          presentInForeground: !bannerInApp,
          authenticationRequired: authenticationRequired,
        );
        try {
          if (!d.fireAt.isAfter(now)) {
            await port.show(request);
            scheduledNow++;
          } else {
            await port.schedule(request);
          }
          calls++;
        } on Object catch (err) {
          _log.warning('schedule failed for ${d.kind}', err);
          continue;
        }
      }
      entries.add(entry);
    }
    await store.putAll(entries);
    final all = await store.all();
    return SchedulerReport(
      osScheduled: all.where((e) => e.os && e.fireAt.isAfter(now)).length,
      tracked: all.where((e) => !e.os && e.fireAt.isAfter(now)).length,
      cancelled: diff.cancel.length,
      scheduledNow: scheduledNow,
      platformCalls: calls,
      coverageUntil: ScheduleComputation.coverageUntil(desired, horizonEnd: horizonEnd),
      saturated: desired.any((d) => d.kind == ScheduleKind.sentinel),
      budget: budget,
    );
  }

  OsNotificationRequest _request(
    DesiredItem d,
    int id, {
    required bool exactAllowed,
    required bool presentInForeground,
    required bool authenticationRequired,
  }) {
    final l = l10n();
    final p = d.planned;
    if (p != null) {
      return OsNotificationRequest(
        id: id,
        title: p.title,
        body: p.body,
        fireAt: p.fireAt,
        channelId: p.channelId,
        payload: jsonEncode(p.payload),
        importance: p.importance,
        interruptionLevel: p.interruptionLevel,
        relevance: p.relevance,
        sound: p.sound,
        vibration: p.vibration,
        actions: ChannelCatalog.osActions(
          p.actions,
          l,
          handlers: handlers(),
          targetType: p.targetType,
          authenticationRequired: authenticationRequired,
        ),
        categoryId: ChannelCatalog.categoryIdFor(p.actions, nag: p.isNag),
        threadId: p.threadId,
        groupKey: 'dl.group.${p.section.wire}',
        silent: p.silent,
        sticky: p.sticky,
        timeoutAfter: p.sticky ? null : p.expiresAt.difference(p.fireAt),
        exact: exactAllowed,
        alarmClock: p.alarmStyle && exactAllowed,
        presentInForeground: presentInForeground,
        tag: p.dedupeKey,
      );
    }
    if (d.kind == ScheduleKind.merged) {
      final first = d.members.first;
      final importance = d.members.map((m) => m.importance).reduce((a, b) => a.rank >= b.rank ? a : b);
      return OsNotificationRequest(
        id: id,
        title: l.notifMergedTitle(d.members.length),
        body: d.members.map((m) => m.title).join(', '),
        fireAt: d.fireAt,
        channelId: first.channelId,
        payload: jsonEncode({
          'v': 1,
          'kind': ScheduleKind.merged,
          'dk': d.key,
          'link': AppLinks.inbox(),
          'mem': [for (final m in d.members) m.dedupeKey],
          'uid': first.userId,
        }),
        importance: importance,
        sound: first.sound,
        vibration: first.vibration,
        actions: ChannelCatalog.osActions(const [NotificationActionIds.open], l, handlers: const []),
        categoryId: ChannelCatalog.categoryIdFor(const [NotificationActionIds.open]),
        threadId: 'merged',
        exact: exactAllowed,
        presentInForeground: presentInForeground,
        tag: d.key,
      );
    }
    return OsNotificationRequest(
      id: id,
      title: l.notifSaturationTitle,
      body: l.notifSaturationBody,
      fireAt: d.fireAt,
      channelId: ChannelCatalog.system,
      payload: jsonEncode({'v': 1, 'kind': ScheduleKind.sentinel, 'dk': d.key, 'link': AppLinks.inbox()}),
      importance: NotificationImportance.low,
      interruptionLevel: InterruptionLevel.passive,
      sound: 'none',
      exact: exactAllowed,
      presentInForeground: presentInForeground,
    );
  }

  /// Snooze instance (reserved budget, T7.2.15). Returns null when the snooze limit is reached.
  Future<ScheduleEntry?> scheduleSnooze({
    required String originalKey,
    required DateTime until,
    required String title,
    required String? body,
    required Map<String, Object?> content,
    required NotificationPayload payload,
    required String channelId,
    required int maxSnoozes,
    required bool exactAllowed,
    required bool presentInForeground,
  }) async {
    final all = await store.all();
    final previous = all.where((e) => e.kind == ScheduleKind.snooze && asString(e.content['orig']) == originalKey).length;
    if (previous >= maxSnoozes) return null;
    final key = snoozeKeyFor(originalKey, previous + 1);
    final id = PlatformIds.assign(key, {for (final e in all) e.platformId});
    final snoozePayload = NotificationPayload.fromJson({...payload.toJson(), 'dk': key, 'bk': originalKey});
    final l = l10n();
    final request = OsNotificationRequest(
      id: id,
      title: title,
      body: body ?? l.notifBodySnoozed,
      fireAt: until,
      channelId: channelId,
      payload: snoozePayload.encode(),
      actions: ChannelCatalog.osActions(payload.actions, l, handlers: handlers(), targetType: payload.targetType),
      categoryId: ChannelCatalog.categoryIdFor(payload.actions),
      threadId: 'nag:$originalKey',
      exact: exactAllowed,
      presentInForeground: presentInForeground,
      tag: key,
    );
    await port.schedule(request);
    final entry = ScheduleEntry(
      dedupeKey: key,
      platformId: id,
      fireAt: until,
      targetKey: payload.targetKey ?? '*',
      kind: ScheduleKind.snooze,
      os: true,
      hash: key.substring(0, 16),
      scheduledAt: clock.nowUtc(),
      channelId: channelId,
      // The inbox row of the original instance is reused (snoozed_until); no new row.
      inbox: false,
      content: {...content, 'orig': originalKey},
    );
    await store.put(entry);
    return entry;
  }

  /// "Send test now" (T7.1.11): a real local notification in [delay].
  Future<void> showTest({
    required String title,
    required String? body,
    required String channelId,
    required List<String> actions,
    required String sound,
    required NotificationImportance importance,
    required InterruptionLevel interruptionLevel,
    Duration delay = const Duration(seconds: 5),
  }) async {
    final now = clock.nowUtc();
    final key = 'test:${now.microsecondsSinceEpoch}';
    final id = PlatformIds.assign(key, await store.usedPlatformIds());
    final l = l10n();
    await port.schedule(
      OsNotificationRequest(
        id: id,
        title: title,
        body: body,
        fireAt: now.add(delay),
        channelId: channelId,
        payload: jsonEncode({'v': 1, 'kind': ScheduleKind.test, 'dk': key, 'link': AppLinks.inbox()}),
        importance: importance,
        interruptionLevel: interruptionLevel,
        sound: sound,
        actions: ChannelCatalog.osActions(actions, l, handlers: handlers()),
        categoryId: ChannelCatalog.categoryIdFor(actions),
        presentInForeground: true,
      ),
    );
    await store.put(
      ScheduleEntry(
        dedupeKey: key,
        platformId: id,
        fireAt: now.add(delay),
        targetKey: '*',
        kind: ScheduleKind.test,
        os: true,
        hash: key,
        scheduledAt: now,
        inbox: false,
        banner: false,
      ),
    );
  }

  /// Cancels the rest of a nag chain (and snoozes) after an action / acknowledgement (T7.2.18).
  Future<int> cancelChain(String baseKey) async {
    final now = clock.nowUtc();
    var count = 0;
    final keys = <String>[];
    for (final e in await store.all()) {
      final chain = asString(e.content['bk']) ?? (e.kind == ScheduleKind.snooze ? asString(e.content['orig']) : null);
      final inChain = e.dedupeKey == baseKey || chain == baseKey;
      if (!inChain || !e.fireAt.isAfter(now)) continue;
      if (e.os) {
        await port.cancel(e.platformId, tag: e.dedupeKey);
        count++;
      }
      keys.add(e.dedupeKey);
    }
    await store.remove(keys);
    return count;
  }

  /// Removes delivered notifications of targets that are now closed (T7.2.20). [closed] holds
  /// `targetKey|occurrenceKey` pairs.
  Future<int> removeDelivered(Set<String> closed) async {
    if (closed.isEmpty) return 0;
    final now = clock.nowUtc();
    var count = 0;
    for (final e in await store.all()) {
      if (!e.os || e.fireAt.isAfter(now)) continue;
      final occ = asString(e.content['occ']) ?? '';
      if (closed.contains('${e.targetKey}|$occ') || closed.contains('${e.targetKey}|')) {
        await port.cancel(e.platformId, tag: e.dedupeKey);
        count++;
      }
    }
    return count;
  }

  /// Sign-out: clears every OS request and the schedule table.
  Future<void> clearAll() async {
    await port.cancelAll();
    await store.clear();
  }
}
