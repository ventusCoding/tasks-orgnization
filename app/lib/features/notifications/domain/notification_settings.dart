import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// One quiet-hours window (`notifications.quietHours[]`, arch §8.5). [days] are the ISO weekdays
/// on which the window **starts**; windows may cross midnight (22:00 → 07:00).
@immutable
class QuietHoursWindow {
  const QuietHoursWindow({required this.days, required this.from, required this.to, this.mode = QuietHoursMode.defer});

  factory QuietHoursWindow.fromJson(Map<String, Object?> json) => QuietHoursWindow(
    days: asIntList(json['days']) ?? const [1, 2, 3, 4, 5, 6, 7],
    from: LocalTime.tryParse(asString(json['from']) ?? '') ?? LocalTime(22, 0),
    to: LocalTime.tryParse(asString(json['to']) ?? '') ?? LocalTime(7, 0),
    mode: QuietHoursMode.parse(asString(json['mode'])),
  );

  final List<int> days;
  final LocalTime from;
  final LocalTime to;
  final QuietHoursMode mode;

  bool get crossesMidnight => to.minuteOfDay <= from.minuteOfDay;

  Map<String, Object?> toJson() => {'days': days, 'from': from.toIso(), 'to': to.toIso(), 'mode': mode.wire};

  /// If [local] falls inside this window, returns the window's end as a wall-clock value.
  LocalDateTime? endIfInside(LocalDateTime local) {
    final m = local.time.minuteOfDay;
    final f = from.minuteOfDay;
    final t = to.isEndOfDay ? 1440 : to.minuteOfDay;
    if (!crossesMidnight) {
      if (days.contains(local.date.weekday.iso) && m >= f && m < t) {
        return LocalDateTime(local.date, to);
      }
      return null;
    }
    // Evening part (window starts today).
    if (m >= f && days.contains(local.date.weekday.iso)) {
      return LocalDateTime(local.date.plusDays(1), to);
    }
    // Morning part (window started yesterday).
    final yesterday = local.date.minusDays(1);
    if (m < t && days.contains(yesterday.weekday.iso)) {
      return LocalDateTime(local.date, to);
    }
    return null;
  }

  QuietHoursWindow copyWith({List<int>? days, LocalTime? from, LocalTime? to, QuietHoursMode? mode}) =>
      QuietHoursWindow(days: days ?? this.days, from: from ?? this.from, to: to ?? this.to, mode: mode ?? this.mode);

  @override
  bool operator ==(Object other) =>
      other is QuietHoursWindow &&
      jsonEquals(other.days, days) &&
      other.from == from &&
      other.to == to &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(Object.hashAll(days), from, to, mode);
}

/// Per-section switch and default profile (`notifications.perSection.<section>`).
@immutable
class SectionNotificationSettings {
  const SectionNotificationSettings({this.enabled = true, this.defaultProfileId});

  final bool enabled;
  final String? defaultProfileId;

  Map<String, Object?> toJson() => {'enabled': enabled, 'defaultProfileId': ?defaultProfileId};
}

/// Typed view of the `notifications` settings namespace (arch §8.5) + the privacy flag.
@immutable
class NotificationSettings {
  const NotificationSettings({
    this.quietHours = const [],
    this.pausedUntil,
    this.perSection = const {},
    this.digestsEnabled = false,
    this.dailyAgendaAt,
    this.eveningReviewAt,
    this.weeklyReviewDay = 7,
    this.weeklyReviewAt,
    this.multiDevicePolicy = MultiDevicePolicy.all,
    this.primaryDeviceId,
    this.latenessMinutes = 30,
    this.digestLatenessMinutes = 120,
    this.bannerInApp = true,
    this.snoozePresets = const [10, 5, 15, 30, 60],
    this.maxNagRepeats = 5,
    this.dateOnlyDefaultTime,
    this.dailyCap = 500,
    this.perTargetDailyCap = 60,
    this.horizonDays = 14,
    this.badgePolicy = 'unread',
    this.hideContent = false,
    this.maxSnoozes = 5,
  });

  factory NotificationSettings.fromMaps(Map<String, dynamic> notifications, [Map<String, dynamic> privacy = const {}]) {
    final quiet = notifications['quietHours'];
    final per = asJsonMap(notifications['perSection']) ?? const {};
    final digest = asJsonMap(notifications['digest']) ?? const {};
    LocalTime? time(Object? v) => v is String ? LocalTime.tryParse(v) : null;
    final paused = asString(notifications['pausedUntil']);
    return NotificationSettings(
      quietHours: quiet is List
          ? [
              for (final w in quiet)
                if (asJsonMap(w) != null) QuietHoursWindow.fromJson(asJsonMap(w)!),
            ]
          : const [],
      pausedUntil: paused == null ? null : DateTime.tryParse(paused)?.toUtc(),
      perSection: {
        for (final e in per.entries)
          if (NotificationSection.tryParse(e.key) != null && asJsonMap(e.value) != null)
            NotificationSection.tryParse(e.key)!: SectionNotificationSettings(
              enabled: asBool(asJsonMap(e.value)!['enabled']) ?? true,
              defaultProfileId: asString(asJsonMap(e.value)!['defaultProfileId']),
            ),
      },
      digestsEnabled: asBool(digest['enabled']) ?? false,
      dailyAgendaAt: time(digest['dailyAgendaAt']),
      eveningReviewAt: time(digest['eveningReviewAt']),
      weeklyReviewDay: asInt(digest['weeklyReviewDay']) ?? 7,
      weeklyReviewAt: time(digest['weeklyReviewAt']),
      multiDevicePolicy: MultiDevicePolicy.parse(asString(notifications['multiDevicePolicy'])),
      primaryDeviceId: asString(notifications['primaryDeviceId']),
      latenessMinutes: asInt(notifications['latenessMinutes']) ?? 30,
      bannerInApp: asBool(notifications['bannerInApp']) ?? true,
      snoozePresets: asIntList(notifications['snoozePresets']) ?? const [10, 5, 15, 30, 60],
      maxNagRepeats: (asInt(notifications['maxNagRepeats']) ?? 5).clamp(1, 10),
      dateOnlyDefaultTime: time(notifications['dateOnlyDefaultTime']),
      dailyCap: asInt(notifications['dailyCap']) ?? 500,
      horizonDays: (asInt(notifications['horizonDays']) ?? 14).clamp(1, 14),
      badgePolicy: asString(notifications['badgePolicy']) ?? 'unread',
      // arch §8.5 key first; `hideNotificationContent` is accepted as an alias.
      hideContent: asBool(privacy['hideContentInNotifications']) ?? asBool(privacy['hideNotificationContent']) ?? false,
    );
  }

  static const defaults = NotificationSettings();

  final List<QuietHoursWindow> quietHours;
  final DateTime? pausedUntil;
  final Map<NotificationSection, SectionNotificationSettings> perSection;
  final bool digestsEnabled;
  final LocalTime? dailyAgendaAt;
  final LocalTime? eveningReviewAt;
  final int weeklyReviewDay;
  final LocalTime? weeklyReviewAt;
  final MultiDevicePolicy multiDevicePolicy;
  final String? primaryDeviceId;

  /// Default lateness window for reminders (drop/mark late after).
  final int latenessMinutes;
  final int digestLatenessMinutes;
  final bool bannerInApp;

  /// First entry = the notification's *Snooze* button.
  final List<int> snoozePresets;
  final int maxNagRepeats;
  final LocalTime? dateOnlyDefaultTime;
  final int dailyCap;
  final int perTargetDailyCap;
  final int horizonDays;

  /// off | unread | due
  final String badgePolicy;
  final bool hideContent;
  final int maxSnoozes;

  LocalTime get effectiveDateOnlyTime => dateOnlyDefaultTime ?? LocalTime(9, 0);

  bool sectionEnabled(NotificationSection section) => perSection[section]?.enabled ?? true;

  String? sectionDefaultProfileId(NotificationSection section) => perSection[section]?.defaultProfileId;

  bool pausedAt(DateTime instant) => pausedUntil != null && instant.isBefore(pausedUntil!);

  /// Whether this device schedules local notifications under the multi-device policy.
  bool localSchedulingAllowed(String deviceId) => switch (multiDevicePolicy) {
    MultiDevicePolicy.all || MultiDevicePolicy.lastActive => true,
    MultiDevicePolicy.primary => primaryDeviceId == null || primaryDeviceId == deviceId,
  };

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings &&
      jsonEquals([for (final w in other.quietHours) w.toJson()], [for (final w in quietHours) w.toJson()]) &&
      other.pausedUntil == pausedUntil &&
      jsonEquals(
        {for (final e in other.perSection.entries) e.key.wire: e.value.toJson()},
        {for (final e in perSection.entries) e.key.wire: e.value.toJson()},
      ) &&
      other.digestsEnabled == digestsEnabled &&
      other.multiDevicePolicy == multiDevicePolicy &&
      other.primaryDeviceId == primaryDeviceId &&
      other.latenessMinutes == latenessMinutes &&
      other.bannerInApp == bannerInApp &&
      jsonEquals(other.snoozePresets, snoozePresets) &&
      other.maxNagRepeats == maxNagRepeats &&
      other.dateOnlyDefaultTime == dateOnlyDefaultTime &&
      other.dailyCap == dailyCap &&
      other.horizonDays == horizonDays &&
      other.badgePolicy == badgePolicy &&
      other.hideContent == hideContent;

  @override
  int get hashCode => Object.hash(
    quietHours.length,
    pausedUntil,
    perSection.length,
    multiDevicePolicy,
    latenessMinutes,
    bannerInApp,
    maxNagRepeats,
    hideContent,
    horizonDays,
  );
}
