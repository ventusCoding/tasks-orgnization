// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get actionAdd => 'Ajouter';

  @override
  String get actionApply => 'Appliquer';

  @override
  String get actionArchive => 'Archiver';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionClear => 'Effacer';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionConfirm => 'Confirmer';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionDone => 'Terminé';

  @override
  String get actionDuplicate => 'Dupliquer';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionInbox => 'Notifications';

  @override
  String get actionMore => 'Plus';

  @override
  String get actionNext => 'Suivant';

  @override
  String get actionOpen => 'Ouvrir';

  @override
  String get actionRedo => 'Rétablir';

  @override
  String get actionRestore => 'Restaurer';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionSearch => 'Rechercher';

  @override
  String get actionSettings => 'Réglages';

  @override
  String get actionShare => 'Partager';

  @override
  String get actionSkip => 'Passer';

  @override
  String get actionToday => 'Aujourd\'hui';

  @override
  String get actionUndo => 'Annuler';

  @override
  String get appName => 'Everslot';

  @override
  String get appTagline => 'Maîtrisez chaque créneau de votre journée.';

  @override
  String get categoriesEmpty => 'Aucune catégorie';

  @override
  String get categoriesTitle => 'Catégories';

  @override
  String get categoryArchived => 'Archivée';

  @override
  String get categoryDefaultHealth => 'Santé';

  @override
  String get categoryDefaultHome => 'Maison';

  @override
  String get categoryDefaultPersonal => 'Personnel';

  @override
  String get categoryDefaultSocial => 'Social';

  @override
  String get categoryDefaultStudy => 'Études';

  @override
  String get categoryDefaultWork => 'Travail';

  @override
  String get categoryDeleteBody =>
      'Les éléments de cette catégorie resteront, sans catégorie.';

  @override
  String get categoryEdit => 'Modifier la catégorie';

  @override
  String get categoryName => 'Nom';

  @override
  String get categoryNew => 'Nouvelle catégorie';

  @override
  String get categoryNone => 'Sans catégorie';

  @override
  String get categoryPick => 'Catégorie';

  @override
  String get categoryUnavailable => 'Compte comme temps indisponible';

  @override
  String get categoryUnavailableHint =>
      'Exclu des statistiques de capacité (sommeil, congés…).';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get confirmDeleteBody =>
      'Vous pourrez le restaurer depuis la corbeille pendant 30 jours.';

  @override
  String confirmDeleteTitle(String item) {
    return 'Supprimer $item ?';
  }

  @override
  String deletedSnack(String item) {
    return '$item supprimé';
  }

  @override
  String get devMenu => 'Menu développeur';

  @override
  String durationDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
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
  String get errorAuth => 'Veuillez vous reconnecter.';

  @override
  String get errorNetwork => 'Serveur injoignable. Vérifiez votre connexion.';

  @override
  String get errorNotConfigured =>
      'Cette fonction nécessite la configuration cloud (voir guide.md).';

  @override
  String get errorNotFound => 'Cet élément n\'existe plus.';

  @override
  String get errorPermission => 'Une autorisation est nécessaire.';

  @override
  String get errorUnknown => 'Erreur inattendue.';

  @override
  String get errorUnsupportedVersion =>
      'Mettez à jour Everslot pour continuer la synchronisation.';

  @override
  String get errorValidation => 'Veuillez vérifier les champs indiqués.';

  @override
  String get localOnlyBanner =>
      'La synchronisation cloud n\'est pas configurée — vos données restent sur cet appareil.';

  @override
  String get notFoundTitle => 'Page introuvable';

  @override
  String get pickerColor => 'Couleur';

  @override
  String get pickerDate => 'Date';

  @override
  String get pickerDays => 'Jours';

  @override
  String get pickerDuration => 'Durée';

  @override
  String get pickerHours => 'Heures';

  @override
  String get pickerIcon => 'Icône';

  @override
  String get pickerMinutes => 'Minutes';

  @override
  String get pickerNoColor => 'Sans couleur';

  @override
  String get pickerSearchIcons => 'Rechercher une icône';

  @override
  String get pickerTime => 'Heure';

  @override
  String get placeholderScreen => 'Cet écran est en construction.';

  @override
  String get priorityHigh => 'Haute';

  @override
  String get priorityLow => 'Basse';

  @override
  String get priorityMedium => 'Moyenne';

  @override
  String get priorityNone => 'Sans priorité';

  @override
  String get priorityUrgent => 'Urgente';

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
  String get recurAddDate => 'Ajouter';

  @override
  String get recurAddTime => 'Ajouter une heure';

  @override
  String get recurAdvancedTitle => 'Répétition personnalisée';

  @override
  String get recurAfterHint =>
      'La suivante arrive ce délai après l’achèvement de la précédente.';

  @override
  String recurAnchorMoved(String date) {
    return 'Première occurrence : $date';
  }

  @override
  String get recurCountCompletions => 'Achèvements';

  @override
  String get recurCountMode => 'Décompte';

  @override
  String get recurCountOccurrences => 'Occurrences';

  @override
  String get recurCurrent => 'Règle actuelle';

  @override
  String get recurEnds => 'Fin';

  @override
  String get recurEndsAfter => 'Après un nombre de fois';

  @override
  String recurEndsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fois',
      one: '1 fois',
    );
    return '$_temp0';
  }

  @override
  String get recurEndsNever => 'Jamais';

  @override
  String get recurEndsOn => 'À une date';

  @override
  String get recurExceptionCancelled => 'Retirée';

  @override
  String get recurExceptionEdited => 'Modifiée';

  @override
  String recurExceptionMoved(String to) {
    return 'Déplacée au $to';
  }

  @override
  String get recurExceptionOpen => 'Ouvrir';

  @override
  String get recurExceptionRestore => 'Restaurer';

  @override
  String get recurExceptionRestoreAll => 'Tout restaurer';

  @override
  String get recurExceptionsEmpty => 'Aucune occurrence retirée ou déplacée';

  @override
  String get recurExceptionsRestored => 'Restaurées';

  @override
  String get recurExceptionsTitle => 'Occurrences passées et déplacées';

  @override
  String get recurExdates => 'Occurrences exclues';

  @override
  String get recurFloatingNote => 'Les heures suivent votre fuseau actuel';

  @override
  String get recurFrequency => 'Fréquence';

  @override
  String get recurHours => 'Heures';

  @override
  String get recurInterval => 'Tous les';

  @override
  String get recurIssueCount => 'Le nombre de fois doit être d’au moins 1';

  @override
  String get recurIssueCountAndUntil =>
      'Choisissez une date de fin ou un nombre de fois';

  @override
  String get recurIssueDate => 'Date non valide';

  @override
  String get recurIssueEmptyWeekdays => 'Sélectionnez au moins un jour';

  @override
  String get recurIssueInterval => 'L’intervalle doit être d’au moins 1';

  @override
  String get recurIssueMissing => 'La règle est incomplète';

  @override
  String get recurIssueOrdinal =>
      '« 1er », « dernier »… ne fonctionnent qu’avec une répétition mensuelle ou annuelle';

  @override
  String recurIssueQuota(int max) {
    return 'Ce quota est impossible avec cet écart ($max max.)';
  }

  @override
  String recurIssueTooFrequent(int count) {
    return 'Trop fréquent : $count par jour (1440 max.)';
  }

  @override
  String get recurIssueUnsupported =>
      'Ces options ne peuvent pas être combinées';

  @override
  String get recurIssueUntilBeforeStart => 'La date de fin est avant le début';

  @override
  String get recurIssueValue => 'Une valeur est hors limites';

  @override
  String get recurIssueWindow => 'La plage doit finir après son début';

  @override
  String get recurLess => 'Moins d’options';

  @override
  String get recurMinutes => 'Minutes';

  @override
  String recurMonthDayFromEnd(int day) {
    return '${day}e jour avant la fin';
  }

  @override
  String get recurMonthDays => 'Jours du mois';

  @override
  String get recurMonthDaysFromEnd => 'En partant de la fin';

  @override
  String get recurMonths => 'Mois';

  @override
  String get recurMore => 'Plus d’options';

  @override
  String get recurOrdinal1 => '1er';

  @override
  String get recurOrdinal2 => '2e';

  @override
  String get recurOrdinal3 => '3e';

  @override
  String get recurOrdinal4 => '4e';

  @override
  String get recurOrdinal5 => '5e';

  @override
  String get recurOrdinalEvery => 'Chaque';

  @override
  String get recurOrdinalLast => 'Dernier';

  @override
  String get recurOrdinalSecondLast => 'Avant-dernier';

  @override
  String get recurOverflow => 'Quand un mois est trop court';

  @override
  String get recurOverflowClamp => 'Prendre son dernier jour';

  @override
  String get recurOverflowSkip => 'Sauter ce mois';

  @override
  String get recurPerDay => 'Jour';

  @override
  String get recurPerMonth => 'Mois';

  @override
  String get recurPerWeek => 'Semaine';

  @override
  String get recurPerYear => 'Année';

  @override
  String get recurPickerTitle => 'Répétition';

  @override
  String get recurPresetAfterCompletion => 'Après achèvement…';

  @override
  String get recurPresetCustom => 'Personnalisé…';

  @override
  String get recurPresetEveryNDays => 'Tous les quelques jours…';

  @override
  String get recurPresetIntraday => 'Toutes les quelques heures ou minutes…';

  @override
  String get recurPresetNone => 'Ne se répète pas';

  @override
  String get recurPresetQuota => 'Plusieurs fois par semaine ou par mois…';

  @override
  String get recurPresetSpecificDays => 'Jours précis…';

  @override
  String get recurPresetTimesPerDay => 'Plusieurs fois par jour…';

  @override
  String get recurPreview => 'Prochaines occurrences';

  @override
  String get recurPreviewCalendar => '60 prochains jours';

  @override
  String get recurPreviewEmpty => 'Aucune occurrence à venir';

  @override
  String get recurQuotaMinGap => 'Jours minimum entre deux';

  @override
  String get recurQuotaOnDays => 'Seulement ces jours';

  @override
  String get recurQuotaPer => 'Par';

  @override
  String get recurQuotaTimes => 'Combien de fois';

  @override
  String get recurRdates => 'Occurrences ajoutées';

  @override
  String recurRemoveTime(String time) {
    return 'Retirer $time';
  }

  @override
  String get recurSetPos => 'Ne garder que les positions';

  @override
  String get recurSetPosHint =>
      '1 = première, −1 = dernière date correspondante de chaque période';

  @override
  String get recurSummary => 'Résumé';

  @override
  String get recurTimes => 'Heures de la journée';

  @override
  String get recurType => 'Type';

  @override
  String get recurTypeAfter => 'Après achèvement';

  @override
  String get recurTypeFixed => 'Calendrier';

  @override
  String get recurTypeQuota => 'Quota';

  @override
  String get recurUnitDay => 'Jours';

  @override
  String get recurUnitHour => 'Heures';

  @override
  String get recurUnitMinute => 'Minutes';

  @override
  String get recurUnitMonth => 'Mois';

  @override
  String get recurUnitWeek => 'Semaines';

  @override
  String get recurUnitYear => 'Années';

  @override
  String get recurWarnAllDaySubDaily =>
      'Un élément sur la journée ne peut pas se répéter dans la journée';

  @override
  String get recurWarnDst =>
      'Certaines heures tombent lors d’un changement d’heure et sont décalées';

  @override
  String get recurWarnNever => 'Ne se produit pas dans les 5 prochaines années';

  @override
  String recurWarnPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences par jour',
      one: '1 occurrence par jour',
    );
    return '$_temp0';
  }

  @override
  String get recurWeekStart => 'La semaine commence le';

  @override
  String get recurWeekdayOrdinal => 'Lequel dans la période';

  @override
  String get recurWeekdays => 'Jours de la semaine';

  @override
  String get recurWindow => 'Plage horaire';

  @override
  String get recurWindowAnchorSeries =>
      'Continuer la chaîne depuis la première occurrence';

  @override
  String get recurWindowAnchorWindow =>
      'Recommencer chaque jour au début de la plage';

  @override
  String get recurWindowEnd => 'Jusqu’à';

  @override
  String get recurWindowNone => 'Toute la journée';

  @override
  String get recurWindowStart => 'De';

  @override
  String recurZoneNote(String zone) {
    return 'Heures de $zone';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'hier',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String relativeInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dans $count jours',
      one: 'demain',
    );
    return '$_temp0';
  }

  @override
  String relativeInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dans $count heures',
      one: 'dans 1 heure',
    );
    return '$_temp0';
  }

  @override
  String relativeInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dans $count minutes',
      one: 'dans 1 minute',
    );
    return '$_temp0';
  }

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get relativeNow => 'maintenant';

  @override
  String get savedSnack => 'Enregistré';

  @override
  String get stateEmpty => 'Rien pour l\'instant';

  @override
  String get stateErrorBody => 'Veuillez réessayer.';

  @override
  String get stateErrorTitle => 'Un problème est survenu';

  @override
  String get stateLoading => 'Chargement…';

  @override
  String get syncError => 'Problème de synchronisation';

  @override
  String get syncIdle => 'Synchronisé';

  @override
  String get syncLocalOnly => 'Sur cet appareil uniquement';

  @override
  String get syncOffline => 'Hors ligne — synchronisation plus tard';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications en attente',
      one: '1 modification en attente',
      zero: 'Aucune modification en attente',
    );
    return '$_temp0';
  }

  @override
  String get syncPulling => 'Mise à jour…';

  @override
  String get syncPushing => 'Envoi des modifications…';

  @override
  String get tabHabits => 'Habitudes';

  @override
  String get tabInsights => 'Statistiques';

  @override
  String get tabLists => 'Listes';

  @override
  String get tabPlan => 'Planning';

  @override
  String get tabToday => 'Aujourd\'hui';

  @override
  String get tasksActionDuplicateSeries => 'Dupliquer comme nouvelle série';

  @override
  String get tasksActionDuplicateTo => 'Dupliquer vers…';

  @override
  String get tasksActionExceptions => 'Occurrences passées et déplacées';

  @override
  String get tasksActionMoveToToday => 'Déplacer à aujourd’hui';

  @override
  String get tasksActionOpenSeries => 'Ouvrir la série';

  @override
  String get tasksActionPause => 'Mettre la série en pause';

  @override
  String get tasksActionPauseTimer => 'Pause';

  @override
  String get tasksActionReopen => 'Rouvrir';

  @override
  String get tasksActionReschedule => 'Replanifier…';

  @override
  String get tasksActionRestoreSeries => 'Revenir à la série';

  @override
  String get tasksActionResume => 'Reprendre la série';

  @override
  String get tasksActionResumeTimer => 'Reprendre';

  @override
  String get tasksActionSeriesHistory => 'Historique de la série';

  @override
  String get tasksActionShare => 'Partager en texte';

  @override
  String get tasksActionStart => 'Démarrer';

  @override
  String get tasksActionStop => 'Arrêter';

  @override
  String get tasksActionUnschedule => 'Remettre à planifier';

  @override
  String get tasksActualAsPlanned => 'Comme prévu';

  @override
  String get tasksActualCustom => 'Personnaliser…';

  @override
  String get tasksActualEndBeforeStart => 'La fin doit être après le début';

  @override
  String get tasksActualJustNow => 'À l’instant';

  @override
  String get tasksActualNotSet => 'Non renseigné';

  @override
  String get tasksActualTime => 'Horaire réel';

  @override
  String get tasksActualTitle => 'Quand l’avez-vous fait ?';

  @override
  String get tasksAddEntry => 'Ajouter une session';

  @override
  String tasksAnchorMoved(String date) {
    return 'Début déplacé au $date pour correspondre à la répétition';
  }

  @override
  String get tasksAttachments => 'Pièces jointes';

  @override
  String get tasksAttachmentsPlaceholder =>
      'Les photos et fichiers seront bientôt disponibles ici';

  @override
  String get tasksBacklogLabel => 'Non planifiée';

  @override
  String get tasksBulkDelete => 'Supprimer';

  @override
  String tasksBulkDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments mis à jour',
      one: '1 élément mis à jour',
    );
    return '$_temp0';
  }

  @override
  String get tasksBulkDuplicate => 'Dupliquer';

  @override
  String get tasksBulkEarlier15 => '15 min plus tôt';

  @override
  String get tasksBulkEarlierDay => '1 jour plus tôt';

  @override
  String get tasksBulkLater15 => '15 min plus tard';

  @override
  String get tasksBulkLater1h => '1 heure plus tard';

  @override
  String get tasksBulkLaterDay => '1 jour plus tard';

  @override
  String get tasksBulkLaterWeek => '1 semaine plus tard';

  @override
  String get tasksBulkMove => 'Déplacer';

  @override
  String get tasksBulkSetCategory => 'Définir la catégorie';

  @override
  String get tasksBulkSetPriority => 'Définir la priorité';

  @override
  String get tasksBulkSetTracking => 'Définir le mode de suivi';

  @override
  String get tasksBulkTarget => 'Pour les éléments répétés';

  @override
  String get tasksBulkTargetOccurrence => 'Seulement ces occurrences';

  @override
  String get tasksBulkTargetSeries => 'Toute la série';

  @override
  String tasksBulkTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments sélectionnés',
      one: '1 élément sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get tasksChecklistEmpty => 'Aucune liste pour l’instant';

  @override
  String get tasksChecklistNone => 'Aucune';

  @override
  String get tasksChecklistOpen => 'Ouvrir la liste';

  @override
  String get tasksChecklistPick => 'Associer une liste';

  @override
  String tasksChecklistProgress(int done, int total) {
    return '$done/$total faits';
  }

  @override
  String get tasksChecklistUnlink => 'Dissocier';

  @override
  String get tasksColorCategoryDefault => 'Couleur de la catégorie';

  @override
  String get tasksCompletion => 'Avancement';

  @override
  String tasksCompletionValue(int percent) {
    return '$percent %';
  }

  @override
  String get tasksCreated => 'Tâche créée';

  @override
  String get tasksCustomDuration => 'Personnaliser…';

  @override
  String get tasksDeadlineNone => 'Aucune échéance';

  @override
  String get tasksDeadlineWarning => 'Planifiée après l’échéance';

  @override
  String get tasksDeleteConfirmBody => 'Elle reste 30 jours dans la corbeille.';

  @override
  String get tasksDeleteConfirmTitle => 'Supprimer cette tâche ?';

  @override
  String get tasksDeleted => 'Tâche supprimée';

  @override
  String get tasksDetailNotFound => 'Cette tâche n’existe plus';

  @override
  String get tasksDetailTitle => 'Tâche';

  @override
  String get tasksDiscard => 'Abandonner';

  @override
  String tasksDuplicateToConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dupliquer vers $count dates',
      one: 'Dupliquer vers 1 date',
      zero: 'Choisissez des dates',
    );
    return '$_temp0';
  }

  @override
  String get tasksDuplicateToTitle => 'Dupliquer vers…';

  @override
  String get tasksDuplicated => 'Tâche dupliquée';

  @override
  String tasksDuplicatedTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copiée vers $count dates',
      one: 'Copiée vers 1 date',
    );
    return '$_temp0';
  }

  @override
  String get tasksDurationMode => 'Durée';

  @override
  String get tasksEditorEditOccurrenceTitle => 'Modifier l’occurrence';

  @override
  String get tasksEditorEditTitle => 'Modifier la tâche';

  @override
  String get tasksEditorNewTitle => 'Nouvelle tâche';

  @override
  String get tasksEndMode => 'Heure de fin';

  @override
  String get tasksEntryDelete => 'Supprimer la session';

  @override
  String get tasksEntryEdit => 'Modifier la session';

  @override
  String get tasksEntryFuture =>
      'Une session ne peut pas commencer dans le futur';

  @override
  String get tasksEntryNegative => 'La fin doit être après le début';

  @override
  String get tasksEntryOverlap => 'Chevauche une autre session';

  @override
  String get tasksEntryRunning => 'En cours';

  @override
  String get tasksErrAllDay =>
      'Les tâches sur la journée couvrent des jours entiers';

  @override
  String get tasksErrDuration =>
      'La durée doit être comprise entre 0 minute et 365 jours';

  @override
  String get tasksErrEstimate => 'L’estimation est hors limites';

  @override
  String get tasksErrPriority => 'Priorité non valide';

  @override
  String get tasksErrRecurrenceInvalid =>
      'La règle de répétition n’est pas valide';

  @override
  String get tasksErrRecurrenceNoDate =>
      'Une tâche répétée a besoin d’une date';

  @override
  String get tasksErrTitleEmpty => 'Saisissez un titre';

  @override
  String get tasksErrTitleTooLong =>
      'Le titre est trop long (300 caractères max.)';

  @override
  String get tasksErrZone => 'Fuseau horaire inconnu';

  @override
  String get tasksEvtCompleted => 'Terminée';

  @override
  String get tasksEvtCreated => 'Créée';

  @override
  String get tasksEvtDeleted => 'Supprimée';

  @override
  String get tasksEvtDeletedOccurrence => 'Occurrence retirée';

  @override
  String tasksEvtOccurrence(String date) {
    return 'Occurrence du $date';
  }

  @override
  String get tasksEvtPaused => 'Série en pause';

  @override
  String get tasksEvtReopened => 'Rouverte';

  @override
  String tasksEvtRescheduled(String from, String to) {
    return 'Replanifiée de $from à $to';
  }

  @override
  String get tasksEvtRestored => 'Restaurée';

  @override
  String get tasksEvtResumed => 'Série reprise';

  @override
  String get tasksEvtScheduled => 'Planifiée';

  @override
  String get tasksEvtSkipped => 'Passée';

  @override
  String tasksEvtSkippedReason(String reason) {
    return 'Passée : $reason';
  }

  @override
  String get tasksEvtSplit => 'Série scindée';

  @override
  String get tasksEvtStarted => 'Commencée';

  @override
  String get tasksEvtStatusChanged => 'Statut modifié';

  @override
  String get tasksEvtStopped => 'Arrêtée';

  @override
  String get tasksEvtTimeEntry => 'Session ajoutée';

  @override
  String get tasksEvtUnscheduled => 'Remise à planifier';

  @override
  String tasksEvtUpdated(String fields) {
    return 'Modifiée : $fields';
  }

  @override
  String get tasksFieldAllDay => 'Toute la journée';

  @override
  String get tasksFieldCategory => 'Catégorie';

  @override
  String get tasksFieldChecklist => 'Liste associée';

  @override
  String get tasksFieldColor => 'Couleur';

  @override
  String get tasksFieldDate => 'Date';

  @override
  String get tasksFieldDeadline => 'Échéance';

  @override
  String get tasksFieldDuration => 'Durée';

  @override
  String get tasksFieldEnd => 'Fin';

  @override
  String get tasksFieldEndDate => 'Date de fin';

  @override
  String get tasksFieldEstimate => 'Estimation';

  @override
  String get tasksFieldIcon => 'Icône';

  @override
  String get tasksFieldLocation => 'Lieu';

  @override
  String get tasksFieldNoDate => 'Sans date (à planifier)';

  @override
  String get tasksFieldNotes => 'Notes';

  @override
  String get tasksFieldPriority => 'Priorité';

  @override
  String get tasksFieldRepeat => 'Répétition';

  @override
  String get tasksFieldStart => 'Début';

  @override
  String get tasksFieldStartDate => 'Date de début';

  @override
  String get tasksFieldTimeZone => 'Fuseau horaire';

  @override
  String get tasksFieldTitle => 'Titre';

  @override
  String get tasksFieldTitleHint => 'Que voulez-vous faire ?';

  @override
  String get tasksFieldTracking => 'Suivi';

  @override
  String get tasksFieldUrl => 'Lien';

  @override
  String get tasksFilterAll => 'Toutes';

  @override
  String get tasksFilterDone => 'Faites';

  @override
  String get tasksFilterMissed => 'Manquées';

  @override
  String get tasksFilterMoved => 'Déplacées';

  @override
  String get tasksFilterSkipped => 'Passées';

  @override
  String get tasksFromTemplate => 'À partir d’un modèle…';

  @override
  String get tasksHistory => 'Historique';

  @override
  String get tasksHistoryEmpty => 'Pas encore d’historique';

  @override
  String get tasksHistoryLoadMore => 'Charger plus';

  @override
  String get tasksIconDefault => 'Icône de la catégorie';

  @override
  String get tasksMarkedDone => 'Marquée comme faite';

  @override
  String get tasksMarkedSkipped => 'Passée';

  @override
  String get tasksMdBold => 'Gras';

  @override
  String get tasksMdBullet => 'Liste à puces';

  @override
  String get tasksMdCheckbox => 'Case à cocher';

  @override
  String get tasksMdCode => 'Code';

  @override
  String get tasksMdHeading => 'Titre';

  @override
  String get tasksMdItalic => 'Italique';

  @override
  String get tasksMdNumbered => 'Liste numérotée';

  @override
  String get tasksMoved => 'Déplacée';

  @override
  String tasksMovedFrom(String time) {
    return 'Déplacée depuis $time';
  }

  @override
  String get tasksNextDay => '+1 jour';

  @override
  String tasksNextLabel(String when) {
    return 'Prochaine : $when';
  }

  @override
  String get tasksNextMonth => 'Mois suivant';

  @override
  String get tasksNextOccurrences => 'Prochaines occurrences';

  @override
  String get tasksNoUpcoming => 'Rien à venir';

  @override
  String get tasksNotesEdit => 'Modifier';

  @override
  String get tasksNotesHint => 'Ajouter des notes (gras, listes, cases…)';

  @override
  String get tasksNotesPreview => 'Aperçu';

  @override
  String get tasksOccurrenceDeleted => 'Occurrence retirée';

  @override
  String tasksOpenLinkBody(String url) {
    return '$url va s’ouvrir en dehors d’Everslot.';
  }

  @override
  String get tasksOpenLinkTitle => 'Ouvrir le lien ?';

  @override
  String get tasksOrphansBody =>
      'Les occurrences avec un historique sont toujours conservées comme tâches ponctuelles.';

  @override
  String tasksOrphansCompleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences terminées',
      one: '1 occurrence terminée',
    );
    return '$_temp0';
  }

  @override
  String get tasksOrphansDiscard => 'Supprimer les déplacées';

  @override
  String get tasksOrphansKeep => 'Garder comme tâches ponctuelles';

  @override
  String tasksOrphansMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences déplacées',
      one: '1 occurrence déplacée',
    );
    return '$_temp0';
  }

  @override
  String tasksOrphansOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences avec notes ou temps suivi',
      one: '1 occurrence avec notes ou temps suivi',
    );
    return '$_temp0';
  }

  @override
  String tasksOrphansSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences passées',
      one: '1 occurrence passée',
    );
    return '$_temp0';
  }

  @override
  String get tasksOrphansTitle => 'Certaines occurrences ne correspondent plus';

  @override
  String get tasksOutcomeNote => 'Note de résultat';

  @override
  String get tasksOutcomeNoteHint => 'Comment ça s’est passé ?';

  @override
  String get tasksOverdue => 'En retard';

  @override
  String tasksOverlapHint(String title, String range) {
    return 'Chevauche $title $range';
  }

  @override
  String tasksOverlapMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'et $count autres',
      one: 'et 1 autre',
    );
    return '$_temp0';
  }

  @override
  String get tasksPauseSnack => 'Série en pause';

  @override
  String get tasksPausedBadge => 'En pause';

  @override
  String tasksPlannedVsActual(String planned, String actual) {
    return 'Prévu $planned · réel $actual';
  }

  @override
  String tasksPlusDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count jours',
      one: '+1 jour',
    );
    return '$_temp0';
  }

  @override
  String get tasksPostpone15 => '+15 min';

  @override
  String get tasksPostpone1h => '+1 heure';

  @override
  String get tasksPostponeEvening => 'Ce soir';

  @override
  String get tasksPostponeNextWeek => 'La semaine prochaine, même heure';

  @override
  String get tasksPostponePick => 'Choisir une date et une heure…';

  @override
  String get tasksPostponeTitle => 'Replanifier';

  @override
  String get tasksPostponeTomorrow => 'Demain, même heure';

  @override
  String get tasksPrevMonth => 'Mois précédent';

  @override
  String get tasksQuickAdd => 'Ajouter';

  @override
  String get tasksQuickAddNew => 'Ajouter et nouvelle';

  @override
  String get tasksQuickMore => 'Plus d’options';

  @override
  String get tasksQuickTitleHint => 'Nouvelle tâche';

  @override
  String get tasksQuotaDone => 'Terminé pour cette période';

  @override
  String tasksQuotaProgress(int done, int total) {
    return '$done/$total sur la période';
  }

  @override
  String get tasksRating => 'Note';

  @override
  String tasksRatingValue(int value) {
    return '$value sur 5';
  }

  @override
  String get tasksReminders => 'Rappels';

  @override
  String get tasksRemindersDefault => 'Par défaut';

  @override
  String get tasksReopened => 'Rouverte';

  @override
  String get tasksRepeatNone => 'Ne se répète pas';

  @override
  String get tasksRestored => 'Tâche restaurée';

  @override
  String get tasksResumeSnack => 'Série reprise';

  @override
  String tasksRolledOver(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches inachevées déplacées à aujourd’hui',
      one: '1 tâche inachevée déplacée à aujourd’hui',
    );
    return '$_temp0';
  }

  @override
  String tasksRunningTimer(String title, String elapsed) {
    return 'Minuteur en cours : $title, $elapsed';
  }

  @override
  String get tasksSaveAsTemplate => 'Enregistrer comme modèle';

  @override
  String get tasksSaved => 'Tâche enregistrée';

  @override
  String get tasksScopeAll => 'Toutes les occurrences';

  @override
  String get tasksScopeDeleteTitle => 'Supprimer une tâche répétée';

  @override
  String get tasksScopeFollowing => 'Celle-ci et les suivantes';

  @override
  String get tasksScopePastKept =>
      'Les occurrences passées gardent leurs horaires d’origine.';

  @override
  String get tasksScopeRewritePast => 'Réécrire aussi les occurrences passées';

  @override
  String get tasksScopeThis => 'Cette occurrence';

  @override
  String get tasksScopeThisDisabled =>
      'Seuls l’heure, la durée, le titre et les notes peuvent changer pour une seule occurrence.';

  @override
  String get tasksScopeTitle => 'Appliquer les modifications à';

  @override
  String get tasksSeriesEmpty => 'Aucune occurrence sur cette période';

  @override
  String get tasksSeriesHistoryTitle => 'Historique de la série';

  @override
  String get tasksSeriesStats => 'Statistiques de la série';

  @override
  String tasksShareRepeats(String rule) {
    return 'Répétition : $rule';
  }

  @override
  String get tasksSkipCustomHint => 'Autre raison (facultatif)';

  @override
  String get tasksSkipForgot => 'Oublié';

  @override
  String get tasksSkipNotNeeded => 'Pas nécessaire';

  @override
  String get tasksSkipOther => 'Autre';

  @override
  String get tasksSkipSick => 'Malade';

  @override
  String get tasksSkipTitle => 'Pourquoi passer ?';

  @override
  String get tasksSkipTooBusy => 'Trop occupé';

  @override
  String get tasksStatusCancelled => 'Annulée';

  @override
  String get tasksStatusDone => 'Faite';

  @override
  String get tasksStatusInProgress => 'En cours';

  @override
  String get tasksStatusMissed => 'Manquée';

  @override
  String get tasksStatusScheduled => 'Planifiée';

  @override
  String get tasksStatusSkipped => 'Passée';

  @override
  String get tasksTemplateDelete => 'Supprimer le modèle';

  @override
  String get tasksTemplateSaved => 'Modèle enregistré';

  @override
  String get tasksTemplatesEmpty =>
      'Aucun modèle. Enregistrez une tâche comme modèle depuis son menu.';

  @override
  String get tasksTemplatesTitle => 'Modèles';

  @override
  String get tasksTimeEntries => 'Sessions';

  @override
  String get tasksTimeTracking => 'Suivi du temps';

  @override
  String get tasksTooManyOccurrences =>
      'Trop d’occurrences à afficher — zoomez';

  @override
  String tasksTracked(String duration) {
    return 'Suivi : $duration';
  }

  @override
  String get tasksTrackingCheck => 'Case à cocher';

  @override
  String get tasksTrackingCheckHint =>
      'À cocher ou à passer ; peut être manquée.';

  @override
  String get tasksTrackingEvent => 'Événement';

  @override
  String get tasksTrackingEventHint =>
      'Un bloc de temps (réunion, repas) : pas de case, jamais manqué.';

  @override
  String get tasksTrackingTimer => 'Minuteur';

  @override
  String get tasksTrackingTimerHint =>
      'Mesurez le temps passé ; terminée à l’arrêt du minuteur.';

  @override
  String get tasksUnsavedBody => 'Vos modifications seront perdues.';

  @override
  String get tasksUnsavedTitle => 'Abandonner les modifications ?';

  @override
  String get tasksUntitled => 'Tâche sans titre';

  @override
  String get tasksUpdated => 'Mise à jour';

  @override
  String get tasksUrlInvalid => 'Saisissez une adresse web valide';

  @override
  String tasksZoneBadge(String zone) {
    return 'Heure de $zone';
  }

  @override
  String get tasksZoneFixed => 'Fixe';

  @override
  String get tasksZoneFixedHint => 'Ancré à un fuseau horaire';

  @override
  String get tasksZoneFloating => 'Flottant';

  @override
  String get tasksZoneFloatingHint => 'Même heure où que vous soyez';

  @override
  String get tasksZonePickTitle => 'Choisir un fuseau horaire';

  @override
  String get tasksZoneSearch => 'Rechercher un fuseau';
}
