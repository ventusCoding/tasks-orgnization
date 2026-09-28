import 'dart:async';
import 'dart:ui';

import 'package:everslot/features/goals/application/achievement_service.dart';
import 'package:everslot/features/habits/application/habit_defaults.dart';
import 'package:everslot/features/habits/application/streak_freezes.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Startup task of the Habits section (registered in `startup/startup_tasks.dart`): seeds the
/// default time-of-day sections (T5.1.11) and trigger/place/coping libraries (T5.3.14) in the
/// system language. Idempotent; cloud accounts wait for their first pull — the Habits tab calls
/// [HabitDefaults.ensure] again when it opens, so a fresh cloud device gets its defaults later.
Future<void> startHabits(ProviderContainer container) async {
  final system = PlatformDispatcher.instance.locale;
  final l10n = lookupAppLocalizations(
    const [
      Locale('en'),
      Locale('fr'),
      Locale('ar'),
    ].firstWhere((l) => l.languageCode == system.languageCode, orElse: () => const Locale('en')),
  );
  await container.read(habitDefaultsProvider).ensure(l10n);
  // Streak freezes of periods that closed while the app was away (T5.4.06).
  unawaited(container.read(streakFreezeJobProvider).run());
  // Daily pass of the badge engine (milestones reached while the app was closed, T5.4.08).
  unawaited(container.read(achievementServiceProvider).evaluate());
}
