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

  /// No description provided for @tasksBulkDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tasksBulkDelete;

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
