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
  String get attachmentsAdd => 'Add attachment';

  @override
  String attachmentsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments added',
      one: '1 attachment added',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsCacheCleared => 'Cache cleared';

  @override
  String attachmentsCacheSize(String size) {
    return 'Local cache: $size';
  }

  @override
  String get attachmentsCameraPrimerBody =>
      'Everslot asks for camera access so you can attach photos. Photos stay on your device until they\'re uploaded to your account.';

  @override
  String get attachmentsCameraPrimerTitle => 'Use your camera';

  @override
  String get attachmentsCaption => 'Caption';

  @override
  String get attachmentsClearCache => 'Clear cache';

  @override
  String attachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments',
      one: '1 attachment',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsDownloadWhenOnline =>
      'This file will download when you\'re online.';

  @override
  String get attachmentsEditCaption => 'Edit caption';

  @override
  String get attachmentsEmpty => 'No attachments yet';

  @override
  String get attachmentsGoToItem => 'Go to item';

  @override
  String get attachmentsKindAudio => 'Audio';

  @override
  String get attachmentsKindFile => 'File';

  @override
  String get attachmentsKindPdf => 'PDF';

  @override
  String get attachmentsKindPhoto => 'Photo';

  @override
  String get attachmentsKindVideo => 'Video';

  @override
  String get attachmentsLocalOnly => 'Stored on this device';

  @override
  String attachmentsMore(int count) {
    return '+$count';
  }

  @override
  String get attachmentsMoveEarlier => 'Move earlier';

  @override
  String get attachmentsMoveLater => 'Move later';

  @override
  String get attachmentsNoPreview => 'No preview for this file type';

  @override
  String get attachmentsOpenSettings => 'Open settings';

  @override
  String get attachmentsOpenWith => 'Open with…';

  @override
  String attachmentsPendingUploads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uploads pending',
      one: '1 upload pending',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsPermissionBody =>
      'Everslot can\'t access your camera or photos. You can allow access in the system settings.';

  @override
  String get attachmentsPermissionTitle => 'Access needed';

  @override
  String attachmentsRejectedDuplicate(String name) {
    return '$name is already attached';
  }

  @override
  String attachmentsRejectedEmpty(String name) {
    return '$name is empty';
  }

  @override
  String attachmentsRejectedTooLarge(String name, String limit) {
    return '$name is larger than $limit';
  }

  @override
  String attachmentsRejectedTooMany(int count) {
    return 'Limit of $count attachments reached';
  }

  @override
  String attachmentsRejectedType(String name) {
    return '$name: this file type isn\'t supported';
  }

  @override
  String attachmentsRejectedUnreadable(String name) {
    return '$name couldn\'t be read';
  }

  @override
  String get attachmentsRemove => 'Remove';

  @override
  String get attachmentsRemoved => 'Attachment removed';

  @override
  String get attachmentsRetry => 'Retry upload';

  @override
  String attachmentsSemantics(String kind, int index, int total) {
    return '$kind $index of $total';
  }

  @override
  String get attachmentsSettingsTitle => 'Attachments';

  @override
  String attachmentsSizeB(String size) {
    return '$size B';
  }

  @override
  String attachmentsSizeGb(String size) {
    return '$size GB';
  }

  @override
  String attachmentsSizeKb(String size) {
    return '$size KB';
  }

  @override
  String attachmentsSizeMb(String size) {
    return '$size MB';
  }

  @override
  String get attachmentsSourceCamera => 'Take photo';

  @override
  String get attachmentsSourceFiles => 'Choose files';

  @override
  String get attachmentsSourcePhotos => 'Choose photos';

  @override
  String get attachmentsStatusDownloading => 'Downloading';

  @override
  String get attachmentsStatusFailed => 'Upload failed — tap to retry';

  @override
  String get attachmentsStatusNotDownloaded => 'Not downloaded — tap to fetch';

  @override
  String get attachmentsStatusProcessing => 'Processing';

  @override
  String attachmentsStatusUploading(int percent) {
    return 'Uploading $percent %';
  }

  @override
  String get attachmentsStatusUploadingShort => 'Uploading';

  @override
  String get attachmentsStatusWaiting => 'Waiting for network';

  @override
  String attachmentsStorageUsed(String size) {
    return 'Storage used: $size';
  }

  @override
  String attachmentsViewerPosition(int index, int total) {
    return '$index / $total';
  }

  @override
  String get attachmentsWifiOnly => 'Upload attachments on Wi-Fi only';

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
  String get notifModeOffHint => 'No notifications for this item';

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
  String notifSectionOffHint(String section) {
    return '$section notifications are turned off in Settings';
  }

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
  String get pvActualColumn => 'Actual';

  @override
  String get pvAddTask => 'Add task';

  @override
  String get pvAddZone => 'Add time zone';

  @override
  String get pvAllDay => 'All day';

  @override
  String get pvAllDaySection => 'All day & untimed';

  @override
  String get pvApplyToView => 'Apply to this view';

  @override
  String get pvAutoAdvance => 'Auto-advance';

  @override
  String get pvAutoScrollNow => 'Scroll to now on open';

  @override
  String get pvBacklogEmpty => 'Your backlog is empty';

  @override
  String get pvCancelOccurrence => 'Cancel this occurrence';

  @override
  String get pvCannotUnschedule =>
      'Recurring occurrences can\'t be moved to the backlog';

  @override
  String get pvCapacity => 'Capacity';

  @override
  String get pvCategories => 'Categories';

  @override
  String get pvClearFilters => 'Clear';

  @override
  String get pvClocksForward => 'Clocks forward';

  @override
  String get pvColCategory => 'Category';

  @override
  String get pvColDate => 'Date';

  @override
  String get pvColDuration => 'Duration';

  @override
  String get pvColEnd => 'End';

  @override
  String get pvColLocation => 'Place';

  @override
  String get pvColPriority => 'Priority';

  @override
  String get pvColRecurrence => 'Repeats';

  @override
  String get pvColStart => 'Start';

  @override
  String get pvColStatus => 'Status';

  @override
  String get pvColTitle => 'Title';

  @override
  String get pvColTracking => 'Tracking';

  @override
  String get pvCollapse => 'Collapse';

  @override
  String get pvColorBy => 'Color by';

  @override
  String get pvColorByCategory => 'Category';

  @override
  String get pvColorByPriority => 'Priority';

  @override
  String get pvColorByStatus => 'Status';

  @override
  String get pvColorByTask => 'Task';

  @override
  String get pvColumns => 'Columns';

  @override
  String get pvCompletion => 'Completion';

  @override
  String get pvContinues => 'continues';

  @override
  String pvCopySuffix(String name) {
    return '$name (copy)';
  }

  @override
  String get pvCreate => 'Create';

  @override
  String get pvCreateHere => 'Create here';

  @override
  String get pvCreatedSnack => 'Task created';

  @override
  String pvDayHeaderSemantics(String day, String items) {
    return '$day, $items';
  }

  @override
  String get pvDayRibbon => 'Day';

  @override
  String pvDayStats(String done, String total, String planned) {
    return '$done/$total · $planned';
  }

  @override
  String get pvDaySummary => 'Day summary';

  @override
  String get pvDayTicker => 'Day ticker';

  @override
  String pvDaysSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String pvDaysUntil(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get pvDaysVisible => 'Days visible';

  @override
  String get pvDaysVisibleLandscape => 'Days in landscape';

  @override
  String get pvDefaultBadge => 'Default';

  @override
  String get pvDeleteView => 'Delete view';

  @override
  String get pvDemoData => 'Demo data (developer)';

  @override
  String get pvDensity => 'Density';

  @override
  String get pvDensityComfortable => 'Comfortable';

  @override
  String get pvDensityCompact => 'Compact';

  @override
  String get pvDimPast => 'Dim past';

  @override
  String get pvDoneTotal => 'Done';

  @override
  String get pvDragToSchedule => 'Drag onto the grid to schedule';

  @override
  String get pvDropNotSupported =>
      'This grouping can\'t be changed by dragging yet';

  @override
  String get pvDuplicateView => 'Duplicate view';

  @override
  String pvElapsed(String duration) {
    return '$duration elapsed';
  }

  @override
  String get pvEmptyDay => 'Nothing planned';

  @override
  String get pvEmptyRange => 'Nothing in this range';

  @override
  String pvEmptySlotSemantics(String day, String time) {
    return '$day $time, empty, double-tap to create';
  }

  @override
  String get pvEmptyWeekTitle => 'Nothing planned this week';

  @override
  String get pvExpand => 'Expand';

  @override
  String get pvExpandInline => 'Expand day inline';

  @override
  String get pvExtend => 'Extend';

  @override
  String pvExtendBy(int minutes) {
    return '+$minutes min';
  }

  @override
  String get pvExtraZones => 'Extra time zones';

  @override
  String get pvFillFromBacklog => 'Fill from backlog';

  @override
  String get pvFillGap => 'Fill this gap';

  @override
  String get pvFilter => 'Filter';

  @override
  String get pvFilters => 'Filters';

  @override
  String get pvFinish => 'Finish';

  @override
  String pvFreeGap(String duration) {
    return 'free $duration';
  }

  @override
  String get pvFreeInWorkHours => 'Free in work hours';

  @override
  String pvFreeRun(String from, String to, String duration) {
    return 'Free $from–$to · $duration';
  }

  @override
  String get pvFrom => 'From';

  @override
  String get pvGotIt => 'Got it';

  @override
  String get pvGroupBy => 'Group by';

  @override
  String get pvGroupCategory => 'Category';

  @override
  String get pvGroupDay => 'Day';

  @override
  String get pvGroupNone => 'None';

  @override
  String get pvGroupPriority => 'Priority';

  @override
  String get pvGroupStatus => 'Status';

  @override
  String get pvGroupTask => 'Task';

  @override
  String get pvHeatMetric => 'Metric';

  @override
  String pvHiddenRange(String from, String to) {
    return 'Hidden $from–$to';
  }

  @override
  String get pvHideEmptySlots => 'Collapse empty slots';

  @override
  String get pvHintLongPress => 'Long-press empty space to create a task';

  @override
  String get pvHintPinch =>
      'Pinch to zoom; pinch sideways to change the number of days';

  @override
  String pvHintSlotSize(String size) {
    return 'Tap $size to change the row size';
  }

  @override
  String get pvHorizonDay => 'Today';

  @override
  String get pvHorizonMonth => 'This month';

  @override
  String get pvHorizonQuarter => 'This quarter';

  @override
  String get pvHorizonWeek => 'This week';

  @override
  String get pvHorizonYear => 'This year';

  @override
  String get pvHorizonsHint =>
      'Unscheduled intentions per horizon (stored on this device until horizons sync).';

  @override
  String get pvIgnoreLowPriority => 'Ignore low-priority tasks';

  @override
  String pvImportanceRule(String priority) {
    return 'Important from priority $priority';
  }

  @override
  String pvItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get pvJumpToDate => 'Jump to date';

  @override
  String get pvKeepScreenOn => 'Keep screen on';

  @override
  String get pvLaneCap => 'Side-by-side lanes';

  @override
  String get pvLanes => 'Lanes';

  @override
  String pvLastRowShort(String duration) {
    return 'the last one $duration';
  }

  @override
  String get pvLess => 'Less';

  @override
  String get pvListBelow => 'List below';

  @override
  String get pvListMode => 'Accessible list';

  @override
  String get pvMapPlaceholder =>
      'The map needs task coordinates, which arrive with the place picker. Tasks with a place are listed below.';

  @override
  String get pvMarkDone => 'Mark done';

  @override
  String get pvMarkNotDone => 'Mark not done';

  @override
  String get pvMetricCompletion => 'Completion rate';

  @override
  String get pvMetricCount => 'Number of items';

  @override
  String get pvMetricPlanned => 'Planned hours';

  @override
  String get pvMinGap => 'Minimum gap';

  @override
  String get pvMonthBars => 'Bars';

  @override
  String get pvMonthDots => 'Dots';

  @override
  String get pvMonthTitles => 'Titles';

  @override
  String get pvMonthTitlesTimes => 'Titles and times';

  @override
  String pvMore(String count) {
    return '+$count';
  }

  @override
  String pvMoreItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more items',
      one: '1 more item',
    );
    return '$_temp0';
  }

  @override
  String get pvMoreLegend => 'More';

  @override
  String get pvMoreOptions => 'More options';

  @override
  String get pvMove => 'Move';

  @override
  String get pvMoveDoneBody =>
      'It\'s already done — moving it changes its history.';

  @override
  String get pvMoveDoneTitle => 'Move a completed task?';

  @override
  String pvMoveEarlier(int minutes) {
    return 'Move $minutes min earlier';
  }

  @override
  String pvMoveLater(int minutes) {
    return 'Move $minutes min later';
  }

  @override
  String get pvMoveTo => 'Move to…';

  @override
  String get pvMoveUnfinishedTomorrow => 'Move unfinished to tomorrow';

  @override
  String pvMovedSnack(String when) {
    return 'Moved to $when';
  }

  @override
  String get pvNext => 'Next';

  @override
  String get pvNextDay => 'Next day';

  @override
  String pvNextDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Next $count days',
      one: 'Next day',
    );
    return '$_temp0';
  }

  @override
  String get pvNextUp => 'Next up';

  @override
  String get pvNextWeek => 'Next week';

  @override
  String get pvNoCategory => 'No category';

  @override
  String get pvNoOpenings => 'No free time found';

  @override
  String pvNoRoom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items didn\'t fit',
      one: '1 item didn\'t fit',
    );
    return '$_temp0';
  }

  @override
  String get pvNoRoutine => 'No routine block today';

  @override
  String get pvNoTasks => 'No tasks';

  @override
  String get pvNothingNow => 'Nothing scheduled right now';

  @override
  String get pvNow => 'Now';

  @override
  String get pvOneOff => 'One-off';

  @override
  String get pvOpenDay => 'Open day';

  @override
  String get pvOpenings => 'Openings';

  @override
  String get pvOverdue => 'Overdue';

  @override
  String get pvOverlapCascade => 'Cascade';

  @override
  String get pvOverlapColumns => 'Columns';

  @override
  String get pvOverlapStyle => 'Overlap style';

  @override
  String get pvOverlayChecklistDue => 'Checklist items due';

  @override
  String get pvOverlayDeviceCalendars => 'Device calendars';

  @override
  String get pvOverlayFreeSlots => 'Free time';

  @override
  String get pvOverlayHabits => 'Habits due';

  @override
  String get pvOverlayHeat => 'Busy-hour heat';

  @override
  String get pvOverlays => 'Overlays';

  @override
  String get pvPagingDay => 'One day';

  @override
  String get pvPagingFree => 'Free scroll';

  @override
  String get pvPagingMode => 'Swipe moves';

  @override
  String get pvPagingWeek => 'One week';

  @override
  String get pvPause => 'Pause';

  @override
  String get pvPickDate => 'Pick a date';

  @override
  String get pvPin => 'Pin';

  @override
  String get pvPinned => 'Pinned';

  @override
  String get pvPlanColumn => 'Plan';

  @override
  String get pvPlanFirstTask => 'Plan your first task';

  @override
  String get pvPlanned => 'Planned';

  @override
  String get pvPostpone => 'Postpone';

  @override
  String pvPostponeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get pvPostponeNextWeek => 'Next week';

  @override
  String get pvPostponeTomorrow => 'Tomorrow';

  @override
  String get pvPrevious => 'Previous';

  @override
  String get pvPreviousDay => 'Previous day';

  @override
  String get pvPreviousWeek => 'Previous week';

  @override
  String get pvPriorities => 'Priorities';

  @override
  String get pvQuadDelegate => 'Delegate';

  @override
  String get pvQuadDo => 'Do';

  @override
  String get pvQuadEliminate => 'Eliminate';

  @override
  String get pvQuadSchedule => 'Schedule';

  @override
  String get pvQuickCreateHint => 'What\'s the plan?';

  @override
  String get pvQuickCreateTitle => 'New task';

  @override
  String get pvRadial12 => '12 h';

  @override
  String get pvRadial24 => '24 h';

  @override
  String get pvRadialHours => 'Dial';

  @override
  String get pvRecurring => 'Recurring';

  @override
  String get pvRenameView => 'Rename view';

  @override
  String get pvRenderAuto => 'Auto';

  @override
  String get pvRenderMode => 'Render';

  @override
  String get pvRenderTable => 'Table';

  @override
  String get pvRenderTimeline => 'Timeline';

  @override
  String pvRepeatedHour(String time, String offset) {
    return '$time ($offset)';
  }

  @override
  String get pvRepeats => 'repeats';

  @override
  String get pvResetView => 'Reset view settings';

  @override
  String pvResizedSnack(String duration) {
    return 'Duration $duration';
  }

  @override
  String get pvRibbonStyle => 'Ribbon';

  @override
  String get pvRoutineComplete => 'Routine complete';

  @override
  String get pvRoutineStart => 'Start routine';

  @override
  String pvRoutineSummary(int done, int total) {
    return '$done of $total steps done';
  }

  @override
  String get pvRowHeight => 'Row height';

  @override
  String get pvRowsOccurrences => 'Occurrences';

  @override
  String pvRowsPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows per day',
      one: '1 row per day',
    );
    return '$_temp0';
  }

  @override
  String get pvRowsTasks => 'Tasks';

  @override
  String get pvRules => 'Rules';

  @override
  String get pvSaveAsNewView => 'Save as new view';

  @override
  String get pvSaveViewAs => 'Save view as…';

  @override
  String get pvSavedViews => 'Saved views';

  @override
  String get pvScale => 'Scale';

  @override
  String get pvScaleDays => 'Days';

  @override
  String get pvScaleHours => 'Hours';

  @override
  String get pvScaleMonths => 'Months';

  @override
  String get pvScaleWeeks => 'Weeks';

  @override
  String get pvScheduleOn => 'Schedule on…';

  @override
  String get pvScheduledSnack => 'Scheduled';

  @override
  String get pvScopeAll => 'All occurrences';

  @override
  String get pvScopeFollowing => 'This and following';

  @override
  String get pvScopeThis => 'This occurrence';

  @override
  String get pvScopeTitle => 'Change a recurring task';

  @override
  String pvSelected(int count) {
    return '$count selected';
  }

  @override
  String get pvSetDefaultView => 'Set as default';

  @override
  String get pvShareAvailability => 'Share availability';

  @override
  String get pvShowCancelled => 'Show cancelled';

  @override
  String get pvShowCompleted => 'Show completed';

  @override
  String get pvShowEmptyDays => 'Show empty days';

  @override
  String get pvShowNotes => 'Show notes';

  @override
  String get pvShowWeekends => 'Show weekends';

  @override
  String get pvSinceGroup => 'Since';

  @override
  String get pvSkip => 'Skip';

  @override
  String get pvSkipRemaining => 'Skip remaining';

  @override
  String get pvSkipStep => 'Skip step';

  @override
  String get pvSlotCustom => 'Custom size';

  @override
  String get pvSlotCustomHint => 'Minutes or h:mm (1 min – 24 h)';

  @override
  String get pvSlotInvalid => 'Enter a size between 1 minute and 24 hours';

  @override
  String get pvSlotPresets => 'Presets';

  @override
  String get pvSlotSize => 'Slot size';

  @override
  String get pvSlotsStyle => 'Slots';

  @override
  String get pvSnap => 'Snap';

  @override
  String get pvSortBy => 'Sort by';

  @override
  String get pvStart => 'Start';

  @override
  String pvStartsAt(String time) {
    return 'Starts at $time';
  }

  @override
  String get pvStatusCancelled => 'Cancelled';

  @override
  String get pvStatusDone => 'Done';

  @override
  String get pvStatusInProgress => 'In progress';

  @override
  String get pvStatusMissed => 'Missed';

  @override
  String get pvStatusScheduled => 'Planned';

  @override
  String get pvStatusSkipped => 'Skipped';

  @override
  String pvStatusSnack(String status) {
    return 'Marked $status';
  }

  @override
  String get pvStatuses => 'Statuses';

  @override
  String pvStep(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String get pvStop => 'Stop';

  @override
  String get pvSwipeVertical => 'Swipe vertically';

  @override
  String pvTableThreshold(String size) {
    return 'Table from $size';
  }

  @override
  String get pvTextFilterHint => 'Search titles and notes';

  @override
  String pvTileSemantics(
    String title,
    String day,
    String start,
    String end,
    String status,
  ) {
    return '$title, $day, $start to $end, $status';
  }

  @override
  String pvTimeLeft(String duration) {
    return '$duration left';
  }

  @override
  String get pvTo => 'To';

  @override
  String get pvTopCategories => 'Top categories';

  @override
  String get pvTracked => 'Tracked';

  @override
  String get pvTrackingCheck => 'Check';

  @override
  String get pvTrackingEvent => 'Event';

  @override
  String get pvTrackingModes => 'Tracking';

  @override
  String get pvTrackingTimer => 'Timer';

  @override
  String get pvUnpin => 'Unpin';

  @override
  String get pvUnscheduleUnsupported =>
      'Moving tasks back to the backlog isn\'t available yet';

  @override
  String get pvUnscheduled => 'Unscheduled';

  @override
  String get pvUntimed => 'Untimed';

  @override
  String get pvUpcoming => 'Upcoming';

  @override
  String pvUrgencyRule(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Urgent within $days days',
      one: 'Urgent within 1 day',
    );
    return '$_temp0';
  }

  @override
  String get pvVarianceLate => 'Started late';

  @override
  String get pvVarianceNotDone => 'Not done';

  @override
  String get pvVarianceOnPlan => 'On plan';

  @override
  String get pvVarianceOverran => 'Overran';

  @override
  String get pvVarianceUnplanned => 'Unplanned';

  @override
  String get pvViewAgenda => 'Agenda';

  @override
  String get pvViewBacklog => 'Backlog';

  @override
  String get pvViewCountdown => 'Countdowns';

  @override
  String get pvViewDayList => 'Day list';

  @override
  String get pvViewFocus => 'Focus';

  @override
  String get pvViewFreeSlots => 'Free slots';

  @override
  String get pvViewHorizons => 'Horizons';

  @override
  String get pvViewKanban => 'Kanban';

  @override
  String get pvViewLoadHeatmap => 'Load heatmap';

  @override
  String get pvViewMap => 'Map';

  @override
  String get pvViewMatrix => 'Eisenhower matrix';

  @override
  String get pvViewMonth => 'Month';

  @override
  String get pvViewMultiWeek => 'Multi-week';

  @override
  String get pvViewNDay => 'N days';

  @override
  String get pvViewName => 'View name';

  @override
  String get pvViewPlanVsActual => 'Plan vs actual';

  @override
  String get pvViewQuarter => 'Quarter';

  @override
  String get pvViewRadial => '24-hour clock';

  @override
  String get pvViewRibbon => 'Ribbon';

  @override
  String get pvViewRoutine => 'Routine player';

  @override
  String get pvViewSaved => 'View saved';

  @override
  String get pvViewSettings => 'View settings';

  @override
  String get pvViewSwimlanes => 'Swimlanes';

  @override
  String get pvViewSwitcher => 'Change view';

  @override
  String get pvViewTable => 'Table';

  @override
  String get pvViewTimeline => 'Timeline';

  @override
  String get pvViewWeekList => 'Week list';

  @override
  String get pvViewWeekTable => 'Week table';

  @override
  String get pvViewWorkWeek => 'Work week';

  @override
  String get pvViewYear => 'Year';

  @override
  String get pvVisibleHours => 'Visible hours';

  @override
  String get pvVisibleHoursAll => 'All 24 hours';

  @override
  String pvWeekNumber(int week) {
    return 'W$week';
  }

  @override
  String get pvWeekNumbers => 'Week numbers';

  @override
  String get pvWeekRibbon => 'Week';

  @override
  String get pvWeekSummary => 'Week summary';

  @override
  String pvWeeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get pvWithPlace => 'Tasks with a place';

  @override
  String get pvWorkHours => 'Work hours';

  @override
  String get pvZoneHint => 'e.g. Asia/Tokyo';

  @override
  String get pvZoomAroundNow => 'Zoom around now';

  @override
  String get pvZoomFixed => 'Fixed slot';

  @override
  String get pvZoomMode => 'Zoom';

  @override
  String get pvZoomSemantic => 'Semantic';

  @override
  String get recurAddDate => 'Add';

  @override
  String get recurAddOrdinal => 'Add a day like “2nd Tuesday”';

  @override
  String get recurAddTime => 'Add a time';

  @override
  String get recurAdvancedTitle => 'Custom repeat';

  @override
  String get recurAfterHint =>
      'The next one is due this long after you complete the previous one.';

  @override
  String get recurAfterPreview =>
      'The next ones depend on when you complete it';

  @override
  String recurAnchorMoved(String date) {
    return 'First occurrence: $date';
  }

  @override
  String recurCalendarSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days with occurrences',
      one: '1 day with occurrences',
      zero: 'no day with occurrences',
    );
    return '$_temp0';
  }

  @override
  String get recurCountCompletions => 'Completions';

  @override
  String get recurCountMode => 'Count';

  @override
  String get recurCountOccurrences => 'Occurrences';

  @override
  String get recurCurrent => 'Current rule';

  @override
  String get recurCustomValue => 'Other value…';

  @override
  String get recurEnds => 'Ends';

  @override
  String get recurEndsAfter => 'After a number of times';

  @override
  String recurEndsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get recurEndsNever => 'Never';

  @override
  String get recurEndsOn => 'On a date';

  @override
  String get recurExceptionCancelled => 'Removed';

  @override
  String get recurExceptionEdited => 'Edited';

  @override
  String get recurExceptionExcluded => 'Excluded';

  @override
  String recurExceptionMoved(String to) {
    return 'Moved to $to';
  }

  @override
  String get recurExceptionOpen => 'Open';

  @override
  String get recurExceptionRestore => 'Restore';

  @override
  String get recurExceptionRestoreAll => 'Restore all';

  @override
  String recurExceptionRestoreAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restore $count occurrences?',
      one: 'Restore 1 occurrence?',
    );
    return '$_temp0';
  }

  @override
  String get recurExceptionsEmpty => 'No skipped or moved occurrences';

  @override
  String get recurExceptionsRestored => 'Restored';

  @override
  String get recurExceptionsTitle => 'Skipped & moved occurrences';

  @override
  String get recurExdates => 'Excluded occurrences';

  @override
  String get recurFloatingNote => 'Times follow your current time zone';

  @override
  String get recurFrequency => 'Frequency';

  @override
  String get recurHours => 'Hours';

  @override
  String get recurInterval => 'Every';

  @override
  String get recurIssueCount => 'The number of times must be at least 1';

  @override
  String get recurIssueCountAndUntil =>
      'Choose either an end date or a number of times';

  @override
  String get recurIssueDate => 'Invalid date';

  @override
  String get recurIssueEmptyWeekdays => 'Select at least one day';

  @override
  String get recurIssueInterval => 'The interval must be at least 1';

  @override
  String get recurIssueMissing => 'The rule is incomplete';

  @override
  String get recurIssueOrdinal =>
      '“1st”, “last”… only work with monthly or yearly repeats';

  @override
  String recurIssueQuota(int max) {
    return 'This quota can\'t be met with that gap ($max max)';
  }

  @override
  String recurIssueTooFrequent(int count) {
    return 'Too frequent: $count per day (1440 max)';
  }

  @override
  String get recurIssueUnsupported => 'These options can\'t be combined';

  @override
  String get recurIssueUntilBeforeStart => 'The end date is before the start';

  @override
  String get recurIssueValue => 'A value is out of range';

  @override
  String get recurIssueWindow => 'The window must end after it starts';

  @override
  String get recurLess => 'Fewer options';

  @override
  String get recurMinutes => 'Minutes';

  @override
  String recurMonthDayFromEnd(int day) {
    return 'Day $day from the end';
  }

  @override
  String get recurMonthDays => 'Days of the month';

  @override
  String get recurMonthDaysFromEnd => 'Counting from the end';

  @override
  String get recurMonths => 'Months';

  @override
  String get recurMore => 'More options';

  @override
  String get recurNumbersHint =>
      'Numbers separated by commas (negative = from the end)';

  @override
  String get recurOrdinal1 => '1st';

  @override
  String get recurOrdinal2 => '2nd';

  @override
  String get recurOrdinal3 => '3rd';

  @override
  String get recurOrdinal4 => '4th';

  @override
  String get recurOrdinal5 => '5th';

  @override
  String get recurOrdinalEvery => 'Every';

  @override
  String get recurOrdinalLast => 'Last';

  @override
  String get recurOrdinalPick => 'Which day?';

  @override
  String get recurOrdinalSecondLast => '2nd to last';

  @override
  String recurOrdinalWeekday(String ordinal, String weekday) {
    return '$ordinal $weekday';
  }

  @override
  String get recurOverflow => 'When a month is too short';

  @override
  String get recurOverflowClamp => 'Use its last day';

  @override
  String get recurOverflowSkip => 'Skip that month';

  @override
  String get recurPerDay => 'Day';

  @override
  String get recurPerMonth => 'Month';

  @override
  String get recurPerWeek => 'Week';

  @override
  String get recurPerYear => 'Year';

  @override
  String recurPeriodWeek(String date) {
    return 'Week of $date';
  }

  @override
  String get recurPickerTitle => 'Repeat';

  @override
  String get recurPresetAfterCompletion => 'After completion…';

  @override
  String get recurPresetCustom => 'Custom…';

  @override
  String get recurPresetEveryNDays => 'Every few days…';

  @override
  String get recurPresetIntraday => 'Every few hours or minutes…';

  @override
  String get recurPresetNone => 'Does not repeat';

  @override
  String get recurPresetQuota => 'Several times per week or month…';

  @override
  String get recurPresetSpecificDays => 'Specific days…';

  @override
  String get recurPresetTimesPerDay => 'Several times a day…';

  @override
  String get recurPreview => 'Next occurrences';

  @override
  String get recurPreviewCalendar => 'Next 60 days';

  @override
  String get recurPreviewEmpty => 'No upcoming occurrence';

  @override
  String get recurQuotaMinGap => 'Minimum days between';

  @override
  String get recurQuotaOnDays => 'Only on these days';

  @override
  String get recurQuotaPer => 'Per';

  @override
  String get recurQuotaTimes => 'How many times';

  @override
  String get recurRdates => 'Extra occurrences';

  @override
  String recurRemove(String item) {
    return 'Remove $item';
  }

  @override
  String recurRemoveTime(String time) {
    return 'Remove $time';
  }

  @override
  String get recurSetPos => 'Keep only positions';

  @override
  String get recurSetPosHint =>
      '1 = first, −1 = last matching date of each period';

  @override
  String get recurSummary => 'Summary';

  @override
  String get recurTimes => 'Times of day';

  @override
  String recurTimesDefault(String time) {
    return 'At the start time ($time)';
  }

  @override
  String get recurType => 'Type';

  @override
  String get recurTypeAfter => 'After completion';

  @override
  String get recurTypeFixed => 'Schedule';

  @override
  String get recurTypeQuota => 'Quota';

  @override
  String get recurUnitDay => 'Days';

  @override
  String get recurUnitHour => 'Hours';

  @override
  String get recurUnitMinute => 'Minutes';

  @override
  String get recurUnitMonth => 'Months';

  @override
  String get recurUnitWeek => 'Weeks';

  @override
  String get recurUnitYear => 'Years';

  @override
  String get recurWarnAllDaySubDaily =>
      'All-day items can\'t repeat within a day';

  @override
  String get recurWarnDst =>
      'Some times fall in a daylight-saving change and are shifted';

  @override
  String get recurWarnNever => 'Never occurs in the next 5 years';

  @override
  String recurWarnPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences per day',
      one: '1 occurrence per day',
    );
    return '$_temp0';
  }

  @override
  String get recurWeekNumbers => 'Week numbers';

  @override
  String get recurWeekStart => 'Week starts on';

  @override
  String get recurWeekdayOrdinal => 'Which one in the period';

  @override
  String get recurWeekdays => 'Days of the week';

  @override
  String get recurWindow => 'Daily window';

  @override
  String get recurWindowAnchorSeries =>
      'Continue the chain from the first occurrence';

  @override
  String get recurWindowAnchorWindow => 'Restart each day at the window start';

  @override
  String get recurWindowEnd => 'Until';

  @override
  String get recurWindowNone => 'Whole day';

  @override
  String get recurWindowStart => 'From';

  @override
  String get recurYearDays => 'Days of the year';

  @override
  String recurZoneNote(String zone) {
    return 'Times in $zone';
  }

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

  @override
  String get tagAdd => 'Add tag';

  @override
  String tagChipSemantics(String name) {
    return 'Tag $name';
  }

  @override
  String tagCreateNamed(String name) {
    return 'Create tag “$name”';
  }

  @override
  String tagDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'It will be removed from $count items.',
      one: 'It will be removed from 1 item.',
      zero: 'This tag isn\'t used yet.',
    );
    return '$_temp0';
  }

  @override
  String get tagEdit => 'Edit tag';

  @override
  String get tagErrorDuplicate => 'A tag with this name already exists.';

  @override
  String get tagErrorInvalid => 'Use 1 to 40 characters.';

  @override
  String get tagMerge => 'Merge into…';

  @override
  String get tagMergeAction => 'Merge';

  @override
  String tagMergeConfirmBody(String source, String target) {
    return 'Everything tagged “$source” will be tagged “$target” instead, and “$source” will be deleted.';
  }

  @override
  String get tagMergeConfirmTitle => 'Merge tags?';

  @override
  String tagMergeTitle(String name) {
    return 'Merge “$name” into';
  }

  @override
  String tagMergedSnack(String name) {
    return 'Merged into “$name”';
  }

  @override
  String get tagName => 'Tag name';

  @override
  String get tagNew => 'New tag';

  @override
  String get tagNoColor => 'No color';

  @override
  String get tagPickerSearch => 'Search or create a tag';

  @override
  String get tagPickerTitle => 'Tags';

  @override
  String tagRemoveSemantics(String name) {
    return 'Remove tag $name';
  }

  @override
  String tagUsage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'Not used',
    );
    return '$_temp0';
  }

  @override
  String get tagsEmpty => 'No tags yet';

  @override
  String get tagsEmptyHint =>
      'Tags work across sections — use them for contexts like errands or waiting on others.';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get tagsUpdatedSnack => 'Tags updated';

  @override
  String get tasksActionDuplicateSeries => 'Duplicate as new series';

  @override
  String get tasksActionDuplicateTo => 'Duplicate to…';

  @override
  String get tasksActionExceptions => 'Skipped & moved occurrences';

  @override
  String get tasksActionMoveToToday => 'Move to today';

  @override
  String get tasksActionOpenSeries => 'Open series';

  @override
  String get tasksActionPause => 'Pause series';

  @override
  String get tasksActionPauseTimer => 'Pause';

  @override
  String get tasksActionReopen => 'Reopen';

  @override
  String get tasksActionReschedule => 'Reschedule…';

  @override
  String get tasksActionRestoreSeries => 'Restore to series';

  @override
  String get tasksActionResume => 'Resume series';

  @override
  String get tasksActionResumeTimer => 'Resume';

  @override
  String get tasksActionSeriesHistory => 'Series history';

  @override
  String get tasksActionShare => 'Share as text';

  @override
  String get tasksActionStart => 'Start';

  @override
  String get tasksActionStop => 'Stop';

  @override
  String get tasksActionUnschedule => 'Move to backlog';

  @override
  String get tasksActualAsPlanned => 'As planned';

  @override
  String get tasksActualCustom => 'Custom…';

  @override
  String get tasksActualEndBeforeStart => 'The end must be after the start';

  @override
  String get tasksActualJustNow => 'Just now';

  @override
  String get tasksActualNotSet => 'Not recorded';

  @override
  String get tasksActualTime => 'Actual time';

  @override
  String get tasksActualTitle => 'When did you do it?';

  @override
  String get tasksAddEntry => 'Add session';

  @override
  String tasksAnchorMoved(String date) {
    return 'Start moved to $date to match the repeat rule';
  }

  @override
  String get tasksAttachments => 'Attachments';

  @override
  String get tasksAttachmentsPlaceholder =>
      'Photos and files will be available here soon';

  @override
  String get tasksBacklogLabel => 'Unscheduled';

  @override
  String get tasksBulkDelete => 'Delete';

  @override
  String tasksBulkDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items updated',
      one: '1 item updated',
    );
    return '$_temp0';
  }

  @override
  String get tasksBulkDuplicate => 'Duplicate';

  @override
  String get tasksBulkEarlier15 => '15 min earlier';

  @override
  String get tasksBulkEarlierDay => '1 day earlier';

  @override
  String get tasksBulkLater15 => '15 min later';

  @override
  String get tasksBulkLater1h => '1 hour later';

  @override
  String get tasksBulkLaterDay => '1 day later';

  @override
  String get tasksBulkLaterWeek => '1 week later';

  @override
  String get tasksBulkMove => 'Move';

  @override
  String get tasksBulkSetCategory => 'Set category';

  @override
  String get tasksBulkSetPriority => 'Set priority';

  @override
  String get tasksBulkSetTracking => 'Set tracking mode';

  @override
  String get tasksBulkTarget => 'For recurring items';

  @override
  String get tasksBulkTargetOccurrence => 'Only these occurrences';

  @override
  String get tasksBulkTargetSeries => 'Whole series';

  @override
  String tasksBulkTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items selected',
      one: '1 item selected',
    );
    return '$_temp0';
  }

  @override
  String get tasksChecklistEmpty => 'No checklists yet';

  @override
  String get tasksChecklistNone => 'None';

  @override
  String get tasksChecklistOpen => 'Open checklist';

  @override
  String get tasksChecklistPick => 'Link a checklist';

  @override
  String tasksChecklistProgress(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get tasksChecklistUnlink => 'Unlink';

  @override
  String get tasksColorCategoryDefault => 'Category color';

  @override
  String get tasksCompletion => 'Progress';

  @override
  String tasksCompletionValue(int percent) {
    return '$percent%';
  }

  @override
  String get tasksCreated => 'Task created';

  @override
  String get tasksCustomDuration => 'Custom…';

  @override
  String get tasksDeadlineNone => 'No deadline';

  @override
  String get tasksDeadlineWarning => 'Planned after the deadline';

  @override
  String get tasksDeleteConfirmBody => 'It stays in Trash for 30 days.';

  @override
  String get tasksDeleteConfirmTitle => 'Delete this task?';

  @override
  String get tasksDeleted => 'Task deleted';

  @override
  String get tasksDetailNotFound => 'This task no longer exists';

  @override
  String get tasksDetailTitle => 'Task';

  @override
  String get tasksDiscard => 'Discard';

  @override
  String tasksDuplicateToConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Duplicate to $count dates',
      one: 'Duplicate to 1 date',
      zero: 'Pick dates',
    );
    return '$_temp0';
  }

  @override
  String get tasksDuplicateToTitle => 'Duplicate to…';

  @override
  String get tasksDuplicated => 'Task duplicated';

  @override
  String tasksDuplicatedTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied to $count dates',
      one: 'Copied to 1 date',
    );
    return '$_temp0';
  }

  @override
  String get tasksDurationMode => 'Duration';

  @override
  String get tasksEditorEditOccurrenceTitle => 'Edit occurrence';

  @override
  String get tasksEditorEditTitle => 'Edit task';

  @override
  String get tasksEditorNewTitle => 'New task';

  @override
  String get tasksEndMode => 'End time';

  @override
  String get tasksEntryDelete => 'Delete session';

  @override
  String get tasksEntryEdit => 'Edit session';

  @override
  String get tasksEntryFuture => 'A session can\'t start in the future';

  @override
  String get tasksEntryNegative => 'The end must be after the start';

  @override
  String get tasksEntryOverlap => 'Overlaps another session';

  @override
  String get tasksEntryRunning => 'Running';

  @override
  String get tasksErrAllDay => 'All-day tasks span whole days';

  @override
  String get tasksErrDuration =>
      'Duration must be between 0 minutes and 365 days';

  @override
  String get tasksErrEstimate => 'The estimate is out of range';

  @override
  String get tasksErrPriority => 'Invalid priority';

  @override
  String get tasksErrRecurrenceInvalid => 'The repeat rule is invalid';

  @override
  String get tasksErrRecurrenceNoDate => 'Repeating tasks need a date';

  @override
  String get tasksErrTitleEmpty => 'Enter a title';

  @override
  String get tasksErrTitleTooLong =>
      'The title is too long (300 characters max)';

  @override
  String get tasksErrZone => 'Unknown time zone';

  @override
  String get tasksEvtCompleted => 'Completed';

  @override
  String get tasksEvtCreated => 'Created';

  @override
  String get tasksEvtDeleted => 'Deleted';

  @override
  String get tasksEvtDeletedOccurrence => 'Occurrence removed';

  @override
  String tasksEvtOccurrence(String date) {
    return 'Occurrence of $date';
  }

  @override
  String get tasksEvtPaused => 'Series paused';

  @override
  String get tasksEvtReopened => 'Reopened';

  @override
  String tasksEvtRescheduled(String from, String to) {
    return 'Rescheduled from $from to $to';
  }

  @override
  String get tasksEvtRestored => 'Restored';

  @override
  String get tasksEvtResumed => 'Series resumed';

  @override
  String get tasksEvtScheduled => 'Scheduled';

  @override
  String get tasksEvtSkipped => 'Skipped';

  @override
  String tasksEvtSkippedReason(String reason) {
    return 'Skipped: $reason';
  }

  @override
  String get tasksEvtSplit => 'Series split';

  @override
  String get tasksEvtStarted => 'Started';

  @override
  String get tasksEvtStatusChanged => 'Status changed';

  @override
  String get tasksEvtStopped => 'Stopped';

  @override
  String get tasksEvtTimeEntry => 'Session added';

  @override
  String get tasksEvtUnscheduled => 'Moved to the backlog';

  @override
  String tasksEvtUpdated(String fields) {
    return 'Edited: $fields';
  }

  @override
  String get tasksFieldAllDay => 'All day';

  @override
  String get tasksFieldCategory => 'Category';

  @override
  String get tasksFieldChecklist => 'Linked checklist';

  @override
  String get tasksFieldColor => 'Color';

  @override
  String get tasksFieldDate => 'Date';

  @override
  String get tasksFieldDeadline => 'Deadline';

  @override
  String get tasksFieldDuration => 'Duration';

  @override
  String get tasksFieldEnd => 'End';

  @override
  String get tasksFieldEndDate => 'End date';

  @override
  String get tasksFieldEstimate => 'Estimate';

  @override
  String get tasksFieldIcon => 'Icon';

  @override
  String get tasksFieldLocation => 'Location';

  @override
  String get tasksFieldNoDate => 'No date (backlog)';

  @override
  String get tasksFieldNotes => 'Notes';

  @override
  String get tasksFieldPriority => 'Priority';

  @override
  String get tasksFieldRepeat => 'Repeat';

  @override
  String get tasksFieldStart => 'Start';

  @override
  String get tasksFieldStartDate => 'Start date';

  @override
  String get tasksFieldTimeZone => 'Time zone';

  @override
  String get tasksFieldTitle => 'Title';

  @override
  String get tasksFieldTitleHint => 'What do you want to do?';

  @override
  String get tasksFieldTracking => 'Tracking';

  @override
  String get tasksFieldUrl => 'Link';

  @override
  String get tasksFilterAll => 'All';

  @override
  String get tasksFilterDone => 'Done';

  @override
  String get tasksFilterMissed => 'Missed';

  @override
  String get tasksFilterMoved => 'Moved';

  @override
  String get tasksFilterSkipped => 'Skipped';

  @override
  String get tasksFromTemplate => 'From template…';

  @override
  String get tasksHistory => 'History';

  @override
  String get tasksHistoryEmpty => 'No history yet';

  @override
  String get tasksHistoryLoadMore => 'Load more';

  @override
  String get tasksIconDefault => 'Category icon';

  @override
  String get tasksMarkedDone => 'Marked as done';

  @override
  String get tasksMarkedSkipped => 'Skipped';

  @override
  String get tasksMdBold => 'Bold';

  @override
  String get tasksMdBullet => 'Bulleted list';

  @override
  String get tasksMdCheckbox => 'Checkbox';

  @override
  String get tasksMdCode => 'Code';

  @override
  String get tasksMdHeading => 'Heading';

  @override
  String get tasksMdItalic => 'Italic';

  @override
  String get tasksMdNumbered => 'Numbered list';

  @override
  String get tasksMoved => 'Moved';

  @override
  String tasksMovedFrom(String time) {
    return 'Moved from $time';
  }

  @override
  String get tasksNextDay => '+1 day';

  @override
  String tasksNextLabel(String when) {
    return 'Next: $when';
  }

  @override
  String get tasksNextMonth => 'Next month';

  @override
  String get tasksNextOccurrences => 'Next occurrences';

  @override
  String get tasksNoUpcoming => 'Nothing upcoming';

  @override
  String get tasksNotesEdit => 'Edit';

  @override
  String get tasksNotesHint => 'Add notes (bold, lists, checkboxes…)';

  @override
  String get tasksNotesPreview => 'Preview';

  @override
  String get tasksOccurrenceDeleted => 'Occurrence removed';

  @override
  String tasksOpenLinkBody(String url) {
    return '$url will open outside Everslot.';
  }

  @override
  String get tasksOpenLinkTitle => 'Open link?';

  @override
  String get tasksOrphansBody =>
      'Occurrences with history are always kept as one-off tasks.';

  @override
  String tasksOrphansCompleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed occurrences',
      one: '1 completed occurrence',
    );
    return '$_temp0';
  }

  @override
  String get tasksOrphansDiscard => 'Discard moved ones';

  @override
  String get tasksOrphansKeep => 'Keep as one-off tasks';

  @override
  String tasksOrphansMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moved occurrences',
      one: '1 moved occurrence',
    );
    return '$_temp0';
  }

  @override
  String tasksOrphansOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences with notes or tracked time',
      one: '1 occurrence with notes or tracked time',
    );
    return '$_temp0';
  }

  @override
  String tasksOrphansSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skipped occurrences',
      one: '1 skipped occurrence',
    );
    return '$_temp0';
  }

  @override
  String get tasksOrphansTitle => 'Some occurrences no longer match';

  @override
  String get tasksOutcomeNote => 'Outcome note';

  @override
  String get tasksOutcomeNoteHint => 'How did it go?';

  @override
  String get tasksOverdue => 'Overdue';

  @override
  String tasksOverlapHint(String title, String range) {
    return 'Overlaps with $title $range';
  }

  @override
  String tasksOverlapMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more',
      one: 'and 1 more',
    );
    return '$_temp0';
  }

  @override
  String get tasksPauseSnack => 'Series paused';

  @override
  String get tasksPausedBadge => 'Paused';

  @override
  String tasksPlannedVsActual(String planned, String actual) {
    return 'Planned $planned · actual $actual';
  }

  @override
  String tasksPlusDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count days',
      one: '+1 day',
    );
    return '$_temp0';
  }

  @override
  String get tasksPostpone15 => '+15 min';

  @override
  String get tasksPostpone1h => '+1 hour';

  @override
  String get tasksPostponeEvening => 'This evening';

  @override
  String get tasksPostponeNextWeek => 'Next week, same time';

  @override
  String get tasksPostponePick => 'Pick a date and time…';

  @override
  String get tasksPostponeTitle => 'Reschedule';

  @override
  String get tasksPostponeTomorrow => 'Tomorrow, same time';

  @override
  String get tasksPrevMonth => 'Previous month';

  @override
  String get tasksQuickAdd => 'Add';

  @override
  String get tasksQuickAddNew => 'Add & new';

  @override
  String get tasksQuickMore => 'More options';

  @override
  String get tasksQuickTitleHint => 'New task';

  @override
  String get tasksQuotaDone => 'Done for this period';

  @override
  String tasksQuotaProgress(int done, int total) {
    return '$done/$total this period';
  }

  @override
  String get tasksRating => 'Rating';

  @override
  String tasksRatingValue(int value) {
    return '$value of 5';
  }

  @override
  String get tasksReminders => 'Reminders';

  @override
  String get tasksRemindersDefault => 'Default';

  @override
  String get tasksReopened => 'Reopened';

  @override
  String get tasksRepeatNone => 'Does not repeat';

  @override
  String get tasksRestored => 'Task restored';

  @override
  String get tasksResumeSnack => 'Series resumed';

  @override
  String tasksRolledOver(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unfinished tasks moved to today',
      one: '1 unfinished task moved to today',
    );
    return '$_temp0';
  }

  @override
  String tasksRunningTimer(String title, String elapsed) {
    return 'Timer running: $title, $elapsed';
  }

  @override
  String get tasksSaveAsTemplate => 'Save as template';

  @override
  String get tasksSaved => 'Task saved';

  @override
  String get tasksScopeAll => 'All occurrences';

  @override
  String get tasksScopeDeleteTitle => 'Delete recurring task';

  @override
  String get tasksScopeFollowing => 'This and following';

  @override
  String get tasksScopePastKept =>
      'Past occurrences keep their original times.';

  @override
  String get tasksScopeRewritePast => 'Also rewrite past occurrences';

  @override
  String get tasksScopeThis => 'This occurrence';

  @override
  String get tasksScopeThisDisabled =>
      'Only the time, duration, title and notes can change for a single occurrence.';

  @override
  String get tasksScopeTitle => 'Apply changes to';

  @override
  String get tasksSeriesEmpty => 'No occurrences in this period';

  @override
  String get tasksSeriesHistoryTitle => 'Series history';

  @override
  String get tasksSeriesStats => 'Series statistics';

  @override
  String tasksShareRepeats(String rule) {
    return 'Repeats: $rule';
  }

  @override
  String get tasksSkipCustomHint => 'Another reason (optional)';

  @override
  String get tasksSkipForgot => 'Forgot';

  @override
  String get tasksSkipNotNeeded => 'Not needed';

  @override
  String get tasksSkipOther => 'Other';

  @override
  String get tasksSkipSick => 'Sick';

  @override
  String get tasksSkipTitle => 'Why skip it?';

  @override
  String get tasksSkipTooBusy => 'Too busy';

  @override
  String get tasksStatusCancelled => 'Cancelled';

  @override
  String get tasksStatusDone => 'Done';

  @override
  String get tasksStatusInProgress => 'In progress';

  @override
  String get tasksStatusMissed => 'Missed';

  @override
  String get tasksStatusScheduled => 'Scheduled';

  @override
  String get tasksStatusSkipped => 'Skipped';

  @override
  String get tasksTemplateDelete => 'Delete template';

  @override
  String get tasksTemplateSaved => 'Template saved';

  @override
  String get tasksTemplatesEmpty =>
      'No templates yet. Save a task as a template from its menu.';

  @override
  String get tasksTemplatesTitle => 'Templates';

  @override
  String get tasksTimeEntries => 'Sessions';

  @override
  String get tasksTimeTracking => 'Time tracking';

  @override
  String get tasksTooManyOccurrences =>
      'Too many occurrences to display — zoom in';

  @override
  String tasksTracked(String duration) {
    return 'Tracked: $duration';
  }

  @override
  String get tasksTrackingCheck => 'Check';

  @override
  String get tasksTrackingCheckHint =>
      'Mark it done or skip it; it can be missed.';

  @override
  String get tasksTrackingEvent => 'Event';

  @override
  String get tasksTrackingEventHint =>
      'A time block (meeting, meal): no checkbox, never missed.';

  @override
  String get tasksTrackingTimer => 'Timer';

  @override
  String get tasksTrackingTimerHint =>
      'Track the time you spend; done when you stop the timer.';

  @override
  String get tasksUnsavedBody => 'Your changes will be lost.';

  @override
  String get tasksUnsavedTitle => 'Discard changes?';

  @override
  String get tasksUntitled => 'Untitled task';

  @override
  String get tasksUpdated => 'Updated';

  @override
  String get tasksUrlInvalid => 'Enter a valid web address';

  @override
  String tasksZoneBadge(String zone) {
    return '$zone time';
  }

  @override
  String get tasksZoneFixed => 'Fixed';

  @override
  String get tasksZoneFixedHint => 'Anchored to one time zone';

  @override
  String get tasksZoneFloating => 'Floating';

  @override
  String get tasksZoneFloatingHint => 'Same clock time wherever you are';

  @override
  String get tasksZonePickTitle => 'Choose a time zone';

  @override
  String get tasksZoneSearch => 'Search time zones';
}
