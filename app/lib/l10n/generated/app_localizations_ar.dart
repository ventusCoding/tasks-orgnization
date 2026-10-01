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
  String get activityArchived => 'أُرشف';

  @override
  String activityAttachmentAdded(String name) {
    return 'أُضيف مرفق: $name';
  }

  @override
  String activityAttachmentRemoved(String name) {
    return 'أُزيل مرفق: $name';
  }

  @override
  String get activityCauseAutomatic => 'تلقائي';

  @override
  String get activityCauseBulk => 'تغيير جماعي';

  @override
  String get activityCauseImport => 'مستورد';

  @override
  String activityChangedFields(String fields) {
    return 'تم تغيير $fields';
  }

  @override
  String get activityCompleted => 'اكتمل';

  @override
  String get activityCreated => 'تم الإنشاء';

  @override
  String get activityCreatedCopy => 'أُنشئ كنسخة';

  @override
  String get activityCreatedFromTemplate => 'أُنشئ من قالب';

  @override
  String get activityDeleted => 'حُذف';

  @override
  String activityDeletedWithItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حُذف مع $count عنصر',
      many: 'حُذف مع $count عنصرًا',
      few: 'حُذف مع $count عناصر',
      two: 'حُذف مع عنصرين',
      one: 'حُذف مع عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String activityDurationChanged(String from, String to) {
    return 'تغيّرت المدة من $from إلى $to';
  }

  @override
  String get activityEdited => 'تم التعديل';

  @override
  String get activityEmpty => 'لا يوجد سجل بعد';

  @override
  String get activityFieldCategory => 'الفئة';

  @override
  String get activityFieldColor => 'اللون';

  @override
  String get activityFieldDue => 'تاريخ الاستحقاق';

  @override
  String get activityFieldDuration => 'المدة';

  @override
  String get activityFieldIcon => 'الأيقونة';

  @override
  String get activityFieldName => 'الاسم';

  @override
  String get activityFieldNotes => 'الملاحظات';

  @override
  String get activityFieldPriority => 'الأولوية';

  @override
  String get activityFieldRepeat => 'التكرار';

  @override
  String get activityFieldTags => 'الوسوم';

  @override
  String get activityFieldText => 'النص';

  @override
  String get activityFieldTime => 'الوقت';

  @override
  String get activityFieldTitle => 'العنوان';

  @override
  String get activityFile => 'ملف';

  @override
  String activityItemsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُضيف $count عنصر',
      many: 'أُضيف $count عنصرًا',
      few: 'أُضيفت $count عناصر',
      two: 'أُضيف عنصران',
      one: 'أُضيف عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String get activityListSeparator => '، ';

  @override
  String get activityMerged => 'دُمج';

  @override
  String get activityMoved => 'نُقل';

  @override
  String get activityMovedToList => 'نُقل إلى قائمة أخرى';

  @override
  String get activityOther => 'تم التغيير';

  @override
  String get activityPaused => 'أُوقف مؤقتًا';

  @override
  String activityQuoted(String text) {
    return '«$text»';
  }

  @override
  String get activityRelapse => 'سُجّلت انتكاسة';

  @override
  String get activityReopened => 'أُعيد فتحه';

  @override
  String activityRescheduled(String from, String to) {
    return 'نُقل من $from إلى $to';
  }

  @override
  String get activityReset => 'أُعيد تعيينه';

  @override
  String get activityRestored => 'استُعيد';

  @override
  String get activityResumed => 'استُؤنف';

  @override
  String get activityRollover => 'رُحّل';

  @override
  String get activityScheduled => 'تمت الجدولة';

  @override
  String get activityScopeFollowing => 'هذا التكرار وما يليه';

  @override
  String get activityScopeSeries => 'كل التكرارات';

  @override
  String get activitySeriesSplit => 'قُسّمت السلسلة';

  @override
  String get activitySkipped => 'تم التخطي';

  @override
  String activitySkippedReason(String reason) {
    return 'تم التخطي: $reason';
  }

  @override
  String get activitySorted => 'رُتّبت العناصر';

  @override
  String get activityStarted => 'بدأ';

  @override
  String activityStatusChanged(String from, String to) {
    return 'تغيّرت الحالة من $from إلى $to';
  }

  @override
  String get activityStatusNoteChanged => 'تم تحديث السبب';

  @override
  String activityStatusSet(String to) {
    return 'عُيّنت الحالة إلى $to';
  }

  @override
  String get activityStopped => 'توقّف';

  @override
  String get activityTagsChanged => 'تم تحديث الوسوم';

  @override
  String get activityTimeLogged => 'سُجّل الوقت';

  @override
  String get activityTitle => 'السجل';

  @override
  String get activityUnarchived => 'أُلغيت أرشفته';

  @override
  String get activityUnscheduled => 'نُقل إلى المهام غير المجدولة';

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
  String get attachmentsDownloadWhenOnline => 'سيُنزَّل هذا الملف عند اتصالك بالإنترنت.';

  @override
  String attachmentsDuration(String duration) {
    return 'المدة $duration';
  }

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
  String get attachmentsPause => 'إيقاف مؤقت';

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
  String get attachmentsPlay => 'تشغيل';

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
  String attachmentsRejectedTooLong(String name, int seconds) {
    return 'مدة $name أطول من $seconds ثانية';
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
  String get attachmentsSourceRecordVideo => 'تصوير فيديو';

  @override
  String get attachmentsSourceScan => 'مسح مستند ضوئيًا';

  @override
  String get attachmentsSourceVideos => 'اختيار فيديو';

  @override
  String get attachmentsSourceVoiceNote => 'ملاحظة صوتية';

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
  String get authAvatarChange => 'تغيير الصورة';

  @override
  String get authAvatarRemove => 'إزالة الصورة';

  @override
  String get authBrowserFlowStarted => 'أكمل تسجيل الدخول في المتصفح ثم عُد إلى Everslot.';

  @override
  String get authChangeEmail => 'استخدام بريد إلكتروني آخر';

  @override
  String authCodeBody(String email) {
    return 'أدخل الرمز المكوّن من 6 أرقام المُرسل إلى $email، أو اضغط على الرابط الموجود في تلك الرسالة.';
  }

  @override
  String get authCodeLabel => 'رمز من 6 أرقام';

  @override
  String get authCodeResent => 'رمز جديد في الطريق إليك.';

  @override
  String get authCodeTitle => 'تحقّق من بريدك الوارد';

  @override
  String get authContinueApple => 'المتابعة باستخدام Apple';

  @override
  String get authContinueGoogle => 'المتابعة باستخدام Google';

  @override
  String get authContinueGuest => 'المتابعة بدون حساب';

  @override
  String get authCurrentZone => 'المنطقة الزمنية الحالية';

  @override
  String get authDeleteAccount => 'حذف الحساب';

  @override
  String get authDeleteBody =>
      'سيُحذف حسابك وجميع بياناتك نهائيًا (الخطط والقوائم والعادات والمرفقات) على كل أجهزتك. لا يمكن التراجع عن ذلك.';

  @override
  String get authDeleteConfirm => 'حذف نهائي';

  @override
  String get authDeleteExportFirst => 'تصدير بياناتي أولًا';

  @override
  String authDeleteReauthBody(String email) {
    return 'للتأكد من هويتك، أدخل الرمز المُرسل إلى $email.';
  }

  @override
  String get authDeleteTitle => 'حذف حسابك؟';

  @override
  String get authDeleteUnderstand => 'أفهم أنه لا يمكن التراجع عن ذلك';

  @override
  String authDeleteWeb(String url) {
    return 'يمكنك أيضًا طلب الحذف عبر الويب: $url';
  }

  @override
  String get authDeleted => 'تم حذف حسابك.';

  @override
  String get authDeleting => 'جارٍ حذف حسابك…';

  @override
  String get authDeviceRevokedBody =>
      'أُزيل هذا الجهاز من حسابك عبر جهاز آخر. صدّر بياناتك أولًا إن أردت الاحتفاظ بنسخة منها، ثم سجّل الخروج.';

  @override
  String get authDeviceRevokedTitle => 'تمت إزالة هذا الجهاز';

  @override
  String get authDisplayName => 'الاسم المعروض';

  @override
  String get authDisplayNameHint => 'بماذا تحب أن نناديك؟';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authErrorCaptcha => 'فشل التحقق الأمني. يُرجى إعادة المحاولة.';

  @override
  String get authErrorEmailInUse => 'هذا البريد الإلكتروني مرتبط بحساب آخر.';

  @override
  String get authErrorGuestDisabled => 'وضع الضيف معطّل على هذا الخادم.';

  @override
  String get authErrorIdentityInUse => 'طريقة تسجيل الدخول هذه مرتبطة بحساب آخر.';

  @override
  String get authErrorInvalidCode => 'هذا الرمز غير صالح أو منتهي الصلاحية.';

  @override
  String get authErrorInvalidEmail => 'يُرجى إدخال بريد إلكتروني صحيح.';

  @override
  String get authErrorLastIdentity => 'لا يمكنك إزالة طريقة تسجيل الدخول الوحيدة لديك.';

  @override
  String get authErrorMfaRequired => 'أدخل الرمز من تطبيق المصادقة للمتابعة.';

  @override
  String get authErrorNotConfigured => 'المزامنة السحابية غير مُعدّة في هذا الإصدار (راجع guide.md).';

  @override
  String get authErrorOffline => 'أنت غير متصل بالإنترنت. تحقّق من اتصالك ثم أعد المحاولة.';

  @override
  String get authErrorProviderNotConfigured => 'طريقة تسجيل الدخول هذه غير مُعدّة بعد (راجع guide.md).';

  @override
  String get authErrorRateLimited => 'محاولات كثيرة جدًا. انتظر قليلًا ثم أعد المحاولة.';

  @override
  String get authErrorSessionExpired => 'انتهت صلاحية جلستك. يُرجى تسجيل الدخول مجددًا.';

  @override
  String get authErrorUnknown => 'حدث خطأ ما. يُرجى إعادة المحاولة.';

  @override
  String get authExportFirst => 'تصدير البيانات';

  @override
  String get authGuestAccount => 'حساب ضيف';

  @override
  String get authGuestBanner => 'أنت تستخدم حساب ضيف. أضف بريدًا إلكترونيًا حتى لا تضيع بياناتك إذا حذفت التطبيق.';

  @override
  String get authGuestBannerAction => 'تأمين بياناتي';

  @override
  String get authGuestHint => 'جرّب Everslot فورًا وأضف بريدًا إلكترونيًا لاحقًا للاحتفاظ ببياناتك.';

  @override
  String get authHomeZone => 'المنطقة الزمنية الأساسية';

  @override
  String get authLegalNote => 'بالمتابعة، فإنك توافق على شروط الخدمة وسياسة الخصوصية.';

  @override
  String get authLink => 'ربط';

  @override
  String authLinked(String provider) {
    return 'تم ربط $provider';
  }

  @override
  String get authLinkedAccounts => 'طرق تسجيل الدخول';

  @override
  String get authLocalOnlyAccount => 'البيانات محفوظة على هذا الجهاز';

  @override
  String get authLocalOnlyAccountBody => 'لم تسجّل الدخول. سجّل الدخول للمزامنة بين أجهزتك وستنتقل بياناتك معك.';

  @override
  String get authMfaBody => 'طلب رمز من تطبيق المصادقة عند تسجيل الدخول وقبل حذف الحساب.';

  @override
  String get authMfaCopySecret => 'نسخ المفتاح';

  @override
  String get authMfaDisable => 'إيقاف';

  @override
  String get authMfaDisableBody => 'أدخل رمزًا من تطبيق المصادقة لإيقاف التحقق بخطوتين.';

  @override
  String get authMfaDisabled => 'التحقق بخطوتين متوقف.';

  @override
  String get authMfaEnabled => 'التحقق بخطوتين مفعّل.';

  @override
  String get authMfaEnroll => 'إعداد';

  @override
  String get authMfaEnrollBody => 'أضف هذا المفتاح إلى تطبيق المصادقة، ثم أدخل الرمز المكوّن من 6 أرقام الذي يظهر فيه.';

  @override
  String get authMfaOpenApp => 'فتح في تطبيق المصادقة';

  @override
  String get authMfaSecret => 'مفتاح الإعداد';

  @override
  String get authMfaSecretCopied => 'تم نسخ مفتاح الإعداد.';

  @override
  String get authMfaTitle => 'التحقق بخطوتين';

  @override
  String get authMfaVerifyBody => 'افتح تطبيق المصادقة وأدخل الرمز المكوّن من 6 أرقام الخاص بـ Everslot.';

  @override
  String get authMfaVerifyTitle => 'أدخل الرمز من تطبيق المصادقة';

  @override
  String get authNotConfiguredBody =>
      'هذا الإصدار غير متصل بمشروع Supabase بعد (راجع guide.md). يعمل Everslot بالكامل على هذا الجهاز في هذه الأثناء.';

  @override
  String get authNotConfiguredTitle => 'المزامنة السحابية غير مُعدّة';

  @override
  String get authOr => 'أو';

  @override
  String get authProfileTitle => 'الحساب';

  @override
  String get authProviderApple => 'Apple';

  @override
  String get authProviderEmail => 'البريد الإلكتروني';

  @override
  String get authProviderGoogle => 'Google';

  @override
  String get authReauthBody =>
      'انتهت صلاحية جلستك. سجّل الدخول مجددًا لاستئناف المزامنة، فكل ما أنجزته دون اتصال محفوظ.';

  @override
  String get authReauthTitle => 'سجّل الدخول مجددًا';

  @override
  String get authRegionalSettings => 'الإعدادات الإقليمية';

  @override
  String get authResend => 'إعادة إرسال الرمز';

  @override
  String authResendIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'إعادة إرسال الرمز بعد $seconds ثانية',
      many: 'إعادة إرسال الرمز بعد $seconds ثانية',
      few: 'إعادة إرسال الرمز بعد $seconds ثوانٍ',
      two: 'إعادة إرسال الرمز بعد ثانيتين',
      one: 'إعادة إرسال الرمز بعد ثانية واحدة',
    );
    return '$_temp0';
  }

  @override
  String get authSendCode => 'إرسال الرمز';

  @override
  String get authSessionExpiredBanner =>
      'انتهت صلاحية جلستك. تغييراتك محفوظة على هذا الجهاز وستُزامَن بمجرد تسجيل دخولك مجددًا.';

  @override
  String get authSignInAgain => 'تسجيل الدخول مجددًا';

  @override
  String get authSignInToSync => 'تسجيل الدخول للمزامنة';

  @override
  String get authSignOut => 'تسجيل الخروج';

  @override
  String get authSignOutAnyway => 'تسجيل الخروج على أي حال';

  @override
  String get authSignOutBody => 'ستُزال بياناتك من هذا الجهاز، وتبقى آمنة في حسابك.';

  @override
  String get authSignOutGuestBody =>
      'حساب الضيف هذا موجود على هذا الجهاز فقط. سيؤدي تسجيل الخروج إلى حذفه نهائيًا مع كل بياناته، فأضف بريدًا إلكترونيًا أولًا للاحتفاظ به.';

  @override
  String authSignOutPendingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لم تتم مزامنة $count تعديل بعد وسيُفقد.',
      many: 'لم تتم مزامنة $count تعديلًا بعد وسيُفقد.',
      few: 'لم تتم مزامنة $count تعديلات بعد وستُفقد.',
      two: 'لم تتم مزامنة تعديلين بعد وسيُفقدان.',
      one: 'لم تتم مزامنة تعديل واحد بعد وسيُفقد.',
    );
    return '$_temp0 صدّر بياناتك أولًا، أو سجّل الخروج على أي حال.';
  }

  @override
  String get authSignOutSyncing => 'جارٍ مزامنة آخر تغييراتك…';

  @override
  String get authSignOutTitle => 'تسجيل الخروج؟';

  @override
  String authSignedInAs(String email) {
    return 'مسجّل الدخول باسم $email';
  }

  @override
  String get authSignedOut => 'تم تسجيل الخروج';

  @override
  String get authUnlink => 'إلغاء الربط';

  @override
  String authUnlinkConfirm(String provider) {
    return 'إلغاء ربط $provider؟';
  }

  @override
  String get authUpdateRequired => 'حدّث Everslot لمواصلة المزامنة. تغييراتك محفوظة على هذا الجهاز.';

  @override
  String get authUpgradeBody => 'أضف طريقة تسجيل دخول إلى حساب الضيف. ستبقى بياناتك كما هي تمامًا.';

  @override
  String get authUpgradeDone => 'تم تأمين حسابك.';

  @override
  String get authUpgradeEmail => 'إضافة بريد إلكتروني';

  @override
  String authUpgradeEmailInUseBody(String email) {
    return 'لدى $email حساب Everslot بالفعل. استخدم بريدًا آخر، أو صدّر بيانات الضيف ثم سجّل الخروج وادخل إلى ذلك الحساب واستورد الملف.';
  }

  @override
  String get authUpgradeEmailInUseTitle => 'البريد الإلكتروني مستخدم بالفعل';

  @override
  String get authUpgradeTitle => 'احتفظ ببياناتك';

  @override
  String get authUseLocalOnly => 'الاستخدام على هذا الجهاز فقط';

  @override
  String get authUseLocalOnlyHint => 'بدون حساب وبدون مزامنة. سجّل الدخول لاحقًا وستنتقل بياناتك معك.';

  @override
  String get authVerify => 'تحقّق';

  @override
  String get authWelcomeBody => 'سجّل الدخول لمزامنة خططك وقوائمك وعاداتك على جميع أجهزتك.';

  @override
  String get authWelcomeTitle => 'مرحبًا بك في Everslot';

  @override
  String authZoneChangedBody(String zone) {
    return 'أنت الآن في $zone. تحتفظ المهام ذات التوقيت الثابت بوقتها الدقيق وتتبعك المهام المرنة. هل تريد جعل $zone منطقتك الزمنية الأساسية؟';
  }

  @override
  String get authZoneChangedTitle => 'منطقة زمنية جديدة';

  @override
  String get authZoneDetected => 'تم اكتشافها على هذا الجهاز';

  @override
  String authZoneKeepHome(String zone) {
    return 'الإبقاء على $zone';
  }

  @override
  String get authZoneMakeHome => 'جعلها الأساسية';

  @override
  String get authZoneNoMatch => 'لا توجد منطقة زمنية تطابق بحثك';

  @override
  String get authZoneSearch => 'البحث عن منطقة زمنية';

  @override
  String get bootstrapErrorBody =>
      'حدث خطأ أثناء فتح التطبيق. بياناتك بأمان على هذا الجهاز. حاول مرة أخرى، وأعد تشغيل هاتفك إذا استمرت المشكلة.';

  @override
  String get bootstrapErrorCopy => 'نسخ التفاصيل';

  @override
  String get bootstrapErrorDetails => 'التفاصيل (للمطوّرين)';

  @override
  String get bootstrapErrorTitle => 'تعذّر تشغيل Everslot';

  @override
  String get categoriesEmpty => 'لا توجد فئات بعد';

  @override
  String get categoriesTitle => 'الفئات';

  @override
  String get categoryArchived => 'مؤرشف';

  @override
  String get categoryClearAction => 'إزالة الفئة منها';

  @override
  String categoryCreateNamed(String name) {
    return 'إنشاء الفئة «$name»';
  }

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
  String get categoryDeleteBody => 'ستبقى العناصر في هذه الفئة بدون فئة.';

  @override
  String categoryDeleteUsedBody(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر يستخدم «$name».',
      many: '$count عنصرًا يستخدم «$name».',
      few: '$count عناصر تستخدم «$name».',
      two: 'عنصران يستخدمان «$name».',
      one: 'عنصر واحد يستخدم «$name».',
    );
    return '$_temp0 ماذا تريد أن تفعل بها؟';
  }

  @override
  String get categoryEdit => 'تعديل الفئة';

  @override
  String get categoryErrorDuplicate => 'توجد فئة بهذا الاسم بالفعل.';

  @override
  String get categoryErrorInvalid => 'استخدم من 1 إلى 60 حرفًا.';

  @override
  String get categoryName => 'الاسم';

  @override
  String get categoryNew => 'فئة جديدة';

  @override
  String get categoryNone => 'بلا فئة';

  @override
  String get categoryPick => 'الفئة';

  @override
  String get categoryReassignAction => 'نقلها إلى فئة أخرى';

  @override
  String get categoryReassignTitle => 'نقل العناصر إلى';

  @override
  String get categoryReorderHint => 'اسحب لإعادة الترتيب';

  @override
  String get categorySearch => 'ابحث عن فئة أو أنشئ واحدة';

  @override
  String get categoryUnavailable => 'يُحتسب وقتًا غير متاح';

  @override
  String get categoryUnavailableHint => 'يُستثنى من إحصاءات السعة (مثل النوم والإجازات).';

  @override
  String categoryUsage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصرًا',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'غير مستخدمة',
    );
    return '$_temp0';
  }

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
  String get chartsLabelBackfillShare => 'مسجَّل متأخرًا';

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
  String get chartsLabelLoggedRatio => 'المسجَّل';

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
  String get chartsLabelMostActive => 'الأكثر نشاطًا';

  @override
  String get chartsLabelMostBlocked => 'الأكثر تعطّلًا';

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
  String get chartsLabelPendingSync => 'بانتظار المزامنة';

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
  String get chartsLabelStalest => 'الأطول ركودًا';

  @override
  String get chartsLabelStreak => 'السلسلة';

  @override
  String get chartsLabelSuccess => 'نجاح';

  @override
  String get chartsLabelSummary => 'ملخّص';

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
  String get chartsLabelTrackedTime => 'الوقت المتتبَّع';

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
  String get chartsLabelUnknownUnits => 'غير المسجَّل';

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
  String get chartsMilestoneRestarted => 'أُعيد تشغيل العدّاد بعد زلّة — كل يوم أنجزته ما زال محسوبًا.';

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
  String chartsSummaryBars(String title, String count, String label, String value) {
    return '$title: $count أعمدة، الأعلى $label بقيمة $value.';
  }

  @override
  String chartsSummaryCalendar(String title, String count) {
    return '$title: عرض $count يومًا.';
  }

  @override
  String chartsSummaryLine(String title, String range, String first, String last, String trend) {
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
  String get checklistCover => 'صورة الغلاف…';

  @override
  String get checklistCoverAuto => 'تلقائي (أول صورة)';

  @override
  String get checklistCoverNoImages => 'أضف صورة إلى القائمة أو إلى عناصرها أولًا';

  @override
  String get checklistCoverUpdated => 'تم تحديث الغلاف';

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
  String checklistDoneThisWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر أُنجز هذا الأسبوع',
      many: '$count عنصرًا أُنجز هذا الأسبوع',
      few: '$count عناصر أُنجزت هذا الأسبوع',
      two: 'عنصران أُنجزا هذا الأسبوع',
      one: 'عنصر واحد أُنجز هذا الأسبوع',
    );
    return '$_temp0';
  }

  @override
  String get checklistDragHandle => 'اسحب للنقل';

  @override
  String get checklistDue => 'تاريخ الاستحقاق';

  @override
  String get checklistDuplicate => 'تكرار القائمة';

  @override
  String get checklistDuplicateItem => 'تكرار';

  @override
  String checklistDurationDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يوم',
      many: '$n يومًا',
      few: '$n أيام',
      two: 'يومين',
      one: 'يوم واحد',
      zero: '0 يوم',
    );
    return '$_temp0';
  }

  @override
  String checklistDurationHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ساعة',
      many: '$n ساعة',
      few: '$n ساعات',
      two: 'ساعتين',
      one: 'ساعة واحدة',
      zero: '0 ساعة',
    );
    return '$_temp0';
  }

  @override
  String checklistDurationMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n دقيقة',
      many: '$n دقيقة',
      few: '$n دقائق',
      two: 'دقيقتين',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return '$_temp0';
  }

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
  String get checklistLinkTask => 'ربط بمهمة موجودة…';

  @override
  String get checklistLinkTaskTitle => 'ربط مهمة';

  @override
  String get checklistLinkedTask => 'مهمة مرتبطة';

  @override
  String get checklistMdBold => 'غامق';

  @override
  String get checklistMdBullet => 'قائمة نقطية';

  @override
  String get checklistMdCode => 'رمز برمجي';

  @override
  String get checklistMdHeading => 'عنوان';

  @override
  String get checklistMdItalic => 'مائل';

  @override
  String get checklistMdLink => 'رابط';

  @override
  String get checklistMdStrike => 'يتوسطه خط';

  @override
  String get checklistModeEdit => 'تحرير';

  @override
  String get checklistModePreview => 'معاينة';

  @override
  String get checklistMoveConflict => 'تعارض نقلٌ مع تغيير على جهاز آخر فتم التراجع عنه.';

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
  String get checklistNoOtherLists => 'لا توجد قائمة أخرى للعرض';

  @override
  String get checklistNoTasksToLink => 'لا توجد مهام للربط بعد';

  @override
  String get checklistNotFound => 'هذه القائمة غير موجودة';

  @override
  String get checklistNotifItemGone => 'هذا العنصر لم يعد موجودًا';

  @override
  String get checklistOpenSideBySide => 'فتح جنبًا إلى جنب…';

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
  String get checklistPickSecondList => 'العرض بجانب هذه القائمة';

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
  String get checklistResetConfirm => 'ستعود كل العناصر إلى «للإنجاز» وتُمسح ملاحظات الأسباب.';

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
  String checklistStatusSpoken(String status, String age) {
    return '$status منذ $age';
  }

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
  String checklistTaskLinked(String task) {
    return 'مرتبطة بـ$task';
  }

  @override
  String get checklistTaskPlaceholder => 'سيتوفر الربط بالمهام مع المخطط.';

  @override
  String get checklistTaskScheduled => 'أُنشئت المهمة — حدّد موعدها';

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
  String get checklistViewMindMap => 'خريطة ذهنية';

  @override
  String get checklistViewOutline => 'مخطط';

  @override
  String get checklistZoomOut => 'تصغير';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get confirmDeleteBody => 'يمكنك استعادته من سلة المحذوفات خلال 30 يومًا.';

  @override
  String confirmDeleteTitle(String item) {
    return 'حذف $item؟';
  }

  @override
  String deletedSnack(String item) {
    return 'تم حذف $item';
  }

  @override
  String get devComponentGallery => 'معرض المكوّنات';

  @override
  String get devConfigured => 'مُهيّأ';

  @override
  String get devCopied => 'تم النسخ';

  @override
  String get devDangerZone => 'منطقة حساسة';

  @override
  String get devDatabase => 'قاعدة البيانات المحلية';

  @override
  String get devDatabaseEmpty => 'لا توجد صفوف.';

  @override
  String devDatabaseRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صف',
      many: '$count صفًا',
      few: '$count صفوف',
      two: 'صفّان',
      one: 'صف واحد',
      zero: 'فارغ',
    );
    return '$_temp0';
  }

  @override
  String get devEnvironment => 'البيئة';

  @override
  String get devFirebase => 'Firebase';

  @override
  String get devFlags => 'الميزات التجريبية';

  @override
  String get devFlagsHint => 'تغييرات لهذه الجلسة فقط (نسخ التطوير).';

  @override
  String devFlavor(String flavor) {
    return 'النسخة: $flavor';
  }

  @override
  String get devLogs => 'السجلات';

  @override
  String get devLogsAll => 'الكل';

  @override
  String get devLogsCopy => 'نسخ السجلات';

  @override
  String get devLogsEmpty => 'لا توجد سجلات بعد.';

  @override
  String get devMenu => 'قائمة المطوّر';

  @override
  String get devNoWarnings => 'لا توجد تحذيرات في الإعداد';

  @override
  String get devNotConfigured => 'غير مُهيّأ';

  @override
  String get devResetData => 'إعادة ضبط البيانات المحلية';

  @override
  String get devResetDataBody =>
      'يحذف كل العناصر والإعدادات والملفات المحفوظة على هذا الجهاز. يتم تسجيل الخروج من الحساب السحابي (تبقى بياناته على الخادم). لا يمكن التراجع عن ذلك.';

  @override
  String get devResetDone => 'تمت إعادة ضبط البيانات المحلية';

  @override
  String get devSampleData => 'بيانات تجريبية';

  @override
  String get devSampleDataBody =>
      'يضيف ما يقارب ستة أشهر من المهام والقوائم والعادات ومتتبّع إقلاع واقعية للعروض ولقطات الشاشة.';

  @override
  String devSampleDataDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُضيف $count عنصر',
      many: 'أُضيف $count عنصرًا',
      few: 'أُضيفت $count عناصر',
      two: 'أُضيف عنصران',
      one: 'أُضيف عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String get devSampleDataGenerate => 'إنشاء بيانات تجريبية';

  @override
  String get devSampleDataRemove => 'حذف البيانات التجريبية';

  @override
  String get devSampleDataRemoved => 'تم حذف البيانات التجريبية';

  @override
  String devSession(String mode) {
    return 'الجلسة: $mode';
  }

  @override
  String get devSupabase => 'Supabase';

  @override
  String devSyncAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محاولة',
      many: '$count محاولة',
      few: '$count محاولات',
      two: 'محاولتان',
      one: 'محاولة واحدة',
      zero: 'لم يُرسل بعد',
    );
    return '$_temp0';
  }

  @override
  String devSyncBatch(int size) {
    return 'حجم دفعة الإرسال: $size';
  }

  @override
  String get devSyncClear => 'مسح';

  @override
  String get devSyncConflicts => 'سجل التعارضات';

  @override
  String get devSyncConflictsEmpty => 'لم تُسجَّل أي تعارضات.';

  @override
  String devSyncCursor(int cursor, int watermark) {
    return 'المؤشر $cursor · حدّ الحذف النهائي $watermark';
  }

  @override
  String get devSyncDiagnostics => 'تشخيص المزامنة';

  @override
  String devSyncGroup(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تغيير',
      many: '$count تغييرًا',
      few: '$count تغييرات',
      two: 'تغييران',
      one: 'تغيير واحد',
    );
    return '$_temp0 · $when';
  }

  @override
  String devSyncLastPull(String when) {
    return 'آخر استلام: $when';
  }

  @override
  String devSyncLastPush(String when) {
    return 'آخر إرسال: $when';
  }

  @override
  String get devSyncNever => 'أبدًا';

  @override
  String get devSyncNoPulls => 'لم يتم أي استلام في هذه الجلسة.';

  @override
  String get devSyncOff =>
      'المزامنة متوقفة على هذا الجهاز (وضع محلي). تحتفظ قائمة الإرسال بالتغييرات لتسجيل دخول لاحق.';

  @override
  String get devSyncOutbox => 'قائمة الإرسال';

  @override
  String get devSyncOutboxEmpty => 'قائمة الإرسال فارغة.';

  @override
  String devSyncPullPage(int since, int next, int changes) {
    String _temp0 = intl.Intl.pluralLogic(
      changes,
      locale: localeName,
      other: '$changes تغيير',
      many: '$changes تغييرًا',
      few: '$changes تغييرات',
      two: 'تغييران',
      one: 'تغيير واحد',
    );
    return '$since ← $next · $_temp0';
  }

  @override
  String get devSyncPulls => 'آخر الصفحات المستلمة';

  @override
  String get devSyncSimulateOffline => 'محاكاة انقطاع الشبكة';

  @override
  String get devSyncSimulateOfflineHint => 'تفشل كل مزامنة كما لو كانت الشبكة مقطوعة.';

  @override
  String get devTestCrash => 'إرسال تعطّل تجريبي';

  @override
  String get devTestCrashBody => 'يرمي خطأ غير مُعالَج؛ نسخ الإصدار تُبلغ عنه إلى Crashlytics.';

  @override
  String get devTimeTravel => 'السفر عبر الزمن';

  @override
  String devTimeTravelNow(String time) {
    return 'وقت التطبيق: $time';
  }

  @override
  String get devTimeTravelOff => 'الوقت الحقيقي';

  @override
  String devTimeTravelOffset(String relative) {
    return 'مُزاح: $relative';
  }

  @override
  String get devTimeTravelPick => 'اختر تاريخًا ووقتًا';

  @override
  String get devTimeTravelReset => 'العودة إلى الوقت الحقيقي';

  @override
  String get devTools => 'الأدوات';

  @override
  String get devZone => 'المنطقة الزمنية';

  @override
  String devZoneDevice(String zone) {
    return 'منطقة الجهاز: $zone';
  }

  @override
  String get devZoneOverridden => 'مُستبدلة حتى إعادة الضبط';

  @override
  String get devZoneOverride => 'استبدال منطقة الجهاز';

  @override
  String get devZoneReset => 'استخدام منطقة الجهاز الحقيقية';

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
  String get entityStatusActive => 'نشط';

  @override
  String get entityStatusArchived => 'مؤرشف';

  @override
  String get entityStatusBlocked => 'محظور';

  @override
  String get entityStatusCancelled => 'ملغى';

  @override
  String get entityStatusCompleted => 'مكتمل';

  @override
  String get entityStatusDone => 'منجز';

  @override
  String get entityStatusInProgress => 'جارٍ';

  @override
  String get entityStatusMissed => 'فائت';

  @override
  String get entityStatusOngoing => 'قيد التنفيذ';

  @override
  String get entityStatusPaused => 'متوقف مؤقتًا';

  @override
  String get entityStatusScheduled => 'مجدول';

  @override
  String get entityStatusSkipped => 'متخطّى';

  @override
  String get entityStatusTodo => 'للقيام به';

  @override
  String get entityStatusWaiting => 'في الانتظار';

  @override
  String get errorAuth => 'يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errorConflict => 'تم تغيير هذا العنصر في مكان آخر. أعد التحميل ثم حاول مرة أخرى.';

  @override
  String get errorNetwork => 'تعذّر الوصول إلى الخادم. تحقّق من اتصالك.';

  @override
  String get errorNotConfigured => 'هذه الميزة تتطلّب إعداد السحابة (راجع guide.md).';

  @override
  String get errorNotFound => 'هذا العنصر لم يعد موجودًا.';

  @override
  String get errorPermission => 'هذا يتطلّب إذنًا.';

  @override
  String get errorStorage => 'تعذّرت قراءة البيانات أو كتابتها على هذا الجهاز. أخلِ بعض المساحة ثم حاول مرة أخرى.';

  @override
  String get errorUnknown => 'خطأ غير متوقّع.';

  @override
  String get errorUnsupportedVersion => 'يرجى تحديث Everslot لمتابعة المزامنة.';

  @override
  String get errorValidation => 'يرجى مراجعة الحقول المحدّدة.';

  @override
  String get errorWidgetFallback => 'تعذّر عرض هذا الجزء.';

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
  String get exportZipBundle => 'مشاركة كملف zip (مع الملفات)';

  @override
  String filterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عامل تصفية نشط',
      many: '$count عامل تصفية نشطًا',
      few: '$count عوامل تصفية نشطة',
      two: 'عاملا تصفية نشطان',
      one: 'عامل تصفية واحد نشط',
      zero: 'لا توجد عوامل تصفية',
    );
    return '$_temp0';
  }

  @override
  String get filterAny => 'الكل';

  @override
  String get filterAttachments => 'المرفقات';

  @override
  String get filterCategory => 'الفئة';

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
    return 'إزالة عامل التصفية $filter';
  }

  @override
  String get filterClearAll => 'مسح الكل';

  @override
  String get filterDate => 'التاريخ';

  @override
  String get filterNoCategory => 'بدون فئة';

  @override
  String get filterOneOffOnly => 'لمرة واحدة';

  @override
  String get filterPriority => 'الأولوية';

  @override
  String get filterRecurring => 'التكرار';

  @override
  String get filterRecurringOnly => 'متكرر';

  @override
  String get filterStatus => 'الحالة';

  @override
  String get filterTag => 'الوسم';

  @override
  String get filterText => 'النص';

  @override
  String get filterTextPrompt => 'يحتوي على النص';

  @override
  String get filterWithAttachments => 'مع مرفقات';

  @override
  String get filterWithoutAttachments => 'بدون مرفقات';

  @override
  String get galleryButtons => 'الأزرار';

  @override
  String get galleryChips => 'الشرائح والوسوم';

  @override
  String get galleryColors => 'ألوان الفئات';

  @override
  String get galleryConfirm => 'تأكيد';

  @override
  String get galleryContainer => 'فتح عنصر';

  @override
  String get galleryDarkTheme => 'المظهر الداكن';

  @override
  String get galleryDialogs => 'الحوارات والأوراق والمنتقيات';

  @override
  String get galleryDisabled => 'معطّل';

  @override
  String get galleryEmpty => 'لا توجد عناصر بصور';

  @override
  String get galleryFadeThrough => 'تلاشٍ متتابع';

  @override
  String get galleryFilters => 'عوامل التصفية';

  @override
  String get galleryIcons => 'الأيقونات';

  @override
  String get galleryInputs => 'حقول الإدخال';

  @override
  String get galleryLargeText => 'نص كبير (200٪)';

  @override
  String get galleryLayout => 'التخطيط المتجاوب';

  @override
  String get galleryMotion => 'الحركة';

  @override
  String get galleryOnlyImages => 'العناصر ذات الصور فقط';

  @override
  String galleryPicked(String value) {
    return 'المختار: $value';
  }

  @override
  String get galleryPriorities => 'الأولويات';

  @override
  String get galleryProgress => 'التقدم';

  @override
  String get galleryPrompt => 'إدخال نص';

  @override
  String get galleryReduceMotion => 'تقليل الحركة';

  @override
  String get galleryRows => 'الصفوف والصور الرمزية';

  @override
  String get galleryRtl => 'من اليمين إلى اليسار';

  @override
  String get gallerySampleText => 'نص تجريبي';

  @override
  String get gallerySharedAxis => 'محور مشترك';

  @override
  String get gallerySheet => 'ورقة سفلية';

  @override
  String get gallerySheetActions => 'ورقة مع إجراءات';

  @override
  String get gallerySheetBody => 'ورقة سفلية بنمط Everslot.';

  @override
  String get galleryStates => 'حالات الفراغ والخطأ والتحميل';

  @override
  String get galleryStatuses => 'الحالات';

  @override
  String get gallerySwipeHint => 'اسحب لعرض الإجراءات';

  @override
  String get galleryTitle => 'معرض المكونات';

  @override
  String get galleryUndoSnack => 'شريط التراجع';

  @override
  String get galleryWindowCompact => 'مضغوطة';

  @override
  String get galleryWindowExpanded => 'موسّعة';

  @override
  String get galleryWindowMedium => 'متوسطة';

  @override
  String galleryWindowSize(String size) {
    return 'النافذة: $size';
  }

  @override
  String get goalsAchieved => 'محقّقة';

  @override
  String goalsAchievedOn(String date) {
    return 'تحقّق في $date';
  }

  @override
  String get goalsActive => 'جارية';

  @override
  String get goalsAdd => 'إضافة هدف';

  @override
  String get goalsBadgeBackfillFreeMonth => 'شهر مسجّل في وقته';

  @override
  String get goalsBadgeChallenge => 'تحدٍّ مكتمل';

  @override
  String goalsBadgeCravings(int count) {
    return 'مقاومة $count رغبة';
  }

  @override
  String goalsBadgeEarnedOn(String date) {
    return 'اكتُسبت في $date';
  }

  @override
  String get goalsBadgeFirstCheckIn => 'أول تسجيل';

  @override
  String get goalsBadgeFirstPerfectDay => 'أول يوم مثالي';

  @override
  String get goalsBadgePerfectWeek => 'أسبوع مثالي';

  @override
  String goalsBadgeProgress(String value, String target) {
    return '$value من $target';
  }

  @override
  String get goalsBadgeShare => 'مشاركة';

  @override
  String get goalsBadgeShareDate => 'تضمين التاريخ';

  @override
  String get goalsBadgeShareHabit => 'تضمين اسم العادة';

  @override
  String goalsBadgeShareText(String name) {
    return 'حصلت على شارة «$name» في Everslot.';
  }

  @override
  String get goalsBadgeShareTitle => 'مشاركة شارة';

  @override
  String goalsBadgeStreak(int count) {
    return 'سلسلة $count يومًا';
  }

  @override
  String goalsBadgeTotal(String value) {
    return '$value مسجّلة';
  }

  @override
  String goalsBadgeUnlocked(String name) {
    return 'شارة جديدة: $name';
  }

  @override
  String get goalsBadgesEarned => 'المكتسبة';

  @override
  String get goalsBadgesEmpty => 'سجّل عادة لتحصل على أول شارة.';

  @override
  String get goalsBadgesLocked => 'للحصول عليها';

  @override
  String get goalsBadgesTitle => 'الشارات';

  @override
  String goalsCelebrate(String title) {
    return 'تحقّق الهدف: $title!';
  }

  @override
  String get goalsDelete => 'حذف الهدف';

  @override
  String get goalsDeleted => 'تم حذف الهدف';

  @override
  String get goalsEdit => 'تعديل الهدف';

  @override
  String get goalsEmpty => 'لا أهداف بعد';

  @override
  String get goalsEmptyBody => 'حدّد هدفًا لعادة — مثلًا 10 000 تمرين ضغط هذه السنة.';

  @override
  String get goalsEnded => 'منتهية';

  @override
  String get goalsErrDates => 'اختر تاريخ بداية وتاريخ نهاية.';

  @override
  String get goalsErrEnd => 'يجب أن تكون النهاية بعد البداية.';

  @override
  String get goalsErrMetric => 'هذا المقياس لا يناسب هذه العادة.';

  @override
  String get goalsErrScope => 'اختر موضوع الهدف.';

  @override
  String get goalsErrTarget => 'أدخل هدفًا أكبر من صفر.';

  @override
  String get goalsErrTitle => 'لا يزيد عن 80 حرفًا.';

  @override
  String goalsEta(String date) {
    return 'متوقَّع في $date';
  }

  @override
  String get goalsFrom => 'من';

  @override
  String get goalsHabit => 'العادة';

  @override
  String get goalsMetric => 'المقياس';

  @override
  String get goalsMetricCleanDays => 'أيام الامتناع';

  @override
  String get goalsMetricCompletions => 'الأيام المنجزة';

  @override
  String get goalsMetricItemsCompleted => 'العناصر المنجزة';

  @override
  String get goalsMetricMoneySaved => 'المال الموفَّر';

  @override
  String get goalsMetricStreakDays => 'السلسلة (أيام)';

  @override
  String get goalsMetricTotalValue => 'المجموع المسجّل';

  @override
  String get goalsMetricTrackedMinutes => 'الدقائق المتتبَّعة';

  @override
  String get goalsMetricUnitsAvoided => 'الوحدات التي تجنّبتها';

  @override
  String goalsNeedPerDay(String value) {
    return '$value يوميًا لإنهائه في الوقت';
  }

  @override
  String get goalsNew => 'هدف جديد';

  @override
  String get goalsPaceMarker => 'حيث يجب أن تكون اليوم';

  @override
  String get goalsPeriod => 'المدة';

  @override
  String get goalsPeriodAllTime => 'بلا حدّ زمني';

  @override
  String get goalsPeriodCustom => 'تواريخ مخصّصة';

  @override
  String get goalsPeriodMonth => 'هذا الشهر';

  @override
  String get goalsPeriodQuarter => 'هذا الربع';

  @override
  String get goalsPeriodWeek => 'هذا الأسبوع';

  @override
  String get goalsPeriodYear => 'هذه السنة';

  @override
  String goalsProgressOf(String actual, String target) {
    return '$actual من $target';
  }

  @override
  String get goalsSaved => 'تم حفظ الهدف';

  @override
  String get goalsStatusAchieved => 'تحقّق';

  @override
  String get goalsStatusAtRisk => 'في خطر';

  @override
  String get goalsStatusBehind => 'متأخر';

  @override
  String get goalsStatusOnTrack => 'على المسار';

  @override
  String goalsSuggestion(String value, String target) {
    return 'بهذا الإيقاع ستصل إلى $value — هل تستهدف $target؟';
  }

  @override
  String get goalsTarget => 'الهدف';

  @override
  String get goalsTitle => 'الأهداف';

  @override
  String get goalsTitleField => 'العنوان (اختياري)';

  @override
  String get goalsTo => 'إلى';

  @override
  String goalsUseSuggestion(String target) {
    return 'استهدف $target';
  }

  @override
  String get habitsActionAddValue => 'إضافة قيمة';

  @override
  String get habitsActionBackfill => 'تسجيل يوم آخر';

  @override
  String get habitsActionCheckNow => 'سجّل الآن';

  @override
  String get habitsActionClear => 'مسح';

  @override
  String get habitsActionDetails => 'التفاصيل';

  @override
  String get habitsActionDone => 'تم';

  @override
  String get habitsActionEdit => 'تعديل';

  @override
  String get habitsActionEditEntries => 'تعديل الإدخالات';

  @override
  String get habitsActionExcuse => 'عذر';

  @override
  String get habitsActionNotDone => 'لم أنجزها';

  @override
  String get habitsActionNoteMood => 'ملاحظة ومزاج';

  @override
  String get habitsActionPause => 'إيقاف مؤقت';

  @override
  String get habitsActionPauseTimer => 'إيقاف المؤقت مؤقتًا';

  @override
  String get habitsActionSkip => 'تخطٍّ';

  @override
  String get habitsActionStartTimer => 'تشغيل المؤقت';

  @override
  String get habitsActionStopTimer => 'إيقاف وتسجيل';

  @override
  String get habitsActionUndoDone => 'إلغاء التسجيل';

  @override
  String get habitsAdd => 'إضافة';

  @override
  String get habitsAddEntry => 'إضافة';

  @override
  String get habitsAddTime => 'إضافة وقت';

  @override
  String get habitsAdvancedTitle => 'متقدم';

  @override
  String get habitsAfterCompletionDueAfter => 'مستحقة مجددًا بعد';

  @override
  String get habitsAfterUnitDays => 'أيام';

  @override
  String get habitsAfterUnitMonths => 'أشهر';

  @override
  String get habitsAfterUnitWeeks => 'أسابيع';

  @override
  String get habitsAllDone => 'أنجزت كل شيء 🎉';

  @override
  String get habitsAllHabits => 'كل العادات';

  @override
  String get habitsAllStats => 'كل الإحصاءات';

  @override
  String get habitsApplyAll => 'كل السجل';

  @override
  String get habitsApplyAllWarn => 'ستتغير الإحصاءات السابقة.';

  @override
  String get habitsApplyDate => 'تاريخ تختاره…';

  @override
  String get habitsApplyTitle => 'تطبيق الجدول أو الهدف الجديد بدءًا من';

  @override
  String get habitsApplyToday => 'اليوم';

  @override
  String get habitsArchived => 'المؤرشفة';

  @override
  String get habitsArchivedSnack => 'تمت أرشفة العادة';

  @override
  String get habitsAskNote => 'اطلب ملاحظة ومزاجًا بعد التسجيل';

  @override
  String get habitsAtRisk => 'مهددة';

  @override
  String get habitsBestStreak => 'أفضل سلسلة';

  @override
  String get habitsCalendar => 'التقويم';

  @override
  String get habitsCelebratePerfectDay => 'يوم مثالي — أنجزت كل شيء!';

  @override
  String habitsCelebrateStreak(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم متتالٍ',
      many: '$count يومًا متتاليًا',
      few: '$count أيام متتالية',
      two: 'يومان متتاليان',
      one: 'يوم واحد متتالٍ',
    );
    return '$name: $_temp0!';
  }

  @override
  String get habitsCelebrationDismiss => 'إغلاق';

  @override
  String habitsCellSemantics(String habit, String date, String status) {
    return '$habit، $date: $status';
  }

  @override
  String habitsChallengeBestStreak(String streak) {
    return 'أفضل سلسلة: $streak';
  }

  @override
  String get habitsChallengeClose => 'إغلاق';

  @override
  String get habitsChallengeContinued => 'أصبحت عادة مستمرة الآن';

  @override
  String habitsChallengeDay(int day, int total) {
    return 'اليوم $day من $total';
  }

  @override
  String habitsChallengeDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقي $count يوم',
      many: 'بقي $count يومًا',
      few: 'بقيت $count أيام',
      two: 'بقي يومان',
      one: 'بقي يوم واحد',
      zero: 'آخر يوم',
    );
    return '$_temp0';
  }

  @override
  String get habitsChallengeEveryDay => 'كل يوم مجدول';

  @override
  String get habitsChallengeKeepGoing => 'واصل';

  @override
  String get habitsChallengeKeepGoingHint => 'اجعلها عادة مستمرة — يبقى سجلّك محفوظًا.';

  @override
  String habitsChallengeMinRatio(String percent) {
    return '$percent من الأيام على الأقل';
  }

  @override
  String get habitsChallengeMissedBody => 'لم تسر كل الأيام كما خُطط لها — لكنك حضرت. أعد المحاولة أو واصل.';

  @override
  String get habitsChallengeMissedTitle => 'انتهى التحدّي';

  @override
  String habitsChallengeProgress(int done, int due) {
    return '$done من $due أيام منجزة';
  }

  @override
  String get habitsChallengeRuleTitle => 'للنجاح';

  @override
  String get habitsChallengeSuccessTitle => 'اكتمل التحدّي!';

  @override
  String get habitsChallengeTitle => 'التحدّي';

  @override
  String habitsChallengeVolume(String value) {
    return 'المجموع: $value';
  }

  @override
  String get habitsCompactRows => 'صفوف مضغوطة';

  @override
  String habitsCounts(int done, int notDone, int missed, int skipped) {
    return 'منجزة $done · غير منجزة $notDone · فائتة $missed · متخطاة $skipped';
  }

  @override
  String get habitsCreateQuitInstead => 'إنشاء متابعة إقلاع';

  @override
  String get habitsCurrentStreak => 'السلسلة الحالية';

  @override
  String get habitsDatesTitle => 'التواريخ';

  @override
  String get habitsDayStateLabel => 'الحالة';

  @override
  String habitsDays(int count) {
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
  String habitsDecrease(String step) {
    return 'إزالة $step';
  }

  @override
  String get habitsDeleteBody => 'ينتقل سجلها معها إلى سلة المهملات. يمكنك استعادتها خلال 30 يومًا.';

  @override
  String get habitsDeleteEntry => 'حذف الإدخال';

  @override
  String habitsDeleteTitle(String name) {
    return 'حذف «$name»؟';
  }

  @override
  String get habitsDeletedSnack => 'تم حذف العادة';

  @override
  String habitsDragHandle(String name) {
    return 'نقل $name';
  }

  @override
  String get habitsEditCustom => 'تعديل الجدول';

  @override
  String get habitsEditEntry => 'تعديل الإدخال';

  @override
  String get habitsEditorEditTitle => 'تعديل العادة';

  @override
  String get habitsEditorNewTitle => 'عادة جديدة';

  @override
  String get habitsEmptyAction => 'إنشاء عادة';

  @override
  String get habitsEmptyBody => 'أنشئ عادة — مثل 15 تمرين ضغط يوميًا — وسجّل كل يوم إن كنت قد أنجزتها.';

  @override
  String get habitsEmptyTitle => 'لا توجد عادات بعد';

  @override
  String get habitsEndNever => 'أبدًا';

  @override
  String get habitsEntries => 'الإدخالات';

  @override
  String get habitsEntryDeleted => 'تم حذف الإدخال';

  @override
  String get habitsErrDuration => 'يجب أن تكون المدة بين دقيقة واحدة و24 ساعة';

  @override
  String get habitsErrEnd => 'تاريخ النهاية يسبق تاريخ البداية';

  @override
  String get habitsErrFreezes => 'بين 0 و31 تجميدًا شهريًا';

  @override
  String get habitsErrLimitNeedsMeasurable => '«على الأكثر» يتطلب عددًا أو مدة أو قيمة';

  @override
  String get habitsErrNameEmpty => 'أدخل اسمًا';

  @override
  String get habitsErrNameTooLong => 'الاسم طويل جدًا (80 حرفًا كحد أقصى)';

  @override
  String get habitsErrSchedule => 'هذا الجدول غير صالح';

  @override
  String get habitsErrSectionName => 'يجب أن يتكون الاسم من 1 إلى 40 حرفًا';

  @override
  String get habitsErrTarget => 'أدخل هدفًا أكبر من 0';

  @override
  String get habitsErrUnit => 'يجب أن تتكون الوحدة من 1 إلى 20 حرفًا';

  @override
  String get habitsErrorArchived => 'هذه العادة مؤرشفة.';

  @override
  String get habitsErrorFuture => 'لا يمكن التسجيل قبل البدء — يمكنك تخطيها أو تسجيل عذر.';

  @override
  String habitsEveryNDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'كل $n يوم',
      many: 'كل $n يومًا',
      few: 'كل $n أيام',
      two: 'يومًا بعد يوم',
    );
    return '$_temp0';
  }

  @override
  String get habitsFieldCategory => 'الفئة';

  @override
  String get habitsFieldColor => 'اللون';

  @override
  String get habitsFieldDescription => 'الوصف';

  @override
  String get habitsFieldEnd => 'النهاية';

  @override
  String get habitsFieldIcon => 'الأيقونة';

  @override
  String get habitsFieldName => 'الاسم';

  @override
  String get habitsFieldNameHint => 'مثال: 15 تمرين ضغط';

  @override
  String get habitsFieldSection => 'القسم';

  @override
  String get habitsFieldStart => 'البداية';

  @override
  String get habitsFieldTarget => 'الهدف';

  @override
  String get habitsFieldUnit => 'الوحدة';

  @override
  String get habitsFilterAll => 'الكل';

  @override
  String get habitsFilterDue => 'المستحقة';

  @override
  String get habitsFor30Days => 'لمدة 30 يومًا';

  @override
  String get habitsFreezes => 'مرات تجميد السلسلة شهريًا';

  @override
  String get habitsFromTemplate => 'من قالب';

  @override
  String get habitsFutureOnlyPlanned => 'يمكن التخطيط للتخطي والأعذار فقط في الأيام القادمة.';

  @override
  String get habitsGoalExampleCheck => 'أنجزتها أم لا';

  @override
  String get habitsGoalExampleCount => '15 تمرين ضغط';

  @override
  String get habitsGoalExampleDuration => 'القراءة 20 دقيقة';

  @override
  String get habitsGoalExampleNumeric => 'الجري 5 كم';

  @override
  String habitsGoalSentence(String op, String amount) {
    return '$op $amount';
  }

  @override
  String get habitsGoalTitle => 'الهدف';

  @override
  String get habitsGoalTypeCheck => 'نعم / لا';

  @override
  String get habitsGoalTypeCount => 'عدد';

  @override
  String get habitsGoalTypeDuration => 'مدة';

  @override
  String get habitsGoalTypeNumeric => 'قيمة رقمية';

  @override
  String get habitsGroupByCategory => 'الفئة';

  @override
  String get habitsGroupByNone => 'بدون';

  @override
  String get habitsGroupBySection => 'الفترة';

  @override
  String get habitsGroupByTitle => 'التجميع حسب';

  @override
  String habitsGroupNotDue(int count) {
    return 'غير مستحقة اليوم ($count)';
  }

  @override
  String get habitsHideNotDue => 'إخفاء العادات غير المستحقة';

  @override
  String get habitsHoldRingHint => 'اضغط مطوّلًا لوضع علامة تم';

  @override
  String get habitsHoldToComplete => 'الضغط المطوّل للإنجاز';

  @override
  String get habitsHoldToCompleteHint => 'اضغط مطوّلًا على الحلقة لتسجيل العادة وتجنّب النقرات غير المقصودة.';

  @override
  String habitsIncrease(String step) {
    return 'إضافة $step';
  }

  @override
  String get habitsIncrementStep => 'الخطوة';

  @override
  String get habitsJournal => 'دفتر الملاحظات';

  @override
  String get habitsJournalEmpty => 'لا توجد ملاحظات بعد';

  @override
  String get habitsJournalEmptyBody => 'تظهر هنا الملاحظات والحالات المزاجية التي تضيفها عند التسجيل.';

  @override
  String get habitsLast90 => 'آخر 90 يومًا';

  @override
  String get habitsLastDay => 'آخر يوم';

  @override
  String habitsLeftOfLimit(String left, String limit) {
    return 'متبقٍ $left من $limit';
  }

  @override
  String get habitsLimitZeroHint => 'حد قدره 0 يعني الإقلاع التام.';

  @override
  String get habitsManage => 'إدارة العادات';

  @override
  String get habitsMatrixTapTitle => 'النقر على يوم في عرض الأسبوع';

  @override
  String get habitsMinPerDay => 'الحد الأدنى يوميًا';

  @override
  String habitsMinutesValue(int minutes) {
    return '$minutes د';
  }

  @override
  String get habitsMood1 => 'سيئ جدًا';

  @override
  String get habitsMood2 => 'سيئ';

  @override
  String get habitsMood3 => 'مقبول';

  @override
  String get habitsMood4 => 'جيد';

  @override
  String get habitsMood5 => 'ممتاز';

  @override
  String get habitsMoodLabel => 'المزاج';

  @override
  String get habitsMoodTrend => 'اتجاه المزاج';

  @override
  String get habitsMoveToSection => 'نقل إلى قسم…';

  @override
  String get habitsNewHabit => 'عادة جديدة';

  @override
  String get habitsNewQuit => 'متابعة إقلاع جديدة';

  @override
  String get habitsNewer => 'أيام لاحقة';

  @override
  String get habitsNextDay => 'اليوم التالي';

  @override
  String get habitsNextMonth => 'الشهر التالي';

  @override
  String get habitsNextYear => 'السنة التالية';

  @override
  String get habitsNoBuildHabits => 'لا توجد عادة لتسجيلها بعد';

  @override
  String get habitsNoCategory => 'بدون فئة';

  @override
  String get habitsNoEntries => 'لا توجد إدخالات بعد';

  @override
  String get habitsNone => 'لا شيء';

  @override
  String get habitsNotActiveThatDay => 'لم تكن هذه العادة نشطة في ذلك اليوم.';

  @override
  String get habitsNotEnoughData => 'لا توجد بيانات كافية بعد';

  @override
  String get habitsNoteHint => 'كيف سارت الأمور؟';

  @override
  String get habitsNoteMoodTitle => 'ملاحظة ومزاج';

  @override
  String get habitsNothingThisDay => 'لا شيء مجدول في هذا اليوم';

  @override
  String get habitsNothingThisDayBody => 'تظهر العادات هنا في الأيام المستحقة فيها.';

  @override
  String get habitsNotifGone => 'لم تعد هذه العادة موجودة.';

  @override
  String habitsNotifInvalidValue(String input) {
    return '«$input» ليس رقمًا — افتح التطبيق لتسجيله.';
  }

  @override
  String get habitsOlder => 'أيام سابقة';

  @override
  String get habitsOnlyOn => 'فقط في (اختياري)';

  @override
  String get habitsOpAtLeast => 'على الأقل';

  @override
  String get habitsOpAtMost => 'على الأكثر';

  @override
  String get habitsOpExactly => 'بالضبط';

  @override
  String habitsOrdinal(String which) {
    String _temp0 = intl.Intl.selectLogic(which, {
      'first': 'الأول',
      'second': 'الثاني',
      'third': 'الثالث',
      'fourth': 'الرابع',
      'other': 'الأخير',
    });
    return '$_temp0';
  }

  @override
  String get habitsOverLimit => 'تجاوزت الحد';

  @override
  String get habitsOverdue => 'متأخرة';

  @override
  String get habitsPauseAction => 'إيقاف مؤقت';

  @override
  String habitsPauseDays(int count) {
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
  String get habitsPauseHint => 'أيام الإيقاف محايدة: لا تُحتسب فائتة ولا تقطع السلسلة أبدًا.';

  @override
  String get habitsPauseIndefinitely => 'إلى أجل غير مسمى';

  @override
  String get habitsPauseTitle => 'إيقاف العادة مؤقتًا';

  @override
  String get habitsPauseToday => 'اليوم';

  @override
  String get habitsPauseUntil => 'حتى تاريخ…';

  @override
  String habitsPauseUntilDate(String date) {
    return 'حتى $date';
  }

  @override
  String get habitsPauseWeek => 'أسبوع واحد';

  @override
  String get habitsPausedIndefinitely => 'متوقفة مؤقتًا';

  @override
  String get habitsPausedSnack => 'تم الإيقاف المؤقت';

  @override
  String habitsPausedUntil(String date) {
    return 'متوقفة مؤقتًا حتى $date';
  }

  @override
  String habitsPerfectDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم مثالي',
      many: '$count يومًا مثاليًا',
      few: '$count أيام مثالية',
      two: 'يومان مثاليان',
      one: 'يوم مثالي واحد',
      zero: 'لا يوجد يوم مثالي بعد',
    );
    return '$_temp0';
  }

  @override
  String get habitsPickDuration => 'اختر مدة';

  @override
  String get habitsPresetAfterCompletion => 'بعد الإنجاز';

  @override
  String get habitsPresetCustom => 'مخصص…';

  @override
  String get habitsPresetDaily => 'كل يوم';

  @override
  String get habitsPresetEveryNDays => 'كل N أيام';

  @override
  String get habitsPresetInterval => 'كل N ساعات';

  @override
  String get habitsPresetMonthlyDay => 'شهريًا في يوم محدد';

  @override
  String get habitsPresetMonthlyWeekday => 'شهريًا في يوم من الأسبوع';

  @override
  String get habitsPresetSpecificDays => 'أيام محددة';

  @override
  String get habitsPresetSpecificTimes => 'في أوقات محددة';

  @override
  String get habitsPresetTimesPerDay => 'N مرات يوميًا';

  @override
  String get habitsPresetTimesPerMonth => 'N مرات شهريًا';

  @override
  String get habitsPresetTimesPerWeek => 'N مرات أسبوعيًا';

  @override
  String get habitsPresetWeekdays => 'أيام العمل';

  @override
  String get habitsPresetWeekends => 'عطلة نهاية الأسبوع';

  @override
  String get habitsPrevDay => 'اليوم السابق';

  @override
  String get habitsPreviewNext => 'القادمة';

  @override
  String get habitsPreviewTitle => 'معاينة';

  @override
  String get habitsPreviousMonth => 'الشهر السابق';

  @override
  String get habitsPreviousYear => 'السنة السابقة';

  @override
  String get habitsProgressionEvery => 'كل';

  @override
  String get habitsProgressionHint => 'يبدأ من الهدف ويضيف خطوة بانتظام طوال التحدّي.';

  @override
  String get habitsProgressionMax => 'حتى (0 = بلا حد)';

  @override
  String get habitsProgressionStep => 'الإضافة في كل مرة';

  @override
  String get habitsProgressionTitle => 'زيادة الهدف تدريجيًا';

  @override
  String habitsProgressionToday(String value) {
    return 'هدف اليوم: $value';
  }

  @override
  String get habitsQuickValues => 'قيم سريعة';

  @override
  String get habitsQuickValuesHint => 'مثال: 5 10 15';

  @override
  String habitsQuotaMonth(int done, int times) {
    return '$done من $times هذا الشهر';
  }

  @override
  String habitsQuotaWeek(int done, int times) {
    return '$done من $times هذا الأسبوع';
  }

  @override
  String get habitsRate30 => 'نسبة 30 يومًا';

  @override
  String get habitsReasonOptional => 'السبب (اختياري)';

  @override
  String get habitsRecentEntries => 'الإدخالات الأخيرة';

  @override
  String habitsRecordAbstinence(String value) {
    return 'أطول فترة امتناع على الإطلاق: $value';
  }

  @override
  String habitsRecordBestDay(String value) {
    return 'أفضل يوم على الإطلاق: $value';
  }

  @override
  String habitsRecordBestWeek(String value) {
    return 'أفضل أسبوع على الإطلاق: $value';
  }

  @override
  String habitsRecordCravings(int count) {
    return 'أكثر رغبات قاومتها في يوم: $count';
  }

  @override
  String get habitsRecordNew => 'رقم قياسي جديد!';

  @override
  String habitsRecordStreak(String value) {
    return 'أطول سلسلة على الإطلاق: $value';
  }

  @override
  String get habitsReorder => 'إعادة الترتيب';

  @override
  String get habitsReorderDone => 'تم';

  @override
  String get habitsReorderHint => 'اسحب المقابض لتغيير الترتيب.';

  @override
  String get habitsReordered => 'تم حفظ الترتيب';

  @override
  String get habitsRequireExplicit => 'يُحتسب اليوم الفارغ فائتًا';

  @override
  String get habitsResume => 'استئناف';

  @override
  String get habitsResumedSnack => 'تم الاستئناف';

  @override
  String get habitsRollupAll => 'يجب إنجاز كل التسجيلات';

  @override
  String habitsRollupMin(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n تسجيل على الأقل',
      many: '$n تسجيلًا على الأقل',
      few: '$n تسجيلات على الأقل',
      two: 'تسجيلان على الأقل',
      one: 'تسجيل واحد على الأقل',
    );
    return '$_temp0';
  }

  @override
  String get habitsRollupMinCount => 'التسجيلات المطلوبة';

  @override
  String get habitsRollupMinTitle => 'يُحتسب اليوم عند إنجاز بعض التسجيلات';

  @override
  String get habitsSavedSnack => 'تم الحفظ';

  @override
  String get habitsScheduleTitle => 'الجدول';

  @override
  String get habitsSectionAfternoon => 'بعد الظهر';

  @override
  String get habitsSectionAnytime => 'في أي وقت';

  @override
  String get habitsSectionDeleteBody => 'تنتقل عاداته إلى «في أي وقت».';

  @override
  String get habitsSectionDeleteTitle => 'حذف هذا القسم؟';

  @override
  String get habitsSectionDeleted => 'تم حذف القسم';

  @override
  String get habitsSectionEdit => 'تعديل القسم';

  @override
  String get habitsSectionEvening => 'المساء';

  @override
  String get habitsSectionMorning => 'الصباح';

  @override
  String get habitsSectionNew => 'قسم جديد';

  @override
  String get habitsSectionNone => 'أخرى';

  @override
  String habitsSectionProgress(int done, int total) {
    return '$done / $total منجزة';
  }

  @override
  String get habitsSectionWindow => 'الفترة الزمنية';

  @override
  String get habitsSections => 'الأقسام';

  @override
  String get habitsShowStreaks => 'إظهار السلاسل';

  @override
  String get habitsSkipBreaks => 'تقطع السلسلة';

  @override
  String get habitsSkipNeutral => 'لا تقطع السلسلة';

  @override
  String get habitsSkipPolicy => 'الأيام المتخطاة';

  @override
  String habitsSlotsProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String habitsSnackCleared(String name) {
    return 'تم مسح «$name»';
  }

  @override
  String habitsSnackDone(String name) {
    return 'تم إنجاز «$name»';
  }

  @override
  String habitsSnackExcused(String name) {
    return 'سُجّل عذر لـ«$name»';
  }

  @override
  String habitsSnackLogged(String amount, String name) {
    return 'تم تسجيل $amount · $name';
  }

  @override
  String habitsSnackNotDone(String name) {
    return 'سُجّلت «$name» كغير منجزة';
  }

  @override
  String habitsSnackSkipped(String name) {
    return 'تم تخطي «$name»';
  }

  @override
  String get habitsStatusDone => 'منجزة';

  @override
  String get habitsStatusExcused => 'معذورة';

  @override
  String get habitsStatusFailed => 'غير منجزة';

  @override
  String get habitsStatusFrozen => 'مجمّدة';

  @override
  String get habitsStatusMissed => 'فائتة';

  @override
  String get habitsStatusNotDue => 'غير مستحقة';

  @override
  String get habitsStatusPartial => 'منجزة جزئيًا';

  @override
  String get habitsStatusPaused => 'متوقفة مؤقتًا';

  @override
  String get habitsStatusPending => 'قيد الانتظار';

  @override
  String get habitsStatusSkipped => 'متخطاة';

  @override
  String habitsStreakSemantics(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'سلسلة $days يوم',
      many: 'سلسلة $days يومًا',
      few: 'سلسلة $days أيام',
      two: 'سلسلة يومين',
      one: 'سلسلة يوم واحد',
      zero: 'سلسلة 0 يوم',
    );
    return '$_temp0';
  }

  @override
  String get habitsStrength => 'القوة';

  @override
  String get habitsTapCycleDoneFail => 'تم ← لم يتم ← مسح';

  @override
  String get habitsTapCycleDoneOnly => 'تم ← مسح';

  @override
  String get habitsTapCycleDoneSkip => 'تم ← تخطٍّ ← مسح';

  @override
  String get habitsTemplatesChallenges => 'التحديات';

  @override
  String get habitsTemplatesHabits => 'العادات';

  @override
  String get habitsTemplatesQuit => 'الإقلاع';

  @override
  String get habitsTemplatesTitle => 'القوالب';

  @override
  String habitsTimerElapsed(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة',
      many: '$minutes دقيقة',
      few: '$minutes دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return 'المؤقت: $_temp0';
  }

  @override
  String habitsTimesPerDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n مرة يوميًا',
      many: '$n مرة يوميًا',
      few: '$n مرات يوميًا',
      two: 'مرتان يوميًا',
      one: 'مرة يوميًا',
    );
    return '$_temp0';
  }

  @override
  String habitsTimesPerMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n مرة شهريًا',
      many: '$n مرة شهريًا',
      few: '$n مرات شهريًا',
      two: 'مرتان شهريًا',
      one: 'مرة شهريًا',
    );
    return '$_temp0';
  }

  @override
  String habitsTimesPerWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n مرة أسبوعيًا',
      many: '$n مرة أسبوعيًا',
      few: '$n مرات أسبوعيًا',
      two: 'مرتان أسبوعيًا',
      one: 'مرة أسبوعيًا',
    );
    return '$_temp0';
  }

  @override
  String get habitsToday => 'اليوم';

  @override
  String get habitsToggleShortPress => 'التبديل بنقرة قصيرة';

  @override
  String get habitsToggleShortPressHint => 'عند الإيقاف: الضغط المطوّل يبدّل الحالة والنقرة القصيرة تفتح اليوم.';

  @override
  String get habitsTolerance => 'نافذة التسجيل المبكر';

  @override
  String habitsTotalOfTarget(String total, String target) {
    return 'المجموع $total من $target';
  }

  @override
  String get habitsTplChallengeMeditate => '14 يومًا من التأمل';

  @override
  String get habitsTplChallengeMeditateDesc => '10 دقائق يوميًا لمدة 14 يومًا';

  @override
  String get habitsTplChallengeNoSugar => '21 يومًا بلا سكر';

  @override
  String get habitsTplChallengeNoSugarDesc => 'كل يوم لمدة 21 يومًا';

  @override
  String get habitsTplChallengePushUps => '30 يومًا من تمارين الضغط';

  @override
  String get habitsTplChallengePushUpsDesc => '20 تكرارًا يوميًا لمدة 30 يومًا';

  @override
  String get habitsTplCoffeeLimit => 'قهوتان على الأكثر';

  @override
  String get habitsTplCoffeeLimitDesc => 'حد يومي';

  @override
  String get habitsTplGym => 'النادي الرياضي';

  @override
  String get habitsTplGymDesc => '3 مرات أسبوعيًا، في أي أيام';

  @override
  String get habitsTplJournal => 'كتابة اليوميات';

  @override
  String get habitsTplJournalDesc => 'نعم / لا، كل مساء';

  @override
  String get habitsTplMeditate => 'التأمل';

  @override
  String get habitsTplMeditateDesc => '10 دقائق يوميًا';

  @override
  String get habitsTplPushUps => '15 تمرين ضغط';

  @override
  String get habitsTplPushUpsDesc => 'عدد ≥ 15 تكرارًا، كل يوم';

  @override
  String get habitsTplRead => 'القراءة';

  @override
  String get habitsTplReadDesc => '20 دقيقة يوميًا';

  @override
  String get habitsTplSleepEarly => 'النوم قبل الساعة 23:00';

  @override
  String get habitsTplSleepEarlyDesc => 'نعم / لا، كل يوم';

  @override
  String get habitsTplStretch => 'تمارين الإطالة';

  @override
  String get habitsTplStretchDesc => 'كل ساعة من 09:00 إلى 18:00 (6 من 10)';

  @override
  String get habitsTplWalk => 'المشي';

  @override
  String get habitsTplWalkDesc => '5 كم يوميًا';

  @override
  String get habitsTplWater => 'شرب الماء';

  @override
  String get habitsTplWaterDesc => '8 أكواب يوميًا';

  @override
  String get habitsTypeBuild => 'بناء عادة';

  @override
  String get habitsTypeQuit => 'الإقلاع عن شيء';

  @override
  String get habitsUnarchive => 'إلغاء الأرشفة';

  @override
  String get habitsUnarchivedSnack => 'تمت استعادة العادة';

  @override
  String habitsUnitCigarettes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سيجارة',
      many: 'سيجارة',
      few: 'سجائر',
      two: 'سيجارتان',
      one: 'سيجارة',
      zero: 'سيجارة',
    );
    return '$_temp0';
  }

  @override
  String habitsUnitCups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فنجان',
      many: 'فنجانًا',
      few: 'فناجين',
      two: 'فنجانان',
      one: 'فنجان',
      zero: 'فنجان',
    );
    return '$_temp0';
  }

  @override
  String get habitsUnitCustom => 'مخصص…';

  @override
  String habitsUnitDrinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مشروب',
      many: 'مشروبًا',
      few: 'مشروبات',
      two: 'مشروبان',
      one: 'مشروب',
      zero: 'مشروب',
    );
    return '$_temp0';
  }

  @override
  String habitsUnitGlasses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'كوب',
      many: 'كوبًا',
      few: 'أكواب',
      two: 'كوبان',
      one: 'كوب',
      zero: 'كوب',
    );
    return '$_temp0';
  }

  @override
  String get habitsUnitH => 'س';

  @override
  String habitsUnitJoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سيجارة حشيش',
      many: 'سيجارة حشيش',
      few: 'سجائر حشيش',
      two: 'سيجارتا حشيش',
      one: 'سيجارة حشيش',
      zero: 'سيجارة حشيش',
    );
    return '$_temp0';
  }

  @override
  String get habitsUnitKcal => 'سعرة';

  @override
  String get habitsUnitKm => 'كم';

  @override
  String get habitsUnitL => 'ل';

  @override
  String get habitsUnitMi => 'ميل';

  @override
  String get habitsUnitMin => 'د';

  @override
  String get habitsUnitMl => 'مل';

  @override
  String habitsUnitPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'صفحة',
      many: 'صفحة',
      few: 'صفحات',
      two: 'صفحتان',
      one: 'صفحة',
      zero: 'صفحة',
    );
    return '$_temp0';
  }

  @override
  String habitsUnitReps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تكرار',
      many: 'تكرارًا',
      few: 'تكرارات',
      two: 'تكراران',
      one: 'تكرار',
      zero: 'تكرار',
    );
    return '$_temp0';
  }

  @override
  String habitsUnitServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حصة',
      many: 'حصة',
      few: 'حصص',
      two: 'حصتان',
      one: 'حصة',
      zero: 'حصة',
    );
    return '$_temp0';
  }

  @override
  String habitsUnitSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'جلسة',
      many: 'جلسة',
      few: 'جلسات',
      two: 'جلستان',
      one: 'جلسة',
      zero: 'جلسة',
    );
    return '$_temp0';
  }

  @override
  String habitsUnitSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'خطوة',
      many: 'خطوة',
      few: 'خطوات',
      two: 'خطوتان',
      one: 'خطوة',
      zero: 'خطوة',
    );
    return '$_temp0';
  }

  @override
  String habitsUnitTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مرة',
      many: 'مرة',
      few: 'مرات',
      two: 'مرتان',
      one: 'مرة',
      zero: 'مرة',
    );
    return '$_temp0';
  }

  @override
  String get habitsVacationIndefinitely => 'وضع العطلة مفعّل';

  @override
  String get habitsVacationTitle => 'وضع العطلة';

  @override
  String habitsVacationUntil(String date) {
    return 'وضع العطلة حتى $date';
  }

  @override
  String get habitsValueHint => 'الكمية';

  @override
  String get habitsValueInvalid => 'أدخل رقمًا أكبر من 0';

  @override
  String get habitsValueTitle => 'تسجيل قيمة';

  @override
  String get habitsViewMonth => 'الشهر';

  @override
  String get habitsViewOptions => 'خيارات العرض';

  @override
  String get habitsViewToday => 'اليوم';

  @override
  String get habitsViewWeek => 'الأسبوع';

  @override
  String get habitsViewYear => 'السنة';

  @override
  String habitsWarnManySlots(int count) {
    return '$count تسجيلًا في اليوم — هذا كثير.';
  }

  @override
  String get habitsWarnNeverDue => 'لا يتضمن هذا الجدول أي يوم قادم.';

  @override
  String habitsWeekOf(String date) {
    return 'أسبوع $date';
  }

  @override
  String get habitsWindowFrom => 'من';

  @override
  String get habitsWindowTo => 'إلى';

  @override
  String get habitsYear => 'السنة';

  @override
  String habitsYearSummary(int done, int scheduled, String year) {
    return 'أُنجزت في $done من أصل $scheduled يومًا مجدولًا في $year';
  }

  @override
  String habitsZoneFixed(String zone) {
    return 'استخدم دائمًا $zone';
  }

  @override
  String habitsZoneFixedHint(String zone) {
    return 'تتبع الأيام $zone أينما كنت';
  }

  @override
  String get habitsZoneFloating => 'تتبع الأيام منطقتك الزمنية الحالية';

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
  String importMoreLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…و$count عنصر آخر',
      many: '…و$count عنصرًا آخر',
      few: '…و$count عناصر أخرى',
      two: '…وعنصران آخران',
      one: '…وعنصر آخر',
    );
    return '$_temp0';
  }

  @override
  String get importPasteHint => 'الصق نصًا بمسافات بادئة أو Markdown أو OPML';

  @override
  String get importSplit => 'التقسيم إلى عناصر (مع الحفاظ على التفرع)';

  @override
  String importSplitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'التقسيم إلى $count عنصر (مع الحفاظ على التداخل)',
      many: 'التقسيم إلى $count عنصرًا (مع الحفاظ على التداخل)',
      few: 'التقسيم إلى $count عناصر (مع الحفاظ على التداخل)',
      two: 'التقسيم إلى عنصرين (مع الحفاظ على التداخل)',
      one: 'التقسيم إلى عنصر واحد (مع الحفاظ على التداخل)',
    );
    return '$_temp0';
  }

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
  String get integrationsActionFailed => 'تعذّر إتمام هذا الإجراء.';

  @override
  String integrationsHabitLogged(String habit) {
    return 'تم التسجيل: $habit';
  }

  @override
  String integrationsHabitNotFound(String name) {
    return 'لا توجد عادة تطابق «$name».';
  }

  @override
  String get integrationsLinkInTrash => 'هذا العنصر موجود في سلة المهملات.';

  @override
  String get integrationsLinkNotFound => 'لا يمكن فتح هذا الرابط في Everslot.';

  @override
  String get integrationsNothingNext => 'لا شيء آخر مخطط له اليوم.';

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
  String itemScheduledAs(String title) {
    return 'مُجدول: $title';
  }

  @override
  String get itemScheduledBadge => 'مُجدول كمهمة';

  @override
  String get itemText => 'النص';

  @override
  String get itemThisDevice => 'هذا الجهاز';

  @override
  String get itemTimeInStatus => 'الوقت في كل حالة';

  @override
  String get itemsColAge => 'المدة';

  @override
  String get itemsColAttachments => 'الملفات';

  @override
  String get itemsColChecklist => 'القائمة';

  @override
  String get itemsColDue => 'الاستحقاق';

  @override
  String get itemsColFollowUp => 'المتابعة';

  @override
  String get itemsColPath => 'المسار';

  @override
  String get itemsColPriority => 'الأولوية';

  @override
  String get itemsColStatus => 'الحالة';

  @override
  String get itemsColText => 'العنصر';

  @override
  String get itemsTableEmpty => 'لا توجد عناصر مطابقة';

  @override
  String get itemsTableFilterHint => 'التصفية حسب النص أو القائمة أو المسار';

  @override
  String get itemsTableOpen => 'كل العناصر (جدول)';

  @override
  String get itemsTableSelectAll => 'تحديد كل العناصر المعروضة';

  @override
  String itemsTableSelectRow(String item) {
    return 'تحديد $item';
  }

  @override
  String itemsTableSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر محدد',
      many: '$count عنصرًا محددًا',
      few: '$count عناصر محددة',
      two: 'عنصران محددان',
      one: 'عنصر واحد محدد',
      zero: 'لا شيء محدد',
    );
    return '$_temp0';
  }

  @override
  String itemsTableSortBy(String column) {
    return 'الترتيب حسب $column';
  }

  @override
  String itemsTableStatusChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحديث $count عنصر',
      many: 'تم تحديث $count عنصرًا',
      few: 'تم تحديث $count عناصر',
      two: 'تم تحديث عنصرين',
      one: 'تم تحديث عنصر واحد',
      zero: 'لم يُحدَّث شيء',
    );
    return '$_temp0';
  }

  @override
  String get itemsTableTitle => 'كل العناصر';

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
  String get linkKindChecklist => 'قائمة';

  @override
  String get linkKindChecklistItem => 'عنصر قائمة';

  @override
  String get linkKindHabit => 'عادة';

  @override
  String get linkKindHabitLog => 'ملاحظة عادة';

  @override
  String get linkKindTask => 'مهمة';

  @override
  String get linkedCompleteAction => 'إكمال';

  @override
  String linkedCompleteItemBody(String item) {
    return '«$item» مُجدول بهذه المهمة.';
  }

  @override
  String get linkedCompleteItemTitle => 'إكمال عنصر القائمة أيضًا؟';

  @override
  String linkedCompleteTaskBody(String task) {
    return '«$task» تُجدول هذا العنصر.';
  }

  @override
  String get linkedCompleteTaskTitle => 'وضع علامة منجزة على المهمة أيضًا؟';

  @override
  String get linkedEntityMissing => 'محذوف';

  @override
  String linkedEntitySemantics(String kind, String title, String status) {
    return '$kind: $title، $status. يفتحه';
  }

  @override
  String get linkedEntityUntitled => 'بلا عنوان';

  @override
  String get listsAllLists => 'كل القوائم';

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
  String get listsEditLabels => 'تعديل التصنيفات';

  @override
  String get listsEmptyAction => 'أنشئ قائمتك الأولى';

  @override
  String get listsEmptyMessage => 'قوائم وملاحظات وروتين — بتفرّع بالعمق الذي تحتاجه.';

  @override
  String get listsEmptyTitle => 'لا توجد قوائم بعد';

  @override
  String get listsFilterAnyLabel => 'أي تصنيف';

  @override
  String get listsFilterColor => 'اللون';

  @override
  String get listsFilterHasAttachments => 'بها مرفقات';

  @override
  String get listsFilterHasBlocked => 'قيد الانتظار أو محظور';

  @override
  String get listsFilterHasDue => 'ذات مواعيد استحقاق';

  @override
  String get listsFilterLabel => 'تصنيف';

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
  String listsLabelFilterActive(String label) {
    return 'القوائم ذات التصنيف $label';
  }

  @override
  String listsLabelSemantics(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قائمة',
      many: '$count قائمة',
      few: '$count قوائم',
      two: 'قائمتان',
      one: 'قائمة واحدة',
      zero: 'لا قوائم',
    );
    return '$label، $_temp0';
  }

  @override
  String get listsListView => 'عرض قائمة';

  @override
  String get listsMoveItems => 'نقل العناصر…';

  @override
  String get listsNewChecklist => 'قائمة جديدة';

  @override
  String get listsNewNote => 'ملاحظة جديدة';

  @override
  String get listsNoLabels => 'لا توجد تصنيفات بعد';

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
  String get localOnlyBanner => 'مزامنة السحابة غير مُعدّة — بياناتك تبقى على هذا الجهاز.';

  @override
  String get mindMapExport => 'تصدير كصورة';

  @override
  String mindMapHidden(int count) {
    return '+$count';
  }

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
  String get notifBodyChildrenComplete => 'اكتملت كل العناصر الفرعية — هل تكمله؟';

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
  String get notifChipChangeTime => 'تغيير الوقت';

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
  String notifChipLastDayAt(String time) {
    return 'في اليوم الأخير الساعة $time';
  }

  @override
  String get notifChipMilestones => 'الإنجازات';

  @override
  String notifChipOnDayAt(String time) {
    return 'في اليوم نفسه عند $time';
  }

  @override
  String get notifChipRepeat => 'تكرار…';

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
  String notifCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نُسخ $count تذكير',
      many: 'نُسخ $count تذكيرًا',
      few: 'نُسخت $count تذكيرات',
      two: 'نُسخ تذكيران',
      one: 'نُسخ تذكير واحد',
      zero: 'لم يُنسخ أي تذكير',
    );
    return '$_temp0';
  }

  @override
  String get notifCopyFrom => 'نسخ التذكيرات من…';

  @override
  String get notifCopyNothing => 'لا يحتوي هذا العنصر على تذكيرات خاصة به';

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
  String get notifDiagBatteryBody => 'بعض الهواتف توقف التطبيقات في الخلفية. اتبع دليل هاتفك لتصل التذكيرات في وقتها.';

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
  String get notifDiagPushOff => 'الإشعارات الفورية غير مهيأة — تذكيرات محلية فقط';

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
  String get notifExactOffBody => 'اسمح بالتذكيرات الدقيقة لتصل في الدقيقة المحددة.';

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
  String get notifFieldRepeats => 'التكرار';

  @override
  String get notifFieldStatuses => 'الحالات';

  @override
  String get notifFieldThresholds => 'العتبات (مفصولة بفواصل، فارغ = تلقائي)';

  @override
  String get notifFieldToStatus => 'الحالة الجديدة';

  @override
  String get notifFieldUntil => 'حتى';

  @override
  String get notifFreqDaily => 'كل يوم';

  @override
  String get notifFreqMonthly => 'كل شهر';

  @override
  String get notifFreqWeekly => 'كل أسبوع';

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
  String get notifIssueRepeatDoze =>
      'على أندرويد، قد تصل التكرارات التي يفصل بينها أقل من 10 دقائق متأخرةً أثناء سكون الهاتف';

  @override
  String get notifIssueRepeatInterval => 'يجب أن يكون التكرار كل دقيقة على الأقل';

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
  String get notifIssueUnknownTrigger => 'هذا النوع من القواعد غير مدعوم في هذا الإصدار';

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
  String get notifNoiseCluster => 'عدة تذكيرات في الدقيقة نفسها — سيُسمع صوت واحد فقط';

  @override
  String notifNoiseConfirm(int perDay) {
    return 'يرسل هذا التذكير حوالي $perDay إشعار يوميًا. هل تحفظه رغم ذلك؟';
  }

  @override
  String notifNoiseWarn(int perDay) {
    return 'حوالي $perDay إشعار يوميًا';
  }

  @override
  String get notifNoticeChannelBody => 'افتح إعدادات النظام للسماح بها من جديد.';

  @override
  String get notifNoticeRevokedBody => 'سجّل الدخول من جديد لمتابعة المزامنة.';

  @override
  String get notifNoticeRevokedTitle => 'أُزيل هذا الجهاز من حسابك';

  @override
  String get notifNoticeSaturatedBody =>
      'يحتفظ iOS بالتذكيرات الـ64 التالية فقط. افتح Everslot بانتظام (أو فعّل الإشعارات الفورية) لتُجدوَل التذكيرات اللاحقة.';

  @override
  String get notifNoticeSaturatedTitle => 'لا يتّسع هذا الجهاز لكل التذكيرات';

  @override
  String get notifNoticeSyncBody => 'تغييراتك محفوظة على هذا الجهاز. تحقّق من اتصالك أو سجّل الدخول من جديد.';

  @override
  String get notifNoticeSyncTitle => 'تفشل المزامنة منذ أكثر من يوم';

  @override
  String get notifNoticeUpdateBody => 'لم يعد بإمكان هذا الإصدار المزامنة. ثبّت أحدث إصدار لتبقى بياناتك متزامنة.';

  @override
  String get notifNoticeUpdateTitle => 'حدّث Everslot';

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
  String get notifPausedShort => 'الإشعارات موقوفة مؤقتًا';

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
  String get notifStatusBlocked => 'متوقفًا';

  @override
  String get notifStatusCancelled => 'ملغًى';

  @override
  String get notifStatusCompleted => 'مكتملًا';

  @override
  String get notifStatusDone => 'منجزًا';

  @override
  String get notifStatusInProgress => 'قيد التنفيذ';

  @override
  String get notifStatusMissed => 'فائتًا';

  @override
  String get notifStatusOngoing => 'جاريًا';

  @override
  String get notifStatusScheduled => 'مجدولًا';

  @override
  String get notifStatusSkipped => 'متخطًّى';

  @override
  String get notifStatusTodo => 'غير منجز';

  @override
  String get notifStatusWaiting => 'في الانتظار';

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
  String get onboardingClock => 'الساعة';

  @override
  String get onboardingClock12 => '12 ساعة';

  @override
  String get onboardingClock24 => '24 ساعة';

  @override
  String get onboardingEssentialsBody =>
      'اخترنا هذه الإعدادات من جهازك. عدّل ما لا يناسبك، ويمكنك تغييرها لاحقًا من الإعدادات › المنطقة.';

  @override
  String get onboardingEssentialsTitle => 'أسبوعك وساعتك';

  @override
  String get onboardingGetStarted => 'لنبدأ';

  @override
  String get onboardingLanguage => 'اللغة';

  @override
  String onboardingStepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get onboardingTimeZone => 'المنطقة الزمنية الأساسية';

  @override
  String get onboardingTitle => 'إعداد Everslot';

  @override
  String get onboardingWeekStart => 'يبدأ الأسبوع يوم';

  @override
  String get pickerColor => 'اللون';

  @override
  String get pickerCustomColor => 'لون مخصّص';

  @override
  String get pickerDate => 'التاريخ';

  @override
  String get pickerDays => 'أيام';

  @override
  String get pickerDuration => 'المدة';

  @override
  String get pickerEnd => 'النهاية';

  @override
  String get pickerHex => 'الرمز الست عشري';

  @override
  String get pickerHexInvalid => 'استخدم 6 خانات ست عشرية، مثل 3B82F6';

  @override
  String get pickerHours => 'ساعات';

  @override
  String get pickerIcon => 'الأيقونة';

  @override
  String get pickerLowContrast => 'تباين منخفض: يصعب رؤية هذا اللون على الخلفية.';

  @override
  String get pickerMinutes => 'دقائق';

  @override
  String get pickerNextMonth => 'الشهر التالي';

  @override
  String get pickerNextWeek => 'الأسبوع القادم';

  @override
  String get pickerNoColor => 'بلا لون';

  @override
  String get pickerPreviousMonth => 'الشهر السابق';

  @override
  String get pickerSearchIcons => 'البحث عن أيقونة';

  @override
  String get pickerStart => 'البداية';

  @override
  String get pickerTime => 'الوقت';

  @override
  String get pickerTimeInvalid => 'أدخل وقتًا مثل 07:03';

  @override
  String get pickerTimeRange => 'النطاق الزمني';

  @override
  String get pickerTomorrow => 'غدًا';

  @override
  String get pickerTypeTime => 'اكتب الوقت';

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
  String get pvAddToBacklog => 'إضافة إلى قائمة الانتظار';

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
  String get pvCannotUnschedule => 'لا يمكن إعادة المواعيد المتكررة إلى المهام غير المجدولة';

  @override
  String get pvCapacity => 'السعة';

  @override
  String get pvCategories => 'الفئات';

  @override
  String get pvChecklistDue => 'عناصر قوائم لها موعد';

  @override
  String get pvClearFilters => 'مسح';

  @override
  String get pvClearSelection => 'إلغاء التحديد';

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
  String pvCopied(String title) {
    return 'تم نسخ «$title»';
  }

  @override
  String get pvCopy => 'نسخ';

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
  String pvCurrentSize(String size) {
    return 'الحالي: $size';
  }

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
  String get pvDisplay => 'العرض';

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
  String pvExtendedSnack(int minutes) {
    return 'مُدّد بمقدار $minutes د';
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
  String get pvFollowWorkHours => 'استخدام ساعات عملي';

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
  String get pvGroupCalendar => 'عروض التقويم';

  @override
  String get pvGroupCategory => 'الفئة';

  @override
  String get pvGroupDay => 'اليوم';

  @override
  String get pvGroupDeadline => 'الموعد النهائي';

  @override
  String get pvGroupNone => 'بلا تجميع';

  @override
  String get pvGroupPriority => 'الأولوية';

  @override
  String get pvGroupProductivity => 'التركيز والإنتاجية';

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
  String get pvHintPinch => 'باعد أو قارب إصبعيك للتكبير، وأفقيًا لتغيير عدد الأيام';

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
  String get pvHorizonsHint => 'نوايا غير مجدولة لكل أفق (تُحفظ على هذا الجهاز إلى أن تتوفر مزامنة الآفاق).';

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
  String get pvLaneOther => 'أخرى';

  @override
  String get pvLanes => 'المسارات';

  @override
  String get pvLanesHint => 'اختر الفئات المعروضة جنبًا إلى جنب وترتيبها.';

  @override
  String pvLastRowShort(String duration) {
    return 'والأخير مدته $duration';
  }

  @override
  String get pvLayout => 'التخطيط';

  @override
  String get pvLess => 'أقل';

  @override
  String get pvListBelow => 'القائمة في الأسفل';

  @override
  String get pvListMode => 'قائمة ميسّرة';

  @override
  String get pvLoadThresholds => 'تلوين الحِمل (مزدحم · متجاوز)';

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
  String get pvMoveDown => 'نقل للأسفل';

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
  String get pvMoveNextDay => 'نقل إلى اليوم التالي';

  @override
  String get pvMovePreviousDay => 'نقل إلى اليوم السابق';

  @override
  String get pvMoveTo => 'نقل إلى…';

  @override
  String get pvMoveUnfinishedTomorrow => 'نقل غير المنجز إلى الغد';

  @override
  String get pvMoveUp => 'نقل للأعلى';

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
  String get pvNoDeadline => 'بلا موعد نهائي';

  @override
  String get pvNoEstimate => 'بلا تقدير';

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
  String get pvNoSavedViews => 'لا توجد عروض محفوظة بعد';

  @override
  String get pvNoTasks => 'لا مهام';

  @override
  String get pvNothingNext => 'لا شيء آخر مخطط اليوم';

  @override
  String get pvNothingNow => 'لا شيء مجدول الآن';

  @override
  String get pvNothingToPaste => 'انسخ مهمة أولًا';

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
  String pvPasted(String time) {
    return 'تم اللصق في $time';
  }

  @override
  String get pvPause => 'إيقاف مؤقت';

  @override
  String get pvPickDate => 'اختر تاريخًا';

  @override
  String get pvPin => 'تثبيت';

  @override
  String get pvPinned => 'المثبتة';

  @override
  String pvPixels(String value) {
    return '$value بكسل';
  }

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
  String pvQuotaProgress(String title, int done, int total) {
    return '$title · $done/$total هذه الفترة';
  }

  @override
  String get pvQuotaSlots => 'أهداف للجدولة';

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
  String pvScheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر مُجدول',
      many: '$count عنصرًا مُجدولًا',
      few: '$count عناصر مُجدولة',
      two: 'عنصران مُجدولان',
      one: 'عنصر واحد مُجدول',
      zero: 'لم تُجدول أي عناصر',
    );
    return '$_temp0';
  }

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
  String get pvSelect => 'تحديد';

  @override
  String pvSelected(int count) {
    return 'المحدد: $count';
  }

  @override
  String get pvSelectionActions => 'إجراءات';

  @override
  String get pvSetAsPlanDefault => 'فتح تبويب الخطة على هذا العرض';

  @override
  String get pvSetDefaultView => 'تعيين كعرض افتراضي';

  @override
  String get pvShareAvailability => 'مشاركة أوقات التوفر';

  @override
  String get pvShowAsTimeline => 'العرض كصفوف في الخط الزمني';

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
  String get pvTags => 'الوسوم';

  @override
  String get pvTextFilterHint => 'ابحث في العناوين والملاحظات';

  @override
  String pvTileSemantics(String title, String day, String start, String end, String status) {
    return '$title، $day، من $start إلى $end، $status';
  }

  @override
  String pvTimeLeft(String duration) {
    return 'المتبقي: $duration';
  }

  @override
  String get pvTo => 'إلى';

  @override
  String get pvToggleBacklog => 'درج قائمة الانتظار';

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
  String get pvUnscheduleUnsupported => 'إعادة المهام إلى قائمة غير المجدولة غير متاحة بعد';

  @override
  String get pvUnscheduled => 'غير مجدولة';

  @override
  String get pvUnscheduledSnack => 'نُقل إلى قائمة الانتظار';

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
  String get pvWorkDaysOnly => 'أيام العمل فقط';

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
  String get quitAddUse => '+1';

  @override
  String get quitAllClocks => 'كل العدادات';

  @override
  String get quitAmount => 'الكمية';

  @override
  String get quitAutoSuccess => 'الأيام بلا انتكاس تُحتسب نظيفة';

  @override
  String get quitAutoSuccessHint => 'عند الإيقاف: أكّد كل يوم نظيف في مراجعة المساء.';

  @override
  String get quitBaseline => 'قبل الإقلاع، يوميًا';

  @override
  String quitBreathCycle(int cycle) {
    return 'الدورة $cycle';
  }

  @override
  String get quitBreathHold => 'احبس النفس';

  @override
  String get quitBreathIn => 'شهيق';

  @override
  String get quitBreathOut => 'زفير';

  @override
  String quitBreathPhase(String phase, int seconds) {
    return '$phase · $seconds';
  }

  @override
  String get quitBreathing478 => '4-7-8';

  @override
  String get quitBreathingBox => 'المربّع 4-4-4-4';

  @override
  String get quitBreathingStart => 'ابدأ';

  @override
  String get quitBreathingStop => 'أوقف';

  @override
  String get quitBreathingTitle => 'التنفّس';

  @override
  String quitCleanDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم نظيف',
      many: '$count يومًا نظيفًا',
      few: '$count أيام نظيفة',
      two: 'يومان نظيفان',
      one: 'يوم نظيف واحد',
      zero: '0 يوم نظيف',
    );
    return '$_temp0';
  }

  @override
  String get quitCleanDaysTitle => 'الأيام النظيفة';

  @override
  String get quitCleanSaved => 'تم تسجيله يومًا ناجحًا';

  @override
  String get quitCoping => 'ما الذي ساعد';

  @override
  String get quitCopingBreathing => 'التنفس العميق';

  @override
  String get quitCopingCallFriend => 'الاتصال بصديق';

  @override
  String get quitCopingDelay10 => 'الانتظار 10 دقائق';

  @override
  String get quitCopingGum => 'علكة';

  @override
  String get quitCopingWalk => 'نزهة قصيرة';

  @override
  String get quitCopingWater => 'كوب ماء';

  @override
  String quitCostPerUnit(String price) {
    return '= $price للوحدة';
  }

  @override
  String get quitCostTitle => 'التكلفة';

  @override
  String quitCounterSemantics(int days, int hours, int minutes) {
    return '$days يوم $hours ساعة $minutes دقيقة';
  }

  @override
  String get quitCravingDetails => 'إضافة تفاصيل';

  @override
  String get quitCravingLogged => 'تم تسجيل الرغبة — أحسنت على ملاحظتها.';

  @override
  String get quitCravingTitle => 'رغبة';

  @override
  String get quitCurrency => 'العملة';

  @override
  String get quitDailyLimit => 'الحد اليومي';

  @override
  String get quitDayMilestonesTitle => 'مدة الامتناع';

  @override
  String quitDaysHours(int days, int hours) {
    return '$days ي $hours س';
  }

  @override
  String get quitDistractionExercise => 'تمرين رياضي';

  @override
  String get quitDistractionGame => 'لعبة سريعة';

  @override
  String get quitDistractionMusic => 'الموسيقى';

  @override
  String get quitDistractionRead => 'القراءة';

  @override
  String get quitDistractionShower => 'حمّام';

  @override
  String get quitDistractionSnack => 'وجبة خفيفة صحية';

  @override
  String get quitDistractionsEmpty => 'أضف الإلهاءات التي تفيدك من القوائم.';

  @override
  String get quitDistractionsTitle => 'الإلهاءات';

  @override
  String get quitDuration => 'المدة';

  @override
  String get quitEditorEditTitle => 'تعديل متابعة الإقلاع';

  @override
  String get quitEditorNewTitle => 'متابعة إقلاع جديدة';

  @override
  String get quitErrCurrency => 'استخدم رمز عملة من 3 أحرف (مثل EUR)';

  @override
  String get quitErrDailyLimit => 'حدّد حدًا يوميًا قدره 0 أو أكثر';

  @override
  String get quitErrNegative => 'لا يمكن أن تكون القيم سالبة';

  @override
  String get quitErrStartInFuture => 'لا يمكن أن يكون تاريخ الإقلاع في المستقبل';

  @override
  String get quitEstimatesNote => 'كل القيم الافتراضية تقديرية — عدّلها لتناسبك.';

  @override
  String quitEventCraving(int intensity) {
    return 'رغبة · شدة $intensity';
  }

  @override
  String get quitEventPledge => 'تعهد اليوم';

  @override
  String get quitEventRelapse => 'انتكاس';

  @override
  String get quitEventRestart => 'محاولة إقلاع جديدة';

  @override
  String get quitHealthTitle => 'تعافي الصحة';

  @override
  String quitIntensity(int value) {
    return 'الشدة: $value/10';
  }

  @override
  String get quitLifePerUnit => 'متوسط العمر المتوقع لكل وحدة';

  @override
  String get quitLifeRegained => 'العمر المستعاد';

  @override
  String get quitLogCraving => 'تسجيل رغبة';

  @override
  String get quitLogRelapse => 'تسجيل انتكاس';

  @override
  String get quitLogUse => 'تسجيل استهلاك';

  @override
  String get quitLongest => 'أطول سلسلة';

  @override
  String get quitManualReset => 'إعادة ضبط يدوية';

  @override
  String quitMilestoneDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم من الامتناع',
      many: '$count يومًا من الامتناع',
      few: '$count أيام من الامتناع',
      two: 'يومان من الامتناع',
      one: 'يوم واحد من الامتناع',
    );
    return '$_temp0';
  }

  @override
  String quitMilestoneElapsed(String percent) {
    return 'انقضى $percent من المدة';
  }

  @override
  String quitMilestoneEta(String date) {
    return 'متوقعة في $date';
  }

  @override
  String quitMilestoneInWindow(String date) {
    return 'جارية الآن · حتى نحو $date';
  }

  @override
  String quitMilestoneReachedOn(String date) {
    return 'تحققت في $date';
  }

  @override
  String get quitMilestoneSources => 'المصادر';

  @override
  String get quitMilestonesClockNote => 'تُحسب المراحل منذ آخر زلّة، لذا تبدأ الساعة من جديد بعدها.';

  @override
  String get quitMilestonesOpen => 'كل المراحل';

  @override
  String get quitMilestonesReached => 'المراحل المحققة';

  @override
  String get quitMilestonesTitle => 'المراحل';

  @override
  String get quitMilestonesUpcoming => 'المراحل القادمة';

  @override
  String get quitModeAbstain => 'الإقلاع التام';

  @override
  String get quitModeReduce => 'التقليل';

  @override
  String get quitModeTitle => 'الهدف';

  @override
  String get quitMoneySaved => 'المال الموفَّر';

  @override
  String get quitMotivation => 'لماذا أُقلع';

  @override
  String get quitMotivationCard => 'أسبابي';

  @override
  String get quitMotivationHint => 'أسبابي…';

  @override
  String get quitNameAlcohol => 'الإقلاع عن الكحول';

  @override
  String get quitNameCaffeine => 'تقليل الكافيين';

  @override
  String get quitNameCannabis => 'الإقلاع عن الحشيش';

  @override
  String get quitNameCigarettes => 'الإقلاع عن التدخين';

  @override
  String get quitNameGaming => 'تقليل ألعاب الفيديو';

  @override
  String get quitNameOther => 'الإقلاع عن عادة';

  @override
  String get quitNameSocialMedia => 'تقليل وسائل التواصل';

  @override
  String get quitNameSugar => 'الإقلاع عن السكر';

  @override
  String get quitNameVape => 'الإقلاع عن السجائر الإلكترونية';

  @override
  String get quitNextMilestone => 'المرحلة التالية';

  @override
  String get quitNo => 'لا';

  @override
  String get quitNoEvents => 'لم يُسجَّل شيء بعد — واصل!';

  @override
  String get quitNoTrackers => 'لا توجد متابعة إقلاع بعد';

  @override
  String get quitNoTrackersBody => 'تابع منذ متى توقفت عن التدخين أو الشرب أو أي شيء آخر.';

  @override
  String get quitNotSure => 'لست متأكدًا';

  @override
  String get quitNote => 'ملاحظة';

  @override
  String get quitNotifInvalidIntensity => 'الشدة رقم من 1 إلى 10.';

  @override
  String quitNotifMoneyMilestone(String amount) {
    return 'تم توفير $amount';
  }

  @override
  String quitOffsetMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شهر',
      many: '$count شهرًا',
      few: '$count أشهر',
      two: 'شهران',
      one: 'شهر واحد',
    );
    return '$_temp0';
  }

  @override
  String quitOffsetRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String quitOffsetWeeks(int count) {
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
  String quitOffsetYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سنة',
      many: '$count سنة',
      few: '$count سنوات',
      two: 'سنتان',
      one: 'سنة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get quitOther => 'أخرى…';

  @override
  String get quitOverLimit => 'تجاوزت حد اليوم';

  @override
  String get quitPackPrice => 'سعر العلبة';

  @override
  String get quitPhotoAfterSave => 'يمكنك إضافة صورة محفزة بعد الحفظ.';

  @override
  String get quitPlace => 'المكان';

  @override
  String get quitPlaceBar => 'المقهى أو الحانة';

  @override
  String get quitPlaceCar => 'السيارة';

  @override
  String get quitPlaceFriends => 'عند الأصدقاء';

  @override
  String get quitPlaceHome => 'المنزل';

  @override
  String get quitPlaceOutside => 'في الخارج';

  @override
  String get quitPlaceWork => 'العمل';

  @override
  String get quitPledgeAction => 'قدّم تعهّد اليوم';

  @override
  String get quitPledgeMorning => 'تعهّد الصباح';

  @override
  String get quitPledgeSaved => 'تم حفظ التعهّد';

  @override
  String quitPledgeStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعهّد لـ$count يوم متتالٍ',
      many: 'تعهّد لـ$count يومًا متتاليًا',
      few: 'تعهّد لـ$count أيام متتالية',
      two: 'تعهّد ليومين متتاليين',
      one: 'تعهّد ليوم واحد متتالٍ',
    );
    return '$_temp0';
  }

  @override
  String get quitPledgeText => 'اليوم أختار أن أبقى ممتنعًا.';

  @override
  String get quitPledged => 'تم التعهّد لهذا اليوم';

  @override
  String get quitPopulationEstimate => 'تقدير على مستوى السكان';

  @override
  String get quitPopulationEstimateHelp =>
      'تقدير على مستوى السكان: نحو 20 دقيقة لكل سيجارة (Jackson وآخرون 2025؛ BMJ 2000: 11 دقيقة). تختلف التأثيرات من شخص لآخر.';

  @override
  String get quitPresetAlcohol => 'الكحول';

  @override
  String get quitPresetCaffeine => 'الكافيين';

  @override
  String get quitPresetCannabis => 'الحشيش';

  @override
  String get quitPresetCigarettes => 'التدخين';

  @override
  String get quitPresetGaming => 'ألعاب الفيديو';

  @override
  String get quitPresetOther => 'شيء آخر';

  @override
  String get quitPresetSocialMedia => 'وسائل التواصل الاجتماعي';

  @override
  String get quitPresetSugar => 'السكر';

  @override
  String get quitPresetTitle => 'عن ماذا تريد الإقلاع؟';

  @override
  String get quitPresetVape => 'السجائر الإلكترونية';

  @override
  String get quitRecentEvents => 'الأحداث الأخيرة';

  @override
  String get quitRelapseAmount => 'كم؟ (اختياري)';

  @override
  String get quitRelapseKindTitle => 'كيف تريد احتسابه؟';

  @override
  String quitRelapseNewAttempt(String time) {
    return 'بدء محاولة إقلاع جديدة من $time';
  }

  @override
  String get quitRelapseSaved => 'تم التسجيل. كن لطيفًا مع نفسك — كل محاولة تعلّمك شيئًا.';

  @override
  String get quitRelapseSlip => 'زلة عابرة — أحتفظ بتاريخ إقلاعي؛ وتبدأ السلسلة من الآن';

  @override
  String quitRelapseSupport(String duration) {
    return 'بقيت نظيفًا لمدة $duration — وهذا إنجاز يُحتسب.';
  }

  @override
  String get quitRelapseTitle => 'تسجيل انتكاس';

  @override
  String get quitResetBody => 'سيُسجَّل انتكاس الآن. يبقى تاريخ إقلاعك كما هو.';

  @override
  String get quitResetCounter => 'إعادة ضبط العداد';

  @override
  String get quitResisted => 'هل قاومت؟';

  @override
  String get quitReviewEvening => 'مراجعة المساء';

  @override
  String get quitReviewQuestion => 'هل بقيت ممتنعًا اليوم؟';

  @override
  String get quitReviewYesterdayQuestion => 'هل بقيت ممتنعًا أمس؟';

  @override
  String get quitReviewedClean => 'يوم نظيف — أحسنت!';

  @override
  String get quitRewardAdd => 'إضافة مكافأة';

  @override
  String get quitRewardClaim => 'الحصول عليها';

  @override
  String quitRewardClaimed(String date) {
    return 'حصلت عليها في $date';
  }

  @override
  String get quitRewardClaimedSnack => 'استمتع بها — لقد استحققتها.';

  @override
  String quitRewardEta(String date) {
    return 'في المتناول نحو $date';
  }

  @override
  String get quitRewardName => 'المكافأة';

  @override
  String get quitRewardNeedsCost => 'حدّد سعر الوحدة في المتتبّع لترى ما تشتريه مدخراتك.';

  @override
  String get quitRewardPrice => 'السعر';

  @override
  String get quitRewardReady => 'يمكنك تحمّل ثمنها!';

  @override
  String get quitRewardSaved => 'تم حفظ المكافأة';

  @override
  String get quitRewardsEmpty => 'اختر شيئًا ستدفع ثمنه مدخراتك.';

  @override
  String get quitRewardsTitle => 'ما يمكن أن توفّره مدخراتي';

  @override
  String get quitRitualEnable => 'تعهّد الصباح ومراجعة المساء';

  @override
  String get quitRitualEnableHint => 'تعهّد في الصباح ومراجعة في المساء. أضف تذكيرات في هذه الأوقات من قسم التذكيرات.';

  @override
  String get quitRitualTitle => 'الطقس اليومي';

  @override
  String get quitSinceFirstQuit => 'منذ إقلاعك الأول';

  @override
  String get quitSinceLastRelapse => 'نظيف منذ';

  @override
  String get quitSinceLastUse => 'منذ آخر استهلاك';

  @override
  String get quitStartedAt => 'أقلعت في';

  @override
  String get quitTimePerUnit => 'الوقت المستغرق لكل وحدة';

  @override
  String get quitTimeWonBack => 'الوقت المستعاد';

  @override
  String quitTodayUse(String used, String limit) {
    return '$used من $limit اليوم';
  }

  @override
  String get quitToolboxDone => 'انقضت ثلاث دقائق — هل قاومت؟';

  @override
  String get quitToolboxLogged => 'تم تسجيل الرغبة مع مدتها.';

  @override
  String get quitToolboxOpen => 'افتح صندوق أدوات التأقلم';

  @override
  String quitToolboxRemaining(String time) {
    return 'بقي $time';
  }

  @override
  String get quitToolboxStart => 'ابدأ مؤقّت الدقائق الثلاث';

  @override
  String get quitToolboxThrough => 'لقد تجاوزتها';

  @override
  String get quitToolboxTimerHint => 'تزول معظم الرغبات خلال 3 إلى 5 دقائق. اصمد.';

  @override
  String get quitToolboxTimerTitle => 'تجاوَز الرغبة';

  @override
  String get quitToolboxTitle => 'صندوق أدوات التأقلم';

  @override
  String get quitTrigger => 'المحفّز';

  @override
  String get quitTriggerAfterMeals => 'بعد الوجبات';

  @override
  String get quitTriggerAlcohol => 'الكحول';

  @override
  String get quitTriggerBoredom => 'الملل';

  @override
  String get quitTriggerCoffee => 'القهوة';

  @override
  String get quitTriggerDriving => 'القيادة';

  @override
  String get quitTriggerPhone => 'الهاتف';

  @override
  String get quitTriggerSocial => 'المواقف الاجتماعية';

  @override
  String get quitTriggerStress => 'التوتر';

  @override
  String get quitTriggerWakingUp => 'الاستيقاظ';

  @override
  String get quitTriggerWorkBreak => 'استراحة العمل';

  @override
  String get quitUnitCost => 'سعر الوحدة';

  @override
  String get quitUnitDays => 'ي';

  @override
  String get quitUnitHours => 'س';

  @override
  String get quitUnitMinutes => 'د';

  @override
  String get quitUnitSeconds => 'ث';

  @override
  String get quitUnitsAvoided => 'تم تجنبه';

  @override
  String get quitUnitsPerPack => 'عدد الوحدات في العلبة';

  @override
  String get quitUseLogged => 'تم تسجيل الاستهلاك';

  @override
  String get quitVocabAdd => 'إضافة عنصر';

  @override
  String get quitVocabCoping => 'التأقلم';

  @override
  String get quitVocabDistractions => 'الإلهاءات';

  @override
  String get quitVocabEmpty => 'لا شيء هنا بعد — أضف عناصرك.';

  @override
  String get quitVocabName => 'الاسم';

  @override
  String get quitVocabPlaces => 'الأماكن';

  @override
  String get quitVocabRename => 'إعادة التسمية';

  @override
  String get quitVocabSaved => 'تم تحديث القائمة';

  @override
  String get quitVocabTitle => 'المحفّزات والأماكن وطرق التأقلم';

  @override
  String get quitVocabTriggers => 'المحفّزات';

  @override
  String quitVocabUses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استُخدم $count مرة',
      many: 'استُخدم $count مرة',
      few: 'استُخدم $count مرات',
      two: 'استُخدم مرتين',
      one: 'استُخدم مرة واحدة',
      zero: 'لم يُستخدم بعد',
    );
    return '$_temp0';
  }

  @override
  String get quitWhen => 'متى';

  @override
  String get quitWithdrawalNow => 'أين أنت الآن';

  @override
  String get quitWithdrawalTitle => 'أعراض الانسحاب';

  @override
  String get quitWithinLimitStreakTitle => 'أيام ضمن الحد';

  @override
  String get quitYes => 'نعم';

  @override
  String get recurAddDate => 'إضافة';

  @override
  String get recurAddOrdinal => 'إضافة يوم مثل «يوم الثلاثاء الثاني»';

  @override
  String get recurAddTime => 'إضافة وقت';

  @override
  String get recurAdvancedTitle => 'تكرار مخصص';

  @override
  String get recurAfterHint => 'يحين الموعد التالي بعد هذه المدة من إنجاز السابق.';

  @override
  String get recurAfterPreview => 'تعتمد المواعيد التالية على وقت إنجازك له';

  @override
  String recurAnchorMoved(String date) {
    return 'أول موعد: $date';
  }

  @override
  String recurCalendarSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم فيه مواعيد',
      many: '$count يومًا فيه مواعيد',
      few: '$count أيام فيها مواعيد',
      two: 'يومان فيهما مواعيد',
      one: 'يوم واحد فيه مواعيد',
      zero: 'لا يوم فيه مواعيد',
    );
    return '$_temp0';
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
  String get recurCustomValue => 'قيمة أخرى…';

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
  String get recurExceptionExcluded => 'مستبعد';

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
  String recurExceptionRestoreAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استعادة $count موعد؟',
      many: 'استعادة $count موعدًا؟',
      few: 'استعادة $count مواعيد؟',
      two: 'استعادة موعدين؟',
      one: 'استعادة موعد واحد؟',
    );
    return '$_temp0';
  }

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
  String get recurIssueOrdinal => '«الأول» و«الأخير»… تعمل فقط مع التكرار الشهري أو السنوي';

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
  String get recurNumbersHint => 'أرقام مفصولة بفواصل (السالب = من النهاية)';

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
  String get recurOrdinalPick => 'أي يوم؟';

  @override
  String get recurOrdinalSecondLast => 'قبل الأخير';

  @override
  String recurOrdinalWeekday(String ordinal, String weekday) {
    return 'يوم $weekday $ordinal';
  }

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
  String recurPeriodWeek(String date) {
    return 'أسبوع $date';
  }

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
  String recurRemove(String item) {
    return 'إزالة $item';
  }

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
  String recurTimesDefault(String time) {
    return 'في وقت البدء ($time)';
  }

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
  String get recurWarnAllDaySubDaily => 'لا يمكن لعناصر اليوم الكامل أن تتكرر داخل اليوم';

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
  String get recurWeekNumbers => 'أرقام الأسابيع';

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
  String get recurYearDays => 'أيام السنة';

  @override
  String recurZoneNote(String zone) {
    return 'الأوقات بتوقيت $zone';
  }

  @override
  String redoDoneSnack(String action) {
    return 'تمت الإعادة: $action';
  }

  @override
  String get redoNothing => 'لا شيء لإعادته';

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
  String get repeatModeAll => 'إعادة كل شيء إلى «للإنجاز»';

  @override
  String get repeatModeCompleted => 'إلغاء تحديد المكتملة فقط';

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
  String get savedSnack => 'تم الحفظ';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get settingsAboutSubtitle => 'الإصدار والتراخيص والمساعدة';

  @override
  String get settingsAccessibility => 'تسهيلات الاستخدام';

  @override
  String get settingsAccessibilitySubtitle => 'الحركة والاهتزاز والتباين والتسميات';

  @override
  String get settingsAccount => 'الحساب';

  @override
  String get settingsAccountLocalOnly => 'على هذا الجهاز فقط';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsAppearanceSubtitle => 'السمة والكثافة واللغة';

  @override
  String get settingsArabicDigits => 'الأرقام العربية المشرقية';

  @override
  String get settingsArabicDigitsSubtitle => 'عرض ٠١٢٣ بدلًا من 0123 عندما يكون التطبيق بالعربية';

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
  String get settingsClock => 'الساعة';

  @override
  String get settingsClock12 => '12 ساعة';

  @override
  String get settingsClock24 => '24 ساعة';

  @override
  String get settingsCompleteChildren => 'عند إكمال عنصر أصلي';

  @override
  String get settingsCurrency => 'عملة مدّخرات الإقلاع';

  @override
  String get settingsCurrentZone => 'المنطقة الزمنية الحالية (هذا الجهاز)';

  @override
  String get settingsDataSubtitle => 'انسخ بياناتك احتياطيًا أو استعدها أو انقلها';

  @override
  String get settingsDataTitle => 'التصدير والاستيراد';

  @override
  String get settingsDayStart => 'يبدأ يوم العادات عند';

  @override
  String get settingsDayStartSubtitle =>
      'تُحتسب التسجيلات قبل هذا الوقت لليوم السابق. ينطبق على التسجيلات الجديدة فقط.';

  @override
  String get settingsDefaultOpen => 'الفتح في وضع';

  @override
  String get settingsDefaultsHint => 'القيم الافتراضية للعناصر الجديدة. تحتفظ العناصر الحالية بإعداداتها.';

  @override
  String get settingsDensity => 'الكثافة';

  @override
  String get settingsDensityComfortable => 'مريحة';

  @override
  String get settingsDensityCompact => 'مضغوطة';

  @override
  String settingsDeviceLastSeen(String when) {
    return 'آخر ظهور $when';
  }

  @override
  String get settingsDevicePushOff => 'إشعارات الدفع متوقفة';

  @override
  String get settingsDevicePushOn => 'إشعارات الدفع مفعّلة';

  @override
  String get settingsDeviceRevoke => 'إزالة الجهاز';

  @override
  String get settingsDeviceRevokeBody => 'سيتوقف عن تلقي الإشعارات وسيُسجَّل خروجه عند اتصاله التالي.';

  @override
  String settingsDeviceRevokeTitle(String name) {
    return 'إزالة $name؟';
  }

  @override
  String get settingsDeviceRevoked => 'تمت إزالة الجهاز';

  @override
  String get settingsDeviceThis => 'هذا الجهاز';

  @override
  String get settingsDeviceUnknown => 'جهاز غير معروف';

  @override
  String get settingsDevices => 'الأجهزة';

  @override
  String get settingsDevicesEmpty => 'لا توجد أجهزة مسجّلة بعد.';

  @override
  String get settingsDevicesOffline => 'اتصل بالإنترنت لعرض أجهزتك.';

  @override
  String get settingsDynamicColor => 'ألوان الخلفية';

  @override
  String get settingsDynamicColorSubtitle => 'استخدام ألوان Material You من جهازك. ألوان الفئات لا تتغير.';

  @override
  String get settingsExportAttachments => 'تضمين ملفات المرفقات';

  @override
  String get settingsExportAttachmentsHint => 'الملفات الموجودة على هذا الجهاز فقط.';

  @override
  String get settingsExportBody => 'نسخة من كل بياناتك على هذا الجهاز. يعمل دون اتصال.';

  @override
  String get settingsExportButton => 'تصدير';

  @override
  String get settingsExportCsv => 'جداول بيانات (CSV)';

  @override
  String get settingsExportCsvHint => 'ملف لكل جدول لبرامج Excel أو Numbers أو Sheets.';

  @override
  String settingsExportDone(String file) {
    return 'التصدير جاهز: $file';
  }

  @override
  String get settingsExportFailed => 'فشل التصدير. حاول مرة أخرى.';

  @override
  String get settingsExportJson => 'نسخة Everslot الاحتياطية (JSON)';

  @override
  String get settingsExportJsonHint => 'نسخة كاملة يمكنك استيرادها لاحقًا.';

  @override
  String settingsExportProgress(int percent) {
    return 'جارٍ التصدير… $percent٪';
  }

  @override
  String get settingsExportShareSubject => 'تصدير Everslot';

  @override
  String get settingsExportTitle => 'تصدير';

  @override
  String get settingsFewer => 'واحد أقل';

  @override
  String get settingsGroupData => 'البيانات والخصوصية';

  @override
  String get settingsGroupGeneral => 'عام';

  @override
  String get settingsGroupHelp => 'المساعدة';

  @override
  String get settingsGroupSections => 'الأقسام';

  @override
  String get settingsHabits => 'العادات';

  @override
  String settingsHabitsDayStartLink(String time) {
    return 'يبدأ اليوم عند $time';
  }

  @override
  String get settingsHabitsFreezes => 'أيام تجميد السلسلة شهريًا';

  @override
  String get settingsHabitsFreezesHint => 'أيام فائتة تُغتفر كل شهر للعادات الجديدة.';

  @override
  String get settingsHabitsSkipBreaks => 'تقطع السلسلة';

  @override
  String get settingsHabitsSkipNeutral => 'لا تؤثر على السلسلة';

  @override
  String get settingsHabitsSkipPolicy => 'الأيام المتخطّاة';

  @override
  String get settingsHabitsSubtitle => 'سياسة التخطي وتجميد السلاسل';

  @override
  String get settingsHideCheckboxes => 'إخفاء مربعات الاختيار (نقاط)';

  @override
  String get settingsHomeZone => 'المنطقة الزمنية الأساسية';

  @override
  String get settingsHomeZoneAuto => 'اتباع هذا الجهاز';

  @override
  String get settingsHomeZoneAutoSubtitle => 'تحديث المنطقة الأساسية تلقائيًا عند السفر';

  @override
  String get settingsHomeZoneSubtitle => 'تستخدم المهام والعادات ذات التوقيت الثابت هذه المنطقة';

  @override
  String get settingsInsights => 'الإحصاءات';

  @override
  String get settingsInsightsCompare => 'المقارنة مع الفترة السابقة';

  @override
  String get settingsInsightsPeriod => 'الفترة الافتراضية';

  @override
  String get settingsInsightsSubtitle => 'الفترة الافتراضية والمقارنات';

  @override
  String get settingsInsightsWeekStart => 'بداية الأسبوع (الإحصاءات)';

  @override
  String settingsInsightsWeekStartProfile(String day) {
    return 'مثل التطبيق ($day)';
  }

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsLanguageSystem => 'لغة النظام';

  @override
  String get settingsLists => 'القوائم';

  @override
  String get settingsListsAutoComplete => 'إكمال العناصر الأم تلقائيًا';

  @override
  String get settingsListsAutoCompleteHint => 'يكتمل العنصر الأم عند اكتمال كل عناصره الفرعية.';

  @override
  String get settingsListsCompletedBottom => 'نقل العناصر المكتملة إلى الأسفل';

  @override
  String get settingsListsProgress => 'يُحسب التقدّم على';

  @override
  String get settingsListsProgressChildren => 'العناصر الفرعية المباشرة';

  @override
  String get settingsListsProgressLeaves => 'كل العناصر';

  @override
  String get settingsListsRequireReason => 'طلب سبب عندما يكون العنصر';

  @override
  String get settingsListsShowCompleted => 'إظهار العناصر المكتملة';

  @override
  String get settingsListsSubtitle => 'الحالات والتقدّم والعناصر المكتملة';

  @override
  String get settingsMore => 'واحد أكثر';

  @override
  String get settingsNotificationsSubtitle => 'التذكيرات وساعات الهدوء وصندوق الوارد';

  @override
  String get settingsOrganizationSubtitle => 'الفئات والوسوم المستخدمة في التطبيق';

  @override
  String get settingsPeriodLastMonth => 'الشهر الماضي';

  @override
  String get settingsPeriodLastWeek => 'الأسبوع الماضي';

  @override
  String settingsPeriodRolling(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'آخر $days يوم',
      many: 'آخر $days يومًا',
      few: 'آخر $days أيام',
      two: 'آخر يومين',
      one: 'آخر يوم',
    );
    return '$_temp0';
  }

  @override
  String get settingsPeriodThisMonth => 'هذا الشهر';

  @override
  String get settingsPeriodThisQuarter => 'هذا الربع';

  @override
  String get settingsPeriodThisWeek => 'هذا الأسبوع';

  @override
  String get settingsPeriodThisYear => 'هذه السنة';

  @override
  String get settingsPlan => 'التخطيط';

  @override
  String get settingsPlanActualAlways => 'دائمًا';

  @override
  String get settingsPlanActualNever => 'أبدًا';

  @override
  String get settingsPlanActualOffSchedule => 'عند الخروج عن الجدول';

  @override
  String get settingsPlanActualTime => 'طلب الوقت الفعلي عند الإنجاز';

  @override
  String get settingsPlanDefaultDuration => 'المدة الافتراضية للمهام';

  @override
  String get settingsPlanDefaultView => 'العرض الافتراضي';

  @override
  String get settingsPlanDefaultViewNone => 'جدول الأسبوع';

  @override
  String get settingsPlanGrace => 'تُعدّ فائتة بعد';

  @override
  String settingsPlanGraceValue(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة بعد انتهائها',
      many: '$minutes دقيقة بعد انتهائها',
      few: '$minutes دقائق بعد انتهائها',
      two: 'دقيقتين بعد انتهائها',
      one: 'دقيقة واحدة بعد انتهائها',
      zero: 'بمجرد انتهائها',
    );
    return '$_temp0';
  }

  @override
  String get settingsPlanRollOver => 'المهام غير المنجزة';

  @override
  String get settingsPlanRollOverAsk => 'اسألني';

  @override
  String get settingsPlanRollOverAuto => 'نقلها إلى اليوم';

  @override
  String get settingsPlanRollOverOff => 'تركها';

  @override
  String get settingsPlanSubtitle => 'العرض الافتراضي والمدد وساعات العمل';

  @override
  String get settingsPlanTracking => 'طريقة المتابعة الافتراضية';

  @override
  String get settingsPlanTrackingCheck => 'تأشير';

  @override
  String get settingsPlanTrackingEvent => 'حدث';

  @override
  String get settingsPlanTrackingTimer => 'مؤقّت';

  @override
  String get settingsPlanWorkDays => 'أيام العمل';

  @override
  String get settingsPlanWorkEnd => 'النهاية';

  @override
  String get settingsPlanWorkHours => 'ساعات العمل';

  @override
  String get settingsPlanWorkStart => 'البداية';

  @override
  String get settingsPreview => 'معاينة';

  @override
  String get settingsPrivacy => 'الخصوصية والأمان';

  @override
  String get settingsPrivacySubtitle => 'قفل التطبيق وإخفاء محتوى الإشعارات';

  @override
  String get settingsProgressChildren => 'العناصر الفرعية المباشرة فقط';

  @override
  String get settingsProgressLeaves => 'كل العناصر الفرعية';

  @override
  String get settingsProgressMode => 'طريقة حساب التقدم';

  @override
  String get settingsRegional => 'المنطقة';

  @override
  String get settingsRegionalSubtitle => 'المنطقة الزمنية وبداية الأسبوع والساعة والعملة';

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
  String get settingsSyncData => 'المزامنة والبيانات';

  @override
  String get settingsSyncDataSubtitle => 'الأجهزة والتصدير والاستيراد والمهملات';

  @override
  String get settingsSyncDiagnostics => 'تشخيص المزامنة';

  @override
  String get settingsSyncDiscardBody => 'ستُستعاد نسخة الخادم من هذه العناصر على هذا الجهاز.';

  @override
  String get settingsSyncDiscardFailed => 'تجاهل التعديلات المرفوضة';

  @override
  String get settingsSyncDiscardTitle => 'تجاهل التعديلات المرفوضة؟';

  @override
  String settingsSyncFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رفض الخادم $count تعديل',
      many: 'رفض الخادم $count تعديلًا',
      few: 'رفض الخادم $count تعديلات',
      two: 'رفض الخادم تعديلين',
      one: 'رفض الخادم تعديلًا واحدًا',
    );
    return '$_temp0';
  }

  @override
  String settingsSyncInitialProgress(int percent) {
    return 'جارٍ تنزيل بياناتك… $percent٪';
  }

  @override
  String get settingsSyncLastError => 'آخر خطأ';

  @override
  String settingsSyncLastSuccess(String when) {
    return 'آخر مزامنة $when';
  }

  @override
  String get settingsSyncNever => 'لم تتم المزامنة بعد';

  @override
  String get settingsSyncNow => 'المزامنة الآن';

  @override
  String get settingsSyncOffBody => 'بياناتك محفوظة على هذا الجهاز فقط.';

  @override
  String get settingsSyncOffTitle => 'المزامنة متوقفة';

  @override
  String get settingsSyncRefreshLocalOnly => 'كل شيء محفوظ على هذا الجهاز.';

  @override
  String get settingsSyncResync => 'فرض مزامنة كاملة';

  @override
  String get settingsSyncResyncBody => 'سيعيد Everslot تنزيل جميع بياناتك. تُحفظ التغييرات التي لم تتم مزامنتها بعد.';

  @override
  String get settingsSyncResyncTitle => 'إعادة مزامنة كل شيء؟';

  @override
  String get settingsSyncRetryFailed => 'إعادة إرسال التعديلات المرفوضة';

  @override
  String get settingsSyncStatus => 'الحالة';

  @override
  String get settingsSyncTitle => 'المزامنة والأجهزة';

  @override
  String get settingsSyncTooltip => 'حالة المزامنة';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get settingsThemeDark => 'داكنة';

  @override
  String get settingsThemeLight => 'فاتحة';

  @override
  String get settingsThemeSystem => 'حسب النظام';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsTrash => 'المهملات';

  @override
  String get settingsTrashDeleteForever => 'حذف نهائي';

  @override
  String get settingsTrashDeleteForeverBody => 'سيُحذف من كل أجهزتك مع كل ما حُذف معه. لا يمكن التراجع عن ذلك.';

  @override
  String settingsTrashDeleteForeverTitle(String title) {
    return 'حذف «$title» نهائيًا؟';
  }

  @override
  String get settingsTrashDeleted => 'حُذف نهائيًا';

  @override
  String settingsTrashDeletedWhen(String when) {
    return 'حُذف $when';
  }

  @override
  String get settingsTrashEmptyAll => 'إفراغ سلة المهملات';

  @override
  String settingsTrashEmptyAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سيُحذف $count عنصر نهائيًا من كل أجهزتك.',
      many: 'سيُحذف $count عنصرًا نهائيًا من كل أجهزتك.',
      few: 'ستُحذف $count عناصر نهائيًا من كل أجهزتك.',
      two: 'سيُحذف عنصران نهائيًا من كل أجهزتك.',
      one: 'سيُحذف عنصر واحد نهائيًا من كل أجهزتك.',
    );
    return '$_temp0 لا يمكن التراجع عن ذلك.';
  }

  @override
  String get settingsTrashEmptyState => 'سلة المهملات فارغة';

  @override
  String get settingsTrashHint => 'تبقى العناصر المحذوفة هنا 30 يومًا. استعادة عنصر تُعيد كل ما حُذف معه.';

  @override
  String get settingsTrashKindAttachment => 'مرفق';

  @override
  String get settingsTrashKindChecklist => 'قائمة';

  @override
  String get settingsTrashKindHabit => 'عادة';

  @override
  String get settingsTrashKindItem => 'عنصر قائمة';

  @override
  String get settingsTrashKindTask => 'مهمة';

  @override
  String get settingsTrashNotSynced => 'لم تتم مزامنة هذا الحذف بعد. أعد المحاولة عند الاتصال.';

  @override
  String get settingsTrashOffline => 'اتصل بالإنترنت للحذف النهائي.';

  @override
  String get settingsTrashRestore => 'استعادة';

  @override
  String get settingsTrashRestored => 'تمت الاستعادة';

  @override
  String get settingsTrashUntitled => 'بلا عنوان';

  @override
  String settingsTrashWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count عنصر مرتبط',
      many: '+ $count عنصرًا مرتبطًا',
      few: '+ $count عناصر مرتبطة',
      two: '+ عنصران مرتبطان',
      one: '+ عنصر مرتبط',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnknownPage => 'صفحة الإعدادات هذه غير موجودة.';

  @override
  String get settingsWeekStart => 'يبدأ الأسبوع يوم';

  @override
  String get shellCreate => 'إنشاء';

  @override
  String shellDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهمة',
      many: '$count مهمة',
      few: '$count مهام',
      two: 'مهمتان',
      one: 'مهمة واحدة',
      zero: 'لا شيء للقيام به',
    );
    return '$_temp0';
  }

  @override
  String get shellQuickAdd => 'إضافة سريعة';

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
  String get statsExplainPopulation => 'تقدير سكاني: الضرر ليس خطيًا ويختلف من شخص لآخر، وليس تنبؤًا شخصيًا.';

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
  String statsGlossaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مؤشر',
      many: '$count مؤشرًا',
      few: '$count مؤشرات',
      two: 'مؤشران',
      one: 'مؤشر واحد',
      zero: 'لا مؤشرات',
    );
    return '$_temp0';
  }

  @override
  String statsGlossaryEmpty(String query) {
    return 'لا يوجد مؤشر يطابق «$query».';
  }

  @override
  String get statsGlossaryFormula => 'الصيغة';

  @override
  String get statsGlossarySearch => 'ابحث عن مؤشر';

  @override
  String get statsGlossaryTitle => 'مسرد المؤشرات';

  @override
  String get statsGuidanceLogFromNotifications => 'سجِّل من إشعارات التذكير لتحسين الدقة.';

  @override
  String get statsGuidanceLogSameDay => 'حاول التسجيل في اليوم نفسه — فالتسجيل المتأخر عرضة للنسيان.';

  @override
  String get statsGuidanceSyncPending => 'قد تنقص بعض التغييرات من أجهزة أخرى حتى تكتمل المزامنة.';

  @override
  String get statsGuidanceTrackTime => 'شغِّل المؤقت في مهامك لترى ساعاتك الفعلية.';

  @override
  String get statsHealthClockNote => 'تتبع المحطات مدة امتناعك الحالية عن التدخين: يُعاد تشغيل العدّاد بعد الزلّة.';

  @override
  String get statsHealthDisclaimer =>
      'تقديرات تثقيفية مبنية على متوسطات سكانية من منظمة الصحة العالمية وهيئة NHS ومراكز CDC والجمعية الأمريكية للسرطان؛ وتختلف النتائج من شخص لآخر. ليست نصيحة طبية. استشر مختصًا في الرعاية الصحية.';

  @override
  String get statsHealthElapsedNote => 'النسب تعبّر عن الوقت المنقضي فقط وليست قياسات فسيولوجية.';

  @override
  String statsHealthRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get statsLoading => 'جارٍ تحديث الإحصاءات…';

  @override
  String get statsMetricClI01Desc => 'المدة التي قضاها هذا العنصر في كل حالة.';

  @override
  String get statsMetricClI01Formula => 'مجموع الفترات في كل حالة حتى الآن (أو الحذف).';

  @override
  String get statsMetricClI01Title => 'الوقت في كل حالة';

  @override
  String get statsMetricClI02Desc => 'الوقت من بدء العمل حتى الإكمال.';

  @override
  String get statsMetricClI02Formula => 'الإكمال − البدء (أول خروج من \"للقيام به\").';

  @override
  String get statsMetricClI02Title => 'زمن الدورة';

  @override
  String get statsMetricClI03Desc => 'الوقت من الإنشاء حتى الإكمال.';

  @override
  String get statsMetricClI03Formula => 'الإكمال − الإنشاء.';

  @override
  String get statsMetricClI03Title => 'المهلة الكلية';

  @override
  String get statsMetricClI04Desc => 'منذ متى والعنصر المفتوح قيد العمل أو بانتظار البدء.';

  @override
  String get statsMetricClI04Formula => 'بدأ: الآن − البدء؛ لم يبدأ: الآن − الإنشاء.';

  @override
  String get statsMetricClI04Title => 'العمر';

  @override
  String get statsMetricClI05Desc => 'الوقت منذ آخر نشاط على هذا العنصر.';

  @override
  String get statsMetricClI05Formula => 'الآن − آخر نشاط (تغيير حالة أو تعديل أو مرفق أو عنصر فرعي).';

  @override
  String get statsMetricClI05Title => 'الركود';

  @override
  String get statsMetricClI06Desc => 'مدى إكمال العناصر المتفرعة من هذا العنصر.';

  @override
  String get statsMetricClI06Formula => 'الأوراق المكتملة ÷ الأوراق المحسوبة (باستثناء الملغاة).';

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
  String get statsMetricClL01Formula => 'العناصر لكل حالة؛ نسبة الإكمال على الأوراق وعلى كل العُقد.';

  @override
  String get statsMetricClL01Title => 'توزيع الحالات';

  @override
  String get statsMetricClL02Desc => 'نسبة إكمال القائمة يوميًا.';

  @override
  String get statsMetricClL02Formula => 'المكتمل ÷ (العناصر − الملغاة) في نهاية كل يوم.';

  @override
  String get statsMetricClL02Title => 'التقدّم عبر الزمن';

  @override
  String get statsMetricClL03Desc => 'العناصر المكتملة أسبوعيًا مع متوسط متحرك لأربعة أسابيع.';

  @override
  String get statsMetricClL03Formula => 'الإكمالات لكل فترة (العنصر المعاد فتحه يُحسب مرة واحدة).';

  @override
  String get statsMetricClL03Title => 'الإنتاجية';

  @override
  String get statsMetricClL04Desc => 'العناصر الجارية أو المنتظرة أو المحظورة في نهاية كل يوم.';

  @override
  String get statsMetricClL04Formula => 'عدد العناصر الجارية + المنتظرة + المحظورة.';

  @override
  String get statsMetricClL04Title => 'العمل الجاري';

  @override
  String get statsMetricClL05Desc => 'العناصر المضافة مقابل المكتملة أسبوعيًا.';

  @override
  String get statsMetricClL05Formula => 'المُنشأ (أو المنقول إليها) مقابل المكتمل أسبوعيًا؛ صافي التدفق = الفرق.';

  @override
  String get statsMetricClL05Title => 'الوافد مقابل المغادِر';

  @override
  String get statsMetricClL06Desc => 'عناصر مفتوحة بلا نشاط منذ مدة، والأقدم منها.';

  @override
  String get statsMetricClL06Formula => 'العناصر المفتوحة التي تجاوز ركودها الحد؛ أقدم 10 عناصر.';

  @override
  String get statsMetricClL06Title => 'العناصر الراكدة';

  @override
  String get statsMetricClX01Desc => 'قوائمك: النشطة والمؤرشفة والقوالب والراكدة.';

  @override
  String get statsMetricClX01Formula => 'عدد القوائم؛ الراكدة = بلا نشاط منذ N يومًا مع عناصر مفتوحة.';

  @override
  String get statsMetricClX01Title => 'نظرة على القوائم';

  @override
  String get statsMetricClX02Desc => 'العناصر المضافة مقابل المكتملة أسبوعيًا في كل القوائم.';

  @override
  String get statsMetricClX02Formula => 'المُنشأ مقابل المكتمل أسبوعيًا؛ صافي التدفق = الفرق.';

  @override
  String get statsMetricClX02Title => 'الوافد مقابل المغادِر (كل القوائم)';

  @override
  String get statsMetricClX03Desc => 'العناصر الجارية أو المنتظرة أو المحظورة الآن، وأقدم العناصر المفتوحة.';

  @override
  String get statsMetricClX03Formula => 'الأعداد في القوائم النشطة (باستثناء المؤرشفة).';

  @override
  String get statsMetricClX03Title => 'العمل الجاري في كل القوائم';

  @override
  String get statsMetricClX04Desc => 'العناصر المكتملة خلال الفترة.';

  @override
  String get statsMetricClX04Formula => 'الإكمالات النهائية في الفترة مقارنة بالفترة السابقة.';

  @override
  String get statsMetricClX04Title => 'العناصر المكتملة';

  @override
  String get statsMetricClX05Desc => 'العناصر لكل حالة في كل القوائم.';

  @override
  String get statsMetricClX05Formula => 'عدد العناصر الحية لكل حالة.';

  @override
  String get statsMetricClX05Title => 'التوزيع حسب الحالة';

  @override
  String get statsMetricGl01Desc => 'يومك عبر الأقسام: جدول الأعمال والعادات والقوائم والإقلاع.';

  @override
  String get statsMetricGl01Formula => 'الأرقام نفسها التي تعرضها مؤشرات كل قسم لهذا اليوم.';

  @override
  String get statsMetricGl01Title => 'اليوم';

  @override
  String get statsMetricGl02Desc => 'هذا الأسبوع حتى الآن مقابل الأيام نفسها من الأسبوع الماضي.';

  @override
  String get statsMetricGl02Formula => 'مؤشرات الأقسام حتى تاريخه وتغيّرها عن الأسبوع السابق.';

  @override
  String get statsMetricGl02Title => 'الأسبوع في لمحة';

  @override
  String get statsMetricGl03Desc => 'أسبوعك: أبرز الأرقام والإنجازات وما يحتاج إلى متابعة وحمل الأسبوع القادم.';

  @override
  String get statsMetricGl03Formula => 'مؤشرات الأقسام وتغيّرها عن الأسبوع السابق.';

  @override
  String get statsMetricGl03Title => 'المراجعة الأسبوعية';

  @override
  String get statsMetricGl10Desc =>
      'مدى موثوقية إحصاءاتك: تسجيل العادات والتسجيل المتأخر والوقت المتتبَّع في المهام والتغييرات التي تنتظر المزامنة — مع نصيحة لتحسين كل منها.';

  @override
  String get statsMetricGl10Formula =>
      'نسبة تسجيل العادات والوحدات المجهولة (آخر 30 يومًا)؛ حصة التسجيل المتأخر (> 24 ساعة)؛ تغطية الوقت الفعلي = التكرارات المنجزة ذات الوقت المتتبَّع ÷ التكرارات المنجزة؛ التغييرات التي تنتظر المزامنة.';

  @override
  String get statsMetricGl10Title => 'جودة البيانات';

  @override
  String get statsMetricHbH01Desc => 'مدى رسوخ العادة — الأيام الأحدث وزنها أكبر.';

  @override
  String get statsMetricHbH01Formula => 'نتيجة Loop: النتيجة = السابقة × m + الرصيد × (1 − m)، m = 0.5^(√f ÷ 13).';

  @override
  String get statsMetricHbH01Title => 'قوة العادة';

  @override
  String get statsMetricHbH02Desc => 'وحدات ناجحة متتالية حتى الآن؛ يبقى اليوم مفتوحًا حتى نهايته.';

  @override
  String get statsMetricHbH02Formula => 'محرك السلاسل: التخطي والعذر والإيقاف والتجميد محايدة.';

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
  String get statsMetricHbH05Formula => 'المنجز ÷ (الوحدات المجدولة المغلقة − المعذورة)؛ مجال ويلسون تحت 20 وحدة.';

  @override
  String get statsMetricHbH05Title => 'معدل النجاح';

  @override
  String get statsMetricHbH06Desc => 'كيف انتهت كل وحدة مجدولة.';

  @override
  String get statsMetricHbH06Formula => 'عدد الوحدات الناجحة والجزئية وغير المنجزة والفائتة والمتخطّاة والمعذورة.';

  @override
  String get statsMetricHbH06Title => 'عدد النتائج';

  @override
  String get statsMetricHbH07Desc => 'النجاحات (والحجم) لكل أسبوع أو شهر أو سنة.';

  @override
  String get statsMetricHbH07Formula => 'مجاميع لكل فترة.';

  @override
  String get statsMetricHbH07Title => 'السجل';

  @override
  String get statsMetricHbH08Desc => 'حالة كل يوم.';

  @override
  String get statsMetricHbH08Formula => 'خانة لكل يوم: منجز، جزئي، غير منجز، فائت، متخطّى، معذور، متوقف، مجمّد.';

  @override
  String get statsMetricHbH08Title => 'التقويم';

  @override
  String get statsMetricHbH09Desc => 'كل تسجيل صوت للشخص الذي تريد أن تكونه.';

  @override
  String get statsMetricHbH09Formula => 'العدد الكلي لتسجيلات الإنجاز والتقدم اليدوية.';

  @override
  String get statsMetricHbH09Title => 'إجمالي التكرارات';

  @override
  String get statsMetricHbH10Desc => 'مقدار ما بلغته من هدف الفترة.';

  @override
  String get statsMetricHbH10Formula => 'المُنجَز ÷ (الهدف اليومي × الأيام المجدولة − الأيام المتخطّاة).';

  @override
  String get statsMetricHbH10Title => 'التقدّم نحو الهدف';

  @override
  String get statsMetricHbH11Desc => 'كل ما سجلته بوحدة العادة.';

  @override
  String get statsMetricHbH11Formula => 'مجموع القيم المسجلة في الفترة وعلى الإطلاق.';

  @override
  String get statsMetricHbH11Title => 'الحجم الإجمالي';

  @override
  String get statsMetricHbH25Desc =>
      'نسبة ما سُجِّل فعلًا من تاريخ هذه العادة. اليوم غير المسجَّل مجهول وليس فشلًا: يُحتسب فائتًا فقط لأنه لم يُسجَّل فيه شيء.';

  @override
  String get statsMetricHbH25Formula =>
      'نسبة التسجيل = الوحدات التي فيها أي تسجيل ÷ الوحدات المجدولة المغلقة · الوحدات المجهولة = الوحدات الفائتة دون أي تسجيل · حصة التسجيل المتأخر = التسجيلات المُنشأة بعد أكثر من 24 ساعة من انتهاء وحدتها ÷ كل التسجيلات.';

  @override
  String get statsMetricHbH25Title => 'اكتمال البيانات';

  @override
  String get statsMetricHbX01Desc => 'العادات المستحقة المنجزة اليوم.';

  @override
  String get statsMetricHbX01Formula => 'المنجز ÷ المستحق اليوم (عادات البناء).';

  @override
  String get statsMetricHbX01Title => 'تقدّم اليوم';

  @override
  String get statsMetricHbX02Desc => 'أيام أُنجزت فيها كل العادات المستحقة.';

  @override
  String get statsMetricHbX02Formula => 'أيام أُنجزت فيها كل الوحدات المستحقة؛ سلسلة الأيام المثالية.';

  @override
  String get statsMetricHbX02Title => 'أيام مثالية';

  @override
  String get statsMetricHbX03Desc => 'مقدار ما أنجزته من عادات كل يوم.';

  @override
  String get statsMetricHbX03Formula => 'لكل يوم: المنجز ÷ المستحق لكل العادات.';

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
  String get statsMetricHbX05Desc => 'المال الموفَّر والوحدات المتجنَّبة والعمر المستعاد لكل متتبعات الإقلاع.';

  @override
  String get statsMetricHbX05Formula => 'مجاميع متتبعات الإقلاع النشطة (العمر المستعاد تقدير سكاني).';

  @override
  String get statsMetricHbX05Title => 'ملخص الإقلاع';

  @override
  String get statsMetricHbX12Desc =>
      'مقاييس الاكتمال نفسها لكل العادات: نسبة التسجيل والوحدات غير المسجَّلة (المجهولة) والتسجيل المتأخر.';

  @override
  String get statsMetricHbX12Formula =>
      'Σ الوحدات التي فيها تسجيل ÷ Σ الوحدات المجدولة المغلقة لكل العادات؛ Σ الوحدات المجهولة؛ Σ التسجيلات المتأخرة ÷ Σ التسجيلات.';

  @override
  String get statsMetricHbX12Title => 'اكتمال البيانات (كل العادات)';

  @override
  String get statsMetricPlS01Desc => 'عدد مرات استحقاق السلسلة خلال الفترة.';

  @override
  String get statsMetricPlS01Formula => 'مرات قاعدة التكرار ضمن الفترة؛ المغلقة والمفتوحة تُحسب كلٌّ على حدة.';

  @override
  String get statsMetricPlS01Title => 'المرات المتوقعة';

  @override
  String get statsMetricPlS02Desc => 'توزيع مرات السلسلة حسب النتيجة.';

  @override
  String get statsMetricPlS02Formula => 'عدد المرات المنجزة (D) والفائتة (M) والمتخطّاة (K) والمعذورة (X).';

  @override
  String get statsMetricPlS02Title => 'منجز وفائت ومتخطّى';

  @override
  String get statsMetricPlS03Desc => 'نسبة المرات المستحقة التي أنجزتها.';

  @override
  String get statsMetricPlS03Formula => 'المنجز ÷ (المتوقع − المعذور)، مع خط متحرك لأربعة أسابيع واتجاه أسبوعي.';

  @override
  String get statsMetricPlS03Title => 'الالتزام';

  @override
  String get statsMetricPlS04Desc => 'نسبة المرات المستحقة الفائتة أو غير المنجزة.';

  @override
  String get statsMetricPlS04Formula => '(الفائت + غير المنجز) ÷ (المتوقع − المعذور).';

  @override
  String get statsMetricPlS04Title => 'معدل الفوات';

  @override
  String get statsMetricPlS05Desc => 'مرات منجزة متتالية؛ التخطي محايد افتراضيًا.';

  @override
  String get statsMetricPlS05Formula => 'محرك السلاسل بوحدة لكل مرة.';

  @override
  String get statsMetricPlS05Title => 'السلسلة الحالية والأفضل';

  @override
  String get statsMetricPlS06Desc => 'الوقت المتتبَّع والمخطَّط التراكمي منذ بدء السلسلة.';

  @override
  String get statsMetricPlS06Formula => 'مجاميع تراكمية للدقائق الفعلية والمخطَّطة.';

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
  String get statsMetricPlS09Formula => 'أسوأ نتيجة في اليوم: فائت > جزئي > متأخر > متخطّى > منجز > معذور.';

  @override
  String get statsMetricPlS09Title => 'تقويم النتائج';

  @override
  String get statsMetricPlT01Desc => 'المدة التي خُطِّط أن تستغرقها هذه المرة.';

  @override
  String get statsMetricPlT01Formula => 'نهاية مخطَّطة − بداية مخطَّطة.';

  @override
  String get statsMetricPlT01Title => 'المدة المخطَّطة';

  @override
  String get statsMetricPlT02Desc => 'الوقت المتتبَّع فعليًا لهذه المرة دون فترات التوقف.';

  @override
  String get statsMetricPlT02Formula => 'مجموع مدد الجلسات المتتبَّعة؛ غير معروفة إن لم يُتتبَّع شيء.';

  @override
  String get statsMetricPlT02Title => 'المدة الفعلية';

  @override
  String get statsMetricPlT03Desc => 'الفرق بين الوقت الفعلي والمخطَّط ونسبتهما.';

  @override
  String get statsMetricPlT03Formula => 'الفعلي − المخطَّط؛ النسبة R = الفعلي ÷ المخطَّط (عندما يكون المخطَّط ≥ 5 د).';

  @override
  String get statsMetricPlT03Title => 'فرق المدة';

  @override
  String get statsMetricPlT04Desc => 'مدى تقدّم أو تأخر البدء مقارنة بالخطة.';

  @override
  String get statsMetricPlT04Formula => 'بداية أول جلسة − البداية المخطَّطة؛ في الوقت ضمن هامش السماح.';

  @override
  String get statsMetricPlT04Title => 'تأخر البدء';

  @override
  String get statsMetricPlT05Desc => 'مدى تقدّم أو تأخر إنهاء هذه المرة.';

  @override
  String get statsMetricPlT05Formula => 'وقت الإنجاز (أو نهاية آخر جلسة للمؤقت) − النهاية المخطَّطة.';

  @override
  String get statsMetricPlT05Title => 'تأخر الإنهاء';

  @override
  String get statsMetricPlT06Desc => 'ما حدث لهذه المرة.';

  @override
  String get statsMetricPlT06Formula => 'منجز في الوقت أو متأخرًا، جزئي، متخطّى، فائت، ملغى، قيد الانتظار أو قادم.';

  @override
  String get statsMetricPlT06Title => 'النتيجة';

  @override
  String get statsMetricPlT07Desc => 'منذ متى تأخرت مرة لم تُنجز بعد.';

  @override
  String get statsMetricPlT07Formula => 'الآن − النهاية المخطَّطة، مجمّعة 1 / 7 / 14 / 30+ يومًا.';

  @override
  String get statsMetricPlT07Title => 'عمر التأخر';

  @override
  String get statsMetricPlX01Desc => 'نسبة ما أنجزته مما كان مخطَّطًا في بداية الفترة.';

  @override
  String get statsMetricPlX01Formula => 'المخطَّط والمنجز في الفترة ÷ المخطَّط عند بدايتها؛ الإضافات اللاحقة مستبعدة.';

  @override
  String get statsMetricPlX01Title => 'الإنجاز مقابل الخطة';

  @override
  String get statsMetricPlX02Desc => 'المهام المخطَّطة والمنجزة لكل يوم.';

  @override
  String get statsMetricPlX02Formula => 'لكل يوم: عدد المخطَّط (لقطة الخطة) والمنجز.';

  @override
  String get statsMetricPlX02Title => 'المنجز مقابل المخطَّط يوميًا';

  @override
  String get statsMetricPlX03Desc => 'مهام أُضيفت بعد بدء الفترة ومهام نُقلت خارجها أو إليها.';

  @override
  String get statsMetricPlX03Formula => 'عدد الإضافات غير المخطَّطة والمرات المنقولة خارجًا وداخلًا.';

  @override
  String get statsMetricPlX03Title => 'غير المخطَّط والمنقول';

  @override
  String get statsMetricPlX04Desc => 'المهام المُنشأة مقابل المنجزة أسبوعيًا، والمتراكم المفتوح.';

  @override
  String get statsMetricPlX04Formula => 'المُنشأ والمنجز أسبوعيًا؛ المتراكم = مهام غير مجدولة + مرات متأخرة.';

  @override
  String get statsMetricPlX04Title => 'تدفق المتراكم';

  @override
  String get statsMetricPlX05Desc => 'نسبة المهام المنجزة قبل نهايتها المخطَّطة.';

  @override
  String get statsMetricPlX05Formula => 'المنجز في الوقت ÷ المنجز (بما في ذلك هامش السماح).';

  @override
  String get statsMetricPlX05Title => 'الإنجاز في الوقت';

  @override
  String get statsMetricPlX06Desc => 'مهام غير منجزة تجاوزت نهايتها المخطَّطة، حسب العمر.';

  @override
  String get statsMetricPlX06Formula => 'المرات المفتوحة المتأخرة مجمّعة 1 / 7 / 14 / 30+ يومًا.';

  @override
  String get statsMetricPlX06Title => 'المتأخر الآن';

  @override
  String get statsMetricPlX07Desc => 'الوقت المتاح للعمل المخطَّط خلال الفترة.';

  @override
  String get statsMetricPlX07Formula => 'ساعات العمل اليومية ناقص الفترات غير المتاحة، مجمّعة على الفترة.';

  @override
  String get statsMetricPlX07Title => 'السعة';

  @override
  String get statsMetricPlX08Desc => 'مقدار السعة المشغول بالمهام المخطَّطة.';

  @override
  String get statsMetricPlX08Formula => 'الدقائق المخطَّطة داخل ساعات العمل ÷ السعة (قد تتجاوز 100 % مع التداخل).';

  @override
  String get statsMetricPlX08Title => 'الاستغلال المخطَّط';

  @override
  String get statsMetricPlX09Desc => 'مقدار السعة المستهلَك في عمل متتبَّع.';

  @override
  String get statsMetricPlX09Formula => 'الدقائق المتتبَّعة داخل ساعات العمل ÷ السعة؛ يتطلب تغطية تتبع 60 %.';

  @override
  String get statsMetricPlX09Title => 'الاستغلال الفعلي';

  @override
  String get statsMetricPlX10Desc => 'أيام خُطِّط فيها أكثر من الوقت المتاح.';

  @override
  String get statsMetricPlX10Formula => 'أيام الحمل المخطَّط فيها > السعة؛ دقائق الزيادة = الحمل − السعة.';

  @override
  String get statsMetricPlX10Title => 'أيام مُثقلة';

  @override
  String get statsMetricPlX11Desc => 'السعة المتبقية من الآن حتى نهاية الفترة.';

  @override
  String get statsMetricPlX11Formula => 'السعة المتبقية − الوقت المخطَّط المتبقي (من الآن).';

  @override
  String get statsMetricPlX11Title => 'الوقت الحر المتبقي';

  @override
  String get statsMetricPlX12Desc => 'الوقت المخطَّط والمتتبَّع لكل يوم وتصنيف.';

  @override
  String get statsMetricPlX12Formula => 'مجموع الدقائق المخطَّطة مقابل مجموع الدقائق المتتبَّعة.';

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
  String get statsMetricPlX15Desc => 'نسبة الوقت المخطَّط الذي تشغله الأحداث بدل المهام.';

  @override
  String get statsMetricPlX15Formula => 'دقائق الأحداث ÷ (دقائق الأحداث + المهام).';

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
  String get statsMetricQt02Formula => 'الآن − الأحدث من (تاريخ الإقلاع، آخر استخدام) (مباشر).';

  @override
  String get statsMetricQt02Title => 'الامتناع الحالي';

  @override
  String get statsMetricQt03Desc => 'أطول فترة لديك دون استخدام.';

  @override
  String get statsMetricQt03Formula => 'أطول فجوة بين الإقلاع ومرات الاستخدام والآن.';

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
  String get statsMetricQt05Formula => 'أيام الامتناع ÷ الأيام المغلقة منذ الإقلاع.';

  @override
  String get statsMetricQt05Title => 'نسبة أيام الامتناع';

  @override
  String get statsMetricQt06Desc => 'عدد الوحدات التي لم تستهلكها بفضل الإقلاع.';

  @override
  String get statsMetricQt06Formula => 'خط الأساس اليومي × الأيام − الوحدات المستهلكة (بحد أدنى 0).';

  @override
  String get statsMetricQt06Title => 'الوحدات المتجنَّبة';

  @override
  String get statsMetricQt07Desc => 'المال الذي لم تنفقه بفضل الإقلاع.';

  @override
  String get statsMetricQt07Formula => 'الوحدات المتجنَّبة يوميًا × سعر الوحدة الساري في ذلك اليوم.';

  @override
  String get statsMetricQt07Title => 'المال الموفَّر';

  @override
  String get statsMetricQt08Desc => 'المال المُنفَق على مرات الاستخدام منذ الإقلاع.';

  @override
  String get statsMetricQt08Formula => 'الوحدات المستهلكة × سعر الوحدة حينها.';

  @override
  String get statsMetricQt08Title => 'المُنفَق في الزلّات';

  @override
  String get statsMetricQt09Desc => 'ما ستوفره إذا واصلت.';

  @override
  String get statsMetricQt09Formula => 'خط الأساس الحالي × سعر الوحدة على الشهر والسنة والسنوات الخمس القادمة.';

  @override
  String get statsMetricQt09Title => 'إسقاط المدخرات';

  @override
  String get statsMetricQt10Desc => 'تقدير سكاني لمتوسط العمر المستعاد — ليس تنبؤًا شخصيًا.';

  @override
  String get statsMetricQt10Formula =>
      'الوحدات المتجنَّبة × دقائق العمر لكل وحدة (≈ 20 دقيقة للسيجارة، Jackson وآخرون 2025).';

  @override
  String get statsMetricQt10Title => 'العمر المستعاد';

  @override
  String get statsMetricQt11Desc => 'محطات التعافي المعتادة بعد آخر سيجارة.';

  @override
  String get statsMetricQt11Formula => 'التقدّم = الامتناع الحالي ÷ زمن المحطة؛ يُعاد تشغيل العدّاد بعد الزلّة.';

  @override
  String get statsMetricQt11Title => 'محطات صحية';

  @override
  String get statsMetricQt12Desc => 'كم مرة بقيت ضمن حدك اليومي ومقدار ما خفّضته.';

  @override
  String get statsMetricQt12Formula => 'الأيام ضمن الحد ÷ الأيام؛ الخفض = 1 − متوسط الاستهلاك ÷ خط الأساس.';

  @override
  String get statsMetricQt12Title => 'تقدّم الخفض';

  @override
  String get statsMetricQt13Desc => 'مدى تكرار الرغبات الملحّة وشدتها.';

  @override
  String get statsMetricQt13Formula => 'الرغبات يوميًا خلال الفترة؛ متوسط وأقصى شدة؛ متوسط متحرك لسبعة أيام.';

  @override
  String get statsMetricQt13Title => 'عبء الرغبات';

  @override
  String get statsMetricQt14Desc => 'ما يثير الرغبات وأين ومتى.';

  @override
  String get statsMetricQt14Formula => 'باريتو حسب المحفّز والمكان والمزاج؛ مصفوفة اليوم × الساعة.';

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
  String get statsNoteLimitHabit => 'تعرض عادات الحد الأيام ضمن الحد بدلًا من ذلك.';

  @override
  String get statsNoteLowCoverage => 'تتبّع الوقت لـ 60 % على الأقل من المهام المنجزة لرؤية هذا.';

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
  String get statsNoteNoLifeEstimate => 'حدّد دقائق العمر لكل وحدة لرؤية هذا التقدير.';

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
  String get statsNoteNotSmoking => 'تُعرض المحطات الصحية لمتتبعات التدخين فقط.';

  @override
  String get statsNoteNotStarted => 'لم يبدأ';

  @override
  String get statsNoteNotTracked => 'الوقت الفعلي غير متتبَّع';

  @override
  String get statsNotePastPeriod => 'للفترات الحالية والمستقبلية فقط.';

  @override
  String get statsNotePopulationEstimate => 'تقدير سكاني';

  @override
  String get statsNoteUnloggedNotFailed =>
      'الأيام غير المسجَّلة مجهولة وليست فشلًا — تُحتسب فائتة فقط لعدم تسجيل أي شيء فيها.';

  @override
  String get statsNoteUsedPlanned => 'يُعرض الوقت المخطَّط: الوقت الفعلي متتبَّع لأقل من 60 % من المهام المنجزة.';

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
  String get statsQuitMilestoneCancers20y => 'خطر سرطانات الفم والحلق والحنجرة والبنكرياس قريب من خطر من لم يدخن قط';

  @override
  String get statsQuitMilestoneChd15y => 'خطر أمراض القلب التاجية قريب من خطر غير المدخن';

  @override
  String get statsQuitMilestoneChdAdded => 'ينخفض الخطر الإضافي لأمراض القلب التاجية إلى النصف';

  @override
  String get statsQuitMilestoneCirculation => 'تتحسن الدورة الدموية ووظائف الرئة';

  @override
  String get statsQuitMilestoneCo12h => 'يعود أول أكسيد الكربون في الدم إلى المستوى الطبيعي';

  @override
  String get statsQuitMilestoneCo8h => 'ينخفض أول أكسيد الكربون في الدم إلى النصف ويتعافى مستوى الأكسجين';

  @override
  String get statsQuitMilestoneCravings => 'تخف الرغبات عادةً (تستمر الرغبة الواحدة نحو 3–5 دقائق)';

  @override
  String get statsQuitMilestoneHeart20m => 'ينخفض معدل ضربات القلب وضغط الدم ويعود النبض إلى طبيعته';

  @override
  String get statsQuitMilestoneHeartAttack => 'ينخفض خطر النوبة القلبية بشدة';

  @override
  String get statsQuitMilestoneHeartHalf1y => 'خطر أمراض القلب التاجية نحو نصف خطر المدخن';

  @override
  String get statsQuitMilestoneLifeExpectancy =>
      'الإقلاع في سن 30 / 40 / 50 / 60 يضيف نحو 10 / 9 / 6 / 3 سنوات إلى متوسط العمر';

  @override
  String get statsQuitMilestoneLungCancer10y => 'خطر سرطان الرئة نحو نصف خطر المدخن';

  @override
  String get statsQuitMilestoneLungs => 'يقل السعال وضيق التنفس وتتحسن وظائف الرئة بنحو 10 %';

  @override
  String get statsQuitMilestoneMouthCancer =>
      'ينخفض خطر سرطانات الفم والحلق والحنجرة إلى النصف ويتراجع خطر السكتة الدماغية';

  @override
  String get statsQuitMilestoneNicotine24h => 'تنخفض النيكوتين في الدم إلى الصفر';

  @override
  String get statsQuitMilestoneTaste48h => 'تتخلص الرئتان من المخاط ويتحسن التذوق والشم';

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
  String get statsSectionDataQuality => 'جودة البيانات';

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
  String get tagsEmptyHint => 'الوسوم تعمل عبر كل الأقسام — استخدمها لسياقات مثل المشتريات أو بانتظار الآخرين.';

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
  String get tasksAddTag => 'إضافة وسم';

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
  String get tasksBulkAddTags => 'إضافة وسوم';

  @override
  String get tasksBulkDelete => 'حذف';

  @override
  String tasksBulkDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حذف $count عنصر؟',
      many: 'حذف $count عنصرًا؟',
      few: 'حذف $count عناصر؟',
      two: 'حذف عنصرين؟',
      one: 'حذف عنصر واحد؟',
      zero: 'لا شيء للحذف',
    );
    return '$_temp0';
  }

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
  String get tasksChecklistNew => 'قائمة جديدة';

  @override
  String get tasksChecklistNewName => 'اسم القائمة';

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
  String get tasksDayDoneAll => 'وضع علامة منجز على كل ما تبقى';

  @override
  String tasksDayDoneAllSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم إنجاز $count مهمة',
      many: 'تم إنجاز $count مهمة',
      few: 'تم إنجاز $count مهام',
      two: 'تم إنجاز مهمتين',
      one: 'تم إنجاز مهمة واحدة',
      zero: 'لم يتبق شيء',
    );
    return '$_temp0';
  }

  @override
  String get tasksDayMoveTomorrow => 'نقل غير المنجز إلى الغد';

  @override
  String tasksDayMoveTomorrowSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نُقلت $count مهمة إلى الغد',
      many: 'نُقلت $count مهمة إلى الغد',
      few: 'نُقلت $count مهام إلى الغد',
      two: 'نُقلت مهمتان إلى الغد',
      one: 'نُقلت مهمة واحدة إلى الغد',
      zero: 'لا شيء للنقل',
    );
    return '$_temp0';
  }

  @override
  String get tasksDaySkipRest => 'تخطي بقية اليوم';

  @override
  String tasksDaySkipRestSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تخطي $count مهمة',
      many: 'تم تخطي $count مهمة',
      few: 'تم تخطي $count مهام',
      two: 'تم تخطي مهمتين',
      one: 'تم تخطي مهمة واحدة',
      zero: 'لم يتبق شيء للتخطي',
    );
    return '$_temp0';
  }

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
  String get tasksFieldTags => 'الوسوم';

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
  String get tasksNotifAlreadyClosed => 'تم إنجازها أو تخطيها بالفعل';

  @override
  String get tasksNotifGone => 'هذه المهمة لم تعد موجودة';

  @override
  String get tasksOccurrenceDeleted => 'تمت إزالة الموعد';

  @override
  String tasksOpenLinkBody(String url) {
    return 'سيُفتح $url خارج Everslot.';
  }

  @override
  String get tasksOpenLinkTitle => 'فتح الرابط؟';

  @override
  String get tasksOrphansBody => 'المواعيد التي لها سجل تُحفظ دائمًا كمهام منفردة.';

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
  String tasksQuotaIndicator(String title, int done, int total, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'اليوم',
      'week': 'هذا الأسبوع',
      'month': 'هذا الشهر',
      'year': 'هذه السنة',
      'other': 'في هذه الفترة',
    });
    return '$title · $done/$total $_temp0';
  }

  @override
  String tasksQuotaIndicatorDone(String title, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'اكتمل لهذا اليوم',
      'week': 'اكتمل لهذا الأسبوع',
      'month': 'اكتمل لهذا الشهر',
      'year': 'اكتمل لهذه السنة',
      'other': 'اكتمل لهذه الفترة',
    });
    return '$title · $_temp0';
  }

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
  String get tasksScopeThisDisabled => 'لموعد واحد يمكن تغيير الوقت والمدة والعنوان والملاحظات فقط.';

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
  String get tasksTemplatesEmpty => 'لا توجد قوالب. احفظ مهمة كقالب من قائمتها.';

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
  String get tasksTrackingEventHint => 'فترة زمنية (اجتماع، وجبة): بلا خانة تأشير ولا تفوت أبدًا.';

  @override
  String get tasksTrackingTimer => 'مؤقت';

  @override
  String get tasksTrackingTimerHint => 'تتبّع الوقت الذي تقضيه؛ تكتمل عند إيقاف المؤقت.';

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

  @override
  String undoDoneSnack(String action) {
    return 'تم التراجع: $action';
  }

  @override
  String get undoNothing => 'لا شيء للتراجع عنه';

  @override
  String get voiceNoteDiscard => 'تجاهل';

  @override
  String get voiceNoteHint => 'اضغط على الميكروفون وتحدّث.';

  @override
  String get voiceNoteMicPrimerBody =>
      'يستخدم Everslot الميكروفون فقط أثناء تسجيل ملاحظة صوتية. تبقى التسجيلات على جهازك حتى تُرفع إلى حسابك.';

  @override
  String get voiceNoteMicPrimerTitle => 'الوصول إلى الميكروفون';

  @override
  String get voiceNoteRecord => 'بدء التسجيل';

  @override
  String voiceNoteRecording(String duration) {
    return 'جارٍ التسجيل، $duration';
  }

  @override
  String get voiceNoteSave => 'إرفاق';

  @override
  String get voiceNoteStop => 'إيقاف التسجيل';

  @override
  String get voiceNoteTitle => 'ملاحظة صوتية';
}
