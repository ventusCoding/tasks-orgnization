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

  /// No description provided for @localOnlyBanner.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync isn\'t configured — your data stays on this device.'**
  String get localOnlyBanner;

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

  /// No description provided for @savedSnack.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedSnack;

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
