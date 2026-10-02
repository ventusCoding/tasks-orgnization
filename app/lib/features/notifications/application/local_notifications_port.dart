import 'dart:async';

import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart' show RepeatMatch;
import 'package:meta/meta.dart';

/// Device notification capabilities (T7.2.04), reported to `devices.capabilities`.
@immutable
class NotificationCapabilities {
  const NotificationCapabilities({
    this.platform = 'other',
    this.notifications = false,
    this.provisional = false,
    this.exactAlarm = false,
    this.timeSensitive = false,
    this.fullScreenIntent = false,
    this.badge = false,
    this.blockedChannels = const {},
    this.determined = true,
  });

  static const unknown = NotificationCapabilities(determined: false);

  /// android | ios | other
  final String platform;
  final bool notifications;
  final bool provisional;
  final bool exactAlarm;
  final bool timeSensitive;
  final bool fullScreenIntent;
  final bool badge;
  final Set<String> blockedChannels;

  /// False before the first OS query (or when the user was never asked on iOS).
  final bool determined;

  bool get isIos => platform == 'ios';
  bool get isAndroid => platform == 'android';

  Map<String, Object?> toJson() => {
    'notifications': notifications,
    'provisional': provisional,
    'exactAlarm': exactAlarm,
    'timeSensitive': timeSensitive,
    'fullScreenIntent': fullScreenIntent,
    'badge': badge,
    if (blockedChannels.isNotEmpty) 'blockedChannels': blockedChannels.toList()..sort(),
  };

  NotificationCapabilities copyWith({
    bool? notifications,
    bool? exactAlarm,
    bool? provisional,
    bool? determined,
    bool? fullScreenIntent,
  }) => NotificationCapabilities(
    platform: platform,
    notifications: notifications ?? this.notifications,
    provisional: provisional ?? this.provisional,
    exactAlarm: exactAlarm ?? this.exactAlarm,
    timeSensitive: timeSensitive,
    fullScreenIntent: fullScreenIntent ?? this.fullScreenIntent,
    badge: badge,
    blockedChannels: blockedChannels,
    determined: determined ?? this.determined,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationCapabilities &&
      other.platform == platform &&
      other.notifications == notifications &&
      other.provisional == provisional &&
      other.exactAlarm == exactAlarm &&
      other.timeSensitive == timeSensitive &&
      other.fullScreenIntent == fullScreenIntent &&
      other.badge == badge &&
      other.determined == determined &&
      other.blockedChannels.length == blockedChannels.length &&
      other.blockedChannels.containsAll(blockedChannels);

  @override
  int get hashCode => Object.hash(platform, notifications, provisional, exactAlarm, timeSensitive, badge, determined);
}

/// A notification action button.
@immutable
class OsAction {
  const OsAction({
    required this.id,
    required this.title,
    this.textInput = false,
    this.placeholder,
    this.buttonTitle,
    this.foreground = false,
    this.authenticationRequired = false,
  });

  final String id;
  final String title;
  final bool textInput;
  final String? placeholder;
  final String? buttonTitle;

  /// Brings the app to the foreground (open / reschedule / unhandled actions).
  final bool foreground;
  final bool authenticationRequired;

  @override
  bool operator ==(Object other) =>
      other is OsAction &&
      other.id == id &&
      other.title == title &&
      other.textInput == textInput &&
      other.foreground == foreground;

  @override
  int get hashCode => Object.hash(id, title, textInput, foreground);
}

/// iOS notification category (registered up front, T7.2.03).
@immutable
class OsCategory {
  const OsCategory({required this.id, required this.actions, this.customDismiss = false});

  final String id;
  final List<OsAction> actions;

  /// Deliver a dismiss callback (stops nag chains, T7.2.18).
  final bool customDismiss;
}

@immutable
class OsChannelGroup {
  const OsChannelGroup(this.id, this.name);

  final String id;
  final String name;
}

/// Android channel (immutable importance/sound/vibration → versioned ids, T7.2.02).
@immutable
class OsChannel {
  const OsChannel({
    required this.id,
    required this.name,
    required this.importance,
    this.description,
    this.groupId,
    this.sound = 'default',
    this.vibration = 'default',
    this.showBadge = true,
    this.alarm = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? groupId;
  final NotificationImportance importance;
  final String sound;
  final String vibration;
  final bool showBadge;

  /// Android: the alarm audio stream (`USAGE_ALARM`) — rings through silent where the OS allows.
  final bool alarm;
}

/// One OS notification request (scheduled or shown now).
@immutable
class OsNotificationRequest {
  const OsNotificationRequest({
    required this.id,
    required this.title,
    required this.channelId,
    required this.payload,
    this.body,
    this.fireAt,
    this.importance = NotificationImportance.normal,
    this.interruptionLevel = InterruptionLevel.active,
    this.relevance = 0.5,
    this.sound = 'default',
    this.vibration = 'default',
    this.actions = const [],
    this.categoryId,
    this.threadId,
    this.groupKey,
    this.silent = false,
    this.sticky = false,
    this.timeoutAfter,
    this.exact = true,
    this.alarmClock = false,
    this.fullScreen = false,
    this.presentInForeground = false,
    this.tag,
    this.badgeNumber,
    this.subtitle,
    this.repeat,
    this.repeatZone,
    this.groupSummary = false,
    this.lines = const [],
  });

  final int id;
  final String title;
  final String? body;

  /// UTC instant; null = show now.
  final DateTime? fireAt;
  final String channelId;
  final String payload;
  final NotificationImportance importance;
  final InterruptionLevel interruptionLevel;
  final double relevance;
  final String sound;
  final String vibration;
  final List<OsAction> actions;
  final String? categoryId;
  final String? threadId;
  final String? groupKey;
  final bool silent;
  final bool sticky;
  final Duration? timeoutAfter;

  /// Android: `exactAllowWhileIdle` when true, else `inexactAllowWhileIdle`.
  final bool exact;

  /// Android `alarmClock` mode (Alarm profile only, P2).
  final bool alarmClock;

  /// Android full-screen intent (Alarm profile, only when the user allows it — T7.2.24).
  final bool fullScreen;

  /// iOS: show the system banner while the app is in the foreground.
  final bool presentInForeground;

  /// Android tag (dedupe key) so pushes replace local notifications.
  final String? tag;
  final int? badgeNumber;
  final String? subtitle;

  /// Repeating calendar trigger (T7.2.10): every day (or every week on the weekday) at the
  /// wall-clock time of [fireAt] in [repeatZone]; [fireAt] is the first firing.
  final RepeatMatch? repeat;
  final String? repeatZone;

  /// Android group summary of [groupKey] (T7.2.19), shown with [lines] (inbox style) and never
  /// alerting by itself.
  final bool groupSummary;
  final List<String> lines;
}

/// A user response (tap or action button).
@immutable
class OsResponse {
  const OsResponse({this.id, this.actionId, this.input, this.payload, this.background = false});

  final int? id;

  /// Null / empty = tap on the notification body.
  final String? actionId;
  final String? input;
  final String? payload;
  final bool background;

  bool get isTap => actionId == null || actionId!.isEmpty;
}

@immutable
class PendingOsRequest {
  const PendingOsRequest(this.id, {this.title, this.payload});

  final int id;
  final String? title;
  final String? payload;
}

@immutable
class ActiveOsNotification {
  const ActiveOsNotification(this.id, {this.tag, this.payload, this.channelId, this.title, this.groupKey});

  final int? id;
  final String? tag;
  final String? payload;
  final String? channelId;
  final String? title;
  final String? groupKey;
}

/// The only code touching the notification plugin (T7.2.01). Tests use
/// [InMemoryLocalNotificationsPort].
abstract interface class LocalNotificationsPort {
  /// android | ios | other
  String get platform;

  Future<void> initialize({
    required List<OsCategory> categories,
    required void Function(OsResponse response) onResponse,
  });

  /// Re-registers iOS categories (replaces the whole set).
  Future<void> setCategories(List<OsCategory> categories);

  Future<void> ensureChannels(List<OsChannelGroup> groups, List<OsChannel> channels, {Set<String> delete = const {}});

  Future<void> schedule(OsNotificationRequest request);

  Future<void> show(OsNotificationRequest request);

  Future<void> cancel(int id, {String? tag});

  Future<void> cancelAll();

  Future<List<PendingOsRequest>> pending();

  Future<List<ActiveOsNotification>> active();

  /// Notification that launched the app (cold start), if any.
  Future<OsResponse?> launchResponse();

  Future<NotificationCapabilities> capabilities();

  Future<bool> requestPermission({bool provisional = false});

  Future<bool> requestExactAlarms();

  /// Android 14+: the "full-screen notifications" settings page (alarm profile, T7.2.24).
  Future<bool> requestFullScreenIntent();

  Future<bool> openSettings();

  Future<void> setBadge(int count);
}

/// Fake port recording every call (tests, debug menu, platforms without a plugin).
class InMemoryLocalNotificationsPort implements LocalNotificationsPort {
  InMemoryLocalNotificationsPort({this.platform = 'android', NotificationCapabilities? capabilities})
    : caps =
          capabilities ??
          NotificationCapabilities(
            platform: platform,
            notifications: true,
            exactAlarm: true,
            timeSensitive: true,
            badge: true,
          );

  @override
  final String platform;
  NotificationCapabilities caps;

  final Map<int, OsNotificationRequest> scheduled = {};
  final List<OsNotificationRequest> shown = [];
  final List<int> cancelled = [];
  final Map<String, OsChannel> channels = {};
  final Set<String> deletedChannels = {};
  List<OsCategory> categories = const [];
  int platformCalls = 0;
  int badge = 0;
  OsResponse? launch;
  bool permissionResult = true;
  void Function(OsResponse response)? _onResponse;

  /// Simulates a tap / action on a notification.
  void respond(OsResponse response) => _onResponse?.call(response);

  @override
  Future<void> initialize({required List<OsCategory> categories, required void Function(OsResponse) onResponse}) async {
    this.categories = categories;
    _onResponse = onResponse;
  }

  @override
  Future<void> setCategories(List<OsCategory> categories) async => this.categories = categories;

  @override
  Future<void> ensureChannels(
    List<OsChannelGroup> groups,
    List<OsChannel> channels, {
    Set<String> delete = const {},
  }) async {
    for (final c in channels) {
      this.channels[c.id] = c;
    }
    for (final id in delete) {
      this.channels.remove(id);
      deletedChannels.add(id);
    }
  }

  @override
  Future<void> schedule(OsNotificationRequest request) async {
    platformCalls++;
    scheduled[request.id] = request;
  }

  @override
  Future<void> show(OsNotificationRequest request) async {
    platformCalls++;
    shown.add(request);
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {
    platformCalls++;
    cancelled.add(id);
    scheduled.remove(id);
    shown.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> cancelAll() async {
    platformCalls++;
    scheduled.clear();
    shown.clear();
  }

  @override
  Future<List<PendingOsRequest>> pending() async => [
    for (final r in scheduled.values) PendingOsRequest(r.id, title: r.title, payload: r.payload),
  ];

  @override
  Future<List<ActiveOsNotification>> active() async => [
    for (final r in shown)
      ActiveOsNotification(
        r.id,
        tag: r.tag,
        payload: r.payload,
        channelId: r.channelId,
        title: r.title,
        groupKey: r.groupKey,
      ),
  ];

  /// Test helper: the OS fires every scheduled request due at [now] (moves it to the tray).
  void deliverDue(DateTime now) {
    final due = [
      for (final r in scheduled.values)
        if (r.fireAt != null && !r.fireAt!.isAfter(now)) r,
    ];
    for (final r in due) {
      scheduled.remove(r.id);
      shown
        ..removeWhere((s) => s.id == r.id)
        ..add(r);
    }
  }

  @override
  Future<OsResponse?> launchResponse() async => launch;

  @override
  Future<NotificationCapabilities> capabilities() async => caps;

  @override
  Future<bool> requestPermission({bool provisional = false}) async {
    caps = caps.copyWith(notifications: permissionResult, provisional: provisional && permissionResult);
    return permissionResult;
  }

  @override
  Future<bool> requestExactAlarms() async {
    caps = caps.copyWith(exactAlarm: permissionResult);
    return permissionResult;
  }

  @override
  Future<bool> requestFullScreenIntent() async {
    caps = caps.copyWith(fullScreenIntent: permissionResult);
    return permissionResult;
  }

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<void> setBadge(int count) async => badge = count;
}
