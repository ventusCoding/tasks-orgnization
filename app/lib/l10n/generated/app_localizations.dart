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

  /// No description provided for @recurAddDate.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get recurAddDate;

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

  /// No description provided for @recurAnchorMoved.
  ///
  /// In en, this message translates to:
  /// **'First occurrence: {date}'**
  String recurAnchorMoved(String date);

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

  /// No description provided for @recurOrdinalSecondLast.
  ///
  /// In en, this message translates to:
  /// **'2nd to last'**
  String get recurOrdinalSecondLast;

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
