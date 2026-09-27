import 'package:everslot/core/providers.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/data/habit_sections_repository.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Localized names of the default time-of-day sections (T5.1.11), by key.
Map<String, String> defaultSectionNames(AppLocalizations l) => {
  DefaultSections.morning: l.habitsSectionMorning,
  DefaultSections.afternoon: l.habitsSectionAfternoon,
  DefaultSections.evening: l.habitsSectionEvening,
  DefaultSections.anytime: l.habitsSectionAnytime,
};

/// Localized names of the default trigger / place / coping / distraction entries (T5.3.14), by
/// `kind.key` (the format [HabitVocabRepository.seedDefaults] expects).
Map<String, String> defaultVocabNames(AppLocalizations l) => {
  'trigger.stress': l.quitTriggerStress,
  'trigger.coffee': l.quitTriggerCoffee,
  'trigger.alcohol': l.quitTriggerAlcohol,
  'trigger.after_meals': l.quitTriggerAfterMeals,
  'trigger.social': l.quitTriggerSocial,
  'trigger.boredom': l.quitTriggerBoredom,
  'trigger.driving': l.quitTriggerDriving,
  'trigger.work_break': l.quitTriggerWorkBreak,
  'trigger.phone': l.quitTriggerPhone,
  'trigger.waking_up': l.quitTriggerWakingUp,
  'place.home': l.quitPlaceHome,
  'place.work': l.quitPlaceWork,
  'place.car': l.quitPlaceCar,
  'place.bar': l.quitPlaceBar,
  'place.outside': l.quitPlaceOutside,
  'place.friends': l.quitPlaceFriends,
  'coping.breathing': l.quitCopingBreathing,
  'coping.walk': l.quitCopingWalk,
  'coping.water': l.quitCopingWater,
  'coping.gum': l.quitCopingGum,
  'coping.call_friend': l.quitCopingCallFriend,
  'coping.delay_10': l.quitCopingDelay10,
  'distraction.music': l.quitDistractionMusic,
  'distraction.game': l.quitDistractionGame,
  'distraction.read': l.quitDistractionRead,
  'distraction.exercise': l.quitDistractionExercise,
  'distraction.snack': l.quitDistractionSnack,
  'distraction.shower': l.quitDistractionShower,
};

/// Seeds the per-user defaults of the Habits section — the four time-of-day sections (T5.1.11)
/// and the trigger/place/coping/distraction libraries (T5.3.14) — with deterministic ids, so two
/// devices converge. Idempotent and cheap when everything exists.
///
/// Cloud accounts seed only after the first successful pull: another device may already have
/// renamed a default, and fresh local defaults (newer clocks) would overwrite that rename.
class HabitDefaults {
  HabitDefaults({required this.sections, required this.vocab, required this.canSeed});

  final HabitSectionsRepository sections;
  final HabitVocabRepository vocab;

  /// Whether this device may seed now (local account, or the first cloud pull happened).
  final Future<bool> Function() canSeed;

  /// Seeds what is missing; returns false when seeding must wait (first pull pending).
  Future<bool> ensure(AppLocalizations l) async {
    if (!await canSeed()) return false;
    await sections.seedDefaults(defaultSectionNames(l));
    await vocab.seedDefaults(defaultVocabNames(l));
    return true;
  }
}

final habitDefaultsProvider = Provider<HabitDefaults>((ref) {
  final sections = ref.watch(habitSectionsRepositoryProvider);
  return HabitDefaults(
    sections: sections,
    vocab: ref.watch(habitVocabRepositoryProvider),
    canSeed: () async {
      if (!(ref.read(sessionProvider)?.isCloud ?? false)) return true;
      return sections.firstPullDone();
    },
  );
});
