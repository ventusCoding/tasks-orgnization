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
  String get attachmentsAdd => 'إضافة مرفق';

  @override
  String attachmentsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُضيف $count مرفق',
      many: 'أُضيف $count مرفقًا',
      few: 'أُضيفت $count مرفقات',
      two: 'أُضيف مرفقان',
      one: 'أُضيف مرفق واحد',
      zero: 'لم يُضف أي مرفق',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsCacheCleared => 'تم مسح ذاكرة التخزين المؤقت';

  @override
  String attachmentsCacheSize(String size) {
    return 'ذاكرة التخزين المؤقت المحلية: $size';
  }

  @override
  String get attachmentsCameraPrimerBody =>
      'يطلب Everslot الوصول إلى الكاميرا لتتمكن من إرفاق الصور. تبقى الصور على جهازك حتى تُرفع إلى حسابك.';

  @override
  String get attachmentsCameraPrimerTitle => 'استخدام الكاميرا';

  @override
  String get attachmentsCaption => 'التعليق';

  @override
  String get attachmentsClearCache => 'مسح ذاكرة التخزين المؤقت';

  @override
  String attachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرفق',
      many: '$count مرفقًا',
      few: '$count مرفقات',
      two: 'مرفقان',
      one: 'مرفق واحد',
      zero: 'لا مرفقات',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsDownloadWhenOnline =>
      'سيُنزَّل هذا الملف عند اتصالك بالإنترنت.';

  @override
  String get attachmentsEditCaption => 'تعديل التعليق';

  @override
  String get attachmentsEmpty => 'لا توجد مرفقات بعد';

  @override
  String get attachmentsGoToItem => 'الانتقال إلى العنصر';

  @override
  String get attachmentsKindAudio => 'صوت';

  @override
  String get attachmentsKindFile => 'ملف';

  @override
  String get attachmentsKindPdf => 'ملف PDF';

  @override
  String get attachmentsKindPhoto => 'صورة';

  @override
  String get attachmentsKindVideo => 'فيديو';

  @override
  String get attachmentsLocalOnly => 'مخزّن على هذا الجهاز';

  @override
  String attachmentsMore(int count) {
    return '+$count';
  }

  @override
  String get attachmentsMoveEarlier => 'نقل إلى الأمام';

  @override
  String get attachmentsMoveLater => 'نقل إلى الخلف';

  @override
  String get attachmentsNoPreview => 'لا تتوفر معاينة لهذا النوع من الملفات';

  @override
  String get attachmentsOpenSettings => 'فتح الإعدادات';

  @override
  String get attachmentsOpenWith => 'فتح باستخدام…';

  @override
  String attachmentsPendingUploads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عملية رفع معلقة',
      many: '$count عملية رفع معلقة',
      few: '$count عمليات رفع معلقة',
      two: 'عمليتا رفع معلقتان',
      one: 'عملية رفع واحدة معلقة',
      zero: 'لا عمليات رفع معلقة',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsPermissionBody =>
      'لا يستطيع Everslot الوصول إلى الكاميرا أو الصور. يمكنك السماح بذلك من إعدادات النظام.';

  @override
  String get attachmentsPermissionTitle => 'يلزم منح الإذن';

  @override
  String attachmentsRejectedDuplicate(String name) {
    return '$name مرفق بالفعل';
  }

  @override
  String attachmentsRejectedEmpty(String name) {
    return '$name فارغ';
  }

  @override
  String attachmentsRejectedTooLarge(String name, String limit) {
    return '$name أكبر من $limit';
  }

  @override
  String attachmentsRejectedTooMany(int count) {
    return 'تم بلوغ الحد الأقصى وهو $count مرفقًا';
  }

  @override
  String attachmentsRejectedType(String name) {
    return '$name: نوع الملف هذا غير مدعوم';
  }

  @override
  String attachmentsRejectedUnreadable(String name) {
    return 'تعذّرت قراءة $name';
  }

  @override
  String get attachmentsRemove => 'إزالة';

  @override
  String get attachmentsRemoved => 'تمت إزالة المرفق';

  @override
  String get attachmentsRetry => 'إعادة محاولة الرفع';

  @override
  String attachmentsSemantics(String kind, int index, int total) {
    return '$kind $index من $total';
  }

  @override
  String get attachmentsSettingsTitle => 'المرفقات';

  @override
  String attachmentsSizeB(String size) {
    return '$size بايت';
  }

  @override
  String attachmentsSizeGb(String size) {
    return '$size ج.ب';
  }

  @override
  String attachmentsSizeKb(String size) {
    return '$size ك.ب';
  }

  @override
  String attachmentsSizeMb(String size) {
    return '$size م.ب';
  }

  @override
  String get attachmentsSourceCamera => 'التقاط صورة';

  @override
  String get attachmentsSourceFiles => 'اختيار ملفات';

  @override
  String get attachmentsSourcePhotos => 'اختيار صور';

  @override
  String get attachmentsStatusDownloading => 'جارٍ التنزيل';

  @override
  String get attachmentsStatusFailed => 'فشل الرفع — اضغط لإعادة المحاولة';

  @override
  String get attachmentsStatusNotDownloaded => 'لم يُنزَّل — اضغط للتنزيل';

  @override
  String get attachmentsStatusProcessing => 'جارٍ المعالجة';

  @override
  String attachmentsStatusUploading(int percent) {
    return 'جارٍ الرفع $percent٪';
  }

  @override
  String get attachmentsStatusUploadingShort => 'جارٍ الرفع';

  @override
  String get attachmentsStatusWaiting => 'بانتظار الاتصال بالشبكة';

  @override
  String attachmentsStorageUsed(String size) {
    return 'المساحة المستخدمة: $size';
  }

  @override
  String attachmentsViewerPosition(int index, int total) {
    return '$index / $total';
  }

  @override
  String get attachmentsWifiOnly => 'رفع المرفقات عبر Wi-Fi فقط';

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
  String chartsAnonymousItem(String n) {
    return 'العنصر $n';
  }

  @override
  String chartsBytesGb(String value) {
    return '$value ج.ب';
  }

  @override
  String chartsBytesKb(String value) {
    return '$value ك.ب';
  }

  @override
  String chartsBytesMb(String value) {
    return '$value م.ب';
  }

  @override
  String get chartsColumnLabel => 'التسمية';

  @override
  String chartsCounterSemantics(String days, String hours, String minutes) {
    return '$days يومًا و$hours ساعة و$minutes دقيقة';
  }

  @override
  String chartsCrosshair(String label, String value) {
    return '$label: $value';
  }

  @override
  String chartsDaysHours(String days, String hours) {
    return '$days ي $hours س';
  }

  @override
  String chartsDaysOnly(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '0 يوم',
    );
    return '$_temp0';
  }

  @override
  String chartsDeltaDown(String value) {
    return 'انخفاض بمقدار $value';
  }

  @override
  String get chartsDeltaFlat => 'دون تغيير';

  @override
  String get chartsDeltaNew => 'جديد';

  @override
  String chartsDeltaUp(String value) {
    return 'ارتفاع بمقدار $value';
  }

  @override
  String get chartsEmpty => 'لا توجد بيانات لهذه الفترة';

  @override
  String get chartsError => 'تعذّر حساب هذا الرسم البياني';

  @override
  String chartsEstimate(String value) {
    return '≈ $value';
  }

  @override
  String get chartsExplain => 'حول هذا المؤشر';

  @override
  String chartsFrozen(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وحدة مجمّدة',
      many: '$count وحدة مجمّدة',
      few: '$count وحدات مجمّدة',
      two: 'وحدتان مجمّدتان',
      one: 'وحدة مجمّدة',
      zero: 'لا شيء مجمّد',
    );
    return '$_temp0';
  }

  @override
  String get chartsGalleryDark => 'السمة الداكنة';

  @override
  String get chartsGalleryRtl => 'من اليمين إلى اليسار';

  @override
  String get chartsGalleryTextScale => 'نص كبير';

  @override
  String get chartsGalleryTitle => 'معرض الرسوم البيانية';

  @override
  String get chartsGalleryVision => 'رؤية الألوان';

  @override
  String get chartsHistogramCount => 'العدد';

  @override
  String get chartsHistogramDensity => 'النسبة';

  @override
  String chartsHour(String hour) {
    return 'الساعة $hour';
  }

  @override
  String chartsHoursMinutes(String hours, String minutes) {
    return '$hours س $minutes د';
  }

  @override
  String chartsHoursOnly(String hours) {
    return '$hours س';
  }

  @override
  String chartsKilo(String value) {
    return '$value ألف';
  }

  @override
  String chartsKpiSemantics(String title, String value, String delta) {
    return '$title: $value. $delta';
  }

  @override
  String get chartsLabelAbstinent => 'ممتنع';

  @override
  String get chartsLabelActual => 'فعلي';

  @override
  String get chartsLabelAfterHours => 'خارج الدوام';

  @override
  String get chartsLabelAgenda => 'جدول الأعمال';

  @override
  String get chartsLabelArchived => 'المؤرشفة';

  @override
  String get chartsLabelArrivals => 'الوافدة';

  @override
  String get chartsLabelAttempt => 'محاولة';

  @override
  String get chartsLabelAttention => 'يحتاج إلى متابعة';

  @override
  String get chartsLabelBaseline => 'خط الأساس';

  @override
  String get chartsLabelBest => 'الأفضل';

  @override
  String get chartsLabelBlocked => 'محظور';

  @override
  String get chartsLabelCancelled => 'ملغى';

  @override
  String get chartsLabelCapacity => 'السعة';

  @override
  String get chartsLabelCheckIns => 'تسجيلات';

  @override
  String get chartsLabelCompleted => 'مكتمل';

  @override
  String get chartsLabelCount => 'العدد';

  @override
  String get chartsLabelCravings => 'الرغبات الملحّة';

  @override
  String get chartsLabelCreated => 'المُنشأة';

  @override
  String get chartsLabelCurrent => 'الحالي';

  @override
  String get chartsLabelDeepWork => 'العمل العميق';

  @override
  String get chartsLabelDepartures => 'المغادِرة';

  @override
  String get chartsLabelDone => 'منجز';

  @override
  String get chartsLabelDoneLate => 'متأخر';

  @override
  String get chartsLabelDoneOnTime => 'في الوقت';

  @override
  String get chartsLabelEarly => 'مبكر';

  @override
  String get chartsLabelEvent => 'الأحداث';

  @override
  String get chartsLabelExcused => 'معذور';

  @override
  String get chartsLabelFailed => 'لم يُنجز';

  @override
  String get chartsLabelFiles => 'الملفات';

  @override
  String get chartsLabelFocus => 'التركيز';

  @override
  String get chartsLabelFree => 'متاح';

  @override
  String get chartsLabelFrozen => 'مجمّد';

  @override
  String get chartsLabelFuture => 'قادم';

  @override
  String get chartsLabelGoal => 'الغاية';

  @override
  String get chartsLabelHabits => 'العادات';

  @override
  String get chartsLabelHighPriority => 'أولوية عالية';

  @override
  String get chartsLabelIdeal => 'المثالي';

  @override
  String get chartsLabelImages => 'الصور';

  @override
  String get chartsLabelInProgress => 'النشطة';

  @override
  String get chartsLabelIntensity => 'الشدة';

  @override
  String get chartsLabelItems => 'العناصر';

  @override
  String get chartsLabelLapse => 'زلّة';

  @override
  String get chartsLabelLate => 'متأخر';

  @override
  String get chartsLabelLifeRegained => 'العمر المُستعاد';

  @override
  String get chartsLabelLimit => 'الحد';

  @override
  String get chartsLabelLists => 'القوائم';

  @override
  String get chartsLabelLowPriority => 'أولوية منخفضة';

  @override
  String get chartsLabelMaxIntensity => 'أعلى شدة';

  @override
  String get chartsLabelMean => 'المتوسط';

  @override
  String get chartsLabelMeanIntensity => 'متوسط الشدة';

  @override
  String get chartsLabelMeanUse => 'متوسط الاستهلاك';

  @override
  String get chartsLabelMedian => 'الوسيط';

  @override
  String get chartsLabelMissed => 'فائت';

  @override
  String get chartsLabelMoney => 'المال';

  @override
  String get chartsLabelMonth => 'الشهر';

  @override
  String get chartsLabelMoods => 'الحالات المزاجية';

  @override
  String get chartsLabelMoved => 'منقول';

  @override
  String get chartsLabelMovedIn => 'نُقل إلى الفترة';

  @override
  String get chartsLabelMovedOut => 'نُقل خارج الفترة';

  @override
  String get chartsLabelNet => 'صافي التدفق';

  @override
  String get chartsLabelNextUp => 'التالي';

  @override
  String get chartsLabelNo => 'لا';

  @override
  String get chartsLabelNotDue => 'غير مستحق';

  @override
  String get chartsLabelNotTracked => 'غير متتبَّع';

  @override
  String get chartsLabelOnTime => 'في الوقت';

  @override
  String get chartsLabelOneOff => 'لمرة واحدة';

  @override
  String get chartsLabelOngoing => 'جارٍ';

  @override
  String get chartsLabelOther => 'أخرى';

  @override
  String get chartsLabelOver => 'زيادة';

  @override
  String get chartsLabelOverLimit => 'فوق الحد';

  @override
  String get chartsLabelOverdue => 'متأخرة';

  @override
  String get chartsLabelOverdue1 => '1–6 أيام';

  @override
  String get chartsLabelOverdue14 => '14–29 يومًا';

  @override
  String get chartsLabelOverdue30 => '30 يومًا فأكثر';

  @override
  String get chartsLabelOverdue7 => '7–13 يومًا';

  @override
  String get chartsLabelOverdueToday => '< يوم';

  @override
  String get chartsLabelOverlap => 'تداخل';

  @override
  String get chartsLabelP50 => 'P50';

  @override
  String get chartsLabelP70 => 'P70';

  @override
  String get chartsLabelP85 => 'P85';

  @override
  String get chartsLabelP95 => 'P95';

  @override
  String get chartsLabelPace => 'الوتيرة';

  @override
  String get chartsLabelPartial => 'جزئي';

  @override
  String get chartsLabelPaused => 'متوقف مؤقتًا';

  @override
  String get chartsLabelPdfs => 'ملفات PDF';

  @override
  String get chartsLabelPending => 'قيد الانتظار';

  @override
  String get chartsLabelPerDay => 'في اليوم';

  @override
  String get chartsLabelPerfectDay => 'يوم مثالي';

  @override
  String get chartsLabelPlaces => 'الأماكن';

  @override
  String get chartsLabelPlanned => 'مخطَّط';

  @override
  String get chartsLabelPrevious => 'السابق';

  @override
  String get chartsLabelProjection => 'الإسقاط';

  @override
  String get chartsLabelProjection1m => 'الشهر القادم';

  @override
  String get chartsLabelProjection1y => 'السنة القادمة';

  @override
  String get chartsLabelProjection5y => 'خلال 5 سنوات';

  @override
  String get chartsLabelQuit => 'الإقلاع';

  @override
  String get chartsLabelRate => 'المعدل';

  @override
  String get chartsLabelRecurring => 'متكرر';

  @override
  String get chartsLabelReduction => 'الخفض';

  @override
  String get chartsLabelRelapse => 'انتكاسة';

  @override
  String get chartsLabelRemaining => 'المتبقي';

  @override
  String get chartsLabelRemoved => 'أُزيل';

  @override
  String get chartsLabelReopened => 'أُعيد فتحه';

  @override
  String get chartsLabelRollingMean => 'المتوسط المتحرك';

  @override
  String get chartsLabelSaved => 'المُدَّخر';

  @override
  String get chartsLabelScope => 'النطاق';

  @override
  String get chartsLabelScore => 'النتيجة';

  @override
  String get chartsLabelSkipped => 'متخطّى';

  @override
  String get chartsLabelSpent => 'المُنفَق';

  @override
  String get chartsLabelStale => 'راكدة';

  @override
  String get chartsLabelStreak => 'السلسلة';

  @override
  String get chartsLabelSuccess => 'نجاح';

  @override
  String get chartsLabelTarget => 'الهدف';

  @override
  String get chartsLabelTask => 'المهام';

  @override
  String get chartsLabelTasks => 'المهام';

  @override
  String get chartsLabelTemplates => 'القوالب';

  @override
  String get chartsLabelTimeNotSpent => 'الوقت الموفَّر';

  @override
  String get chartsLabelTodo => 'للقيام به';

  @override
  String get chartsLabelTotal => 'الإجمالي';

  @override
  String get chartsLabelTrend => 'الاتجاه';

  @override
  String get chartsLabelTriggers => 'المحفّزات';

  @override
  String get chartsLabelUncategorized => 'بلا تصنيف';

  @override
  String get chartsLabelUnder => 'أقل';

  @override
  String get chartsLabelUnits => 'الوحدات';

  @override
  String get chartsLabelUnplanned => 'غير مخطط';

  @override
  String get chartsLabelUnspecified => 'غير محدد';

  @override
  String get chartsLabelUsed => 'مستهلَك';

  @override
  String get chartsLabelVolume => 'الحجم';

  @override
  String get chartsLabelWaiting => 'بانتظار';

  @override
  String get chartsLabelWeek => 'الأسبوع';

  @override
  String get chartsLabelWeekend => 'عطلة نهاية الأسبوع';

  @override
  String get chartsLabelWhenLabel => 'متى';

  @override
  String get chartsLabelWins => 'الإنجازات';

  @override
  String get chartsLabelWip => 'قيد العمل';

  @override
  String get chartsLabelWithinLimit => 'ضمن الحد';

  @override
  String get chartsLabelWithinLimitDays => 'أيام ضمن الحد';

  @override
  String get chartsLabelYear => 'السنة';

  @override
  String get chartsLabelYes => 'نعم';

  @override
  String get chartsLegend => 'مفتاح الرسم';

  @override
  String get chartsLoading => 'جارٍ التحميل…';

  @override
  String chartsMedianAt(String value) {
    return 'الوسيط $value';
  }

  @override
  String get chartsMedianNotReached => 'لم يتم بلوغ الوسيط';

  @override
  String chartsMega(String value) {
    return '$value مليون';
  }

  @override
  String chartsMilestoneEta(String time) {
    return 'خلال $time';
  }

  @override
  String get chartsMilestoneInWindow => 'قيد التقدم';

  @override
  String get chartsMilestoneNext => 'التالي';

  @override
  String get chartsMilestoneReached => 'تم بلوغه';

  @override
  String get chartsMilestoneRestarted =>
      'أُعيد تشغيل العدّاد بعد زلّة — كل يوم أنجزته ما زال محسوبًا.';

  @override
  String chartsMilestoneSources(String sources) {
    return 'المصادر: $sources';
  }

  @override
  String chartsMinutesOnly(String minutes) {
    return '$minutes د';
  }

  @override
  String chartsNeedsMore(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يحتاج إلى $count نقطة بيانات إضافية',
      many: 'يحتاج إلى $count نقطة بيانات إضافية',
      few: 'يحتاج إلى $count نقاط بيانات إضافية',
      two: 'يحتاج إلى نقطتي بيانات إضافيتين',
      one: 'يحتاج إلى نقطة بيانات إضافية واحدة',
      zero: 'لا حاجة لمزيد من البيانات',
    );
    return '$_temp0';
  }

  @override
  String get chartsNoConsistentTime => 'لا يوجد وقت ثابت';

  @override
  String get chartsNotApplicable => '—';

  @override
  String chartsOrdinalAttempt(String n) {
    return 'المحاولة $n';
  }

  @override
  String chartsOrdinalDepth(String n) {
    return 'العمق $n';
  }

  @override
  String chartsOrdinalLevel(String n) {
    return 'المستوى $n';
  }

  @override
  String chartsOrdinalMonth(String n) {
    return 'الشهر $n';
  }

  @override
  String chartsOrdinalPriority(String n) {
    return 'الأولوية $n';
  }

  @override
  String chartsOrdinalRun(String n) {
    return 'الدورة $n';
  }

  @override
  String chartsOrdinalWeek(String n) {
    return 'الأسبوع $n';
  }

  @override
  String chartsOrdinalYear(String n) {
    return 'السنة $n';
  }

  @override
  String chartsOver(String value) {
    return '+$value';
  }

  @override
  String chartsPerDay(String value) {
    return '$value/يوم';
  }

  @override
  String chartsPerWeek(String value) {
    return '$value/أسبوع';
  }

  @override
  String chartsPlusMinus(String value) {
    return '± $value';
  }

  @override
  String get chartsPopulationEstimate => 'تقدير على مستوى السكان';

  @override
  String chartsPp(String value) {
    return '$value نقطة';
  }

  @override
  String chartsPpSpoken(String value) {
    return '$value نقطة مئوية';
  }

  @override
  String chartsPrevious(String value) {
    return 'السابق $value';
  }

  @override
  String chartsProbability(String value) {
    return 'احتمال $value';
  }

  @override
  String chartsRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String chartsRatio(String value) {
    return '$value×';
  }

  @override
  String chartsSecondsOnly(String seconds) {
    return '$seconds ث';
  }

  @override
  String get chartsSelected => 'محدد';

  @override
  String chartsSeriesToggle(String series) {
    return 'إظهار أو إخفاء $series';
  }

  @override
  String get chartsShare => 'مشاركة الرسم البياني';

  @override
  String get chartsShareHideNames => 'إخفاء الأسماء';

  @override
  String get chartsShareMark => 'أُنشئ باستخدام Everslot';

  @override
  String get chartsStreakBest => 'الأفضل';

  @override
  String get chartsStreakCurrent => 'الحالية';

  @override
  String chartsSummaryBars(
    String title,
    String count,
    String label,
    String value,
  ) {
    return '$title: $count أعمدة، الأعلى $label بقيمة $value.';
  }

  @override
  String chartsSummaryCalendar(String title, String count) {
    return '$title: عرض $count يومًا.';
  }

  @override
  String chartsSummaryLine(
    String title,
    String range,
    String first,
    String last,
    String trend,
  ) {
    return '$title، $range: من $first إلى $last. $trend';
  }

  @override
  String chartsSummaryList(String title, String count) {
    return '$title: $count عنصرًا.';
  }

  @override
  String chartsSummaryMilestones(String title, String done, String total) {
    return '$title: تم بلوغ $done من $total.';
  }

  @override
  String chartsSummaryMinMax(String min, String max) {
    return 'الأدنى $min، الأعلى $max.';
  }

  @override
  String chartsSummaryPunchCard(String title, String weekday, String hour) {
    return '$title: الذروة يوم $weekday عند $hour.';
  }

  @override
  String chartsSummaryShare(String title, String label, String share) {
    return '$title: الجزء الأكبر $label، $share.';
  }

  @override
  String chartsSummaryStreaks(String title, String length) {
    return '$title: أطول سلسلة $length.';
  }

  @override
  String chartsSummaryValue(String title, String value) {
    return '$title: $value.';
  }

  @override
  String chartsTableSort(String column) {
    return 'الترتيب حسب $column';
  }

  @override
  String get chartsTapForDetails => 'انقر مرتين لعرض التفاصيل';

  @override
  String chartsTarget(String value) {
    return 'الهدف $value';
  }

  @override
  String chartsTooltip(String label, String value) {
    return '$label: $value';
  }

  @override
  String chartsTrendFalling(String slope) {
    return 'في انخفاض بمقدار $slope أسبوعيًا.';
  }

  @override
  String chartsTrendRising(String slope) {
    return 'في ارتفاع بمقدار $slope أسبوعيًا.';
  }

  @override
  String get chartsTrendStable => 'لا يوجد اتجاه واضح.';

  @override
  String get chartsViewAsChart => 'عرض كرسم بياني';

  @override
  String get chartsViewAsTable => 'عرض كجدول';

  @override
  String get chartsVisionDeuteranopia => 'عمى اللون الأخضر';

  @override
  String get chartsVisionNormal => 'عادية';

  @override
  String get chartsVisionProtanopia => 'عمى اللون الأحمر';

  @override
  String get chartsVisionTritanopia => 'عمى اللون الأزرق';

  @override
  String get chartsVsPrevious => 'مقارنة بالفترة السابقة';

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
  String get pvActualColumn => 'Actual';

  @override
  String get pvAddTask => 'Add task';

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
  String get pvCannotUnschedule =>
      'Recurring occurrences can\'t be moved to the backlog';

  @override
  String get pvCapacity => 'Capacity';

  @override
  String get pvCategories => 'Categories';

  @override
  String get pvClearFilters => 'Clear';

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
  String pvCopySuffix(String name) {
    return '$name (copy)';
  }

  @override
  String get pvCreate => 'Create';

  @override
  String get pvCreateHere => 'Create here';

  @override
  String get pvCreatedSnack => 'Task created';

  @override
  String pvDayHeaderSemantics(String day, String items) {
    return '$day, $items';
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
  String get pvDoneTotal => 'Done';

  @override
  String get pvDragToSchedule => 'Drag onto the grid to schedule';

  @override
  String get pvDropNotSupported =>
      'This grouping can\'t be changed by dragging yet';

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
  String get pvGotIt => 'Got it';

  @override
  String get pvGroupBy => 'Group by';

  @override
  String get pvGroupCategory => 'Category';

  @override
  String get pvGroupDay => 'Day';

  @override
  String get pvGroupNone => 'None';

  @override
  String get pvGroupPriority => 'Priority';

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
  String get pvHintPinch =>
      'Pinch to zoom; pinch sideways to change the number of days';

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
  String get pvHorizonsHint =>
      'Unscheduled intentions per horizon (stored on this device until horizons sync).';

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
  String get pvLanes => 'Lanes';

  @override
  String pvLastRowShort(String duration) {
    return 'the last one $duration';
  }

  @override
  String get pvLess => 'Less';

  @override
  String get pvListBelow => 'List below';

  @override
  String get pvListMode => 'Accessible list';

  @override
  String get pvMapPlaceholder =>
      'The map needs task coordinates, which arrive with the place picker. Tasks with a place are listed below.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more items',
      one: '1 more item',
    );
    return '$_temp0';
  }

  @override
  String get pvMoreLegend => 'More';

  @override
  String get pvMoreOptions => 'More options';

  @override
  String get pvMove => 'Move';

  @override
  String get pvMoveDoneBody =>
      'It\'s already done — moving it changes its history.';

  @override
  String get pvMoveDoneTitle => 'Move a completed task?';

  @override
  String pvMoveEarlier(int minutes) {
    return 'Move $minutes min earlier';
  }

  @override
  String pvMoveLater(int minutes) {
    return 'Move $minutes min later';
  }

  @override
  String get pvMoveTo => 'Move to…';

  @override
  String get pvMoveUnfinishedTomorrow => 'Move unfinished to tomorrow';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Next $count days',
      one: 'Next day',
    );
    return '$_temp0';
  }

  @override
  String get pvNextUp => 'Next up';

  @override
  String get pvNextWeek => 'Next week';

  @override
  String get pvNoCategory => 'No category';

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
  String get pvNoTasks => 'No tasks';

  @override
  String get pvNothingNow => 'Nothing scheduled right now';

  @override
  String get pvNow => 'Now';

  @override
  String get pvOneOff => 'One-off';

  @override
  String get pvOpenDay => 'Open day';

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
  String get pvPause => 'Pause';

  @override
  String get pvPickDate => 'Pick a date';

  @override
  String get pvPin => 'Pin';

  @override
  String get pvPinned => 'Pinned';

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
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
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
  String get pvRadial12 => '12 h';

  @override
  String get pvRadial24 => '24 h';

  @override
  String get pvRadialHours => 'Dial';

  @override
  String get pvRecurring => 'Recurring';

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
  String pvSelected(int count) {
    return '$count selected';
  }

  @override
  String get pvSetDefaultView => 'Set as default';

  @override
  String get pvShareAvailability => 'Share availability';

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
  String get pvTextFilterHint => 'Search titles and notes';

  @override
  String pvTileSemantics(
    String title,
    String day,
    String start,
    String end,
    String status,
  ) {
    return '$title, $day, $start to $end, $status';
  }

  @override
  String pvTimeLeft(String duration) {
    return '$duration left';
  }

  @override
  String get pvTo => 'To';

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
  String get pvUnscheduleUnsupported =>
      'Moving tasks back to the backlog isn\'t available yet';

  @override
  String get pvUnscheduled => 'Unscheduled';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get pvWithPlace => 'Tasks with a place';

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
  String get recurAddDate => 'إضافة';

  @override
  String get recurAddTime => 'إضافة وقت';

  @override
  String get recurAdvancedTitle => 'تكرار مخصص';

  @override
  String get recurAfterHint =>
      'يحين الموعد التالي بعد هذه المدة من إنجاز السابق.';

  @override
  String recurAnchorMoved(String date) {
    return 'أول موعد: $date';
  }

  @override
  String get recurCountCompletions => 'مرات الإنجاز';

  @override
  String get recurCountMode => 'العدّ';

  @override
  String get recurCountOccurrences => 'المواعيد';

  @override
  String get recurCurrent => 'القاعدة الحالية';

  @override
  String get recurEnds => 'الانتهاء';

  @override
  String get recurEndsAfter => 'بعد عدد من المرات';

  @override
  String recurEndsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرة',
      many: '$count مرة',
      few: '$count مرات',
      two: 'مرتان',
      one: 'مرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get recurEndsNever => 'أبدًا';

  @override
  String get recurEndsOn => 'في تاريخ';

  @override
  String get recurExceptionCancelled => 'مزال';

  @override
  String get recurExceptionEdited => 'معدّل';

  @override
  String recurExceptionMoved(String to) {
    return 'نُقل إلى $to';
  }

  @override
  String get recurExceptionOpen => 'فتح';

  @override
  String get recurExceptionRestore => 'استعادة';

  @override
  String get recurExceptionRestoreAll => 'استعادة الكل';

  @override
  String get recurExceptionsEmpty => 'لا مواعيد مزالة أو منقولة';

  @override
  String get recurExceptionsRestored => 'تمت الاستعادة';

  @override
  String get recurExceptionsTitle => 'المواعيد المتخطاة والمنقولة';

  @override
  String get recurExdates => 'مواعيد مستبعدة';

  @override
  String get recurFloatingNote => 'الأوقات تتبع منطقتك الزمنية الحالية';

  @override
  String get recurFrequency => 'التواتر';

  @override
  String get recurHours => 'الساعات';

  @override
  String get recurInterval => 'كل';

  @override
  String get recurIssueCount => 'يجب أن يكون عدد المرات 1 على الأقل';

  @override
  String get recurIssueCountAndUntil => 'اختر تاريخ انتهاء أو عدد مرات';

  @override
  String get recurIssueDate => 'تاريخ غير صالح';

  @override
  String get recurIssueEmptyWeekdays => 'اختر يومًا واحدًا على الأقل';

  @override
  String get recurIssueInterval => 'يجب أن تكون الفترة 1 على الأقل';

  @override
  String get recurIssueMissing => 'القاعدة غير مكتملة';

  @override
  String get recurIssueOrdinal =>
      '«الأول» و«الأخير»… تعمل فقط مع التكرار الشهري أو السنوي';

  @override
  String recurIssueQuota(int max) {
    return 'لا يمكن تحقيق هذه الحصة مع هذا الفاصل (الحد $max)';
  }

  @override
  String recurIssueTooFrequent(int count) {
    return 'متكرر جدًا: $count في اليوم (الحد 1440)';
  }

  @override
  String get recurIssueUnsupported => 'لا يمكن الجمع بين هذه الخيارات';

  @override
  String get recurIssueUntilBeforeStart => 'تاريخ الانتهاء قبل البداية';

  @override
  String get recurIssueValue => 'قيمة خارج النطاق';

  @override
  String get recurIssueWindow => 'يجب أن تنتهي النافذة بعد بدايتها';

  @override
  String get recurLess => 'خيارات أقل';

  @override
  String get recurMinutes => 'الدقائق';

  @override
  String recurMonthDayFromEnd(int day) {
    return 'اليوم $day من النهاية';
  }

  @override
  String get recurMonthDays => 'أيام الشهر';

  @override
  String get recurMonthDaysFromEnd => 'العد من النهاية';

  @override
  String get recurMonths => 'الأشهر';

  @override
  String get recurMore => 'خيارات أكثر';

  @override
  String get recurOrdinal1 => 'الأول';

  @override
  String get recurOrdinal2 => 'الثاني';

  @override
  String get recurOrdinal3 => 'الثالث';

  @override
  String get recurOrdinal4 => 'الرابع';

  @override
  String get recurOrdinal5 => 'الخامس';

  @override
  String get recurOrdinalEvery => 'كل';

  @override
  String get recurOrdinalLast => 'الأخير';

  @override
  String get recurOrdinalSecondLast => 'قبل الأخير';

  @override
  String get recurOverflow => 'عندما يكون الشهر أقصر';

  @override
  String get recurOverflowClamp => 'استخدام آخر يوم فيه';

  @override
  String get recurOverflowSkip => 'تخطي ذلك الشهر';

  @override
  String get recurPerDay => 'اليوم';

  @override
  String get recurPerMonth => 'الشهر';

  @override
  String get recurPerWeek => 'الأسبوع';

  @override
  String get recurPerYear => 'السنة';

  @override
  String get recurPickerTitle => 'التكرار';

  @override
  String get recurPresetAfterCompletion => 'بعد الإنجاز…';

  @override
  String get recurPresetCustom => 'مخصص…';

  @override
  String get recurPresetEveryNDays => 'كل بضعة أيام…';

  @override
  String get recurPresetIntraday => 'كل بضع ساعات أو دقائق…';

  @override
  String get recurPresetNone => 'لا يتكرر';

  @override
  String get recurPresetQuota => 'عدة مرات في الأسبوع أو الشهر…';

  @override
  String get recurPresetSpecificDays => 'أيام محددة…';

  @override
  String get recurPresetTimesPerDay => 'عدة مرات في اليوم…';

  @override
  String get recurPreview => 'المواعيد القادمة';

  @override
  String get recurPreviewCalendar => 'الأيام الستون القادمة';

  @override
  String get recurPreviewEmpty => 'لا مواعيد قادمة';

  @override
  String get recurQuotaMinGap => 'أدنى عدد أيام بين مرتين';

  @override
  String get recurQuotaOnDays => 'في هذه الأيام فقط';

  @override
  String get recurQuotaPer => 'في';

  @override
  String get recurQuotaTimes => 'كم مرة';

  @override
  String get recurRdates => 'مواعيد إضافية';

  @override
  String recurRemoveTime(String time) {
    return 'إزالة $time';
  }

  @override
  String get recurSetPos => 'الاحتفاظ بالمواضع فقط';

  @override
  String get recurSetPosHint => '1 = الأول، −1 = آخر تاريخ مطابق في كل فترة';

  @override
  String get recurSummary => 'الملخص';

  @override
  String get recurTimes => 'أوقات اليوم';

  @override
  String get recurType => 'النوع';

  @override
  String get recurTypeAfter => 'بعد الإنجاز';

  @override
  String get recurTypeFixed => 'جدول زمني';

  @override
  String get recurTypeQuota => 'حصة';

  @override
  String get recurUnitDay => 'أيام';

  @override
  String get recurUnitHour => 'ساعات';

  @override
  String get recurUnitMinute => 'دقائق';

  @override
  String get recurUnitMonth => 'أشهر';

  @override
  String get recurUnitWeek => 'أسابيع';

  @override
  String get recurUnitYear => 'سنوات';

  @override
  String get recurWarnAllDaySubDaily =>
      'لا يمكن لعناصر اليوم الكامل أن تتكرر داخل اليوم';

  @override
  String get recurWarnDst => 'بعض الأوقات تقع عند تغيير التوقيت الصيفي فتُزاح';

  @override
  String get recurWarnNever => 'لا يحدث خلال السنوات الخمس القادمة';

  @override
  String recurWarnPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موعد في اليوم',
      many: '$count موعدًا في اليوم',
      few: '$count مواعيد في اليوم',
      two: 'موعدان في اليوم',
      one: 'موعد واحد في اليوم',
    );
    return '$_temp0';
  }

  @override
  String get recurWeekStart => 'يبدأ الأسبوع يوم';

  @override
  String get recurWeekdayOrdinal => 'أيّها في الفترة';

  @override
  String get recurWeekdays => 'أيام الأسبوع';

  @override
  String get recurWindow => 'النافذة اليومية';

  @override
  String get recurWindowAnchorSeries => 'متابعة السلسلة من أول موعد';

  @override
  String get recurWindowAnchorWindow => 'إعادة البدء كل يوم عند بداية النافذة';

  @override
  String get recurWindowEnd => 'حتى';

  @override
  String get recurWindowNone => 'اليوم كله';

  @override
  String get recurWindowStart => 'من';

  @override
  String recurZoneNote(String zone) {
    return 'الأوقات بتوقيت $zone';
  }

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
  String get statsCardError => 'تعذّر حساب هذه البطاقة.';

  @override
  String get statsCompareToggle => 'المقارنة بالفترة السابقة';

  @override
  String statsDetailAllTime(String value) {
    return 'على الإطلاق: $value';
  }

  @override
  String statsDetailBacklog(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهمة غير مجدولة',
      many: '$count مهمة غير مجدولة',
      few: '$count مهام غير مجدولة',
      two: 'مهمتان غير مجدولتين',
      one: 'مهمة غير مجدولة',
      zero: 'لا مهام غير مجدولة',
    );
    return '$_temp0';
  }

  @override
  String statsDetailBest(String value) {
    return 'الأفضل: $value';
  }

  @override
  String statsDetailCoverage(String value) {
    return 'الوقت متتبَّع لـ $value من المهام المنجزة';
  }

  @override
  String statsDetailDelta30(String value) {
    return '$value مقارنة بما قبل 30 يومًا';
  }

  @override
  String statsDetailLastDone(String date) {
    return 'آخر إنجاز $date';
  }

  @override
  String statsDetailOfTotal(String done, String total) {
    return '$done من $total';
  }

  @override
  String statsDetailOpen(String count) {
    return '$count مفتوحة';
  }

  @override
  String statsDetailPerDay(String value) {
    return '$value يوميًا';
  }

  @override
  String statsDetailPeriods(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فترة',
      many: '$count فترة',
      few: '$count فترات',
      two: 'فترتان',
      one: 'فترة واحدة',
      zero: 'لا فترات',
    );
    return '$_temp0';
  }

  @override
  String statsDetailPlanned(String value) {
    return 'المخطَّط: $value';
  }

  @override
  String statsDetailQueue(String time) {
    return 'بانتظار البدء منذ $time';
  }

  @override
  String statsDetailReduction(String value) {
    return 'انخفاض $value عن خط الأساس';
  }

  @override
  String statsDetailSince(String date) {
    return 'منذ $date';
  }

  @override
  String statsDetailWorkItem(String time) {
    return 'قيد العمل منذ $time';
  }

  @override
  String get statsDrillEmpty => 'لا شيء لعرضه';

  @override
  String statsDrillMore(String count) {
    return '$count إضافية';
  }

  @override
  String get statsDrillTitle => 'خلف هذا الرقم';

  @override
  String get statsEmptyHabits => 'أضف عادة لمتابعة انتظامك.';

  @override
  String get statsEmptyLists => 'أنشئ قائمة لترى كيف يسير العمل فيها.';

  @override
  String get statsEmptyPlanner => 'خطّط لبعض المهام ثم عد لرؤية الإحصاءات.';

  @override
  String get statsEmptyQuit => 'لا توجد متتبعات إقلاع بعد';

  @override
  String get statsEmptyQuitBody => 'أنشئ واحدًا في العادات لترى تقدّمك هنا.';

  @override
  String get statsEmptyTitle => 'لا شيء لعرضه بعد';

  @override
  String statsExclusionCancelled(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرة ملغاة',
      many: '$count مرة ملغاة',
      few: '$count مرات ملغاة',
      two: 'مرتان ملغاتان',
      one: 'مرة ملغاة',
      zero: 'لا مرات ملغاة',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionExcused(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وحدة معذورة',
      many: '$count وحدة معذورة',
      few: '$count وحدات معذورة',
      two: 'وحدتان معذورتان',
      one: 'وحدة معذورة',
      zero: 'لا وحدات معذورة',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionFrozen(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وحدة مجمّدة',
      many: '$count وحدة مجمّدة',
      few: '$count وحدات مجمّدة',
      two: 'وحدتان مجمّدتان',
      one: 'وحدة مجمّدة',
      zero: 'لا وحدات مجمّدة',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionPaused(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وحدة متوقفة',
      many: '$count وحدة متوقفة',
      few: '$count وحدات متوقفة',
      two: 'وحدتان متوقفتان',
      one: 'وحدة متوقفة',
      zero: 'لا وحدات متوقفة',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionSkipped(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وحدة متخطّاة',
      many: '$count وحدة متخطّاة',
      few: '$count وحدات متخطّاة',
      two: 'وحدتان متخطّاتان',
      one: 'وحدة متخطّاة',
      zero: 'لا وحدات متخطّاة',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionUnknown(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم غير مسجل',
      many: '$count يومًا غير مسجل',
      few: '$count أيام غير مسجلة',
      two: 'يومان غير مسجلين',
      one: 'يوم غير مسجل',
      zero: 'لا أيام غير مسجلة',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionUnplanned(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إضافة غير مخططة',
      many: '$count إضافة غير مخططة',
      few: '$count إضافات غير مخططة',
      two: 'إضافتان غير مخططتين',
      one: 'إضافة غير مخططة',
      zero: 'لا إضافات غير مخططة',
    );
    return '$_temp0';
  }

  @override
  String get statsExplainEstimate => 'هذا الرقم تقديري.';

  @override
  String get statsExplainExcluded => 'المستبعد';

  @override
  String get statsExplainFormula => 'طريقة الحساب';

  @override
  String get statsExplainGlossary => 'مسرد المؤشرات';

  @override
  String statsExplainId(String id) {
    return 'المؤشر $id';
  }

  @override
  String statsExplainInterval(String lower, String upper) {
    return 'مجال الثقة 95 %: $lower – $upper';
  }

  @override
  String statsExplainIntervalRule(String count) {
    return 'يُعرض هامش ± تحت $count وحدة.';
  }

  @override
  String statsExplainMinData(String count) {
    return 'يُعرض عند توفر $count وحدات على الأقل.';
  }

  @override
  String get statsExplainNothingExcluded => 'لا شيء مستبعد';

  @override
  String get statsExplainPopulation =>
      'تقدير سكاني: الضرر ليس خطيًا ويختلف من شخص لآخر، وليس تنبؤًا شخصيًا.';

  @override
  String statsExplainPrevious(String value) {
    return 'الفترة السابقة: $value';
  }

  @override
  String statsExplainSample(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بناءً على $count وحدة',
      many: 'بناءً على $count وحدة',
      few: 'بناءً على $count وحدات',
      two: 'بناءً على وحدتين',
      one: 'بناءً على وحدة واحدة',
      zero: 'بلا وحدات',
    );
    return '$_temp0';
  }

  @override
  String get statsExplainSources => 'المصادر';

  @override
  String get statsExplainThisView => 'في هذا العرض';

  @override
  String statsExplainValue(String value) {
    return 'القيمة: $value';
  }

  @override
  String get statsExplainWhat => 'ماذا يقيس';

  @override
  String get statsFilterApply => 'تطبيق';

  @override
  String get statsFilterCategories => 'التصنيفات';

  @override
  String get statsFilterClear => 'مسح';

  @override
  String get statsFilterPriority => 'الأولوية';

  @override
  String get statsFilterTags => 'الوسوم';

  @override
  String get statsFilterTracking => 'التتبع';

  @override
  String get statsFilterTrackingCheck => 'تأشير';

  @override
  String get statsFilterTrackingEvent => 'حدث';

  @override
  String get statsFilterTrackingTimer => 'مؤقت';

  @override
  String get statsFilters => 'عوامل التصفية';

  @override
  String statsFiltersActive(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عامل تصفية',
      many: '$count عامل تصفية',
      few: '$count عوامل تصفية',
      two: 'عاملا تصفية',
      one: 'عامل تصفية واحد',
      zero: 'بلا عوامل تصفية',
    );
    return '$_temp0';
  }

  @override
  String get statsHealthClockNote =>
      'تتبع المحطات مدة امتناعك الحالية عن التدخين: يُعاد تشغيل العدّاد بعد الزلّة.';

  @override
  String get statsHealthDisclaimer =>
      'تقديرات تثقيفية مبنية على متوسطات سكانية من منظمة الصحة العالمية وهيئة NHS ومراكز CDC والجمعية الأمريكية للسرطان؛ وتختلف النتائج من شخص لآخر. ليست نصيحة طبية. استشر مختصًا في الرعاية الصحية.';

  @override
  String get statsHealthElapsedNote =>
      'النسب تعبّر عن الوقت المنقضي فقط وليست قياسات فسيولوجية.';

  @override
  String statsHealthRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get statsMetricClI01Desc => 'المدة التي قضاها هذا العنصر في كل حالة.';

  @override
  String get statsMetricClI01Formula =>
      'مجموع الفترات في كل حالة حتى الآن (أو الحذف).';

  @override
  String get statsMetricClI01Title => 'الوقت في كل حالة';

  @override
  String get statsMetricClI02Desc => 'الوقت من بدء العمل حتى الإكمال.';

  @override
  String get statsMetricClI02Formula =>
      'الإكمال − البدء (أول خروج من \"للقيام به\").';

  @override
  String get statsMetricClI02Title => 'زمن الدورة';

  @override
  String get statsMetricClI03Desc => 'الوقت من الإنشاء حتى الإكمال.';

  @override
  String get statsMetricClI03Formula => 'الإكمال − الإنشاء.';

  @override
  String get statsMetricClI03Title => 'المهلة الكلية';

  @override
  String get statsMetricClI04Desc =>
      'منذ متى والعنصر المفتوح قيد العمل أو بانتظار البدء.';

  @override
  String get statsMetricClI04Formula =>
      'بدأ: الآن − البدء؛ لم يبدأ: الآن − الإنشاء.';

  @override
  String get statsMetricClI04Title => 'العمر';

  @override
  String get statsMetricClI05Desc => 'الوقت منذ آخر نشاط على هذا العنصر.';

  @override
  String get statsMetricClI05Formula =>
      'الآن − آخر نشاط (تغيير حالة أو تعديل أو مرفق أو عنصر فرعي).';

  @override
  String get statsMetricClI05Title => 'الركود';

  @override
  String get statsMetricClI06Desc =>
      'مدى إكمال العناصر المتفرعة من هذا العنصر.';

  @override
  String get statsMetricClI06Formula =>
      'الأوراق المكتملة ÷ الأوراق المحسوبة (باستثناء الملغاة).';

  @override
  String get statsMetricClI06Title => 'تقدّم الشجرة الفرعية';

  @override
  String get statsMetricClI07Desc => 'تاريخ العنصر كمقاطع ملونة مع الملاحظات.';

  @override
  String get statsMetricClI07Formula => 'كل فترة حالة من الإنشاء حتى الآن.';

  @override
  String get statsMetricClI07Title => 'خط زمني للحالات';

  @override
  String get statsMetricClL01Desc => 'كيفية توزع عناصر القائمة على الحالات.';

  @override
  String get statsMetricClL01Formula =>
      'العناصر لكل حالة؛ نسبة الإكمال على الأوراق وعلى كل العُقد.';

  @override
  String get statsMetricClL01Title => 'توزيع الحالات';

  @override
  String get statsMetricClL02Desc => 'نسبة إكمال القائمة يوميًا.';

  @override
  String get statsMetricClL02Formula =>
      'المكتمل ÷ (العناصر − الملغاة) في نهاية كل يوم.';

  @override
  String get statsMetricClL02Title => 'التقدّم عبر الزمن';

  @override
  String get statsMetricClL03Desc =>
      'العناصر المكتملة أسبوعيًا مع متوسط متحرك لأربعة أسابيع.';

  @override
  String get statsMetricClL03Formula =>
      'الإكمالات لكل فترة (العنصر المعاد فتحه يُحسب مرة واحدة).';

  @override
  String get statsMetricClL03Title => 'الإنتاجية';

  @override
  String get statsMetricClL04Desc =>
      'العناصر الجارية أو المنتظرة أو المحظورة في نهاية كل يوم.';

  @override
  String get statsMetricClL04Formula =>
      'عدد العناصر الجارية + المنتظرة + المحظورة.';

  @override
  String get statsMetricClL04Title => 'العمل الجاري';

  @override
  String get statsMetricClL05Desc => 'العناصر المضافة مقابل المكتملة أسبوعيًا.';

  @override
  String get statsMetricClL05Formula =>
      'المُنشأ (أو المنقول إليها) مقابل المكتمل أسبوعيًا؛ صافي التدفق = الفرق.';

  @override
  String get statsMetricClL05Title => 'الوافد مقابل المغادِر';

  @override
  String get statsMetricClL06Desc =>
      'عناصر مفتوحة بلا نشاط منذ مدة، والأقدم منها.';

  @override
  String get statsMetricClL06Formula =>
      'العناصر المفتوحة التي تجاوز ركودها الحد؛ أقدم 10 عناصر.';

  @override
  String get statsMetricClL06Title => 'العناصر الراكدة';

  @override
  String get statsMetricClX01Desc =>
      'قوائمك: النشطة والمؤرشفة والقوالب والراكدة.';

  @override
  String get statsMetricClX01Formula =>
      'عدد القوائم؛ الراكدة = بلا نشاط منذ N يومًا مع عناصر مفتوحة.';

  @override
  String get statsMetricClX01Title => 'نظرة على القوائم';

  @override
  String get statsMetricClX02Desc =>
      'العناصر المضافة مقابل المكتملة أسبوعيًا في كل القوائم.';

  @override
  String get statsMetricClX02Formula =>
      'المُنشأ مقابل المكتمل أسبوعيًا؛ صافي التدفق = الفرق.';

  @override
  String get statsMetricClX02Title => 'الوافد مقابل المغادِر (كل القوائم)';

  @override
  String get statsMetricClX03Desc =>
      'العناصر الجارية أو المنتظرة أو المحظورة الآن، وأقدم العناصر المفتوحة.';

  @override
  String get statsMetricClX03Formula =>
      'الأعداد في القوائم النشطة (باستثناء المؤرشفة).';

  @override
  String get statsMetricClX03Title => 'العمل الجاري في كل القوائم';

  @override
  String get statsMetricClX04Desc => 'العناصر المكتملة خلال الفترة.';

  @override
  String get statsMetricClX04Formula =>
      'الإكمالات النهائية في الفترة مقارنة بالفترة السابقة.';

  @override
  String get statsMetricClX04Title => 'العناصر المكتملة';

  @override
  String get statsMetricClX05Desc => 'العناصر لكل حالة في كل القوائم.';

  @override
  String get statsMetricClX05Formula => 'عدد العناصر الحية لكل حالة.';

  @override
  String get statsMetricClX05Title => 'التوزيع حسب الحالة';

  @override
  String get statsMetricGl01Desc =>
      'يومك عبر الأقسام: جدول الأعمال والعادات والقوائم والإقلاع.';

  @override
  String get statsMetricGl01Formula =>
      'الأرقام نفسها التي تعرضها مؤشرات كل قسم لهذا اليوم.';

  @override
  String get statsMetricGl01Title => 'اليوم';

  @override
  String get statsMetricGl02Desc =>
      'هذا الأسبوع حتى الآن مقابل الأيام نفسها من الأسبوع الماضي.';

  @override
  String get statsMetricGl02Formula =>
      'مؤشرات الأقسام حتى تاريخه وتغيّرها عن الأسبوع السابق.';

  @override
  String get statsMetricGl02Title => 'الأسبوع في لمحة';

  @override
  String get statsMetricGl03Desc =>
      'أسبوعك: أبرز الأرقام والإنجازات وما يحتاج إلى متابعة وحمل الأسبوع القادم.';

  @override
  String get statsMetricGl03Formula =>
      'مؤشرات الأقسام وتغيّرها عن الأسبوع السابق.';

  @override
  String get statsMetricGl03Title => 'المراجعة الأسبوعية';

  @override
  String get statsMetricHbH01Desc =>
      'مدى رسوخ العادة — الأيام الأحدث وزنها أكبر.';

  @override
  String get statsMetricHbH01Formula =>
      'نتيجة Loop: النتيجة = السابقة × m + الرصيد × (1 − m)، m = 0.5^(√f ÷ 13).';

  @override
  String get statsMetricHbH01Title => 'قوة العادة';

  @override
  String get statsMetricHbH02Desc =>
      'وحدات ناجحة متتالية حتى الآن؛ يبقى اليوم مفتوحًا حتى نهايته.';

  @override
  String get statsMetricHbH02Formula =>
      'محرك السلاسل: التخطي والعذر والإيقاف والتجميد محايدة.';

  @override
  String get statsMetricHbH02Title => 'السلسلة الحالية';

  @override
  String get statsMetricHbH03Desc => 'أطول سلسلة من الوحدات الناجحة.';

  @override
  String get statsMetricHbH03Formula => 'أطول سلسلة مع مدى تواريخها.';

  @override
  String get statsMetricHbH03Title => 'أفضل سلسلة';

  @override
  String get statsMetricHbH04Desc => 'أطول عشر سلاسل لديك.';

  @override
  String get statsMetricHbH04Formula => 'السلاسل مرتبة حسب الطول ثم الحداثة.';

  @override
  String get statsMetricHbH04Title => 'أفضل السلاسل';

  @override
  String get statsMetricHbH05Desc => 'نسبة الوحدات المجدولة التي أنجزتها.';

  @override
  String get statsMetricHbH05Formula =>
      'المنجز ÷ (الوحدات المجدولة المغلقة − المعذورة)؛ مجال ويلسون تحت 20 وحدة.';

  @override
  String get statsMetricHbH05Title => 'معدل النجاح';

  @override
  String get statsMetricHbH06Desc => 'كيف انتهت كل وحدة مجدولة.';

  @override
  String get statsMetricHbH06Formula =>
      'عدد الوحدات الناجحة والجزئية وغير المنجزة والفائتة والمتخطّاة والمعذورة.';

  @override
  String get statsMetricHbH06Title => 'عدد النتائج';

  @override
  String get statsMetricHbH07Desc =>
      'النجاحات (والحجم) لكل أسبوع أو شهر أو سنة.';

  @override
  String get statsMetricHbH07Formula => 'مجاميع لكل فترة.';

  @override
  String get statsMetricHbH07Title => 'السجل';

  @override
  String get statsMetricHbH08Desc => 'حالة كل يوم.';

  @override
  String get statsMetricHbH08Formula =>
      'خانة لكل يوم: منجز، جزئي، غير منجز، فائت، متخطّى، معذور، متوقف، مجمّد.';

  @override
  String get statsMetricHbH08Title => 'التقويم';

  @override
  String get statsMetricHbH09Desc => 'كل تسجيل صوت للشخص الذي تريد أن تكونه.';

  @override
  String get statsMetricHbH09Formula =>
      'العدد الكلي لتسجيلات الإنجاز والتقدم اليدوية.';

  @override
  String get statsMetricHbH09Title => 'إجمالي التكرارات';

  @override
  String get statsMetricHbH10Desc => 'مقدار ما بلغته من هدف الفترة.';

  @override
  String get statsMetricHbH10Formula =>
      'المُنجَز ÷ (الهدف اليومي × الأيام المجدولة − الأيام المتخطّاة).';

  @override
  String get statsMetricHbH10Title => 'التقدّم نحو الهدف';

  @override
  String get statsMetricHbH11Desc => 'كل ما سجلته بوحدة العادة.';

  @override
  String get statsMetricHbH11Formula =>
      'مجموع القيم المسجلة في الفترة وعلى الإطلاق.';

  @override
  String get statsMetricHbH11Title => 'الحجم الإجمالي';

  @override
  String get statsMetricHbX01Desc => 'العادات المستحقة المنجزة اليوم.';

  @override
  String get statsMetricHbX01Formula =>
      'المنجز ÷ المستحق اليوم (عادات البناء).';

  @override
  String get statsMetricHbX01Title => 'تقدّم اليوم';

  @override
  String get statsMetricHbX02Desc => 'أيام أُنجزت فيها كل العادات المستحقة.';

  @override
  String get statsMetricHbX02Formula =>
      'أيام أُنجزت فيها كل الوحدات المستحقة؛ سلسلة الأيام المثالية.';

  @override
  String get statsMetricHbX02Title => 'أيام مثالية';

  @override
  String get statsMetricHbX03Desc => 'مقدار ما أنجزته من عادات كل يوم.';

  @override
  String get statsMetricHbX03Formula =>
      'لكل يوم: المنجز ÷ المستحق لكل العادات.';

  @override
  String get statsMetricHbX03Title => 'الإنجاز اليومي';

  @override
  String get statsMetricHbX04Desc => 'معدل النجاح الأسبوعي لكل العادات.';

  @override
  String get statsMetricHbX04Formula =>
      'المنجز ÷ المستحق أسبوعيًا مع خط متحرك لأربعة أسابيع؛ الفرق عن الأسبوع السابق بالنقاط.';

  @override
  String get statsMetricHbX04Title => 'اتجاه الالتزام';

  @override
  String get statsMetricHbX05Desc =>
      'المال الموفَّر والوحدات المتجنَّبة والعمر المستعاد لكل متتبعات الإقلاع.';

  @override
  String get statsMetricHbX05Formula =>
      'مجاميع متتبعات الإقلاع النشطة (العمر المستعاد تقدير سكاني).';

  @override
  String get statsMetricHbX05Title => 'ملخص الإقلاع';

  @override
  String get statsMetricPlS01Desc => 'عدد مرات استحقاق السلسلة خلال الفترة.';

  @override
  String get statsMetricPlS01Formula =>
      'مرات قاعدة التكرار ضمن الفترة؛ المغلقة والمفتوحة تُحسب كلٌّ على حدة.';

  @override
  String get statsMetricPlS01Title => 'المرات المتوقعة';

  @override
  String get statsMetricPlS02Desc => 'توزيع مرات السلسلة حسب النتيجة.';

  @override
  String get statsMetricPlS02Formula =>
      'عدد المرات المنجزة (D) والفائتة (M) والمتخطّاة (K) والمعذورة (X).';

  @override
  String get statsMetricPlS02Title => 'منجز وفائت ومتخطّى';

  @override
  String get statsMetricPlS03Desc => 'نسبة المرات المستحقة التي أنجزتها.';

  @override
  String get statsMetricPlS03Formula =>
      'المنجز ÷ (المتوقع − المعذور)، مع خط متحرك لأربعة أسابيع واتجاه أسبوعي.';

  @override
  String get statsMetricPlS03Title => 'الالتزام';

  @override
  String get statsMetricPlS04Desc =>
      'نسبة المرات المستحقة الفائتة أو غير المنجزة.';

  @override
  String get statsMetricPlS04Formula =>
      '(الفائت + غير المنجز) ÷ (المتوقع − المعذور).';

  @override
  String get statsMetricPlS04Title => 'معدل الفوات';

  @override
  String get statsMetricPlS05Desc =>
      'مرات منجزة متتالية؛ التخطي محايد افتراضيًا.';

  @override
  String get statsMetricPlS05Formula => 'محرك السلاسل بوحدة لكل مرة.';

  @override
  String get statsMetricPlS05Title => 'السلسلة الحالية والأفضل';

  @override
  String get statsMetricPlS06Desc =>
      'الوقت المتتبَّع والمخطَّط التراكمي منذ بدء السلسلة.';

  @override
  String get statsMetricPlS06Formula =>
      'مجاميع تراكمية للدقائق الفعلية والمخطَّطة.';

  @override
  String get statsMetricPlS06Title => 'الوقت المستثمَر';

  @override
  String get statsMetricPlS07Desc => 'العدد الكلي للمرات المنجزة.';

  @override
  String get statsMetricPlS07Formula => 'عدد المرات المنجزة.';

  @override
  String get statsMetricPlS07Title => 'إجمالي المنجز';

  @override
  String get statsMetricPlS08Desc => 'الأيام منذ آخر مرة منجزة.';

  @override
  String get statsMetricPlS08Formula => 'اليوم − تاريخ آخر إنجاز.';

  @override
  String get statsMetricPlS08Title => 'آخر إنجاز';

  @override
  String get statsMetricPlS09Desc => 'نتيجة كل يوم للسلسلة.';

  @override
  String get statsMetricPlS09Formula =>
      'أسوأ نتيجة في اليوم: فائت > جزئي > متأخر > متخطّى > منجز > معذور.';

  @override
  String get statsMetricPlS09Title => 'تقويم النتائج';

  @override
  String get statsMetricPlT01Desc => 'المدة التي خُطِّط أن تستغرقها هذه المرة.';

  @override
  String get statsMetricPlT01Formula => 'نهاية مخطَّطة − بداية مخطَّطة.';

  @override
  String get statsMetricPlT01Title => 'المدة المخطَّطة';

  @override
  String get statsMetricPlT02Desc =>
      'الوقت المتتبَّع فعليًا لهذه المرة دون فترات التوقف.';

  @override
  String get statsMetricPlT02Formula =>
      'مجموع مدد الجلسات المتتبَّعة؛ غير معروفة إن لم يُتتبَّع شيء.';

  @override
  String get statsMetricPlT02Title => 'المدة الفعلية';

  @override
  String get statsMetricPlT03Desc =>
      'الفرق بين الوقت الفعلي والمخطَّط ونسبتهما.';

  @override
  String get statsMetricPlT03Formula =>
      'الفعلي − المخطَّط؛ النسبة R = الفعلي ÷ المخطَّط (عندما يكون المخطَّط ≥ 5 د).';

  @override
  String get statsMetricPlT03Title => 'فرق المدة';

  @override
  String get statsMetricPlT04Desc => 'مدى تقدّم أو تأخر البدء مقارنة بالخطة.';

  @override
  String get statsMetricPlT04Formula =>
      'بداية أول جلسة − البداية المخطَّطة؛ في الوقت ضمن هامش السماح.';

  @override
  String get statsMetricPlT04Title => 'تأخر البدء';

  @override
  String get statsMetricPlT05Desc => 'مدى تقدّم أو تأخر إنهاء هذه المرة.';

  @override
  String get statsMetricPlT05Formula =>
      'وقت الإنجاز (أو نهاية آخر جلسة للمؤقت) − النهاية المخطَّطة.';

  @override
  String get statsMetricPlT05Title => 'تأخر الإنهاء';

  @override
  String get statsMetricPlT06Desc => 'ما حدث لهذه المرة.';

  @override
  String get statsMetricPlT06Formula =>
      'منجز في الوقت أو متأخرًا، جزئي، متخطّى، فائت، ملغى، قيد الانتظار أو قادم.';

  @override
  String get statsMetricPlT06Title => 'النتيجة';

  @override
  String get statsMetricPlT07Desc => 'منذ متى تأخرت مرة لم تُنجز بعد.';

  @override
  String get statsMetricPlT07Formula =>
      'الآن − النهاية المخطَّطة، مجمّعة 1 / 7 / 14 / 30+ يومًا.';

  @override
  String get statsMetricPlT07Title => 'عمر التأخر';

  @override
  String get statsMetricPlX01Desc =>
      'نسبة ما أنجزته مما كان مخطَّطًا في بداية الفترة.';

  @override
  String get statsMetricPlX01Formula =>
      'المخطَّط والمنجز في الفترة ÷ المخطَّط عند بدايتها؛ الإضافات اللاحقة مستبعدة.';

  @override
  String get statsMetricPlX01Title => 'الإنجاز مقابل الخطة';

  @override
  String get statsMetricPlX02Desc => 'المهام المخطَّطة والمنجزة لكل يوم.';

  @override
  String get statsMetricPlX02Formula =>
      'لكل يوم: عدد المخطَّط (لقطة الخطة) والمنجز.';

  @override
  String get statsMetricPlX02Title => 'المنجز مقابل المخطَّط يوميًا';

  @override
  String get statsMetricPlX03Desc =>
      'مهام أُضيفت بعد بدء الفترة ومهام نُقلت خارجها أو إليها.';

  @override
  String get statsMetricPlX03Formula =>
      'عدد الإضافات غير المخطَّطة والمرات المنقولة خارجًا وداخلًا.';

  @override
  String get statsMetricPlX03Title => 'غير المخطَّط والمنقول';

  @override
  String get statsMetricPlX04Desc =>
      'المهام المُنشأة مقابل المنجزة أسبوعيًا، والمتراكم المفتوح.';

  @override
  String get statsMetricPlX04Formula =>
      'المُنشأ والمنجز أسبوعيًا؛ المتراكم = مهام غير مجدولة + مرات متأخرة.';

  @override
  String get statsMetricPlX04Title => 'تدفق المتراكم';

  @override
  String get statsMetricPlX05Desc =>
      'نسبة المهام المنجزة قبل نهايتها المخطَّطة.';

  @override
  String get statsMetricPlX05Formula =>
      'المنجز في الوقت ÷ المنجز (بما في ذلك هامش السماح).';

  @override
  String get statsMetricPlX05Title => 'الإنجاز في الوقت';

  @override
  String get statsMetricPlX06Desc =>
      'مهام غير منجزة تجاوزت نهايتها المخطَّطة، حسب العمر.';

  @override
  String get statsMetricPlX06Formula =>
      'المرات المفتوحة المتأخرة مجمّعة 1 / 7 / 14 / 30+ يومًا.';

  @override
  String get statsMetricPlX06Title => 'المتأخر الآن';

  @override
  String get statsMetricPlX07Desc => 'الوقت المتاح للعمل المخطَّط خلال الفترة.';

  @override
  String get statsMetricPlX07Formula =>
      'ساعات العمل اليومية ناقص الفترات غير المتاحة، مجمّعة على الفترة.';

  @override
  String get statsMetricPlX07Title => 'السعة';

  @override
  String get statsMetricPlX08Desc => 'مقدار السعة المشغول بالمهام المخطَّطة.';

  @override
  String get statsMetricPlX08Formula =>
      'الدقائق المخطَّطة داخل ساعات العمل ÷ السعة (قد تتجاوز 100 % مع التداخل).';

  @override
  String get statsMetricPlX08Title => 'الاستغلال المخطَّط';

  @override
  String get statsMetricPlX09Desc => 'مقدار السعة المستهلَك في عمل متتبَّع.';

  @override
  String get statsMetricPlX09Formula =>
      'الدقائق المتتبَّعة داخل ساعات العمل ÷ السعة؛ يتطلب تغطية تتبع 60 %.';

  @override
  String get statsMetricPlX09Title => 'الاستغلال الفعلي';

  @override
  String get statsMetricPlX10Desc => 'أيام خُطِّط فيها أكثر من الوقت المتاح.';

  @override
  String get statsMetricPlX10Formula =>
      'أيام الحمل المخطَّط فيها > السعة؛ دقائق الزيادة = الحمل − السعة.';

  @override
  String get statsMetricPlX10Title => 'أيام مُثقلة';

  @override
  String get statsMetricPlX11Desc => 'السعة المتبقية من الآن حتى نهاية الفترة.';

  @override
  String get statsMetricPlX11Formula =>
      'السعة المتبقية − الوقت المخطَّط المتبقي (من الآن).';

  @override
  String get statsMetricPlX11Title => 'الوقت الحر المتبقي';

  @override
  String get statsMetricPlX12Desc =>
      'الوقت المخطَّط والمتتبَّع لكل يوم وتصنيف.';

  @override
  String get statsMetricPlX12Formula =>
      'مجموع الدقائق المخطَّطة مقابل مجموع الدقائق المتتبَّعة.';

  @override
  String get statsMetricPlX12Title => 'الساعات المخطَّطة مقابل الفعلية';

  @override
  String get statsMetricPlX13Desc => 'أين يذهب وقتك حسب التصنيف.';

  @override
  String get statsMetricPlX13Formula =>
      'الدقائق المتتبَّعة لكل تصنيف (المخطَّطة إذا غطى التتبع < 60 %)؛ نسبتها من الإجمالي.';

  @override
  String get statsMetricPlX13Title => 'الوقت حسب التصنيف';

  @override
  String get statsMetricPlX14Desc => 'الوقت الأسبوعي لكل تصنيف.';

  @override
  String get statsMetricPlX14Formula => 'الدقائق لكل تصنيف في كل أسبوع.';

  @override
  String get statsMetricPlX14Title => 'اتجاه التصنيفات';

  @override
  String get statsMetricPlX15Desc =>
      'نسبة الوقت المخطَّط الذي تشغله الأحداث بدل المهام.';

  @override
  String get statsMetricPlX15Formula =>
      'دقائق الأحداث ÷ (دقائق الأحداث + المهام).';

  @override
  String get statsMetricPlX15Title => 'الأحداث مقابل المهام';

  @override
  String get statsMetricQt01Desc => 'الوقت المنقضي منذ تاريخ إقلاعك.';

  @override
  String get statsMetricQt01Formula => 'الآن − تاريخ الإقلاع (مباشر).';

  @override
  String get statsMetricQt01Title => 'منذ الإقلاع';

  @override
  String get statsMetricQt02Desc => 'الوقت منذ آخر استخدام (أو تاريخ الإقلاع).';

  @override
  String get statsMetricQt02Formula =>
      'الآن − الأحدث من (تاريخ الإقلاع، آخر استخدام) (مباشر).';

  @override
  String get statsMetricQt02Title => 'الامتناع الحالي';

  @override
  String get statsMetricQt03Desc => 'أطول فترة لديك دون استخدام.';

  @override
  String get statsMetricQt03Formula =>
      'أطول فجوة بين الإقلاع ومرات الاستخدام والآن.';

  @override
  String get statsMetricQt03Title => 'أطول امتناع';

  @override
  String get statsMetricQt04Desc => 'الأيام منذ الإقلاع دون أي استخدام.';

  @override
  String get statsMetricQt04Formula => 'عدد الأيام المغلقة دون استخدام.';

  @override
  String get statsMetricQt04Title => 'أيام الامتناع';

  @override
  String get statsMetricQt05Desc => 'نسبة الأيام دون استخدام منذ الإقلاع.';

  @override
  String get statsMetricQt05Formula =>
      'أيام الامتناع ÷ الأيام المغلقة منذ الإقلاع.';

  @override
  String get statsMetricQt05Title => 'نسبة أيام الامتناع';

  @override
  String get statsMetricQt06Desc =>
      'عدد الوحدات التي لم تستهلكها بفضل الإقلاع.';

  @override
  String get statsMetricQt06Formula =>
      'خط الأساس اليومي × الأيام − الوحدات المستهلكة (بحد أدنى 0).';

  @override
  String get statsMetricQt06Title => 'الوحدات المتجنَّبة';

  @override
  String get statsMetricQt07Desc => 'المال الذي لم تنفقه بفضل الإقلاع.';

  @override
  String get statsMetricQt07Formula =>
      'الوحدات المتجنَّبة يوميًا × سعر الوحدة الساري في ذلك اليوم.';

  @override
  String get statsMetricQt07Title => 'المال الموفَّر';

  @override
  String get statsMetricQt08Desc =>
      'المال المُنفَق على مرات الاستخدام منذ الإقلاع.';

  @override
  String get statsMetricQt08Formula => 'الوحدات المستهلكة × سعر الوحدة حينها.';

  @override
  String get statsMetricQt08Title => 'المُنفَق في الزلّات';

  @override
  String get statsMetricQt09Desc => 'ما ستوفره إذا واصلت.';

  @override
  String get statsMetricQt09Formula =>
      'خط الأساس الحالي × سعر الوحدة على الشهر والسنة والسنوات الخمس القادمة.';

  @override
  String get statsMetricQt09Title => 'إسقاط المدخرات';

  @override
  String get statsMetricQt10Desc =>
      'تقدير سكاني لمتوسط العمر المستعاد — ليس تنبؤًا شخصيًا.';

  @override
  String get statsMetricQt10Formula =>
      'الوحدات المتجنَّبة × دقائق العمر لكل وحدة (≈ 20 دقيقة للسيجارة، Jackson وآخرون 2025).';

  @override
  String get statsMetricQt10Title => 'العمر المستعاد';

  @override
  String get statsMetricQt11Desc => 'محطات التعافي المعتادة بعد آخر سيجارة.';

  @override
  String get statsMetricQt11Formula =>
      'التقدّم = الامتناع الحالي ÷ زمن المحطة؛ يُعاد تشغيل العدّاد بعد الزلّة.';

  @override
  String get statsMetricQt11Title => 'محطات صحية';

  @override
  String get statsMetricQt12Desc =>
      'كم مرة بقيت ضمن حدك اليومي ومقدار ما خفّضته.';

  @override
  String get statsMetricQt12Formula =>
      'الأيام ضمن الحد ÷ الأيام؛ الخفض = 1 − متوسط الاستهلاك ÷ خط الأساس.';

  @override
  String get statsMetricQt12Title => 'تقدّم الخفض';

  @override
  String get statsMetricQt13Desc => 'مدى تكرار الرغبات الملحّة وشدتها.';

  @override
  String get statsMetricQt13Formula =>
      'الرغبات يوميًا خلال الفترة؛ متوسط وأقصى شدة؛ متوسط متحرك لسبعة أيام.';

  @override
  String get statsMetricQt13Title => 'عبء الرغبات';

  @override
  String get statsMetricQt14Desc => 'ما يثير الرغبات وأين ومتى.';

  @override
  String get statsMetricQt14Formula =>
      'باريتو حسب المحفّز والمكان والمزاج؛ مصفوفة اليوم × الساعة.';

  @override
  String get statsMetricQt14Title => 'سياق الرغبات';

  @override
  String get statsNoteAbstainMode => 'لمتتبعات وضع الخفض فقط.';

  @override
  String get statsNoteAllDay => 'لا مدة لمهام اليوم الكامل.';

  @override
  String get statsNoteClosed => 'هذا العنصر مغلق.';

  @override
  String get statsNoteError => 'تعذّر الحساب';

  @override
  String get statsNoteLimitHabit =>
      'تعرض عادات الحد الأيام ضمن الحد بدلًا من ذلك.';

  @override
  String get statsNoteLowCoverage =>
      'تتبّع الوقت لـ 60 % على الأقل من المهام المنجزة لرؤية هذا.';

  @override
  String get statsNoteNew => 'جديد';

  @override
  String get statsNoteNoData => 'لا توجد بيانات بعد';

  @override
  String get statsNoteNoGoal => 'لا يوجد هدف';

  @override
  String get statsNoteNoHabit => 'تعذّر العثور على هذه العادة.';

  @override
  String get statsNoteNoItem => 'تعذّر العثور على هذا العنصر.';

  @override
  String get statsNoteNoLifeEstimate =>
      'حدّد دقائق العمر لكل وحدة لرؤية هذا التقدير.';

  @override
  String get statsNoteNoOccurrence => 'تعذّر العثور على هذه المرة.';

  @override
  String get statsNoteNoQuitTrackers => 'لا توجد متتبعات إقلاع بعد.';

  @override
  String get statsNoteNoTracker => 'تعذّر العثور على متتبع الإقلاع هذا.';

  @override
  String get statsNoteNoUnitCost => 'حدّد سعر الوحدة لرؤية المدخرات.';

  @override
  String get statsNoteNotApplicable => 'لا ينطبق';

  @override
  String get statsNoteNotDone => 'لم يُنجز بعد';

  @override
  String get statsNoteNotOverdue => 'غير متأخرة';

  @override
  String get statsNoteNotScheduled => 'غير مجدول';

  @override
  String get statsNoteNotSmoking =>
      'تُعرض المحطات الصحية لمتتبعات التدخين فقط.';

  @override
  String get statsNoteNotStarted => 'لم يبدأ';

  @override
  String get statsNoteNotTracked => 'الوقت الفعلي غير متتبَّع';

  @override
  String get statsNotePastPeriod => 'للفترات الحالية والمستقبلية فقط.';

  @override
  String get statsNotePopulationEstimate => 'تقدير سكاني';

  @override
  String get statsNoteUsedPlanned =>
      'يُعرض الوقت المخطَّط: الوقت الفعلي متتبَّع لأقل من 60 % من المهام المنجزة.';

  @override
  String get statsNoteYesNoHabit => 'غير متاح لعادات نعم/لا.';

  @override
  String get statsNoteZeroDenominator => 'لم يكن هناك شيء مستحق في هذه الفترة.';

  @override
  String statsOpenInsights(String section) {
    return 'فتح $section';
  }

  @override
  String statsOverviewNextUp(String title, String time) {
    return 'التالي: $title عند $time';
  }

  @override
  String get statsOverviewOpenReview => 'المراجعة الأسبوعية';

  @override
  String get statsPeriodAll => 'الكل';

  @override
  String get statsPeriodCustom => 'مخصص';

  @override
  String statsPeriodCustomRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get statsPeriodLastMonth => 'الشهر الماضي';

  @override
  String get statsPeriodLastQuarter => 'الربع الماضي';

  @override
  String get statsPeriodLastWeek => 'الأسبوع الماضي';

  @override
  String get statsPeriodLastYear => 'السنة الماضية';

  @override
  String get statsPeriodMonth => 'الشهر';

  @override
  String get statsPeriodQuarter => 'الربع';

  @override
  String statsPeriodRolling(String days) {
    return 'آخر $days يومًا';
  }

  @override
  String get statsPeriodRollingMenu => 'متحرك';

  @override
  String statsPeriodSelected(String period) {
    return 'الفترة: $period';
  }

  @override
  String get statsPeriodToday => 'اليوم';

  @override
  String get statsPeriodWeek => 'الأسبوع';

  @override
  String get statsPeriodYear => 'السنة';

  @override
  String get statsPeriodYesterday => 'أمس';

  @override
  String get statsQuitMilestoneBreathing72h => 'يصبح التنفس أسهل وترتفع الطاقة';

  @override
  String get statsQuitMilestoneCancers20y =>
      'خطر سرطانات الفم والحلق والحنجرة والبنكرياس قريب من خطر من لم يدخن قط';

  @override
  String get statsQuitMilestoneChd15y =>
      'خطر أمراض القلب التاجية قريب من خطر غير المدخن';

  @override
  String get statsQuitMilestoneChdAdded =>
      'ينخفض الخطر الإضافي لأمراض القلب التاجية إلى النصف';

  @override
  String get statsQuitMilestoneCirculation =>
      'تتحسن الدورة الدموية ووظائف الرئة';

  @override
  String get statsQuitMilestoneCo12h =>
      'يعود أول أكسيد الكربون في الدم إلى المستوى الطبيعي';

  @override
  String get statsQuitMilestoneCo8h =>
      'ينخفض أول أكسيد الكربون في الدم إلى النصف ويتعافى مستوى الأكسجين';

  @override
  String get statsQuitMilestoneCravings =>
      'تخف الرغبات عادةً (تستمر الرغبة الواحدة نحو 3–5 دقائق)';

  @override
  String get statsQuitMilestoneHeart20m =>
      'ينخفض معدل ضربات القلب وضغط الدم ويعود النبض إلى طبيعته';

  @override
  String get statsQuitMilestoneHeartAttack => 'ينخفض خطر النوبة القلبية بشدة';

  @override
  String get statsQuitMilestoneHeartHalf1y =>
      'خطر أمراض القلب التاجية نحو نصف خطر المدخن';

  @override
  String get statsQuitMilestoneLifeExpectancy =>
      'الإقلاع في سن 30 / 40 / 50 / 60 يضيف نحو 10 / 9 / 6 / 3 سنوات إلى متوسط العمر';

  @override
  String get statsQuitMilestoneLungCancer10y =>
      'خطر سرطان الرئة نحو نصف خطر المدخن';

  @override
  String get statsQuitMilestoneLungs =>
      'يقل السعال وضيق التنفس وتتحسن وظائف الرئة بنحو 10 %';

  @override
  String get statsQuitMilestoneMouthCancer =>
      'ينخفض خطر سرطانات الفم والحلق والحنجرة إلى النصف ويتراجع خطر السكتة الدماغية';

  @override
  String get statsQuitMilestoneNicotine24h =>
      'تنخفض النيكوتين في الدم إلى الصفر';

  @override
  String get statsQuitMilestoneTaste48h =>
      'تتخلص الرئتان من المخاط ويتحسن التذوق والشم';

  @override
  String statsReviewAtRisk(String title) {
    return 'معرّض للخطر: $title';
  }

  @override
  String statsReviewBlocked(String title) {
    return 'محظور أو بانتظار: $title';
  }

  @override
  String statsReviewFollowUp(String title) {
    return 'متابعة متأخرة: $title';
  }

  @override
  String get statsReviewHeadline => 'أبرز الأرقام';

  @override
  String statsReviewHealth(String title) {
    return 'تم بلوغ محطة صحية: $title';
  }

  @override
  String get statsReviewLastWeek => 'الأسبوع الماضي';

  @override
  String statsReviewLoad(String planned, String capacity) {
    return '$planned مخطَّط من $capacity';
  }

  @override
  String get statsReviewNextWeek => 'الأسبوع القادم';

  @override
  String get statsReviewNothing => 'لا شيء هذا الأسبوع.';

  @override
  String statsReviewOverbooked(String date, String time) {
    return '$date مُثقل بمقدار $time';
  }

  @override
  String statsReviewOverdue(String title) {
    return 'متأخرة: $title';
  }

  @override
  String statsReviewPerfectDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم مثالي',
      many: '$count يومًا مثاليًا',
      few: '$count أيام مثالية',
      two: 'يومان مثاليان',
      one: 'يوم مثالي واحد',
      zero: 'لا أيام مثالية',
    );
    return '$_temp0';
  }

  @override
  String statsReviewRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String statsReviewRecord(String title) {
    return 'رقم قياسي جديد: $title';
  }

  @override
  String statsReviewStale(String title) {
    return 'لا نشاط حديث: $title';
  }

  @override
  String statsReviewStreak(String title, String count) {
    return '$title: سلسلة من $count يومًا';
  }

  @override
  String get statsReviewThisWeek => 'هذا الأسبوع حتى الآن';

  @override
  String get statsReviewTime => 'أين ذهب الوقت';

  @override
  String get statsScopeChecklist => 'إحصاءات القائمة';

  @override
  String get statsScopeChecklists => 'إحصاءات القوائم';

  @override
  String get statsScopeGlobal => 'نظرة عامة';

  @override
  String get statsScopeHabit => 'إحصاءات العادة';

  @override
  String get statsScopeHabits => 'إحصاءات العادات';

  @override
  String get statsScopeItem => 'إحصاءات العنصر';

  @override
  String get statsScopePlanner => 'إحصاءات الخطة';

  @override
  String get statsScopeQuit => 'إحصاءات الإقلاع';

  @override
  String get statsScopeReview => 'المراجعة الأسبوعية';

  @override
  String get statsScopeSeries => 'إحصاءات السلسلة';

  @override
  String get statsScopeTask => 'إحصاءات المهمة';

  @override
  String get statsScopeYear => 'حصاد العام';

  @override
  String get statsSectionAbstinence => 'الامتناع';

  @override
  String get statsSectionAdvanced => 'متقدم';

  @override
  String get statsSectionAllocation => 'توزيع الوقت';

  @override
  String get statsSectionCalendar => 'التقويم';

  @override
  String get statsSectionCapacity => 'السعة';

  @override
  String statsSectionCollapse(String section) {
    return 'طي $section';
  }

  @override
  String get statsSectionCravings => 'الرغبات الملحّة';

  @override
  String get statsSectionExecution => 'التنفيذ';

  @override
  String statsSectionExpand(String section) {
    return 'توسيع $section';
  }

  @override
  String get statsSectionFlow => 'التدفق';

  @override
  String get statsSectionFocus => 'التركيز والتوازن';

  @override
  String get statsSectionHabitTable => 'عاداتك';

  @override
  String get statsSectionHistory => 'السجل';

  @override
  String get statsSectionItem => 'هذا العنصر';

  @override
  String get statsSectionLists => 'القوائم';

  @override
  String get statsSectionMilestones => 'المحطات الصحية';

  @override
  String get statsSectionMoney => 'المال والوحدات';

  @override
  String get statsSectionOccurrence => 'هذه المرة';

  @override
  String get statsSectionOutcomes => 'النتائج';

  @override
  String get statsSectionPatterns => 'الأنماط';

  @override
  String get statsSectionPinned => 'المثبّتة';

  @override
  String get statsSectionPlanning => 'التخطيط';

  @override
  String get statsSectionPlanningQuality => 'جودة التخطيط';

  @override
  String get statsSectionQuality => 'الجودة';

  @override
  String get statsSectionQuitTrackers => 'متتبعات الإقلاع';

  @override
  String get statsSectionReduction => 'الخفض';

  @override
  String get statsSectionReview => 'المراجعة الأسبوعية';

  @override
  String get statsSectionSeries => 'التنفيذ';

  @override
  String get statsSectionShortcuts => 'الأقسام';

  @override
  String get statsSectionStale => 'العناصر الراكدة';

  @override
  String get statsSectionStatus => 'الحالة';

  @override
  String get statsSectionStreaks => 'السلاسل';

  @override
  String get statsSectionStrength => 'القوة';

  @override
  String get statsSectionTargetVolume => 'الهدف والحجم';

  @override
  String get statsSectionTiming => 'التوقيت والأنماط';

  @override
  String get statsSectionToday => 'اليوم';

  @override
  String get statsSectionTrend => 'الاتجاه';

  @override
  String get statsSectionWeek => 'الأسبوع في لمحة';

  @override
  String get statsSeeAll => 'عرض كل الإحصاءات';

  @override
  String get statsSeeSeries => 'عرض إحصاءات السلسلة';

  @override
  String get statsSegmentHabits => 'العادات';

  @override
  String get statsSegmentLists => 'القوائم';

  @override
  String get statsSegmentOverview => 'نظرة عامة';

  @override
  String get statsSegmentPlan => 'الخطة';

  @override
  String get statsSegmentQuit => 'الإقلاع';

  @override
  String get statsSourceAcs => 'الجمعية الأمريكية للسرطان';

  @override
  String get statsSourceBmj2000 => 'Shaw وآخرون، BMJ 2000';

  @override
  String get statsSourceCdc => 'CDC';

  @override
  String get statsSourceHse => 'HSE';

  @override
  String get statsSourceJackson2025 => 'Jackson وآخرون، Addiction 2025';

  @override
  String get statsSourceNci => 'المعهد الوطني للسرطان';

  @override
  String get statsSourceNhs => 'NHS';

  @override
  String get statsSourceWho => 'منظمة الصحة العالمية';

  @override
  String get statsUnknownScope => 'هذه الإحصائية غير موجودة.';

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

  @override
  String get tasksActionDuplicateSeries => 'تكرار كسلسلة جديدة';

  @override
  String get tasksActionDuplicateTo => 'تكرار إلى…';

  @override
  String get tasksActionExceptions => 'المواعيد المتخطاة والمنقولة';

  @override
  String get tasksActionMoveToToday => 'نقل إلى اليوم';

  @override
  String get tasksActionOpenSeries => 'فتح السلسلة';

  @override
  String get tasksActionPause => 'إيقاف السلسلة مؤقتًا';

  @override
  String get tasksActionPauseTimer => 'إيقاف مؤقت';

  @override
  String get tasksActionReopen => 'إعادة فتح';

  @override
  String get tasksActionReschedule => 'إعادة الجدولة…';

  @override
  String get tasksActionRestoreSeries => 'إعادة إلى السلسلة';

  @override
  String get tasksActionResume => 'استئناف السلسلة';

  @override
  String get tasksActionResumeTimer => 'استئناف';

  @override
  String get tasksActionSeriesHistory => 'سجل السلسلة';

  @override
  String get tasksActionShare => 'مشاركة كنص';

  @override
  String get tasksActionStart => 'ابدأ';

  @override
  String get tasksActionStop => 'إيقاف';

  @override
  String get tasksActionUnschedule => 'إرجاع إلى غير المجدولة';

  @override
  String get tasksActualAsPlanned => 'كما هو مخطط';

  @override
  String get tasksActualCustom => 'مخصص…';

  @override
  String get tasksActualEndBeforeStart => 'يجب أن تكون النهاية بعد البداية';

  @override
  String get tasksActualJustNow => 'الآن';

  @override
  String get tasksActualNotSet => 'غير مسجل';

  @override
  String get tasksActualTime => 'الوقت الفعلي';

  @override
  String get tasksActualTitle => 'متى أنجزتها؟';

  @override
  String get tasksAddEntry => 'إضافة جلسة';

  @override
  String tasksAnchorMoved(String date) {
    return 'نُقلت البداية إلى $date لتطابق قاعدة التكرار';
  }

  @override
  String get tasksAttachments => 'المرفقات';

  @override
  String get tasksAttachmentsPlaceholder => 'ستتوفر الصور والملفات هنا قريبًا';

  @override
  String get tasksBacklogLabel => 'غير مجدولة';

  @override
  String get tasksBulkDelete => 'حذف';

  @override
  String tasksBulkDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حُدّث $count عنصر',
      many: 'حُدّث $count عنصرًا',
      few: 'حُدّثت $count عناصر',
      two: 'حُدّث عنصران',
      one: 'حُدّث عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String get tasksBulkDuplicate => 'تكرار';

  @override
  String get tasksBulkEarlier15 => 'قبل 15 دقيقة';

  @override
  String get tasksBulkEarlierDay => 'قبل يوم';

  @override
  String get tasksBulkLater15 => 'بعد 15 دقيقة';

  @override
  String get tasksBulkLater1h => 'بعد ساعة';

  @override
  String get tasksBulkLaterDay => 'بعد يوم';

  @override
  String get tasksBulkLaterWeek => 'بعد أسبوع';

  @override
  String get tasksBulkMove => 'نقل';

  @override
  String get tasksBulkSetCategory => 'تعيين الفئة';

  @override
  String get tasksBulkSetPriority => 'تعيين الأولوية';

  @override
  String get tasksBulkSetTracking => 'تعيين نمط المتابعة';

  @override
  String get tasksBulkTarget => 'للعناصر المتكررة';

  @override
  String get tasksBulkTargetOccurrence => 'هذه المواعيد فقط';

  @override
  String get tasksBulkTargetSeries => 'السلسلة كاملة';

  @override
  String tasksBulkTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر محدد',
      many: '$count عنصرًا محددًا',
      few: '$count عناصر محددة',
      two: 'عنصران محددان',
      one: 'عنصر واحد محدد',
    );
    return '$_temp0';
  }

  @override
  String get tasksChecklistEmpty => 'لا توجد قوائم بعد';

  @override
  String get tasksChecklistNone => 'لا شيء';

  @override
  String get tasksChecklistOpen => 'فتح القائمة';

  @override
  String get tasksChecklistPick => 'ربط قائمة';

  @override
  String tasksChecklistProgress(int done, int total) {
    return 'أُنجز $done من $total';
  }

  @override
  String get tasksChecklistUnlink => 'إلغاء الربط';

  @override
  String get tasksColorCategoryDefault => 'لون الفئة';

  @override
  String get tasksCompletion => 'التقدم';

  @override
  String tasksCompletionValue(int percent) {
    return '$percent٪';
  }

  @override
  String get tasksCreated => 'تم إنشاء المهمة';

  @override
  String get tasksCustomDuration => 'مخصص…';

  @override
  String get tasksDeadlineNone => 'بلا موعد نهائي';

  @override
  String get tasksDeadlineWarning => 'مخطط لها بعد الموعد النهائي';

  @override
  String get tasksDeleteConfirmBody => 'تبقى في سلة المهملات 30 يومًا.';

  @override
  String get tasksDeleteConfirmTitle => 'حذف هذه المهمة؟';

  @override
  String get tasksDeleted => 'تم حذف المهمة';

  @override
  String get tasksDetailNotFound => 'هذه المهمة لم تعد موجودة';

  @override
  String get tasksDetailTitle => 'مهمة';

  @override
  String get tasksDiscard => 'تجاهل';

  @override
  String tasksDuplicateToConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تكرار إلى $count تاريخ',
      many: 'تكرار إلى $count تاريخًا',
      few: 'تكرار إلى $count تواريخ',
      two: 'تكرار إلى تاريخين',
      one: 'تكرار إلى تاريخ واحد',
      zero: 'اختر تواريخ',
    );
    return '$_temp0';
  }

  @override
  String get tasksDuplicateToTitle => 'تكرار إلى…';

  @override
  String get tasksDuplicated => 'تم تكرار المهمة';

  @override
  String tasksDuplicatedTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نُسخت إلى $count تاريخ',
      many: 'نُسخت إلى $count تاريخًا',
      few: 'نُسخت إلى $count تواريخ',
      two: 'نُسخت إلى تاريخين',
      one: 'نُسخت إلى تاريخ واحد',
    );
    return '$_temp0';
  }

  @override
  String get tasksDurationMode => 'المدة';

  @override
  String get tasksEditorEditOccurrenceTitle => 'تعديل الموعد';

  @override
  String get tasksEditorEditTitle => 'تعديل المهمة';

  @override
  String get tasksEditorNewTitle => 'مهمة جديدة';

  @override
  String get tasksEndMode => 'وقت الانتهاء';

  @override
  String get tasksEntryDelete => 'حذف الجلسة';

  @override
  String get tasksEntryEdit => 'تعديل الجلسة';

  @override
  String get tasksEntryFuture => 'لا يمكن أن تبدأ الجلسة في المستقبل';

  @override
  String get tasksEntryNegative => 'يجب أن تكون النهاية بعد البداية';

  @override
  String get tasksEntryOverlap => 'تتداخل مع جلسة أخرى';

  @override
  String get tasksEntryRunning => 'جارية';

  @override
  String get tasksErrAllDay => 'مهام اليوم الكامل تمتد لأيام كاملة';

  @override
  String get tasksErrDuration => 'يجب أن تكون المدة بين 0 دقيقة و365 يومًا';

  @override
  String get tasksErrEstimate => 'التقدير خارج النطاق';

  @override
  String get tasksErrPriority => 'أولوية غير صالحة';

  @override
  String get tasksErrRecurrenceInvalid => 'قاعدة التكرار غير صالحة';

  @override
  String get tasksErrRecurrenceNoDate => 'المهام المتكررة تحتاج إلى تاريخ';

  @override
  String get tasksErrTitleEmpty => 'أدخل عنوانًا';

  @override
  String get tasksErrTitleTooLong => 'العنوان طويل جدًا (300 حرف كحد أقصى)';

  @override
  String get tasksErrZone => 'منطقة زمنية غير معروفة';

  @override
  String get tasksEvtCompleted => 'أُنجزت';

  @override
  String get tasksEvtCreated => 'أُنشئت';

  @override
  String get tasksEvtDeleted => 'حُذفت';

  @override
  String get tasksEvtDeletedOccurrence => 'أُزيل الموعد';

  @override
  String tasksEvtOccurrence(String date) {
    return 'موعد $date';
  }

  @override
  String get tasksEvtPaused => 'أُوقفت السلسلة مؤقتًا';

  @override
  String get tasksEvtReopened => 'أُعيد فتحها';

  @override
  String tasksEvtRescheduled(String from, String to) {
    return 'أُعيدت جدولتها من $from إلى $to';
  }

  @override
  String get tasksEvtRestored => 'استُعيدت';

  @override
  String get tasksEvtResumed => 'استُؤنفت السلسلة';

  @override
  String get tasksEvtScheduled => 'جُدولت';

  @override
  String get tasksEvtSkipped => 'تم تخطيها';

  @override
  String tasksEvtSkippedReason(String reason) {
    return 'تم تخطيها: $reason';
  }

  @override
  String get tasksEvtSplit => 'قُسّمت السلسلة';

  @override
  String get tasksEvtStarted => 'بدأت';

  @override
  String get tasksEvtStatusChanged => 'تغيّرت الحالة';

  @override
  String get tasksEvtStopped => 'توقفت';

  @override
  String get tasksEvtTimeEntry => 'أُضيفت جلسة';

  @override
  String get tasksEvtUnscheduled => 'أُعيدت إلى قائمة غير المجدولة';

  @override
  String tasksEvtUpdated(String fields) {
    return 'عُدّلت: $fields';
  }

  @override
  String get tasksFieldAllDay => 'طوال اليوم';

  @override
  String get tasksFieldCategory => 'الفئة';

  @override
  String get tasksFieldChecklist => 'القائمة المرتبطة';

  @override
  String get tasksFieldColor => 'اللون';

  @override
  String get tasksFieldDate => 'التاريخ';

  @override
  String get tasksFieldDeadline => 'الموعد النهائي';

  @override
  String get tasksFieldDuration => 'المدة';

  @override
  String get tasksFieldEnd => 'النهاية';

  @override
  String get tasksFieldEndDate => 'تاريخ الانتهاء';

  @override
  String get tasksFieldEstimate => 'التقدير';

  @override
  String get tasksFieldIcon => 'الأيقونة';

  @override
  String get tasksFieldLocation => 'المكان';

  @override
  String get tasksFieldNoDate => 'بلا تاريخ (للجدولة لاحقًا)';

  @override
  String get tasksFieldNotes => 'ملاحظات';

  @override
  String get tasksFieldPriority => 'الأولوية';

  @override
  String get tasksFieldRepeat => 'التكرار';

  @override
  String get tasksFieldStart => 'البداية';

  @override
  String get tasksFieldStartDate => 'تاريخ البدء';

  @override
  String get tasksFieldTimeZone => 'المنطقة الزمنية';

  @override
  String get tasksFieldTitle => 'العنوان';

  @override
  String get tasksFieldTitleHint => 'ماذا تريد أن تفعل؟';

  @override
  String get tasksFieldTracking => 'المتابعة';

  @override
  String get tasksFieldUrl => 'الرابط';

  @override
  String get tasksFilterAll => 'الكل';

  @override
  String get tasksFilterDone => 'المنجزة';

  @override
  String get tasksFilterMissed => 'الفائتة';

  @override
  String get tasksFilterMoved => 'المنقولة';

  @override
  String get tasksFilterSkipped => 'المتخطاة';

  @override
  String get tasksFromTemplate => 'من قالب…';

  @override
  String get tasksHistory => 'السجل';

  @override
  String get tasksHistoryEmpty => 'لا يوجد سجل بعد';

  @override
  String get tasksHistoryLoadMore => 'تحميل المزيد';

  @override
  String get tasksIconDefault => 'أيقونة الفئة';

  @override
  String get tasksMarkedDone => 'تم التأشير كمنجزة';

  @override
  String get tasksMarkedSkipped => 'تم التخطي';

  @override
  String get tasksMdBold => 'عريض';

  @override
  String get tasksMdBullet => 'قائمة نقطية';

  @override
  String get tasksMdCheckbox => 'خانة تأشير';

  @override
  String get tasksMdCode => 'رمز';

  @override
  String get tasksMdHeading => 'عنوان';

  @override
  String get tasksMdItalic => 'مائل';

  @override
  String get tasksMdNumbered => 'قائمة مرقمة';

  @override
  String get tasksMoved => 'تم النقل';

  @override
  String tasksMovedFrom(String time) {
    return 'نُقلت من $time';
  }

  @override
  String get tasksNextDay => '+يوم واحد';

  @override
  String tasksNextLabel(String when) {
    return 'التالي: $when';
  }

  @override
  String get tasksNextMonth => 'الشهر التالي';

  @override
  String get tasksNextOccurrences => 'المواعيد القادمة';

  @override
  String get tasksNoUpcoming => 'لا شيء قادم';

  @override
  String get tasksNotesEdit => 'تعديل';

  @override
  String get tasksNotesHint => 'أضف ملاحظات (عريض، قوائم، خانات…)';

  @override
  String get tasksNotesPreview => 'معاينة';

  @override
  String get tasksOccurrenceDeleted => 'تمت إزالة الموعد';

  @override
  String tasksOpenLinkBody(String url) {
    return 'سيُفتح $url خارج Everslot.';
  }

  @override
  String get tasksOpenLinkTitle => 'فتح الرابط؟';

  @override
  String get tasksOrphansBody =>
      'المواعيد التي لها سجل تُحفظ دائمًا كمهام منفردة.';

  @override
  String tasksOrphansCompleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موعد منجز',
      many: '$count موعدًا منجزًا',
      few: '$count مواعيد منجزة',
      two: 'موعدان منجزان',
      one: 'موعد واحد منجز',
    );
    return '$_temp0';
  }

  @override
  String get tasksOrphansDiscard => 'حذف المنقولة';

  @override
  String get tasksOrphansKeep => 'الاحتفاظ بها كمهام منفردة';

  @override
  String tasksOrphansMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موعد منقول',
      many: '$count موعدًا منقولًا',
      few: '$count مواعيد منقولة',
      two: 'موعدان منقولان',
      one: 'موعد واحد منقول',
    );
    return '$_temp0';
  }

  @override
  String tasksOrphansOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موعد بملاحظات أو وقت متتبع',
      many: '$count موعدًا بملاحظات أو وقت متتبع',
      few: '$count مواعيد بملاحظات أو وقت متتبع',
      two: 'موعدان بملاحظات أو وقت متتبع',
      one: 'موعد واحد بملاحظات أو وقت متتبع',
    );
    return '$_temp0';
  }

  @override
  String tasksOrphansSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موعد متخطى',
      many: '$count موعدًا متخطى',
      few: '$count مواعيد متخطاة',
      two: 'موعدان متخطيان',
      one: 'موعد واحد متخطى',
    );
    return '$_temp0';
  }

  @override
  String get tasksOrphansTitle => 'بعض المواعيد لم تعد مطابقة';

  @override
  String get tasksOutcomeNote => 'ملاحظة النتيجة';

  @override
  String get tasksOutcomeNoteHint => 'كيف جرى الأمر؟';

  @override
  String get tasksOverdue => 'متأخرة';

  @override
  String tasksOverlapHint(String title, String range) {
    return 'يتداخل مع $title $range';
  }

  @override
  String tasksOverlapMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'و$count عنصر آخر',
      many: 'و$count عنصرًا آخر',
      few: 'و$count عناصر أخرى',
      two: 'وعنصران آخران',
      one: 'وعنصر آخر',
    );
    return '$_temp0';
  }

  @override
  String get tasksPauseSnack => 'أُوقفت السلسلة مؤقتًا';

  @override
  String get tasksPausedBadge => 'متوقفة مؤقتًا';

  @override
  String tasksPlannedVsActual(String planned, String actual) {
    return 'المخطط $planned · الفعلي $actual';
  }

  @override
  String tasksPlusDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count يوم',
      many: '+$count يومًا',
      few: '+$count أيام',
      two: '+يومان',
      one: '+يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get tasksPostpone15 => '+15 دقيقة';

  @override
  String get tasksPostpone1h => '+ساعة';

  @override
  String get tasksPostponeEvening => 'هذا المساء';

  @override
  String get tasksPostponeNextWeek => 'الأسبوع القادم في نفس الوقت';

  @override
  String get tasksPostponePick => 'اختر تاريخًا ووقتًا…';

  @override
  String get tasksPostponeTitle => 'إعادة الجدولة';

  @override
  String get tasksPostponeTomorrow => 'غدًا في نفس الوقت';

  @override
  String get tasksPrevMonth => 'الشهر السابق';

  @override
  String get tasksQuickAdd => 'إضافة';

  @override
  String get tasksQuickAddNew => 'إضافة وأخرى';

  @override
  String get tasksQuickMore => 'خيارات أكثر';

  @override
  String get tasksQuickTitleHint => 'مهمة جديدة';

  @override
  String get tasksQuotaDone => 'اكتمل لهذه الفترة';

  @override
  String tasksQuotaProgress(int done, int total) {
    return '$done/$total في هذه الفترة';
  }

  @override
  String get tasksRating => 'التقييم';

  @override
  String tasksRatingValue(int value) {
    return '$value من 5';
  }

  @override
  String get tasksReminders => 'التذكيرات';

  @override
  String get tasksRemindersDefault => 'افتراضي';

  @override
  String get tasksReopened => 'أُعيد فتحها';

  @override
  String get tasksRepeatNone => 'لا يتكرر';

  @override
  String get tasksRestored => 'تمت استعادة المهمة';

  @override
  String get tasksResumeSnack => 'استُؤنفت السلسلة';

  @override
  String tasksRolledOver(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نُقلت $count مهمة غير منجزة إلى اليوم',
      many: 'نُقلت $count مهمة غير منجزة إلى اليوم',
      few: 'نُقلت $count مهام غير منجزة إلى اليوم',
      two: 'نُقلت مهمتان غير منجزتين إلى اليوم',
      one: 'نُقلت مهمة غير منجزة إلى اليوم',
    );
    return '$_temp0';
  }

  @override
  String tasksRunningTimer(String title, String elapsed) {
    return 'مؤقت يعمل: $title، $elapsed';
  }

  @override
  String get tasksSaveAsTemplate => 'حفظ كقالب';

  @override
  String get tasksSaved => 'تم حفظ المهمة';

  @override
  String get tasksScopeAll => 'كل المواعيد';

  @override
  String get tasksScopeDeleteTitle => 'حذف مهمة متكررة';

  @override
  String get tasksScopeFollowing => 'هذا الموعد وما بعده';

  @override
  String get tasksScopePastKept => 'تحتفظ المواعيد الماضية بأوقاتها الأصلية.';

  @override
  String get tasksScopeRewritePast => 'إعادة كتابة المواعيد الماضية أيضًا';

  @override
  String get tasksScopeThis => 'هذا الموعد';

  @override
  String get tasksScopeThisDisabled =>
      'لموعد واحد يمكن تغيير الوقت والمدة والعنوان والملاحظات فقط.';

  @override
  String get tasksScopeTitle => 'تطبيق التغييرات على';

  @override
  String get tasksSeriesEmpty => 'لا مواعيد في هذه الفترة';

  @override
  String get tasksSeriesHistoryTitle => 'سجل السلسلة';

  @override
  String get tasksSeriesStats => 'إحصاءات السلسلة';

  @override
  String tasksShareRepeats(String rule) {
    return 'التكرار: $rule';
  }

  @override
  String get tasksSkipCustomHint => 'سبب آخر (اختياري)';

  @override
  String get tasksSkipForgot => 'نسيت';

  @override
  String get tasksSkipNotNeeded => 'غير ضرورية';

  @override
  String get tasksSkipOther => 'سبب آخر';

  @override
  String get tasksSkipSick => 'مريض';

  @override
  String get tasksSkipTitle => 'لماذا تتخطاها؟';

  @override
  String get tasksSkipTooBusy => 'مشغول جدًا';

  @override
  String get tasksStatusCancelled => 'ملغاة';

  @override
  String get tasksStatusDone => 'منجزة';

  @override
  String get tasksStatusInProgress => 'قيد التنفيذ';

  @override
  String get tasksStatusMissed => 'فائتة';

  @override
  String get tasksStatusScheduled => 'مجدولة';

  @override
  String get tasksStatusSkipped => 'متخطاة';

  @override
  String get tasksTemplateDelete => 'حذف القالب';

  @override
  String get tasksTemplateSaved => 'تم حفظ القالب';

  @override
  String get tasksTemplatesEmpty =>
      'لا توجد قوالب. احفظ مهمة كقالب من قائمتها.';

  @override
  String get tasksTemplatesTitle => 'القوالب';

  @override
  String get tasksTimeEntries => 'الجلسات';

  @override
  String get tasksTimeTracking => 'تتبع الوقت';

  @override
  String get tasksTooManyOccurrences => 'مواعيد كثيرة جدًا للعرض — كبّر العرض';

  @override
  String tasksTracked(String duration) {
    return 'الوقت المتتبع: $duration';
  }

  @override
  String get tasksTrackingCheck => 'تأشير';

  @override
  String get tasksTrackingCheckHint => 'أشّر عليها أو تخطّها؛ قد تفوتك.';

  @override
  String get tasksTrackingEvent => 'حدث';

  @override
  String get tasksTrackingEventHint =>
      'فترة زمنية (اجتماع، وجبة): بلا خانة تأشير ولا تفوت أبدًا.';

  @override
  String get tasksTrackingTimer => 'مؤقت';

  @override
  String get tasksTrackingTimerHint =>
      'تتبّع الوقت الذي تقضيه؛ تكتمل عند إيقاف المؤقت.';

  @override
  String get tasksUnsavedBody => 'ستضيع تغييراتك.';

  @override
  String get tasksUnsavedTitle => 'تجاهل التغييرات؟';

  @override
  String get tasksUntitled => 'مهمة بلا عنوان';

  @override
  String get tasksUpdated => 'تم التحديث';

  @override
  String get tasksUrlInvalid => 'أدخل عنوان ويب صالحًا';

  @override
  String tasksZoneBadge(String zone) {
    return 'توقيت $zone';
  }

  @override
  String get tasksZoneFixed => 'ثابتة';

  @override
  String get tasksZoneFixedHint => 'مرتبطة بمنطقة زمنية واحدة';

  @override
  String get tasksZoneFloating => 'عائمة';

  @override
  String get tasksZoneFloatingHint => 'نفس الساعة أينما كنت';

  @override
  String get tasksZonePickTitle => 'اختر منطقة زمنية';

  @override
  String get tasksZoneSearch => 'ابحث عن منطقة زمنية';
}
