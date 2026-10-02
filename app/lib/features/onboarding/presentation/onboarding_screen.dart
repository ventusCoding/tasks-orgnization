import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/domain/auth_redirect.dart';
import 'package:everslot/features/notifications/application/capabilities_service.dart';
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
                OnboardingStep.welcome => const _WelcomeStep(),
                OnboardingStep.essentials => _EssentialsStep(draft: state.draft!),
                OnboardingStep.track => _TrackStep(tracks: state.tracks),
                OnboardingStep.notifications => const _NotificationsStep(),
                OnboardingStep.starters => _StartersStep(state: state),
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

/// Header shared by the steps.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, Space.lg, Space.xl, Space.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 40, color: context.colors.primary),
        const SizedBox(height: Space.md),
        Semantics(header: true, child: Text(title, style: context.text.headlineSmall)),
        const SizedBox(height: Space.sm),
        Text(body, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
      ],
    ),
  );
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      key: const ValueKey('onboarding-welcome'),
      children: [
        _StepHeader(icon: Icons.wb_sunny_outlined, title: l.onboardingWelcomeTitle, body: l.onboardingWelcomeBody),
        for (final (icon, text) in [
          (Icons.calendar_view_week_outlined, l.onboardingWelcomePlan),
          (Icons.checklist_outlined, l.onboardingWelcomeLists),
          (Icons.local_fire_department_outlined, l.onboardingWelcomeHabits),
          (Icons.insights_outlined, l.onboardingWelcomeInsights),
        ])
          ListTile(leading: Icon(icon), title: Text(text)),
      ],
    );
  }
}

class _TrackStep extends ConsumerWidget {
  const _TrackStep({required this.tracks});

  final Set<TrackArea> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final controller = ref.read(onboardingControllerProvider.notifier);
    return ListView(
      children: [
        _StepHeader(icon: Icons.track_changes, title: l.onboardingTrackTitle, body: l.onboardingTrackBody),
        for (final (area, icon, title, subtitle) in [
          (TrackArea.plan, Icons.calendar_view_week_outlined, l.tabPlan, l.onboardingTrackPlan),
          (TrackArea.lists, Icons.checklist_outlined, l.tabLists, l.onboardingTrackLists),
          (TrackArea.habits, Icons.local_fire_department_outlined, l.tabHabits, l.onboardingTrackHabits),
          (TrackArea.quit, Icons.smoke_free, l.onboardingTrackQuitTitle, l.onboardingTrackQuit),
        ])
          CheckboxListTile(
            key: ValueKey('onboarding-track-${area.name}'),
            secondary: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            value: tracks.contains(area),
            onChanged: (_) => controller.toggleTrack(area),
          ),
      ],
    );
  }
}

/// The step itself is the primer: the OS prompt only follows a tap on "Allow" (T7.2.05).
class _NotificationsStep extends ConsumerWidget {
  const _NotificationsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final caps = ref.watch(notificationCapabilitiesProvider);
    final controller = ref.read(notificationCapabilitiesProvider.notifier);
    final android = caps.platform == 'android';
    return ListView(
      children: [
        _StepHeader(icon: Icons.notifications_active_outlined, title: l.notifPrimerTitle, body: l.notifPrimerBody),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.xl),
          child: caps.notifications
              ? ListTile(
                  key: const ValueKey('onboarding-notif-on'),
                  contentPadding: EdgeInsetsDirectional.zero,
                  leading: Icon(Icons.check_circle, color: context.colors.primary),
                  title: Text(l.onboardingNotificationsOn),
                )
              : FilledButton.tonalIcon(
                  key: const ValueKey('onboarding-notif-allow'),
                  onPressed: () => unawaited(controller.requestNotifications()),
                  icon: const Icon(Icons.notifications_outlined),
                  label: Text(l.notifPrimerAllow),
                ),
        ),
        if (caps.notifications && android && !caps.exactAlarm) ...[
          _StepHeader(icon: Icons.alarm_on_outlined, title: l.notifPrimerExactTitle, body: l.notifPrimerExactBody),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.xl),
            child: OutlinedButton.icon(
              key: const ValueKey('onboarding-exact-allow'),
              onPressed: () => unawaited(controller.requestExactAlarms()),
              icon: const Icon(Icons.alarm_on_outlined),
              label: Text(l.notifAllowPrecise),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, Space.lg, Space.xl, 0),
          child: Text(l.onboardingNotificationsLater, style: context.text.bodySmall),
        ),
      ],
    );
  }
}

class _StartersStep extends ConsumerWidget {
  const _StartersStep({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final offered = state.offeredStarters;
    return ListView(
      children: [
        _StepHeader(
          icon: Icons.auto_awesome_outlined,
          title: l.onboardingStartersTitle,
          body: l.onboardingStartersBody,
        ),
        if (offered.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.xl),
            child: Text(l.onboardingStartersNone),
          ),
        for (final s in offered)
          CheckboxListTile(
            key: ValueKey('onboarding-starter-${s.name}'),
            secondary: Icon(switch (s) {
              StarterTemplate.morningRoutine => Icons.wb_sunny_outlined,
              StarterTemplate.water => Icons.water_drop_outlined,
              StarterTemplate.pushUps => Icons.fitness_center,
              StarterTemplate.quitSmoking => Icons.smoke_free,
            }),
            title: Text(s.label(l)),
            value: state.starters.contains(s),
            onChanged: (_) => controller.toggleStarter(s),
          ),
      ],
    );
  }
}
