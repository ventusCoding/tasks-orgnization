import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/planner_providers.dart' show rangeTimeEntriesProvider;
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/plan_actual.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/occurrence_panel.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Pixels per minute of the plan-vs-actual timeline.
const double _ppm = 1;
const double _rulerWidth = 44;

/// Plan vs actual (T3.7.06, Toggl style): a day (or week, `options.scope`) where each day column is
/// split into planned tiles and tracked time entries side by side. Variance is flagged on the plan
/// (started late, overran, not done) and on tracked blocks without a plan (unplanned). Tapping a
/// tracked block opens its occurrence, where entries are edited.
class PlanVsActualView extends ConsumerStatefulWidget {
  const PlanVsActualView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<PlanVsActualView> createState() => _PlanVsActualViewState();
}

class _PlanVsActualViewState extends ConsumerState<PlanVsActualView> {
  late LocalDate _day;
  final _scroll = ScrollController(initialScrollOffset: 7 * 60 * _ppm);

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    _day =
        widget.args.date ??
        ref.read(plannerAnchorProvider) ??
        ref.read(plannerViewStateProvider(_key))?.anchor ??
        ref.read<LocalDate>(plannerTodayProvider);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _week => ref.read(plannerViewConfigProvider(_key)).option<String>('scope', 'day') == 'week';

  void _go(LocalDate d) {
    setState(() => _day = d);
    ref.read(plannerAnchorProvider.notifier).set(d);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: d));
  }

  void _step(int dir) => _go(_day.plusDays(_week ? 7 * dir : dir));

  Future<void> _pick() async {
    final weekStart = ref.read(userPreferencesProvider).weekStart;
    final picked = await showMiniMonth(context, initial: _day, weekStart: weekStart, highlight: [_day]);
    if (picked != null) _go(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final today = ref.watch(plannerTodayProvider);
    final now = ref.watch(plannerNowProvider);
    final week = config.option<String>('scope', 'day') == 'week';
    final weekStart = weekStartFor(config, prefs.weekStart);
    final first = week ? _day.startOfWeek(weekStart) : _day;
    final days = [for (var i = 0; i < (week ? 7 : 1); i++) first.plusDays(i)];
    final range = DayRange(first, days.length);
    final f = context.plannerFormat(use24h: prefs.use24h);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final planned = filteredItems(ref, range, config).value ?? const <PlannerItem>[];
    final entries = ref.watch(plannerDemoModeProvider)
        ? const <TimeEntry>[]
        : (ref.watch(rangeTimeEntriesProvider(range)).value ?? const <TimeEntry>[]);
    final zones = ref.watch(zoneResolverProvider);
    final zone = ref.watch(plannerZoneProvider);
    final nowUtc = ref.read(clockProvider).nowUtc();
    final blocks = [
      for (final e in entries)
        ActualBlock(
          entryId: e.id,
          taskId: e.taskId,
          occurrenceKey: e.occurrenceKey,
          start: zones.toLocal(e.startedAt, zone),
          end: zones.toLocal(e.endedAt ?? nowUtc, zone),
          running: e.isRunning,
        ),
    ];
    final titleOf = {for (final p in planned) p.taskId: p.title};
    final unplanned = unplannedBlocks(blocks, planned);
    final colors = viewColors(context, ref, config);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: week ? rangeTitle(locale, first, first.plusDays(6)) : f.dayLong(_day),
        onPrevious: () => _step(-1),
        onNext: () => _step(1),
        onToday: () => _go(today),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: week ? l.pvPreviousWeek : l.pvPreviousDay,
        nextLabel: week ? l.pvNextWeek : l.pvNextDay,
        trailing: [
          SegmentedButton<String>(
            key: const Key('pva-scope'),
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: 'day', label: Text(l.pvDayRibbon)),
              ButtonSegment(value: 'week', label: Text(l.pvWeekRibbon)),
            ],
            selected: {if (week) 'week' else 'day'},
            onSelectionChanged: (s) =>
                ref.read(plannerViewConfigProvider(_key).notifier).change((c) => c.withOption('scope', s.first)),
          ),
          PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => _step(-1),
        onNext: () => _step(1),
        onToday: () => _go(today),
        child: Column(
          children: [
            ActiveFilterBar(viewKey: _key),
            // Day headers with the Plan / Actual sub-columns.
            Row(
              children: [
                const SizedBox(width: _rulerWidth),
                for (final d in days)
                  Expanded(
                    child: Column(
                      children: [
                        if (week)
                          Text(
                            f.dayShort(d),
                            maxLines: 1,
                            style: context.text.labelSmall?.copyWith(fontWeight: d == today ? FontWeight.w800 : null),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: Center(child: Text(l.pvPlanColumn, style: context.text.labelSmall)),
                            ),
                            Expanded(
                              child: Center(child: Text(l.pvActualColumn, style: context.text.labelSmall)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() < 300) return;
                  _step((rtl ? v > 0 : v < 0) ? 1 : -1);
                },
                child: SingleChildScrollView(
                  key: ValueKey('pva-${first.toIso()}-$week'),
                  controller: _scroll,
                  child: SizedBox(
                    height: 1440 * _ppm,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: _rulerWidth,
                          child: _Ruler(format: f),
                        ),
                        for (final d in days)
                          Expanded(
                            child: _DayColumns(
                              day: d,
                              now: now,
                              planned: [
                                for (final p in planned)
                                  if (!p.allDay && p.startLocal.date == d) p,
                              ],
                              blocks: [
                                for (final b in blocks)
                                  if (b.start.date == d) b,
                              ],
                              unplanned: {for (final b in unplanned) b.entryId},
                              titleOf: (id) => titleOf[id] ?? '',
                              colors: colors,
                              format: f,
                              onOpenPlan: (p) => unawaited(showOccurrenceSheet(context, p)),
                              onOpenBlock: (b) {
                                final p = planned
                                    .where(
                                      (p) =>
                                          p.taskId == b.taskId &&
                                          (b.occurrenceKey == null || p.occurrenceKey == b.occurrenceKey),
                                    )
                                    .firstOrNull;
                                if (p != null) {
                                  unawaited(showOccurrenceSheet(context, p));
                                } else {
                                  ref.read(plannerNavProvider).openTaskId(context, b.taskId);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ruler extends StatelessWidget {
  const _Ruler({required this.format});

  final AppFormat format;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (var h = 0; h < 24; h++)
        PositionedDirectional(
          top: h * 60 * _ppm,
          start: 0,
          end: Space.xxs,
          child: Text(
            format.time(LocalTime(h, 0)),
            textAlign: TextAlign.end,
            textScaler: TextScaler.noScaling,
            style: TextStyle(fontSize: 10, color: context.colors.onSurfaceVariant),
          ),
        ),
    ],
  );
}

class _DayColumns extends StatelessWidget {
  const _DayColumns({
    required this.day,
    required this.now,
    required this.planned,
    required this.blocks,
    required this.unplanned,
    required this.titleOf,
    required this.colors,
    required this.format,
    required this.onOpenPlan,
    required this.onOpenBlock,
  });

  final LocalDate day;
  final LocalDateTime now;
  final List<PlannerItem> planned;
  final List<ActualBlock> blocks;
  final Set<String> unplanned;
  final String Function(String taskId) titleOf;
  final ItemColorResolver colors;
  final AppFormat format;
  final ValueChanged<PlannerItem> onOpenPlan;
  final ValueChanged<ActualBlock> onOpenBlock;

  double _top(LocalDateTime t) => day.atStartOfDay.minutesUntil(t).clamp(0, 1440) * _ppm;

  String _varianceLabel(BuildContext context, Variance v) {
    final l = context.l10n;
    return switch (v) {
      Variance.onPlan => l.pvVarianceOnPlan,
      Variance.startedLate => l.pvVarianceLate,
      Variance.overran => l.pvVarianceOverran,
      Variance.notDone => l.pvVarianceNotDone,
      Variance.unplanned => l.pvVarianceUnplanned,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final warn = context.appColors.warning;
    final danger = context.appColors.danger;
    return LayoutBuilder(
      builder: (context, box) {
        final half = box.maxWidth / 2;
        return Stack(
          children: [
            for (var h = 0; h < 24; h++)
              PositionedDirectional(
                top: h * 60 * _ppm,
                start: 0,
                end: 0,
                height: 0.5,
                child: ColoredBox(color: c.outlineVariant.withValues(alpha: 0.5)),
              ),
            PositionedDirectional(
              start: half,
              top: 0,
              bottom: 0,
              width: 0.5,
              child: ColoredBox(color: c.outlineVariant),
            ),
            for (final p in planned)
              Builder(
                builder: (context) {
                  final variance = classifyVariance(p, blocksOf(p, blocks), now);
                  final flagged = variance.where((v) => v != Variance.onPlan).toList();
                  final tc = colors.of(p);
                  final label = [
                    p.title,
                    format.timeRange(p.startLocal, p.endLocal),
                    for (final v in variance) _varianceLabel(context, v),
                  ].join(', ');
                  return PositionedDirectional(
                    key: ValueKey('pva-plan-${p.key}'),
                    start: 1,
                    width: half - 2,
                    top: _top(p.startLocal),
                    height: math.max(18, p.durationMinutes * _ppm - 1),
                    child: Semantics(
                      button: true,
                      label: label,
                      child: ExcludeSemantics(
                        child: GestureDetector(
                          onTap: () => onOpenPlan(p),
                          child: Container(
                            padding: const EdgeInsetsDirectional.only(start: Space.xxs),
                            decoration: BoxDecoration(
                              color: tc.background,
                              borderRadius: BorderRadius.circular(Radii.sm),
                              border: Border.all(
                                color: flagged.contains(Variance.notDone)
                                    ? danger
                                    : (flagged.isEmpty ? tc.accent : warn),
                                width: flagged.isEmpty ? 1 : 2,
                              ),
                            ),
                            // One line when short ("Email · Not done"), two from 40 px.
                            child: Text(
                              [
                                p.title,
                                if (flagged.isNotEmpty) flagged.map((v) => _varianceLabel(context, v)).join(' · '),
                              ].join(p.durationMinutes * _ppm >= 40 ? '\n' : ' · '),
                              key: ValueKey('pva-plan-text-${p.key}'),
                              maxLines: p.durationMinutes * _ppm >= 40 ? 2 : 1,
                              overflow: TextOverflow.clip,
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(fontSize: 11, color: tc.foreground, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            for (final b in blocks)
              PositionedDirectional(
                key: ValueKey('pva-actual-${b.entryId}'),
                start: half + 1,
                width: half - 2,
                top: _top(b.start),
                height: math.max(8, b.minutes * _ppm - 1),
                child: Semantics(
                  button: true,
                  label: [
                    titleOf(b.taskId),
                    format.timeRange(b.start, b.end),
                    if (unplanned.contains(b.entryId)) _varianceLabel(context, Variance.unplanned),
                  ].join(', '),
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      onTap: () => onOpenBlock(b),
                      child: Container(
                        padding: const EdgeInsetsDirectional.only(start: Space.xxs),
                        decoration: BoxDecoration(
                          color: unplanned.contains(b.entryId)
                              ? c.tertiaryContainer
                              : c.primaryContainer.withValues(alpha: b.running ? 0.6 : 0.9),
                          borderRadius: BorderRadius.circular(Radii.sm),
                          border: unplanned.contains(b.entryId) ? Border.all(color: c.tertiary, width: 1.5) : null,
                        ),
                        child: Text(
                          titleOf(b.taskId).isEmpty ? _varianceLabel(context, Variance.unplanned) : titleOf(b.taskId),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(fontSize: 10.5, color: c.onPrimaryContainer),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (now.date == day)
              PositionedDirectional(
                start: 0,
                end: 0,
                top: _top(now),
                height: 1.5,
                child: ColoredBox(color: context.appColors.nowLine),
              ),
          ],
        );
      },
    );
  }
}
