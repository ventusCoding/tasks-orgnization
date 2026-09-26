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
  String get recurAddTime => 'Add a time';

  @override
  String get recurAdvancedTitle => 'Custom repeat';

  @override
  String get recurAfterHint =>
      'The next one is due this long after you complete the previous one.';

  @override
  String recurAnchorMoved(String date) {
    return 'First occurrence: $date';
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
  String get recurOrdinalSecondLast => '2nd to last';

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
