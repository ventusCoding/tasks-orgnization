import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @actionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get actionDuplicate;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get actionInbox;

  /// No description provided for @actionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get actionMore;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @actionRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get actionRedo;

  /// No description provided for @actionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get actionRestore;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get actionSettings;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get actionToday;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @activityArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get activityArchived;

  /// No description provided for @activityAttachmentAdded.
  ///
  /// In en, this message translates to:
  /// **'Attachment added: {name}'**
  String activityAttachmentAdded(String name);

  /// No description provided for @activityAttachmentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Attachment removed: {name}'**
  String activityAttachmentRemoved(String name);

  /// No description provided for @activityCauseAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get activityCauseAutomatic;

  /// No description provided for @activityCauseBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk change'**
  String get activityCauseBulk;

  /// No description provided for @activityCauseImport.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get activityCauseImport;

  /// No description provided for @activityChangedFields.
  ///
  /// In en, this message translates to:
  /// **'Changed {fields}'**
  String activityChangedFields(String fields);

  /// No description provided for @activityCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get activityCompleted;

  /// No description provided for @activityCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get activityCreated;

  /// No description provided for @activityCreatedCopy.
  ///
  /// In en, this message translates to:
  /// **'Created as a copy'**
  String get activityCreatedCopy;

  /// No description provided for @activityCreatedFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'Created from a template'**
  String get activityCreatedFromTemplate;

  /// No description provided for @activityDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get activityDeleted;

  /// No description provided for @activityDeletedWithItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleted with 1 item} other{Deleted with {count} items}}'**
  String activityDeletedWithItems(int count);

  /// No description provided for @activityDurationChanged.
  ///
  /// In en, this message translates to:
  /// **'Duration changed from {from} to {to}'**
  String activityDurationChanged(String from, String to);

  /// No description provided for @activityEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get activityEdited;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get activityEmpty;

  /// No description provided for @activityFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'category'**
  String get activityFieldCategory;

  /// No description provided for @activityFieldColor.
  ///
  /// In en, this message translates to:
  /// **'color'**
  String get activityFieldColor;

  /// No description provided for @activityFieldDue.
  ///
  /// In en, this message translates to:
  /// **'due date'**
  String get activityFieldDue;

  /// No description provided for @activityFieldDuration.
  ///
  /// In en, this message translates to:
  /// **'duration'**
  String get activityFieldDuration;

  /// No description provided for @activityFieldIcon.
  ///
  /// In en, this message translates to:
  /// **'icon'**
  String get activityFieldIcon;

  /// No description provided for @activityFieldName.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get activityFieldName;

  /// No description provided for @activityFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'notes'**
  String get activityFieldNotes;

  /// No description provided for @activityFieldPriority.
  ///
  /// In en, this message translates to:
  /// **'priority'**
  String get activityFieldPriority;

  /// No description provided for @activityFieldRepeat.
  ///
  /// In en, this message translates to:
  /// **'repeat'**
  String get activityFieldRepeat;

  /// No description provided for @activityFieldTags.
  ///
  /// In en, this message translates to:
  /// **'tags'**
  String get activityFieldTags;

  /// No description provided for @activityFieldText.
  ///
  /// In en, this message translates to:
  /// **'text'**
  String get activityFieldText;

  /// No description provided for @activityFieldTime.
  ///
  /// In en, this message translates to:
  /// **'time'**
  String get activityFieldTime;

  /// No description provided for @activityFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'title'**
  String get activityFieldTitle;

  /// No description provided for @activityFile.
  ///
  /// In en, this message translates to:
  /// **'file'**
  String get activityFile;

  /// No description provided for @activityItemsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item added} other{{count} items added}}'**
  String activityItemsAdded(int count);

  /// No description provided for @activityListSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get activityListSeparator;

  /// No description provided for @activityMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get activityMerged;

  /// No description provided for @activityMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get activityMoved;

  /// No description provided for @activityMovedToList.
  ///
  /// In en, this message translates to:
  /// **'Moved to another list'**
  String get activityMovedToList;

  /// No description provided for @activityOther.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get activityOther;

  /// No description provided for @activityPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get activityPaused;

  /// No description provided for @activityQuoted.
  ///
  /// In en, this message translates to:
  /// **'“{text}”'**
  String activityQuoted(String text);

  /// No description provided for @activityRelapse.
  ///
  /// In en, this message translates to:
  /// **'Relapse logged'**
  String get activityRelapse;

  /// No description provided for @activityReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get activityReopened;

  /// No description provided for @activityRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Moved from {from} to {to}'**
  String activityRescheduled(String from, String to);

  /// No description provided for @activityReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get activityReset;

  /// No description provided for @activityRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get activityRestored;

  /// No description provided for @activityResumed.
  ///
  /// In en, this message translates to:
  /// **'Resumed'**
  String get activityResumed;

  /// No description provided for @activityRollover.
  ///
  /// In en, this message translates to:
  /// **'Rolled over'**
  String get activityRollover;

  /// No description provided for @activityScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get activityScheduled;

  /// No description provided for @activityScopeFollowing.
  ///
  /// In en, this message translates to:
  /// **'This and following occurrences'**
  String get activityScopeFollowing;

  /// No description provided for @activityScopeSeries.
  ///
  /// In en, this message translates to:
  /// **'All occurrences'**
  String get activityScopeSeries;

  /// No description provided for @activitySeriesSplit.
  ///
  /// In en, this message translates to:
  /// **'Series split'**
  String get activitySeriesSplit;

  /// No description provided for @activitySkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get activitySkipped;

  /// No description provided for @activitySkippedReason.
  ///
  /// In en, this message translates to:
  /// **'Skipped: {reason}'**
  String activitySkippedReason(String reason);

  /// No description provided for @activitySorted.
  ///
  /// In en, this message translates to:
  /// **'Items sorted'**
  String get activitySorted;

  /// No description provided for @activityStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get activityStarted;

  /// No description provided for @activityStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed from {from} to {to}'**
  String activityStatusChanged(String from, String to);

  /// No description provided for @activityStatusNoteChanged.
  ///
  /// In en, this message translates to:
  /// **'Reason updated'**
  String get activityStatusNoteChanged;

  /// No description provided for @activityStatusSet.
  ///
  /// In en, this message translates to:
  /// **'Status set to {to}'**
  String activityStatusSet(String to);

  /// No description provided for @activityStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get activityStopped;

  /// No description provided for @activityTagsChanged.
  ///
  /// In en, this message translates to:
  /// **'Tags updated'**
  String get activityTagsChanged;

  /// No description provided for @activityTimeLogged.
  ///
  /// In en, this message translates to:
  /// **'Time logged'**
  String get activityTimeLogged;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get activityTitle;

  /// No description provided for @activityUnarchived.
  ///
  /// In en, this message translates to:
  /// **'Unarchived'**
  String get activityUnarchived;

  /// No description provided for @activityUnscheduled.
  ///
  /// In en, this message translates to:
  /// **'Moved to the backlog'**
  String get activityUnscheduled;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Everslot'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Own every slot of your day.'**
  String get appTagline;

  /// No description provided for @attachmentsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get attachmentsAdd;

  /// No description provided for @attachmentsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment added} other{{count} attachments added}}'**
  String attachmentsAdded(int count);

  /// No description provided for @attachmentsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get attachmentsCacheCleared;

  /// No description provided for @attachmentsCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Local cache: {size}'**
  String attachmentsCacheSize(String size);

  /// No description provided for @attachmentsCameraPrimerBody.
  ///
  /// In en, this message translates to:
  /// **'Everslot asks for camera access so you can attach photos. Photos stay on your device until they\'re uploaded to your account.'**
  String get attachmentsCameraPrimerBody;

  /// No description provided for @attachmentsCameraPrimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Use your camera'**
  String get attachmentsCameraPrimerTitle;

  /// No description provided for @attachmentsCaption.
  ///
  /// In en, this message translates to:
  /// **'Caption'**
  String get attachmentsCaption;

  /// No description provided for @attachmentsChecklistLevel.
  ///
  /// In en, this message translates to:
  /// **'On the list'**
  String get attachmentsChecklistLevel;

  /// No description provided for @attachmentsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get attachmentsClearCache;

  /// No description provided for @attachmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment} other{{count} attachments}}'**
  String attachmentsCount(int count);

  /// No description provided for @attachmentsDownloadWhenOnline.
  ///
  /// In en, this message translates to:
  /// **'This file will download when you\'re online.'**
  String get attachmentsDownloadWhenOnline;

  /// No description provided for @attachmentsEditCaption.
  ///
  /// In en, this message translates to:
  /// **'Edit caption'**
  String get attachmentsEditCaption;

  /// No description provided for @attachmentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No attachments yet'**
  String get attachmentsEmpty;

  /// No description provided for @attachmentsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get attachmentsFilterAll;

  /// No description provided for @attachmentsFilterImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get attachmentsFilterImages;

  /// No description provided for @attachmentsFilterOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get attachmentsFilterOther;

  /// No description provided for @attachmentsFilterPdfs.
  ///
  /// In en, this message translates to:
  /// **'PDFs'**
  String get attachmentsFilterPdfs;

  /// No description provided for @attachmentsGoToItem.
  ///
  /// In en, this message translates to:
  /// **'Go to item'**
  String get attachmentsGoToItem;

  /// No description provided for @attachmentsKindAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get attachmentsKindAudio;

  /// No description provided for @attachmentsKindFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get attachmentsKindFile;

  /// No description provided for @attachmentsKindPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get attachmentsKindPdf;

  /// No description provided for @attachmentsKindPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get attachmentsKindPhoto;

  /// No description provided for @attachmentsKindVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get attachmentsKindVideo;

  /// No description provided for @attachmentsLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device'**
  String get attachmentsLocalOnly;

  /// No description provided for @attachmentsMore.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String attachmentsMore(int count);

  /// No description provided for @attachmentsMoveEarlier.
  ///
  /// In en, this message translates to:
  /// **'Move earlier'**
  String get attachmentsMoveEarlier;

  /// No description provided for @attachmentsMoveLater.
  ///
  /// In en, this message translates to:
  /// **'Move later'**
  String get attachmentsMoveLater;

  /// No description provided for @attachmentsNoPreview.
  ///
  /// In en, this message translates to:
  /// **'No preview for this file type'**
  String get attachmentsNoPreview;

  /// No description provided for @attachmentsOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get attachmentsOpenSettings;

  /// No description provided for @attachmentsOpenWith.
  ///
  /// In en, this message translates to:
  /// **'Open with…'**
  String get attachmentsOpenWith;

  /// No description provided for @attachmentsPendingUploads.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 upload pending} other{{count} uploads pending}}'**
  String attachmentsPendingUploads(int count);

  /// No description provided for @attachmentsPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Everslot can\'t access your camera or photos. You can allow access in the system settings.'**
  String get attachmentsPermissionBody;

  /// No description provided for @attachmentsPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Access needed'**
  String get attachmentsPermissionTitle;

  /// No description provided for @attachmentsRejectedDuplicate.
  ///
  /// In en, this message translates to:
  /// **'{name} is already attached'**
  String attachmentsRejectedDuplicate(String name);

  /// No description provided for @attachmentsRejectedEmpty.
  ///
  /// In en, this message translates to:
  /// **'{name} is empty'**
  String attachmentsRejectedEmpty(String name);

  /// No description provided for @attachmentsRejectedTooLarge.
  ///
  /// In en, this message translates to:
  /// **'{name} is larger than {limit}'**
  String attachmentsRejectedTooLarge(String name, String limit);

  /// No description provided for @attachmentsRejectedTooMany.
  ///
  /// In en, this message translates to:
  /// **'Limit of {count} attachments reached'**
  String attachmentsRejectedTooMany(int count);

  /// No description provided for @attachmentsRejectedType.
  ///
  /// In en, this message translates to:
  /// **'{name}: this file type isn\'t supported'**
  String attachmentsRejectedType(String name);

  /// No description provided for @attachmentsRejectedUnreadable.
  ///
  /// In en, this message translates to:
  /// **'{name} couldn\'t be read'**
  String attachmentsRejectedUnreadable(String name);

  /// No description provided for @attachmentsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get attachmentsRemove;

  /// No description provided for @attachmentsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Attachment removed'**
  String get attachmentsRemoved;

  /// No description provided for @attachmentsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry upload'**
  String get attachmentsRetry;

  /// No description provided for @attachmentsSemantics.
  ///
  /// In en, this message translates to:
  /// **'{kind} {index} of {total}'**
  String attachmentsSemantics(String kind, int index, int total);

  /// No description provided for @attachmentsSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsSettingsTitle;

  /// No description provided for @attachmentsSizeB.
  ///
  /// In en, this message translates to:
  /// **'{size} B'**
  String attachmentsSizeB(String size);

  /// No description provided for @attachmentsSizeGb.
  ///
  /// In en, this message translates to:
  /// **'{size} GB'**
  String attachmentsSizeGb(String size);

  /// No description provided for @attachmentsSizeKb.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String attachmentsSizeKb(String size);

  /// No description provided for @attachmentsSizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String attachmentsSizeMb(String size);

  /// No description provided for @attachmentsSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get attachmentsSourceCamera;

  /// No description provided for @attachmentsSourceFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose files'**
  String get attachmentsSourceFiles;

  /// No description provided for @attachmentsSourcePhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose photos'**
  String get attachmentsSourcePhotos;

  /// No description provided for @attachmentsStatusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get attachmentsStatusDownloading;

  /// No description provided for @attachmentsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed — tap to retry'**
  String get attachmentsStatusFailed;

  /// No description provided for @attachmentsStatusNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded — tap to fetch'**
  String get attachmentsStatusNotDownloaded;

  /// No description provided for @attachmentsStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get attachmentsStatusProcessing;

  /// No description provided for @attachmentsStatusUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {percent} %'**
  String attachmentsStatusUploading(int percent);

  /// No description provided for @attachmentsStatusUploadingShort.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get attachmentsStatusUploadingShort;

  /// No description provided for @attachmentsStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for network'**
  String get attachmentsStatusWaiting;

  /// No description provided for @attachmentsStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage used: {size}'**
  String attachmentsStorageUsed(String size);

  /// No description provided for @attachmentsViewerPosition.
  ///
  /// In en, this message translates to:
  /// **'{index} / {total}'**
  String attachmentsViewerPosition(int index, int total);

  /// No description provided for @attachmentsWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Upload attachments on Wi-Fi only'**
  String get attachmentsWifiOnly;

  /// No description provided for @authAvatarChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get authAvatarChange;

  /// No description provided for @authAvatarRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get authAvatarRemove;

  /// No description provided for @authBrowserFlowStarted.
  ///
  /// In en, this message translates to:
  /// **'Finish signing in in your browser, then come back to Everslot.'**
  String get authBrowserFlowStarted;

  /// No description provided for @authChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get authChangeEmail;

  /// No description provided for @authCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email}, or tap the link in that email.'**
  String authCodeBody(String email);

  /// No description provided for @authCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get authCodeLabel;

  /// No description provided for @authCodeResent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way.'**
  String get authCodeResent;

  /// No description provided for @authCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get authCodeTitle;

  /// No description provided for @authContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueApple;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @authContinueGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue without an account'**
  String get authContinueGuest;

  /// No description provided for @authCurrentZone.
  ///
  /// In en, this message translates to:
  /// **'Current time zone'**
  String get authCurrentZone;

  /// No description provided for @authDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get authDeleteAccount;

  /// No description provided for @authDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all your data — plans, lists, habits and attachments — on every device. It can\'t be undone.'**
  String get authDeleteBody;

  /// No description provided for @authDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get authDeleteConfirm;

  /// No description provided for @authDeleteExportFirst.
  ///
  /// In en, this message translates to:
  /// **'Export my data first'**
  String get authDeleteExportFirst;

  /// No description provided for @authDeleteReauthBody.
  ///
  /// In en, this message translates to:
  /// **'To confirm it\'s you, enter the code we sent to {email}.'**
  String authDeleteReauthBody(String email);

  /// No description provided for @authDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get authDeleteTitle;

  /// No description provided for @authDeleteUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand this can\'t be undone'**
  String get authDeleteUnderstand;

  /// No description provided for @authDeleteWeb.
  ///
  /// In en, this message translates to:
  /// **'You can also request deletion on the web: {url}'**
  String authDeleteWeb(String url);

  /// No description provided for @authDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get authDeleted;

  /// No description provided for @authDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get authDeleting;

  /// No description provided for @authDeviceRevokedBody.
  ///
  /// In en, this message translates to:
  /// **'This device was removed from your account on another device. Export your data first if you want a copy, then sign out.'**
  String get authDeviceRevokedBody;

  /// No description provided for @authDeviceRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'This device was removed'**
  String get authDeviceRevokedTitle;

  /// No description provided for @authDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get authDisplayName;

  /// No description provided for @authDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get authDisplayNameHint;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailHint;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authErrorCaptcha.
  ///
  /// In en, this message translates to:
  /// **'The security check failed. Please try again.'**
  String get authErrorCaptcha;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email already belongs to another account.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorGuestDisabled.
  ///
  /// In en, this message translates to:
  /// **'Guest mode is turned off on this server.'**
  String get authErrorGuestDisabled;

  /// No description provided for @authErrorIdentityInUse.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is already linked to another account.'**
  String get authErrorIdentityInUse;

  /// No description provided for @authErrorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'This code is invalid or has expired.'**
  String get authErrorInvalidCode;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorLastIdentity.
  ///
  /// In en, this message translates to:
  /// **'You can\'t remove your only sign-in method.'**
  String get authErrorLastIdentity;

  /// No description provided for @authErrorNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync isn\'t configured on this build (see guide.md).'**
  String get authErrorNotConfigured;

  /// No description provided for @authErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check your connection and try again.'**
  String get authErrorOffline;

  /// No description provided for @authErrorProviderNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method isn\'t set up yet (see guide.md).'**
  String get authErrorProviderNotConfigured;

  /// No description provided for @authErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get authErrorRateLimited;

  /// No description provided for @authErrorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get authErrorSessionExpired;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorUnknown;

  /// No description provided for @authExportFirst.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get authExportFirst;

  /// No description provided for @authGuestAccount.
  ///
  /// In en, this message translates to:
  /// **'Guest account'**
  String get authGuestAccount;

  /// No description provided for @authGuestBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re using a guest account. Add an email so your data survives if you delete the app.'**
  String get authGuestBanner;

  /// No description provided for @authGuestBannerAction.
  ///
  /// In en, this message translates to:
  /// **'Secure my data'**
  String get authGuestBannerAction;

  /// No description provided for @authGuestHint.
  ///
  /// In en, this message translates to:
  /// **'Try Everslot right away and add an email later to keep your data.'**
  String get authGuestHint;

  /// No description provided for @authHomeZone.
  ///
  /// In en, this message translates to:
  /// **'Home time zone'**
  String get authHomeZone;

  /// No description provided for @authLegalNote.
  ///
  /// In en, this message translates to:
  /// **'By continuing you accept the Terms of Service and the Privacy Policy.'**
  String get authLegalNote;

  /// No description provided for @authLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get authLink;

  /// No description provided for @authLinked.
  ///
  /// In en, this message translates to:
  /// **'{provider} linked'**
  String authLinked(String provider);

  /// No description provided for @authLinkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Sign-in methods'**
  String get authLinkedAccounts;

  /// No description provided for @authLocalOnlyAccount.
  ///
  /// In en, this message translates to:
  /// **'Data stays on this device'**
  String get authLocalOnlyAccount;

  /// No description provided for @authLocalOnlyAccountBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re not signed in. Sign in to sync across devices — your data comes along.'**
  String get authLocalOnlyAccountBody;

  /// No description provided for @authMfaBody.
  ///
  /// In en, this message translates to:
  /// **'Ask for a code from an authenticator app when you sign in or delete your account.'**
  String get authMfaBody;

  /// No description provided for @authMfaDisable.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get authMfaDisable;

  /// No description provided for @authMfaEnabled.
  ///
  /// In en, this message translates to:
  /// **'Two-step verification is on.'**
  String get authMfaEnabled;

  /// No description provided for @authMfaEnroll.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get authMfaEnroll;

  /// No description provided for @authMfaEnrollBody.
  ///
  /// In en, this message translates to:
  /// **'Add this key to your authenticator app, then enter the 6-digit code it shows.'**
  String get authMfaEnrollBody;

  /// No description provided for @authMfaSecret.
  ///
  /// In en, this message translates to:
  /// **'Setup key'**
  String get authMfaSecret;

  /// No description provided for @authMfaTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-step verification'**
  String get authMfaTitle;

  /// No description provided for @authMfaVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your authenticator code'**
  String get authMfaVerifyTitle;

  /// No description provided for @authNotConfiguredBody.
  ///
  /// In en, this message translates to:
  /// **'This build isn\'t connected to a Supabase project yet (see guide.md). Everslot works fully on this device in the meantime.'**
  String get authNotConfiguredBody;

  /// No description provided for @authNotConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync isn\'t configured'**
  String get authNotConfiguredTitle;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get authProfileTitle;

  /// No description provided for @authProviderApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get authProviderApple;

  /// No description provided for @authProviderEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authProviderEmail;

  /// No description provided for @authProviderGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get authProviderGoogle;

  /// No description provided for @authReauthBody.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again to resume syncing — everything you did offline is kept.'**
  String get authReauthBody;

  /// No description provided for @authReauthTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get authReauthTitle;

  /// No description provided for @authRegionalSettings.
  ///
  /// In en, this message translates to:
  /// **'Regional settings'**
  String get authRegionalSettings;

  /// No description provided for @authResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResend;

  /// No description provided for @authResendIn.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Resend code in 1 second} other{Resend code in {seconds} seconds}}'**
  String authResendIn(int seconds);

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authSessionExpiredBanner.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Your changes are saved on this device and will sync once you sign in again.'**
  String get authSessionExpiredBanner;

  /// No description provided for @authSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get authSignInAgain;

  /// No description provided for @authSignInToSync.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync'**
  String get authSignInToSync;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authSignOutAnyway.
  ///
  /// In en, this message translates to:
  /// **'Sign out anyway'**
  String get authSignOutAnyway;

  /// No description provided for @authSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your data will be removed from this device. It stays safe in your account.'**
  String get authSignOutBody;

  /// No description provided for @authSignOutGuestBody.
  ///
  /// In en, this message translates to:
  /// **'This guest account only exists on this device. Signing out deletes it and all its data for good — add an email first to keep it.'**
  String get authSignOutGuestBody;

  /// No description provided for @authSignOutPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change hasn\'t synced yet and will be lost.} other{{count} changes haven\'t synced yet and will be lost.}} Export your data first, or sign out anyway.'**
  String authSignOutPendingBody(int count);

  /// No description provided for @authSignOutSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing your last changes…'**
  String get authSignOutSyncing;

  /// No description provided for @authSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get authSignOutTitle;

  /// No description provided for @authSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String authSignedInAs(String email);

  /// No description provided for @authSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get authSignedOut;

  /// No description provided for @authUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get authUnlink;

  /// No description provided for @authUnlinkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unlink {provider}?'**
  String authUnlinkConfirm(String provider);

  /// No description provided for @authUpdateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update Everslot to keep syncing. Your changes are kept on this device.'**
  String get authUpdateRequired;

  /// No description provided for @authUpgradeBody.
  ///
  /// In en, this message translates to:
  /// **'Add a sign-in method to your guest account. Your data stays exactly as it is.'**
  String get authUpgradeBody;

  /// No description provided for @authUpgradeDone.
  ///
  /// In en, this message translates to:
  /// **'Your account is secured.'**
  String get authUpgradeDone;

  /// No description provided for @authUpgradeEmail.
  ///
  /// In en, this message translates to:
  /// **'Add an email'**
  String get authUpgradeEmail;

  /// No description provided for @authUpgradeEmailInUseBody.
  ///
  /// In en, this message translates to:
  /// **'{email} already has an Everslot account. Use another email — or export your guest data, sign out, sign in to that account and import the file.'**
  String authUpgradeEmailInUseBody(String email);

  /// No description provided for @authUpgradeEmailInUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get authUpgradeEmailInUseTitle;

  /// No description provided for @authUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your data'**
  String get authUpgradeTitle;

  /// No description provided for @authUseLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Use on this device only'**
  String get authUseLocalOnly;

  /// No description provided for @authUseLocalOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'No account and no sync. Sign in later and your data comes along.'**
  String get authUseLocalOnlyHint;

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your plans, lists and habits in sync on all your devices.'**
  String get authWelcomeBody;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Everslot'**
  String get authWelcomeTitle;

  /// No description provided for @authZoneChangedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re now in {zone}. Fixed-time tasks keep their exact time and floating tasks follow you. Make {zone} your home time zone?'**
  String authZoneChangedBody(String zone);

  /// No description provided for @authZoneChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'New time zone'**
  String get authZoneChangedTitle;

  /// No description provided for @authZoneDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected on this device'**
  String get authZoneDetected;

  /// No description provided for @authZoneKeepHome.
  ///
  /// In en, this message translates to:
  /// **'Keep {zone}'**
  String authZoneKeepHome(String zone);

  /// No description provided for @authZoneMakeHome.
  ///
  /// In en, this message translates to:
  /// **'Make it home'**
  String get authZoneMakeHome;

  /// No description provided for @authZoneNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No time zone matches your search'**
  String get authZoneNoMatch;

  /// No description provided for @authZoneSearch.
  ///
  /// In en, this message translates to:
  /// **'Search time zones'**
  String get authZoneSearch;

  /// No description provided for @categoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get categoriesEmpty;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoryArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get categoryArchived;

  /// No description provided for @categoryClearAction.
  ///
  /// In en, this message translates to:
  /// **'Remove the category from them'**
  String get categoryClearAction;

  /// No description provided for @categoryCreateNamed.
  ///
  /// In en, this message translates to:
  /// **'Create category “{name}”'**
  String categoryCreateNamed(String name);

  /// No description provided for @categoryDefaultHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryDefaultHealth;

  /// No description provided for @categoryDefaultHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get categoryDefaultHome;

  /// No description provided for @categoryDefaultPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryDefaultPersonal;

  /// No description provided for @categoryDefaultSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get categoryDefaultSocial;

  /// No description provided for @categoryDefaultStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get categoryDefaultStudy;

  /// No description provided for @categoryDefaultWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryDefaultWork;

  /// No description provided for @categoryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Items in this category will keep existing without a category.'**
  String get categoryDeleteBody;

  /// No description provided for @categoryDeleteUsedBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item uses “{name}”.} other{{count} items use “{name}”.}} What should happen to them?'**
  String categoryDeleteUsedBody(int count, String name);

  /// No description provided for @categoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoryEdit;

  /// No description provided for @categoryErrorDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists.'**
  String get categoryErrorDuplicate;

  /// No description provided for @categoryErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 60 characters.'**
  String get categoryErrorInvalid;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoryName;

  /// No description provided for @categoryNew.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoryNew;

  /// No description provided for @categoryNone.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get categoryNone;

  /// No description provided for @categoryPick.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryPick;

  /// No description provided for @categoryReassignAction.
  ///
  /// In en, this message translates to:
  /// **'Move them to another category'**
  String get categoryReassignAction;

  /// No description provided for @categoryReassignTitle.
  ///
  /// In en, this message translates to:
  /// **'Move items to'**
  String get categoryReassignTitle;

  /// No description provided for @categoryReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get categoryReorderHint;

  /// No description provided for @categorySearch.
  ///
  /// In en, this message translates to:
  /// **'Search or create a category'**
  String get categorySearch;

  /// No description provided for @categoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Counts as unavailable time'**
  String get categoryUnavailable;

  /// No description provided for @categoryUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Excluded from capacity stats (e.g. sleep, time off).'**
  String get categoryUnavailableHint;

  /// No description provided for @categoryUsage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not used} =1{1 item} other{{count} items}}'**
  String categoryUsage(int count);

  /// No description provided for @chartsAnonymousItem.
  ///
  /// In en, this message translates to:
  /// **'Item {n}'**
  String chartsAnonymousItem(String n);

  /// No description provided for @chartsBytesGb.
  ///
  /// In en, this message translates to:
  /// **'{value} GB'**
  String chartsBytesGb(String value);

  /// No description provided for @chartsBytesKb.
  ///
  /// In en, this message translates to:
  /// **'{value} KB'**
  String chartsBytesKb(String value);

  /// No description provided for @chartsBytesMb.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String chartsBytesMb(String value);

  /// No description provided for @chartsColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get chartsColumnLabel;

  /// No description provided for @chartsCounterSemantics.
  ///
  /// In en, this message translates to:
  /// **'{days} days, {hours} hours, {minutes} minutes'**
  String chartsCounterSemantics(String days, String hours, String minutes);

  /// No description provided for @chartsCrosshair.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String chartsCrosshair(String label, String value);

  /// No description provided for @chartsDaysHours.
  ///
  /// In en, this message translates to:
  /// **'{days} d {hours} h'**
  String chartsDaysHours(String days, String hours);

  /// No description provided for @chartsDaysOnly.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String chartsDaysOnly(num count);

  /// No description provided for @chartsDeltaDown.
  ///
  /// In en, this message translates to:
  /// **'down {value}'**
  String chartsDeltaDown(String value);

  /// No description provided for @chartsDeltaFlat.
  ///
  /// In en, this message translates to:
  /// **'no change'**
  String get chartsDeltaFlat;

  /// No description provided for @chartsDeltaNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get chartsDeltaNew;

  /// No description provided for @chartsDeltaUp.
  ///
  /// In en, this message translates to:
  /// **'up {value}'**
  String chartsDeltaUp(String value);

  /// No description provided for @chartsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get chartsEmpty;

  /// No description provided for @chartsError.
  ///
  /// In en, this message translates to:
  /// **'This chart couldn’t be computed'**
  String get chartsError;

  /// No description provided for @chartsEstimate.
  ///
  /// In en, this message translates to:
  /// **'≈ {value}'**
  String chartsEstimate(String value);

  /// No description provided for @chartsExplain.
  ///
  /// In en, this message translates to:
  /// **'About this metric'**
  String get chartsExplain;

  /// No description provided for @chartsFrozen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 frozen} other{{count} frozen}}'**
  String chartsFrozen(num count);

  /// No description provided for @chartsGalleryDark.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get chartsGalleryDark;

  /// No description provided for @chartsGalleryRtl.
  ///
  /// In en, this message translates to:
  /// **'Right to left'**
  String get chartsGalleryRtl;

  /// No description provided for @chartsGalleryTextScale.
  ///
  /// In en, this message translates to:
  /// **'Large text'**
  String get chartsGalleryTextScale;

  /// No description provided for @chartsGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Chart gallery'**
  String get chartsGalleryTitle;

  /// No description provided for @chartsGalleryVision.
  ///
  /// In en, this message translates to:
  /// **'Color vision'**
  String get chartsGalleryVision;

  /// No description provided for @chartsHistogramCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get chartsHistogramCount;

  /// No description provided for @chartsHistogramDensity.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get chartsHistogramDensity;

  /// No description provided for @chartsHour.
  ///
  /// In en, this message translates to:
  /// **'{hour} h'**
  String chartsHour(String hour);

  /// No description provided for @chartsHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String chartsHoursMinutes(String hours, String minutes);

  /// No description provided for @chartsHoursOnly.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String chartsHoursOnly(String hours);

  /// No description provided for @chartsKilo.
  ///
  /// In en, this message translates to:
  /// **'{value} k'**
  String chartsKilo(String value);

  /// No description provided for @chartsKpiSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}: {value}. {delta}'**
  String chartsKpiSemantics(String title, String value, String delta);

  /// No description provided for @chartsLabelAbstinent.
  ///
  /// In en, this message translates to:
  /// **'Abstinent'**
  String get chartsLabelAbstinent;

  /// No description provided for @chartsLabelActual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get chartsLabelActual;

  /// No description provided for @chartsLabelAfterHours.
  ///
  /// In en, this message translates to:
  /// **'After hours'**
  String get chartsLabelAfterHours;

  /// No description provided for @chartsLabelAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get chartsLabelAgenda;

  /// No description provided for @chartsLabelArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get chartsLabelArchived;

  /// No description provided for @chartsLabelArrivals.
  ///
  /// In en, this message translates to:
  /// **'Arrivals'**
  String get chartsLabelArrivals;

  /// No description provided for @chartsLabelAttempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt'**
  String get chartsLabelAttempt;

  /// No description provided for @chartsLabelAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get chartsLabelAttention;

  /// No description provided for @chartsLabelBaseline.
  ///
  /// In en, this message translates to:
  /// **'Baseline'**
  String get chartsLabelBaseline;

  /// No description provided for @chartsLabelBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get chartsLabelBest;

  /// No description provided for @chartsLabelBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get chartsLabelBlocked;

  /// No description provided for @chartsLabelCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get chartsLabelCancelled;

  /// No description provided for @chartsLabelCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get chartsLabelCapacity;

  /// No description provided for @chartsLabelCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Check-ins'**
  String get chartsLabelCheckIns;

  /// No description provided for @chartsLabelCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get chartsLabelCompleted;

  /// No description provided for @chartsLabelCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get chartsLabelCount;

  /// No description provided for @chartsLabelCravings.
  ///
  /// In en, this message translates to:
  /// **'Cravings'**
  String get chartsLabelCravings;

  /// No description provided for @chartsLabelCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get chartsLabelCreated;

  /// No description provided for @chartsLabelCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get chartsLabelCurrent;

  /// No description provided for @chartsLabelDeepWork.
  ///
  /// In en, this message translates to:
  /// **'Deep work'**
  String get chartsLabelDeepWork;

  /// No description provided for @chartsLabelDepartures.
  ///
  /// In en, this message translates to:
  /// **'Departures'**
  String get chartsLabelDepartures;

  /// No description provided for @chartsLabelDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get chartsLabelDone;

  /// No description provided for @chartsLabelDoneLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get chartsLabelDoneLate;

  /// No description provided for @chartsLabelDoneOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get chartsLabelDoneOnTime;

  /// No description provided for @chartsLabelEarly.
  ///
  /// In en, this message translates to:
  /// **'Early'**
  String get chartsLabelEarly;

  /// No description provided for @chartsLabelEvent.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get chartsLabelEvent;

  /// No description provided for @chartsLabelExcused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get chartsLabelExcused;

  /// No description provided for @chartsLabelFailed.
  ///
  /// In en, this message translates to:
  /// **'Not done'**
  String get chartsLabelFailed;

  /// No description provided for @chartsLabelFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get chartsLabelFiles;

  /// No description provided for @chartsLabelFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get chartsLabelFocus;

  /// No description provided for @chartsLabelFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get chartsLabelFree;

  /// No description provided for @chartsLabelFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get chartsLabelFrozen;

  /// No description provided for @chartsLabelFuture.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get chartsLabelFuture;

  /// No description provided for @chartsLabelGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get chartsLabelGoal;

  /// No description provided for @chartsLabelHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get chartsLabelHabits;

  /// No description provided for @chartsLabelHighPriority.
  ///
  /// In en, this message translates to:
  /// **'High priority'**
  String get chartsLabelHighPriority;

  /// No description provided for @chartsLabelIdeal.
  ///
  /// In en, this message translates to:
  /// **'Ideal'**
  String get chartsLabelIdeal;

  /// No description provided for @chartsLabelImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get chartsLabelImages;

  /// No description provided for @chartsLabelInProgress.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get chartsLabelInProgress;

  /// No description provided for @chartsLabelIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get chartsLabelIntensity;

  /// No description provided for @chartsLabelItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get chartsLabelItems;

  /// No description provided for @chartsLabelLapse.
  ///
  /// In en, this message translates to:
  /// **'Slip'**
  String get chartsLabelLapse;

  /// No description provided for @chartsLabelLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get chartsLabelLate;

  /// No description provided for @chartsLabelLifeRegained.
  ///
  /// In en, this message translates to:
  /// **'Life regained'**
  String get chartsLabelLifeRegained;

  /// No description provided for @chartsLabelLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get chartsLabelLimit;

  /// No description provided for @chartsLabelLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get chartsLabelLists;

  /// No description provided for @chartsLabelLowPriority.
  ///
  /// In en, this message translates to:
  /// **'Low priority'**
  String get chartsLabelLowPriority;

  /// No description provided for @chartsLabelMaxIntensity.
  ///
  /// In en, this message translates to:
  /// **'Peak intensity'**
  String get chartsLabelMaxIntensity;

  /// No description provided for @chartsLabelMean.
  ///
  /// In en, this message translates to:
  /// **'Mean'**
  String get chartsLabelMean;

  /// No description provided for @chartsLabelMeanIntensity.
  ///
  /// In en, this message translates to:
  /// **'Average intensity'**
  String get chartsLabelMeanIntensity;

  /// No description provided for @chartsLabelMeanUse.
  ///
  /// In en, this message translates to:
  /// **'Average use'**
  String get chartsLabelMeanUse;

  /// No description provided for @chartsLabelMedian.
  ///
  /// In en, this message translates to:
  /// **'Median'**
  String get chartsLabelMedian;

  /// No description provided for @chartsLabelMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get chartsLabelMissed;

  /// No description provided for @chartsLabelMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get chartsLabelMoney;

  /// No description provided for @chartsLabelMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get chartsLabelMonth;

  /// No description provided for @chartsLabelMoods.
  ///
  /// In en, this message translates to:
  /// **'Moods'**
  String get chartsLabelMoods;

  /// No description provided for @chartsLabelMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get chartsLabelMoved;

  /// No description provided for @chartsLabelMovedIn.
  ///
  /// In en, this message translates to:
  /// **'Moved in'**
  String get chartsLabelMovedIn;

  /// No description provided for @chartsLabelMovedOut.
  ///
  /// In en, this message translates to:
  /// **'Moved out'**
  String get chartsLabelMovedOut;

  /// No description provided for @chartsLabelNet.
  ///
  /// In en, this message translates to:
  /// **'Net flow'**
  String get chartsLabelNet;

  /// No description provided for @chartsLabelNextUp.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get chartsLabelNextUp;

  /// No description provided for @chartsLabelNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get chartsLabelNo;

  /// No description provided for @chartsLabelNotDue.
  ///
  /// In en, this message translates to:
  /// **'Not due'**
  String get chartsLabelNotDue;

  /// No description provided for @chartsLabelNotTracked.
  ///
  /// In en, this message translates to:
  /// **'Not tracked'**
  String get chartsLabelNotTracked;

  /// No description provided for @chartsLabelOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get chartsLabelOnTime;

  /// No description provided for @chartsLabelOneOff.
  ///
  /// In en, this message translates to:
  /// **'One-off'**
  String get chartsLabelOneOff;

  /// No description provided for @chartsLabelOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get chartsLabelOngoing;

  /// No description provided for @chartsLabelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chartsLabelOther;

  /// No description provided for @chartsLabelOver.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get chartsLabelOver;

  /// No description provided for @chartsLabelOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Over limit'**
  String get chartsLabelOverLimit;

  /// No description provided for @chartsLabelOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get chartsLabelOverdue;

  /// No description provided for @chartsLabelOverdue1.
  ///
  /// In en, this message translates to:
  /// **'1–6 days'**
  String get chartsLabelOverdue1;

  /// No description provided for @chartsLabelOverdue14.
  ///
  /// In en, this message translates to:
  /// **'14–29 days'**
  String get chartsLabelOverdue14;

  /// No description provided for @chartsLabelOverdue30.
  ///
  /// In en, this message translates to:
  /// **'30+ days'**
  String get chartsLabelOverdue30;

  /// No description provided for @chartsLabelOverdue7.
  ///
  /// In en, this message translates to:
  /// **'7–13 days'**
  String get chartsLabelOverdue7;

  /// No description provided for @chartsLabelOverdueToday.
  ///
  /// In en, this message translates to:
  /// **'< 1 day'**
  String get chartsLabelOverdueToday;

  /// No description provided for @chartsLabelOverlap.
  ///
  /// In en, this message translates to:
  /// **'Overlap'**
  String get chartsLabelOverlap;

  /// No description provided for @chartsLabelP50.
  ///
  /// In en, this message translates to:
  /// **'P50'**
  String get chartsLabelP50;

  /// No description provided for @chartsLabelP70.
  ///
  /// In en, this message translates to:
  /// **'P70'**
  String get chartsLabelP70;

  /// No description provided for @chartsLabelP85.
  ///
  /// In en, this message translates to:
  /// **'P85'**
  String get chartsLabelP85;

  /// No description provided for @chartsLabelP95.
  ///
  /// In en, this message translates to:
  /// **'P95'**
  String get chartsLabelP95;

  /// No description provided for @chartsLabelPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get chartsLabelPace;

  /// No description provided for @chartsLabelPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get chartsLabelPartial;

  /// No description provided for @chartsLabelPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get chartsLabelPaused;

  /// No description provided for @chartsLabelPdfs.
  ///
  /// In en, this message translates to:
  /// **'PDFs'**
  String get chartsLabelPdfs;

  /// No description provided for @chartsLabelPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get chartsLabelPending;

  /// No description provided for @chartsLabelPerDay.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get chartsLabelPerDay;

  /// No description provided for @chartsLabelPerfectDay.
  ///
  /// In en, this message translates to:
  /// **'Perfect day'**
  String get chartsLabelPerfectDay;

  /// No description provided for @chartsLabelPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get chartsLabelPlaces;

  /// No description provided for @chartsLabelPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get chartsLabelPlanned;

  /// No description provided for @chartsLabelPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get chartsLabelPrevious;

  /// No description provided for @chartsLabelProjection.
  ///
  /// In en, this message translates to:
  /// **'Projection'**
  String get chartsLabelProjection;

  /// No description provided for @chartsLabelProjection1m.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get chartsLabelProjection1m;

  /// No description provided for @chartsLabelProjection1y.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get chartsLabelProjection1y;

  /// No description provided for @chartsLabelProjection5y.
  ///
  /// In en, this message translates to:
  /// **'In 5 years'**
  String get chartsLabelProjection5y;

  /// No description provided for @chartsLabelQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get chartsLabelQuit;

  /// No description provided for @chartsLabelRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get chartsLabelRate;

  /// No description provided for @chartsLabelRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get chartsLabelRecurring;

  /// No description provided for @chartsLabelReduction.
  ///
  /// In en, this message translates to:
  /// **'Reduction'**
  String get chartsLabelReduction;

  /// No description provided for @chartsLabelRelapse.
  ///
  /// In en, this message translates to:
  /// **'Relapse'**
  String get chartsLabelRelapse;

  /// No description provided for @chartsLabelRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get chartsLabelRemaining;

  /// No description provided for @chartsLabelRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get chartsLabelRemoved;

  /// No description provided for @chartsLabelReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get chartsLabelReopened;

  /// No description provided for @chartsLabelRollingMean.
  ///
  /// In en, this message translates to:
  /// **'Rolling mean'**
  String get chartsLabelRollingMean;

  /// No description provided for @chartsLabelSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get chartsLabelSaved;

  /// No description provided for @chartsLabelScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get chartsLabelScope;

  /// No description provided for @chartsLabelScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get chartsLabelScore;

  /// No description provided for @chartsLabelSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get chartsLabelSkipped;

  /// No description provided for @chartsLabelSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get chartsLabelSpent;

  /// No description provided for @chartsLabelStale.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get chartsLabelStale;

  /// No description provided for @chartsLabelStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get chartsLabelStreak;

  /// No description provided for @chartsLabelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get chartsLabelSuccess;

  /// No description provided for @chartsLabelTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get chartsLabelTarget;

  /// No description provided for @chartsLabelTask.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get chartsLabelTask;

  /// No description provided for @chartsLabelTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get chartsLabelTasks;

  /// No description provided for @chartsLabelTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get chartsLabelTemplates;

  /// No description provided for @chartsLabelTimeNotSpent.
  ///
  /// In en, this message translates to:
  /// **'Time not spent'**
  String get chartsLabelTimeNotSpent;

  /// No description provided for @chartsLabelTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get chartsLabelTodo;

  /// No description provided for @chartsLabelTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get chartsLabelTotal;

  /// No description provided for @chartsLabelTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get chartsLabelTrend;

  /// No description provided for @chartsLabelTriggers.
  ///
  /// In en, this message translates to:
  /// **'Triggers'**
  String get chartsLabelTriggers;

  /// No description provided for @chartsLabelUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get chartsLabelUncategorized;

  /// No description provided for @chartsLabelUnder.
  ///
  /// In en, this message translates to:
  /// **'Under'**
  String get chartsLabelUnder;

  /// No description provided for @chartsLabelUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get chartsLabelUnits;

  /// No description provided for @chartsLabelUnplanned.
  ///
  /// In en, this message translates to:
  /// **'Unplanned'**
  String get chartsLabelUnplanned;

  /// No description provided for @chartsLabelUnspecified.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get chartsLabelUnspecified;

  /// No description provided for @chartsLabelUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get chartsLabelUsed;

  /// No description provided for @chartsLabelVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get chartsLabelVolume;

  /// No description provided for @chartsLabelWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get chartsLabelWaiting;

  /// No description provided for @chartsLabelWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get chartsLabelWeek;

  /// No description provided for @chartsLabelWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get chartsLabelWeekend;

  /// No description provided for @chartsLabelWhenLabel.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get chartsLabelWhenLabel;

  /// No description provided for @chartsLabelWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get chartsLabelWins;

  /// No description provided for @chartsLabelWip.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get chartsLabelWip;

  /// No description provided for @chartsLabelWithinLimit.
  ///
  /// In en, this message translates to:
  /// **'Within limit'**
  String get chartsLabelWithinLimit;

  /// No description provided for @chartsLabelWithinLimitDays.
  ///
  /// In en, this message translates to:
  /// **'Days within limit'**
  String get chartsLabelWithinLimitDays;

  /// No description provided for @chartsLabelYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get chartsLabelYear;

  /// No description provided for @chartsLabelYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get chartsLabelYes;

  /// No description provided for @chartsLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get chartsLegend;

  /// No description provided for @chartsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get chartsLoading;

  /// No description provided for @chartsMedianAt.
  ///
  /// In en, this message translates to:
  /// **'Median {value}'**
  String chartsMedianAt(String value);

  /// No description provided for @chartsMedianNotReached.
  ///
  /// In en, this message translates to:
  /// **'Median not reached'**
  String get chartsMedianNotReached;

  /// No description provided for @chartsMega.
  ///
  /// In en, this message translates to:
  /// **'{value} M'**
  String chartsMega(String value);

  /// No description provided for @chartsMilestoneEta.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String chartsMilestoneEta(String time);

  /// No description provided for @chartsMilestoneInWindow.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get chartsMilestoneInWindow;

  /// No description provided for @chartsMilestoneNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get chartsMilestoneNext;

  /// No description provided for @chartsMilestoneReached.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get chartsMilestoneReached;

  /// No description provided for @chartsMilestoneRestarted.
  ///
  /// In en, this message translates to:
  /// **'The clock restarted after a slip — every day you already did still counts.'**
  String get chartsMilestoneRestarted;

  /// No description provided for @chartsMilestoneSources.
  ///
  /// In en, this message translates to:
  /// **'Sources: {sources}'**
  String chartsMilestoneSources(String sources);

  /// No description provided for @chartsMinutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String chartsMinutesOnly(String minutes);

  /// No description provided for @chartsNeedsMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Needs 1 more data point} other{Needs {count} more data points}}'**
  String chartsNeedsMore(num count);

  /// No description provided for @chartsNoConsistentTime.
  ///
  /// In en, this message translates to:
  /// **'No consistent time'**
  String get chartsNoConsistentTime;

  /// No description provided for @chartsNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get chartsNotApplicable;

  /// No description provided for @chartsOrdinalAttempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt {n}'**
  String chartsOrdinalAttempt(String n);

  /// No description provided for @chartsOrdinalDepth.
  ///
  /// In en, this message translates to:
  /// **'Depth {n}'**
  String chartsOrdinalDepth(String n);

  /// No description provided for @chartsOrdinalLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String chartsOrdinalLevel(String n);

  /// No description provided for @chartsOrdinalMonth.
  ///
  /// In en, this message translates to:
  /// **'Month {n}'**
  String chartsOrdinalMonth(String n);

  /// No description provided for @chartsOrdinalPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority {n}'**
  String chartsOrdinalPriority(String n);

  /// No description provided for @chartsOrdinalRun.
  ///
  /// In en, this message translates to:
  /// **'Run {n}'**
  String chartsOrdinalRun(String n);

  /// No description provided for @chartsOrdinalWeek.
  ///
  /// In en, this message translates to:
  /// **'Week {n}'**
  String chartsOrdinalWeek(String n);

  /// No description provided for @chartsOrdinalYear.
  ///
  /// In en, this message translates to:
  /// **'Year {n}'**
  String chartsOrdinalYear(String n);

  /// No description provided for @chartsOver.
  ///
  /// In en, this message translates to:
  /// **'+{value}'**
  String chartsOver(String value);

  /// No description provided for @chartsPerDay.
  ///
  /// In en, this message translates to:
  /// **'{value}/day'**
  String chartsPerDay(String value);

  /// No description provided for @chartsPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{value}/week'**
  String chartsPerWeek(String value);

  /// No description provided for @chartsPlusMinus.
  ///
  /// In en, this message translates to:
  /// **'± {value}'**
  String chartsPlusMinus(String value);

  /// No description provided for @chartsPopulationEstimate.
  ///
  /// In en, this message translates to:
  /// **'Population estimate'**
  String get chartsPopulationEstimate;

  /// No description provided for @chartsPp.
  ///
  /// In en, this message translates to:
  /// **'{value} pp'**
  String chartsPp(String value);

  /// No description provided for @chartsPpSpoken.
  ///
  /// In en, this message translates to:
  /// **'{value} percentage points'**
  String chartsPpSpoken(String value);

  /// No description provided for @chartsPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous {value}'**
  String chartsPrevious(String value);

  /// No description provided for @chartsProbability.
  ///
  /// In en, this message translates to:
  /// **'{value} chance'**
  String chartsProbability(String value);

  /// No description provided for @chartsRange.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to}'**
  String chartsRange(String from, String to);

  /// No description provided for @chartsRatio.
  ///
  /// In en, this message translates to:
  /// **'{value}×'**
  String chartsRatio(String value);

  /// No description provided for @chartsSecondsOnly.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String chartsSecondsOnly(String seconds);

  /// No description provided for @chartsSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get chartsSelected;

  /// No description provided for @chartsSeriesToggle.
  ///
  /// In en, this message translates to:
  /// **'Show or hide {series}'**
  String chartsSeriesToggle(String series);

  /// No description provided for @chartsShare.
  ///
  /// In en, this message translates to:
  /// **'Share chart'**
  String get chartsShare;

  /// No description provided for @chartsShareHideNames.
  ///
  /// In en, this message translates to:
  /// **'Hide names'**
  String get chartsShareHideNames;

  /// No description provided for @chartsShareMark.
  ///
  /// In en, this message translates to:
  /// **'Made with Everslot'**
  String get chartsShareMark;

  /// No description provided for @chartsStreakBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get chartsStreakBest;

  /// No description provided for @chartsStreakCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get chartsStreakCurrent;

  /// No description provided for @chartsSummaryBars.
  ///
  /// In en, this message translates to:
  /// **'{title}: {count} bars, highest {label} with {value}.'**
  String chartsSummaryBars(
    String title,
    String count,
    String label,
    String value,
  );

  /// No description provided for @chartsSummaryCalendar.
  ///
  /// In en, this message translates to:
  /// **'{title}: {count} days shown.'**
  String chartsSummaryCalendar(String title, String count);

  /// No description provided for @chartsSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{title}, {range}: from {first} to {last}. {trend}'**
  String chartsSummaryLine(
    String title,
    String range,
    String first,
    String last,
    String trend,
  );

  /// No description provided for @chartsSummaryList.
  ///
  /// In en, this message translates to:
  /// **'{title}: {count} entries.'**
  String chartsSummaryList(String title, String count);

  /// No description provided for @chartsSummaryMilestones.
  ///
  /// In en, this message translates to:
  /// **'{title}: {done} of {total} reached.'**
  String chartsSummaryMilestones(String title, String done, String total);

  /// No description provided for @chartsSummaryMinMax.
  ///
  /// In en, this message translates to:
  /// **'Lowest {min}, highest {max}.'**
  String chartsSummaryMinMax(String min, String max);

  /// No description provided for @chartsSummaryPunchCard.
  ///
  /// In en, this message translates to:
  /// **'{title}: busiest {weekday} at {hour}.'**
  String chartsSummaryPunchCard(String title, String weekday, String hour);

  /// No description provided for @chartsSummaryShare.
  ///
  /// In en, this message translates to:
  /// **'{title}: largest part {label}, {share}.'**
  String chartsSummaryShare(String title, String label, String share);

  /// No description provided for @chartsSummaryStreaks.
  ///
  /// In en, this message translates to:
  /// **'{title}: longest streak {length}.'**
  String chartsSummaryStreaks(String title, String length);

  /// No description provided for @chartsSummaryValue.
  ///
  /// In en, this message translates to:
  /// **'{title}: {value}.'**
  String chartsSummaryValue(String title, String value);

  /// No description provided for @chartsTableSort.
  ///
  /// In en, this message translates to:
  /// **'Sort by {column}'**
  String chartsTableSort(String column);

  /// No description provided for @chartsTapForDetails.
  ///
  /// In en, this message translates to:
  /// **'Double tap for details'**
  String get chartsTapForDetails;

  /// No description provided for @chartsTarget.
  ///
  /// In en, this message translates to:
  /// **'Target {value}'**
  String chartsTarget(String value);

  /// No description provided for @chartsTooltip.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String chartsTooltip(String label, String value);

  /// No description provided for @chartsTrendFalling.
  ///
  /// In en, this message translates to:
  /// **'Falling {slope} per week.'**
  String chartsTrendFalling(String slope);

  /// No description provided for @chartsTrendRising.
  ///
  /// In en, this message translates to:
  /// **'Rising {slope} per week.'**
  String chartsTrendRising(String slope);

  /// No description provided for @chartsTrendStable.
  ///
  /// In en, this message translates to:
  /// **'No clear trend.'**
  String get chartsTrendStable;

  /// No description provided for @chartsViewAsChart.
  ///
  /// In en, this message translates to:
  /// **'View as chart'**
  String get chartsViewAsChart;

  /// No description provided for @chartsViewAsTable.
  ///
  /// In en, this message translates to:
  /// **'View as table'**
  String get chartsViewAsTable;

  /// No description provided for @chartsVisionDeuteranopia.
  ///
  /// In en, this message translates to:
  /// **'Deuteranopia'**
  String get chartsVisionDeuteranopia;

  /// No description provided for @chartsVisionNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get chartsVisionNormal;

  /// No description provided for @chartsVisionProtanopia.
  ///
  /// In en, this message translates to:
  /// **'Protanopia'**
  String get chartsVisionProtanopia;

  /// No description provided for @chartsVisionTritanopia.
  ///
  /// In en, this message translates to:
  /// **'Tritanopia'**
  String get chartsVisionTritanopia;

  /// No description provided for @chartsVsPrevious.
  ///
  /// In en, this message translates to:
  /// **'vs previous period'**
  String get chartsVsPrevious;

  /// No description provided for @checklistAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get checklistAddItem;

  /// No description provided for @checklistAddSubItem.
  ///
  /// In en, this message translates to:
  /// **'Add sub-item'**
  String get checklistAddSubItem;

  /// No description provided for @checklistAllAttachments.
  ///
  /// In en, this message translates to:
  /// **'All attachments'**
  String get checklistAllAttachments;

  /// No description provided for @checklistAllLists.
  ///
  /// In en, this message translates to:
  /// **'All lists'**
  String get checklistAllLists;

  /// No description provided for @checklistAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get checklistAttach;

  /// No description provided for @checklistBelowBadges.
  ///
  /// In en, this message translates to:
  /// **'{blocked} blocked · {waiting} waiting below'**
  String checklistBelowBadges(int blocked, int waiting);

  /// No description provided for @checklistBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get checklistBodyHint;

  /// No description provided for @checklistCarrying.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moving 1 item} other{Moving {count} items}}'**
  String checklistCarrying(int count);

  /// No description provided for @checklistCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get checklistCollapse;

  /// No description provided for @checklistCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get checklistCollapseAll;

  /// No description provided for @checklistCollapsedState.
  ///
  /// In en, this message translates to:
  /// **'collapsed'**
  String get checklistCollapsedState;

  /// No description provided for @checklistCompleted.
  ///
  /// In en, this message translates to:
  /// **'List completed!'**
  String get checklistCompleted;

  /// No description provided for @checklistCompletedArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get checklistCompletedArchive;

  /// No description provided for @checklistCompletedKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get checklistCompletedKeep;

  /// No description provided for @checklistCompletedReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get checklistCompletedReset;

  /// No description provided for @checklistCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get checklistCopied;

  /// No description provided for @checklistCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get checklistCopy;

  /// No description provided for @checklistCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy as text'**
  String get checklistCopyText;

  /// No description provided for @checklistCover.
  ///
  /// In en, this message translates to:
  /// **'Cover image…'**
  String get checklistCover;

  /// No description provided for @checklistCoverAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic (first image)'**
  String get checklistCoverAuto;

  /// No description provided for @checklistCoverNoImages.
  ///
  /// In en, this message translates to:
  /// **'Add an image to the list or its items first'**
  String get checklistCoverNoImages;

  /// No description provided for @checklistCoverUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cover updated'**
  String get checklistCoverUpdated;

  /// No description provided for @checklistCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get checklistCut;

  /// No description provided for @checklistDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get checklistDelete;

  /// No description provided for @checklistDeleteCompleted.
  ///
  /// In en, this message translates to:
  /// **'Delete completed items'**
  String get checklistDeleteCompleted;

  /// No description provided for @checklistDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get checklistDeleteItem;

  /// No description provided for @checklistDepthBadge.
  ///
  /// In en, this message translates to:
  /// **'L{level}'**
  String checklistDepthBadge(int level);

  /// No description provided for @checklistDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get checklistDetails;

  /// No description provided for @checklistDoneThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 done this week} other{{count} done this week}}'**
  String checklistDoneThisWeek(int count);

  /// No description provided for @checklistDragHandle.
  ///
  /// In en, this message translates to:
  /// **'Drag to move'**
  String get checklistDragHandle;

  /// No description provided for @checklistDue.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get checklistDue;

  /// No description provided for @checklistDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate list'**
  String get checklistDuplicate;

  /// No description provided for @checklistDuplicateItem.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get checklistDuplicateItem;

  /// No description provided for @checklistDurationDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day} other{{n} days}}'**
  String checklistDurationDays(int n);

  /// No description provided for @checklistDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hour} other{{n} hours}}'**
  String checklistDurationHours(int n);

  /// No description provided for @checklistDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 minute} other{{n} minutes}}'**
  String checklistDurationMinutes(int n);

  /// No description provided for @checklistEmptyFocus.
  ///
  /// In en, this message translates to:
  /// **'No sub-items yet'**
  String get checklistEmptyFocus;

  /// No description provided for @checklistExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get checklistExpand;

  /// No description provided for @checklistExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get checklistExpandAll;

  /// No description provided for @checklistExpandToLevel.
  ///
  /// In en, this message translates to:
  /// **'Expand to level {level}'**
  String checklistExpandToLevel(int level);

  /// No description provided for @checklistExpandToLevelMenu.
  ///
  /// In en, this message translates to:
  /// **'Expand to level…'**
  String get checklistExpandToLevelMenu;

  /// No description provided for @checklistFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get checklistFilterAll;

  /// No description provided for @checklistFilterDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get checklistFilterDueSoon;

  /// No description provided for @checklistFilterHasAttachments.
  ///
  /// In en, this message translates to:
  /// **'Has attachments'**
  String get checklistFilterHasAttachments;

  /// No description provided for @checklistFilterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get checklistFilterOpen;

  /// No description provided for @checklistFilterText.
  ///
  /// In en, this message translates to:
  /// **'Search in list'**
  String get checklistFilterText;

  /// No description provided for @checklistFiltered.
  ///
  /// In en, this message translates to:
  /// **'Filtered view'**
  String get checklistFiltered;

  /// No description provided for @checklistFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get checklistFocus;

  /// No description provided for @checklistHasReminders.
  ///
  /// In en, this message translates to:
  /// **'Has reminders'**
  String get checklistHasReminders;

  /// No description provided for @checklistHideCheckboxes.
  ///
  /// In en, this message translates to:
  /// **'Hide checkboxes'**
  String get checklistHideCheckboxes;

  /// No description provided for @checklistHideCompleted.
  ///
  /// In en, this message translates to:
  /// **'Hide completed'**
  String get checklistHideCompleted;

  /// No description provided for @checklistHideKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Hide keyboard'**
  String get checklistHideKeyboard;

  /// No description provided for @checklistImport.
  ///
  /// In en, this message translates to:
  /// **'Import items…'**
  String get checklistImport;

  /// No description provided for @checklistInTrash.
  ///
  /// In en, this message translates to:
  /// **'This list is in the trash'**
  String get checklistInTrash;

  /// No description provided for @checklistIndent.
  ///
  /// In en, this message translates to:
  /// **'Indent'**
  String get checklistIndent;

  /// No description provided for @checklistInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get checklistInsights;

  /// No description provided for @checklistItemHint.
  ///
  /// In en, this message translates to:
  /// **'List item'**
  String get checklistItemHint;

  /// No description provided for @checklistItemsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item deleted} other{{count} items deleted}}'**
  String checklistItemsDeleted(int count);

  /// No description provided for @checklistItemsDuplicated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item duplicated} other{{count} items duplicated}}'**
  String checklistItemsDuplicated(int count);

  /// No description provided for @checklistItemsMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get checklistItemsMoved;

  /// No description provided for @checklistLabelName.
  ///
  /// In en, this message translates to:
  /// **'Label name'**
  String get checklistLabelName;

  /// No description provided for @checklistLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get checklistLabels;

  /// No description provided for @checklistLineBreak.
  ///
  /// In en, this message translates to:
  /// **'Line break'**
  String get checklistLineBreak;

  /// No description provided for @checklistLinkTask.
  ///
  /// In en, this message translates to:
  /// **'Link to existing task…'**
  String get checklistLinkTask;

  /// No description provided for @checklistLinkTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Link a task'**
  String get checklistLinkTaskTitle;

  /// No description provided for @checklistLinkedTask.
  ///
  /// In en, this message translates to:
  /// **'Linked task'**
  String get checklistLinkedTask;

  /// No description provided for @checklistLinkedTaskSemantics.
  ///
  /// In en, this message translates to:
  /// **'Linked task {task}'**
  String checklistLinkedTaskSemantics(String task);

  /// No description provided for @checklistMdBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get checklistMdBold;

  /// No description provided for @checklistMdBullet.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get checklistMdBullet;

  /// No description provided for @checklistMdCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get checklistMdCode;

  /// No description provided for @checklistMdHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get checklistMdHeading;

  /// No description provided for @checklistMdItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get checklistMdItalic;

  /// No description provided for @checklistMdLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get checklistMdLink;

  /// No description provided for @checklistMdStrike.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get checklistMdStrike;

  /// No description provided for @checklistModeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get checklistModeEdit;

  /// No description provided for @checklistModePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get checklistModePreview;

  /// No description provided for @checklistMoveConflict.
  ///
  /// In en, this message translates to:
  /// **'A move conflicted with a change on another device and was undone.'**
  String get checklistMoveConflict;

  /// No description provided for @checklistMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get checklistMoveDown;

  /// No description provided for @checklistMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get checklistMoveTo;

  /// No description provided for @checklistMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get checklistMoveUp;

  /// No description provided for @checklistNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New label'**
  String get checklistNewLabel;

  /// No description provided for @checklistNextOpen.
  ///
  /// In en, this message translates to:
  /// **'Next open item'**
  String get checklistNextOpen;

  /// No description provided for @checklistNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get checklistNoItems;

  /// No description provided for @checklistNoLabels.
  ///
  /// In en, this message translates to:
  /// **'No labels yet'**
  String get checklistNoLabels;

  /// No description provided for @checklistNoOtherLists.
  ///
  /// In en, this message translates to:
  /// **'No other list to show'**
  String get checklistNoOtherLists;

  /// No description provided for @checklistNoTasksToLink.
  ///
  /// In en, this message translates to:
  /// **'No tasks to link yet'**
  String get checklistNoTasksToLink;

  /// No description provided for @checklistNotFound.
  ///
  /// In en, this message translates to:
  /// **'This list doesn\'t exist'**
  String get checklistNotFound;

  /// No description provided for @checklistNotifItemGone.
  ///
  /// In en, this message translates to:
  /// **'This item no longer exists'**
  String get checklistNotifItemGone;

  /// No description provided for @checklistOpenSideBySide.
  ///
  /// In en, this message translates to:
  /// **'Open side by side…'**
  String get checklistOpenSideBySide;

  /// No description provided for @checklistOpenTrash.
  ///
  /// In en, this message translates to:
  /// **'Open trash'**
  String get checklistOpenTrash;

  /// No description provided for @checklistOutdent.
  ///
  /// In en, this message translates to:
  /// **'Outdent'**
  String get checklistOutdent;

  /// No description provided for @checklistPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get checklistPaste;

  /// No description provided for @checklistPasteHere.
  ///
  /// In en, this message translates to:
  /// **'Paste here'**
  String get checklistPasteHere;

  /// No description provided for @checklistPendingUploads.
  ///
  /// In en, this message translates to:
  /// **'Uploads pending'**
  String get checklistPendingUploads;

  /// No description provided for @checklistPickSecondList.
  ///
  /// In en, this message translates to:
  /// **'Show next to this list'**
  String get checklistPickSecondList;

  /// No description provided for @checklistProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String checklistProgress(int done, int total);

  /// No description provided for @checklistPromote.
  ///
  /// In en, this message translates to:
  /// **'Promote to list'**
  String get checklistPromote;

  /// No description provided for @checklistPromoted.
  ///
  /// In en, this message translates to:
  /// **'Created a new list'**
  String get checklistPromoted;

  /// No description provided for @checklistRecovered.
  ///
  /// In en, this message translates to:
  /// **'Recovered'**
  String get checklistRecovered;

  /// No description provided for @checklistRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat…'**
  String get checklistRepeat;

  /// No description provided for @checklistResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Every item goes back to to-do and reason notes are cleared.'**
  String get checklistResetConfirm;

  /// No description provided for @checklistResetDone.
  ///
  /// In en, this message translates to:
  /// **'List reset'**
  String get checklistResetDone;

  /// No description provided for @checklistResetNow.
  ///
  /// In en, this message translates to:
  /// **'Reset now'**
  String get checklistResetNow;

  /// No description provided for @checklistResetStatuses.
  ///
  /// In en, this message translates to:
  /// **'Reset all statuses'**
  String get checklistResetStatuses;

  /// No description provided for @checklistResetView.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get checklistResetView;

  /// No description provided for @checklistRowSemantics.
  ///
  /// In en, this message translates to:
  /// **'{text}, level {level}, item {index} of {count}'**
  String checklistRowSemantics(String text, int level, int index, int count);

  /// No description provided for @checklistSaveAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as template'**
  String get checklistSaveAsTemplate;

  /// No description provided for @checklistScheduleTask.
  ///
  /// In en, this message translates to:
  /// **'Schedule as task'**
  String get checklistScheduleTask;

  /// No description provided for @checklistSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get checklistSelect;

  /// No description provided for @checklistSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get checklistSelectAll;

  /// No description provided for @checklistSelectSubtree.
  ///
  /// In en, this message translates to:
  /// **'Select sub-items'**
  String get checklistSelectSubtree;

  /// No description provided for @checklistSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String checklistSelected(int count);

  /// No description provided for @checklistSettings.
  ///
  /// In en, this message translates to:
  /// **'List settings'**
  String get checklistSettings;

  /// No description provided for @checklistShare.
  ///
  /// In en, this message translates to:
  /// **'Share / export'**
  String get checklistShare;

  /// No description provided for @checklistShowCheckboxes.
  ///
  /// In en, this message translates to:
  /// **'Show checkboxes'**
  String get checklistShowCheckboxes;

  /// No description provided for @checklistSortAlpha.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get checklistSortAlpha;

  /// No description provided for @checklistSortChildren.
  ///
  /// In en, this message translates to:
  /// **'Sort sub-items'**
  String get checklistSortChildren;

  /// No description provided for @checklistSortCompletedBottom.
  ///
  /// In en, this message translates to:
  /// **'Sort completed to bottom'**
  String get checklistSortCompletedBottom;

  /// No description provided for @checklistSortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get checklistSortDescending;

  /// No description provided for @checklistSortDue.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get checklistSortDue;

  /// No description provided for @checklistSortFilter.
  ///
  /// In en, this message translates to:
  /// **'Sort & filter'**
  String get checklistSortFilter;

  /// No description provided for @checklistSortManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get checklistSortManual;

  /// No description provided for @checklistSortPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get checklistSortPriority;

  /// No description provided for @checklistSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently changed'**
  String get checklistSortRecent;

  /// No description provided for @checklistSortStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get checklistSortStatus;

  /// No description provided for @checklistSortedBy.
  ///
  /// In en, this message translates to:
  /// **'Sorted by {criterion}'**
  String checklistSortedBy(String criterion);

  /// No description provided for @checklistStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get checklistStatusChanged;

  /// Screen-reader form of a status with its age, e.g. 'Waiting for 4 days'.
  ///
  /// In en, this message translates to:
  /// **'{status} for {age}'**
  String checklistStatusSpoken(String status, String age);

  /// No description provided for @checklistSubItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sub-item} other{{count} sub-items}}'**
  String checklistSubItems(int count);

  /// No description provided for @checklistTaskLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to {task}'**
  String checklistTaskLinked(String task);

  /// No description provided for @checklistTaskPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Linking to planner tasks arrives with the planner.'**
  String get checklistTaskPlaceholder;

  /// No description provided for @checklistTaskScheduled.
  ///
  /// In en, this message translates to:
  /// **'Task created — set its time'**
  String get checklistTaskScheduled;

  /// No description provided for @checklistTemplateSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as template'**
  String get checklistTemplateSaved;

  /// No description provided for @checklistTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get checklistTitleHint;

  /// No description provided for @checklistUncheckAll.
  ///
  /// In en, this message translates to:
  /// **'Uncheck all'**
  String get checklistUncheckAll;

  /// No description provided for @checklistUncheckConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Uncheck 1 item?} other{Uncheck {count} items?}}'**
  String checklistUncheckConfirm(int count);

  /// No description provided for @checklistViewGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get checklistViewGallery;

  /// No description provided for @checklistViewKanban.
  ///
  /// In en, this message translates to:
  /// **'Kanban'**
  String get checklistViewKanban;

  /// No description provided for @checklistViewMindMap.
  ///
  /// In en, this message translates to:
  /// **'Mind map'**
  String get checklistViewMindMap;

  /// No description provided for @checklistViewOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get checklistViewOutline;

  /// No description provided for @checklistZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get checklistZoomOut;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @confirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'You can restore it from Trash for 30 days.'**
  String get confirmDeleteBody;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {item}?'**
  String confirmDeleteTitle(String item);

  /// No description provided for @deletedSnack.
  ///
  /// In en, this message translates to:
  /// **'{item} deleted'**
  String deletedSnack(String item);

  /// No description provided for @devMenu.
  ///
  /// In en, this message translates to:
  /// **'Developer menu'**
  String get devMenu;

  /// No description provided for @durationDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String durationDaysShort(int days);

  /// No description provided for @durationHoursMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutesShort(int hours, int minutes);

  /// No description provided for @durationHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String durationHoursShort(int hours);

  /// No description provided for @durationMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutesShort(int minutes);

  /// No description provided for @entityStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get entityStatusActive;

  /// No description provided for @entityStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get entityStatusArchived;

  /// No description provided for @entityStatusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get entityStatusBlocked;

  /// No description provided for @entityStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get entityStatusCancelled;

  /// No description provided for @entityStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get entityStatusCompleted;

  /// No description provided for @entityStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get entityStatusDone;

  /// No description provided for @entityStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get entityStatusInProgress;

  /// No description provided for @entityStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get entityStatusMissed;

  /// No description provided for @entityStatusOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get entityStatusOngoing;

  /// No description provided for @entityStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get entityStatusPaused;

  /// No description provided for @entityStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get entityStatusScheduled;

  /// No description provided for @entityStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get entityStatusSkipped;

  /// No description provided for @entityStatusTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get entityStatusTodo;

  /// No description provided for @entityStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get entityStatusWaiting;

  /// No description provided for @errorAuth.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get errorAuth;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This feature needs cloud configuration (see guide.md).'**
  String get errorNotConfigured;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item no longer exists.'**
  String get errorNotFound;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission is needed for this.'**
  String get errorPermission;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error.'**
  String get errorUnknown;

  /// No description provided for @errorUnsupportedVersion.
  ///
  /// In en, this message translates to:
  /// **'Please update Everslot to keep syncing.'**
  String get errorUnsupportedVersion;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get errorValidation;

  /// No description provided for @exportBranchOnly.
  ///
  /// In en, this message translates to:
  /// **'Only this branch'**
  String get exportBranchOnly;

  /// No description provided for @exportCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get exportCopied;

  /// No description provided for @exportCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get exportCopy;

  /// No description provided for @exportMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get exportMarkdown;

  /// No description provided for @exportOpml.
  ///
  /// In en, this message translates to:
  /// **'OPML'**
  String get exportOpml;

  /// No description provided for @exportPlain.
  ///
  /// In en, this message translates to:
  /// **'Plain text'**
  String get exportPlain;

  /// No description provided for @exportShare.
  ///
  /// In en, this message translates to:
  /// **'Share…'**
  String get exportShare;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Share / export'**
  String get exportTitle;

  /// No description provided for @filterActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No filters} =1{1 filter active} other{{count} filters active}}'**
  String filterActiveCount(int count);

  /// No description provided for @filterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get filterAny;

  /// No description provided for @filterAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get filterAttachments;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// No description provided for @filterChipCount.
  ///
  /// In en, this message translates to:
  /// **'{field} · {count}'**
  String filterChipCount(String field, int count);

  /// No description provided for @filterChipValue.
  ///
  /// In en, this message translates to:
  /// **'{field}: {value}'**
  String filterChipValue(String field, String value);

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filter {filter}'**
  String filterClear(String filter);

  /// No description provided for @filterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get filterClearAll;

  /// No description provided for @filterDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get filterDate;

  /// No description provided for @filterNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get filterNoCategory;

  /// No description provided for @filterOneOffOnly.
  ///
  /// In en, this message translates to:
  /// **'One-off'**
  String get filterOneOffOnly;

  /// No description provided for @filterPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get filterPriority;

  /// No description provided for @filterRecurring.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get filterRecurring;

  /// No description provided for @filterRecurringOnly.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get filterRecurringOnly;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// No description provided for @filterTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get filterTag;

  /// No description provided for @filterText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get filterText;

  /// No description provided for @filterTextPrompt.
  ///
  /// In en, this message translates to:
  /// **'Contains text'**
  String get filterTextPrompt;

  /// No description provided for @filterWithAttachments.
  ///
  /// In en, this message translates to:
  /// **'With attachments'**
  String get filterWithAttachments;

  /// No description provided for @filterWithoutAttachments.
  ///
  /// In en, this message translates to:
  /// **'Without attachments'**
  String get filterWithoutAttachments;

  /// No description provided for @galleryButtons.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get galleryButtons;

  /// No description provided for @galleryChips.
  ///
  /// In en, this message translates to:
  /// **'Chips & tags'**
  String get galleryChips;

  /// No description provided for @galleryColors.
  ///
  /// In en, this message translates to:
  /// **'Category colors'**
  String get galleryColors;

  /// No description provided for @galleryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get galleryConfirm;

  /// No description provided for @galleryContainer.
  ///
  /// In en, this message translates to:
  /// **'Open item'**
  String get galleryContainer;

  /// No description provided for @galleryDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get galleryDarkTheme;

  /// No description provided for @galleryDialogs.
  ///
  /// In en, this message translates to:
  /// **'Dialogs, sheets & pickers'**
  String get galleryDialogs;

  /// No description provided for @galleryDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get galleryDisabled;

  /// No description provided for @galleryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items with images'**
  String get galleryEmpty;

  /// No description provided for @galleryFadeThrough.
  ///
  /// In en, this message translates to:
  /// **'Fade through'**
  String get galleryFadeThrough;

  /// No description provided for @galleryFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get galleryFilters;

  /// No description provided for @galleryIcons.
  ///
  /// In en, this message translates to:
  /// **'Icons'**
  String get galleryIcons;

  /// No description provided for @galleryInputs.
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get galleryInputs;

  /// No description provided for @galleryLargeText.
  ///
  /// In en, this message translates to:
  /// **'Large text (200 %)'**
  String get galleryLargeText;

  /// No description provided for @galleryLayout.
  ///
  /// In en, this message translates to:
  /// **'Adaptive layout'**
  String get galleryLayout;

  /// No description provided for @galleryMotion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get galleryMotion;

  /// No description provided for @galleryOnlyImages.
  ///
  /// In en, this message translates to:
  /// **'Only items with images'**
  String get galleryOnlyImages;

  /// No description provided for @galleryPicked.
  ///
  /// In en, this message translates to:
  /// **'Picked: {value}'**
  String galleryPicked(String value);

  /// No description provided for @galleryPriorities.
  ///
  /// In en, this message translates to:
  /// **'Priorities'**
  String get galleryPriorities;

  /// No description provided for @galleryProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get galleryProgress;

  /// No description provided for @galleryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Text prompt'**
  String get galleryPrompt;

  /// No description provided for @galleryReduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get galleryReduceMotion;

  /// No description provided for @galleryRtl.
  ///
  /// In en, this message translates to:
  /// **'Right-to-left'**
  String get galleryRtl;

  /// No description provided for @gallerySampleText.
  ///
  /// In en, this message translates to:
  /// **'Sample text'**
  String get gallerySampleText;

  /// No description provided for @gallerySharedAxis.
  ///
  /// In en, this message translates to:
  /// **'Shared axis'**
  String get gallerySharedAxis;

  /// No description provided for @gallerySheet.
  ///
  /// In en, this message translates to:
  /// **'Bottom sheet'**
  String get gallerySheet;

  /// No description provided for @gallerySheetBody.
  ///
  /// In en, this message translates to:
  /// **'A bottom sheet with Everslot styling.'**
  String get gallerySheetBody;

  /// No description provided for @galleryStates.
  ///
  /// In en, this message translates to:
  /// **'Empty, error & loading states'**
  String get galleryStates;

  /// No description provided for @galleryStatuses.
  ///
  /// In en, this message translates to:
  /// **'Statuses'**
  String get galleryStatuses;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Component gallery'**
  String get galleryTitle;

  /// No description provided for @galleryUndoSnack.
  ///
  /// In en, this message translates to:
  /// **'Undo snackbar'**
  String get galleryUndoSnack;

  /// No description provided for @galleryWindowCompact.
  ///
  /// In en, this message translates to:
  /// **'compact'**
  String get galleryWindowCompact;

  /// No description provided for @galleryWindowExpanded.
  ///
  /// In en, this message translates to:
  /// **'expanded'**
  String get galleryWindowExpanded;

  /// No description provided for @galleryWindowMedium.
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get galleryWindowMedium;

  /// No description provided for @galleryWindowSize.
  ///
  /// In en, this message translates to:
  /// **'Window: {size}'**
  String galleryWindowSize(String size);

  /// No description provided for @habitsActionAddValue.
  ///
  /// In en, this message translates to:
  /// **'Add a value'**
  String get habitsActionAddValue;

  /// No description provided for @habitsActionBackfill.
  ///
  /// In en, this message translates to:
  /// **'Log another day'**
  String get habitsActionBackfill;

  /// No description provided for @habitsActionCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get habitsActionCheckNow;

  /// No description provided for @habitsActionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get habitsActionClear;

  /// No description provided for @habitsActionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get habitsActionDetails;

  /// No description provided for @habitsActionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get habitsActionDone;

  /// No description provided for @habitsActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get habitsActionEdit;

  /// No description provided for @habitsActionEditEntries.
  ///
  /// In en, this message translates to:
  /// **'Edit entries'**
  String get habitsActionEditEntries;

  /// No description provided for @habitsActionExcuse.
  ///
  /// In en, this message translates to:
  /// **'Excuse'**
  String get habitsActionExcuse;

  /// No description provided for @habitsActionNotDone.
  ///
  /// In en, this message translates to:
  /// **'Not done'**
  String get habitsActionNotDone;

  /// No description provided for @habitsActionNoteMood.
  ///
  /// In en, this message translates to:
  /// **'Note & mood'**
  String get habitsActionNoteMood;

  /// No description provided for @habitsActionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get habitsActionPause;

  /// No description provided for @habitsActionPauseTimer.
  ///
  /// In en, this message translates to:
  /// **'Pause timer'**
  String get habitsActionPauseTimer;

  /// No description provided for @habitsActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get habitsActionSkip;

  /// No description provided for @habitsActionStartTimer.
  ///
  /// In en, this message translates to:
  /// **'Start timer'**
  String get habitsActionStartTimer;

  /// No description provided for @habitsActionStopTimer.
  ///
  /// In en, this message translates to:
  /// **'Stop and log'**
  String get habitsActionStopTimer;

  /// No description provided for @habitsActionUndoDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as not checked'**
  String get habitsActionUndoDone;

  /// No description provided for @habitsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get habitsAdd;

  /// No description provided for @habitsAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get habitsAddEntry;

  /// No description provided for @habitsAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get habitsAddTime;

  /// No description provided for @habitsAdvancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get habitsAdvancedTitle;

  /// No description provided for @habitsAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done 🎉'**
  String get habitsAllDone;

  /// No description provided for @habitsAllHabits.
  ///
  /// In en, this message translates to:
  /// **'All habits'**
  String get habitsAllHabits;

  /// No description provided for @habitsAllStats.
  ///
  /// In en, this message translates to:
  /// **'All stats'**
  String get habitsAllStats;

  /// No description provided for @habitsApplyAll.
  ///
  /// In en, this message translates to:
  /// **'All history'**
  String get habitsApplyAll;

  /// No description provided for @habitsApplyAllWarn.
  ///
  /// In en, this message translates to:
  /// **'Past statistics will change.'**
  String get habitsApplyAllWarn;

  /// No description provided for @habitsApplyDate.
  ///
  /// In en, this message translates to:
  /// **'A chosen date…'**
  String get habitsApplyDate;

  /// No description provided for @habitsApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply the new schedule or goal from'**
  String get habitsApplyTitle;

  /// No description provided for @habitsApplyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get habitsApplyToday;

  /// No description provided for @habitsArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get habitsArchived;

  /// No description provided for @habitsArchivedSnack.
  ///
  /// In en, this message translates to:
  /// **'Habit archived'**
  String get habitsArchivedSnack;

  /// No description provided for @habitsAskNote.
  ///
  /// In en, this message translates to:
  /// **'Ask for a note & mood after check-in'**
  String get habitsAskNote;

  /// No description provided for @habitsAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get habitsAtRisk;

  /// No description provided for @habitsBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get habitsBestStreak;

  /// No description provided for @habitsCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get habitsCalendar;

  /// No description provided for @habitsCelebratePerfectDay.
  ///
  /// In en, this message translates to:
  /// **'Perfect day — everything done!'**
  String get habitsCelebratePerfectDay;

  /// No description provided for @habitsCelebrateStreak.
  ///
  /// In en, this message translates to:
  /// **'{name}: {count, plural, =1{1 day in a row} other{{count} days in a row}}!'**
  String habitsCelebrateStreak(String name, int count);

  /// No description provided for @habitsCelebrationDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get habitsCelebrationDismiss;

  /// No description provided for @habitsCellSemantics.
  ///
  /// In en, this message translates to:
  /// **'{habit}, {date}: {status}'**
  String habitsCellSemantics(String habit, String date, String status);

  /// No description provided for @habitsChallengeDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String habitsChallengeDay(int day, int total);

  /// No description provided for @habitsCompactRows.
  ///
  /// In en, this message translates to:
  /// **'Compact rows'**
  String get habitsCompactRows;

  /// No description provided for @habitsCounts.
  ///
  /// In en, this message translates to:
  /// **'Done {done} · Not done {notDone} · Missed {missed} · Skipped {skipped}'**
  String habitsCounts(int done, int notDone, int missed, int skipped);

  /// No description provided for @habitsCreateQuitInstead.
  ///
  /// In en, this message translates to:
  /// **'Create a quit tracker'**
  String get habitsCreateQuitInstead;

  /// No description provided for @habitsCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get habitsCurrentStreak;

  /// No description provided for @habitsDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get habitsDatesTitle;

  /// No description provided for @habitsDayStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get habitsDayStateLabel;

  /// No description provided for @habitsDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 days} =1{1 day} other{{count} days}}'**
  String habitsDays(int count);

  /// No description provided for @habitsDecrease.
  ///
  /// In en, this message translates to:
  /// **'Remove {step}'**
  String habitsDecrease(String step);

  /// No description provided for @habitsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its history goes to the trash with it. You can restore it for 30 days.'**
  String get habitsDeleteBody;

  /// No description provided for @habitsDeleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get habitsDeleteEntry;

  /// No description provided for @habitsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String habitsDeleteTitle(String name);

  /// No description provided for @habitsDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Habit deleted'**
  String get habitsDeletedSnack;

  /// No description provided for @habitsDragHandle.
  ///
  /// In en, this message translates to:
  /// **'Reorder {name}'**
  String habitsDragHandle(String name);

  /// No description provided for @habitsEditCustom.
  ///
  /// In en, this message translates to:
  /// **'Edit the schedule'**
  String get habitsEditCustom;

  /// No description provided for @habitsEditEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get habitsEditEntry;

  /// No description provided for @habitsEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get habitsEditorEditTitle;

  /// No description provided for @habitsEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get habitsEditorNewTitle;

  /// No description provided for @habitsEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Create a habit'**
  String get habitsEmptyAction;

  /// No description provided for @habitsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a habit — like 15 push-ups a day — and mark each day whether you did it.'**
  String get habitsEmptyBody;

  /// No description provided for @habitsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get habitsEmptyTitle;

  /// No description provided for @habitsEndNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get habitsEndNever;

  /// No description provided for @habitsEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get habitsEntries;

  /// No description provided for @habitsEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get habitsEntryDeleted;

  /// No description provided for @habitsErrDuration.
  ///
  /// In en, this message translates to:
  /// **'A duration goal must be between 1 min and 24 h'**
  String get habitsErrDuration;

  /// No description provided for @habitsErrEnd.
  ///
  /// In en, this message translates to:
  /// **'The end date is before the start date'**
  String get habitsErrEnd;

  /// No description provided for @habitsErrFreezes.
  ///
  /// In en, this message translates to:
  /// **'Between 0 and 31 freezes per month'**
  String get habitsErrFreezes;

  /// No description provided for @habitsErrLimitNeedsMeasurable.
  ///
  /// In en, this message translates to:
  /// **'“At most” needs a count, a duration or a number'**
  String get habitsErrLimitNeedsMeasurable;

  /// No description provided for @habitsErrNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get habitsErrNameEmpty;

  /// No description provided for @habitsErrNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'The name is too long (80 characters max)'**
  String get habitsErrNameTooLong;

  /// No description provided for @habitsErrSchedule.
  ///
  /// In en, this message translates to:
  /// **'This schedule isn\'t valid'**
  String get habitsErrSchedule;

  /// No description provided for @habitsErrSectionName.
  ///
  /// In en, this message translates to:
  /// **'Name must be 1–40 characters'**
  String get habitsErrSectionName;

  /// No description provided for @habitsErrTarget.
  ///
  /// In en, this message translates to:
  /// **'Enter a target greater than 0'**
  String get habitsErrTarget;

  /// No description provided for @habitsErrUnit.
  ///
  /// In en, this message translates to:
  /// **'The unit must be 1–20 characters'**
  String get habitsErrUnit;

  /// No description provided for @habitsErrorArchived.
  ///
  /// In en, this message translates to:
  /// **'This habit is archived.'**
  String get habitsErrorArchived;

  /// No description provided for @habitsErrorFuture.
  ///
  /// In en, this message translates to:
  /// **'You can\'t log this before it starts — skip or excuse it instead.'**
  String get habitsErrorFuture;

  /// No description provided for @habitsEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =2{Every other day} other{Every {n} days}}'**
  String habitsEveryNDays(int n);

  /// No description provided for @habitsFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get habitsFieldCategory;

  /// No description provided for @habitsFieldColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get habitsFieldColor;

  /// No description provided for @habitsFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get habitsFieldDescription;

  /// No description provided for @habitsFieldEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get habitsFieldEnd;

  /// No description provided for @habitsFieldIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get habitsFieldIcon;

  /// No description provided for @habitsFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get habitsFieldName;

  /// No description provided for @habitsFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 15 push-ups'**
  String get habitsFieldNameHint;

  /// No description provided for @habitsFieldSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get habitsFieldSection;

  /// No description provided for @habitsFieldStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get habitsFieldStart;

  /// No description provided for @habitsFieldTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get habitsFieldTarget;

  /// No description provided for @habitsFieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get habitsFieldUnit;

  /// No description provided for @habitsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get habitsFilterAll;

  /// No description provided for @habitsFilterDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get habitsFilterDue;

  /// No description provided for @habitsFor30Days.
  ///
  /// In en, this message translates to:
  /// **'For 30 days'**
  String get habitsFor30Days;

  /// No description provided for @habitsFreezes.
  ///
  /// In en, this message translates to:
  /// **'Streak freezes per month'**
  String get habitsFreezes;

  /// No description provided for @habitsFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'From a template'**
  String get habitsFromTemplate;

  /// No description provided for @habitsFutureOnlyPlanned.
  ///
  /// In en, this message translates to:
  /// **'Only skips and excuses can be planned for future days.'**
  String get habitsFutureOnlyPlanned;

  /// No description provided for @habitsGoalExampleCheck.
  ///
  /// In en, this message translates to:
  /// **'Did it or not'**
  String get habitsGoalExampleCheck;

  /// No description provided for @habitsGoalExampleCount.
  ///
  /// In en, this message translates to:
  /// **'15 push-ups'**
  String get habitsGoalExampleCount;

  /// No description provided for @habitsGoalExampleDuration.
  ///
  /// In en, this message translates to:
  /// **'Read 20 min'**
  String get habitsGoalExampleDuration;

  /// No description provided for @habitsGoalExampleNumeric.
  ///
  /// In en, this message translates to:
  /// **'Run 5 km'**
  String get habitsGoalExampleNumeric;

  /// No description provided for @habitsGoalSentence.
  ///
  /// In en, this message translates to:
  /// **'{op} {amount}'**
  String habitsGoalSentence(String op, String amount);

  /// No description provided for @habitsGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get habitsGoalTitle;

  /// No description provided for @habitsGoalTypeCheck.
  ///
  /// In en, this message translates to:
  /// **'Yes / No'**
  String get habitsGoalTypeCheck;

  /// No description provided for @habitsGoalTypeCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get habitsGoalTypeCount;

  /// No description provided for @habitsGoalTypeDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get habitsGoalTypeDuration;

  /// No description provided for @habitsGoalTypeNumeric.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get habitsGoalTypeNumeric;

  /// No description provided for @habitsGroupByCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get habitsGroupByCategory;

  /// No description provided for @habitsGroupByNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get habitsGroupByNone;

  /// No description provided for @habitsGroupBySection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get habitsGroupBySection;

  /// No description provided for @habitsGroupByTitle.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get habitsGroupByTitle;

  /// No description provided for @habitsGroupNotDue.
  ///
  /// In en, this message translates to:
  /// **'Not due today ({count})'**
  String habitsGroupNotDue(int count);

  /// No description provided for @habitsHideNotDue.
  ///
  /// In en, this message translates to:
  /// **'Hide habits not due'**
  String get habitsHideNotDue;

  /// No description provided for @habitsHoldRingHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold to mark as done'**
  String get habitsHoldRingHint;

  /// No description provided for @habitsHoldToComplete.
  ///
  /// In en, this message translates to:
  /// **'Hold to complete'**
  String get habitsHoldToComplete;

  /// No description provided for @habitsHoldToCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the ring to check a habit off, to avoid accidental taps.'**
  String get habitsHoldToCompleteHint;

  /// No description provided for @habitsIncrease.
  ///
  /// In en, this message translates to:
  /// **'Add {step}'**
  String habitsIncrease(String step);

  /// No description provided for @habitsIncrementStep.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get habitsIncrementStep;

  /// No description provided for @habitsJournal.
  ///
  /// In en, this message translates to:
  /// **'Notes journal'**
  String get habitsJournal;

  /// No description provided for @habitsJournalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get habitsJournalEmpty;

  /// No description provided for @habitsJournalEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Notes and moods you add to check-ins appear here.'**
  String get habitsJournalEmptyBody;

  /// No description provided for @habitsLast90.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get habitsLast90;

  /// No description provided for @habitsLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get habitsLastDay;

  /// No description provided for @habitsLeftOfLimit.
  ///
  /// In en, this message translates to:
  /// **'{left} of {limit} left'**
  String habitsLeftOfLimit(String left, String limit);

  /// No description provided for @habitsLimitZeroHint.
  ///
  /// In en, this message translates to:
  /// **'A limit of 0 means quitting it completely.'**
  String get habitsLimitZeroHint;

  /// No description provided for @habitsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage habits'**
  String get habitsManage;

  /// No description provided for @habitsMatrixTapTitle.
  ///
  /// In en, this message translates to:
  /// **'Tapping a day in the week view'**
  String get habitsMatrixTapTitle;

  /// No description provided for @habitsMinPerDay.
  ///
  /// In en, this message translates to:
  /// **'Minimum per day'**
  String get habitsMinPerDay;

  /// No description provided for @habitsMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String habitsMinutesValue(int minutes);

  /// No description provided for @habitsMood1.
  ///
  /// In en, this message translates to:
  /// **'Awful'**
  String get habitsMood1;

  /// No description provided for @habitsMood2.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get habitsMood2;

  /// No description provided for @habitsMood3.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get habitsMood3;

  /// No description provided for @habitsMood4.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get habitsMood4;

  /// No description provided for @habitsMood5.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get habitsMood5;

  /// No description provided for @habitsMoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get habitsMoodLabel;

  /// No description provided for @habitsMoodTrend.
  ///
  /// In en, this message translates to:
  /// **'Mood trend'**
  String get habitsMoodTrend;

  /// No description provided for @habitsMoveToSection.
  ///
  /// In en, this message translates to:
  /// **'Move to section…'**
  String get habitsMoveToSection;

  /// No description provided for @habitsNewHabit.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get habitsNewHabit;

  /// No description provided for @habitsNewQuit.
  ///
  /// In en, this message translates to:
  /// **'New quit tracker'**
  String get habitsNewQuit;

  /// No description provided for @habitsNewer.
  ///
  /// In en, this message translates to:
  /// **'Later days'**
  String get habitsNewer;

  /// No description provided for @habitsNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get habitsNextDay;

  /// No description provided for @habitsNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get habitsNextMonth;

  /// No description provided for @habitsNextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get habitsNextYear;

  /// No description provided for @habitsNoBuildHabits.
  ///
  /// In en, this message translates to:
  /// **'No habit to check in yet'**
  String get habitsNoBuildHabits;

  /// No description provided for @habitsNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get habitsNoCategory;

  /// No description provided for @habitsNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get habitsNoEntries;

  /// No description provided for @habitsNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get habitsNone;

  /// No description provided for @habitsNotActiveThatDay.
  ///
  /// In en, this message translates to:
  /// **'This habit wasn\'t active that day.'**
  String get habitsNotActiveThatDay;

  /// No description provided for @habitsNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get habitsNotEnoughData;

  /// No description provided for @habitsNoteHint.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get habitsNoteHint;

  /// No description provided for @habitsNoteMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Note & mood'**
  String get habitsNoteMoodTitle;

  /// No description provided for @habitsNothingThisDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled this day'**
  String get habitsNothingThisDay;

  /// No description provided for @habitsNothingThisDayBody.
  ///
  /// In en, this message translates to:
  /// **'Habits appear here on the days they are due.'**
  String get habitsNothingThisDayBody;

  /// No description provided for @habitsNotifGone.
  ///
  /// In en, this message translates to:
  /// **'This habit no longer exists.'**
  String get habitsNotifGone;

  /// No description provided for @habitsNotifInvalidValue.
  ///
  /// In en, this message translates to:
  /// **'“{input}” isn\'t a number — open the app to log it.'**
  String habitsNotifInvalidValue(String input);

  /// No description provided for @habitsOlder.
  ///
  /// In en, this message translates to:
  /// **'Earlier days'**
  String get habitsOlder;

  /// No description provided for @habitsOnlyOn.
  ///
  /// In en, this message translates to:
  /// **'Only on (optional)'**
  String get habitsOnlyOn;

  /// No description provided for @habitsOpAtLeast.
  ///
  /// In en, this message translates to:
  /// **'At least'**
  String get habitsOpAtLeast;

  /// No description provided for @habitsOpAtMost.
  ///
  /// In en, this message translates to:
  /// **'At most'**
  String get habitsOpAtMost;

  /// No description provided for @habitsOpExactly.
  ///
  /// In en, this message translates to:
  /// **'Exactly'**
  String get habitsOpExactly;

  /// No description provided for @habitsOrdinal.
  ///
  /// In en, this message translates to:
  /// **'{which, select, first{First} second{Second} third{Third} fourth{Fourth} other{Last}}'**
  String habitsOrdinal(String which);

  /// No description provided for @habitsOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Over the limit'**
  String get habitsOverLimit;

  /// No description provided for @habitsPauseAction.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get habitsPauseAction;

  /// No description provided for @habitsPauseDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String habitsPauseDays(int count);

  /// No description provided for @habitsPauseHint.
  ///
  /// In en, this message translates to:
  /// **'Paused days are neutral: never missed and they never break a streak.'**
  String get habitsPauseHint;

  /// No description provided for @habitsPauseIndefinitely.
  ///
  /// In en, this message translates to:
  /// **'Indefinitely'**
  String get habitsPauseIndefinitely;

  /// No description provided for @habitsPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause habit'**
  String get habitsPauseTitle;

  /// No description provided for @habitsPauseToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get habitsPauseToday;

  /// No description provided for @habitsPauseUntil.
  ///
  /// In en, this message translates to:
  /// **'Until a date…'**
  String get habitsPauseUntil;

  /// No description provided for @habitsPauseUntilDate.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String habitsPauseUntilDate(String date);

  /// No description provided for @habitsPauseWeek.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get habitsPauseWeek;

  /// No description provided for @habitsPausedIndefinitely.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get habitsPausedIndefinitely;

  /// No description provided for @habitsPausedSnack.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get habitsPausedSnack;

  /// No description provided for @habitsPausedUntil.
  ///
  /// In en, this message translates to:
  /// **'Paused until {date}'**
  String habitsPausedUntil(String date);

  /// No description provided for @habitsPerfectDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No perfect day yet} =1{1 perfect day} other{{count} perfect days}}'**
  String habitsPerfectDays(int count);

  /// No description provided for @habitsPickDuration.
  ///
  /// In en, this message translates to:
  /// **'Pick a duration'**
  String get habitsPickDuration;

  /// No description provided for @habitsPresetAfterCompletion.
  ///
  /// In en, this message translates to:
  /// **'After I finish'**
  String get habitsPresetAfterCompletion;

  /// No description provided for @habitsPresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get habitsPresetCustom;

  /// No description provided for @habitsPresetDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get habitsPresetDaily;

  /// No description provided for @habitsPresetEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'Every N days'**
  String get habitsPresetEveryNDays;

  /// No description provided for @habitsPresetInterval.
  ///
  /// In en, this message translates to:
  /// **'Every N hours'**
  String get habitsPresetInterval;

  /// No description provided for @habitsPresetMonthlyDay.
  ///
  /// In en, this message translates to:
  /// **'Monthly on a day'**
  String get habitsPresetMonthlyDay;

  /// No description provided for @habitsPresetMonthlyWeekday.
  ///
  /// In en, this message translates to:
  /// **'Monthly on a weekday'**
  String get habitsPresetMonthlyWeekday;

  /// No description provided for @habitsPresetSpecificDays.
  ///
  /// In en, this message translates to:
  /// **'Specific days'**
  String get habitsPresetSpecificDays;

  /// No description provided for @habitsPresetSpecificTimes.
  ///
  /// In en, this message translates to:
  /// **'At set times'**
  String get habitsPresetSpecificTimes;

  /// No description provided for @habitsPresetTimesPerDay.
  ///
  /// In en, this message translates to:
  /// **'N times a day'**
  String get habitsPresetTimesPerDay;

  /// No description provided for @habitsPresetTimesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'N× a month'**
  String get habitsPresetTimesPerMonth;

  /// No description provided for @habitsPresetTimesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'N× a week'**
  String get habitsPresetTimesPerWeek;

  /// No description provided for @habitsPresetWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get habitsPresetWeekdays;

  /// No description provided for @habitsPresetWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get habitsPresetWeekends;

  /// No description provided for @habitsPrevDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get habitsPrevDay;

  /// No description provided for @habitsPreviewNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get habitsPreviewNext;

  /// No description provided for @habitsPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get habitsPreviewTitle;

  /// No description provided for @habitsPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get habitsPreviousMonth;

  /// No description provided for @habitsPreviousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get habitsPreviousYear;

  /// No description provided for @habitsQuickValues.
  ///
  /// In en, this message translates to:
  /// **'Quick values'**
  String get habitsQuickValues;

  /// No description provided for @habitsQuickValuesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5 10 15'**
  String get habitsQuickValuesHint;

  /// No description provided for @habitsQuotaMonth.
  ///
  /// In en, this message translates to:
  /// **'{done} of {times} this month'**
  String habitsQuotaMonth(int done, int times);

  /// No description provided for @habitsQuotaWeek.
  ///
  /// In en, this message translates to:
  /// **'{done} of {times} this week'**
  String habitsQuotaWeek(int done, int times);

  /// No description provided for @habitsRate30.
  ///
  /// In en, this message translates to:
  /// **'30-day rate'**
  String get habitsRate30;

  /// No description provided for @habitsReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get habitsReasonOptional;

  /// No description provided for @habitsRecentEntries.
  ///
  /// In en, this message translates to:
  /// **'Recent entries'**
  String get habitsRecentEntries;

  /// No description provided for @habitsReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get habitsReorder;

  /// No description provided for @habitsReorderDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get habitsReorderDone;

  /// No description provided for @habitsReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the handles to change the order.'**
  String get habitsReorderHint;

  /// No description provided for @habitsReordered.
  ///
  /// In en, this message translates to:
  /// **'Order saved'**
  String get habitsReordered;

  /// No description provided for @habitsRequireExplicit.
  ///
  /// In en, this message translates to:
  /// **'An empty day counts as missed'**
  String get habitsRequireExplicit;

  /// No description provided for @habitsResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get habitsResume;

  /// No description provided for @habitsResumedSnack.
  ///
  /// In en, this message translates to:
  /// **'Resumed'**
  String get habitsResumedSnack;

  /// No description provided for @habitsRollupAll.
  ///
  /// In en, this message translates to:
  /// **'All check-ins must be done'**
  String get habitsRollupAll;

  /// No description provided for @habitsRollupMin.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{At least 1 check-in} other{At least {n} check-ins}}'**
  String habitsRollupMin(int n);

  /// No description provided for @habitsRollupMinCount.
  ///
  /// In en, this message translates to:
  /// **'Check-ins needed'**
  String get habitsRollupMinCount;

  /// No description provided for @habitsRollupMinTitle.
  ///
  /// In en, this message translates to:
  /// **'A day counts when some check-ins are done'**
  String get habitsRollupMinTitle;

  /// No description provided for @habitsSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get habitsSavedSnack;

  /// No description provided for @habitsScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get habitsScheduleTitle;

  /// No description provided for @habitsSectionAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get habitsSectionAfternoon;

  /// No description provided for @habitsSectionAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get habitsSectionAnytime;

  /// No description provided for @habitsSectionDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its habits move to Anytime.'**
  String get habitsSectionDeleteBody;

  /// No description provided for @habitsSectionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this section?'**
  String get habitsSectionDeleteTitle;

  /// No description provided for @habitsSectionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Section deleted'**
  String get habitsSectionDeleted;

  /// No description provided for @habitsSectionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit section'**
  String get habitsSectionEdit;

  /// No description provided for @habitsSectionEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get habitsSectionEvening;

  /// No description provided for @habitsSectionMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get habitsSectionMorning;

  /// No description provided for @habitsSectionNew.
  ///
  /// In en, this message translates to:
  /// **'New section'**
  String get habitsSectionNew;

  /// No description provided for @habitsSectionNone.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get habitsSectionNone;

  /// No description provided for @habitsSectionProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} done'**
  String habitsSectionProgress(int done, int total);

  /// No description provided for @habitsSectionWindow.
  ///
  /// In en, this message translates to:
  /// **'Time window'**
  String get habitsSectionWindow;

  /// No description provided for @habitsSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get habitsSections;

  /// No description provided for @habitsShowStreaks.
  ///
  /// In en, this message translates to:
  /// **'Show streaks'**
  String get habitsShowStreaks;

  /// No description provided for @habitsSkipBreaks.
  ///
  /// In en, this message translates to:
  /// **'Break the streak'**
  String get habitsSkipBreaks;

  /// No description provided for @habitsSkipNeutral.
  ///
  /// In en, this message translates to:
  /// **'Don\'t break the streak'**
  String get habitsSkipNeutral;

  /// No description provided for @habitsSkipPolicy.
  ///
  /// In en, this message translates to:
  /// **'Skipped days'**
  String get habitsSkipPolicy;

  /// No description provided for @habitsSlotsProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total}'**
  String habitsSlotsProgress(int done, int total);

  /// No description provided for @habitsSnackCleared.
  ///
  /// In en, this message translates to:
  /// **'“{name}” cleared'**
  String habitsSnackCleared(String name);

  /// No description provided for @habitsSnackDone.
  ///
  /// In en, this message translates to:
  /// **'“{name}” done'**
  String habitsSnackDone(String name);

  /// No description provided for @habitsSnackExcused.
  ///
  /// In en, this message translates to:
  /// **'“{name}” excused'**
  String habitsSnackExcused(String name);

  /// No description provided for @habitsSnackLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged {amount} · {name}'**
  String habitsSnackLogged(String amount, String name);

  /// No description provided for @habitsSnackNotDone.
  ///
  /// In en, this message translates to:
  /// **'“{name}” marked not done'**
  String habitsSnackNotDone(String name);

  /// No description provided for @habitsSnackSkipped.
  ///
  /// In en, this message translates to:
  /// **'“{name}” skipped'**
  String habitsSnackSkipped(String name);

  /// No description provided for @habitsStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get habitsStatusDone;

  /// No description provided for @habitsStatusExcused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get habitsStatusExcused;

  /// No description provided for @habitsStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Not done'**
  String get habitsStatusFailed;

  /// No description provided for @habitsStatusFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get habitsStatusFrozen;

  /// No description provided for @habitsStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get habitsStatusMissed;

  /// No description provided for @habitsStatusNotDue.
  ///
  /// In en, this message translates to:
  /// **'Not due'**
  String get habitsStatusNotDue;

  /// No description provided for @habitsStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly done'**
  String get habitsStatusPartial;

  /// No description provided for @habitsStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get habitsStatusPaused;

  /// No description provided for @habitsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get habitsStatusPending;

  /// No description provided for @habitsStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get habitsStatusSkipped;

  /// No description provided for @habitsStreakSemantics.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1-day streak} other{{days}-day streak}}'**
  String habitsStreakSemantics(int days);

  /// No description provided for @habitsStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get habitsStrength;

  /// No description provided for @habitsTapCycleDoneFail.
  ///
  /// In en, this message translates to:
  /// **'Done → Not done → Clear'**
  String get habitsTapCycleDoneFail;

  /// No description provided for @habitsTapCycleDoneOnly.
  ///
  /// In en, this message translates to:
  /// **'Done → Clear'**
  String get habitsTapCycleDoneOnly;

  /// No description provided for @habitsTapCycleDoneSkip.
  ///
  /// In en, this message translates to:
  /// **'Done → Skip → Clear'**
  String get habitsTapCycleDoneSkip;

  /// No description provided for @habitsTemplatesChallenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get habitsTemplatesChallenges;

  /// No description provided for @habitsTemplatesHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitsTemplatesHabits;

  /// No description provided for @habitsTemplatesQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get habitsTemplatesQuit;

  /// No description provided for @habitsTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get habitsTemplatesTitle;

  /// No description provided for @habitsTimerElapsed.
  ///
  /// In en, this message translates to:
  /// **'Timer: {minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String habitsTimerElapsed(int minutes);

  /// No description provided for @habitsTimesPerDay.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Once a day} other{{n} times a day}}'**
  String habitsTimesPerDay(int n);

  /// No description provided for @habitsTimesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Once a month} =2{Twice a month} other{{n} times a month}}'**
  String habitsTimesPerMonth(int n);

  /// No description provided for @habitsTimesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Once a week} =2{Twice a week} other{{n} times a week}}'**
  String habitsTimesPerWeek(int n);

  /// No description provided for @habitsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get habitsToday;

  /// No description provided for @habitsToggleShortPress.
  ///
  /// In en, this message translates to:
  /// **'Toggle with a short press'**
  String get habitsToggleShortPress;

  /// No description provided for @habitsToggleShortPressHint.
  ///
  /// In en, this message translates to:
  /// **'Off: a long press toggles, a short press opens the day.'**
  String get habitsToggleShortPressHint;

  /// No description provided for @habitsTolerance.
  ///
  /// In en, this message translates to:
  /// **'Early check-in window'**
  String get habitsTolerance;

  /// No description provided for @habitsTotalOfTarget.
  ///
  /// In en, this message translates to:
  /// **'Total {total} of {target}'**
  String habitsTotalOfTarget(String total, String target);

  /// No description provided for @habitsTplChallengeMeditate.
  ///
  /// In en, this message translates to:
  /// **'14 days of meditation'**
  String get habitsTplChallengeMeditate;

  /// No description provided for @habitsTplChallengeMeditateDesc.
  ///
  /// In en, this message translates to:
  /// **'10 minutes a day for 14 days'**
  String get habitsTplChallengeMeditateDesc;

  /// No description provided for @habitsTplChallengeNoSugar.
  ///
  /// In en, this message translates to:
  /// **'21 days without sugar'**
  String get habitsTplChallengeNoSugar;

  /// No description provided for @habitsTplChallengeNoSugarDesc.
  ///
  /// In en, this message translates to:
  /// **'Every day for 21 days'**
  String get habitsTplChallengeNoSugarDesc;

  /// No description provided for @habitsTplChallengePushUps.
  ///
  /// In en, this message translates to:
  /// **'30 days of push-ups'**
  String get habitsTplChallengePushUps;

  /// No description provided for @habitsTplChallengePushUpsDesc.
  ///
  /// In en, this message translates to:
  /// **'20 reps a day for 30 days'**
  String get habitsTplChallengePushUpsDesc;

  /// No description provided for @habitsTplCoffeeLimit.
  ///
  /// In en, this message translates to:
  /// **'At most 2 coffees'**
  String get habitsTplCoffeeLimit;

  /// No description provided for @habitsTplCoffeeLimitDesc.
  ///
  /// In en, this message translates to:
  /// **'A daily limit'**
  String get habitsTplCoffeeLimitDesc;

  /// No description provided for @habitsTplGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get habitsTplGym;

  /// No description provided for @habitsTplGymDesc.
  ///
  /// In en, this message translates to:
  /// **'3 times a week, any days'**
  String get habitsTplGymDesc;

  /// No description provided for @habitsTplJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get habitsTplJournal;

  /// No description provided for @habitsTplJournalDesc.
  ///
  /// In en, this message translates to:
  /// **'Yes / no, every evening'**
  String get habitsTplJournalDesc;

  /// No description provided for @habitsTplMeditate.
  ///
  /// In en, this message translates to:
  /// **'Meditate'**
  String get habitsTplMeditate;

  /// No description provided for @habitsTplMeditateDesc.
  ///
  /// In en, this message translates to:
  /// **'10 minutes a day'**
  String get habitsTplMeditateDesc;

  /// No description provided for @habitsTplPushUps.
  ///
  /// In en, this message translates to:
  /// **'15 push-ups'**
  String get habitsTplPushUps;

  /// No description provided for @habitsTplPushUpsDesc.
  ///
  /// In en, this message translates to:
  /// **'Count ≥ 15 reps, every day'**
  String get habitsTplPushUpsDesc;

  /// No description provided for @habitsTplRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get habitsTplRead;

  /// No description provided for @habitsTplReadDesc.
  ///
  /// In en, this message translates to:
  /// **'20 minutes a day'**
  String get habitsTplReadDesc;

  /// No description provided for @habitsTplSleepEarly.
  ///
  /// In en, this message translates to:
  /// **'Sleep before 23:00'**
  String get habitsTplSleepEarly;

  /// No description provided for @habitsTplSleepEarlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Yes / no, every day'**
  String get habitsTplSleepEarlyDesc;

  /// No description provided for @habitsTplStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get habitsTplStretch;

  /// No description provided for @habitsTplStretchDesc.
  ///
  /// In en, this message translates to:
  /// **'Every hour 09:00–18:00 (6 of 10)'**
  String get habitsTplStretchDesc;

  /// No description provided for @habitsTplWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get habitsTplWalk;

  /// No description provided for @habitsTplWalkDesc.
  ///
  /// In en, this message translates to:
  /// **'5 km a day'**
  String get habitsTplWalkDesc;

  /// No description provided for @habitsTplWater.
  ///
  /// In en, this message translates to:
  /// **'Drink water'**
  String get habitsTplWater;

  /// No description provided for @habitsTplWaterDesc.
  ///
  /// In en, this message translates to:
  /// **'8 glasses a day'**
  String get habitsTplWaterDesc;

  /// No description provided for @habitsTypeBuild.
  ///
  /// In en, this message translates to:
  /// **'Build a habit'**
  String get habitsTypeBuild;

  /// No description provided for @habitsTypeQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit something'**
  String get habitsTypeQuit;

  /// No description provided for @habitsUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get habitsUnarchive;

  /// No description provided for @habitsUnarchivedSnack.
  ///
  /// In en, this message translates to:
  /// **'Habit restored'**
  String get habitsUnarchivedSnack;

  /// No description provided for @habitsUnitCigarettes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{cigarette} other{cigarettes}}'**
  String habitsUnitCigarettes(int count);

  /// No description provided for @habitsUnitCups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{cup} other{cups}}'**
  String habitsUnitCups(int count);

  /// No description provided for @habitsUnitCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get habitsUnitCustom;

  /// No description provided for @habitsUnitDrinks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{drink} other{drinks}}'**
  String habitsUnitDrinks(int count);

  /// No description provided for @habitsUnitGlasses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{glass} other{glasses}}'**
  String habitsUnitGlasses(int count);

  /// No description provided for @habitsUnitH.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get habitsUnitH;

  /// No description provided for @habitsUnitJoints.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{joint} other{joints}}'**
  String habitsUnitJoints(int count);

  /// No description provided for @habitsUnitKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get habitsUnitKcal;

  /// No description provided for @habitsUnitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get habitsUnitKm;

  /// No description provided for @habitsUnitL.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get habitsUnitL;

  /// No description provided for @habitsUnitMi.
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get habitsUnitMi;

  /// No description provided for @habitsUnitMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get habitsUnitMin;

  /// No description provided for @habitsUnitMl.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get habitsUnitMl;

  /// No description provided for @habitsUnitPages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{page} other{pages}}'**
  String habitsUnitPages(int count);

  /// No description provided for @habitsUnitReps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{rep} other{reps}}'**
  String habitsUnitReps(int count);

  /// No description provided for @habitsUnitServings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{serving} other{servings}}'**
  String habitsUnitServings(int count);

  /// No description provided for @habitsUnitSessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{session} other{sessions}}'**
  String habitsUnitSessions(int count);

  /// No description provided for @habitsUnitSteps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{step} other{steps}}'**
  String habitsUnitSteps(int count);

  /// No description provided for @habitsUnitTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{time} other{times}}'**
  String habitsUnitTimes(int count);

  /// No description provided for @habitsVacationIndefinitely.
  ///
  /// In en, this message translates to:
  /// **'Vacation mode is on'**
  String get habitsVacationIndefinitely;

  /// No description provided for @habitsVacationTitle.
  ///
  /// In en, this message translates to:
  /// **'Vacation mode'**
  String get habitsVacationTitle;

  /// No description provided for @habitsVacationUntil.
  ///
  /// In en, this message translates to:
  /// **'Vacation mode until {date}'**
  String habitsVacationUntil(String date);

  /// No description provided for @habitsValueHint.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get habitsValueHint;

  /// No description provided for @habitsValueInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number greater than 0'**
  String get habitsValueInvalid;

  /// No description provided for @habitsValueTitle.
  ///
  /// In en, this message translates to:
  /// **'Log a value'**
  String get habitsValueTitle;

  /// No description provided for @habitsViewMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get habitsViewMonth;

  /// No description provided for @habitsViewOptions.
  ///
  /// In en, this message translates to:
  /// **'View options'**
  String get habitsViewOptions;

  /// No description provided for @habitsViewToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get habitsViewToday;

  /// No description provided for @habitsViewWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get habitsViewWeek;

  /// No description provided for @habitsViewYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get habitsViewYear;

  /// No description provided for @habitsWarnManySlots.
  ///
  /// In en, this message translates to:
  /// **'{count} check-ins a day — that is a lot.'**
  String habitsWarnManySlots(int count);

  /// No description provided for @habitsWarnNeverDue.
  ///
  /// In en, this message translates to:
  /// **'This schedule has no upcoming day.'**
  String get habitsWarnNeverDue;

  /// No description provided for @habitsWeekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String habitsWeekOf(String date);

  /// No description provided for @habitsWindowFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get habitsWindowFrom;

  /// No description provided for @habitsWindowTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get habitsWindowTo;

  /// No description provided for @habitsYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get habitsYear;

  /// No description provided for @habitsYearSummary.
  ///
  /// In en, this message translates to:
  /// **'Done on {done} of {scheduled} scheduled days in {year}'**
  String habitsYearSummary(int done, int scheduled, String year);

  /// No description provided for @habitsZoneFixed.
  ///
  /// In en, this message translates to:
  /// **'Always use {zone}'**
  String habitsZoneFixed(String zone);

  /// No description provided for @habitsZoneFixedHint.
  ///
  /// In en, this message translates to:
  /// **'Days follow {zone} wherever you are'**
  String habitsZoneFixedHint(String zone);

  /// No description provided for @habitsZoneFloating.
  ///
  /// In en, this message translates to:
  /// **'Days follow your current time zone'**
  String get habitsZoneFloating;

  /// No description provided for @importAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importAction;

  /// No description provided for @importChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get importChooseFile;

  /// No description provided for @importConvertBody.
  ///
  /// In en, this message translates to:
  /// **'Convert note to items'**
  String get importConvertBody;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item imported} other{{count} items imported}}'**
  String importDone(int count);

  /// No description provided for @importItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String importItemsCount(int count);

  /// No description provided for @importKeepOne.
  ///
  /// In en, this message translates to:
  /// **'Keep as one item'**
  String get importKeepOne;

  /// No description provided for @importMoreLines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{…and 1 more item} other{…and {count} more items}}'**
  String importMoreLines(int count);

  /// No description provided for @importPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste indented text, Markdown or OPML'**
  String get importPasteHint;

  /// No description provided for @importSplit.
  ///
  /// In en, this message translates to:
  /// **'Split into items (keep nesting)'**
  String get importSplit;

  /// No description provided for @importSplitCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Split into 1 item (keep nesting)} other{Split into {count} items (keep nesting)}}'**
  String importSplitCount(int count);

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// No description provided for @importWarningAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachment references were skipped'**
  String get importWarningAttachments;

  /// No description provided for @importWarningEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to import'**
  String get importWarningEmpty;

  /// No description provided for @importWarningMalformed.
  ///
  /// In en, this message translates to:
  /// **'This file couldn\'t be read'**
  String get importWarningMalformed;

  /// No description provided for @importWarningTooMany.
  ///
  /// In en, this message translates to:
  /// **'Only the first 10 000 lines were imported'**
  String get importWarningTooMany;

  /// No description provided for @integrationsActionFailed.
  ///
  /// In en, this message translates to:
  /// **'That action couldn\'t be completed.'**
  String get integrationsActionFailed;

  /// No description provided for @integrationsHabitLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged: {habit}'**
  String integrationsHabitLogged(String habit);

  /// No description provided for @integrationsHabitNotFound.
  ///
  /// In en, this message translates to:
  /// **'No habit matches \"{name}\".'**
  String integrationsHabitNotFound(String name);

  /// No description provided for @integrationsLinkInTrash.
  ///
  /// In en, this message translates to:
  /// **'This item is in the Trash.'**
  String get integrationsLinkInTrash;

  /// No description provided for @integrationsLinkNotFound.
  ///
  /// In en, this message translates to:
  /// **'This link can\'t be opened in Everslot.'**
  String get integrationsLinkNotFound;

  /// No description provided for @integrationsNothingNext.
  ///
  /// In en, this message translates to:
  /// **'Nothing else is planned today.'**
  String get integrationsNothingNext;

  /// No description provided for @itemAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get itemAddTime;

  /// No description provided for @itemAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get itemAttachments;

  /// No description provided for @itemClearDue.
  ///
  /// In en, this message translates to:
  /// **'Remove due date'**
  String get itemClearDue;

  /// No description provided for @itemCompletedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String itemCompletedOn(String date);

  /// No description provided for @itemCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String itemCreated(String date);

  /// No description provided for @itemDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Item details'**
  String get itemDetailsTitle;

  /// No description provided for @itemDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get itemDue;

  /// No description provided for @itemDueOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get itemDueOverdue;

  /// No description provided for @itemDueToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get itemDueToday;

  /// No description provided for @itemDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get itemDueTomorrow;

  /// No description provided for @itemEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited {date}'**
  String itemEdited(String date);

  /// No description provided for @itemHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get itemHistory;

  /// No description provided for @itemHistoryCause.
  ///
  /// In en, this message translates to:
  /// **'automatic'**
  String get itemHistoryCause;

  /// No description provided for @itemHistoryDevice.
  ///
  /// In en, this message translates to:
  /// **'on {device}'**
  String itemHistoryDevice(String device);

  /// No description provided for @itemHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No status changes yet'**
  String get itemHistoryEmpty;

  /// No description provided for @itemHistoryTransition.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String itemHistoryTransition(String from, String to);

  /// No description provided for @itemInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get itemInsights;

  /// No description provided for @itemNoDue.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get itemNoDue;

  /// No description provided for @itemNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get itemNote;

  /// No description provided for @itemOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'another device'**
  String get itemOtherDevice;

  /// No description provided for @itemPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get itemPriority;

  /// No description provided for @itemText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get itemText;

  /// No description provided for @itemThisDevice.
  ///
  /// In en, this message translates to:
  /// **'this device'**
  String get itemThisDevice;

  /// No description provided for @itemTimeInStatus.
  ///
  /// In en, this message translates to:
  /// **'Time in status'**
  String get itemTimeInStatus;

  /// No description provided for @itemsColAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get itemsColAge;

  /// No description provided for @itemsColAttachments.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get itemsColAttachments;

  /// No description provided for @itemsColChecklist.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get itemsColChecklist;

  /// No description provided for @itemsColDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get itemsColDue;

  /// No description provided for @itemsColFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get itemsColFollowUp;

  /// No description provided for @itemsColPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get itemsColPath;

  /// No description provided for @itemsColPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get itemsColPriority;

  /// No description provided for @itemsColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get itemsColStatus;

  /// No description provided for @itemsColText.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemsColText;

  /// No description provided for @itemsTableEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items match'**
  String get itemsTableEmpty;

  /// No description provided for @itemsTableFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by text, list or path'**
  String get itemsTableFilterHint;

  /// No description provided for @itemsTableOpen.
  ///
  /// In en, this message translates to:
  /// **'All items (table)'**
  String get itemsTableOpen;

  /// No description provided for @itemsTableSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all shown items'**
  String get itemsTableSelectAll;

  /// No description provided for @itemsTableSelectRow.
  ///
  /// In en, this message translates to:
  /// **'Select {item}'**
  String itemsTableSelectRow(String item);

  /// No description provided for @itemsTableSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String itemsTableSelected(int count);

  /// No description provided for @itemsTableSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by {column}'**
  String itemsTableSortBy(String column);

  /// No description provided for @itemsTableStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item updated} other{{count} items updated}}'**
  String itemsTableStatusChanged(int count);

  /// No description provided for @itemsTableTitle.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get itemsTableTitle;

  /// No description provided for @kanbanAll.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get kanbanAll;

  /// No description provided for @kanbanChildren.
  ///
  /// In en, this message translates to:
  /// **'Direct sub-items'**
  String get kanbanChildren;

  /// No description provided for @kanbanEmptyColumn.
  ///
  /// In en, this message translates to:
  /// **'Drop items here'**
  String get kanbanEmptyColumn;

  /// No description provided for @kanbanLeaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves only'**
  String get kanbanLeaves;

  /// No description provided for @kanbanScope.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get kanbanScope;

  /// No description provided for @kanbanShowCancelled.
  ///
  /// In en, this message translates to:
  /// **'Show cancelled'**
  String get kanbanShowCancelled;

  /// No description provided for @listsAllLists.
  ///
  /// In en, this message translates to:
  /// **'All lists'**
  String get listsAllLists;

  /// No description provided for @listsArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get listsArchive;

  /// No description provided for @listsArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get listsArchiveAction;

  /// No description provided for @listsArchiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No archived lists'**
  String get listsArchiveEmpty;

  /// No description provided for @listsArchived.
  ///
  /// In en, this message translates to:
  /// **'List archived'**
  String get listsArchived;

  /// No description provided for @listsBadgeBlocked.
  ///
  /// In en, this message translates to:
  /// **'{count} blocked'**
  String listsBadgeBlocked(int count);

  /// No description provided for @listsBadgeStale.
  ///
  /// In en, this message translates to:
  /// **'{count} stale'**
  String listsBadgeStale(int count);

  /// No description provided for @listsBadgeWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String listsBadgeWaiting(int count);

  /// No description provided for @listsBoardSort.
  ///
  /// In en, this message translates to:
  /// **'Sort cards'**
  String get listsBoardSort;

  /// No description provided for @listsBoardSortManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get listsBoardSortManual;

  /// No description provided for @listsBoardSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently edited'**
  String get listsBoardSortRecent;

  /// No description provided for @listsBoardSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get listsBoardSortTitle;

  /// No description provided for @listsCardActions.
  ///
  /// In en, this message translates to:
  /// **'List actions'**
  String get listsCardActions;

  /// No description provided for @listsCardMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String listsCardMore(int count);

  /// No description provided for @listsCardProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total}'**
  String listsCardProgress(int done, int total);

  /// No description provided for @listsCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}, {progress}'**
  String listsCardSemantics(String title, String progress);

  /// No description provided for @listsColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get listsColor;

  /// No description provided for @listsCopyOf.
  ///
  /// In en, this message translates to:
  /// **'Copy of {title}'**
  String listsCopyOf(String title);

  /// No description provided for @listsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get listsDelete;

  /// No description provided for @listsDeleted.
  ///
  /// In en, this message translates to:
  /// **'List deleted'**
  String get listsDeleted;

  /// No description provided for @listsDragHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press and drag to reorder'**
  String get listsDragHint;

  /// No description provided for @listsDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get listsDuplicate;

  /// No description provided for @listsDuplicated.
  ///
  /// In en, this message translates to:
  /// **'List duplicated'**
  String get listsDuplicated;

  /// No description provided for @listsEditLabels.
  ///
  /// In en, this message translates to:
  /// **'Edit labels'**
  String get listsEditLabels;

  /// No description provided for @listsEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Create your first list'**
  String get listsEmptyAction;

  /// No description provided for @listsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Checklists, notes and routines — nested as deep as you need.'**
  String get listsEmptyMessage;

  /// No description provided for @listsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No lists yet'**
  String get listsEmptyTitle;

  /// No description provided for @listsFilterAnyLabel.
  ///
  /// In en, this message translates to:
  /// **'Any label'**
  String get listsFilterAnyLabel;

  /// No description provided for @listsFilterColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get listsFilterColor;

  /// No description provided for @listsFilterHasAttachments.
  ///
  /// In en, this message translates to:
  /// **'With attachments'**
  String get listsFilterHasAttachments;

  /// No description provided for @listsFilterHasBlocked.
  ///
  /// In en, this message translates to:
  /// **'Waiting or blocked'**
  String get listsFilterHasBlocked;

  /// No description provided for @listsFilterHasDue.
  ///
  /// In en, this message translates to:
  /// **'With due dates'**
  String get listsFilterHasDue;

  /// No description provided for @listsFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get listsFilterLabel;

  /// No description provided for @listsFilterPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get listsFilterPinned;

  /// No description provided for @listsFilterRepeating.
  ///
  /// In en, this message translates to:
  /// **'Repeating'**
  String get listsFilterRepeating;

  /// No description provided for @listsFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'From template'**
  String get listsFromTemplate;

  /// No description provided for @listsGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get listsGridView;

  /// No description provided for @listsImportFile.
  ///
  /// In en, this message translates to:
  /// **'Import file…'**
  String get listsImportFile;

  /// No description provided for @listsLabelFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Showing lists labelled {label}'**
  String listsLabelFilterActive(String label);

  /// No description provided for @listsLabelSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count, plural, =0{no lists} =1{1 list} other{{count} lists}}'**
  String listsLabelSemantics(String label, int count);

  /// No description provided for @listsListView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listsListView;

  /// No description provided for @listsMoveItems.
  ///
  /// In en, this message translates to:
  /// **'Move items…'**
  String get listsMoveItems;

  /// No description provided for @listsNewChecklist.
  ///
  /// In en, this message translates to:
  /// **'New checklist'**
  String get listsNewChecklist;

  /// No description provided for @listsNewNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get listsNewNote;

  /// No description provided for @listsNoLabels.
  ///
  /// In en, this message translates to:
  /// **'No labels yet'**
  String get listsNoLabels;

  /// No description provided for @listsOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get listsOthers;

  /// No description provided for @listsPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get listsPin;

  /// No description provided for @listsPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get listsPinned;

  /// No description provided for @listsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Lists settings'**
  String get listsPreferences;

  /// No description provided for @listsRepeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get listsRepeats;

  /// No description provided for @listsResetStatusesOption.
  ///
  /// In en, this message translates to:
  /// **'Reset all statuses to to-do'**
  String get listsResetStatusesOption;

  /// No description provided for @listsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search lists'**
  String get listsSearchHint;

  /// No description provided for @listsSearchItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get listsSearchItems;

  /// No description provided for @listsSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching lists or items'**
  String get listsSearchNoResults;

  /// No description provided for @listsShowBody.
  ///
  /// In en, this message translates to:
  /// **'Show note text on cards'**
  String get listsShowBody;

  /// No description provided for @listsShowSmartChips.
  ///
  /// In en, this message translates to:
  /// **'Show waiting / blocked chips'**
  String get listsShowSmartChips;

  /// No description provided for @listsTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get listsTemplates;

  /// No description provided for @listsTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get listsTrash;

  /// No description provided for @listsUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get listsUnarchive;

  /// No description provided for @listsUnarchived.
  ///
  /// In en, this message translates to:
  /// **'List restored from archive'**
  String get listsUnarchived;

  /// No description provided for @listsUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get listsUnpin;

  /// No description provided for @listsUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get listsUntitled;

  /// No description provided for @localOnlyBanner.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync isn\'t configured — your data stays on this device.'**
  String get localOnlyBanner;

  /// No description provided for @mindMapExport.
  ///
  /// In en, this message translates to:
  /// **'Export as image'**
  String get mindMapExport;

  /// No description provided for @mindMapHidden.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String mindMapHidden(int count);

  /// No description provided for @moveChooseParent.
  ///
  /// In en, this message translates to:
  /// **'Choose where'**
  String get moveChooseParent;

  /// No description provided for @moveDone.
  ///
  /// In en, this message translates to:
  /// **'Moved to {title}'**
  String moveDone(String title);

  /// No description provided for @moveToList.
  ///
  /// In en, this message translates to:
  /// **'Move to list'**
  String get moveToList;

  /// No description provided for @moveToTop.
  ///
  /// In en, this message translates to:
  /// **'Top level'**
  String get moveToTop;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notifActionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get notifActionComplete;

  /// No description provided for @notifActionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get notifActionDone;

  /// No description provided for @notifActionInputPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get notifActionInputPlaceholder;

  /// No description provided for @notifActionLogCraving.
  ///
  /// In en, this message translates to:
  /// **'Log craving'**
  String get notifActionLogCraving;

  /// No description provided for @notifActionLogValue.
  ///
  /// In en, this message translates to:
  /// **'Log value'**
  String get notifActionLogValue;

  /// No description provided for @notifActionMarkBlocked.
  ///
  /// In en, this message translates to:
  /// **'Mark blocked'**
  String get notifActionMarkBlocked;

  /// No description provided for @notifActionMarkOngoing.
  ///
  /// In en, this message translates to:
  /// **'Mark ongoing'**
  String get notifActionMarkOngoing;

  /// No description provided for @notifActionMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get notifActionMarkRead;

  /// No description provided for @notifActionMarkWaiting.
  ///
  /// In en, this message translates to:
  /// **'Mark waiting'**
  String get notifActionMarkWaiting;

  /// No description provided for @notifActionMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get notifActionMute;

  /// No description provided for @notifActionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notifActionOpen;

  /// No description provided for @notifActionReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get notifActionReschedule;

  /// No description provided for @notifActionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get notifActionSend;

  /// No description provided for @notifActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get notifActionSkip;

  /// No description provided for @notifActionSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get notifActionSnooze;

  /// No description provided for @notifActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get notifActionStart;

  /// No description provided for @notifActionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get notifActionStop;

  /// No description provided for @notifActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get notifActions;

  /// No description provided for @notifAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get notifAddReminder;

  /// No description provided for @notifAdjCatchUp.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get notifAdjCatchUp;

  /// No description provided for @notifAdjDeferred.
  ///
  /// In en, this message translates to:
  /// **'Deferred (quiet hours)'**
  String get notifAdjDeferred;

  /// No description provided for @notifAdjNotLocal.
  ///
  /// In en, this message translates to:
  /// **'Delivered on another device'**
  String get notifAdjNotLocal;

  /// No description provided for @notifAdjPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused — inbox only'**
  String get notifAdjPaused;

  /// No description provided for @notifAdjShifted.
  ///
  /// In en, this message translates to:
  /// **'Moved into the time window'**
  String get notifAdjShifted;

  /// No description provided for @notifAdjSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent (quiet hours)'**
  String get notifAdjSilent;

  /// No description provided for @notifAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced…'**
  String get notifAdvanced;

  /// No description provided for @notifAdvancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder rule'**
  String get notifAdvancedTitle;

  /// No description provided for @notifAfter.
  ///
  /// In en, this message translates to:
  /// **'after'**
  String get notifAfter;

  /// No description provided for @notifAllowPrecise.
  ///
  /// In en, this message translates to:
  /// **'Allow precise reminders'**
  String get notifAllowPrecise;

  /// No description provided for @notifAnchorDue.
  ///
  /// In en, this message translates to:
  /// **'due'**
  String get notifAnchorDue;

  /// No description provided for @notifAnchorEnd.
  ///
  /// In en, this message translates to:
  /// **'end'**
  String get notifAnchorEnd;

  /// No description provided for @notifAnchorFollowUp.
  ///
  /// In en, this message translates to:
  /// **'follow-up'**
  String get notifAnchorFollowUp;

  /// No description provided for @notifAnchorPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'period end'**
  String get notifAnchorPeriodEnd;

  /// No description provided for @notifAnchorPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'period start'**
  String get notifAnchorPeriodStart;

  /// No description provided for @notifAnchorSlot.
  ///
  /// In en, this message translates to:
  /// **'slot'**
  String get notifAnchorSlot;

  /// No description provided for @notifAnchorStart.
  ///
  /// In en, this message translates to:
  /// **'start'**
  String get notifAnchorStart;

  /// No description provided for @notifAndroidLabel.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get notifAndroidLabel;

  /// No description provided for @notifBadgeDue.
  ///
  /// In en, this message translates to:
  /// **'Overdue + due today'**
  String get notifBadgeDue;

  /// No description provided for @notifBadgeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifBadgeOff;

  /// No description provided for @notifBadgePolicy.
  ///
  /// In en, this message translates to:
  /// **'App icon badge'**
  String get notifBadgePolicy;

  /// No description provided for @notifBadgeUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread inbox'**
  String get notifBadgeUnread;

  /// No description provided for @notifBannerCollapsed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reminder} other{{count} reminders}}'**
  String notifBannerCollapsed(int count);

  /// No description provided for @notifBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get notifBannerDismiss;

  /// No description provided for @notifBannerInApp.
  ///
  /// In en, this message translates to:
  /// **'In-app banners'**
  String get notifBannerInApp;

  /// No description provided for @notifBannerToggle.
  ///
  /// In en, this message translates to:
  /// **'In-app banner'**
  String get notifBannerToggle;

  /// No description provided for @notifBefore.
  ///
  /// In en, this message translates to:
  /// **'before'**
  String get notifBefore;

  /// No description provided for @notifBodyChildOverdue.
  ///
  /// In en, this message translates to:
  /// **'A sub-item is overdue'**
  String get notifBodyChildOverdue;

  /// No description provided for @notifBodyChildrenComplete.
  ///
  /// In en, this message translates to:
  /// **'All sub-items are done — complete it?'**
  String get notifBodyChildrenComplete;

  /// No description provided for @notifBodyCleanDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}} free — well done!'**
  String notifBodyCleanDays(int days);

  /// No description provided for @notifBodyDueIn.
  ///
  /// In en, this message translates to:
  /// **'Due in {minutes, plural, =1{1 min} other{{minutes} min}}'**
  String notifBodyDueIn(int minutes);

  /// No description provided for @notifBodyDueNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get notifBodyDueNow;

  /// No description provided for @notifBodyEndedAgo.
  ///
  /// In en, this message translates to:
  /// **'Ended {minutes, plural, =1{1 min} other{{minutes} min}} ago'**
  String notifBodyEndedAgo(int minutes);

  /// No description provided for @notifBodyEndingNow.
  ///
  /// In en, this message translates to:
  /// **'Ending now'**
  String get notifBodyEndingNow;

  /// No description provided for @notifBodyEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Ends in {minutes, plural, =1{1 min} other{{minutes} min}}'**
  String notifBodyEndsIn(int minutes);

  /// No description provided for @notifBodyInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days, plural, =1{1 day} other{{days} days}} · {date}'**
  String notifBodyInDays(int days, String date);

  /// No description provided for @notifBodyInactivity.
  ///
  /// In en, this message translates to:
  /// **'No activity for {days, plural, =1{1 day} other{{days} days}}'**
  String notifBodyInactivity(int days);

  /// No description provided for @notifBodyMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone reached: {label}'**
  String notifBodyMilestone(String label);

  /// No description provided for @notifBodyNotDone.
  ///
  /// In en, this message translates to:
  /// **'You haven’t logged {title} today'**
  String notifBodyNotDone(String title);

  /// No description provided for @notifBodyOverdue.
  ///
  /// In en, this message translates to:
  /// **'{title} is overdue'**
  String notifBodyOverdue(String title);

  /// No description provided for @notifBodyQuotaBehind.
  ///
  /// In en, this message translates to:
  /// **'{done}/{target} done — {remaining} to go'**
  String notifBodyQuotaBehind(String done, String target, int remaining);

  /// No description provided for @notifBodySnoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed reminder'**
  String get notifBodySnoozed;

  /// No description provided for @notifBodyStartedAgo.
  ///
  /// In en, this message translates to:
  /// **'Started {minutes, plural, =1{1 min} other{{minutes} min}} ago'**
  String notifBodyStartedAgo(int minutes);

  /// No description provided for @notifBodyStartingNow.
  ///
  /// In en, this message translates to:
  /// **'Starting now'**
  String get notifBodyStartingNow;

  /// No description provided for @notifBodyStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {minutes, plural, =1{1 min} other{{minutes} min}}'**
  String notifBodyStartsIn(int minutes);

  /// No description provided for @notifBodyStatusAge.
  ///
  /// In en, this message translates to:
  /// **'Still {status} · {age}'**
  String notifBodyStatusAge(String status, String age);

  /// No description provided for @notifBodyStatusChange.
  ///
  /// In en, this message translates to:
  /// **'Now {status}'**
  String notifBodyStatusChange(String status);

  /// No description provided for @notifBodyStreakRisk.
  ///
  /// In en, this message translates to:
  /// **'Keep your {days, plural, =1{1-day} other{{days}-day}} streak alive'**
  String notifBodyStreakRisk(int days);

  /// No description provided for @notifBodyTest.
  ///
  /// In en, this message translates to:
  /// **'Test notification from Everslot'**
  String get notifBodyTest;

  /// No description provided for @notifBodyTimeFor.
  ///
  /// In en, this message translates to:
  /// **'Time for {title}'**
  String notifBodyTimeFor(String title);

  /// No description provided for @notifBodyToday.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String notifBodyToday(String date);

  /// No description provided for @notifCategoryDigest.
  ///
  /// In en, this message translates to:
  /// **'Digest'**
  String get notifCategoryDigest;

  /// No description provided for @notifCategoryMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get notifCategoryMilestone;

  /// No description provided for @notifCategoryNag.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get notifCategoryNag;

  /// No description provided for @notifCategoryReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get notifCategoryReminder;

  /// No description provided for @notifCategoryStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get notifCategoryStreak;

  /// No description provided for @notifCategorySystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notifCategorySystem;

  /// No description provided for @notifChannelBlocked.
  ///
  /// In en, this message translates to:
  /// **'Some notification categories are blocked'**
  String get notifChannelBlocked;

  /// No description provided for @notifChannelDigest.
  ///
  /// In en, this message translates to:
  /// **'Digests'**
  String get notifChannelDigest;

  /// No description provided for @notifChannelForeground.
  ///
  /// In en, this message translates to:
  /// **'While Everslot is open'**
  String get notifChannelForeground;

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'{section} · {profile}'**
  String notifChannelName(String section, String profile);

  /// No description provided for @notifChannelQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notifChannelQuiet;

  /// No description provided for @notifChannelSystem.
  ///
  /// In en, this message translates to:
  /// **'System notices'**
  String get notifChannelSystem;

  /// No description provided for @notifChipAtDue.
  ///
  /// In en, this message translates to:
  /// **'At due'**
  String get notifChipAtDue;

  /// No description provided for @notifChipAtEnd.
  ///
  /// In en, this message translates to:
  /// **'At end'**
  String get notifChipAtEnd;

  /// No description provided for @notifChipAtFollowUp.
  ///
  /// In en, this message translates to:
  /// **'At follow-up'**
  String get notifChipAtFollowUp;

  /// No description provided for @notifChipAtSlot.
  ///
  /// In en, this message translates to:
  /// **'At slot time'**
  String get notifChipAtSlot;

  /// No description provided for @notifChipAtStart.
  ///
  /// In en, this message translates to:
  /// **'At start'**
  String get notifChipAtStart;

  /// No description provided for @notifChipAtTime.
  ///
  /// In en, this message translates to:
  /// **'At a time…'**
  String get notifChipAtTime;

  /// No description provided for @notifChipBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 min before} other{{minutes} min before}}'**
  String notifChipBefore(int minutes);

  /// No description provided for @notifChipChangeTime.
  ///
  /// In en, this message translates to:
  /// **'Change the time'**
  String get notifChipChangeTime;

  /// No description provided for @notifChipCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get notifChipCustom;

  /// No description provided for @notifChipDayBeforeAt.
  ///
  /// In en, this message translates to:
  /// **'1 day before at {time}'**
  String notifChipDayBeforeAt(String time);

  /// No description provided for @notifChipEvery.
  ///
  /// In en, this message translates to:
  /// **'Every day at…'**
  String get notifChipEvery;

  /// No description provided for @notifChipIfNotDoneBy.
  ///
  /// In en, this message translates to:
  /// **'If not done by…'**
  String get notifChipIfNotDoneBy;

  /// No description provided for @notifChipLastDayAt.
  ///
  /// In en, this message translates to:
  /// **'On the last day at {time}'**
  String notifChipLastDayAt(String time);

  /// No description provided for @notifChipMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get notifChipMilestones;

  /// No description provided for @notifChipOnDayAt.
  ///
  /// In en, this message translates to:
  /// **'On the day at {time}'**
  String notifChipOnDayAt(String time);

  /// No description provided for @notifChipRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat…'**
  String get notifChipRepeat;

  /// No description provided for @notifChipStreakRisk.
  ///
  /// In en, this message translates to:
  /// **'Streak at risk'**
  String get notifChipStreakRisk;

  /// No description provided for @notifConditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get notifConditions;

  /// No description provided for @notifContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get notifContent;

  /// No description provided for @notifContentBody.
  ///
  /// In en, this message translates to:
  /// **'Body template'**
  String get notifContentBody;

  /// No description provided for @notifContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Title template'**
  String get notifContentTitle;

  /// No description provided for @notifCreateCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 reminder} other{Add {count} reminders}}'**
  String notifCreateCount(int count);

  /// No description provided for @notifCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get notifCustomize;

  /// No description provided for @notifDateOnlyTime.
  ///
  /// In en, this message translates to:
  /// **'Default time for date-only items'**
  String get notifDateOnlyTime;

  /// No description provided for @notifDefaultLateness.
  ///
  /// In en, this message translates to:
  /// **'Deliver late reminders up to'**
  String get notifDefaultLateness;

  /// No description provided for @notifDefaultProfile.
  ///
  /// In en, this message translates to:
  /// **'Default profile'**
  String get notifDefaultProfile;

  /// No description provided for @notifDefaultsAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category defaults'**
  String get notifDefaultsAddCategory;

  /// No description provided for @notifDefaultsAllDay.
  ///
  /// In en, this message translates to:
  /// **'All-day items'**
  String get notifDefaultsAllDay;

  /// No description provided for @notifDefaultsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category defaults'**
  String get notifDefaultsCategory;

  /// No description provided for @notifDefaultsDateOnly.
  ///
  /// In en, this message translates to:
  /// **'Date-only items'**
  String get notifDefaultsDateOnly;

  /// No description provided for @notifDefaultsEntry.
  ///
  /// In en, this message translates to:
  /// **'Default reminders'**
  String get notifDefaultsEntry;

  /// No description provided for @notifDefaultsOther.
  ///
  /// In en, this message translates to:
  /// **'Other defaults'**
  String get notifDefaultsOther;

  /// No description provided for @notifDefaultsTimed.
  ///
  /// In en, this message translates to:
  /// **'Timed items'**
  String get notifDefaultsTimed;

  /// No description provided for @notifDefaultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Default reminders'**
  String get notifDefaultsTitle;

  /// No description provided for @notifDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get notifDelivery;

  /// No description provided for @notifDeviceAll.
  ///
  /// In en, this message translates to:
  /// **'All devices'**
  String get notifDeviceAll;

  /// No description provided for @notifDeviceLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active device'**
  String get notifDeviceLastActive;

  /// No description provided for @notifDevicePrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary device only'**
  String get notifDevicePrimary;

  /// No description provided for @notifDiagBadge.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get notifDiagBadge;

  /// No description provided for @notifDiagBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization'**
  String get notifDiagBattery;

  /// No description provided for @notifDiagBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'Some phones stop apps in the background. Follow the guide for your phone to keep reminders on time.'**
  String get notifDiagBatteryBody;

  /// No description provided for @notifDiagBatteryOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the guide for {maker}'**
  String notifDiagBatteryOpen(String maker);

  /// No description provided for @notifDiagBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked channels'**
  String get notifDiagBlocked;

  /// No description provided for @notifDiagBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget {used}/{total}'**
  String notifDiagBudget(int used, int total);

  /// No description provided for @notifDiagCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get notifDiagCapabilities;

  /// No description provided for @notifDiagCopied.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied (no content included)'**
  String get notifDiagCopied;

  /// No description provided for @notifDiagCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get notifDiagCopy;

  /// No description provided for @notifDiagCoverage.
  ///
  /// In en, this message translates to:
  /// **'Covered until'**
  String get notifDiagCoverage;

  /// No description provided for @notifDiagExact.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms'**
  String get notifDiagExact;

  /// No description provided for @notifDiagLastReplan.
  ///
  /// In en, this message translates to:
  /// **'Last replan'**
  String get notifDiagLastReplan;

  /// No description provided for @notifDiagMismatch.
  ///
  /// In en, this message translates to:
  /// **'Mismatches between the system and the schedule: {count}'**
  String notifDiagMismatch(int count);

  /// No description provided for @notifDiagNext.
  ///
  /// In en, this message translates to:
  /// **'Next firings'**
  String get notifDiagNext;

  /// No description provided for @notifDiagPendingOs.
  ///
  /// In en, this message translates to:
  /// **'Pending in the system'**
  String get notifDiagPendingOs;

  /// No description provided for @notifDiagPermission.
  ///
  /// In en, this message translates to:
  /// **'Notifications allowed'**
  String get notifDiagPermission;

  /// No description provided for @notifDiagProvisional.
  ///
  /// In en, this message translates to:
  /// **'Provisional (quiet) delivery'**
  String get notifDiagProvisional;

  /// No description provided for @notifDiagPush.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get notifDiagPush;

  /// No description provided for @notifDiagPushOff.
  ///
  /// In en, this message translates to:
  /// **'Push not configured — local reminders only'**
  String get notifDiagPushOff;

  /// No description provided for @notifDiagPushOn.
  ///
  /// In en, this message translates to:
  /// **'Push active'**
  String get notifDiagPushOn;

  /// No description provided for @notifDiagReplanInfo.
  ///
  /// In en, this message translates to:
  /// **'{time} · {ms} ms · {reason}'**
  String notifDiagReplanInfo(String time, int ms, String reason);

  /// No description provided for @notifDiagReplanNow.
  ///
  /// In en, this message translates to:
  /// **'Replan now'**
  String get notifDiagReplanNow;

  /// No description provided for @notifDiagSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get notifDiagSchedule;

  /// No description provided for @notifDiagTimeSensitive.
  ///
  /// In en, this message translates to:
  /// **'Time sensitive'**
  String get notifDiagTimeSensitive;

  /// No description provided for @notifDiagTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification diagnostics'**
  String get notifDiagTitle;

  /// No description provided for @notifDiagTracked.
  ///
  /// In en, this message translates to:
  /// **'Tracked (inbox only or over budget)'**
  String get notifDiagTracked;

  /// No description provided for @notifDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get notifDiagnostics;

  /// No description provided for @notifDigestAt.
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String notifDigestAt(String time);

  /// No description provided for @notifDigestDailyAgenda.
  ///
  /// In en, this message translates to:
  /// **'Today’s agenda'**
  String get notifDigestDailyAgenda;

  /// No description provided for @notifDigestEveningReview.
  ///
  /// In en, this message translates to:
  /// **'Evening review'**
  String get notifDigestEveningReview;

  /// No description provided for @notifDigestFirst.
  ///
  /// In en, this message translates to:
  /// **'First: {first}'**
  String notifDigestFirst(String first);

  /// No description provided for @notifDigestMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly report'**
  String get notifDigestMonthly;

  /// No description provided for @notifDigestOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue summary'**
  String get notifDigestOverdue;

  /// No description provided for @notifDigestPlanTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Plan tomorrow'**
  String get notifDigestPlanTomorrow;

  /// No description provided for @notifDigestSummary.
  ///
  /// In en, this message translates to:
  /// **'{tasks, plural, =1{1 task} other{{tasks} tasks}} · {habits, plural, =1{1 habit} other{{habits} habits}} · {items, plural, =1{1 list item} other{{items} list items}}'**
  String notifDigestSummary(int tasks, int habits, int items);

  /// No description provided for @notifDigestWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly review'**
  String get notifDigestWeekly;

  /// No description provided for @notifDigests.
  ///
  /// In en, this message translates to:
  /// **'Digests'**
  String get notifDigests;

  /// No description provided for @notifDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get notifDisable;

  /// No description provided for @notifEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get notifEditorTitle;

  /// No description provided for @notifEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get notifEnable;

  /// No description provided for @notifExactOff.
  ///
  /// In en, this message translates to:
  /// **'Reminders may arrive up to an hour late'**
  String get notifExactOff;

  /// No description provided for @notifExactOffBody.
  ///
  /// In en, this message translates to:
  /// **'Allow precise reminders so they fire at the exact minute.'**
  String get notifExactOffBody;

  /// No description provided for @notifFieldAfterDays.
  ///
  /// In en, this message translates to:
  /// **'After (days)'**
  String get notifFieldAfterDays;

  /// No description provided for @notifFieldAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'After (minutes)'**
  String get notifFieldAfterMinutes;

  /// No description provided for @notifFieldAtTime.
  ///
  /// In en, this message translates to:
  /// **'At time'**
  String get notifFieldAtTime;

  /// No description provided for @notifFieldDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get notifFieldDateTime;

  /// No description provided for @notifFieldDayForm.
  ///
  /// In en, this message translates to:
  /// **'N days before or after at a time'**
  String get notifFieldDayForm;

  /// No description provided for @notifFieldDayOffset.
  ///
  /// In en, this message translates to:
  /// **'Days (negative = before)'**
  String get notifFieldDayOffset;

  /// No description provided for @notifFieldDigestKind.
  ///
  /// In en, this message translates to:
  /// **'Digest'**
  String get notifFieldDigestKind;

  /// No description provided for @notifFieldEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every (minutes)'**
  String get notifFieldEveryMinutes;

  /// No description provided for @notifFieldMaxTimes.
  ///
  /// In en, this message translates to:
  /// **'At most (times)'**
  String get notifFieldMaxTimes;

  /// No description provided for @notifFieldMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get notifFieldMetric;

  /// No description provided for @notifFieldMinStreak.
  ///
  /// In en, this message translates to:
  /// **'Minimum streak'**
  String get notifFieldMinStreak;

  /// No description provided for @notifFieldOffset.
  ///
  /// In en, this message translates to:
  /// **'Offset in minutes (negative = before)'**
  String get notifFieldOffset;

  /// No description provided for @notifFieldRepeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get notifFieldRepeats;

  /// No description provided for @notifFieldStatuses.
  ///
  /// In en, this message translates to:
  /// **'Statuses'**
  String get notifFieldStatuses;

  /// No description provided for @notifFieldThresholds.
  ///
  /// In en, this message translates to:
  /// **'Thresholds (comma separated, empty = automatic)'**
  String get notifFieldThresholds;

  /// No description provided for @notifFieldToStatus.
  ///
  /// In en, this message translates to:
  /// **'New status'**
  String get notifFieldToStatus;

  /// No description provided for @notifFieldUntil.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get notifFieldUntil;

  /// No description provided for @notifFreqDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get notifFreqDaily;

  /// No description provided for @notifFreqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get notifFreqMonthly;

  /// No description provided for @notifFreqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get notifFreqWeekly;

  /// No description provided for @notifFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get notifFrom;

  /// No description provided for @notifHideContent.
  ///
  /// In en, this message translates to:
  /// **'Hide content in notifications'**
  String get notifHideContent;

  /// No description provided for @notifImpact.
  ///
  /// In en, this message translates to:
  /// **'Affects {count, plural, =1{1 item} other{{count} items}} that use defaults'**
  String notifImpact(int count);

  /// No description provided for @notifImportance.
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get notifImportance;

  /// No description provided for @notifImportanceDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get notifImportanceDefault;

  /// No description provided for @notifImportanceHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get notifImportanceHigh;

  /// No description provided for @notifImportanceLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get notifImportanceLow;

  /// No description provided for @notifImportanceMin.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get notifImportanceMin;

  /// No description provided for @notifImportanceUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get notifImportanceUrgent;

  /// No description provided for @notifInboxAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'Already done'**
  String get notifInboxAlreadyDone;

  /// No description provided for @notifInboxCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get notifInboxCaughtUp;

  /// No description provided for @notifInboxChangeSnooze.
  ///
  /// In en, this message translates to:
  /// **'Change snooze'**
  String get notifInboxChangeSnooze;

  /// No description provided for @notifInboxDismissSelected.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get notifInboxDismissSelected;

  /// No description provided for @notifInboxDismissed.
  ///
  /// In en, this message translates to:
  /// **'Notification dismissed'**
  String get notifInboxDismissed;

  /// No description provided for @notifInboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifInboxEmpty;

  /// No description provided for @notifInboxEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Reminders you receive appear here.'**
  String get notifInboxEmptyBody;

  /// No description provided for @notifInboxFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notifInboxFilterAll;

  /// No description provided for @notifInboxFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notifInboxFilterUnread;

  /// No description provided for @notifInboxHistory.
  ///
  /// In en, this message translates to:
  /// **'Reminder history'**
  String get notifInboxHistory;

  /// No description provided for @notifInboxHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get notifInboxHistoryEmpty;

  /// No description provided for @notifInboxLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get notifInboxLate;

  /// No description provided for @notifInboxMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifInboxMarkAllRead;

  /// No description provided for @notifInboxMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'Marked as read'**
  String get notifInboxMarkedRead;

  /// No description provided for @notifInboxMarkedUnread.
  ///
  /// In en, this message translates to:
  /// **'Marked as unread'**
  String get notifInboxMarkedUnread;

  /// No description provided for @notifInboxMuteRule.
  ///
  /// In en, this message translates to:
  /// **'Mute this reminder'**
  String get notifInboxMuteRule;

  /// No description provided for @notifInboxNagCount.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String notifInboxNagCount(int count);

  /// No description provided for @notifInboxRemindAgain.
  ///
  /// In en, this message translates to:
  /// **'Remind me again…'**
  String get notifInboxRemindAgain;

  /// No description provided for @notifInboxSearch.
  ///
  /// In en, this message translates to:
  /// **'Search notifications'**
  String get notifInboxSearch;

  /// No description provided for @notifInboxSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String notifInboxSelected(int count);

  /// No description provided for @notifInboxSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get notifInboxSnoozed;

  /// No description provided for @notifInboxSnoozedUntil.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {time}'**
  String notifInboxSnoozedUntil(String time);

  /// No description provided for @notifInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get notifInboxTitle;

  /// No description provided for @notifInboxToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notifInboxToday;

  /// No description provided for @notifInboxToggle.
  ///
  /// In en, this message translates to:
  /// **'Show in inbox'**
  String get notifInboxToggle;

  /// No description provided for @notifInboxUnreadSemantics.
  ///
  /// In en, this message translates to:
  /// **'Unread reminder, {title}'**
  String notifInboxUnreadSemantics(String title);

  /// No description provided for @notifInboxWakeNow.
  ///
  /// In en, this message translates to:
  /// **'Wake now'**
  String get notifInboxWakeNow;

  /// No description provided for @notifInboxYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notifInboxYesterday;

  /// No description provided for @notifInherit.
  ///
  /// In en, this message translates to:
  /// **'Inherit'**
  String get notifInherit;

  /// No description provided for @notifInheritedFrom.
  ///
  /// In en, this message translates to:
  /// **'From {source}'**
  String notifInheritedFrom(String source);

  /// No description provided for @notifInheritedFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Inherited from {name}'**
  String notifInheritedFromProfile(String name);

  /// No description provided for @notifInterruption.
  ///
  /// In en, this message translates to:
  /// **'Interruption level (iOS)'**
  String get notifInterruption;

  /// No description provided for @notifInterruptionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get notifInterruptionActive;

  /// No description provided for @notifInterruptionPassive.
  ///
  /// In en, this message translates to:
  /// **'Passive'**
  String get notifInterruptionPassive;

  /// No description provided for @notifInterruptionTimeSensitive.
  ///
  /// In en, this message translates to:
  /// **'Time sensitive'**
  String get notifInterruptionTimeSensitive;

  /// No description provided for @notifIosLabel.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get notifIosLabel;

  /// No description provided for @notifIssueAnchorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This anchor isn’t available for this item'**
  String get notifIssueAnchorUnavailable;

  /// No description provided for @notifIssueEmptyContent.
  ///
  /// In en, this message translates to:
  /// **'The title can’t be empty'**
  String get notifIssueEmptyContent;

  /// No description provided for @notifIssueLateness.
  ///
  /// In en, this message translates to:
  /// **'Lateness must be at least 1 minute'**
  String get notifIssueLateness;

  /// No description provided for @notifIssueNoChannel.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one way to be notified'**
  String get notifIssueNoChannel;

  /// No description provided for @notifIssueOffsetOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'The offset must be within 30 days'**
  String get notifIssueOffsetOutOfRange;

  /// No description provided for @notifIssueRepeatInterval.
  ///
  /// In en, this message translates to:
  /// **'Repeat at least every minute'**
  String get notifIssueRepeatInterval;

  /// No description provided for @notifIssueRepeatMax.
  ///
  /// In en, this message translates to:
  /// **'At most 10 repeats'**
  String get notifIssueRepeatMax;

  /// No description provided for @notifIssueSchedule.
  ///
  /// In en, this message translates to:
  /// **'Invalid schedule'**
  String get notifIssueSchedule;

  /// No description provided for @notifIssueStatuses.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one status'**
  String get notifIssueStatuses;

  /// No description provided for @notifIssueThresholds.
  ///
  /// In en, this message translates to:
  /// **'Invalid thresholds'**
  String get notifIssueThresholds;

  /// No description provided for @notifIssueTooManyActions.
  ///
  /// In en, this message translates to:
  /// **'Android shows only the first 3 actions'**
  String get notifIssueTooManyActions;

  /// No description provided for @notifIssueUnknownTrigger.
  ///
  /// In en, this message translates to:
  /// **'This rule type isn’t supported by this version'**
  String get notifIssueUnknownTrigger;

  /// No description provided for @notifIssueUnknownVariable.
  ///
  /// In en, this message translates to:
  /// **'Unknown variable: {names}'**
  String notifIssueUnknownVariable(String names);

  /// No description provided for @notifItemKind.
  ///
  /// In en, this message translates to:
  /// **'Item kind'**
  String get notifItemKind;

  /// No description provided for @notifItemKindAllDay.
  ///
  /// In en, this message translates to:
  /// **'All-day'**
  String get notifItemKindAllDay;

  /// No description provided for @notifItemKindAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get notifItemKindAny;

  /// No description provided for @notifItemKindDateOnly.
  ///
  /// In en, this message translates to:
  /// **'Date only'**
  String get notifItemKindDateOnly;

  /// No description provided for @notifItemKindTimed.
  ///
  /// In en, this message translates to:
  /// **'Timed'**
  String get notifItemKindTimed;

  /// No description provided for @notifLateness.
  ///
  /// In en, this message translates to:
  /// **'Still deliver if late by up to (minutes)'**
  String get notifLateness;

  /// No description provided for @notifMakePrimary.
  ///
  /// In en, this message translates to:
  /// **'Use this device as primary'**
  String get notifMakePrimary;

  /// No description provided for @notifMaxNag.
  ///
  /// In en, this message translates to:
  /// **'Maximum nag repeats'**
  String get notifMaxNag;

  /// No description provided for @notifMergedTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reminder} other{{count} reminders}}'**
  String notifMergedTitle(int count);

  /// No description provided for @notifMetricCleanDays.
  ///
  /// In en, this message translates to:
  /// **'Clean days'**
  String get notifMetricCleanDays;

  /// No description provided for @notifMetricMoney.
  ///
  /// In en, this message translates to:
  /// **'Money saved'**
  String get notifMetricMoney;

  /// No description provided for @notifMetricStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get notifMetricStreak;

  /// No description provided for @notifMetricTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get notifMetricTotal;

  /// No description provided for @notifMetricUnits.
  ///
  /// In en, this message translates to:
  /// **'Units avoided'**
  String get notifMetricUnits;

  /// No description provided for @notifMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 min} other{{minutes} min}}'**
  String notifMinutesValue(int minutes);

  /// No description provided for @notifModeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get notifModeCustom;

  /// No description provided for @notifModeInherit.
  ///
  /// In en, this message translates to:
  /// **'Use defaults'**
  String get notifModeInherit;

  /// No description provided for @notifModeInheritPlus.
  ///
  /// In en, this message translates to:
  /// **'Defaults + mine'**
  String get notifModeInheritPlus;

  /// No description provided for @notifModeOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifModeOff;

  /// No description provided for @notifModeOffHint.
  ///
  /// In en, this message translates to:
  /// **'No notifications for this item'**
  String get notifModeOffHint;

  /// No description provided for @notifMultiDevice.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get notifMultiDevice;

  /// No description provided for @notifMute1h.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get notifMute1h;

  /// No description provided for @notifMuteFor.
  ///
  /// In en, this message translates to:
  /// **'Mute…'**
  String get notifMuteFor;

  /// No description provided for @notifMuteForever.
  ///
  /// In en, this message translates to:
  /// **'Until I unmute'**
  String get notifMuteForever;

  /// No description provided for @notifMuteToday.
  ///
  /// In en, this message translates to:
  /// **'Rest of today'**
  String get notifMuteToday;

  /// No description provided for @notifMuteTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Until tomorrow'**
  String get notifMuteTomorrow;

  /// No description provided for @notifMuteWeek.
  ///
  /// In en, this message translates to:
  /// **'For a week'**
  String get notifMuteWeek;

  /// No description provided for @notifMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get notifMuted;

  /// No description provided for @notifMutedForever.
  ///
  /// In en, this message translates to:
  /// **'Muted until unmuted'**
  String get notifMutedForever;

  /// No description provided for @notifMutedSnack.
  ///
  /// In en, this message translates to:
  /// **'Muted until tomorrow'**
  String get notifMutedSnack;

  /// No description provided for @notifMutedUntil.
  ///
  /// In en, this message translates to:
  /// **'Muted until {time}'**
  String notifMutedUntil(String time);

  /// No description provided for @notifMutes.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get notifMutes;

  /// No description provided for @notifMutesNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing is muted'**
  String get notifMutesNone;

  /// No description provided for @notifNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get notifNever;

  /// No description provided for @notifNextFirings.
  ///
  /// In en, this message translates to:
  /// **'Next reminders'**
  String get notifNextFirings;

  /// No description provided for @notifNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get notifNo;

  /// No description provided for @notifNoReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders'**
  String get notifNoReminders;

  /// No description provided for @notifNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled in the next 14 days'**
  String get notifNoUpcoming;

  /// No description provided for @notifNoiseBlocked.
  ///
  /// In en, this message translates to:
  /// **'Too many notifications (more than 1 440 per day)'**
  String get notifNoiseBlocked;

  /// No description provided for @notifNoiseCluster.
  ///
  /// In en, this message translates to:
  /// **'Several reminders share this minute — only one sound plays'**
  String get notifNoiseCluster;

  /// No description provided for @notifNoiseConfirm.
  ///
  /// In en, this message translates to:
  /// **'This reminder sends about {perDay} notifications per day. Save anyway?'**
  String notifNoiseConfirm(int perDay);

  /// No description provided for @notifNoiseWarn.
  ///
  /// In en, this message translates to:
  /// **'About {perDay} notifications per day'**
  String notifNoiseWarn(int perDay);

  /// No description provided for @notifOffsetAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get notifOffsetAmount;

  /// No description provided for @notifOnlyIfStatus.
  ///
  /// In en, this message translates to:
  /// **'Only if status is'**
  String get notifOnlyIfStatus;

  /// No description provided for @notifOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get notifOpenSettings;

  /// No description provided for @notifOutsideDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop outside'**
  String get notifOutsideDrop;

  /// No description provided for @notifOutsideShiftEnd.
  ///
  /// In en, this message translates to:
  /// **'Move to window end'**
  String get notifOutsideShiftEnd;

  /// No description provided for @notifOutsideShiftStart.
  ///
  /// In en, this message translates to:
  /// **'Move to window start'**
  String get notifOutsideShiftStart;

  /// No description provided for @notifPause1h.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get notifPause1h;

  /// No description provided for @notifPauseAll.
  ///
  /// In en, this message translates to:
  /// **'Pause all'**
  String get notifPauseAll;

  /// No description provided for @notifPauseCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get notifPauseCustom;

  /// No description provided for @notifPauseTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Until tomorrow 08:00'**
  String get notifPauseTomorrow;

  /// No description provided for @notifPausedUntil.
  ///
  /// In en, this message translates to:
  /// **'Paused until {time}'**
  String notifPausedUntil(String time);

  /// No description provided for @notifPermissionOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off'**
  String get notifPermissionOff;

  /// No description provided for @notifPermissionOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn them on to receive your reminders.'**
  String get notifPermissionOffBody;

  /// No description provided for @notifPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get notifPreview;

  /// No description provided for @notifPrimerAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notifPrimerAllow;

  /// No description provided for @notifPrimerBody.
  ///
  /// In en, this message translates to:
  /// **'Everslot reminds you before tasks start, when habits are due and when lists need a follow-up. You decide exactly when.'**
  String get notifPrimerBody;

  /// No description provided for @notifPrimerExactBody.
  ///
  /// In en, this message translates to:
  /// **'Android needs your permission to deliver reminders at the exact minute. Without it they may be up to an hour late.'**
  String get notifPrimerExactBody;

  /// No description provided for @notifPrimerExactTitle.
  ///
  /// In en, this message translates to:
  /// **'Precise reminders'**
  String get notifPrimerExactTitle;

  /// No description provided for @notifPrimerLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notifPrimerLater;

  /// No description provided for @notifPrimerTimeSensitiveBody.
  ///
  /// In en, this message translates to:
  /// **'Important reminders can break through Focus modes. You can change this in iOS Settings at any time.'**
  String get notifPrimerTimeSensitiveBody;

  /// No description provided for @notifPrimerTimeSensitiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Time-sensitive reminders'**
  String get notifPrimerTimeSensitiveTitle;

  /// No description provided for @notifPrimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss what matters'**
  String get notifPrimerTitle;

  /// No description provided for @notifProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get notifProfile;

  /// No description provided for @notifProfileAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get notifProfileAlarm;

  /// No description provided for @notifProfileBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get notifProfileBuiltin;

  /// No description provided for @notifProfileChannelWarning.
  ///
  /// In en, this message translates to:
  /// **'Changing importance, sound or vibration creates a new Android notification category; the old one appears as deleted in system settings.'**
  String get notifProfileChannelWarning;

  /// No description provided for @notifProfileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get notifProfileDelete;

  /// No description provided for @notifProfileDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reminder uses this profile.} other{{count} reminders use this profile.}} Move them to:'**
  String notifProfileDeleteBody(int count);

  /// No description provided for @notifProfileDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get notifProfileDuplicate;

  /// No description provided for @notifProfileGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get notifProfileGentle;

  /// No description provided for @notifProfileNag.
  ///
  /// In en, this message translates to:
  /// **'Nag until done'**
  String get notifProfileNag;

  /// No description provided for @notifProfileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get notifProfileName;

  /// No description provided for @notifProfileNew.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get notifProfileNew;

  /// No description provided for @notifProfileNone.
  ///
  /// In en, this message translates to:
  /// **'No profile'**
  String get notifProfileNone;

  /// No description provided for @notifProfileRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get notifProfileRename;

  /// No description provided for @notifProfileStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get notifProfileStandard;

  /// No description provided for @notifProfilesEntry.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get notifProfilesEntry;

  /// No description provided for @notifProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification profiles'**
  String get notifProfilesTitle;

  /// No description provided for @notifProvenanceAncestor.
  ///
  /// In en, this message translates to:
  /// **'parent item'**
  String get notifProvenanceAncestor;

  /// No description provided for @notifProvenanceCategory.
  ///
  /// In en, this message translates to:
  /// **'category'**
  String get notifProvenanceCategory;

  /// No description provided for @notifProvenanceChecklist.
  ///
  /// In en, this message translates to:
  /// **'list'**
  String get notifProvenanceChecklist;

  /// No description provided for @notifProvenanceGlobal.
  ///
  /// In en, this message translates to:
  /// **'global defaults'**
  String get notifProvenanceGlobal;

  /// No description provided for @notifProvenanceOccurrence.
  ///
  /// In en, this message translates to:
  /// **'this occurrence only'**
  String get notifProvenanceOccurrence;

  /// No description provided for @notifProvenanceSection.
  ///
  /// In en, this message translates to:
  /// **'section defaults'**
  String get notifProvenanceSection;

  /// No description provided for @notifQuietAdd.
  ///
  /// In en, this message translates to:
  /// **'Add quiet hours'**
  String get notifQuietAdd;

  /// No description provided for @notifQuietDefer.
  ///
  /// In en, this message translates to:
  /// **'Defer to the end'**
  String get notifQuietDefer;

  /// No description provided for @notifQuietDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get notifQuietDrop;

  /// No description provided for @notifQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notifQuietHours;

  /// No description provided for @notifQuietMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get notifQuietMode;

  /// No description provided for @notifQuietNone.
  ///
  /// In en, this message translates to:
  /// **'No quiet hours'**
  String get notifQuietNone;

  /// No description provided for @notifQuietSilent.
  ///
  /// In en, this message translates to:
  /// **'Deliver silently'**
  String get notifQuietSilent;

  /// No description provided for @notifQuietWindow.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String notifQuietWindow(String from, String to);

  /// No description provided for @notifRedactedBody.
  ///
  /// In en, this message translates to:
  /// **'Open Everslot to see it'**
  String get notifRedactedBody;

  /// No description provided for @notifRedactedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder from Everslot'**
  String get notifRedactedTitle;

  /// No description provided for @notifRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat (nag)'**
  String get notifRepeat;

  /// No description provided for @notifRespectQuiet.
  ///
  /// In en, this message translates to:
  /// **'Respect quiet hours'**
  String get notifRespectQuiet;

  /// No description provided for @notifResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get notifResume;

  /// No description provided for @notifRuleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reminder deleted'**
  String get notifRuleDeleted;

  /// No description provided for @notifRuleEnabled.
  ///
  /// In en, this message translates to:
  /// **'Reminder enabled'**
  String get notifRuleEnabled;

  /// No description provided for @notifRuleSaved.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved'**
  String get notifRuleSaved;

  /// No description provided for @notifSaturationBody.
  ///
  /// In en, this message translates to:
  /// **'Open Everslot to keep your reminders up to date'**
  String get notifSaturationBody;

  /// No description provided for @notifSaturationTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Everslot'**
  String get notifSaturationTitle;

  /// No description provided for @notifSectionChecklists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get notifSectionChecklists;

  /// No description provided for @notifSectionDigests.
  ///
  /// In en, this message translates to:
  /// **'Digests'**
  String get notifSectionDigests;

  /// No description provided for @notifSectionHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get notifSectionHabits;

  /// No description provided for @notifSectionOffHint.
  ///
  /// In en, this message translates to:
  /// **'{section} notifications are turned off in Settings'**
  String notifSectionOffHint(String section);

  /// No description provided for @notifSectionPlanner.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get notifSectionPlanner;

  /// No description provided for @notifSectionQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get notifSectionQuit;

  /// No description provided for @notifSectionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notifSectionSystem;

  /// No description provided for @notifSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifSectionTitle;

  /// No description provided for @notifSendTest.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get notifSendTest;

  /// No description provided for @notifSettingsSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get notifSettingsSections;

  /// No description provided for @notifSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifSettingsTitle;

  /// No description provided for @notifShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all ({count})'**
  String notifShowAll(int count);

  /// No description provided for @notifSkipAck.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get notifSkipAck;

  /// No description provided for @notifSkipCap.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get notifSkipCap;

  /// No description provided for @notifSkipDone.
  ///
  /// In en, this message translates to:
  /// **'Already done'**
  String get notifSkipDone;

  /// No description provided for @notifSkipExpired.
  ///
  /// In en, this message translates to:
  /// **'Too late'**
  String get notifSkipExpired;

  /// No description provided for @notifSkipMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get notifSkipMuted;

  /// No description provided for @notifSkipNoChannel.
  ///
  /// In en, this message translates to:
  /// **'No delivery channel'**
  String get notifSkipNoChannel;

  /// No description provided for @notifSkipQuiet.
  ///
  /// In en, this message translates to:
  /// **'Dropped (quiet hours)'**
  String get notifSkipQuiet;

  /// No description provided for @notifSkipStatus.
  ///
  /// In en, this message translates to:
  /// **'Status doesn’t match'**
  String get notifSkipStatus;

  /// No description provided for @notifSkipWeekday.
  ///
  /// In en, this message translates to:
  /// **'Not on this weekday'**
  String get notifSkipWeekday;

  /// No description provided for @notifSkipWindow.
  ///
  /// In en, this message translates to:
  /// **'Outside the time window'**
  String get notifSkipWindow;

  /// No description provided for @notifSnoozeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get notifSnoozeCustom;

  /// No description provided for @notifSnoozeEvening.
  ///
  /// In en, this message translates to:
  /// **'This evening'**
  String get notifSnoozeEvening;

  /// No description provided for @notifSnoozeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String notifSnoozeHours(int hours);

  /// No description provided for @notifSnoozeLimit.
  ///
  /// In en, this message translates to:
  /// **'Snooze limit reached'**
  String get notifSnoozeLimit;

  /// No description provided for @notifSnoozeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 min} other{{minutes} min}}'**
  String notifSnoozeMinutes(int minutes);

  /// No description provided for @notifSnoozeOptions.
  ///
  /// In en, this message translates to:
  /// **'Snooze options (minutes)'**
  String get notifSnoozeOptions;

  /// No description provided for @notifSnoozePresets.
  ///
  /// In en, this message translates to:
  /// **'Snooze presets'**
  String get notifSnoozePresets;

  /// No description provided for @notifSnoozeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow morning'**
  String get notifSnoozeTomorrow;

  /// No description provided for @notifSnoozedSnack.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {time}'**
  String notifSnoozedSnack(String time);

  /// No description provided for @notifSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get notifSound;

  /// No description provided for @notifSoundAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get notifSoundAlarm;

  /// No description provided for @notifSoundBell.
  ///
  /// In en, this message translates to:
  /// **'Bell'**
  String get notifSoundBell;

  /// No description provided for @notifSoundChime.
  ///
  /// In en, this message translates to:
  /// **'Chime'**
  String get notifSoundChime;

  /// No description provided for @notifSoundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get notifSoundDefault;

  /// No description provided for @notifSoundNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get notifSoundNone;

  /// No description provided for @notifSoundPop.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get notifSoundPop;

  /// No description provided for @notifSoundSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get notifSoundSoft;

  /// No description provided for @notifStatusBlocked.
  ///
  /// In en, this message translates to:
  /// **'blocked'**
  String get notifStatusBlocked;

  /// No description provided for @notifStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled'**
  String get notifStatusCancelled;

  /// No description provided for @notifStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get notifStatusCompleted;

  /// No description provided for @notifStatusDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get notifStatusDone;

  /// No description provided for @notifStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get notifStatusInProgress;

  /// No description provided for @notifStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'missed'**
  String get notifStatusMissed;

  /// No description provided for @notifStatusOngoing.
  ///
  /// In en, this message translates to:
  /// **'ongoing'**
  String get notifStatusOngoing;

  /// No description provided for @notifStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'scheduled'**
  String get notifStatusScheduled;

  /// No description provided for @notifStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get notifStatusSkipped;

  /// No description provided for @notifStatusTodo.
  ///
  /// In en, this message translates to:
  /// **'to do'**
  String get notifStatusTodo;

  /// No description provided for @notifStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'waiting'**
  String get notifStatusWaiting;

  /// No description provided for @notifSticky.
  ///
  /// In en, this message translates to:
  /// **'Keep until done (Android)'**
  String get notifSticky;

  /// No description provided for @notifSumAbsolute.
  ///
  /// In en, this message translates to:
  /// **'On {dateTime}'**
  String notifSumAbsolute(String dateTime);

  /// No description provided for @notifSumAfterDue.
  ///
  /// In en, this message translates to:
  /// **'{duration} after due'**
  String notifSumAfterDue(String duration);

  /// No description provided for @notifSumAfterEnd.
  ///
  /// In en, this message translates to:
  /// **'{duration} after end'**
  String notifSumAfterEnd(String duration);

  /// No description provided for @notifSumAfterStart.
  ///
  /// In en, this message translates to:
  /// **'{duration} after start'**
  String notifSumAfterStart(String duration);

  /// No description provided for @notifSumAtDue.
  ///
  /// In en, this message translates to:
  /// **'At due'**
  String get notifSumAtDue;

  /// No description provided for @notifSumAtEnd.
  ///
  /// In en, this message translates to:
  /// **'At end'**
  String get notifSumAtEnd;

  /// No description provided for @notifSumAtFollowUp.
  ///
  /// In en, this message translates to:
  /// **'At follow-up'**
  String get notifSumAtFollowUp;

  /// No description provided for @notifSumAtPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'At period end'**
  String get notifSumAtPeriodEnd;

  /// No description provided for @notifSumAtPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'At period start'**
  String get notifSumAtPeriodStart;

  /// No description provided for @notifSumAtSlot.
  ///
  /// In en, this message translates to:
  /// **'At slot time'**
  String get notifSumAtSlot;

  /// No description provided for @notifSumAtStart.
  ///
  /// In en, this message translates to:
  /// **'At start'**
  String get notifSumAtStart;

  /// No description provided for @notifSumBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'{duration} before due'**
  String notifSumBeforeDue(String duration);

  /// No description provided for @notifSumBeforeEnd.
  ///
  /// In en, this message translates to:
  /// **'{duration} before end'**
  String notifSumBeforeEnd(String duration);

  /// No description provided for @notifSumBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'{duration} before start'**
  String notifSumBeforeStart(String duration);

  /// No description provided for @notifSumChildOverdue.
  ///
  /// In en, this message translates to:
  /// **'When a sub-item is overdue'**
  String get notifSumChildOverdue;

  /// No description provided for @notifSumChildrenComplete.
  ///
  /// In en, this message translates to:
  /// **'When all sub-items are done'**
  String get notifSumChildrenComplete;

  /// No description provided for @notifSumDaysAfter.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}} after at {time}'**
  String notifSumDaysAfter(int days, String time);

  /// No description provided for @notifSumDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}} before at {time}'**
  String notifSumDaysBefore(int days, String time);

  /// No description provided for @notifSumInactivity.
  ///
  /// In en, this message translates to:
  /// **'After {days, plural, =1{1 day} other{{days} days}} without activity'**
  String notifSumInactivity(int days);

  /// No description provided for @notifSumMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get notifSumMilestones;

  /// No description provided for @notifSumNotDoneBy.
  ///
  /// In en, this message translates to:
  /// **'If not done by {time}'**
  String notifSumNotDoneBy(String time);

  /// No description provided for @notifSumNotDoneByEnd.
  ///
  /// In en, this message translates to:
  /// **'If not done by the end'**
  String get notifSumNotDoneByEnd;

  /// No description provided for @notifSumOnDayAt.
  ///
  /// In en, this message translates to:
  /// **'On the day at {time}'**
  String notifSumOnDayAt(String time);

  /// No description provided for @notifSumOverdue.
  ///
  /// In en, this message translates to:
  /// **'When overdue'**
  String get notifSumOverdue;

  /// No description provided for @notifSumQuotaBehind.
  ///
  /// In en, this message translates to:
  /// **'Behind pace, at {time}'**
  String notifSumQuotaBehind(String time);

  /// No description provided for @notifSumRepeat.
  ///
  /// In en, this message translates to:
  /// **'repeats every {minutes} min ×{times}'**
  String notifSumRepeat(int minutes, int times);

  /// No description provided for @notifSumSchedule.
  ///
  /// In en, this message translates to:
  /// **'On a repeating schedule'**
  String get notifSumSchedule;

  /// No description provided for @notifSumStale.
  ///
  /// In en, this message translates to:
  /// **'After {days, plural, =1{1 day} other{{days} days}} without progress'**
  String notifSumStale(int days);

  /// No description provided for @notifSumStatusAge.
  ///
  /// In en, this message translates to:
  /// **'Still waiting or blocked after {duration}'**
  String notifSumStatusAge(String duration);

  /// No description provided for @notifSumStatusChange.
  ///
  /// In en, this message translates to:
  /// **'When it becomes {status}'**
  String notifSumStatusChange(String status);

  /// No description provided for @notifSumStreakRisk.
  ///
  /// In en, this message translates to:
  /// **'Streak at risk, at {time}'**
  String notifSumStreakRisk(String time);

  /// No description provided for @notifSumUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unsupported rule'**
  String get notifSumUnknown;

  /// No description provided for @notifSystemNotification.
  ///
  /// In en, this message translates to:
  /// **'System notification'**
  String get notifSystemNotification;

  /// No description provided for @notifTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification in 5 seconds'**
  String get notifTestSent;

  /// No description provided for @notifThisDeviceIsPrimary.
  ///
  /// In en, this message translates to:
  /// **'This device is the primary device'**
  String get notifThisDeviceIsPrimary;

  /// No description provided for @notifTimeWindow.
  ///
  /// In en, this message translates to:
  /// **'Time window'**
  String get notifTimeWindow;

  /// No description provided for @notifTitleFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow up: {title}'**
  String notifTitleFollowUp(String title);

  /// No description provided for @notifTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get notifTo;

  /// No description provided for @notifTrigger.
  ///
  /// In en, this message translates to:
  /// **'Trigger'**
  String get notifTrigger;

  /// No description provided for @notifTriggerAbsolute.
  ///
  /// In en, this message translates to:
  /// **'At a date and time'**
  String get notifTriggerAbsolute;

  /// No description provided for @notifTriggerChildOverdue.
  ///
  /// In en, this message translates to:
  /// **'Sub-item overdue'**
  String get notifTriggerChildOverdue;

  /// No description provided for @notifTriggerChildrenComplete.
  ///
  /// In en, this message translates to:
  /// **'All sub-items done'**
  String get notifTriggerChildrenComplete;

  /// No description provided for @notifTriggerDigest.
  ///
  /// In en, this message translates to:
  /// **'Digest'**
  String get notifTriggerDigest;

  /// No description provided for @notifTriggerInactivity.
  ///
  /// In en, this message translates to:
  /// **'Inactivity'**
  String get notifTriggerInactivity;

  /// No description provided for @notifTriggerMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get notifTriggerMilestone;

  /// No description provided for @notifTriggerNotDoneBy.
  ///
  /// In en, this message translates to:
  /// **'If not done by'**
  String get notifTriggerNotDoneBy;

  /// No description provided for @notifTriggerOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get notifTriggerOverdue;

  /// No description provided for @notifTriggerQuotaBehind.
  ///
  /// In en, this message translates to:
  /// **'Behind pace'**
  String get notifTriggerQuotaBehind;

  /// No description provided for @notifTriggerRelative.
  ///
  /// In en, this message translates to:
  /// **'Relative to the item'**
  String get notifTriggerRelative;

  /// No description provided for @notifTriggerSchedule.
  ///
  /// In en, this message translates to:
  /// **'Repeating schedule'**
  String get notifTriggerSchedule;

  /// No description provided for @notifTriggerStale.
  ///
  /// In en, this message translates to:
  /// **'No progress'**
  String get notifTriggerStale;

  /// No description provided for @notifTriggerStatusAge.
  ///
  /// In en, this message translates to:
  /// **'Status age'**
  String get notifTriggerStatusAge;

  /// No description provided for @notifTriggerStatusChange.
  ///
  /// In en, this message translates to:
  /// **'Status change'**
  String get notifTriggerStatusChange;

  /// No description provided for @notifTriggerStreakRisk.
  ///
  /// In en, this message translates to:
  /// **'Streak at risk'**
  String get notifTriggerStreakRisk;

  /// No description provided for @notifUnitDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get notifUnitDays;

  /// No description provided for @notifUnitHours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get notifUnitHours;

  /// No description provided for @notifUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get notifUnitMinutes;

  /// No description provided for @notifUnitWeeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get notifUnitWeeks;

  /// No description provided for @notifUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get notifUnknown;

  /// No description provided for @notifUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get notifUnmute;

  /// No description provided for @notifUntilAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'acknowledged'**
  String get notifUntilAcknowledged;

  /// No description provided for @notifUntilCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get notifUntilCompleted;

  /// No description provided for @notifUntilMax.
  ///
  /// In en, this message translates to:
  /// **'maximum reached'**
  String get notifUntilMax;

  /// No description provided for @notifVariables.
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get notifVariables;

  /// No description provided for @notifVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get notifVibration;

  /// No description provided for @notifVibrationDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get notifVibrationDefault;

  /// No description provided for @notifVibrationLong.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get notifVibrationLong;

  /// No description provided for @notifVibrationNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get notifVibrationNone;

  /// No description provided for @notifVibrationShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get notifVibrationShort;

  /// No description provided for @notifWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Only on'**
  String get notifWeekdays;

  /// No description provided for @notifYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get notifYes;

  /// No description provided for @onboardingClock.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get onboardingClock;

  /// No description provided for @onboardingClock12.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get onboardingClock12;

  /// No description provided for @onboardingClock24.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get onboardingClock24;

  /// No description provided for @onboardingEssentialsBody.
  ///
  /// In en, this message translates to:
  /// **'We picked these from your device. Adjust anything that\'s off — you can change them later in Settings › Regional.'**
  String get onboardingEssentialsBody;

  /// No description provided for @onboardingEssentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your week, your clock'**
  String get onboardingEssentialsTitle;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onboardingLanguage;

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepOf(int current, int total);

  /// No description provided for @onboardingTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Home time zone'**
  String get onboardingTimeZone;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up Everslot'**
  String get onboardingTitle;

  /// No description provided for @onboardingWeekStart.
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get onboardingWeekStart;

  /// No description provided for @pickerColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get pickerColor;

  /// No description provided for @pickerDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get pickerDate;

  /// No description provided for @pickerDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get pickerDays;

  /// No description provided for @pickerDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get pickerDuration;

  /// No description provided for @pickerHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get pickerHours;

  /// No description provided for @pickerIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get pickerIcon;

  /// No description provided for @pickerMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get pickerMinutes;

  /// No description provided for @pickerNoColor.
  ///
  /// In en, this message translates to:
  /// **'No color'**
  String get pickerNoColor;

  /// No description provided for @pickerSearchIcons.
  ///
  /// In en, this message translates to:
  /// **'Search icons'**
  String get pickerSearchIcons;

  /// No description provided for @pickerTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get pickerTime;

  /// No description provided for @placeholderScreen.
  ///
  /// In en, this message translates to:
  /// **'This screen is being built.'**
  String get placeholderScreen;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityNone.
  ///
  /// In en, this message translates to:
  /// **'No priority'**
  String get priorityNone;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @pvActualColumn.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get pvActualColumn;

  /// No description provided for @pvAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get pvAddTask;

  /// No description provided for @pvAddZone.
  ///
  /// In en, this message translates to:
  /// **'Add time zone'**
  String get pvAddZone;

  /// No description provided for @pvAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get pvAllDay;

  /// No description provided for @pvAllDaySection.
  ///
  /// In en, this message translates to:
  /// **'All day & untimed'**
  String get pvAllDaySection;

  /// No description provided for @pvApplyToView.
  ///
  /// In en, this message translates to:
  /// **'Apply to this view'**
  String get pvApplyToView;

  /// No description provided for @pvAutoAdvance.
  ///
  /// In en, this message translates to:
  /// **'Auto-advance'**
  String get pvAutoAdvance;

  /// No description provided for @pvAutoScrollNow.
  ///
  /// In en, this message translates to:
  /// **'Scroll to now on open'**
  String get pvAutoScrollNow;

  /// No description provided for @pvBacklogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your backlog is empty'**
  String get pvBacklogEmpty;

  /// No description provided for @pvCancelOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Cancel this occurrence'**
  String get pvCancelOccurrence;

  /// No description provided for @pvCannotUnschedule.
  ///
  /// In en, this message translates to:
  /// **'Recurring occurrences can\'t be moved to the backlog'**
  String get pvCannotUnschedule;

  /// No description provided for @pvCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get pvCapacity;

  /// No description provided for @pvCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get pvCategories;

  /// No description provided for @pvClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get pvClearFilters;

  /// No description provided for @pvClocksForward.
  ///
  /// In en, this message translates to:
  /// **'Clocks forward'**
  String get pvClocksForward;

  /// No description provided for @pvColCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get pvColCategory;

  /// No description provided for @pvColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get pvColDate;

  /// No description provided for @pvColDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get pvColDuration;

  /// No description provided for @pvColEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get pvColEnd;

  /// No description provided for @pvColLocation.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get pvColLocation;

  /// No description provided for @pvColPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get pvColPriority;

  /// No description provided for @pvColRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get pvColRecurrence;

  /// No description provided for @pvColStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get pvColStart;

  /// No description provided for @pvColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pvColStatus;

  /// No description provided for @pvColTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get pvColTitle;

  /// No description provided for @pvColTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get pvColTracking;

  /// No description provided for @pvCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get pvCollapse;

  /// No description provided for @pvColorBy.
  ///
  /// In en, this message translates to:
  /// **'Color by'**
  String get pvColorBy;

  /// No description provided for @pvColorByCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get pvColorByCategory;

  /// No description provided for @pvColorByPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get pvColorByPriority;

  /// No description provided for @pvColorByStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pvColorByStatus;

  /// No description provided for @pvColorByTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get pvColorByTask;

  /// No description provided for @pvColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get pvColumns;

  /// No description provided for @pvCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get pvCompletion;

  /// No description provided for @pvContinues.
  ///
  /// In en, this message translates to:
  /// **'continues'**
  String get pvContinues;

  /// No description provided for @pvCopySuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String pvCopySuffix(String name);

  /// No description provided for @pvCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get pvCreate;

  /// No description provided for @pvCreateHere.
  ///
  /// In en, this message translates to:
  /// **'Create here'**
  String get pvCreateHere;

  /// No description provided for @pvCreatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Task created'**
  String get pvCreatedSnack;

  /// No description provided for @pvCurrentSize.
  ///
  /// In en, this message translates to:
  /// **'Current: {size}'**
  String pvCurrentSize(String size);

  /// No description provided for @pvDayHeaderSemantics.
  ///
  /// In en, this message translates to:
  /// **'{day}, {items}'**
  String pvDayHeaderSemantics(String day, String items);

  /// No description provided for @pvDayRibbon.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get pvDayRibbon;

  /// No description provided for @pvDayStats.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} · {planned}'**
  String pvDayStats(String done, String total, String planned);

  /// No description provided for @pvDaySummary.
  ///
  /// In en, this message translates to:
  /// **'Day summary'**
  String get pvDaySummary;

  /// No description provided for @pvDayTicker.
  ///
  /// In en, this message translates to:
  /// **'Day ticker'**
  String get pvDayTicker;

  /// No description provided for @pvDaysSince.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{today} =1{1 day ago} other{{count} days ago}}'**
  String pvDaysSince(int count);

  /// No description provided for @pvDaysUntil.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{today} =1{in 1 day} other{in {count} days}}'**
  String pvDaysUntil(int count);

  /// No description provided for @pvDaysVisible.
  ///
  /// In en, this message translates to:
  /// **'Days visible'**
  String get pvDaysVisible;

  /// No description provided for @pvDaysVisibleLandscape.
  ///
  /// In en, this message translates to:
  /// **'Days in landscape'**
  String get pvDaysVisibleLandscape;

  /// No description provided for @pvDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get pvDefaultBadge;

  /// No description provided for @pvDeleteView.
  ///
  /// In en, this message translates to:
  /// **'Delete view'**
  String get pvDeleteView;

  /// No description provided for @pvDemoData.
  ///
  /// In en, this message translates to:
  /// **'Demo data (developer)'**
  String get pvDemoData;

  /// No description provided for @pvDensity.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get pvDensity;

  /// No description provided for @pvDensityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get pvDensityComfortable;

  /// No description provided for @pvDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get pvDensityCompact;

  /// No description provided for @pvDimPast.
  ///
  /// In en, this message translates to:
  /// **'Dim past'**
  String get pvDimPast;

  /// No description provided for @pvDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get pvDisplay;

  /// No description provided for @pvDoneTotal.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pvDoneTotal;

  /// No description provided for @pvDragToSchedule.
  ///
  /// In en, this message translates to:
  /// **'Drag onto the grid to schedule'**
  String get pvDragToSchedule;

  /// No description provided for @pvDropNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This grouping can\'t be changed by dragging yet'**
  String get pvDropNotSupported;

  /// No description provided for @pvDuplicateView.
  ///
  /// In en, this message translates to:
  /// **'Duplicate view'**
  String get pvDuplicateView;

  /// No description provided for @pvElapsed.
  ///
  /// In en, this message translates to:
  /// **'{duration} elapsed'**
  String pvElapsed(String duration);

  /// No description provided for @pvEmptyDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned'**
  String get pvEmptyDay;

  /// No description provided for @pvEmptyRange.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this range'**
  String get pvEmptyRange;

  /// No description provided for @pvEmptySlotSemantics.
  ///
  /// In en, this message translates to:
  /// **'{day} {time}, empty, double-tap to create'**
  String pvEmptySlotSemantics(String day, String time);

  /// No description provided for @pvEmptyWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned this week'**
  String get pvEmptyWeekTitle;

  /// No description provided for @pvExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get pvExpand;

  /// No description provided for @pvExpandInline.
  ///
  /// In en, this message translates to:
  /// **'Expand day inline'**
  String get pvExpandInline;

  /// No description provided for @pvExtend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get pvExtend;

  /// No description provided for @pvExtendBy.
  ///
  /// In en, this message translates to:
  /// **'+{minutes} min'**
  String pvExtendBy(int minutes);

  /// No description provided for @pvExtraZones.
  ///
  /// In en, this message translates to:
  /// **'Extra time zones'**
  String get pvExtraZones;

  /// No description provided for @pvFillFromBacklog.
  ///
  /// In en, this message translates to:
  /// **'Fill from backlog'**
  String get pvFillFromBacklog;

  /// No description provided for @pvFillGap.
  ///
  /// In en, this message translates to:
  /// **'Fill this gap'**
  String get pvFillGap;

  /// No description provided for @pvFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get pvFilter;

  /// No description provided for @pvFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get pvFilters;

  /// No description provided for @pvFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get pvFinish;

  /// No description provided for @pvFollowWorkHours.
  ///
  /// In en, this message translates to:
  /// **'Use my work hours'**
  String get pvFollowWorkHours;

  /// No description provided for @pvFreeGap.
  ///
  /// In en, this message translates to:
  /// **'free {duration}'**
  String pvFreeGap(String duration);

  /// No description provided for @pvFreeInWorkHours.
  ///
  /// In en, this message translates to:
  /// **'Free in work hours'**
  String get pvFreeInWorkHours;

  /// No description provided for @pvFreeRun.
  ///
  /// In en, this message translates to:
  /// **'Free {from}–{to} · {duration}'**
  String pvFreeRun(String from, String to, String duration);

  /// No description provided for @pvFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get pvFrom;

  /// No description provided for @pvGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get pvGotIt;

  /// No description provided for @pvGroupBy.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get pvGroupBy;

  /// No description provided for @pvGroupCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar views'**
  String get pvGroupCalendar;

  /// No description provided for @pvGroupCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get pvGroupCategory;

  /// No description provided for @pvGroupDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get pvGroupDay;

  /// No description provided for @pvGroupNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get pvGroupNone;

  /// No description provided for @pvGroupPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get pvGroupPriority;

  /// No description provided for @pvGroupProductivity.
  ///
  /// In en, this message translates to:
  /// **'Focus & productivity'**
  String get pvGroupProductivity;

  /// No description provided for @pvGroupStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pvGroupStatus;

  /// No description provided for @pvGroupTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get pvGroupTask;

  /// No description provided for @pvHeatMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get pvHeatMetric;

  /// No description provided for @pvHiddenRange.
  ///
  /// In en, this message translates to:
  /// **'Hidden {from}–{to}'**
  String pvHiddenRange(String from, String to);

  /// No description provided for @pvHideEmptySlots.
  ///
  /// In en, this message translates to:
  /// **'Collapse empty slots'**
  String get pvHideEmptySlots;

  /// No description provided for @pvHintLongPress.
  ///
  /// In en, this message translates to:
  /// **'Long-press empty space to create a task'**
  String get pvHintLongPress;

  /// No description provided for @pvHintPinch.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom; pinch sideways to change the number of days'**
  String get pvHintPinch;

  /// No description provided for @pvHintSlotSize.
  ///
  /// In en, this message translates to:
  /// **'Tap {size} to change the row size'**
  String pvHintSlotSize(String size);

  /// No description provided for @pvHorizonDay.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get pvHorizonDay;

  /// No description provided for @pvHorizonMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get pvHorizonMonth;

  /// No description provided for @pvHorizonQuarter.
  ///
  /// In en, this message translates to:
  /// **'This quarter'**
  String get pvHorizonQuarter;

  /// No description provided for @pvHorizonWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get pvHorizonWeek;

  /// No description provided for @pvHorizonYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get pvHorizonYear;

  /// No description provided for @pvHorizonsHint.
  ///
  /// In en, this message translates to:
  /// **'Unscheduled intentions per horizon (stored on this device until horizons sync).'**
  String get pvHorizonsHint;

  /// No description provided for @pvIgnoreLowPriority.
  ///
  /// In en, this message translates to:
  /// **'Ignore low-priority tasks'**
  String get pvIgnoreLowPriority;

  /// No description provided for @pvImportanceRule.
  ///
  /// In en, this message translates to:
  /// **'Important from priority {priority}'**
  String pvImportanceRule(String priority);

  /// No description provided for @pvItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String pvItemsCount(int count);

  /// No description provided for @pvJumpToDate.
  ///
  /// In en, this message translates to:
  /// **'Jump to date'**
  String get pvJumpToDate;

  /// No description provided for @pvKeepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get pvKeepScreenOn;

  /// No description provided for @pvLaneCap.
  ///
  /// In en, this message translates to:
  /// **'Side-by-side lanes'**
  String get pvLaneCap;

  /// No description provided for @pvLanes.
  ///
  /// In en, this message translates to:
  /// **'Lanes'**
  String get pvLanes;

  /// No description provided for @pvLastRowShort.
  ///
  /// In en, this message translates to:
  /// **'the last one {duration}'**
  String pvLastRowShort(String duration);

  /// No description provided for @pvLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get pvLayout;

  /// No description provided for @pvLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get pvLess;

  /// No description provided for @pvListBelow.
  ///
  /// In en, this message translates to:
  /// **'List below'**
  String get pvListBelow;

  /// No description provided for @pvListMode.
  ///
  /// In en, this message translates to:
  /// **'Accessible list'**
  String get pvListMode;

  /// No description provided for @pvMapPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'The map needs task coordinates, which arrive with the place picker. Tasks with a place are listed below.'**
  String get pvMapPlaceholder;

  /// No description provided for @pvMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get pvMarkDone;

  /// No description provided for @pvMarkNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark not done'**
  String get pvMarkNotDone;

  /// No description provided for @pvMetricCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get pvMetricCompletion;

  /// No description provided for @pvMetricCount.
  ///
  /// In en, this message translates to:
  /// **'Number of items'**
  String get pvMetricCount;

  /// No description provided for @pvMetricPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned hours'**
  String get pvMetricPlanned;

  /// No description provided for @pvMinGap.
  ///
  /// In en, this message translates to:
  /// **'Minimum gap'**
  String get pvMinGap;

  /// No description provided for @pvMonthBars.
  ///
  /// In en, this message translates to:
  /// **'Bars'**
  String get pvMonthBars;

  /// No description provided for @pvMonthDots.
  ///
  /// In en, this message translates to:
  /// **'Dots'**
  String get pvMonthDots;

  /// No description provided for @pvMonthTitles.
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get pvMonthTitles;

  /// No description provided for @pvMonthTitlesTimes.
  ///
  /// In en, this message translates to:
  /// **'Titles and times'**
  String get pvMonthTitlesTimes;

  /// No description provided for @pvMore.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String pvMore(String count);

  /// No description provided for @pvMoreItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more item} other{{count} more items}}'**
  String pvMoreItems(int count);

  /// No description provided for @pvMoreLegend.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get pvMoreLegend;

  /// No description provided for @pvMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get pvMoreOptions;

  /// No description provided for @pvMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get pvMove;

  /// No description provided for @pvMoveDoneBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s already done — moving it changes its history.'**
  String get pvMoveDoneBody;

  /// No description provided for @pvMoveDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Move a completed task?'**
  String get pvMoveDoneTitle;

  /// No description provided for @pvMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get pvMoveDown;

  /// No description provided for @pvMoveEarlier.
  ///
  /// In en, this message translates to:
  /// **'Move {minutes} min earlier'**
  String pvMoveEarlier(int minutes);

  /// No description provided for @pvMoveLater.
  ///
  /// In en, this message translates to:
  /// **'Move {minutes} min later'**
  String pvMoveLater(int minutes);

  /// No description provided for @pvMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get pvMoveTo;

  /// No description provided for @pvMoveUnfinishedTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Move unfinished to tomorrow'**
  String get pvMoveUnfinishedTomorrow;

  /// No description provided for @pvMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get pvMoveUp;

  /// No description provided for @pvMovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Moved to {when}'**
  String pvMovedSnack(String when);

  /// No description provided for @pvNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get pvNext;

  /// No description provided for @pvNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get pvNextDay;

  /// No description provided for @pvNextDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Next day} other{Next {count} days}}'**
  String pvNextDays(int count);

  /// No description provided for @pvNextUp.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get pvNextUp;

  /// No description provided for @pvNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get pvNextWeek;

  /// No description provided for @pvNoCategory.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get pvNoCategory;

  /// No description provided for @pvNoOpenings.
  ///
  /// In en, this message translates to:
  /// **'No free time found'**
  String get pvNoOpenings;

  /// No description provided for @pvNoRoom.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item didn\'t fit} other{{count} items didn\'t fit}}'**
  String pvNoRoom(int count);

  /// No description provided for @pvNoRoutine.
  ///
  /// In en, this message translates to:
  /// **'No routine block today'**
  String get pvNoRoutine;

  /// No description provided for @pvNoSavedViews.
  ///
  /// In en, this message translates to:
  /// **'No saved views yet'**
  String get pvNoSavedViews;

  /// No description provided for @pvNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get pvNoTasks;

  /// No description provided for @pvNothingNow.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled right now'**
  String get pvNothingNow;

  /// No description provided for @pvNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get pvNow;

  /// No description provided for @pvOneOff.
  ///
  /// In en, this message translates to:
  /// **'One-off'**
  String get pvOneOff;

  /// No description provided for @pvOpenDay.
  ///
  /// In en, this message translates to:
  /// **'Open day'**
  String get pvOpenDay;

  /// No description provided for @pvOpenings.
  ///
  /// In en, this message translates to:
  /// **'Openings'**
  String get pvOpenings;

  /// No description provided for @pvOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get pvOverdue;

  /// No description provided for @pvOverlapCascade.
  ///
  /// In en, this message translates to:
  /// **'Cascade'**
  String get pvOverlapCascade;

  /// No description provided for @pvOverlapColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get pvOverlapColumns;

  /// No description provided for @pvOverlapStyle.
  ///
  /// In en, this message translates to:
  /// **'Overlap style'**
  String get pvOverlapStyle;

  /// No description provided for @pvOverlayChecklistDue.
  ///
  /// In en, this message translates to:
  /// **'Checklist items due'**
  String get pvOverlayChecklistDue;

  /// No description provided for @pvOverlayDeviceCalendars.
  ///
  /// In en, this message translates to:
  /// **'Device calendars'**
  String get pvOverlayDeviceCalendars;

  /// No description provided for @pvOverlayFreeSlots.
  ///
  /// In en, this message translates to:
  /// **'Free time'**
  String get pvOverlayFreeSlots;

  /// No description provided for @pvOverlayHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits due'**
  String get pvOverlayHabits;

  /// No description provided for @pvOverlayHeat.
  ///
  /// In en, this message translates to:
  /// **'Busy-hour heat'**
  String get pvOverlayHeat;

  /// No description provided for @pvOverlays.
  ///
  /// In en, this message translates to:
  /// **'Overlays'**
  String get pvOverlays;

  /// No description provided for @pvPagingDay.
  ///
  /// In en, this message translates to:
  /// **'One day'**
  String get pvPagingDay;

  /// No description provided for @pvPagingFree.
  ///
  /// In en, this message translates to:
  /// **'Free scroll'**
  String get pvPagingFree;

  /// No description provided for @pvPagingMode.
  ///
  /// In en, this message translates to:
  /// **'Swipe moves'**
  String get pvPagingMode;

  /// No description provided for @pvPagingWeek.
  ///
  /// In en, this message translates to:
  /// **'One week'**
  String get pvPagingWeek;

  /// No description provided for @pvPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pvPause;

  /// No description provided for @pvPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pvPickDate;

  /// No description provided for @pvPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pvPin;

  /// No description provided for @pvPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pvPinned;

  /// No description provided for @pvPixels.
  ///
  /// In en, this message translates to:
  /// **'{value} px'**
  String pvPixels(String value);

  /// No description provided for @pvPlanColumn.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get pvPlanColumn;

  /// No description provided for @pvPlanFirstTask.
  ///
  /// In en, this message translates to:
  /// **'Plan your first task'**
  String get pvPlanFirstTask;

  /// No description provided for @pvPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get pvPlanned;

  /// No description provided for @pvPostpone.
  ///
  /// In en, this message translates to:
  /// **'Postpone'**
  String get pvPostpone;

  /// No description provided for @pvPostponeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String pvPostponeMinutes(int minutes);

  /// No description provided for @pvPostponeNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get pvPostponeNextWeek;

  /// No description provided for @pvPostponeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get pvPostponeTomorrow;

  /// No description provided for @pvPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get pvPrevious;

  /// No description provided for @pvPreviousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get pvPreviousDay;

  /// No description provided for @pvPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get pvPreviousWeek;

  /// No description provided for @pvPriorities.
  ///
  /// In en, this message translates to:
  /// **'Priorities'**
  String get pvPriorities;

  /// No description provided for @pvQuadDelegate.
  ///
  /// In en, this message translates to:
  /// **'Delegate'**
  String get pvQuadDelegate;

  /// No description provided for @pvQuadDo.
  ///
  /// In en, this message translates to:
  /// **'Do'**
  String get pvQuadDo;

  /// No description provided for @pvQuadEliminate.
  ///
  /// In en, this message translates to:
  /// **'Eliminate'**
  String get pvQuadEliminate;

  /// No description provided for @pvQuadSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get pvQuadSchedule;

  /// No description provided for @pvQuickCreateHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s the plan?'**
  String get pvQuickCreateHint;

  /// No description provided for @pvQuickCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get pvQuickCreateTitle;

  /// No description provided for @pvRadial12.
  ///
  /// In en, this message translates to:
  /// **'12 h'**
  String get pvRadial12;

  /// No description provided for @pvRadial24.
  ///
  /// In en, this message translates to:
  /// **'24 h'**
  String get pvRadial24;

  /// No description provided for @pvRadialHours.
  ///
  /// In en, this message translates to:
  /// **'Dial'**
  String get pvRadialHours;

  /// No description provided for @pvRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get pvRecurring;

  /// No description provided for @pvRenameView.
  ///
  /// In en, this message translates to:
  /// **'Rename view'**
  String get pvRenameView;

  /// No description provided for @pvRenderAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get pvRenderAuto;

  /// No description provided for @pvRenderMode.
  ///
  /// In en, this message translates to:
  /// **'Render'**
  String get pvRenderMode;

  /// No description provided for @pvRenderTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get pvRenderTable;

  /// No description provided for @pvRenderTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get pvRenderTimeline;

  /// No description provided for @pvRepeatedHour.
  ///
  /// In en, this message translates to:
  /// **'{time} ({offset})'**
  String pvRepeatedHour(String time, String offset);

  /// No description provided for @pvRepeats.
  ///
  /// In en, this message translates to:
  /// **'repeats'**
  String get pvRepeats;

  /// No description provided for @pvResetView.
  ///
  /// In en, this message translates to:
  /// **'Reset view settings'**
  String get pvResetView;

  /// No description provided for @pvResizedSnack.
  ///
  /// In en, this message translates to:
  /// **'Duration {duration}'**
  String pvResizedSnack(String duration);

  /// No description provided for @pvRibbonStyle.
  ///
  /// In en, this message translates to:
  /// **'Ribbon'**
  String get pvRibbonStyle;

  /// No description provided for @pvRoutineComplete.
  ///
  /// In en, this message translates to:
  /// **'Routine complete'**
  String get pvRoutineComplete;

  /// No description provided for @pvRoutineStart.
  ///
  /// In en, this message translates to:
  /// **'Start routine'**
  String get pvRoutineStart;

  /// No description provided for @pvRoutineSummary.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} steps done'**
  String pvRoutineSummary(int done, int total);

  /// No description provided for @pvRowHeight.
  ///
  /// In en, this message translates to:
  /// **'Row height'**
  String get pvRowHeight;

  /// No description provided for @pvRowsOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Occurrences'**
  String get pvRowsOccurrences;

  /// No description provided for @pvRowsPerDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row per day} other{{count} rows per day}}'**
  String pvRowsPerDay(int count);

  /// No description provided for @pvRowsTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get pvRowsTasks;

  /// No description provided for @pvRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get pvRules;

  /// No description provided for @pvSaveAsNewView.
  ///
  /// In en, this message translates to:
  /// **'Save as new view'**
  String get pvSaveAsNewView;

  /// No description provided for @pvSaveViewAs.
  ///
  /// In en, this message translates to:
  /// **'Save view as…'**
  String get pvSaveViewAs;

  /// No description provided for @pvSavedViews.
  ///
  /// In en, this message translates to:
  /// **'Saved views'**
  String get pvSavedViews;

  /// No description provided for @pvScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get pvScale;

  /// No description provided for @pvScaleDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get pvScaleDays;

  /// No description provided for @pvScaleHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get pvScaleHours;

  /// No description provided for @pvScaleMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get pvScaleMonths;

  /// No description provided for @pvScaleWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get pvScaleWeeks;

  /// No description provided for @pvScheduleOn.
  ///
  /// In en, this message translates to:
  /// **'Schedule on…'**
  String get pvScheduleOn;

  /// No description provided for @pvScheduledSnack.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get pvScheduledSnack;

  /// No description provided for @pvScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All occurrences'**
  String get pvScopeAll;

  /// No description provided for @pvScopeFollowing.
  ///
  /// In en, this message translates to:
  /// **'This and following'**
  String get pvScopeFollowing;

  /// No description provided for @pvScopeThis.
  ///
  /// In en, this message translates to:
  /// **'This occurrence'**
  String get pvScopeThis;

  /// No description provided for @pvScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change a recurring task'**
  String get pvScopeTitle;

  /// No description provided for @pvSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String pvSelected(int count);

  /// No description provided for @pvSetAsPlanDefault.
  ///
  /// In en, this message translates to:
  /// **'Open the Plan tab on this view'**
  String get pvSetAsPlanDefault;

  /// No description provided for @pvSetDefaultView.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get pvSetDefaultView;

  /// No description provided for @pvShareAvailability.
  ///
  /// In en, this message translates to:
  /// **'Share availability'**
  String get pvShareAvailability;

  /// No description provided for @pvShowCancelled.
  ///
  /// In en, this message translates to:
  /// **'Show cancelled'**
  String get pvShowCancelled;

  /// No description provided for @pvShowCompleted.
  ///
  /// In en, this message translates to:
  /// **'Show completed'**
  String get pvShowCompleted;

  /// No description provided for @pvShowEmptyDays.
  ///
  /// In en, this message translates to:
  /// **'Show empty days'**
  String get pvShowEmptyDays;

  /// No description provided for @pvShowNotes.
  ///
  /// In en, this message translates to:
  /// **'Show notes'**
  String get pvShowNotes;

  /// No description provided for @pvShowWeekends.
  ///
  /// In en, this message translates to:
  /// **'Show weekends'**
  String get pvShowWeekends;

  /// No description provided for @pvSinceGroup.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get pvSinceGroup;

  /// No description provided for @pvSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get pvSkip;

  /// No description provided for @pvSkipRemaining.
  ///
  /// In en, this message translates to:
  /// **'Skip remaining'**
  String get pvSkipRemaining;

  /// No description provided for @pvSkipStep.
  ///
  /// In en, this message translates to:
  /// **'Skip step'**
  String get pvSkipStep;

  /// No description provided for @pvSlotCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom size'**
  String get pvSlotCustom;

  /// No description provided for @pvSlotCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Minutes or h:mm (1 min – 24 h)'**
  String get pvSlotCustomHint;

  /// No description provided for @pvSlotInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a size between 1 minute and 24 hours'**
  String get pvSlotInvalid;

  /// No description provided for @pvSlotPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get pvSlotPresets;

  /// No description provided for @pvSlotSize.
  ///
  /// In en, this message translates to:
  /// **'Slot size'**
  String get pvSlotSize;

  /// No description provided for @pvSlotsStyle.
  ///
  /// In en, this message translates to:
  /// **'Slots'**
  String get pvSlotsStyle;

  /// No description provided for @pvSnap.
  ///
  /// In en, this message translates to:
  /// **'Snap'**
  String get pvSnap;

  /// No description provided for @pvSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get pvSortBy;

  /// No description provided for @pvStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get pvStart;

  /// No description provided for @pvStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {time}'**
  String pvStartsAt(String time);

  /// No description provided for @pvStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get pvStatusCancelled;

  /// No description provided for @pvStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pvStatusDone;

  /// No description provided for @pvStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get pvStatusInProgress;

  /// No description provided for @pvStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get pvStatusMissed;

  /// No description provided for @pvStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get pvStatusScheduled;

  /// No description provided for @pvStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get pvStatusSkipped;

  /// No description provided for @pvStatusSnack.
  ///
  /// In en, this message translates to:
  /// **'Marked {status}'**
  String pvStatusSnack(String status);

  /// No description provided for @pvStatuses.
  ///
  /// In en, this message translates to:
  /// **'Statuses'**
  String get pvStatuses;

  /// No description provided for @pvStep.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String pvStep(int n, int total);

  /// No description provided for @pvStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get pvStop;

  /// No description provided for @pvSwipeVertical.
  ///
  /// In en, this message translates to:
  /// **'Swipe vertically'**
  String get pvSwipeVertical;

  /// No description provided for @pvTableThreshold.
  ///
  /// In en, this message translates to:
  /// **'Table from {size}'**
  String pvTableThreshold(String size);

  /// No description provided for @pvTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get pvTags;

  /// No description provided for @pvTextFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles and notes'**
  String get pvTextFilterHint;

  /// No description provided for @pvTileSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}, {day}, {start} to {end}, {status}'**
  String pvTileSemantics(
    String title,
    String day,
    String start,
    String end,
    String status,
  );

  /// No description provided for @pvTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{duration} left'**
  String pvTimeLeft(String duration);

  /// No description provided for @pvTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get pvTo;

  /// No description provided for @pvTopCategories.
  ///
  /// In en, this message translates to:
  /// **'Top categories'**
  String get pvTopCategories;

  /// No description provided for @pvTracked.
  ///
  /// In en, this message translates to:
  /// **'Tracked'**
  String get pvTracked;

  /// No description provided for @pvTrackingCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get pvTrackingCheck;

  /// No description provided for @pvTrackingEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get pvTrackingEvent;

  /// No description provided for @pvTrackingModes.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get pvTrackingModes;

  /// No description provided for @pvTrackingTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get pvTrackingTimer;

  /// No description provided for @pvUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get pvUnpin;

  /// No description provided for @pvUnscheduleUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Moving tasks back to the backlog isn\'t available yet'**
  String get pvUnscheduleUnsupported;

  /// No description provided for @pvUnscheduled.
  ///
  /// In en, this message translates to:
  /// **'Unscheduled'**
  String get pvUnscheduled;

  /// No description provided for @pvUntimed.
  ///
  /// In en, this message translates to:
  /// **'Untimed'**
  String get pvUntimed;

  /// No description provided for @pvUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get pvUpcoming;

  /// No description provided for @pvUrgencyRule.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Urgent within 1 day} other{Urgent within {days} days}}'**
  String pvUrgencyRule(int days);

  /// No description provided for @pvVarianceLate.
  ///
  /// In en, this message translates to:
  /// **'Started late'**
  String get pvVarianceLate;

  /// No description provided for @pvVarianceNotDone.
  ///
  /// In en, this message translates to:
  /// **'Not done'**
  String get pvVarianceNotDone;

  /// No description provided for @pvVarianceOnPlan.
  ///
  /// In en, this message translates to:
  /// **'On plan'**
  String get pvVarianceOnPlan;

  /// No description provided for @pvVarianceOverran.
  ///
  /// In en, this message translates to:
  /// **'Overran'**
  String get pvVarianceOverran;

  /// No description provided for @pvVarianceUnplanned.
  ///
  /// In en, this message translates to:
  /// **'Unplanned'**
  String get pvVarianceUnplanned;

  /// No description provided for @pvViewAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get pvViewAgenda;

  /// No description provided for @pvViewBacklog.
  ///
  /// In en, this message translates to:
  /// **'Backlog'**
  String get pvViewBacklog;

  /// No description provided for @pvViewCountdown.
  ///
  /// In en, this message translates to:
  /// **'Countdowns'**
  String get pvViewCountdown;

  /// No description provided for @pvViewDayList.
  ///
  /// In en, this message translates to:
  /// **'Day list'**
  String get pvViewDayList;

  /// No description provided for @pvViewFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get pvViewFocus;

  /// No description provided for @pvViewFreeSlots.
  ///
  /// In en, this message translates to:
  /// **'Free slots'**
  String get pvViewFreeSlots;

  /// No description provided for @pvViewHorizons.
  ///
  /// In en, this message translates to:
  /// **'Horizons'**
  String get pvViewHorizons;

  /// No description provided for @pvViewKanban.
  ///
  /// In en, this message translates to:
  /// **'Kanban'**
  String get pvViewKanban;

  /// No description provided for @pvViewLoadHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Load heatmap'**
  String get pvViewLoadHeatmap;

  /// No description provided for @pvViewMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get pvViewMap;

  /// No description provided for @pvViewMatrix.
  ///
  /// In en, this message translates to:
  /// **'Eisenhower matrix'**
  String get pvViewMatrix;

  /// No description provided for @pvViewMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get pvViewMonth;

  /// No description provided for @pvViewMultiWeek.
  ///
  /// In en, this message translates to:
  /// **'Multi-week'**
  String get pvViewMultiWeek;

  /// No description provided for @pvViewNDay.
  ///
  /// In en, this message translates to:
  /// **'N days'**
  String get pvViewNDay;

  /// No description provided for @pvViewName.
  ///
  /// In en, this message translates to:
  /// **'View name'**
  String get pvViewName;

  /// No description provided for @pvViewPlanVsActual.
  ///
  /// In en, this message translates to:
  /// **'Plan vs actual'**
  String get pvViewPlanVsActual;

  /// No description provided for @pvViewQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get pvViewQuarter;

  /// No description provided for @pvViewRadial.
  ///
  /// In en, this message translates to:
  /// **'24-hour clock'**
  String get pvViewRadial;

  /// No description provided for @pvViewRibbon.
  ///
  /// In en, this message translates to:
  /// **'Ribbon'**
  String get pvViewRibbon;

  /// No description provided for @pvViewRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine player'**
  String get pvViewRoutine;

  /// No description provided for @pvViewSaved.
  ///
  /// In en, this message translates to:
  /// **'View saved'**
  String get pvViewSaved;

  /// No description provided for @pvViewSettings.
  ///
  /// In en, this message translates to:
  /// **'View settings'**
  String get pvViewSettings;

  /// No description provided for @pvViewSwimlanes.
  ///
  /// In en, this message translates to:
  /// **'Swimlanes'**
  String get pvViewSwimlanes;

  /// No description provided for @pvViewSwitcher.
  ///
  /// In en, this message translates to:
  /// **'Change view'**
  String get pvViewSwitcher;

  /// No description provided for @pvViewTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get pvViewTable;

  /// No description provided for @pvViewTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get pvViewTimeline;

  /// No description provided for @pvViewWeekList.
  ///
  /// In en, this message translates to:
  /// **'Week list'**
  String get pvViewWeekList;

  /// No description provided for @pvViewWeekTable.
  ///
  /// In en, this message translates to:
  /// **'Week table'**
  String get pvViewWeekTable;

  /// No description provided for @pvViewWorkWeek.
  ///
  /// In en, this message translates to:
  /// **'Work week'**
  String get pvViewWorkWeek;

  /// No description provided for @pvViewYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get pvViewYear;

  /// No description provided for @pvVisibleHours.
  ///
  /// In en, this message translates to:
  /// **'Visible hours'**
  String get pvVisibleHours;

  /// No description provided for @pvVisibleHoursAll.
  ///
  /// In en, this message translates to:
  /// **'All 24 hours'**
  String get pvVisibleHoursAll;

  /// No description provided for @pvWeekNumber.
  ///
  /// In en, this message translates to:
  /// **'W{week}'**
  String pvWeekNumber(int week);

  /// No description provided for @pvWeekNumbers.
  ///
  /// In en, this message translates to:
  /// **'Week numbers'**
  String get pvWeekNumbers;

  /// No description provided for @pvWeekRibbon.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get pvWeekRibbon;

  /// No description provided for @pvWeekSummary.
  ///
  /// In en, this message translates to:
  /// **'Week summary'**
  String get pvWeekSummary;

  /// No description provided for @pvWeeksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String pvWeeksCount(int count);

  /// No description provided for @pvWithPlace.
  ///
  /// In en, this message translates to:
  /// **'Tasks with a place'**
  String get pvWithPlace;

  /// No description provided for @pvWorkDaysOnly.
  ///
  /// In en, this message translates to:
  /// **'Work days only'**
  String get pvWorkDaysOnly;

  /// No description provided for @pvWorkHours.
  ///
  /// In en, this message translates to:
  /// **'Work hours'**
  String get pvWorkHours;

  /// No description provided for @pvZoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Asia/Tokyo'**
  String get pvZoneHint;

  /// No description provided for @pvZoomAroundNow.
  ///
  /// In en, this message translates to:
  /// **'Zoom around now'**
  String get pvZoomAroundNow;

  /// No description provided for @pvZoomFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed slot'**
  String get pvZoomFixed;

  /// No description provided for @pvZoomMode.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get pvZoomMode;

  /// No description provided for @pvZoomSemantic.
  ///
  /// In en, this message translates to:
  /// **'Semantic'**
  String get pvZoomSemantic;

  /// No description provided for @quitAddUse.
  ///
  /// In en, this message translates to:
  /// **'+1'**
  String get quitAddUse;

  /// No description provided for @quitAllClocks.
  ///
  /// In en, this message translates to:
  /// **'All clocks'**
  String get quitAllClocks;

  /// No description provided for @quitAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get quitAmount;

  /// No description provided for @quitAutoSuccess.
  ///
  /// In en, this message translates to:
  /// **'Days without a relapse count as clean'**
  String get quitAutoSuccess;

  /// No description provided for @quitAutoSuccessHint.
  ///
  /// In en, this message translates to:
  /// **'Off: confirm each clean day in the evening review.'**
  String get quitAutoSuccessHint;

  /// No description provided for @quitBaseline.
  ///
  /// In en, this message translates to:
  /// **'Before quitting, per day'**
  String get quitBaseline;

  /// No description provided for @quitCleanDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 clean days} =1{1 clean day} other{{count} clean days}}'**
  String quitCleanDays(int count);

  /// No description provided for @quitCleanDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean days'**
  String get quitCleanDaysTitle;

  /// No description provided for @quitCoping.
  ///
  /// In en, this message translates to:
  /// **'What helped'**
  String get quitCoping;

  /// No description provided for @quitCopingBreathing.
  ///
  /// In en, this message translates to:
  /// **'Deep breathing'**
  String get quitCopingBreathing;

  /// No description provided for @quitCopingCallFriend.
  ///
  /// In en, this message translates to:
  /// **'Call a friend'**
  String get quitCopingCallFriend;

  /// No description provided for @quitCopingDelay10.
  ///
  /// In en, this message translates to:
  /// **'Wait 10 minutes'**
  String get quitCopingDelay10;

  /// No description provided for @quitCopingGum.
  ///
  /// In en, this message translates to:
  /// **'Chewing gum'**
  String get quitCopingGum;

  /// No description provided for @quitCopingWalk.
  ///
  /// In en, this message translates to:
  /// **'A walk'**
  String get quitCopingWalk;

  /// No description provided for @quitCopingWater.
  ///
  /// In en, this message translates to:
  /// **'Glass of water'**
  String get quitCopingWater;

  /// No description provided for @quitCostPerUnit.
  ///
  /// In en, this message translates to:
  /// **'= {price} per unit'**
  String quitCostPerUnit(String price);

  /// No description provided for @quitCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get quitCostTitle;

  /// No description provided for @quitCounterSemantics.
  ///
  /// In en, this message translates to:
  /// **'{days} days {hours} hours {minutes} minutes'**
  String quitCounterSemantics(int days, int hours, int minutes);

  /// No description provided for @quitCravingDetails.
  ///
  /// In en, this message translates to:
  /// **'Add details'**
  String get quitCravingDetails;

  /// No description provided for @quitCravingLogged.
  ///
  /// In en, this message translates to:
  /// **'Craving logged — well done for noticing it.'**
  String get quitCravingLogged;

  /// No description provided for @quitCravingTitle.
  ///
  /// In en, this message translates to:
  /// **'Craving'**
  String get quitCravingTitle;

  /// No description provided for @quitCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get quitCurrency;

  /// No description provided for @quitDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily limit'**
  String get quitDailyLimit;

  /// No description provided for @quitDayMilestonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean time'**
  String get quitDayMilestonesTitle;

  /// No description provided for @quitDaysHours.
  ///
  /// In en, this message translates to:
  /// **'{days} d {hours} h'**
  String quitDaysHours(int days, int hours);

  /// No description provided for @quitDistractionExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get quitDistractionExercise;

  /// No description provided for @quitDistractionGame.
  ///
  /// In en, this message translates to:
  /// **'A quick game'**
  String get quitDistractionGame;

  /// No description provided for @quitDistractionMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get quitDistractionMusic;

  /// No description provided for @quitDistractionRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get quitDistractionRead;

  /// No description provided for @quitDistractionShower.
  ///
  /// In en, this message translates to:
  /// **'A shower'**
  String get quitDistractionShower;

  /// No description provided for @quitDistractionSnack.
  ///
  /// In en, this message translates to:
  /// **'A healthy snack'**
  String get quitDistractionSnack;

  /// No description provided for @quitDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get quitDuration;

  /// No description provided for @quitEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit quit tracker'**
  String get quitEditorEditTitle;

  /// No description provided for @quitEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New quit tracker'**
  String get quitEditorNewTitle;

  /// No description provided for @quitErrCurrency.
  ///
  /// In en, this message translates to:
  /// **'Use a 3-letter currency code (e.g. EUR)'**
  String get quitErrCurrency;

  /// No description provided for @quitErrDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Set a daily limit of 0 or more'**
  String get quitErrDailyLimit;

  /// No description provided for @quitErrNegative.
  ///
  /// In en, this message translates to:
  /// **'Values cannot be negative'**
  String get quitErrNegative;

  /// No description provided for @quitErrStartInFuture.
  ///
  /// In en, this message translates to:
  /// **'The quit date cannot be in the future'**
  String get quitErrStartInFuture;

  /// No description provided for @quitEstimatesNote.
  ///
  /// In en, this message translates to:
  /// **'All defaults are estimates — adjust them to you.'**
  String get quitEstimatesNote;

  /// No description provided for @quitEventCraving.
  ///
  /// In en, this message translates to:
  /// **'Craving · intensity {intensity}'**
  String quitEventCraving(int intensity);

  /// No description provided for @quitEventPledge.
  ///
  /// In en, this message translates to:
  /// **'Daily pledge'**
  String get quitEventPledge;

  /// No description provided for @quitEventRelapse.
  ///
  /// In en, this message translates to:
  /// **'Relapse'**
  String get quitEventRelapse;

  /// No description provided for @quitEventRestart.
  ///
  /// In en, this message translates to:
  /// **'New quit attempt'**
  String get quitEventRestart;

  /// No description provided for @quitHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Health recovery'**
  String get quitHealthTitle;

  /// No description provided for @quitIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity: {value}/10'**
  String quitIntensity(int value);

  /// No description provided for @quitLifePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Life expectancy per unit'**
  String get quitLifePerUnit;

  /// No description provided for @quitLifeRegained.
  ///
  /// In en, this message translates to:
  /// **'Life regained'**
  String get quitLifeRegained;

  /// No description provided for @quitLogCraving.
  ///
  /// In en, this message translates to:
  /// **'Log craving'**
  String get quitLogCraving;

  /// No description provided for @quitLogRelapse.
  ///
  /// In en, this message translates to:
  /// **'Log relapse'**
  String get quitLogRelapse;

  /// No description provided for @quitLogUse.
  ///
  /// In en, this message translates to:
  /// **'Log use'**
  String get quitLogUse;

  /// No description provided for @quitLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get quitLongest;

  /// No description provided for @quitManualReset.
  ///
  /// In en, this message translates to:
  /// **'manual reset'**
  String get quitManualReset;

  /// No description provided for @quitMilestoneDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day clean} other{{count} days clean}}'**
  String quitMilestoneDays(int count);

  /// No description provided for @quitMilestoneElapsed.
  ///
  /// In en, this message translates to:
  /// **'{percent} of the time elapsed'**
  String quitMilestoneElapsed(String percent);

  /// No description provided for @quitMilestoneEta.
  ///
  /// In en, this message translates to:
  /// **'Expected {date}'**
  String quitMilestoneEta(String date);

  /// No description provided for @quitMilestoneInWindow.
  ///
  /// In en, this message translates to:
  /// **'Happening now · until about {date}'**
  String quitMilestoneInWindow(String date);

  /// No description provided for @quitMilestoneReachedOn.
  ///
  /// In en, this message translates to:
  /// **'Reached {date}'**
  String quitMilestoneReachedOn(String date);

  /// No description provided for @quitMilestoneSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get quitMilestoneSources;

  /// No description provided for @quitMilestonesClockNote.
  ///
  /// In en, this message translates to:
  /// **'Milestones count from your last lapse, so the clock restarts after one.'**
  String get quitMilestonesClockNote;

  /// No description provided for @quitMilestonesOpen.
  ///
  /// In en, this message translates to:
  /// **'All milestones'**
  String get quitMilestonesOpen;

  /// No description provided for @quitMilestonesReached.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get quitMilestonesReached;

  /// No description provided for @quitMilestonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get quitMilestonesTitle;

  /// No description provided for @quitMilestonesUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get quitMilestonesUpcoming;

  /// No description provided for @quitModeAbstain.
  ///
  /// In en, this message translates to:
  /// **'Quit completely'**
  String get quitModeAbstain;

  /// No description provided for @quitModeReduce.
  ///
  /// In en, this message translates to:
  /// **'Cut down'**
  String get quitModeReduce;

  /// No description provided for @quitModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get quitModeTitle;

  /// No description provided for @quitMoneySaved.
  ///
  /// In en, this message translates to:
  /// **'Money saved'**
  String get quitMoneySaved;

  /// No description provided for @quitMotivation.
  ///
  /// In en, this message translates to:
  /// **'Why I am quitting'**
  String get quitMotivation;

  /// No description provided for @quitMotivationCard.
  ///
  /// In en, this message translates to:
  /// **'My reasons'**
  String get quitMotivationCard;

  /// No description provided for @quitMotivationHint.
  ///
  /// In en, this message translates to:
  /// **'My reasons…'**
  String get quitMotivationHint;

  /// No description provided for @quitNameAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Stop drinking'**
  String get quitNameAlcohol;

  /// No description provided for @quitNameCaffeine.
  ///
  /// In en, this message translates to:
  /// **'Less caffeine'**
  String get quitNameCaffeine;

  /// No description provided for @quitNameCannabis.
  ///
  /// In en, this message translates to:
  /// **'Stop cannabis'**
  String get quitNameCannabis;

  /// No description provided for @quitNameCigarettes.
  ///
  /// In en, this message translates to:
  /// **'Stop smoking'**
  String get quitNameCigarettes;

  /// No description provided for @quitNameGaming.
  ///
  /// In en, this message translates to:
  /// **'Less gaming'**
  String get quitNameGaming;

  /// No description provided for @quitNameOther.
  ///
  /// In en, this message translates to:
  /// **'Quit a habit'**
  String get quitNameOther;

  /// No description provided for @quitNameSocialMedia.
  ///
  /// In en, this message translates to:
  /// **'Less social media'**
  String get quitNameSocialMedia;

  /// No description provided for @quitNameSugar.
  ///
  /// In en, this message translates to:
  /// **'Stop sugar'**
  String get quitNameSugar;

  /// No description provided for @quitNameVape.
  ///
  /// In en, this message translates to:
  /// **'Stop vaping'**
  String get quitNameVape;

  /// No description provided for @quitNextMilestone.
  ///
  /// In en, this message translates to:
  /// **'Next milestone'**
  String get quitNextMilestone;

  /// No description provided for @quitNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get quitNo;

  /// No description provided for @quitNoEvents.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet — keep going!'**
  String get quitNoEvents;

  /// No description provided for @quitNoTrackers.
  ///
  /// In en, this message translates to:
  /// **'No quit tracker yet'**
  String get quitNoTrackers;

  /// No description provided for @quitNoTrackersBody.
  ///
  /// In en, this message translates to:
  /// **'Track how long you have stopped smoking, drinking or anything else.'**
  String get quitNoTrackersBody;

  /// No description provided for @quitNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get quitNotSure;

  /// No description provided for @quitNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get quitNote;

  /// No description provided for @quitNotifInvalidIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity is a number from 1 to 10.'**
  String get quitNotifInvalidIntensity;

  /// No description provided for @quitNotifMoneyMilestone.
  ///
  /// In en, this message translates to:
  /// **'{amount} saved'**
  String quitNotifMoneyMilestone(String amount);

  /// No description provided for @quitOffsetMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String quitOffsetMonths(int count);

  /// No description provided for @quitOffsetRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String quitOffsetRange(String from, String to);

  /// No description provided for @quitOffsetWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String quitOffsetWeeks(int count);

  /// No description provided for @quitOffsetYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
  String quitOffsetYears(int count);

  /// No description provided for @quitOther.
  ///
  /// In en, this message translates to:
  /// **'Other…'**
  String get quitOther;

  /// No description provided for @quitOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Over today\'s limit'**
  String get quitOverLimit;

  /// No description provided for @quitPackPrice.
  ///
  /// In en, this message translates to:
  /// **'Pack price'**
  String get quitPackPrice;

  /// No description provided for @quitPhotoAfterSave.
  ///
  /// In en, this message translates to:
  /// **'You can add a motivating photo after saving.'**
  String get quitPhotoAfterSave;

  /// No description provided for @quitPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get quitPlace;

  /// No description provided for @quitPlaceBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get quitPlaceBar;

  /// No description provided for @quitPlaceCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get quitPlaceCar;

  /// No description provided for @quitPlaceFriends.
  ///
  /// In en, this message translates to:
  /// **'At friends\''**
  String get quitPlaceFriends;

  /// No description provided for @quitPlaceHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get quitPlaceHome;

  /// No description provided for @quitPlaceOutside.
  ///
  /// In en, this message translates to:
  /// **'Outside'**
  String get quitPlaceOutside;

  /// No description provided for @quitPlaceWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get quitPlaceWork;

  /// No description provided for @quitPopulationEstimate.
  ///
  /// In en, this message translates to:
  /// **'population estimate'**
  String get quitPopulationEstimate;

  /// No description provided for @quitPopulationEstimateHelp.
  ///
  /// In en, this message translates to:
  /// **'Population estimate: about 20 min per cigarette (Jackson et al. 2025; BMJ 2000: 11 min). Individual effects vary.'**
  String get quitPopulationEstimateHelp;

  /// No description provided for @quitPresetAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get quitPresetAlcohol;

  /// No description provided for @quitPresetCaffeine.
  ///
  /// In en, this message translates to:
  /// **'Caffeine'**
  String get quitPresetCaffeine;

  /// No description provided for @quitPresetCannabis.
  ///
  /// In en, this message translates to:
  /// **'Cannabis'**
  String get quitPresetCannabis;

  /// No description provided for @quitPresetCigarettes.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get quitPresetCigarettes;

  /// No description provided for @quitPresetGaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get quitPresetGaming;

  /// No description provided for @quitPresetOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get quitPresetOther;

  /// No description provided for @quitPresetSocialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social media'**
  String get quitPresetSocialMedia;

  /// No description provided for @quitPresetSugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get quitPresetSugar;

  /// No description provided for @quitPresetTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to quit?'**
  String get quitPresetTitle;

  /// No description provided for @quitPresetVape.
  ///
  /// In en, this message translates to:
  /// **'Vaping'**
  String get quitPresetVape;

  /// No description provided for @quitRecentEvents.
  ///
  /// In en, this message translates to:
  /// **'Recent events'**
  String get quitRecentEvents;

  /// No description provided for @quitRelapseAmount.
  ///
  /// In en, this message translates to:
  /// **'How many? (optional)'**
  String get quitRelapseAmount;

  /// No description provided for @quitRelapseKindTitle.
  ///
  /// In en, this message translates to:
  /// **'How should it count?'**
  String get quitRelapseKindTitle;

  /// No description provided for @quitRelapseNewAttempt.
  ///
  /// In en, this message translates to:
  /// **'Start a new quit attempt from {time}'**
  String quitRelapseNewAttempt(String time);

  /// No description provided for @quitRelapseSaved.
  ///
  /// In en, this message translates to:
  /// **'Logged. Be kind to yourself — every attempt teaches you something.'**
  String get quitRelapseSaved;

  /// No description provided for @quitRelapseSlip.
  ///
  /// In en, this message translates to:
  /// **'As a slip — keep my quit date; the streak restarts now'**
  String get quitRelapseSlip;

  /// No description provided for @quitRelapseSupport.
  ///
  /// In en, this message translates to:
  /// **'You stayed clean for {duration} — that still counts.'**
  String quitRelapseSupport(String duration);

  /// No description provided for @quitRelapseTitle.
  ///
  /// In en, this message translates to:
  /// **'Log a relapse'**
  String get quitRelapseTitle;

  /// No description provided for @quitResetBody.
  ///
  /// In en, this message translates to:
  /// **'This logs a relapse now. Your quit date stays the same.'**
  String get quitResetBody;

  /// No description provided for @quitResetCounter.
  ///
  /// In en, this message translates to:
  /// **'Reset counter'**
  String get quitResetCounter;

  /// No description provided for @quitResisted.
  ///
  /// In en, this message translates to:
  /// **'Did you resist?'**
  String get quitResisted;

  /// No description provided for @quitSinceFirstQuit.
  ///
  /// In en, this message translates to:
  /// **'Since you first quit'**
  String get quitSinceFirstQuit;

  /// No description provided for @quitSinceLastRelapse.
  ///
  /// In en, this message translates to:
  /// **'Clean for'**
  String get quitSinceLastRelapse;

  /// No description provided for @quitSinceLastUse.
  ///
  /// In en, this message translates to:
  /// **'Since the last use'**
  String get quitSinceLastUse;

  /// No description provided for @quitStartedAt.
  ///
  /// In en, this message translates to:
  /// **'I quit on'**
  String get quitStartedAt;

  /// No description provided for @quitTimePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Time spent per unit'**
  String get quitTimePerUnit;

  /// No description provided for @quitTimeWonBack.
  ///
  /// In en, this message translates to:
  /// **'Time won back'**
  String get quitTimeWonBack;

  /// No description provided for @quitTodayUse.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} today'**
  String quitTodayUse(String used, String limit);

  /// No description provided for @quitTrigger.
  ///
  /// In en, this message translates to:
  /// **'Trigger'**
  String get quitTrigger;

  /// No description provided for @quitTriggerAfterMeals.
  ///
  /// In en, this message translates to:
  /// **'After meals'**
  String get quitTriggerAfterMeals;

  /// No description provided for @quitTriggerAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get quitTriggerAlcohol;

  /// No description provided for @quitTriggerBoredom.
  ///
  /// In en, this message translates to:
  /// **'Boredom'**
  String get quitTriggerBoredom;

  /// No description provided for @quitTriggerCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get quitTriggerCoffee;

  /// No description provided for @quitTriggerDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get quitTriggerDriving;

  /// No description provided for @quitTriggerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get quitTriggerPhone;

  /// No description provided for @quitTriggerSocial.
  ///
  /// In en, this message translates to:
  /// **'Social situations'**
  String get quitTriggerSocial;

  /// No description provided for @quitTriggerStress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get quitTriggerStress;

  /// No description provided for @quitTriggerWakingUp.
  ///
  /// In en, this message translates to:
  /// **'Waking up'**
  String get quitTriggerWakingUp;

  /// No description provided for @quitTriggerWorkBreak.
  ///
  /// In en, this message translates to:
  /// **'Work break'**
  String get quitTriggerWorkBreak;

  /// No description provided for @quitUnitCost.
  ///
  /// In en, this message translates to:
  /// **'Price per unit'**
  String get quitUnitCost;

  /// No description provided for @quitUnitDays.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get quitUnitDays;

  /// No description provided for @quitUnitHours.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get quitUnitHours;

  /// No description provided for @quitUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get quitUnitMinutes;

  /// No description provided for @quitUnitSeconds.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get quitUnitSeconds;

  /// No description provided for @quitUnitsAvoided.
  ///
  /// In en, this message translates to:
  /// **'Avoided'**
  String get quitUnitsAvoided;

  /// No description provided for @quitUnitsPerPack.
  ///
  /// In en, this message translates to:
  /// **'Units per pack'**
  String get quitUnitsPerPack;

  /// No description provided for @quitUseLogged.
  ///
  /// In en, this message translates to:
  /// **'Use logged'**
  String get quitUseLogged;

  /// No description provided for @quitWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get quitWhen;

  /// No description provided for @quitWithdrawalNow.
  ///
  /// In en, this message translates to:
  /// **'Where you are now'**
  String get quitWithdrawalNow;

  /// No description provided for @quitWithdrawalTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get quitWithdrawalTitle;

  /// No description provided for @quitWithinLimitStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Days within the limit'**
  String get quitWithinLimitStreakTitle;

  /// No description provided for @quitYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get quitYes;

  /// No description provided for @recurAddDate.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get recurAddDate;

  /// No description provided for @recurAddOrdinal.
  ///
  /// In en, this message translates to:
  /// **'Add a day like “2nd Tuesday”'**
  String get recurAddOrdinal;

  /// No description provided for @recurAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get recurAddTime;

  /// No description provided for @recurAdvancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom repeat'**
  String get recurAdvancedTitle;

  /// No description provided for @recurAfterHint.
  ///
  /// In en, this message translates to:
  /// **'The next one is due this long after you complete the previous one.'**
  String get recurAfterHint;

  /// No description provided for @recurAfterPreview.
  ///
  /// In en, this message translates to:
  /// **'The next ones depend on when you complete it'**
  String get recurAfterPreview;

  /// No description provided for @recurAnchorMoved.
  ///
  /// In en, this message translates to:
  /// **'First occurrence: {date}'**
  String recurAnchorMoved(String date);

  /// No description provided for @recurCalendarSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no day with occurrences} =1{1 day with occurrences} other{{count} days with occurrences}}'**
  String recurCalendarSummary(int count);

  /// No description provided for @recurCountCompletions.
  ///
  /// In en, this message translates to:
  /// **'Completions'**
  String get recurCountCompletions;

  /// No description provided for @recurCountMode.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get recurCountMode;

  /// No description provided for @recurCountOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Occurrences'**
  String get recurCountOccurrences;

  /// No description provided for @recurCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current rule'**
  String get recurCurrent;

  /// No description provided for @recurCustomValue.
  ///
  /// In en, this message translates to:
  /// **'Other value…'**
  String get recurCustomValue;

  /// No description provided for @recurEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get recurEnds;

  /// No description provided for @recurEndsAfter.
  ///
  /// In en, this message translates to:
  /// **'After a number of times'**
  String get recurEndsAfter;

  /// No description provided for @recurEndsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String recurEndsCount(int count);

  /// No description provided for @recurEndsNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get recurEndsNever;

  /// No description provided for @recurEndsOn.
  ///
  /// In en, this message translates to:
  /// **'On a date'**
  String get recurEndsOn;

  /// No description provided for @recurExceptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get recurExceptionCancelled;

  /// No description provided for @recurExceptionEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get recurExceptionEdited;

  /// No description provided for @recurExceptionExcluded.
  ///
  /// In en, this message translates to:
  /// **'Excluded'**
  String get recurExceptionExcluded;

  /// No description provided for @recurExceptionMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved to {to}'**
  String recurExceptionMoved(String to);

  /// No description provided for @recurExceptionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get recurExceptionOpen;

  /// No description provided for @recurExceptionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get recurExceptionRestore;

  /// No description provided for @recurExceptionRestoreAll.
  ///
  /// In en, this message translates to:
  /// **'Restore all'**
  String get recurExceptionRestoreAll;

  /// No description provided for @recurExceptionRestoreAllTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Restore 1 occurrence?} other{Restore {count} occurrences?}}'**
  String recurExceptionRestoreAllTitle(int count);

  /// No description provided for @recurExceptionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No skipped or moved occurrences'**
  String get recurExceptionsEmpty;

  /// No description provided for @recurExceptionsRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get recurExceptionsRestored;

  /// No description provided for @recurExceptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Skipped & moved occurrences'**
  String get recurExceptionsTitle;

  /// No description provided for @recurExdates.
  ///
  /// In en, this message translates to:
  /// **'Excluded occurrences'**
  String get recurExdates;

  /// No description provided for @recurFloatingNote.
  ///
  /// In en, this message translates to:
  /// **'Times follow your current time zone'**
  String get recurFloatingNote;

  /// No description provided for @recurFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get recurFrequency;

  /// No description provided for @recurHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get recurHours;

  /// No description provided for @recurInterval.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get recurInterval;

  /// No description provided for @recurIssueCount.
  ///
  /// In en, this message translates to:
  /// **'The number of times must be at least 1'**
  String get recurIssueCount;

  /// No description provided for @recurIssueCountAndUntil.
  ///
  /// In en, this message translates to:
  /// **'Choose either an end date or a number of times'**
  String get recurIssueCountAndUntil;

  /// No description provided for @recurIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get recurIssueDate;

  /// No description provided for @recurIssueEmptyWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Select at least one day'**
  String get recurIssueEmptyWeekdays;

  /// No description provided for @recurIssueInterval.
  ///
  /// In en, this message translates to:
  /// **'The interval must be at least 1'**
  String get recurIssueInterval;

  /// No description provided for @recurIssueMissing.
  ///
  /// In en, this message translates to:
  /// **'The rule is incomplete'**
  String get recurIssueMissing;

  /// No description provided for @recurIssueOrdinal.
  ///
  /// In en, this message translates to:
  /// **'“1st”, “last”… only work with monthly or yearly repeats'**
  String get recurIssueOrdinal;

  /// No description provided for @recurIssueQuota.
  ///
  /// In en, this message translates to:
  /// **'This quota can\'t be met with that gap ({max} max)'**
  String recurIssueQuota(int max);

  /// No description provided for @recurIssueTooFrequent.
  ///
  /// In en, this message translates to:
  /// **'Too frequent: {count} per day (1440 max)'**
  String recurIssueTooFrequent(int count);

  /// No description provided for @recurIssueUnsupported.
  ///
  /// In en, this message translates to:
  /// **'These options can\'t be combined'**
  String get recurIssueUnsupported;

  /// No description provided for @recurIssueUntilBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The end date is before the start'**
  String get recurIssueUntilBeforeStart;

  /// No description provided for @recurIssueValue.
  ///
  /// In en, this message translates to:
  /// **'A value is out of range'**
  String get recurIssueValue;

  /// No description provided for @recurIssueWindow.
  ///
  /// In en, this message translates to:
  /// **'The window must end after it starts'**
  String get recurIssueWindow;

  /// No description provided for @recurLess.
  ///
  /// In en, this message translates to:
  /// **'Fewer options'**
  String get recurLess;

  /// No description provided for @recurMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get recurMinutes;

  /// No description provided for @recurMonthDayFromEnd.
  ///
  /// In en, this message translates to:
  /// **'Day {day} from the end'**
  String recurMonthDayFromEnd(int day);

  /// No description provided for @recurMonthDays.
  ///
  /// In en, this message translates to:
  /// **'Days of the month'**
  String get recurMonthDays;

  /// No description provided for @recurMonthDaysFromEnd.
  ///
  /// In en, this message translates to:
  /// **'Counting from the end'**
  String get recurMonthDaysFromEnd;

  /// No description provided for @recurMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get recurMonths;

  /// No description provided for @recurMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get recurMore;

  /// No description provided for @recurNumbersHint.
  ///
  /// In en, this message translates to:
  /// **'Numbers separated by commas (negative = from the end)'**
  String get recurNumbersHint;

  /// No description provided for @recurOrdinal1.
  ///
  /// In en, this message translates to:
  /// **'1st'**
  String get recurOrdinal1;

  /// No description provided for @recurOrdinal2.
  ///
  /// In en, this message translates to:
  /// **'2nd'**
  String get recurOrdinal2;

  /// No description provided for @recurOrdinal3.
  ///
  /// In en, this message translates to:
  /// **'3rd'**
  String get recurOrdinal3;

  /// No description provided for @recurOrdinal4.
  ///
  /// In en, this message translates to:
  /// **'4th'**
  String get recurOrdinal4;

  /// No description provided for @recurOrdinal5.
  ///
  /// In en, this message translates to:
  /// **'5th'**
  String get recurOrdinal5;

  /// No description provided for @recurOrdinalEvery.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get recurOrdinalEvery;

  /// No description provided for @recurOrdinalLast.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get recurOrdinalLast;

  /// No description provided for @recurOrdinalPick.
  ///
  /// In en, this message translates to:
  /// **'Which day?'**
  String get recurOrdinalPick;

  /// No description provided for @recurOrdinalSecondLast.
  ///
  /// In en, this message translates to:
  /// **'2nd to last'**
  String get recurOrdinalSecondLast;

  /// No description provided for @recurOrdinalWeekday.
  ///
  /// In en, this message translates to:
  /// **'{ordinal} {weekday}'**
  String recurOrdinalWeekday(String ordinal, String weekday);

  /// No description provided for @recurOverflow.
  ///
  /// In en, this message translates to:
  /// **'When a month is too short'**
  String get recurOverflow;

  /// No description provided for @recurOverflowClamp.
  ///
  /// In en, this message translates to:
  /// **'Use its last day'**
  String get recurOverflowClamp;

  /// No description provided for @recurOverflowSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip that month'**
  String get recurOverflowSkip;

  /// No description provided for @recurPerDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get recurPerDay;

  /// No description provided for @recurPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get recurPerMonth;

  /// No description provided for @recurPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get recurPerWeek;

  /// No description provided for @recurPerYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get recurPerYear;

  /// No description provided for @recurPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String recurPeriodWeek(String date);

  /// No description provided for @recurPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get recurPickerTitle;

  /// No description provided for @recurPresetAfterCompletion.
  ///
  /// In en, this message translates to:
  /// **'After completion…'**
  String get recurPresetAfterCompletion;

  /// No description provided for @recurPresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get recurPresetCustom;

  /// No description provided for @recurPresetEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'Every few days…'**
  String get recurPresetEveryNDays;

  /// No description provided for @recurPresetIntraday.
  ///
  /// In en, this message translates to:
  /// **'Every few hours or minutes…'**
  String get recurPresetIntraday;

  /// No description provided for @recurPresetNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get recurPresetNone;

  /// No description provided for @recurPresetQuota.
  ///
  /// In en, this message translates to:
  /// **'Several times per week or month…'**
  String get recurPresetQuota;

  /// No description provided for @recurPresetSpecificDays.
  ///
  /// In en, this message translates to:
  /// **'Specific days…'**
  String get recurPresetSpecificDays;

  /// No description provided for @recurPresetTimesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Several times a day…'**
  String get recurPresetTimesPerDay;

  /// No description provided for @recurPreview.
  ///
  /// In en, this message translates to:
  /// **'Next occurrences'**
  String get recurPreview;

  /// No description provided for @recurPreviewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Next 60 days'**
  String get recurPreviewCalendar;

  /// No description provided for @recurPreviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming occurrence'**
  String get recurPreviewEmpty;

  /// No description provided for @recurQuotaMinGap.
  ///
  /// In en, this message translates to:
  /// **'Minimum days between'**
  String get recurQuotaMinGap;

  /// No description provided for @recurQuotaOnDays.
  ///
  /// In en, this message translates to:
  /// **'Only on these days'**
  String get recurQuotaOnDays;

  /// No description provided for @recurQuotaPer.
  ///
  /// In en, this message translates to:
  /// **'Per'**
  String get recurQuotaPer;

  /// No description provided for @recurQuotaTimes.
  ///
  /// In en, this message translates to:
  /// **'How many times'**
  String get recurQuotaTimes;

  /// No description provided for @recurRdates.
  ///
  /// In en, this message translates to:
  /// **'Extra occurrences'**
  String get recurRdates;

  /// No description provided for @recurRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {item}'**
  String recurRemove(String item);

  /// No description provided for @recurRemoveTime.
  ///
  /// In en, this message translates to:
  /// **'Remove {time}'**
  String recurRemoveTime(String time);

  /// No description provided for @recurSetPos.
  ///
  /// In en, this message translates to:
  /// **'Keep only positions'**
  String get recurSetPos;

  /// No description provided for @recurSetPosHint.
  ///
  /// In en, this message translates to:
  /// **'1 = first, −1 = last matching date of each period'**
  String get recurSetPosHint;

  /// No description provided for @recurSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get recurSummary;

  /// No description provided for @recurTimes.
  ///
  /// In en, this message translates to:
  /// **'Times of day'**
  String get recurTimes;

  /// No description provided for @recurTimesDefault.
  ///
  /// In en, this message translates to:
  /// **'At the start time ({time})'**
  String recurTimesDefault(String time);

  /// No description provided for @recurType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get recurType;

  /// No description provided for @recurTypeAfter.
  ///
  /// In en, this message translates to:
  /// **'After completion'**
  String get recurTypeAfter;

  /// No description provided for @recurTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get recurTypeFixed;

  /// No description provided for @recurTypeQuota.
  ///
  /// In en, this message translates to:
  /// **'Quota'**
  String get recurTypeQuota;

  /// No description provided for @recurUnitDay.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get recurUnitDay;

  /// No description provided for @recurUnitHour.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get recurUnitHour;

  /// No description provided for @recurUnitMinute.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get recurUnitMinute;

  /// No description provided for @recurUnitMonth.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get recurUnitMonth;

  /// No description provided for @recurUnitWeek.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get recurUnitWeek;

  /// No description provided for @recurUnitYear.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get recurUnitYear;

  /// No description provided for @recurWarnAllDaySubDaily.
  ///
  /// In en, this message translates to:
  /// **'All-day items can\'t repeat within a day'**
  String get recurWarnAllDaySubDaily;

  /// No description provided for @recurWarnDst.
  ///
  /// In en, this message translates to:
  /// **'Some times fall in a daylight-saving change and are shifted'**
  String get recurWarnDst;

  /// No description provided for @recurWarnNever.
  ///
  /// In en, this message translates to:
  /// **'Never occurs in the next 5 years'**
  String get recurWarnNever;

  /// No description provided for @recurWarnPerDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 occurrence per day} other{{count} occurrences per day}}'**
  String recurWarnPerDay(int count);

  /// No description provided for @recurWeekNumbers.
  ///
  /// In en, this message translates to:
  /// **'Week numbers'**
  String get recurWeekNumbers;

  /// No description provided for @recurWeekStart.
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get recurWeekStart;

  /// No description provided for @recurWeekdayOrdinal.
  ///
  /// In en, this message translates to:
  /// **'Which one in the period'**
  String get recurWeekdayOrdinal;

  /// No description provided for @recurWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Days of the week'**
  String get recurWeekdays;

  /// No description provided for @recurWindow.
  ///
  /// In en, this message translates to:
  /// **'Daily window'**
  String get recurWindow;

  /// No description provided for @recurWindowAnchorSeries.
  ///
  /// In en, this message translates to:
  /// **'Continue the chain from the first occurrence'**
  String get recurWindowAnchorSeries;

  /// No description provided for @recurWindowAnchorWindow.
  ///
  /// In en, this message translates to:
  /// **'Restart each day at the window start'**
  String get recurWindowAnchorWindow;

  /// No description provided for @recurWindowEnd.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get recurWindowEnd;

  /// No description provided for @recurWindowNone.
  ///
  /// In en, this message translates to:
  /// **'Whole day'**
  String get recurWindowNone;

  /// No description provided for @recurWindowStart.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get recurWindowStart;

  /// No description provided for @recurYearDays.
  ///
  /// In en, this message translates to:
  /// **'Days of the year'**
  String get recurYearDays;

  /// No description provided for @recurZoneNote.
  ///
  /// In en, this message translates to:
  /// **'Times in {zone}'**
  String recurZoneNote(String zone);

  /// No description provided for @redoDoneSnack.
  ///
  /// In en, this message translates to:
  /// **'Redone: {action}'**
  String redoDoneSnack(String action);

  /// No description provided for @redoNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to redo'**
  String get redoNothing;

  /// No description provided for @relativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{yesterday} other{{count} days ago}}'**
  String relativeDaysAgo(int count);

  /// No description provided for @relativeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String relativeHoursAgo(int count);

  /// No description provided for @relativeInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{tomorrow} other{in {count} days}}'**
  String relativeInDays(int count);

  /// No description provided for @relativeInHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 hour} other{in {count} hours}}'**
  String relativeInHours(int count);

  /// No description provided for @relativeInMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 minute} other{in {count} minutes}}'**
  String relativeInMinutes(int count);

  /// No description provided for @relativeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String relativeMinutesAgo(int count);

  /// No description provided for @relativeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get relativeNow;

  /// No description provided for @repeatChip.
  ///
  /// In en, this message translates to:
  /// **'Resets {rule} · next {when}'**
  String repeatChip(String rule, String when);

  /// No description provided for @repeatCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom rule'**
  String get repeatCustom;

  /// No description provided for @repeatModeAll.
  ///
  /// In en, this message translates to:
  /// **'Everything back to to-do'**
  String get repeatModeAll;

  /// No description provided for @repeatModeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Uncheck completed items only'**
  String get repeatModeCompleted;

  /// No description provided for @repeatNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No finished runs yet'**
  String get repeatNoRuns;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t repeat'**
  String get repeatNone;

  /// No description provided for @repeatResetTime.
  ///
  /// In en, this message translates to:
  /// **'Reset time'**
  String get repeatResetTime;

  /// No description provided for @repeatRunSummary.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} done'**
  String repeatRunSummary(int done, int total);

  /// No description provided for @repeatRuns.
  ///
  /// In en, this message translates to:
  /// **'Run history'**
  String get repeatRuns;

  /// No description provided for @repeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatTitle;

  /// No description provided for @savedSnack.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedSnack;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, licenses, help'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get settingsAccessibility;

  /// No description provided for @settingsAccessibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Motion, haptics, contrast, labels'**
  String get settingsAccessibilitySubtitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsAccountLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'On this device only'**
  String get settingsAccountLocalOnly;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, density, language'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsArabicDigits.
  ///
  /// In en, this message translates to:
  /// **'Arabic-Indic digits'**
  String get settingsArabicDigits;

  /// No description provided for @settingsArabicDigitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show ٠١٢٣ instead of 0123 when the app is in Arabic'**
  String get settingsArabicDigitsSubtitle;

  /// No description provided for @settingsAutoComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete parents automatically'**
  String get settingsAutoComplete;

  /// No description provided for @settingsCascadeAlways.
  ///
  /// In en, this message translates to:
  /// **'Complete sub-items too'**
  String get settingsCascadeAlways;

  /// No description provided for @settingsCascadeAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get settingsCascadeAsk;

  /// No description provided for @settingsCascadeNever.
  ///
  /// In en, this message translates to:
  /// **'Leave sub-items'**
  String get settingsCascadeNever;

  /// No description provided for @settingsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get settingsCategory;

  /// No description provided for @settingsClock.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get settingsClock;

  /// No description provided for @settingsClock12.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get settingsClock12;

  /// No description provided for @settingsClock24.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get settingsClock24;

  /// No description provided for @settingsCompleteChildren.
  ///
  /// In en, this message translates to:
  /// **'When completing a parent'**
  String get settingsCompleteChildren;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency for quit savings'**
  String get settingsCurrency;

  /// No description provided for @settingsCurrentZone.
  ///
  /// In en, this message translates to:
  /// **'Current time zone (this device)'**
  String get settingsCurrentZone;

  /// No description provided for @settingsDayStart.
  ///
  /// In en, this message translates to:
  /// **'Habit day starts at'**
  String get settingsDayStart;

  /// No description provided for @settingsDayStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check-ins before this time count for the previous day. Applies to new check-ins only.'**
  String get settingsDayStartSubtitle;

  /// No description provided for @settingsDefaultOpen.
  ///
  /// In en, this message translates to:
  /// **'Open in'**
  String get settingsDefaultOpen;

  /// No description provided for @settingsDensity.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get settingsDensity;

  /// No description provided for @settingsDensityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get settingsDensityComfortable;

  /// No description provided for @settingsDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get settingsDensityCompact;

  /// No description provided for @settingsDeviceLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {when}'**
  String settingsDeviceLastSeen(String when);

  /// No description provided for @settingsDevicePushOff.
  ///
  /// In en, this message translates to:
  /// **'Push notifications off'**
  String get settingsDevicePushOff;

  /// No description provided for @settingsDevicePushOn.
  ///
  /// In en, this message translates to:
  /// **'Push notifications on'**
  String get settingsDevicePushOn;

  /// No description provided for @settingsDeviceRevoke.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get settingsDeviceRevoke;

  /// No description provided for @settingsDeviceRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'It stops receiving notifications and is signed out the next time it connects.'**
  String get settingsDeviceRevokeBody;

  /// No description provided for @settingsDeviceRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String settingsDeviceRevokeTitle(String name);

  /// No description provided for @settingsDeviceRevoked.
  ///
  /// In en, this message translates to:
  /// **'Device removed'**
  String get settingsDeviceRevoked;

  /// No description provided for @settingsDeviceThis.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get settingsDeviceThis;

  /// No description provided for @settingsDeviceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get settingsDeviceUnknown;

  /// No description provided for @settingsDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get settingsDevices;

  /// No description provided for @settingsDevicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No devices registered yet.'**
  String get settingsDevicesEmpty;

  /// No description provided for @settingsDevicesOffline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to see your devices.'**
  String get settingsDevicesOffline;

  /// No description provided for @settingsGroupData.
  ///
  /// In en, this message translates to:
  /// **'Data & privacy'**
  String get settingsGroupData;

  /// No description provided for @settingsGroupGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGroupGeneral;

  /// No description provided for @settingsGroupHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsGroupHelp;

  /// No description provided for @settingsGroupSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get settingsGroupSections;

  /// No description provided for @settingsHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get settingsHabits;

  /// No description provided for @settingsHabitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skip policy, streak freezes'**
  String get settingsHabitsSubtitle;

  /// No description provided for @settingsHideCheckboxes.
  ///
  /// In en, this message translates to:
  /// **'Hide checkboxes (bullets)'**
  String get settingsHideCheckboxes;

  /// No description provided for @settingsHomeZone.
  ///
  /// In en, this message translates to:
  /// **'Home time zone'**
  String get settingsHomeZone;

  /// No description provided for @settingsHomeZoneAuto.
  ///
  /// In en, this message translates to:
  /// **'Follow this device'**
  String get settingsHomeZoneAuto;

  /// No description provided for @settingsHomeZoneAutoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update the home zone automatically when you travel'**
  String get settingsHomeZoneAutoSubtitle;

  /// No description provided for @settingsHomeZoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fixed-time tasks and habits use this zone'**
  String get settingsHomeZoneSubtitle;

  /// No description provided for @settingsInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get settingsInsights;

  /// No description provided for @settingsInsightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default period, comparisons'**
  String get settingsInsightsSubtitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get settingsLanguageArabic;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get settingsLanguageFrench;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get settingsLists;

  /// No description provided for @settingsListsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Statuses, progress, completed items'**
  String get settingsListsSubtitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders, quiet hours, inbox'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsOrganizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Categories and tags used across the app'**
  String get settingsOrganizationSubtitle;

  /// No description provided for @settingsPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get settingsPlan;

  /// No description provided for @settingsPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default view, durations, work hours'**
  String get settingsPlanSubtitle;

  /// No description provided for @settingsPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get settingsPreview;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'App lock, hidden notification content'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsProgressChildren.
  ///
  /// In en, this message translates to:
  /// **'Direct sub-items only'**
  String get settingsProgressChildren;

  /// No description provided for @settingsProgressLeaves.
  ///
  /// In en, this message translates to:
  /// **'All sub-items'**
  String get settingsProgressLeaves;

  /// No description provided for @settingsProgressMode.
  ///
  /// In en, this message translates to:
  /// **'Progress counts'**
  String get settingsProgressMode;

  /// No description provided for @settingsRegional.
  ///
  /// In en, this message translates to:
  /// **'Regional'**
  String get settingsRegional;

  /// No description provided for @settingsRegionalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Time zone, week start, clock, currency'**
  String get settingsRegionalSubtitle;

  /// No description provided for @settingsRequireReason.
  ///
  /// In en, this message translates to:
  /// **'Require a reason for'**
  String get settingsRequireReason;

  /// No description provided for @settingsShowAttachments.
  ///
  /// In en, this message translates to:
  /// **'Show attachments in preview'**
  String get settingsShowAttachments;

  /// No description provided for @settingsShowNotes.
  ///
  /// In en, this message translates to:
  /// **'Show notes in preview'**
  String get settingsShowNotes;

  /// No description provided for @settingsSortCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sort completed to bottom'**
  String get settingsSortCompleted;

  /// No description provided for @settingsStaleDays.
  ///
  /// In en, this message translates to:
  /// **'Mark stale after {days} days'**
  String settingsStaleDays(int days);

  /// No description provided for @settingsSwipeComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get settingsSwipeComplete;

  /// No description provided for @settingsSwipeEditLeft.
  ///
  /// In en, this message translates to:
  /// **'Edit mode · swipe left'**
  String get settingsSwipeEditLeft;

  /// No description provided for @settingsSwipeEditRight.
  ///
  /// In en, this message translates to:
  /// **'Edit mode · swipe right'**
  String get settingsSwipeEditRight;

  /// No description provided for @settingsSwipeIndent.
  ///
  /// In en, this message translates to:
  /// **'Indent'**
  String get settingsSwipeIndent;

  /// No description provided for @settingsSwipeMenu.
  ///
  /// In en, this message translates to:
  /// **'Actions menu'**
  String get settingsSwipeMenu;

  /// No description provided for @settingsSwipeNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get settingsSwipeNone;

  /// No description provided for @settingsSwipeOutdent.
  ///
  /// In en, this message translates to:
  /// **'Outdent'**
  String get settingsSwipeOutdent;

  /// No description provided for @settingsSwipePreviewLeft.
  ///
  /// In en, this message translates to:
  /// **'Preview · swipe left'**
  String get settingsSwipePreviewLeft;

  /// No description provided for @settingsSwipePreviewRight.
  ///
  /// In en, this message translates to:
  /// **'Preview · swipe right'**
  String get settingsSwipePreviewRight;

  /// No description provided for @settingsSwipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe actions'**
  String get settingsSwipeTitle;

  /// No description provided for @settingsSyncData.
  ///
  /// In en, this message translates to:
  /// **'Sync & data'**
  String get settingsSyncData;

  /// No description provided for @settingsSyncDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Devices, export, import, trash'**
  String get settingsSyncDataSubtitle;

  /// No description provided for @settingsSyncDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Sync diagnostics'**
  String get settingsSyncDiagnostics;

  /// No description provided for @settingsSyncDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The server\'s version of these items is restored on this device.'**
  String get settingsSyncDiscardBody;

  /// No description provided for @settingsSyncDiscardFailed.
  ///
  /// In en, this message translates to:
  /// **'Discard rejected changes'**
  String get settingsSyncDiscardFailed;

  /// No description provided for @settingsSyncDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard rejected changes?'**
  String get settingsSyncDiscardTitle;

  /// No description provided for @settingsSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change was rejected by the server} other{{count} changes were rejected by the server}}'**
  String settingsSyncFailed(int count);

  /// No description provided for @settingsSyncInitialProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading your data… {percent}%'**
  String settingsSyncInitialProgress(int percent);

  /// No description provided for @settingsSyncLastError.
  ///
  /// In en, this message translates to:
  /// **'Last error'**
  String get settingsSyncLastError;

  /// No description provided for @settingsSyncLastSuccess.
  ///
  /// In en, this message translates to:
  /// **'Last synced {when}'**
  String settingsSyncLastSuccess(String when);

  /// No description provided for @settingsSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get settingsSyncNever;

  /// No description provided for @settingsSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get settingsSyncNow;

  /// No description provided for @settingsSyncOffBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored on this device only.'**
  String get settingsSyncOffBody;

  /// No description provided for @settingsSyncOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync is off'**
  String get settingsSyncOffTitle;

  /// No description provided for @settingsSyncRefreshLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Everything is saved on this device.'**
  String get settingsSyncRefreshLocalOnly;

  /// No description provided for @settingsSyncResync.
  ///
  /// In en, this message translates to:
  /// **'Force full resync'**
  String get settingsSyncResync;

  /// No description provided for @settingsSyncResyncBody.
  ///
  /// In en, this message translates to:
  /// **'Everslot downloads all your data again. Changes that haven\'t synced yet are kept.'**
  String get settingsSyncResyncBody;

  /// No description provided for @settingsSyncResyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Resync everything?'**
  String get settingsSyncResyncTitle;

  /// No description provided for @settingsSyncRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry rejected changes'**
  String get settingsSyncRetryFailed;

  /// No description provided for @settingsSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get settingsSyncStatus;

  /// No description provided for @settingsSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync & devices'**
  String get settingsSyncTitle;

  /// No description provided for @settingsSyncTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get settingsSyncTooltip;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get settingsTrash;

  /// No description provided for @settingsUnknownPage.
  ///
  /// In en, this message translates to:
  /// **'This settings page doesn\'t exist.'**
  String get settingsUnknownPage;

  /// No description provided for @settingsWeekStart.
  ///
  /// In en, this message translates to:
  /// **'Week starts on'**
  String get settingsWeekStart;

  /// No description provided for @smartBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get smartBlocked;

  /// No description provided for @smartChip.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count}'**
  String smartChip(String label, int count);

  /// No description provided for @smartClearFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Clear follow-up'**
  String get smartClearFollowUp;

  /// No description provided for @smartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here — nice.'**
  String get smartEmpty;

  /// No description provided for @smartFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Follow-ups'**
  String get smartFollowUps;

  /// No description provided for @smartGroupByList.
  ///
  /// In en, this message translates to:
  /// **'Group by list'**
  String get smartGroupByList;

  /// No description provided for @smartOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get smartOngoing;

  /// No description provided for @smartOpenInList.
  ///
  /// In en, this message translates to:
  /// **'Open in list'**
  String get smartOpenInList;

  /// No description provided for @smartSetFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Set follow-up'**
  String get smartSetFollowUp;

  /// No description provided for @smartSortAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get smartSortAge;

  /// No description provided for @smartSortFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get smartSortFollowUp;

  /// No description provided for @smartSortList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get smartSortList;

  /// No description provided for @smartUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown smart list'**
  String get smartUnknown;

  /// No description provided for @smartWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get smartWaiting;

  /// No description provided for @stateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get stateEmpty;

  /// No description provided for @stateErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get stateErrorBody;

  /// No description provided for @stateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get stateErrorTitle;

  /// No description provided for @stateLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get stateLoading;

  /// No description provided for @statsCardError.
  ///
  /// In en, this message translates to:
  /// **'This card couldn’t be computed.'**
  String get statsCardError;

  /// No description provided for @statsCompareToggle.
  ///
  /// In en, this message translates to:
  /// **'Compare with previous period'**
  String get statsCompareToggle;

  /// No description provided for @statsDetailAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time: {value}'**
  String statsDetailAllTime(String value);

  /// No description provided for @statsDetailBacklog.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unscheduled task} other{{count} unscheduled tasks}}'**
  String statsDetailBacklog(num count);

  /// No description provided for @statsDetailBest.
  ///
  /// In en, this message translates to:
  /// **'Best: {value}'**
  String statsDetailBest(String value);

  /// No description provided for @statsDetailCoverage.
  ///
  /// In en, this message translates to:
  /// **'Time tracked on {value} of done tasks'**
  String statsDetailCoverage(String value);

  /// No description provided for @statsDetailDelta30.
  ///
  /// In en, this message translates to:
  /// **'{value} vs 30 days ago'**
  String statsDetailDelta30(String value);

  /// No description provided for @statsDetailLastDone.
  ///
  /// In en, this message translates to:
  /// **'Last done {date}'**
  String statsDetailLastDone(String date);

  /// No description provided for @statsDetailOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String statsDetailOfTotal(String done, String total);

  /// No description provided for @statsDetailOpen.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String statsDetailOpen(String count);

  /// No description provided for @statsDetailPerDay.
  ///
  /// In en, this message translates to:
  /// **'{value} per day'**
  String statsDetailPerDay(String value);

  /// No description provided for @statsDetailPeriods.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 period} other{{count} periods}}'**
  String statsDetailPeriods(num count);

  /// No description provided for @statsDetailPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned: {value}'**
  String statsDetailPlanned(String value);

  /// No description provided for @statsDetailQueue.
  ///
  /// In en, this message translates to:
  /// **'Waiting to start for {time}'**
  String statsDetailQueue(String time);

  /// No description provided for @statsDetailReduction.
  ///
  /// In en, this message translates to:
  /// **'Down {value} from baseline'**
  String statsDetailReduction(String value);

  /// No description provided for @statsDetailSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String statsDetailSince(String date);

  /// No description provided for @statsDetailWorkItem.
  ///
  /// In en, this message translates to:
  /// **'In progress for {time}'**
  String statsDetailWorkItem(String time);

  /// No description provided for @statsDrillEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show'**
  String get statsDrillEmpty;

  /// No description provided for @statsDrillMore.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String statsDrillMore(String count);

  /// No description provided for @statsDrillTitle.
  ///
  /// In en, this message translates to:
  /// **'Behind this number'**
  String get statsDrillTitle;

  /// No description provided for @statsEmptyHabits.
  ///
  /// In en, this message translates to:
  /// **'Add a habit to follow your consistency.'**
  String get statsEmptyHabits;

  /// No description provided for @statsEmptyLists.
  ///
  /// In en, this message translates to:
  /// **'Create a list to see how work flows through it.'**
  String get statsEmptyLists;

  /// No description provided for @statsEmptyPlanner.
  ///
  /// In en, this message translates to:
  /// **'Plan a few tasks and come back for insights.'**
  String get statsEmptyPlanner;

  /// No description provided for @statsEmptyQuit.
  ///
  /// In en, this message translates to:
  /// **'No quit trackers yet'**
  String get statsEmptyQuit;

  /// No description provided for @statsEmptyQuitBody.
  ///
  /// In en, this message translates to:
  /// **'Create one in Habits to see your progress here.'**
  String get statsEmptyQuitBody;

  /// No description provided for @statsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get statsEmptyTitle;

  /// No description provided for @statsExclusionCancelled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cancelled occurrence} other{{count} cancelled occurrences}}'**
  String statsExclusionCancelled(num count);

  /// No description provided for @statsExclusionExcused.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 excused unit} other{{count} excused units}}'**
  String statsExclusionExcused(num count);

  /// No description provided for @statsExclusionFrozen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 frozen unit} other{{count} frozen units}}'**
  String statsExclusionFrozen(num count);

  /// No description provided for @statsExclusionPaused.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 paused unit} other{{count} paused units}}'**
  String statsExclusionPaused(num count);

  /// No description provided for @statsExclusionSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 skipped unit} other{{count} skipped units}}'**
  String statsExclusionSkipped(num count);

  /// No description provided for @statsExclusionUnknown.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unlogged day} other{{count} unlogged days}}'**
  String statsExclusionUnknown(num count);

  /// No description provided for @statsExclusionUnplanned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unplanned addition} other{{count} unplanned additions}}'**
  String statsExclusionUnplanned(num count);

  /// No description provided for @statsExplainEstimate.
  ///
  /// In en, this message translates to:
  /// **'This number is an estimate.'**
  String get statsExplainEstimate;

  /// No description provided for @statsExplainExcluded.
  ///
  /// In en, this message translates to:
  /// **'Excluded'**
  String get statsExplainExcluded;

  /// No description provided for @statsExplainFormula.
  ///
  /// In en, this message translates to:
  /// **'How it’s computed'**
  String get statsExplainFormula;

  /// No description provided for @statsExplainGlossary.
  ///
  /// In en, this message translates to:
  /// **'Metric glossary'**
  String get statsExplainGlossary;

  /// No description provided for @statsExplainId.
  ///
  /// In en, this message translates to:
  /// **'Metric {id}'**
  String statsExplainId(String id);

  /// No description provided for @statsExplainInterval.
  ///
  /// In en, this message translates to:
  /// **'95 % interval: {lower} – {upper}'**
  String statsExplainInterval(String lower, String upper);

  /// No description provided for @statsExplainIntervalRule.
  ///
  /// In en, this message translates to:
  /// **'A ± range is shown below {count} units.'**
  String statsExplainIntervalRule(String count);

  /// No description provided for @statsExplainMinData.
  ///
  /// In en, this message translates to:
  /// **'Shown once at least {count} units exist.'**
  String statsExplainMinData(String count);

  /// No description provided for @statsExplainNothingExcluded.
  ///
  /// In en, this message translates to:
  /// **'Nothing excluded'**
  String get statsExplainNothingExcluded;

  /// No description provided for @statsExplainPopulation.
  ///
  /// In en, this message translates to:
  /// **'Population estimate: harm is non-linear and varies between individuals; it is not a personal prediction.'**
  String get statsExplainPopulation;

  /// No description provided for @statsExplainPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous period: {value}'**
  String statsExplainPrevious(String value);

  /// No description provided for @statsExplainSample.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Based on 1 unit} other{Based on {count} units}}'**
  String statsExplainSample(num count);

  /// No description provided for @statsExplainSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get statsExplainSources;

  /// No description provided for @statsExplainThisView.
  ///
  /// In en, this message translates to:
  /// **'In this view'**
  String get statsExplainThisView;

  /// No description provided for @statsExplainValue.
  ///
  /// In en, this message translates to:
  /// **'Value: {value}'**
  String statsExplainValue(String value);

  /// No description provided for @statsExplainWhat.
  ///
  /// In en, this message translates to:
  /// **'What it measures'**
  String get statsExplainWhat;

  /// No description provided for @statsFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get statsFilterApply;

  /// No description provided for @statsFilterCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get statsFilterCategories;

  /// No description provided for @statsFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get statsFilterClear;

  /// No description provided for @statsFilterPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get statsFilterPriority;

  /// No description provided for @statsFilterTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get statsFilterTags;

  /// No description provided for @statsFilterTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get statsFilterTracking;

  /// No description provided for @statsFilterTrackingCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get statsFilterTrackingCheck;

  /// No description provided for @statsFilterTrackingEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get statsFilterTrackingEvent;

  /// No description provided for @statsFilterTrackingTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get statsFilterTrackingTimer;

  /// No description provided for @statsFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get statsFilters;

  /// No description provided for @statsFiltersActive.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 filter} other{{count} filters}}'**
  String statsFiltersActive(num count);

  /// No description provided for @statsHealthClockNote.
  ///
  /// In en, this message translates to:
  /// **'Milestones follow your current smoke-free time: the clock restarts after a slip.'**
  String get statsHealthClockNote;

  /// No description provided for @statsHealthDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Educational estimates based on population averages from WHO, NHS, CDC and the American Cancer Society; individual results vary. Not medical advice. Consult a healthcare professional.'**
  String get statsHealthDisclaimer;

  /// No description provided for @statsHealthElapsedNote.
  ///
  /// In en, this message translates to:
  /// **'Percentages show elapsed time only, not physiological measurements.'**
  String get statsHealthElapsedNote;

  /// No description provided for @statsHealthRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String statsHealthRange(String from, String to);

  /// No description provided for @statsMetricClI01Desc.
  ///
  /// In en, this message translates to:
  /// **'How long this item spent in each status.'**
  String get statsMetricClI01Desc;

  /// No description provided for @statsMetricClI01Formula.
  ///
  /// In en, this message translates to:
  /// **'Sum of the intervals in each status until now (or deletion).'**
  String get statsMetricClI01Formula;

  /// No description provided for @statsMetricClI01Title.
  ///
  /// In en, this message translates to:
  /// **'Time in status'**
  String get statsMetricClI01Title;

  /// No description provided for @statsMetricClI02Desc.
  ///
  /// In en, this message translates to:
  /// **'Time from starting work to completion.'**
  String get statsMetricClI02Desc;

  /// No description provided for @statsMetricClI02Formula.
  ///
  /// In en, this message translates to:
  /// **'Done − start (first move out of to do).'**
  String get statsMetricClI02Formula;

  /// No description provided for @statsMetricClI02Title.
  ///
  /// In en, this message translates to:
  /// **'Cycle time'**
  String get statsMetricClI02Title;

  /// No description provided for @statsMetricClI03Desc.
  ///
  /// In en, this message translates to:
  /// **'Time from creation to completion.'**
  String get statsMetricClI03Desc;

  /// No description provided for @statsMetricClI03Formula.
  ///
  /// In en, this message translates to:
  /// **'Done − created.'**
  String get statsMetricClI03Formula;

  /// No description provided for @statsMetricClI03Title.
  ///
  /// In en, this message translates to:
  /// **'Lead time'**
  String get statsMetricClI03Title;

  /// No description provided for @statsMetricClI04Desc.
  ///
  /// In en, this message translates to:
  /// **'How long an open item has been in progress or waiting to start.'**
  String get statsMetricClI04Desc;

  /// No description provided for @statsMetricClI04Formula.
  ///
  /// In en, this message translates to:
  /// **'Started: now − start; not started: now − created.'**
  String get statsMetricClI04Formula;

  /// No description provided for @statsMetricClI04Title.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get statsMetricClI04Title;

  /// No description provided for @statsMetricClI05Desc.
  ///
  /// In en, this message translates to:
  /// **'Time since anything last happened on this item.'**
  String get statsMetricClI05Desc;

  /// No description provided for @statsMetricClI05Formula.
  ///
  /// In en, this message translates to:
  /// **'Now − last activity (status change, edit, attachment or child change).'**
  String get statsMetricClI05Formula;

  /// No description provided for @statsMetricClI05Title.
  ///
  /// In en, this message translates to:
  /// **'Staleness'**
  String get statsMetricClI05Title;

  /// No description provided for @statsMetricClI06Desc.
  ///
  /// In en, this message translates to:
  /// **'Completion of this item’s nested items.'**
  String get statsMetricClI06Desc;

  /// No description provided for @statsMetricClI06Formula.
  ///
  /// In en, this message translates to:
  /// **'Completed leaves ÷ countable leaves (cancelled excluded).'**
  String get statsMetricClI06Formula;

  /// No description provided for @statsMetricClI06Title.
  ///
  /// In en, this message translates to:
  /// **'Subtree progress'**
  String get statsMetricClI06Title;

  /// No description provided for @statsMetricClI07Desc.
  ///
  /// In en, this message translates to:
  /// **'The item’s history as colored segments with notes.'**
  String get statsMetricClI07Desc;

  /// No description provided for @statsMetricClI07Formula.
  ///
  /// In en, this message translates to:
  /// **'Each status interval from creation to now.'**
  String get statsMetricClI07Formula;

  /// No description provided for @statsMetricClI07Title.
  ///
  /// In en, this message translates to:
  /// **'Status timeline'**
  String get statsMetricClI07Title;

  /// No description provided for @statsMetricClL01Desc.
  ///
  /// In en, this message translates to:
  /// **'How the list’s items are split across statuses.'**
  String get statsMetricClL01Desc;

  /// No description provided for @statsMetricClL01Formula.
  ///
  /// In en, this message translates to:
  /// **'Items per status; % done over leaves and over all nodes.'**
  String get statsMetricClL01Formula;

  /// No description provided for @statsMetricClL01Title.
  ///
  /// In en, this message translates to:
  /// **'Status mix'**
  String get statsMetricClL01Title;

  /// No description provided for @statsMetricClL02Desc.
  ///
  /// In en, this message translates to:
  /// **'Daily completion of the list.'**
  String get statsMetricClL02Desc;

  /// No description provided for @statsMetricClL02Formula.
  ///
  /// In en, this message translates to:
  /// **'Completed ÷ (items in scope − cancelled) at each day end.'**
  String get statsMetricClL02Formula;

  /// No description provided for @statsMetricClL02Title.
  ///
  /// In en, this message translates to:
  /// **'Progress over time'**
  String get statsMetricClL02Title;

  /// No description provided for @statsMetricClL03Desc.
  ///
  /// In en, this message translates to:
  /// **'Items completed per week, with a 4-week rolling mean.'**
  String get statsMetricClL03Desc;

  /// No description provided for @statsMetricClL03Formula.
  ///
  /// In en, this message translates to:
  /// **'Completions per bucket (a reopened item counts once, on its final completion).'**
  String get statsMetricClL03Formula;

  /// No description provided for @statsMetricClL03Title.
  ///
  /// In en, this message translates to:
  /// **'Throughput'**
  String get statsMetricClL03Title;

  /// No description provided for @statsMetricClL04Desc.
  ///
  /// In en, this message translates to:
  /// **'Items ongoing, waiting or blocked at each day end.'**
  String get statsMetricClL04Desc;

  /// No description provided for @statsMetricClL04Formula.
  ///
  /// In en, this message translates to:
  /// **'Count of ongoing + waiting + blocked items.'**
  String get statsMetricClL04Formula;

  /// No description provided for @statsMetricClL04Title.
  ///
  /// In en, this message translates to:
  /// **'Work in progress'**
  String get statsMetricClL04Title;

  /// No description provided for @statsMetricClL05Desc.
  ///
  /// In en, this message translates to:
  /// **'Items added vs completed each week.'**
  String get statsMetricClL05Desc;

  /// No description provided for @statsMetricClL05Formula.
  ///
  /// In en, this message translates to:
  /// **'Weekly created (or moved in) vs completed; net flow = difference.'**
  String get statsMetricClL05Formula;

  /// No description provided for @statsMetricClL05Title.
  ///
  /// In en, this message translates to:
  /// **'Arrivals vs departures'**
  String get statsMetricClL05Title;

  /// No description provided for @statsMetricClL06Desc.
  ///
  /// In en, this message translates to:
  /// **'Open items without activity for a while, and the oldest ones.'**
  String get statsMetricClL06Desc;

  /// No description provided for @statsMetricClL06Formula.
  ///
  /// In en, this message translates to:
  /// **'Open items with staleness ≥ the stale threshold; 10 oldest by age.'**
  String get statsMetricClL06Formula;

  /// No description provided for @statsMetricClL06Title.
  ///
  /// In en, this message translates to:
  /// **'Stale items'**
  String get statsMetricClL06Title;

  /// No description provided for @statsMetricClX01Desc.
  ///
  /// In en, this message translates to:
  /// **'Your lists: active, archived, templates and stale ones.'**
  String get statsMetricClX01Desc;

  /// No description provided for @statsMetricClX01Formula.
  ///
  /// In en, this message translates to:
  /// **'Counts of lists; stale = no activity for N days while holding open items.'**
  String get statsMetricClX01Formula;

  /// No description provided for @statsMetricClX01Title.
  ///
  /// In en, this message translates to:
  /// **'Lists overview'**
  String get statsMetricClX01Title;

  /// No description provided for @statsMetricClX02Desc.
  ///
  /// In en, this message translates to:
  /// **'Items added vs completed each week across lists.'**
  String get statsMetricClX02Desc;

  /// No description provided for @statsMetricClX02Formula.
  ///
  /// In en, this message translates to:
  /// **'Weekly created vs completed; net flow = difference.'**
  String get statsMetricClX02Formula;

  /// No description provided for @statsMetricClX02Title.
  ///
  /// In en, this message translates to:
  /// **'Arrivals vs departures (all lists)'**
  String get statsMetricClX02Title;

  /// No description provided for @statsMetricClX03Desc.
  ///
  /// In en, this message translates to:
  /// **'Items ongoing, waiting or blocked now, and the oldest open items.'**
  String get statsMetricClX03Desc;

  /// No description provided for @statsMetricClX03Formula.
  ///
  /// In en, this message translates to:
  /// **'Counts across active lists (archived excluded).'**
  String get statsMetricClX03Formula;

  /// No description provided for @statsMetricClX03Title.
  ///
  /// In en, this message translates to:
  /// **'Work in progress across lists'**
  String get statsMetricClX03Title;

  /// No description provided for @statsMetricClX04Desc.
  ///
  /// In en, this message translates to:
  /// **'Items completed in the period.'**
  String get statsMetricClX04Desc;

  /// No description provided for @statsMetricClX04Formula.
  ///
  /// In en, this message translates to:
  /// **'Final completions in the period, compared with the previous period.'**
  String get statsMetricClX04Formula;

  /// No description provided for @statsMetricClX04Title.
  ///
  /// In en, this message translates to:
  /// **'Items completed'**
  String get statsMetricClX04Title;

  /// No description provided for @statsMetricClX05Desc.
  ///
  /// In en, this message translates to:
  /// **'Items per status across all lists.'**
  String get statsMetricClX05Desc;

  /// No description provided for @statsMetricClX05Formula.
  ///
  /// In en, this message translates to:
  /// **'Count of live items per status.'**
  String get statsMetricClX05Formula;

  /// No description provided for @statsMetricClX05Title.
  ///
  /// In en, this message translates to:
  /// **'Status distribution'**
  String get statsMetricClX05Title;

  /// No description provided for @statsMetricGl01Desc.
  ///
  /// In en, this message translates to:
  /// **'Your day across sections: agenda, habits, lists and quit.'**
  String get statsMetricGl01Desc;

  /// No description provided for @statsMetricGl01Formula.
  ///
  /// In en, this message translates to:
  /// **'Same numbers as each section’s metrics for today.'**
  String get statsMetricGl01Formula;

  /// No description provided for @statsMetricGl01Title.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsMetricGl01Title;

  /// No description provided for @statsMetricGl02Desc.
  ///
  /// In en, this message translates to:
  /// **'This week so far vs the same days last week.'**
  String get statsMetricGl02Desc;

  /// No description provided for @statsMetricGl02Formula.
  ///
  /// In en, this message translates to:
  /// **'Section KPIs to date with their change vs the previous week.'**
  String get statsMetricGl02Formula;

  /// No description provided for @statsMetricGl02Title.
  ///
  /// In en, this message translates to:
  /// **'Week at a glance'**
  String get statsMetricGl02Title;

  /// No description provided for @statsMetricGl03Desc.
  ///
  /// In en, this message translates to:
  /// **'Your week: headline numbers, wins, what needs attention and next week’s load.'**
  String get statsMetricGl03Desc;

  /// No description provided for @statsMetricGl03Formula.
  ///
  /// In en, this message translates to:
  /// **'Section KPIs with their change vs the previous week.'**
  String get statsMetricGl03Formula;

  /// No description provided for @statsMetricGl03Title.
  ///
  /// In en, this message translates to:
  /// **'Weekly review'**
  String get statsMetricGl03Title;

  /// No description provided for @statsMetricHbH01Desc.
  ///
  /// In en, this message translates to:
  /// **'How well the habit is established — recent days count more.'**
  String get statsMetricHbH01Desc;

  /// No description provided for @statsMetricHbH01Formula.
  ///
  /// In en, this message translates to:
  /// **'Loop score: score = previous × m + credit × (1 − m), m = 0.5^(√f ÷ 13).'**
  String get statsMetricHbH01Formula;

  /// No description provided for @statsMetricHbH01Title.
  ///
  /// In en, this message translates to:
  /// **'Habit strength'**
  String get statsMetricHbH01Title;

  /// No description provided for @statsMetricHbH02Desc.
  ///
  /// In en, this message translates to:
  /// **'Consecutive successful units up to now; today stays open until it ends.'**
  String get statsMetricHbH02Desc;

  /// No description provided for @statsMetricHbH02Formula.
  ///
  /// In en, this message translates to:
  /// **'Streak engine: skips, excuses, pauses and freezes are neutral.'**
  String get statsMetricHbH02Formula;

  /// No description provided for @statsMetricHbH02Title.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get statsMetricHbH02Title;

  /// No description provided for @statsMetricHbH03Desc.
  ///
  /// In en, this message translates to:
  /// **'Your longest run of successful units.'**
  String get statsMetricHbH03Desc;

  /// No description provided for @statsMetricHbH03Formula.
  ///
  /// In en, this message translates to:
  /// **'Maximum streak length, with its date range.'**
  String get statsMetricHbH03Formula;

  /// No description provided for @statsMetricHbH03Title.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get statsMetricHbH03Title;

  /// No description provided for @statsMetricHbH04Desc.
  ///
  /// In en, this message translates to:
  /// **'Your ten longest streaks.'**
  String get statsMetricHbH04Desc;

  /// No description provided for @statsMetricHbH04Formula.
  ///
  /// In en, this message translates to:
  /// **'Streaks ordered by length, then recency.'**
  String get statsMetricHbH04Formula;

  /// No description provided for @statsMetricHbH04Title.
  ///
  /// In en, this message translates to:
  /// **'Top streaks'**
  String get statsMetricHbH04Title;

  /// No description provided for @statsMetricHbH05Desc.
  ///
  /// In en, this message translates to:
  /// **'Share of scheduled units you completed.'**
  String get statsMetricHbH05Desc;

  /// No description provided for @statsMetricHbH05Formula.
  ///
  /// In en, this message translates to:
  /// **'Done ÷ (closed scheduled units − excused); Wilson interval below 20 units.'**
  String get statsMetricHbH05Formula;

  /// No description provided for @statsMetricHbH05Title.
  ///
  /// In en, this message translates to:
  /// **'Success rate'**
  String get statsMetricHbH05Title;

  /// No description provided for @statsMetricHbH06Desc.
  ///
  /// In en, this message translates to:
  /// **'How each scheduled unit ended.'**
  String get statsMetricHbH06Desc;

  /// No description provided for @statsMetricHbH06Formula.
  ///
  /// In en, this message translates to:
  /// **'Counts of success, partial, not done, missed, skipped and excused units.'**
  String get statsMetricHbH06Formula;

  /// No description provided for @statsMetricHbH06Title.
  ///
  /// In en, this message translates to:
  /// **'Outcome counts'**
  String get statsMetricHbH06Title;

  /// No description provided for @statsMetricHbH07Desc.
  ///
  /// In en, this message translates to:
  /// **'Successes (and volume) per week, month or year.'**
  String get statsMetricHbH07Desc;

  /// No description provided for @statsMetricHbH07Formula.
  ///
  /// In en, this message translates to:
  /// **'Sums per bucket.'**
  String get statsMetricHbH07Formula;

  /// No description provided for @statsMetricHbH07Title.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get statsMetricHbH07Title;

  /// No description provided for @statsMetricHbH08Desc.
  ///
  /// In en, this message translates to:
  /// **'Each day’s status.'**
  String get statsMetricHbH08Desc;

  /// No description provided for @statsMetricHbH08Formula.
  ///
  /// In en, this message translates to:
  /// **'One cell per day: done, partial, not done, missed, skipped, excused, paused, frozen.'**
  String get statsMetricHbH08Formula;

  /// No description provided for @statsMetricHbH08Title.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get statsMetricHbH08Title;

  /// No description provided for @statsMetricHbH09Desc.
  ///
  /// In en, this message translates to:
  /// **'Every check-in is a vote for the person you want to be.'**
  String get statsMetricHbH09Desc;

  /// No description provided for @statsMetricHbH09Formula.
  ///
  /// In en, this message translates to:
  /// **'All-time count of manual done and progress logs.'**
  String get statsMetricHbH09Formula;

  /// No description provided for @statsMetricHbH09Title.
  ///
  /// In en, this message translates to:
  /// **'Total repetitions'**
  String get statsMetricHbH09Title;

  /// No description provided for @statsMetricHbH10Desc.
  ///
  /// In en, this message translates to:
  /// **'How much of the period’s target you reached.'**
  String get statsMetricHbH10Desc;

  /// No description provided for @statsMetricHbH10Formula.
  ///
  /// In en, this message translates to:
  /// **'Achieved ÷ (daily target × scheduled days − skipped days).'**
  String get statsMetricHbH10Formula;

  /// No description provided for @statsMetricHbH10Title.
  ///
  /// In en, this message translates to:
  /// **'Target progress'**
  String get statsMetricHbH10Title;

  /// No description provided for @statsMetricHbH11Desc.
  ///
  /// In en, this message translates to:
  /// **'Everything you logged, in the habit’s unit.'**
  String get statsMetricHbH11Desc;

  /// No description provided for @statsMetricHbH11Formula.
  ///
  /// In en, this message translates to:
  /// **'Sum of logged values in the period and all time.'**
  String get statsMetricHbH11Formula;

  /// No description provided for @statsMetricHbH11Title.
  ///
  /// In en, this message translates to:
  /// **'Total volume'**
  String get statsMetricHbH11Title;

  /// No description provided for @statsMetricHbX01Desc.
  ///
  /// In en, this message translates to:
  /// **'Due habits done today.'**
  String get statsMetricHbX01Desc;

  /// No description provided for @statsMetricHbX01Formula.
  ///
  /// In en, this message translates to:
  /// **'Done ÷ due day units today (build habits).'**
  String get statsMetricHbX01Formula;

  /// No description provided for @statsMetricHbX01Title.
  ///
  /// In en, this message translates to:
  /// **'Today’s progress'**
  String get statsMetricHbX01Title;

  /// No description provided for @statsMetricHbX02Desc.
  ///
  /// In en, this message translates to:
  /// **'Days where every due habit was done.'**
  String get statsMetricHbX02Desc;

  /// No description provided for @statsMetricHbX02Formula.
  ///
  /// In en, this message translates to:
  /// **'Days with all due units done; perfect-day streak (days with nothing due are neutral).'**
  String get statsMetricHbX02Formula;

  /// No description provided for @statsMetricHbX02Title.
  ///
  /// In en, this message translates to:
  /// **'Perfect days'**
  String get statsMetricHbX02Title;

  /// No description provided for @statsMetricHbX03Desc.
  ///
  /// In en, this message translates to:
  /// **'How much of each day’s habits you completed.'**
  String get statsMetricHbX03Desc;

  /// No description provided for @statsMetricHbX03Formula.
  ///
  /// In en, this message translates to:
  /// **'Per day: done ÷ due across habits.'**
  String get statsMetricHbX03Formula;

  /// No description provided for @statsMetricHbX03Title.
  ///
  /// In en, this message translates to:
  /// **'Daily completion'**
  String get statsMetricHbX03Title;

  /// No description provided for @statsMetricHbX04Desc.
  ///
  /// In en, this message translates to:
  /// **'Weekly success rate across habits.'**
  String get statsMetricHbX04Desc;

  /// No description provided for @statsMetricHbX04Formula.
  ///
  /// In en, this message translates to:
  /// **'Weekly done ÷ due, with a 4-week rolling line; Δ vs previous week in points.'**
  String get statsMetricHbX04Formula;

  /// No description provided for @statsMetricHbX04Title.
  ///
  /// In en, this message translates to:
  /// **'Adherence trend'**
  String get statsMetricHbX04Title;

  /// No description provided for @statsMetricHbX05Desc.
  ///
  /// In en, this message translates to:
  /// **'Money saved, units avoided and life regained across quit trackers.'**
  String get statsMetricHbX05Desc;

  /// No description provided for @statsMetricHbX05Formula.
  ///
  /// In en, this message translates to:
  /// **'Sums over active quit trackers (life regained is a population estimate).'**
  String get statsMetricHbX05Formula;

  /// No description provided for @statsMetricHbX05Title.
  ///
  /// In en, this message translates to:
  /// **'Quit trackers roll-up'**
  String get statsMetricHbX05Title;

  /// No description provided for @statsMetricPlS01Desc.
  ///
  /// In en, this message translates to:
  /// **'How many times the series was due in the period.'**
  String get statsMetricPlS01Desc;

  /// No description provided for @statsMetricPlS01Formula.
  ///
  /// In en, this message translates to:
  /// **'Occurrences from the recurrence rule in the window; closed and open counted separately.'**
  String get statsMetricPlS01Formula;

  /// No description provided for @statsMetricPlS01Title.
  ///
  /// In en, this message translates to:
  /// **'Expected occurrences'**
  String get statsMetricPlS01Title;

  /// No description provided for @statsMetricPlS02Desc.
  ///
  /// In en, this message translates to:
  /// **'Breakdown of the series’ occurrences by outcome.'**
  String get statsMetricPlS02Desc;

  /// No description provided for @statsMetricPlS02Formula.
  ///
  /// In en, this message translates to:
  /// **'Counts of done (D), missed (M), skipped (K) and excused (X) occurrences.'**
  String get statsMetricPlS02Formula;

  /// No description provided for @statsMetricPlS02Title.
  ///
  /// In en, this message translates to:
  /// **'Done, missed, skipped'**
  String get statsMetricPlS02Title;

  /// No description provided for @statsMetricPlS03Desc.
  ///
  /// In en, this message translates to:
  /// **'Share of due occurrences you completed.'**
  String get statsMetricPlS03Desc;

  /// No description provided for @statsMetricPlS03Formula.
  ///
  /// In en, this message translates to:
  /// **'Done ÷ (expected − excused), with a 4-week rolling line and a weekly trend.'**
  String get statsMetricPlS03Formula;

  /// No description provided for @statsMetricPlS03Title.
  ///
  /// In en, this message translates to:
  /// **'Adherence'**
  String get statsMetricPlS03Title;

  /// No description provided for @statsMetricPlS04Desc.
  ///
  /// In en, this message translates to:
  /// **'Share of due occurrences that were missed or not done.'**
  String get statsMetricPlS04Desc;

  /// No description provided for @statsMetricPlS04Formula.
  ///
  /// In en, this message translates to:
  /// **'(Missed + not done) ÷ (expected − excused).'**
  String get statsMetricPlS04Formula;

  /// No description provided for @statsMetricPlS04Title.
  ///
  /// In en, this message translates to:
  /// **'Miss rate'**
  String get statsMetricPlS04Title;

  /// No description provided for @statsMetricPlS05Desc.
  ///
  /// In en, this message translates to:
  /// **'Consecutive completed occurrences; skips are neutral by default.'**
  String get statsMetricPlS05Desc;

  /// No description provided for @statsMetricPlS05Formula.
  ///
  /// In en, this message translates to:
  /// **'Streak engine with one unit per occurrence.'**
  String get statsMetricPlS05Formula;

  /// No description provided for @statsMetricPlS05Title.
  ///
  /// In en, this message translates to:
  /// **'Current & best streak'**
  String get statsMetricPlS05Title;

  /// No description provided for @statsMetricPlS06Desc.
  ///
  /// In en, this message translates to:
  /// **'Cumulative tracked and planned time since the series started.'**
  String get statsMetricPlS06Desc;

  /// No description provided for @statsMetricPlS06Formula.
  ///
  /// In en, this message translates to:
  /// **'Running totals of actual and planned minutes.'**
  String get statsMetricPlS06Formula;

  /// No description provided for @statsMetricPlS06Title.
  ///
  /// In en, this message translates to:
  /// **'Time invested'**
  String get statsMetricPlS06Title;

  /// No description provided for @statsMetricPlS07Desc.
  ///
  /// In en, this message translates to:
  /// **'All-time number of completed occurrences.'**
  String get statsMetricPlS07Desc;

  /// No description provided for @statsMetricPlS07Formula.
  ///
  /// In en, this message translates to:
  /// **'Count of done occurrences.'**
  String get statsMetricPlS07Formula;

  /// No description provided for @statsMetricPlS07Title.
  ///
  /// In en, this message translates to:
  /// **'Total done'**
  String get statsMetricPlS07Title;

  /// No description provided for @statsMetricPlS08Desc.
  ///
  /// In en, this message translates to:
  /// **'Days since the last completed occurrence.'**
  String get statsMetricPlS08Desc;

  /// No description provided for @statsMetricPlS08Formula.
  ///
  /// In en, this message translates to:
  /// **'Today − date of the last completion.'**
  String get statsMetricPlS08Formula;

  /// No description provided for @statsMetricPlS08Title.
  ///
  /// In en, this message translates to:
  /// **'Last done'**
  String get statsMetricPlS08Title;

  /// No description provided for @statsMetricPlS09Desc.
  ///
  /// In en, this message translates to:
  /// **'Each day’s outcome for the series.'**
  String get statsMetricPlS09Desc;

  /// No description provided for @statsMetricPlS09Formula.
  ///
  /// In en, this message translates to:
  /// **'Worst outcome of the day: missed > partial > late > skipped > done > excused.'**
  String get statsMetricPlS09Formula;

  /// No description provided for @statsMetricPlS09Title.
  ///
  /// In en, this message translates to:
  /// **'Outcome calendar'**
  String get statsMetricPlS09Title;

  /// No description provided for @statsMetricPlT01Desc.
  ///
  /// In en, this message translates to:
  /// **'How long this occurrence was planned to take.'**
  String get statsMetricPlT01Desc;

  /// No description provided for @statsMetricPlT01Formula.
  ///
  /// In en, this message translates to:
  /// **'Planned end − planned start.'**
  String get statsMetricPlT01Formula;

  /// No description provided for @statsMetricPlT01Title.
  ///
  /// In en, this message translates to:
  /// **'Planned duration'**
  String get statsMetricPlT01Title;

  /// No description provided for @statsMetricPlT02Desc.
  ///
  /// In en, this message translates to:
  /// **'Time actually tracked on this occurrence, pauses excluded.'**
  String get statsMetricPlT02Desc;

  /// No description provided for @statsMetricPlT02Formula.
  ///
  /// In en, this message translates to:
  /// **'Sum of tracked session lengths; unknown when nothing was tracked.'**
  String get statsMetricPlT02Formula;

  /// No description provided for @statsMetricPlT02Title.
  ///
  /// In en, this message translates to:
  /// **'Actual duration'**
  String get statsMetricPlT02Title;

  /// No description provided for @statsMetricPlT03Desc.
  ///
  /// In en, this message translates to:
  /// **'Difference between actual and planned time, and their ratio.'**
  String get statsMetricPlT03Desc;

  /// No description provided for @statsMetricPlT03Formula.
  ///
  /// In en, this message translates to:
  /// **'Actual − planned; ratio R = actual ÷ planned (only when planned ≥ 5 min).'**
  String get statsMetricPlT03Formula;

  /// No description provided for @statsMetricPlT03Title.
  ///
  /// In en, this message translates to:
  /// **'Duration variance'**
  String get statsMetricPlT03Title;

  /// No description provided for @statsMetricPlT04Desc.
  ///
  /// In en, this message translates to:
  /// **'How early or late you started compared with the plan.'**
  String get statsMetricPlT04Desc;

  /// No description provided for @statsMetricPlT04Formula.
  ///
  /// In en, this message translates to:
  /// **'First session start − planned start; on time within the grace period.'**
  String get statsMetricPlT04Formula;

  /// No description provided for @statsMetricPlT04Title.
  ///
  /// In en, this message translates to:
  /// **'Start delay'**
  String get statsMetricPlT04Title;

  /// No description provided for @statsMetricPlT05Desc.
  ///
  /// In en, this message translates to:
  /// **'How early or late the occurrence was finished.'**
  String get statsMetricPlT05Desc;

  /// No description provided for @statsMetricPlT05Formula.
  ///
  /// In en, this message translates to:
  /// **'Completion (or last session end for timers) − planned end.'**
  String get statsMetricPlT05Formula;

  /// No description provided for @statsMetricPlT05Title.
  ///
  /// In en, this message translates to:
  /// **'Finish delay'**
  String get statsMetricPlT05Title;

  /// No description provided for @statsMetricPlT06Desc.
  ///
  /// In en, this message translates to:
  /// **'What happened to this occurrence.'**
  String get statsMetricPlT06Desc;

  /// No description provided for @statsMetricPlT06Formula.
  ///
  /// In en, this message translates to:
  /// **'Done on time, done late, partial, skipped, missed, cancelled, pending or upcoming.'**
  String get statsMetricPlT06Formula;

  /// No description provided for @statsMetricPlT06Title.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get statsMetricPlT06Title;

  /// No description provided for @statsMetricPlT07Desc.
  ///
  /// In en, this message translates to:
  /// **'How long an unfinished occurrence has been overdue.'**
  String get statsMetricPlT07Desc;

  /// No description provided for @statsMetricPlT07Formula.
  ///
  /// In en, this message translates to:
  /// **'Now − planned end, bucketed 1 / 7 / 14 / 30+ days.'**
  String get statsMetricPlT07Formula;

  /// No description provided for @statsMetricPlT07Title.
  ///
  /// In en, this message translates to:
  /// **'Overdue age'**
  String get statsMetricPlT07Title;

  /// No description provided for @statsMetricPlX01Desc.
  ///
  /// In en, this message translates to:
  /// **'Share of what was planned at the start of the period that you completed.'**
  String get statsMetricPlX01Desc;

  /// No description provided for @statsMetricPlX01Formula.
  ///
  /// In en, this message translates to:
  /// **'Planned and done in the period ÷ planned as of the period start; tasks added later are excluded.'**
  String get statsMetricPlX01Formula;

  /// No description provided for @statsMetricPlX01Title.
  ///
  /// In en, this message translates to:
  /// **'Completion vs plan'**
  String get statsMetricPlX01Title;

  /// No description provided for @statsMetricPlX02Desc.
  ///
  /// In en, this message translates to:
  /// **'Planned and completed tasks for each day.'**
  String get statsMetricPlX02Desc;

  /// No description provided for @statsMetricPlX02Formula.
  ///
  /// In en, this message translates to:
  /// **'Per day: planned (plan snapshot) and done counts.'**
  String get statsMetricPlX02Formula;

  /// No description provided for @statsMetricPlX02Title.
  ///
  /// In en, this message translates to:
  /// **'Done vs planned per day'**
  String get statsMetricPlX02Title;

  /// No description provided for @statsMetricPlX03Desc.
  ///
  /// In en, this message translates to:
  /// **'Tasks added after the period started, and tasks moved out of or into it.'**
  String get statsMetricPlX03Desc;

  /// No description provided for @statsMetricPlX03Formula.
  ///
  /// In en, this message translates to:
  /// **'Counts of unplanned additions, moved-out and moved-in occurrences.'**
  String get statsMetricPlX03Formula;

  /// No description provided for @statsMetricPlX03Title.
  ///
  /// In en, this message translates to:
  /// **'Unplanned & moved'**
  String get statsMetricPlX03Title;

  /// No description provided for @statsMetricPlX04Desc.
  ///
  /// In en, this message translates to:
  /// **'Tasks created vs completed each week, and the open backlog.'**
  String get statsMetricPlX04Desc;

  /// No description provided for @statsMetricPlX04Formula.
  ///
  /// In en, this message translates to:
  /// **'Created and completed per week; backlog = unscheduled tasks + overdue occurrences.'**
  String get statsMetricPlX04Formula;

  /// No description provided for @statsMetricPlX04Title.
  ///
  /// In en, this message translates to:
  /// **'Backlog flow'**
  String get statsMetricPlX04Title;

  /// No description provided for @statsMetricPlX05Desc.
  ///
  /// In en, this message translates to:
  /// **'Share of completed tasks finished by their planned end.'**
  String get statsMetricPlX05Desc;

  /// No description provided for @statsMetricPlX05Formula.
  ///
  /// In en, this message translates to:
  /// **'Done on time ÷ done (grace period included).'**
  String get statsMetricPlX05Formula;

  /// No description provided for @statsMetricPlX05Title.
  ///
  /// In en, this message translates to:
  /// **'On-time completion'**
  String get statsMetricPlX05Title;

  /// No description provided for @statsMetricPlX06Desc.
  ///
  /// In en, this message translates to:
  /// **'Unfinished tasks past their planned end, by age.'**
  String get statsMetricPlX06Desc;

  /// No description provided for @statsMetricPlX06Formula.
  ///
  /// In en, this message translates to:
  /// **'Open overdue occurrences, bucketed 1 / 7 / 14 / 30+ days.'**
  String get statsMetricPlX06Formula;

  /// No description provided for @statsMetricPlX06Title.
  ///
  /// In en, this message translates to:
  /// **'Overdue now'**
  String get statsMetricPlX06Title;

  /// No description provided for @statsMetricPlX07Desc.
  ///
  /// In en, this message translates to:
  /// **'Time available for planned work in the period.'**
  String get statsMetricPlX07Desc;

  /// No description provided for @statsMetricPlX07Formula.
  ///
  /// In en, this message translates to:
  /// **'Work hours per day minus unavailable blocks, summed over the period.'**
  String get statsMetricPlX07Formula;

  /// No description provided for @statsMetricPlX07Title.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get statsMetricPlX07Title;

  /// No description provided for @statsMetricPlX08Desc.
  ///
  /// In en, this message translates to:
  /// **'How much of your capacity is filled with planned tasks.'**
  String get statsMetricPlX08Desc;

  /// No description provided for @statsMetricPlX08Formula.
  ///
  /// In en, this message translates to:
  /// **'Planned minutes inside work hours ÷ capacity (can exceed 100 % with overlaps).'**
  String get statsMetricPlX08Formula;

  /// No description provided for @statsMetricPlX08Title.
  ///
  /// In en, this message translates to:
  /// **'Planned utilization'**
  String get statsMetricPlX08Title;

  /// No description provided for @statsMetricPlX09Desc.
  ///
  /// In en, this message translates to:
  /// **'How much of your capacity was spent on tracked work.'**
  String get statsMetricPlX09Desc;

  /// No description provided for @statsMetricPlX09Formula.
  ///
  /// In en, this message translates to:
  /// **'Tracked minutes inside work hours ÷ capacity; needs 60 % tracking coverage.'**
  String get statsMetricPlX09Formula;

  /// No description provided for @statsMetricPlX09Title.
  ///
  /// In en, this message translates to:
  /// **'Actual utilization'**
  String get statsMetricPlX09Title;

  /// No description provided for @statsMetricPlX10Desc.
  ///
  /// In en, this message translates to:
  /// **'Days where more is planned than the time available.'**
  String get statsMetricPlX10Desc;

  /// No description provided for @statsMetricPlX10Formula.
  ///
  /// In en, this message translates to:
  /// **'Days with planned load > capacity; overbooked minutes = load − capacity.'**
  String get statsMetricPlX10Formula;

  /// No description provided for @statsMetricPlX10Title.
  ///
  /// In en, this message translates to:
  /// **'Overbooked days'**
  String get statsMetricPlX10Title;

  /// No description provided for @statsMetricPlX11Desc.
  ///
  /// In en, this message translates to:
  /// **'Capacity left from now until the end of the period.'**
  String get statsMetricPlX11Desc;

  /// No description provided for @statsMetricPlX11Formula.
  ///
  /// In en, this message translates to:
  /// **'Remaining capacity − remaining planned time (from now).'**
  String get statsMetricPlX11Formula;

  /// No description provided for @statsMetricPlX11Title.
  ///
  /// In en, this message translates to:
  /// **'Remaining free time'**
  String get statsMetricPlX11Title;

  /// No description provided for @statsMetricPlX12Desc.
  ///
  /// In en, this message translates to:
  /// **'Planned and tracked time per day and category.'**
  String get statsMetricPlX12Desc;

  /// No description provided for @statsMetricPlX12Formula.
  ///
  /// In en, this message translates to:
  /// **'Sum of planned minutes vs sum of tracked minutes.'**
  String get statsMetricPlX12Formula;

  /// No description provided for @statsMetricPlX12Title.
  ///
  /// In en, this message translates to:
  /// **'Planned vs actual hours'**
  String get statsMetricPlX12Title;

  /// No description provided for @statsMetricPlX13Desc.
  ///
  /// In en, this message translates to:
  /// **'Where your time goes, by category.'**
  String get statsMetricPlX13Desc;

  /// No description provided for @statsMetricPlX13Formula.
  ///
  /// In en, this message translates to:
  /// **'Tracked minutes per category (planned when tracking covers < 60 %); share of total.'**
  String get statsMetricPlX13Formula;

  /// No description provided for @statsMetricPlX13Title.
  ///
  /// In en, this message translates to:
  /// **'Time by category'**
  String get statsMetricPlX13Title;

  /// No description provided for @statsMetricPlX14Desc.
  ///
  /// In en, this message translates to:
  /// **'Weekly time per category.'**
  String get statsMetricPlX14Desc;

  /// No description provided for @statsMetricPlX14Formula.
  ///
  /// In en, this message translates to:
  /// **'Minutes per category per week.'**
  String get statsMetricPlX14Formula;

  /// No description provided for @statsMetricPlX14Title.
  ///
  /// In en, this message translates to:
  /// **'Category trend'**
  String get statsMetricPlX14Title;

  /// No description provided for @statsMetricPlX15Desc.
  ///
  /// In en, this message translates to:
  /// **'Share of planned time taken by events rather than tasks.'**
  String get statsMetricPlX15Desc;

  /// No description provided for @statsMetricPlX15Formula.
  ///
  /// In en, this message translates to:
  /// **'Event minutes ÷ (event + task minutes).'**
  String get statsMetricPlX15Formula;

  /// No description provided for @statsMetricPlX15Title.
  ///
  /// In en, this message translates to:
  /// **'Events vs tasks'**
  String get statsMetricPlX15Title;

  /// No description provided for @statsMetricQt01Desc.
  ///
  /// In en, this message translates to:
  /// **'Time since your quit date.'**
  String get statsMetricQt01Desc;

  /// No description provided for @statsMetricQt01Formula.
  ///
  /// In en, this message translates to:
  /// **'Now − quit date (live).'**
  String get statsMetricQt01Formula;

  /// No description provided for @statsMetricQt01Title.
  ///
  /// In en, this message translates to:
  /// **'Time since quitting'**
  String get statsMetricQt01Title;

  /// No description provided for @statsMetricQt02Desc.
  ///
  /// In en, this message translates to:
  /// **'Time since the last use (or your quit date).'**
  String get statsMetricQt02Desc;

  /// No description provided for @statsMetricQt02Formula.
  ///
  /// In en, this message translates to:
  /// **'Now − max(quit date, last use) (live).'**
  String get statsMetricQt02Formula;

  /// No description provided for @statsMetricQt02Title.
  ///
  /// In en, this message translates to:
  /// **'Current abstinence'**
  String get statsMetricQt02Title;

  /// No description provided for @statsMetricQt03Desc.
  ///
  /// In en, this message translates to:
  /// **'Your longest stretch without using.'**
  String get statsMetricQt03Desc;

  /// No description provided for @statsMetricQt03Formula.
  ///
  /// In en, this message translates to:
  /// **'Longest gap between quit date, uses and now.'**
  String get statsMetricQt03Formula;

  /// No description provided for @statsMetricQt03Title.
  ///
  /// In en, this message translates to:
  /// **'Longest abstinence'**
  String get statsMetricQt03Title;

  /// No description provided for @statsMetricQt04Desc.
  ///
  /// In en, this message translates to:
  /// **'Local days since quitting without any use.'**
  String get statsMetricQt04Desc;

  /// No description provided for @statsMetricQt04Formula.
  ///
  /// In en, this message translates to:
  /// **'Count of closed days with no use.'**
  String get statsMetricQt04Formula;

  /// No description provided for @statsMetricQt04Title.
  ///
  /// In en, this message translates to:
  /// **'Abstinent days'**
  String get statsMetricQt04Title;

  /// No description provided for @statsMetricQt05Desc.
  ///
  /// In en, this message translates to:
  /// **'Share of days since quitting without any use.'**
  String get statsMetricQt05Desc;

  /// No description provided for @statsMetricQt05Formula.
  ///
  /// In en, this message translates to:
  /// **'Abstinent days ÷ closed days since the quit date.'**
  String get statsMetricQt05Formula;

  /// No description provided for @statsMetricQt05Title.
  ///
  /// In en, this message translates to:
  /// **'Abstinent days share'**
  String get statsMetricQt05Title;

  /// No description provided for @statsMetricQt06Desc.
  ///
  /// In en, this message translates to:
  /// **'How many units you did not consume thanks to quitting.'**
  String get statsMetricQt06Desc;

  /// No description provided for @statsMetricQt06Formula.
  ///
  /// In en, this message translates to:
  /// **'Baseline per day × days − units used (floored at 0).'**
  String get statsMetricQt06Formula;

  /// No description provided for @statsMetricQt06Title.
  ///
  /// In en, this message translates to:
  /// **'Units avoided'**
  String get statsMetricQt06Title;

  /// No description provided for @statsMetricQt07Desc.
  ///
  /// In en, this message translates to:
  /// **'Money not spent thanks to quitting.'**
  String get statsMetricQt07Desc;

  /// No description provided for @statsMetricQt07Formula.
  ///
  /// In en, this message translates to:
  /// **'Units avoided each day × unit cost in force that day.'**
  String get statsMetricQt07Formula;

  /// No description provided for @statsMetricQt07Title.
  ///
  /// In en, this message translates to:
  /// **'Money saved'**
  String get statsMetricQt07Title;

  /// No description provided for @statsMetricQt08Desc.
  ///
  /// In en, this message translates to:
  /// **'Money spent on uses since quitting.'**
  String get statsMetricQt08Desc;

  /// No description provided for @statsMetricQt08Formula.
  ///
  /// In en, this message translates to:
  /// **'Units used × unit cost at the time.'**
  String get statsMetricQt08Formula;

  /// No description provided for @statsMetricQt08Title.
  ///
  /// In en, this message translates to:
  /// **'Spent on slips'**
  String get statsMetricQt08Title;

  /// No description provided for @statsMetricQt09Desc.
  ///
  /// In en, this message translates to:
  /// **'What you will save if you keep going.'**
  String get statsMetricQt09Desc;

  /// No description provided for @statsMetricQt09Formula.
  ///
  /// In en, this message translates to:
  /// **'Current baseline × unit cost over the next month, year and 5 years.'**
  String get statsMetricQt09Formula;

  /// No description provided for @statsMetricQt09Title.
  ///
  /// In en, this message translates to:
  /// **'Savings projection'**
  String get statsMetricQt09Title;

  /// No description provided for @statsMetricQt10Desc.
  ///
  /// In en, this message translates to:
  /// **'Population estimate of life expectancy regained — not a personal prediction.'**
  String get statsMetricQt10Desc;

  /// No description provided for @statsMetricQt10Formula.
  ///
  /// In en, this message translates to:
  /// **'Units avoided × minutes of life per unit (≈ 20 min per cigarette, Jackson et al. 2025).'**
  String get statsMetricQt10Formula;

  /// No description provided for @statsMetricQt10Title.
  ///
  /// In en, this message translates to:
  /// **'Life regained'**
  String get statsMetricQt10Title;

  /// No description provided for @statsMetricQt11Desc.
  ///
  /// In en, this message translates to:
  /// **'Typical recovery milestones after the last cigarette.'**
  String get statsMetricQt11Desc;

  /// No description provided for @statsMetricQt11Formula.
  ///
  /// In en, this message translates to:
  /// **'Progress = current abstinence ÷ milestone time; the clock restarts after a slip.'**
  String get statsMetricQt11Formula;

  /// No description provided for @statsMetricQt11Title.
  ///
  /// In en, this message translates to:
  /// **'Health milestones'**
  String get statsMetricQt11Title;

  /// No description provided for @statsMetricQt12Desc.
  ///
  /// In en, this message translates to:
  /// **'How often you stayed within your daily limit, and how much you cut down.'**
  String get statsMetricQt12Desc;

  /// No description provided for @statsMetricQt12Formula.
  ///
  /// In en, this message translates to:
  /// **'Days within limit ÷ days; reduction = 1 − average use ÷ baseline.'**
  String get statsMetricQt12Formula;

  /// No description provided for @statsMetricQt12Title.
  ///
  /// In en, this message translates to:
  /// **'Reduction progress'**
  String get statsMetricQt12Title;

  /// No description provided for @statsMetricQt13Desc.
  ///
  /// In en, this message translates to:
  /// **'How often cravings hit, and how strong they were.'**
  String get statsMetricQt13Desc;

  /// No description provided for @statsMetricQt13Formula.
  ///
  /// In en, this message translates to:
  /// **'Cravings per day over the period; mean and peak intensity; 7-day rolling mean.'**
  String get statsMetricQt13Formula;

  /// No description provided for @statsMetricQt13Title.
  ///
  /// In en, this message translates to:
  /// **'Craving load'**
  String get statsMetricQt13Title;

  /// No description provided for @statsMetricQt14Desc.
  ///
  /// In en, this message translates to:
  /// **'What triggers cravings, where and when.'**
  String get statsMetricQt14Desc;

  /// No description provided for @statsMetricQt14Formula.
  ///
  /// In en, this message translates to:
  /// **'Pareto by trigger, place and mood; weekday × hour matrix.'**
  String get statsMetricQt14Formula;

  /// No description provided for @statsMetricQt14Title.
  ///
  /// In en, this message translates to:
  /// **'Craving context'**
  String get statsMetricQt14Title;

  /// No description provided for @statsNoteAbstainMode.
  ///
  /// In en, this message translates to:
  /// **'Only for reduce-mode trackers.'**
  String get statsNoteAbstainMode;

  /// No description provided for @statsNoteAllDay.
  ///
  /// In en, this message translates to:
  /// **'All-day tasks have no duration.'**
  String get statsNoteAllDay;

  /// No description provided for @statsNoteClosed.
  ///
  /// In en, this message translates to:
  /// **'This item is closed.'**
  String get statsNoteClosed;

  /// No description provided for @statsNoteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t compute'**
  String get statsNoteError;

  /// No description provided for @statsNoteLimitHabit.
  ///
  /// In en, this message translates to:
  /// **'Limit habits show within-limit days instead.'**
  String get statsNoteLimitHabit;

  /// No description provided for @statsNoteLowCoverage.
  ///
  /// In en, this message translates to:
  /// **'Track time on at least 60 % of done tasks to see this.'**
  String get statsNoteLowCoverage;

  /// No description provided for @statsNoteNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statsNoteNew;

  /// No description provided for @statsNoteNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get statsNoteNoData;

  /// No description provided for @statsNoteNoGoal.
  ///
  /// In en, this message translates to:
  /// **'No goal set'**
  String get statsNoteNoGoal;

  /// No description provided for @statsNoteNoHabit.
  ///
  /// In en, this message translates to:
  /// **'This habit couldn’t be found.'**
  String get statsNoteNoHabit;

  /// No description provided for @statsNoteNoItem.
  ///
  /// In en, this message translates to:
  /// **'This item couldn’t be found.'**
  String get statsNoteNoItem;

  /// No description provided for @statsNoteNoLifeEstimate.
  ///
  /// In en, this message translates to:
  /// **'Set minutes of life per unit to see this estimate.'**
  String get statsNoteNoLifeEstimate;

  /// No description provided for @statsNoteNoOccurrence.
  ///
  /// In en, this message translates to:
  /// **'This occurrence couldn’t be found.'**
  String get statsNoteNoOccurrence;

  /// No description provided for @statsNoteNoQuitTrackers.
  ///
  /// In en, this message translates to:
  /// **'No quit trackers yet.'**
  String get statsNoteNoQuitTrackers;

  /// No description provided for @statsNoteNoTracker.
  ///
  /// In en, this message translates to:
  /// **'This quit tracker couldn’t be found.'**
  String get statsNoteNoTracker;

  /// No description provided for @statsNoteNoUnitCost.
  ///
  /// In en, this message translates to:
  /// **'Set a unit cost to see savings.'**
  String get statsNoteNoUnitCost;

  /// No description provided for @statsNoteNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get statsNoteNotApplicable;

  /// No description provided for @statsNoteNotDone.
  ///
  /// In en, this message translates to:
  /// **'Not done yet'**
  String get statsNoteNotDone;

  /// No description provided for @statsNoteNotOverdue.
  ///
  /// In en, this message translates to:
  /// **'Not overdue'**
  String get statsNoteNotOverdue;

  /// No description provided for @statsNoteNotScheduled.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get statsNoteNotScheduled;

  /// No description provided for @statsNoteNotSmoking.
  ///
  /// In en, this message translates to:
  /// **'Health milestones are shown for smoking trackers only.'**
  String get statsNoteNotSmoking;

  /// No description provided for @statsNoteNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get statsNoteNotStarted;

  /// No description provided for @statsNoteNotTracked.
  ///
  /// In en, this message translates to:
  /// **'Actual time not tracked'**
  String get statsNoteNotTracked;

  /// No description provided for @statsNotePastPeriod.
  ///
  /// In en, this message translates to:
  /// **'Only for current and future periods.'**
  String get statsNotePastPeriod;

  /// No description provided for @statsNotePopulationEstimate.
  ///
  /// In en, this message translates to:
  /// **'Population estimate'**
  String get statsNotePopulationEstimate;

  /// No description provided for @statsNoteUsedPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned time shown: actual time is tracked on fewer than 60 % of done tasks.'**
  String get statsNoteUsedPlanned;

  /// No description provided for @statsNoteYesNoHabit.
  ///
  /// In en, this message translates to:
  /// **'Not available for yes/no habits.'**
  String get statsNoteYesNoHabit;

  /// No description provided for @statsNoteZeroDenominator.
  ///
  /// In en, this message translates to:
  /// **'Nothing was due in this period.'**
  String get statsNoteZeroDenominator;

  /// No description provided for @statsOpenInsights.
  ///
  /// In en, this message translates to:
  /// **'Open {section}'**
  String statsOpenInsights(String section);

  /// No description provided for @statsOverviewNextUp.
  ///
  /// In en, this message translates to:
  /// **'Next up: {title} at {time}'**
  String statsOverviewNextUp(String title, String time);

  /// No description provided for @statsOverviewOpenReview.
  ///
  /// In en, this message translates to:
  /// **'Weekly review'**
  String get statsOverviewOpenReview;

  /// No description provided for @statsPeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statsPeriodAll;

  /// No description provided for @statsPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get statsPeriodCustom;

  /// No description provided for @statsPeriodCustomRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String statsPeriodCustomRange(String from, String to);

  /// No description provided for @statsPeriodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get statsPeriodLastMonth;

  /// No description provided for @statsPeriodLastQuarter.
  ///
  /// In en, this message translates to:
  /// **'Last quarter'**
  String get statsPeriodLastQuarter;

  /// No description provided for @statsPeriodLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get statsPeriodLastWeek;

  /// No description provided for @statsPeriodLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get statsPeriodLastYear;

  /// No description provided for @statsPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get statsPeriodMonth;

  /// No description provided for @statsPeriodQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get statsPeriodQuarter;

  /// No description provided for @statsPeriodRolling.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String statsPeriodRolling(String days);

  /// No description provided for @statsPeriodRollingMenu.
  ///
  /// In en, this message translates to:
  /// **'Rolling'**
  String get statsPeriodRollingMenu;

  /// No description provided for @statsPeriodSelected.
  ///
  /// In en, this message translates to:
  /// **'Period: {period}'**
  String statsPeriodSelected(String period);

  /// No description provided for @statsPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsPeriodToday;

  /// No description provided for @statsPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get statsPeriodWeek;

  /// No description provided for @statsPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get statsPeriodYear;

  /// No description provided for @statsPeriodYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get statsPeriodYesterday;

  /// No description provided for @statsQuitMilestoneBreathing72h.
  ///
  /// In en, this message translates to:
  /// **'Breathing gets easier; energy rises'**
  String get statsQuitMilestoneBreathing72h;

  /// No description provided for @statsQuitMilestoneCancers20y.
  ///
  /// In en, this message translates to:
  /// **'Mouth, throat, larynx and pancreas cancer risk near a never-smoker’s'**
  String get statsQuitMilestoneCancers20y;

  /// No description provided for @statsQuitMilestoneChd15y.
  ///
  /// In en, this message translates to:
  /// **'Coronary heart disease risk close to a non-smoker’s'**
  String get statsQuitMilestoneChd15y;

  /// No description provided for @statsQuitMilestoneChdAdded.
  ///
  /// In en, this message translates to:
  /// **'Added coronary heart disease risk halves'**
  String get statsQuitMilestoneChdAdded;

  /// No description provided for @statsQuitMilestoneCirculation.
  ///
  /// In en, this message translates to:
  /// **'Circulation and lung function improve'**
  String get statsQuitMilestoneCirculation;

  /// No description provided for @statsQuitMilestoneCo12h.
  ///
  /// In en, this message translates to:
  /// **'Blood carbon monoxide back to normal'**
  String get statsQuitMilestoneCo12h;

  /// No description provided for @statsQuitMilestoneCo8h.
  ///
  /// In en, this message translates to:
  /// **'Carbon monoxide in the blood is halved; oxygen levels recover'**
  String get statsQuitMilestoneCo8h;

  /// No description provided for @statsQuitMilestoneCravings.
  ///
  /// In en, this message translates to:
  /// **'Cravings usually ease (a single craving lasts about 3–5 min)'**
  String get statsQuitMilestoneCravings;

  /// No description provided for @statsQuitMilestoneHeart20m.
  ///
  /// In en, this message translates to:
  /// **'Heart rate and blood pressure drop; pulse returns to normal'**
  String get statsQuitMilestoneHeart20m;

  /// No description provided for @statsQuitMilestoneHeartAttack.
  ///
  /// In en, this message translates to:
  /// **'Heart-attack risk drops sharply'**
  String get statsQuitMilestoneHeartAttack;

  /// No description provided for @statsQuitMilestoneHeartHalf1y.
  ///
  /// In en, this message translates to:
  /// **'Coronary heart disease risk about half that of a smoker'**
  String get statsQuitMilestoneHeartHalf1y;

  /// No description provided for @statsQuitMilestoneLifeExpectancy.
  ///
  /// In en, this message translates to:
  /// **'Quitting at 30 / 40 / 50 / 60 gains about 10 / 9 / 6 / 3 years of life expectancy'**
  String get statsQuitMilestoneLifeExpectancy;

  /// No description provided for @statsQuitMilestoneLungCancer10y.
  ///
  /// In en, this message translates to:
  /// **'Lung-cancer risk about half that of a smoker'**
  String get statsQuitMilestoneLungCancer10y;

  /// No description provided for @statsQuitMilestoneLungs.
  ///
  /// In en, this message translates to:
  /// **'Coughing and shortness of breath decrease; lung function up to ~10 % better'**
  String get statsQuitMilestoneLungs;

  /// No description provided for @statsQuitMilestoneMouthCancer.
  ///
  /// In en, this message translates to:
  /// **'Mouth, throat and larynx cancer risk halves; stroke risk falls'**
  String get statsQuitMilestoneMouthCancer;

  /// No description provided for @statsQuitMilestoneNicotine24h.
  ///
  /// In en, this message translates to:
  /// **'Nicotine in the blood falls to zero'**
  String get statsQuitMilestoneNicotine24h;

  /// No description provided for @statsQuitMilestoneTaste48h.
  ///
  /// In en, this message translates to:
  /// **'Lungs clear mucus; taste and smell improve'**
  String get statsQuitMilestoneTaste48h;

  /// No description provided for @statsReviewAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk: {title}'**
  String statsReviewAtRisk(String title);

  /// No description provided for @statsReviewBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked or waiting: {title}'**
  String statsReviewBlocked(String title);

  /// No description provided for @statsReviewFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up overdue: {title}'**
  String statsReviewFollowUp(String title);

  /// No description provided for @statsReviewHeadline.
  ///
  /// In en, this message translates to:
  /// **'Headline numbers'**
  String get statsReviewHeadline;

  /// No description provided for @statsReviewHealth.
  ///
  /// In en, this message translates to:
  /// **'Health milestone reached: {title}'**
  String statsReviewHealth(String title);

  /// No description provided for @statsReviewLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get statsReviewLastWeek;

  /// No description provided for @statsReviewLoad.
  ///
  /// In en, this message translates to:
  /// **'{planned} planned of {capacity}'**
  String statsReviewLoad(String planned, String capacity);

  /// No description provided for @statsReviewNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get statsReviewNextWeek;

  /// No description provided for @statsReviewNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing here this week.'**
  String get statsReviewNothing;

  /// No description provided for @statsReviewOverbooked.
  ///
  /// In en, this message translates to:
  /// **'{date} is overbooked by {time}'**
  String statsReviewOverbooked(String date, String time);

  /// No description provided for @statsReviewOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue: {title}'**
  String statsReviewOverdue(String title);

  /// No description provided for @statsReviewPerfectDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 perfect day} other{{count} perfect days}}'**
  String statsReviewPerfectDays(num count);

  /// No description provided for @statsReviewRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String statsReviewRange(String from, String to);

  /// No description provided for @statsReviewRecord.
  ///
  /// In en, this message translates to:
  /// **'New record: {title}'**
  String statsReviewRecord(String title);

  /// No description provided for @statsReviewStale.
  ///
  /// In en, this message translates to:
  /// **'No recent activity: {title}'**
  String statsReviewStale(String title);

  /// No description provided for @statsReviewStreak.
  ///
  /// In en, this message translates to:
  /// **'{title}: {count}-day streak'**
  String statsReviewStreak(String title, String count);

  /// No description provided for @statsReviewThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week so far'**
  String get statsReviewThisWeek;

  /// No description provided for @statsReviewTime.
  ///
  /// In en, this message translates to:
  /// **'Where the time went'**
  String get statsReviewTime;

  /// No description provided for @statsScopeChecklist.
  ///
  /// In en, this message translates to:
  /// **'List insights'**
  String get statsScopeChecklist;

  /// No description provided for @statsScopeChecklists.
  ///
  /// In en, this message translates to:
  /// **'Lists insights'**
  String get statsScopeChecklists;

  /// No description provided for @statsScopeGlobal.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsScopeGlobal;

  /// No description provided for @statsScopeHabit.
  ///
  /// In en, this message translates to:
  /// **'Habit insights'**
  String get statsScopeHabit;

  /// No description provided for @statsScopeHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits insights'**
  String get statsScopeHabits;

  /// No description provided for @statsScopeItem.
  ///
  /// In en, this message translates to:
  /// **'Item insights'**
  String get statsScopeItem;

  /// No description provided for @statsScopePlanner.
  ///
  /// In en, this message translates to:
  /// **'Plan insights'**
  String get statsScopePlanner;

  /// No description provided for @statsScopeQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit insights'**
  String get statsScopeQuit;

  /// No description provided for @statsScopeReview.
  ///
  /// In en, this message translates to:
  /// **'Weekly review'**
  String get statsScopeReview;

  /// No description provided for @statsScopeSeries.
  ///
  /// In en, this message translates to:
  /// **'Series insights'**
  String get statsScopeSeries;

  /// No description provided for @statsScopeTask.
  ///
  /// In en, this message translates to:
  /// **'Task insights'**
  String get statsScopeTask;

  /// No description provided for @statsScopeYear.
  ///
  /// In en, this message translates to:
  /// **'Year in review'**
  String get statsScopeYear;

  /// No description provided for @statsSectionAbstinence.
  ///
  /// In en, this message translates to:
  /// **'Abstinence'**
  String get statsSectionAbstinence;

  /// No description provided for @statsSectionAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get statsSectionAdvanced;

  /// No description provided for @statsSectionAllocation.
  ///
  /// In en, this message translates to:
  /// **'Time allocation'**
  String get statsSectionAllocation;

  /// No description provided for @statsSectionCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get statsSectionCalendar;

  /// No description provided for @statsSectionCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get statsSectionCapacity;

  /// No description provided for @statsSectionCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse {section}'**
  String statsSectionCollapse(String section);

  /// No description provided for @statsSectionCravings.
  ///
  /// In en, this message translates to:
  /// **'Cravings'**
  String get statsSectionCravings;

  /// No description provided for @statsSectionExecution.
  ///
  /// In en, this message translates to:
  /// **'Execution'**
  String get statsSectionExecution;

  /// No description provided for @statsSectionExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand {section}'**
  String statsSectionExpand(String section);

  /// No description provided for @statsSectionFlow.
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get statsSectionFlow;

  /// No description provided for @statsSectionFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus & balance'**
  String get statsSectionFocus;

  /// No description provided for @statsSectionHabitTable.
  ///
  /// In en, this message translates to:
  /// **'Your habits'**
  String get statsSectionHabitTable;

  /// No description provided for @statsSectionHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get statsSectionHistory;

  /// No description provided for @statsSectionItem.
  ///
  /// In en, this message translates to:
  /// **'This item'**
  String get statsSectionItem;

  /// No description provided for @statsSectionLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get statsSectionLists;

  /// No description provided for @statsSectionMilestones.
  ///
  /// In en, this message translates to:
  /// **'Health milestones'**
  String get statsSectionMilestones;

  /// No description provided for @statsSectionMoney.
  ///
  /// In en, this message translates to:
  /// **'Money & units'**
  String get statsSectionMoney;

  /// No description provided for @statsSectionOccurrence.
  ///
  /// In en, this message translates to:
  /// **'This occurrence'**
  String get statsSectionOccurrence;

  /// No description provided for @statsSectionOutcomes.
  ///
  /// In en, this message translates to:
  /// **'Outcomes'**
  String get statsSectionOutcomes;

  /// No description provided for @statsSectionPatterns.
  ///
  /// In en, this message translates to:
  /// **'Patterns'**
  String get statsSectionPatterns;

  /// No description provided for @statsSectionPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get statsSectionPinned;

  /// No description provided for @statsSectionPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get statsSectionPlanning;

  /// No description provided for @statsSectionPlanningQuality.
  ///
  /// In en, this message translates to:
  /// **'Planning quality'**
  String get statsSectionPlanningQuality;

  /// No description provided for @statsSectionQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get statsSectionQuality;

  /// No description provided for @statsSectionQuitTrackers.
  ///
  /// In en, this message translates to:
  /// **'Quit trackers'**
  String get statsSectionQuitTrackers;

  /// No description provided for @statsSectionReduction.
  ///
  /// In en, this message translates to:
  /// **'Reduction'**
  String get statsSectionReduction;

  /// No description provided for @statsSectionReview.
  ///
  /// In en, this message translates to:
  /// **'Weekly review'**
  String get statsSectionReview;

  /// No description provided for @statsSectionSeries.
  ///
  /// In en, this message translates to:
  /// **'Execution'**
  String get statsSectionSeries;

  /// No description provided for @statsSectionShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get statsSectionShortcuts;

  /// No description provided for @statsSectionStale.
  ///
  /// In en, this message translates to:
  /// **'Stale items'**
  String get statsSectionStale;

  /// No description provided for @statsSectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statsSectionStatus;

  /// No description provided for @statsSectionStreaks.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get statsSectionStreaks;

  /// No description provided for @statsSectionStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get statsSectionStrength;

  /// No description provided for @statsSectionTargetVolume.
  ///
  /// In en, this message translates to:
  /// **'Target & volume'**
  String get statsSectionTargetVolume;

  /// No description provided for @statsSectionTiming.
  ///
  /// In en, this message translates to:
  /// **'Timing & patterns'**
  String get statsSectionTiming;

  /// No description provided for @statsSectionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsSectionToday;

  /// No description provided for @statsSectionTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get statsSectionTrend;

  /// No description provided for @statsSectionWeek.
  ///
  /// In en, this message translates to:
  /// **'Week at a glance'**
  String get statsSectionWeek;

  /// No description provided for @statsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all stats'**
  String get statsSeeAll;

  /// No description provided for @statsSeeSeries.
  ///
  /// In en, this message translates to:
  /// **'See series stats'**
  String get statsSeeSeries;

  /// No description provided for @statsSegmentHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get statsSegmentHabits;

  /// No description provided for @statsSegmentLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get statsSegmentLists;

  /// No description provided for @statsSegmentOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsSegmentOverview;

  /// No description provided for @statsSegmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get statsSegmentPlan;

  /// No description provided for @statsSegmentQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get statsSegmentQuit;

  /// No description provided for @statsSourceAcs.
  ///
  /// In en, this message translates to:
  /// **'American Cancer Society'**
  String get statsSourceAcs;

  /// No description provided for @statsSourceBmj2000.
  ///
  /// In en, this message translates to:
  /// **'Shaw et al., BMJ 2000'**
  String get statsSourceBmj2000;

  /// No description provided for @statsSourceCdc.
  ///
  /// In en, this message translates to:
  /// **'CDC'**
  String get statsSourceCdc;

  /// No description provided for @statsSourceHse.
  ///
  /// In en, this message translates to:
  /// **'HSE'**
  String get statsSourceHse;

  /// No description provided for @statsSourceJackson2025.
  ///
  /// In en, this message translates to:
  /// **'Jackson et al., Addiction 2025'**
  String get statsSourceJackson2025;

  /// No description provided for @statsSourceNci.
  ///
  /// In en, this message translates to:
  /// **'National Cancer Institute'**
  String get statsSourceNci;

  /// No description provided for @statsSourceNhs.
  ///
  /// In en, this message translates to:
  /// **'NHS'**
  String get statsSourceNhs;

  /// No description provided for @statsSourceWho.
  ///
  /// In en, this message translates to:
  /// **'WHO'**
  String get statsSourceWho;

  /// No description provided for @statsUnknownScope.
  ///
  /// In en, this message translates to:
  /// **'This insight doesn’t exist.'**
  String get statsUnknownScope;

  /// No description provided for @statusAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add note…'**
  String get statusAddNote;

  /// No description provided for @statusAgeDays.
  ///
  /// In en, this message translates to:
  /// **'{n} d'**
  String statusAgeDays(int n);

  /// No description provided for @statusAgeHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h'**
  String statusAgeHours(int n);

  /// No description provided for @statusAgeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String statusAgeMinutes(int n);

  /// No description provided for @statusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get statusBlocked;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusCascadeAll.
  ///
  /// In en, this message translates to:
  /// **'Complete all'**
  String get statusCascadeAll;

  /// No description provided for @statusCascadeOnlyThis.
  ///
  /// In en, this message translates to:
  /// **'Only this one'**
  String get statusCascadeOnlyThis;

  /// No description provided for @statusCascadeTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Also complete 1 open sub-item?} other{Also complete {count} open sub-items?}}'**
  String statusCascadeTitle(int count);

  /// No description provided for @statusChange.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get statusChange;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Follow up'**
  String get statusFollowUp;

  /// No description provided for @statusFollowUpChip.
  ///
  /// In en, this message translates to:
  /// **'Check back {when}'**
  String statusFollowUpChip(String when);

  /// No description provided for @statusFollowUpCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get statusFollowUpCustom;

  /// No description provided for @statusFollowUpIn3Days.
  ///
  /// In en, this message translates to:
  /// **'In 3 days'**
  String get statusFollowUpIn3Days;

  /// No description provided for @statusFollowUpLaterToday.
  ///
  /// In en, this message translates to:
  /// **'Later today'**
  String get statusFollowUpLaterToday;

  /// No description provided for @statusFollowUpNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get statusFollowUpNextWeek;

  /// No description provided for @statusFollowUpNone.
  ///
  /// In en, this message translates to:
  /// **'No follow-up'**
  String get statusFollowUpNone;

  /// No description provided for @statusFollowUpOverdue.
  ///
  /// In en, this message translates to:
  /// **'Check back now'**
  String get statusFollowUpOverdue;

  /// No description provided for @statusFollowUpTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow 09:00'**
  String get statusFollowUpTomorrow;

  /// No description provided for @statusKeepFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Keep follow-up'**
  String get statusKeepFollowUp;

  /// No description provided for @statusMarked.
  ///
  /// In en, this message translates to:
  /// **'Marked {status}'**
  String statusMarked(String status);

  /// No description provided for @statusOngoing.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusOngoing;

  /// No description provided for @statusReasonBlocked.
  ///
  /// In en, this message translates to:
  /// **'What\'s blocking it?'**
  String get statusReasonBlocked;

  /// No description provided for @statusReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get statusReasonOther;

  /// No description provided for @statusReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required'**
  String get statusReasonRequired;

  /// No description provided for @statusReasonWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting on whom / what?'**
  String get statusReasonWaiting;

  /// No description provided for @statusRecentReasons.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get statusRecentReasons;

  /// No description provided for @statusSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusSheetTitle;

  /// No description provided for @statusStale.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get statusStale;

  /// No description provided for @statusTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get statusTodo;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statusWaiting;

  /// No description provided for @statusWithAge.
  ///
  /// In en, this message translates to:
  /// **'{status} · {age}'**
  String statusWithAge(String status, String age);

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync problem'**
  String get syncError;

  /// No description provided for @syncIdle.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncIdle;

  /// No description provided for @syncLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'On this device only'**
  String get syncLocalOnly;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline — changes will sync later'**
  String get syncOffline;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No pending changes} =1{1 change waiting} other{{count} changes waiting}}'**
  String syncPending(int count);

  /// No description provided for @syncPulling.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get syncPulling;

  /// No description provided for @syncPushing.
  ///
  /// In en, this message translates to:
  /// **'Uploading changes…'**
  String get syncPushing;

  /// No description provided for @tabHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get tabHabits;

  /// No description provided for @tabInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get tabInsights;

  /// No description provided for @tabLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get tabLists;

  /// No description provided for @tabPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get tabPlan;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tagAdd.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get tagAdd;

  /// No description provided for @tagChipSemantics.
  ///
  /// In en, this message translates to:
  /// **'Tag {name}'**
  String tagChipSemantics(String name);

  /// No description provided for @tagCreateNamed.
  ///
  /// In en, this message translates to:
  /// **'Create tag “{name}”'**
  String tagCreateNamed(String name);

  /// No description provided for @tagDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{This tag isn\'t used yet.} =1{It will be removed from 1 item.} other{It will be removed from {count} items.}}'**
  String tagDeleteBody(int count);

  /// No description provided for @tagEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get tagEdit;

  /// No description provided for @tagErrorDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A tag with this name already exists.'**
  String get tagErrorDuplicate;

  /// No description provided for @tagErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 40 characters.'**
  String get tagErrorInvalid;

  /// No description provided for @tagMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge into…'**
  String get tagMerge;

  /// No description provided for @tagMergeAction.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get tagMergeAction;

  /// No description provided for @tagMergeConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Everything tagged “{source}” will be tagged “{target}” instead, and “{source}” will be deleted.'**
  String tagMergeConfirmBody(String source, String target);

  /// No description provided for @tagMergeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge tags?'**
  String get tagMergeConfirmTitle;

  /// No description provided for @tagMergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge “{name}” into'**
  String tagMergeTitle(String name);

  /// No description provided for @tagMergedSnack.
  ///
  /// In en, this message translates to:
  /// **'Merged into “{name}”'**
  String tagMergedSnack(String name);

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagName;

  /// No description provided for @tagNew.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get tagNew;

  /// No description provided for @tagNoColor.
  ///
  /// In en, this message translates to:
  /// **'No color'**
  String get tagNoColor;

  /// No description provided for @tagPickerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search or create a tag'**
  String get tagPickerSearch;

  /// No description provided for @tagPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagPickerTitle;

  /// No description provided for @tagRemoveSemantics.
  ///
  /// In en, this message translates to:
  /// **'Remove tag {name}'**
  String tagRemoveSemantics(String name);

  /// No description provided for @tagUsage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not used} =1{1 item} other{{count} items}}'**
  String tagUsage(int count);

  /// No description provided for @tagsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get tagsEmpty;

  /// No description provided for @tagsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tags work across sections — use them for contexts like errands or waiting on others.'**
  String get tagsEmptyHint;

  /// No description provided for @tagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsTitle;

  /// No description provided for @tagsUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Tags updated'**
  String get tagsUpdatedSnack;

  /// No description provided for @tasksActionDuplicateSeries.
  ///
  /// In en, this message translates to:
  /// **'Duplicate as new series'**
  String get tasksActionDuplicateSeries;

  /// No description provided for @tasksActionDuplicateTo.
  ///
  /// In en, this message translates to:
  /// **'Duplicate to…'**
  String get tasksActionDuplicateTo;

  /// No description provided for @tasksActionExceptions.
  ///
  /// In en, this message translates to:
  /// **'Skipped & moved occurrences'**
  String get tasksActionExceptions;

  /// No description provided for @tasksActionMoveToToday.
  ///
  /// In en, this message translates to:
  /// **'Move to today'**
  String get tasksActionMoveToToday;

  /// No description provided for @tasksActionOpenSeries.
  ///
  /// In en, this message translates to:
  /// **'Open series'**
  String get tasksActionOpenSeries;

  /// No description provided for @tasksActionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause series'**
  String get tasksActionPause;

  /// No description provided for @tasksActionPauseTimer.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get tasksActionPauseTimer;

  /// No description provided for @tasksActionReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get tasksActionReopen;

  /// No description provided for @tasksActionReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule…'**
  String get tasksActionReschedule;

  /// No description provided for @tasksActionRestoreSeries.
  ///
  /// In en, this message translates to:
  /// **'Restore to series'**
  String get tasksActionRestoreSeries;

  /// No description provided for @tasksActionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume series'**
  String get tasksActionResume;

  /// No description provided for @tasksActionResumeTimer.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get tasksActionResumeTimer;

  /// No description provided for @tasksActionSeriesHistory.
  ///
  /// In en, this message translates to:
  /// **'Series history'**
  String get tasksActionSeriesHistory;

  /// No description provided for @tasksActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share as text'**
  String get tasksActionShare;

  /// No description provided for @tasksActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get tasksActionStart;

  /// No description provided for @tasksActionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get tasksActionStop;

  /// No description provided for @tasksActionUnschedule.
  ///
  /// In en, this message translates to:
  /// **'Move to backlog'**
  String get tasksActionUnschedule;

  /// No description provided for @tasksActualAsPlanned.
  ///
  /// In en, this message translates to:
  /// **'As planned'**
  String get tasksActualAsPlanned;

  /// No description provided for @tasksActualCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get tasksActualCustom;

  /// No description provided for @tasksActualEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The end must be after the start'**
  String get tasksActualEndBeforeStart;

  /// No description provided for @tasksActualJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get tasksActualJustNow;

  /// No description provided for @tasksActualNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get tasksActualNotSet;

  /// No description provided for @tasksActualTime.
  ///
  /// In en, this message translates to:
  /// **'Actual time'**
  String get tasksActualTime;

  /// No description provided for @tasksActualTitle.
  ///
  /// In en, this message translates to:
  /// **'When did you do it?'**
  String get tasksActualTitle;

  /// No description provided for @tasksAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add session'**
  String get tasksAddEntry;

  /// No description provided for @tasksAddTag.
  ///
  /// In en, this message translates to:
  /// **'Add a tag'**
  String get tasksAddTag;

  /// No description provided for @tasksAnchorMoved.
  ///
  /// In en, this message translates to:
  /// **'Start moved to {date} to match the repeat rule'**
  String tasksAnchorMoved(String date);

  /// No description provided for @tasksAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get tasksAttachments;

  /// No description provided for @tasksAttachmentsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Photos and files will be available here soon'**
  String get tasksAttachmentsPlaceholder;

  /// No description provided for @tasksBacklogLabel.
  ///
  /// In en, this message translates to:
  /// **'Unscheduled'**
  String get tasksBacklogLabel;

  /// No description provided for @tasksBulkAddTags.
  ///
  /// In en, this message translates to:
  /// **'Add tags'**
  String get tasksBulkAddTags;

  /// No description provided for @tasksBulkDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tasksBulkDelete;

  /// No description provided for @tasksBulkDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 item?} other{Delete {count} items?}}'**
  String tasksBulkDeleteConfirm(int count);

  /// No description provided for @tasksBulkDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item updated} other{{count} items updated}}'**
  String tasksBulkDone(int count);

  /// No description provided for @tasksBulkDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get tasksBulkDuplicate;

  /// No description provided for @tasksBulkEarlier15.
  ///
  /// In en, this message translates to:
  /// **'15 min earlier'**
  String get tasksBulkEarlier15;

  /// No description provided for @tasksBulkEarlierDay.
  ///
  /// In en, this message translates to:
  /// **'1 day earlier'**
  String get tasksBulkEarlierDay;

  /// No description provided for @tasksBulkLater15.
  ///
  /// In en, this message translates to:
  /// **'15 min later'**
  String get tasksBulkLater15;

  /// No description provided for @tasksBulkLater1h.
  ///
  /// In en, this message translates to:
  /// **'1 hour later'**
  String get tasksBulkLater1h;

  /// No description provided for @tasksBulkLaterDay.
  ///
  /// In en, this message translates to:
  /// **'1 day later'**
  String get tasksBulkLaterDay;

  /// No description provided for @tasksBulkLaterWeek.
  ///
  /// In en, this message translates to:
  /// **'1 week later'**
  String get tasksBulkLaterWeek;

  /// No description provided for @tasksBulkMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get tasksBulkMove;

  /// No description provided for @tasksBulkSetCategory.
  ///
  /// In en, this message translates to:
  /// **'Set category'**
  String get tasksBulkSetCategory;

  /// No description provided for @tasksBulkSetPriority.
  ///
  /// In en, this message translates to:
  /// **'Set priority'**
  String get tasksBulkSetPriority;

  /// No description provided for @tasksBulkSetTracking.
  ///
  /// In en, this message translates to:
  /// **'Set tracking mode'**
  String get tasksBulkSetTracking;

  /// No description provided for @tasksBulkTarget.
  ///
  /// In en, this message translates to:
  /// **'For recurring items'**
  String get tasksBulkTarget;

  /// No description provided for @tasksBulkTargetOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Only these occurrences'**
  String get tasksBulkTargetOccurrence;

  /// No description provided for @tasksBulkTargetSeries.
  ///
  /// In en, this message translates to:
  /// **'Whole series'**
  String get tasksBulkTargetSeries;

  /// No description provided for @tasksBulkTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item selected} other{{count} items selected}}'**
  String tasksBulkTitle(int count);

  /// No description provided for @tasksChecklistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No checklists yet'**
  String get tasksChecklistEmpty;

  /// No description provided for @tasksChecklistNew.
  ///
  /// In en, this message translates to:
  /// **'New checklist'**
  String get tasksChecklistNew;

  /// No description provided for @tasksChecklistNewName.
  ///
  /// In en, this message translates to:
  /// **'Checklist name'**
  String get tasksChecklistNewName;

  /// No description provided for @tasksChecklistNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get tasksChecklistNone;

  /// No description provided for @tasksChecklistOpen.
  ///
  /// In en, this message translates to:
  /// **'Open checklist'**
  String get tasksChecklistOpen;

  /// No description provided for @tasksChecklistPick.
  ///
  /// In en, this message translates to:
  /// **'Link a checklist'**
  String get tasksChecklistPick;

  /// No description provided for @tasksChecklistProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} done'**
  String tasksChecklistProgress(int done, int total);

  /// No description provided for @tasksChecklistUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get tasksChecklistUnlink;

  /// No description provided for @tasksColorCategoryDefault.
  ///
  /// In en, this message translates to:
  /// **'Category color'**
  String get tasksColorCategoryDefault;

  /// No description provided for @tasksCompletion.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tasksCompletion;

  /// No description provided for @tasksCompletionValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String tasksCompletionValue(int percent);

  /// No description provided for @tasksCreated.
  ///
  /// In en, this message translates to:
  /// **'Task created'**
  String get tasksCreated;

  /// No description provided for @tasksCustomDuration.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get tasksCustomDuration;

  /// No description provided for @tasksDayDoneAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all remaining as done'**
  String get tasksDayDoneAll;

  /// No description provided for @tasksDayDoneAllSnack.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing left to mark} =1{1 task marked as done} other{{count} tasks marked as done}}'**
  String tasksDayDoneAllSnack(int count);

  /// No description provided for @tasksDayMoveTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Move unfinished to tomorrow'**
  String get tasksDayMoveTomorrow;

  /// No description provided for @tasksDayMoveTomorrowSnack.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to move} =1{1 task moved to tomorrow} other{{count} tasks moved to tomorrow}}'**
  String tasksDayMoveTomorrowSnack(int count);

  /// No description provided for @tasksDaySkipRest.
  ///
  /// In en, this message translates to:
  /// **'Skip the rest of the day'**
  String get tasksDaySkipRest;

  /// No description provided for @tasksDaySkipRestSnack.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing left to skip} =1{1 task skipped} other{{count} tasks skipped}}'**
  String tasksDaySkipRestSnack(int count);

  /// No description provided for @tasksDeadlineNone.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get tasksDeadlineNone;

  /// No description provided for @tasksDeadlineWarning.
  ///
  /// In en, this message translates to:
  /// **'Planned after the deadline'**
  String get tasksDeadlineWarning;

  /// No description provided for @tasksDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It stays in Trash for 30 days.'**
  String get tasksDeleteConfirmBody;

  /// No description provided for @tasksDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get tasksDeleteConfirmTitle;

  /// No description provided for @tasksDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get tasksDeleted;

  /// No description provided for @tasksDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'This task no longer exists'**
  String get tasksDetailNotFound;

  /// No description provided for @tasksDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get tasksDetailTitle;

  /// No description provided for @tasksDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get tasksDiscard;

  /// No description provided for @tasksDuplicateToConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Pick dates} =1{Duplicate to 1 date} other{Duplicate to {count} dates}}'**
  String tasksDuplicateToConfirm(int count);

  /// No description provided for @tasksDuplicateToTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate to…'**
  String get tasksDuplicateToTitle;

  /// No description provided for @tasksDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Task duplicated'**
  String get tasksDuplicated;

  /// No description provided for @tasksDuplicatedTo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copied to 1 date} other{Copied to {count} dates}}'**
  String tasksDuplicatedTo(int count);

  /// No description provided for @tasksDurationMode.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get tasksDurationMode;

  /// No description provided for @tasksEditorEditOccurrenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit occurrence'**
  String get tasksEditorEditOccurrenceTitle;

  /// No description provided for @tasksEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get tasksEditorEditTitle;

  /// No description provided for @tasksEditorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get tasksEditorNewTitle;

  /// No description provided for @tasksEndMode.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get tasksEndMode;

  /// No description provided for @tasksEntryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get tasksEntryDelete;

  /// No description provided for @tasksEntryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get tasksEntryEdit;

  /// No description provided for @tasksEntryFuture.
  ///
  /// In en, this message translates to:
  /// **'A session can\'t start in the future'**
  String get tasksEntryFuture;

  /// No description provided for @tasksEntryNegative.
  ///
  /// In en, this message translates to:
  /// **'The end must be after the start'**
  String get tasksEntryNegative;

  /// No description provided for @tasksEntryOverlap.
  ///
  /// In en, this message translates to:
  /// **'Overlaps another session'**
  String get tasksEntryOverlap;

  /// No description provided for @tasksEntryRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get tasksEntryRunning;

  /// No description provided for @tasksErrAllDay.
  ///
  /// In en, this message translates to:
  /// **'All-day tasks span whole days'**
  String get tasksErrAllDay;

  /// No description provided for @tasksErrDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration must be between 0 minutes and 365 days'**
  String get tasksErrDuration;

  /// No description provided for @tasksErrEstimate.
  ///
  /// In en, this message translates to:
  /// **'The estimate is out of range'**
  String get tasksErrEstimate;

  /// No description provided for @tasksErrPriority.
  ///
  /// In en, this message translates to:
  /// **'Invalid priority'**
  String get tasksErrPriority;

  /// No description provided for @tasksErrRecurrenceInvalid.
  ///
  /// In en, this message translates to:
  /// **'The repeat rule is invalid'**
  String get tasksErrRecurrenceInvalid;

  /// No description provided for @tasksErrRecurrenceNoDate.
  ///
  /// In en, this message translates to:
  /// **'Repeating tasks need a date'**
  String get tasksErrRecurrenceNoDate;

  /// No description provided for @tasksErrTitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get tasksErrTitleEmpty;

  /// No description provided for @tasksErrTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'The title is too long (300 characters max)'**
  String get tasksErrTitleTooLong;

  /// No description provided for @tasksErrZone.
  ///
  /// In en, this message translates to:
  /// **'Unknown time zone'**
  String get tasksErrZone;

  /// No description provided for @tasksEvtCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tasksEvtCompleted;

  /// No description provided for @tasksEvtCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get tasksEvtCreated;

  /// No description provided for @tasksEvtDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get tasksEvtDeleted;

  /// No description provided for @tasksEvtDeletedOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Occurrence removed'**
  String get tasksEvtDeletedOccurrence;

  /// No description provided for @tasksEvtOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Occurrence of {date}'**
  String tasksEvtOccurrence(String date);

  /// No description provided for @tasksEvtPaused.
  ///
  /// In en, this message translates to:
  /// **'Series paused'**
  String get tasksEvtPaused;

  /// No description provided for @tasksEvtReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get tasksEvtReopened;

  /// No description provided for @tasksEvtRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled from {from} to {to}'**
  String tasksEvtRescheduled(String from, String to);

  /// No description provided for @tasksEvtRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get tasksEvtRestored;

  /// No description provided for @tasksEvtResumed.
  ///
  /// In en, this message translates to:
  /// **'Series resumed'**
  String get tasksEvtResumed;

  /// No description provided for @tasksEvtScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get tasksEvtScheduled;

  /// No description provided for @tasksEvtSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get tasksEvtSkipped;

  /// No description provided for @tasksEvtSkippedReason.
  ///
  /// In en, this message translates to:
  /// **'Skipped: {reason}'**
  String tasksEvtSkippedReason(String reason);

  /// No description provided for @tasksEvtSplit.
  ///
  /// In en, this message translates to:
  /// **'Series split'**
  String get tasksEvtSplit;

  /// No description provided for @tasksEvtStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get tasksEvtStarted;

  /// No description provided for @tasksEvtStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get tasksEvtStatusChanged;

  /// No description provided for @tasksEvtStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get tasksEvtStopped;

  /// No description provided for @tasksEvtTimeEntry.
  ///
  /// In en, this message translates to:
  /// **'Session added'**
  String get tasksEvtTimeEntry;

  /// No description provided for @tasksEvtUnscheduled.
  ///
  /// In en, this message translates to:
  /// **'Moved to the backlog'**
  String get tasksEvtUnscheduled;

  /// No description provided for @tasksEvtUpdated.
  ///
  /// In en, this message translates to:
  /// **'Edited: {fields}'**
  String tasksEvtUpdated(String fields);

  /// No description provided for @tasksFieldAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get tasksFieldAllDay;

  /// No description provided for @tasksFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get tasksFieldCategory;

  /// No description provided for @tasksFieldChecklist.
  ///
  /// In en, this message translates to:
  /// **'Linked checklist'**
  String get tasksFieldChecklist;

  /// No description provided for @tasksFieldColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get tasksFieldColor;

  /// No description provided for @tasksFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get tasksFieldDate;

  /// No description provided for @tasksFieldDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get tasksFieldDeadline;

  /// No description provided for @tasksFieldDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get tasksFieldDuration;

  /// No description provided for @tasksFieldEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get tasksFieldEnd;

  /// No description provided for @tasksFieldEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get tasksFieldEndDate;

  /// No description provided for @tasksFieldEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get tasksFieldEstimate;

  /// No description provided for @tasksFieldIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get tasksFieldIcon;

  /// No description provided for @tasksFieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get tasksFieldLocation;

  /// No description provided for @tasksFieldNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date (backlog)'**
  String get tasksFieldNoDate;

  /// No description provided for @tasksFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get tasksFieldNotes;

  /// No description provided for @tasksFieldPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get tasksFieldPriority;

  /// No description provided for @tasksFieldRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get tasksFieldRepeat;

  /// No description provided for @tasksFieldStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get tasksFieldStart;

  /// No description provided for @tasksFieldStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get tasksFieldStartDate;

  /// No description provided for @tasksFieldTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tasksFieldTags;

  /// No description provided for @tasksFieldTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get tasksFieldTimeZone;

  /// No description provided for @tasksFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get tasksFieldTitle;

  /// No description provided for @tasksFieldTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What do you want to do?'**
  String get tasksFieldTitleHint;

  /// No description provided for @tasksFieldTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tasksFieldTracking;

  /// No description provided for @tasksFieldUrl.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get tasksFieldUrl;

  /// No description provided for @tasksFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tasksFilterAll;

  /// No description provided for @tasksFilterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tasksFilterDone;

  /// No description provided for @tasksFilterMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get tasksFilterMissed;

  /// No description provided for @tasksFilterMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get tasksFilterMoved;

  /// No description provided for @tasksFilterSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get tasksFilterSkipped;

  /// No description provided for @tasksFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'From template…'**
  String get tasksFromTemplate;

  /// No description provided for @tasksHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tasksHistory;

  /// No description provided for @tasksHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get tasksHistoryEmpty;

  /// No description provided for @tasksHistoryLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get tasksHistoryLoadMore;

  /// No description provided for @tasksIconDefault.
  ///
  /// In en, this message translates to:
  /// **'Category icon'**
  String get tasksIconDefault;

  /// No description provided for @tasksMarkedDone.
  ///
  /// In en, this message translates to:
  /// **'Marked as done'**
  String get tasksMarkedDone;

  /// No description provided for @tasksMarkedSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get tasksMarkedSkipped;

  /// No description provided for @tasksMdBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get tasksMdBold;

  /// No description provided for @tasksMdBullet.
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get tasksMdBullet;

  /// No description provided for @tasksMdCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Checkbox'**
  String get tasksMdCheckbox;

  /// No description provided for @tasksMdCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get tasksMdCode;

  /// No description provided for @tasksMdHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get tasksMdHeading;

  /// No description provided for @tasksMdItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get tasksMdItalic;

  /// No description provided for @tasksMdNumbered.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get tasksMdNumbered;

  /// No description provided for @tasksMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get tasksMoved;

  /// No description provided for @tasksMovedFrom.
  ///
  /// In en, this message translates to:
  /// **'Moved from {time}'**
  String tasksMovedFrom(String time);

  /// No description provided for @tasksNextDay.
  ///
  /// In en, this message translates to:
  /// **'+1 day'**
  String get tasksNextDay;

  /// No description provided for @tasksNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next: {when}'**
  String tasksNextLabel(String when);

  /// No description provided for @tasksNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get tasksNextMonth;

  /// No description provided for @tasksNextOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Next occurrences'**
  String get tasksNextOccurrences;

  /// No description provided for @tasksNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Nothing upcoming'**
  String get tasksNoUpcoming;

  /// No description provided for @tasksNotesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get tasksNotesEdit;

  /// No description provided for @tasksNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes (bold, lists, checkboxes…)'**
  String get tasksNotesHint;

  /// No description provided for @tasksNotesPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get tasksNotesPreview;

  /// No description provided for @tasksNotifAlreadyClosed.
  ///
  /// In en, this message translates to:
  /// **'Already done or skipped'**
  String get tasksNotifAlreadyClosed;

  /// No description provided for @tasksNotifGone.
  ///
  /// In en, this message translates to:
  /// **'This task no longer exists'**
  String get tasksNotifGone;

  /// No description provided for @tasksOccurrenceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Occurrence removed'**
  String get tasksOccurrenceDeleted;

  /// No description provided for @tasksOpenLinkBody.
  ///
  /// In en, this message translates to:
  /// **'{url} will open outside Everslot.'**
  String tasksOpenLinkBody(String url);

  /// No description provided for @tasksOpenLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Open link?'**
  String get tasksOpenLinkTitle;

  /// No description provided for @tasksOrphansBody.
  ///
  /// In en, this message translates to:
  /// **'Occurrences with history are always kept as one-off tasks.'**
  String get tasksOrphansBody;

  /// No description provided for @tasksOrphansCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 completed occurrence} other{{count} completed occurrences}}'**
  String tasksOrphansCompleted(int count);

  /// No description provided for @tasksOrphansDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard moved ones'**
  String get tasksOrphansDiscard;

  /// No description provided for @tasksOrphansKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep as one-off tasks'**
  String get tasksOrphansKeep;

  /// No description provided for @tasksOrphansMoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 moved occurrence} other{{count} moved occurrences}}'**
  String tasksOrphansMoved(int count);

  /// No description provided for @tasksOrphansOther.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 occurrence with notes or tracked time} other{{count} occurrences with notes or tracked time}}'**
  String tasksOrphansOther(int count);

  /// No description provided for @tasksOrphansSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 skipped occurrence} other{{count} skipped occurrences}}'**
  String tasksOrphansSkipped(int count);

  /// No description provided for @tasksOrphansTitle.
  ///
  /// In en, this message translates to:
  /// **'Some occurrences no longer match'**
  String get tasksOrphansTitle;

  /// No description provided for @tasksOutcomeNote.
  ///
  /// In en, this message translates to:
  /// **'Outcome note'**
  String get tasksOutcomeNote;

  /// No description provided for @tasksOutcomeNoteHint.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get tasksOutcomeNoteHint;

  /// No description provided for @tasksOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get tasksOverdue;

  /// No description provided for @tasksOverlapHint.
  ///
  /// In en, this message translates to:
  /// **'Overlaps with {title} {range}'**
  String tasksOverlapHint(String title, String range);

  /// No description provided for @tasksOverlapMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{and 1 more} other{and {count} more}}'**
  String tasksOverlapMore(int count);

  /// No description provided for @tasksPauseSnack.
  ///
  /// In en, this message translates to:
  /// **'Series paused'**
  String get tasksPauseSnack;

  /// No description provided for @tasksPausedBadge.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get tasksPausedBadge;

  /// No description provided for @tasksPlannedVsActual.
  ///
  /// In en, this message translates to:
  /// **'Planned {planned} · actual {actual}'**
  String tasksPlannedVsActual(String planned, String actual);

  /// No description provided for @tasksPlusDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+1 day} other{+{count} days}}'**
  String tasksPlusDays(int count);

  /// No description provided for @tasksPostpone15.
  ///
  /// In en, this message translates to:
  /// **'+15 min'**
  String get tasksPostpone15;

  /// No description provided for @tasksPostpone1h.
  ///
  /// In en, this message translates to:
  /// **'+1 hour'**
  String get tasksPostpone1h;

  /// No description provided for @tasksPostponeEvening.
  ///
  /// In en, this message translates to:
  /// **'This evening'**
  String get tasksPostponeEvening;

  /// No description provided for @tasksPostponeNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week, same time'**
  String get tasksPostponeNextWeek;

  /// No description provided for @tasksPostponePick.
  ///
  /// In en, this message translates to:
  /// **'Pick a date and time…'**
  String get tasksPostponePick;

  /// No description provided for @tasksPostponeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get tasksPostponeTitle;

  /// No description provided for @tasksPostponeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, same time'**
  String get tasksPostponeTomorrow;

  /// No description provided for @tasksPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get tasksPrevMonth;

  /// No description provided for @tasksQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tasksQuickAdd;

  /// No description provided for @tasksQuickAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add & new'**
  String get tasksQuickAddNew;

  /// No description provided for @tasksQuickMore.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get tasksQuickMore;

  /// No description provided for @tasksQuickTitleHint.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get tasksQuickTitleHint;

  /// No description provided for @tasksQuotaDone.
  ///
  /// In en, this message translates to:
  /// **'Done for this period'**
  String get tasksQuotaDone;

  /// No description provided for @tasksQuotaIndicator.
  ///
  /// In en, this message translates to:
  /// **'{title} · {done}/{total} {unit, select, day{today} week{this week} month{this month} year{this year} other{this period}}'**
  String tasksQuotaIndicator(String title, int done, int total, String unit);

  /// No description provided for @tasksQuotaIndicatorDone.
  ///
  /// In en, this message translates to:
  /// **'{title} · {unit, select, day{done for today} week{done for this week} month{done for this month} year{done for this year} other{done for this period}}'**
  String tasksQuotaIndicatorDone(String title, String unit);

  /// No description provided for @tasksQuotaProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} this period'**
  String tasksQuotaProgress(int done, int total);

  /// No description provided for @tasksRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get tasksRating;

  /// No description provided for @tasksRatingValue.
  ///
  /// In en, this message translates to:
  /// **'{value} of 5'**
  String tasksRatingValue(int value);

  /// No description provided for @tasksReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get tasksReminders;

  /// No description provided for @tasksRemindersDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get tasksRemindersDefault;

  /// No description provided for @tasksReopened.
  ///
  /// In en, this message translates to:
  /// **'Reopened'**
  String get tasksReopened;

  /// No description provided for @tasksRepeatNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get tasksRepeatNone;

  /// No description provided for @tasksRestored.
  ///
  /// In en, this message translates to:
  /// **'Task restored'**
  String get tasksRestored;

  /// No description provided for @tasksResumeSnack.
  ///
  /// In en, this message translates to:
  /// **'Series resumed'**
  String get tasksResumeSnack;

  /// No description provided for @tasksRolledOver.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unfinished task moved to today} other{{count} unfinished tasks moved to today}}'**
  String tasksRolledOver(int count);

  /// No description provided for @tasksRunningTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer running: {title}, {elapsed}'**
  String tasksRunningTimer(String title, String elapsed);

  /// No description provided for @tasksSaveAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as template'**
  String get tasksSaveAsTemplate;

  /// No description provided for @tasksSaved.
  ///
  /// In en, this message translates to:
  /// **'Task saved'**
  String get tasksSaved;

  /// No description provided for @tasksScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All occurrences'**
  String get tasksScopeAll;

  /// No description provided for @tasksScopeDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recurring task'**
  String get tasksScopeDeleteTitle;

  /// No description provided for @tasksScopeFollowing.
  ///
  /// In en, this message translates to:
  /// **'This and following'**
  String get tasksScopeFollowing;

  /// No description provided for @tasksScopePastKept.
  ///
  /// In en, this message translates to:
  /// **'Past occurrences keep their original times.'**
  String get tasksScopePastKept;

  /// No description provided for @tasksScopeRewritePast.
  ///
  /// In en, this message translates to:
  /// **'Also rewrite past occurrences'**
  String get tasksScopeRewritePast;

  /// No description provided for @tasksScopeThis.
  ///
  /// In en, this message translates to:
  /// **'This occurrence'**
  String get tasksScopeThis;

  /// No description provided for @tasksScopeThisDisabled.
  ///
  /// In en, this message translates to:
  /// **'Only the time, duration, title and notes can change for a single occurrence.'**
  String get tasksScopeThisDisabled;

  /// No description provided for @tasksScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply changes to'**
  String get tasksScopeTitle;

  /// No description provided for @tasksSeriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No occurrences in this period'**
  String get tasksSeriesEmpty;

  /// No description provided for @tasksSeriesHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Series history'**
  String get tasksSeriesHistoryTitle;

  /// No description provided for @tasksSeriesStats.
  ///
  /// In en, this message translates to:
  /// **'Series statistics'**
  String get tasksSeriesStats;

  /// No description provided for @tasksShareRepeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats: {rule}'**
  String tasksShareRepeats(String rule);

  /// No description provided for @tasksSkipCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Another reason (optional)'**
  String get tasksSkipCustomHint;

  /// No description provided for @tasksSkipForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot'**
  String get tasksSkipForgot;

  /// No description provided for @tasksSkipNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'Not needed'**
  String get tasksSkipNotNeeded;

  /// No description provided for @tasksSkipOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get tasksSkipOther;

  /// No description provided for @tasksSkipSick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get tasksSkipSick;

  /// No description provided for @tasksSkipTitle.
  ///
  /// In en, this message translates to:
  /// **'Why skip it?'**
  String get tasksSkipTitle;

  /// No description provided for @tasksSkipTooBusy.
  ///
  /// In en, this message translates to:
  /// **'Too busy'**
  String get tasksSkipTooBusy;

  /// No description provided for @tasksStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tasksStatusCancelled;

  /// No description provided for @tasksStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tasksStatusDone;

  /// No description provided for @tasksStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get tasksStatusInProgress;

  /// No description provided for @tasksStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get tasksStatusMissed;

  /// No description provided for @tasksStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get tasksStatusScheduled;

  /// No description provided for @tasksStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get tasksStatusSkipped;

  /// No description provided for @tasksTemplateDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete template'**
  String get tasksTemplateDelete;

  /// No description provided for @tasksTemplateSaved.
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get tasksTemplateSaved;

  /// No description provided for @tasksTemplatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No templates yet. Save a task as a template from its menu.'**
  String get tasksTemplatesEmpty;

  /// No description provided for @tasksTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get tasksTemplatesTitle;

  /// No description provided for @tasksTimeEntries.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get tasksTimeEntries;

  /// No description provided for @tasksTimeTracking.
  ///
  /// In en, this message translates to:
  /// **'Time tracking'**
  String get tasksTimeTracking;

  /// No description provided for @tasksTooManyOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Too many occurrences to display — zoom in'**
  String get tasksTooManyOccurrences;

  /// No description provided for @tasksTracked.
  ///
  /// In en, this message translates to:
  /// **'Tracked: {duration}'**
  String tasksTracked(String duration);

  /// No description provided for @tasksTrackingCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get tasksTrackingCheck;

  /// No description provided for @tasksTrackingCheckHint.
  ///
  /// In en, this message translates to:
  /// **'Mark it done or skip it; it can be missed.'**
  String get tasksTrackingCheckHint;

  /// No description provided for @tasksTrackingEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get tasksTrackingEvent;

  /// No description provided for @tasksTrackingEventHint.
  ///
  /// In en, this message translates to:
  /// **'A time block (meeting, meal): no checkbox, never missed.'**
  String get tasksTrackingEventHint;

  /// No description provided for @tasksTrackingTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get tasksTrackingTimer;

  /// No description provided for @tasksTrackingTimerHint.
  ///
  /// In en, this message translates to:
  /// **'Track the time you spend; done when you stop the timer.'**
  String get tasksTrackingTimerHint;

  /// No description provided for @tasksUnsavedBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes will be lost.'**
  String get tasksUnsavedBody;

  /// No description provided for @tasksUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get tasksUnsavedTitle;

  /// No description provided for @tasksUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled task'**
  String get tasksUntitled;

  /// No description provided for @tasksUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get tasksUpdated;

  /// No description provided for @tasksUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid web address'**
  String get tasksUrlInvalid;

  /// No description provided for @tasksZoneBadge.
  ///
  /// In en, this message translates to:
  /// **'{zone} time'**
  String tasksZoneBadge(String zone);

  /// No description provided for @tasksZoneFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get tasksZoneFixed;

  /// No description provided for @tasksZoneFixedHint.
  ///
  /// In en, this message translates to:
  /// **'Anchored to one time zone'**
  String get tasksZoneFixedHint;

  /// No description provided for @tasksZoneFloating.
  ///
  /// In en, this message translates to:
  /// **'Floating'**
  String get tasksZoneFloating;

  /// No description provided for @tasksZoneFloatingHint.
  ///
  /// In en, this message translates to:
  /// **'Same clock time wherever you are'**
  String get tasksZoneFloatingHint;

  /// No description provided for @tasksZonePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a time zone'**
  String get tasksZonePickTitle;

  /// No description provided for @tasksZoneSearch.
  ///
  /// In en, this message translates to:
  /// **'Search time zones'**
  String get tasksZoneSearch;

  /// No description provided for @templatesBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get templatesBuiltin;

  /// No description provided for @templatesCreated.
  ///
  /// In en, this message translates to:
  /// **'List created from template'**
  String get templatesCreated;

  /// No description provided for @templatesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit template'**
  String get templatesEdit;

  /// No description provided for @templatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Save any list as a template from its menu.'**
  String get templatesEmpty;

  /// No description provided for @templatesMine.
  ///
  /// In en, this message translates to:
  /// **'My templates'**
  String get templatesMine;

  /// No description provided for @templatesRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get templatesRename;

  /// No description provided for @templatesUse.
  ///
  /// In en, this message translates to:
  /// **'Use template'**
  String get templatesUse;

  /// No description provided for @undoDoneSnack.
  ///
  /// In en, this message translates to:
  /// **'Undone: {action}'**
  String undoDoneSnack(String action);

  /// No description provided for @undoNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to undo'**
  String get undoNothing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
