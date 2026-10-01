import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/goals/application/goal_providers.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/goals/presentation/goal_card.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/application/live_ticker.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/quit.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/features/habits/presentation/pause_sheet.dart';
import 'package:everslot/features/habits/presentation/quit/coping_toolbox.dart';
import 'package:everslot/features/habits/presentation/quit/live_counter.dart';
import 'package:everslot/features/habits/presentation/quit/milestone_timeline.dart';
import 'package:everslot/features/habits/presentation/quit/quit_sheets.dart';
import 'package:everslot/features/habits/presentation/quit/rewards_section.dart';
import 'package:everslot/features/habits/presentation/quit/ritual_card.dart';
import 'package:everslot/features/habits/presentation/quit/vocab_manage_screen.dart';
import 'package:everslot/features/habits/presentation/record_banner.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show MilestoneProgress, QuitCalculator, QuitMode, defaultDayMilestones, milestoneProgress;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "16 d 15 h" for long durations (life regained, time won back).
String formatDaysHours(BuildContext context, double minutes) {
  final l = context.l10n;
  final total = minutes.round();
  final days = total ~/ 1440;
  final hours = (total % 1440) ~/ 60;
  if (days == 0) return AppFormat(context.localeName, l10n: l).duration(total);
  return l.quitDaysHours(days, hours);
}

/// Per-tracker dashboard (T5.3.05): big live counter since the last relapse, "since you first quit",
/// money saved / units avoided / time won back / life regained (smoking, population estimate),
/// longest streak, clean days, next-milestone ring with ETA, recent events, motivation, and the
/// primary **Log craving** / **Log relapse** buttons. Reduce mode shows today's use vs the limit.
class QuitDashboardScreen extends ConsumerWidget {
  const QuitDashboardScreen({required this.habitId, super.key});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapAsync = ref.watch(habitSnapshotProvider(habitId));
    return AsyncValueView(
      value: snapAsync,
      loading: const Scaffold(body: LoadingState()),
      data: (snapshot) {
        final habit = snapshot.quitHabit;
        if (habit == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) unawaited(HabitRoutes.detail(context, habitId));
          });
          return const Scaffold(body: LoadingState());
        }
        return _Dashboard(snapshot: snapshot, habit: habit);
      },
    );
  }
}

class _Dashboard extends ConsumerStatefulWidget {
  const _Dashboard({required this.snapshot, required this.habit});

  final HabitSnapshot snapshot;
  final QuitHabit habit;

  @override
  ConsumerState<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<_Dashboard> {
  late final SharedTicker _ticker = ref.read(sharedTickerProvider);
  int _minute = -1;

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

  // Money and units grow through the day: refresh the tiles once a minute.
  void _onTick() {
    final m = _ticker.now.millisecondsSinceEpoch ~/ 60000;
    if (m != _minute && mounted) {
      setState(() => _minute = m);
      if (_minute != -1) ref.read(habitTickProvider.notifier).bump();
    }
  }

  QuitCalculator _calculator() {
    final s = widget.snapshot;
    return quitCalculatorOf(
      widget.habit,
      revisions: s.revisions,
      logs: s.logs,
      days: s.boundaries,
      now: ref.read(clockProvider).nowUtc(),
    );
  }

  Future<void> _menu(String value) async {
    final l = context.l10n;
    final habit = widget.habit;
    final service = ref.read(habitServiceProvider);
    switch (value) {
      case 'reset':
        final ok = await confirmDialog(
          context,
          title: l.quitResetCounter,
          body: l.quitResetBody,
          confirmLabel: l.quitResetCounter,
        );
        if (!ok) return;
        final record = await ref.read(quitServiceProvider).resetCounter(habit, note: l.quitManualReset);
        if (mounted) showUndoSnackBar(context, ref, message: l.quitRelapseSaved, record: record);
      case 'stats':
        await HabitNav.push(context, AppLinks.insightsScope('quit', habit.id), (_) => const SizedBox());
      case 'milestones':
        await openQuitMilestones(context, habit.id);
      case 'vocab':
        await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const VocabManageScreen()));
      case 'pause':
        await showPauseSheet(context, ref, habitId: habit.id);
      case 'archive':
        final record = await service.setArchived(habit.id, archived: !habit.isArchived);
        if (mounted) {
          showUndoSnackBar(
            context,
            ref,
            message: habit.isArchived ? l.habitsUnarchivedSnack : l.habitsArchivedSnack,
            record: record,
          );
        }
      case 'delete':
        final ok = await confirmDialog(
          context,
          title: l.habitsDeleteTitle(habit.name),
          body: l.habitsDeleteBody,
          confirmLabel: l.actionDelete,
          destructive: true,
        );
        if (!ok || !mounted) return;
        final record = await service.delete(habit.id);
        if (!mounted) return;
        showUndoSnackBar(context, ref, message: l.habitsDeletedSnack, record: record);
        Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final habit = widget.habit;
    final snapshot = widget.snapshot;
    final calc = _calculator();
    final prefs = ref.watch(userPreferencesProvider);
    final fmt = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final accent = habitAccent(context, habit);
    final currency = habit.currency ?? prefs.currency;
    final reduce = habit.mode == QuitMode.reduce;
    final today = snapshot.today;
    final usedToday = calc.days.isEmpty ? 0.0 : (calc.days.last.localDate == today ? calc.days.last.used : 0.0);
    final limitToday = calc.tracker.economicsOn(today).dailyLimit;
    final milestones = milestoneProgress(
      defaultDayMilestones,
      abstinenceStart: calc.currentAbstinenceStart,
      now: calc.now,
    );
    final next = milestones.where((m) => m.isNext).firstOrNull;
    final restarted = calc.currentAbstinenceStart.isAfter(calc.quitStartedAt);
    final events = [
      for (final e in snapshot.logs.reversed)
        if (e.kind == HabitLogKind.relapse ||
            e.kind == HabitLogKind.restart ||
            e.kind == HabitLogKind.craving ||
            e.kind == HabitLogKind.use ||
            e.kind == HabitLogKind.pledge)
          e,
    ].take(10).toList();
    final vocab = ref.watch(habitVocabProvider).value ?? const <VocabEntry>[];
    final zone = ref.watch(habitPeriodServiceProvider).zoneOf(habit);
    final resolver = ref.watch(zoneResolverProvider);
    final pause = snapshot.pauseOn(today);
    final claimedRewards = [
      for (final g in ref.watch(habitGoalsProvider(habit.id)).value ?? const <Goal>[])
        if (g.isReward && g.achievedAt != null) g,
    ]..sort((a, b) => b.achievedAt!.compareTo(a.achievedAt!));

    Widget tile(String label, String value, IconData icon, {String? note}) => Semantics(
      label: '$label: $value${note == null ? '' : ', $note'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: Space.xs),
                Flexible(child: Text(label, style: context.text.labelMedium)),
              ],
            ),
            const SizedBox(height: Space.xs),
            Text(value, style: context.text.titleLarge),
            if (note != null)
              Text(note, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ),
    );

    final tiles = <Widget>[
      if (habit.unitCost != null)
        tile(l.quitMoneySaved, fmt.currency(calc.moneySaved.toDouble(), currency), Icons.savings_outlined),
      tile(l.quitUnitsAvoided, formatAmount(context, _round1(calc.unitsAvoided), habit.unit), Icons.block),
      if (calc.timeWonBackMinutes != null)
        tile(l.quitTimeWonBack, formatDaysHours(context, calc.timeWonBackMinutes!), Icons.hourglass_bottom),
      if (calc.lifeRegainedMinutes != null)
        tile(
          l.quitLifeRegained,
          formatDaysHours(context, calc.lifeRegainedMinutes!),
          Icons.favorite_border,
          note: l.quitPopulationEstimate,
        ),
      tile(l.quitLongest, fmt.duration(calc.longestAbstinence.inMinutes), Icons.emoji_events_outlined),
      tile(l.quitCleanDaysTitle, l.quitCleanDays(calc.cleanDays), Icons.event_available),
      if (reduce) tile(l.quitWithinLimitStreakTitle, l.habitsDays(calc.dayStreak), Icons.local_fire_department),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            tooltip: l.quitToolboxOpen,
            icon: const Icon(Icons.self_improvement),
            onPressed: () => openCopingToolbox(context, habit),
          ),
          IconButton(
            tooltip: l.actionEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => HabitRoutes.edit(context, habit.id),
          ),
          PopupMenuButton<String>(
            tooltip: l.actionMore,
            onSelected: (v) => unawaited(_menu(v)),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'stats', child: Text(l.habitsAllStats)),
              PopupMenuItem(value: 'milestones', child: Text(l.quitMilestonesOpen)),
              PopupMenuItem(value: 'vocab', child: Text(l.quitVocabTitle)),
              if (!reduce) PopupMenuItem(value: 'reset', child: Text(l.quitResetCounter)),
              PopupMenuItem(value: 'pause', child: Text(l.habitsActionPause)),
              PopupMenuItem(value: 'archive', child: Text(habit.isArchived ? l.habitsUnarchive : l.actionArchive)),
              PopupMenuItem(value: 'delete', child: Text(l.actionDelete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 120),
        children: [
          if (pause != null) PauseBanner(pause: pause),
          Text(reduce ? l.quitSinceLastUse : l.quitSinceLastRelapse, style: context.text.titleSmall),
          const SizedBox(height: Space.xs),
          LiveCounter(since: calc.currentAbstinenceStart, color: accent),
          if (restarted) ...[
            const SizedBox(height: Space.md),
            Text(l.quitSinceFirstQuit, style: context.text.labelLarge),
            LiveCounter(since: calc.quitStartedAt, size: CounterSize.compact),
          ],
          if (reduce) ...[
            const SizedBox(height: Space.lg),
            Card(
              child: ListTile(
                title: Text(
                  limitToday == null
                      ? formatAmount(context, usedToday, habit.unit)
                      : l.quitTodayUse(formatValue(context, usedToday), formatAmount(context, limitToday, habit.unit)),
                  style: context.text.titleMedium,
                ),
                subtitle: limitToday != null && usedToday > limitToday + 1e-9
                    ? Text(l.quitOverLimit, style: TextStyle(color: context.appColors.warning))
                    : null,
                trailing: GestureDetector(
                  onLongPress: () => showUseSheet(context, ref, habit),
                  child: FilledButton.tonal(
                    onPressed: () async {
                      final record = await ref.read(quitServiceProvider).logUse(habit);
                      if (context.mounted) showUndoSnackBar(context, ref, message: l.quitUseLogged, record: record);
                    },
                    child: Text(l.quitAddUse),
                  ),
                ),
              ),
            ),
          ],
          RecordBanner(habitId: habit.id),
          if (QuitRitualCard.shownFor(habit)) ...[const SizedBox(height: Space.lg), QuitRitualCard(snapshot: snapshot)],
          const SizedBox(height: Space.lg),
          LayoutBuilder(
            builder: (context, c) {
              final width = c.maxWidth >= 560 ? (c.maxWidth - Space.sm * 2) / 3 : (c.maxWidth - Space.sm) / 2;
              return Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [for (final t in tiles) SizedBox(width: width, child: t)],
              );
            },
          ),
          if (next != null) ...[
            const SizedBox(height: Space.lg),
            _NextMilestone(
              progress: next,
              fmt: fmt,
              eta: resolver.toLocal(next.eta, zone),
              onTap: () => openQuitMilestones(context, habit.id),
            ),
          ],
          HabitGoalsSection(habitId: habit.id),
          QuitRewardsSection(habitId: habit.id),
          if (habit.motivation != null) ...[
            SectionHeader(
              l.quitMotivationCard,
              padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs),
            ),
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
          SectionHeader(
            l.quitRecentEvents,
            padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs),
          ),
          for (final g in claimedRewards)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.card_giftcard),
              title: Text(g.reward ?? ''),
              subtitle: Text(l.quitRewardClaimed(fmt.dateTime(resolver.toLocal(g.achievedAt!, zone)))),
            ),
          if (events.isEmpty && claimedRewards.isEmpty)
            Text(l.quitNoEvents, style: context.text.bodyMedium)
          else
            for (final e in events)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_eventIcon(e.kind)),
                title: Text(_eventTitle(context, e, habit)),
                subtitle: Text(
                  [
                    fmt.dateTime(resolver.toLocal(e.loggedAt, zone)),
                    if (e.trigger != null) vocabLabel(vocab, e.trigger),
                    if (e.place != null) vocabLabel(vocab, e.place),
                    if (e.note != null) e.note!,
                  ].join(' · '),
                ),
                onTap: e.kind == HabitLogKind.craving ? () => showCravingSheet(context, ref, habit, existing: e) : null,
                trailing: IconButton(
                  tooltip: l.actionDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final record = await ref.read(quitServiceProvider).deleteLog(e);
                    if (context.mounted) showUndoSnackBar(context, ref, message: l.habitsEntryDeleted, record: record);
                  },
                ),
              ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => logQuickCraving(context, ref, habit),
                  icon: const Icon(Icons.bolt),
                  label: Text(l.quitLogCraving),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => reduce
                      ? showUseSheet(context, ref, habit)
                      : showRelapseSheet(context, ref, habit, cleanFor: calc.currentAbstinence),
                  icon: const Icon(Icons.replay),
                  label: Text(reduce ? l.quitLogUse : l.quitLogRelapse),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _round1(double v) => (v * 10).roundToDouble() / 10;

  static IconData _eventIcon(HabitLogKind kind) => switch (kind) {
    HabitLogKind.relapse => Icons.replay,
    HabitLogKind.restart => Icons.restart_alt,
    HabitLogKind.craving => Icons.bolt,
    HabitLogKind.use => Icons.add_circle_outline,
    HabitLogKind.pledge => Icons.handshake_outlined,
    _ => Icons.circle_outlined,
  };

  static String _eventTitle(BuildContext context, HabitLogEntry e, QuitHabit habit) {
    final l = context.l10n;
    return switch (e.kind) {
      HabitLogKind.relapse =>
        e.value == null ? l.quitEventRelapse : '${l.quitEventRelapse} · ${formatAmount(context, e.value!, habit.unit)}',
      HabitLogKind.restart => l.quitEventRestart,
      HabitLogKind.craving => l.quitEventCraving(e.intensity ?? 5),
      HabitLogKind.use => formatAmount(context, e.value ?? 1, habit.unit),
      HabitLogKind.pledge => l.quitEventPledge,
      _ => e.kind.name,
    };
  }
}

class _NextMilestone extends StatelessWidget {
  const _NextMilestone({required this.progress, required this.fmt, required this.eta, required this.onTap});

  final MilestoneProgress progress;
  final AppFormat fmt;

  /// ETA in the tracker's zone.
  final LocalDateTime eta;

  /// Opens the milestone timeline.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final days = progress.milestone.tMin.inDays;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              ProgressRing(
                progress: progress.progress,
                size: 64,
                stroke: 6,
                semanticsLabel: l.quitNextMilestone,
                child: Text(fmt.number(days), style: context.text.titleMedium),
              ),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.quitNextMilestone, style: context.text.labelLarge),
                    Text(l.habitsDays(days), style: context.text.titleMedium),
                    Text(l.quitMilestoneEta(fmt.dateTime(eta)), style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
