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
  String get attachmentsChecklistLevel => 'على القائمة';

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
  String get attachmentsFilterAll => 'الكل';

  @override
  String get attachmentsFilterImages => 'الصور';

  @override
  String get attachmentsFilterOther => 'أخرى';

  @override
  String get attachmentsFilterPdfs => 'ملفات PDF';

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
  String get checklistAddItem => 'إضافة عنصر';

  @override
  String get checklistAddSubItem => 'إضافة عنصر فرعي';

  @override
  String get checklistAllAttachments => 'كل المرفقات';

  @override
  String get checklistAllLists => 'كل القوائم';

  @override
  String get checklistAttach => 'إرفاق';

  @override
  String checklistBelowBadges(int blocked, int waiting) {
    return '$blocked محظور · $waiting قيد الانتظار أدناه';
  }

  @override
  String get checklistBodyHint => 'ملاحظة';

  @override
  String checklistCarrying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نقل $count عنصر',
      many: 'نقل $count عنصرًا',
      few: 'نقل $count عناصر',
      two: 'نقل عنصرين',
      one: 'نقل عنصر واحد',
      zero: 'لا شيء',
    );
    return '$_temp0';
  }

  @override
  String get checklistCollapse => 'طي';

  @override
  String get checklistCollapseAll => 'طي الكل';

  @override
  String get checklistCollapsedState => 'مطوي';

  @override
  String get checklistCompleted => 'اكتملت القائمة!';

  @override
  String get checklistCompletedArchive => 'أرشفة';

  @override
  String get checklistCompletedKeep => 'الإبقاء';

  @override
  String get checklistCompletedReset => 'إعادة تعيين';

  @override
  String get checklistCopied => 'تم النسخ';

  @override
  String get checklistCopy => 'نسخ';

  @override
  String get checklistCopyText => 'نسخ كنص';

  @override
  String get checklistCut => 'قص';

  @override
  String get checklistDelete => 'حذف القائمة';

  @override
  String get checklistDeleteCompleted => 'حذف العناصر المكتملة';

  @override
  String get checklistDeleteItem => 'حذف';

  @override
  String checklistDepthBadge(int level) {
    return 'م$level';
  }

  @override
  String get checklistDetails => 'التفاصيل';

  @override
  String get checklistDragHandle => 'اسحب للنقل';

  @override
  String get checklistDue => 'تاريخ الاستحقاق';

  @override
  String get checklistDuplicate => 'تكرار القائمة';

  @override
  String get checklistDuplicateItem => 'تكرار';

  @override
  String get checklistEmptyFocus => 'لا توجد عناصر فرعية بعد';

  @override
  String get checklistExpand => 'توسيع';

  @override
  String get checklistExpandAll => 'توسيع الكل';

  @override
  String checklistExpandToLevel(int level) {
    return 'التوسيع حتى المستوى $level';
  }

  @override
  String get checklistExpandToLevelMenu => 'التوسيع حتى المستوى…';

  @override
  String get checklistFilterAll => 'الكل';

  @override
  String get checklistFilterDueSoon => 'يستحق قريبًا';

  @override
  String get checklistFilterHasAttachments => 'بها مرفقات';

  @override
  String get checklistFilterOpen => 'المفتوحة';

  @override
  String get checklistFilterText => 'البحث في القائمة';

  @override
  String get checklistFiltered => 'عرض مُصفّى';

  @override
  String get checklistFocus => 'تركيز';

  @override
  String get checklistHasReminders => 'توجد تذكيرات';

  @override
  String get checklistHideCheckboxes => 'إخفاء مربعات الاختيار';

  @override
  String get checklistHideCompleted => 'إخفاء المكتملة';

  @override
  String get checklistHideKeyboard => 'إخفاء لوحة المفاتيح';

  @override
  String get checklistImport => 'استيراد عناصر…';

  @override
  String get checklistInTrash => 'هذه القائمة في المهملات';

  @override
  String get checklistIndent => 'زيادة المسافة البادئة';

  @override
  String get checklistInsights => 'الإحصاءات';

  @override
  String get checklistItemHint => 'عنصر';

  @override
  String checklistItemsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حُذف $count عنصر',
      many: 'حُذف $count عنصرًا',
      few: 'حُذفت $count عناصر',
      two: 'حُذف عنصران',
      one: 'حُذف عنصر واحد',
      zero: 'لم يُحذف شيء',
    );
    return '$_temp0';
  }

  @override
  String checklistItemsDuplicated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تكرار $count عنصر',
      many: 'تم تكرار $count عنصرًا',
      few: 'تم تكرار $count عناصر',
      two: 'تم تكرار عنصرين',
      one: 'تم تكرار عنصر واحد',
      zero: 'لم يُكرَّر أي عنصر',
    );
    return '$_temp0';
  }

  @override
  String get checklistItemsMoved => 'تم النقل';

  @override
  String get checklistLabelName => 'اسم التسمية';

  @override
  String get checklistLabels => 'التسميات';

  @override
  String get checklistLineBreak => 'سطر جديد';

  @override
  String get checklistLinkedTask => 'مهمة مرتبطة';

  @override
  String get checklistModeEdit => 'تحرير';

  @override
  String get checklistModePreview => 'معاينة';

  @override
  String get checklistMoveConflict =>
      'تعارض نقلٌ مع تغيير على جهاز آخر فتم التراجع عنه.';

  @override
  String get checklistMoveDown => 'نقل لأسفل';

  @override
  String get checklistMoveTo => 'نقل إلى…';

  @override
  String get checklistMoveUp => 'نقل لأعلى';

  @override
  String get checklistNewLabel => 'تسمية جديدة';

  @override
  String get checklistNextOpen => 'العنصر المفتوح التالي';

  @override
  String get checklistNoItems => 'لا توجد عناصر بعد';

  @override
  String get checklistNoLabels => 'لا توجد تسميات بعد';

  @override
  String get checklistNotFound => 'هذه القائمة غير موجودة';

  @override
  String get checklistOpenTrash => 'فتح المهملات';

  @override
  String get checklistOutdent => 'إنقاص المسافة البادئة';

  @override
  String get checklistPaste => 'لصق';

  @override
  String get checklistPasteHere => 'لصق هنا';

  @override
  String get checklistPendingUploads => 'عمليات رفع معلقة';

  @override
  String checklistProgress(int done, int total) {
    return '$done من $total مكتمل';
  }

  @override
  String get checklistPromote => 'تحويل إلى قائمة';

  @override
  String get checklistPromoted => 'تم إنشاء قائمة جديدة';

  @override
  String get checklistRecovered => 'مُستعاد';

  @override
  String get checklistRepeat => 'التكرار…';

  @override
  String get checklistResetConfirm =>
      'ستعود كل العناصر إلى «للإنجاز» وتُمسح ملاحظات الأسباب.';

  @override
  String get checklistResetDone => 'تمت إعادة تعيين القائمة';

  @override
  String get checklistResetNow => 'إعادة التعيين الآن';

  @override
  String get checklistResetStatuses => 'إعادة تعيين كل الحالات';

  @override
  String get checklistResetView => 'إعادة الضبط';

  @override
  String checklistRowSemantics(String text, int level, int index, int count) {
    return '$text، المستوى $level، العنصر $index من $count';
  }

  @override
  String get checklistSaveAsTemplate => 'حفظ كقالب';

  @override
  String get checklistScheduleTask => 'جدولة كمهمة';

  @override
  String get checklistSelect => 'تحديد';

  @override
  String get checklistSelectAll => 'تحديد الكل';

  @override
  String get checklistSelectSubtree => 'تحديد العناصر الفرعية';

  @override
  String checklistSelected(int count) {
    return '$count محدد';
  }

  @override
  String get checklistSettings => 'إعدادات القائمة';

  @override
  String get checklistShare => 'مشاركة / تصدير';

  @override
  String get checklistShowCheckboxes => 'إظهار مربعات الاختيار';

  @override
  String get checklistSortAlpha => 'أبجدي';

  @override
  String get checklistSortChildren => 'ترتيب العناصر الفرعية';

  @override
  String get checklistSortCompletedBottom => 'نقل المكتملة إلى الأسفل';

  @override
  String get checklistSortDescending => 'تنازلي';

  @override
  String get checklistSortDue => 'تاريخ الاستحقاق';

  @override
  String get checklistSortFilter => 'الترتيب والتصفية';

  @override
  String get checklistSortManual => 'يدوي';

  @override
  String get checklistSortPriority => 'الأولوية';

  @override
  String get checklistSortRecent => 'المعدلة مؤخرًا';

  @override
  String get checklistSortStatus => 'الحالة';

  @override
  String checklistSortedBy(String criterion) {
    return 'مرتبة حسب $criterion';
  }

  @override
  String get checklistStatusChanged => 'تم تغيير الحالة';

  @override
  String checklistSubItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر فرعي',
      many: '$count عنصرًا فرعيًا',
      few: '$count عناصر فرعية',
      two: 'عنصران فرعيان',
      one: 'عنصر فرعي واحد',
      zero: 'لا عناصر فرعية',
    );
    return '$_temp0';
  }

  @override
  String get checklistTaskPlaceholder => 'سيتوفر الربط بالمهام مع المخطط.';

  @override
  String get checklistTemplateSaved => 'تم الحفظ كقالب';

  @override
  String get checklistTitleHint => 'العنوان';

  @override
  String get checklistUncheckAll => 'إلغاء تحديد الكل';

  @override
  String checklistUncheckConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إلغاء تحديد $count عنصر؟',
      many: 'إلغاء تحديد $count عنصرًا؟',
      few: 'إلغاء تحديد $count عناصر؟',
      two: 'إلغاء تحديد عنصرين؟',
      one: 'إلغاء تحديد عنصر واحد؟',
      zero: 'لا عناصر',
    );
    return '$_temp0';
  }

  @override
  String get checklistViewGallery => 'معرض';

  @override
  String get checklistViewKanban => 'كانبان';

  @override
  String get checklistViewOutline => 'مخطط';

  @override
  String get checklistZoomOut => 'تصغير';

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
  String get exportBranchOnly => 'هذا الفرع فقط';

  @override
  String get exportCopied => 'تم النسخ إلى الحافظة';

  @override
  String get exportCopy => 'نسخ إلى الحافظة';

  @override
  String get exportMarkdown => 'Markdown';

  @override
  String get exportOpml => 'OPML';

  @override
  String get exportPlain => 'نص عادي';

  @override
  String get exportShare => 'مشاركة…';

  @override
  String get exportTitle => 'مشاركة / تصدير';

  @override
  String get galleryEmpty => 'لا توجد عناصر بصور';

  @override
  String get galleryOnlyImages => 'العناصر ذات الصور فقط';

  @override
  String get importAction => 'استيراد';

  @override
  String get importChooseFile => 'اختيار ملف';

  @override
  String get importConvertBody => 'تحويل الملاحظة إلى عناصر';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استُورد $count عنصر',
      many: 'استُورد $count عنصرًا',
      few: 'استُوردت $count عناصر',
      two: 'استُورد عنصران',
      one: 'استُورد عنصر واحد',
      zero: 'لم يُستورد شيء',
    );
    return '$_temp0';
  }

  @override
  String importItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصرًا',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا عناصر',
    );
    return '$_temp0';
  }

  @override
  String get importKeepOne => 'الإبقاء كعنصر واحد';

  @override
  String get importPasteHint => 'الصق نصًا بمسافات بادئة أو Markdown أو OPML';

  @override
  String get importSplit => 'التقسيم إلى عناصر (مع الحفاظ على التفرع)';

  @override
  String get importTitle => 'استيراد';

  @override
  String get importWarningAttachments => 'تم تجاهل مراجع المرفقات';

  @override
  String get importWarningEmpty => 'لا شيء للاستيراد';

  @override
  String get importWarningMalformed => 'تعذرت قراءة هذا الملف';

  @override
  String get importWarningTooMany => 'تم استيراد أول 10000 سطر فقط';

  @override
  String get itemAddTime => 'إضافة وقت';

  @override
  String get itemAttachments => 'المرفقات';

  @override
  String get itemClearDue => 'إزالة تاريخ الاستحقاق';

  @override
  String itemCompletedOn(String date) {
    return 'اكتمل $date';
  }

  @override
  String itemCreated(String date) {
    return 'أُنشئ $date';
  }

  @override
  String get itemDetailsTitle => 'تفاصيل العنصر';

  @override
  String get itemDue => 'الاستحقاق';

  @override
  String get itemDueOverdue => 'متأخر';

  @override
  String get itemDueToday => 'اليوم';

  @override
  String get itemDueTomorrow => 'غدًا';

  @override
  String itemEdited(String date) {
    return 'عُدّل $date';
  }

  @override
  String get itemHistory => 'السجل';

  @override
  String get itemHistoryCause => 'تلقائي';

  @override
  String itemHistoryDevice(String device) {
    return 'على $device';
  }

  @override
  String get itemHistoryEmpty => 'لا توجد تغييرات في الحالة بعد';

  @override
  String itemHistoryTransition(String from, String to) {
    return '$from ← $to';
  }

  @override
  String get itemInsights => 'الإحصاءات';

  @override
  String get itemNoDue => 'بدون تاريخ استحقاق';

  @override
  String get itemNote => 'ملاحظة';

  @override
  String get itemOtherDevice => 'جهاز آخر';

  @override
  String get itemPriority => 'الأولوية';

  @override
  String get itemText => 'النص';

  @override
  String get itemThisDevice => 'هذا الجهاز';

  @override
  String get itemTimeInStatus => 'الوقت في كل حالة';

  @override
  String get kanbanAll => 'كل العناصر';

  @override
  String get kanbanChildren => 'العناصر الفرعية المباشرة';

  @override
  String get kanbanEmptyColumn => 'أفلت العناصر هنا';

  @override
  String get kanbanLeaves => 'العناصر النهائية فقط';

  @override
  String get kanbanScope => 'عرض';

  @override
  String get kanbanShowCancelled => 'إظهار الملغاة';

  @override
  String get listsArchive => 'الأرشيف';

  @override
  String get listsArchiveAction => 'أرشفة';

  @override
  String get listsArchiveEmpty => 'لا توجد قوائم مؤرشفة';

  @override
  String get listsArchived => 'تمت أرشفة القائمة';

  @override
  String listsBadgeBlocked(int count) {
    return '$count محظور';
  }

  @override
  String listsBadgeStale(int count) {
    return '$count راكد';
  }

  @override
  String listsBadgeWaiting(int count) {
    return '$count قيد الانتظار';
  }

  @override
  String get listsBoardSort => 'ترتيب البطاقات';

  @override
  String get listsBoardSortManual => 'يدوي';

  @override
  String get listsBoardSortRecent => 'المعدلة مؤخرًا';

  @override
  String get listsBoardSortTitle => 'العنوان';

  @override
  String get listsCardActions => 'إجراءات القائمة';

  @override
  String listsCardMore(int count) {
    return '+$count أخرى';
  }

  @override
  String listsCardProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String listsCardSemantics(String title, String progress) {
    return '$title، $progress';
  }

  @override
  String get listsColor => 'اللون';

  @override
  String listsCopyOf(String title) {
    return 'نسخة من $title';
  }

  @override
  String get listsDelete => 'حذف';

  @override
  String get listsDeleted => 'تم حذف القائمة';

  @override
  String get listsDragHint => 'اضغط مطولًا واسحب لإعادة الترتيب';

  @override
  String get listsDuplicate => 'تكرار';

  @override
  String get listsDuplicated => 'تم تكرار القائمة';

  @override
  String get listsEmptyAction => 'أنشئ قائمتك الأولى';

  @override
  String get listsEmptyMessage =>
      'قوائم وملاحظات وروتين — بتفرّع بالعمق الذي تحتاجه.';

  @override
  String get listsEmptyTitle => 'لا توجد قوائم بعد';

  @override
  String get listsFilterColor => 'اللون';

  @override
  String get listsFilterHasAttachments => 'بها مرفقات';

  @override
  String get listsFilterHasBlocked => 'قيد الانتظار أو محظور';

  @override
  String get listsFilterPinned => 'مثبتة';

  @override
  String get listsFilterRepeating => 'متكررة';

  @override
  String get listsFromTemplate => 'من قالب';

  @override
  String get listsGridView => 'عرض شبكي';

  @override
  String get listsImportFile => 'استيراد ملف…';

  @override
  String get listsListView => 'عرض قائمة';

  @override
  String get listsMoveItems => 'نقل العناصر…';

  @override
  String get listsNewChecklist => 'قائمة جديدة';

  @override
  String get listsNewNote => 'ملاحظة جديدة';

  @override
  String get listsOthers => 'أخرى';

  @override
  String get listsPin => 'تثبيت';

  @override
  String get listsPinned => 'المثبتة';

  @override
  String get listsPreferences => 'إعدادات القوائم';

  @override
  String get listsRepeats => 'تتكرر';

  @override
  String get listsResetStatusesOption => 'إعادة كل الحالات إلى «للإنجاز»';

  @override
  String get listsSearchHint => 'البحث في القوائم';

  @override
  String get listsSearchItems => 'العناصر';

  @override
  String get listsSearchNoResults => 'لا توجد قوائم أو عناصر مطابقة';

  @override
  String get listsShowBody => 'إظهار نص الملاحظة على البطاقات';

  @override
  String get listsShowSmartChips => 'إظهار شارات قيد الانتظار / محظور';

  @override
  String get listsTemplates => 'القوالب';

  @override
  String get listsTrash => 'المهملات';

  @override
  String get listsUnarchive => 'إلغاء الأرشفة';

  @override
  String get listsUnarchived => 'تمت استعادة القائمة من الأرشيف';

  @override
  String get listsUnpin => 'إلغاء التثبيت';

  @override
  String get listsUntitled => 'بلا عنوان';

  @override
  String get localOnlyBanner =>
      'مزامنة السحابة غير مُعدّة — بياناتك تبقى على هذا الجهاز.';

  @override
  String get moveChooseParent => 'اختر المكان';

  @override
  String moveDone(String title) {
    return 'نُقل إلى $title';
  }

  @override
  String get moveToList => 'نقل إلى قائمة';

  @override
  String get moveToTop => 'المستوى الأعلى';

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
  String get notifModeOffHint => 'لا إشعارات لهذا العنصر';

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
  String notifSectionOffHint(String section) {
    return 'إشعارات «$section» متوقفة في الإعدادات';
  }

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
  String get pvActualColumn => 'الفعلي';

  @override
  String get pvAddTask => 'إضافة مهمة';

  @override
  String get pvAddZone => 'إضافة منطقة زمنية';

  @override
  String get pvAllDay => 'طوال اليوم';

  @override
  String get pvAllDaySection => 'طوال اليوم وبلا وقت';

  @override
  String get pvApplyToView => 'تطبيق على هذا العرض';

  @override
  String get pvAutoAdvance => 'الانتقال التلقائي';

  @override
  String get pvAutoScrollNow => 'الانتقال إلى الوقت الحالي عند الفتح';

  @override
  String get pvBacklogEmpty => 'لا توجد مهام غير مجدولة';

  @override
  String get pvCancelOccurrence => 'إلغاء هذا الموعد';

  @override
  String get pvCannotUnschedule =>
      'لا يمكن إعادة المواعيد المتكررة إلى المهام غير المجدولة';

  @override
  String get pvCapacity => 'السعة';

  @override
  String get pvCategories => 'الفئات';

  @override
  String get pvClearFilters => 'مسح';

  @override
  String get pvClocksForward => 'تقديم الساعة';

  @override
  String get pvColCategory => 'الفئة';

  @override
  String get pvColDate => 'التاريخ';

  @override
  String get pvColDuration => 'المدة';

  @override
  String get pvColEnd => 'النهاية';

  @override
  String get pvColLocation => 'المكان';

  @override
  String get pvColPriority => 'الأولوية';

  @override
  String get pvColRecurrence => 'التكرار';

  @override
  String get pvColStart => 'البداية';

  @override
  String get pvColStatus => 'الحالة';

  @override
  String get pvColTitle => 'العنوان';

  @override
  String get pvColTracking => 'التتبع';

  @override
  String get pvCollapse => 'طي';

  @override
  String get pvColorBy => 'التلوين حسب';

  @override
  String get pvColorByCategory => 'الفئة';

  @override
  String get pvColorByPriority => 'الأولوية';

  @override
  String get pvColorByStatus => 'الحالة';

  @override
  String get pvColorByTask => 'المهمة';

  @override
  String get pvColumns => 'الأعمدة';

  @override
  String get pvCompletion => 'نسبة الإنجاز';

  @override
  String get pvContinues => 'مستمرة';

  @override
  String pvCopySuffix(String name) {
    return '$name (نسخة)';
  }

  @override
  String get pvCreate => 'إنشاء';

  @override
  String get pvCreateHere => 'إنشاء هنا';

  @override
  String get pvCreatedSnack => 'أُنشئت المهمة';

  @override
  String pvDayHeaderSemantics(String day, String items) {
    return '$day، $items';
  }

  @override
  String get pvDayRibbon => 'اليوم';

  @override
  String pvDayStats(String done, String total, String planned) {
    return '$done/$total · $planned';
  }

  @override
  String get pvDaySummary => 'ملخص اليوم';

  @override
  String get pvDayTicker => 'شريط الأيام';

  @override
  String pvDaysSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم واحد',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String pvDaysUntil(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بعد $count يوم',
      many: 'بعد $count يومًا',
      few: 'بعد $count أيام',
      two: 'بعد يومين',
      one: 'بعد يوم واحد',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String get pvDaysVisible => 'الأيام الظاهرة';

  @override
  String get pvDaysVisibleLandscape => 'الأيام في الوضع الأفقي';

  @override
  String get pvDefaultBadge => 'افتراضي';

  @override
  String get pvDeleteView => 'حذف العرض';

  @override
  String get pvDemoData => 'بيانات تجريبية (للمطوّرين)';

  @override
  String get pvDensity => 'الكثافة';

  @override
  String get pvDensityComfortable => 'مريحة';

  @override
  String get pvDensityCompact => 'مضغوطة';

  @override
  String get pvDimPast => 'تعتيم ما مضى';

  @override
  String get pvDoneTotal => 'المنجز';

  @override
  String get pvDragToSchedule => 'اسحب إلى الشبكة للجدولة';

  @override
  String get pvDropNotSupported => 'لا يمكن تغيير هذا التجميع بالسحب بعد';

  @override
  String get pvDuplicateView => 'تكرار العرض';

  @override
  String pvElapsed(String duration) {
    return 'المنقضي: $duration';
  }

  @override
  String get pvEmptyDay => 'لا شيء مخطط';

  @override
  String get pvEmptyRange => 'لا شيء في هذه الفترة';

  @override
  String pvEmptySlotSemantics(String day, String time) {
    return '$day $time، فارغة، انقر مرتين للإنشاء';
  }

  @override
  String get pvEmptyWeekTitle => 'لا شيء مخطط هذا الأسبوع';

  @override
  String get pvExpand => 'توسيع';

  @override
  String get pvExpandInline => 'توسيع اليوم في مكانه';

  @override
  String get pvExtend => 'تمديد';

  @override
  String pvExtendBy(int minutes) {
    return '+$minutes د';
  }

  @override
  String get pvExtraZones => 'مناطق زمنية إضافية';

  @override
  String get pvFillFromBacklog => 'ملء بمهمة غير مجدولة';

  @override
  String get pvFillGap => 'ملء هذه الفجوة';

  @override
  String get pvFilter => 'تصفية';

  @override
  String get pvFilters => 'عوامل التصفية';

  @override
  String get pvFinish => 'إنهاء';

  @override
  String pvFreeGap(String duration) {
    return 'متاح $duration';
  }

  @override
  String get pvFreeInWorkHours => 'الوقت الحر في ساعات العمل';

  @override
  String pvFreeRun(String from, String to, String duration) {
    return 'متاح $from–$to · $duration';
  }

  @override
  String get pvFrom => 'من';

  @override
  String get pvGotIt => 'فهمت';

  @override
  String get pvGroupBy => 'التجميع حسب';

  @override
  String get pvGroupCategory => 'الفئة';

  @override
  String get pvGroupDay => 'اليوم';

  @override
  String get pvGroupNone => 'بلا تجميع';

  @override
  String get pvGroupPriority => 'الأولوية';

  @override
  String get pvGroupStatus => 'الحالة';

  @override
  String get pvGroupTask => 'المهمة';

  @override
  String get pvHeatMetric => 'المقياس';

  @override
  String pvHiddenRange(String from, String to) {
    return 'مخفي $from–$to';
  }

  @override
  String get pvHideEmptySlots => 'طي الفترات الفارغة';

  @override
  String get pvHintLongPress => 'اضغط مطولًا على مساحة فارغة لإنشاء مهمة';

  @override
  String get pvHintPinch =>
      'باعد أو قارب إصبعيك للتكبير، وأفقيًا لتغيير عدد الأيام';

  @override
  String pvHintSlotSize(String size) {
    return 'انقر $size لتغيير حجم الصف';
  }

  @override
  String get pvHorizonDay => 'اليوم';

  @override
  String get pvHorizonMonth => 'هذا الشهر';

  @override
  String get pvHorizonQuarter => 'هذا الربع';

  @override
  String get pvHorizonWeek => 'هذا الأسبوع';

  @override
  String get pvHorizonYear => 'هذا العام';

  @override
  String get pvHorizonsHint =>
      'نوايا غير مجدولة لكل أفق (تُحفظ على هذا الجهاز إلى أن تتوفر مزامنة الآفاق).';

  @override
  String get pvIgnoreLowPriority => 'تجاهل المهام منخفضة الأولوية';

  @override
  String pvImportanceRule(String priority) {
    return 'مهمة ابتداءً من الأولوية $priority';
  }

  @override
  String pvItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصرًا',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا عناصر',
    );
    return '$_temp0';
  }

  @override
  String get pvJumpToDate => 'الانتقال إلى تاريخ';

  @override
  String get pvKeepScreenOn => 'إبقاء الشاشة مضاءة';

  @override
  String get pvLaneCap => 'المسارات المتجاورة';

  @override
  String get pvLanes => 'المسارات';

  @override
  String pvLastRowShort(String duration) {
    return 'والأخير مدته $duration';
  }

  @override
  String get pvLess => 'أقل';

  @override
  String get pvListBelow => 'القائمة في الأسفل';

  @override
  String get pvListMode => 'قائمة ميسّرة';

  @override
  String get pvMapPlaceholder =>
      'تحتاج الخريطة إلى إحداثيات المهام، وستتوفر مع أداة اختيار المكان. المهام التي لها مكان مدرجة أدناه.';

  @override
  String get pvMarkDone => 'تحديد كمنجزة';

  @override
  String get pvMarkNotDone => 'تحديد كغير منجزة';

  @override
  String get pvMetricCompletion => 'معدل الإنجاز';

  @override
  String get pvMetricCount => 'عدد العناصر';

  @override
  String get pvMetricPlanned => 'الساعات المخططة';

  @override
  String get pvMinGap => 'أقل مدة';

  @override
  String get pvMonthBars => 'أشرطة';

  @override
  String get pvMonthDots => 'نقاط';

  @override
  String get pvMonthTitles => 'عناوين';

  @override
  String get pvMonthTitlesTimes => 'عناوين وأوقات';

  @override
  String pvMore(String count) {
    return '+$count';
  }

  @override
  String pvMoreItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر آخر',
      many: '$count عنصرًا آخر',
      few: '$count عناصر أخرى',
      two: 'عنصران آخران',
      one: 'عنصر آخر',
    );
    return '$_temp0';
  }

  @override
  String get pvMoreLegend => 'أكثر';

  @override
  String get pvMoreOptions => 'خيارات أخرى';

  @override
  String get pvMove => 'نقل';

  @override
  String get pvMoveDoneBody => 'هذه المهمة منجزة بالفعل، ونقلها يغيّر سجلّها.';

  @override
  String get pvMoveDoneTitle => 'نقل مهمة منجزة؟';

  @override
  String pvMoveEarlier(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'تقديم $minutes دقيقة',
      many: 'تقديم $minutes دقيقة',
      few: 'تقديم $minutes دقائق',
      two: 'تقديم دقيقتين',
      one: 'تقديم دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String pvMoveLater(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'تأخير $minutes دقيقة',
      many: 'تأخير $minutes دقيقة',
      few: 'تأخير $minutes دقائق',
      two: 'تأخير دقيقتين',
      one: 'تأخير دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get pvMoveTo => 'نقل إلى…';

  @override
  String get pvMoveUnfinishedTomorrow => 'نقل غير المنجز إلى الغد';

  @override
  String pvMovedSnack(String when) {
    return 'نُقلت إلى $when';
  }

  @override
  String get pvNext => 'التالي';

  @override
  String get pvNextDay => 'اليوم التالي';

  @override
  String pvNextDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الـ$count يوم القادمة',
      many: 'الـ$count يومًا القادمة',
      few: 'الأيام الـ$count القادمة',
      two: 'اليومان القادمان',
      one: 'اليوم التالي',
    );
    return '$_temp0';
  }

  @override
  String get pvNextUp => 'التالي';

  @override
  String get pvNextWeek => 'الأسبوع التالي';

  @override
  String get pvNoCategory => 'بلا فئة';

  @override
  String get pvNoOpenings => 'لم يُعثر على وقت متاح';

  @override
  String pvNoRoom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر لم يتسع له الوقت',
      many: '$count عنصرًا لم يتسع له الوقت',
      few: '$count عناصر لم يتسع لها الوقت',
      two: 'عنصران لم يتسع لهما الوقت',
      one: 'عنصر واحد لم يتسع له الوقت',
    );
    return '$_temp0';
  }

  @override
  String get pvNoRoutine => 'لا توجد فترة روتين اليوم';

  @override
  String get pvNoTasks => 'لا مهام';

  @override
  String get pvNothingNow => 'لا شيء مجدول الآن';

  @override
  String get pvNow => 'الآن';

  @override
  String get pvOneOff => 'لمرة واحدة';

  @override
  String get pvOpenDay => 'فتح اليوم';

  @override
  String get pvOpenings => 'الأوقات المتاحة';

  @override
  String get pvOverdue => 'متأخرة';

  @override
  String get pvOverlapCascade => 'متدرّج';

  @override
  String get pvOverlapColumns => 'أعمدة';

  @override
  String get pvOverlapStyle => 'نمط التداخل';

  @override
  String get pvOverlayChecklistDue => 'عناصر القوائم المستحقة';

  @override
  String get pvOverlayDeviceCalendars => 'تقويمات الجهاز';

  @override
  String get pvOverlayFreeSlots => 'الوقت الحر';

  @override
  String get pvOverlayHabits => 'العادات المستحقة';

  @override
  String get pvOverlayHeat => 'كثافة الساعات المزدحمة';

  @override
  String get pvOverlays => 'الطبقات الإضافية';

  @override
  String get pvPagingDay => 'يومًا واحدًا';

  @override
  String get pvPagingFree => 'تمرير حر';

  @override
  String get pvPagingMode => 'السحب الأفقي ينتقل';

  @override
  String get pvPagingWeek => 'أسبوعًا واحدًا';

  @override
  String get pvPause => 'إيقاف مؤقت';

  @override
  String get pvPickDate => 'اختر تاريخًا';

  @override
  String get pvPin => 'تثبيت';

  @override
  String get pvPinned => 'المثبتة';

  @override
  String get pvPlanColumn => 'المخطط';

  @override
  String get pvPlanFirstTask => 'خطّط لمهمتك الأولى';

  @override
  String get pvPlanned => 'المخطط';

  @override
  String get pvPostpone => 'تأجيل';

  @override
  String pvPostponeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get pvPostponeNextWeek => 'الأسبوع القادم';

  @override
  String get pvPostponeTomorrow => 'غدًا';

  @override
  String get pvPrevious => 'السابق';

  @override
  String get pvPreviousDay => 'اليوم السابق';

  @override
  String get pvPreviousWeek => 'الأسبوع السابق';

  @override
  String get pvPriorities => 'الأولويات';

  @override
  String get pvQuadDelegate => 'فوّض';

  @override
  String get pvQuadDo => 'نفّذ';

  @override
  String get pvQuadEliminate => 'احذف';

  @override
  String get pvQuadSchedule => 'جدول';

  @override
  String get pvQuickCreateHint => 'ما الذي تخطط له؟';

  @override
  String get pvQuickCreateTitle => 'مهمة جديدة';

  @override
  String get pvRadial12 => '12 ساعة';

  @override
  String get pvRadial24 => '24 ساعة';

  @override
  String get pvRadialHours => 'القرص';

  @override
  String get pvRecurring => 'متكررة';

  @override
  String get pvRenameView => 'إعادة تسمية العرض';

  @override
  String get pvRenderAuto => 'تلقائي';

  @override
  String get pvRenderMode => 'طريقة العرض';

  @override
  String get pvRenderTable => 'جدول';

  @override
  String get pvRenderTimeline => 'مخطط زمني';

  @override
  String pvRepeatedHour(String time, String offset) {
    return '$time ($offset)';
  }

  @override
  String get pvRepeats => 'متكررة';

  @override
  String get pvResetView => 'إعادة ضبط إعدادات العرض';

  @override
  String pvResizedSnack(String duration) {
    return 'المدة: $duration';
  }

  @override
  String get pvRibbonStyle => 'شريط';

  @override
  String get pvRoutineComplete => 'اكتمل الروتين';

  @override
  String get pvRoutineStart => 'بدء الروتين';

  @override
  String pvRoutineSummary(int done, int total) {
    return 'الخطوات المنجزة: $done من $total';
  }

  @override
  String get pvRowHeight => 'ارتفاع الصف';

  @override
  String get pvRowsOccurrences => 'المواعيد';

  @override
  String pvRowsPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صف في اليوم',
      many: '$count صفًا في اليوم',
      few: '$count صفوف في اليوم',
      two: 'صفّان في اليوم',
      one: 'صف واحد في اليوم',
    );
    return '$_temp0';
  }

  @override
  String get pvRowsTasks => 'المهام';

  @override
  String get pvRules => 'القواعد';

  @override
  String get pvSaveAsNewView => 'حفظ كعرض جديد';

  @override
  String get pvSaveViewAs => 'حفظ العرض باسم…';

  @override
  String get pvSavedViews => 'العروض المحفوظة';

  @override
  String get pvScale => 'المقياس';

  @override
  String get pvScaleDays => 'أيام';

  @override
  String get pvScaleHours => 'ساعات';

  @override
  String get pvScaleMonths => 'أشهر';

  @override
  String get pvScaleWeeks => 'أسابيع';

  @override
  String get pvScheduleOn => 'جدولة في…';

  @override
  String get pvScheduledSnack => 'جُدولت';

  @override
  String get pvScopeAll => 'كل المواعيد';

  @override
  String get pvScopeFollowing => 'هذا الموعد وما يليه';

  @override
  String get pvScopeThis => 'هذا الموعد فقط';

  @override
  String get pvScopeTitle => 'تعديل مهمة متكررة';

  @override
  String pvSelected(int count) {
    return 'المحدد: $count';
  }

  @override
  String get pvSetDefaultView => 'تعيين كعرض افتراضي';

  @override
  String get pvShareAvailability => 'مشاركة أوقات التوفر';

  @override
  String get pvShowCancelled => 'إظهار المهام الملغاة';

  @override
  String get pvShowCompleted => 'إظهار المهام المنجزة';

  @override
  String get pvShowEmptyDays => 'إظهار الأيام الفارغة';

  @override
  String get pvShowNotes => 'إظهار الملاحظات';

  @override
  String get pvShowWeekends => 'إظهار عطلة نهاية الأسبوع';

  @override
  String get pvSinceGroup => 'منذ';

  @override
  String get pvSkip => 'تخطٍّ';

  @override
  String get pvSkipRemaining => 'تخطي المتبقي';

  @override
  String get pvSkipStep => 'تخطي الخطوة';

  @override
  String get pvSlotCustom => 'حجم مخصص';

  @override
  String get pvSlotCustomHint => 'دقائق أو س:د (من دقيقة إلى 24 ساعة)';

  @override
  String get pvSlotInvalid => 'أدخل حجمًا بين دقيقة واحدة و24 ساعة';

  @override
  String get pvSlotPresets => 'أحجام جاهزة';

  @override
  String get pvSlotSize => 'حجم الفترة';

  @override
  String get pvSlotsStyle => 'فترات';

  @override
  String get pvSnap => 'المحاذاة';

  @override
  String get pvSortBy => 'الترتيب حسب';

  @override
  String get pvStart => 'بدء';

  @override
  String pvStartsAt(String time) {
    return 'تبدأ في $time';
  }

  @override
  String get pvStatusCancelled => 'ملغاة';

  @override
  String get pvStatusDone => 'منجزة';

  @override
  String get pvStatusInProgress => 'قيد التنفيذ';

  @override
  String get pvStatusMissed => 'فائتة';

  @override
  String get pvStatusScheduled => 'مجدولة';

  @override
  String get pvStatusSkipped => 'متخطاة';

  @override
  String pvStatusSnack(String status) {
    return 'الحالة: $status';
  }

  @override
  String get pvStatuses => 'الحالات';

  @override
  String pvStep(int n, int total) {
    return 'الخطوة $n من $total';
  }

  @override
  String get pvStop => 'إيقاف';

  @override
  String get pvSwipeVertical => 'السحب عموديًا';

  @override
  String pvTableThreshold(String size) {
    return 'جدول ابتداءً من $size';
  }

  @override
  String get pvTextFilterHint => 'ابحث في العناوين والملاحظات';

  @override
  String pvTileSemantics(
    String title,
    String day,
    String start,
    String end,
    String status,
  ) {
    return '$title، $day، من $start إلى $end، $status';
  }

  @override
  String pvTimeLeft(String duration) {
    return 'المتبقي: $duration';
  }

  @override
  String get pvTo => 'إلى';

  @override
  String get pvTopCategories => 'أبرز الفئات';

  @override
  String get pvTracked => 'المتتبَّع';

  @override
  String get pvTrackingCheck => 'تأشير';

  @override
  String get pvTrackingEvent => 'حدث';

  @override
  String get pvTrackingModes => 'طريقة التتبع';

  @override
  String get pvTrackingTimer => 'مؤقت';

  @override
  String get pvUnpin => 'إلغاء التثبيت';

  @override
  String get pvUnscheduleUnsupported =>
      'إعادة المهام إلى قائمة غير المجدولة غير متاحة بعد';

  @override
  String get pvUnscheduled => 'غير مجدولة';

  @override
  String get pvUntimed => 'بلا وقت';

  @override
  String get pvUpcoming => 'القادمة';

  @override
  String pvUrgencyRule(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'عاجلة خلال $days يوم',
      many: 'عاجلة خلال $days يومًا',
      few: 'عاجلة خلال $days أيام',
      two: 'عاجلة خلال يومين',
      one: 'عاجلة خلال يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get pvVarianceLate => 'بدأت متأخرة';

  @override
  String get pvVarianceNotDone => 'غير منجزة';

  @override
  String get pvVarianceOnPlan => 'حسب الخطة';

  @override
  String get pvVarianceOverran => 'تجاوزت الوقت';

  @override
  String get pvVarianceUnplanned => 'غير مخططة';

  @override
  String get pvViewAgenda => 'جدول الأعمال';

  @override
  String get pvViewBacklog => 'بانتظار الجدولة';

  @override
  String get pvViewCountdown => 'العدّ التنازلي';

  @override
  String get pvViewDayList => 'قائمة اليوم';

  @override
  String get pvViewFocus => 'التركيز';

  @override
  String get pvViewFreeSlots => 'الأوقات الحرة';

  @override
  String get pvViewHorizons => 'الآفاق';

  @override
  String get pvViewKanban => 'كانبان';

  @override
  String get pvViewLoadHeatmap => 'خريطة الانشغال';

  @override
  String get pvViewMap => 'الخريطة';

  @override
  String get pvViewMatrix => 'مصفوفة أيزنهاور';

  @override
  String get pvViewMonth => 'الشهر';

  @override
  String get pvViewMultiWeek => 'عدة أسابيع';

  @override
  String get pvViewNDay => 'عدة أيام';

  @override
  String get pvViewName => 'اسم العرض';

  @override
  String get pvViewPlanVsActual => 'المخطط مقابل الفعلي';

  @override
  String get pvViewQuarter => 'ربع السنة';

  @override
  String get pvViewRadial => 'الساعة الدائرية';

  @override
  String get pvViewRibbon => 'الشريط';

  @override
  String get pvViewRoutine => 'مشغّل الروتين';

  @override
  String get pvViewSaved => 'حُفظ العرض';

  @override
  String get pvViewSettings => 'إعدادات العرض';

  @override
  String get pvViewSwimlanes => 'المسارات';

  @override
  String get pvViewSwitcher => 'تغيير العرض';

  @override
  String get pvViewTable => 'جدول بيانات';

  @override
  String get pvViewTimeline => 'المخطط الزمني';

  @override
  String get pvViewWeekList => 'قائمة الأسبوع';

  @override
  String get pvViewWeekTable => 'جدول الأسبوع';

  @override
  String get pvViewWorkWeek => 'أسبوع العمل';

  @override
  String get pvViewYear => 'السنة';

  @override
  String get pvVisibleHours => 'الساعات الظاهرة';

  @override
  String get pvVisibleHoursAll => 'كل الساعات الأربع والعشرين';

  @override
  String pvWeekNumber(int week) {
    return 'أسبوع $week';
  }

  @override
  String get pvWeekNumbers => 'أرقام الأسابيع';

  @override
  String get pvWeekRibbon => 'الأسبوع';

  @override
  String get pvWeekSummary => 'ملخص الأسبوع';

  @override
  String pvWeeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أسبوع',
      many: '$count أسبوعًا',
      few: '$count أسابيع',
      two: 'أسبوعان',
      one: 'أسبوع واحد',
    );
    return '$_temp0';
  }

  @override
  String get pvWithPlace => 'مهام لها مكان';

  @override
  String get pvWorkHours => 'ساعات العمل';

  @override
  String get pvZoneHint => 'مثال: Asia/Tokyo';

  @override
  String get pvZoomAroundNow => 'التكبير حول الوقت الحالي';

  @override
  String get pvZoomFixed => 'فترة ثابتة';

  @override
  String get pvZoomMode => 'التكبير';

  @override
  String get pvZoomSemantic => 'دلالي';

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
  String repeatChip(String rule, String when) {
    return 'إعادة تعيين $rule · التالية $when';
  }

  @override
  String get repeatCustom => 'قاعدة مخصصة';

  @override
  String get repeatDaily => 'كل يوم';

  @override
  String get repeatModeAll => 'إعادة كل شيء إلى «للإنجاز»';

  @override
  String get repeatModeCompleted => 'إلغاء تحديد المكتملة فقط';

  @override
  String get repeatMonthly => 'كل شهر';

  @override
  String get repeatNoRuns => 'لا توجد دورات مكتملة بعد';

  @override
  String get repeatNone => 'لا يتكرر';

  @override
  String get repeatResetTime => 'وقت إعادة التعيين';

  @override
  String repeatRunSummary(int done, int total) {
    return '$done/$total مكتمل';
  }

  @override
  String get repeatRuns => 'سجل الدورات';

  @override
  String get repeatTitle => 'التكرار';

  @override
  String get repeatWeekdays => 'كل أيام العمل';

  @override
  String get repeatWeekly => 'كل أسبوع';

  @override
  String get savedSnack => 'تم الحفظ';

  @override
  String get settingsAutoComplete => 'إكمال العناصر الأصلية تلقائيًا';

  @override
  String get settingsCascadeAlways => 'إكمال العناصر الفرعية أيضًا';

  @override
  String get settingsCascadeAsk => 'السؤال';

  @override
  String get settingsCascadeNever => 'ترك العناصر الفرعية';

  @override
  String get settingsCategory => 'الفئة';

  @override
  String get settingsCompleteChildren => 'عند إكمال عنصر أصلي';

  @override
  String get settingsDefaultOpen => 'الفتح في وضع';

  @override
  String get settingsHideCheckboxes => 'إخفاء مربعات الاختيار (نقاط)';

  @override
  String get settingsProgressChildren => 'العناصر الفرعية المباشرة فقط';

  @override
  String get settingsProgressLeaves => 'كل العناصر الفرعية';

  @override
  String get settingsProgressMode => 'طريقة حساب التقدم';

  @override
  String get settingsRequireReason => 'طلب سبب لـ';

  @override
  String get settingsShowAttachments => 'إظهار المرفقات في المعاينة';

  @override
  String get settingsShowNotes => 'إظهار الملاحظات في المعاينة';

  @override
  String get settingsSortCompleted => 'نقل المكتملة إلى الأسفل';

  @override
  String settingsStaleDays(int days) {
    return 'اعتباره راكدًا بعد $days يومًا';
  }

  @override
  String get settingsSwipeComplete => 'إكمال';

  @override
  String get settingsSwipeEditLeft => 'وضع التحرير · السحب لليسار';

  @override
  String get settingsSwipeEditRight => 'وضع التحرير · السحب لليمين';

  @override
  String get settingsSwipeIndent => 'زيادة المسافة';

  @override
  String get settingsSwipeMenu => 'قائمة الإجراءات';

  @override
  String get settingsSwipeNone => 'لا شيء';

  @override
  String get settingsSwipeOutdent => 'إنقاص المسافة';

  @override
  String get settingsSwipePreviewLeft => 'المعاينة · السحب لليسار';

  @override
  String get settingsSwipePreviewRight => 'المعاينة · السحب لليمين';

  @override
  String get settingsSwipeTitle => 'إجراءات السحب';

  @override
  String get smartBlocked => 'محظور';

  @override
  String smartChip(String label, int count) {
    return '$label · $count';
  }

  @override
  String get smartClearFollowUp => 'إزالة المتابعة';

  @override
  String get smartEmpty => 'لا شيء هنا — رائع.';

  @override
  String get smartFollowUps => 'المتابعات';

  @override
  String get smartGroupByList => 'التجميع حسب القائمة';

  @override
  String get smartOngoing => 'قيد التنفيذ';

  @override
  String get smartOpenInList => 'فتح في القائمة';

  @override
  String get smartSetFollowUp => 'تعيين متابعة';

  @override
  String get smartSortAge => 'المدة';

  @override
  String get smartSortFollowUp => 'المتابعة';

  @override
  String get smartSortList => 'القائمة';

  @override
  String get smartUnknown => 'قائمة ذكية غير معروفة';

  @override
  String get smartWaiting => 'قيد الانتظار';

  @override
  String get stateEmpty => 'لا يوجد شيء بعد';

  @override
  String get stateErrorBody => 'يرجى المحاولة مرة أخرى.';

  @override
  String get stateErrorTitle => 'حدث خطأ ما';

  @override
  String get stateLoading => 'جارٍ التحميل…';

  @override
  String get statusAddNote => 'إضافة ملاحظة…';

  @override
  String statusAgeDays(int n) {
    return '$n ي';
  }

  @override
  String statusAgeHours(int n) {
    return '$n س';
  }

  @override
  String statusAgeMinutes(int n) {
    return '$n د';
  }

  @override
  String get statusBlocked => 'محظور';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get statusCascadeAll => 'إكمال الكل';

  @override
  String get statusCascadeOnlyThis => 'هذا فقط';

  @override
  String statusCascadeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'هل تريد إكمال $count عنصر فرعي مفتوح أيضًا؟',
      many: 'هل تريد إكمال $count عنصرًا فرعيًا مفتوحًا أيضًا؟',
      few: 'هل تريد إكمال $count عناصر فرعية مفتوحة أيضًا؟',
      two: 'هل تريد إكمال العنصرين الفرعيين المفتوحين أيضًا؟',
      one: 'هل تريد إكمال العنصر الفرعي المفتوح أيضًا؟',
      zero: 'لا عناصر فرعية مفتوحة',
    );
    return '$_temp0';
  }

  @override
  String get statusChange => 'تغيير الحالة';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusFollowUp => 'المتابعة';

  @override
  String statusFollowUpChip(String when) {
    return 'المتابعة $when';
  }

  @override
  String get statusFollowUpCustom => 'مخصص…';

  @override
  String get statusFollowUpIn3Days => 'بعد 3 أيام';

  @override
  String get statusFollowUpLaterToday => 'لاحقًا اليوم';

  @override
  String get statusFollowUpNextWeek => 'الأسبوع القادم';

  @override
  String get statusFollowUpNone => 'بدون متابعة';

  @override
  String get statusFollowUpOverdue => 'حان وقت المتابعة';

  @override
  String get statusFollowUpTomorrow => 'غدًا 09:00';

  @override
  String get statusKeepFollowUp => 'الإبقاء على المتابعة';

  @override
  String statusMarked(String status) {
    return 'تم التعيين: $status';
  }

  @override
  String get statusOngoing => 'قيد التنفيذ';

  @override
  String get statusReasonBlocked => 'ما الذي يعيقه؟';

  @override
  String get statusReasonOther => 'إضافة ملاحظة (اختياري)';

  @override
  String get statusReasonRequired => 'السبب مطلوب';

  @override
  String get statusReasonWaiting => 'بانتظار من / ماذا؟';

  @override
  String get statusRecentReasons => 'الأحدث';

  @override
  String get statusSheetTitle => 'الحالة';

  @override
  String get statusStale => 'راكد';

  @override
  String get statusTodo => 'للإنجاز';

  @override
  String get statusWaiting => 'قيد الانتظار';

  @override
  String statusWithAge(String status, String age) {
    return '$status · $age';
  }

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

  @override
  String get templatesBuiltin => 'مدمجة';

  @override
  String get templatesCreated => 'تم إنشاء قائمة من القالب';

  @override
  String get templatesEdit => 'تعديل القالب';

  @override
  String get templatesEmpty => 'احفظ أي قائمة كقالب من قائمتها.';

  @override
  String get templatesMine => 'قوالبي';

  @override
  String get templatesRename => 'إعادة تسمية';

  @override
  String get templatesUse => 'استخدام القالب';
}
