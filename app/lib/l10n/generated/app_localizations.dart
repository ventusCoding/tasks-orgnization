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
