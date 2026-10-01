import 'package:material_ui/material_ui.dart';

/// Curated icons for categories, habits, checklists (T2.3.04). Stored in the DB by key.
class CatalogIcon {
  const CatalogIcon(this.key, this.icon, this.keywords);

  final String key;
  final IconData icon;

  /// Search keywords in EN / FR / AR.
  final String keywords;
}

abstract final class IconCatalog {
  static const all = <CatalogIcon>[
    CatalogIcon('work', Icons.work_outline, 'work job office travail bureau عمل'),
    CatalogIcon('home', Icons.home_outlined, 'home house maison منزل بيت'),
    CatalogIcon('health', Icons.favorite_border, 'health heart santé cœur صحة'),
    CatalogIcon('fitness', Icons.fitness_center, 'fitness gym sport push-ups رياضة'),
    CatalogIcon('run', Icons.directions_run, 'run running course جري'),
    CatalogIcon('walk', Icons.directions_walk, 'walk steps marche مشي'),
    CatalogIcon('bike', Icons.directions_bike, 'bike cycling vélo دراجة'),
    CatalogIcon('study', Icons.school_outlined, 'study school étude école دراسة'),
    CatalogIcon('book', Icons.menu_book, 'book reading lire livre قراءة كتاب'),
    CatalogIcon('write', Icons.edit_note, 'write journal écrire كتابة'),
    CatalogIcon('code', Icons.code, 'code programming développement برمجة'),
    CatalogIcon('meeting', Icons.groups_outlined, 'meeting team réunion اجتماع'),
    CatalogIcon('call', Icons.call_outlined, 'call phone appel اتصال'),
    CatalogIcon('email', Icons.mail_outline, 'email mail courriel بريد'),
    CatalogIcon('shopping', Icons.shopping_cart_outlined, 'shopping groceries courses تسوق'),
    CatalogIcon('money', Icons.savings_outlined, 'money savings argent épargne مال'),
    CatalogIcon('food', Icons.restaurant, 'food meal repas طعام'),
    CatalogIcon('water', Icons.water_drop_outlined, 'water drink eau boire ماء'),
    CatalogIcon('coffee', Icons.coffee_outlined, 'coffee café قهوة'),
    CatalogIcon('sleep', Icons.bedtime_outlined, 'sleep bed sommeil نوم'),
    CatalogIcon('meditate', Icons.self_improvement, 'meditate yoga méditation تأمل'),
    CatalogIcon('pray', Icons.mosque_outlined, 'pray prayer prière صلاة'),
    CatalogIcon('medicine', Icons.medication_outlined, 'medicine pill médicament دواء'),
    CatalogIcon('smoke_free', Icons.smoke_free, 'smoke free quit arrêter fumer تدخين'),
    CatalogIcon('no_drinks', Icons.no_drinks, 'alcohol quit alcool كحول'),
    CatalogIcon('phone_off', Icons.phonelink_erase, 'phone social media écran هاتف'),
    CatalogIcon('game', Icons.sports_esports_outlined, 'game gaming jeux ألعاب'),
    CatalogIcon('music', Icons.music_note_outlined, 'music musique موسيقى'),
    CatalogIcon('art', Icons.palette_outlined, 'art draw dessin فن'),
    CatalogIcon('family', Icons.family_restroom, 'family famille عائلة'),
    CatalogIcon('friends', Icons.people_outline, 'friends social amis أصدقاء'),
    CatalogIcon('pet', Icons.pets, 'pet dog cat animal حيوان'),
    CatalogIcon('plant', Icons.local_florist_outlined, 'plant garden jardin نبات'),
    CatalogIcon('clean', Icons.cleaning_services_outlined, 'clean chores ménage تنظيف'),
    CatalogIcon('laundry', Icons.local_laundry_service_outlined, 'laundry lessive غسيل'),
    CatalogIcon('car', Icons.directions_car_outlined, 'car drive voiture سيارة'),
    CatalogIcon('travel', Icons.flight_takeoff, 'travel trip voyage سفر'),
    CatalogIcon('calendar', Icons.event_outlined, 'calendar event agenda تقويم'),
    CatalogIcon('checklist', Icons.checklist, 'checklist list tasks liste قائمة'),
    CatalogIcon('idea', Icons.lightbulb_outline, 'idea idée فكرة'),
    CatalogIcon('star', Icons.star_border, 'star important étoile نجمة'),
    CatalogIcon('flag', Icons.flag_outlined, 'flag goal objectif هدف'),
    CatalogIcon('trophy', Icons.emoji_events_outlined, 'trophy achievement trophée جائزة'),
    CatalogIcon('timer', Icons.timer_outlined, 'timer focus minuteur مؤقت'),
    CatalogIcon('sun', Icons.wb_sunny_outlined, 'morning sun matin soleil صباح'),
    CatalogIcon('moon', Icons.nights_stay_outlined, 'evening night soir nuit مساء'),
    CatalogIcon('language', Icons.translate, 'language learn langue لغة'),
    CatalogIcon('camera', Icons.photo_camera_outlined, 'photo camera appareil كاميرا'),
  ];

  static final Map<String, CatalogIcon> _byKey = {for (final i in all) i.key: i};

  static IconData iconFor(String? key, {IconData fallback = Icons.label_outline}) => _byKey[key]?.icon ?? fallback;

  static List<CatalogIcon> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((i) => i.key.contains(q) || i.keywords.toLowerCase().contains(q)).toList();
  }
}
