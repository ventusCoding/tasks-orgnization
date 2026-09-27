import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Localized name / description of a template (T5.1.16).
extension TemplateLabels on AppLocalizations {
  String templateName(String key) => switch (key) {
    'pushUps' => habitsTplPushUps,
    'water' => habitsTplWater,
    'read' => habitsTplRead,
    'meditate' => habitsTplMeditate,
    'walk' => habitsTplWalk,
    'sleepEarly' => habitsTplSleepEarly,
    'stretch' => habitsTplStretch,
    'gym' => habitsTplGym,
    'coffeeLimit' => habitsTplCoffeeLimit,
    'journal' => habitsTplJournal,
    'challengePushUps' => habitsTplChallengePushUps,
    'challengeNoSugar' => habitsTplChallengeNoSugar,
    'challengeMeditate' => habitsTplChallengeMeditate,
    _ => key,
  };

  String templateDescription(String key) => switch (key) {
    'pushUps' => habitsTplPushUpsDesc,
    'water' => habitsTplWaterDesc,
    'read' => habitsTplReadDesc,
    'meditate' => habitsTplMeditateDesc,
    'walk' => habitsTplWalkDesc,
    'sleepEarly' => habitsTplSleepEarlyDesc,
    'stretch' => habitsTplStretchDesc,
    'gym' => habitsTplGymDesc,
    'coffeeLimit' => habitsTplCoffeeLimitDesc,
    'journal' => habitsTplJournalDesc,
    'challengePushUps' => habitsTplChallengePushUpsDesc,
    'challengeNoSugar' => habitsTplChallengeNoSugarDesc,
    'challengeMeditate' => habitsTplChallengeMeditateDesc,
    _ => '',
  };
}

/// "Browse templates" (T5.1.16): habits, challenges and quit presets that prefill the editor.
Future<void> showTemplatesSheet(BuildContext context) => showAppSheet<void>(
  context,
  title: context.l10n.habitsTemplatesTitle,
  builder: (ctx) {
    final l = ctx.l10n;
    final habits = [for (final t in HabitTemplate.all) if (!t.isChallenge) t];
    final challenges = [for (final t in HabitTemplate.all) if (t.isChallenge) t];
    Widget tile(HabitTemplate t) => ListTile(
      leading: Icon(IconCatalog.iconFor(t.icon)),
      title: Text(l.templateName(t.key)),
      subtitle: Text(l.templateDescription(t.key)),
      onTap: () {
        Navigator.pop(ctx);
        HabitRoutes.create(context, template: t.key);
      },
    );
    return ListView(
      shrinkWrap: true,
      children: [
        SectionHeader(l.habitsTemplatesHabits),
        for (final t in habits) tile(t),
        SectionHeader(l.habitsTemplatesChallenges),
        for (final t in challenges) tile(t),
        SectionHeader(l.habitsTemplatesQuit),
        for (final p in QuitPreset.all)
          ListTile(
            leading: Icon(IconCatalog.iconFor(p.icon)),
            title: Text(l.quitPresetLabel(p.substance)),
            onTap: () {
              Navigator.pop(ctx);
              HabitRoutes.create(context, kind: 'quit', template: p.key);
            },
          ),
      ],
    );
  },
);
