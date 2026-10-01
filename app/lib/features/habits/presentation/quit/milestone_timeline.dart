import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/live_ticker.dart';
import 'package:everslot/features/habits/application/milestone_content.dart';
import 'package:everslot/features/habits/domain/quit.dart';
import 'package:everslot_metrics/everslot_metrics.dart'
    show MilestoneProgress, MilestoneState, QuitMilestone, defaultDayMilestones, milestoneProgress;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// "20 min", "8 h", "3 days", "2 weeks", "1 month", "10 years".
String milestoneOffset(BuildContext context, Duration d) {
  final l = context.l10n;
  final days = d.inDays;
  if (days < 1) return AppFormat(context.localeName, l10n: l).duration(d.inMinutes);
  if (days < 14) return l.habitsDays(days);
  if (days % 7 == 0 && days <= 84) return l.quitOffsetWeeks(days ~/ 7);
  if (days < 365) return l.quitOffsetMonths((days / 30).round());
  return l.quitOffsetYears((days / 365).round());
}

/// When a milestone happens: a point ("8 h") or a range ("2 weeks – 12 weeks").
String milestoneWhen(BuildContext context, QuitMilestone m) => m.isRange
    ? context.l10n.quitOffsetRange(milestoneOffset(context, m.tMin), milestoneOffset(context, m.tMax!))
    : milestoneOffset(context, m.tMin);

/// Milestone timeline of a quit tracker (T5.3.12): reached milestones with the date, the next one
/// with a progress ring and ETA, and the upcoming ones — clean-time milestones for every tracker,
/// and for smoking the sourced health-recovery content with its range notes, the withdrawal phase
/// and the disclaimer (always shown at the top of the section). Progress is driven by the current
/// abstinence, so the clock restarts after a lapse (the screen says so); percentages show elapsed
/// time only.
class QuitMilestonesScreen extends ConsumerStatefulWidget {
  const QuitMilestonesScreen({required this.habitId, super.key});

  final String habitId;

  @override
  ConsumerState<QuitMilestonesScreen> createState() => _QuitMilestonesScreenState();
}

class _QuitMilestonesScreenState extends ConsumerState<QuitMilestonesScreen> {
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

  // Progress moves continuously: refresh once a minute.
  void _onTick() {
    final m = _ticker.now.millisecondsSinceEpoch ~/ 60000;
    if (m != _minute && mounted) setState(() => _minute = m);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final snapshot = ref.watch(habitSnapshotProvider(widget.habitId)).value;
    final habit = snapshot?.quitHabit;
    if (snapshot == null || habit == null) return const Scaffold(body: LoadingState());
    final now = ref.read(clockProvider).nowUtc();
    final calc = quitCalculatorOf(
      habit,
      revisions: snapshot.revisions,
      logs: snapshot.logs,
      days: snapshot.boundaries,
      now: now,
    );
    final start = calc.currentAbstinenceStart;
    final smoking = habit.substance?.hasHealthContent ?? false;
    final content = smoking ? ref.watch(smokingMilestoneContentProvider).value : null;
    final lang = Localizations.localeOf(context).languageCode;
    final zone = ref.watch(habitPeriodServiceProvider).zoneOf(habit);
    final resolver = ref.watch(zoneResolverProvider);
    final fmt = AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h, l10n: l);
    String date(DateTime instant) => fmt.dateMedium(resolver.toLocal(instant, zone).date);
    String dateTime(DateTime instant) => fmt.dateTime(resolver.toLocal(instant, zone));

    final dayRows = milestoneProgress(defaultDayMilestones, abstinenceStart: start, now: now);
    final healthRows = content == null
        ? const <MilestoneProgress>[]
        : milestoneProgress(content.progressMilestones, abstinenceStart: start, now: now);
    final dayNumber = now.difference(start).inDays + 1;
    final phase = content?.withdrawal.where((w) => dayNumber >= w.fromDay && dayNumber <= w.toDay).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l.quitMilestonesTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.xxxl),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.restart_alt),
              title: Text(content?.clockNoteFor(lang) ?? l.quitMilestonesClockNote),
            ),
          ),
          SectionHeader(
            l.quitDayMilestonesTitle,
            padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs),
          ),
          _DayMilestones(rows: dayRows, date: date, dateTime: dateTime),
          if (smoking) ...[
            SectionHeader(
              l.quitHealthTitle,
              padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs),
            ),
            if (content == null)
              const LoadingState()
            else ...[
              // The disclaimer stays at the top of the section, visible without scrolling in it.
              Text(content.disclaimerFor(lang), style: context.text.bodySmall),
              const SizedBox(height: Space.sm),
              for (final row in healthRows)
                if (content.byId(row.milestone.id) case final health?)
                  _HealthTile(row: row, health: health, lang: lang, date: date, dateTime: dateTime),
              for (final info in content.milestones.where((m) => m.info))
                _HealthTile(health: info, lang: lang, date: date, dateTime: dateTime),
              if (phase != null) ...[
                SectionHeader(
                  l.quitWithdrawalTitle,
                  padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.xs),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.timeline),
                    title: Text(l.quitWithdrawalNow, style: context.text.labelLarge),
                    subtitle: Text(phase.textFor(lang)),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

/// Clean-time milestones: reached ones as chips with their date, the next one with a ring and
/// ETA, then the upcoming ones.
class _DayMilestones extends StatelessWidget {
  const _DayMilestones({required this.rows, required this.date, required this.dateTime});

  final List<MilestoneProgress> rows;
  final String Function(DateTime) date;
  final String Function(DateTime) dateTime;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = AppFormat(context.localeName, l10n: l);
    final reached = [
      for (final r in rows)
        if (r.state == MilestoneState.done) r,
    ];
    final next = rows.where((r) => r.isNext).firstOrNull;
    final upcoming = [
      for (final r in rows)
        if (r.state != MilestoneState.done && !r.isNext) r,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reached.isNotEmpty) ...[
          Text(l.quitMilestonesReached, style: context.text.labelLarge),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final r in reached)
                Chip(
                  avatar: const Icon(Icons.check_circle, size: 18),
                  label: Text('${l.quitMilestoneDays(r.milestone.tMin.inDays)} · ${date(r.eta)}'),
                ),
            ],
          ),
        ],
        if (next != null)
          Card(
            margin: const EdgeInsetsDirectional.only(top: Space.md),
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  ProgressRing(
                    progress: next.progress,
                    size: 56,
                    stroke: 6,
                    semanticsLabel: l.quitNextMilestone,
                    child: Text(fmt.percent(next.progress), style: context.text.labelSmall),
                  ),
                  const SizedBox(width: Space.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.quitNextMilestone, style: context.text.labelLarge),
                        Text(l.quitMilestoneDays(next.milestone.tMin.inDays), style: context.text.titleMedium),
                        Text(l.quitMilestoneEta(dateTime(next.eta)), style: context.text.bodySmall),
                        Text(l.quitMilestoneElapsed(fmt.percent(next.progress)), style: context.text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          Text(l.quitMilestonesUpcoming, style: context.text.labelLarge),
          for (final r in upcoming)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.radio_button_unchecked),
              title: Text(l.quitMilestoneDays(r.milestone.tMin.inDays)),
              trailing: Text(date(r.eta), style: context.text.bodySmall),
            ),
        ],
      ],
    );
  }
}

/// One health row: when (point or range), title, text, the range note where sources differ, its
/// sources (tap to open) and its state — reached with the date, happening now, or the ETA with the
/// share of the time elapsed. Info rows ([row] null) have no progress.
class _HealthTile extends StatelessWidget {
  const _HealthTile({required this.health, required this.lang, required this.date, required this.dateTime, this.row});

  final MilestoneProgress? row;
  final HealthMilestone health;
  final String lang;
  final String Function(DateTime) date;
  final String Function(DateTime) dateTime;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = AppFormat(context.localeName, l10n: l);
    final text = health.textFor(lang);
    final r = row;
    final (icon, color) = switch (r?.state) {
      MilestoneState.done => (Icons.check_circle, context.appColors.success),
      MilestoneState.inWindow => (Icons.timelapse, context.colors.primary),
      MilestoneState.upcoming => (Icons.radio_button_unchecked, context.colors.outline),
      null => (Icons.info_outline, context.colors.primary),
    };
    final status = switch (r?.state) {
      MilestoneState.done => l.quitMilestoneReachedOn(date(r!.eta)),
      MilestoneState.inWindow => l.quitMilestoneInWindow(date(r!.eta)),
      MilestoneState.upcoming =>
        '${l.quitMilestoneEta(dateTime(r!.eta))} · ${l.quitMilestoneElapsed(fmt.percent(r.progress))}',
      null => null,
    };
    return Card(
      color: r?.isNext ?? false ? context.colors.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: Space.sm),
                if (!health.info) Text(milestoneWhen(context, health.toMetrics()), style: context.text.labelLarge),
              ],
            ),
            const SizedBox(height: Space.xs),
            Text(text.title, style: context.text.titleSmall),
            Text(text.body, style: context.text.bodyMedium),
            if (text.range != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: Space.xs),
                child: Text(text.range!, style: context.text.bodySmall),
              ),
            if (status != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: Space.xs),
                child: Text(status, style: context.text.labelMedium),
              ),
            if (r != null && r.state != MilestoneState.done) ...[
              const SizedBox(height: Space.xs),
              LinearProgressIndicator(
                value: r.progress,
                semanticsLabel: l.quitMilestoneElapsed(fmt.percent(r.progress)),
              ),
            ],
            Wrap(
              spacing: Space.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${l.quitMilestoneSources}:', style: context.text.labelSmall),
                for (final s in health.sources)
                  TextButton(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () => unawaited(launchUrl(Uri.parse(s.url), mode: LaunchMode.externalApplication)),
                    child: Text(s.name),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the timeline (dashboard, notifications).
Future<void> openQuitMilestones(BuildContext context, String habitId) =>
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => QuitMilestonesScreen(habitId: habitId)));
