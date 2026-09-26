import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:meta/meta.dart';

/// `dedupe_key = sha1(rule_id | target_id | occurrence_key | trigger_idx | repeat_idx)` — 40 hex
/// chars, identical on every device, valid APNs collapse id (arch §6.13).
String dedupeKeyFor({
  required String ruleId,
  required String targetId,
  required String occurrenceKey,
  int triggerIdx = 0,
  int repeatIdx = 0,
}) => sha1.convert(utf8.encode('$ruleId|$targetId|$occurrenceKey|$triggerIdx|$repeatIdx')).toString();

/// Key of the n-th snooze instance of [originalKey] (T7.2.15).
String snoozeKeyFor(String originalKey, int n) => sha1.convert(utf8.encode('$originalKey|snooze|$n')).toString();

/// Adjustments a policy applied to a firing (shown as preview reasons, T7.1.11).
enum PlanAdjustment { deferredQuietHours, silentQuietHours, paused, shiftedToWindow, catchUp, notLocal }

/// Why a candidate firing was not planned.
enum SkipReason {
  quietHoursDrop,
  muted,
  statusFilter,
  weekdayFilter,
  timeWindowDrop,
  guardClosed,
  expired,
  acknowledged,
  cap,
  noChannel,
}

/// One concrete firing (arch §6.13 "planned notification").
@immutable
class PlannedNotification {
  const PlannedNotification({
    required this.dedupeKey,
    required this.baseKey,
    required this.targetKey,
    required this.targetType,
    required this.targetId,
    required this.ruleId,
    required this.occurrenceKey,
    required this.triggerType,
    required this.fireAt,
    required this.expiresAt,
    required this.category,
    required this.section,
    required this.channelId,
    required this.importance,
    required this.interruptionLevel,
    required this.relevance,
    required this.sound,
    required this.vibration,
    required this.sticky,
    required this.alarmStyle,
    required this.actions,
    required this.snoozeOptions,
    required this.title,
    required this.body,
    required this.inboxTitle,
    required this.inboxBody,
    required this.threadId,
    required this.deepLink,
    required this.guard,
    required this.deliverSystem,
    required this.deliverInbox,
    required this.deliverBanner,
    required this.scheduleLocally,
    required this.repeatIdx,
    required this.userId,
    this.adjustments = const {},
    this.anchorFireAt,
    this.silent = false,
    this.targetDevices,
  });

  final String dedupeKey;

  /// Key of repeat 0 of the chain (== [dedupeKey] for non-nag firings).
  final String baseKey;
  final String targetKey;
  final NotificationTargetType targetType;
  final String targetId;
  final String ruleId;
  final String occurrenceKey;
  final String triggerType;

  /// UTC instant (may be in the past for catch-up firings still inside their lateness window).
  final DateTime fireAt;
  final DateTime expiresAt;
  final InboxCategory category;
  final NotificationSection section;
  final String channelId;
  final NotificationImportance importance;
  final InterruptionLevel interruptionLevel;
  final double relevance;
  final String sound;
  final String vibration;
  final bool sticky;
  final bool alarmStyle;
  final List<String> actions;
  final List<int> snoozeOptions;

  /// System notification text (redacted when "hide content" is on).
  final String title;
  final String? body;

  /// Full text (inbox, in-app banner).
  final String inboxTitle;
  final String? inboxBody;
  final String threadId;
  final String deepLink;
  final NotificationGuard guard;
  final bool deliverSystem;
  final bool deliverInbox;
  final bool deliverBanner;

  /// False when the multi-device policy / rule devices exclude this device (still uploaded as a job).
  final bool scheduleLocally;
  final int repeatIdx;
  final String userId;
  final Set<PlanAdjustment> adjustments;

  /// Original fire time before quiet-hours / window shifts (null when unchanged).
  final DateTime? anchorFireAt;

  /// Delivered without sound (quiet hours "silent" mode).
  final bool silent;

  /// Rule `conditions.devices` (null = all devices) — pushed as `target_devices`.
  final List<String>? targetDevices;

  bool get isNag => repeatIdx > 0;

  /// Payload carried by the OS notification, the push job and the inbox row.
  Map<String, Object?> get payload => {
    'v': 1,
    'dk': dedupeKey,
    if (baseKey != dedupeKey) 'bk': baseKey,
    'tk': targetKey,
    'tt': targetType.wire,
    'tid': targetId,
    if (occurrenceKey.isNotEmpty) 'occ': occurrenceKey,
    'rid': ruleId,
    'sec': section.wire,
    'cat': category.wire,
    'link': deepLink,
    if (actions.isNotEmpty) 'acts': actions,
    if (snoozeOptions.isNotEmpty) 'snz': snoozeOptions,
    'uid': userId,
    if (repeatIdx > 0) 'rep': repeatIdx,
  };

  PlannedNotification copyWith({
    DateTime? fireAt,
    DateTime? expiresAt,
    String? channelId,
    bool? deliverSystem,
    bool? deliverBanner,
    String? title,
    String? body,
  }) => PlannedNotification(
    dedupeKey: dedupeKey,
    baseKey: baseKey,
    targetKey: targetKey,
    targetType: targetType,
    targetId: targetId,
    ruleId: ruleId,
    occurrenceKey: occurrenceKey,
    triggerType: triggerType,
    fireAt: fireAt ?? this.fireAt,
    expiresAt: expiresAt ?? this.expiresAt,
    category: category,
    section: section,
    channelId: channelId ?? this.channelId,
    importance: importance,
    interruptionLevel: interruptionLevel,
    relevance: relevance,
    sound: sound,
    vibration: vibration,
    sticky: sticky,
    alarmStyle: alarmStyle,
    actions: actions,
    snoozeOptions: snoozeOptions,
    title: title ?? this.title,
    body: body ?? this.body,
    inboxTitle: inboxTitle,
    inboxBody: inboxBody,
    threadId: threadId,
    deepLink: deepLink,
    guard: guard,
    deliverSystem: deliverSystem ?? this.deliverSystem,
    deliverInbox: deliverInbox,
    deliverBanner: deliverBanner ?? this.deliverBanner,
    scheduleLocally: scheduleLocally,
    repeatIdx: repeatIdx,
    userId: userId,
    adjustments: adjustments,
    anchorFireAt: anchorFireAt,
    silent: silent,
    targetDevices: targetDevices,
  );

  /// Stable hash of everything the OS shows (scheduler diffing).
  String get contentHash => sha1
      .convert(
        utf8.encode(
          jsonEncode([
            fireAt.toIso8601String(),
            expiresAt.toIso8601String(),
            channelId,
            title,
            body,
            actions,
            sound,
            interruptionLevel.wire,
            threadId,
            deliverSystem,
            payload,
          ]),
        ),
      )
      .toString()
      .substring(0, 16);

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification && other.dedupeKey == dedupeKey && other.contentHash == contentHash;

  @override
  int get hashCode => Object.hash(dedupeKey, fireAt);

  @override
  String toString() => 'Planned(${dedupeKey.substring(0, 8)} $targetKey@$occurrenceKey $fireAt $title)';
}

/// A candidate that was dropped, with the reason (preview "skipped" rows).
@immutable
class SkippedFiring {
  const SkippedFiring({
    required this.ruleId,
    required this.targetKey,
    required this.occurrenceKey,
    required this.fireAt,
    required this.reason,
  });

  final String ruleId;
  final String targetKey;
  final String occurrenceKey;
  final DateTime fireAt;
  final SkipReason reason;

  @override
  String toString() => 'Skipped($ruleId $targetKey $fireAt $reason)';
}

@immutable
class PlanResult {
  const PlanResult(this.planned, this.skipped);

  static const empty = PlanResult([], []);

  /// Sorted by fire time, then importance (desc), then key.
  final List<PlannedNotification> planned;
  final List<SkippedFiring> skipped;

  /// Fires per local day (noise estimate helper).
  double firesPerDay(Duration window) => window.inMinutes <= 0 ? 0 : planned.length / (window.inMinutes / 1440);
}

/// Anchor used by a planned relative firing (for descriptions).
extension TriggerAnchorX on TriggerAnchor {
  bool get isEndLike => this == TriggerAnchor.end || this == TriggerAnchor.periodEnd;
}
