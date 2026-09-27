import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_day_view.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/application/live_ticker.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Converts ASCII digits to Arabic-Indic digits (users who prefer them, T5.3.04).
String localizeDigits(String text, {required bool arabicIndic}) {
  if (!arabicIndic) return text;
  const digits = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final c in text.runes) {
    b.write(c >= 48 && c <= 57 ? digits[c - 48] : String.fromCharCode(c));
  }
  return b.toString();
}

/// The parts of a duration shown by live counters.
({int days, int hours, int minutes, int seconds}) counterParts(Duration d) {
  final total = d.isNegative ? Duration.zero : d;
  return (
    days: total.inDays,
    hours: total.inHours % 24,
    minutes: total.inMinutes % 60,
    seconds: total.inSeconds % 60,
  );
}

/// Size variants of [LiveCounter].
enum CounterSize { big, medium, compact }

/// A live d · h · m · s counter since [since], driven by the one shared ticker (T5.3.04): the
/// value is derived from instants on each tick (no drift, no DB writes). Screen readers get a
/// minute-level polite live region; large text wraps units onto lines.
class LiveCounter extends ConsumerStatefulWidget {
  const LiveCounter({required this.since, super.key, this.size = CounterSize.big, this.color});

  final DateTime since;
  final CounterSize size;
  final Color? color;

  @override
  ConsumerState<LiveCounter> createState() => _LiveCounterState();
}

class _LiveCounterState extends ConsumerState<LiveCounter> {
  late final SharedTicker _ticker = ref.read(sharedTickerProvider);

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

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final arabic = ref.watch(userPreferencesProvider).useArabicDigits && context.localeName.startsWith('ar');
    final now = ref.read(clockProvider).nowUtc();
    final p = counterParts(now.difference(widget.since));
    String n(int v, {int pad = 1}) => localizeDigits(v.toString().padLeft(pad, '0'), arabicIndic: arabic);
    final spoken = l.quitCounterSemantics(p.days, p.hours, p.minutes);
    final (valueStyle, unitStyle) = switch (widget.size) {
      CounterSize.big => (context.text.displaySmall, context.text.titleMedium),
      CounterSize.medium => (context.text.headlineSmall, context.text.labelLarge),
      CounterSize.compact => (context.text.titleMedium, context.text.labelSmall),
    };
    final color = widget.color ?? context.colors.onSurface;
    Widget part(String value, String unit) => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: valueStyle?.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(width: 2),
        Text(unit, style: unitStyle?.copyWith(color: color.withValues(alpha: 0.75))),
      ],
    );
    return Semantics(
      liveRegion: true,
      label: spoken,
      excludeSemantics: true,
      child: Wrap(
        spacing: widget.size == CounterSize.compact ? Space.xs : Space.sm,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          if (p.days > 0 || widget.size != CounterSize.compact) part(n(p.days), l.quitUnitDays),
          part(n(p.hours, pad: 2), l.quitUnitHours),
          part(n(p.minutes, pad: 2), l.quitUnitMinutes),
          if (widget.size != CounterSize.compact || p.days == 0) part(n(p.seconds, pad: 2), l.quitUnitSeconds),
        ],
      ),
    );
  }
}

/// Horizontal strip of live mini-counters at the top of the Habits tab (T5.3.10).
class QuitStrip extends ConsumerWidget {
  const QuitStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final trackers = ref.watch(quitSnapshotsProvider).value ?? const [];
    if (trackers.isEmpty) return const SizedBox.shrink();
    // Grows with large text (the counters themselves scale down to one line).
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return SizedBox(
      height: 112 * scale,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.sm),
        children: [
          for (final s in trackers)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.sm),
              child: _QuitCard(snapshotId: s.habit.id),
            ),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const AllClocksScreen()),
              ),
              icon: const Icon(Icons.timer_outlined),
              label: Text(l.quitAllClocks),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuitCard extends ConsumerWidget {
  const _QuitCard({required this.snapshotId});

  final String snapshotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(habitSnapshotProvider(snapshotId)).value;
    final quit = s?.quit;
    final habit = s?.quitHabit;
    if (s == null || quit == null || habit == null) return const SizedBox(width: 160);
    return SizedBox(
      width: 188,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () => HabitRoutes.quit(context, habit.id),
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HabitAvatar(habit: habit, size: 24),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(habit.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.labelLarge),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.bottomStart,
                      child: LiveCounter(
                        since: quit.currentAbstinenceStart,
                        size: CounterSize.compact,
                        color: habitAccent(context, habit),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "All clocks" (Nomo-style): every tracker's live counter, drag to reorder (T5.3.10).
class AllClocksScreen extends ConsumerWidget {
  const AllClocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final trackers = ref.watch(quitSnapshotsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l.quitAllClocks)),
      body: trackers.isEmpty
          ? EmptyState(icon: Icons.timer_outlined, title: l.quitNoTrackers, message: l.quitNoTrackersBody)
          : ReorderableListView(
              padding: const EdgeInsets.all(Space.md),
              onReorderItem: (from, to) async {
                final habits = [for (final t in trackers) t.habit];
                final moved = habits[from];
                final index = to;
                await ref.read(habitServiceProvider).reorder(moved.id, habits, index);
              },
              children: [
                for (final t in trackers)
                  Card(
                    key: ValueKey(t.habit.id),
                    child: ListTile(
                      leading: HabitAvatar(habit: t.habit),
                      title: Text(t.habit.name),
                      subtitle: LiveCounter(
                        since: t.quit!.currentAbstinenceStart,
                        size: CounterSize.medium,
                        color: habitAccent(context, t.habit),
                      ),
                      onTap: () => HabitRoutes.quit(context, t.habit.id),
                    ),
                  ),
              ],
            ),
    );
  }
}
