import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Days per resolver range of the agenda (T3.6.09).
const agendaChunkDays = 14;

/// Content (px) to keep built beyond the viewport at each end.
const _fillExtent = 1500.0;

/// Agenda / schedule view (T3.6.09): an infinite chronological list in both directions, grouped
/// by day; empty days collapse unless *Show empty days*; optional notes preview and a DayTicker
/// strip; inline check / open / menu. Data loads in 2-week ranges as you scroll.
///
/// Layout: the anchor day starts the *forward* region (sticky day headers); earlier ranges grow
/// upward from it in the *past* region (`CustomScrollView.center`), whose headers scroll with their
/// rows. Both directions append ranges without ever moving the scroll offset.
class AgendaView extends ConsumerStatefulWidget {
  const AgendaView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<AgendaView> createState() => _AgendaViewState();
}

/// Headers currently built, by day: the agenda reads their positions to find the day at the top.
class _HeaderRegistry {
  final Map<LocalDate, BuildContext> _byDay = {};

  void register(LocalDate day, BuildContext context) => _byDay[day] = context;

  void unregister(LocalDate day, BuildContext context) {
    if (identical(_byDay[day], context)) _byDay.remove(day);
  }

  /// The day whose header is at (or scrolled above) the top edge of [viewport]: the latest such day.
  LocalDate? topDay(RenderBox viewport) {
    LocalDate? best;
    for (final e in _byDay.entries) {
      if (!e.value.mounted) continue;
      final box = e.value.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final dy = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
      if (dy <= 1.0 && (best == null || e.key.isAfter(best))) best = e.key;
    }
    return best;
  }
}

class _AgendaViewState extends ConsumerState<AgendaView> {
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey(debugLabel: 'agenda-viewport');
  final _center = GlobalKey(debugLabel: 'agenda-center');
  final _headers = _HeaderRegistry();
  late LocalDate _origin;
  late LocalDate _topDay;

  /// Ranges built after / before the origin, and how far they may grow on their own (a sparse plan
  /// has empty stretches: the caps stop the chain and only scrolling into them raises them).
  int _forward = 3;
  int _past = 2;
  int _forwardCap = 8;
  int _pastCap = 8;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    final start = widget.args.date ?? ref.read(plannerAnchorProvider) ?? ref.read<LocalDate>(plannerTodayProvider);
    _origin = start;
    _topDay = start;
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    // Scrolling near an end lets the range grow again.
    if (p.extentAfter < _fillExtent) {
      _forwardCap = math.max(_forwardCap, _forward + 1);
    }
    if (p.extentBefore < _fillExtent) _pastCap = math.max(_pastCap, _past + 1);
    final viewport = _viewportKey.currentContext?.findRenderObject();
    final top = viewport is RenderBox ? _headers.topDay(viewport) : null;
    final topChanged = top != null && top != _topDay;
    if (topChanged) _topDay = top;
    if (_grow() || topChanged) setState(() {});
    if (topChanged) ref.read(plannerAnchorProvider.notifier).set(_topDay);
  }

  /// Adds one range at an end that is running short. Returns whether anything changed.
  bool _grow() {
    if (!_scroll.hasClients) return false;
    final p = _scroll.position;
    var grew = false;
    if (p.extentAfter < _fillExtent && _forward < _forwardCap) {
      _forward++;
      grew = true;
    }
    if (p.extentBefore < _fillExtent && _past < _pastCap) {
      _past++;
      grew = true;
    }
    return grew;
  }

  /// After every build: keeps filling until both ends have enough content (or hit their caps).
  void _fillAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _grow()) setState(() {});
    });
  }

  /// Dragging past an end (nothing left to scroll) loads two more ranges there.
  bool _onNotification(ScrollNotification n) {
    if (n is OverscrollNotification && n.metrics.axis == Axis.vertical) {
      setState(() {
        if (n.overscroll > 0) {
          _forwardCap = _forward + 2;
        } else {
          _pastCap = _past + 2;
        }
      });
    }
    return false;
  }

  Future<void> _pick() async {
    final picked = await pickDate(context, initial: _topDay);
    if (picked != null) _jump(picked);
  }

  void _jump(LocalDate date) {
    setState(() {
      _origin = date;
      _topDay = date;
      _forward = 3;
      _past = 2;
      _forwardCap = 8;
      _pastCap = 8;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    ref.read(plannerAnchorProvider.notifier).set(date);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: date));
  }

  LocalDate _chunkStart(int i) => _origin.plusDays(i * agendaChunkDays);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final today = ref.watch(plannerTodayProvider);
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final notifier = ref.read(plannerViewConfigProvider(_key).notifier);
    final showEmpty = config.option<bool>('showEmptyDays', false);
    final showNotes = config.option<bool>('showNotes', false);
    final ticker = config.option<bool>('ticker', true);
    _fillAfterBuild();
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: f.monthYear(_topDay),
        onPrevious: () => _jump(_topDay.plusDays(-agendaChunkDays)),
        onNext: () => _jump(_topDay.plusDays(agendaChunkDays)),
        onToday: () => _jump(today),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: l.pvPrevious,
        nextLabel: l.pvNext,
        trailing: [
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(
            viewKey: _key,
            kind: ViewSettingsKind.list,
            extra: [
              ('empty', l.pvShowEmptyDays, () => notifier.change((c) => c.withOption('showEmptyDays', !showEmpty))),
              ('notes', l.pvShowNotes, () => notifier.change((c) => c.withOption('showNotes', !showNotes))),
              ('ticker', l.pvDayTicker, () => notifier.change((c) => c.withOption('ticker', !ticker))),
            ],
          ),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => _jump(_topDay.plusDays(-agendaChunkDays)),
        onNext: () => _jump(_topDay.plusDays(agendaChunkDays)),
        onToday: () => _jump(today),
        child: Column(
          children: [
            ActiveFilterBar(viewKey: _key),
            if (ticker)
              _DayTicker(
                viewKey: _key,
                week: _topDay.startOfWeek(ref.watch(userPreferencesProvider).weekStart),
                config: config,
                selected: _topDay,
                onDay: _jump,
              ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onNotification,
                child: CustomScrollView(
                  key: _viewportKey,
                  controller: _scroll,
                  center: _center,
                  slivers: [
                    // Past ranges, nearest first (they grow upward from the centre).
                    for (var i = _past; i >= 1; i--)
                      _AgendaChunk(
                        key: ValueKey('agenda-past-${_chunkStart(-i).toIso()}'),
                        viewKey: _key,
                        start: _chunkStart(-i),
                        forward: false,
                        config: config,
                        today: today,
                        showEmpty: showEmpty,
                        showNotes: showNotes,
                        registry: _headers,
                      ),
                    SliverToBoxAdapter(key: _center, child: const SizedBox.shrink()),
                    for (var i = 0; i < _forward; i++)
                      _AgendaChunk(
                        key: ValueKey('agenda-chunk-${_chunkStart(i).toIso()}'),
                        viewKey: _key,
                        start: _chunkStart(i),
                        forward: true,
                        config: config,
                        today: today,
                        target: i == 0 ? _origin : null,
                        showEmpty: showEmpty,
                        showNotes: showNotes,
                        registry: _headers,
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      fab: PlannerFab(start: () => suggestedStart(_topDay, ref.read(plannerNowProvider))),
    );
  }
}

/// One day of a chunk: the day, its ordered items and whether it stays visible while empty.
class _DayGroup {
  const _DayGroup(this.day, this.items);

  final LocalDate day;
  final List<PlannerItem> items;
}

/// Two weeks of days: a sticky header + item list per day that has items (or every day with
/// *Show empty days*; today and the anchor day are always shown). In the past region a day is one
/// box (header + items) in reverse chronological order so it grows upward from the centre.
class _AgendaChunk extends ConsumerWidget {
  const _AgendaChunk({
    required this.viewKey,
    required this.start,
    required this.forward,
    required this.config,
    required this.today,
    required this.showEmpty,
    required this.showNotes,
    required this.registry,
    this.target,
    super.key,
  });

  final String viewKey;
  final LocalDate start;
  final bool forward;
  final PlannerViewConfig config;
  final LocalDate today;
  final LocalDate? target;
  final bool showEmpty;
  final bool showNotes;
  final _HeaderRegistry registry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = filteredItems(ref, DayRange(start, agendaChunkDays), config);
    final items = value.value;
    if (items == null) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 96,
          child: value.hasError ? const SizedBox.shrink() : const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final groups = <_DayGroup>[
      for (var d = 0; d < agendaChunkDays; d++)
        if (_shown(start.plusDays(d), itemsOnDay(items, start.plusDays(d))))
          _DayGroup(start.plusDays(d), dayListOrder(itemsOnDay(items, start.plusDays(d)))),
    ];
    if (groups.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final colors = viewColors(context, ref, config);
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    Widget row(PlannerItem item, LocalDate day) => Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: PlannerItemChip(
        viewKey: viewKey,
        item: item,
        colors: colors.of(item),
        showNotes: showNotes,
        trailing: item.isMultiDay && item.startLocal.date != day
            ? Text(f.dayShort(item.startLocal.date), style: context.text.labelSmall)
            : null,
      ),
    );
    if (!forward) {
      final reversed = groups.reversed.toList();
      return SliverList.builder(
        itemCount: reversed.length,
        itemBuilder: (context, i) {
          final g = reversed[i];
          return Column(
            key: ValueKey('agenda-day-${g.day.toIso()}'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DayHeader(day: g.day, isToday: g.day == today, count: g.items.length, registry: registry),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, 0, Space.sm, Space.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [if (g.items.isEmpty) _EmptyDay(), for (final item in g.items) row(item, g.day)],
                ),
              ),
            ],
          );
        },
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        for (final g in groups)
          SliverMainAxisGroup(
            key: ValueKey('agenda-day-${g.day.toIso()}'),
            slivers: [
              PinnedHeaderSliver(
                child: _DayHeader(day: g.day, isToday: g.day == today, count: g.items.length, registry: registry),
              ),
              if (g.items.isEmpty)
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, 0, Space.sm, Space.sm),
                  sliver: SliverToBoxAdapter(child: _EmptyDay()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, 0, Space.sm, Space.sm),
                  sliver: SliverList.builder(
                    itemCount: g.items.length,
                    itemBuilder: (context, i) => row(g.items[i], g.day),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  bool _shown(LocalDate day, List<PlannerItem> dayItems) =>
      dayItems.isNotEmpty || showEmpty || day == today || day == target;
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: Space.xs, bottom: Space.xs),
    child: Text(
      context.l10n.pvEmptyDay,
      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
    ),
  );
}

class _DayHeader extends ConsumerStatefulWidget {
  const _DayHeader({required this.day, required this.isToday, required this.count, required this.registry});

  final LocalDate day;
  final bool isToday;
  final int count;
  final _HeaderRegistry registry;

  @override
  ConsumerState<_DayHeader> createState() => _DayHeaderState();
}

class _DayHeaderState extends ConsumerState<_DayHeader> {
  late _HeaderRegistry _registry;
  late LocalDate _day;

  @override
  void initState() {
    super.initState();
    _registry = widget.registry;
    _day = widget.day;
    _registry.register(_day, context);
  }

  @override
  void didUpdateWidget(_DayHeader old) {
    super.didUpdateWidget(old);
    if (old.day != widget.day || !identical(old.registry, widget.registry)) {
      _registry.unregister(_day, context);
      _registry = widget.registry;
      _day = widget.day;
      _registry.register(_day, context);
    }
  }

  @override
  void dispose() {
    _registry.unregister(_day, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final day = widget.day;
    return Semantics(
      header: true,
      button: true,
      label: '${f.dayLong(day)}, ${l.pvItemsCount(widget.count)}',
      child: Material(
        color: c.surface,
        child: InkWell(
          key: ValueKey('agenda-header-${day.toIso()}'),
          onTap: () => ref.read(plannerNavProvider).openView(context, 'day_list', date: day),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.md, Space.sm, Space.md, Space.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    f.dayLong(day),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: widget.isToday ? c.primary : null,
                    ),
                  ),
                ),
                if (widget.isToday)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.sm),
                    child: Text(l.actionToday, style: context.text.labelSmall?.copyWith(color: c.primary)),
                  ),
                Text(l.pvItemsCount(widget.count), style: context.text.labelSmall?.copyWith(color: c.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// DayTicker-style strip (T3.6.09): the week's days with colored pills at their approximate time;
/// tap a day to jump the agenda to it.
class _DayTicker extends ConsumerWidget {
  const _DayTicker({
    required this.viewKey,
    required this.week,
    required this.config,
    required this.selected,
    required this.onDay,
  });

  final String viewKey;
  final LocalDate week;
  final PlannerViewConfig config;
  final LocalDate selected;
  final ValueChanged<LocalDate> onDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = filteredItems(ref, DayRange(week, 7), config).value ?? const <PlannerItem>[];
    final colors = viewColors(context, ref, config);
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final today = ref.watch(plannerTodayProvider);
    final c = context.colors;
    return SizedBox(
      key: const Key('day-ticker'),
      height: 64,
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = week.plusDays(i);
                  final dayItems = [
                    for (final it in itemsOnDay(items, day))
                      if (!it.allDay) it,
                  ];
                  return Semantics(
                    button: true,
                    selected: day == selected,
                    label: f.dayLong(day),
                    child: InkWell(
                      key: ValueKey('ticker-${day.toIso()}'),
                      onTap: () => onDay(day),
                      child: Column(
                        children: [
                          Text(
                            f.dayShort(day),
                            maxLines: 1,
                            style: context.text.labelSmall?.copyWith(
                              fontWeight: day == today || day == selected ? FontWeight.w800 : null,
                              color: day == today ? c.primary : c.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: c.surfaceContainerHighest.withValues(alpha: day == selected ? 0.9 : 0.5),
                                  borderRadius: BorderRadius.circular(Radii.sm),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, box) => Stack(
                                    children: [
                                      for (final it in dayItems)
                                        PositionedDirectional(
                                          start: 2,
                                          end: 2,
                                          top: box.maxHeight * it.startLocal.time.minuteOfDay / 1440,
                                          height: (box.maxHeight * it.durationMinutes / 1440).clamp(2.0, box.maxHeight),
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: colors.of(it).accent,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
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
                },
              ),
            ),
        ],
      ),
    );
  }
}
