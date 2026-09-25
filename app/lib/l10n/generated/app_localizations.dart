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
