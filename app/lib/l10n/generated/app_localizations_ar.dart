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
  String get authAvatarChange => 'تغيير الصورة';

  @override
  String get authAvatarRemove => 'إزالة الصورة';

  @override
  String get authBrowserFlowStarted =>
      'أكمل تسجيل الدخول في المتصفح ثم عُد إلى Everslot.';

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
  String get authErrorIdentityInUse =>
      'طريقة تسجيل الدخول هذه مرتبطة بحساب آخر.';

  @override
  String get authErrorInvalidCode => 'هذا الرمز غير صالح أو منتهي الصلاحية.';

  @override
  String get authErrorInvalidEmail => 'يُرجى إدخال بريد إلكتروني صحيح.';

  @override
  String get authErrorLastIdentity =>
      'لا يمكنك إزالة طريقة تسجيل الدخول الوحيدة لديك.';

  @override
  String get authErrorNotConfigured =>
      'المزامنة السحابية غير مُعدّة في هذا الإصدار (راجع guide.md).';

  @override
  String get authErrorOffline =>
      'أنت غير متصل بالإنترنت. تحقّق من اتصالك ثم أعد المحاولة.';

  @override
  String get authErrorProviderNotConfigured =>
      'طريقة تسجيل الدخول هذه غير مُعدّة بعد (راجع guide.md).';

  @override
  String get authErrorRateLimited =>
      'محاولات كثيرة جدًا. انتظر قليلًا ثم أعد المحاولة.';

  @override
  String get authErrorSessionExpired =>
      'انتهت صلاحية جلستك. يُرجى تسجيل الدخول مجددًا.';

  @override
  String get authErrorUnknown => 'حدث خطأ ما. يُرجى إعادة المحاولة.';

  @override
  String get authExportFirst => 'تصدير البيانات';

  @override
  String get authGuestAccount => 'حساب ضيف';

  @override
  String get authGuestBanner =>
      'أنت تستخدم حساب ضيف. أضف بريدًا إلكترونيًا حتى لا تضيع بياناتك إذا حذفت التطبيق.';

  @override
  String get authGuestBannerAction => 'تأمين بياناتي';

  @override
  String get authGuestHint =>
      'جرّب Everslot فورًا وأضف بريدًا إلكترونيًا لاحقًا للاحتفاظ ببياناتك.';

  @override
  String get authHomeZone => 'المنطقة الزمنية الأساسية';

  @override
  String get authLegalNote =>
      'بالمتابعة، فإنك توافق على شروط الخدمة وسياسة الخصوصية.';

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
  String get authLocalOnlyAccountBody =>
      'لم تسجّل الدخول. سجّل الدخول للمزامنة بين أجهزتك وستنتقل بياناتك معك.';

  @override
  String get authMfaBody =>
      'طلب رمز من تطبيق المصادقة عند تسجيل الدخول وقبل حذف الحساب.';

  @override
  String get authMfaDisable => 'إيقاف';

  @override
  String get authMfaEnabled => 'التحقق بخطوتين مفعّل.';

  @override
  String get authMfaEnroll => 'إعداد';

  @override
  String get authMfaEnrollBody =>
      'أضف هذا المفتاح إلى تطبيق المصادقة، ثم أدخل الرمز المكوّن من 6 أرقام الذي يظهر فيه.';

  @override
  String get authMfaSecret => 'مفتاح الإعداد';

  @override
  String get authMfaTitle => 'التحقق بخطوتين';

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
  String get authSignOutBody =>
      'ستُزال بياناتك من هذا الجهاز، وتبقى آمنة في حسابك.';

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
  String get authUpdateRequired =>
      'حدّث Everslot لمواصلة المزامنة. تغييراتك محفوظة على هذا الجهاز.';

  @override
  String get authUpgradeBody =>
      'أضف طريقة تسجيل دخول إلى حساب الضيف. ستبقى بياناتك كما هي تمامًا.';

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
  String get authUseLocalOnlyHint =>
      'بدون حساب وبدون مزامنة. سجّل الدخول لاحقًا وستنتقل بياناتك معك.';

  @override
  String get authVerify => 'تحقّق';

  @override
  String get authWelcomeBody =>
      'سجّل الدخول لمزامنة خططك وقوائمك وعاداتك على جميع أجهزتك.';

  @override
  String get authWelcomeTitle => 'مرحبًا بك في Everslot';

  @override
  String authZoneChangedBody(String zone) {
    return 'أنت الآن في $zone. تحتفظ المهام ذات التوقيت الثابت بوقتها الدقيق وتتبعك المهام المرنة. هل تريد جعل $zone منطقتك الزمنية الأساسية؟';
  }

  @override
  String get authZoneChangedTitle => 'منطقة زمنية جديدة';

  @override
  String authZoneKeepHome(String zone) {
    return 'الإبقاء على $zone';
  }

  @override
  String get authZoneMakeHome => 'جعلها الأساسية';

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
