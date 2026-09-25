// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get actionAdd => 'إضافة';

  @override
  String get actionApply => 'تطبيق';

  @override
  String get actionArchive => 'أرشفة';

  @override
  String get actionBack => 'رجوع';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionClear => 'مسح';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionConfirm => 'تأكيد';

  @override
  String get actionContinue => 'متابعة';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionDone => 'تم';

  @override
  String get actionDuplicate => 'تكرار';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get actionInbox => 'الإشعارات';

  @override
  String get actionMore => 'المزيد';

  @override
  String get actionNext => 'التالي';

  @override
  String get actionOpen => 'فتح';

  @override
  String get actionRedo => 'إعادة';

  @override
  String get actionRestore => 'استعادة';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionSearch => 'بحث';

  @override
  String get actionSettings => 'الإعدادات';

  @override
  String get actionShare => 'مشاركة';

  @override
  String get actionSkip => 'تخطٍّ';

  @override
  String get actionToday => 'اليوم';

  @override
  String get actionUndo => 'تراجع';

  @override
  String get appName => 'Everslot';

  @override
  String get appTagline => 'تحكّم في كل خانة من يومك.';

  @override
  String get categoriesEmpty => 'لا توجد تصنيفات بعد';

  @override
  String get categoriesTitle => 'التصنيفات';

  @override
  String get categoryArchived => 'مؤرشف';

  @override
  String get categoryDefaultHealth => 'الصحة';

  @override
  String get categoryDefaultHome => 'المنزل';

  @override
  String get categoryDefaultPersonal => 'شخصي';

  @override
  String get categoryDefaultSocial => 'اجتماعي';

  @override
  String get categoryDefaultStudy => 'الدراسة';

  @override
  String get categoryDefaultWork => 'العمل';

  @override
  String get categoryDeleteBody => 'ستبقى العناصر في هذا التصنيف بدون تصنيف.';

  @override
  String get categoryEdit => 'تعديل التصنيف';

  @override
  String get categoryName => 'الاسم';

  @override
  String get categoryNew => 'تصنيف جديد';

  @override
  String get categoryNone => 'بلا تصنيف';

  @override
  String get categoryPick => 'التصنيف';

  @override
  String get categoryUnavailable => 'يُحتسب وقتًا غير متاح';

  @override
  String get categoryUnavailableHint =>
      'يُستثنى من إحصاءات السعة (مثل النوم والإجازات).';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get confirmDeleteBody =>
      'يمكنك استعادته من سلة المحذوفات خلال 30 يومًا.';

  @override
  String confirmDeleteTitle(String item) {
    return 'حذف $item؟';
  }

  @override
  String deletedSnack(String item) {
    return 'تم حذف $item';
  }

  @override
  String get devMenu => 'قائمة المطوّر';

  @override
  String durationDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يومًا',
      few: '$days أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String durationHoursShort(int hours) {
    return '$hours س';
  }

  @override
  String durationMinutesShort(int minutes) {
    return '$minutes د';
  }

  @override
  String get errorAuth => 'يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errorNetwork => 'تعذّر الوصول إلى الخادم. تحقّق من اتصالك.';

  @override
  String get errorNotConfigured =>
      'هذه الميزة تتطلّب إعداد السحابة (راجع guide.md).';

  @override
  String get errorNotFound => 'هذا العنصر لم يعد موجودًا.';

  @override
  String get errorPermission => 'هذا يتطلّب إذنًا.';

  @override
  String get errorUnknown => 'خطأ غير متوقّع.';

  @override
  String get errorUnsupportedVersion => 'يرجى تحديث Everslot لمتابعة المزامنة.';

  @override
  String get errorValidation => 'يرجى مراجعة الحقول المحدّدة.';

  @override
  String get localOnlyBanner =>
      'مزامنة السحابة غير مُعدّة — بياناتك تبقى على هذا الجهاز.';

  @override
  String get notFoundTitle => 'الصفحة غير موجودة';

  @override
  String get notifActionComplete => 'أكمل';

  @override
  String get notifActionDone => 'تم';

  @override
  String get notifActionInputPlaceholder => 'القيمة';

  @override
  String get notifActionLogCraving => 'سجّل رغبة';

  @override
  String get notifActionLogValue => 'سجّل قيمة';

  @override
  String get notifActionMarkBlocked => 'محظور';

  @override
  String get notifActionMarkOngoing => 'قيد التنفيذ';

  @override
  String get notifActionMarkRead => 'تعليم كمقروء';

  @override
  String get notifActionMarkWaiting => 'في الانتظار';

  @override
  String get notifActionMute => 'اكتم';

  @override
  String get notifActionOpen => 'افتح';

  @override
  String get notifActionReschedule => 'أعد الجدولة';

  @override
  String get notifActionSend => 'إرسال';

  @override
  String get notifActionSkip => 'تخطَّ';

  @override
  String get notifActionSnooze => 'أجّل';

  @override
  String get notifActionStart => 'ابدأ';

  @override
  String get notifActionStop => 'أوقف';

  @override
  String get notifActions => 'الإجراءات';

  @override
  String get notifAddReminder => 'إضافة تذكير';

  @override
  String get notifAdjCatchUp => 'متأخر';

  @override
  String get notifAdjDeferred => 'مؤجل (ساعات الهدوء)';

  @override
  String get notifAdjNotLocal => 'يُسلَّم على جهاز آخر';

  @override
  String get notifAdjPaused => 'متوقف مؤقتًا — صندوق الوارد فقط';

  @override
  String get notifAdjShifted => 'نُقل إلى النافذة الزمنية';

  @override
  String get notifAdjSilent => 'صامت (ساعات الهدوء)';

  @override
  String get notifAdvanced => 'متقدم…';

  @override
  String get notifAdvancedTitle => 'قاعدة التذكير';

  @override
  String get notifAfter => 'بعد';

  @override
  String get notifAllowPrecise => 'السماح بالتذكيرات الدقيقة';

  @override
  String get notifAnchorDue => 'الموعد النهائي';

  @override
  String get notifAnchorEnd => 'الانتهاء';

  @override
  String get notifAnchorFollowUp => 'المتابعة';

  @override
  String get notifAnchorPeriodEnd => 'نهاية الفترة';

  @override
  String get notifAnchorPeriodStart => 'بداية الفترة';

  @override
  String get notifAnchorSlot => 'الموعد';

  @override
  String get notifAnchorStart => 'البدء';

  @override
  String get notifAndroidLabel => 'Android';

  @override
  String get notifBadgeDue => 'المتأخر + مستحق اليوم';

  @override
  String get notifBadgeOff => 'متوقفة';

  @override
  String get notifBadgePolicy => 'شارة أيقونة التطبيق';

  @override
  String get notifBadgeUnread => 'غير المقروء';

  @override
  String notifBannerCollapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكير',
      many: '$count تذكيرًا',
      few: '$count تذكيرات',
      two: 'تذكيران',
      one: 'تذكير واحد',
      zero: 'لا تذكيرات',
    );
    return '$_temp0';
  }

  @override
  String get notifBannerDismiss => 'إغلاق';

  @override
  String get notifBannerInApp => 'أشرطة داخل التطبيق';

  @override
  String get notifBannerToggle => 'شريط داخل التطبيق';

  @override
  String get notifBefore => 'قبل';

  @override
  String get notifBodyChildOverdue => 'عنصر فرعي متأخر';

  @override
  String get notifBodyChildrenComplete =>
      'اكتملت كل العناصر الفرعية — هل تكمله؟';

  @override
  String notifBodyCleanDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يومًا',
      few: '$days أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '$days يوم',
    );
    return '$_temp0 دون انتكاس — أحسنت!';
  }

  @override
  String notifBodyDueIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتين',
      one: 'دقيقة',
      zero: '$minutes دقيقة',
    );
    return 'الموعد النهائي خلال $_temp0';
  }

  @override
  String get notifBodyDueNow => 'حان الموعد النهائي';

  @override
  String notifBodyEndedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتين',
      one: 'دقيقة',
      zero: '$minutes دقيقة',
    );
    return 'انتهى منذ $_temp0';
  }

  @override
  String get notifBodyEndingNow => 'ينتهي الآن';

  @override
  String notifBodyEndsIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتين',
      one: 'دقيقة',
      zero: '$minutes دقيقة',
    );
    return 'ينتهي خلال $_temp0';
  }

  @override
  String notifBodyInDays(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يومًا',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم واحد',
      zero: '$days يوم',
    );
    return 'بعد $_temp0 · $date';
  }

  @override
  String notifBodyInactivity(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يومًا',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم واحد',
      zero: '$days يوم',
    );
    return 'لا نشاط منذ $_temp0';
  }

  @override
  String notifBodyMilestone(String label) {
    return 'تم بلوغ إنجاز: $label';
  }

  @override
  String notifBodyNotDone(String title) {
    return 'لم تسجّل $title اليوم';
  }

  @override
  String notifBodyOverdue(String title) {
    return '$title متأخر';
  }

  @override
  String notifBodyQuotaBehind(String done, String target, int remaining) {
    return 'أُنجز $done/$target — بقي $remaining';
  }

  @override
  String get notifBodySnoozed => 'تذكير مؤجل';

  @override
  String notifBodyStartedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتين',
      one: 'دقيقة',
      zero: '$minutes دقيقة',
    );
    return 'بدأ منذ $_temp0';
  }

  @override
  String get notifBodyStartingNow => 'يبدأ الآن';

  @override
  String notifBodyStartsIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتين',
      one: 'دقيقة',
      zero: '$minutes دقيقة',
    );
    return 'يبدأ خلال $_temp0';
  }

  @override
  String notifBodyStatusAge(String status, String age) {
    return 'ما زال $status · $age';
  }

  @override
  String notifBodyStatusChange(String status) {
    return 'أصبح الآن $status';
  }

  @override
  String notifBodyStreakRisk(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '($days يوم)',
      many: '($days يومًا)',
      few: '($days أيام)',
      two: '(يومان)',
      one: '(يوم واحد)',
      zero: '($days يوم)',
    );
    return 'حافظ على سلسلتك $_temp0';
  }

  @override
  String get notifBodyTest => 'إشعار تجريبي من Everslot';

  @override
  String notifBodyTimeFor(String title) {
    return 'حان وقت $title';
  }

  @override
  String notifBodyToday(String date) {
    return 'اليوم · $date';
  }

  @override
  String get notifCategoryDigest => 'ملخص';

  @override
  String get notifCategoryMilestone => 'إنجاز';

  @override
  String get notifCategoryNag => 'تكرار';

  @override
  String get notifCategoryReminder => 'تذكير';

  @override
  String get notifCategoryStreak => 'سلسلة';

  @override
  String get notifCategorySystem => 'النظام';

  @override
  String get notifChannelBlocked => 'بعض فئات الإشعارات محظورة';

  @override
  String get notifChannelDigest => 'الملخصات';

  @override
  String get notifChannelForeground => 'عندما يكون Everslot مفتوحًا';

  @override
  String notifChannelName(String section, String profile) {
    return '$section · $profile';
  }

  @override
  String get notifChannelQuiet => 'ساعات الهدوء';

  @override
  String get notifChannelSystem => 'إشعارات النظام';

  @override
  String get notifChipAtDue => 'عند الموعد النهائي';

  @override
  String get notifChipAtEnd => 'عند الانتهاء';

  @override
  String get notifChipAtFollowUp => 'عند المتابعة';

  @override
  String get notifChipAtSlot => 'في الوقت المحدد';

  @override
  String get notifChipAtStart => 'عند البدء';

  @override
  String get notifChipAtTime => 'في وقت…';

  @override
  String notifChipBefore(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'قبل $minutes دقيقة',
      many: 'قبل $minutes دقيقة',
      few: 'قبل $minutes دقائق',
      two: 'قبل دقيقتين',
      one: 'قبل دقيقة',
      zero: 'قبل $minutes دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get notifChipCustom => 'مخصص…';

  @override
  String notifChipDayBeforeAt(String time) {
    return 'قبل يوم عند $time';
  }

  @override
  String get notifChipEvery => 'كل يوم عند…';

  @override
  String get notifChipIfNotDoneBy => 'إن لم يُنجز قبل…';

  @override
  String get notifChipMilestones => 'الإنجازات';

  @override
  String notifChipOnDayAt(String time) {
    return 'في اليوم نفسه عند $time';
  }

  @override
  String get notifChipStreakRisk => 'السلسلة في خطر';

  @override
  String get notifConditions => 'الشروط';

  @override
  String get notifContent => 'المحتوى';

  @override
  String get notifContentBody => 'قالب النص';

  @override
  String get notifContentTitle => 'قالب العنوان';

  @override
  String notifCreateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إضافة $count تذكير',
      many: 'إضافة $count تذكيرًا',
      few: 'إضافة $count تذكيرات',
      two: 'إضافة تذكيرين',
      one: 'إضافة تذكير',
      zero: 'لا شيء لإضافته',
    );
    return '$_temp0';
  }

  @override
  String get notifCustomize => 'تخصيص';

  @override
  String get notifDateOnlyTime => 'الوقت الافتراضي للعناصر بتاريخ فقط';

  @override
  String get notifDefaultLateness => 'تسليم التذكيرات المتأخرة حتى';

  @override
  String get notifDefaultProfile => 'الملف الافتراضي';

  @override
  String get notifDefaultsAddCategory => 'إضافة افتراضيات لفئة';

  @override
  String get notifDefaultsAllDay => 'عناصر طوال اليوم';

  @override
  String get notifDefaultsCategory => 'افتراضيات الفئات';

  @override
  String get notifDefaultsDateOnly => 'عناصر بتاريخ فقط';

  @override
  String get notifDefaultsEntry => 'التذكيرات الافتراضية';

  @override
  String get notifDefaultsOther => 'افتراضيات أخرى';

  @override
  String get notifDefaultsTimed => 'العناصر ذات التوقيت';

  @override
  String get notifDefaultsTitle => 'التذكيرات الافتراضية';

  @override
  String get notifDelivery => 'طريقة التسليم';

  @override
  String get notifDeviceAll => 'كل الأجهزة';

  @override
  String get notifDeviceLastActive => 'آخر جهاز نشط';

  @override
  String get notifDevicePrimary => 'الجهاز الرئيسي فقط';

  @override
  String get notifDiagBadge => 'الشارة';

  @override
  String get notifDiagBattery => 'تحسين البطارية';

  @override
  String get notifDiagBatteryBody =>
      'بعض الهواتف توقف التطبيقات في الخلفية. اتبع دليل هاتفك لتصل التذكيرات في وقتها.';

  @override
  String notifDiagBatteryOpen(String maker) {
    return 'افتح دليل $maker';
  }

  @override
  String get notifDiagBlocked => 'القنوات المحظورة';

  @override
  String notifDiagBudget(int used, int total) {
    return 'الحد $used/$total';
  }

  @override
  String get notifDiagCapabilities => 'القدرات';

  @override
  String get notifDiagCopied => 'تم نسخ التشخيص (دون محتوى)';

  @override
  String get notifDiagCopy => 'نسخ التشخيص';

  @override
  String get notifDiagCoverage => 'مغطى حتى';

  @override
  String get notifDiagExact => 'التنبيهات الدقيقة';

  @override
  String get notifDiagLastReplan => 'آخر إعادة تخطيط';

  @override
  String notifDiagMismatch(int count) {
    return 'اختلافات بين النظام والجدولة: $count';
  }

  @override
  String get notifDiagNext => 'الإشعارات القادمة';

  @override
  String get notifDiagPendingOs => 'قيد الانتظار في النظام';

  @override
  String get notifDiagPermission => 'الإشعارات مسموحة';

  @override
  String get notifDiagProvisional => 'تسليم مؤقت (هادئ)';

  @override
  String get notifDiagPush => 'الإشعارات الفورية';

  @override
  String get notifDiagPushOff =>
      'الإشعارات الفورية غير مهيأة — تذكيرات محلية فقط';

  @override
  String get notifDiagPushOn => 'الإشعارات الفورية نشطة';

  @override
  String notifDiagReplanInfo(String time, int ms, String reason) {
    return '$time · $ms مللي ثانية · $reason';
  }

  @override
  String get notifDiagReplanNow => 'أعد التخطيط الآن';

  @override
  String get notifDiagSchedule => 'الجدولة';

  @override
  String get notifDiagTimeSensitive => 'حساسة للوقت';

  @override
  String get notifDiagTitle => 'تشخيص الإشعارات';

  @override
  String get notifDiagTracked => 'متتبعة (صندوق الوارد فقط أو خارج الحد)';

  @override
  String get notifDiagnostics => 'التشخيص';

  @override
  String notifDigestAt(String time) {
    return 'عند $time';
  }

  @override
  String get notifDigestDailyAgenda => 'جدول اليوم';

  @override
  String get notifDigestEveningReview => 'مراجعة المساء';

  @override
  String notifDigestFirst(String first) {
    return 'الأول: $first';
  }

  @override
  String get notifDigestMonthly => 'التقرير الشهري';

  @override
  String get notifDigestOverdue => 'ملخص المتأخرات';

  @override
  String get notifDigestPlanTomorrow => 'خطّط للغد';

  @override
  String notifDigestSummary(int tasks, int habits, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      tasks,
      locale: localeName,
      other: '$tasks مهمة',
      many: '$tasks مهمة',
      few: '$tasks مهام',
      two: 'مهمتان',
      one: 'مهمة واحدة',
      zero: 'لا مهام',
    );
    String _temp1 = intl.Intl.pluralLogic(
      habits,
      locale: localeName,
      other: '$habits عادة',
      many: '$habits عادة',
      few: '$habits عادات',
      two: 'عادتان',
      one: 'عادة واحدة',
      zero: 'لا عادات',
    );
    String _temp2 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items عنصر',
      many: '$items عنصرًا',
      few: '$items عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا عناصر',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get notifDigestWeekly => 'المراجعة الأسبوعية';

  @override
  String get notifDigests => 'الملخصات';

  @override
  String get notifDisable => 'تعطيل';

  @override
  String get notifEditorTitle => 'تذكير جديد';

  @override
  String get notifEnable => 'تفعيل';

  @override
  String get notifExactOff => 'قد تصل التذكيرات متأخرة حتى ساعة';

  @override
  String get notifExactOffBody =>
      'اسمح بالتذكيرات الدقيقة لتصل في الدقيقة المحددة.';

  @override
  String get notifFieldAfterDays => 'بعد (أيام)';

  @override
  String get notifFieldAfterMinutes => 'بعد (دقائق)';

  @override
  String get notifFieldAtTime => 'عند الساعة';

  @override
  String get notifFieldDateTime => 'التاريخ والوقت';

  @override
  String get notifFieldDayForm => 'قبل أو بعد N يوم عند وقت';

  @override
  String get notifFieldDayOffset => 'الأيام (سالب = قبل)';

  @override
  String get notifFieldDigestKind => 'الملخص';

  @override
  String get notifFieldEveryMinutes => 'كل (دقائق)';

  @override
  String get notifFieldMaxTimes => 'بحد أقصى (مرات)';

  @override
  String get notifFieldMetric => 'المقياس';

  @override
  String get notifFieldMinStreak => 'أقل طول للسلسلة';

  @override
  String get notifFieldOffset => 'الفارق بالدقائق (سالب = قبل)';

  @override
  String get notifFieldStatuses => 'الحالات';

  @override
  String get notifFieldThresholds => 'العتبات (مفصولة بفواصل، فارغ = تلقائي)';

  @override
  String get notifFieldToStatus => 'الحالة الجديدة';

  @override
  String get notifFieldUntil => 'حتى';

  @override
  String get notifFrom => 'من';

  @override
  String get notifHideContent => 'إخفاء المحتوى في الإشعارات';

  @override
  String notifImpact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصرًا',
      few: '$count عناصر',
      two: 'عنصرين',
      one: 'عنصر واحد',
      zero: 'لا عناصر',
    );
    return 'يؤثر على $_temp0 تستخدم الافتراضيات';
  }

  @override
  String get notifImportance => 'الأهمية';

  @override
  String get notifImportanceDefault => 'عادية';

  @override
  String get notifImportanceHigh => 'مرتفعة';

  @override
  String get notifImportanceLow => 'منخفضة';

  @override
  String get notifImportanceMin => 'دنيا';

  @override
  String get notifImportanceUrgent => 'عاجلة';

  @override
  String get notifInboxAlreadyDone => 'تم بالفعل';

  @override
  String get notifInboxCaughtUp => 'لا شيء جديد';

  @override
  String get notifInboxChangeSnooze => 'تغيير التأجيل';

  @override
  String get notifInboxDismissSelected => 'تجاهل';

  @override
  String get notifInboxDismissed => 'تم تجاهل الإشعار';

  @override
  String get notifInboxEmpty => 'لا توجد إشعارات بعد';

  @override
  String get notifInboxEmptyBody => 'تظهر هنا التذكيرات التي تصلك.';

  @override
  String get notifInboxFilterAll => 'الكل';

  @override
  String get notifInboxFilterUnread => 'غير المقروءة';

  @override
  String get notifInboxHistory => 'سجل التذكيرات';

  @override
  String get notifInboxHistoryEmpty => 'لا تذكيرات بعد';

  @override
  String get notifInboxLate => 'متأخر';

  @override
  String get notifInboxMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get notifInboxMarkedRead => 'تم التعليم كمقروء';

  @override
  String get notifInboxMarkedUnread => 'تم التعليم كغير مقروء';

  @override
  String get notifInboxMuteRule => 'اكتم هذا التذكير';

  @override
  String notifInboxNagCount(int count) {
    return '×$count';
  }

  @override
  String get notifInboxRemindAgain => 'ذكّرني مجددًا…';

  @override
  String get notifInboxSearch => 'البحث في الإشعارات';

  @override
  String notifInboxSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر محدد',
      many: '$count عنصرًا محددًا',
      few: '$count عناصر محددة',
      two: 'عنصران محددان',
      one: 'عنصر محدد',
      zero: 'لا شيء محدد',
    );
    return '$_temp0';
  }

  @override
  String get notifInboxSnoozed => 'المؤجلة';

  @override
  String notifInboxSnoozedUntil(String time) {
    return 'مؤجل حتى $time';
  }

  @override
  String get notifInboxTitle => 'صندوق الوارد';

  @override
  String get notifInboxToday => 'اليوم';

  @override
  String get notifInboxToggle => 'إظهار في صندوق الوارد';

  @override
  String notifInboxUnreadSemantics(String title) {
    return 'تذكير غير مقروء، $title';
  }

  @override
  String get notifInboxWakeNow => 'نبّه الآن';

  @override
  String get notifInboxYesterday => 'أمس';

  @override
  String get notifInherit => 'وراثة';

  @override
  String notifInheritedFrom(String source) {
    return 'من $source';
  }

  @override
  String notifInheritedFromProfile(String name) {
    return 'موروث من $name';
  }

  @override
  String get notifInterruption => 'مستوى المقاطعة (iOS)';

  @override
  String get notifInterruptionActive => 'نشط';

  @override
  String get notifInterruptionPassive => 'هادئ';

  @override
  String get notifInterruptionTimeSensitive => 'حساس للوقت';

  @override
  String get notifIosLabel => 'iOS';

  @override
  String get notifIssueAnchorUnavailable => 'هذا المرجع غير متاح لهذا العنصر';

  @override
  String get notifIssueEmptyContent => 'لا يمكن أن يكون العنوان فارغًا';

  @override
  String get notifIssueLateness => 'يجب أن يكون التأخير دقيقة على الأقل';

  @override
  String get notifIssueNoChannel => 'اختر طريقة واحدة للإشعار على الأقل';

  @override
  String get notifIssueOffsetOutOfRange => 'يجب ألا يتجاوز الفارق 30 يومًا';

  @override
  String get notifIssueRepeatInterval =>
      'يجب أن يكون التكرار كل دقيقة على الأقل';

  @override
  String get notifIssueRepeatMax => '10 تكرارات كحد أقصى';

  @override
  String get notifIssueSchedule => 'جدول غير صالح';

  @override
  String get notifIssueStatuses => 'اختر حالة واحدة على الأقل';

  @override
  String get notifIssueThresholds => 'عتبات غير صالحة';

  @override
  String get notifIssueTooManyActions => 'يعرض Android أول 3 إجراءات فقط';

  @override
  String get notifIssueUnknownTrigger =>
      'هذا النوع من القواعد غير مدعوم في هذا الإصدار';

  @override
  String notifIssueUnknownVariable(String names) {
    return 'متغير غير معروف: $names';
  }

  @override
  String get notifItemKind => 'نوع العنصر';

  @override
  String get notifItemKindAllDay => 'طوال اليوم';

  @override
  String get notifItemKindAny => 'أي نوع';

  @override
  String get notifItemKindDateOnly => 'تاريخ فقط';

  @override
  String get notifItemKindTimed => 'بتوقيت';

  @override
  String get notifLateness => 'التسليم عند التأخر حتى (دقائق)';

  @override
  String get notifMakePrimary => 'استخدم هذا الجهاز كرئيسي';

  @override
  String get notifMaxNag => 'أقصى عدد للتكرار';

  @override
  String notifMergedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكير',
      many: '$count تذكيرًا',
      few: '$count تذكيرات',
      two: 'تذكيران',
      one: 'تذكير واحد',
      zero: 'لا تذكيرات',
    );
    return '$_temp0';
  }

  @override
  String get notifMetricCleanDays => 'أيام دون انتكاس';

  @override
  String get notifMetricMoney => 'المال الموفَّر';

  @override
  String get notifMetricStreak => 'السلسلة';

  @override
  String get notifMetricTotal => 'الإجمالي';

  @override
  String get notifMetricUnits => 'الوحدات المتجنبة';

  @override
  String notifMinutesValue(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة',
      zero: '$minutes دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get notifModeCustom => 'مخصص';

  @override
  String get notifModeInherit => 'الافتراضي';

  @override
  String get notifModeInheritPlus => 'الافتراضي + الخاص';

  @override
  String get notifModeOff => 'متوقف';

  @override
  String get notifMultiDevice => 'التسليم إلى';

  @override
  String get notifMute1h => 'ساعة';

  @override
  String get notifMuteFor => 'اكتم…';

  @override
  String get notifMuteForever => 'حتى أُلغي الكتم';

  @override
  String get notifMuteToday => 'بقية اليوم';

  @override
  String get notifMuteTomorrow => 'حتى الغد';

  @override
  String get notifMuteWeek => 'لمدة أسبوع';

  @override
  String get notifMuted => 'مكتوم';

  @override
  String get notifMutedForever => 'مكتوم حتى الإلغاء';

  @override
  String get notifMutedSnack => 'مكتوم حتى الغد';

  @override
  String notifMutedUntil(String time) {
    return 'مكتوم حتى $time';
  }

  @override
  String get notifMutes => 'المكتومة';

  @override
  String get notifMutesNone => 'لا شيء مكتوم';

  @override
  String get notifNever => 'أبدًا';

  @override
  String get notifNextFirings => 'التذكيرات القادمة';

  @override
  String get notifNo => 'لا';

  @override
  String get notifNoReminders => 'لا تذكيرات';

  @override
  String get notifNoUpcoming => 'لا شيء مجدول خلال 14 يومًا القادمة';

  @override
  String get notifNoiseBlocked => 'إشعارات كثيرة جدًا (أكثر من 1440 يوميًا)';

  @override
  String get notifNoiseCluster =>
      'عدة تذكيرات في الدقيقة نفسها — سيُسمع صوت واحد فقط';

  @override
  String notifNoiseConfirm(int perDay) {
    return 'يرسل هذا التذكير حوالي $perDay إشعار يوميًا. هل تحفظه رغم ذلك؟';
  }

  @override
  String notifNoiseWarn(int perDay) {
    return 'حوالي $perDay إشعار يوميًا';
  }

  @override
  String get notifOffsetAmount => 'المقدار';

  @override
  String get notifOnlyIfStatus => 'فقط إذا كانت الحالة';

  @override
  String get notifOpenSettings => 'فتح الإعدادات';

  @override
  String get notifOutsideDrop => 'تجاهل خارجها';

  @override
  String get notifOutsideShiftEnd => 'انقل إلى النهاية';

  @override
  String get notifOutsideShiftStart => 'انقل إلى البداية';

  @override
  String get notifPause1h => 'ساعة';

  @override
  String get notifPauseAll => 'إيقاف الكل مؤقتًا';

  @override
  String get notifPauseCustom => 'مخصص…';

  @override
  String get notifPauseTomorrow => 'حتى الغد 08:00';

  @override
  String notifPausedUntil(String time) {
    return 'متوقف مؤقتًا حتى $time';
  }

  @override
  String get notifPermissionOff => 'الإشعارات متوقفة';

  @override
  String get notifPermissionOffBody => 'فعّلها لتصلك تذكيراتك.';

  @override
  String get notifPreview => 'معاينة';

  @override
  String get notifPrimerAllow => 'السماح بالإشعارات';

  @override
  String get notifPrimerBody =>
      'يذكّرك Everslot قبل بدء المهام وعند استحقاق العادات وعندما تحتاج القوائم إلى متابعة. وأنت تحدد التوقيت بدقة.';

  @override
  String get notifPrimerExactBody =>
      'يحتاج Android إلى إذنك لتسليم التذكيرات في الدقيقة المحددة. بدونه قد تتأخر حتى ساعة.';

  @override
  String get notifPrimerExactTitle => 'تذكيرات دقيقة';

  @override
  String get notifPrimerLater => 'ليس الآن';

  @override
  String get notifPrimerTimeSensitiveBody =>
      'يمكن للتذكيرات المهمة تجاوز أوضاع التركيز. يمكنك تغيير ذلك في إعدادات iOS في أي وقت.';

  @override
  String get notifPrimerTimeSensitiveTitle => 'تذكيرات حساسة للوقت';

  @override
  String get notifPrimerTitle => 'لا تفوّت ما يهم';

  @override
  String get notifProfile => 'الملف';

  @override
  String get notifProfileAlarm => 'منبّه';

  @override
  String get notifProfileBuiltin => 'مدمج';

  @override
  String get notifProfileChannelWarning =>
      'تغيير الأهمية أو الصوت أو الاهتزاز ينشئ فئة إشعارات جديدة في Android؛ وتظهر الفئة القديمة كمحذوفة في الإعدادات.';

  @override
  String get notifProfileDelete => 'حذف الملف';

  @override
  String notifProfileDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكير يستخدم هذا الملف.',
      many: '$count تذكيرًا يستخدم هذا الملف.',
      few: '$count تذكيرات تستخدم هذا الملف.',
      two: 'تذكيران يستخدمان هذا الملف.',
      one: 'تذكير واحد يستخدم هذا الملف.',
      zero: 'لا تذكيرات تستخدم هذا الملف.',
    );
    return '$_temp0 انقلها إلى:';
  }

  @override
  String get notifProfileDuplicate => 'تكرار';

  @override
  String get notifProfileGentle => 'لطيف';

  @override
  String get notifProfileNag => 'إلحاح حتى الإنجاز';

  @override
  String get notifProfileName => 'الاسم';

  @override
  String get notifProfileNew => 'ملف جديد';

  @override
  String get notifProfileNone => 'بدون ملف';

  @override
  String get notifProfileRename => 'إعادة التسمية';

  @override
  String get notifProfileStandard => 'قياسي';

  @override
  String get notifProfilesEntry => 'الملفات';

  @override
  String get notifProfilesTitle => 'ملفات الإشعارات';

  @override
  String get notifProvenanceAncestor => 'العنصر الأب';

  @override
  String get notifProvenanceCategory => 'الفئة';

  @override
  String get notifProvenanceChecklist => 'القائمة';

  @override
  String get notifProvenanceGlobal => 'الافتراضيات العامة';

  @override
  String get notifProvenanceOccurrence => 'هذا الموعد فقط';

  @override
  String get notifProvenanceSection => 'افتراضيات القسم';

  @override
  String get notifQuietAdd => 'إضافة ساعات هدوء';

  @override
  String get notifQuietDefer => 'التأجيل إلى النهاية';

  @override
  String get notifQuietDrop => 'التجاهل';

  @override
  String get notifQuietHours => 'ساعات الهدوء';

  @override
  String get notifQuietMode => 'الوضع';

  @override
  String get notifQuietNone => 'لا ساعات هدوء';

  @override
  String get notifQuietSilent => 'التسليم بصمت';

  @override
  String notifQuietWindow(String from, String to) {
    return '$from – $to';
  }

  @override
  String get notifRedactedBody => 'افتح Everslot لعرضه';

  @override
  String get notifRedactedTitle => 'تذكير من Everslot';

  @override
  String get notifRepeat => 'التكرار (الإلحاح)';

  @override
  String get notifRespectQuiet => 'احترام ساعات الهدوء';

  @override
  String get notifResume => 'استئناف';

  @override
  String get notifRuleDeleted => 'تم حذف التذكير';

  @override
  String get notifRuleEnabled => 'التذكير مفعّل';

  @override
  String get notifRuleSaved => 'تم حفظ التذكير';

  @override
  String get notifSaturationBody => 'افتح Everslot لتحديث تذكيراتك';

  @override
  String get notifSaturationTitle => 'افتح Everslot';

  @override
  String get notifSectionChecklists => 'القوائم';

  @override
  String get notifSectionDigests => 'الملخصات';

  @override
  String get notifSectionHabits => 'العادات';

  @override
  String get notifSectionPlanner => 'الخطة';

  @override
  String get notifSectionQuit => 'الإقلاع';

  @override
  String get notifSectionSystem => 'النظام';

  @override
  String get notifSectionTitle => 'الإشعارات';

  @override
  String get notifSendTest => 'إرسال إشعار تجريبي';

  @override
  String get notifSettingsSections => 'الأقسام';

  @override
  String get notifSettingsTitle => 'الإشعارات';

  @override
  String notifShowAll(int count) {
    return 'عرض الكل ($count)';
  }

  @override
  String get notifSkipAck => 'تم الاطلاع';

  @override
  String get notifSkipCap => 'تم بلوغ الحد اليومي';

  @override
  String get notifSkipDone => 'تم بالفعل';

  @override
  String get notifSkipExpired => 'متأخر جدًا';

  @override
  String get notifSkipMuted => 'مكتوم';

  @override
  String get notifSkipNoChannel => 'لا قناة تسليم';

  @override
  String get notifSkipQuiet => 'متجاهل (ساعات الهدوء)';

  @override
  String get notifSkipStatus => 'الحالة غير مطابقة';

  @override
  String get notifSkipWeekday => 'ليس في هذا اليوم';

  @override
  String get notifSkipWindow => 'خارج النافذة الزمنية';

  @override
  String get notifSnoozeCustom => 'مخصص…';

  @override
  String get notifSnoozeEvening => 'هذا المساء';

  @override
  String notifSnoozeHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعة',
      many: '$hours ساعة',
      few: '$hours ساعات',
      two: 'ساعتان',
      one: 'ساعة',
      zero: '$hours ساعة',
    );
    return '$_temp0';
  }

  @override
  String get notifSnoozeLimit => 'تم بلوغ حد التأجيل';

  @override
  String notifSnoozeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة',
      zero: '$minutes دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get notifSnoozeOptions => 'خيارات التأجيل (دقائق)';

  @override
  String get notifSnoozePresets => 'خيارات التأجيل';

  @override
  String get notifSnoozeTomorrow => 'صباح الغد';

  @override
  String notifSnoozedSnack(String time) {
    return 'تم التأجيل حتى $time';
  }

  @override
  String get notifSound => 'الصوت';

  @override
  String get notifSoundAlarm => 'منبّه';

  @override
  String get notifSoundBell => 'جرس';

  @override
  String get notifSoundChime => 'رنين';

  @override
  String get notifSoundDefault => 'افتراضي';

  @override
  String get notifSoundNone => 'بدون';

  @override
  String get notifSoundPop => 'فرقعة';

  @override
  String get notifSoundSoft => 'ناعم';

  @override
  String get notifSticky => 'إبقاء حتى الإنجاز (Android)';

  @override
  String notifSumAbsolute(String dateTime) {
    return 'في $dateTime';
  }

  @override
  String notifSumAfterDue(String duration) {
    return 'بعد الموعد النهائي بـ $duration';
  }

  @override
  String notifSumAfterEnd(String duration) {
    return 'بعد الانتهاء بـ $duration';
  }

  @override
  String notifSumAfterStart(String duration) {
    return 'بعد البدء بـ $duration';
  }

  @override
  String get notifSumAtDue => 'عند الموعد النهائي';

  @override
  String get notifSumAtEnd => 'عند الانتهاء';

  @override
  String get notifSumAtFollowUp => 'عند المتابعة';

  @override
  String get notifSumAtPeriodEnd => 'عند نهاية الفترة';

  @override
  String get notifSumAtPeriodStart => 'عند بداية الفترة';

  @override
  String get notifSumAtSlot => 'في الوقت المحدد';

  @override
  String get notifSumAtStart => 'عند البدء';

  @override
  String notifSumBeforeDue(String duration) {
    return 'قبل الموعد النهائي بـ $duration';
  }

  @override
  String notifSumBeforeEnd(String duration) {
    return 'قبل الانتهاء بـ $duration';
  }

  @override
  String notifSumBeforeStart(String duration) {
    return 'قبل البدء بـ $duration';
  }

  @override
  String get notifSumChildOverdue => 'عند تأخر عنصر فرعي';

  @override
  String get notifSumChildrenComplete => 'عند اكتمال كل العناصر الفرعية';

  @override
  String notifSumDaysAfter(int days, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يومًا',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم',
      zero: '$days يوم',
    );
    return 'بعد $_temp0 عند $time';
  }

  @override
  String notifSumDaysBefore(int days, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يومًا',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم',
      zero: '$days يوم',
    );
    return 'قبل $_temp0 عند $time';
  }

  @override
  String notifSumInactivity(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يومًا',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم',
      zero: '$days يوم',
    );
    return 'بعد $_temp0 دون نشاط';
  }

  @override
  String get notifSumMilestones => 'الإنجازات';

  @override
  String notifSumNotDoneBy(String time) {
    return 'إن لم يُنجز قبل $time';
  }

  @override
  String get notifSumNotDoneByEnd => 'إن لم يُنجز قبل النهاية';

  @override
  String notifSumOnDayAt(String time) {
    return 'في اليوم نفسه عند $time';
  }

  @override
  String get notifSumOverdue => 'عند التأخر';

  @override
  String notifSumQuotaBehind(String time) {
    return 'متأخر عن الهدف، عند $time';
  }

  @override
  String notifSumRepeat(int minutes, int times) {
    return 'يتكرر كل $minutes دقيقة ×$times';
  }

  @override
  String get notifSumSchedule => 'وفق جدول متكرر';

  @override
  String notifSumStale(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يومًا',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم',
      zero: '$days يوم',
    );
    return 'بعد $_temp0 دون تقدم';
  }

  @override
  String notifSumStatusAge(String duration) {
    return 'ما زال منتظرًا أو محظورًا بعد $duration';
  }

  @override
  String notifSumStatusChange(String status) {
    return 'عندما يصبح $status';
  }

  @override
  String notifSumStreakRisk(String time) {
    return 'السلسلة في خطر، عند $time';
  }

  @override
  String get notifSumUnknown => 'قاعدة غير مدعومة';

  @override
  String get notifSystemNotification => 'إشعار النظام';

  @override
  String get notifTestSent => 'إشعار تجريبي خلال 5 ثوانٍ';

  @override
  String get notifThisDeviceIsPrimary => 'هذا الجهاز هو الرئيسي';

  @override
  String get notifTimeWindow => 'النافذة الزمنية';

  @override
  String notifTitleFollowUp(String title) {
    return 'متابعة: $title';
  }

  @override
  String get notifTo => 'إلى';

  @override
  String get notifTrigger => 'المشغّل';

  @override
  String get notifTriggerAbsolute => 'في تاريخ ووقت';

  @override
  String get notifTriggerChildOverdue => 'تأخر عنصر فرعي';

  @override
  String get notifTriggerChildrenComplete => 'اكتمال العناصر الفرعية';

  @override
  String get notifTriggerDigest => 'ملخص';

  @override
  String get notifTriggerInactivity => 'عدم النشاط';

  @override
  String get notifTriggerMilestone => 'إنجاز';

  @override
  String get notifTriggerNotDoneBy => 'إن لم يُنجز قبل';

  @override
  String get notifTriggerOverdue => 'التأخر';

  @override
  String get notifTriggerQuotaBehind => 'متأخر عن الهدف';

  @override
  String get notifTriggerRelative => 'نسبةً إلى العنصر';

  @override
  String get notifTriggerSchedule => 'جدول متكرر';

  @override
  String get notifTriggerStale => 'دون تقدم';

  @override
  String get notifTriggerStatusAge => 'مدة الحالة';

  @override
  String get notifTriggerStatusChange => 'تغيّر الحالة';

  @override
  String get notifTriggerStreakRisk => 'السلسلة في خطر';

  @override
  String get notifUnitDays => 'أيام';

  @override
  String get notifUnitHours => 'ساعات';

  @override
  String get notifUnitMinutes => 'دقائق';

  @override
  String get notifUnitWeeks => 'أسابيع';

  @override
  String get notifUnknown => 'غير معروف';

  @override
  String get notifUnmute => 'إلغاء الكتم';

  @override
  String get notifUntilAcknowledged => 'الاطلاع';

  @override
  String get notifUntilCompleted => 'الإنجاز';

  @override
  String get notifUntilMax => 'بلوغ الحد الأقصى';

  @override
  String get notifVariables => 'المتغيرات';

  @override
  String get notifVibration => 'الاهتزاز';

  @override
  String get notifVibrationDefault => 'افتراضي';

  @override
  String get notifVibrationLong => 'طويل';

  @override
  String get notifVibrationNone => 'بدون';

  @override
  String get notifVibrationShort => 'قصير';

  @override
  String get notifWeekdays => 'فقط في';

  @override
  String get notifYes => 'نعم';

  @override
  String get pickerColor => 'اللون';

  @override
  String get pickerDate => 'التاريخ';

  @override
  String get pickerDays => 'أيام';

  @override
  String get pickerDuration => 'المدة';

  @override
  String get pickerHours => 'ساعات';

  @override
  String get pickerIcon => 'الأيقونة';

  @override
  String get pickerMinutes => 'دقائق';

  @override
  String get pickerNoColor => 'بلا لون';

  @override
  String get pickerSearchIcons => 'البحث عن أيقونة';

  @override
  String get pickerTime => 'الوقت';

  @override
  String get placeholderScreen => 'هذه الشاشة قيد الإنشاء.';

  @override
  String get priorityHigh => 'عالية';

  @override
  String get priorityLow => 'منخفضة';

  @override
  String get priorityMedium => 'متوسطة';

  @override
  String get priorityNone => 'بلا أولوية';

  @override
  String get priorityUrgent => 'عاجلة';

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'أمس',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String relativeInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بعد $count يوم',
      many: 'بعد $count يومًا',
      few: 'بعد $count أيام',
      two: 'بعد يومين',
      one: 'غدًا',
    );
    return '$_temp0';
  }

  @override
  String relativeInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بعد $count ساعة',
      many: 'بعد $count ساعة',
      few: 'بعد $count ساعات',
      two: 'بعد ساعتين',
      one: 'بعد ساعة',
    );
    return '$_temp0';
  }

  @override
  String relativeInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بعد $count دقيقة',
      many: 'بعد $count دقيقة',
      few: 'بعد $count دقائق',
      two: 'بعد دقيقتين',
      one: 'بعد دقيقة',
    );
    return '$_temp0';
  }

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get relativeNow => 'الآن';

  @override
  String get savedSnack => 'تم الحفظ';

  @override
  String get stateEmpty => 'لا يوجد شيء بعد';

  @override
  String get stateErrorBody => 'يرجى المحاولة مرة أخرى.';

  @override
  String get stateErrorTitle => 'حدث خطأ ما';

  @override
  String get stateLoading => 'جارٍ التحميل…';

  @override
  String get syncError => 'مشكلة في المزامنة';

  @override
  String get syncIdle => 'تمت المزامنة';

  @override
  String get syncLocalOnly => 'على هذا الجهاز فقط';

  @override
  String get syncOffline => 'غير متصل — ستتم المزامنة لاحقًا';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغيير معلّق',
      many: '$count تغييرًا معلّقًا',
      few: '$count تغييرات معلّقة',
      two: 'تغييران معلّقان',
      one: 'تغيير واحد معلّق',
      zero: 'لا توجد تغييرات معلّقة',
    );
    return '$_temp0';
  }

  @override
  String get syncPulling => 'جارٍ التحديث…';

  @override
  String get syncPushing => 'جارٍ رفع التغييرات…';

  @override
  String get tabHabits => 'العادات';

  @override
  String get tabInsights => 'الإحصاءات';

  @override
  String get tabLists => 'القوائم';

  @override
  String get tabPlan => 'الخطة';

  @override
  String get tabToday => 'اليوم';
}
