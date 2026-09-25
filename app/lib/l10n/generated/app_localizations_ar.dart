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

  @override
  String get tagAdd => 'إضافة وسم';

  @override
  String tagChipSemantics(String name) {
    return 'الوسم $name';
  }

  @override
  String tagCreateNamed(String name) {
    return 'إنشاء الوسم «$name»';
  }

  @override
  String tagDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سيُزال من $count عنصر.',
      many: 'سيُزال من $count عنصرًا.',
      few: 'سيُزال من $count عناصر.',
      two: 'سيُزال من عنصرين.',
      one: 'سيُزال من عنصر واحد.',
      zero: 'هذا الوسم غير مستخدم بعد.',
    );
    return '$_temp0';
  }

  @override
  String get tagEdit => 'تعديل الوسم';

  @override
  String get tagErrorDuplicate => 'يوجد وسم بهذا الاسم بالفعل.';

  @override
  String get tagErrorInvalid => 'استخدم من 1 إلى 40 حرفًا.';

  @override
  String get tagMerge => 'دمج في…';

  @override
  String get tagMergeAction => 'دمج';

  @override
  String tagMergeConfirmBody(String source, String target) {
    return 'كل ما يحمل الوسم «$source» سيحمل الوسم «$target» بدلاً منه، ثم سيُحذف «$source».';
  }

  @override
  String get tagMergeConfirmTitle => 'دمج الوسوم؟';

  @override
  String tagMergeTitle(String name) {
    return 'دمج «$name» في';
  }

  @override
  String tagMergedSnack(String name) {
    return 'تم الدمج في «$name»';
  }

  @override
  String get tagName => 'اسم الوسم';

  @override
  String get tagNew => 'وسم جديد';

  @override
  String get tagNoColor => 'بدون لون';

  @override
  String get tagPickerSearch => 'ابحث عن وسم أو أنشئ واحدًا';

  @override
  String get tagPickerTitle => 'الوسوم';

  @override
  String tagRemoveSemantics(String name) {
    return 'إزالة الوسم $name';
  }

  @override
  String tagUsage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصرًا',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'غير مستخدم',
    );
    return '$_temp0';
  }

  @override
  String get tagsEmpty => 'لا توجد وسوم بعد';

  @override
  String get tagsEmptyHint =>
      'الوسوم تعمل عبر كل الأقسام — استخدمها لسياقات مثل المشتريات أو بانتظار الآخرين.';

  @override
  String get tagsTitle => 'الوسوم';

  @override
  String get tagsUpdatedSnack => 'تم تحديث الوسوم';
}
