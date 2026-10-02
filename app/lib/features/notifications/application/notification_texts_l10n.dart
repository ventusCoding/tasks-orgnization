import 'dart:ui';

import 'package:everslot/design_system/formatting.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart' show ContentPacks, ContentVariant;
import 'package:everslot/features/notifications/domain/template_engine.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:intl/date_symbol_data_local.dart';

/// [NotificationTexts] backed by the app's ARB strings and [AppFormat] (T7.1.08). Pure enough to
/// be used from background isolates (no BuildContext).
class L10nNotificationTexts implements NotificationTexts {
  L10nNotificationTexts(this.l10n, {required this.localeTag, this.use24h = true})
    : format = AppFormat(localeTag, use24h: use24h, l10n: l10n) {
    _ensureDateSymbols();
  }

  static bool _dateSymbolsReady = false;

  /// Date symbols are normally loaded by the Material localizations delegate; the planner also
  /// runs outside the widget tree (background isolate, tests), so load the bundled data here
  /// (synchronous for the local data set).
  static void _ensureDateSymbols() {
    if (_dateSymbolsReady) return;
    _dateSymbolsReady = true;
    initializeDateFormatting().ignore();
  }

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
  /// Whole days read as days ("3 days", status ages); shorter spans as hours and minutes.
  String duration(int minutes) =>
      minutes >= 1440 && minutes % 1440 == 0 ? l10n.durationDaysShort(minutes ~/ 1440) : format.duration(minutes);

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
      DefaultContentKind.statusAge => (
        title: t,
        body: switch (vars['status_wire']) {
          'waiting' => l10n.notifBodyStillWaitingOn(vars['item_text'] ?? t, vars['status_age'] ?? ''),
          'blocked' => l10n.notifBodyBlockedFor(vars['item_text'] ?? t, vars['status_age'] ?? ''),
          _ => l10n.notifBodyStatusAge(vars['status'] ?? '', vars['status_age'] ?? ''),
        },
      ),
      DefaultContentKind.overdue => (title: t, body: l10n.notifBodyOverdue(t)),
      DefaultContentKind.streakRisk => (title: t, body: l10n.notifBodyStreakRisk(n)),
      DefaultContentKind.quotaBehind => (
        title: t,
        // "2 of 3 done — 1 day left" / last eligible day: "Last chance today: 1 to go" (T7.5.12).
        body: vars['days_left'] == '1'
            ? l10n.notifBodyQuotaLastChance(n)
            : vars['days_left'] != null
            ? l10n.notifBodyQuotaPace(vars['done'] ?? '', vars['target'] ?? '', int.tryParse(vars['days_left']!) ?? 0)
            : l10n.notifBodyQuotaBehind(vars['done'] ?? '', vars['target'] ?? '', n),
      ),
      DefaultContentKind.milestone => (
        title: t,
        body: vars['days_free'] != null
            ? l10n.notifBodyCleanDays(n)
            : l10n.notifBodyMilestone(vars['next_milestone'] ?? ''),
      ),
      DefaultContentKind.inactivity => (title: t, body: l10n.notifBodyInactivity(n)),
      DefaultContentKind.digest => (title: digestTitle(vars['kind'] ?? ''), body: vars['summary']),
      DefaultContentKind.statusChange => (title: t, body: l10n.notifBodyStatusChange(vars['status'] ?? '')),
      DefaultContentKind.childrenComplete => (title: t, body: l10n.notifBodyChildrenComplete),
      DefaultContentKind.childOverdue => (title: t, body: l10n.notifBodyChildOverdue),
      DefaultContentKind.stale => (title: t, body: l10n.notifBodyInactivity(n)),
      DefaultContentKind.upNext => (
        title: t,
        body: l10n.notifBodyUpNext(vars['next_title'] ?? '', vars['next_start_time'] ?? ''),
      ),
      DefaultContentKind.upNextMerged => (
        title: vars['next_title'] ?? t,
        body: l10n.notifBodyUpNextMerged(t, vars['next_title'] ?? '', vars['next_start_time'] ?? ''),
      ),
      DefaultContentKind.timerEnd => (title: t, body: l10n.notifBodyTimeUp(t)),
      DefaultContentKind.listReset => (title: t, body: l10n.notifBodyListReset(t)),
      DefaultContentKind.pledge => (title: t, body: l10n.notifBodyPledge),
      DefaultContentKind.eveningReview => (title: t, body: l10n.notifBodyEveningReview),
      DefaultContentKind.cravingSupport => (
        title: t,
        body: vars['tip'] == null ? l10n.notifBodyCravingSupport : l10n.notifBodyCravingSupportTip(vars['tip']!),
      ),
      DefaultContentKind.encouragement => (title: t, body: l10n.notifBodyEncouragement),
      DefaultContentKind.motivation => (title: t, body: l10n.notifBodyMotivation(vars['reason'] ?? '')),
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
  String status(String wire) => statusLabelOf(l10n, wire);

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
  String digestSummary(
    String kind, {
    required int tasks,
    required int habits,
    required int items,
    String? first,
    int? backlog,
  }) {
    if (kind == 'weekly_review') return l10n.notifDigestWeeklyReady;
    if (kind == 'monthly_report') return l10n.notifDigestMonthlyReady;
    final parts = [
      l10n.notifDigestSummary(tasks, habits, items),
      if (first != null) l10n.notifDigestFirst(first),
      if (backlog != null && backlog > 0) l10n.notifDigestBacklog(backlog),
    ];
    return parts.join(' · ');
  }

  @override
  List<ContentVariant> packVariants(String pack) => switch (pack) {
    // ICU placeholders receive the literal `{variable}` the template engine fills in later.
    ContentPacks.habitMotivation => [
      ContentVariant(body: l10n.notifPackHabit1('{title}')),
      ContentVariant(body: l10n.notifPackHabit2('{title}')),
      ContentVariant(body: l10n.notifPackHabit3('{title}')),
      ContentVariant(body: l10n.notifPackHabit4('{title}')),
      ContentVariant(body: l10n.notifPackHabit5('{title}')),
    ],
    ContentPacks.quitMotivation => [
      ContentVariant(body: l10n.notifPackQuit1('{days_free}')),
      ContentVariant(body: l10n.notifPackQuit2('{reason}')),
      ContentVariant(body: l10n.notifPackQuit3),
      ContentVariant(body: l10n.notifPackQuit4('{money_saved}')),
      ContentVariant(body: l10n.notifPackQuit5),
    ],
    _ => const [],
  };

  String sectionName(NotificationSection section) => sectionLabelOf(l10n, section);
}

/// Localized label of a notification action id.
/// Localized item / occurrence / habit-period status (`{status}` in templates, editors).
String statusLabelOf(AppLocalizations l10n, String wire) => switch (wire) {
  'scheduled' => l10n.notifStatusScheduled,
  'in_progress' => l10n.notifStatusInProgress,
  'done' => l10n.notifStatusDone,
  'skipped' => l10n.notifStatusSkipped,
  'missed' => l10n.notifStatusMissed,
  'cancelled' => l10n.notifStatusCancelled,
  'todo' => l10n.notifStatusTodo,
  'ongoing' => l10n.notifStatusOngoing,
  'waiting' => l10n.notifStatusWaiting,
  'blocked' => l10n.notifStatusBlocked,
  'completed' => l10n.notifStatusCompleted,
  _ => wire,
};

String actionLabelOf(AppLocalizations l10n, String actionId) => switch (actionId) {
  NotificationActionIds.done => l10n.notifActionDone,
  NotificationActionIds.start => l10n.notifActionStart,
  NotificationActionIds.stop => l10n.notifActionStop,
  NotificationActionIds.snooze => l10n.notifActionSnooze,
  NotificationActionIds.skip => l10n.notifActionSkip,
  NotificationActionIds.reschedule => l10n.notifActionReschedule,
  NotificationActionIds.extend => l10n.notifActionExtend,
  NotificationActionIds.logValue => l10n.notifActionLogValue,
  NotificationActionIds.logCraving => l10n.notifActionLogCraving,
  NotificationActionIds.pledge => l10n.notifActionPledge,
  NotificationActionIds.cleanDay => l10n.notifActionCleanDay,
  NotificationActionIds.logRelapse => l10n.notifActionLogRelapse,
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
