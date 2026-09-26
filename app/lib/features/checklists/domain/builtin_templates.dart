import 'package:everslot/features/checklists/domain/import_export.dart';
import 'package:meta/meta.dart';

/// A built-in, localized template (T4.5.05). Content is indented Markdown parsed by
/// [ChecklistImport] so nesting is preserved.
@immutable
class BuiltinTemplate {
  const BuiltinTemplate({required this.code, required this.icon, required this.content});

  final String code;
  final String icon;

  /// locale → `# Title` + indented items.
  final Map<String, String> content;

  ImportResult parse(String locale) {
    final lang = locale.split(RegExp('[-_]')).first;
    return ChecklistImport.parseText(content[lang] ?? content['en']!);
  }
}

abstract final class BuiltinTemplates {
  static const all = <BuiltinTemplate>[packing, morningRoutine, weeklyReview, groceries, movingHouse, projectKickoff];

  static BuiltinTemplate? byCode(String code) {
    for (final t in all) {
      if (t.code == code) return t;
    }
    return null;
  }

  static const packing = BuiltinTemplate(
    code: 'packing',
    icon: 'travel',
    content: {
      'en': '''# Packing list
- Documents
  - Passport / ID
  - Tickets & bookings
  - Insurance card
- Clothes
  - Underwear & socks
  - T-shirts
  - Jacket
- Toiletries
  - Toothbrush & toothpaste
  - Medication
- Electronics
  - Phone charger
  - Power bank
  - Adapter''',
      'fr': '''# Liste de bagages
- Documents
  - Passeport / carte d'identité
  - Billets et réservations
  - Carte d'assurance
- Vêtements
  - Sous-vêtements et chaussettes
  - T-shirts
  - Veste
- Trousse de toilette
  - Brosse à dents et dentifrice
  - Médicaments
- Électronique
  - Chargeur de téléphone
  - Batterie externe
  - Adaptateur''',
      'ar': '''# قائمة الأمتعة
- الوثائق
  - جواز السفر / بطاقة الهوية
  - التذاكر والحجوزات
  - بطاقة التأمين
- الملابس
  - الملابس الداخلية والجوارب
  - القمصان
  - السترة
- أدوات النظافة
  - فرشاة ومعجون الأسنان
  - الأدوية
- الأجهزة الإلكترونية
  - شاحن الهاتف
  - بطارية متنقلة
  - محوّل كهربائي''',
    },
  );

  static const morningRoutine = BuiltinTemplate(
    code: 'morning_routine',
    icon: 'sun',
    content: {
      'en': '''# Morning routine
- Drink a glass of water
- Stretch 5 minutes
- Shower
- Breakfast
- Review today's plan
  - Top 3 priorities
  - Check calendar''',
      'fr': '''# Routine du matin
- Boire un verre d'eau
- S'étirer 5 minutes
- Douche
- Petit-déjeuner
- Revoir le plan du jour
  - 3 priorités
  - Consulter l'agenda''',
      'ar': '''# روتين الصباح
- شرب كوب من الماء
- تمارين تمدد لمدة 5 دقائق
- الاستحمام
- الفطور
- مراجعة خطة اليوم
  - أهم 3 أولويات
  - مراجعة التقويم''',
    },
  );

  static const weeklyReview = BuiltinTemplate(
    code: 'weekly_review',
    icon: 'calendar',
    content: {
      'en': '''# Weekly review
- Get clear
  - Empty inbox
  - Process notes
- Get current
  - Review last week's calendar
  - Review upcoming week
  - Check waiting items
- Get creative
  - Someday / maybe ideas
  - Set next week's goals''',
      'fr': '''# Revue hebdomadaire
- Faire le vide
  - Vider la boîte de réception
  - Traiter les notes
- Se mettre à jour
  - Revoir l'agenda de la semaine passée
  - Revoir la semaine à venir
  - Vérifier les éléments en attente
- Être créatif
  - Idées « un jour peut-être »
  - Fixer les objectifs de la semaine''',
      'ar': '''# المراجعة الأسبوعية
- التصفية
  - إفراغ صندوق الوارد
  - معالجة الملاحظات
- المواكبة
  - مراجعة تقويم الأسبوع الماضي
  - مراجعة الأسبوع القادم
  - تفقد العناصر قيد الانتظار
- الإبداع
  - أفكار لاحقة
  - تحديد أهداف الأسبوع القادم''',
    },
  );

  static const groceries = BuiltinTemplate(
    code: 'groceries',
    icon: 'cart',
    content: {
      'en': '''# Groceries
- Produce
  - Fruit
  - Vegetables
- Bakery
  - Bread
- Dairy
  - Milk
  - Eggs
  - Cheese
- Pantry
  - Rice / pasta
  - Olive oil
- Household
  - Dish soap''',
      'fr': '''# Courses
- Fruits et légumes
  - Fruits
  - Légumes
- Boulangerie
  - Pain
- Crèmerie
  - Lait
  - Œufs
  - Fromage
- Épicerie
  - Riz / pâtes
  - Huile d'olive
- Entretien
  - Liquide vaisselle''',
      'ar': '''# البقالة
- الخضار والفواكه
  - فواكه
  - خضار
- المخبز
  - خبز
- الألبان
  - حليب
  - بيض
  - جبن
- المؤونة
  - أرز / معكرونة
  - زيت زيتون
- مستلزمات المنزل
  - سائل غسيل الصحون''',
    },
  );

  static const movingHouse = BuiltinTemplate(
    code: 'moving_house',
    icon: 'home',
    content: {
      'en': '''# Moving house
- 4 weeks before
  - Book movers
  - Declutter
  - Collect boxes
- 2 weeks before
  - Change address
    - Bank
    - Insurance
    - Employer
  - Transfer utilities
- Moving day
  - Meter readings
  - Final walkthrough
  - Hand over keys''',
      'fr': '''# Déménagement
- 4 semaines avant
  - Réserver les déménageurs
  - Trier et désencombrer
  - Récupérer des cartons
- 2 semaines avant
  - Changer d'adresse
    - Banque
    - Assurance
    - Employeur
  - Transférer les contrats d'énergie
- Jour J
  - Relever les compteurs
  - Dernière visite
  - Remettre les clés''',
      'ar': '''# الانتقال إلى منزل جديد
- قبل 4 أسابيع
  - حجز شركة النقل
  - التخلص من الأغراض غير اللازمة
  - جمع الصناديق
- قبل أسبوعين
  - تغيير العنوان
    - البنك
    - التأمين
    - جهة العمل
  - نقل اشتراكات الخدمات
- يوم الانتقال
  - قراءة العدادات
  - الجولة الأخيرة
  - تسليم المفاتيح''',
    },
  );

  static const projectKickoff = BuiltinTemplate(
    code: 'project_kickoff',
    icon: 'work',
    content: {
      'en': '''# Project kickoff
- Define goals
  - Problem statement
  - Success criteria
- Team
  - Roles & owners
  - Communication channel
- Plan
  - Milestones
  - Risks
  - Budget
- Kickoff meeting
  - Agenda
  - Share notes''',
      'fr': '''# Lancement de projet
- Définir les objectifs
  - Énoncé du problème
  - Critères de réussite
- Équipe
  - Rôles et responsables
  - Canal de communication
- Plan
  - Jalons
  - Risques
  - Budget
- Réunion de lancement
  - Ordre du jour
  - Partager le compte rendu''',
      'ar': '''# إطلاق مشروع
- تحديد الأهداف
  - وصف المشكلة
  - معايير النجاح
- الفريق
  - الأدوار والمسؤولون
  - قناة التواصل
- الخطة
  - المراحل الرئيسية
  - المخاطر
  - الميزانية
- اجتماع الانطلاق
  - جدول الأعمال
  - مشاركة المحضر''',
    },
  );
}
