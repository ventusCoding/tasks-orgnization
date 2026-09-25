import 'dart:ui';

import 'package:everslot/design_system/formatting.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/template_engine.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// [NotificationTexts] backed by the app's ARB strings and [AppFormat] (T7.1.08). Pure enough to
/// be used from background isolates (no BuildContext).
class L10nNotificationTexts implements NotificationTexts {
  L10nNotificationTexts(this.l10n, {required this.localeTag, this.use24h = true})
    : format = AppFormat(localeTag, use24h: use24h, l10n: l10n);

  /// Resolves the app language (explicit override, else system, else English).
  factory L10nNotificationTexts.forLocale(String? localeCode, {bool use24h = true}) {
    const supported = ['en', 'fr', 'ar'];
    final code = supported.contains(localeCode)
        ? localeCode!
        : (supported.contains(PlatformDispatcher.instance.locale.languageCode)
              ? PlatformDispatcher.instance.locale.languageCode
              : 'en');
    return L10nNotificationTexts(lookupAppLocalizations(Locale(code)), localeTag: code, use24h: use24h);
  }

  final AppLocalizations l10n;
  final AppFormat format;
  @override
  final String localeTag;
  final bool use24h;

  @override
  bool get isRtl => localeTag.startsWith('ar');

  @override
  String time(LocalDateTime local) => format.timeOf(local);

  @override
  String date(LocalDate date) => format.dateMedium(date);

  @override
  String weekday(LocalDate date) => format.weekdayShort(date.weekday);

  @override
  String duration(int minutes) => format.duration(minutes);

  @override
  String number(num value) => format.number(value, decimals: value is int || value == value.roundToDouble() ? 0 : 1);

  @override
  String relative(int minutes) {
    final now = DateTime.utc(2000);
    return format.relative(now.add(Duration(minutes: minutes)), now);
  }

  @override
  ({String title, String? body}) defaultContent(DefaultContentKind kind, Map<String, String> vars, {int? count}) {
    final t = vars['title'] ?? '';
    final n = count ?? 0;
    final start = vars['start_time'];
    final end = vars['end_time'];
    final range = [start, end].whereType<String>().where((s) => s.isNotEmpty).join('–');
    String withRange(String s) => range.isEmpty ? s : '$s · $range';
    return switch (kind) {
      DefaultContentKind.beforeStart => (title: t, body: withRange(l10n.notifBodyStartsIn(n))),
      DefaultContentKind.atStart => (title: t, body: withRange(l10n.notifBodyStartingNow)),
      DefaultContentKind.afterStart => (title: t, body: l10n.notifBodyStartedAgo(n)),
      DefaultContentKind.beforeEnd => (title: t, body: l10n.notifBodyEndsIn(n)),
      DefaultContentKind.atEnd => (title: t, body: l10n.notifBodyEndingNow),
      DefaultContentKind.afterEnd => (title: t, body: l10n.notifBodyEndedAgo(n)),
      DefaultContentKind.beforeDue => (title: t, body: l10n.notifBodyDueIn(n)),
      DefaultContentKind.atDue => (title: t, body: l10n.notifBodyDueNow),
      DefaultContentKind.followUp => (title: l10n.notifTitleFollowUp(t), body: vars['status_note']),
      DefaultContentKind.slot => (title: t, body: l10n.notifBodyTimeFor(t)),
      DefaultContentKind.onDay => (title: t, body: l10n.notifBodyToday(vars['date'] ?? '')),
      DefaultContentKind.daysBefore => (title: t, body: l10n.notifBodyInDays(n, vars['date'] ?? '')),
      DefaultContentKind.absolute || DefaultContentKind.schedule => (title: t, body: vars['notes_excerpt']),
      DefaultContentKind.notDoneBy => (title: t, body: l10n.notifBodyNotDone(t)),
      DefaultContentKind.statusAge => (title: t, body: l10n.notifBodyStatusAge(vars['status'] ?? '', vars['status_age'] ?? '')),
      DefaultContentKind.overdue => (title: t, body: l10n.notifBodyOverdue(t)),
      DefaultContentKind.streakRisk => (title: t, body: l10n.notifBodyStreakRisk(n)),
      DefaultContentKind.quotaBehind => (
        title: t,
        body: l10n.notifBodyQuotaBehind(vars['done'] ?? '', vars['target'] ?? '', n),
      ),
      DefaultContentKind.milestone => (
        title: t,
        body: vars['days_free'] != null ? l10n.notifBodyCleanDays(n) : l10n.notifBodyMilestone(vars['next_milestone'] ?? ''),
      ),
      DefaultContentKind.inactivity => (title: t, body: l10n.notifBodyInactivity(n)),
      DefaultContentKind.digest => (title: digestTitle(vars['kind'] ?? ''), body: vars['summary']),
      DefaultContentKind.statusChange => (title: t, body: l10n.notifBodyStatusChange(vars['status'] ?? '')),
      DefaultContentKind.childrenComplete => (title: t, body: l10n.notifBodyChildrenComplete),
      DefaultContentKind.childOverdue => (title: t, body: l10n.notifBodyChildOverdue),
      DefaultContentKind.stale => (title: t, body: l10n.notifBodyInactivity(n)),
      DefaultContentKind.snoozed => (title: t, body: l10n.notifBodySnoozed),
      DefaultContentKind.test => (title: t, body: l10n.notifBodyTest),
    };
  }

  @override
  String get redactedTitle => l10n.notifRedactedTitle;

  @override
  String get redactedBody => l10n.notifRedactedBody;

  @override
  String mergedTitle(int count) => l10n.notifMergedTitle(count);

  @override
  String get saturationTitle => l10n.notifSaturationTitle;

  @override
  String get saturationBody => l10n.notifSaturationBody;

  @override
  String actionLabel(String actionId) => actionLabelOf(l10n, actionId);

  @override
  String digestTitle(String kind) => switch (kind) {
    'daily_agenda' => l10n.notifDigestDailyAgenda,
    'plan_tomorrow' => l10n.notifDigestPlanTomorrow,
    'evening_review' => l10n.notifDigestEveningReview,
    'overdue_summary' => l10n.notifDigestOverdue,
    'weekly_review' => l10n.notifDigestWeekly,
    'monthly_report' => l10n.notifDigestMonthly,
    _ => l10n.notifSectionDigests,
  };

  @override
  String digestSummary(String kind, {required int tasks, required int habits, required int items, String? first}) {
    final base = l10n.notifDigestSummary(tasks, habits, items);
    return first == null ? base : '$base · ${l10n.notifDigestFirst(first)}';
  }

  String sectionName(NotificationSection section) => sectionLabelOf(l10n, section);
}

/// Localized label of a notification action id.
String actionLabelOf(AppLocalizations l10n, String actionId) => switch (actionId) {
  NotificationActionIds.done => l10n.notifActionDone,
  NotificationActionIds.start => l10n.notifActionStart,
  NotificationActionIds.stop => l10n.notifActionStop,
  NotificationActionIds.snooze => l10n.notifActionSnooze,
  NotificationActionIds.skip => l10n.notifActionSkip,
  NotificationActionIds.reschedule => l10n.notifActionReschedule,
  NotificationActionIds.logValue => l10n.notifActionLogValue,
  NotificationActionIds.logCraving => l10n.notifActionLogCraving,
  NotificationActionIds.completeItem => l10n.notifActionComplete,
  NotificationActionIds.markOngoing => l10n.notifActionMarkOngoing,
  NotificationActionIds.markWaiting => l10n.notifActionMarkWaiting,
  NotificationActionIds.markBlocked => l10n.notifActionMarkBlocked,
  NotificationActionIds.open => l10n.notifActionOpen,
  NotificationActionIds.muteRule => l10n.notifActionMute,
  NotificationActionIds.markRead => l10n.notifActionMarkRead,
  _ => actionId,
};

String sectionLabelOf(AppLocalizations l10n, NotificationSection section) => switch (section) {
  NotificationSection.planner => l10n.notifSectionPlanner,
  NotificationSection.checklists => l10n.notifSectionChecklists,
  NotificationSection.habits => l10n.notifSectionHabits,
  NotificationSection.quit => l10n.notifSectionQuit,
  NotificationSection.system => l10n.notifSectionSystem,
};

String builtinProfileName(AppLocalizations l10n, String code) => switch (code) {
  'gentle' => l10n.notifProfileGentle,
  'standard' => l10n.notifProfileStandard,
  'nag' => l10n.notifProfileNag,
  'alarm' => l10n.notifProfileAlarm,
  _ => code,
};
