import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/domain/auth_redirect.dart';
import 'package:everslot/features/onboarding/application/onboarding_controller.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/profile/presentation/zone_picker.dart';
import 'package:everslot/features/settings/presentation/widgets/choice_sheet.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// First run after sign-in (T1.5.05 essentials; T8.3.11 tour). Every step can be skipped; the
/// flow ends by writing `profiles.onboarding_completed_at`, then resumes [from] (or Today).
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key, this.from});

  final String? from;

  void _exit(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(AuthRedirect.safeFrom(from) ?? AuthRedirect.home);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    Future<void> finish() async {
      await controller.finish();
      if (context.mounted) _exit(context);
    }

    Future<void> next() async {
      if (await controller.next() && context.mounted) _exit(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.onboardingTitle),
        leading: state.isFirst ? null : BackButton(onPressed: controller.back),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            key: const ValueKey('onboarding-skip'),
            onPressed: state.busy || state.draft == null ? null : () => unawaited(finish()),
            child: Text(l.actionSkip),
          ),
        ],
      ),
      body: SafeArea(
        child: state.draft == null
            ? const LoadingState()
            : switch (state.step) {
                OnboardingStep.essentials => _EssentialsStep(draft: state.draft!),
              },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, Space.sm, Space.xl, Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.steps.length > 1)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: Space.sm),
                  child: Text(l.onboardingStepOf(state.index + 1, state.steps.length), style: context.text.bodySmall),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('onboarding-next'),
                  onPressed: state.busy || state.draft == null ? null : () => unawaited(next()),
                  child: Text(state.isLast ? l.onboardingGetStarted : l.actionContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EssentialsStep extends ConsumerWidget {
  const _EssentialsStep({required this.draft});

  final EssentialsDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final format = AppFormat(locale, use24h: draft.use24h);
    final now = ref.watch(clockProvider).nowUtc();
    final profileLocale = ref.watch(profileProvider).value?.locale;
    final deviceZone = ref.watch(deviceZoneProvider);

    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: Space.xl),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, Space.lg, Space.xl, Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tune, size: 40, color: context.colors.primary),
              const SizedBox(height: Space.md),
              Semantics(header: true, child: Text(l.onboardingEssentialsTitle, style: context.text.headlineSmall)),
              const SizedBox(height: Space.sm),
              Text(
                l.onboardingEssentialsBody,
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        ListTile(
          key: const ValueKey('onboarding-language'),
          leading: const Icon(Icons.translate),
          title: Text(l.onboardingLanguage),
          subtitle: Text(languageLabel(context, profileLocale)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final code = await pickChoice<String>(
              context,
              title: l.onboardingLanguage,
              choices: languageChoices(context),
              selected: profileLocale ?? '',
            );
            if (code != null) await controller.setLanguage(code.isEmpty ? null : code);
          },
        ),
        ListTile(
          key: const ValueKey('onboarding-zone'),
          leading: const Icon(Icons.public),
          title: Text(l.onboardingTimeZone),
          subtitle: Text(zoneDisplay(draft.zone, now)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final zone = await pickTimeZone(
              context,
              current: draft.zone,
              detected: deviceZone,
              title: l.onboardingTimeZone,
            );
            if (zone != null) controller.setZone(zone);
          },
        ),
        ListTile(
          key: const ValueKey('onboarding-week-start'),
          leading: const Icon(Icons.date_range),
          title: Text(l.onboardingWeekStart),
          subtitle: Text(format.weekdayLong(Weekday.fromIso(draft.weekStart))),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final day = await pickChoice<int>(
              context,
              title: l.onboardingWeekStart,
              selected: draft.weekStart,
              choices: [
                for (final iso in const [1, 6, 7, 2, 3, 4, 5]) Choice(iso, format.weekdayLong(Weekday.fromIso(iso))),
              ],
            );
            if (day != null) controller.setWeekStart(day);
          },
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
          child: Row(
            children: [
              Icon(Icons.schedule, color: context.colors.onSurfaceVariant),
              const SizedBox(width: Space.xl),
              Expanded(child: Text(l.onboardingClock, style: context.text.bodyLarge)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
          child: SegmentedButton<bool>(
            key: const ValueKey('onboarding-clock'),
            segments: [
              ButtonSegment(
                value: false,
                label: Text('${l.onboardingClock12}\n${AppFormat(locale, use24h: false).time(LocalTime(13, 30))}'),
              ),
              ButtonSegment(
                value: true,
                label: Text('${l.onboardingClock24}\n${AppFormat(locale).time(LocalTime(13, 30))}'),
              ),
            ],
            selected: {draft.use24h},
            showSelectedIcon: false,
            onSelectionChanged: (s) => controller.setUse24h(s.first),
          ),
        ),
      ],
    );
  }
}
