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

  /// No description provided for @categoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoryEdit;

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

  /// No description provided for @checklistInsightsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Checklist insights arrive with the stats section.'**
  String get checklistInsightsPlaceholder;

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

  /// No description provided for @checklistLinkedTask.
  ///
  /// In en, this message translates to:
  /// **'Linked task'**
  String get checklistLinkedTask;

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

  /// No description provided for @checklistNotFound.
  ///
  /// In en, this message translates to:
  /// **'This list doesn\'t exist'**
  String get checklistNotFound;

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

  /// No description provided for @checklistSubItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sub-item} other{{count} sub-items}}'**
  String checklistSubItems(int count);

  /// No description provided for @checklistTaskPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Linking to planner tasks arrives with the planner.'**
  String get checklistTaskPlaceholder;

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

  /// No description provided for @galleryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items with images'**
  String get galleryEmpty;

  /// No description provided for @galleryOnlyImages.
  ///
  /// In en, this message translates to:
  /// **'Only items with images'**
  String get galleryOnlyImages;

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

  /// No description provided for @itemAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get itemAddReminder;

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

  /// No description provided for @itemReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get itemReminders;

  /// No description provided for @itemRemindersPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Reminders for this item will be set here.'**
  String get itemRemindersPlaceholder;

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

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatDaily;

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

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get repeatMonthly;

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

  /// No description provided for @repeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Every weekday'**
  String get repeatWeekdays;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get repeatWeekly;

  /// No description provided for @savedSnack.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedSnack;

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

  /// No description provided for @settingsCompleteChildren.
  ///
  /// In en, this message translates to:
  /// **'When completing a parent'**
  String get settingsCompleteChildren;

  /// No description provided for @settingsDefaultOpen.
  ///
  /// In en, this message translates to:
  /// **'Open in'**
  String get settingsDefaultOpen;

  /// No description provided for @settingsHideCheckboxes.
  ///
  /// In en, this message translates to:
  /// **'Hide checkboxes (bullets)'**
  String get settingsHideCheckboxes;

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
