import 'dart:async';
import 'dart:io';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/formatting.dart';
import 'package:everslot/features/notifications/application/channel_catalog.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/planner/application/planner_notifications.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/planner_service.dart' show plannerL10nProvider;
import 'package:everslot/features/planner/domain/timer_surface.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:live_activities/live_activities.dart';

/// Where the running timer is shown outside the app (T8.2.10).
abstract interface class TimerSurfacePort {
  Future<void> show(TimerSurface surface);
  Future<void> clear();
}

/// Android: an ongoing, silent notification with a system chronometer and *Stop* / *Done*. The
/// buttons go through the notification action dispatcher (planner handler) — in the background
/// isolate when the app was killed — which closes the time entry.
class NotificationTimerSurface implements TimerSurfacePort {
  NotificationTimerSurface(this._port, this._l10n, this._timeLabel, this._userId, {bool Function()? hideContent})
    : _hideContent = hideContent ?? _never;

  static bool _never() => false;

  final LocalNotificationsPort _port;
  final AppLocalizations _l10n;

  /// Local wall-clock label of an instant ("21:00").
  final String Function(DateTime utc) _timeLabel;
  final String? _userId;

  /// "Hide notification content" (T8.3.10): generic title, no task name or times.
  final bool Function() _hideContent;

  /// The request for [surface] at [now] (pure: tested without a platform).
  OsNotificationRequest request(TimerSurface surface, DateTime now, {String? endLabel}) {
    final l = _l10n;
    final hide = _hideContent();
    final body = hide || surface.plannedEnd == null
        ? null
        : (surface.isOver(now) ? l.timerSurfaceOver : l.timerSurfacePlannedUntil(endLabel ?? ''));
    return OsNotificationRequest(
      id: TimerSurface.notificationId,
      title: hide
          ? l.notifRedactedTitle
          : (surface.others == 0 ? surface.title : l.timerSurfaceMore(surface.title, surface.others)),
      body: body,
      channelId: ChannelCatalog.quiet,
      payload: NotificationPayload(
        dedupeKey: surface.dedupeKey,
        targetType: NotificationTargetType.task,
        targetId: surface.taskId,
        occurrenceKey: surface.occurrenceKey,
        section: NotificationSection.planner,
        deepLink: AppLinks.task(surface.taskId, occurrenceKey: surface.occurrenceKey),
        actions: const [NotificationActionIds.stop, NotificationActionIds.done],
        userId: _userId,
      ).encode(),
      sticky: true,
      silent: true,
      chronometerFrom: surface.startedAt,
      actions: [
        OsAction(id: NotificationActionIds.stop, title: l.notifActionStop),
        OsAction(id: NotificationActionIds.done, title: l.actionDone),
      ],
    );
  }

  @override
  Future<void> show(TimerSurface surface) async {
    final end = surface.plannedEnd;
    await _port.show(request(surface, DateTime.now().toUtc(), endLabel: end == null ? null : _timeLabel(end)));
  }

  @override
  Future<void> clear() => _port.cancel(TimerSurface.notificationId);
}

/// iOS 16.1+: a Live Activity (lock screen + Dynamic Island) rendered by the widget extension
/// from these keys (`ios/EverslotWidgets/TimerActivity.swift`).
class LiveActivityTimerSurface implements TimerSurfacePort {
  LiveActivityTimerSurface(this._plugin, this._appGroup, this._l10n, {bool Function()? hideContent})
    : _hideContent = hideContent ?? NotificationTimerSurface._never;

  final LiveActivities _plugin;
  final String _appGroup;
  final AppLocalizations _l10n;
  final bool Function() _hideContent;
  var _ready = false;

  static Map<String, dynamic> data(TimerSurface s, AppLocalizations l, {bool hideContent = false}) => {
    'title': hideContent ? l.notifRedactedTitle : (s.others == 0 ? s.title : l.timerSurfaceMore(s.title, s.others)),
    'startedAt': s.startedAt.millisecondsSinceEpoch / 1000,
    'plannedEnd': s.plannedEnd == null ? 0 : s.plannedEnd!.millisecondsSinceEpoch / 1000,
    'taskId': s.taskId,
    'occurrenceKey': s.occurrenceKey,
    'link': AppLinks.external(AppLinks.task(s.taskId, occurrenceKey: s.occurrenceKey)).toString(),
    'stopLink': Uri.parse('everslot://do/timer-stop')
        .replace(queryParameters: {'task': s.taskId, 'occ': s.occurrenceKey})
        .toString(),
    'stopLabel': l.notifActionStop,
    'overLabel': l.timerSurfaceOver,
  };

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.init(appGroupId: _appGroup, requestAndroidNotificationPermission: false);
    _ready = true;
  }

  @override
  Future<void> show(TimerSurface surface) async {
    await _init();
    if (!await _plugin.areActivitiesEnabled()) return;
    await _plugin.createOrUpdateActivity(TimerSurface.activityId, data(surface, _l10n, hideContent: _hideContent()));
  }

  @override
  Future<void> clear() async {
    await _init();
    await _plugin.endAllActivities();
  }
}

/// Keeps the surface in sync with the running timers (start, stop, title / plan changes).
class TimerSurfaceService {
  TimerSurfaceService(this._read, this._surface);

  final T Function<T>(ProviderListenable<T> provider) _read;
  final TimerSurfacePort _surface;
  TimerSurface? _shown;
  var _cleared = false;
  static final _log = AppLog.get('planner.timer_surface');

  Future<void> update(List<RunningTimer> running) async {
    final infos = <RunningTimerInfo>[];
    for (final t in running) {
      final key = t.entry.occurrenceKey;
      if (key == null) continue;
      final o = await PlannerNotificationActions.occurrence(_read, t.entry.taskId, key);
      infos.add(
        RunningTimerInfo(
          taskId: t.entry.taskId,
          occurrenceKey: key,
          title: t.title,
          startedAt: t.entry.startedAt,
          plannedEnd: o?.endInstant,
        ),
      );
    }
    final next = TimerSurface.of(infos);
    try {
      if (next == null) {
        if (_shown != null || !_cleared) await _surface.clear();
        _cleared = true;
      } else if (next != _shown) {
        await _surface.show(next);
        _cleared = false;
      }
      _shown = next;
    } on Object catch (e) {
      _log.info('timer surface unavailable: $e');
    }
  }

  /// Re-renders the shown surface (e.g. after "Hide notification content" changed).
  Future<void> refresh() async {
    final shown = _shown;
    if (shown == null) return;
    try {
      await _surface.show(shown);
    } on Object catch (e) {
      _log.info('timer surface unavailable: $e');
    }
  }
}

final timerSurfacePortProvider = Provider<TimerSurfacePort?>((ref) {
  final l10n = ref.watch(plannerL10nProvider);
  if (Platform.isAndroid) {
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(l10n.localeName, use24h: prefs.use24h, l10n: l10n);
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(deviceZoneProvider);
    return NotificationTimerSurface(
      ref.watch(localNotificationsPortProvider),
      l10n,
      (utc) => format.timeOf(zones.toLocal(utc, zone)),
      ref.watch(currentUserIdProvider),
      hideContent: () => ref.read(notificationSettingsProvider).hideContent,
    );
  }
  if (Platform.isIOS) {
    final appGroup = ref.watch(envProvider).isDev ? 'group.app.everslot.dev' : 'group.app.everslot';
    return LiveActivityTimerSurface(
      LiveActivities(),
      appGroup,
      l10n,
      hideContent: () => ref.read(notificationSettingsProvider).hideContent,
    );
  }
  return null;
});

/// Startup hook: mirrors running timers to the lock screen while the app runs; the surface itself
/// survives the app being killed (ongoing notification / Live Activity).
void startTimerSurface(ProviderContainer container) {
  final port = container.read(timerSurfacePortProvider);
  if (port == null) return;
  final service = TimerSurfaceService(container.read, port);
  container.listen<AsyncValue<List<RunningTimer>>>(runningTimersProvider, (_, next) {
    final value = next.value;
    if (value != null) unawaited(service.update(value));
  }, fireImmediately: true);
  container.listen<bool>(
    notificationSettingsProvider.select((s) => s.hideContent),
    (_, _) => unawaited(service.refresh()),
  );
}
