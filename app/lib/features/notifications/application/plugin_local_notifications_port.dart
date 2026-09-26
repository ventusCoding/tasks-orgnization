import 'package:everslot/core/logging/log.dart';
import 'package:everslot/design_system/theme.dart';
import 'package:everslot/features/notifications/application/background_entry.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart'
    as nt;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/timezone.dart' as tz;

/// [LocalNotificationsPort] over `flutter_local_notifications` 22.x (T7.2.01).
///
/// - Scheduling uses UTC instants (`TZDateTime` in UTC): the planner already resolved zones/DST.
/// - Android: `exactAllowWhileIdle` when exact alarms are granted, else `inexactAllowWhileIdle`
///   (`alarmClock` for the Alarm profile), channels per section × profile, ≤ 3 actions, text input
///   actions, tag = dedupe key (pushes replace the local entry).
/// - iOS: categories registered at initialization (re-registered on change), interruption levels,
///   foreground presentation off when in-app banners are on, thread ids for grouping.
/// - Small icon: the monochrome `@drawable/ic_stat_everslot` (kept from R8 resource shrinking by
///   `res/raw/keep.xml`) tinted with the brand accent.
class PluginLocalNotificationsPort implements LocalNotificationsPort {
  PluginLocalNotificationsPort({fln.FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? fln.FlutterLocalNotificationsPlugin();

  static final _log = AppLog.get('notifications.port');
  static const androidIcon = '@drawable/ic_stat_everslot';

  final fln.FlutterLocalNotificationsPlugin _plugin;
  void Function(OsResponse response)? _onResponse;
  Map<String, OsChannel> _channels = const {};

  @override
  String get platform => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => 'other',
  };

  fln.AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        fln.AndroidFlutterLocalNotificationsPlugin
      >();

  fln.IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        fln.IOSFlutterLocalNotificationsPlugin
      >();

  static OsResponse mapResponse(
    fln.NotificationResponse r, {
    bool background = false,
  }) => OsResponse(
    id: r.id,
    actionId:
        r.notificationResponseType ==
            fln.NotificationResponseType.selectedNotificationAction
        ? r.actionId
        : null,
    input: r.input,
    payload: r.payload,
    background: background,
  );

  @override
  Future<void> initialize({
    required List<OsCategory> categories,
    required void Function(OsResponse) onResponse,
  }) async {
    _onResponse = onResponse;
    await _plugin.initialize(
      settings: fln.InitializationSettings(
        android: const fln.AndroidInitializationSettings(androidIcon),
        iOS: fln.DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [for (final c in categories) _category(c)],
        ),
      ),
      onDidReceiveNotificationResponse: (r) =>
          _onResponse?.call(mapResponse(r)),
      onDidReceiveBackgroundNotificationResponse:
          notificationBackgroundResponse,
    );
  }

  @override
  Future<void> setCategories(List<OsCategory> categories) async {
    if (platform != 'ios' || _onResponse == null) return;
    await initialize(categories: categories, onResponse: _onResponse!);
  }

  fln.DarwinNotificationCategory _category(
    OsCategory c,
  ) => fln.DarwinNotificationCategory(
    c.id,
    actions: [
      for (final a in c.actions)
        a.textInput
            ? fln.DarwinNotificationAction.text(
                a.id,
                a.title,
                buttonTitle: a.buttonTitle ?? a.title,
                placeholder: a.placeholder,
                options: {
                  if (a.authenticationRequired)
                    fln.DarwinNotificationActionOption.authenticationRequired,
                },
              )
            : fln.DarwinNotificationAction.plain(
                a.id,
                a.title,
                options: {
                  if (a.foreground)
                    fln.DarwinNotificationActionOption.foreground,
                  if (a.authenticationRequired)
                    fln.DarwinNotificationActionOption.authenticationRequired,
                },
              ),
    ],
    options: {
      if (c.customDismiss)
        fln.DarwinNotificationCategoryOption.customDismissAction,
    },
  );

  static fln.Importance _importance(nt.NotificationImportance i) => switch (i) {
    nt.NotificationImportance.min => fln.Importance.min,
    nt.NotificationImportance.low => fln.Importance.low,
    nt.NotificationImportance.normal => fln.Importance.defaultImportance,
    nt.NotificationImportance.high => fln.Importance.high,
    nt.NotificationImportance.urgent => fln.Importance.max,
  };

  static fln.Priority _priority(nt.NotificationImportance i) => switch (i) {
    nt.NotificationImportance.min => fln.Priority.min,
    nt.NotificationImportance.low => fln.Priority.low,
    nt.NotificationImportance.normal => fln.Priority.defaultPriority,
    nt.NotificationImportance.high => fln.Priority.high,
    nt.NotificationImportance.urgent => fln.Priority.max,
  };

  static Int64List? _vibration(String key) => switch (key) {
    'short' => Int64List.fromList([0, 200]),
    'long' => Int64List.fromList([0, 600, 200, 600]),
    _ => null,
  };

  /// Curated sounds (T7.2.02): raw resources `res/raw/<key>` on Android, `<key>.caf` on iOS.
  /// Until the assets are bundled every curated key falls back to the default sound.
  static const bundledSounds = <String>{};

  @override
  Future<void> ensureChannels(
    List<OsChannelGroup> groups,
    List<OsChannel> channels, {
    Set<String> delete = const {},
  }) async {
    _channels = {for (final c in channels) c.id: c};
    final android = _android;
    if (android == null) return;
    for (final g in groups) {
      await android.createNotificationChannelGroup(
        fln.AndroidNotificationChannelGroup(g.id, g.name),
      );
    }
    for (final c in channels) {
      await android.createNotificationChannel(
        fln.AndroidNotificationChannel(
          c.id,
          c.name,
          description: c.description,
          groupId: c.groupId,
          importance: _importance(c.importance),
          playSound: c.sound != 'none',
          sound: bundledSounds.contains(c.sound)
              ? fln.RawResourceAndroidNotificationSound(c.sound)
              : null,
          enableVibration: c.vibration != 'none',
          vibrationPattern: _vibration(c.vibration),
          showBadge: c.showBadge,
        ),
      );
    }
    for (final id in delete) {
      await android.deleteNotificationChannel(channelId: id);
    }
  }

  fln.NotificationDetails _details(OsNotificationRequest r) {
    final channel = _channels[r.channelId];
    final actions = r.actions.take(3).toList();
    return fln.NotificationDetails(
      android: fln.AndroidNotificationDetails(
        r.channelId,
        channel?.name ?? r.channelId,
        channelDescription: channel?.description,
        importance: _importance(channel?.importance ?? r.importance),
        priority: _priority(r.importance),
        playSound: !r.silent && r.sound != 'none',
        sound: bundledSounds.contains(r.sound)
            ? fln.RawResourceAndroidNotificationSound(r.sound)
            : null,
        enableVibration: !r.silent && r.vibration != 'none',
        vibrationPattern: _vibration(r.vibration),
        groupKey: r.groupKey,
        category: r.alarmClock
            ? fln.AndroidNotificationCategory.alarm
            : fln.AndroidNotificationCategory.reminder,
        visibility: fln.NotificationVisibility.private,
        color: AppTheme.seed,
        ongoing: r.sticky,
        autoCancel: !r.sticky,
        silent: r.silent,
        timeoutAfter: r.timeoutAfter?.inMilliseconds,
        tag: r.tag,
        subText: r.subtitle,
        number: r.badgeNumber,
        actions: [
          for (final a in actions)
            fln.AndroidNotificationAction(
              a.id,
              a.title,
              showsUserInterface: a.foreground,
              inputs: a.textInput
                  ? [fln.AndroidNotificationActionInput(label: a.placeholder)]
                  : const <fln.AndroidNotificationActionInput>[],
            ),
        ],
      ),
      iOS: fln.DarwinNotificationDetails(
        presentAlert: r.presentInForeground,
        presentBanner: r.presentInForeground,
        presentSound: r.presentInForeground && !r.silent,
        presentList: true,
        presentBadge: true,
        sound: bundledSounds.contains(r.sound) ? '${r.sound}.caf' : null,
        badgeNumber: r.badgeNumber,
        subtitle: r.subtitle,
        threadIdentifier: r.threadId,
        categoryIdentifier: r.categoryId,
        interruptionLevel: switch (r.interruptionLevel) {
          nt.InterruptionLevel.passive => fln.InterruptionLevel.passive,
          nt.InterruptionLevel.active => fln.InterruptionLevel.active,
          nt.InterruptionLevel.timeSensitive =>
            fln.InterruptionLevel.timeSensitive,
        },
      ),
    );
  }

  @override
  Future<void> schedule(OsNotificationRequest request) async {
    final at = request.fireAt;
    if (at == null ||
        !at.isAfter(DateTime.now().toUtc().add(const Duration(seconds: 1)))) {
      await show(request);
      return;
    }
    await _plugin.zonedSchedule(
      id: request.id,
      title: request.title,
      body: request.body,
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: _details(request),
      androidScheduleMode: request.alarmClock
          ? fln.AndroidScheduleMode.alarmClock
          : (request.exact
                ? fln.AndroidScheduleMode.exactAllowWhileIdle
                : fln.AndroidScheduleMode.inexactAllowWhileIdle),
      payload: request.payload,
    );
  }

  @override
  Future<void> show(OsNotificationRequest request) => _plugin.show(
    id: request.id,
    title: request.title,
    body: request.body,
    notificationDetails: _details(request),
    payload: request.payload,
  );

  @override
  Future<void> cancel(int id, {String? tag}) =>
      _plugin.cancel(id: id, tag: tag);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<List<PendingOsRequest>> pending() async => [
    for (final p in await _plugin.pendingNotificationRequests())
      PendingOsRequest(p.id, title: p.title, payload: p.payload),
  ];

  @override
  Future<List<ActiveOsNotification>> active() async {
    try {
      return [
        for (final a in await _plugin.getActiveNotifications())
          ActiveOsNotification(
            a.id,
            tag: a.tag,
            payload: a.payload,
            channelId: a.channelId,
          ),
      ];
    } on Object catch (e) {
      _log.fine('getActiveNotifications unavailable', e);
      return const [];
    }
  }

  @override
  Future<OsResponse?> launchResponse() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (details == null ||
        !details.didNotificationLaunchApp ||
        response == null)
      return null;
    return mapResponse(response);
  }

  @override
  Future<NotificationCapabilities> capabilities() async {
    try {
      final android = _android;
      if (android != null) {
        final enabled = await android.areNotificationsEnabled() ?? false;
        final exact = await android.canScheduleExactNotifications() ?? false;
        final channels =
            await android.getNotificationChannels() ??
            const <fln.AndroidNotificationChannel>[];
        return NotificationCapabilities(
          platform: 'android',
          notifications: enabled,
          exactAlarm: exact,
          timeSensitive: true,
          badge: true,
          blockedChannels: {
            for (final c in channels)
              if (c.importance == fln.Importance.none) c.id,
          },
        );
      }
      final ios = _ios;
      if (ios != null) {
        final options = await ios.checkPermissions();
        return NotificationCapabilities(
          platform: 'ios',
          notifications: options?.isEnabled ?? false,
          provisional: options?.isProvisionalEnabled ?? false,
          exactAlarm: true,
          // The plugin doesn't expose `timeSensitiveSetting`; the capability is declared in the
          // entitlements, so it is assumed available while notifications are allowed.
          timeSensitive: options?.isEnabled ?? false,
          badge: options?.isBadgeEnabled ?? false,
          determined: options != null,
        );
      }
    } on Object catch (e) {
      _log.warning('capability query failed', e);
    }
    return NotificationCapabilities(platform: platform);
  }

  @override
  Future<bool> requestPermission({bool provisional = false}) async {
    final android = _android;
    if (android != null)
      return await android.requestNotificationsPermission() ?? false;
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            provisional: provisional,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<bool> requestExactAlarms() async =>
      await _android?.requestExactAlarmsPermission() ?? true;

  @override
  Future<bool> openSettings() async {
    final android = _android;
    if (android != null)
      return await android.openAppNotificationSettings() ?? false;
    return await _ios?.openAppNotificationSettings() ?? false;
  }

  @override
  Future<void> setBadge(int count) async {
    // iOS badges are carried by scheduled notifications (`badgeNumber`); Android launchers derive
    // them from active notifications. A dedicated badge plugin is not bundled (T7.3.06 note).
  }
}
