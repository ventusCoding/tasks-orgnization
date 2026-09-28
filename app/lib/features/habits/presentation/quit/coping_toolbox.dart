import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/live_ticker.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/coping.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Coping toolbox of a quit tracker (T5.3.16): a 3-minute craving timer that logs the craving
/// with its duration and the answer to "Did you resist?" in one confirmation, paced breathing
/// (box, 4-7-8) — a growing and shrinking circle, or with reduce motion just the text with a haptic
/// at each phase —, the personal distraction list and the motivation card.
class CopingToolboxScreen extends ConsumerStatefulWidget {
  const CopingToolboxScreen({required this.habitId, super.key});

  final String habitId;

  @override
  ConsumerState<CopingToolboxScreen> createState() => _CopingToolboxScreenState();
}

class _CopingToolboxScreenState extends ConsumerState<CopingToolboxScreen> {
  late final SharedTicker _ticker = ref.read(sharedTickerProvider);
  CravingTimer? _timer;
  BreathingPattern _pattern = BreathingPattern.box;
  DateTime? _breathingSince;
  BreathPhase? _lastPhase;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    _ticker.addListener(_onTick);
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    super.dispose();
  }

  DateTime _now() => ref.read(clockProvider).nowUtc();

  void _onTick() {
    if (!mounted) return;
    final now = _now();
    final since = _breathingSince;
    if (since != null) {
      final phase = _pattern.at(now.difference(since)).phase;
      if (phase != _lastPhase) {
        _lastPhase = phase;
        unawaited(HapticFeedback.selectionClick());
      }
    }
    setState(() {});
    final timer = _timer;
    if (timer != null && timer.finished(now) && !_asking) unawaited(_finishTimer());
  }

  Future<void> _finishTimer() async {
    final timer = _timer;
    final habit = ref.read(habitSnapshotProvider(widget.habitId)).value?.quitHabit;
    if (timer == null || habit == null || _asking) return;
    _asking = true;
    final l = context.l10n;
    final seconds = timer.durationSeconds(_now());
    final resisted = await showDialog<Object>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.quitToolboxDone),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'unsure'), child: Text(l.quitNotSure)),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.quitNo)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.quitYes)),
        ],
      ),
    );
    _asking = false;
    if (!mounted || resisted == null) return;
    final result = await ref.read(quitServiceProvider).logCraving(
      habit,
      at: timer.startedAt,
      input: CravingInput(durationSeconds: seconds, resisted: resisted is bool ? resisted : null),
    );
    setState(() => _timer = null);
    if (mounted) showUndoSnackBar(context, ref, message: l.quitToolboxLogged, record: result.record);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final snapshot = ref.watch(habitSnapshotProvider(widget.habitId)).value;
    final habit = snapshot?.quitHabit;
    if (habit == null) return const Scaffold(body: LoadingState());
    final now = _now();
    final distractions = [
      for (final v in ref.watch(habitVocabProvider).value ?? const <VocabEntry>[])
        if (v.kind == VocabKind.distraction) v,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.quitToolboxTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.xxxl),
        children: [
          _timerCard(context, now),
          SectionHeader(l.quitBreathingTitle, padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs)),
          _breathingCard(context, now),
          SectionHeader(l.quitDistractionsTitle, padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs)),
          if (distractions.isEmpty)
            Text(l.quitDistractionsEmpty, style: context.text.bodySmall)
          else
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [for (final d in distractions) Chip(label: Text(d.name))],
            ),
          if (habit.motivation != null) ...[
            SectionHeader(l.quitMotivationCard, padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs)),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(habit.motivation!, style: context.text.bodyLarge),
                    const SizedBox(height: Space.sm),
                    AttachmentStrip(ownerType: 'habit', ownerId: habit.id, editable: false, showAddButton: false),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timerCard(BuildContext context, DateTime now) {
    final l = context.l10n;
    final timer = _timer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.quitToolboxTimerTitle, style: context.text.titleSmall),
            Text(l.quitToolboxTimerHint, style: context.text.bodySmall),
            const SizedBox(height: Space.md),
            if (timer == null)
              FilledButton.icon(
                onPressed: () => setState(() => _timer = CravingTimer(_now())),
                icon: const Icon(Icons.timer_outlined),
                label: Text(l.quitToolboxStart),
              )
            else ...[
              Center(
                child: ProgressRing(
                  progress: timer.progress(now),
                  size: 120,
                  stroke: 8,
                  semanticsLabel: l.quitToolboxRemaining(AppFormat.counter(timer.remaining(now))),
                  child: Text(AppFormat.counter(timer.remaining(now)), style: context.text.headlineSmall),
                ),
              ),
              const SizedBox(height: Space.md),
              OutlinedButton(onPressed: _finishTimer, child: Text(l.quitToolboxThrough)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _breathingCard(BuildContext context, DateTime now) {
    final l = context.l10n;
    final since = _breathingSince;
    final reduced = AppMotion.reduced(context);
    String phaseLabel(BreathPhase p) => switch (p) {
      BreathPhase.inhale => l.quitBreathIn,
      BreathPhase.exhale => l.quitBreathOut,
      BreathPhase.hold || BreathPhase.holdEmpty => l.quitBreathHold,
    };
    final state = since == null ? null : _pattern.at(now.difference(since));
    // Circle size follows the phase: full while holding in, small while holding out.
    final full = state != null && (state.phase == BreathPhase.inhale || state.phase == BreathPhase.hold);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<BreathingPattern>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: BreathingPattern.box, label: Text(l.quitBreathingBox)),
                ButtonSegment(value: BreathingPattern.relax478, label: Text(l.quitBreathing478)),
              ],
              selected: {_pattern},
              onSelectionChanged: (s) => setState(() {
                _pattern = s.first;
                if (_breathingSince != null) _breathingSince = _now();
              }),
            ),
            const SizedBox(height: Space.md),
            if (state != null) ...[
              if (!reduced)
                Center(
                  child: AnimatedContainer(
                    duration: Duration(seconds: state.phase == BreathPhase.inhale ? _pattern.inhale : _pattern.exhale),
                    curve: Curves.easeInOut,
                    width: full ? 140 : 70,
                    height: full ? 140 : 70,
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              const SizedBox(height: Space.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  l.quitBreathPhase(phaseLabel(state.phase), state.secondsLeft),
                  style: context.text.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              Text(l.quitBreathCycle(state.cycle), textAlign: TextAlign.center, style: context.text.bodySmall),
              const SizedBox(height: Space.sm),
            ],
            FilledButton.tonal(
              onPressed: () => setState(() {
                _breathingSince = since == null ? _now() : null;
                _lastPhase = null;
              }),
              child: Text(since == null ? l.quitBreathingStart : l.quitBreathingStop),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the toolbox (quit dashboard).
Future<void> openCopingToolbox(BuildContext context, Habit habit) =>
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => CopingToolboxScreen(habitId: habit.id)));
