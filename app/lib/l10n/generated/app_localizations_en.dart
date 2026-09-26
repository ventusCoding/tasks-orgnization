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
  String get attachmentsChecklistLevel => 'On the list';

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
  String get attachmentsFilterAll => 'All';

  @override
  String get attachmentsFilterImages => 'Images';

  @override
  String get attachmentsFilterOther => 'Other';

  @override
  String get attachmentsFilterPdfs => 'PDFs';

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
  String get checklistAddItem => 'Add item';

  @override
  String get checklistAddSubItem => 'Add sub-item';

  @override
  String get checklistAllAttachments => 'All attachments';

  @override
  String get checklistAllLists => 'All lists';

  @override
  String get checklistAttach => 'Attach';

  @override
  String checklistBelowBadges(int blocked, int waiting) {
    return '$blocked blocked · $waiting waiting below';
  }

  @override
  String get checklistBodyHint => 'Note';

  @override
  String checklistCarrying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moving $count items',
      one: 'Moving 1 item',
    );
    return '$_temp0';
  }

  @override
  String get checklistCollapse => 'Collapse';

  @override
  String get checklistCollapseAll => 'Collapse all';

  @override
  String get checklistCollapsedState => 'collapsed';

  @override
  String get checklistCompleted => 'List completed!';

  @override
  String get checklistCompletedArchive => 'Archive';

  @override
  String get checklistCompletedKeep => 'Keep';

  @override
  String get checklistCompletedReset => 'Reset';

  @override
  String get checklistCopied => 'Copied';

  @override
  String get checklistCopy => 'Copy';

  @override
  String get checklistCopyText => 'Copy as text';

  @override
  String get checklistCut => 'Cut';

  @override
  String get checklistDelete => 'Delete list';

  @override
  String get checklistDeleteCompleted => 'Delete completed items';

  @override
  String get checklistDeleteItem => 'Delete';

  @override
  String checklistDepthBadge(int level) {
    return 'L$level';
  }

  @override
  String get checklistDetails => 'Details';

  @override
  String get checklistDragHandle => 'Drag to move';

  @override
  String get checklistDue => 'Due date';

  @override
  String get checklistDuplicate => 'Duplicate list';

  @override
  String get checklistDuplicateItem => 'Duplicate';

  @override
  String get checklistEmptyFocus => 'No sub-items yet';

  @override
  String get checklistExpand => 'Expand';

  @override
  String get checklistExpandAll => 'Expand all';

  @override
  String checklistExpandToLevel(int level) {
    return 'Expand to level $level';
  }

  @override
  String get checklistFilterAll => 'All';

  @override
  String get checklistFilterDueSoon => 'Due soon';

  @override
  String get checklistFilterHasAttachments => 'Has attachments';

  @override
  String get checklistFilterOpen => 'Open';

  @override
  String get checklistFilterText => 'Search in list';

  @override
  String get checklistFiltered => 'Filtered view';

  @override
  String get checklistFocus => 'Focus';

  @override
  String get checklistHideCheckboxes => 'Hide checkboxes';

  @override
  String get checklistHideCompleted => 'Hide completed';

  @override
  String get checklistHideKeyboard => 'Hide keyboard';

  @override
  String get checklistImport => 'Import items…';

  @override
  String get checklistInTrash => 'This list is in the trash';

  @override
  String get checklistIndent => 'Indent';

  @override
  String get checklistInsights => 'Insights';

  @override
  String get checklistInsightsPlaceholder =>
      'Checklist insights arrive with the stats section.';

  @override
  String get checklistItemHint => 'List item';

  @override
  String checklistItemsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items deleted',
      one: '1 item deleted',
    );
    return '$_temp0';
  }

  @override
  String get checklistItemsMoved => 'Moved';

  @override
  String get checklistLabelName => 'Label name';

  @override
  String get checklistLabels => 'Labels';

  @override
  String get checklistLineBreak => 'Line break';

  @override
  String get checklistLinkedTask => 'Linked task';

  @override
  String get checklistModeEdit => 'Edit';

  @override
  String get checklistModePreview => 'Preview';

  @override
  String get checklistMoveConflict =>
      'A move conflicted with a change on another device and was undone.';

  @override
  String get checklistMoveDown => 'Move down';

  @override
  String get checklistMoveTo => 'Move to…';

  @override
  String get checklistMoveUp => 'Move up';

  @override
  String get checklistNewLabel => 'New label';

  @override
  String get checklistNextOpen => 'Next open item';

  @override
  String get checklistNoItems => 'No items yet';

  @override
  String get checklistNoLabels => 'No labels yet';

  @override
  String get checklistNotFound => 'This list doesn\'t exist';

  @override
  String get checklistOpenTrash => 'Open trash';

  @override
  String get checklistOutdent => 'Outdent';

  @override
  String get checklistPaste => 'Paste';

  @override
  String get checklistPasteHere => 'Paste here';

  @override
  String get checklistPendingUploads => 'Uploads pending';

  @override
  String checklistProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get checklistPromote => 'Promote to list';

  @override
  String get checklistPromoted => 'Created a new list';

  @override
  String get checklistRecovered => 'Recovered';

  @override
  String get checklistRepeat => 'Repeat…';

  @override
  String get checklistResetConfirm =>
      'Every item goes back to to-do and reason notes are cleared.';

  @override
  String get checklistResetDone => 'List reset';

  @override
  String get checklistResetNow => 'Reset now';

  @override
  String get checklistResetStatuses => 'Reset all statuses';

  @override
  String get checklistResetView => 'Reset';

  @override
  String checklistRowSemantics(String text, int level, int index, int count) {
    return '$text, level $level, item $index of $count';
  }

  @override
  String get checklistSaveAsTemplate => 'Save as template';

  @override
  String get checklistScheduleTask => 'Schedule as task';

  @override
  String get checklistSelect => 'Select';

  @override
  String get checklistSelectAll => 'Select all';

  @override
  String get checklistSelectSubtree => 'Select sub-items';

  @override
  String checklistSelected(int count) {
    return '$count selected';
  }

  @override
  String get checklistSettings => 'List settings';

  @override
  String get checklistShare => 'Share / export';

  @override
  String get checklistShowCheckboxes => 'Show checkboxes';

  @override
  String get checklistSortAlpha => 'Alphabetical';

  @override
  String get checklistSortChildren => 'Sort sub-items';

  @override
  String get checklistSortCompletedBottom => 'Sort completed to bottom';

  @override
  String get checklistSortDescending => 'Descending';

  @override
  String get checklistSortDue => 'Due date';

  @override
  String get checklistSortFilter => 'Sort & filter';

  @override
  String get checklistSortManual => 'Manual';

  @override
  String get checklistSortPriority => 'Priority';

  @override
  String get checklistSortRecent => 'Recently changed';

  @override
  String get checklistSortStatus => 'Status';

  @override
  String checklistSortedBy(String criterion) {
    return 'Sorted by $criterion';
  }

  @override
  String get checklistStatusChanged => 'Status changed';

  @override
  String checklistSubItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sub-items',
      one: '1 sub-item',
    );
    return '$_temp0';
  }

  @override
  String get checklistTaskPlaceholder =>
      'Linking to planner tasks arrives with the planner.';

  @override
  String get checklistTemplateSaved => 'Saved as template';

  @override
  String get checklistTitleHint => 'Title';

  @override
  String get checklistUncheckAll => 'Uncheck all';

  @override
  String checklistUncheckConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uncheck $count items?',
      one: 'Uncheck 1 item?',
    );
    return '$_temp0';
  }

  @override
  String get checklistViewGallery => 'Gallery';

  @override
  String get checklistViewKanban => 'Kanban';

  @override
  String get checklistViewOutline => 'Outline';

  @override
  String get checklistZoomOut => 'Zoom out';

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
  String get exportBranchOnly => 'Only this branch';

  @override
  String get exportCopied => 'Copied to clipboard';

  @override
  String get exportCopy => 'Copy to clipboard';

  @override
  String get exportMarkdown => 'Markdown';

  @override
  String get exportOpml => 'OPML';

  @override
  String get exportPlain => 'Plain text';

  @override
  String get exportShare => 'Share…';

  @override
  String get exportTitle => 'Share / export';

  @override
  String get galleryEmpty => 'No items with images';

  @override
  String get galleryOnlyImages => 'Only items with images';

  @override
  String get importAction => 'Import';

  @override
  String get importChooseFile => 'Choose file';

  @override
  String get importConvertBody => 'Convert note to items';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items imported',
      one: '1 item imported',
    );
    return '$_temp0';
  }

  @override
  String importItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get importKeepOne => 'Keep as one item';

  @override
  String get importPasteHint => 'Paste indented text, Markdown or OPML';

  @override
  String get importSplit => 'Split into items (keep nesting)';

  @override
  String get importTitle => 'Import';

  @override
  String get importWarningAttachments => 'Attachment references were skipped';

  @override
  String get importWarningEmpty => 'Nothing to import';

  @override
  String get importWarningMalformed => 'This file couldn\'t be read';

  @override
  String get importWarningTooMany =>
      'Only the first 10 000 lines were imported';

  @override
  String get itemAddReminder => 'Add reminder';

  @override
  String get itemAddTime => 'Add time';

  @override
  String get itemAttachments => 'Attachments';

  @override
  String get itemClearDue => 'Remove due date';

  @override
  String itemCompletedOn(String date) {
    return 'Completed $date';
  }

  @override
  String itemCreated(String date) {
    return 'Created $date';
  }

  @override
  String get itemDetailsTitle => 'Item details';

  @override
  String get itemDue => 'Due';

  @override
  String get itemDueOverdue => 'Overdue';

  @override
  String get itemDueToday => 'Today';

  @override
  String get itemDueTomorrow => 'Tomorrow';

  @override
  String itemEdited(String date) {
    return 'Edited $date';
  }

  @override
  String get itemHistory => 'History';

  @override
  String get itemHistoryCause => 'automatic';

  @override
  String itemHistoryDevice(String device) {
    return 'on $device';
  }

  @override
  String get itemHistoryEmpty => 'No status changes yet';

  @override
  String itemHistoryTransition(String from, String to) {
    return '$from → $to';
  }

  @override
  String get itemInsights => 'Insights';

  @override
  String get itemNoDue => 'No due date';

  @override
  String get itemNote => 'Note';

  @override
  String get itemOtherDevice => 'another device';

  @override
  String get itemPriority => 'Priority';

  @override
  String get itemReminders => 'Reminders';

  @override
  String get itemRemindersPlaceholder =>
      'Reminders for this item will be set here.';

  @override
  String get itemText => 'Text';

  @override
  String get itemThisDevice => 'this device';

  @override
  String get itemTimeInStatus => 'Time in status';

  @override
  String get kanbanAll => 'All items';

  @override
  String get kanbanChildren => 'Direct sub-items';

  @override
  String get kanbanEmptyColumn => 'Drop items here';

  @override
  String get kanbanLeaves => 'Leaves only';

  @override
  String get kanbanScope => 'Show';

  @override
  String get kanbanShowCancelled => 'Show cancelled';

  @override
  String get listsArchive => 'Archive';

  @override
  String get listsArchiveAction => 'Archive';

  @override
  String get listsArchiveEmpty => 'No archived lists';

  @override
  String get listsArchived => 'List archived';

  @override
  String listsBadgeBlocked(int count) {
    return '$count blocked';
  }

  @override
  String listsBadgeStale(int count) {
    return '$count stale';
  }

  @override
  String listsBadgeWaiting(int count) {
    return '$count waiting';
  }

  @override
  String get listsBoardSort => 'Sort cards';

  @override
  String get listsBoardSortManual => 'Manual';

  @override
  String get listsBoardSortRecent => 'Recently edited';

  @override
  String get listsBoardSortTitle => 'Title';

  @override
  String get listsCardActions => 'List actions';

  @override
  String listsCardMore(int count) {
    return '+$count more';
  }

  @override
  String listsCardProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String listsCardSemantics(String title, String progress) {
    return '$title, $progress';
  }

  @override
  String get listsColor => 'Color';

  @override
  String listsCopyOf(String title) {
    return 'Copy of $title';
  }

  @override
  String get listsDelete => 'Delete';

  @override
  String get listsDeleted => 'List deleted';

  @override
  String get listsDragHint => 'Long-press and drag to reorder';

  @override
  String get listsDuplicate => 'Duplicate';

  @override
  String get listsDuplicated => 'List duplicated';

  @override
  String get listsEmptyAction => 'Create your first list';

  @override
  String get listsEmptyMessage =>
      'Checklists, notes and routines — nested as deep as you need.';

  @override
  String get listsEmptyTitle => 'No lists yet';

  @override
  String get listsFilterColor => 'Color';

  @override
  String get listsFilterHasAttachments => 'With attachments';

  @override
  String get listsFilterHasBlocked => 'Waiting or blocked';

  @override
  String get listsFilterPinned => 'Pinned';

  @override
  String get listsFilterRepeating => 'Repeating';

  @override
  String get listsFromTemplate => 'From template';

  @override
  String get listsGridView => 'Grid view';

  @override
  String get listsImportFile => 'Import file…';

  @override
  String get listsListView => 'List view';

  @override
  String get listsMoveItems => 'Move items…';

  @override
  String get listsNewChecklist => 'New checklist';

  @override
  String get listsNewNote => 'New note';

  @override
  String get listsOthers => 'Others';

  @override
  String get listsPin => 'Pin';

  @override
  String get listsPinned => 'Pinned';

  @override
  String get listsPreferences => 'Lists settings';

  @override
  String get listsRepeats => 'Repeats';

  @override
  String get listsResetStatusesOption => 'Reset all statuses to to-do';

  @override
  String get listsSearchHint => 'Search lists';

  @override
  String get listsSearchItems => 'Items';

  @override
  String get listsSearchNoResults => 'No matching lists or items';

  @override
  String get listsShowBody => 'Show note text on cards';

  @override
  String get listsShowSmartChips => 'Show waiting / blocked chips';

  @override
  String get listsTemplates => 'Templates';

  @override
  String get listsTrash => 'Trash';

  @override
  String get listsUnarchive => 'Unarchive';

  @override
  String get listsUnarchived => 'List restored from archive';

  @override
  String get listsUnpin => 'Unpin';

  @override
  String get listsUntitled => 'Untitled';

  @override
  String get localOnlyBanner =>
      'Cloud sync isn\'t configured — your data stays on this device.';

  @override
  String get moveChooseParent => 'Choose where';

  @override
  String moveDone(String title) {
    return 'Moved to $title';
  }

  @override
  String get moveToList => 'Move to list';

  @override
  String get moveToTop => 'Top level';

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
  String repeatChip(String rule, String when) {
    return 'Resets $rule · next $when';
  }

  @override
  String get repeatCustom => 'Custom rule';

  @override
  String get repeatDaily => 'Every day';

  @override
  String get repeatModeAll => 'Everything back to to-do';

  @override
  String get repeatModeCompleted => 'Uncheck completed items only';

  @override
  String get repeatMonthly => 'Every month';

  @override
  String get repeatNoRuns => 'No finished runs yet';

  @override
  String get repeatNone => 'Doesn\'t repeat';

  @override
  String get repeatResetTime => 'Reset time';

  @override
  String repeatRunSummary(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get repeatRuns => 'Run history';

  @override
  String get repeatTitle => 'Repeat';

  @override
  String get repeatWeekdays => 'Every weekday';

  @override
  String get repeatWeekly => 'Every week';

  @override
  String get savedSnack => 'Saved';

  @override
  String get settingsAutoComplete => 'Complete parents automatically';

  @override
  String get settingsCascadeAlways => 'Complete sub-items too';

  @override
  String get settingsCascadeAsk => 'Ask';

  @override
  String get settingsCascadeNever => 'Leave sub-items';

  @override
  String get settingsCategory => 'Category';

  @override
  String get settingsCompleteChildren => 'When completing a parent';

  @override
  String get settingsDefaultOpen => 'Open in';

  @override
  String get settingsHideCheckboxes => 'Hide checkboxes (bullets)';

  @override
  String get settingsProgressChildren => 'Direct sub-items only';

  @override
  String get settingsProgressLeaves => 'All sub-items';

  @override
  String get settingsProgressMode => 'Progress counts';

  @override
  String get settingsRequireReason => 'Require a reason for';

  @override
  String get settingsShowAttachments => 'Show attachments in preview';

  @override
  String get settingsShowNotes => 'Show notes in preview';

  @override
  String get settingsSortCompleted => 'Sort completed to bottom';

  @override
  String settingsStaleDays(int days) {
    return 'Mark stale after $days days';
  }

  @override
  String get settingsSwipeComplete => 'Complete';

  @override
  String get settingsSwipeEditLeft => 'Edit mode · swipe left';

  @override
  String get settingsSwipeEditRight => 'Edit mode · swipe right';

  @override
  String get settingsSwipeIndent => 'Indent';

  @override
  String get settingsSwipeMenu => 'Actions menu';

  @override
  String get settingsSwipeNone => 'Nothing';

  @override
  String get settingsSwipeOutdent => 'Outdent';

  @override
  String get settingsSwipePreviewLeft => 'Preview · swipe left';

  @override
  String get settingsSwipePreviewRight => 'Preview · swipe right';

  @override
  String get settingsSwipeTitle => 'Swipe actions';

  @override
  String get smartBlocked => 'Blocked';

  @override
  String smartChip(String label, int count) {
    return '$label · $count';
  }

  @override
  String get smartClearFollowUp => 'Clear follow-up';

  @override
  String get smartEmpty => 'Nothing here — nice.';

  @override
  String get smartFollowUps => 'Follow-ups';

  @override
  String get smartGroupByList => 'Group by list';

  @override
  String get smartOngoing => 'Ongoing';

  @override
  String get smartOpenInList => 'Open in list';

  @override
  String get smartSetFollowUp => 'Set follow-up';

  @override
  String get smartSortAge => 'Age';

  @override
  String get smartSortFollowUp => 'Follow-up';

  @override
  String get smartSortList => 'List';

  @override
  String get smartUnknown => 'Unknown smart list';

  @override
  String get smartWaiting => 'Waiting';

  @override
  String get stateEmpty => 'Nothing here yet';

  @override
  String get stateErrorBody => 'Please try again.';

  @override
  String get stateErrorTitle => 'Something went wrong';

  @override
  String get stateLoading => 'Loading…';

  @override
  String get statusAddNote => 'Add note…';

  @override
  String statusAgeDays(int n) {
    return '$n d';
  }

  @override
  String statusAgeHours(int n) {
    return '$n h';
  }

  @override
  String statusAgeMinutes(int n) {
    return '$n min';
  }

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusCascadeAll => 'Complete all';

  @override
  String get statusCascadeOnlyThis => 'Only this one';

  @override
  String statusCascadeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Also complete $count open sub-items?',
      one: 'Also complete 1 open sub-item?',
    );
    return '$_temp0';
  }

  @override
  String get statusChange => 'Change status';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFollowUp => 'Follow up';

  @override
  String statusFollowUpChip(String when) {
    return 'Check back $when';
  }

  @override
  String get statusFollowUpCustom => 'Custom…';

  @override
  String get statusFollowUpIn3Days => 'In 3 days';

  @override
  String get statusFollowUpLaterToday => 'Later today';

  @override
  String get statusFollowUpNextWeek => 'Next week';

  @override
  String get statusFollowUpNone => 'No follow-up';

  @override
  String get statusFollowUpOverdue => 'Check back now';

  @override
  String get statusFollowUpTomorrow => 'Tomorrow 09:00';

  @override
  String get statusKeepFollowUp => 'Keep follow-up';

  @override
  String statusMarked(String status) {
    return 'Marked $status';
  }

  @override
  String get statusOngoing => 'In progress';

  @override
  String get statusReasonBlocked => 'What\'s blocking it?';

  @override
  String get statusReasonOther => 'Add a note (optional)';

  @override
  String get statusReasonRequired => 'A reason is required';

  @override
  String get statusReasonWaiting => 'Waiting on whom / what?';

  @override
  String get statusRecentReasons => 'Recent';

  @override
  String get statusSheetTitle => 'Status';

  @override
  String get statusStale => 'Stale';

  @override
  String get statusTodo => 'To do';

  @override
  String get statusWaiting => 'Waiting';

  @override
  String statusWithAge(String status, String age) {
    return '$status · $age';
  }

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
  String get templatesBuiltin => 'Built-in';

  @override
  String get templatesCreated => 'List created from template';

  @override
  String get templatesEdit => 'Edit template';

  @override
  String get templatesEmpty => 'Save any list as a template from its menu.';

  @override
  String get templatesMine => 'My templates';

  @override
  String get templatesRename => 'Rename';

  @override
  String get templatesUse => 'Use template';
}
