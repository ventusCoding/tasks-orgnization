import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_rows.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot/features/planner/presentation/grid/engine/drag_math.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_controller.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/view_config/slot_size_sheet.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/day_ribbon.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_keys.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The day of [slice] as items for lists: all-day / lane items (manual order, then title) and
/// quota slots first, then timed items by start.
({List<PlannerItem> allDay, List<DayEntry> timed}) dayListItems(
  DaySlice slice,
) {
  final seen = <String>{};
  final allDay =
      [
        for (final i in slice.lane)
          if (seen.add(i.key)) i,
      ]..sort((a, b) {
        final ka = a.manualSortKey;
        final kb = b.manualSortKey;
        if (ka != null && kb != null && ka != kb) return ka.compareTo(kb);
        return a.title.compareTo(b.title);
      });
  var lane = 0;
  return (
    allDay: allDay,
    timed: [
      for (final s in slice.timed)
        if (seen.add(s.item.key))
          DayEntry(
            item: s.item,
            tStart: s.tStart,
            tEnd: s.tEnd,
            lane: lane++,
            continues: s.continuesBefore,
            continuesAfter: s.continuesAfter,
          ),
    ],
  );
}

/// The Day list view (T3.5.01–T3.5.14): a date strip, then the selected day's slots as a list —
/// 1 minute to 24 hours per row, DST aware, lazily built — with the all-day section on top.
/// Swiping the list changes the day and keeps the time position.
class DayListView extends ConsumerStatefulWidget {
  const DayListView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<DayListView> createState() => _DayListViewState();
}

class _DayListViewState extends ConsumerState<DayListView>
    implements GridNavigator {
  static const _base = 100000;
  final _controller = PlannerGridController();
  late LocalDate _origin;
  late LocalDate _day;
  late final PageController _pages = PageController(initialPage: _base);

  /// Minute at the top of the list, shared by the day pages (T3.5.09).
  double? _topMinute;

  /// Scroll requests for the page of a day: (day, minute, anchor fraction).
  final ValueNotifier<(LocalDate, double, double)?> _scrollRequest =
      ValueNotifier(null);

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    final LocalDate today = ref.read(plannerTodayProvider);
    final LocalDate? shared = ref.read(plannerAnchorProvider);
    final LocalDate? stored = ref.read(plannerViewStateProvider(_key))?.anchor;
    _origin = widget.args.date ?? shared ?? stored ?? today;
    _day = _origin;
    _topMinute = ref.read(plannerScrollMinuteProvider);
    _controller.attach(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.updateVisibleDays([_day]);
    });
  }

  @override
  void didUpdateWidget(DayListView old) {
    super.didUpdateWidget(old);
    final date = widget.args.date;
    if (date != null && date != old.args.date) unawaited(jumpToDate(date));
  }

  @override
  void dispose() {
    _controller
      ..detach(this)
      ..dispose();
    _pages.dispose();
    _scrollRequest.dispose();
    super.dispose();
  }

  LocalDate _dayAt(int index) => _origin.plusDays(index - _base);

  int _indexOf(LocalDate d) => _base + _origin.daysUntil(d);

  void _onPage(int index) {
    final d = _dayAt(index);
    if (d == _day) return;
    setState(() => _day = d);
    _controller.updateVisibleDays([d]);
    ref.read(plannerAnchorProvider.notifier).set(d);
    ref
        .read(plannerViewStateProvider(_key).notifier)
        .update((s) => s.copyWith(anchor: d));
  }

  @override
  Future<void> jumpToDate(
    LocalDate date, {
    bool animate = true,
    double? minute,
    double anchorFraction = 0,
  }) async {
    if (minute != null) {
      _topMinute = minute;
      _scrollRequest.value = (date, minute, anchorFraction);
    }
    if (!_pages.hasClients) return;
    final target = _indexOf(date);
    final current = _pages.page?.round() ?? _base;
    if (animate &&
        (target - current).abs() <= 3 &&
        !MediaQuery.of(context).disableAnimations) {
      await _pages.animateToPage(
        target,
        duration: Motion.normal,
        curve: Motion.curve,
      );
    } else {
      _pages.jumpToPage(target);
    }
    _onPage(target);
  }

  @override
  Future<void> step(int pages) => jumpToDate(_day.plusDays(pages));

  @override
  void scrollToMinute(
    double minute, {
    bool animate = true,
    double anchorFraction = 0,
  }) => _scrollRequest.value = (_day, minute, anchorFraction);

  @override
  void zoomBy(double factor) {}

  Future<void> _today() async {
    final now = ref.read(plannerNowProvider);
    await jumpToDate(
      now.date,
      minute: now.time.minuteOfDay.toDouble(),
      anchorFraction: 1 / 3,
    );
  }

  Future<void> _pickDay() async {
    final picked = await showMiniMonth(
      context,
      initial: _day,
      weekStart: ref.read(userPreferencesProvider).weekStart,
      highlight: [_day],
    );
    if (picked != null) await jumpToDate(picked);
  }

  Future<void> _farJump() async {
    final picked = await pickDate(context, initial: _day);
    if (picked != null) await jumpToDate(picked, animate: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final f = context.plannerFormat(use24h: prefs.use24h);
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: f.dayLong(_day),
        onPrevious: () => unawaited(step(-1)),
        onNext: () => unawaited(step(1)),
        onToday: () => unawaited(_today()),
        onTodayLongPress: () => unawaited(_farJump()),
        onTitleTap: () => unawaited(_pickDay()),
        previousLabel: l.pvPreviousDay,
        nextLabel: l.pvNextDay,
        trailing: [
          SlotSizeButton(
            label: slotLabel(f, config.slotMinutes),
            onPressed: () => unawaited(
              showSlotSizeSheet(context, ref, viewKey: _key, timeGrid: false),
            ),
          ),
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(
            viewKey: _key,
            kind: ViewSettingsKind.dayList,
            extra: [
              (
                'style',
                config.option<String>('style', 'slots') == 'ribbon'
                    ? l.pvSlotsStyle
                    : l.pvRibbonStyle,
                () => ref
                    .read(plannerViewConfigProvider(_key).notifier)
                    .change(
                      (c) => c.withOption(
                        'style',
                        c.option<String>('style', 'slots') == 'ribbon'
                            ? 'slots'
                            : 'ribbon',
                      ),
                    ),
              ),
            ],
          ),
        ],
      ),
      body: PlannerKeys(
        onPrevious: () => unawaited(step(-1)),
        onNext: () => unawaited(step(1)),
        onToday: () => unawaited(_today()),
        child: Column(
          children: [
            DateStrip(
              selected: _day,
              weekStart: prefs.weekStart,
              onSelect: (d) => unawaited(jumpToDate(d)),
            ),
            ActiveFilterBar(viewKey: _key),
            Expanded(
              child: PageView.builder(
                key: const Key('day-pages'),
                controller: _pages,
                onPageChanged: _onPage,
                itemBuilder: (context, index) => DayListPage(
                  key: ValueKey(_dayAt(index)),
                  viewKey: _key,
                  day: _dayAt(index),
                  initialTopMinute: _topMinute,
                  onTopMinute: (m) {
                    _topMinute = m;
                    ref.read(plannerScrollMinuteProvider.notifier).set(m);
                  },
                  scrollRequest: _scrollRequest,
                ),
              ),
            ),
          ],
        ),
      ),
      fab: PlannerFab(
        start: () => suggestedStart(_day, ref.read(plannerNowProvider)),
      ),
    );
  }
}

/// Week strip of day chips (T3.5.01): weekday, date and a load dot; swipe to change week.
class DateStrip extends ConsumerStatefulWidget {
  const DateStrip({
    required this.selected,
    required this.weekStart,
    required this.onSelect,
    super.key,
  });

  final LocalDate selected;
  final Weekday weekStart;
  final ValueChanged<LocalDate> onSelect;

  @override
  ConsumerState<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends ConsumerState<DateStrip> {
  static const _base = 5000;
  late LocalDate _originWeek = widget.selected.startOfWeek(widget.weekStart);
  late final PageController _pages = PageController(initialPage: _base);

  LocalDate _weekAt(int i) => _originWeek.plusDays((i - _base) * 7);

  @override
  void didUpdateWidget(DateStrip old) {
    super.didUpdateWidget(old);
    if (old.weekStart != widget.weekStart) {
      _originWeek = widget.selected.startOfWeek(widget.weekStart);
      if (_pages.hasClients) _pages.jumpToPage(_base);
      return;
    }
    final week = widget.selected.startOfWeek(widget.weekStart);
    final target = _base + _originWeek.daysUntil(week) ~/ 7;
    if (_pages.hasClients && (_pages.page?.round() ?? _base) != target) {
      unawaited(
        _pages.animateToPage(
          target,
          duration: Motion.normal,
          curve: Motion.curve,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: PageView.builder(
      key: const Key('date-strip'),
      controller: _pages,
      itemBuilder: (context, i) => _WeekChips(
        week: _weekAt(i),
        selected: widget.selected,
        onSelect: widget.onSelect,
      ),
    ),
  );
}

class _WeekChips extends ConsumerWidget {
  const _WeekChips({
    required this.week,
    required this.selected,
    required this.onSelect,
  });

  final LocalDate week;
  final LocalDate selected;
  final ValueChanged<LocalDate> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = DayRange(week, 7);
    final items =
        ref.watch(viewItemsProvider(range)).value ?? const <PlannerItem>[];
    final counts = countsByDay(items, range);
    final today = ref.watch(plannerTodayProvider);
    final f = context.plannerFormat();
    final l = context.l10n;
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(
              builder: (context) {
                final d = week.plusDays(i);
                final isSelected = d == selected;
                final count = counts[d] ?? 0;
                final c = context.colors;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: '${f.dayLong(d)}, ${l.pvItemsCount(count)}',
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: Space.xs,
                      ),
                      child: InkWell(
                        key: Key('strip-${d.toIso()}'),
                        borderRadius: BorderRadius.circular(Radii.md),
                        onTap: () => onSelect(d),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? c.primary
                                : (d == today
                                      ? c.primaryContainer.withValues(
                                          alpha: 0.5,
                                        )
                                      : null),
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(Space.xs),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    f.weekdayShort(d.weekday),
                                    style: context.text.labelSmall?.copyWith(
                                      color: isSelected
                                          ? c.onPrimary
                                          : c.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    f.number(d.day),
                                    style: context.text.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? c.onPrimary
                                          : c.onSurface,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 6,
                                    child: count == 0
                                        ? null
                                        : ColorDot(
                                            isSelected
                                                ? c.onPrimary
                                                : c.primary,
                                            size: math.min(
                                              6,
                                              3 + count.toDouble(),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------- page --

/// A drag in the list: creating a range from empty rows or moving an item (T3.5.07 / T3.5.13).
class _ListDrag {
  _ListDrag.create(this.fromRow) : item = null, fromAllDay = false;
  _ListDrag.move(this.item, this.fromRow, {this.fromAllDay = false});

  final PlannerItem? item;
  final int fromRow;
  final bool fromAllDay;
  int toRow = -1;
  bool toAllDay = false;
  bool moved = false;
  Offset global = Offset.zero;
}

/// One day of the day list.
class DayListPage extends ConsumerStatefulWidget {
  const DayListPage({
    required this.viewKey,
    required this.day,
    required this.onTopMinute,
    required this.scrollRequest,
    this.initialTopMinute,
    super.key,
  });

  final String viewKey;
  final LocalDate day;
  final double? initialTopMinute;
  final ValueChanged<double> onTopMinute;
  final ValueListenable<(LocalDate, double, double)?> scrollRequest;

  @override
  ConsumerState<DayListPage> createState() => _DayListPageState();
}

class _DayListPageState extends ConsumerState<DayListPage>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _listKey = GlobalKey();
  final Set<int> _expandedRuns = {};
  bool _allDayOpen = true;
  final ValueNotifier<int?> _nowT = ValueNotifier(null);
  final ValueNotifier<(int, int)?> _highlight = ValueNotifier(null);
  final ValueNotifier<bool> _showNowButton = ValueNotifier(false);

  /// Hour (wall minute, repeat pass) of the first visible row: the sticky hour header (T3.5.03).
  final ValueNotifier<(int, int)?> _stickyHour = ValueNotifier(null);
  Timer? _timer;
  bool _initialScrolled = false;
  _ListDrag? _drag;
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;

  static const _allDayDropExtent = 40.0;

  // Layout of the last build (offset math).
  List<DayListRow> _display = const [];
  List<double> _tops = const [];
  List<double> _extents = const [];
  DaySlice? _slice;

  @override
  void initState() {
    super.initState();
    widget.scrollRequest.addListener(_onScrollRequest);
    _scroll.addListener(_onScroll);
    _tickNow();
  }

  @override
  void dispose() {
    widget.scrollRequest.removeListener(_onScrollRequest);
    _timer?.cancel();
    _ticker.dispose();
    _scroll.dispose();
    _nowT.dispose();
    _highlight.dispose();
    _showNowButton.dispose();
    _stickyHour.dispose();
    super.dispose();
  }

  void _tickNow() {
    final now = ref.read(clockProvider).nowUtc();
    final slice = _slice;
    if (slice != null) {
      final t = slice.timeline.tOfInstant(now);
      _nowT.value = t >= 0 && t < slice.timeline.lengthMinutes ? t : null;
    }
    _timer = Timer(Duration(seconds: 60 - now.second), () {
      if (mounted) _tickNow();
    });
  }

  void _onScrollRequest() {
    final r = widget.scrollRequest.value;
    if (r == null || r.$1 != widget.day) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToT(_tOfWall(r.$2), anchorFraction: r.$3);
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final t = _tAtOffset(_scroll.offset);
    if (t != null) widget.onTopMinute(_wallOfT(t).toDouble());
    final tl = _slice?.timeline;
    if (t != null && tl != null && _scroll.offset > 0.5) {
      final (wall, repeat) = tl.wallAt(
        t.clamp(0, math.max(0, tl.lengthMinutes - 1)),
      );
      _stickyHour.value = ((wall ~/ 60) * 60, repeat);
    } else {
      _stickyHour.value = null;
    }
    final now = _nowT.value;
    if (now == null) {
      _showNowButton.value = false;
    } else {
      final y = _offsetOfT(now);
      final viewport = _scroll.position.viewportDimension;
      _showNowButton.value =
          y < _scroll.offset - 8 || y > _scroll.offset + viewport - 24;
    }
  }

  int _tOfWall(double wall) =>
      _slice?.timeline.tOfWall(wall.floor().clamp(0, 1440)) ?? wall.floor();

  int _wallOfT(int t) => _slice?.timeline.wallAt(t).$1 ?? t;

  /// Content offset of elapsed minute [t] (top of its row + fraction).
  double _offsetOfT(int t) {
    for (var i = 0; i < _display.length; i++) {
      final (a, b) = _rangeOf(_display[i]);
      if (t < b || i == _display.length - 1) {
        final frac = b <= a ? 0.0 : ((t - a) / (b - a)).clamp(0.0, 1.0);
        return _tops[i] + frac * _extents[i];
      }
    }
    return 0;
  }

  int? _tAtOffset(double y) {
    final i = _indexAtOffset(y);
    if (i == null) return null;
    final (a, b) = _rangeOf(_display[i]);
    final frac = _extents[i] <= 0
        ? 0.0
        : ((y - _tops[i]) / _extents[i]).clamp(0.0, 1.0);
    return (a + frac * (b - a)).floor();
  }

  int? _indexAtOffset(double y) {
    if (_display.isEmpty) return null;
    var lo = 0;
    var hi = _tops.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_tops[mid] <= y) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  (int, int) _rangeOf(DayListRow r) => switch (r) {
    SlotListRow(:final row) => (row.tStart, row.tEnd),
    FreeListRow() => (r.tStart, r.tEnd),
  };

  void _scrollToT(int t, {double anchorFraction = 0, bool animate = true}) {
    if (!_scroll.hasClients) return;
    final viewport = _scroll.position.viewportDimension;
    final target = (_offsetOfT(t) - viewport * anchorFraction).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if (animate && !MediaQuery.of(context).disableAnimations) {
      unawaited(
        _scroll.animateTo(target, duration: Motion.normal, curve: Motion.curve),
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  void _initialScroll(
    PlannerViewConfig config,
    LocalDate today,
    LocalDateTime now,
  ) {
    if (_initialScrolled) return;
    _initialScrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (widget.day == today && config.autoScrollToNow) {
        _scrollToT(
          _tOfWall(now.time.minuteOfDay.toDouble()),
          anchorFraction: 1 / 3,
          animate: false,
        );
      } else if (widget.initialTopMinute != null) {
        _scrollToT(_tOfWall(widget.initialTopMinute!), animate: false);
      } else {
        final first = _slice?.timed.firstOrNull;
        _scrollToT(
          first == null ? _tOfWall(8 * 60) : math.max(0, first.tStart - 60),
          animate: false,
        );
      }
      _onScroll();
    });
  }

  // ------------------------------------------------------------------------------ drags --

  RenderBox? get _listBox =>
      _listKey.currentContext?.findRenderObject() as RenderBox?;

  /// Display row at a global position (null when outside the list).
  int? _rowAtGlobal(Offset global) {
    final box = _listBox;
    if (box == null || !_scroll.hasClients) return null;
    final local = box.globalToLocal(global);
    if (local.dy < 0 || local.dy > box.size.height) return null;
    return _indexAtOffset(local.dy + _scroll.offset);
  }

  void _startCreate(int displayIndex, Offset global) {
    _drag = _ListDrag.create(displayIndex)
      ..toRow = displayIndex
      ..global = global;
    ref.read(plannerHapticsProvider).lift();
    _highlight.value = (displayIndex, displayIndex);
    _lastTick = Duration.zero;
    if (!_ticker.isActive) unawaited(_ticker.start());
  }

  void _startMove(
    PlannerItem item,
    int displayIndex,
    Offset global, {
    bool fromAllDay = false,
  }) {
    _drag = _ListDrag.move(item, displayIndex, fromAllDay: fromAllDay)
      ..toRow = displayIndex
      ..toAllDay = fromAllDay
      ..global = global;
    ref.read(plannerHapticsProvider).lift();
    setState(() {});
    _highlight.value = fromAllDay ? null : (displayIndex, displayIndex);
    _lastTick = Duration.zero;
    if (!_ticker.isActive) unawaited(_ticker.start());
  }

  void _updateDrag(Offset global) {
    final d = _drag;
    if (d == null) return;
    d.global = global;
    final row = _rowAtGlobal(global);
    final box = _listBox;
    final strip =
        d.item != null &&
            !d.fromAllDay &&
            (_slice == null || dayListItems(_slice!).allDay.isEmpty)
        ? _allDayDropExtent
        : 0.0;
    final aboveList = box != null && box.globalToLocal(global).dy < strip;
    if (d.item != null && aboveList) {
      if (!d.toAllDay) ref.read(plannerHapticsProvider).selection();
      d
        ..toAllDay = true
        ..moved = true;
      _highlight.value = null;
      setState(() {});
      return;
    }
    if (row == null) return;
    if (row != d.toRow || d.toAllDay) {
      ref.read(plannerHapticsProvider).selection();
      d
        ..moved = true
        ..toAllDay = false
        ..toRow = row;
      _highlight.value = d.item == null
          ? (math.min(d.fromRow, row), math.max(d.fromRow, row))
          : (row, row);
      setState(() {});
    }
  }

  void _onTick(Duration elapsed) {
    final d = _drag;
    final box = _listBox;
    if (d == null || box == null || !_scroll.hasClients) {
      _ticker.stop();
      return;
    }
    final dt = _lastTick == Duration.zero
        ? 0.0
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0) return;
    final y = box.globalToLocal(d.global).dy;
    final speed = DragMath.autoScrollSpeed(y, 0, box.size.height);
    if (speed == 0) return;
    final pos = _scroll.position;
    final next = (pos.pixels + speed * dt).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    if (next != pos.pixels) {
      _scroll.jumpTo(next);
      _updateDrag(d.global);
    }
  }

  Future<void> _endDrag() async {
    final d = _drag;
    _drag = null;
    _ticker.stop();
    _highlight.value = null;
    if (mounted) setState(() {});
    if (d == null) return;
    final commands = PlannerCommands(context, ref);
    final l = context.l10n;
    final f = context.plannerFormat(
      use24h: ref.read(userPreferencesProvider).use24h,
    );
    final item = d.item;
    if (item == null) {
      final a = math.min(d.fromRow, d.toRow);
      final b = math.max(d.fromRow, d.toRow);
      if (a < 0 || b >= _display.length) return;
      final (ta, _) = _rangeOf(_display[a]);
      final (_, tb) = _rangeOf(_display[b]);
      final start = widget.day.atStartOfDay.plusMinutes(_wallOfT(ta));
      final minutes = math.max(1, _wallDuration(ta, tb));
      await commands.quickCreate(
        start: start,
        duration: d.moved
            ? minutes
            : quickCreateDuration(
                ref.read(plannerViewConfigProvider(widget.viewKey)).slotMinutes,
                ref.read(plannerWorkSettingsProvider),
              ),
      );
      return;
    }
    if (!d.moved) {
      await commands.showTileMenu(item);
      return;
    }
    if (d.toAllDay) {
      if (item.allDay) return;
      await commands.reschedule(
        item,
        start: widget.day.atStartOfDay,
        duration: 1440,
        allDay: true,
        message: l.pvMovedSnack('${f.dayShort(widget.day)} · ${l.pvAllDay}'),
      );
      return;
    }
    if (d.toRow < 0 || d.toRow >= _display.length) return;
    final (ta, _) = _rangeOf(_display[d.toRow]);
    final start = widget.day.atStartOfDay.plusMinutes(_wallOfT(ta));
    if (start == item.startLocal && !item.allDay) return;
    await commands.reschedule(
      item,
      start: start,
      duration: item.allDay ? 30 : null,
      allDay: item.allDay ? false : null,
      message: l.pvMovedSnack('${f.dayShort(start.date)} ${f.timeOf(start)}'),
    );
  }

  int _wallDuration(int ta, int tb) {
    final tl = _slice?.timeline;
    if (tl == null) return tb - ta;
    final (wa, _) = tl.wallAt(ta);
    final (wb, _) = tl.wallAtEnd(tb);
    return math.max(tb - ta, wb - wa);
  }

  // ------------------------------------------------------------------------------ build --

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(widget.viewKey));
    final prefs = ref.watch(userPreferencesProvider);
    final zone = ref.watch(plannerZoneProvider);
    final cache = ref.watch(timelineCacheProvider);
    final work = ref.watch(plannerWorkSettingsProvider);
    final today = ref.watch(plannerTodayProvider);
    final now = ref.read(plannerNowProvider);
    final filter = viewItemFilter(ref, config);
    final chunk = widget.day.startOfWeek(prefs.weekStart);
    final slices = ref
        .watch(daySlicesProvider(SliceKey(DayRange(chunk, 7), filter: filter)))
        .value;
    final slice =
        slices?.firstWhereOrNull((s) => s.date == widget.day) ??
        DaySlice(
          date: widget.day,
          timeline: cache.of(widget.day, zone),
          timed: const [],
          lane: const [],
        );
    final f = context.plannerFormat(use24h: prefs.use24h);
    final colors = ItemColorResolver(
      colorBy: config.colorBy,
      brightness: Theme.of(context).brightness,
      categoryColor: ref.watch(categoryColorLookupProvider),
      statusColor: context.statusColor,
    );
    if (!identical(slice, _slice)) {
      _slice = slice;
      final t = slice.timeline.tOfInstant(ref.read(clockProvider).nowUtc());
      _nowT.value = t >= 0 && t < slice.timeline.lengthMinutes ? t : null;
    }
    final lists = dayListItems(slice);
    final agenda = config.slotMinutes >= 1440;
    final ribbon =
        !agenda && config.option<String>('style', 'slots') == 'ribbon';
    Widget body;
    if (agenda) {
      body = _agenda(
        context,
        lists.timed,
        lists.allDay,
        config,
        f,
        colors,
        now,
      );
    } else if (ribbon) {
      body = DayRibbon(
        day: widget.day,
        slice: slice,
        colors: colors,
        format: f,
        now: now,
        dimPast: config.dimPast,
        onOpen: (i) => ref.read(plannerNavProvider).openTask(context, i),
        onToggle: (i) => unawaited(PlannerCommands(context, ref).toggleDone(i)),
        onMenu: (i) => unawaited(PlannerCommands(context, ref).showTileMenu(i)),
        onCreate: (start, minutes) => unawaited(
          PlannerCommands(
            context,
            ref,
          ).quickCreate(start: start, duration: minutes),
        ),
      );
    } else {
      body = _slots(context, slice, config, f, colors, now, work);
    }
    _initialScroll(config, today, now);
    return Column(
      children: [
        if (!agenda) _allDaySection(context, lists.allDay, f, colors),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: body),
              // Drop target for "make all-day" when the section is empty (doesn't shift the list).
              if (_drag?.item != null &&
                  !_drag!.fromAllDay &&
                  lists.allDay.isEmpty)
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  height: _allDayDropExtent,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const Key('all-day-drop'),
                      decoration: BoxDecoration(
                        color:
                            (_drag!.toAllDay
                                    ? context.colors.primaryContainer
                                    : context.colors.surfaceContainerHighest)
                                .withValues(alpha: 0.92),
                        border: Border(
                          bottom: BorderSide(color: context.colors.primary),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          l.pvAllDaySection,
                          style: context.text.labelLarge,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!agenda && !ribbon && widget.day == today)
                PositionedDirectional(
                  bottom: Space.lg,
                  start: 0,
                  end: 0,
                  child: Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _showNowButton,
                      builder: (context, show, _) => AnimatedOpacity(
                        opacity: show ? 1 : 0,
                        duration: Motion.fast,
                        child: IgnorePointer(
                          ignoring: !show,
                          child: ActionChip(
                            key: const Key('now-button'),
                            avatar: const Icon(Icons.schedule, size: 18),
                            label: Text(l.pvNow),
                            onPressed: () {
                              final t = _nowT.value;
                              if (t != null)
                                _scrollToT(t, anchorFraction: 1 / 3);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _allDaySection(
    BuildContext context,
    List<PlannerItem> items,
    AppFormat f,
    ItemColorResolver colors,
  ) {
    final l = context.l10n;
    final dropping = _drag?.item != null && _drag!.toAllDay;
    if (items.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dropping
            ? context.colors.primaryContainer.withValues(alpha: 0.5)
            : null,
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: const Key('all-day-header'),
            onTap: () => setState(() => _allDayOpen = !_allDayOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l.pvAllDaySection} · ${f.number(items.length)}',
                      style: context.text.labelLarge,
                    ),
                  ),
                  Icon(_allDayOpen ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_allDayOpen)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.25,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                children: [
                  for (final i in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: SizedBox(
                        height: 40,
                        child: _EntryChip(
                          item: i,
                          colors: colors.of(i),
                          subtitle: i.isQuotaSlot ? l.pvUntimed : l.pvAllDay,
                          semanticsLabel:
                              '${i.title}, ${l.pvAllDay}, ${context.statusLabel(i.status)}',
                          past: false,
                          dimPast: false,
                          dragging: _drag?.item?.key == i.key,
                          onDragStart: (g) =>
                              _startMove(i, -1, g, fromAllDay: true),
                          onDragUpdate: _updateDrag,
                          onDragEnd: () => unawaited(_endDrag()),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _agenda(
    BuildContext context,
    List<DayEntry> timed,
    List<PlannerItem> allDay,
    PlannerViewConfig config,
    AppFormat f,
    ItemColorResolver colors,
    LocalDateTime now,
  ) {
    final l = context.l10n;
    final entries = [
      for (final i in allDay) (i, l.pvAllDay),
      for (final e in timed)
        (
          e.item,
          e.continues
              ? '${l.pvContinues} · ${f.timeOf(e.item.endLocal)}'
              : f.timeRange(e.item.startLocal, e.item.endLocal),
        ),
    ];
    if (entries.isEmpty) {
      return EmptyState(
        icon: Icons.event_available_outlined,
        title: l.pvEmptyDay,
        message: l.pvHintLongPress,
      );
    }
    return ListView.separated(
      key: const Key('day-agenda'),
      padding: const EdgeInsets.all(Space.md),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: Space.xs),
      itemBuilder: (context, i) {
        final (item, time) = entries[i];
        return SizedBox(
          height: 52,
          child: _EntryChip(
            item: item,
            colors: colors.of(item),
            subtitle: time,
            semanticsLabel:
                '${item.title}, $time, ${context.statusLabel(item.status)}',
            past: item.endLocal.isBefore(now),
            dimPast: config.dimPast,
          ),
        );
      },
    );
  }

  Widget _slots(
    BuildContext context,
    DaySlice slice,
    PlannerViewConfig config,
    AppFormat f,
    ItemColorResolver colors,
    LocalDateTime now,
    WorkSettings work,
  ) {
    final rows = buildDayRows(
      slice: slice,
      slotMinutes: config.slotMinutes,
      window: config.dayWindow,
    );
    final collapsed = config.hideEmptySlots;
    _display = collapsed
        ? collapseRows(rows, expanded: _expandedRuns)
        : [for (var i = 0; i < rows.length; i++) SlotListRow(rows[i], i)];
    final extent = config.slotExtentPx.clamp(32.0, 160.0);
    const freeExtent = 44.0;
    final hiddenExtent = math.min(extent, 28.0);
    final tops = <double>[];
    final extents = <double>[];
    var y = 0.0;
    for (final r in _display) {
      final e = switch (r) {
        FreeListRow() => freeExtent,
        SlotListRow(:final row) =>
          row.kind == AxisBandKind.normal ? extent : hiddenExtent,
      };
      tops.add(y);
      extents.add(e);
      y += e;
    }
    _tops = tops;
    _extents = extents;
    final lanes = rows.fold<int>(
      0,
      (m, r) => r.bars.fold(m, (mm, b) => math.max(mm, b.lane + 1)),
    );
    final repeatedDay = slice.timeline.repeatedRanges.isNotEmpty;
    final list = RawScrollbar(
      controller: _scroll,
      child: CustomScrollView(
        key: _listKey,
        controller: _scroll,
        slivers: [
          SliverVariedExtentList.builder(
            itemCount: _display.length,
            itemExtentBuilder: (i, _) =>
                i < extents.length ? extents[i] : extent,
            itemBuilder: (context, i) {
              final r = _display[i];
              return switch (r) {
                FreeListRow() => _FreeRunTile(
                  key: ValueKey('free-${r.fromIndex}'),
                  run: r,
                  format: f,
                  onTap: () => unawaited(_freeRunMenu(r, work)),
                ),
                SlotListRow(:final row) => _slotRow(
                  context,
                  i,
                  row,
                  config,
                  f,
                  colors,
                  now,
                  lanes,
                  repeatedDay ? slice : null,
                ),
              };
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
    if (config.slotMinutes >= 60) return list;
    // Sticky hour header: sub-hour rows only label their minutes, so the current hour stays pinned.
    return Stack(
      children: [
        Positioned.fill(child: list),
        PositionedDirectional(
          top: 0,
          start: 0,
          child: IgnorePointer(
            child: ValueListenableBuilder<(int, int)?>(
              valueListenable: _stickyHour,
              builder: (context, hour, _) {
                if (hour == null) return const SizedBox.shrink();
                var label = f.time(
                  LocalTime.fromMinuteOfDay(hour.$1.clamp(0, 1439)),
                );
                if (hour.$2 == 1 && repeatedDay) {
                  label = context.l10n.pvRepeatedHour(
                    label,
                    slice.timeline.offsetLabelAt(hour.$1, repeat: 1),
                  );
                }
                return DecoratedBox(
                  key: const Key('sticky-hour'),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    border: Border(
                      bottom: BorderSide(color: context.colors.outlineVariant),
                    ),
                    borderRadius: const BorderRadiusDirectional.only(
                      bottomEnd: Radius.circular(Radii.sm),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      Space.sm,
                      2,
                      Space.sm,
                      2,
                    ),
                    child: Text(
                      label,
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _slotRow(
    BuildContext context,
    int index,
    SlotRow row,
    PlannerViewConfig config,
    AppFormat f,
    ItemColorResolver colors,
    LocalDateTime now,
    int lanes,
    DaySlice? dstSlice,
  ) {
    final l = context.l10n;
    final day = widget.day;
    final hourStart = row.wallStart % 60 == 0 || config.slotMinutes >= 60;
    String label;
    if (row.kind == AxisBandKind.hidden) {
      label = l.pvHiddenRange(
        f.time(LocalTime.fromMinuteOfDay(row.wallStart)),
        f.time(LocalTime.fromMinuteOfDay(row.wallEnd)),
      );
    } else if (row.kind == AxisBandKind.gap) {
      label = l.pvClocksForward;
    } else if (hourStart) {
      label = f.time(LocalTime.fromMinuteOfDay(row.wallStart));
      if (row.repeat == 1 && dstSlice != null)
        label = l.pvRepeatedHour(
          label,
          dstSlice.timeline.offsetLabelAt(row.wallStart, repeat: 1),
        );
    } else {
      label = ':${(row.wallStart % 60).toString().padLeft(2, '0')}';
    }
    final entries = row.entries;
    final extent = config.slotExtentPx.clamp(32.0, 160.0);
    return _SlotRowTile(
      key: ValueKey('slot-$index-${row.tStart}'),
      index: index,
      row: row,
      label: label,
      strongLabel: hourStart,
      lanes: lanes,
      nowT: _nowT,
      highlight: _highlight,
      colors: colors,
      emptySemantics: l.pvEmptySlotSemantics(
        f.dayShort(day),
        f.time(LocalTime.fromMinuteOfDay(row.wallStart.clamp(0, 1440))),
      ),
      onTapEmpty: row.kind == AxisBandKind.normal
          ? () => unawaited(
              PlannerCommands(context, ref).quickCreate(
                start: day.atStartOfDay.plusMinutes(row.wallStart),
                duration: quickCreateDuration(
                  config.slotMinutes,
                  ref.read(plannerWorkSettingsProvider),
                ),
              ),
            )
          : () => unawaited(_expandHidden(config)),
      onLongPressEmpty: row.kind == AxisBandKind.normal
          ? (g) => _startCreate(index, g)
          : null,
      onDragUpdate: _updateDrag,
      onDragEnd: () => unawaited(_endDrag()),
      chips: [
        for (final e in entries)
          _EntryChip(
            key: ValueKey(e.item.key),
            item: e.item,
            colors: colors.of(e.item),
            subtitle: e.continues
                ? '${l.pvContinues} · ${f.timeOf(e.item.endLocal)}'
                : f.timeRange(e.item.startLocal, e.item.endLocal),
            semanticsLabel: l.pvTileSemantics(
              e.item.title,
              f.dayLong(day),
              f.timeOf(e.item.startLocal),
              f.timeOf(e.item.endLocal),
              context.statusLabel(e.item.status),
            ),
            past: e.item.endLocal.isBefore(now),
            dimPast: config.dimPast,
            compact: extent < 44,
            dragging: _drag?.item?.key == e.item.key,
            onDragStart: (g) => _startMove(e.item, index, g),
            onDragUpdate: _updateDrag,
            onDragEnd: () => unawaited(_endDrag()),
          ),
      ],
    );
  }

  Future<void> _expandHidden(PlannerViewConfig config) async {
    ref
        .read(plannerViewConfigProvider(widget.viewKey).notifier)
        .change((c) => c.copyWith(dayWindow: DayWindow.full));
  }

  Future<void> _freeRunMenu(FreeListRow run, WorkSettings work) async {
    final l = context.l10n;
    final day = widget.day;
    final start = day.atStartOfDay.plusMinutes(run.wallStart);
    final minutes = math.max(1, run.wallEnd - run.wallStart);
    final action = await showAppSheet<Object>(
      context,
      builder: (ctx) => _FreeRunSheet(start: start, minutes: minutes),
    );
    if (!mounted) return;
    final commands = PlannerCommands(context, ref);
    switch (action) {
      case 'create':
        await commands.quickCreate(
          start: start,
          duration: math.min(minutes, work.defaultDuration),
        );
      case 'expand':
        setState(() => _expandedRuns.add(run.fromIndex));
      case final PlannerItem backlog:
        final duration = math.min(
          minutes,
          backlog.estimateMinutes ?? backlog.durationMinutes,
        );
        await commands.run(
          l.pvScheduledSnack,
          (a) => a.scheduleBacklogItem(backlog, start, duration),
        );
    }
  }
}

/// Sheet of a free run: *Create here*, *Fill from backlog* (items whose estimate fits), *Expand*.
class _FreeRunSheet extends ConsumerWidget {
  const _FreeRunSheet({required this.start, required this.minutes});

  final LocalDateTime start;
  final int minutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.plannerFormat(
      use24h: ref.watch(userPreferencesProvider).use24h,
    );
    final backlog =
        ref.watch(viewBacklogProvider).value ?? const <PlannerItem>[];
    final fitting = [
      for (final b in backlog)
        if ((b.estimateMinutes ?? b.durationMinutes) <= minutes) b,
    ];
    return ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            Space.xl,
            0,
            Space.xl,
            Space.sm,
          ),
          child: Text(
            l.pvFreeRun(
              f.timeOf(start),
              f.timeOf(start.plusMinutes(minutes)),
              f.duration(minutes),
            ),
            style: context.text.titleMedium,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(l.pvCreateHere),
          onTap: () => Navigator.pop(context, 'create'),
        ),
        ListTile(
          leading: const Icon(Icons.unfold_more),
          title: Text(l.pvExpand),
          onTap: () => Navigator.pop(context, 'expand'),
        ),
        if (fitting.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              Space.xl,
              Space.md,
              Space.xl,
              Space.xs,
            ),
            child: Text(
              l.pvFillFromBacklog,
              style: context.text.labelLarge?.copyWith(
                color: context.colors.primary,
              ),
            ),
          ),
          for (final b in fitting)
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: Text(b.title),
              subtitle: Text(
                f.duration(b.estimateMinutes ?? b.durationMinutes),
              ),
              onTap: () => Navigator.pop(context, b),
            ),
        ],
        const SizedBox(height: Space.md),
      ],
    );
  }
}

/// "Free 10:00–11:20 · 1 h 20" (T3.5.08).
class _FreeRunTile extends StatelessWidget {
  const _FreeRunTile({
    required this.run,
    required this.format,
    required this.onTap,
    super.key,
  });

  final FreeListRow run;
  final AppFormat format;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final minutes = run.wallEnd - run.wallStart;
    final text = l.pvFreeRun(
      format.time(LocalTime.fromMinuteOfDay(run.wallStart.clamp(0, 1440))),
      format.time(LocalTime.fromMinuteOfDay(run.wallEnd.clamp(0, 1440))),
      format.duration(math.max(0, minutes)),
    );
    return Semantics(
      button: true,
      label: text,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Row(
              children: [
                Icon(Icons.more_vert, size: 16, color: context.colors.outline),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
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

/// One slot row: time label, duration bars, item chips; empty space creates.
class _SlotRowTile extends StatelessWidget {
  const _SlotRowTile({
    required this.index,
    required this.row,
    required this.label,
    required this.strongLabel,
    required this.lanes,
    required this.nowT,
    required this.highlight,
    required this.colors,
    required this.chips,
    required this.emptySemantics,
    required this.onTapEmpty,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.onLongPressEmpty,
    super.key,
  });

  final int index;
  final SlotRow row;
  final String label;
  final bool strongLabel;
  final int lanes;
  final ValueListenable<int?> nowT;
  final ValueListenable<(int, int)?> highlight;
  final ItemColorResolver colors;
  final List<Widget> chips;
  final String emptySemantics;
  final VoidCallback onTapEmpty;
  final ValueChanged<Offset>? onLongPressEmpty;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  static const _maxChips = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shown = chips
        .take(chips.length > _maxChips ? _maxChips - 1 : _maxChips)
        .toList();
    final more = chips.length - shown.length;
    final barsWidth = lanes == 0 ? 6.0 : 6.0 + lanes * 5;
    final textScale = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.6);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScale),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: row.kind == AxisBandKind.normal
              ? null
              : c.surfaceContainerHighest.withValues(alpha: 0.6),
          border: Border(
            top: BorderSide(
              color: strongLabel
                  ? c.outlineVariant
                  : c.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: ValueListenableBuilder<int?>(
          valueListenable: nowT,
          builder: (context, now, child) {
            final isNow = now != null && row.containsT(now);
            return Stack(
              children: [
                if (isNow)
                  Positioned.fill(
                    child: ColoredBox(
                      color: context.appColors.nowLine.withValues(alpha: 0.06),
                    ),
                  ),
                child!,
                ValueListenableBuilder<(int, int)?>(
                  valueListenable: highlight,
                  builder: (context, h, _) =>
                      h != null && index >= h.$1 && index <= h.$2
                      ? Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(
                              color: c.primary.withValues(alpha: 0.14),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (isNow)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final frac = row.minutes <= 0
                              ? 0.0
                              : (now - row.tStart) / row.minutes;
                          return Align(
                            alignment: AlignmentDirectional(
                              -1,
                              -1 + 2 * frac.clamp(0.0, 1.0),
                            ),
                            child: SizedBox(
                              key: const Key('now-divider'),
                              height: 2,
                              width: constraints.maxWidth,
                              child: ColoredBox(
                                color: context.appColors.nowLine,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
          child: Semantics(
            label: chips.isEmpty ? emptySemantics : null,
            button: chips.isEmpty,
            onTap: chips.isEmpty ? onTapEmpty : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapEmpty,
              onLongPressStart: onLongPressEmpty == null
                  ? null
                  : (d) => onLongPressEmpty!(d.globalPosition),
              onLongPressMoveUpdate: onLongPressEmpty == null
                  ? null
                  : (d) => onDragUpdate(d.globalPosition),
              onLongPressEnd: onLongPressEmpty == null
                  ? null
                  : (_) => onDragEnd(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 64,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: Space.sm,
                        top: 2,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: context.text.labelSmall?.copyWith(
                          color: strongLabel ? c.onSurface : c.onSurfaceVariant,
                          fontWeight: strongLabel ? FontWeight.w600 : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: barsWidth,
                    child: CustomPaint(
                      painter: _BarsPainter(
                        row.bars,
                        colors,
                        Directionality.of(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        0,
                        3,
                        Space.sm,
                        3,
                      ),
                      child: Row(
                        children: [
                          for (final chip in shown)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 3,
                                ),
                                child: chip,
                              ),
                            ),
                          if (more > 0)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 2,
                              ),
                              child: Text(
                                context.l10n.pvMore('$more'),
                                style: context.text.labelMedium?.copyWith(
                                  color: c.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Duration bars of one row (the segments line up across rows).
class _BarsPainter extends CustomPainter {
  _BarsPainter(this.bars, this.colors, this.direction);

  final List<RowBar> bars;
  final ItemColorResolver colors;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bars) {
      final x = direction == TextDirection.rtl
          ? size.width - 4 - b.lane * 5
          : 2 + b.lane * 5.0;
      final top = b.starts ? 4.0 : 0.0;
      final bottom = b.ends ? size.height - 4 : size.height;
      final paint = Paint()
        ..color = colors.of(b.item).accent
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x + 1.5, top),
        Offset(x + 1.5, math.max(top, bottom)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.bars != bars || old.direction != direction;
}

/// An item chip of the day list (T3.5.06): check → done, swipe right = done / left = skip, tap →
/// open, long-press → quick menu, long-press + drag → reschedule.
class _EntryChip extends ConsumerWidget {
  const _EntryChip({
    required this.item,
    required this.colors,
    required this.subtitle,
    required this.semanticsLabel,
    required this.past,
    required this.dimPast,
    this.compact = false,
    this.dragging = false,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    super.key,
  });

  final PlannerItem item;
  final TileColors colors;
  final String subtitle;
  final String semanticsLabel;
  final bool past;
  final bool dimPast;
  final bool compact;
  final bool dragging;
  final ValueChanged<Offset>? onDragStart;
  final ValueChanged<Offset>? onDragUpdate;
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final done = item.isDone;
    final struck = done || item.status == OccurrenceStatus.cancelled;
    final faded =
        done ||
        item.status == OccurrenceStatus.skipped ||
        item.status == OccurrenceStatus.cancelled;
    final missed = item.status == OccurrenceStatus.missed;
    final check = item.trackingMode == TrackingMode.check;
    final commands = PlannerCommands(context, ref);
    final fg = colors.foreground;
    Widget chip = Opacity(
      opacity: dragging ? 0.35 : (faded ? 0.55 : (past && dimPast ? 0.75 : 1)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: BorderDirectional(
            start: BorderSide(
              color: missed ? context.appColors.missed : colors.accent,
              width: missed ? 4 : 3,
            ),
          ),
        ),
        child: Row(
          children: [
            if (check)
              Semantics(
                checked: done,
                label: done ? l.pvMarkNotDone : l.pvMarkDone,
                child: InkResponse(
                  key: Key('check-${item.key}'),
                  radius: 20,
                  onTap: () => unawaited(commands.toggleDone(item)),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4, end: 2),
                    child: Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: compact ? 18 : 20,
                      color: fg,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 2, end: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        decoration: struck ? TextDecoration.lineThrough : null,
                        decorationColor: fg,
                        height: 1.1,
                      ),
                    ),
                    if (!compact)
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelSmall?.copyWith(
                                color: fg.withValues(alpha: 0.85),
                                height: 1.1,
                              ),
                            ),
                          ),
                          if (item.isRecurring)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 3,
                              ),
                              child: Icon(Icons.repeat, size: 12, color: fg),
                            ),
                          if (item.timeZone != null)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 3,
                              ),
                              child: Icon(Icons.public, size: 12, color: fg),
                            ),
                          if (item.linkedChecklistId != null)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 3,
                              ),
                              child: Icon(Icons.checklist, size: 12, color: fg),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    chip = Semantics(
      container: true,
      button: true,
      label: semanticsLabel,
      onTap: () => ref.read(plannerNavProvider).openTask(context, item),
      onLongPress: () => unawaited(commands.showTileMenu(item)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(plannerNavProvider).openTask(context, item),
        onLongPressStart: onDragStart == null
            ? null
            : (d) => onDragStart!(d.globalPosition),
        onLongPressMoveUpdate: onDragUpdate == null
            ? null
            : (d) => onDragUpdate!(d.globalPosition),
        onLongPressEnd: onDragEnd == null ? null : (_) => onDragEnd!(),
        onLongPress: onDragStart == null
            ? () => unawaited(commands.showTileMenu(item))
            : null,
        child: chip,
      ),
    );
    if (!item.isOpen && !done) return chip;
    return Dismissible(
      key: ValueKey('swipe-${item.key}'),
      direction: item.isOpen
          ? DismissDirection.horizontal
          : DismissDirection.startToEnd,
      background: _SwipeBackground(
        icon: done ? Icons.remove_done : Icons.check,
        color: context.appColors.completed,
        start: true,
      ),
      secondaryBackground: _SwipeBackground(
        icon: Icons.skip_next,
        color: context.appColors.skipped,
        start: false,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await commands.toggleDone(item);
        } else {
          await commands.setStatus(item, OccurrenceStatus.skipped);
        }
        return false;
      },
      child: chip,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.icon,
    required this.color,
    required this.start,
  });

  final IconData icon;
  final Color color;
  final bool start;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(Radii.sm),
    ),
    child: Align(
      alignment: start
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        child: Icon(icon, color: color),
      ),
    ),
  );
}
