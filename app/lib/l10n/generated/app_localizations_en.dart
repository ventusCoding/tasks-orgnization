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
  String get activityArchived => 'Archived';

  @override
  String activityAttachmentAdded(String name) {
    return 'Attachment added: $name';
  }

  @override
  String activityAttachmentRemoved(String name) {
    return 'Attachment removed: $name';
  }

  @override
  String get activityCauseAutomatic => 'Automatic';

  @override
  String get activityCauseBulk => 'Bulk change';

  @override
  String get activityCauseImport => 'Imported';

  @override
  String activityChangedFields(String fields) {
    return 'Changed $fields';
  }

  @override
  String get activityCompleted => 'Completed';

  @override
  String get activityCreated => 'Created';

  @override
  String get activityCreatedCopy => 'Created as a copy';

  @override
  String get activityCreatedFromTemplate => 'Created from a template';

  @override
  String get activityDeleted => 'Deleted';

  @override
  String activityDeletedWithItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted with $count items',
      one: 'Deleted with 1 item',
    );
    return '$_temp0';
  }

  @override
  String activityDurationChanged(String from, String to) {
    return 'Duration changed from $from to $to';
  }

  @override
  String get activityEdited => 'Edited';

  @override
  String get activityEmpty => 'No history yet';

  @override
  String get activityFieldCategory => 'category';

  @override
  String get activityFieldColor => 'color';

  @override
  String get activityFieldDue => 'due date';

  @override
  String get activityFieldDuration => 'duration';

  @override
  String get activityFieldIcon => 'icon';

  @override
  String get activityFieldName => 'name';

  @override
  String get activityFieldNotes => 'notes';

  @override
  String get activityFieldPriority => 'priority';

  @override
  String get activityFieldRepeat => 'repeat';

  @override
  String get activityFieldTags => 'tags';

  @override
  String get activityFieldText => 'text';

  @override
  String get activityFieldTime => 'time';

  @override
  String get activityFieldTitle => 'title';

  @override
  String get activityFile => 'file';

  @override
  String activityItemsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count items added', one: '1 item added');
    return '$_temp0';
  }

  @override
  String get activityListSeparator => ', ';

  @override
  String get activityMerged => 'Merged';

  @override
  String get activityMoved => 'Moved';

  @override
  String get activityMovedToList => 'Moved to another list';

  @override
  String get activityOther => 'Changed';

  @override
  String get activityPaused => 'Paused';

  @override
  String activityQuoted(String text) {
    return '“$text”';
  }

  @override
  String get activityRelapse => 'Relapse logged';

  @override
  String get activityReopened => 'Reopened';

  @override
  String activityRescheduled(String from, String to) {
    return 'Moved from $from to $to';
  }

  @override
  String get activityReset => 'Reset';

  @override
  String get activityRestored => 'Restored';

  @override
  String get activityResumed => 'Resumed';

  @override
  String get activityRollover => 'Rolled over';

  @override
  String get activityScheduled => 'Scheduled';

  @override
  String get activityScopeFollowing => 'This and following occurrences';

  @override
  String get activityScopeSeries => 'All occurrences';

  @override
  String get activitySeriesSplit => 'Series split';

  @override
  String get activitySkipped => 'Skipped';

  @override
  String activitySkippedReason(String reason) {
    return 'Skipped: $reason';
  }

  @override
  String get activitySorted => 'Items sorted';

  @override
  String get activityStarted => 'Started';

  @override
  String activityStatusChanged(String from, String to) {
    return 'Status changed from $from to $to';
  }

  @override
  String get activityStatusNoteChanged => 'Reason updated';

  @override
  String activityStatusSet(String to) {
    return 'Status set to $to';
  }

  @override
  String get activityStopped => 'Stopped';

  @override
  String get activityTagsChanged => 'Tags updated';

  @override
  String get activityTimeLogged => 'Time logged';

  @override
  String get activityTitle => 'History';

  @override
  String get activityUnarchived => 'Unarchived';

  @override
  String get activityUnscheduled => 'Moved to the backlog';

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
  String get attachmentsClipboardNoImage => 'No image in the clipboard';

  @override
  String attachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count attachments', one: '1 attachment');
    return '$_temp0';
  }

  @override
  String get attachmentsDownloadWhenOnline => 'This file will download when you\'re online.';

  @override
  String attachmentsDuration(String duration) {
    return 'Length $duration';
  }

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
  String get attachmentsPause => 'Pause';

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
  String get attachmentsPlay => 'Play';

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
  String attachmentsRejectedTooLong(String name, int seconds) {
    return '$name is longer than $seconds seconds';
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
  String get attachmentsSourcePaste => 'Paste image';

  @override
  String get attachmentsSourcePhotos => 'Choose photos';

  @override
  String get attachmentsSourceRecordVideo => 'Record a video';

  @override
  String get attachmentsSourceScan => 'Scan a document';

  @override
  String get attachmentsSourceVideos => 'Choose a video';

  @override
  String get attachmentsSourceVoiceNote => 'Voice note';

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
  String get authAvatarChange => 'Change photo';

  @override
  String get authAvatarRemove => 'Remove photo';

  @override
  String get authBrowserFlowStarted => 'Finish signing in in your browser, then come back to Everslot.';

  @override
  String get authChangeEmail => 'Use a different email';

  @override
  String authCodeBody(String email) {
    return 'Enter the 6-digit code sent to $email, or tap the link in that email.';
  }

  @override
  String get authCodeLabel => '6-digit code';

  @override
  String get authCodeResent => 'A new code is on its way.';

  @override
  String get authCodeTitle => 'Check your inbox';

  @override
  String get authContinueApple => 'Continue with Apple';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authContinueGuest => 'Continue without an account';

  @override
  String get authCurrentZone => 'Current time zone';

  @override
  String get authDeleteAccount => 'Delete account';

  @override
  String get authDeleteBody =>
      'This permanently deletes your account and all your data — plans, lists, habits and attachments — on every device. It can\'t be undone.';

  @override
  String get authDeleteConfirm => 'Delete forever';

  @override
  String get authDeleteExportFirst => 'Export my data first';

  @override
  String authDeleteReauthBody(String email) {
    return 'To confirm it\'s you, enter the code we sent to $email.';
  }

  @override
  String get authDeleteTitle => 'Delete your account?';

  @override
  String get authDeleteUnderstand => 'I understand this can\'t be undone';

  @override
  String authDeleteWeb(String url) {
    return 'You can also request deletion on the web: $url';
  }

  @override
  String get authDeleted => 'Your account has been deleted.';

  @override
  String get authDeleting => 'Deleting your account…';

  @override
  String get authDeviceRevokedBody =>
      'This device was removed from your account on another device. Export your data first if you want a copy, then sign out.';

  @override
  String get authDeviceRevokedTitle => 'This device was removed';

  @override
  String get authDisplayName => 'Display name';

  @override
  String get authDisplayNameHint => 'What should we call you?';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authErrorCaptcha => 'The security check failed. Please try again.';

  @override
  String get authErrorEmailInUse => 'This email already belongs to another account.';

  @override
  String get authErrorGuestDisabled => 'Guest mode is turned off on this server.';

  @override
  String get authErrorIdentityInUse => 'This sign-in method is already linked to another account.';

  @override
  String get authErrorInvalidCode => 'This code is invalid or has expired.';

  @override
  String get authErrorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get authErrorLastIdentity => 'You can\'t remove your only sign-in method.';

  @override
  String get authErrorMfaRequired => 'Enter the code from your authenticator app to continue.';

  @override
  String get authErrorNotConfigured => 'Cloud sync isn\'t configured on this build (see guide.md).';

  @override
  String get authErrorOffline => 'You\'re offline. Check your connection and try again.';

  @override
  String get authErrorProviderNotConfigured => 'This sign-in method isn\'t set up yet (see guide.md).';

  @override
  String get authErrorRateLimited => 'Too many attempts. Please wait a moment and try again.';

  @override
  String get authErrorSessionExpired => 'Your session has expired. Please sign in again.';

  @override
  String get authErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String get authExportFirst => 'Export data';

  @override
  String get authGuestAccount => 'Guest account';

  @override
  String get authGuestBanner =>
      'You\'re using a guest account. Add an email so your data survives if you delete the app.';

  @override
  String get authGuestBannerAction => 'Secure my data';

  @override
  String get authGuestHint => 'Try Everslot right away and add an email later to keep your data.';

  @override
  String get authHomeZone => 'Home time zone';

  @override
  String get authLegalNote => 'By continuing you accept the Terms of Service and the Privacy Policy.';

  @override
  String get authLink => 'Link';

  @override
  String authLinked(String provider) {
    return '$provider linked';
  }

  @override
  String get authLinkedAccounts => 'Sign-in methods';

  @override
  String get authLocalOnlyAccount => 'Data stays on this device';

  @override
  String get authLocalOnlyAccountBody =>
      'You\'re not signed in. Sign in to sync across devices — your data comes along.';

  @override
  String get authMfaBody => 'Ask for a code from an authenticator app when you sign in or delete your account.';

  @override
  String get authMfaCopySecret => 'Copy key';

  @override
  String get authMfaDisable => 'Turn off';

  @override
  String get authMfaDisableBody => 'Enter a code from your authenticator app to turn off two-step verification.';

  @override
  String get authMfaDisabled => 'Two-step verification is off.';

  @override
  String get authMfaEnabled => 'Two-step verification is on.';

  @override
  String get authMfaEnroll => 'Set up';

  @override
  String get authMfaEnrollBody => 'Add this key to your authenticator app, then enter the 6-digit code it shows.';

  @override
  String get authMfaOpenApp => 'Open in authenticator app';

  @override
  String get authMfaSecret => 'Setup key';

  @override
  String get authMfaSecretCopied => 'Setup key copied.';

  @override
  String get authMfaTitle => 'Two-step verification';

  @override
  String get authMfaVerifyBody => 'Open your authenticator app and enter the 6-digit code for Everslot.';

  @override
  String get authMfaVerifyTitle => 'Enter your authenticator code';

  @override
  String get authNotConfiguredBody =>
      'This build isn\'t connected to a Supabase project yet (see guide.md). Everslot works fully on this device in the meantime.';

  @override
  String get authNotConfiguredTitle => 'Cloud sync isn\'t configured';

  @override
  String get authOr => 'or';

  @override
  String get authProfileTitle => 'Account';

  @override
  String get authProviderApple => 'Apple';

  @override
  String get authProviderEmail => 'Email';

  @override
  String get authProviderGoogle => 'Google';

  @override
  String get authReauthBody =>
      'Your session has expired. Sign in again to resume syncing — everything you did offline is kept.';

  @override
  String get authReauthTitle => 'Sign in again';

  @override
  String get authRegionalSettings => 'Regional settings';

  @override
  String get authResend => 'Resend code';

  @override
  String authResendIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Resend code in $seconds seconds',
      one: 'Resend code in 1 second',
    );
    return '$_temp0';
  }

  @override
  String get authSendCode => 'Send code';

  @override
  String get authSessionExpiredBanner =>
      'Your session expired. Your changes are saved on this device and will sync once you sign in again.';

  @override
  String get authSignInAgain => 'Sign in again';

  @override
  String get authSignInToSync => 'Sign in to sync';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authSignOutAnyway => 'Sign out anyway';

  @override
  String get authSignOutBody => 'Your data will be removed from this device. It stays safe in your account.';

  @override
  String get authSignOutGuestBody =>
      'This guest account only exists on this device. Signing out deletes it and all its data for good — add an email first to keep it.';

  @override
  String authSignOutPendingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes haven\'t synced yet and will be lost.',
      one: '1 change hasn\'t synced yet and will be lost.',
    );
    return '$_temp0 Export your data first, or sign out anyway.';
  }

  @override
  String get authSignOutSyncing => 'Syncing your last changes…';

  @override
  String get authSignOutTitle => 'Sign out?';

  @override
  String authSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get authSignedOut => 'Signed out';

  @override
  String get authUnlink => 'Unlink';

  @override
  String authUnlinkConfirm(String provider) {
    return 'Unlink $provider?';
  }

  @override
  String get authUpdateRequired => 'Update Everslot to keep syncing. Your changes are kept on this device.';

  @override
  String get authUpgradeBody => 'Add a sign-in method to your guest account. Your data stays exactly as it is.';

  @override
  String get authUpgradeDone => 'Your account is secured.';

  @override
  String get authUpgradeEmail => 'Add an email';

  @override
  String authUpgradeEmailInUseBody(String email) {
    return '$email already has an Everslot account. Use another email — or export your guest data, sign out, sign in to that account and import the file.';
  }

  @override
  String get authUpgradeEmailInUseTitle => 'Email already in use';

  @override
  String get authUpgradeTitle => 'Keep your data';

  @override
  String get authUseLocalOnly => 'Use on this device only';

  @override
  String get authUseLocalOnlyHint => 'No account and no sync. Sign in later and your data comes along.';

  @override
  String get authVerify => 'Verify';

  @override
  String get authWelcomeBody => 'Sign in to keep your plans, lists and habits in sync on all your devices.';

  @override
  String get authWelcomeTitle => 'Welcome to Everslot';

  @override
  String authZoneChangedBody(String zone) {
    return 'You\'re now in $zone. Fixed-time tasks keep their exact time and floating tasks follow you. Make $zone your home time zone?';
  }

  @override
  String get authZoneChangedTitle => 'New time zone';

  @override
  String get authZoneDetected => 'Detected on this device';

  @override
  String authZoneKeepHome(String zone) {
    return 'Keep $zone';
  }

  @override
  String get authZoneMakeHome => 'Make it home';

  @override
  String get authZoneNoMatch => 'No time zone matches your search';

  @override
  String get authZoneSearch => 'Search time zones';

  @override
  String get bootstrapErrorBody =>
      'Something went wrong while opening the app. Your data is safe on this device. Try again, and restart your phone if it keeps happening.';

  @override
  String get bootstrapErrorCopy => 'Copy details';

  @override
  String get bootstrapErrorDetails => 'Details (for developers)';

  @override
  String get bootstrapErrorTitle => 'Everslot couldn\'t start';

  @override
  String get categoriesEmpty => 'No categories yet';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoryArchived => 'Archived';

  @override
  String get categoryClearAction => 'Remove the category from them';

  @override
  String categoryCreateNamed(String name) {
    return 'Create category “$name”';
  }

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
  String get categoryDeleteBody => 'Items in this category will keep existing without a category.';

  @override
  String categoryDeleteUsedBody(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items use “$name”.',
      one: '1 item uses “$name”.',
    );
    return '$_temp0 What should happen to them?';
  }

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryErrorDuplicate => 'A category with this name already exists.';

  @override
  String get categoryErrorInvalid => 'Use 1 to 60 characters.';

  @override
  String get categoryName => 'Name';

  @override
  String get categoryNew => 'New category';

  @override
  String get categoryNone => 'No category';

  @override
  String get categoryPick => 'Category';

  @override
  String get categoryReassignAction => 'Move them to another category';

  @override
  String get categoryReassignTitle => 'Move items to';

  @override
  String get categoryReorderHint => 'Drag to reorder';

  @override
  String get categorySearch => 'Search or create a category';

  @override
  String get categoryUnavailable => 'Counts as unavailable time';

  @override
  String get categoryUnavailableHint => 'Excluded from capacity stats (e.g. sleep, time off).';

  @override
  String categoryUsage(int count) {
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
  String chartsAnonymousItem(String n) {
    return 'Item $n';
  }

  @override
  String chartsBytesGb(String value) {
    return '$value GB';
  }

  @override
  String chartsBytesKb(String value) {
    return '$value KB';
  }

  @override
  String chartsBytesMb(String value) {
    return '$value MB';
  }

  @override
  String get chartsColumnLabel => 'Label';

  @override
  String chartsCounterSemantics(String days, String hours, String minutes) {
    return '$days days, $hours hours, $minutes minutes';
  }

  @override
  String chartsCrosshair(String label, String value) {
    return '$label: $value';
  }

  @override
  String chartsDaysHours(String days, String hours) {
    return '$days d $hours h';
  }

  @override
  String chartsDaysOnly(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String chartsDeltaDown(String value) {
    return 'down $value';
  }

  @override
  String get chartsDeltaFlat => 'no change';

  @override
  String get chartsDeltaNew => 'new';

  @override
  String chartsDeltaUp(String value) {
    return 'up $value';
  }

  @override
  String get chartsEmpty => 'No data for this period';

  @override
  String get chartsError => 'This chart couldn’t be computed';

  @override
  String chartsEstimate(String value) {
    return '≈ $value';
  }

  @override
  String get chartsExplain => 'About this metric';

  @override
  String get chartsExportBom => 'Excel-compatible (UTF-8 BOM)';

  @override
  String get chartsExportCsv => 'Export CSV';

  @override
  String get chartsExportFailed => 'Couldn’t export';

  @override
  String get chartsExportJson => 'Export JSON';

  @override
  String get chartsExportLocale => 'Local number and date format';

  @override
  String chartsFrozen(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count frozen', one: '1 frozen');
    return '$_temp0';
  }

  @override
  String get chartsGalleryDark => 'Dark theme';

  @override
  String get chartsGalleryEmptyState => 'Empty state';

  @override
  String get chartsGalleryRtl => 'Right to left';

  @override
  String get chartsGalleryTextScale => 'Large text';

  @override
  String get chartsGalleryTitle => 'Chart gallery';

  @override
  String get chartsGalleryVision => 'Color vision';

  @override
  String get chartsHistogramCount => 'Count';

  @override
  String get chartsHistogramDensity => 'Share';

  @override
  String chartsHour(String hour) {
    return '$hour h';
  }

  @override
  String chartsHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String chartsHoursOnly(String hours) {
    return '$hours h';
  }

  @override
  String chartsKilo(String value) {
    return '$value k';
  }

  @override
  String chartsKpiSemantics(String title, String value, String delta) {
    return '$title: $value. $delta';
  }

  @override
  String get chartsLabelAbstinent => 'Abstinent';

  @override
  String get chartsLabelAchieved => 'Achieved';

  @override
  String get chartsLabelActive => 'Active';

  @override
  String get chartsLabelActual => 'Actual';

  @override
  String get chartsLabelAfterHours => 'After hours';

  @override
  String get chartsLabelAgenda => 'Agenda';

  @override
  String get chartsLabelArchetype => 'Your style';

  @override
  String get chartsLabelArchived => 'Archived';

  @override
  String get chartsLabelArrivals => 'Arrivals';

  @override
  String get chartsLabelArrivalsPerDeparture => 'Arrivals ÷ departures';

  @override
  String get chartsLabelAtRisk => 'At risk';

  @override
  String get chartsLabelAttempt => 'Attempt';

  @override
  String get chartsLabelAttention => 'Needs attention';

  @override
  String get chartsLabelBackfillShare => 'Logged late';

  @override
  String get chartsLabelBaseline => 'Baseline';

  @override
  String get chartsLabelBehind => 'Behind';

  @override
  String get chartsLabelBest => 'Best';

  @override
  String get chartsLabelBestDay => 'Best day';

  @override
  String get chartsLabelBestMonth => 'Best month';

  @override
  String get chartsLabelBestWeek => 'Best week';

  @override
  String get chartsLabelBias => 'Bias';

  @override
  String get chartsLabelBlocked => 'Blocked';

  @override
  String get chartsLabelBranching => 'Children per parent';

  @override
  String get chartsLabelBusiest => 'Busiest times';

  @override
  String get chartsLabelCancelled => 'Cancelled';

  @override
  String get chartsLabelCapacity => 'Capacity';

  @override
  String get chartsLabelCheckIns => 'Check-ins';

  @override
  String get chartsLabelComebacks => 'Comebacks';

  @override
  String get chartsLabelCompleted => 'Completed';

  @override
  String get chartsLabelConsistency => 'Consistency';

  @override
  String get chartsLabelConsistent => 'Consistent';

  @override
  String get chartsLabelContextSwitches => 'Switches';

  @override
  String get chartsLabelCount => 'Count';

  @override
  String get chartsLabelCravings => 'Cravings';

  @override
  String get chartsLabelCreated => 'Created';

  @override
  String get chartsLabelCurrent => 'Current';

  @override
  String get chartsLabelCycleTime => 'Cycle time';

  @override
  String get chartsLabelDaysBetween => 'Days between uses';

  @override
  String get chartsLabelDeepWork => 'Deep work';

  @override
  String get chartsLabelDepartures => 'Departures';

  @override
  String get chartsLabelDone => 'Done';

  @override
  String get chartsLabelDoneLate => 'Late';

  @override
  String get chartsLabelDoneOnTime => 'On time';

  @override
  String get chartsLabelEarly => 'Early';

  @override
  String get chartsLabelEarlyBird => 'Early Bird';

  @override
  String get chartsLabelEvent => 'Events';

  @override
  String get chartsLabelExcused => 'Excused';

  @override
  String get chartsLabelFailed => 'Not done';

  @override
  String get chartsLabelFalling => 'Falling';

  @override
  String get chartsLabelFiles => 'Files';

  @override
  String get chartsLabelFinisher => 'Finisher';

  @override
  String get chartsLabelFocus => 'Focus';

  @override
  String get chartsLabelFollowUpOverdue => 'Follow-up overdue';

  @override
  String get chartsLabelFragmentation => 'Fragmentation';

  @override
  String get chartsLabelFree => 'Free';

  @override
  String get chartsLabelFrozen => 'Frozen';

  @override
  String get chartsLabelFulfilment => 'Fulfilment';

  @override
  String get chartsLabelFuture => 'Upcoming';

  @override
  String get chartsLabelGoal => 'Goal';

  @override
  String get chartsLabelHabits => 'Habits';

  @override
  String get chartsLabelHighPriority => 'High priority';

  @override
  String get chartsLabelIdeal => 'Ideal';

  @override
  String get chartsLabelImages => 'Images';

  @override
  String get chartsLabelInProgress => 'Active';

  @override
  String get chartsLabelIntegrityMissingReason => 'Reason missing';

  @override
  String get chartsLabelIntegrityOpenChildren => 'Done, but has open sub-items';

  @override
  String get chartsLabelIntegrityParentOpen => 'All sub-items done, still open';

  @override
  String get chartsLabelIntensity => 'Intensity';

  @override
  String get chartsLabelItems => 'Items';

  @override
  String get chartsLabelLapse => 'Slip';

  @override
  String get chartsLabelLargestBranch => 'Largest branch';

  @override
  String get chartsLabelLate => 'Late';

  @override
  String get chartsLabelLeafDepth => 'Mean leaf depth';

  @override
  String get chartsLabelLeaves => 'Leaves';

  @override
  String get chartsLabelLevel => 'Level';

  @override
  String get chartsLabelLifeRegained => 'Life regained';

  @override
  String get chartsLabelLimit => 'Limit';

  @override
  String get chartsLabelLists => 'Lists';

  @override
  String get chartsLabelLittleRatio => 'Little’s ratio';

  @override
  String get chartsLabelLoggedRatio => 'Logged';

  @override
  String get chartsLabelLongestBlock => 'Longest block';

  @override
  String get chartsLabelLongestGap => 'Longest gap';

  @override
  String get chartsLabelLongestStreaks => 'Longest streaks';

  @override
  String get chartsLabelLoops => 'Ongoing ↔ waiting loops';

  @override
  String get chartsLabelLowPriority => 'Low priority';

  @override
  String get chartsLabelMape => 'Error';

  @override
  String get chartsLabelMarathoner => 'Marathoner';

  @override
  String get chartsLabelMaxDepth => 'Max depth';

  @override
  String get chartsLabelMaxIntensity => 'Peak intensity';

  @override
  String get chartsLabelMean => 'Mean';

  @override
  String get chartsLabelMeanGap => 'Mean gap';

  @override
  String get chartsLabelMeanIntensity => 'Average intensity';

  @override
  String get chartsLabelMeanUse => 'Average use';

  @override
  String get chartsLabelMedian => 'Median';

  @override
  String get chartsLabelMilestones => 'Milestones';

  @override
  String get chartsLabelMissed => 'Missed';

  @override
  String get chartsLabelMoney => 'Money';

  @override
  String get chartsLabelMonth => 'Month';

  @override
  String get chartsLabelMood => 'Mood';

  @override
  String get chartsLabelMoods => 'Moods';

  @override
  String get chartsLabelMostActive => 'Most active';

  @override
  String get chartsLabelMostBlocked => 'Most blocked';

  @override
  String get chartsLabelMoved => 'Moved';

  @override
  String get chartsLabelMovedIn => 'Moved in';

  @override
  String get chartsLabelMovedOut => 'Moved out';

  @override
  String get chartsLabelMovedShare => 'Moved';

  @override
  String get chartsLabelNet => 'Net flow';

  @override
  String get chartsLabelNextUp => 'Next up';

  @override
  String get chartsLabelNightOwl => 'Night Owl';

  @override
  String get chartsLabelNo => 'No';

  @override
  String get chartsLabelNotDue => 'Not due';

  @override
  String get chartsLabelNotTracked => 'Not tracked';

  @override
  String get chartsLabelOnTime => 'On time';

  @override
  String get chartsLabelOnTrack => 'On track';

  @override
  String get chartsLabelOneOff => 'One-off';

  @override
  String get chartsLabelOngoing => 'Ongoing';

  @override
  String get chartsLabelOther => 'Other';

  @override
  String get chartsLabelOver => 'Over';

  @override
  String get chartsLabelOverLimit => 'Over limit';

  @override
  String get chartsLabelOverdue => 'Overdue';

  @override
  String get chartsLabelOverdue1 => '1–6 days';

  @override
  String get chartsLabelOverdue14 => '14–29 days';

  @override
  String get chartsLabelOverdue30 => '30+ days';

  @override
  String get chartsLabelOverdue7 => '7–13 days';

  @override
  String get chartsLabelOverdueToday => '< 1 day';

  @override
  String get chartsLabelOverlap => 'Overlap';

  @override
  String get chartsLabelP50 => 'P50';

  @override
  String get chartsLabelP70 => 'P70';

  @override
  String get chartsLabelP85 => 'P85';

  @override
  String get chartsLabelP95 => 'P95';

  @override
  String get chartsLabelPace => 'Pace';

  @override
  String get chartsLabelPartial => 'Partial';

  @override
  String get chartsLabelPaused => 'Paused';

  @override
  String get chartsLabelPauses => 'Pauses';

  @override
  String get chartsLabelPdfs => 'PDFs';

  @override
  String get chartsLabelPending => 'Pending';

  @override
  String get chartsLabelPendingSync => 'Waiting to sync';

  @override
  String get chartsLabelPerActiveDay => 'Per active day';

  @override
  String get chartsLabelPerDay => 'Per day';

  @override
  String get chartsLabelPerScheduledDay => 'Per scheduled day';

  @override
  String get chartsLabelPerfectDay => 'Perfect day';

  @override
  String get chartsLabelPlaces => 'Places';

  @override
  String get chartsLabelPlanned => 'Planned';

  @override
  String get chartsLabelPostponed => 'Postponed';

  @override
  String get chartsLabelPrevious => 'Previous';

  @override
  String get chartsLabelProjection => 'Projection';

  @override
  String get chartsLabelProjection1m => 'Next month';

  @override
  String get chartsLabelProjection1y => 'Next year';

  @override
  String get chartsLabelProjection5y => 'In 5 years';

  @override
  String get chartsLabelQuit => 'Quit';

  @override
  String get chartsLabelQuitJourney => 'Your quit journey';

  @override
  String get chartsLabelRate => 'Rate';

  @override
  String get chartsLabelRating => 'Rating';

  @override
  String get chartsLabelRecordAbstinence => 'Longest abstinence';

  @override
  String get chartsLabelRecordActualWeek => 'Most hours worked in a week';

  @override
  String get chartsLabelRecordCompletionWeek => 'Best weekly completion vs plan';

  @override
  String get chartsLabelRecordDeepWorkWeek => 'Most deep-work hours in a week';

  @override
  String get chartsLabelRecordHabitMaxDay => 'Best day';

  @override
  String get chartsLabelRecordHabitStreak => 'Longest habit streak';

  @override
  String get chartsLabelRecordHabitVolumeWeek => 'Best volume week';

  @override
  String get chartsLabelRecordItemsWeek => 'Most items completed in a week';

  @override
  String get chartsLabelRecordMoneyMonth => 'Most money saved in a month';

  @override
  String get chartsLabelRecordPerfectStreak => 'Longest perfect-day streak';

  @override
  String get chartsLabelRecordTasksDay => 'Most tasks done in a day';

  @override
  String get chartsLabelRecordsBroken => 'Records broken';

  @override
  String get chartsLabelRecurring => 'Recurring';

  @override
  String get chartsLabelReduction => 'Reduction';

  @override
  String get chartsLabelRelapse => 'Relapse';

  @override
  String get chartsLabelRemaining => 'Remaining';

  @override
  String get chartsLabelRemoved => 'Removed';

  @override
  String get chartsLabelReopened => 'Reopened';

  @override
  String get chartsLabelRising => 'Rising';

  @override
  String get chartsLabelRiskDueToday => 'Due today, streak on the line';

  @override
  String get chartsLabelRiskQuota => 'Behind on its quota';

  @override
  String get chartsLabelRiskScoreDrop => 'Strength dropping';

  @override
  String get chartsLabelRollingMean => 'Rolling mean';

  @override
  String get chartsLabelRuleChanged => 'Rule changed';

  @override
  String get chartsLabelSaved => 'Saved';

  @override
  String get chartsLabelScope => 'Scope';

  @override
  String get chartsLabelScore => 'Score';

  @override
  String get chartsLabelSessions => 'Sessions';

  @override
  String get chartsLabelShortcut => 'Done without start';

  @override
  String get chartsLabelSkipped => 'Skipped';

  @override
  String get chartsLabelSnowballing => 'Snowballing — moved 3+ times';

  @override
  String get chartsLabelSpent => 'Spent';

  @override
  String get chartsLabelStable => 'Stable';

  @override
  String get chartsLabelStale => 'Stale';

  @override
  String get chartsLabelStalest => 'Stalest';

  @override
  String get chartsLabelStatusChanges => 'Status changes';

  @override
  String get chartsLabelStreak => 'Streak';

  @override
  String get chartsLabelSuccess => 'Success';

  @override
  String get chartsLabelSummary => 'Summary';

  @override
  String get chartsLabelTarget => 'Target';

  @override
  String get chartsLabelTask => 'Tasks';

  @override
  String get chartsLabelTasks => 'Tasks';

  @override
  String get chartsLabelTemplates => 'Templates';

  @override
  String get chartsLabelTimeNotSpent => 'Time not spent';

  @override
  String get chartsLabelToday => 'Today';

  @override
  String get chartsLabelTodo => 'To do';

  @override
  String get chartsLabelTopCategories => 'Top categories';

  @override
  String get chartsLabelTotal => 'Total';

  @override
  String get chartsLabelTrackedTime => 'Tracked time';

  @override
  String get chartsLabelTrend => 'Trend';

  @override
  String get chartsLabelTriggers => 'Triggers';

  @override
  String get chartsLabelTypicalVaries => 'You are here — typical, individual experience varies';

  @override
  String get chartsLabelUncategorized => 'Uncategorized';

  @override
  String get chartsLabelUnder => 'Under';

  @override
  String get chartsLabelUnits => 'Units';

  @override
  String get chartsLabelUnknownUnits => 'Unlogged';

  @override
  String get chartsLabelUnplanned => 'Unplanned';

  @override
  String get chartsLabelUnspecified => 'Unspecified';

  @override
  String get chartsLabelUsed => 'Used';

  @override
  String get chartsLabelVolume => 'Volume';

  @override
  String get chartsLabelWaiting => 'Waiting';

  @override
  String get chartsLabelWeek => 'Week';

  @override
  String get chartsLabelWeekdayLabel => 'Weekday';

  @override
  String get chartsLabelWeekend => 'Weekend';

  @override
  String get chartsLabelWhenLabel => 'When';

  @override
  String get chartsLabelWidestLevel => 'Widest level';

  @override
  String get chartsLabelWins => 'Wins';

  @override
  String get chartsLabelWip => 'In progress';

  @override
  String get chartsLabelWithdrawalBeyond => 'After week 4: mostly behind you';

  @override
  String get chartsLabelWithdrawalEasing => 'Weeks 2–4: easing';

  @override
  String get chartsLabelWithdrawalFirstWeek => 'Rest of week 1: hardest';

  @override
  String get chartsLabelWithdrawalPeak => 'Days 1–3: strongest';

  @override
  String get chartsLabelWithinLimit => 'Within limit';

  @override
  String get chartsLabelWithinLimitDays => 'Days within limit';

  @override
  String get chartsLabelXp => 'XP';

  @override
  String get chartsLabelYear => 'Year';

  @override
  String get chartsLabelYearInNumbers => 'Your year in numbers';

  @override
  String get chartsLabelYearOverYear => 'Year over year';

  @override
  String get chartsLabelYes => 'Yes';

  @override
  String get chartsLegend => 'Legend';

  @override
  String get chartsLoading => 'Loading…';

  @override
  String chartsMedianAt(String value) {
    return 'Median $value';
  }

  @override
  String get chartsMedianNotReached => 'Median not reached';

  @override
  String chartsMega(String value) {
    return '$value M';
  }

  @override
  String chartsMilestoneEta(String time) {
    return 'in $time';
  }

  @override
  String get chartsMilestoneInWindow => 'In progress';

  @override
  String get chartsMilestoneNext => 'Next';

  @override
  String get chartsMilestoneReached => 'Reached';

  @override
  String get chartsMilestoneRestarted => 'The clock restarted after a slip — every day you already did still counts.';

  @override
  String chartsMilestoneSources(String sources) {
    return 'Sources: $sources';
  }

  @override
  String chartsMinutesOnly(String minutes) {
    return '$minutes min';
  }

  @override
  String chartsNeedsMore(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Needs $count more data points',
      one: 'Needs 1 more data point',
    );
    return '$_temp0';
  }

  @override
  String get chartsNoConsistentTime => 'No consistent time';

  @override
  String get chartsNotApplicable => '—';

  @override
  String chartsOrdinalAttempt(String n) {
    return 'Attempt $n';
  }

  @override
  String chartsOrdinalDepth(String n) {
    return 'Depth $n';
  }

  @override
  String chartsOrdinalLevel(String n) {
    return 'Level $n';
  }

  @override
  String chartsOrdinalMonth(String n) {
    return 'Month $n';
  }

  @override
  String chartsOrdinalPriority(String n) {
    return 'Priority $n';
  }

  @override
  String chartsOrdinalRun(String n) {
    return 'Run $n';
  }

  @override
  String chartsOrdinalWeek(String n) {
    return 'Week $n';
  }

  @override
  String chartsOrdinalYear(String n) {
    return 'Year $n';
  }

  @override
  String chartsOver(String value) {
    return '+$value';
  }

  @override
  String chartsPerDay(String value) {
    return '$value/day';
  }

  @override
  String chartsPerWeek(String value) {
    return '$value/week';
  }

  @override
  String chartsPlusMinus(String value) {
    return '± $value';
  }

  @override
  String get chartsPopulationEstimate => 'Population estimate';

  @override
  String chartsPp(String value) {
    return '$value pp';
  }

  @override
  String chartsPpSpoken(String value) {
    return '$value percentage points';
  }

  @override
  String chartsPrevious(String value) {
    return 'Previous $value';
  }

  @override
  String chartsProbability(String value) {
    return '$value chance';
  }

  @override
  String chartsRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String chartsRangeBrush(String from, String to) {
    return 'Visible range $from–$to. Drag to move, drag an edge to resize.';
  }

  @override
  String chartsRatio(String value) {
    return '$value×';
  }

  @override
  String chartsScopeAdded(String date, String count, String items) {
    return '$date: +$count — $items';
  }

  @override
  String chartsSecondsOnly(String seconds) {
    return '$seconds s';
  }

  @override
  String get chartsSelected => 'Selected';

  @override
  String chartsSeriesToggle(String series) {
    return 'Show or hide $series';
  }

  @override
  String get chartsShare => 'Share chart';

  @override
  String get chartsShareAction => 'Share';

  @override
  String get chartsShareFailed => 'The chart image couldn’t be created';

  @override
  String get chartsShareHideNames => 'Hide names';

  @override
  String get chartsShareMark => 'Made with Everslot';

  @override
  String get chartsStreakBest => 'Best';

  @override
  String get chartsStreakCurrent => 'Current';

  @override
  String chartsSummaryBars(String title, String count, String label, String value) {
    return '$title: $count bars, highest $label with $value.';
  }

  @override
  String chartsSummaryCalendar(String title, String count) {
    return '$title: $count days shown.';
  }

  @override
  String chartsSummaryLine(String title, String range, String first, String last, String trend) {
    return '$title, $range: from $first to $last. $trend';
  }

  @override
  String chartsSummaryList(String title, String count) {
    return '$title: $count entries.';
  }

  @override
  String chartsSummaryMilestones(String title, String done, String total) {
    return '$title: $done of $total reached.';
  }

  @override
  String chartsSummaryMinMax(String min, String max) {
    return 'Lowest $min, highest $max.';
  }

  @override
  String chartsSummaryPunchCard(String title, String weekday, String hour) {
    return '$title: busiest $weekday at $hour.';
  }

  @override
  String chartsSummaryShare(String title, String label, String share) {
    return '$title: largest part $label, $share.';
  }

  @override
  String chartsSummaryStreaks(String title, String length) {
    return '$title: longest streak $length.';
  }

  @override
  String chartsSummaryValue(String title, String value) {
    return '$title: $value.';
  }

  @override
  String chartsTableSort(String column) {
    return 'Sort by $column';
  }

  @override
  String get chartsTapForDetails => 'Double tap for details';

  @override
  String chartsTarget(String value) {
    return 'Target $value';
  }

  @override
  String chartsTooltip(String label, String value) {
    return '$label: $value';
  }

  @override
  String chartsTrendFalling(String slope) {
    return 'Falling $slope per week.';
  }

  @override
  String chartsTrendRising(String slope) {
    return 'Rising $slope per week.';
  }

  @override
  String get chartsTrendStable => 'No clear trend.';

  @override
  String get chartsViewAsChart => 'View as chart';

  @override
  String get chartsViewAsTable => 'View as table';

  @override
  String get chartsVisionDeuteranopia => 'Deuteranopia';

  @override
  String get chartsVisionNormal => 'Normal';

  @override
  String get chartsVisionProtanopia => 'Protanopia';

  @override
  String get chartsVisionTritanopia => 'Tritanopia';

  @override
  String get chartsVsPrevious => 'vs previous period';

  @override
  String get chartsZoomReset => 'Reset zoom';

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
  String get checklistCover => 'Cover image…';

  @override
  String get checklistCoverAuto => 'Automatic (first image)';

  @override
  String get checklistCoverNoImages => 'Add an image to the list or its items first';

  @override
  String get checklistCoverUpdated => 'Cover updated';

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
  String checklistDoneThisWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count done this week',
      one: '1 done this week',
    );
    return '$_temp0';
  }

  @override
  String get checklistDragHandle => 'Drag to move';

  @override
  String get checklistDue => 'Due date';

  @override
  String get checklistDuplicate => 'Duplicate list';

  @override
  String get checklistDuplicateItem => 'Duplicate';

  @override
  String checklistDurationDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n days', one: '1 day');
    return '$_temp0';
  }

  @override
  String checklistDurationHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n hours', one: '1 hour');
    return '$_temp0';
  }

  @override
  String checklistDurationMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n minutes', one: '1 minute');
    return '$_temp0';
  }

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
  String get checklistExpandToLevelMenu => 'Expand to level…';

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
  String get checklistHasReminders => 'Has reminders';

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
  String checklistItemsDuplicated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items duplicated',
      one: '1 item duplicated',
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
  String get checklistLinkTask => 'Link to existing task…';

  @override
  String get checklistLinkTaskTitle => 'Link a task';

  @override
  String get checklistLinkedTask => 'Linked task';

  @override
  String get checklistMdBold => 'Bold';

  @override
  String get checklistMdBullet => 'Bulleted list';

  @override
  String get checklistMdCode => 'Code';

  @override
  String get checklistMdHeading => 'Heading';

  @override
  String get checklistMdItalic => 'Italic';

  @override
  String get checklistMdLink => 'Link';

  @override
  String get checklistMdStrike => 'Strikethrough';

  @override
  String get checklistMirror => 'Mirror';

  @override
  String checklistMirrorDone(String list) {
    return 'Mirrored to $list';
  }

  @override
  String get checklistMirrorMore => 'More in the original…';

  @override
  String get checklistMirrorNotAllowed => 'A mirror can’t go inside its original';

  @override
  String checklistMirrorOf(String list) {
    return 'Mirror · $list';
  }

  @override
  String get checklistMirrorTo => 'Mirror to…';

  @override
  String get checklistModeEdit => 'Edit';

  @override
  String get checklistModePreview => 'Preview';

  @override
  String get checklistMoveConflict => 'A move conflicted with a change on another device and was undone.';

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
  String get checklistNoOtherLists => 'No other list to show';

  @override
  String get checklistNoTasksToLink => 'No tasks to link yet';

  @override
  String get checklistNotFound => 'This list doesn\'t exist';

  @override
  String get checklistNotifItemGone => 'This item no longer exists';

  @override
  String get checklistOpenOriginal => 'Open the original';

  @override
  String get checklistOpenSideBySide => 'Open side by side…';

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
  String get checklistPickSecondList => 'Show next to this list';

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
  String get checklistResetConfirm => 'Every item goes back to to-do and reason notes are cleared.';

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
  String checklistStatusSpoken(String status, String age) {
    return '$status for $age';
  }

  @override
  String checklistSubItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sub-items', one: '1 sub-item');
    return '$_temp0';
  }

  @override
  String checklistTaskLinked(String task) {
    return 'Linked to $task';
  }

  @override
  String get checklistTaskPlaceholder => 'Linking to planner tasks arrives with the planner.';

  @override
  String get checklistTaskScheduled => 'Task created — set its time';

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
  String get checklistUnlinkMirror => 'Unlink mirror (keep a copy)';

  @override
  String get checklistViewGallery => 'Gallery';

  @override
  String get checklistViewKanban => 'Kanban';

  @override
  String get checklistViewMindMap => 'Mind map';

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
  String get devComponentGallery => 'Component gallery';

  @override
  String get devConfigured => 'Configured';

  @override
  String get devCopied => 'Copied';

  @override
  String get devDangerZone => 'Danger zone';

  @override
  String get devDatabase => 'Local database';

  @override
  String get devDatabaseEmpty => 'No rows.';

  @override
  String devDatabaseRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count rows', one: '1 row', zero: 'empty');
    return '$_temp0';
  }

  @override
  String get devEnvironment => 'Environment';

  @override
  String get devFirebase => 'Firebase';

  @override
  String get devFlags => 'Feature flags';

  @override
  String get devFlagsHint => 'Overrides for this session only (dev builds).';

  @override
  String devFlavor(String flavor) {
    return 'Flavor: $flavor';
  }

  @override
  String get devLogs => 'Logs';

  @override
  String get devLogsAll => 'All';

  @override
  String get devLogsCopy => 'Copy logs';

  @override
  String get devLogsEmpty => 'No log records yet.';

  @override
  String get devMenu => 'Developer menu';

  @override
  String get devNoWarnings => 'No configuration warnings';

  @override
  String get devNotConfigured => 'Not configured';

  @override
  String get devResetData => 'Reset local data';

  @override
  String get devResetDataBody =>
      'Deletes every item, setting and file stored on this device. A cloud account is signed out (its data stays on the server). This can\'t be undone.';

  @override
  String get devResetDone => 'Local data reset';

  @override
  String get devSampleData => 'Sample data';

  @override
  String get devSampleDataBody =>
      'Adds about six months of realistic tasks, lists, habits and a quit tracker for demos and screenshots.';

  @override
  String devSampleDataDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count items added', one: '1 item added');
    return '$_temp0';
  }

  @override
  String get devSampleDataGenerate => 'Generate sample data';

  @override
  String get devSampleDataRemove => 'Remove sample data';

  @override
  String get devSampleDataRemoved => 'Sample data removed';

  @override
  String devSession(String mode) {
    return 'Session: $mode';
  }

  @override
  String get devSupabase => 'Supabase';

  @override
  String devSyncAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
      zero: 'not sent yet',
    );
    return '$_temp0';
  }

  @override
  String devSyncBatch(int size) {
    return 'Push batch size: $size';
  }

  @override
  String get devSyncClear => 'Clear';

  @override
  String get devSyncConflicts => 'Conflict log';

  @override
  String get devSyncConflictsEmpty => 'No conflicts recorded.';

  @override
  String devSyncCursor(int cursor, int watermark) {
    return 'Cursor $cursor · purge watermark $watermark';
  }

  @override
  String get devSyncDiagnostics => 'Sync diagnostics';

  @override
  String devSyncGroup(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count changes', one: '1 change');
    return '$_temp0 · $when';
  }

  @override
  String devSyncLastPull(String when) {
    return 'Last pull: $when';
  }

  @override
  String devSyncLastPush(String when) {
    return 'Last push: $when';
  }

  @override
  String get devSyncNever => 'never';

  @override
  String get devSyncNoPulls => 'No pull yet in this session.';

  @override
  String get devSyncOff => 'Sync is off on this device (local-only). The outbox keeps changes for a later sign-in.';

  @override
  String get devSyncOutbox => 'Outbox';

  @override
  String get devSyncOutboxEmpty => 'The outbox is empty.';

  @override
  String devSyncPullPage(int since, int next, int changes) {
    String _temp0 = intl.Intl.pluralLogic(changes, locale: localeName, other: '$changes changes', one: '1 change');
    return '$since → $next · $_temp0';
  }

  @override
  String get devSyncPulls => 'Last pulled pages';

  @override
  String get devSyncSimulateOffline => 'Simulate offline';

  @override
  String get devSyncSimulateOfflineHint => 'Every sync run fails as if the network were down.';

  @override
  String get devTestCrash => 'Send a test crash';

  @override
  String get devTestCrashBody => 'Throws an uncaught error; release builds report it to Crashlytics.';

  @override
  String get devTimeTravel => 'Time travel';

  @override
  String devTimeTravelNow(String time) {
    return 'App time: $time';
  }

  @override
  String get devTimeTravelOff => 'Real time';

  @override
  String devTimeTravelOffset(String relative) {
    return 'Shifted: $relative';
  }

  @override
  String get devTimeTravelPick => 'Pick a date & time';

  @override
  String get devTimeTravelReset => 'Back to real time';

  @override
  String get devTools => 'Tools';

  @override
  String get devZone => 'Time zone';

  @override
  String devZoneDevice(String zone) {
    return 'Device zone: $zone';
  }

  @override
  String get devZoneOverridden => 'Overridden until reset';

  @override
  String get devZoneOverride => 'Override the device zone';

  @override
  String get devZoneReset => 'Use the real device zone';

  @override
  String durationDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
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
  String get entityStatusActive => 'Active';

  @override
  String get entityStatusArchived => 'Archived';

  @override
  String get entityStatusBlocked => 'Blocked';

  @override
  String get entityStatusCancelled => 'Cancelled';

  @override
  String get entityStatusCompleted => 'Completed';

  @override
  String get entityStatusDone => 'Done';

  @override
  String get entityStatusInProgress => 'In progress';

  @override
  String get entityStatusMissed => 'Missed';

  @override
  String get entityStatusOngoing => 'Ongoing';

  @override
  String get entityStatusPaused => 'Paused';

  @override
  String get entityStatusScheduled => 'Scheduled';

  @override
  String get entityStatusSkipped => 'Skipped';

  @override
  String get entityStatusTodo => 'To do';

  @override
  String get entityStatusWaiting => 'Waiting';

  @override
  String get errorAuth => 'Please sign in again.';

  @override
  String get errorConflict => 'This changed somewhere else. Reload and try again.';

  @override
  String get errorNetwork => 'Can\'t reach the server. Check your connection.';

  @override
  String get errorNotConfigured => 'This feature needs cloud configuration (see guide.md).';

  @override
  String get errorNotFound => 'This item no longer exists.';

  @override
  String get errorPermission => 'Permission is needed for this.';

  @override
  String get errorStorage => 'Couldn\'t read or write data on this device. Free some space and try again.';

  @override
  String get errorUnknown => 'Unexpected error.';

  @override
  String get errorUnsupportedVersion => 'Please update Everslot to keep syncing.';

  @override
  String get errorValidation => 'Please check the highlighted fields.';

  @override
  String get errorWidgetFallback => 'This part couldn\'t be shown.';

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
  String get exportPdf => 'PDF';

  @override
  String get exportPdfFailed => 'Couldn’t create the PDF';

  @override
  String get exportPdfImages => 'Include image thumbnails';

  @override
  String get exportPdfNotes => 'Include notes';

  @override
  String exportPdfPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get exportPlain => 'Plain text';

  @override
  String get exportPrint => 'Print…';

  @override
  String get exportShare => 'Share…';

  @override
  String get exportTitle => 'Share / export';

  @override
  String get exportZipBundle => 'Share as zip (with files)';

  @override
  String filterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters active',
      one: '1 filter active',
      zero: 'No filters',
    );
    return '$_temp0';
  }

  @override
  String get filterAny => 'Any';

  @override
  String get filterAttachments => 'Attachments';

  @override
  String get filterCategory => 'Category';

  @override
  String filterChipCount(String field, int count) {
    return '$field · $count';
  }

  @override
  String filterChipValue(String field, String value) {
    return '$field: $value';
  }

  @override
  String filterClear(String filter) {
    return 'Clear filter $filter';
  }

  @override
  String get filterClearAll => 'Clear all';

  @override
  String get filterDate => 'Date';

  @override
  String get filterNoCategory => 'No category';

  @override
  String get filterOneOffOnly => 'One-off';

  @override
  String get filterPriority => 'Priority';

  @override
  String get filterRecurring => 'Repeats';

  @override
  String get filterRecurringOnly => 'Recurring';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterTag => 'Tag';

  @override
  String get filterText => 'Text';

  @override
  String get filterTextPrompt => 'Contains text';

  @override
  String get filterWithAttachments => 'With attachments';

  @override
  String get filterWithoutAttachments => 'Without attachments';

  @override
  String get galleryButtons => 'Buttons';

  @override
  String get galleryChips => 'Chips & tags';

  @override
  String get galleryColors => 'Category colors';

  @override
  String get galleryConfirm => 'Confirmation';

  @override
  String get galleryContainer => 'Open item';

  @override
  String get galleryDarkTheme => 'Dark theme';

  @override
  String get galleryDialogs => 'Dialogs, sheets & pickers';

  @override
  String get galleryDisabled => 'Disabled';

  @override
  String get galleryEmpty => 'No items with images';

  @override
  String get galleryFadeThrough => 'Fade through';

  @override
  String get galleryFilters => 'Filters';

  @override
  String get galleryIcons => 'Icons';

  @override
  String get galleryInputs => 'Inputs';

  @override
  String get galleryLargeText => 'Large text (200 %)';

  @override
  String get galleryLayout => 'Adaptive layout';

  @override
  String get galleryMotion => 'Motion';

  @override
  String get galleryOnlyImages => 'Only items with images';

  @override
  String galleryPicked(String value) {
    return 'Picked: $value';
  }

  @override
  String get galleryPriorities => 'Priorities';

  @override
  String get galleryProgress => 'Progress';

  @override
  String get galleryPrompt => 'Text prompt';

  @override
  String get galleryReduceMotion => 'Reduce motion';

  @override
  String get galleryRows => 'Rows & avatars';

  @override
  String get galleryRtl => 'Right-to-left';

  @override
  String get gallerySampleText => 'Sample text';

  @override
  String get gallerySharedAxis => 'Shared axis';

  @override
  String get gallerySheet => 'Bottom sheet';

  @override
  String get gallerySheetActions => 'Sheet with actions';

  @override
  String get gallerySheetBody => 'A bottom sheet with Everslot styling.';

  @override
  String get galleryStates => 'Empty, error & loading states';

  @override
  String get galleryStatuses => 'Statuses';

  @override
  String get gallerySwipeHint => 'Swipe for actions';

  @override
  String get galleryTitle => 'Component gallery';

  @override
  String get galleryUndoSnack => 'Undo snackbar';

  @override
  String get galleryWindowCompact => 'compact';

  @override
  String get galleryWindowExpanded => 'expanded';

  @override
  String get galleryWindowMedium => 'medium';

  @override
  String galleryWindowSize(String size) {
    return 'Window: $size';
  }

  @override
  String get goalsAchieved => 'Achieved';

  @override
  String goalsAchievedOn(String date) {
    return 'Achieved $date';
  }

  @override
  String get goalsActive => 'Active';

  @override
  String get goalsAdd => 'Add a goal';

  @override
  String get goalsBadgeBackfillFreeMonth => 'A month logged on time';

  @override
  String get goalsBadgeChallenge => 'Challenge completed';

  @override
  String goalsBadgeCravings(int count) {
    return '$count cravings resisted';
  }

  @override
  String goalsBadgeEarnedOn(String date) {
    return 'Earned $date';
  }

  @override
  String get goalsBadgeFirstCheckIn => 'First check-in';

  @override
  String get goalsBadgeFirstPerfectDay => 'First perfect day';

  @override
  String get goalsBadgePerfectWeek => 'Perfect week';

  @override
  String goalsBadgeProgress(String value, String target) {
    return '$value of $target';
  }

  @override
  String get goalsBadgeShare => 'Share';

  @override
  String get goalsBadgeShareDate => 'Include the date';

  @override
  String get goalsBadgeShareHabit => 'Include the habit\'s name';

  @override
  String goalsBadgeShareText(String name) {
    return 'I earned the \"$name\" badge in Everslot.';
  }

  @override
  String get goalsBadgeShareTitle => 'Share a badge';

  @override
  String goalsBadgeStreak(int count) {
    return '$count-day streak';
  }

  @override
  String goalsBadgeTotal(String value) {
    return '$value logged';
  }

  @override
  String goalsBadgeUnlocked(String name) {
    return 'Badge unlocked: $name';
  }

  @override
  String get goalsBadgesEarned => 'Earned';

  @override
  String get goalsBadgesEmpty => 'Check in to earn your first badge.';

  @override
  String get goalsBadgesLocked => 'To earn';

  @override
  String get goalsBadgesTitle => 'Badges';

  @override
  String goalsCelebrate(String title) {
    return 'Goal reached: $title!';
  }

  @override
  String get goalsDelete => 'Delete goal';

  @override
  String get goalsDeleted => 'Goal deleted';

  @override
  String get goalsEdit => 'Edit goal';

  @override
  String get goalsEmpty => 'No goals yet';

  @override
  String get goalsEmptyBody => 'Set a target for a habit — for example 10 000 push-ups this year.';

  @override
  String get goalsEnded => 'Ended';

  @override
  String get goalsErrDates => 'Choose a start and an end date.';

  @override
  String get goalsErrEnd => 'The end must be after the start.';

  @override
  String get goalsErrMetric => 'This measure doesn\'t fit this habit.';

  @override
  String get goalsErrScope => 'Choose what the goal is about.';

  @override
  String get goalsErrTarget => 'Enter a target above zero.';

  @override
  String get goalsErrTitle => 'Keep it under 80 characters.';

  @override
  String goalsEta(String date) {
    return 'Expected $date';
  }

  @override
  String get goalsFrom => 'From';

  @override
  String get goalsHabit => 'Habit';

  @override
  String get goalsMetric => 'Measure';

  @override
  String get goalsMetricCleanDays => 'Clean days';

  @override
  String get goalsMetricCompletions => 'Days done';

  @override
  String get goalsMetricItemsCompleted => 'Items completed';

  @override
  String get goalsMetricMoneySaved => 'Money saved';

  @override
  String get goalsMetricStreakDays => 'Streak (days)';

  @override
  String get goalsMetricTotalValue => 'Total logged';

  @override
  String get goalsMetricTrackedMinutes => 'Minutes tracked';

  @override
  String get goalsMetricUnitsAvoided => 'Units avoided';

  @override
  String goalsNeedPerDay(String value) {
    return '$value a day to finish on time';
  }

  @override
  String get goalsNew => 'New goal';

  @override
  String get goalsPaceMarker => 'Where you should be today';

  @override
  String get goalsPeriod => 'Period';

  @override
  String get goalsPeriodAllTime => 'No time limit';

  @override
  String get goalsPeriodCustom => 'Custom dates';

  @override
  String get goalsPeriodMonth => 'This month';

  @override
  String get goalsPeriodQuarter => 'This quarter';

  @override
  String get goalsPeriodWeek => 'This week';

  @override
  String get goalsPeriodYear => 'This year';

  @override
  String goalsProgressOf(String actual, String target) {
    return '$actual of $target';
  }

  @override
  String get goalsSaved => 'Goal saved';

  @override
  String get goalsStatusAchieved => 'Achieved';

  @override
  String get goalsStatusAtRisk => 'At risk';

  @override
  String get goalsStatusBehind => 'Behind';

  @override
  String get goalsStatusOnTrack => 'On track';

  @override
  String goalsSuggestion(String value, String target) {
    return 'At your pace you\'d reach $value — aim for $target?';
  }

  @override
  String get goalsTarget => 'Target';

  @override
  String get goalsTitle => 'Goals';

  @override
  String get goalsTitleField => 'Title (optional)';

  @override
  String get goalsTo => 'To';

  @override
  String goalsUseSuggestion(String target) {
    return 'Aim for $target';
  }

  @override
  String habitNotifStreakMilestone(int days) {
    return '$days-day streak!';
  }

  @override
  String habitNotifTotalMilestone(String amount, String unit) {
    return '$amount $unit in total';
  }

  @override
  String get habitsActionAddValue => 'Add a value';

  @override
  String get habitsActionBackfill => 'Log another day';

  @override
  String get habitsActionCheckNow => 'Check now';

  @override
  String get habitsActionClear => 'Clear';

  @override
  String get habitsActionDetails => 'Details';

  @override
  String get habitsActionDone => 'Done';

  @override
  String get habitsActionEdit => 'Edit';

  @override
  String get habitsActionEditEntries => 'Edit entries';

  @override
  String get habitsActionExcuse => 'Excuse';

  @override
  String get habitsActionNotDone => 'Not done';

  @override
  String get habitsActionNoteMood => 'Note & mood';

  @override
  String get habitsActionPause => 'Pause';

  @override
  String get habitsActionPauseTimer => 'Pause timer';

  @override
  String get habitsActionSkip => 'Skip';

  @override
  String get habitsActionStartTimer => 'Start timer';

  @override
  String get habitsActionStopTimer => 'Stop and log';

  @override
  String get habitsActionUndoDone => 'Mark as not checked';

  @override
  String get habitsAdd => 'Add';

  @override
  String get habitsAddEntry => 'Add';

  @override
  String get habitsAddTime => 'Add a time';

  @override
  String get habitsAdvancedTitle => 'Advanced';

  @override
  String get habitsAfterCompletionDueAfter => 'Due again after';

  @override
  String get habitsAfterUnitDays => 'Days';

  @override
  String get habitsAfterUnitMonths => 'Months';

  @override
  String get habitsAfterUnitWeeks => 'Weeks';

  @override
  String get habitsAllDone => 'All done 🎉';

  @override
  String get habitsAllHabits => 'All habits';

  @override
  String get habitsAllStats => 'All stats';

  @override
  String get habitsApplyAll => 'All history';

  @override
  String get habitsApplyAllWarn => 'Past statistics will change.';

  @override
  String get habitsApplyDate => 'A chosen date…';

  @override
  String get habitsApplyTitle => 'Apply the new schedule or goal from';

  @override
  String get habitsApplyToday => 'Today';

  @override
  String get habitsArchived => 'Archived';

  @override
  String get habitsArchivedSnack => 'Habit archived';

  @override
  String get habitsAskNote => 'Ask for a note & mood after check-in';

  @override
  String get habitsAtRisk => 'At risk';

  @override
  String get habitsBestStreak => 'Best streak';

  @override
  String get habitsCalendar => 'Calendar';

  @override
  String get habitsCelebratePerfectDay => 'Perfect day — everything done!';

  @override
  String habitsCelebrateStreak(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days in a row',
      one: '1 day in a row',
    );
    return '$name: $_temp0!';
  }

  @override
  String get habitsCelebrationDismiss => 'Dismiss';

  @override
  String habitsCellSemantics(String habit, String date, String status) {
    return '$habit, $date: $status';
  }

  @override
  String habitsChallengeBestStreak(String streak) {
    return 'Best streak: $streak';
  }

  @override
  String get habitsChallengeClose => 'Close';

  @override
  String get habitsChallengeContinued => 'It\'s an ongoing habit now';

  @override
  String habitsChallengeDay(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String habitsChallengeDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: 'Last day',
    );
    return '$_temp0';
  }

  @override
  String get habitsChallengeEveryDay => 'Every scheduled day';

  @override
  String get habitsChallengeKeepGoing => 'Keep going';

  @override
  String get habitsChallengeKeepGoingHint => 'Turn it into an ongoing habit — your history stays.';

  @override
  String habitsChallengeMinRatio(String percent) {
    return 'At least $percent of the days';
  }

  @override
  String get habitsChallengeMissedBody =>
      'Not every day went to plan — and you still showed up. Try again or keep going.';

  @override
  String get habitsChallengeMissedTitle => 'Challenge finished';

  @override
  String habitsChallengeProgress(int done, int due) {
    return '$done of $due days done';
  }

  @override
  String get habitsChallengeRuleTitle => 'To succeed';

  @override
  String get habitsChallengeSuccessTitle => 'Challenge complete!';

  @override
  String get habitsChallengeTitle => 'Challenge';

  @override
  String habitsChallengeVolume(String value) {
    return 'Total: $value';
  }

  @override
  String get habitsCompactRows => 'Compact rows';

  @override
  String habitsCounts(int done, int notDone, int missed, int skipped) {
    return 'Done $done · Not done $notDone · Missed $missed · Skipped $skipped';
  }

  @override
  String get habitsCreateQuitInstead => 'Create a quit tracker';

  @override
  String get habitsCurrentStreak => 'Current streak';

  @override
  String get habitsDatesTitle => 'Dates';

  @override
  String get habitsDayStateLabel => 'Status';

  @override
  String habitsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String habitsDecrease(String step) {
    return 'Remove $step';
  }

  @override
  String get habitsDeleteBody => 'Its history goes to the trash with it. You can restore it for 30 days.';

  @override
  String get habitsDeleteEntry => 'Delete entry';

  @override
  String habitsDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get habitsDeletedSnack => 'Habit deleted';

  @override
  String habitsDragHandle(String name) {
    return 'Reorder $name';
  }

  @override
  String get habitsEditCustom => 'Edit the schedule';

  @override
  String get habitsEditEntry => 'Edit entry';

  @override
  String get habitsEditorEditTitle => 'Edit habit';

  @override
  String get habitsEditorNewTitle => 'New habit';

  @override
  String get habitsEmptyAction => 'Create a habit';

  @override
  String get habitsEmptyBody => 'Create a habit — like 15 push-ups a day — and mark each day whether you did it.';

  @override
  String get habitsEmptyTitle => 'No habits yet';

  @override
  String get habitsEndNever => 'Never';

  @override
  String get habitsEntries => 'Entries';

  @override
  String get habitsEntryDeleted => 'Entry deleted';

  @override
  String get habitsErrDuration => 'A duration goal must be between 1 min and 24 h';

  @override
  String get habitsErrEnd => 'The end date is before the start date';

  @override
  String get habitsErrFreezes => 'Between 0 and 31 freezes per month';

  @override
  String get habitsErrLimitNeedsMeasurable => '“At most” needs a count, a duration or a number';

  @override
  String get habitsErrNameEmpty => 'Enter a name';

  @override
  String get habitsErrNameTooLong => 'The name is too long (80 characters max)';

  @override
  String get habitsErrSchedule => 'This schedule isn\'t valid';

  @override
  String get habitsErrSectionName => 'Name must be 1–40 characters';

  @override
  String get habitsErrTarget => 'Enter a target greater than 0';

  @override
  String get habitsErrUnit => 'The unit must be 1–20 characters';

  @override
  String get habitsErrorArchived => 'This habit is archived.';

  @override
  String get habitsErrorFuture => 'You can\'t log this before it starts — skip or excuse it instead.';

  @override
  String habitsEveryNDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'Every $n days', two: 'Every other day');
    return '$_temp0';
  }

  @override
  String get habitsFieldCategory => 'Category';

  @override
  String get habitsFieldColor => 'Color';

  @override
  String get habitsFieldDescription => 'Description';

  @override
  String get habitsFieldEnd => 'Ends';

  @override
  String get habitsFieldIcon => 'Icon';

  @override
  String get habitsFieldName => 'Name';

  @override
  String get habitsFieldNameHint => 'e.g. 15 push-ups';

  @override
  String get habitsFieldSection => 'Section';

  @override
  String get habitsFieldStart => 'Starts';

  @override
  String get habitsFieldTarget => 'Target';

  @override
  String get habitsFieldUnit => 'Unit';

  @override
  String get habitsFilterAll => 'All';

  @override
  String get habitsFilterDue => 'Due';

  @override
  String get habitsFor30Days => 'For 30 days';

  @override
  String get habitsFreezes => 'Streak freezes per month';

  @override
  String get habitsFromTemplate => 'From a template';

  @override
  String get habitsFutureOnlyPlanned => 'Only skips and excuses can be planned for future days.';

  @override
  String get habitsGoalExampleCheck => 'Did it or not';

  @override
  String get habitsGoalExampleCount => '15 push-ups';

  @override
  String get habitsGoalExampleDuration => 'Read 20 min';

  @override
  String get habitsGoalExampleNumeric => 'Run 5 km';

  @override
  String habitsGoalSentence(String op, String amount) {
    return '$op $amount';
  }

  @override
  String get habitsGoalTitle => 'Goal';

  @override
  String get habitsGoalTypeCheck => 'Yes / No';

  @override
  String get habitsGoalTypeCount => 'Count';

  @override
  String get habitsGoalTypeDuration => 'Duration';

  @override
  String get habitsGoalTypeNumeric => 'Number';

  @override
  String get habitsGroupByCategory => 'Category';

  @override
  String get habitsGroupByNone => 'None';

  @override
  String get habitsGroupBySection => 'Section';

  @override
  String get habitsGroupByTitle => 'Group by';

  @override
  String habitsGroupNotDue(int count) {
    return 'Not due today ($count)';
  }

  @override
  String get habitsHideNotDue => 'Hide habits not due';

  @override
  String get habitsHoldRingHint => 'Press and hold to mark as done';

  @override
  String get habitsHoldToComplete => 'Hold to complete';

  @override
  String get habitsHoldToCompleteHint => 'Press and hold the ring to check a habit off, to avoid accidental taps.';

  @override
  String habitsIncrease(String step) {
    return 'Add $step';
  }

  @override
  String get habitsIncrementStep => 'Step';

  @override
  String get habitsJournal => 'Notes journal';

  @override
  String get habitsJournalEmpty => 'No notes yet';

  @override
  String get habitsJournalEmptyBody => 'Notes and moods you add to check-ins appear here.';

  @override
  String get habitsLast90 => 'Last 90 days';

  @override
  String get habitsLastDay => 'Last day';

  @override
  String habitsLeftOfLimit(String left, String limit) {
    return '$left of $limit left';
  }

  @override
  String get habitsLimitZeroHint => 'A limit of 0 means quitting it completely.';

  @override
  String get habitsManage => 'Manage habits';

  @override
  String get habitsMatrixTapTitle => 'Tapping a day in the week view';

  @override
  String get habitsMinPerDay => 'Minimum per day';

  @override
  String habitsMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get habitsMood1 => 'Awful';

  @override
  String get habitsMood2 => 'Bad';

  @override
  String get habitsMood3 => 'Okay';

  @override
  String get habitsMood4 => 'Good';

  @override
  String get habitsMood5 => 'Great';

  @override
  String get habitsMoodLabel => 'Mood';

  @override
  String get habitsMoodTrend => 'Mood trend';

  @override
  String get habitsMoveToSection => 'Move to section…';

  @override
  String get habitsNewHabit => 'New habit';

  @override
  String get habitsNewQuit => 'New quit tracker';

  @override
  String get habitsNewer => 'Later days';

  @override
  String get habitsNextDay => 'Next day';

  @override
  String get habitsNextMonth => 'Next month';

  @override
  String get habitsNextYear => 'Next year';

  @override
  String get habitsNoBuildHabits => 'No habit to check in yet';

  @override
  String get habitsNoCategory => 'No category';

  @override
  String get habitsNoEntries => 'No entries yet';

  @override
  String get habitsNone => 'None';

  @override
  String get habitsNotActiveThatDay => 'This habit wasn\'t active that day.';

  @override
  String get habitsNotEnoughData => 'Not enough data yet';

  @override
  String get habitsNoteHint => 'How did it go?';

  @override
  String get habitsNoteMoodTitle => 'Note & mood';

  @override
  String get habitsNothingThisDay => 'Nothing scheduled this day';

  @override
  String get habitsNothingThisDayBody => 'Habits appear here on the days they are due.';

  @override
  String get habitsNotifGone => 'This habit no longer exists.';

  @override
  String habitsNotifInvalidValue(String input) {
    return '“$input” isn\'t a number — open the app to log it.';
  }

  @override
  String get habitsOlder => 'Earlier days';

  @override
  String get habitsOnlyOn => 'Only on (optional)';

  @override
  String get habitsOpAtLeast => 'At least';

  @override
  String get habitsOpAtMost => 'At most';

  @override
  String get habitsOpExactly => 'Exactly';

  @override
  String habitsOrdinal(String which) {
    String _temp0 = intl.Intl.selectLogic(which, {
      'first': 'First',
      'second': 'Second',
      'third': 'Third',
      'fourth': 'Fourth',
      'other': 'Last',
    });
    return '$_temp0';
  }

  @override
  String get habitsOverLimit => 'Over the limit';

  @override
  String get habitsOverdue => 'Overdue';

  @override
  String get habitsPauseAction => 'Pause';

  @override
  String habitsPauseDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get habitsPauseHint => 'Paused days are neutral: never missed and they never break a streak.';

  @override
  String get habitsPauseIndefinitely => 'Indefinitely';

  @override
  String get habitsPauseTitle => 'Pause habit';

  @override
  String get habitsPauseToday => 'Today';

  @override
  String get habitsPauseUntil => 'Until a date…';

  @override
  String habitsPauseUntilDate(String date) {
    return 'Until $date';
  }

  @override
  String get habitsPauseWeek => '1 week';

  @override
  String get habitsPausedIndefinitely => 'Paused';

  @override
  String get habitsPausedSnack => 'Paused';

  @override
  String habitsPausedUntil(String date) {
    return 'Paused until $date';
  }

  @override
  String habitsPerfectDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perfect days',
      one: '1 perfect day',
      zero: 'No perfect day yet',
    );
    return '$_temp0';
  }

  @override
  String get habitsPickDuration => 'Pick a duration';

  @override
  String get habitsPresetAfterCompletion => 'After I finish';

  @override
  String get habitsPresetCustom => 'Custom…';

  @override
  String get habitsPresetDaily => 'Every day';

  @override
  String get habitsPresetEveryNDays => 'Every N days';

  @override
  String get habitsPresetInterval => 'Every N hours';

  @override
  String get habitsPresetMonthlyDay => 'Monthly on a day';

  @override
  String get habitsPresetMonthlyWeekday => 'Monthly on a weekday';

  @override
  String get habitsPresetSpecificDays => 'Specific days';

  @override
  String get habitsPresetSpecificTimes => 'At set times';

  @override
  String get habitsPresetTimesPerDay => 'N times a day';

  @override
  String get habitsPresetTimesPerMonth => 'N× a month';

  @override
  String get habitsPresetTimesPerWeek => 'N× a week';

  @override
  String get habitsPresetWeekdays => 'Weekdays';

  @override
  String get habitsPresetWeekends => 'Weekends';

  @override
  String get habitsPrevDay => 'Previous day';

  @override
  String get habitsPreviewNext => 'Next';

  @override
  String get habitsPreviewTitle => 'Preview';

  @override
  String get habitsPreviousMonth => 'Previous month';

  @override
  String get habitsPreviousYear => 'Previous year';

  @override
  String get habitsProgressionEvery => 'Every';

  @override
  String get habitsProgressionHint => 'Starts at the target and adds a step regularly during the challenge.';

  @override
  String get habitsProgressionMax => 'Up to (0 = no limit)';

  @override
  String get habitsProgressionStep => 'Add each time';

  @override
  String get habitsProgressionTitle => 'Grow the target';

  @override
  String habitsProgressionToday(String value) {
    return 'Today\'s target: $value';
  }

  @override
  String get habitsQuickValues => 'Quick values';

  @override
  String get habitsQuickValuesHint => 'e.g. 5 10 15';

  @override
  String habitsQuotaMonth(int done, int times) {
    return '$done of $times this month';
  }

  @override
  String habitsQuotaWeek(int done, int times) {
    return '$done of $times this week';
  }

  @override
  String get habitsRate30 => '30-day rate';

  @override
  String get habitsReasonOptional => 'Reason (optional)';

  @override
  String get habitsRecentEntries => 'Recent entries';

  @override
  String habitsRecordAbstinence(String value) {
    return 'Longest clean stretch ever: $value';
  }

  @override
  String habitsRecordBestDay(String value) {
    return 'Best day ever: $value';
  }

  @override
  String habitsRecordBestWeek(String value) {
    return 'Best week ever: $value';
  }

  @override
  String habitsRecordCravings(int count) {
    return 'Most cravings resisted in a day: $count';
  }

  @override
  String get habitsRecordNew => 'New record!';

  @override
  String habitsRecordStreak(String value) {
    return 'Longest streak ever: $value';
  }

  @override
  String get habitsReorder => 'Reorder';

  @override
  String get habitsReorderDone => 'Done';

  @override
  String get habitsReorderHint => 'Drag the handles to change the order.';

  @override
  String get habitsReordered => 'Order saved';

  @override
  String get habitsRequireExplicit => 'An empty day counts as missed';

  @override
  String get habitsResume => 'Resume';

  @override
  String get habitsResumedSnack => 'Resumed';

  @override
  String get habitsRollupAll => 'All check-ins must be done';

  @override
  String habitsRollupMin(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'At least $n check-ins',
      one: 'At least 1 check-in',
    );
    return '$_temp0';
  }

  @override
  String get habitsRollupMinCount => 'Check-ins needed';

  @override
  String get habitsRollupMinTitle => 'A day counts when some check-ins are done';

  @override
  String get habitsSavedSnack => 'Saved';

  @override
  String get habitsScheduleTitle => 'Schedule';

  @override
  String get habitsSectionAfternoon => 'Afternoon';

  @override
  String get habitsSectionAnytime => 'Anytime';

  @override
  String get habitsSectionDeleteBody => 'Its habits move to Anytime.';

  @override
  String get habitsSectionDeleteTitle => 'Delete this section?';

  @override
  String get habitsSectionDeleted => 'Section deleted';

  @override
  String get habitsSectionEdit => 'Edit section';

  @override
  String get habitsSectionEvening => 'Evening';

  @override
  String get habitsSectionMorning => 'Morning';

  @override
  String get habitsSectionNew => 'New section';

  @override
  String get habitsSectionNone => 'Other';

  @override
  String habitsSectionProgress(int done, int total) {
    return '$done / $total done';
  }

  @override
  String get habitsSectionWindow => 'Time window';

  @override
  String get habitsSections => 'Sections';

  @override
  String get habitsShowStreaks => 'Show streaks';

  @override
  String get habitsSkipBreaks => 'Break the streak';

  @override
  String get habitsSkipNeutral => 'Don\'t break the streak';

  @override
  String get habitsSkipPolicy => 'Skipped days';

  @override
  String habitsSlotsProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String habitsSnackCleared(String name) {
    return '“$name” cleared';
  }

  @override
  String habitsSnackDone(String name) {
    return '“$name” done';
  }

  @override
  String habitsSnackExcused(String name) {
    return '“$name” excused';
  }

  @override
  String habitsSnackLogged(String amount, String name) {
    return 'Logged $amount · $name';
  }

  @override
  String habitsSnackNotDone(String name) {
    return '“$name” marked not done';
  }

  @override
  String habitsSnackSkipped(String name) {
    return '“$name” skipped';
  }

  @override
  String get habitsStatusDone => 'Done';

  @override
  String get habitsStatusExcused => 'Excused';

  @override
  String get habitsStatusFailed => 'Not done';

  @override
  String get habitsStatusFrozen => 'Frozen';

  @override
  String get habitsStatusMissed => 'Missed';

  @override
  String get habitsStatusNotDue => 'Not due';

  @override
  String get habitsStatusPartial => 'Partly done';

  @override
  String get habitsStatusPaused => 'Paused';

  @override
  String get habitsStatusPending => 'To do';

  @override
  String get habitsStatusSkipped => 'Skipped';

  @override
  String habitsStreakSemantics(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days-day streak', one: '1-day streak');
    return '$_temp0';
  }

  @override
  String get habitsStrength => 'Strength';

  @override
  String get habitsTapCycleDoneFail => 'Done → Not done → Clear';

  @override
  String get habitsTapCycleDoneOnly => 'Done → Clear';

  @override
  String get habitsTapCycleDoneSkip => 'Done → Skip → Clear';

  @override
  String get habitsTemplatesChallenges => 'Challenges';

  @override
  String get habitsTemplatesHabits => 'Habits';

  @override
  String get habitsTemplatesQuit => 'Quit';

  @override
  String get habitsTemplatesTitle => 'Templates';

  @override
  String habitsTimerElapsed(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes minutes', one: '1 minute');
    return 'Timer: $_temp0';
  }

  @override
  String habitsTimesPerDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n times a day', one: 'Once a day');
    return '$_temp0';
  }

  @override
  String habitsTimesPerMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n times a month',
      two: 'Twice a month',
      one: 'Once a month',
    );
    return '$_temp0';
  }

  @override
  String habitsTimesPerWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n times a week',
      two: 'Twice a week',
      one: 'Once a week',
    );
    return '$_temp0';
  }

  @override
  String get habitsToday => 'Today';

  @override
  String get habitsToggleShortPress => 'Toggle with a short press';

  @override
  String get habitsToggleShortPressHint => 'Off: a long press toggles, a short press opens the day.';

  @override
  String get habitsTolerance => 'Early check-in window';

  @override
  String habitsTotalOfTarget(String total, String target) {
    return 'Total $total of $target';
  }

  @override
  String get habitsTplChallengeMeditate => '14 days of meditation';

  @override
  String get habitsTplChallengeMeditateDesc => '10 minutes a day for 14 days';

  @override
  String get habitsTplChallengeNoSugar => '21 days without sugar';

  @override
  String get habitsTplChallengeNoSugarDesc => 'Every day for 21 days';

  @override
  String get habitsTplChallengePushUps => '30 days of push-ups';

  @override
  String get habitsTplChallengePushUpsDesc => '20 reps a day for 30 days';

  @override
  String get habitsTplCoffeeLimit => 'At most 2 coffees';

  @override
  String get habitsTplCoffeeLimitDesc => 'A daily limit';

  @override
  String get habitsTplGym => 'Gym';

  @override
  String get habitsTplGymDesc => '3 times a week, any days';

  @override
  String get habitsTplJournal => 'Journal';

  @override
  String get habitsTplJournalDesc => 'Yes / no, every evening';

  @override
  String get habitsTplMeditate => 'Meditate';

  @override
  String get habitsTplMeditateDesc => '10 minutes a day';

  @override
  String get habitsTplPushUps => '15 push-ups';

  @override
  String get habitsTplPushUpsDesc => 'Count ≥ 15 reps, every day';

  @override
  String get habitsTplRead => 'Read';

  @override
  String get habitsTplReadDesc => '20 minutes a day';

  @override
  String get habitsTplSleepEarly => 'Sleep before 23:00';

  @override
  String get habitsTplSleepEarlyDesc => 'Yes / no, every day';

  @override
  String get habitsTplStretch => 'Stretch';

  @override
  String get habitsTplStretchDesc => 'Every hour 09:00–18:00 (6 of 10)';

  @override
  String get habitsTplWalk => 'Walk';

  @override
  String get habitsTplWalkDesc => '5 km a day';

  @override
  String get habitsTplWater => 'Drink water';

  @override
  String get habitsTplWaterDesc => '8 glasses a day';

  @override
  String get habitsTypeBuild => 'Build a habit';

  @override
  String get habitsTypeQuit => 'Quit something';

  @override
  String get habitsUnarchive => 'Unarchive';

  @override
  String get habitsUnarchivedSnack => 'Habit restored';

  @override
  String habitsUnitCigarettes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'cigarettes', one: 'cigarette');
    return '$_temp0';
  }

  @override
  String habitsUnitCups(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'cups', one: 'cup');
    return '$_temp0';
  }

  @override
  String get habitsUnitCustom => 'Custom…';

  @override
  String habitsUnitDrinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'drinks', one: 'drink');
    return '$_temp0';
  }

  @override
  String habitsUnitGlasses(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'glasses', one: 'glass');
    return '$_temp0';
  }

  @override
  String get habitsUnitH => 'h';

  @override
  String habitsUnitJoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'joints', one: 'joint');
    return '$_temp0';
  }

  @override
  String get habitsUnitKcal => 'kcal';

  @override
  String get habitsUnitKm => 'km';

  @override
  String get habitsUnitL => 'L';

  @override
  String get habitsUnitMi => 'mi';

  @override
  String get habitsUnitMin => 'min';

  @override
  String get habitsUnitMl => 'ml';

  @override
  String habitsUnitPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'pages', one: 'page');
    return '$_temp0';
  }

  @override
  String habitsUnitReps(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'reps', one: 'rep');
    return '$_temp0';
  }

  @override
  String habitsUnitServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'servings', one: 'serving');
    return '$_temp0';
  }

  @override
  String habitsUnitSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'sessions', one: 'session');
    return '$_temp0';
  }

  @override
  String habitsUnitSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'steps', one: 'step');
    return '$_temp0';
  }

  @override
  String habitsUnitTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'times', one: 'time');
    return '$_temp0';
  }

  @override
  String get habitsVacationIndefinitely => 'Vacation mode is on';

  @override
  String get habitsVacationTitle => 'Vacation mode';

  @override
  String habitsVacationUntil(String date) {
    return 'Vacation mode until $date';
  }

  @override
  String get habitsValueHint => 'Amount';

  @override
  String get habitsValueInvalid => 'Enter a number greater than 0';

  @override
  String get habitsValueTitle => 'Log a value';

  @override
  String get habitsViewMonth => 'Month';

  @override
  String get habitsViewOptions => 'View options';

  @override
  String get habitsViewToday => 'Today';

  @override
  String get habitsViewWeek => 'Week';

  @override
  String get habitsViewYear => 'Year';

  @override
  String habitsWarnManySlots(int count) {
    return '$count check-ins a day — that is a lot.';
  }

  @override
  String get habitsWarnNeverDue => 'This schedule has no upcoming day.';

  @override
  String habitsWeekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get habitsWindowFrom => 'From';

  @override
  String get habitsWindowTo => 'To';

  @override
  String get habitsYear => 'Year';

  @override
  String habitsYearSummary(int done, int scheduled, String year) {
    return 'Done on $done of $scheduled scheduled days in $year';
  }

  @override
  String habitsZoneFixed(String zone) {
    return 'Always use $zone';
  }

  @override
  String habitsZoneFixedHint(String zone) {
    return 'Days follow $zone wherever you are';
  }

  @override
  String get habitsZoneFloating => 'Days follow your current time zone';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count items', one: '1 item');
    return '$_temp0';
  }

  @override
  String get importKeepOne => 'Keep as one item';

  @override
  String importMoreLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…and $count more items',
      one: '…and 1 more item',
    );
    return '$_temp0';
  }

  @override
  String get importPasteHint => 'Paste indented text, Markdown or OPML';

  @override
  String get importSplit => 'Split into items (keep nesting)';

  @override
  String importSplitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Split into $count items (keep nesting)',
      one: 'Split into 1 item (keep nesting)',
    );
    return '$_temp0';
  }

  @override
  String get importTitle => 'Import';

  @override
  String get importWarningAttachments => 'Attachment references were skipped';

  @override
  String get importWarningEmpty => 'Nothing to import';

  @override
  String get importWarningMalformed => 'This file couldn\'t be read';

  @override
  String get importWarningTooMany => 'Only the first 10 000 lines were imported';

  @override
  String get integrationsActionFailed => 'That action couldn\'t be completed.';

  @override
  String integrationsHabitLogged(String habit) {
    return 'Logged: $habit';
  }

  @override
  String integrationsHabitNotFound(String name) {
    return 'No habit matches \"$name\".';
  }

  @override
  String get integrationsLinkInTrash => 'This item is in the Trash.';

  @override
  String get integrationsLinkNotFound => 'This link can\'t be opened in Everslot.';

  @override
  String get integrationsNothingNext => 'Nothing else is planned today.';

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
  String get itemNoStepDuration => 'Shares the task’s time';

  @override
  String get itemNote => 'Note';

  @override
  String get itemOtherDevice => 'another device';

  @override
  String get itemPriority => 'Priority';

  @override
  String itemScheduledAs(String title) {
    return 'Scheduled: $title';
  }

  @override
  String get itemScheduledBadge => 'Scheduled as a task';

  @override
  String get itemStepDuration => 'Step duration (routines)';

  @override
  String get itemText => 'Text';

  @override
  String get itemThisDevice => 'this device';

  @override
  String get itemTimeInStatus => 'Time in status';

  @override
  String get itemsColAge => 'Age';

  @override
  String get itemsColAttachments => 'Files';

  @override
  String get itemsColChecklist => 'List';

  @override
  String get itemsColDue => 'Due';

  @override
  String get itemsColFollowUp => 'Follow-up';

  @override
  String get itemsColPath => 'Path';

  @override
  String get itemsColPriority => 'Priority';

  @override
  String get itemsColStatus => 'Status';

  @override
  String get itemsColText => 'Item';

  @override
  String get itemsTableEmpty => 'No items match';

  @override
  String get itemsTableFilterHint => 'Filter by text, list or path';

  @override
  String get itemsTableOpen => 'All items (table)';

  @override
  String get itemsTableSelectAll => 'Select all shown items';

  @override
  String itemsTableSelectRow(String item) {
    return 'Select $item';
  }

  @override
  String itemsTableSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count selected', one: '1 selected');
    return '$_temp0';
  }

  @override
  String itemsTableSortBy(String column) {
    return 'Sort by $column';
  }

  @override
  String itemsTableStatusChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items updated',
      one: '1 item updated',
    );
    return '$_temp0';
  }

  @override
  String get itemsTableTitle => 'All items';

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
  String get linkKindChecklist => 'List';

  @override
  String get linkKindChecklistItem => 'List item';

  @override
  String get linkKindHabit => 'Habit';

  @override
  String get linkKindHabitLog => 'Habit note';

  @override
  String get linkKindTask => 'Task';

  @override
  String get linkedCompleteAction => 'Complete';

  @override
  String linkedCompleteItemBody(String item) {
    return '“$item” is scheduled by this task.';
  }

  @override
  String get linkedCompleteItemTitle => 'Complete the list item too?';

  @override
  String linkedCompleteTaskBody(String task) {
    return '“$task” schedules this item.';
  }

  @override
  String get linkedCompleteTaskTitle => 'Mark the task done too?';

  @override
  String get linkedEntityMissing => 'Deleted';

  @override
  String linkedEntitySemantics(String kind, String title, String status) {
    return '$kind: $title, $status. Opens it';
  }

  @override
  String get linkedEntityUntitled => 'Untitled';

  @override
  String get listsAllLists => 'All lists';

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
  String get listsEditLabels => 'Edit labels';

  @override
  String get listsEmptyAction => 'Create your first list';

  @override
  String get listsEmptyMessage => 'Checklists, notes and routines — nested as deep as you need.';

  @override
  String get listsEmptyTitle => 'No lists yet';

  @override
  String get listsFilterAnyLabel => 'Any label';

  @override
  String get listsFilterColor => 'Color';

  @override
  String get listsFilterHasAttachments => 'With attachments';

  @override
  String get listsFilterHasBlocked => 'Waiting or blocked';

  @override
  String get listsFilterHasDue => 'With due dates';

  @override
  String get listsFilterLabel => 'Label';

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
  String listsLabelFilterActive(String label) {
    return 'Showing lists labelled $label';
  }

  @override
  String listsLabelSemantics(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lists',
      one: '1 list',
      zero: 'no lists',
    );
    return '$label, $_temp0';
  }

  @override
  String get listsListView => 'List view';

  @override
  String get listsMoveConflicted => 'A move conflicted with a change on another device and was undone.';

  @override
  String get listsMoveConflictedUndo => 'Move undone after a sync conflict';

  @override
  String get listsMoveItems => 'Move items…';

  @override
  String get listsNewChecklist => 'New checklist';

  @override
  String get listsNewNote => 'New note';

  @override
  String get listsNoLabels => 'No labels yet';

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
  String get localOnlyBanner => 'Cloud sync isn\'t configured — your data stays on this device.';

  @override
  String get mindMapExport => 'Export as image';

  @override
  String mindMapHidden(int count) {
    return '+$count';
  }

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
  String get notifActionCleanDay => 'Clean day';

  @override
  String get notifActionComplete => 'Complete';

  @override
  String get notifActionDone => 'Done';

  @override
  String get notifActionExtend => '+10 min';

  @override
  String get notifActionInputPlaceholder => 'Value';

  @override
  String get notifActionLogCraving => 'Log craving';

  @override
  String get notifActionLogRelapse => 'Log relapse';

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
  String get notifActionPledge => 'Pledge';

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
  String get notifAlarmAllowExact => 'Allow exact alarms';

  @override
  String get notifAlarmAllowFullScreen => 'Allow full-screen alarms';

  @override
  String get notifAlarmIosFallback =>
      'On this iPhone, alarms arrive as time-sensitive notifications: they break through Focus but follow the ring/silent switch.';

  @override
  String get notifAlarmLimited =>
      'Alarms may not ring through silent mode: allow exact alarms and full-screen notifications for Everslot.';

  @override
  String get notifAlarmMaxSnoozes => 'Snoozes allowed';

  @override
  String get notifAlarmMission => 'Mission to stop it';

  @override
  String get notifAlarmMissionCount => 'How many';

  @override
  String get notifAlarmOptions => 'Alarm options';

  @override
  String get notifAlarmQrSaved => 'Code saved — scan again to change it';

  @override
  String get notifAlarmQrScan => 'Scan the code to use';

  @override
  String get notifAlarmRamp => 'Gradually louder';

  @override
  String get notifAlarmRinging => 'Alarm';

  @override
  String notifAlarmSnooze(int minutes) {
    return 'Snooze $minutes min';
  }

  @override
  String get notifAlarmStop => 'Stop';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count reminders', one: '1 reminder');
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
  String notifBodyBlockedFor(String item, String age) {
    return '$item has been blocked for $age';
  }

  @override
  String get notifBodyChildOverdue => 'A sub-item is overdue';

  @override
  String get notifBodyChildrenComplete => 'All sub-items are done — complete it?';

  @override
  String notifBodyCleanDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
    return '$_temp0 free — well done!';
  }

  @override
  String get notifBodyCravingSupport => 'Cravings often come around now — you can ride it out.';

  @override
  String notifBodyCravingSupportTip(String tip) {
    return 'Cravings often come around now. $tip';
  }

  @override
  String notifBodyDueIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes min', one: '1 min');
    return 'Due in $_temp0';
  }

  @override
  String get notifBodyDueNow => 'Due now';

  @override
  String get notifBodyEncouragement => 'A slip is not the end — today is a fresh start.';

  @override
  String notifBodyEndedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes min', one: '1 min');
    return 'Ended $_temp0 ago';
  }

  @override
  String get notifBodyEndingNow => 'Ending now';

  @override
  String notifBodyEndsIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes min', one: '1 min');
    return 'Ends in $_temp0';
  }

  @override
  String get notifBodyEveningReview => 'How did today go?';

  @override
  String notifBodyInDays(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
    return 'In $_temp0 · $date';
  }

  @override
  String notifBodyInactivity(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
    return 'No activity for $_temp0';
  }

  @override
  String notifBodyListReset(String list) {
    return '$list was reset for today';
  }

  @override
  String notifBodyMilestone(String label) {
    return 'Milestone reached: $label';
  }

  @override
  String notifBodyMotivation(String reason) {
    return 'Remember why: $reason';
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
  String get notifBodyPledge => 'Ready to pledge for today?';

  @override
  String notifBodyQuotaBehind(String done, String target, int remaining) {
    return '$done/$target done — $remaining to go';
  }

  @override
  String notifBodyQuotaLastChance(int remaining) {
    return 'Last chance today: $remaining to go';
  }

  @override
  String notifBodyQuotaPace(String done, String target, int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days left', one: '1 day left');
    return '$done of $target done — $_temp0';
  }

  @override
  String get notifBodySnoozed => 'Snoozed reminder';

  @override
  String notifBodyStartedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes min', one: '1 min');
    return 'Started $_temp0 ago';
  }

  @override
  String get notifBodyStartingNow => 'Starting now';

  @override
  String notifBodyStartsIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes min', one: '1 min');
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
  String notifBodyStillWaitingOn(String item, String age) {
    return 'Still waiting on $item ($age)';
  }

  @override
  String notifBodyStreakRisk(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days-day', one: '1-day');
    return 'Keep your $_temp0 streak alive';
  }

  @override
  String get notifBodyTest => 'Test notification from Everslot';

  @override
  String notifBodyTimeFor(String title) {
    return 'Time for $title';
  }

  @override
  String notifBodyTimeUp(String title) {
    return 'Time\'s up for $title';
  }

  @override
  String notifBodyToday(String date) {
    return 'Today · $date';
  }

  @override
  String notifBodyUpNext(String next, String time) {
    return 'Up next: $next at $time';
  }

  @override
  String notifBodyUpNextMerged(String title, String next, String time) {
    return 'Done with $title? Up next: $next at $time';
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
  String get notifChipChangeTime => 'Change the time';

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
  String notifChipLastDayAt(String time) {
    return 'On the last day at $time';
  }

  @override
  String get notifChipMilestones => 'Milestones';

  @override
  String notifChipOnDayAt(String time) {
    return 'On the day at $time';
  }

  @override
  String get notifChipRepeat => 'Repeat…';

  @override
  String get notifChipStreakRisk => 'Streak at risk';

  @override
  String get notifConditions => 'Conditions';

  @override
  String get notifContent => 'Content';

  @override
  String get notifContentBody => 'Body template';

  @override
  String get notifContentPack => 'Rotating messages';

  @override
  String get notifContentTitle => 'Title template';

  @override
  String notifCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders copied',
      one: '1 reminder copied',
    );
    return '$_temp0';
  }

  @override
  String get notifCopingTipBreathe => 'Try a minute of box breathing.';

  @override
  String get notifCopingTipWalk => 'Take a short walk.';

  @override
  String get notifCopingTipWater => 'Drink a glass of water.';

  @override
  String get notifCopyFrom => 'Copy reminders from…';

  @override
  String get notifCopyNothing => 'That item has no reminders of its own';

  @override
  String notifCravingSupportNeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Craving support learns your usual craving hours from 10 logged cravings — $count logged so far.',
      one: 'Craving support learns your usual craving hours from 10 logged cravings — 1 logged so far.',
    );
    return '$_temp0';
  }

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
  String notifDigestBacklog(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count unscheduled', one: '1 unscheduled');
    return '$_temp0';
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
  String get notifDigestMonthlyReady => 'Your monthly report is ready';

  @override
  String get notifDigestOverdue => 'Overdue summary';

  @override
  String get notifDigestPlanTomorrow => 'Plan tomorrow';

  @override
  String notifDigestSummary(int tasks, int habits, int items) {
    String _temp0 = intl.Intl.pluralLogic(tasks, locale: localeName, other: '$tasks tasks', one: '1 task');
    String _temp1 = intl.Intl.pluralLogic(habits, locale: localeName, other: '$habits habits', one: '1 habit');
    String _temp2 = intl.Intl.pluralLogic(items, locale: localeName, other: '$items list items', one: '1 list item');
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get notifDigestWeekly => 'Weekly review';

  @override
  String get notifDigestWeeklyReady => 'Your week in review is ready';

  @override
  String get notifDigests => 'Digests';

  @override
  String get notifDisable => 'Disable';

  @override
  String get notifEditorTitle => 'New reminder';

  @override
  String get notifEmailDigests => 'Email me my digests';

  @override
  String get notifEmailDigestsHint =>
      'Agenda and review digests also arrive by email. Reminders never do. Unsubscribe from any email.';

  @override
  String get notifEnable => 'Turn on';

  @override
  String get notifEscalation => 'Escalation';

  @override
  String get notifEscalationAdd => 'Add escalation step';

  @override
  String get notifEscalationAllDevices => 'On every device';

  @override
  String get notifEscalationFrom => 'From repeat';

  @override
  String get notifExactOff => 'Reminders may arrive up to an hour late';

  @override
  String get notifExactOffBody => 'Allow precise reminders so they fire at the exact minute.';

  @override
  String get notifFieldAfterDays => 'After (days)';

  @override
  String get notifFieldAfterMinutes => 'After (minutes)';

  @override
  String get notifFieldAtTime => 'At time';

  @override
  String get notifFieldBeforeNextMinutes => 'Minutes before the next task (0 = at the end)';

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
  String get notifFieldMinutesBefore => 'Minutes before';

  @override
  String get notifFieldOffset => 'Offset in minutes (negative = before)';

  @override
  String get notifFieldRepeats => 'Repeats';

  @override
  String get notifFieldRitual => 'Ritual';

  @override
  String get notifFieldStatuses => 'Statuses';

  @override
  String get notifFieldThresholds => 'Thresholds (comma separated, empty = automatic)';

  @override
  String get notifFieldToStatus => 'New status';

  @override
  String get notifFieldUntil => 'Until';

  @override
  String get notifFreqDaily => 'Every day';

  @override
  String get notifFreqMonthly => 'Every month';

  @override
  String get notifFreqWeekly => 'Every week';

  @override
  String get notifFrom => 'From';

  @override
  String get notifHideContent => 'Hide content in notifications';

  @override
  String notifImpact(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count items', one: '1 item');
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
  String get notifInboxDeletedRule => 'Deleted reminder';

  @override
  String get notifInboxDismiss => 'Dismiss';

  @override
  String get notifInboxDismissSelected => 'Dismiss';

  @override
  String get notifInboxDismissed => 'Notification dismissed';

  @override
  String notifInboxDismissedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications dismissed',
      one: '1 notification dismissed',
    );
    return '$_temp0';
  }

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
  String get notifInboxMarkRead => 'Mark as read';

  @override
  String get notifInboxMarkedRead => 'Marked as read';

  @override
  String get notifInboxMarkedUnread => 'Marked as unread';

  @override
  String get notifInboxMuteRule => 'Mute this reminder';

  @override
  String get notifInboxMuteRules => 'Mute these reminders';

  @override
  String notifInboxNagCount(int count) {
    return '×$count';
  }

  @override
  String get notifInboxNoisiest => 'Busiest this week';

  @override
  String get notifInboxNoneThisWeek => 'Nothing fired this week.';

  @override
  String get notifInboxOneItem => 'One item';

  @override
  String get notifInboxRemindAgain => 'Remind me again…';

  @override
  String notifInboxRulesMuted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminder rules muted',
      one: '1 reminder rule muted',
    );
    return '$_temp0';
  }

  @override
  String get notifInboxSearch => 'Search notifications';

  @override
  String get notifInboxSearchHint => 'Search titles and text';

  @override
  String notifInboxSelected(int count) {
    return '$count selected';
  }

  @override
  String get notifInboxSnoozed => 'Snoozed';

  @override
  String notifInboxSnoozedUntil(String time) {
    return 'Snoozed until $time';
  }

  @override
  String notifInboxTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count times', one: '1 time');
    return '$_temp0';
  }

  @override
  String get notifInboxTitle => 'Inbox';

  @override
  String get notifInboxToday => 'Today';

  @override
  String get notifInboxToggle => 'Show in inbox';

  @override
  String get notifInboxTopItems => 'Items with the most notifications';

  @override
  String get notifInboxTopRules => 'Rules that fired most';

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
  String get notifIssueAnchorUnavailable => 'This anchor isn’t available for this item';

  @override
  String get notifIssueEmptyContent => 'The title can’t be empty';

  @override
  String get notifIssueEscalation =>
      'Escalation steps must start at repeat 1 or later, go up, and each pick a profile.';

  @override
  String get notifIssueLateness => 'Lateness must be at least 1 minute';

  @override
  String get notifIssueNoChannel => 'Choose at least one way to be notified';

  @override
  String get notifIssueOffsetOutOfRange => 'The offset must be within 30 days';

  @override
  String get notifIssueRepeatDoze =>
      'On Android, repeats less than 10 minutes apart may arrive late while the phone sleeps';

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
  String get notifIssueTooManyActions => 'Android shows only the first 3 actions';

  @override
  String get notifIssueUnknownTrigger => 'This rule type isn’t supported by this version';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count reminders', one: '1 reminder');
    return '$_temp0';
  }

  @override
  String get notifMetricCleanDays => 'Clean days';

  @override
  String get notifMetricCustom => 'My goals';

  @override
  String get notifMetricHealth => 'Health milestones';

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
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes min', one: '1 min');
    return '$_temp0';
  }

  @override
  String get notifMissionAnswer => 'Answer';

  @override
  String get notifMissionCheck => 'Check';

  @override
  String get notifMissionMathName => 'Solve sums';

  @override
  String notifMissionMathProgress(int current, int total) {
    return 'Sum $current of $total';
  }

  @override
  String get notifMissionQr => 'Scan your saved code to stop the alarm';

  @override
  String get notifMissionQrName => 'Scan a QR code';

  @override
  String notifMissionShake(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shake your phone $count times',
      one: 'Shake your phone once',
    );
    return '$_temp0';
  }

  @override
  String get notifMissionShakeName => 'Shake the phone';

  @override
  String get notifMissionToStop => 'Complete the mission to stop the alarm';

  @override
  String get notifMissionTypeName => 'Type the title';

  @override
  String get notifMissionTypeTitle => 'Type this to stop the alarm';

  @override
  String get notifMissionWrong => 'Not quite — try again';

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
  String get notifNoiseBlocked => 'Too many notifications (more than 1 440 per day)';

  @override
  String get notifNoiseCluster => 'Several reminders share this minute — only one sound plays';

  @override
  String notifNoiseConfirm(int perDay) {
    return 'This reminder sends about $perDay notifications per day. Save anyway?';
  }

  @override
  String notifNoiseWarn(int perDay) {
    return 'About $perDay notifications per day';
  }

  @override
  String get notifNoticeChannelBody => 'Open the system settings to allow them again.';

  @override
  String get notifNoticeRevokedBody => 'Sign in again to keep syncing.';

  @override
  String get notifNoticeRevokedTitle => 'This device was removed from your account';

  @override
  String get notifNoticeSaturatedBody =>
      'iOS keeps only the next 64 reminders. Open Everslot regularly (or turn on push) so the later ones get scheduled.';

  @override
  String get notifNoticeSaturatedTitle => 'Not all reminders fit on this device';

  @override
  String get notifNoticeSyncBody => 'Your changes are safe on this device. Check your connection or sign in again.';

  @override
  String get notifNoticeSyncTitle => 'Sync has been failing for over a day';

  @override
  String get notifNoticeUpdateBody =>
      'This version can no longer sync. Install the latest version to keep your data in sync.';

  @override
  String get notifNoticeUpdateTitle => 'Update Everslot';

  @override
  String get notifOccurrenceAdd => 'Add for this occurrence only';

  @override
  String get notifOccurrenceNone => 'No reminders for this occurrence.';

  @override
  String get notifOccurrenceOff => 'Off for this occurrence';

  @override
  String get notifOccurrenceOnly => 'This occurrence only';

  @override
  String get notifOccurrenceReminders => 'Reminders for this occurrence';

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
  String notifPackHabit1(String habit) {
    return 'Small steps add up — time for $habit.';
  }

  @override
  String notifPackHabit2(String habit) {
    return 'Keep the chain going: $habit today.';
  }

  @override
  String notifPackHabit3(String habit) {
    return 'Future you will thank you for $habit.';
  }

  @override
  String notifPackHabit4(String habit) {
    return 'Just start — two minutes of $habit counts.';
  }

  @override
  String notifPackHabit5(String habit) {
    return 'You\'ve got this: $habit.';
  }

  @override
  String get notifPackHabitName => 'Motivation (habits)';

  @override
  String get notifPackNone => 'Off';

  @override
  String notifPackQuit1(String days) {
    return '$days days free — keep going.';
  }

  @override
  String notifPackQuit2(String reason) {
    return 'Remember why you started: $reason';
  }

  @override
  String get notifPackQuit3 => 'Cravings pass. You\'re stronger than this one.';

  @override
  String notifPackQuit4(String amount) {
    return '$amount saved so far — well done.';
  }

  @override
  String get notifPackQuit5 => 'One day at a time — today counts.';

  @override
  String get notifPackQuitName => 'Motivation (quit)';

  @override
  String get notifPause1h => '1 hour';

  @override
  String get notifPauseAll => 'Pause all';

  @override
  String get notifPauseCustom => 'Custom…';

  @override
  String get notifPauseTomorrow => 'Until tomorrow 08:00';

  @override
  String get notifPausedShort => 'Notifications paused';

  @override
  String notifPausedUntil(String time) {
    return 'Paused until $time';
  }

  @override
  String get notifPermissionOff => 'Notifications are turned off';

  @override
  String get notifPermissionOffBody => 'Turn them on to receive your reminders.';

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
  String get notifRitualCravingSupport => 'Craving support';

  @override
  String get notifRitualEncouragement => 'Encouragement after a slip';

  @override
  String get notifRitualEveningReview => 'Evening review';

  @override
  String get notifRitualMotivation => 'Reminder of my reason';

  @override
  String get notifRitualPledge => 'Morning pledge';

  @override
  String get notifRuleDeleted => 'Reminder deleted';

  @override
  String get notifRuleEnabled => 'Reminder enabled';

  @override
  String get notifRuleSaved => 'Reminder saved';

  @override
  String notifRuleSetApplied(String name) {
    return 'Applied “$name”';
  }

  @override
  String get notifRuleSetApply => 'Apply';

  @override
  String get notifRuleSetApplyBody => 'Its reminders replace this item\'s own reminders.';

  @override
  String notifRuleSetApplyTitle(String name) {
    return 'Apply “$name”?';
  }

  @override
  String notifRuleSetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count reminders', one: '1 reminder');
    return '$_temp0';
  }

  @override
  String notifRuleSetDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get notifRuleSetEmpty => 'No rule sets yet. Save an item\'s reminders as a set to reuse them anywhere.';

  @override
  String get notifRuleSetExport => 'Export';

  @override
  String get notifRuleSetImport => 'Import a rule set';

  @override
  String notifRuleSetImported(String name) {
    return 'Imported “$name”';
  }

  @override
  String get notifRuleSetInvalid => 'This file isn\'t a valid Everslot rule set.';

  @override
  String get notifRuleSetName => 'Rule set name';

  @override
  String get notifRuleSetNothing => 'This item has no reminders of its own to save.';

  @override
  String get notifRuleSetSave => 'Save these reminders as a rule set…';

  @override
  String notifRuleSetSaved(String name) {
    return 'Saved as “$name”';
  }

  @override
  String get notifRuleSets => 'Rule sets';

  @override
  String get notifSaturationBody => 'Open Everslot to keep your reminders up to date';

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
    String _temp0 = intl.Intl.pluralLogic(hours, locale: localeName, other: '$hours hours', one: '1 hour');
    return '$_temp0';
  }

  @override
  String get notifSnoozeLimit => 'Snooze limit reached';

  @override
  String notifSnoozeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes min', one: '1 min');
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
  String notifStatsActed(int count) {
    return '$count acted on';
  }

  @override
  String get notifStatsByItem => 'Items';

  @override
  String get notifStatsByRule => 'Reminders';

  @override
  String get notifStatsBySection => 'Sections';

  @override
  String notifStatsDays(int days) {
    return '$days d';
  }

  @override
  String notifStatsDeferred(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deferred by quiet hours',
      one: '1 deferred by quiet hours',
    );
    return '$_temp0';
  }

  @override
  String notifStatsDelivered(int count) {
    return '$count delivered';
  }

  @override
  String get notifStatsEffective => 'followed within an hour';

  @override
  String get notifStatsEmpty => 'No notifications in this period.';

  @override
  String get notifStatsEntry => 'Statistics';

  @override
  String get notifStatsIgnored => 'ignored';

  @override
  String get notifStatsLate => 'late';

  @override
  String notifStatsMedian(int minutes) {
    return 'acted after $minutes min (median)';
  }

  @override
  String get notifStatsMuteWeek => 'Mute for a week';

  @override
  String notifStatsNoisy(int percent) {
    return 'You ignore $percent % of this reminder — mute or change it?';
  }

  @override
  String notifStatsOpened(int count) {
    return '$count opened';
  }

  @override
  String notifStatsSince(String date) {
    return 'Since $date';
  }

  @override
  String get notifStatsTitle => 'Notification statistics';

  @override
  String get notifStatsTurnOff => 'Turn it off';

  @override
  String get notifStatusBlocked => 'blocked';

  @override
  String get notifStatusCancelled => 'cancelled';

  @override
  String get notifStatusCompleted => 'completed';

  @override
  String get notifStatusDone => 'done';

  @override
  String get notifStatusInProgress => 'in progress';

  @override
  String get notifStatusMissed => 'missed';

  @override
  String get notifStatusOngoing => 'ongoing';

  @override
  String get notifStatusScheduled => 'scheduled';

  @override
  String get notifStatusSkipped => 'skipped';

  @override
  String get notifStatusTodo => 'to do';

  @override
  String get notifStatusWaiting => 'waiting';

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
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
    return '$_temp0 after at $time';
  }

  @override
  String notifSumDaysBefore(int days, String time) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
    return '$_temp0 before at $time';
  }

  @override
  String notifSumInactivity(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
    return 'After $_temp0 without activity';
  }

  @override
  String get notifSumListReset => 'When the list resets';

  @override
  String notifSumListResetAt(String time) {
    return 'When the list resets (not before $time)';
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
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
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
  String get notifSumTimerEnd => 'When the timer reaches the planned end';

  @override
  String get notifSumUnknown => 'Unsupported rule';

  @override
  String get notifSumUpNextAtEnd => 'At the end: what\'s up next';

  @override
  String notifSumUpNextBefore(int minutes) {
    return '$minutes min before the next task';
  }

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
  String get notifTriggerListReset => 'List reset';

  @override
  String get notifTriggerMilestone => 'Milestone';

  @override
  String get notifTriggerNotDoneBy => 'If not done by';

  @override
  String get notifTriggerOverdue => 'Overdue';

  @override
  String get notifTriggerQuitRitual => 'Quit ritual';

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
  String get notifTriggerTimerEnd => 'Timer end';

  @override
  String get notifTriggerUpNext => 'Up next';

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
  String get onboardingClock => 'Clock';

  @override
  String get onboardingClock12 => '12-hour';

  @override
  String get onboardingClock24 => '24-hour';

  @override
  String get onboardingEssentialsBody =>
      'We picked these from your device. Adjust anything that\'s off — you can change them later in Settings › Regional.';

  @override
  String get onboardingEssentialsTitle => 'Your week, your clock';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingLanguage => 'Language';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingTimeZone => 'Home time zone';

  @override
  String get onboardingTitle => 'Set up Everslot';

  @override
  String get onboardingWeekStart => 'Week starts on';

  @override
  String get pickerColor => 'Color';

  @override
  String get pickerCustomColor => 'Custom color';

  @override
  String get pickerDate => 'Date';

  @override
  String get pickerDays => 'Days';

  @override
  String get pickerDuration => 'Duration';

  @override
  String get pickerEnd => 'End';

  @override
  String get pickerHex => 'Hex code';

  @override
  String get pickerHexInvalid => 'Use 6 hex digits, like 3B82F6';

  @override
  String get pickerHours => 'Hours';

  @override
  String get pickerIcon => 'Icon';

  @override
  String get pickerLowContrast => 'Low contrast: this color is hard to see on the background.';

  @override
  String get pickerMinutes => 'Minutes';

  @override
  String get pickerNextMonth => 'Next month';

  @override
  String get pickerNextWeek => 'Next week';

  @override
  String get pickerNoColor => 'No color';

  @override
  String get pickerPreviousMonth => 'Previous month';

  @override
  String get pickerSearchIcons => 'Search icons';

  @override
  String get pickerStart => 'Start';

  @override
  String get pickerTime => 'Time';

  @override
  String get pickerTimeInvalid => 'Enter a time like 07:03';

  @override
  String get pickerTimeRange => 'Time range';

  @override
  String get pickerTomorrow => 'Tomorrow';

  @override
  String get pickerTypeTime => 'Type a time';

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
  String get pvAddCountdown => 'Add a countdown';

  @override
  String get pvAddTask => 'Add task';

  @override
  String get pvAddToBacklog => 'Add to backlog';

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
  String get pvCannotUnschedule => 'Recurring occurrences can\'t be moved to the backlog';

  @override
  String get pvCapacity => 'Capacity';

  @override
  String get pvCategories => 'Categories';

  @override
  String get pvChecklistDue => 'List items with a due date';

  @override
  String get pvClearFilters => 'Clear';

  @override
  String get pvClearPlace => 'Remove the map pin';

  @override
  String get pvClearSelection => 'Clear selection';

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
  String pvCopied(String title) {
    return 'Copied “$title”';
  }

  @override
  String get pvCopy => 'Copy';

  @override
  String pvCopySuffix(String name) {
    return '$name (copy)';
  }

  @override
  String get pvCountdownSince => 'Count up since it';

  @override
  String get pvCountdownUntil => 'Count down to it';

  @override
  String pvCounterParts(int days, int hours, int minutes) {
    return '$days d $hours h $minutes min';
  }

  @override
  String get pvCreate => 'Create';

  @override
  String get pvCreateHere => 'Create here';

  @override
  String get pvCreatedSnack => 'Task created';

  @override
  String pvCurrentSize(String size) {
    return 'Current: $size';
  }

  @override
  String pvDayHeaderSemantics(String day, String items) {
    return '$day, $items';
  }

  @override
  String pvDayOverbooked(String duration) {
    return 'Overbooked by $duration';
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
  String pvDayUtilizationExplain(String planned, String capacity) {
    return '$planned planned for $capacity of work hours';
  }

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
  String get pvDisplay => 'Display';

  @override
  String get pvDoneTotal => 'Done';

  @override
  String get pvDragToSchedule => 'Drag onto the grid to schedule';

  @override
  String get pvDropNotSupported => 'This grouping can\'t be changed by dragging yet';

  @override
  String get pvDroppedPin => 'Dropped pin';

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
  String pvExtendedSnack(int minutes) {
    return 'Extended by $minutes min';
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
  String get pvFollowWorkHours => 'Use my work hours';

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
  String get pvGoalLinked => 'Linked to a goal';

  @override
  String get pvGotIt => 'Got it';

  @override
  String get pvGroupBy => 'Group by';

  @override
  String get pvGroupCalendar => 'Calendar views';

  @override
  String get pvGroupCategory => 'Category';

  @override
  String get pvGroupDay => 'Day';

  @override
  String get pvGroupDeadline => 'Deadline';

  @override
  String get pvGroupNone => 'None';

  @override
  String get pvGroupPriority => 'Priority';

  @override
  String get pvGroupProductivity => 'Focus & productivity';

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
  String get pvHintPinch => 'Pinch to zoom; pinch sideways to change the number of days';

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
  String get pvHorizonsHint => 'Unscheduled intentions per horizon — drag them to another horizon or onto a day.';

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
  String get pvLaneOther => 'Other';

  @override
  String get pvLanes => 'Lanes';

  @override
  String get pvLanesHint => 'Pick the categories shown side by side and their order.';

  @override
  String pvLastRowShort(String duration) {
    return 'the last one $duration';
  }

  @override
  String get pvLayout => 'Layout';

  @override
  String get pvLess => 'Less';

  @override
  String get pvListBelow => 'List below';

  @override
  String get pvListMode => 'Accessible list';

  @override
  String get pvLoadThresholds => 'Load tint (busy · over)';

  @override
  String get pvMakeGoal => 'Make it a goal';

  @override
  String get pvMapAttribution => '© OpenStreetMap contributors';

  @override
  String get pvMapPlaceholder => 'Give a task a place (task editor → find a place) to see it on the map.';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count more items', one: '1 more item');
    return '$_temp0';
  }

  @override
  String get pvMoreLegend => 'More';

  @override
  String get pvMoreOptions => 'More options';

  @override
  String get pvMove => 'Move';

  @override
  String get pvMoveDoneBody => 'It\'s already done — moving it changes its history.';

  @override
  String get pvMoveDoneTitle => 'Move a completed task?';

  @override
  String get pvMoveDown => 'Move down';

  @override
  String pvMoveEarlier(int minutes) {
    return 'Move $minutes min earlier';
  }

  @override
  String pvMoveLater(int minutes) {
    return 'Move $minutes min later';
  }

  @override
  String get pvMoveNextDay => 'Move to the next day';

  @override
  String get pvMovePreviousDay => 'Move to the previous day';

  @override
  String get pvMoveTo => 'Move to…';

  @override
  String get pvMoveUnfinishedTomorrow => 'Move unfinished to tomorrow';

  @override
  String get pvMoveUp => 'Move up';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Next $count days', one: 'Next day');
    return '$_temp0';
  }

  @override
  String get pvNextUp => 'Next up';

  @override
  String get pvNextWeek => 'Next week';

  @override
  String get pvNoCategory => 'No category';

  @override
  String get pvNoCountdowns => 'No countdowns yet';

  @override
  String get pvNoDeadline => 'No deadline';

  @override
  String get pvNoEstimate => 'No estimate';

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
  String get pvNoSavedViews => 'No saved views yet';

  @override
  String get pvNoTasks => 'No tasks';

  @override
  String get pvNothingNext => 'Nothing else planned today';

  @override
  String get pvNothingNow => 'Nothing scheduled right now';

  @override
  String get pvNothingToPaste => 'Copy a task first';

  @override
  String get pvNow => 'Now';

  @override
  String get pvOneOff => 'One-off';

  @override
  String get pvOpenDay => 'Open day';

  @override
  String get pvOpenPlannerInsights => 'Open Planner Insights';

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
  String get pvOverlayOccupancy => 'Slot occupancy (last 4 weeks)';

  @override
  String get pvOverlayUtilization => 'Day utilization';

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
  String pvPasted(String time) {
    return 'Pasted at $time';
  }

  @override
  String get pvPause => 'Pause';

  @override
  String get pvPickDate => 'Pick a date';

  @override
  String get pvPickPlace => 'Find a place';

  @override
  String get pvPin => 'Pin';

  @override
  String get pvPinned => 'Pinned';

  @override
  String pvPixels(String value) {
    return '$value px';
  }

  @override
  String get pvPlaceNoResults => 'No place found';

  @override
  String get pvPlaceSearchHint => 'Address or place name';

  @override
  String get pvPlaceTapHint => 'Or tap the map to drop a pin.';

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
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes minutes', one: '1 minute');
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
  String pvQuotaProgress(String title, int done, int total) {
    return '$title · $done/$total this period';
  }

  @override
  String get pvQuotaSlots => 'Targets to place';

  @override
  String get pvRadial12 => '12 h';

  @override
  String get pvRadial24 => '24 h';

  @override
  String get pvRadialHours => 'Dial';

  @override
  String get pvRecurring => 'Recurring';

  @override
  String get pvRemoveCountdown => 'Remove from countdowns';

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
  String pvScheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items scheduled',
      one: '1 item scheduled',
    );
    return '$_temp0';
  }

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
  String get pvSelect => 'Select';

  @override
  String pvSelected(int count) {
    return '$count selected';
  }

  @override
  String get pvSelectionActions => 'Actions';

  @override
  String pvSeriesPreview(String adherence, String streak) {
    return '$adherence done · streak $streak';
  }

  @override
  String get pvSetAsPlanDefault => 'Open the Plan tab on this view';

  @override
  String get pvSetDefaultView => 'Set as default';

  @override
  String get pvShareAvailability => 'Share availability';

  @override
  String get pvShowAsTimeline => 'Show as timeline rows';

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
  String get pvTags => 'Tags';

  @override
  String get pvTextFilterHint => 'Search titles and notes';

  @override
  String pvTileSemantics(String title, String day, String start, String end, String status) {
    return '$title, $day, $start to $end, $status';
  }

  @override
  String pvTimeLeft(String duration) {
    return '$duration left';
  }

  @override
  String get pvTo => 'To';

  @override
  String get pvToggleBacklog => 'Backlog drawer';

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
  String get pvUnscheduleUnsupported => 'Moving tasks back to the backlog isn\'t available yet';

  @override
  String get pvUnscheduled => 'Unscheduled';

  @override
  String get pvUnscheduledSnack => 'Moved to the backlog';

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
  String get pvUsePlace => 'Use this place';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count weeks', one: '1 week');
    return '$_temp0';
  }

  @override
  String get pvWithPlace => 'Tasks with a place';

  @override
  String get pvWorkDaysOnly => 'Work days only';

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
  String get quitAddUse => '+1';

  @override
  String get quitAllClocks => 'All clocks';

  @override
  String get quitAmount => 'Amount';

  @override
  String get quitAutoSuccess => 'Days without a relapse count as clean';

  @override
  String get quitAutoSuccessHint => 'Off: confirm each clean day in the evening review.';

  @override
  String get quitBaseline => 'Before quitting, per day';

  @override
  String quitBreathCycle(int cycle) {
    return 'Cycle $cycle';
  }

  @override
  String get quitBreathHold => 'Hold';

  @override
  String get quitBreathIn => 'Breathe in';

  @override
  String get quitBreathOut => 'Breathe out';

  @override
  String quitBreathPhase(String phase, int seconds) {
    return '$phase · $seconds';
  }

  @override
  String get quitBreathing478 => '4-7-8';

  @override
  String get quitBreathingBox => 'Box 4-4-4-4';

  @override
  String get quitBreathingStart => 'Start';

  @override
  String get quitBreathingStop => 'Stop';

  @override
  String get quitBreathingTitle => 'Breathing';

  @override
  String quitCleanDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clean days',
      one: '1 clean day',
      zero: '0 clean days',
    );
    return '$_temp0';
  }

  @override
  String get quitCleanDaysTitle => 'Clean days';

  @override
  String get quitCleanSaved => 'Marked as a clean day';

  @override
  String get quitCoping => 'What helped';

  @override
  String get quitCopingBreathing => 'Deep breathing';

  @override
  String get quitCopingCallFriend => 'Call a friend';

  @override
  String get quitCopingDelay10 => 'Wait 10 minutes';

  @override
  String get quitCopingGum => 'Chewing gum';

  @override
  String get quitCopingWalk => 'A walk';

  @override
  String get quitCopingWater => 'Glass of water';

  @override
  String quitCostPerUnit(String price) {
    return '= $price per unit';
  }

  @override
  String get quitCostTitle => 'Cost';

  @override
  String quitCounterSemantics(int days, int hours, int minutes) {
    return '$days days $hours hours $minutes minutes';
  }

  @override
  String get quitCravingDetails => 'Add details';

  @override
  String get quitCravingLogged => 'Craving logged — well done for noticing it.';

  @override
  String get quitCravingTitle => 'Craving';

  @override
  String get quitCurrency => 'Currency';

  @override
  String get quitDailyLimit => 'Daily limit';

  @override
  String get quitDayMilestonesTitle => 'Clean time';

  @override
  String quitDaysHours(int days, int hours) {
    return '$days d $hours h';
  }

  @override
  String get quitDistractionExercise => 'Exercise';

  @override
  String get quitDistractionGame => 'A quick game';

  @override
  String get quitDistractionMusic => 'Music';

  @override
  String get quitDistractionRead => 'Read';

  @override
  String get quitDistractionShower => 'A shower';

  @override
  String get quitDistractionSnack => 'A healthy snack';

  @override
  String get quitDistractionsEmpty => 'Add distractions that work for you in the libraries.';

  @override
  String get quitDistractionsTitle => 'Distractions';

  @override
  String get quitDuration => 'Duration';

  @override
  String get quitEditorEditTitle => 'Edit quit tracker';

  @override
  String get quitEditorNewTitle => 'New quit tracker';

  @override
  String get quitErrCurrency => 'Use a 3-letter currency code (e.g. EUR)';

  @override
  String get quitErrDailyLimit => 'Set a daily limit of 0 or more';

  @override
  String get quitErrNegative => 'Values cannot be negative';

  @override
  String get quitErrStartInFuture => 'The quit date cannot be in the future';

  @override
  String get quitEstimatesNote => 'All defaults are estimates — adjust them to you.';

  @override
  String quitEventCraving(int intensity) {
    return 'Craving · intensity $intensity';
  }

  @override
  String get quitEventPledge => 'Daily pledge';

  @override
  String get quitEventRelapse => 'Relapse';

  @override
  String get quitEventRestart => 'New quit attempt';

  @override
  String get quitHealthTitle => 'Health recovery';

  @override
  String quitIntensity(int value) {
    return 'Intensity: $value/10';
  }

  @override
  String get quitLifePerUnit => 'Life expectancy per unit';

  @override
  String get quitLifeRegained => 'Life regained';

  @override
  String get quitLogCraving => 'Log craving';

  @override
  String get quitLogRelapse => 'Log relapse';

  @override
  String get quitLogUse => 'Log use';

  @override
  String get quitLongest => 'Longest streak';

  @override
  String get quitManualReset => 'manual reset';

  @override
  String quitMilestoneDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days clean', one: '1 day clean');
    return '$_temp0';
  }

  @override
  String quitMilestoneElapsed(String percent) {
    return '$percent of the time elapsed';
  }

  @override
  String quitMilestoneEta(String date) {
    return 'Expected $date';
  }

  @override
  String quitMilestoneInWindow(String date) {
    return 'Happening now · until about $date';
  }

  @override
  String quitMilestoneReachedOn(String date) {
    return 'Reached $date';
  }

  @override
  String get quitMilestoneSources => 'Sources';

  @override
  String get quitMilestonesClockNote => 'Milestones count from your last lapse, so the clock restarts after one.';

  @override
  String get quitMilestonesOpen => 'All milestones';

  @override
  String get quitMilestonesReached => 'Reached';

  @override
  String get quitMilestonesTitle => 'Milestones';

  @override
  String get quitMilestonesUpcoming => 'Upcoming';

  @override
  String get quitModeAbstain => 'Quit completely';

  @override
  String get quitModeReduce => 'Cut down';

  @override
  String get quitModeTitle => 'Goal';

  @override
  String get quitMoneySaved => 'Money saved';

  @override
  String get quitMotivation => 'Why I am quitting';

  @override
  String get quitMotivationCard => 'My reasons';

  @override
  String get quitMotivationHint => 'My reasons…';

  @override
  String get quitNameAlcohol => 'Stop drinking';

  @override
  String get quitNameCaffeine => 'Less caffeine';

  @override
  String get quitNameCannabis => 'Stop cannabis';

  @override
  String get quitNameCigarettes => 'Stop smoking';

  @override
  String get quitNameGaming => 'Less gaming';

  @override
  String get quitNameOther => 'Quit a habit';

  @override
  String get quitNameSocialMedia => 'Less social media';

  @override
  String get quitNameSugar => 'Stop sugar';

  @override
  String get quitNameVape => 'Stop vaping';

  @override
  String get quitNextMilestone => 'Next milestone';

  @override
  String get quitNo => 'No';

  @override
  String get quitNoEvents => 'Nothing logged yet — keep going!';

  @override
  String get quitNoTrackers => 'No quit tracker yet';

  @override
  String get quitNoTrackersBody => 'Track how long you have stopped smoking, drinking or anything else.';

  @override
  String get quitNotSure => 'Not sure';

  @override
  String get quitNote => 'Note';

  @override
  String quitNotifGoalMilestone(String title, String what) {
    return '$title — $what';
  }

  @override
  String get quitNotifInvalidIntensity => 'Intensity is a number from 1 to 10.';

  @override
  String quitNotifMoneyMilestone(String amount) {
    return '$amount saved';
  }

  @override
  String quitNotifUnitsMilestone(String amount, String unit) {
    return '$amount $unit avoided';
  }

  @override
  String quitOffsetMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count months', one: '1 month');
    return '$_temp0';
  }

  @override
  String quitOffsetRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String quitOffsetWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count weeks', one: '1 week');
    return '$_temp0';
  }

  @override
  String quitOffsetYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count years', one: '1 year');
    return '$_temp0';
  }

  @override
  String get quitOther => 'Other…';

  @override
  String get quitOverLimit => 'Over today\'s limit';

  @override
  String get quitPackPrice => 'Pack price';

  @override
  String get quitPhotoAfterSave => 'You can add a motivating photo after saving.';

  @override
  String get quitPlace => 'Place';

  @override
  String get quitPlaceBar => 'Bar';

  @override
  String get quitPlaceCar => 'Car';

  @override
  String get quitPlaceFriends => 'At friends\'';

  @override
  String get quitPlaceHome => 'Home';

  @override
  String get quitPlaceOutside => 'Outside';

  @override
  String get quitPlaceWork => 'Work';

  @override
  String get quitPledgeAction => 'Take today\'s pledge';

  @override
  String get quitPledgeMorning => 'Morning pledge';

  @override
  String get quitPledgeSaved => 'Pledge saved';

  @override
  String quitPledgeStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day pledge streak',
      one: '1-day pledge streak',
    );
    return '$_temp0';
  }

  @override
  String get quitPledgeText => 'Today, I choose to stay clean.';

  @override
  String get quitPledged => 'Pledged for today';

  @override
  String get quitPopulationEstimate => 'population estimate';

  @override
  String get quitPopulationEstimateHelp =>
      'Population estimate: about 20 min per cigarette (Jackson et al. 2025; BMJ 2000: 11 min). Individual effects vary.';

  @override
  String get quitPresetAlcohol => 'Alcohol';

  @override
  String get quitPresetCaffeine => 'Caffeine';

  @override
  String get quitPresetCannabis => 'Cannabis';

  @override
  String get quitPresetCigarettes => 'Smoking';

  @override
  String get quitPresetGaming => 'Gaming';

  @override
  String get quitPresetOther => 'Something else';

  @override
  String get quitPresetSocialMedia => 'Social media';

  @override
  String get quitPresetSugar => 'Sugar';

  @override
  String get quitPresetTitle => 'What do you want to quit?';

  @override
  String get quitPresetVape => 'Vaping';

  @override
  String get quitRecentEvents => 'Recent events';

  @override
  String get quitRelapseAmount => 'How many? (optional)';

  @override
  String get quitRelapseKindTitle => 'How should it count?';

  @override
  String quitRelapseNewAttempt(String time) {
    return 'Start a new quit attempt from $time';
  }

  @override
  String get quitRelapseSaved => 'Logged. Be kind to yourself — every attempt teaches you something.';

  @override
  String get quitRelapseSlip => 'As a slip — keep my quit date; the streak restarts now';

  @override
  String quitRelapseSupport(String duration) {
    return 'You stayed clean for $duration — that still counts.';
  }

  @override
  String get quitRelapseTitle => 'Log a relapse';

  @override
  String get quitResetBody => 'This logs a relapse now. Your quit date stays the same.';

  @override
  String get quitResetCounter => 'Reset counter';

  @override
  String get quitResisted => 'Did you resist?';

  @override
  String get quitReviewEvening => 'Evening review';

  @override
  String get quitReviewQuestion => 'Did you stay clean today?';

  @override
  String get quitReviewYesterdayQuestion => 'Did you stay clean yesterday?';

  @override
  String get quitReviewedClean => 'Clean today — well done!';

  @override
  String get quitRewardAdd => 'Add a reward';

  @override
  String get quitRewardClaim => 'Claim';

  @override
  String quitRewardClaimed(String date) {
    return 'Claimed $date';
  }

  @override
  String get quitRewardClaimedSnack => 'Enjoy it — you earned it.';

  @override
  String quitRewardEta(String date) {
    return 'Affordable around $date';
  }

  @override
  String get quitRewardName => 'Reward';

  @override
  String get quitRewardNeedsCost => 'Set a price per unit in the tracker to see what your savings buy.';

  @override
  String get quitRewardPrice => 'Price';

  @override
  String get quitRewardReady => 'You can afford it!';

  @override
  String get quitRewardSaved => 'Reward saved';

  @override
  String get quitRewardsEmpty => 'Pick something your savings will pay for.';

  @override
  String get quitRewardsTitle => 'What my savings buy';

  @override
  String get quitRitualEnable => 'Daily pledge & evening review';

  @override
  String get quitRitualEnableHint =>
      'A morning pledge and an evening check-in. Add reminders at these times in the Reminders section.';

  @override
  String get quitRitualTitle => 'Daily ritual';

  @override
  String get quitSinceFirstQuit => 'Since you first quit';

  @override
  String get quitSinceLastRelapse => 'Clean for';

  @override
  String get quitSinceLastUse => 'Since the last use';

  @override
  String get quitStartedAt => 'I quit on';

  @override
  String get quitTimePerUnit => 'Time spent per unit';

  @override
  String get quitTimeWonBack => 'Time won back';

  @override
  String quitTodayUse(String used, String limit) {
    return '$used of $limit today';
  }

  @override
  String get quitToolboxDone => 'Three minutes done — did you resist?';

  @override
  String get quitToolboxLogged => 'Craving logged with its duration.';

  @override
  String get quitToolboxOpen => 'Open the coping toolbox';

  @override
  String quitToolboxRemaining(String time) {
    return '$time left';
  }

  @override
  String get quitToolboxStart => 'Start the 3-minute timer';

  @override
  String get quitToolboxThrough => 'I\'m through it';

  @override
  String get quitToolboxTimerHint => 'Most cravings pass within 3 to 5 minutes. Stay with it.';

  @override
  String get quitToolboxTimerTitle => 'Ride out the craving';

  @override
  String get quitToolboxTitle => 'Coping toolbox';

  @override
  String get quitTrigger => 'Trigger';

  @override
  String get quitTriggerAfterMeals => 'After meals';

  @override
  String get quitTriggerAlcohol => 'Alcohol';

  @override
  String get quitTriggerBoredom => 'Boredom';

  @override
  String get quitTriggerCoffee => 'Coffee';

  @override
  String get quitTriggerDriving => 'Driving';

  @override
  String get quitTriggerPhone => 'Phone';

  @override
  String get quitTriggerSocial => 'Social situations';

  @override
  String get quitTriggerStress => 'Stress';

  @override
  String get quitTriggerWakingUp => 'Waking up';

  @override
  String get quitTriggerWorkBreak => 'Work break';

  @override
  String get quitUnitCost => 'Price per unit';

  @override
  String get quitUnitDays => 'd';

  @override
  String get quitUnitHours => 'h';

  @override
  String get quitUnitMinutes => 'min';

  @override
  String get quitUnitSeconds => 's';

  @override
  String get quitUnitsAvoided => 'Avoided';

  @override
  String get quitUnitsPerPack => 'Units per pack';

  @override
  String get quitUseLogged => 'Use logged';

  @override
  String get quitVocabAdd => 'Add an entry';

  @override
  String get quitVocabCoping => 'Coping';

  @override
  String get quitVocabDistractions => 'Distractions';

  @override
  String get quitVocabEmpty => 'Nothing here yet — add your own.';

  @override
  String get quitVocabName => 'Name';

  @override
  String get quitVocabPlaces => 'Places';

  @override
  String get quitVocabRename => 'Rename';

  @override
  String get quitVocabSaved => 'Library updated';

  @override
  String get quitVocabTitle => 'Triggers, places & coping';

  @override
  String get quitVocabTriggers => 'Triggers';

  @override
  String quitVocabUses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used $count times',
      one: 'Used once',
      zero: 'Not used yet',
    );
    return '$_temp0';
  }

  @override
  String get quitWhen => 'When';

  @override
  String get quitWithdrawalNow => 'Where you are now';

  @override
  String get quitWithdrawalTitle => 'Withdrawal';

  @override
  String get quitWithinLimitStreakTitle => 'Days within the limit';

  @override
  String get quitYes => 'Yes';

  @override
  String get recurAddDate => 'Add';

  @override
  String get recurAddOrdinal => 'Add a day like “2nd Tuesday”';

  @override
  String get recurAddTime => 'Add a time';

  @override
  String get recurAdvancedTitle => 'Custom repeat';

  @override
  String get recurAfterHint => 'The next one is due this long after you complete the previous one.';

  @override
  String get recurAfterPreview => 'The next ones depend on when you complete it';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count times', one: '1 time');
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
  String get recurIssueCountAndUntil => 'Choose either an end date or a number of times';

  @override
  String get recurIssueDate => 'Invalid date';

  @override
  String get recurIssueEmptyWeekdays => 'Select at least one day';

  @override
  String get recurIssueInterval => 'The interval must be at least 1';

  @override
  String get recurIssueMissing => 'The rule is incomplete';

  @override
  String get recurIssueOrdinal => '“1st”, “last”… only work with monthly or yearly repeats';

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
  String get recurNumbersHint => 'Numbers separated by commas (negative = from the end)';

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
  String get recurSetPosHint => '1 = first, −1 = last matching date of each period';

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
  String get recurWarnAllDaySubDaily => 'All-day items can\'t repeat within a day';

  @override
  String get recurWarnDst => 'Some times fall in a daylight-saving change and are shifted';

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
  String get recurWindowAnchorSeries => 'Continue the chain from the first occurrence';

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
  String redoDoneSnack(String action) {
    return 'Redone: $action';
  }

  @override
  String get redoNothing => 'Nothing to redo';

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days ago', one: 'yesterday');
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count hours ago', one: '1 hour ago');
    return '$_temp0';
  }

  @override
  String relativeInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'in $count days', one: 'tomorrow');
    return '$_temp0';
  }

  @override
  String relativeInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'in $count hours', one: 'in 1 hour');
    return '$_temp0';
  }

  @override
  String relativeInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'in $count minutes', one: 'in 1 minute');
    return '$_temp0';
  }

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count minutes ago', one: '1 minute ago');
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
  String get repeatModeAll => 'Everything back to to-do';

  @override
  String get repeatModeCompleted => 'Uncheck completed items only';

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
  String get savedSnack => 'Saved';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutSubtitle => 'Version, licenses, help';

  @override
  String get settingsAccessibility => 'Accessibility';

  @override
  String get settingsAccessibilitySubtitle => 'Motion, haptics, contrast, labels';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsAccountLocalOnly => 'On this device only';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceSubtitle => 'Theme, density, language';

  @override
  String get settingsArabicDigits => 'Arabic-Indic digits';

  @override
  String get settingsArabicDigitsSubtitle => 'Show ٠١٢٣ instead of 0123 when the app is in Arabic';

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
  String get settingsClock => 'Clock';

  @override
  String get settingsClock12 => '12-hour';

  @override
  String get settingsClock24 => '24-hour';

  @override
  String get settingsCompleteChildren => 'When completing a parent';

  @override
  String get settingsCurrency => 'Currency for quit savings';

  @override
  String get settingsCurrentZone => 'Current time zone (this device)';

  @override
  String get settingsDataSubtitle => 'Back up, restore or move your data';

  @override
  String get settingsDataTitle => 'Export & import';

  @override
  String get settingsDayStart => 'Habit day starts at';

  @override
  String get settingsDayStartSubtitle =>
      'Check-ins before this time count for the previous day. Applies to new check-ins only.';

  @override
  String get settingsDefaultOpen => 'Open in';

  @override
  String get settingsDefaultsHint => 'Defaults for new items. Existing items keep their own settings.';

  @override
  String get settingsDensity => 'Density';

  @override
  String get settingsDensityComfortable => 'Comfortable';

  @override
  String get settingsDensityCompact => 'Compact';

  @override
  String settingsDeviceLastSeen(String when) {
    return 'Last seen $when';
  }

  @override
  String get settingsDevicePushOff => 'Push notifications off';

  @override
  String get settingsDevicePushOn => 'Push notifications on';

  @override
  String get settingsDeviceRevoke => 'Remove device';

  @override
  String get settingsDeviceRevokeBody =>
      'It stops receiving notifications and is signed out the next time it connects.';

  @override
  String settingsDeviceRevokeTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get settingsDeviceRevoked => 'Device removed';

  @override
  String get settingsDeviceThis => 'This device';

  @override
  String get settingsDeviceUnknown => 'Unknown device';

  @override
  String get settingsDevices => 'Devices';

  @override
  String get settingsDevicesEmpty => 'No devices registered yet.';

  @override
  String get settingsDevicesOffline => 'Connect to the internet to see your devices.';

  @override
  String get settingsDynamicColor => 'Wallpaper colors';

  @override
  String get settingsDynamicColorSubtitle => 'Use your device\'s Material You colors. Category colors stay the same.';

  @override
  String get settingsExportAttachments => 'Include attachment files';

  @override
  String get settingsExportAttachmentsHint => 'Only files already on this device.';

  @override
  String get settingsExportBody => 'A copy of all your data on this device. Works offline.';

  @override
  String get settingsExportButton => 'Export';

  @override
  String get settingsExportCsv => 'Spreadsheets (CSV)';

  @override
  String get settingsExportCsvHint => 'One file per table for Excel, Numbers or Sheets.';

  @override
  String settingsExportDone(String file) {
    return 'Export ready: $file';
  }

  @override
  String get settingsExportFailed => 'The export failed. Please try again.';

  @override
  String get settingsExportJson => 'Everslot backup (JSON)';

  @override
  String get settingsExportJsonHint => 'A complete copy you can import again.';

  @override
  String settingsExportProgress(int percent) {
    return 'Exporting… $percent%';
  }

  @override
  String get settingsExportShareSubject => 'Everslot export';

  @override
  String get settingsExportTitle => 'Export';

  @override
  String get settingsFewer => 'One fewer';

  @override
  String get settingsGroupData => 'Data & privacy';

  @override
  String get settingsGroupGeneral => 'General';

  @override
  String get settingsGroupHelp => 'Help';

  @override
  String get settingsGroupSections => 'Sections';

  @override
  String get settingsHabits => 'Habits';

  @override
  String settingsHabitsDayStartLink(String time) {
    return 'Day starts at $time';
  }

  @override
  String get settingsHabitsFreezes => 'Streak freezes per month';

  @override
  String get settingsHabitsFreezesHint => 'Missed days forgiven each month for new habits.';

  @override
  String get settingsHabitsSkipBreaks => 'Break the streak';

  @override
  String get settingsHabitsSkipNeutral => 'Don\'t affect the streak';

  @override
  String get settingsHabitsSkipPolicy => 'Skipped days';

  @override
  String get settingsHabitsSubtitle => 'Skip policy, streak freezes';

  @override
  String get settingsHideCheckboxes => 'Hide checkboxes (bullets)';

  @override
  String get settingsHomeZone => 'Home time zone';

  @override
  String get settingsHomeZoneAuto => 'Follow this device';

  @override
  String get settingsHomeZoneAutoSubtitle => 'Update the home zone automatically when you travel';

  @override
  String get settingsHomeZoneSubtitle => 'Fixed-time tasks and habits use this zone';

  @override
  String get settingsInsights => 'Insights';

  @override
  String get settingsInsightsCompare => 'Compare with the previous period';

  @override
  String get settingsInsightsGamification => 'XP and levels';

  @override
  String get settingsInsightsGamificationHint => 'Earn XP for what you complete (off by default).';

  @override
  String settingsInsightsHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count hours', one: '1 hour');
    return '$_temp0';
  }

  @override
  String get settingsInsightsPeriod => 'Default period';

  @override
  String get settingsInsightsSubtitle => 'Default period, comparisons';

  @override
  String get settingsInsightsWakingHours => 'Waking hours';

  @override
  String get settingsInsightsWeekStart => 'Week starts on (insights)';

  @override
  String settingsInsightsWeekStartProfile(String day) {
    return 'Same as the app ($day)';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLists => 'Lists';

  @override
  String get settingsListsAutoComplete => 'Complete parents automatically';

  @override
  String get settingsListsAutoCompleteHint => 'A parent is done when all its sub-items are done.';

  @override
  String get settingsListsCompletedBottom => 'Move completed items to the bottom';

  @override
  String get settingsListsProgress => 'Progress counts';

  @override
  String get settingsListsProgressChildren => 'Direct sub-items';

  @override
  String get settingsListsProgressLeaves => 'Every item';

  @override
  String get settingsListsRequireReason => 'Ask for a reason when an item is';

  @override
  String get settingsListsShowCompleted => 'Show completed items';

  @override
  String get settingsListsSubtitle => 'Statuses, progress, completed items';

  @override
  String get settingsMore => 'One more';

  @override
  String get settingsNotificationsSubtitle => 'Reminders, quiet hours, inbox';

  @override
  String get settingsOrganizationSubtitle => 'Categories and tags used across the app';

  @override
  String get settingsPeriodLastMonth => 'Last month';

  @override
  String get settingsPeriodLastWeek => 'Last week';

  @override
  String settingsPeriodRolling(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: 'Last $days days', one: 'Last day');
    return '$_temp0';
  }

  @override
  String get settingsPeriodThisMonth => 'This month';

  @override
  String get settingsPeriodThisQuarter => 'This quarter';

  @override
  String get settingsPeriodThisWeek => 'This week';

  @override
  String get settingsPeriodThisYear => 'This year';

  @override
  String get settingsPlan => 'Plan';

  @override
  String get settingsPlanActualAlways => 'Always';

  @override
  String get settingsPlanActualNever => 'Never';

  @override
  String get settingsPlanActualOffSchedule => 'When off schedule';

  @override
  String get settingsPlanActualTime => 'Ask for the actual time when done';

  @override
  String get settingsPlanDefaultDuration => 'Default task duration';

  @override
  String get settingsPlanDefaultView => 'Default view';

  @override
  String get settingsPlanDefaultViewNone => 'Week table';

  @override
  String get settingsPlanGrace => 'Missed after';

  @override
  String settingsPlanGraceValue(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes after the end',
      one: '1 minute after the end',
      zero: 'As soon as it ends',
    );
    return '$_temp0';
  }

  @override
  String get settingsPlanRollOver => 'Unfinished tasks';

  @override
  String get settingsPlanRollOverAsk => 'Ask me';

  @override
  String get settingsPlanRollOverAuto => 'Move to today';

  @override
  String get settingsPlanRollOverOff => 'Leave them';

  @override
  String get settingsPlanSubtitle => 'Default view, durations, work hours';

  @override
  String get settingsPlanTracking => 'Default tracking';

  @override
  String get settingsPlanTrackingCheck => 'Check off';

  @override
  String get settingsPlanTrackingEvent => 'Event';

  @override
  String get settingsPlanTrackingTimer => 'Timer';

  @override
  String get settingsPlanWorkDays => 'Work days';

  @override
  String get settingsPlanWorkEnd => 'End';

  @override
  String get settingsPlanWorkHours => 'Work hours';

  @override
  String get settingsPlanWorkStart => 'Start';

  @override
  String get settingsPreview => 'Preview';

  @override
  String get settingsPrivacy => 'Privacy & security';

  @override
  String get settingsPrivacySubtitle => 'App lock, hidden notification content';

  @override
  String get settingsProgressChildren => 'Direct sub-items only';

  @override
  String get settingsProgressLeaves => 'All sub-items';

  @override
  String get settingsProgressMode => 'Progress counts';

  @override
  String get settingsRegional => 'Regional';

  @override
  String get settingsRegionalSubtitle => 'Time zone, week start, clock, currency';

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
  String get settingsSyncData => 'Sync & data';

  @override
  String get settingsSyncDataSubtitle => 'Devices, export, import, trash';

  @override
  String get settingsSyncDiagnostics => 'Sync diagnostics';

  @override
  String get settingsSyncDiscardBody => 'The server\'s version of these items is restored on this device.';

  @override
  String get settingsSyncDiscardFailed => 'Discard rejected changes';

  @override
  String get settingsSyncDiscardTitle => 'Discard rejected changes?';

  @override
  String settingsSyncFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes were rejected by the server',
      one: '1 change was rejected by the server',
    );
    return '$_temp0';
  }

  @override
  String settingsSyncInitialProgress(int percent) {
    return 'Downloading your data… $percent%';
  }

  @override
  String get settingsSyncLastError => 'Last error';

  @override
  String settingsSyncLastSuccess(String when) {
    return 'Last synced $when';
  }

  @override
  String get settingsSyncNever => 'Not synced yet';

  @override
  String get settingsSyncNow => 'Sync now';

  @override
  String get settingsSyncOffBody => 'Your data is stored on this device only.';

  @override
  String get settingsSyncOffTitle => 'Sync is off';

  @override
  String get settingsSyncRefreshLocalOnly => 'Everything is saved on this device.';

  @override
  String get settingsSyncResync => 'Force full resync';

  @override
  String get settingsSyncResyncBody =>
      'Everslot downloads all your data again. Changes that haven\'t synced yet are kept.';

  @override
  String get settingsSyncResyncTitle => 'Resync everything?';

  @override
  String get settingsSyncRetryFailed => 'Retry rejected changes';

  @override
  String get settingsSyncStatus => 'Status';

  @override
  String get settingsSyncTitle => 'Sync & devices';

  @override
  String get settingsSyncTooltip => 'Sync status';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTrash => 'Trash';

  @override
  String get settingsTrashDeleteForever => 'Delete forever';

  @override
  String get settingsTrashDeleteForeverBody =>
      'It will be removed from all your devices, with everything deleted with it. This can\'t be undone.';

  @override
  String settingsTrashDeleteForeverTitle(String title) {
    return 'Delete \"$title\" forever?';
  }

  @override
  String get settingsTrashDeleted => 'Deleted forever';

  @override
  String settingsTrashDeletedWhen(String when) {
    return 'Deleted $when';
  }

  @override
  String get settingsTrashEmptyAll => 'Empty trash';

  @override
  String settingsTrashEmptyAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items will be deleted forever from all your devices.',
      one: '1 item will be deleted forever from all your devices.',
    );
    return '$_temp0 This can\'t be undone.';
  }

  @override
  String get settingsTrashEmptyState => 'The trash is empty';

  @override
  String get settingsTrashHint =>
      'Deleted items stay here for 30 days. Restoring one brings back everything deleted with it.';

  @override
  String get settingsTrashKindAttachment => 'Attachment';

  @override
  String get settingsTrashKindChecklist => 'List';

  @override
  String get settingsTrashKindHabit => 'Habit';

  @override
  String get settingsTrashKindItem => 'List item';

  @override
  String get settingsTrashKindTask => 'Task';

  @override
  String get settingsTrashNotSynced => 'This deletion hasn\'t synced yet. Try again once you\'re online.';

  @override
  String get settingsTrashOffline => 'Connect to the internet to delete forever.';

  @override
  String get settingsTrashRestore => 'Restore';

  @override
  String get settingsTrashRestored => 'Restored';

  @override
  String get settingsTrashUntitled => 'Untitled';

  @override
  String settingsTrashWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count related items',
      one: '+1 related item',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnknownPage => 'This settings page doesn\'t exist.';

  @override
  String get settingsWeekStart => 'Week starts on';

  @override
  String get shellCreate => 'Create';

  @override
  String shellDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count to do', one: '1 to do');
    return '$_temp0';
  }

  @override
  String get shellQuickAdd => 'Quick add';

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
  String get statsCardError => 'This card couldn’t be computed.';

  @override
  String statsClustersEpisodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count times', one: '1 time');
    return '$_temp0';
  }

  @override
  String get statsClustersHint =>
      'Pick reasons that mean the same thing and give the group a name. Groups apply to every list.';

  @override
  String statsClustersIn(String name) {
    return 'in “$name”';
  }

  @override
  String get statsClustersMerge => 'Merge';

  @override
  String get statsClustersName => 'Group name';

  @override
  String get statsClustersOpen => 'Merge reasons';

  @override
  String get statsClustersTitle => 'Blocker clusters';

  @override
  String get statsClustersUnmerge => 'Remove from groups';

  @override
  String get statsCompareToggle => 'Compare with previous period';

  @override
  String get statsDashboardAddCard => 'Add card';

  @override
  String get statsDashboardCreate => 'Create';

  @override
  String get statsDashboardDefaultName => 'My dashboard';

  @override
  String get statsDashboardDelete => 'Delete dashboard';

  @override
  String get statsDashboardDeleted => 'Dashboard deleted';

  @override
  String get statsDashboardEmptyCards => 'Add cards from any section.';

  @override
  String get statsDashboardMetric => 'Metric';

  @override
  String get statsDashboardMoveDown => 'Move down';

  @override
  String get statsDashboardMoveUp => 'Move up';

  @override
  String get statsDashboardName => 'Name';

  @override
  String get statsDashboardNarrow => 'Half width';

  @override
  String get statsDashboardNew => 'New dashboard';

  @override
  String get statsDashboardPeriod => 'Period';

  @override
  String get statsDashboardRemoveCard => 'Remove card';

  @override
  String get statsDashboardRename => 'Rename';

  @override
  String get statsDashboardSave => 'Save';

  @override
  String get statsDashboardScope => 'Section';

  @override
  String get statsDashboardTracker => 'Tracker';

  @override
  String get statsDashboardWide => 'Full width';

  @override
  String get statsDashboardsEmpty => 'No dashboards yet';

  @override
  String get statsDashboardsEmptyBody => 'Compose your own view from any metric card.';

  @override
  String statsDayScoreVsMedian(String delta) {
    return '$delta vs your 28-day median';
  }

  @override
  String statsDetailAllTime(String value) {
    return 'All time: $value';
  }

  @override
  String statsDetailBacklog(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unscheduled tasks',
      one: '1 unscheduled task',
    );
    return '$_temp0';
  }

  @override
  String statsDetailBest(String value) {
    return 'Best: $value';
  }

  @override
  String statsDetailCoverage(String value) {
    return 'Time tracked on $value of done tasks';
  }

  @override
  String statsDetailDelta30(String value) {
    return '$value vs 30 days ago';
  }

  @override
  String statsDetailLastDone(String date) {
    return 'Last done $date';
  }

  @override
  String statsDetailOfTotal(String done, String total) {
    return '$done of $total';
  }

  @override
  String statsDetailOpen(String count) {
    return '$count open';
  }

  @override
  String statsDetailPerDay(String value) {
    return '$value per day';
  }

  @override
  String statsDetailPeriods(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count periods', one: '1 period');
    return '$_temp0';
  }

  @override
  String statsDetailPlanned(String value) {
    return 'Planned: $value';
  }

  @override
  String statsDetailQueue(String time) {
    return 'Waiting to start for $time';
  }

  @override
  String statsDetailReduction(String value) {
    return 'Down $value from baseline';
  }

  @override
  String statsDetailSince(String date) {
    return 'Since $date';
  }

  @override
  String statsDetailWorkItem(String time) {
    return 'In progress for $time';
  }

  @override
  String get statsDrillEmpty => 'Nothing to show';

  @override
  String statsDrillMore(String count) {
    return '$count more';
  }

  @override
  String get statsDrillTitle => 'Behind this number';

  @override
  String get statsEmptyHabits => 'Add a habit to follow your consistency.';

  @override
  String get statsEmptyLists => 'Create a list to see how work flows through it.';

  @override
  String get statsEmptyPlanner => 'Plan a few tasks and come back for insights.';

  @override
  String get statsEmptyQuit => 'No quit trackers yet';

  @override
  String get statsEmptyQuitBody => 'Create one in Habits to see your progress here.';

  @override
  String get statsEmptyTitle => 'Nothing to show yet';

  @override
  String statsExclusionCancelled(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cancelled occurrences',
      one: '1 cancelled occurrence',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionExcused(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count excused units',
      one: '1 excused unit',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionFrozen(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frozen units',
      one: '1 frozen unit',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionPaused(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paused units',
      one: '1 paused unit',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionSkipped(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skipped units',
      one: '1 skipped unit',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionUnknown(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unlogged days',
      one: '1 unlogged day',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionUnplanned(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unplanned additions',
      one: '1 unplanned addition',
    );
    return '$_temp0';
  }

  @override
  String get statsExplainEstimate => 'This number is an estimate.';

  @override
  String get statsExplainExcluded => 'Excluded';

  @override
  String get statsExplainFormula => 'How it’s computed';

  @override
  String get statsExplainGlossary => 'Metric glossary';

  @override
  String statsExplainId(String id) {
    return 'Metric $id';
  }

  @override
  String statsExplainInterval(String lower, String upper) {
    return '95 % interval: $lower – $upper';
  }

  @override
  String statsExplainIntervalRule(String count) {
    return 'A ± range is shown below $count units.';
  }

  @override
  String statsExplainMinData(String count) {
    return 'Shown once at least $count units exist.';
  }

  @override
  String get statsExplainNothingExcluded => 'Nothing excluded';

  @override
  String get statsExplainPopulation =>
      'Population estimate: harm is non-linear and varies between individuals; it is not a personal prediction.';

  @override
  String statsExplainPrevious(String value) {
    return 'Previous period: $value';
  }

  @override
  String statsExplainSample(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count units',
      one: 'Based on 1 unit',
    );
    return '$_temp0';
  }

  @override
  String get statsExplainSources => 'Sources';

  @override
  String get statsExplainThisView => 'In this view';

  @override
  String statsExplainValue(String value) {
    return 'Value: $value';
  }

  @override
  String get statsExplainWhat => 'What it measures';

  @override
  String get statsExportScope => 'Export data';

  @override
  String statsFeedBasedOn(String metric) {
    return 'Based on: $metric';
  }

  @override
  String get statsFeedDismiss => 'Dismiss';

  @override
  String get statsFeedEmpty => 'No insights yet';

  @override
  String get statsFeedEmptyBody => 'Insights appear as your data grows.';

  @override
  String get statsFeedMute => 'Mute this kind';

  @override
  String get statsFeedMutedSnack => 'Muted. You can unmute it from the insights feed.';

  @override
  String get statsFeedMutedTypes => 'Muted insight types';

  @override
  String get statsFeedOpen => 'Open';

  @override
  String get statsFeedSeeAll => 'See all insights';

  @override
  String get statsFeedUnmute => 'Unmute';

  @override
  String get statsFeedWhy => 'Why am I seeing this?';

  @override
  String get statsFilterApply => 'Apply';

  @override
  String get statsFilterCategories => 'Categories';

  @override
  String get statsFilterClear => 'Clear';

  @override
  String get statsFilterPriority => 'Priority';

  @override
  String get statsFilterTags => 'Tags';

  @override
  String get statsFilterTracking => 'Tracking';

  @override
  String get statsFilterTrackingCheck => 'Check';

  @override
  String get statsFilterTrackingEvent => 'Event';

  @override
  String get statsFilterTrackingTimer => 'Timer';

  @override
  String get statsFilters => 'Filters';

  @override
  String statsFiltersActive(num count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count filters', one: '1 filter');
    return '$_temp0';
  }

  @override
  String statsForecastLikely(String p50, String p85, String p95) {
    return 'Likely done by $p50 (50 %), $p85 (85 %) or $p95 (95 %) at your recent pace.';
  }

  @override
  String statsGlossaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count metrics', one: '1 metric');
    return '$_temp0';
  }

  @override
  String statsGlossaryEmpty(String query) {
    return 'No metric matches “$query”.';
  }

  @override
  String get statsGlossaryFormula => 'Formula';

  @override
  String get statsGlossarySearch => 'Search metrics';

  @override
  String get statsGlossaryTitle => 'Metric glossary';

  @override
  String get statsGuidanceLogFromNotifications => 'Log from the reminder notifications to improve accuracy.';

  @override
  String get statsGuidanceLogSameDay => 'Try to log on the same day — late entries are easy to misremember.';

  @override
  String get statsGuidanceSyncPending => 'Some changes from other devices may be missing until sync completes.';

  @override
  String get statsGuidanceTrackTime => 'Start the timer on tasks to see your actual hours.';

  @override
  String get statsGuidedArchive => 'Archive';

  @override
  String get statsGuidedBack => 'Back';

  @override
  String get statsGuidedCompleted => 'Review completed — see you next week!';

  @override
  String get statsGuidedDrop => 'Drop';

  @override
  String get statsGuidedFinish => 'Finish review';

  @override
  String get statsGuidedFollowUp => 'Follow up tomorrow';

  @override
  String get statsGuidedNext => 'Next';

  @override
  String get statsGuidedOpen => 'Open';

  @override
  String get statsGuidedPause => 'Pause 1 week';

  @override
  String get statsGuidedSkip => 'Skip';

  @override
  String get statsGuidedStepHabits => 'Check habits at risk';

  @override
  String statsGuidedStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get statsGuidedStepOverdue => 'Handle overdue tasks';

  @override
  String get statsGuidedStepRebalance => 'Rebalance next week';

  @override
  String get statsGuidedStepStale => 'Review stale lists';

  @override
  String get statsGuidedStepWaiting => 'Process waiting and blocked items';

  @override
  String get statsGuidedStepWins => 'Celebrate your wins';

  @override
  String get statsGuidedTomorrow => 'Tomorrow';

  @override
  String get statsGuidedUnblock => 'Unblock';

  @override
  String get statsGuidedUpdated => 'Updated';

  @override
  String get statsHealthClockNote => 'Milestones follow your current smoke-free time: the clock restarts after a slip.';

  @override
  String get statsHealthDisclaimer =>
      'Educational estimates based on population averages from WHO, NHS, CDC and the American Cancer Society; individual results vary. Not medical advice. Consult a healthcare professional.';

  @override
  String get statsHealthElapsedNote => 'Percentages show elapsed time only, not physiological measurements.';

  @override
  String statsHealthRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String statsInsightAtRisk(String name) {
    return '$name needs attention this week.';
  }

  @override
  String statsInsightBestWeekday(String weekday, String rate) {
    return 'Your habits go best on $weekday ($rate).';
  }

  @override
  String statsInsightBlockerCluster(int count, String reason) {
    return '$count items blocked on “$reason” in two weeks.';
  }

  @override
  String statsInsightComeback(String name) {
    return 'Welcome back to $name!';
  }

  @override
  String statsInsightCorrelationNeg(String a, String b) {
    return 'When $a is higher, $b tends to be lower.';
  }

  @override
  String statsInsightCorrelationPos(String a, String b) {
    return 'When $a is higher, $b tends to be higher too.';
  }

  @override
  String statsInsightEstimationBias(String pct) {
    return 'Tasks take ~$pct longer than planned — try adding a buffer.';
  }

  @override
  String statsInsightFallingCravings(String pct) {
    return 'Cravings are down $pct this week.';
  }

  @override
  String statsInsightFollowUps(int count) {
    return '$count waiting items need a follow-up.';
  }

  @override
  String statsInsightHealth(String milestone) {
    return 'Health milestone: $milestone';
  }

  @override
  String statsInsightMoney(String amount, String name) {
    return '$amount saved since you quit ($name).';
  }

  @override
  String get statsInsightNameBestWeekday => 'Best weekday';

  @override
  String get statsInsightNameBlockerCluster => 'Blocker clusters';

  @override
  String get statsInsightNameComeback => 'Comebacks';

  @override
  String get statsInsightNameCorrelation => 'Correlations';

  @override
  String get statsInsightNameEstimationBias => 'Estimation bias';

  @override
  String get statsInsightNameFallingCravings => 'Falling cravings';

  @override
  String get statsInsightNameFollowUpsDue => 'Follow-ups due';

  @override
  String get statsInsightNameHabitAtRisk => 'Habits at risk';

  @override
  String get statsInsightNameHealthMilestone => 'Health milestones';

  @override
  String get statsInsightNameMoneyMilestone => 'Money milestones';

  @override
  String get statsInsightNameNewRecord => 'New records';

  @override
  String get statsInsightNameOverbookedNextWeek => 'Overbooked weeks';

  @override
  String get statsInsightNamePerfectWeek => 'Perfect weeks';

  @override
  String get statsInsightNameRisingOverdue => 'Rising overdue';

  @override
  String get statsInsightNameSignificantTrend => 'Trends';

  @override
  String get statsInsightNameStaleList => 'Stale lists';

  @override
  String get statsInsightNameStreakMilestone => 'Streak milestones';

  @override
  String get statsInsightNameStrengthThreshold => 'Strength thresholds';

  @override
  String statsInsightNewRecord(String record, String value, String previous) {
    return 'New record: $record — $value (previous $previous).';
  }

  @override
  String statsInsightNewRecordFirst(String record, String value) {
    return 'New record: $record — $value.';
  }

  @override
  String statsInsightOverbooked(String days) {
    return 'Next week has overbooked days: $days.';
  }

  @override
  String get statsInsightPerfectWeek => 'Perfect habit week!';

  @override
  String statsInsightRisingOverdue(int count, int previous) {
    return 'Overdue tasks are piling up ($count, up from $previous).';
  }

  @override
  String get statsInsightRuleBestWeekday =>
      'A weekday is ≥ 15 pp above your average over 4+ weeks and the weekday effect is significant. At most every 30 days.';

  @override
  String get statsInsightRuleBlockerCluster =>
      'Three or more items blocked for the same reason within 14 days. At most every 14 days.';

  @override
  String get statsInsightRuleComeback => 'A success after 3 or more misses in a row. Once per comeback.';

  @override
  String get statsInsightRuleCorrelation =>
      'Two daily series move together, significant after false-discovery control. At most every 30 days per pair.';

  @override
  String get statsInsightRuleEstimationBias =>
      'Over the last 30 days (≥ 10 tasks) actual time exceeds planned time by more than 20 %. At most every 30 days.';

  @override
  String get statsInsightRuleFallingCravings =>
      'Cravings in the last 7 days are at least 25 % below the 7 days before (≥ 5 before). At most every 7 days.';

  @override
  String get statsInsightRuleFollowUpsDue =>
      'Three or more waiting items are past their follow-up date. At most every 3 days.';

  @override
  String get statsInsightRuleHabitAtRisk =>
      'A quota is behind pace or the habit score dropped more than 10 points in 7 days. Daily.';

  @override
  String get statsInsightRuleHealthMilestone =>
      'A smoke-free health milestone was reached. Once per milestone and attempt.';

  @override
  String get statsInsightRuleMoneyMilestone => 'Money saved crossed 10, 50, 100, 250, 500, 1 000… Once per amount.';

  @override
  String get statsInsightRuleNewRecord => 'A value beats every earlier one (set in the last 7 days). Once per value.';

  @override
  String get statsInsightRuleOverbookedNextWeek => 'Two or more days next week are planned beyond capacity. Weekly.';

  @override
  String get statsInsightRulePerfectWeek => 'Every due habit was done on every scheduled day last week. Weekly.';

  @override
  String get statsInsightRuleRisingOverdue =>
      'At least 5 overdue tasks and 30 % more than 4 weeks ago. At most every 7 days.';

  @override
  String get statsInsightRuleSignificantTrend =>
      'Weekly adherence over 8+ weeks has a significant slope (p < 0.05) of at least 2 pp per week. At most every 14 days.';

  @override
  String get statsInsightRuleStaleList =>
      'A list with open items has had no activity for its stale threshold. At most every 14 days.';

  @override
  String get statsInsightRuleStreakMilestone =>
      'A streak reaches 7, 14, 21, 30, 50, 66, 100, 150, 200 or 365 days, then every 100. Once per milestone.';

  @override
  String get statsInsightRuleStrengthThreshold => 'Habit strength crossed 50 % or 80 % upwards. Once per crossing.';

  @override
  String statsInsightStaleList(String name, int days) {
    return '“$name” has had no activity for $days days.';
  }

  @override
  String statsInsightStreak(String name, int count) {
    return '$name: $count-day streak!';
  }

  @override
  String statsInsightStrength(String name, String pct) {
    return '$name strength passed $pct.';
  }

  @override
  String statsInsightTrendDown(String name, String pp) {
    return '$name adherence is falling: −$pp pp per week.';
  }

  @override
  String statsInsightTrendUp(String name, String pp) {
    return '$name adherence is rising: +$pp pp per week.';
  }

  @override
  String get statsLayoutDone => 'Done';

  @override
  String get statsLayoutEdit => 'Customize cards';

  @override
  String get statsLayoutHiddenTag => 'Hidden';

  @override
  String statsLayoutHide(String card) {
    return 'Hide $card';
  }

  @override
  String get statsLayoutHint => 'Drag to reorder. Pin a card to keep it on top, or hide the ones you don’t need.';

  @override
  String statsLayoutPin(String card) {
    return 'Pin $card';
  }

  @override
  String statsLayoutReorder(String card) {
    return 'Reorder $card';
  }

  @override
  String get statsLayoutReset => 'Reset to default';

  @override
  String statsLayoutShow(String card) {
    return 'Show $card';
  }

  @override
  String statsLayoutUnpin(String card) {
    return 'Unpin $card';
  }

  @override
  String get statsLoading => 'Updating statistics…';

  @override
  String get statsMetricClI01Desc => 'How long this item spent in each status.';

  @override
  String get statsMetricClI01Formula => 'Sum of the intervals in each status until now (or deletion).';

  @override
  String get statsMetricClI01Title => 'Time in status';

  @override
  String get statsMetricClI02Desc => 'Time from starting work to completion.';

  @override
  String get statsMetricClI02Formula => 'Done − start (first move out of to do).';

  @override
  String get statsMetricClI02Title => 'Cycle time';

  @override
  String get statsMetricClI03Desc => 'Time from creation to completion.';

  @override
  String get statsMetricClI03Formula => 'Done − created.';

  @override
  String get statsMetricClI03Title => 'Lead time';

  @override
  String get statsMetricClI04Desc => 'How long an open item has been in progress or waiting to start.';

  @override
  String get statsMetricClI04Formula => 'Started: now − start; not started: now − created.';

  @override
  String get statsMetricClI04Title => 'Age';

  @override
  String get statsMetricClI05Desc => 'Time since anything last happened on this item.';

  @override
  String get statsMetricClI05Formula => 'Now − last activity (status change, edit, attachment or child change).';

  @override
  String get statsMetricClI05Title => 'Staleness';

  @override
  String get statsMetricClI06Desc => 'Completion of this item’s nested items.';

  @override
  String get statsMetricClI06Formula => 'Completed leaves ÷ countable leaves (cancelled excluded).';

  @override
  String get statsMetricClI06Title => 'Subtree progress';

  @override
  String get statsMetricClI07Desc => 'The item’s history as colored segments with notes.';

  @override
  String get statsMetricClI07Formula => 'Each status interval from creation to now.';

  @override
  String get statsMetricClI07Title => 'Status timeline';

  @override
  String get statsMetricClI08Desc => 'How often and how long this item was blocked, and why.';

  @override
  String get statsMetricClI08Formula =>
      'Number of blocked intervals, total blocked time and its share of the cycle time.';

  @override
  String get statsMetricClI08Title => 'Blocked episodes';

  @override
  String get statsMetricClI09Desc => 'How long this item waited on someone or something, with the follow-up status.';

  @override
  String get statsMetricClI09Formula =>
      'Number of waiting intervals, total wait, current wait; follow-up overdue when the date passed while waiting.';

  @override
  String get statsMetricClI09Title => 'Waiting episodes';

  @override
  String get statsMetricClI10Desc => 'Share of the cycle time spent actively working.';

  @override
  String get statsMetricClI10Formula => 'Time in ongoing ÷ cycle time.';

  @override
  String get statsMetricClI10Title => 'Flow efficiency';

  @override
  String get statsMetricClI11Desc => 'How much this item bounced between statuses.';

  @override
  String get statsMetricClI11Formula => 'Status changes; reopens (completed → other); ongoing ↔ waiting loops.';

  @override
  String get statsMetricClI11Title => 'Churn';

  @override
  String get statsMetricClI12Desc => 'How long the item waited before work started.';

  @override
  String get statsMetricClI12Formula => 'Start − created (queue time).';

  @override
  String get statsMetricClI12Title => 'Time to first action';

  @override
  String get statsMetricClI13Desc => 'Files attached to this item.';

  @override
  String get statsMetricClI13Formula => 'Count, total size and type mix (images, PDFs, other).';

  @override
  String get statsMetricClI13Title => 'Item attachments';

  @override
  String get statsMetricClI14Desc => 'How often the item text was edited.';

  @override
  String get statsMetricClI14Formula => 'Number of text edits; last edit time.';

  @override
  String get statsMetricClI14Title => 'Edit activity';

  @override
  String get statsMetricClL01Desc => 'How the list’s items are split across statuses.';

  @override
  String get statsMetricClL01Formula => 'Items per status; % done over leaves and over all nodes.';

  @override
  String get statsMetricClL01Title => 'Status mix';

  @override
  String get statsMetricClL02Desc => 'Daily completion of the list.';

  @override
  String get statsMetricClL02Formula => 'Completed ÷ (items in scope − cancelled) at each day end.';

  @override
  String get statsMetricClL02Title => 'Progress over time';

  @override
  String get statsMetricClL03Desc => 'Items completed per week, with a 4-week rolling mean.';

  @override
  String get statsMetricClL03Formula =>
      'Completions per bucket (a reopened item counts once, on its final completion).';

  @override
  String get statsMetricClL03Title => 'Throughput';

  @override
  String get statsMetricClL04Desc => 'Items ongoing, waiting or blocked at each day end.';

  @override
  String get statsMetricClL04Formula => 'Count of ongoing + waiting + blocked items.';

  @override
  String get statsMetricClL04Title => 'Work in progress';

  @override
  String get statsMetricClL05Desc => 'Items added vs completed each week.';

  @override
  String get statsMetricClL05Formula => 'Weekly created (or moved in) vs completed; net flow = difference.';

  @override
  String get statsMetricClL05Title => 'Arrivals vs departures';

  @override
  String get statsMetricClL06Desc => 'Open items without activity for a while, and the oldest ones.';

  @override
  String get statsMetricClL06Formula => 'Open items with staleness ≥ the stale threshold; 10 oldest by age.';

  @override
  String get statsMetricClL06Title => 'Stale items';

  @override
  String get statsMetricClL07Desc => 'How many items sat in each status at the end of every day.';

  @override
  String get statsMetricClL07Formula =>
      'Day-end counts per status from the event log; WIP, approximate cycle time and throughput at a date.';

  @override
  String get statsMetricClL07Title => 'Cumulative flow';

  @override
  String get statsMetricClL08Desc => 'How long items take from start to done.';

  @override
  String get statsMetricClL08Formula =>
      'Histogram of cycle times; scatter by completion date with P50/P70/P85/P95 lines.';

  @override
  String get statsMetricClL08Title => 'Cycle-time distribution';

  @override
  String get statsMetricClL09Desc => '“85 % of items finish within X”.';

  @override
  String get statsMetricClL09Formula => 'P85 of the cycle time over the last 90 days.';

  @override
  String get statsMetricClL09Title => 'Service level';

  @override
  String get statsMetricClL10Desc =>
      'Open started items by status and age; older than the usual cycle time means at risk.';

  @override
  String get statsMetricClL10Formula => 'Age = now − start; at risk when older than P85 of the cycle time.';

  @override
  String get statsMetricClL10Title => 'Aging work in progress';

  @override
  String get statsMetricClL11Desc => 'Items left to do each day, with an ideal line to the due date.';

  @override
  String get statsMetricClL11Formula =>
      'Remaining = arrived − completed − cancelled; forecast cone when enough history.';

  @override
  String get statsMetricClL11Title => 'Burn-down';

  @override
  String get statsMetricClL12Desc => 'How much the list grew after work began.';

  @override
  String get statsMetricClL12Formula => 'Items added after the baseline ÷ items at the baseline (first status change).';

  @override
  String get statsMetricClL12Title => 'Scope creep';

  @override
  String get statsMetricClL13Desc => 'Share of items cancelled, and of items completed without ever being started.';

  @override
  String get statsMetricClL13Formula => 'Cancelled ÷ created; completed without start ÷ completed.';

  @override
  String get statsMetricClL13Title => 'Cancelled & shortcuts';

  @override
  String get statsMetricClL14Desc => 'Items stuck right now, with how long they have been stuck.';

  @override
  String get statsMetricClL14Formula =>
      'Current blocked and waiting counts with ages; blocked time in the period; top reasons.';

  @override
  String get statsMetricClL14Title => 'Blocked & waiting now';

  @override
  String get statsMetricClL15Desc => 'Whether you act on items by their follow-up date.';

  @override
  String get statsMetricClL15Formula =>
      'Episodes acted on within 24 h of the follow-up ÷ episodes with a follow-up date; overdue follow-ups listed.';

  @override
  String get statsMetricClL15Title => 'Follow-up discipline';

  @override
  String get statsMetricClL16Desc => 'How deep and wide the list is.';

  @override
  String get statsMetricClL16Formula =>
      'Max depth, mean leaf depth, children per parent, leaves, widest level and largest branch.';

  @override
  String get statsMetricClL16Title => 'Tree shape';

  @override
  String get statsMetricClL17Desc => 'Items whose status disagrees with their children or misses a required reason.';

  @override
  String get statsMetricClL17Formula =>
      'Completed parents with open children; open parents whose children are all done; missing reasons.';

  @override
  String get statsMetricClL17Title => 'Integrity checks';

  @override
  String get statsMetricClL18Desc => 'Progress, throughput and blocked time of each top-level branch.';

  @override
  String get statsMetricClL18Formula => 'Leaf-based progress per branch; completions and blocked time in the period.';

  @override
  String get statsMetricClL18Title => 'Branch contribution';

  @override
  String get statsMetricClL19Desc => 'How often items with a due date are done on time, and what is overdue now.';

  @override
  String get statsMetricClL19Formula =>
      'Done by the due time ÷ completed with a due date; open overdue items and mean days late.';

  @override
  String get statsMetricClL19Title => 'Due-date performance';

  @override
  String get statsMetricClL20Desc => 'How complete each run of this routine list was at reset.';

  @override
  String get statsMetricClL20Formula => 'Completed ÷ total items per run; mean and trend.';

  @override
  String get statsMetricClL20Title => 'Run completion';

  @override
  String get statsMetricClL21Desc => 'Consecutive runs finished at 100 %.';

  @override
  String get statsMetricClL21Formula => 'Streak of fully completed runs.';

  @override
  String get statsMetricClL21Title => 'Perfect-run streak';

  @override
  String get statsMetricClL22Desc => 'How long a complete run takes.';

  @override
  String get statsMetricClL22Formula => 'Last completion − run start for 100 % runs; median and P85.';

  @override
  String get statsMetricClL22Title => 'Time to finish a run';

  @override
  String get statsMetricClL23Desc => 'Items most often left undone at reset.';

  @override
  String get statsMetricClL23Formula => 'Times not completed at reset, and share of runs.';

  @override
  String get statsMetricClL23Title => 'Most-skipped items';

  @override
  String get statsMetricClL24Desc => 'Average run completion on each weekday.';

  @override
  String get statsMetricClL24Formula => 'Mean completion % per weekday.';

  @override
  String get statsMetricClL24Title => 'Runs by weekday';

  @override
  String get statsMetricClL25Desc => 'Items completed each day in this list, with the current streak.';

  @override
  String get statsMetricClL25Formula => 'Completions per day; streak of days with at least one.';

  @override
  String get statsMetricClL25Title => 'Completion calendar';

  @override
  String get statsMetricClL26Desc => 'Similar blocked reasons grouped together, ranked by impact.';

  @override
  String get statsMetricClL26Formula =>
      'Normalized reasons; rank = episodes × blocked hours; clusters can be merged in settings.';

  @override
  String get statsMetricClL26Title => 'Blocker clusters';

  @override
  String get statsMetricClL27Desc =>
      'Whether the list’s flow is stable enough to trust its averages. Never a forecast.';

  @override
  String get statsMetricClL27Formula =>
      'mean cycle time ÷ (mean WIP ÷ mean throughput); unstable outside 0.7–1.3 or when arrivals ÷ departures leaves 0.8–1.2.';

  @override
  String get statsMetricClL27Title => 'Little’s Law check';

  @override
  String get statsMetricClL28Desc => 'When the remaining items will probably be done.';

  @override
  String get statsMetricClL28Formula =>
      '10 000 simulations resampling recent daily completions; dates at 50 %, 85 % and 95 % chance.';

  @override
  String get statsMetricClL28Title => 'Finish forecast';

  @override
  String get statsMetricClL29Desc => 'How complete each level of the tree is.';

  @override
  String get statsMetricClL29Formula => 'Completed ÷ countable items per depth level.';

  @override
  String get statsMetricClL29Title => 'Progress by depth';

  @override
  String get statsMetricClL30Desc => 'Files attached in this list.';

  @override
  String get statsMetricClL30Formula => 'Count, total size and type mix.';

  @override
  String get statsMetricClL30Title => 'List attachments';

  @override
  String get statsMetricClX01Desc => 'Your lists: active, archived, templates and stale ones.';

  @override
  String get statsMetricClX01Formula => 'Counts of lists; stale = no activity for N days while holding open items.';

  @override
  String get statsMetricClX01Title => 'Lists overview';

  @override
  String get statsMetricClX02Desc => 'Items added vs completed each week across lists.';

  @override
  String get statsMetricClX02Formula => 'Weekly created vs completed; net flow = difference.';

  @override
  String get statsMetricClX02Title => 'Arrivals vs departures (all lists)';

  @override
  String get statsMetricClX03Desc => 'Items ongoing, waiting or blocked now, and the oldest open items.';

  @override
  String get statsMetricClX03Formula => 'Counts across active lists (archived excluded).';

  @override
  String get statsMetricClX03Title => 'Work in progress across lists';

  @override
  String get statsMetricClX04Desc => 'Items completed in the period.';

  @override
  String get statsMetricClX04Formula => 'Final completions in the period, compared with the previous period.';

  @override
  String get statsMetricClX04Title => 'Items completed';

  @override
  String get statsMetricClX05Desc => 'Items per status across all lists.';

  @override
  String get statsMetricClX05Formula => 'Count of live items per status.';

  @override
  String get statsMetricClX05Title => 'Status distribution';

  @override
  String get statsMetricClX06Desc => 'Most common blocked and waiting reasons in all your lists.';

  @override
  String get statsMetricClX06Formula => 'Pareto of normalized reasons: episodes and total time.';

  @override
  String get statsMetricClX06Title => 'Reasons across lists';

  @override
  String get statsMetricClX07Desc => 'Who or what your items are waiting on.';

  @override
  String get statsMetricClX07Formula =>
      'Waiting episodes grouped by person or thing: open count, mean wait, longest wait, overdue follow-ups.';

  @override
  String get statsMetricClX07Title => 'Waiting-for register';

  @override
  String get statsMetricClX08Desc => 'Lists that lost the most time to blocked items.';

  @override
  String get statsMetricClX08Formula => 'Lists ranked by total blocked time in the period.';

  @override
  String get statsMetricClX08Title => 'Most blocked lists';

  @override
  String get statsMetricClX09Desc => 'Typical cycle time across all lists and the throughput trend.';

  @override
  String get statsMetricClX09Formula => 'Section-wide cycle-time P50/P85; weekly throughput slope.';

  @override
  String get statsMetricClX09Title => 'Flow benchmarks';

  @override
  String get statsMetricClX10Desc => 'Items completed each day across your lists, with the current streak.';

  @override
  String get statsMetricClX10Formula => 'Completions per day; streak of days with at least one.';

  @override
  String get statsMetricClX10Title => 'Completion calendar';

  @override
  String get statsMetricClX11Desc => 'Space used by attachments in your lists.';

  @override
  String get statsMetricClX11Formula => 'Σ attachment sizes; count and type mix.';

  @override
  String get statsMetricClX11Title => 'Attachment storage';

  @override
  String get statsMetricClX12Desc => 'How many lists you create and archive each month.';

  @override
  String get statsMetricClX12Formula => 'Checklists created and archived per month.';

  @override
  String get statsMetricClX12Title => 'Lists created & archived';

  @override
  String get statsMetricGl01Desc => 'Your day across sections: agenda, habits, lists and quit.';

  @override
  String get statsMetricGl01Formula => 'Same numbers as each section’s metrics for today.';

  @override
  String get statsMetricGl01Title => 'Today';

  @override
  String get statsMetricGl02Desc => 'This week so far vs the same days last week.';

  @override
  String get statsMetricGl02Formula => 'Section KPIs to date with their change vs the previous week.';

  @override
  String get statsMetricGl02Title => 'Week at a glance';

  @override
  String get statsMetricGl03Desc => 'Your week: headline numbers, wins, what needs attention and next week’s load.';

  @override
  String get statsMetricGl03Formula => 'Section KPIs with their change vs the previous week.';

  @override
  String get statsMetricGl03Title => 'Weekly review';

  @override
  String get statsMetricGl04Desc => 'Consecutive weeks with a completed guided review.';

  @override
  String get statsMetricGl04Formula =>
      'Run of reviewed weeks ending with the last completed week (open until reviewed).';

  @override
  String get statsMetricGl04Title => 'Weekly review streak';

  @override
  String get statsMetricGl05Desc =>
      'Your month across every section, compared with the previous month (and last year when available).';

  @override
  String get statsMetricGl05Formula =>
      'Rates compare directly; sums compare as per-day averages (months have different lengths).';

  @override
  String get statsMetricGl05Title => 'Monthly review';

  @override
  String get statsMetricGl06Desc => 'Your best days, weeks, months and streaks across every section.';

  @override
  String get statsMetricGl06Formula => 'New = set in the last 7 days and above every value before.';

  @override
  String get statsMetricGl06Title => 'Personal records';

  @override
  String get statsMetricGl07Desc => 'One 0–100 number for the day, from the sections you used.';

  @override
  String get statsMetricGl07Formula =>
      'Weighted mean of planner done ÷ planned, habits done ÷ due, list completions ÷ usual (max 1) and abstinence; sections without data are left out.';

  @override
  String get statsMetricGl07Title => 'Day score';

  @override
  String get statsMetricGl08Desc => 'Whether some weekdays go better than others.';

  @override
  String get statsMetricGl08Formula =>
      'Mean per weekday over the last 26 weeks (≥ 4 weeks); Kruskal–Wallis test, significant when p < 0.05.';

  @override
  String get statsMetricGl08Title => 'Day-of-week effects';

  @override
  String get statsMetricGl09Desc => 'Every goal with its progress, pace and projected end.';

  @override
  String get statsMetricGl09Formula =>
      'Progress = actual ÷ target; pace = target × elapsed share; projected = actual + 28-day rate × remaining days.';

  @override
  String get statsMetricGl09Title => 'Goals & projections';

  @override
  String get statsMetricGl10Desc =>
      'How trustworthy your statistics are: habit logging, late entries, tracked time on tasks and changes still waiting to sync — each with a tip to improve it.';

  @override
  String get statsMetricGl10Formula =>
      'Habit logged ratio and unknown units (last 30 days); late-log share (> 24 h); planner actual-time coverage = done occurrences with tracked time ÷ done occurrences; pending sync changes.';

  @override
  String get statsMetricGl10Title => 'Data quality';

  @override
  String get statsMetricGl11Desc => 'Every day of the year coloured by what you got done.';

  @override
  String get statsMetricGl11Formula => 'Done tasks + done habit check-ins + completed list items per day.';

  @override
  String get statsMetricGl11Title => 'Year activity';

  @override
  String get statsMetricGl13Desc => 'Things that tend to move together in your data.';

  @override
  String get statsMetricGl13Formula =>
      'Phi, point-biserial or Spearman over the last 180 days, lags 0–3, ≥ 21 paired days, false-discovery rate 10 %.';

  @override
  String get statsMetricGl13Title => 'Correlations';

  @override
  String get statsMetricGl14Desc => 'Your year as a story: numbers, streaks, records and your style.';

  @override
  String get statsMetricGl14Formula =>
      'Yearly totals of the day facts; year-over-year when the previous year has data.';

  @override
  String get statsMetricGl14Title => 'Year in review';

  @override
  String get statsMetricGl15Desc => 'Experience points from what you complete (opt-in).';

  @override
  String get statsMetricGl15Formula =>
      'Task 10 × priority (× 1.1 on time), habit 10 × (1 + streak/100), list item 5, clean day 20; 500 per day max; level n at 100·n^1.5.';

  @override
  String get statsMetricGl15Title => 'XP & level';

  @override
  String get statsMetricGl17Desc => 'How your waking hours split between tasks, habits and free time.';

  @override
  String get statsMetricGl17Formula =>
      'max(planned, tracked) task time + duration-habit time − overlap; free = waking hours − used.';

  @override
  String get statsMetricGl17Title => 'Time budget';

  @override
  String get statsMetricGl18Desc => 'When you are likely to reach your goals at your recent pace.';

  @override
  String get statsMetricGl18Formula =>
      '10 000 simulations resampling the last 6 weeks of daily progress; 50 / 85 / 95 % likely dates.';

  @override
  String get statsMetricGl18Title => 'Goal forecast';

  @override
  String get statsMetricGl19Desc => 'Short, data-backed observations about your week.';

  @override
  String get statsMetricGl19Formula =>
      '18 rules (records, streaks, trends, overload, blockers…), each with a cooldown; dismissed or muted ones stay hidden.';

  @override
  String get statsMetricGl19Title => 'Insights';

  @override
  String get statsMetricHbH01Desc => 'How well the habit is established — recent days count more.';

  @override
  String get statsMetricHbH01Formula => 'Loop score: score = previous × m + credit × (1 − m), m = 0.5^(√f ÷ 13).';

  @override
  String get statsMetricHbH01Title => 'Habit strength';

  @override
  String get statsMetricHbH02Desc => 'Consecutive successful units up to now; today stays open until it ends.';

  @override
  String get statsMetricHbH02Formula => 'Streak engine: skips, excuses, pauses and freezes are neutral.';

  @override
  String get statsMetricHbH02Title => 'Current streak';

  @override
  String get statsMetricHbH03Desc => 'Your longest run of successful units.';

  @override
  String get statsMetricHbH03Formula => 'Maximum streak length, with its date range.';

  @override
  String get statsMetricHbH03Title => 'Best streak';

  @override
  String get statsMetricHbH04Desc => 'Your ten longest streaks.';

  @override
  String get statsMetricHbH04Formula => 'Streaks ordered by length, then recency.';

  @override
  String get statsMetricHbH04Title => 'Top streaks';

  @override
  String get statsMetricHbH05Desc => 'Share of scheduled units you completed.';

  @override
  String get statsMetricHbH05Formula => 'Done ÷ (closed scheduled units − excused); Wilson interval below 20 units.';

  @override
  String get statsMetricHbH05Title => 'Success rate';

  @override
  String get statsMetricHbH06Desc => 'How each scheduled unit ended.';

  @override
  String get statsMetricHbH06Formula => 'Counts of success, partial, not done, missed, skipped and excused units.';

  @override
  String get statsMetricHbH06Title => 'Outcome counts';

  @override
  String get statsMetricHbH07Desc => 'Successes (and volume) per week, month or year.';

  @override
  String get statsMetricHbH07Formula => 'Sums per bucket.';

  @override
  String get statsMetricHbH07Title => 'History';

  @override
  String get statsMetricHbH08Desc => 'Each day’s status.';

  @override
  String get statsMetricHbH08Formula =>
      'One cell per day: done, partial, not done, missed, skipped, excused, paused, frozen.';

  @override
  String get statsMetricHbH08Title => 'Calendar';

  @override
  String get statsMetricHbH09Desc => 'Every check-in is a vote for the person you want to be.';

  @override
  String get statsMetricHbH09Formula => 'All-time count of manual done and progress logs.';

  @override
  String get statsMetricHbH09Title => 'Total repetitions';

  @override
  String get statsMetricHbH10Desc => 'How much of the period’s target you reached.';

  @override
  String get statsMetricHbH10Formula => 'Achieved ÷ (daily target × scheduled days − skipped days).';

  @override
  String get statsMetricHbH10Title => 'Target progress';

  @override
  String get statsMetricHbH11Desc => 'Everything you logged, in the habit’s unit.';

  @override
  String get statsMetricHbH11Formula => 'Sum of logged values in the period and all time.';

  @override
  String get statsMetricHbH11Title => 'Total volume';

  @override
  String get statsMetricHbH12Desc => 'Typical amount per scheduled day and per day you were active.';

  @override
  String get statsMetricHbH12Formula => 'Mean value per scheduled day (E − X) and per day with a value above 0.';

  @override
  String get statsMetricHbH12Title => 'Averages';

  @override
  String get statsMetricHbH13Desc => 'Your best day, week and month.';

  @override
  String get statsMetricHbH13Formula => 'Highest total per day, week and month, with dates; a new record is flagged.';

  @override
  String get statsMetricHbH13Title => 'Records';

  @override
  String get statsMetricHbH14Desc => 'How much you usually log on a scheduled day.';

  @override
  String get statsMetricHbH14Formula => 'Histogram of daily values; median and P85.';

  @override
  String get statsMetricHbH14Title => 'Value distribution';

  @override
  String get statsMetricHbH15Desc =>
      'How close you get to the target on average, and how often a day is only partly done.';

  @override
  String get statsMetricHbH15Formula => 'mean(min(1, value ÷ target)) over non-excused units; partial ÷ (E − X).';

  @override
  String get statsMetricHbH15Title => 'Fulfilment';

  @override
  String get statsMetricHbH16Desc => 'Days you stayed at or under your limit, and how far over you went otherwise.';

  @override
  String get statsMetricHbH16Formula => 'Days with value ≤ limit ÷ (E − X); excess = Σ max(0, value − limit).';

  @override
  String get statsMetricHbH16Title => 'Within limit';

  @override
  String get statsMetricHbH17Desc => 'How steadily you keep the habit, ignoring days it isn\'t scheduled.';

  @override
  String get statsMetricHbH17Formula =>
      'Mean of the rolling 30-day mean of per-unit scores (1 done, value ÷ target partial, 0 missed).';

  @override
  String get statsMetricHbH17Title => 'Consistency index';

  @override
  String get statsMetricHbH18Desc => 'Your success rate on each weekday.';

  @override
  String get statsMetricHbH18Formula => 'Done ÷ closed scheduled units per weekday.';

  @override
  String get statsMetricHbH18Title => 'Weekday profile';

  @override
  String get statsMetricHbH19Desc => 'When in the day you usually check in, and how regular that is.';

  @override
  String get statsMetricHbH19Formula =>
      'Circular mean and SD of check-in times (counted from your day start); weekday × hour grid.';

  @override
  String get statsMetricHbH19Title => 'Check-in time';

  @override
  String get statsMetricHbH20Desc => 'Share of check-ins close to their slot time.';

  @override
  String get statsMetricHbH20Formula => 'Check-ins within ± the slot tolerance (30 min) of the slot ÷ slot check-ins.';

  @override
  String get statsMetricHbH20Title => 'Slot punctuality';

  @override
  String get statsMetricHbH21Desc => 'Today\'s count against the target and the usual gap between check-ins.';

  @override
  String get statsMetricHbH21Formula =>
      'Check-ins vs target per day; mean and median spacing between consecutive check-ins.';

  @override
  String get statsMetricHbH21Title => 'Several times a day';

  @override
  String get statsMetricHbH22Desc => '“Never miss twice”: how often a miss is followed by a success.';

  @override
  String get statsMetricHbH22Formula =>
      'Misses followed by a success ÷ misses with a closed next unit; longest and mean gaps; comebacks after 3+ misses.';

  @override
  String get statsMetricHbH22Title => 'Recovery';

  @override
  String get statsMetricHbH23Desc => 'Freezes used against those granted, this month and overall.';

  @override
  String get statsMetricHbH23Formula => 'Freezes used ÷ granted per month and all time; protected days listed.';

  @override
  String get statsMetricHbH23Title => 'Streak freezes';

  @override
  String get statsMetricHbH24Desc => 'Whether the habit strength is rising, stable or falling.';

  @override
  String get statsMetricHbH24Formula => 'Slope of the strength score over 30 days; |slope| < 0.1 point/day = stable.';

  @override
  String get statsMetricHbH24Title => 'Momentum';

  @override
  String get statsMetricHbH25Desc =>
      'How much of this habit\'s history is actually logged. An unlogged day is unknown, not failed: it counts as missed only because nothing was recorded.';

  @override
  String get statsMetricHbH25Formula =>
      'Logged ratio = units with any log ÷ closed scheduled units · unknown units = missed units without any log · backfill share = logs created more than 24 h after their unit ended ÷ all logs.';

  @override
  String get statsMetricHbH25Title => 'Data completeness';

  @override
  String get statsMetricHbH26Desc => 'Whether you are on track for this habit\'s goal, and when you should reach it.';

  @override
  String get statsMetricHbH26Formula =>
      'Pace = goal × elapsed share; projection = actual + 28-day rate × days left; ETA when the projection reaches the goal.';

  @override
  String get statsMetricHbH26Title => 'Goal pace';

  @override
  String get statsMetricHbH27Desc => 'How long it took for the habit to settle (80 % success held for 14 days).';

  @override
  String get statsMetricHbH27Formula =>
      'Days until the rolling 30-day success rate first stays ≥ 80 % for 14 days; research range 18–254 days (Lally et al. 2010).';

  @override
  String get statsMetricHbH27Title => 'Habit formation';

  @override
  String get statsMetricHbH28Desc => 'How often you check in soon after a reminder.';

  @override
  String get statsMetricHbH28Formula => 'Check-ins within 60 min after a reminder ÷ check-ins; median delay.';

  @override
  String get statsMetricHbH28Title => 'Reminder effectiveness';

  @override
  String get statsMetricHbH29Desc =>
      'Your mood on days you did the habit versus days you didn\'t (association, not cause).';

  @override
  String get statsMetricHbH29Formula => 'Mean mood on done vs not-done days; Mann–Whitney test.';

  @override
  String get statsMetricHbH29Title => 'Mood by outcome';

  @override
  String get statsMetricHbH30Desc => 'Why you skipped or excused days.';

  @override
  String get statsMetricHbH30Formula => 'Pareto of skip and excuse notes.';

  @override
  String get statsMetricHbH30Title => 'Skip & excuse reasons';

  @override
  String get statsMetricHbX01Desc => 'Due habits done today.';

  @override
  String get statsMetricHbX01Formula => 'Done ÷ due day units today (build habits).';

  @override
  String get statsMetricHbX01Title => 'Today’s progress';

  @override
  String get statsMetricHbX02Desc => 'Days where every due habit was done.';

  @override
  String get statsMetricHbX02Formula =>
      'Days with all due units done; perfect-day streak (days with nothing due are neutral).';

  @override
  String get statsMetricHbX02Title => 'Perfect days';

  @override
  String get statsMetricHbX03Desc => 'How much of each day’s habits you completed.';

  @override
  String get statsMetricHbX03Formula => 'Per day: done ÷ due across habits.';

  @override
  String get statsMetricHbX03Title => 'Daily completion';

  @override
  String get statsMetricHbX04Desc => 'Weekly success rate across habits.';

  @override
  String get statsMetricHbX04Formula => 'Weekly done ÷ due, with a 4-week rolling line; Δ vs previous week in points.';

  @override
  String get statsMetricHbX04Title => 'Adherence trend';

  @override
  String get statsMetricHbX05Desc => 'Money saved, units avoided and life regained across quit trackers.';

  @override
  String get statsMetricHbX05Formula => 'Sums over active quit trackers (life regained is a population estimate).';

  @override
  String get statsMetricHbX05Title => 'Quit trackers roll-up';

  @override
  String get statsMetricHbX06Desc => 'How strong each habit is, and which are rising or falling.';

  @override
  String get statsMetricHbX06Formula => 'Mean and median strength; ranked bars; change over 30 days.';

  @override
  String get statsMetricHbX06Title => 'Strength across habits';

  @override
  String get statsMetricHbX07Desc => 'Habits that need attention now.';

  @override
  String get statsMetricHbX07Formula =>
      'Quota behind, due today with a live streak, or strength down more than 10 points in 7 days.';

  @override
  String get statsMetricHbX07Title => 'At risk';

  @override
  String get statsMetricHbX08Desc => 'Success rate and volume by category.';

  @override
  String get statsMetricHbX08Formula => 'Done ÷ closed units and Σ volume per category.';

  @override
  String get statsMetricHbX08Title => 'Life areas';

  @override
  String get statsMetricHbX09Desc => 'Habits ranked by success rate in the period.';

  @override
  String get statsMetricHbX09Formula => 'Success rate per habit (at least 5 closed units).';

  @override
  String get statsMetricHbX09Title => 'Best & worst habits';

  @override
  String get statsMetricHbX10Desc => 'How many check-ins you log.';

  @override
  String get statsMetricHbX10Formula => 'Check-ins per day (per week for long periods).';

  @override
  String get statsMetricHbX10Title => 'Check-in volume';

  @override
  String get statsMetricHbX11Desc => 'Your success rate on each weekday across habits.';

  @override
  String get statsMetricHbX11Formula => 'Done ÷ closed scheduled units per weekday, all habits.';

  @override
  String get statsMetricHbX11Title => 'Weekday profile (all habits)';

  @override
  String get statsMetricHbX12Desc =>
      'The same completeness measures across every build habit: logged ratio, unlogged (unknown) units and late logging.';

  @override
  String get statsMetricHbX12Formula =>
      'Σ units with any log ÷ Σ closed scheduled units across habits; Σ unknown units; Σ late logs ÷ Σ logs.';

  @override
  String get statsMetricHbX12Title => 'Data completeness (all habits)';

  @override
  String get statsMetricHbX13Desc => 'Habits you often complete on the same days (association, not cause).';

  @override
  String get statsMetricHbX13Formula =>
      'Phi between daily done flags (≥ 21 shared days), kept only when significant after false-discovery control.';

  @override
  String get statsMetricHbX13Title => 'Done together';

  @override
  String get statsMetricHbX14Desc => 'Habits you start and archive, and how many are still going after 30 and 90 days.';

  @override
  String get statsMetricHbX14Formula =>
      'Created and archived per month; share still active 30 and 90 days after creation.';

  @override
  String get statsMetricHbX14Title => 'Habit portfolio';

  @override
  String get statsMetricPlS01Desc => 'How many times the series was due in the period.';

  @override
  String get statsMetricPlS01Formula =>
      'Occurrences from the recurrence rule in the window; closed and open counted separately.';

  @override
  String get statsMetricPlS01Title => 'Expected occurrences';

  @override
  String get statsMetricPlS02Desc => 'Breakdown of the series’ occurrences by outcome.';

  @override
  String get statsMetricPlS02Formula => 'Counts of done (D), missed (M), skipped (K) and excused (X) occurrences.';

  @override
  String get statsMetricPlS02Title => 'Done, missed, skipped';

  @override
  String get statsMetricPlS03Desc => 'Share of due occurrences you completed.';

  @override
  String get statsMetricPlS03Formula => 'Done ÷ (expected − excused), with a 4-week rolling line and a weekly trend.';

  @override
  String get statsMetricPlS03Title => 'Adherence';

  @override
  String get statsMetricPlS04Desc => 'Share of due occurrences that were missed or not done.';

  @override
  String get statsMetricPlS04Formula => '(Missed + not done) ÷ (expected − excused).';

  @override
  String get statsMetricPlS04Title => 'Miss rate';

  @override
  String get statsMetricPlS05Desc => 'Consecutive completed occurrences; skips are neutral by default.';

  @override
  String get statsMetricPlS05Formula => 'Streak engine with one unit per occurrence.';

  @override
  String get statsMetricPlS05Title => 'Current & best streak';

  @override
  String get statsMetricPlS06Desc => 'Cumulative tracked and planned time since the series started.';

  @override
  String get statsMetricPlS06Formula => 'Running totals of actual and planned minutes.';

  @override
  String get statsMetricPlS06Title => 'Time invested';

  @override
  String get statsMetricPlS07Desc => 'All-time number of completed occurrences.';

  @override
  String get statsMetricPlS07Formula => 'Count of done occurrences.';

  @override
  String get statsMetricPlS07Title => 'Total done';

  @override
  String get statsMetricPlS08Desc => 'Days since the last completed occurrence.';

  @override
  String get statsMetricPlS08Formula => 'Today − date of the last completion.';

  @override
  String get statsMetricPlS08Title => 'Last done';

  @override
  String get statsMetricPlS09Desc => 'Each day’s outcome for the series.';

  @override
  String get statsMetricPlS09Formula => 'Worst outcome of the day: missed > partial > late > skipped > done > excused.';

  @override
  String get statsMetricPlS09Title => 'Outcome calendar';

  @override
  String get statsMetricPlS10Desc => 'Share of scheduled occurrences you skipped, and why.';

  @override
  String get statsMetricPlS10Formula => 'Skipped ÷ scheduled; reasons ranked by count.';

  @override
  String get statsMetricPlS10Title => 'Skip rate & reasons';

  @override
  String get statsMetricPlS11Desc => 'Share of starts within the grace period, with start delays per month.';

  @override
  String get statsMetricPlS11Formula => 'On-time starts ÷ started occurrences; box plot of start delay.';

  @override
  String get statsMetricPlS11Title => 'Start timeliness';

  @override
  String get statsMetricPlS12Desc => 'Share of done occurrences that were finished on time.';

  @override
  String get statsMetricPlS12Formula => 'Done on time ÷ done.';

  @override
  String get statsMetricPlS12Title => 'On-time completion';

  @override
  String get statsMetricPlS13Desc => 'Your ten longest streaks for this series.';

  @override
  String get statsMetricPlS13Formula => 'Streaks ordered by length, then by recency.';

  @override
  String get statsMetricPlS13Title => 'Top streaks';

  @override
  String get statsMetricPlS14Desc => 'How firmly the routine is established (Loop-style score).';

  @override
  String get statsMetricPlS14Formula => 'score = score·m + done·(1 − m), m = 0.5^(√f/13), f = occurrences per day.';

  @override
  String get statsMetricPlS14Title => 'Series strength';

  @override
  String get statsMetricPlS15Desc => 'How steady the actual duration is, and how it compares with the plan.';

  @override
  String get statsMetricPlS15Formula => 'Median, mean, SD and CV of actual minutes; median of actual ÷ planned.';

  @override
  String get statsMetricPlS15Title => 'Duration stability';

  @override
  String get statsMetricPlS16Desc => 'Adherence on each weekday the rule schedules.';

  @override
  String get statsMetricPlS16Formula => 'Done ÷ closed, non-excused occurrences per weekday.';

  @override
  String get statsMetricPlS16Title => 'Weekday profile';

  @override
  String get statsMetricPlS17Desc => 'When in the day you usually finish this series.';

  @override
  String get statsMetricPlS17Formula => 'Done occurrences per hour of the done time.';

  @override
  String get statsMetricPlS17Title => 'Completion hours';

  @override
  String get statsMetricPlS18Desc => 'How often occurrences of this series get moved and how far they are pushed.';

  @override
  String get statsMetricPlS18Formula => 'Moved ≥ 1× ÷ occurrences; mean moves; mean postponement.';

  @override
  String get statsMetricPlS18Title => 'Series reschedules';

  @override
  String get statsMetricPlS19Desc => 'Adherence before and after each change of the series’ rule.';

  @override
  String get statsMetricPlS19Formula => 'Adherence in the 28 days before vs after each split.';

  @override
  String get statsMetricPlS19Title => 'Rule changes';

  @override
  String get statsMetricPlS20Desc => 'When you actually start this series, and how consistent that time is.';

  @override
  String get statsMetricPlS20Formula => 'Circular mean and circular SD of start (or done) times.';

  @override
  String get statsMetricPlS20Title => 'Time-of-day consistency';

  @override
  String get statsMetricPlS21Desc => 'How much earlier or later than planned you usually start.';

  @override
  String get statsMetricPlS21Formula => 'Circular mean of (actual start − planned start), within ±12 h.';

  @override
  String get statsMetricPlS21Title => 'Start drift';

  @override
  String get statsMetricPlT01Desc => 'How long this occurrence was planned to take.';

  @override
  String get statsMetricPlT01Formula => 'Planned end − planned start.';

  @override
  String get statsMetricPlT01Title => 'Planned duration';

  @override
  String get statsMetricPlT02Desc => 'Time actually tracked on this occurrence, pauses excluded.';

  @override
  String get statsMetricPlT02Formula => 'Sum of tracked session lengths; unknown when nothing was tracked.';

  @override
  String get statsMetricPlT02Title => 'Actual duration';

  @override
  String get statsMetricPlT03Desc => 'Difference between actual and planned time, and their ratio.';

  @override
  String get statsMetricPlT03Formula => 'Actual − planned; ratio R = actual ÷ planned (only when planned ≥ 5 min).';

  @override
  String get statsMetricPlT03Title => 'Duration variance';

  @override
  String get statsMetricPlT04Desc => 'How early or late you started compared with the plan.';

  @override
  String get statsMetricPlT04Formula => 'First session start − planned start; on time within the grace period.';

  @override
  String get statsMetricPlT04Title => 'Start delay';

  @override
  String get statsMetricPlT05Desc => 'How early or late the occurrence was finished.';

  @override
  String get statsMetricPlT05Formula => 'Completion (or last session end for timers) − planned end.';

  @override
  String get statsMetricPlT05Title => 'Finish delay';

  @override
  String get statsMetricPlT06Desc => 'What happened to this occurrence.';

  @override
  String get statsMetricPlT06Formula =>
      'Done on time, done late, partial, skipped, missed, cancelled, pending or upcoming.';

  @override
  String get statsMetricPlT06Title => 'Outcome';

  @override
  String get statsMetricPlT07Desc => 'How long an unfinished occurrence has been overdue.';

  @override
  String get statsMetricPlT07Formula => 'Now − planned end, bucketed 1 / 7 / 14 / 30+ days.';

  @override
  String get statsMetricPlT07Title => 'Overdue age';

  @override
  String get statsMetricPlT08Desc =>
      'How many times this occurrence was moved. Moves of the whole series count once for each affected occurrence.';

  @override
  String get statsMetricPlT08Formula => 'Number of “rescheduled” events of this occurrence.';

  @override
  String get statsMetricPlT08Title => 'Reschedules';

  @override
  String get statsMetricPlT09Desc => 'Total time this occurrence was pushed around, in both directions.';

  @override
  String get statsMetricPlT09Formula => 'Σ |new start − old start| over every move.';

  @override
  String get statsMetricPlT09Title => 'Reschedule distance';

  @override
  String get statsMetricPlT10Desc => 'How far the final start ended up from the first planned start.';

  @override
  String get statsMetricPlT10Formula => 'Final planned start − first planned start.';

  @override
  String get statsMetricPlT10Title => 'Net drift';

  @override
  String get statsMetricPlT11Desc => 'Flags an occurrence that keeps being postponed.';

  @override
  String get statsMetricPlT11Formula => 'Shown when the occurrence was moved 3 times or more.';

  @override
  String get statsMetricPlT11Title => 'Snowballing';

  @override
  String get statsMetricPlT12Desc => 'Time from creating the task to finishing it.';

  @override
  String get statsMetricPlT12Formula => 'Done time − task creation time.';

  @override
  String get statsMetricPlT12Title => 'Lead time';

  @override
  String get statsMetricPlT13Desc => 'Time from creating the task to starting work on it.';

  @override
  String get statsMetricPlT13Formula => 'First session start − task creation time.';

  @override
  String get statsMetricPlT13Title => 'Start latency';

  @override
  String get statsMetricPlT14Desc => 'How far ahead the occurrence was planned.';

  @override
  String get statsMetricPlT14Formula => 'First planned start − task creation time.';

  @override
  String get statsMetricPlT14Title => 'Planning horizon';

  @override
  String get statsMetricPlT15Desc =>
      'Share of the tracked time that happened inside the planned slot, with minutes spilled before and after.';

  @override
  String get statsMetricPlT15Formula => 'Overlap(sessions, planned slot) ÷ actual minutes.';

  @override
  String get statsMetricPlT15Title => 'Slot fit';

  @override
  String get statsMetricPlT16Desc =>
      'Tracked sessions of this occurrence: count, total, mean length, pauses and the longest uninterrupted block.';

  @override
  String get statsMetricPlT16Formula => 'Pauses = gaps ≥ 2 min; sessions less than 2 min apart form one block.';

  @override
  String get statsMetricPlT16Title => 'Focus sessions';

  @override
  String get statsMetricPlT17Desc => 'How much of the occurrence was completed.';

  @override
  String get statsMetricPlT17Formula => 'Completion percent recorded with the occurrence.';

  @override
  String get statsMetricPlT17Title => 'Partial completion';

  @override
  String get statsMetricPlT18Desc => 'Your rating (1–5) and outcome note for this occurrence.';

  @override
  String get statsMetricPlT18Formula => 'Rating and note saved when finishing.';

  @override
  String get statsMetricPlT18Title => 'Self-rating';

  @override
  String get statsMetricPlX01Desc => 'Share of what was planned at the start of the period that you completed.';

  @override
  String get statsMetricPlX01Formula =>
      'Planned and done in the period ÷ planned as of the period start; tasks added later are excluded.';

  @override
  String get statsMetricPlX01Title => 'Completion vs plan';

  @override
  String get statsMetricPlX02Desc => 'Planned and completed tasks for each day.';

  @override
  String get statsMetricPlX02Formula => 'Per day: planned (plan snapshot) and done counts.';

  @override
  String get statsMetricPlX02Title => 'Done vs planned per day';

  @override
  String get statsMetricPlX03Desc => 'Tasks added after the period started, and tasks moved out of or into it.';

  @override
  String get statsMetricPlX03Formula => 'Counts of unplanned additions, moved-out and moved-in occurrences.';

  @override
  String get statsMetricPlX03Title => 'Unplanned & moved';

  @override
  String get statsMetricPlX04Desc => 'Tasks created vs completed each week, and the open backlog.';

  @override
  String get statsMetricPlX04Formula =>
      'Created and completed per week; backlog = unscheduled tasks + overdue occurrences.';

  @override
  String get statsMetricPlX04Title => 'Backlog flow';

  @override
  String get statsMetricPlX05Desc => 'Share of completed tasks finished by their planned end.';

  @override
  String get statsMetricPlX05Formula => 'Done on time ÷ done (grace period included).';

  @override
  String get statsMetricPlX05Title => 'On-time completion';

  @override
  String get statsMetricPlX06Desc => 'Unfinished tasks past their planned end, by age.';

  @override
  String get statsMetricPlX06Formula => 'Open overdue occurrences, bucketed 1 / 7 / 14 / 30+ days.';

  @override
  String get statsMetricPlX06Title => 'Overdue now';

  @override
  String get statsMetricPlX07Desc => 'Time available for planned work in the period.';

  @override
  String get statsMetricPlX07Formula => 'Work hours per day minus unavailable blocks, summed over the period.';

  @override
  String get statsMetricPlX07Title => 'Capacity';

  @override
  String get statsMetricPlX08Desc => 'How much of your capacity is filled with planned tasks.';

  @override
  String get statsMetricPlX08Formula =>
      'Planned minutes inside work hours ÷ capacity (can exceed 100 % with overlaps).';

  @override
  String get statsMetricPlX08Title => 'Planned utilization';

  @override
  String get statsMetricPlX09Desc => 'How much of your capacity was spent on tracked work.';

  @override
  String get statsMetricPlX09Formula => 'Tracked minutes inside work hours ÷ capacity; needs 60 % tracking coverage.';

  @override
  String get statsMetricPlX09Title => 'Actual utilization';

  @override
  String get statsMetricPlX10Desc => 'Days where more is planned than the time available.';

  @override
  String get statsMetricPlX10Formula => 'Days with planned load > capacity; overbooked minutes = load − capacity.';

  @override
  String get statsMetricPlX10Title => 'Overbooked days';

  @override
  String get statsMetricPlX11Desc => 'Capacity left from now until the end of the period.';

  @override
  String get statsMetricPlX11Formula => 'Remaining capacity − remaining planned time (from now).';

  @override
  String get statsMetricPlX11Title => 'Remaining free time';

  @override
  String get statsMetricPlX12Desc => 'Planned and tracked time per day and category.';

  @override
  String get statsMetricPlX12Formula => 'Sum of planned minutes vs sum of tracked minutes.';

  @override
  String get statsMetricPlX12Title => 'Planned vs actual hours';

  @override
  String get statsMetricPlX13Desc => 'Where your time goes, by category.';

  @override
  String get statsMetricPlX13Formula =>
      'Tracked minutes per category (planned when tracking covers < 60 %); share of total.';

  @override
  String get statsMetricPlX13Title => 'Time by category';

  @override
  String get statsMetricPlX14Desc => 'Weekly time per category.';

  @override
  String get statsMetricPlX14Formula => 'Minutes per category per week.';

  @override
  String get statsMetricPlX14Title => 'Category trend';

  @override
  String get statsMetricPlX15Desc => 'Share of planned time taken by events rather than tasks.';

  @override
  String get statsMetricPlX15Formula => 'Event minutes ÷ (event + task minutes).';

  @override
  String get statsMetricPlX15Title => 'Events vs tasks';

  @override
  String get statsMetricPlX16Desc => 'Where your time goes by task priority.';

  @override
  String get statsMetricPlX16Formula => 'Σ minutes per priority 0–4 (actual when tracked, else planned).';

  @override
  String get statsMetricPlX16Title => 'Time by priority';

  @override
  String get statsMetricPlX17Desc => 'Minutes per tag. A task with several tags counts fully for each one.';

  @override
  String get statsMetricPlX17Formula => 'Σ minutes per tag.';

  @override
  String get statsMetricPlX17Title => 'Time by tag';

  @override
  String get statsMetricPlX18Desc => 'Whether your time and completions go to high-priority work.';

  @override
  String get statsMetricPlX18Formula => 'Share of time on priorities 3–4; completion rate high vs low.';

  @override
  String get statsMetricPlX18Title => 'Priority alignment';

  @override
  String get statsMetricPlX19Desc => 'Your time by category, then by task.';

  @override
  String get statsMetricPlX19Formula => 'Area ∝ minutes (category → task).';

  @override
  String get statsMetricPlX19Title => 'Allocation map';

  @override
  String get statsMetricPlX20Desc => 'Share of your time spent on recurring series rather than one-off tasks.';

  @override
  String get statsMetricPlX20Formula => 'Recurring minutes ÷ all minutes; completions of each.';

  @override
  String get statsMetricPlX20Title => 'Recurring vs one-off';

  @override
  String get statsMetricPlX21Desc => 'Whether tasks usually take longer or shorter than planned.';

  @override
  String get statsMetricPlX21Formula => 'exp(median ln(actual ÷ planned)) − 1; needs 10 tracked occurrences.';

  @override
  String get statsMetricPlX21Title => 'Estimation bias';

  @override
  String get statsMetricPlX22Desc => 'Average size of the gap between planned and actual duration.';

  @override
  String get statsMetricPlX22Formula => 'mean(|actual − planned| ÷ planned) (MAPE).';

  @override
  String get statsMetricPlX22Title => 'Estimation error';

  @override
  String get statsMetricPlX23Desc => 'Extra time to add to estimates so 8 in 10 tasks fit.';

  @override
  String get statsMetricPlX23Formula => 'P80(actual ÷ planned) − 1.';

  @override
  String get statsMetricPlX23Title => 'Suggested buffer';

  @override
  String get statsMetricPlX24Desc => 'Each tracked occurrence by planned and actual duration.';

  @override
  String get statsMetricPlX24Formula => 'Points (planned, actual) with the y = x line and a ±20 % band.';

  @override
  String get statsMetricPlX24Title => 'Planned vs actual';

  @override
  String get statsMetricPlX25Desc => 'How long the tasks you plan usually are.';

  @override
  String get statsMetricPlX25Formula => 'Histogram of planned minutes; median and mean.';

  @override
  String get statsMetricPlX25Title => 'Planned durations';

  @override
  String get statsMetricPlX26Desc => 'Estimation bias and error per category.';

  @override
  String get statsMetricPlX26Formula => 'Bias and MAPE computed within each category.';

  @override
  String get statsMetricPlX26Title => 'Accuracy by category';

  @override
  String get statsMetricPlX27Desc => 'Share of started occurrences that began on time.';

  @override
  String get statsMetricPlX27Formula => 'On-time starts ÷ started occurrences.';

  @override
  String get statsMetricPlX27Title => 'Punctuality';

  @override
  String get statsMetricPlX28Desc => 'Typical delay between the planned and actual start, by weekday and hour.';

  @override
  String get statsMetricPlX28Formula => 'Median, mean and P85 of (actual start − planned start).';

  @override
  String get statsMetricPlX28Title => 'Start delay';

  @override
  String get statsMetricPlX29Desc => 'Share of occurrences moved at least once, in either direction.';

  @override
  String get statsMetricPlX29Formula => 'Occurrences moved ≥ 1× ÷ occurrences in the period.';

  @override
  String get statsMetricPlX29Title => 'Reschedule share';

  @override
  String get statsMetricPlX30Desc => 'How much work was pushed later, and how often moved occurrences move.';

  @override
  String get statsMetricPlX30Formula => 'Σ forward postponement (hours); mean moves per moved occurrence.';

  @override
  String get statsMetricPlX30Title => 'Hours postponed';

  @override
  String get statsMetricPlX31Desc => 'Share of occurrences that ended up later than first planned.';

  @override
  String get statsMetricPlX31Formula => 'Occurrences with final start > first planned start ÷ occurrences.';

  @override
  String get statsMetricPlX31Title => 'Procrastination index';

  @override
  String get statsMetricPlX32Desc => 'Share of scheduled occurrences skipped, and the most common reasons.';

  @override
  String get statsMetricPlX32Formula => 'Skipped ÷ scheduled; reasons ranked by count.';

  @override
  String get statsMetricPlX32Title => 'Skips & reasons';

  @override
  String get statsMetricPlX33Desc => 'When in the week your planned time, tracked time or completions happen.';

  @override
  String get statsMetricPlX33Formula => 'Minutes (or completions) per weekday × hour.';

  @override
  String get statsMetricPlX33Title => 'Busiest hours';

  @override
  String get statsMetricPlX34Desc => 'Completion rate and hours worked on each weekday.';

  @override
  String get statsMetricPlX34Formula => 'Done ÷ closed occurrences and tracked hours per weekday.';

  @override
  String get statsMetricPlX34Title => 'Best working days';

  @override
  String get statsMetricPlX35Desc => 'How often each slot of the week holds planned work.';

  @override
  String get statsMetricPlX35Formula => 'Weeks with a planned task in the slot ÷ weeks in the period.';

  @override
  String get statsMetricPlX35Title => 'Slot occupancy';

  @override
  String get statsMetricPlX36Desc => 'Work-hour slots that never held planned work over at least 4 weeks.';

  @override
  String get statsMetricPlX36Formula => 'Slots inside work hours with 0 % occupancy.';

  @override
  String get statsMetricPlX36Title => 'Unused slots';

  @override
  String get statsMetricPlX37Desc => 'Completion rate by the planned start hour.';

  @override
  String get statsMetricPlX37Formula => 'Done ÷ closed occurrences per hour of planned start.';

  @override
  String get statsMetricPlX37Title => 'Most productive hours';

  @override
  String get statsMetricPlX38Desc => 'Hours spent in uninterrupted blocks of at least the deep-work length.';

  @override
  String get statsMetricPlX38Formula => 'Blocks ≥ 60 min (setting); same-task sessions < 2 min apart are merged.';

  @override
  String get statsMetricPlX38Title => 'Deep work';

  @override
  String get statsMetricPlX39Desc => 'Tracked time outside your work hours, and on weekends.';

  @override
  String get statsMetricPlX39Formula => 'Σ tracked minutes outside work hours; weekend minutes.';

  @override
  String get statsMetricPlX39Title => 'After-hours work';

  @override
  String get statsMetricPlX40Desc => 'How much you use the timer.';

  @override
  String get statsMetricPlX40Formula => 'Sessions, mean session length, share of done occurrences with sessions.';

  @override
  String get statsMetricPlX40Title => 'Timer usage';

  @override
  String get statsMetricPlX41Desc => 'How many done occurrences have tracked time — the data behind duration metrics.';

  @override
  String get statsMetricPlX41Formula => 'Done occurrences with sessions ÷ done occurrences.';

  @override
  String get statsMetricPlX41Title => 'Actual-time coverage';

  @override
  String get statsMetricPlX42Desc =>
      'Consecutive days (or weeks) reaching your completion goal. Days off don’t break it.';

  @override
  String get statsMetricPlX42Formula => 'Days with ≥ N completions in a row; days without capacity are neutral.';

  @override
  String get statsMetricPlX42Title => 'Goal streak';

  @override
  String get statsMetricPlX43Desc => 'How chopped up your free time within work hours is.';

  @override
  String get statsMetricPlX43Formula => '1 − largest free block ÷ total free time (0 = one free block).';

  @override
  String get statsMetricPlX43Title => 'Fragmentation';

  @override
  String get statsMetricPlX44Desc => 'How often you switch category between consecutive sessions.';

  @override
  String get statsMetricPlX44Formula => 'Category changes between consecutive sessions ÷ tracked hours.';

  @override
  String get statsMetricPlX44Title => 'Context switches';

  @override
  String get statsMetricPlX45Desc => 'Weighted score of your time using your category weights (0–4).';

  @override
  String get statsMetricPlX45Formula => '100 · Σ(weight × minutes) ÷ (4 · Σ minutes) over weighted categories.';

  @override
  String get statsMetricPlX45Title => 'Productivity score';

  @override
  String get statsMetricPlX46Desc => 'How far ahead you usually plan tasks.';

  @override
  String get statsMetricPlX46Formula => 'Histogram of (first planned start − creation time), in hours.';

  @override
  String get statsMetricPlX46Title => 'Planning ahead';

  @override
  String get statsMetricQt01Desc => 'Time since your quit date.';

  @override
  String get statsMetricQt01Formula => 'Now − quit date (live).';

  @override
  String get statsMetricQt01Title => 'Time since quitting';

  @override
  String get statsMetricQt02Desc => 'Time since the last use (or your quit date).';

  @override
  String get statsMetricQt02Formula => 'Now − max(quit date, last use) (live).';

  @override
  String get statsMetricQt02Title => 'Current abstinence';

  @override
  String get statsMetricQt03Desc => 'Your longest stretch without using.';

  @override
  String get statsMetricQt03Formula => 'Longest gap between quit date, uses and now.';

  @override
  String get statsMetricQt03Title => 'Longest abstinence';

  @override
  String get statsMetricQt04Desc => 'Local days since quitting without any use.';

  @override
  String get statsMetricQt04Formula => 'Count of closed days with no use.';

  @override
  String get statsMetricQt04Title => 'Abstinent days';

  @override
  String get statsMetricQt05Desc => 'Share of days since quitting without any use.';

  @override
  String get statsMetricQt05Formula => 'Abstinent days ÷ closed days since the quit date.';

  @override
  String get statsMetricQt05Title => 'Abstinent days share';

  @override
  String get statsMetricQt06Desc => 'How many units you did not consume thanks to quitting.';

  @override
  String get statsMetricQt06Formula => 'Baseline per day × days − units used (floored at 0).';

  @override
  String get statsMetricQt06Title => 'Units avoided';

  @override
  String get statsMetricQt07Desc => 'Money not spent thanks to quitting.';

  @override
  String get statsMetricQt07Formula => 'Units avoided each day × unit cost in force that day.';

  @override
  String get statsMetricQt07Title => 'Money saved';

  @override
  String get statsMetricQt08Desc => 'Money spent on uses since quitting.';

  @override
  String get statsMetricQt08Formula => 'Units used × unit cost at the time.';

  @override
  String get statsMetricQt08Title => 'Spent on slips';

  @override
  String get statsMetricQt09Desc => 'What you will save if you keep going.';

  @override
  String get statsMetricQt09Formula => 'Current baseline × unit cost over the next month, year and 5 years.';

  @override
  String get statsMetricQt09Title => 'Savings projection';

  @override
  String get statsMetricQt10Desc => 'Population estimate of life expectancy regained — not a personal prediction.';

  @override
  String get statsMetricQt10Formula =>
      'Units avoided × minutes of life per unit (≈ 20 min per cigarette, Jackson et al. 2025).';

  @override
  String get statsMetricQt10Title => 'Life regained';

  @override
  String get statsMetricQt11Desc => 'Typical recovery milestones after the last cigarette.';

  @override
  String get statsMetricQt11Formula =>
      'Progress = current abstinence ÷ milestone time; the clock restarts after a slip.';

  @override
  String get statsMetricQt11Title => 'Health milestones';

  @override
  String get statsMetricQt12Desc => 'How often you stayed within your daily limit, and how much you cut down.';

  @override
  String get statsMetricQt12Formula => 'Days within limit ÷ days; reduction = 1 − average use ÷ baseline.';

  @override
  String get statsMetricQt12Title => 'Reduction progress';

  @override
  String get statsMetricQt13Desc => 'How often cravings hit, and how strong they were.';

  @override
  String get statsMetricQt13Formula => 'Cravings per day over the period; mean and peak intensity; 7-day rolling mean.';

  @override
  String get statsMetricQt13Title => 'Craving load';

  @override
  String get statsMetricQt14Desc => 'What triggers cravings, where and when.';

  @override
  String get statsMetricQt14Formula => 'Pareto by trigger, place and mood; weekday × hour matrix.';

  @override
  String get statsMetricQt14Title => 'Craving context';

  @override
  String get statsMetricQt15Desc => 'Share of cravings that passed without a use.';

  @override
  String get statsMetricQt15Formula =>
      'Cravings not followed by a use within 2 h ÷ cravings (your “resisted” answer wins).';

  @override
  String get statsMetricQt15Title => 'Cravings resisted';

  @override
  String get statsMetricQt16Desc => 'How long your cravings last. Most pass within a few minutes.';

  @override
  String get statsMetricQt16Formula => 'Median and P85 of craving durations; cravings typically last 3–5 min (HSE).';

  @override
  String get statsMetricQt16Title => 'Craving duration';

  @override
  String get statsMetricQt17Desc => 'How cravings per day change week by week since you quit.';

  @override
  String get statsMetricQt17Formula =>
      'Cravings per day for each week since the quit date; % change of the last full week vs week 1.';

  @override
  String get statsMetricQt17Title => 'Cravings over time';

  @override
  String get statsMetricQt18Desc => 'Each attempt and whether it had a slip — every clean day still counts.';

  @override
  String get statsMetricQt18Formula =>
      'Slip = any use; setback = use on 7 days in a row or in 2 consecutive 7-day blocks (SRNT).';

  @override
  String get statsMetricQt18Title => 'Slips and attempts';

  @override
  String get statsMetricQt19Desc => 'When uses happen and what came just before them.';

  @override
  String get statsMetricQt19Formula =>
      'Uses by weekday × hour; amount per use; days between use days; triggers logged up to 2 h before a use.';

  @override
  String get statsMetricQt19Title => 'Use patterns';

  @override
  String get statsMetricQt20Desc => 'Your attempts and how long each one lasted.';

  @override
  String get statsMetricQt20Formula => 'Number of attempts; mean and longest duration; rank of the current one.';

  @override
  String get statsMetricQt20Title => 'Quit attempts';

  @override
  String get statsMetricQt21Desc => 'Progress toward what you are saving for.';

  @override
  String get statsMetricQt21Formula => 'Money saved ÷ goal price; ETA = remaining ÷ current daily saving.';

  @override
  String get statsMetricQt21Title => 'Savings goal';

  @override
  String get statsMetricQt22Desc => 'Time you are no longer spending consuming.';

  @override
  String get statsMetricQt22Formula => 'Units avoided × time per unit.';

  @override
  String get statsMetricQt22Title => 'Time won back';

  @override
  String get statsMetricQt23Desc => 'How much you save each week or month.';

  @override
  String get statsMetricQt23Formula => 'Money saved per week (per month for long periods); mean saved per day.';

  @override
  String get statsMetricQt23Title => 'Money saved by period';

  @override
  String get statsMetricQt24Desc => 'Days in a row you renewed your pledge.';

  @override
  String get statsMetricQt24Formula => 'Consecutive days with a pledge or review.';

  @override
  String get statsMetricQt24Title => 'Pledge streak';

  @override
  String get statsMetricQt25Desc => 'Where you are in the typical withdrawal timeline. Individual experience varies.';

  @override
  String get statsMetricQt25Formula => 'Days 1–3 peak, rest of week 1 hardest, weeks 2–4 easing (NCI fact sheet).';

  @override
  String get statsMetricQt25Title => 'Withdrawal phase';

  @override
  String get statsMetricQt26Desc => 'How long attempts usually last before a first slip, across attempts.';

  @override
  String get statsMetricQt26Formula =>
      'Kaplan–Meier curve (the current attempt counts as still going); median time, or “not reached”.';

  @override
  String get statsMetricQt26Title => 'Time to first slip';

  @override
  String get statsMetricQt27Desc => 'Which coping tools help you get through cravings.';

  @override
  String get statsMetricQt27Formula =>
      'Cravings resisted per coping tool (tools with fewer than 5 cravings are greyed out).';

  @override
  String get statsMetricQt27Title => 'Coping that works';

  @override
  String get statsMetricQt28Desc => 'Time since your last craving and your longest craving-free stretch.';

  @override
  String get statsMetricQt28Formula => 'Now − last craving; longest gap between cravings since the quit date.';

  @override
  String get statsMetricQt28Title => 'Craving-free time';

  @override
  String get statsNoteAbstainMode => 'Only for reduce-mode trackers.';

  @override
  String get statsNoteAllDay => 'All-day tasks have no duration.';

  @override
  String get statsNoteClosed => 'This item is closed.';

  @override
  String get statsNoteCorrelationNotCausation =>
      'Correlation is not causation: these pairs move together, nothing more.';

  @override
  String get statsNoteCravingPasses => 'A craving usually passes within a few minutes';

  @override
  String get statsNoteError => 'Couldn’t compute';

  @override
  String get statsNoteGamificationOff => 'XP is off. Turn it on in Insights settings.';

  @override
  String get statsNoteLimitHabit => 'Limit habits show within-limit days instead.';

  @override
  String get statsNoteLowCoverage => 'Track time on at least 60 % of done tasks to see this.';

  @override
  String get statsNoteNeedsMoreData => 'Needs more data';

  @override
  String get statsNoteNew => 'New';

  @override
  String get statsNoteNoCategoryWeights => 'Give categories a weight (0–4) in Settings to see this score';

  @override
  String get statsNoteNoConsistentTime => 'No consistent time of day';

  @override
  String get statsNoteNoCoping => 'Note a coping tool when you log a craving to see this';

  @override
  String get statsNoteNoData => 'No data yet';

  @override
  String get statsNoteNoFreeTime => 'No free time within work hours';

  @override
  String get statsNoteNoFreezes => 'This habit has no streak freezes';

  @override
  String get statsNoteNoGoal => 'No goal set';

  @override
  String get statsNoteNoHabit => 'This habit couldn’t be found.';

  @override
  String get statsNoteNoItem => 'This item couldn’t be found.';

  @override
  String get statsNoteNoLifeEstimate => 'Set minutes of life per unit to see this estimate.';

  @override
  String get statsNoteNoMood => 'Log your mood on check-ins to see this';

  @override
  String get statsNoteNoOccurrence => 'This occurrence couldn’t be found.';

  @override
  String get statsNoteNoQuitTrackers => 'No quit trackers yet.';

  @override
  String get statsNoteNoRating => 'No rating yet';

  @override
  String get statsNoteNoReminders => 'No reminders for this habit yet';

  @override
  String get statsNoteNoRuns => 'This list has no runs yet (it is not resettable or was never reset)';

  @override
  String get statsNoteNoSignificantPairs => 'No pair of habits stands out yet';

  @override
  String get statsNoteNoTimePerUnit => 'Set the time per unit in the tracker to see this';

  @override
  String get statsNoteNoTracker => 'This quit tracker couldn’t be found.';

  @override
  String get statsNoteNoUnitCost => 'Set a unit cost to see savings.';

  @override
  String get statsNoteNoUses => 'No uses logged — keep going';

  @override
  String get statsNoteNonCausal => 'An association, not a cause';

  @override
  String get statsNoteNotApplicable => 'Not applicable';

  @override
  String get statsNoteNotDone => 'Not done yet';

  @override
  String get statsNoteNotIntraday => 'Only for habits with time slots';

  @override
  String get statsNoteNotLimitHabit => 'Only for habits with a limit';

  @override
  String get statsNoteNotOverdue => 'Not overdue';

  @override
  String get statsNoteNotScheduled => 'Not scheduled';

  @override
  String get statsNoteNotSmoking => 'Health milestones are shown for smoking trackers only.';

  @override
  String get statsNoteNotSnowballing => 'Moved fewer than 3 times';

  @override
  String get statsNoteNotStarted => 'Not started';

  @override
  String get statsNoteNotTracked => 'Actual time not tracked';

  @override
  String get statsNoteOftenTogether => 'Often done together — not a cause';

  @override
  String get statsNoteOncePerDay => 'Only for habits done several times a day';

  @override
  String get statsNotePastPeriod => 'Only for current and future periods.';

  @override
  String get statsNotePopulationEstimate => 'Population estimate';

  @override
  String get statsNoteSlipSupport => 'A slip is part of many quit journeys — every clean day still counts';

  @override
  String get statsNoteTagsOverlap => 'Some tasks have several tags: totals overlap';

  @override
  String get statsNoteTypicalVaries => 'Typical timeline — individual experience varies';

  @override
  String get statsNoteUnloggedNotFailed =>
      'Unlogged days are unknown, not failed — they only count as missed because nothing was recorded.';

  @override
  String get statsNoteUnstableFlow => 'Flow is unstable: averages may mislead';

  @override
  String get statsNoteUsedPlanned => 'Planned time shown: actual time is tracked on fewer than 60 % of done tasks.';

  @override
  String get statsNoteYesNoHabit => 'Not available for yes/no habits.';

  @override
  String get statsNoteZeroDenominator => 'Nothing was due in this period.';

  @override
  String statsOpenInsights(String section) {
    return 'Open $section';
  }

  @override
  String get statsOverviewMore => 'More reports';

  @override
  String statsOverviewNextUp(String title, String time) {
    return 'Next up: $title at $time';
  }

  @override
  String get statsOverviewOpenReview => 'Weekly review';

  @override
  String get statsOverviewStartGuided => 'Guided review';

  @override
  String get statsPeriodAll => 'All';

  @override
  String get statsPeriodCustom => 'Custom';

  @override
  String statsPeriodCustomRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get statsPeriodLastMonth => 'Last month';

  @override
  String get statsPeriodLastQuarter => 'Last quarter';

  @override
  String get statsPeriodLastWeek => 'Last week';

  @override
  String get statsPeriodLastYear => 'Last year';

  @override
  String get statsPeriodMonth => 'Month';

  @override
  String get statsPeriodQuarter => 'Quarter';

  @override
  String statsPeriodRolling(String days) {
    return 'Last $days days';
  }

  @override
  String get statsPeriodRollingMenu => 'Rolling';

  @override
  String statsPeriodSelected(String period) {
    return 'Period: $period';
  }

  @override
  String get statsPeriodToday => 'Today';

  @override
  String get statsPeriodWeek => 'Week';

  @override
  String get statsPeriodYear => 'Year';

  @override
  String get statsPeriodYesterday => 'Yesterday';

  @override
  String get statsQuitMilestoneBreathing72h => 'Breathing gets easier; energy rises';

  @override
  String get statsQuitMilestoneCancers20y => 'Mouth, throat, larynx and pancreas cancer risk near a never-smoker’s';

  @override
  String get statsQuitMilestoneChd15y => 'Coronary heart disease risk close to a non-smoker’s';

  @override
  String get statsQuitMilestoneChdAdded => 'Added coronary heart disease risk halves';

  @override
  String get statsQuitMilestoneCirculation => 'Circulation and lung function improve';

  @override
  String get statsQuitMilestoneCo12h => 'Blood carbon monoxide back to normal';

  @override
  String get statsQuitMilestoneCo8h => 'Carbon monoxide in the blood is halved; oxygen levels recover';

  @override
  String get statsQuitMilestoneCravings => 'Cravings usually ease (a single craving lasts about 3–5 min)';

  @override
  String get statsQuitMilestoneHeart20m => 'Heart rate and blood pressure drop; pulse returns to normal';

  @override
  String get statsQuitMilestoneHeartAttack => 'Heart-attack risk drops sharply';

  @override
  String get statsQuitMilestoneHeartHalf1y => 'Coronary heart disease risk about half that of a smoker';

  @override
  String get statsQuitMilestoneLifeExpectancy =>
      'Quitting at 30 / 40 / 50 / 60 gains about 10 / 9 / 6 / 3 years of life expectancy';

  @override
  String get statsQuitMilestoneLungCancer10y => 'Lung-cancer risk about half that of a smoker';

  @override
  String get statsQuitMilestoneLungs => 'Coughing and shortness of breath decrease; lung function up to ~10 % better';

  @override
  String get statsQuitMilestoneMouthCancer => 'Mouth, throat and larynx cancer risk halves; stroke risk falls';

  @override
  String get statsQuitMilestoneNicotine24h => 'Nicotine in the blood falls to zero';

  @override
  String get statsQuitMilestoneTaste48h => 'Lungs clear mucus; taste and smell improve';

  @override
  String statsReviewAtRisk(String title) {
    return 'At risk: $title';
  }

  @override
  String statsReviewBlocked(String title) {
    return 'Blocked or waiting: $title';
  }

  @override
  String statsReviewFollowUp(String title) {
    return 'Follow-up overdue: $title';
  }

  @override
  String get statsReviewHeadline => 'Headline numbers';

  @override
  String statsReviewHealth(String title) {
    return 'Health milestone reached: $title';
  }

  @override
  String get statsReviewLastMonth => 'Last month';

  @override
  String get statsReviewLastWeek => 'Last week';

  @override
  String statsReviewLoad(String planned, String capacity) {
    return '$planned planned of $capacity';
  }

  @override
  String get statsReviewNextWeek => 'Next week';

  @override
  String get statsReviewNothing => 'Nothing here this week.';

  @override
  String statsReviewOverbooked(String date, String time) {
    return '$date is overbooked by $time';
  }

  @override
  String statsReviewOverdue(String title) {
    return 'Overdue: $title';
  }

  @override
  String get statsReviewPerDayNote => 'Months have different lengths: totals are compared as per-day averages.';

  @override
  String statsReviewPerfectDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perfect days',
      one: '1 perfect day',
    );
    return '$_temp0';
  }

  @override
  String statsReviewRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String statsReviewRecord(String title) {
    return 'New record: $title';
  }

  @override
  String get statsReviewShareWeek => 'Share week summary';

  @override
  String statsReviewStale(String title) {
    return 'No recent activity: $title';
  }

  @override
  String statsReviewStreak(String title, String count) {
    return '$title: $count-day streak';
  }

  @override
  String get statsReviewThisMonth => 'This month so far';

  @override
  String get statsReviewThisWeek => 'This week so far';

  @override
  String get statsReviewTime => 'Where the time went';

  @override
  String get statsScopeBudget => 'Time budget';

  @override
  String get statsScopeChecklist => 'List insights';

  @override
  String get statsScopeChecklists => 'Lists insights';

  @override
  String get statsScopeDashboards => 'Dashboards';

  @override
  String get statsScopeFeed => 'Insights';

  @override
  String get statsScopeGlobal => 'Overview';

  @override
  String get statsScopeGoals => 'Goals';

  @override
  String get statsScopeGuided => 'Guided weekly review';

  @override
  String get statsScopeHabit => 'Habit insights';

  @override
  String get statsScopeHabits => 'Habits insights';

  @override
  String get statsScopeItem => 'Item insights';

  @override
  String get statsScopeMonth => 'Monthly review';

  @override
  String get statsScopePatterns => 'Patterns';

  @override
  String get statsScopePlanner => 'Plan insights';

  @override
  String get statsScopeQuit => 'Quit insights';

  @override
  String get statsScopeRecords => 'Personal records';

  @override
  String get statsScopeReview => 'Weekly review';

  @override
  String get statsScopeSeries => 'Series insights';

  @override
  String get statsScopeTask => 'Task insights';

  @override
  String get statsScopeWrapped => 'Year in review';

  @override
  String get statsScopeYear => 'Year in review';

  @override
  String get statsSectionAbstinence => 'Abstinence';

  @override
  String get statsSectionActivity => 'Activity';

  @override
  String get statsSectionAdvanced => 'Advanced';

  @override
  String get statsSectionAllocation => 'Time allocation';

  @override
  String get statsSectionAttachments => 'Attachments & edits';

  @override
  String get statsSectionBlockers => 'Blocked & waiting';

  @override
  String get statsSectionBudget => 'Time budget';

  @override
  String get statsSectionBurn => 'Burn-down & scope';

  @override
  String get statsSectionCalendar => 'Calendar';

  @override
  String get statsSectionCapacity => 'Capacity';

  @override
  String statsSectionCollapse(String section) {
    return 'Collapse $section';
  }

  @override
  String get statsSectionCorrelations => 'Correlations';

  @override
  String get statsSectionCravings => 'Cravings';

  @override
  String get statsSectionCycleTime => 'Cycle time';

  @override
  String get statsSectionDataQuality => 'Data quality';

  @override
  String get statsSectionExecution => 'Execution';

  @override
  String statsSectionExpand(String section) {
    return 'Expand $section';
  }

  @override
  String get statsSectionFlow => 'Flow';

  @override
  String get statsSectionFocus => 'Focus & balance';

  @override
  String get statsSectionForecast => 'Forecast';

  @override
  String get statsSectionGoals => 'Goals';

  @override
  String get statsSectionHabitTable => 'Your habits';

  @override
  String get statsSectionHistory => 'History';

  @override
  String get statsSectionItem => 'This item';

  @override
  String get statsSectionLists => 'Lists';

  @override
  String get statsSectionMilestones => 'Health milestones';

  @override
  String get statsSectionMoney => 'Money & units';

  @override
  String get statsSectionMonth => 'Month';

  @override
  String get statsSectionOccurrence => 'This occurrence';

  @override
  String get statsSectionOutcomes => 'Outcomes';

  @override
  String get statsSectionPatterns => 'Patterns';

  @override
  String get statsSectionPinned => 'Pinned';

  @override
  String get statsSectionPlanning => 'Planning';

  @override
  String get statsSectionPlanningQuality => 'Planning quality';

  @override
  String get statsSectionProgress => 'Progress';

  @override
  String get statsSectionQuality => 'Quality';

  @override
  String get statsSectionQuitTrackers => 'Quit trackers';

  @override
  String get statsSectionRecords => 'Records';

  @override
  String get statsSectionReduction => 'Reduction';

  @override
  String get statsSectionReview => 'Weekly review';

  @override
  String get statsSectionRuns => 'Routine runs';

  @override
  String get statsSectionScore => 'Day score';

  @override
  String get statsSectionSeries => 'Execution';

  @override
  String get statsSectionShortcuts => 'Sections';

  @override
  String get statsSectionStale => 'Stale items';

  @override
  String get statsSectionStatus => 'Status';

  @override
  String get statsSectionStreaks => 'Streaks';

  @override
  String get statsSectionStrength => 'Strength';

  @override
  String get statsSectionTargetVolume => 'Target & volume';

  @override
  String get statsSectionTiming => 'Timing & patterns';

  @override
  String get statsSectionToday => 'Today';

  @override
  String get statsSectionTree => 'Tree';

  @override
  String get statsSectionTrend => 'Trend';

  @override
  String get statsSectionWeek => 'Week at a glance';

  @override
  String get statsSectionYearInReview => 'Year in review';

  @override
  String get statsSeeAll => 'See all stats';

  @override
  String get statsSeeSeries => 'See series stats';

  @override
  String get statsSegmentHabits => 'Habits';

  @override
  String get statsSegmentLists => 'Lists';

  @override
  String get statsSegmentOverview => 'Overview';

  @override
  String get statsSegmentPlan => 'Plan';

  @override
  String get statsSegmentQuit => 'Quit';

  @override
  String get statsSourceAcs => 'American Cancer Society';

  @override
  String get statsSourceBmj2000 => 'Shaw et al., BMJ 2000';

  @override
  String get statsSourceCdc => 'CDC';

  @override
  String get statsSourceHse => 'HSE';

  @override
  String get statsSourceJackson2025 => 'Jackson et al., Addiction 2025';

  @override
  String get statsSourceLally2010 => 'Lally et al. 2010 (European Journal of Social Psychology)';

  @override
  String get statsSourceNci => 'National Cancer Institute';

  @override
  String get statsSourceNhs => 'NHS';

  @override
  String get statsSourceWho => 'WHO';

  @override
  String get statsUnknownScope => 'This insight doesn’t exist.';

  @override
  String statsWeekdayEffect(String metric, String best, String worst) {
    return '$metric: best on $best, weakest on $worst';
  }

  @override
  String statsWeekdayNoPattern(String metric) {
    return '$metric: no clear weekday pattern';
  }

  @override
  String get statsWrappedEmpty => 'Not enough data for this year yet.';

  @override
  String get statsWrappedNext => 'Next card';

  @override
  String get statsWrappedOpen => 'Open year in review';

  @override
  String get statsWrappedPrevious => 'Previous card';

  @override
  String get statsWrappedReady => 'Your year in review is ready';

  @override
  String get statsWrappedShare => 'Share summary';

  @override
  String statsWrappedTitle(int year) {
    final intl.NumberFormat yearNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String yearString = yearNumberFormat.format(year);

    return 'Your $yearString';
  }

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
  String get tagsEmptyHint => 'Tags work across sections — use them for contexts like errands or waiting on others.';

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
  String get tasksAddTag => 'Add a tag';

  @override
  String tasksAnchorMoved(String date) {
    return 'Start moved to $date to match the repeat rule';
  }

  @override
  String get tasksAttachments => 'Attachments';

  @override
  String get tasksAttachmentsPlaceholder => 'Photos and files will be available here soon';

  @override
  String get tasksBacklogLabel => 'Unscheduled';

  @override
  String get tasksBulkAddTags => 'Add tags';

  @override
  String get tasksBulkDelete => 'Delete';

  @override
  String tasksBulkDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items?',
      one: 'Delete 1 item?',
    );
    return '$_temp0';
  }

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
  String get tasksChecklistNew => 'New checklist';

  @override
  String get tasksChecklistNewName => 'Checklist name';

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
  String get tasksDayDoneAll => 'Mark all remaining as done';

  @override
  String tasksDayDoneAllSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks marked as done',
      one: '1 task marked as done',
      zero: 'Nothing left to mark',
    );
    return '$_temp0';
  }

  @override
  String get tasksDayMoveTomorrow => 'Move unfinished to tomorrow';

  @override
  String tasksDayMoveTomorrowSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks moved to tomorrow',
      one: '1 task moved to tomorrow',
      zero: 'Nothing to move',
    );
    return '$_temp0';
  }

  @override
  String get tasksDaySkipRest => 'Skip the rest of the day';

  @override
  String tasksDaySkipRestSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks skipped',
      one: '1 task skipped',
      zero: 'Nothing left to skip',
    );
    return '$_temp0';
  }

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
  String get tasksErrDuration => 'Duration must be between 0 minutes and 365 days';

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
  String get tasksErrTitleTooLong => 'The title is too long (300 characters max)';

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
  String get tasksFieldTags => 'Tags';

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
  String get tasksNotifAlreadyClosed => 'Already done or skipped';

  @override
  String get tasksNotifGone => 'This task no longer exists';

  @override
  String get tasksOccurrenceDeleted => 'Occurrence removed';

  @override
  String tasksOpenLinkBody(String url) {
    return '$url will open outside Everslot.';
  }

  @override
  String get tasksOpenLinkTitle => 'Open link?';

  @override
  String get tasksOrphansBody => 'Occurrences with history are always kept as one-off tasks.';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'and $count more', one: 'and 1 more');
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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '+$count days', one: '+1 day');
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
  String tasksQuickRescheduleHour(String time) {
    return 'In 1 hour ($time)';
  }

  @override
  String get tasksQuickRescheduleTitle => 'Reschedule';

  @override
  String tasksQuickRescheduleTomorrow(String time) {
    return 'Tomorrow at $time';
  }

  @override
  String tasksQuickRescheduleTonight(String time) {
    return 'Tonight at $time';
  }

  @override
  String get tasksQuickRescheduled => 'Rescheduled';

  @override
  String get tasksQuickTitleHint => 'New task';

  @override
  String get tasksQuotaDone => 'Done for this period';

  @override
  String tasksQuotaIndicator(String title, int done, int total, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'today',
      'week': 'this week',
      'month': 'this month',
      'year': 'this year',
      'other': 'this period',
    });
    return '$title · $done/$total $_temp0';
  }

  @override
  String tasksQuotaIndicatorDone(String title, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'done for today',
      'week': 'done for this week',
      'month': 'done for this month',
      'year': 'done for this year',
      'other': 'done for this period',
    });
    return '$title · $_temp0';
  }

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
  String get tasksScopePastKept => 'Past occurrences keep their original times.';

  @override
  String get tasksScopeRewritePast => 'Also rewrite past occurrences';

  @override
  String get tasksScopeThis => 'This occurrence';

  @override
  String get tasksScopeThisDisabled => 'Only the time, duration, title and notes can change for a single occurrence.';

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
  String get tasksTemplatesEmpty => 'No templates yet. Save a task as a template from its menu.';

  @override
  String get tasksTemplatesTitle => 'Templates';

  @override
  String get tasksTimeEntries => 'Sessions';

  @override
  String get tasksTimeTracking => 'Time tracking';

  @override
  String get tasksTooManyOccurrences => 'Too many occurrences to display — zoom in';

  @override
  String tasksTracked(String duration) {
    return 'Tracked: $duration';
  }

  @override
  String get tasksTrackingCheck => 'Check';

  @override
  String get tasksTrackingCheckHint => 'Mark it done or skip it; it can be missed.';

  @override
  String get tasksTrackingEvent => 'Event';

  @override
  String get tasksTrackingEventHint => 'A time block (meeting, meal): no checkbox, never missed.';

  @override
  String get tasksTrackingTimer => 'Timer';

  @override
  String get tasksTrackingTimerHint => 'Track the time you spend; done when you stop the timer.';

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

  @override
  String undoDoneSnack(String action) {
    return 'Undone: $action';
  }

  @override
  String get undoNothing => 'Nothing to undo';

  @override
  String get voiceNoteDiscard => 'Discard';

  @override
  String get voiceNoteHint => 'Tap the microphone and speak.';

  @override
  String get voiceNoteMicPrimerBody =>
      'Everslot uses the microphone only while you record a voice note. Recordings stay on your device until they\'re uploaded to your account.';

  @override
  String get voiceNoteMicPrimerTitle => 'Microphone access';

  @override
  String get voiceNoteRecord => 'Start recording';

  @override
  String voiceNoteRecording(String duration) {
    return 'Recording, $duration';
  }

  @override
  String get voiceNoteSave => 'Attach';

  @override
  String get voiceNoteStop => 'Stop recording';

  @override
  String get voiceNoteTitle => 'Voice note';
}
