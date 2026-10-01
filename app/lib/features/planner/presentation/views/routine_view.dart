import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/checklist_steps.dart';
import 'package:everslot/features/planner/application/view_config/screen_awake.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/routine.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/focus_view.dart' show FocusRingPainter, focusClock;
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A routine to play: a task with a linked checklist (steps = its top-level items) or a block of
/// consecutive tasks (steps = the tasks).
@immutable
sealed class RoutineSource {
  const RoutineSource(this.first);

  final PlannerItem first;
}

final class ChecklistRoutine extends RoutineSource {
  const ChecklistRoutine(super.first);
}

final class BlockRoutine extends RoutineSource {
  const BlockRoutine(super.first, this.items);

  final List<PlannerItem> items;
}

/// Routine player (T3.7.07, Routinery / Tiimo style): pick today's routine, then run it step by
/// step — each step has its own countdown, auto-advance (`options.autoAdvance`), a haptic and a
/// sound on step change, pause / skip / done; the summary completes the checked items and marks
/// the occurrence(s) done.
class RoutineView extends ConsumerStatefulWidget {
  const RoutineView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<RoutineView> createState() => _RoutineViewState();
}

class _RoutineViewState extends ConsumerState<RoutineView> {
  RoutineSource? _source;
  RoutineState? _state;
  Timer? _timer;
  DateTime? _lastTick;
  late final ScreenAwake _awake = ref.read(screenAwakeProvider);
  bool _awakeOn = false;

  String get _key => widget.args.viewKey;

  @override
  void dispose() {
    _timer?.cancel();
    if (_awakeOn) unawaited(_awake.keepOn(on: false));
    super.dispose();
  }

  void _setAwake(bool on) {
    if (on == _awakeOn) return;
    _awakeOn = on;
    unawaited(_awake.keepOn(on: on));
  }

  void _play(RoutineSource source, List<RoutineStep> steps) {
    setState(() {
      _source = source;
      _state = RoutineMachine.start(RoutineState(steps: steps));
    });
    _lastTick = ref.read(clockProvider).nowUtc();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _setAwake(true);
  }

  void _tick() {
    final s = _state;
    if (!mounted || s == null) return;
    final now = ref.read(clockProvider).nowUtc();
    final dt = now.difference(_lastTick ?? now);
    _lastTick = now;
    final auto = ref.read(plannerViewConfigProvider(_key)).option<bool>('autoAdvance', true);
    _apply(RoutineMachine.tick(s, dt, autoAdvance: auto));
  }

  /// Applies a transition, signalling step changes (haptic + system sound).
  void _apply(RoutineState next) {
    final prev = _state;
    setState(() => _state = next);
    if (prev != null && next.index != prev.index) {
      ref.read(plannerHapticsProvider).lift();
      unawaited(SystemSound.play(SystemSoundType.alert));
    }
    if (next.finished) {
      _timer?.cancel();
      _setAwake(false);
    }
  }

  void _resetClock() => _lastTick = ref.read(clockProvider).nowUtc();

  Future<void> _finish() async {
    final source = _source;
    final s = _state;
    if (source == null || s == null) return;
    final l = context.l10n;
    final commands = PlannerCommands(context, ref);
    switch (source) {
      case ChecklistRoutine(:final first):
        final checklistId = first.linkedChecklistId!;
        final done = [
          for (final (i, o) in s.outcomes.indexed)
            if (o == StepOutcome.done) s.steps[i].id,
        ];
        await ref.read(checklistStepActionsProvider).completeMany(checklistId, done);
        if (!mounted) return;
        await commands.setStatus(first, OccurrenceStatus.done);
      case BlockRoutine(:final items):
        await commands.run(l.pvRoutineComplete, (a) async {
          for (final (i, o) in s.outcomes.indexed) {
            if (o == StepOutcome.pending) continue;
            await a.setStatus(items[i], o == StepOutcome.done ? OccurrenceStatus.done : OccurrenceStatus.skipped);
          }
        });
    }
    if (mounted) {
      setState(() {
        _source = null;
        _state = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final auto = config.option<bool>('autoAdvance', true);
    final s = _state;
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: SizedBox(
        height: 48,
        child: Row(
          children: [
            const SizedBox(width: Space.md),
            Expanded(
              child: Text(
                s == null
                    ? l.pvViewRoutine
                    : (s.finished ? l.pvRoutineComplete : l.pvStep(s.index + 1, s.steps.length)),
                key: const Key('routine-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            FilterChip(
              key: const Key('routine-auto'),
              label: Text(l.pvAutoAdvance),
              selected: auto,
              onSelected: (v) =>
                  ref.read(plannerViewConfigProvider(_key).notifier).change((c) => c.withOption('autoAdvance', v)),
            ),
            PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
          ],
        ),
      ),
      body: s == null
          ? _Picker(onPlay: _play)
          : s.finished
          ? _Summary(state: s, onFinish: () => unawaited(_finish()))
          : _Player(
              state: s,
              onPause: () => _apply(RoutineMachine.pause(s)),
              onResume: () {
                _resetClock();
                _apply(RoutineMachine.resume(s));
              },
              onDone: () {
                _resetClock();
                _apply(RoutineMachine.complete(s));
              },
              onSkip: () {
                _resetClock();
                _apply(RoutineMachine.skip(s));
              },
            ),
    );
  }
}

/// Today's routines: tasks with a linked checklist and blocks of ≥ 2 consecutive tasks.
class _Picker extends ConsumerWidget {
  const _Picker({required this.onPlay});

  final void Function(RoutineSource source, List<RoutineStep> steps) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final today = ref.watch(plannerTodayProvider);
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final items =
        (ref.watch(viewItemsProvider(DayRange(today, 1))).value ?? const <PlannerItem>[])
            .where((i) => i.isOpen && !i.allDay)
            .toList()
          ..sort((a, b) => a.startLocal.compareTo(b.startLocal));
    final sources = <RoutineSource>[];
    final inBlock = <String>{};
    for (final i in items) {
      if (i.linkedChecklistId != null) sources.add(ChecklistRoutine(i));
      if (inBlock.contains(i.key)) continue;
      final block = consecutiveBlock(i, items);
      if (block.length >= 2) {
        sources.add(BlockRoutine(i, block));
        inBlock.addAll(block.map((b) => b.key));
      }
    }
    if (sources.isEmpty) return EmptyState(icon: Icons.playlist_play, title: l.pvNoRoutine);
    return ListView(
      key: const Key('routine-picker'),
      padding: const EdgeInsets.all(Space.md),
      children: [
        for (final src in sources)
          Card(
            child: switch (src) {
              ChecklistRoutine(:final first) => _ChecklistSourceTile(item: first, format: f, onPlay: onPlay),
              BlockRoutine(:final first, :final items) => ListTile(
                key: ValueKey('routine-block-${first.key}'),
                leading: const Icon(Icons.view_stream_outlined),
                title: Text(items.map((i) => i.title).join(' → ')),
                subtitle: Text(f.timeRange(first.startLocal, items.last.endLocal)),
                trailing: FilledButton(
                  onPressed: () => onPlay(src, [
                    for (final i in items) RoutineStep(id: i.key, title: i.title, minutes: i.durationMinutes),
                  ]),
                  child: Text(l.pvRoutineStart),
                ),
              ),
            },
          ),
      ],
    );
  }
}

class _ChecklistSourceTile extends ConsumerWidget {
  const _ChecklistSourceTile({required this.item, required this.format, required this.onPlay});

  final PlannerItem item;
  final AppFormat format;
  final void Function(RoutineSource source, List<RoutineStep> steps) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final steps = ref.watch(checklistStepsProvider((checklistId: item.linkedChecklistId!, rootOnly: true)));
    final open = [
      for (final s in steps ?? const <ChecklistStep>[])
        if (!s.done) s,
    ];
    final minutes = stepDurations([for (final s in open) s.estimateMinutes], item.durationMinutes);
    return ListTile(
      key: ValueKey('routine-checklist-${item.key}'),
      leading: const Icon(Icons.checklist),
      title: Text(item.title),
      subtitle: Text('${format.timeRange(item.startLocal, item.endLocal)} · ${l.pvItemsCount(open.length)}'),
      trailing: FilledButton(
        onPressed: open.isEmpty
            ? null
            : () => onPlay(ChecklistRoutine(item), [
                for (final (i, s) in open.indexed)
                  RoutineStep(id: s.id, title: s.text.trim().split('\n').first, minutes: minutes[i]),
              ]),
        child: Text(l.pvRoutineStart),
      ),
    );
  }
}

class _Player extends StatelessWidget {
  const _Player({
    required this.state,
    required this.onPause,
    required this.onResume,
    required this.onDone,
    required this.onSkip,
  });

  final RoutineState state;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final step = state.current!;
    final remaining = state.remaining;
    final over = remaining.isNegative;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final next = state.index + 1 < state.steps.length ? state.steps[state.index + 1] : null;
    final fraction = step.minutes == 0
        ? 0.0
        : (remaining.inMilliseconds / step.duration.inMilliseconds).clamp(0.0, 1.0);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.all(Space.lg),
          children: [
            Text(
              step.title,
              key: const Key('routine-step'),
              textAlign: TextAlign.center,
              style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Space.lg),
            Semantics(
              label:
                  '${l.pvStep(state.index + 1, state.steps.length)}, ${focusClock(remaining.abs(), seconds: !reduce)}',
              child: SizedBox(
                height: 220,
                child: CustomPaint(
                  painter: FocusRingPainter(
                    fraction: fraction,
                    color: over ? context.appColors.danger : c.primary,
                    track: c.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Text(
                      '${over ? '+' : ''}${focusClock(remaining.abs(), seconds: !reduce)}',
                      key: const Key('routine-clock'),
                      style: AppTypography.tabular(context.text.displaySmall),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                if (state.running)
                  OutlinedButton.icon(
                    key: const Key('routine-pause'),
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: Text(l.pvPause),
                  )
                else
                  OutlinedButton.icon(
                    key: const Key('routine-resume'),
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l.pvStart),
                  ),
                FilledButton.icon(
                  key: const Key('routine-done'),
                  onPressed: onDone,
                  icon: const Icon(Icons.check),
                  label: Text(l.pvMarkDone),
                ),
                TextButton.icon(
                  key: const Key('routine-skip'),
                  onPressed: onSkip,
                  icon: const Icon(Icons.skip_next),
                  label: Text(l.pvSkipStep),
                ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: Space.lg),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.arrow_forward),
                  title: Text(next.title),
                  subtitle: Text('${l.pvNextUp} · ${context.plannerFormat().duration(next.minutes)}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state, required this.onFinish});

  final RoutineState state;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      key: const Key('routine-summary'),
      padding: const EdgeInsets.all(Space.lg),
      children: [
        Text(
          l.pvRoutineSummary(state.doneCount, state.steps.length),
          textAlign: TextAlign.center,
          style: context.text.titleLarge,
        ),
        const SizedBox(height: Space.md),
        for (final (i, s) in state.steps.indexed)
          ListTile(
            leading: Icon(switch (state.outcomes[i]) {
              StepOutcome.done => Icons.check_circle,
              StepOutcome.skipped => Icons.skip_next,
              StepOutcome.pending => Icons.radio_button_unchecked,
            }),
            title: Text(s.title),
          ),
        const SizedBox(height: Space.md),
        FilledButton(key: const Key('routine-finish'), onPressed: onFinish, child: Text(l.pvFinish)),
      ],
    );
  }
}
