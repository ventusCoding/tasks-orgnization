import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/profile/application/device_locale.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/profile/domain/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onboarding steps (T1.5.05 essentials; the tour of T8.3.11 adds the others).
enum OnboardingStep { essentials }

/// Editable first-run essentials (T1.5.05).
class EssentialsDraft {
  const EssentialsDraft({required this.zone, required this.weekStart, required this.use24h});

  final String zone;

  /// ISO weekday (1 = Monday … 7 = Sunday).
  final int weekStart;
  final bool use24h;

  EssentialsDraft copyWith({String? zone, int? weekStart, bool? use24h}) =>
      EssentialsDraft(zone: zone ?? this.zone, weekStart: weekStart ?? this.weekStart, use24h: use24h ?? this.use24h);

  @override
  bool operator ==(Object other) =>
      other is EssentialsDraft && other.zone == zone && other.weekStart == weekStart && other.use24h == use24h;

  @override
  int get hashCode => Object.hash(zone, weekStart, use24h);
}

class OnboardingState {
  const OnboardingState({required this.steps, this.index = 0, this.draft, this.busy = false, this.done = false});

  final List<OnboardingStep> steps;
  final int index;

  /// Null until the profile (or its absence) is known.
  final EssentialsDraft? draft;
  final bool busy;

  /// The flow finished (profile written).
  final bool done;

  OnboardingStep get step => steps[index];
  bool get isFirst => index == 0;
  bool get isLast => index == steps.length - 1;

  OnboardingState copyWith({int? index, EssentialsDraft? draft, bool? busy, bool? done}) => OnboardingState(
    steps: steps,
    index: index ?? this.index,
    draft: draft ?? this.draft,
    busy: busy ?? this.busy,
    done: done ?? this.done,
  );
}

final onboardingControllerProvider = NotifierProvider.autoDispose<OnboardingController, OnboardingState>(
  OnboardingController.new,
);

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    ref.listen(profileProvider, (_, next) {
      if (state.draft == null && next.hasValue) state = state.copyWith(draft: defaultsFor(next.value));
    });
    final current = ref.read(profileProvider);
    return OnboardingState(
      steps: const [OnboardingStep.essentials],
      draft: current.hasValue ? defaultsFor(current.value) : null,
    );
  }

  /// Suggested essentials: on a first run the device's zone and the locale's CLDR conventions
  /// (the server-created profile only has generic defaults); afterwards the profile's values.
  EssentialsDraft defaultsFor(Profile? profile) {
    final deviceZone = ref.read(deviceZoneProvider);
    if (profile != null && profile.onboardingDone) {
      return EssentialsDraft(zone: profile.homeTimeZone, weekStart: profile.weekStart, use24h: profile.use24h);
    }
    final zone = profile == null || profile.homeTimeZone == 'UTC' ? deviceZone : profile.homeTimeZone;
    return EssentialsDraft(
      zone: zone,
      weekStart: ref.read(firstRunWeekStartProvider),
      use24h: ref.read(firstRunUse24hProvider),
    );
  }

  EssentialsDraft get _draft => state.draft ?? defaultsFor(null);

  void setZone(String zone) => state = state.copyWith(draft: _draft.copyWith(zone: zone));
  void setWeekStart(int day) => state = state.copyWith(draft: _draft.copyWith(weekStart: day));
  void setUse24h(bool value) => state = state.copyWith(draft: _draft.copyWith(use24h: value));

  /// Language applies immediately (the rest of the flow renders in it).
  Future<void> setLanguage(String? code) => ref.read(profileRepositoryProvider).update(locale: code);

  void back() {
    if (!state.isFirst) state = state.copyWith(index: state.index - 1);
  }

  /// Next step, or [finish] on the last one. Returns true when the flow is complete.
  Future<bool> next() async {
    if (!state.isLast) {
      state = state.copyWith(index: state.index + 1);
      return false;
    }
    await finish();
    return true;
  }

  /// Writes the essentials and marks onboarding complete (T1.5.05; skipping keeps the detected
  /// values). Idempotent.
  Future<void> finish() async {
    if (state.busy) return;
    final draft = _draft;
    final repo = ref.read(profileRepositoryProvider);
    final now = ref.read(clockProvider).nowUtc();
    final deviceZone = ref.read(deviceZoneProvider);
    state = state.copyWith(busy: true);
    try {
      await repo.update(
        homeTimeZone: draft.zone,
        currentTimeZone: deviceZone,
        weekStart: draft.weekStart,
        timeFormat: draft.use24h ? TimeFormat.h24 : TimeFormat.h12,
        onboardingCompletedAt: now,
      );
      if (ref.mounted) state = state.copyWith(busy: false, done: true);
    } on Object {
      if (ref.mounted) state = state.copyWith(busy: false);
      rethrow;
    }
  }
}
