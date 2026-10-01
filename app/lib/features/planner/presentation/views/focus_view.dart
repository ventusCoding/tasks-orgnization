import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/application/view_config/checklist_steps.dart';
import 'package:everslot/features/planner/application/view_config/screen_awake.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/focus_selection.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Minutes offered by the *Extend* chips.
const focusExtendChoices = [5, 15, 30];

/// "12:34" / "1:02:03" of a non-negative duration; without [seconds] (reduced motion) "0:12" /
/// "1:02" (hours and minutes).
String focusClock(Duration d, {bool seconds = true}) {
  final total = d.isNegative ? Duration.zero : d;
  final h = total.inHours;
  final m = total.inMinutes % 60;
  final s = total.inSeconds % 60;
  if (!seconds) return '$h:${m.toString().padLeft(2, '0')}';
  return h > 0
      ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
      : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Now / Next focus view (T3.7.01): a distraction-free screen for the occurrence happening now —
/// countdown ring to its planned end, tracked time, notes, the linked checklist (tick inline) and a
/// *Next up* card with its own countdown. Start / pause / stop, done, skip, next and *Extend* (+5 /
/// +15 / +30 min, this occurrence only). Everything derives from the clock and stored data, so
/// reopening after an app restart shows the right remaining and elapsed time.
class FocusView extends ConsumerStatefulWidget {
  const FocusView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<FocusView> createState() => _FocusViewState();
}

class _FocusViewState extends ConsumerState<FocusView> {
  Timer? _timer;
  bool _reduceMotion = false;
  String? _pinnedKey;
  bool _awakeApplied = false;
  late final ScreenAwake _awake;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    _awake = ref.read(screenAwakeProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_timer == null || reduce != _reduceMotion) {
      _reduceMotion = reduce;
      _timer?.cancel();
      // Reduced motion: the countdown updates every 15 s and hides seconds.
      _timer = Timer.periodic(reduce ? const Duration(seconds: 15) : const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_awakeApplied) unawaited(_awake.keepOn(on: false));
    super.dispose();
  }

  void _syncAwake(bool on) {
    if (on == _awakeApplied) return;
    _awakeApplied = on;
    unawaited(_awake.keepOn(on: on));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final keepOn = config.option<bool>('keepScreenOn', false);
    _syncAwake(keepOn);
    final clock = ref.read(clockProvider);
    final nowUtc = clock.nowUtc();
    final zone = ref.watch(plannerZoneProvider);
    final localNow = ref.watch(zoneResolverProvider).toLocal(nowUtc, zone);
    final range = DayRange(localNow.date.plusDays(-1), 3);
    final items = ref.watch(viewItemsProvider(range)).value ?? const <PlannerItem>[];
    final selection = selectFocus(items, localNow, pinnedKey: _pinnedKey);
    final notifier = ref.read(plannerViewConfigProvider(_key).notifier);
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.4,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(l.pvNow, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Semantics(
                toggled: keepOn,
                label: l.pvKeepScreenOn,
                child: ExcludeSemantics(
                  child: FilterChip(
                    key: const Key('focus-keep-awake'),
                    avatar: Icon(keepOn ? Icons.lightbulb : Icons.lightbulb_outline, size: 18),
                    label: Text(l.pvKeepScreenOn),
                    selected: keepOn,
                    showCheckmark: false,
                    onSelected: (v) => notifier.change((c) => c.withOption('keepScreenOn', v)),
                  ),
                ),
              ),
              PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            key: const Key('focus-scroll'),
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selection.current == null)
                  _NothingNow(next: selection.next)
                else
                  _Current(
                    key: ValueKey('focus-current-${selection.current!.key}'),
                    viewKey: _key,
                    item: selection.current!,
                    nowUtc: nowUtc,
                    reduceMotion: _reduceMotion,
                    hasNext: selection.next != null,
                    onNext: () => setState(() => _pinnedKey = selection.next?.key),
                    onFinished: () => setState(() => _pinnedKey = null),
                  ),
                if (selection.next != null) ...[
                  const SizedBox(height: Space.lg),
                  _NextUp(
                    item: selection.next!,
                    nowUtc: nowUtc,
                    reduceMotion: _reduceMotion,
                    onTap: () => setState(() => _pinnedKey = selection.next!.key),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The focused occurrence: ring, tracked time, actions, notes and checklist.
class _Current extends ConsumerWidget {
  const _Current({
    required this.viewKey,
    required this.item,
    required this.nowUtc,
    required this.reduceMotion,
    required this.hasNext,
    required this.onNext,
    required this.onFinished,
    super.key,
  });

  final String viewKey;
  final PlannerItem item;
  final DateTime nowUtc;
  final bool reduceMotion;
  final bool hasNext;
  final VoidCallback onNext;
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final commands = PlannerCommands(context, ref);
    final entries =
        ref.watch(timeEntriesProvider((taskId: item.taskId, key: item.occurrenceKey))).value ?? const <TimeEntry>[];
    final running = entries.any((e) => e.isRunning && e.deletedAt == null);
    var tracked = Duration.zero;
    for (final e in entries) {
      if (e.deletedAt == null) tracked += e.durationAt(nowUtc);
    }
    if (tracked == Duration.zero && item.trackedSeconds != null) {
      tracked = Duration(seconds: item.trackedSeconds!);
    }
    final started = !nowUtc.isBefore(item.startUtc);
    final left = timeLeft(item.endUtc, nowUtc);
    final overtime = started && left.isNegative;
    final elapsed = started ? (tracked > Duration.zero ? tracked : nowUtc.difference(item.startUtc)) : Duration.zero;
    final untilStart = item.startUtc.difference(nowUtc);
    final ringColor = overtime ? context.appColors.danger : c.primary;
    final fraction = started ? remainingFraction(item.startUtc, item.endUtc, nowUtc) : 1.0;
    final showSeconds = !reduceMotion;
    final big = !started
        ? focusClock(untilStart, seconds: showSeconds)
        : (overtime ? '+${focusClock(-left, seconds: showSeconds)}' : focusClock(left, seconds: showSeconds));
    final minutesLeft = (left.inSeconds / 60).ceil();
    final caption = !started
        ? l.pvStartsAt(f.timeOf(item.startLocal))
        : (overtime
              ? '${l.pvVarianceOverran} ${f.duration((-left).inMinutes.clamp(1, 1 << 20))}'
              : l.pvTimeLeft(f.duration(math.max(1, minutesLeft))));
    final semanticsLabel = '${item.title}, $caption, ${l.pvElapsed(f.duration(elapsed.inMinutes))}';
    final timerMode = item.trackingMode == TrackingMode.timer;
    final checklistId = item.linkedChecklistId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: const Key('focus-title'),
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () => ref.read(plannerNavProvider).openTask(context, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Column(
              children: [
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Space.xxs),
                Text(
                  [f.timeRange(item.startLocal, item.endLocal), if (item.location != null) item.location!].join(' · '),
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.lg),
        Center(
          child: Semantics(
            key: const Key('focus-ring'),
            label: semanticsLabel,
            excludeSemantics: true,
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: FocusRingPainter(
                  fraction: fraction,
                  color: ringColor,
                  track: c.surfaceContainerHighest,
                  stroke: 14,
                  dashed: !started,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(34),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          big,
                          key: const Key('focus-clock'),
                          style: context.text.displayMedium?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: overtime ? context.appColors.danger : null,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          caption,
                          key: const Key('focus-caption'),
                          style: context.text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        Center(
          child: Text(
            l.pvElapsed(f.duration(elapsed.inMinutes)),
            key: const Key('focus-elapsed'),
            style: context.text.titleMedium?.copyWith(color: c.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: Space.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            if (timerMode && !running)
              FilledButton.icon(
                key: const Key('focus-start'),
                onPressed: () => unawaited(commands.runExtra(l.pvStart, (a) => a.startTimer(item))),
                icon: const Icon(Icons.play_arrow),
                label: Text(l.pvStart),
              ),
            if (timerMode && running)
              FilledButton.tonalIcon(
                key: const Key('focus-pause'),
                onPressed: () => unawaited(commands.runExtra(l.pvPause, (a) => a.pauseTimer(item))),
                icon: const Icon(Icons.pause),
                label: Text(l.pvPause),
              ),
            if (timerMode && (running || entries.isNotEmpty))
              OutlinedButton.icon(
                key: const Key('focus-stop'),
                onPressed: () => unawaited(commands.runExtra(l.pvStop, (a) => a.stopTimer(item))),
                icon: const Icon(Icons.stop),
                label: Text(l.pvStop),
              ),
            if (timerMode)
              OutlinedButton.icon(
                key: const Key('focus-done'),
                onPressed: () => unawaited(_finish(commands, OccurrenceStatus.done)),
                icon: const Icon(Icons.check),
                label: Text(l.pvMarkDone),
              )
            else
              FilledButton.icon(
                key: const Key('focus-done'),
                onPressed: () => unawaited(_finish(commands, OccurrenceStatus.done)),
                icon: const Icon(Icons.check),
                label: Text(l.pvMarkDone),
              ),
            OutlinedButton.icon(
              key: const Key('focus-skip'),
              onPressed: () => unawaited(_finish(commands, OccurrenceStatus.skipped)),
              icon: const Icon(Icons.redo),
              label: Text(l.pvSkip),
            ),
            OutlinedButton.icon(
              key: const Key('focus-next'),
              onPressed: hasNext ? onNext : null,
              icon: const Icon(Icons.skip_next),
              label: Text(l.pvNext),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: Space.sm,
          runSpacing: Space.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l.pvExtend, style: context.text.labelLarge?.copyWith(color: c.onSurfaceVariant)),
            for (final n in focusExtendChoices)
              ActionChip(
                key: ValueKey('focus-extend-$n'),
                label: Text(l.pvExtendBy(n)),
                onPressed: () => unawaited(_extend(commands, n)),
              ),
          ],
        ),
        if (item.notes?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: Space.lg),
          Card(
            key: const Key('focus-notes'),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Text(item.notes!, style: context.text.bodyLarge),
            ),
          ),
        ],
        if (checklistId != null) ...[const SizedBox(height: Space.md), _FocusChecklist(checklistId: checklistId)],
      ],
    );
  }

  Future<void> _finish(PlannerCommands commands, OccurrenceStatus status) async {
    await commands.setStatus(item, status);
    onFinished();
  }

  Future<void> _extend(PlannerCommands commands, int minutes) async {
    final l = commands.context.l10n;
    await commands.run(
      l.pvExtendedSnack(minutes),
      (a) => a.reschedule(
        item,
        newStart: item.startLocal,
        newDurationMinutes: item.durationMinutes + minutes,
        allDay: false,
        scope: EditScope.thisOccurrence,
      ),
    );
  }
}

/// The linked checklist's items, tickable inline.
class _FocusChecklist extends ConsumerWidget {
  const _FocusChecklist({required this.checklistId});

  final String checklistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(checklistStepsProvider((checklistId: checklistId, rootOnly: false)));
    if (steps == null || steps.isEmpty) return const SizedBox.shrink();
    final actions = ref.read(checklistStepActionsProvider);
    return Card(
      key: const Key('focus-checklist'),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (final s in steps)
            CheckboxListTile(
              key: ValueKey('focus-step-${s.id}'),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsetsDirectional.only(start: Space.sm + s.depth * Space.lg, end: Space.sm),
              value: s.done,
              onChanged: (v) => unawaited(actions.setDone(checklistId, s.id, done: v ?? false)),
              title: Text(s.text, style: TextStyle(decoration: s.done ? TextDecoration.lineThrough : null)),
            ),
        ],
      ),
    );
  }
}

class _NothingNow extends StatelessWidget {
  const _NothingNow({required this.next});

  final PlannerItem? next;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return Padding(
      key: const Key('focus-nothing'),
      padding: const EdgeInsets.symmetric(vertical: Space.xl),
      child: Column(
        children: [
          Icon(Icons.self_improvement, size: 64, color: c.primary),
          const SizedBox(height: Space.md),
          Text(l.pvNothingNow, textAlign: TextAlign.center, style: context.text.titleLarge),
          if (next == null) ...[
            const SizedBox(height: Space.xs),
            Text(
              l.pvNothingNext,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// *Next up*: the following occurrence with its own countdown (tap to focus it).
class _NextUp extends ConsumerWidget {
  const _NextUp({required this.item, required this.nowUtc, required this.reduceMotion, required this.onTap});

  final PlannerItem item;
  final DateTime nowUtc;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final untilStart = item.startUtc.difference(nowUtc);
    final label = '${l.pvNextUp}: ${item.title}, ${l.pvStartsAt(f.timeOf(item.startLocal))}';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Card(
        key: const Key('focus-next-card'),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.pvNextUp, style: context.text.labelSmall?.copyWith(color: c.primary)),
                      Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                      Text(
                        l.pvStartsAt(f.timeOf(item.startLocal)),
                        style: context.text.bodySmall?.copyWith(color: c.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                Text(
                  key: const Key('focus-next-clock'),
                  focusClock(untilStart, seconds: !reduceMotion),
                  style: context.text.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Countdown ring (T3.7.01): the part of the planned window still ahead, clockwise from the top; a
/// dashed full ring before the start. No animation — it repaints on each clock tick.
class FocusRingPainter extends CustomPainter {
  FocusRingPainter({
    required this.fraction,
    required this.color,
    required this.track,
    this.stroke = 14,
    this.dashed = false,
  });

  final double fraction;
  final Color color;
  final Color track;
  final double stroke;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, base);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    if (dashed) {
      const dashes = 48;
      for (var i = 0; i < dashes; i++) {
        canvas.drawArc(
          rect,
          -math.pi / 2 + i * 2 * math.pi / dashes,
          math.pi / dashes,
          false,
          arc..strokeCap = StrokeCap.butt,
        );
      }
      return;
    }
    if (fraction <= 0) return;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(FocusRingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke ||
      old.dashed != dashed;
}
