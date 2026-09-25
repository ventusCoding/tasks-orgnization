// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get actionAdd => 'Add';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionBack => 'Back';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDone => 'Done';

  @override
  String get actionDuplicate => 'Duplicate';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionInbox => 'Inbox';

  @override
  String get actionMore => 'More';

  @override
  String get actionNext => 'Next';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionRedo => 'Redo';

  @override
  String get actionRestore => 'Restore';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionSettings => 'Settings';

  @override
  String get actionShare => 'Share';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionToday => 'Today';

  @override
  String get actionUndo => 'Undo';

  @override
  String get appName => 'Everslot';

  @override
  String get appTagline => 'Own every slot of your day.';

  @override
  String get categoriesEmpty => 'No categories yet';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoryArchived => 'Archived';

  @override
  String get categoryDefaultHealth => 'Health';

  @override
  String get categoryDefaultHome => 'Home';

  @override
  String get categoryDefaultPersonal => 'Personal';

  @override
  String get categoryDefaultSocial => 'Social';

  @override
  String get categoryDefaultStudy => 'Study';

  @override
  String get categoryDefaultWork => 'Work';

  @override
  String get categoryDeleteBody =>
      'Items in this category will keep existing without a category.';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryName => 'Name';

  @override
  String get categoryNew => 'New category';

  @override
  String get categoryNone => 'No category';

  @override
  String get categoryPick => 'Category';

  @override
  String get categoryUnavailable => 'Counts as unavailable time';

  @override
  String get categoryUnavailableHint =>
      'Excluded from capacity stats (e.g. sleep, time off).';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get confirmDeleteBody => 'You can restore it from Trash for 30 days.';

  @override
  String confirmDeleteTitle(String item) {
    return 'Delete $item?';
  }

  @override
  String deletedSnack(String item) {
    return '$item deleted';
  }

  @override
  String get devMenu => 'Developer menu';

  @override
  String durationDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String durationMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get errorAuth => 'Please sign in again.';

  @override
  String get errorNetwork => 'Can\'t reach the server. Check your connection.';

  @override
  String get errorNotConfigured =>
      'This feature needs cloud configuration (see guide.md).';

  @override
  String get errorNotFound => 'This item no longer exists.';

  @override
  String get errorPermission => 'Permission is needed for this.';

  @override
  String get errorUnknown => 'Unexpected error.';

  @override
  String get errorUnsupportedVersion =>
      'Please update Everslot to keep syncing.';

  @override
  String get errorValidation => 'Please check the highlighted fields.';

  @override
  String get localOnlyBanner =>
      'Cloud sync isn\'t configured — your data stays on this device.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notifActionComplete => 'Complete';

  @override
  String get notifActionDone => 'Done';

  @override
  String get notifActionInputPlaceholder => 'Value';

  @override
  String get notifActionLogCraving => 'Log craving';

  @override
  String get notifActionLogValue => 'Log value';

  @override
  String get notifActionMarkBlocked => 'Mark blocked';

  @override
  String get notifActionMarkOngoing => 'Mark ongoing';

  @override
  String get notifActionMarkRead => 'Mark read';

  @override
  String get notifActionMarkWaiting => 'Mark waiting';

  @override
  String get notifActionMute => 'Mute';

  @override
  String get notifActionOpen => 'Open';

  @override
  String get notifActionReschedule => 'Reschedule';

  @override
  String get notifActionSend => 'Send';

  @override
  String get notifActionSkip => 'Skip';

  @override
  String get notifActionSnooze => 'Snooze';

  @override
  String get notifActionStart => 'Start';

  @override
  String get notifActionStop => 'Stop';

  @override
  String get notifActions => 'Actions';

  @override
  String get notifAddReminder => 'Add reminder';

  @override
  String get notifAdjCatchUp => 'Late';

  @override
  String get notifAdjDeferred => 'Deferred (quiet hours)';

  @override
  String get notifAdjNotLocal => 'Delivered on another device';

  @override
  String get notifAdjPaused => 'Paused — inbox only';

  @override
  String get notifAdjShifted => 'Moved into the time window';

  @override
  String get notifAdjSilent => 'Silent (quiet hours)';

  @override
  String get notifAdvanced => 'Advanced…';

  @override
  String get notifAdvancedTitle => 'Reminder rule';

  @override
  String get notifAfter => 'after';

  @override
  String get notifAllowPrecise => 'Allow precise reminders';

  @override
  String get notifAnchorDue => 'due';

  @override
  String get notifAnchorEnd => 'end';

  @override
  String get notifAnchorFollowUp => 'follow-up';

  @override
  String get notifAnchorPeriodEnd => 'period end';

  @override
  String get notifAnchorPeriodStart => 'period start';

  @override
  String get notifAnchorSlot => 'slot';

  @override
  String get notifAnchorStart => 'start';

  @override
  String get notifAndroidLabel => 'Android';

  @override
  String get notifBadgeDue => 'Overdue + due today';

  @override
  String get notifBadgeOff => 'Off';

  @override
  String get notifBadgePolicy => 'App icon badge';

  @override
  String get notifBadgeUnread => 'Unread inbox';

  @override
  String notifBannerCollapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders',
      one: '1 reminder',
    );
    return '$_temp0';
  }

  @override
  String get notifBannerDismiss => 'Dismiss';

  @override
  String get notifBannerInApp => 'In-app banners';

  @override
  String get notifBannerToggle => 'In-app banner';

  @override
  String get notifBefore => 'before';

  @override
  String get notifBodyChildOverdue => 'A sub-item is overdue';

  @override
  String get notifBodyChildrenComplete =>
      'All sub-items are done — complete it?';

  @override
  String notifBodyCleanDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 free — well done!';
  }

  @override
  String notifBodyDueIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return 'Due in $_temp0';
  }

  @override
  String get notifBodyDueNow => 'Due now';

  @override
  String notifBodyEndedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return 'Ended $_temp0 ago';
  }

  @override
  String get notifBodyEndingNow => 'Ending now';

  @override
  String notifBodyEndsIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return 'Ends in $_temp0';
  }

  @override
  String notifBodyInDays(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'In $_temp0 · $date';
  }

  @override
  String notifBodyInactivity(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'No activity for $_temp0';
  }

  @override
  String notifBodyMilestone(String label) {
    return 'Milestone reached: $label';
  }

  @override
  String notifBodyNotDone(String title) {
    return 'You haven’t logged $title today';
  }

  @override
  String notifBodyOverdue(String title) {
    return '$title is overdue';
  }

  @override
  String notifBodyQuotaBehind(String done, String target, int remaining) {
    return '$done/$target done — $remaining to go';
  }

  @override
  String get notifBodySnoozed => 'Snoozed reminder';

  @override
  String notifBodyStartedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return 'Started $_temp0 ago';
  }

  @override
  String get notifBodyStartingNow => 'Starting now';

  @override
  String notifBodyStartsIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return 'Starts in $_temp0';
  }

  @override
  String notifBodyStatusAge(String status, String age) {
    return 'Still $status · $age';
  }

  @override
  String notifBodyStatusChange(String status) {
    return 'Now $status';
  }

  @override
  String notifBodyStreakRisk(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day',
      one: '1-day',
    );
    return 'Keep your $_temp0 streak alive';
  }

  @override
  String get notifBodyTest => 'Test notification from Everslot';

  @override
  String notifBodyTimeFor(String title) {
    return 'Time for $title';
  }

  @override
  String notifBodyToday(String date) {
    return 'Today · $date';
  }

  @override
  String get notifCategoryDigest => 'Digest';

  @override
  String get notifCategoryMilestone => 'Milestone';

  @override
  String get notifCategoryNag => 'Repeat';

  @override
  String get notifCategoryReminder => 'Reminder';

  @override
  String get notifCategoryStreak => 'Streak';

  @override
  String get notifCategorySystem => 'System';

  @override
  String get notifChannelBlocked => 'Some notification categories are blocked';

  @override
  String get notifChannelDigest => 'Digests';

  @override
  String get notifChannelForeground => 'While Everslot is open';

  @override
  String notifChannelName(String section, String profile) {
    return '$section · $profile';
  }

  @override
  String get notifChannelQuiet => 'Quiet hours';

  @override
  String get notifChannelSystem => 'System notices';

  @override
  String get notifChipAtDue => 'At due';

  @override
  String get notifChipAtEnd => 'At end';

  @override
  String get notifChipAtFollowUp => 'At follow-up';

  @override
  String get notifChipAtSlot => 'At slot time';

  @override
  String get notifChipAtStart => 'At start';

  @override
  String get notifChipAtTime => 'At a time…';

  @override
  String notifChipBefore(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min before',
      one: '1 min before',
    );
    return '$_temp0';
  }

  @override
  String get notifChipCustom => 'Custom…';

  @override
  String notifChipDayBeforeAt(String time) {
    return '1 day before at $time';
  }

  @override
  String get notifChipEvery => 'Every day at…';

  @override
  String get notifChipIfNotDoneBy => 'If not done by…';

  @override
  String get notifChipMilestones => 'Milestones';

  @override
  String notifChipOnDayAt(String time) {
    return 'On the day at $time';
  }

  @override
  String get notifChipStreakRisk => 'Streak at risk';

  @override
  String get notifConditions => 'Conditions';

  @override
  String get notifContent => 'Content';

  @override
  String get notifContentBody => 'Body template';

  @override
  String get notifContentTitle => 'Title template';

  @override
  String notifCreateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count reminders',
      one: 'Add 1 reminder',
    );
    return '$_temp0';
  }

  @override
  String get notifCustomize => 'Customize';

  @override
  String get notifDateOnlyTime => 'Default time for date-only items';

  @override
  String get notifDefaultLateness => 'Deliver late reminders up to';

  @override
  String get notifDefaultProfile => 'Default profile';

  @override
  String get notifDefaultsAddCategory => 'Add category defaults';

  @override
  String get notifDefaultsAllDay => 'All-day items';

  @override
  String get notifDefaultsCategory => 'Category defaults';

  @override
  String get notifDefaultsDateOnly => 'Date-only items';

  @override
  String get notifDefaultsEntry => 'Default reminders';

  @override
  String get notifDefaultsOther => 'Other defaults';

  @override
  String get notifDefaultsTimed => 'Timed items';

  @override
  String get notifDefaultsTitle => 'Default reminders';

  @override
  String get notifDelivery => 'Delivery';

  @override
  String get notifDeviceAll => 'All devices';

  @override
  String get notifDeviceLastActive => 'Last active device';

  @override
  String get notifDevicePrimary => 'Primary device only';

  @override
  String get notifDiagBadge => 'Badge';

  @override
  String get notifDiagBattery => 'Battery optimization';

  @override
  String get notifDiagBatteryBody =>
      'Some phones stop apps in the background. Follow the guide for your phone to keep reminders on time.';

  @override
  String notifDiagBatteryOpen(String maker) {
    return 'Open the guide for $maker';
  }

  @override
  String get notifDiagBlocked => 'Blocked channels';

  @override
  String notifDiagBudget(int used, int total) {
    return 'Budget $used/$total';
  }

  @override
  String get notifDiagCapabilities => 'Capabilities';

  @override
  String get notifDiagCopied => 'Diagnostics copied (no content included)';

  @override
  String get notifDiagCopy => 'Copy diagnostics';

  @override
  String get notifDiagCoverage => 'Covered until';

  @override
  String get notifDiagExact => 'Exact alarms';

  @override
  String get notifDiagLastReplan => 'Last replan';

  @override
  String notifDiagMismatch(int count) {
    return 'Mismatches between the system and the schedule: $count';
  }

  @override
  String get notifDiagNext => 'Next firings';

  @override
  String get notifDiagPendingOs => 'Pending in the system';

  @override
  String get notifDiagPermission => 'Notifications allowed';

  @override
  String get notifDiagProvisional => 'Provisional (quiet) delivery';

  @override
  String get notifDiagPush => 'Push';

  @override
  String get notifDiagPushOff => 'Push not configured — local reminders only';

  @override
  String get notifDiagPushOn => 'Push active';

  @override
  String notifDiagReplanInfo(String time, int ms, String reason) {
    return '$time · $ms ms · $reason';
  }

  @override
  String get notifDiagReplanNow => 'Replan now';

  @override
  String get notifDiagSchedule => 'Schedule';

  @override
  String get notifDiagTimeSensitive => 'Time sensitive';

  @override
  String get notifDiagTitle => 'Notification diagnostics';

  @override
  String get notifDiagTracked => 'Tracked (inbox only or over budget)';

  @override
  String get notifDiagnostics => 'Diagnostics';

  @override
  String notifDigestAt(String time) {
    return 'at $time';
  }

  @override
  String get notifDigestDailyAgenda => 'Today’s agenda';

  @override
  String get notifDigestEveningReview => 'Evening review';

  @override
  String notifDigestFirst(String first) {
    return 'First: $first';
  }

  @override
  String get notifDigestMonthly => 'Monthly report';

  @override
  String get notifDigestOverdue => 'Overdue summary';

  @override
  String get notifDigestPlanTomorrow => 'Plan tomorrow';

  @override
  String notifDigestSummary(int tasks, int habits, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      tasks,
      locale: localeName,
      other: '$tasks tasks',
      one: '1 task',
    );
    String _temp1 = intl.Intl.pluralLogic(
      habits,
      locale: localeName,
      other: '$habits habits',
      one: '1 habit',
    );
    String _temp2 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items list items',
      one: '1 list item',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get notifDigestWeekly => 'Weekly review';

  @override
  String get notifDigests => 'Digests';

  @override
  String get notifDisable => 'Disable';

  @override
  String get notifEditorTitle => 'New reminder';

  @override
  String get notifEnable => 'Turn on';

  @override
  String get notifExactOff => 'Reminders may arrive up to an hour late';

  @override
  String get notifExactOffBody =>
      'Allow precise reminders so they fire at the exact minute.';

  @override
  String get notifFieldAfterDays => 'After (days)';

  @override
  String get notifFieldAfterMinutes => 'After (minutes)';

  @override
  String get notifFieldAtTime => 'At time';

  @override
  String get notifFieldDateTime => 'Date and time';

  @override
  String get notifFieldDayForm => 'N days before or after at a time';

  @override
  String get notifFieldDayOffset => 'Days (negative = before)';

  @override
  String get notifFieldDigestKind => 'Digest';

  @override
  String get notifFieldEveryMinutes => 'Every (minutes)';

  @override
  String get notifFieldMaxTimes => 'At most (times)';

  @override
  String get notifFieldMetric => 'Metric';

  @override
  String get notifFieldMinStreak => 'Minimum streak';

  @override
  String get notifFieldOffset => 'Offset in minutes (negative = before)';

  @override
  String get notifFieldStatuses => 'Statuses';

  @override
  String get notifFieldThresholds =>
      'Thresholds (comma separated, empty = automatic)';

  @override
  String get notifFieldToStatus => 'New status';

  @override
  String get notifFieldUntil => 'Until';

  @override
  String get notifFrom => 'From';

  @override
  String get notifHideContent => 'Hide content in notifications';

  @override
  String notifImpact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Affects $_temp0 that use defaults';
  }

  @override
  String get notifImportance => 'Importance';

  @override
  String get notifImportanceDefault => 'Default';

  @override
  String get notifImportanceHigh => 'High';

  @override
  String get notifImportanceLow => 'Low';

  @override
  String get notifImportanceMin => 'Minimal';

  @override
  String get notifImportanceUrgent => 'Urgent';

  @override
  String get notifInboxAlreadyDone => 'Already done';

  @override
  String get notifInboxCaughtUp => 'All caught up';

  @override
  String get notifInboxChangeSnooze => 'Change snooze';

  @override
  String get notifInboxDismissSelected => 'Dismiss';

  @override
  String get notifInboxDismissed => 'Notification dismissed';

  @override
  String get notifInboxEmpty => 'No notifications yet';

  @override
  String get notifInboxEmptyBody => 'Reminders you receive appear here.';

  @override
  String get notifInboxFilterAll => 'All';

  @override
  String get notifInboxFilterUnread => 'Unread';

  @override
  String get notifInboxHistory => 'Reminder history';

  @override
  String get notifInboxHistoryEmpty => 'No reminders yet';

  @override
  String get notifInboxLate => 'Late';

  @override
  String get notifInboxMarkAllRead => 'Mark all read';

  @override
  String get notifInboxMarkedRead => 'Marked as read';

  @override
  String get notifInboxMarkedUnread => 'Marked as unread';

  @override
  String get notifInboxMuteRule => 'Mute this reminder';

  @override
  String notifInboxNagCount(int count) {
    return '×$count';
  }

  @override
  String get notifInboxRemindAgain => 'Remind me again…';

  @override
  String get notifInboxSearch => 'Search notifications';

  @override
  String notifInboxSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get notifInboxSnoozed => 'Snoozed';

  @override
  String notifInboxSnoozedUntil(String time) {
    return 'Snoozed until $time';
  }

  @override
  String get notifInboxTitle => 'Inbox';

  @override
  String get notifInboxToday => 'Today';

  @override
  String get notifInboxToggle => 'Show in inbox';

  @override
  String notifInboxUnreadSemantics(String title) {
    return 'Unread reminder, $title';
  }

  @override
  String get notifInboxWakeNow => 'Wake now';

  @override
  String get notifInboxYesterday => 'Yesterday';

  @override
  String get notifInherit => 'Inherit';

  @override
  String notifInheritedFrom(String source) {
    return 'From $source';
  }

  @override
  String notifInheritedFromProfile(String name) {
    return 'Inherited from $name';
  }

  @override
  String get notifInterruption => 'Interruption level (iOS)';

  @override
  String get notifInterruptionActive => 'Active';

  @override
  String get notifInterruptionPassive => 'Passive';

  @override
  String get notifInterruptionTimeSensitive => 'Time sensitive';

  @override
  String get notifIosLabel => 'iOS';

  @override
  String get notifIssueAnchorUnavailable =>
      'This anchor isn’t available for this item';

  @override
  String get notifIssueEmptyContent => 'The title can’t be empty';

  @override
  String get notifIssueLateness => 'Lateness must be at least 1 minute';

  @override
  String get notifIssueNoChannel => 'Choose at least one way to be notified';

  @override
  String get notifIssueOffsetOutOfRange => 'The offset must be within 30 days';

  @override
  String get notifIssueRepeatInterval => 'Repeat at least every minute';

  @override
  String get notifIssueRepeatMax => 'At most 10 repeats';

  @override
  String get notifIssueSchedule => 'Invalid schedule';

  @override
  String get notifIssueStatuses => 'Choose at least one status';

  @override
  String get notifIssueThresholds => 'Invalid thresholds';

  @override
  String get notifIssueTooManyActions =>
      'Android shows only the first 3 actions';

  @override
  String get notifIssueUnknownTrigger =>
      'This rule type isn’t supported by this version';

  @override
  String notifIssueUnknownVariable(String names) {
    return 'Unknown variable: $names';
  }

  @override
  String get notifItemKind => 'Item kind';

  @override
  String get notifItemKindAllDay => 'All-day';

  @override
  String get notifItemKindAny => 'Any';

  @override
  String get notifItemKindDateOnly => 'Date only';

  @override
  String get notifItemKindTimed => 'Timed';

  @override
  String get notifLateness => 'Still deliver if late by up to (minutes)';

  @override
  String get notifMakePrimary => 'Use this device as primary';

  @override
  String get notifMaxNag => 'Maximum nag repeats';

  @override
  String notifMergedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders',
      one: '1 reminder',
    );
    return '$_temp0';
  }

  @override
  String get notifMetricCleanDays => 'Clean days';

  @override
  String get notifMetricMoney => 'Money saved';

  @override
  String get notifMetricStreak => 'Streak';

  @override
  String get notifMetricTotal => 'Total';

  @override
  String get notifMetricUnits => 'Units avoided';

  @override
  String notifMinutesValue(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String get notifModeCustom => 'Custom';

  @override
  String get notifModeInherit => 'Use defaults';

  @override
  String get notifModeInheritPlus => 'Defaults + mine';

  @override
  String get notifModeOff => 'Off';

  @override
  String get notifMultiDevice => 'Deliver to';

  @override
  String get notifMute1h => '1 hour';

  @override
  String get notifMuteFor => 'Mute…';

  @override
  String get notifMuteForever => 'Until I unmute';

  @override
  String get notifMuteToday => 'Rest of today';

  @override
  String get notifMuteTomorrow => 'Until tomorrow';

  @override
  String get notifMuteWeek => 'For a week';

  @override
  String get notifMuted => 'Muted';

  @override
  String get notifMutedForever => 'Muted until unmuted';

  @override
  String get notifMutedSnack => 'Muted until tomorrow';

  @override
  String notifMutedUntil(String time) {
    return 'Muted until $time';
  }

  @override
  String get notifMutes => 'Muted';

  @override
  String get notifMutesNone => 'Nothing is muted';

  @override
  String get notifNever => 'Never';

  @override
  String get notifNextFirings => 'Next reminders';

  @override
  String get notifNo => 'No';

  @override
  String get notifNoReminders => 'No reminders';

  @override
  String get notifNoUpcoming => 'Nothing scheduled in the next 14 days';

  @override
  String get notifNoiseBlocked =>
      'Too many notifications (more than 1 440 per day)';

  @override
  String get notifNoiseCluster =>
      'Several reminders share this minute — only one sound plays';

  @override
  String notifNoiseConfirm(int perDay) {
    return 'This reminder sends about $perDay notifications per day. Save anyway?';
  }

  @override
  String notifNoiseWarn(int perDay) {
    return 'About $perDay notifications per day';
  }

  @override
  String get notifOffsetAmount => 'Amount';

  @override
  String get notifOnlyIfStatus => 'Only if status is';

  @override
  String get notifOpenSettings => 'Open settings';

  @override
  String get notifOutsideDrop => 'Drop outside';

  @override
  String get notifOutsideShiftEnd => 'Move to window end';

  @override
  String get notifOutsideShiftStart => 'Move to window start';

  @override
  String get notifPause1h => '1 hour';

  @override
  String get notifPauseAll => 'Pause all';

  @override
  String get notifPauseCustom => 'Custom…';

  @override
  String get notifPauseTomorrow => 'Until tomorrow 08:00';

  @override
  String notifPausedUntil(String time) {
    return 'Paused until $time';
  }

  @override
  String get notifPermissionOff => 'Notifications are turned off';

  @override
  String get notifPermissionOffBody =>
      'Turn them on to receive your reminders.';

  @override
  String get notifPreview => 'Preview';

  @override
  String get notifPrimerAllow => 'Allow notifications';

  @override
  String get notifPrimerBody =>
      'Everslot reminds you before tasks start, when habits are due and when lists need a follow-up. You decide exactly when.';

  @override
  String get notifPrimerExactBody =>
      'Android needs your permission to deliver reminders at the exact minute. Without it they may be up to an hour late.';

  @override
  String get notifPrimerExactTitle => 'Precise reminders';

  @override
  String get notifPrimerLater => 'Not now';

  @override
  String get notifPrimerTimeSensitiveBody =>
      'Important reminders can break through Focus modes. You can change this in iOS Settings at any time.';

  @override
  String get notifPrimerTimeSensitiveTitle => 'Time-sensitive reminders';

  @override
  String get notifPrimerTitle => 'Never miss what matters';

  @override
  String get notifProfile => 'Profile';

  @override
  String get notifProfileAlarm => 'Alarm';

  @override
  String get notifProfileBuiltin => 'Built-in';

  @override
  String get notifProfileChannelWarning =>
      'Changing importance, sound or vibration creates a new Android notification category; the old one appears as deleted in system settings.';

  @override
  String get notifProfileDelete => 'Delete profile';

  @override
  String notifProfileDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders use this profile.',
      one: '1 reminder uses this profile.',
    );
    return '$_temp0 Move them to:';
  }

  @override
  String get notifProfileDuplicate => 'Duplicate';

  @override
  String get notifProfileGentle => 'Gentle';

  @override
  String get notifProfileNag => 'Nag until done';

  @override
  String get notifProfileName => 'Name';

  @override
  String get notifProfileNew => 'New profile';

  @override
  String get notifProfileNone => 'No profile';

  @override
  String get notifProfileRename => 'Rename';

  @override
  String get notifProfileStandard => 'Standard';

  @override
  String get notifProfilesEntry => 'Profiles';

  @override
  String get notifProfilesTitle => 'Notification profiles';

  @override
  String get notifProvenanceAncestor => 'parent item';

  @override
  String get notifProvenanceCategory => 'category';

  @override
  String get notifProvenanceChecklist => 'list';

  @override
  String get notifProvenanceGlobal => 'global defaults';

  @override
  String get notifProvenanceOccurrence => 'this occurrence only';

  @override
  String get notifProvenanceSection => 'section defaults';

  @override
  String get notifQuietAdd => 'Add quiet hours';

  @override
  String get notifQuietDefer => 'Defer to the end';

  @override
  String get notifQuietDrop => 'Drop';

  @override
  String get notifQuietHours => 'Quiet hours';

  @override
  String get notifQuietMode => 'Mode';

  @override
  String get notifQuietNone => 'No quiet hours';

  @override
  String get notifQuietSilent => 'Deliver silently';

  @override
  String notifQuietWindow(String from, String to) {
    return '$from – $to';
  }

  @override
  String get notifRedactedBody => 'Open Everslot to see it';

  @override
  String get notifRedactedTitle => 'Reminder from Everslot';

  @override
  String get notifRepeat => 'Repeat (nag)';

  @override
  String get notifRespectQuiet => 'Respect quiet hours';

  @override
  String get notifResume => 'Resume';

  @override
  String get notifRuleDeleted => 'Reminder deleted';

  @override
  String get notifRuleEnabled => 'Reminder enabled';

  @override
  String get notifRuleSaved => 'Reminder saved';

  @override
  String get notifSaturationBody =>
      'Open Everslot to keep your reminders up to date';

  @override
  String get notifSaturationTitle => 'Open Everslot';

  @override
  String get notifSectionChecklists => 'Lists';

  @override
  String get notifSectionDigests => 'Digests';

  @override
  String get notifSectionHabits => 'Habits';

  @override
  String get notifSectionPlanner => 'Plan';

  @override
  String get notifSectionQuit => 'Quit';

  @override
  String get notifSectionSystem => 'System';

  @override
  String get notifSectionTitle => 'Notifications';

  @override
  String get notifSendTest => 'Send test notification';

  @override
  String get notifSettingsSections => 'Sections';

  @override
  String get notifSettingsTitle => 'Notifications';

  @override
  String notifShowAll(int count) {
    return 'Show all ($count)';
  }

  @override
  String get notifSkipAck => 'Acknowledged';

  @override
  String get notifSkipCap => 'Daily limit reached';

  @override
  String get notifSkipDone => 'Already done';

  @override
  String get notifSkipExpired => 'Too late';

  @override
  String get notifSkipMuted => 'Muted';

  @override
  String get notifSkipNoChannel => 'No delivery channel';

  @override
  String get notifSkipQuiet => 'Dropped (quiet hours)';

  @override
  String get notifSkipStatus => 'Status doesn’t match';

  @override
  String get notifSkipWeekday => 'Not on this weekday';

  @override
  String get notifSkipWindow => 'Outside the time window';

  @override
  String get notifSnoozeCustom => 'Custom…';

  @override
  String get notifSnoozeEvening => 'This evening';

  @override
  String notifSnoozeHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get notifSnoozeLimit => 'Snooze limit reached';

  @override
  String notifSnoozeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String get notifSnoozeOptions => 'Snooze options (minutes)';

  @override
  String get notifSnoozePresets => 'Snooze presets';

  @override
  String get notifSnoozeTomorrow => 'Tomorrow morning';

  @override
  String notifSnoozedSnack(String time) {
    return 'Snoozed until $time';
  }

  @override
  String get notifSound => 'Sound';

  @override
  String get notifSoundAlarm => 'Alarm';

  @override
  String get notifSoundBell => 'Bell';

  @override
  String get notifSoundChime => 'Chime';

  @override
  String get notifSoundDefault => 'Default';

  @override
  String get notifSoundNone => 'None';

  @override
  String get notifSoundPop => 'Pop';

  @override
  String get notifSoundSoft => 'Soft';

  @override
  String get notifSticky => 'Keep until done (Android)';

  @override
  String notifSumAbsolute(String dateTime) {
    return 'On $dateTime';
  }

  @override
  String notifSumAfterDue(String duration) {
    return '$duration after due';
  }

  @override
  String notifSumAfterEnd(String duration) {
    return '$duration after end';
  }

  @override
  String notifSumAfterStart(String duration) {
    return '$duration after start';
  }

  @override
  String get notifSumAtDue => 'At due';

  @override
  String get notifSumAtEnd => 'At end';

  @override
  String get notifSumAtFollowUp => 'At follow-up';

  @override
  String get notifSumAtPeriodEnd => 'At period end';

  @override
  String get notifSumAtPeriodStart => 'At period start';

  @override
  String get notifSumAtSlot => 'At slot time';

  @override
  String get notifSumAtStart => 'At start';

  @override
  String notifSumBeforeDue(String duration) {
    return '$duration before due';
  }

  @override
  String notifSumBeforeEnd(String duration) {
    return '$duration before end';
  }

  @override
  String notifSumBeforeStart(String duration) {
    return '$duration before start';
  }

  @override
  String get notifSumChildOverdue => 'When a sub-item is overdue';

  @override
  String get notifSumChildrenComplete => 'When all sub-items are done';

  @override
  String notifSumDaysAfter(int days, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 after at $time';
  }

  @override
  String notifSumDaysBefore(int days, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 before at $time';
  }

  @override
  String notifSumInactivity(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'After $_temp0 without activity';
  }

  @override
  String get notifSumMilestones => 'Milestones';

  @override
  String notifSumNotDoneBy(String time) {
    return 'If not done by $time';
  }

  @override
  String get notifSumNotDoneByEnd => 'If not done by the end';

  @override
  String notifSumOnDayAt(String time) {
    return 'On the day at $time';
  }

  @override
  String get notifSumOverdue => 'When overdue';

  @override
  String notifSumQuotaBehind(String time) {
    return 'Behind pace, at $time';
  }

  @override
  String notifSumRepeat(int minutes, int times) {
    return 'repeats every $minutes min ×$times';
  }

  @override
  String get notifSumSchedule => 'On a repeating schedule';

  @override
  String notifSumStale(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'After $_temp0 without progress';
  }

  @override
  String notifSumStatusAge(String duration) {
    return 'Still waiting or blocked after $duration';
  }

  @override
  String notifSumStatusChange(String status) {
    return 'When it becomes $status';
  }

  @override
  String notifSumStreakRisk(String time) {
    return 'Streak at risk, at $time';
  }

  @override
  String get notifSumUnknown => 'Unsupported rule';

  @override
  String get notifSystemNotification => 'System notification';

  @override
  String get notifTestSent => 'Test notification in 5 seconds';

  @override
  String get notifThisDeviceIsPrimary => 'This device is the primary device';

  @override
  String get notifTimeWindow => 'Time window';

  @override
  String notifTitleFollowUp(String title) {
    return 'Follow up: $title';
  }

  @override
  String get notifTo => 'To';

  @override
  String get notifTrigger => 'Trigger';

  @override
  String get notifTriggerAbsolute => 'At a date and time';

  @override
  String get notifTriggerChildOverdue => 'Sub-item overdue';

  @override
  String get notifTriggerChildrenComplete => 'All sub-items done';

  @override
  String get notifTriggerDigest => 'Digest';

  @override
  String get notifTriggerInactivity => 'Inactivity';

  @override
  String get notifTriggerMilestone => 'Milestone';

  @override
  String get notifTriggerNotDoneBy => 'If not done by';

  @override
  String get notifTriggerOverdue => 'Overdue';

  @override
  String get notifTriggerQuotaBehind => 'Behind pace';

  @override
  String get notifTriggerRelative => 'Relative to the item';

  @override
  String get notifTriggerSchedule => 'Repeating schedule';

  @override
  String get notifTriggerStale => 'No progress';

  @override
  String get notifTriggerStatusAge => 'Status age';

  @override
  String get notifTriggerStatusChange => 'Status change';

  @override
  String get notifTriggerStreakRisk => 'Streak at risk';

  @override
  String get notifUnitDays => 'days';

  @override
  String get notifUnitHours => 'hours';

  @override
  String get notifUnitMinutes => 'minutes';

  @override
  String get notifUnitWeeks => 'weeks';

  @override
  String get notifUnknown => 'Unknown';

  @override
  String get notifUnmute => 'Unmute';

  @override
  String get notifUntilAcknowledged => 'acknowledged';

  @override
  String get notifUntilCompleted => 'completed';

  @override
  String get notifUntilMax => 'maximum reached';

  @override
  String get notifVariables => 'Variables';

  @override
  String get notifVibration => 'Vibration';

  @override
  String get notifVibrationDefault => 'Default';

  @override
  String get notifVibrationLong => 'Long';

  @override
  String get notifVibrationNone => 'None';

  @override
  String get notifVibrationShort => 'Short';

  @override
  String get notifWeekdays => 'Only on';

  @override
  String get notifYes => 'Yes';

  @override
  String get pickerColor => 'Color';

  @override
  String get pickerDate => 'Date';

  @override
  String get pickerDays => 'Days';

  @override
  String get pickerDuration => 'Duration';

  @override
  String get pickerHours => 'Hours';

  @override
  String get pickerIcon => 'Icon';

  @override
  String get pickerMinutes => 'Minutes';

  @override
  String get pickerNoColor => 'No color';

  @override
  String get pickerSearchIcons => 'Search icons';

  @override
  String get pickerTime => 'Time';

  @override
  String get placeholderScreen => 'This screen is being built.';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityNone => 'No priority';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String relativeInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'tomorrow',
    );
    return '$_temp0';
  }

  @override
  String relativeInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count hours',
      one: 'in 1 hour',
    );
    return '$_temp0';
  }

  @override
  String relativeInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count minutes',
      one: 'in 1 minute',
    );
    return '$_temp0';
  }

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String get relativeNow => 'now';

  @override
  String get savedSnack => 'Saved';

  @override
  String get stateEmpty => 'Nothing here yet';

  @override
  String get stateErrorBody => 'Please try again.';

  @override
  String get stateErrorTitle => 'Something went wrong';

  @override
  String get stateLoading => 'Loading…';

  @override
  String get syncError => 'Sync problem';

  @override
  String get syncIdle => 'Synced';

  @override
  String get syncLocalOnly => 'On this device only';

  @override
  String get syncOffline => 'Offline — changes will sync later';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting',
      one: '1 change waiting',
      zero: 'No pending changes',
    );
    return '$_temp0';
  }

  @override
  String get syncPulling => 'Updating…';

  @override
  String get syncPushing => 'Uploading changes…';

  @override
  String get tabHabits => 'Habits';

  @override
  String get tabInsights => 'Insights';

  @override
  String get tabLists => 'Lists';

  @override
  String get tabPlan => 'Plan';

  @override
  String get tabToday => 'Today';
}
