import 'dart:convert';

import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:meta/meta.dart';

/// Action ids shared by OS notifications, pushes, in-app banners and inbox rows (T7.2.03).
/// Deep links to the notification module's own pages (system notices, diagnostics). The app
/// shell doesn't route them yet, so notification UI opens them directly (`openNotificationLink`).
abstract final class NotificationLinks {
  static const settings = '/settings/notifications';
  static const diagnostics = '/settings/notifications/diagnostics';
}

abstract final class NotificationActionIds {
  static const done = 'done';
  static const start = 'start';
  static const stop = 'stop';
  static const snooze = 'snooze';
  static const skip = 'skip';
  static const reschedule = 'reschedule';

  /// Extends a running timer task by 10 minutes (timer-end alerts, T7.5.04).
  static const extend = 'extend';
  static const logValue = 'log_value';
  static const logCraving = 'log_craving';
  static const completeItem = 'complete_item';
  static const markOngoing = 'mark_ongoing';
  static const markWaiting = 'mark_waiting';
  static const markBlocked = 'mark_blocked';
  static const open = 'open';
  static const muteRule = 'mute_rule';
  static const markRead = 'mark_read';

  /// Tap on the notification body (not an action button).
  static const tap = 'tap';

  /// Dismissal (Android delete intent / iOS custom dismiss action) — stops nags.
  static const dismiss = 'dismiss';

  static const all = [
    done,
    start,
    stop,
    snooze,
    skip,
    reschedule,
    extend,
    logValue,
    logCraving,
    completeItem,
    markOngoing,
    markWaiting,
    markBlocked,
    open,
    muteRule,
    markRead,
  ];

  /// Actions collecting text input (numbers).
  static const textInput = {logValue, logCraving};

  /// Actions that bring the app to the foreground.
  static const foreground = {open, reschedule};

  /// Actions the notification system handles itself (feature handlers cover the rest).
  static const generic = {snooze, open, muteRule, markRead, tap, dismiss};
}

/// Parsed notification payload (see `PlannedNotification.payload`).
@immutable
class NotificationPayload {
  const NotificationPayload({
    required this.dedupeKey,
    this.baseKey,
    this.targetKey,
    this.targetType,
    this.targetId,
    this.occurrenceKey,
    this.ruleId,
    this.section,
    this.category,
    this.deepLink,
    this.actions = const [],
    this.snoozeOptions = const [],
    this.userId,
    this.repeatIdx = 0,
    this.kind,
    this.members = const [],
  });

  factory NotificationPayload.fromJson(Map<String, Object?> json) => NotificationPayload(
    dedupeKey: asString(json['dk']) ?? '',
    baseKey: asString(json['bk']),
    targetKey: asString(json['tk']),
    targetType: json['tt'] == null ? null : NotificationTargetType.parse(asString(json['tt'])),
    targetId: asString(json['tid']),
    occurrenceKey: asString(json['occ']),
    ruleId: asString(json['rid']),
    section: NotificationSection.tryParse(asString(json['sec'])),
    category: json['cat'] == null ? null : InboxCategory.parse(asString(json['cat'])),
    deepLink: asString(json['link']),
    actions: asStringList(json['acts']) ?? const [],
    snoozeOptions: asIntList(json['snz']) ?? const [],
    userId: asString(json['uid']),
    repeatIdx: asInt(json['rep']) ?? 0,
    kind: asString(json['kind']),
    members: asStringList(json['mem']) ?? const [],
  );

  static NotificationPayload? tryDecode(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final map = asJsonMap(jsonDecode(source));
      if (map == null) return null;
      final p = NotificationPayload.fromJson(map);
      return p.dedupeKey.isEmpty && p.kind == null ? null : p;
    } on FormatException {
      return null;
    }
  }

  final String dedupeKey;
  final String? baseKey;
  final String? targetKey;
  final NotificationTargetType? targetType;
  final String? targetId;
  final String? occurrenceKey;
  final String? ruleId;
  final NotificationSection? section;
  final InboxCategory? category;
  final String? deepLink;
  final List<String> actions;
  final List<int> snoozeOptions;
  final String? userId;
  final int repeatIdx;

  /// `merged` / `sentinel` / `test` for synthetic notifications.
  final String? kind;
  final List<String> members;

  String get chainKey => baseKey ?? dedupeKey;

  Map<String, Object?> toJson() => {
    'v': 1,
    'dk': dedupeKey,
    'bk': ?baseKey,
    'tk': ?targetKey,
    'tt': ?targetType?.wire,
    'tid': ?targetId,
    'occ': ?occurrenceKey,
    'rid': ?ruleId,
    'sec': ?section?.wire,
    'cat': ?category?.wire,
    'link': ?deepLink,
    if (actions.isNotEmpty) 'acts': actions,
    if (snoozeOptions.isNotEmpty) 'snz': snoozeOptions,
    'uid': ?userId,
    if (repeatIdx > 0) 'rep': repeatIdx,
    'kind': ?kind,
    if (members.isNotEmpty) 'mem': members,
  };

  String encode() => jsonEncode(toJson());
}
