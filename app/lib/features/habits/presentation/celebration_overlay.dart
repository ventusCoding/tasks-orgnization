import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/goals/application/achievement_service.dart';
import 'package:everslot/features/goals/domain/achievements.dart';
import 'package:everslot/features/goals/presentation/badge_ui.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_celebrations.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Non-blocking celebrations (T5.2.13): listens to committed check-ins, asks the celebration
/// service what they earned (streak milestones, perfect day) and shows dismissible cards at the
/// top with a success haptic — scaling in, or instantly when motion is reduced. Only the top-most
/// route celebrates, so stacked screens never show the same card twice.
class CelebrationOverlay extends ConsumerStatefulWidget {
  const CelebrationOverlay({required this.child, super.key, this.visibleFor = const Duration(seconds: 4)});

  final Widget child;

  /// How long a card stays before it dismisses itself.
  final Duration visibleFor;

  @override
  ConsumerState<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends ConsumerState<CelebrationOverlay> {
  final _items = <Celebration>[];

  Future<void> _onEvent(HabitCheckInEvent event) async {
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final earned = [
      ...await ref.read(celebrationServiceProvider).onCheckIn(event),
      // Badges unlocked by this check-in (T5.4.08).
      if (event.kind == HabitLogKind.done || event.kind == HabitLogKind.progress)
        for (final b in await ref.read(achievementServiceProvider).evaluate())
          Celebration(CelebrationKind.badge, dedupeKey: 'badge|${b.code.wire}|${b.habitId}', badge: b.code.wire),
    ];
    if (!mounted || earned.isEmpty) return;
    unawaited(HapticFeedback.heavyImpact());
    setState(() => _items.addAll(earned));
  }

  void _dismiss(Celebration c) {
    if (mounted) setState(() => _items.remove(c));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(habitCheckInEventsProvider, (_, next) {
      final event = next.value;
      if (event != null) unawaited(_onEvent(event));
    });
    return Stack(
      children: [
        widget.child,
        if (_items.isNotEmpty)
          PositionedDirectional(
            top: Space.sm,
            start: Space.lg,
            end: Space.lg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in _items)
                  _CelebrationCard(
                    c,
                    key: ValueKey(c.dedupeKey),
                    visibleFor: widget.visibleFor,
                    onDismiss: () => _dismiss(c),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CelebrationCard extends StatefulWidget {
  const _CelebrationCard(this.celebration, {required this.visibleFor, required this.onDismiss, super.key});

  final Celebration celebration;
  final Duration visibleFor;
  final VoidCallback onDismiss;

  @override
  State<_CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<_CelebrationCard> with SingleTickerProviderStateMixin {
  // Frame-driven countdown: pauses while the route is hidden, no timers to cancel.
  late final AnimationController _countdown;

  @override
  void initState() {
    super.initState();
    // `preserve`: reduce motion would otherwise shorten this countdown 20-fold.
    _countdown = AnimationController(
      vsync: this,
      duration: widget.visibleFor,
      animationBehavior: AnimationBehavior.preserve,
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDismiss();
      });
    unawaited(_countdown.forward());
  }

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = widget.celebration;
    final (icon, text) = switch (c.kind) {
      CelebrationKind.streak => (Icons.local_fire_department, l.habitsCelebrateStreak(c.habitName ?? '', c.count)),
      CelebrationKind.perfectDay => (Icons.emoji_events, l.habitsCelebratePerfectDay),
      CelebrationKind.badge => switch (AchievementCode.tryParse(c.badge)) {
        final code? => (badgeIcon(code), l.goalsBadgeUnlocked(badgeName(context, code))),
        null => (Icons.emoji_events, l.habitsCelebratePerfectDay),
      },
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: AppMotion.duration(context, Motion.slow),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Semantics(
        liveRegion: true,
        child: Card(
          color: context.colors.tertiaryContainer,
          margin: const EdgeInsetsDirectional.only(bottom: Space.sm),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.xs, Space.sm),
            child: Row(
              children: [
                Icon(icon, color: context.colors.onTertiaryContainer),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    text,
                    style: context.text.titleSmall?.copyWith(color: context.colors.onTertiaryContainer),
                  ),
                ),
                IconButton(
                  tooltip: l.habitsCelebrationDismiss,
                  icon: const Icon(Icons.close),
                  onPressed: widget.onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
