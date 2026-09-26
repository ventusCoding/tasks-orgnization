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
  String get checklistInsightsPlaceholder =>
      'ستتوفر إحصاءات القائمة مع قسم الإحصاءات.';

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
  String get itemAddReminder => 'إضافة تذكير';

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
  String get itemReminders => 'التذكيرات';

  @override
  String get itemRemindersPlaceholder => 'سيتم ضبط تذكيرات هذا العنصر هنا.';

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
