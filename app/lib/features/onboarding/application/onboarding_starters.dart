import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/builtin_templates.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart' show DefaultSections;
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

/// What the user wants to track (T8.3.11); filters the starter templates offered.
enum TrackArea { plan, lists, habits, quit }

/// Optional starter content of the onboarding (T8.3.11).
enum StarterTemplate {
  morningRoutine(TrackArea.lists),
  water(TrackArea.habits),
  pushUps(TrackArea.habits),
  quitSmoking(TrackArea.quit);

  StarterTemplate(this.area);

  final TrackArea area;

  String label(AppLocalizations l) => switch (this) {
    morningRoutine => BuiltinTemplates.morningRoutine.parse(l.localeName).title ?? l.onboardingStarterRoutine,
    water => l.habitsTplWater,
    pushUps => l.habitsTplPushUps,
    quitSmoking => l.quitNameCigarettes,
  };
}

/// Creates the chosen starters with the regular services (outbox, reminders defaults).
class OnboardingStarters {
  OnboardingStarters(this._read);

  final T Function<T>(ProviderListenable<T> provider) _read;

  Future<void> create(
    Set<StarterTemplate> starters, {
    required AppLocalizations l10n,
    required LocalDate today,
    required int weekStart,
  }) async {
    for (final s in StarterTemplate.values.where(starters.contains)) {
      switch (s) {
        case StarterTemplate.morningRoutine:
          final parsed = BuiltinTemplates.morningRoutine.parse(l10n.localeName);
          await _read(checklistsRepositoryProvider).create(title: parsed.title ?? s.label(l10n), items: parsed.nodes);
        case StarterTemplate.water || StarterTemplate.pushUps:
          final template = HabitTemplate.all.firstWhere(
            (t) => t.key == (s == StarterTemplate.water ? 'water' : 'pushUps'),
          );
          await _read(habitServiceProvider).create(
            template.toHabit(
              id: Ids.v7(),
              name: s.label(l10n),
              startDate: today,
              sortKey: '',
              weekStart: Weekday.fromIso(weekStart),
              sectionId: _read(habitSectionsRepositoryProvider).defaultId(template.sectionKey),
            ),
          );
        case StarterTemplate.quitSmoking:
          final preset = QuitPreset.all.first;
          await _read(habitServiceProvider).create(
            QuitHabit(
              id: Ids.v7(),
              name: s.label(l10n),
              startDate: today,
              sortKey: '',
              mode: preset.mode,
              quitStartedAt: _read(clockProvider).nowUtc(),
              substance: preset.substance,
              baselinePerDay: preset.baselinePerDay,
              timePerUnitMinutes: preset.timePerUnitMinutes,
              lifeMinutesPerUnit: preset.lifeMinutesPerUnit,
              unit: preset.unit,
              icon: preset.icon,
              sectionId: _read(habitSectionsRepositoryProvider).defaultId(DefaultSections.anytime),
            ),
          );
      }
    }
  }
}

final onboardingStartersProvider = Provider<OnboardingStarters>((ref) => OnboardingStarters(ref.read));
