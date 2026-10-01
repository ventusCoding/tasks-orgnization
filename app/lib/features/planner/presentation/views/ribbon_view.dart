import 'dart:async';

import 'package:collection/collection.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/time_grid.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/day_ribbon.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/planner_selection.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

/// Ribbon view (T3.6.13, Structured style) with `options.scope`:
/// - `day`: the day list's ribbon ([DayRibbon]) as its own view type, paged by day;
/// - `week`: seven columns, each day compressed to its items' icons in order (all-day first, then
///   timed by start). Tap an icon → task, long-press → tile menu, a day header → day ribbon.
class RibbonView extends ConsumerStatefulWidget {
  const RibbonView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<RibbonView> createState() => _RibbonViewState();
}

class _RibbonViewState extends ConsumerState<RibbonView> {
  late LocalDate _day;

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

  bool get _week => ref.read(plannerViewConfigProvider(_key)).option<String>('scope', 'day') == 'week';

  Weekday get _weekStart =>
      weekStartFor(ref.read(plannerViewConfigProvider(_key)), ref.read(userPreferencesProvider).weekStart);

  void _go(LocalDate date) {
    setState(() => _day = date);
    ref.read(plannerAnchorProvider.notifier).set(date);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: date));
  }

  void _step(int dir) => _go(_day.plusDays(_week ? 7 * dir : dir));

  void _setScope(String scope, {LocalDate? day}) {
    ref.read(plannerViewConfigProvider(_key).notifier).change((c) => c.withOption('scope', scope));
    if (day != null) _go(day);
  }

  Future<void> _pick() async {
    final picked = await showMiniMonth(context, initial: _day, weekStart: _weekStart, highlight: [_day]);
    if (picked != null) _go(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final today = ref.watch(plannerTodayProvider);
    final week = config.option<String>('scope', 'day') == 'week';
    final weekStart = weekStartFor(config, prefs.weekStart);
    final first = _day.startOfWeek(weekStart);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final f = context.plannerFormat(use24h: prefs.use24h);
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
            key: const Key('ribbon-scope'),
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: 'day', label: Text(l.pvDayRibbon)),
              ButtonSegment(value: 'week', label: Text(l.pvWeekRibbon)),
            ],
            selected: {if (week) 'week' else 'day'},
            onSelectionChanged: (s) => _setScope(s.first),
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
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() < 300) return;
                  _step((rtl ? v > 0 : v < 0) ? 1 : -1);
                },
                child: week
                    ? _WeekRibbon(
                        viewKey: _key,
                        first: first,
                        config: config,
                        onOpenDay: (d) => _setScope('day', day: d),
                      )
                    : _DayRibbonPage(viewKey: _key, day: _day, config: config),
              ),
            ),
          ],
        ),
      ),
      fab: PlannerFab(start: () => suggestedStart(week ? today : _day, ref.read(plannerNowProvider))),
    );
  }
}

/// The day ribbon of [day] (shared with the day list's ribbon style).
class _DayRibbonPage extends ConsumerWidget {
  const _DayRibbonPage({required this.viewKey, required this.day, required this.config});

  final String viewKey;
  final LocalDate day;
  final PlannerViewConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final filter = viewItemFilter(ref, config);
    final zone = ref.watch(plannerZoneProvider);
    final cache = ref.watch(timelineCacheProvider);
    final slices = ref.watch(daySlicesProvider(SliceKey(DayRange(day, 1), filter: filter))).value;
    final slice =
        slices?.firstWhereOrNull((s) => s.date == day) ??
        DaySlice(date: day, timeline: cache.of(day, zone), timed: const [], lane: const []);
    final commands = PlannerCommands(context, ref);
    return DayRibbon(
      key: ValueKey('ribbon-day-${day.toIso()}'),
      day: day,
      slice: slice,
      colors: viewColors(context, ref, config),
      format: context.plannerFormat(use24h: prefs.use24h),
      now: ref.watch(plannerNowProvider),
      dimPast: config.dimPast,
      onOpen: (i) => tapOrToggle(ref, viewKey, i, () => ref.read(plannerNavProvider).openTask(context, i)),
      onToggle: (i) => unawaited(commands.toggleDone(i)),
      onMenu: (i) => unawaited(
        commands.showTileMenu(i, onSelect: () => ref.read(plannerSelectionProvider(viewKey).notifier).select(i)),
      ),
      onCreate: (start, minutes) => unawaited(commands.quickCreate(start: start, duration: minutes)),
    );
  }
}

/// Seven day columns of item icons in order (Structured's week view).
class _WeekRibbon extends ConsumerWidget {
  const _WeekRibbon({required this.viewKey, required this.first, required this.config, required this.onOpenDay});

  final String viewKey;
  final LocalDate first;
  final PlannerViewConfig config;
  final ValueChanged<LocalDate> onOpenDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final today = ref.watch(plannerTodayProvider);
    final now = ref.watch(plannerNowProvider);
    final f = context.plannerFormat(use24h: prefs.use24h);
    final colors = viewColors(context, ref, config);
    final commands = PlannerCommands(context, ref);
    final items = filteredItems(ref, DayRange(first, 7), config).value ?? const <PlannerItem>[];
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekday = DateFormat.E(locale);
    final c = context.colors;
    final days = [
      for (var i = 0; i < 7; i++)
        if (config.showWeekends || !first.plusDays(i).weekday.isWeekend) first.plusDays(i),
    ];
    return SingleChildScrollView(
      key: ValueKey('ribbon-week-${first.toIso()}'),
      padding: const EdgeInsetsDirectional.fromSTEB(Space.xs, Space.sm, Space.xs, 96),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final d in days)
            Expanded(
              child: Builder(
                builder: (context) {
                  final dayItems = dayListOrder(itemsOnDay(items, d));
                  final isToday = d == today;
                  return Column(
                    key: ValueKey('ribbon-week-day-${d.toIso()}'),
                    children: [
                      Semantics(
                        button: true,
                        header: true,
                        label: '${f.dayLong(d)}, ${l.pvItemsCount(dayItems.length)}',
                        child: ExcludeSemantics(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(Radii.md),
                            onTap: () => onOpenDay(d),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    weekday.format(d.toDateTimeUtc()),
                                    maxLines: 1,
                                    style: context.text.labelSmall?.copyWith(color: c.onSurfaceVariant),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isToday ? c.primary : null,
                                    ),
                                    child: Text(
                                      f.number(d.day),
                                      style: context.text.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isToday ? c.onPrimary : c.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      for (final (n, i) in dayItems.indexed) ...[
                        if (n > 0) Container(width: 2, height: 10, color: c.outlineVariant),
                        _RibbonIcon(
                          item: i,
                          colors: colors.of(i),
                          label:
                              '${i.title}, ${i.allDay ? l.pvAllDay : f.timeRange(i.startLocal, i.endLocal)}, '
                              '${context.statusLabel(i.status)}',
                          past: config.dimPast && i.endLocal.isBefore(now),
                          onTap: () =>
                              tapOrToggle(ref, viewKey, i, () => ref.read(plannerNavProvider).openTask(context, i)),
                          onLongPress: () => unawaited(commands.showTileMenu(i)),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// One item as a colored icon bubble (rounded square for all-day items), ticked when done.
class _RibbonIcon extends StatelessWidget {
  const _RibbonIcon({
    required this.item,
    required this.colors,
    required this.label,
    required this.past,
    required this.onTap,
    required this.onLongPress,
  });

  final PlannerItem item;
  final TileColors colors;
  final String label;
  final bool past;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final done = item.isDone;
    final faded = done || item.status == OccurrenceStatus.skipped || item.status == OccurrenceStatus.cancelled;
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      onLongPress: onLongPress,
      child: ExcludeSemantics(
        child: InkResponse(
          key: ValueKey('ribbon-icon-${item.key}'),
          radius: 24,
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Opacity(
                opacity: faded ? 0.5 : (past ? 0.75 : 1),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: item.allDay ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: item.allDay ? BorderRadius.circular(Radii.sm) : null,
                    border: item.isCurrent ? Border.all(color: context.appColors.nowLine, width: 2.5) : null,
                  ),
                  child: Icon(
                    done ? Icons.check : IconCatalog.iconFor(item.icon, fallback: Icons.event),
                    size: 18,
                    color: CategoryColors.onBackground(colors.accent),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
