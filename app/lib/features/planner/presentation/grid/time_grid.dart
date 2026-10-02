import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/integrations/application/device_calendar_providers.dart';
import 'package:everslot/features/integrations/domain/device_calendar.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/planner/presentation/grid/day_header.dart';
import 'package:everslot/features/planner/presentation/grid/engine/bucketing.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot/features/planner/presentation/grid/engine/drag_math.dart';
import 'package:everslot/features/planner/presentation/grid/engine/free_slots.dart';
import 'package:everslot/features/planner/presentation/grid/engine/occupancy.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:everslot/features/planner/presentation/grid/engine/paging.dart';
import 'package:everslot/features/planner/presentation/grid/engine/snapping.dart';
import 'package:everslot/features/planner/presentation/grid/engine/time_scale.dart';
import 'package:everslot/features/planner/presentation/grid/engine/zoom.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_controller.dart';
import 'package:everslot/features/planner/presentation/grid/grid_painter.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/grid/overlays.dart';
import 'package:everslot/features/planner/presentation/grid/page_physics.dart';
import 'package:everslot/features/planner/presentation/grid/table_page.dart';
import 'package:everslot/features/planner/presentation/grid/task_tile.dart';
import 'package:everslot/features/planner/presentation/grid/time_ruler.dart';
import 'package:everslot/features/planner/presentation/grid/timeline_page.dart';
import 'package:everslot/features/planner/presentation/grid/vertical_scroll_proxy.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/planner_selection.dart';
import 'package:everslot/features/stats/application/planner_overlays.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Which renderer draws the grid body (T3.4.06).
enum GridRenderer { timeline, table, weekList }

GridRenderer rendererFor(PlannerViewConfig c) =>
    c.isWeekListMode ? GridRenderer.weekList : (c.usesTable ? GridRenderer.table : GridRenderer.timeline);

/// Week start of a view: a fixed `firstDay` code (MO…SU) overrides the profile's week start.
Weekday weekStartFor(PlannerViewConfig c, Weekday profileWeekStart) {
  final code = c.firstDay;
  if (code.length == 2) {
    try {
      return Weekday.fromCode(code);
    } on FormatException {
      return profileWeekStart;
    }
  }
  return profileWeekStart;
}

/// Weekdays shown by a view: all, all but the weekend, or the work days (work-week preset).
Set<Weekday> visibleWeekdaysFor(PlannerViewConfig c, WorkSettings work) {
  if (c.option<bool>('workWeek', false)) return {for (final iso in work.days) Weekday.fromIso(iso)};
  if (!c.showWeekends) {
    return {
      for (final w in Weekday.values)
        if (!w.isWeekend) w,
    };
  }
  return Weekday.values.toSet();
}

/// Lane cap by column width (T3.3.05 / T3.4.16): phones 2, wider columns 3, day views and tablets 4.
int laneCapFor(double columnWidth, int configured) {
  if (columnWidth >= 150) return math.max(configured, 4);
  if (columnWidth >= 90) return math.max(configured, 3);
  return configured;
}

/// Width of the hour ruler at the start of time-based grids (views align headers with it).
double timeRulerWidth(TextScaler ts, {required bool use24h}) {
  final font = ts.scale(11);
  return (use24h ? font * 3.3 : font * 4.6).clamp(40.0, 88.0) + 6;
}

/// The time-grid engine widget (T3.3.11–T3.3.21) behind the week table, N-day, work week, swimlanes
/// and plan-vs-actual views: infinite horizontal paging (week / day / free, any week start, RTL
/// mirrored) over one shared vertical scroll, a pinned ruler, day headers and the all-day lane,
/// three renderers (proportional timeline, bucketed table, week list), create / move / resize
/// gestures with snapping, magnets, a time bubble and haptics, auto-scroll and auto-page while
/// dragging, and pinch zoom (vertical = px/min or semantic slot presets, horizontal = days).
class TimeGrid extends ConsumerStatefulWidget {
  const TimeGrid({
    required this.viewKey,
    this.controller,
    this.initialDate,
    this.configTransform,
    this.tileLayout = overlapStrategy,
    this.overlayPainters = const [],
    this.onRulerDoubleTap,
    this.showHeaderStats = true,
    this.fixedAnchor,
    this.onDropOutside,
    super.key,
  });

  /// A tile move released over another widget (the backlog drawer, T3.7.02): return true when
  /// the drop was handled there (the grid then doesn't reschedule).
  final Future<bool> Function(PlannerItem item, Offset global)? onDropOutside;

  /// Registry entry id or `saved:<id>`: keys the view config and the local view state.
  final String viewKey;
  final PlannerGridController? controller;

  /// Date to show first (deep link); later changes jump to it.
  final LocalDate? initialDate;

  /// Adjusts the effective config (presets such as the work week).
  final PlannerViewConfig Function(PlannerViewConfig config)? configTransform;

  /// Column layout strategy (swimlanes swap it).
  final TileLayoutStrategy tileLayout;

  /// Overlay layers painted under the tiles (T3.3.23).
  final List<OverlayPainterBuilder> overlayPainters;
  final VoidCallback? onRulerDoubleTap;

  /// Per-day done/total, planned time and load tint in the headers (T3.4.11).
  final bool showHeaderStats;

  /// Rolling views anchored to a date regardless of stored state (N-day "today").
  final LocalDate? fixedAnchor;

  @override
  ConsumerState<TimeGrid> createState() => TimeGridState();
}

enum _Region { header, lane, body }

@immutable
class _Hit {
  const _Hit({
    required this.page,
    required this.days,
    required this.column,
    required this.region,
    required this.point,
    required this.local,
  });

  final int page;
  final List<LocalDate> days;
  final int column;
  final _Region region;

  /// Page coordinates: physical x inside the page; y is content y (body) or y inside the lane.
  final Offset point;

  /// Position in the pages area.
  final Offset local;

  LocalDate get day => days[column];
}

enum _SessionKind { create, move, resizeStart, resizeEnd }

/// An in-progress drag (T3.3.15–T3.3.20). Minutes are wall-clock minutes relative to [refDay].
class _Session {
  _Session({
    required this.kind,
    required this.refDay,
    required this.range,
    required this.pointer,
    this.item,
    this.grabOffset = 0,
    this.toLane = false,
    this.fromLane = false,
    this.listMode = false,
    this.insertIndex,
  }) : initialDay = refDay,
       initialRange = range,
       initialLane = toLane,
       startPointer = pointer;

  final _SessionKind kind;
  final PlannerItem? item;
  final int grabOffset;
  final bool fromLane;
  final bool listMode;
  final LocalDate initialDay;
  final DragRange initialRange;
  final bool initialLane;
  final Offset startPointer;

  /// Day the range is relative to (target day for moves, origin day for create/resize).
  LocalDate refDay;
  DragRange range;
  bool toLane;
  Offset pointer;
  int? insertIndex;
  bool moved = false;

  bool get changed => refDay != initialDay || range != initialRange || toLane != initialLane;
}

/// Snapshot rendered by the drag overlay (the grid itself doesn't rebuild per pointer move).
@immutable
class _SessionView {
  const _SessionView(this.session, this.label);

  final _Session session;
  final String label;
}

@immutable
class _Metrics {
  const _Metrics({
    required this.width,
    required this.height,
    required this.rulerWidth,
    required this.pagesWidth,
    required this.pageWidth,
    required this.headerHeight,
    required this.laneHeight,
    required this.laneRowExtent,
    required this.rtl,
  });

  final double width;
  final double height;
  final double rulerWidth;
  final double pagesWidth;
  final double pageWidth;
  final double headerHeight;
  final double laneHeight;
  final double laneRowExtent;
  final bool rtl;

  double get bodyTop => headerHeight + laneHeight;
  double get bodyHeight => math.max(0, height - bodyTop);
}

/// Everything a page needs from the grid's last build.
class _Frame {
  _Frame({
    required this.config,
    required this.renderer,
    required this.today,
    required this.nowLocal,
    required this.zone,
    required this.cache,
    required this.work,
    required this.style,
    required this.format,
    required this.colors,
    required this.l10n,
    required this.metrics,
    required this.axis,
    required this.ppm,
    required this.rows,
    required this.weekStart,
    required this.filter,
  });

  final PlannerViewConfig config;
  final GridRenderer renderer;
  final LocalDate today;
  final LocalDateTime nowLocal;
  final String zone;
  final DayTimelineCache cache;
  final WorkSettings work;
  final GridStyle style;
  final AppFormat format;
  final ItemColorResolver colors;
  final AppLocalizations l10n;
  final _Metrics metrics;
  final PageAxis axis;
  final double ppm;
  final TableRowsLayout? rows;
  final Weekday weekStart;
  final ItemFilter filter;

  TimeScale get scale => TimeScale.withPpm(config.slotMinutes, ppm);
}

/// Cached per-page data used for rendering and hit testing.
class _PageData {
  _PageData(this.days, this.slices);

  final List<LocalDate> days;
  final Map<LocalDate, DaySlice> slices;
  LaneModel? lane;
  PageGeometry? timeline;
  TablePageGeometry? table;
  WeekListGeometry? weekList;
  List<Object?> timelineDeps = const [];
  List<Object?> tableDeps = const [];
  List<Object?> weekListDeps = const [];
  List<Object?> laneDeps = const [];
}

class _Pinch {
  _Pinch({
    required this.a,
    required this.b,
    required this.startPpm,
    required this.startDays,
    required this.focalY,
    required this.focalMinute,
    required this.focalRepeat,
  });

  final Offset a;
  final Offset b;
  final double startPpm;
  final int startDays;

  /// Focal point in body coordinates and the wall minute under it.
  final double focalY;
  final double focalMinute;
  final int focalRepeat;
  Axis? lock;
}

class TimeGridState extends ConsumerState<TimeGrid>
    with TickerProviderStateMixin
    implements GridNavigator, DropSlotSource {
  static const _dragOverlayKey = ValueKey('time-grid-drag-overlay');

  bool _ready = false;
  late final ViewStateController _viewState;
  late final PlannerAnchorController _sharedAnchor;
  late final PlannerScrollMinuteController _sharedMinute;
  PagingModel? _paging;
  PageController? _pages;
  final ScrollController _vertical = ScrollController();
  int _page = PagingModel.baseIndex;
  LocalDate? _initialAnchor;
  (double, double)? _pendingScroll;
  double? _ppm;
  double? _lastConfigPpm;
  int? _daysPortrait;
  int? _daysLandscape;
  bool _landscape = false;
  final Set<int> _expandedHidden = {};
  bool _laneExpanded = false;
  String? _selectedKey;

  /// Multi-selection of the view (T3.1.18), mirrored from [plannerSelectionProvider].
  Map<String, PlannerItem> _selection = const {};

  /// Slot under the mouse or last tapped empty slot: the Ctrl/Cmd + V target (T3.1.19).
  LocalDateTime? _cursor;

  /// Keyboard focus of the grid (T3.3.24): arrows, Enter, Space, Shift+arrows, +/-, Ctrl/Cmd+C/V.
  final FocusNode _focus = FocusNode(debugLabel: 'planner-grid');
  _Session? _session;
  final ValueNotifier<_SessionView?> _sessionView = ValueNotifier(null);

  /// Series mini-stats preview while a recurring tile is held (T6.3.20); hidden once it moves.
  final ValueNotifier<({String seriesId, Offset at})?> _preview = ValueNotifier(null);
  bool _freeSnap = false;
  late final ValueNotifier<DateTime> _now;
  Timer? _minuteTimer;
  final Map<int, Offset> _pointers = {};
  _Pinch? _pinch;
  bool _pinchedSinceDown = false;
  String? _toast;
  Timer? _toastTimer;
  Ticker? _edgeTicker;
  Duration _lastTick = Duration.zero;
  int _edgeDir = 0;
  Duration _edgeSince = Duration.zero;
  bool _autoPaging = false;
  int? _lastSnapMinute;
  final ColumnLayoutCache _layouts = ColumnLayoutCache();
  final LabelCache _labels = LabelCache();
  final Map<int, _PageData> _pageData = {};
  final GlobalKey _pagesKey = GlobalKey();
  _Frame? _frame;
  PlannerCommands get _commands => PlannerCommands(context, ref);

  // ------------------------------------------------------------------------------ lifecycle --

  @override
  void initState() {
    super.initState();
    _viewState = ref.read(plannerViewStateProvider(widget.viewKey).notifier);
    _sharedAnchor = ref.read(plannerAnchorProvider.notifier);
    _sharedMinute = ref.read(plannerScrollMinuteProvider.notifier);
    _now = ValueNotifier(ref.read(clockProvider).nowUtc());
    widget.controller?.attach(this);
    if (!_viewState.isLoaded) {
      unawaited(
        _viewState.ready.then((_) {
          if (mounted) setState(() {});
        }),
      );
    }
    _scheduleMinuteTick();
  }

  @override
  void didUpdateWidget(TimeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }
    final date = widget.initialDate;
    if (date != null && date != oldWidget.initialDate && _ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(jumpToDate(date));
      });
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(this);
    _minuteTimer?.cancel();
    _toastTimer?.cancel();
    _edgeTicker?.dispose();
    _sessionView.dispose();
    _preview.dispose();
    _now.dispose();
    _vertical.dispose();
    _pages?.dispose();
    _focus.dispose();
    unawaited(_viewState.flush());
    super.dispose();
  }

  void _scheduleMinuteTick() {
    final now = ref.read(clockProvider).nowUtc();
    _minuteTimer = Timer(Duration(seconds: 60 - now.second, milliseconds: -now.millisecond), () {
      if (!mounted) return;
      if (TickerMode.valuesOf(context).enabled) {
        _now.value = ref.read(clockProvider).nowUtc();
        ref.read(plannerMinuteTickProvider.notifier).tick();
      }
      _scheduleMinuteTick();
    });
  }

  void _init(PlannerViewConfig config) {
    final vs = ref.read(plannerViewStateProvider(widget.viewKey));
    final today = ref.read(plannerTodayProvider);
    _initialAnchor = widget.fixedAnchor ?? widget.initialDate ?? ref.read(plannerAnchorProvider) ?? vs?.anchor ?? today;
    _ppm = vs?.pxPerMinute;
    _daysPortrait = vs?.daysPortrait;
    _daysLandscape = vs?.daysLandscape;
    final shared = ref.read(plannerScrollMinuteProvider);
    if (shared != null) {
      _pendingScroll = (shared, 0);
    } else if (vs?.scrollMinute != null) {
      _pendingScroll = (vs!.scrollMinute!, 0);
    } else {
      _pendingScroll = null; // decided after the first layout (now in the upper third)
    }
    _ready = true;
  }

  // -------------------------------------------------------------------------------- paging --

  void _ensurePaging({
    required PagingMode mode,
    required Weekday weekStart,
    required int days,
    required Set<Weekday> weekdays,
    required PlannerViewConfig config,
  }) {
    final current = _paging;
    if (current != null &&
        current.mode == mode &&
        current.weekStart == weekStart &&
        current.daysVisible == days &&
        setEquals(current.visibleWeekdays, weekdays)) {
      return;
    }
    final today = ref.read(plannerTodayProvider);
    var anchor = current == null ? (_initialAnchor ?? today) : current.daysOnScreen(_page).first;
    final weekPaging = mode == PagingMode.week && days >= (weekdays.isEmpty ? 7 : weekdays.length);
    if (current == null &&
        !weekPaging &&
        config.firstDay != 'today' &&
        widget.fixedAnchor == null &&
        widget.initialDate == null) {
      anchor = anchor.startOfWeek(weekStart);
    }
    final old = _pages;
    _paging = PagingModel(
      mode: mode,
      anchor: anchor,
      weekStart: weekStart,
      daysVisible: days,
      visibleWeekdays: weekdays,
    );
    _page = PagingModel.baseIndex;
    _pageData.clear();
    _pages = PageController(initialPage: PagingModel.baseIndex, viewportFraction: _paging!.viewportFraction);
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  List<LocalDate> get visibleDays => _paging?.daysOnScreen(_page) ?? const [];

  void _onPageChanged(int index) {
    if (index == _page) return;
    setState(() => _page = index);
    _afterPageChange();
  }

  void _afterPageChange() {
    final days = visibleDays;
    if (days.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller?.updateVisibleDays(days);
    });
    _sharedAnchor.set(days.first);
    if (widget.fixedAnchor == null) _viewState.update((s) => s.copyWith(anchor: days.first));
    _pageData.removeWhere((k, _) => (k - _page).abs() > 16);
  }

  bool _onPagesNotification(ScrollNotification n) {
    if (n.depth != 0 || n is! ScrollEndNotification) return false;
    final page = _pages?.page?.round();
    if (page != null && page != _page) _onPageChanged(page);
    return false;
  }

  bool _onVerticalNotification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n is! ScrollEndNotification) return false;
    final f = _frame;
    if (f == null || !_vertical.hasClients) return false;
    final minute = _minuteAtContent(_vertical.offset);
    _sharedMinute.set(minute);
    _viewState.update((s) => s.copyWith(scrollMinute: minute));
    return false;
  }

  // --------------------------------------------------------------------- GridNavigator API --

  @override
  Future<void> jumpToDate(LocalDate date, {bool animate = true, double? minute, double anchorFraction = 0}) async {
    final paging = _paging;
    final pages = _pages;
    if (paging == null || pages == null || !pages.hasClients) return;
    final target = paging.pageOf(date);
    if (animate && (target - _page).abs() <= 4 && !MediaQuery.of(context).disableAnimations) {
      await pages.animateToPage(target, duration: Motion.slow, curve: Motion.curve);
    } else {
      pages.jumpToPage(target);
    }
    if (target != _page) _onPageChanged(target);
    if (minute != null) scrollToMinute(minute, animate: animate, anchorFraction: anchorFraction);
  }

  @override
  Future<void> step(int pages) async {
    final paging = _paging;
    final controller = _pages;
    if (paging == null || controller == null || !controller.hasClients) return;
    final delta = paging.isWeekPaging ? pages : pages * paging.daysVisible;
    final target = _page + delta;
    if (MediaQuery.of(context).disableAnimations) {
      controller.jumpToPage(target);
    } else {
      await controller.animateToPage(target, duration: Motion.normal, curve: Motion.curve);
    }
    if (target != _page) _onPageChanged(target);
  }

  @override
  void scrollToMinute(double minute, {bool animate = true, double anchorFraction = 0}) {
    final f = _frame;
    if (f == null || !_vertical.hasClients) {
      _pendingScroll = (minute, anchorFraction);
      return;
    }
    final offset = _offsetForMinute(minute, anchorFraction: anchorFraction);
    if (animate && !MediaQuery.of(context).disableAnimations) {
      unawaited(_vertical.animateTo(offset, duration: Motion.normal, curve: Motion.curve));
    } else {
      _vertical.jumpTo(offset);
    }
  }

  @override
  void zoomBy(double factor) {
    final f = _frame;
    if (f == null) return;
    final centre = _minuteAtContent(_vertical.hasClients ? _vertical.offset + f.metrics.bodyHeight / 2 : 0);
    _pendingScroll = (centre, 0.5);
    setState(() => _ppm = f.ppm * factor);
    _viewState.update((s) => s.copyWith(pxPerMinute: _ppm));
  }

  double _offsetForMinute(double minute, {double anchorFraction = 0}) {
    final f = _frame!;
    final m = f.metrics;
    final max = math.max<double>(0, _contentHeight(f) - m.bodyHeight);
    final double y;
    switch (f.renderer) {
      case GridRenderer.timeline:
        y = f.axis.yOf(minute, ppm: f.ppm);
      case GridRenderer.table:
        final rows = f.rows!;
        final r = rows.rowOfWall(minute.floor());
        final row = rows.rows[r];
        final frac = row.minutes <= 0 ? 0.0 : ((minute - row.wallStart) / row.minutes).clamp(0.0, 1.0);
        y = rows.tops[r] + frac * rows.heights[r];
      case GridRenderer.weekList:
        y = 0;
    }
    return (y - m.bodyHeight * anchorFraction).clamp(0.0, max);
  }

  double _minuteAtContent(double contentY) {
    final f = _frame;
    if (f == null) return 0;
    switch (f.renderer) {
      case GridRenderer.timeline:
        return f.axis.locate(contentY, f.ppm).wall;
      case GridRenderer.table:
        final rows = f.rows!;
        if (rows.length == 0) return 0;
        final r = rows.indexAt(contentY);
        final row = rows.rows[r];
        final frac = rows.heights[r] <= 0 ? 0.0 : ((contentY - rows.tops[r]) / rows.heights[r]).clamp(0.0, 1.0);
        return row.wallStart + frac * row.minutes;
      case GridRenderer.weekList:
        return 0;
    }
  }

  double _contentHeight(_Frame f) => switch (f.renderer) {
    GridRenderer.timeline => f.axis.height(f.ppm),
    GridRenderer.table => f.rows!.height,
    GridRenderer.weekList => math.max(f.metrics.bodyHeight, _weekListHeight(f)),
  };

  double _weekListHeight(_Frame f) {
    var max = 0.0;
    for (final d in _pageData.values) {
      final g = d.weekList;
      if (g != null) max = math.max(max, g.contentHeight);
    }
    return max;
  }

  // --------------------------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    final base = ref.watch(plannerViewConfigProvider(widget.viewKey));
    final config = widget.configTransform?.call(base) ?? base;
    if (!_ready) {
      if (!_viewState.isLoaded) return const SizedBox.expand();
      _init(config);
    }
    // Settings may clear the local days / zoom overrides.
    ref.listen<ViewState?>(plannerViewStateProvider(widget.viewKey), (prev, next) {
      if (!_ready || _pinch != null || next == null) return;
      final clearZoom = next.pxPerMinute == null && _ppm != null;
      if (next.daysPortrait != _daysPortrait || next.daysLandscape != _daysLandscape || clearZoom) {
        setState(() {
          _daysPortrait = next.daysPortrait;
          _daysLandscape = next.daysLandscape;
          if (clearZoom) _ppm = null;
        });
      }
    });
    final prefs = ref.watch(userPreferencesProvider);
    final zone = ref.watch(plannerZoneProvider);
    final today = ref.watch(plannerTodayProvider);
    final work = ref.watch(plannerWorkSettingsProvider);
    final cache = ref.watch(timelineCacheProvider);
    final lookup = ref.watch(categoryColorLookupProvider);
    _selection = ref.watch(plannerSelectionProvider(widget.viewKey));
    ref.watch(plannerDemoModeProvider);
    final media = MediaQuery.of(context);
    _landscape = media.orientation == Orientation.landscape;
    final tablet = media.size.shortestSide >= 600;
    final weekStart = weekStartFor(config, prefs.weekStart);
    final daysWanted =
        (_landscape ? (_daysLandscape ?? config.daysVisibleLandscape) : (_daysPortrait ?? config.daysVisible)).clamp(
          1,
          tablet ? 14 : 7,
        );
    _ensurePaging(
      mode: config.paging,
      weekStart: weekStart,
      days: daysWanted,
      weekdays: visibleWeekdaysFor(config, work),
      config: config,
    );
    final paging = _paging!;
    final renderer = rendererFor(config);
    final visible = paging.daysOnScreen(_page);
    // A new row height / slot from the slot-size sheet replaces the local pinch zoom.
    final configPpm = config.pxPerMinute;
    if (_lastConfigPpm != null && (_lastConfigPpm! - configPpm).abs() > 1e-9 && _pinch == null) _ppm = null;
    _lastConfigPpm = configPpm;
    // Neighbour pages share the lane height (no jump while swiping).
    final around = <LocalDate>{
      ...visible,
      ...paging.daysOnScreen(_page - (paging.isWeekPaging ? 1 : paging.daysVisible)),
      ...paging.daysOnScreen(_page + (paging.isWeekPaging ? 1 : paging.daysVisible)),
    }.toList()..sort();
    final filter = viewItemFilter(ref, config);
    final slices = _watchSlices(ref, around, filter, weekStart).$1;
    final nowLocal = ref.read(plannerNowProvider);
    final l = context.l10n;
    final format = context.plannerFormat(use24h: prefs.use24h);
    final style = GridStyle.of(context, density: config.density);
    final colors = ItemColorResolver(
      highContrast: context.a11y.highContrastCategories,
      colorBy: config.colorBy,
      brightness: Theme.of(context).brightness,
      categoryColor: lookup,
      statusColor: context.statusColor,
    );
    final timelines = [for (final d in visible) cache.of(d, zone)];
    final axis = PageAxis.build(timelines, window: config.dayWindow, expandedHidden: _expandedHidden);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ts = MediaQuery.textScalerOf(context);
          final rtl = Directionality.of(context) == TextDirection.rtl;
          final width = constraints.maxWidth.isFinite ? constraints.maxWidth : media.size.width;
          final height = constraints.maxHeight.isFinite ? constraints.maxHeight : media.size.height;
          // Whole-pixel page area (the ruler absorbs the fraction): at the ±10 000 virtual page index
          // a fractional viewport makes PageView's page ↔ pixel round trips drift past its tolerance.
          final pagesWidth = math.max<double>(
            1,
            (width -
                    (renderer == GridRenderer.weekList
                        ? 0.0
                        : _rulerWidth(ts, prefs.use24h) +
                              (renderer == GridRenderer.timeline
                                  ? config.extraTimeZones.length * zoneRulerWidth(ts)
                                  : 0)))
                .floorToDouble(),
          );
          final rulerWidth = renderer == GridRenderer.weekList ? 0.0 : width - pagesWidth;
          final pageWidth = pagesWidth * paging.viewportFraction;
          final headerHeight = _headerHeight(ts, config);
          final laneRow = style.laneRowExtent;
          var laneHeight = 0.0;
          if (renderer != GridRenderer.weekList) {
            final lane = LaneModel.compute(visible, slices, maxRows: _laneExpanded ? null : 2);
            var rows = lane.packing.rowCount;
            var hidden = lane.packing.hasHidden;
            for (final side in [-1, 1]) {
              final days = paging.daysOnScreen(_page + side * (paging.isWeekPaging ? 1 : paging.daysVisible));
              final other = LaneModel.compute(days, slices, maxRows: _laneExpanded ? null : 2);
              rows = math.max(rows, other.packing.rowCount);
              hidden = hidden || other.packing.hasHidden;
            }
            laneHeight = rows == 0 ? 0 : rows * laneRow + (hidden ? 14 : 0) + 4;
          }
          final bodyHeight = math.max<double>(0, height - headerHeight - laneHeight);
          final dayMinutes = math.max(60, axis.normalMinutes);
          final ppm = TimeScale.clampPxPerMinute(
            _ppm ?? config.pxPerMinute,
            slotMinutes: config.slotMinutes,
            viewportExtent: bodyHeight,
            dayMinutes: dayMinutes,
          );
          TableRowsLayout? rows;
          if (renderer == GridRenderer.table) {
            final axisRows = axis.slotRows(config.slotMinutes);
            final perDay = [
              for (final d in visible)
                if (slices[d] case final s?) tableBuckets(s, axisRows),
            ];
            rows = TableRowsLayout.build(
              axis: axis,
              slotMinutes: config.slotMinutes,
              rowExtent: (ppm * config.slotMinutes).clamp(8.0, 400.0),
              chipExtent: style.chipExtent,
              maxChipsPerCell: config.maxChipsPerCell,
              maxCountPerRow: maxCounts(perDay, axisRows.length),
              autoFit: config.option<bool>('autoFit', true),
            );
          }
          final metrics = _Metrics(
            width: width,
            height: height,
            rulerWidth: rulerWidth,
            pagesWidth: pagesWidth,
            pageWidth: pageWidth,
            headerHeight: headerHeight,
            laneHeight: laneHeight,
            laneRowExtent: laneRow,
            rtl: rtl,
          );
          final frame = _Frame(
            config: config,
            renderer: renderer,
            today: today,
            nowLocal: nowLocal,
            zone: zone,
            cache: cache,
            work: work,
            style: style,
            format: format,
            colors: colors,
            l10n: l,
            metrics: metrics,
            axis: axis,
            ppm: ppm,
            rows: rows,
            weekStart: weekStart,
            filter: filter,
          );
          final old = _frame;
          if (old != null &&
              _pinch == null &&
              _pendingScroll == null &&
              _initialScrollDone &&
              _vertical.hasClients &&
              (old.renderer != frame.renderer ||
                  old.ppm != frame.ppm ||
                  old.axis != frame.axis ||
                  old.rows?.height != frame.rows?.height)) {
            // Keep the time at the top of the viewport (T3.4.06 / T3.3.02).
            _pendingScroll = (_minuteAtContent(_vertical.offset), 0);
          }
          _frame = frame;
          _afterLayout(frame, visible);
          final locked = _pinch != null;
          return Focus(
            focusNode: _focus,
            autofocus: true,
            onKeyEvent: _onKey,
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onVerticalNotification,
                child: VerticalScrollProxy(
                  controller: _vertical,
                  viewportExtent: bodyHeight,
                  contentExtent: _contentHeight(frame),
                  physics: locked ? const NeverScrollableScrollPhysics() : null,
                  child: Row(
                    children: [
                      if (rulerWidth > 0)
                        SizedBox(
                          width: rulerWidth,
                          child: Column(
                            children: [
                              SizedBox(height: metrics.bodyTop, child: _corner(context, frame, visible)),
                              Expanded(child: _ruler(context, frame, visible, timelines)),
                            ],
                          ),
                        ),
                      Expanded(child: _pagesArea(context, frame, locked)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<LocalDate> _notifiedDays = const [];

  void _afterLayout(_Frame f, List<LocalDate> visible) {
    if (_initialScrollDone && !listEquals(visible, _notifiedDays)) {
      _notifiedDays = visible;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.controller?.updateVisibleDays(visible);
        // The shared anchor follows the first page too, not only page changes (T3.6.03).
        if (visible.isNotEmpty && widget.fixedAnchor == null) _sharedAnchor.set(visible.first);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_vertical.hasClients) return;
      final pending = _pendingScroll;
      if (pending != null) {
        _pendingScroll = null;
        _vertical.jumpTo(_offsetForMinute(pending.$1, anchorFraction: pending.$2));
      } else if (!_initialScrollDone) {
        final today = f.today;
        if (f.config.autoScrollToNow && visible.contains(today)) {
          _vertical.jumpTo(_offsetForMinute(f.nowLocal.time.minuteOfDay.toDouble(), anchorFraction: 1 / 3));
        } else {
          _vertical.jumpTo(_offsetForMinute(_firstTaskMinute(visible) ?? 7 * 60));
        }
      }
      if (!_initialScrollDone) {
        _initialScrollDone = true;
        _notifiedDays = visible;
        widget.controller?.updateVisibleDays(visible);
        if (visible.isNotEmpty && widget.fixedAnchor == null) _sharedAnchor.set(visible.first);
      }
    });
  }

  bool _initialScrollDone = false;

  double? _firstTaskMinute(List<LocalDate> days) {
    int? first;
    for (final d in _pageData.values) {
      for (final day in days) {
        final s = d.slices[day];
        if (s == null || s.timed.isEmpty) continue;
        final m = s.timed.first.wallStart;
        if (first == null || m < first) first = m;
      }
    }
    return first == null ? null : math.max(0, first - 60).toDouble();
  }

  double _rulerWidth(TextScaler ts, bool use24h) => timeRulerWidth(ts, use24h: use24h);

  double _headerHeight(TextScaler ts, PlannerViewConfig c) {
    var h = 6 + ts.scale(11) * 1.35 + 2 + 28;
    if (widget.showHeaderStats) h += ts.scale(10) * 1.3;
    if (c.showWeekNumbers) h += ts.scale(11) * 1.3;
    return h.ceilToDouble();
  }

  (Map<LocalDate, DaySlice>, bool) _watchSlices(
    WidgetRef ref,
    List<LocalDate> days,
    ItemFilter filter,
    Weekday weekStart,
  ) {
    final result = <LocalDate, DaySlice>{};
    var loading = false;
    final chunks = <LocalDate>{for (final d in days) d.startOfWeek(weekStart)};
    for (final c in chunks) {
      final value = ref.watch(daySlicesProvider(SliceKey(DayRange(c, 7), filter: filter))).value;
      if (value == null) {
        loading = true;
        continue;
      }
      for (final s in value) {
        result[s.date] = s;
      }
    }
    return (result, loading);
  }

  // --------------------------------------------------------------------------------- ruler --

  String Function(int, int) _formatMinute(_Frame f) =>
      (minute, repeat) => f.format.time(LocalTime.fromMinuteOfDay(minute.clamp(0, 1440)));

  Widget _ruler(BuildContext context, _Frame f, List<LocalDate> visible, List<DayTimeline> timelines) {
    final l = f.l10n;
    final repeatedDay = timelines.firstWhereOrNull((t) => t.repeatedRanges.isNotEmpty);
    String? offsetLabel(int m) => repeatedDay?.offsetLabelAt(m, repeat: 1);
    String hiddenLabel(int a, int b) => l.pvHiddenRange(
      f.format.time(LocalTime.fromMinuteOfDay(a.clamp(0, 1440))),
      f.format.time(LocalTime.fromMinuteOfDay(b.clamp(0, 1440))),
    );
    final todayIndex = visible.indexOf(f.today);
    if (f.renderer == GridRenderer.table) {
      return TableRuler(
        vertical: _vertical,
        rows: f.rows!,
        width: f.metrics.rulerWidth,
        formatMinute: _formatMinute(f),
        style: f.style,
        cache: _labels,
        hiddenLabel: hiddenLabel,
        gapLabel: l.pvClocksForward,
        offsetLabel: repeatedDay == null ? null : (m) => offsetLabel(m) ?? '',
        onDoubleTap: widget.onRulerDoubleTap,
        semanticsLabel: l.pvSlotSize,
      );
    }
    final zones = f.config.extraTimeZones;
    final zoneWidth = zoneRulerWidth(MediaQuery.textScalerOf(context));
    final main = TimeRuler(
      vertical: _vertical,
      axis: f.axis,
      scale: f.scale,
      width: f.metrics.rulerWidth - zones.length * zoneWidth,
      formatMinute: _formatMinute(f),
      style: f.style,
      now: _now,
      todayTimeline: todayIndex >= 0 ? timelines[todayIndex] : null,
      cache: _labels,
      offsetLabel: repeatedDay == null ? null : (m) => offsetLabel(m) ?? '',
      hiddenLabel: hiddenLabel,
      gapLabel: l.pvClocksForward,
      onDoubleTap: widget.onRulerDoubleTap,
      semanticsLabel: l.pvSlotSize,
    );
    if (zones.isEmpty || timelines.isEmpty) return main;
    // Extra zones (T3.3.26) convert the instants of the reference day (today when visible).
    final reference = todayIndex >= 0 ? timelines[todayIndex] : timelines.first;
    final resolver = ref.read(zoneResolverProvider);
    return Row(
      children: [
        for (final z in zones)
          ZoneRuler(
            key: ValueKey('zone-ruler-$z'),
            vertical: _vertical,
            axis: f.axis,
            scale: f.scale,
            width: zoneWidth,
            formatMinute: zoneFormatter(reference, (utc) => f.format.timeOf(resolver.toLocal(utc, z))),
            style: f.style,
            cache: _labels,
            label: zoneShortName(z),
            semanticsLabel: '${l.pvExtraZones}: ${zoneShortName(z)}',
          ),
        main,
      ],
    );
  }

  Widget _corner(BuildContext context, _Frame f, List<LocalDate> visible) {
    final l = f.l10n;
    final m = f.metrics;
    final week = f.config.showWeekNumbers && visible.isNotEmpty ? visible.first.weekOfYear(f.weekStart).week : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: m.headerHeight,
            child: Center(
              child: week == null
                  ? null
                  : FittedBox(
                      child: Text(
                        l.pvWeekNumber(week),
                        style: context.text.labelSmall?.copyWith(color: context.colors.outline),
                      ),
                    ),
            ),
          ),
          if (m.laneHeight > 0)
            SizedBox(
              height: m.laneHeight,
              child: Semantics(
                button: true,
                label: _laneExpanded ? l.pvCollapse : l.pvExpand,
                child: InkWell(
                  onTap: () => setState(() => _laneExpanded = !_laneExpanded),
                  child: Center(
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          l.pvAllDay,
                          style: context.text.labelSmall?.copyWith(fontSize: 9, color: context.colors.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------------- pages --

  Widget _pagesArea(BuildContext context, _Frame f, bool locked) {
    final paging = _paging!;
    final free = paging.mode == PagingMode.free && !paging.isWeekPaging;
    return Stack(
      key: _pagesKey,
      children: [
        Positioned.fill(
          child: MouseRegion(
            onHover: (e) => _cursor = _slotAt(e.localPosition),
            child: GestureDetector(
              onTapUp: _onTapUp,
              onLongPressStart: _onLongPressStart,
              onLongPressMoveUpdate: _onLongPressMoveUpdate,
              onLongPressEnd: _onLongPressEnd,
              onLongPressCancel: _cancelSession,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onPagesNotification,
                child: PageView.builder(
                  key: ValueKey(identityHashCode(_pages)),
                  controller: _pages,
                  padEnds: false,
                  allowImplicitScrolling: true,
                  pageSnapping: !free,
                  physics: locked
                      ? const NeverScrollableScrollPhysics()
                      : (free ? SnapToPagePhysics(pageFraction: paging.viewportFraction) : null),
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) => _GridPage(grid: this, index: index),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          key: _dragOverlayKey,
          child: IgnorePointer(
            child: ValueListenableBuilder<_SessionView?>(
              valueListenable: _sessionView,
              builder: (context, view, _) => view == null ? const SizedBox.shrink() : _dragOverlay(context, view),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<({String seriesId, Offset at})?>(
              valueListenable: _preview,
              builder: (context, p, _) => p == null
                  ? const SizedBox.shrink()
                  : Stack(
                      children: [
                        Positioned(
                          // rtl-ok anchored to the physical pointer position.
                          left: math.max(Space.sm, p.at.dx - 90),
                          top: math.max(Space.sm, p.at.dy - 64),
                          child: SeriesPreviewBubble(seriesId: p.seriesId),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (_toast != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.inverseSurface,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
                    child: Text(
                      _toast!,
                      style: context.text.titleMedium?.copyWith(color: context.colors.onInverseSurface),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPage(BuildContext context, WidgetRef ref, int index) {
    final f = _frame;
    final paging = _paging;
    if (f == null || paging == null) return const SizedBox.shrink();
    final days = paging.daysOfPage(index);
    final (slices, _) = _watchSlices(ref, days, f.filter, f.weekStart);
    var page = _pageData[index];
    if (page == null || !listEquals(page.days, days) || !mapEquals(page.slices, slices)) {
      page = _pageData[index] = _PageData(days, slices);
    }
    final m = f.metrics;
    final timelines = [for (final d in days) f.cache.of(d, f.zone)];
    final body = switch (f.renderer) {
      GridRenderer.timeline => _timelineBody(
        context,
        index,
        page,
        timelines,
        f,
        overlays: _watchOverlays(ref, days, f),
      ),
      GridRenderer.table => _tableBody(context, page, timelines, f),
      GridRenderer.weekList => _weekListBody(context, page, f),
    };
    return Column(
      children: [
        SizedBox(height: m.headerHeight, child: _headerRow(context, page, f)),
        if (m.laneHeight > 0) SizedBox(height: m.laneHeight, child: _lane(context, page, f)),
        Expanded(child: body),
      ],
    );
  }

  Widget _headerRow(BuildContext context, _PageData page, _Frame f) {
    final l = f.l10n;
    final fmt = f.format;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: Row(
        children: [
          for (final (i, d) in page.days.indexed)
            Expanded(
              child: Builder(
                builder: (context) {
                  final slice = page.slices[d];
                  final utilization = f.config.overlay('utilization');
                  final stats = (widget.showHeaderStats || utilization) && slice != null
                      ? DayStats.of(slice, f.work)
                      : null;
                  final overbookedMinutes = stats == null || !utilization || !stats.load.isFinite || stats.load <= 1
                      ? 0
                      : stats.plannedMinutes - (stats.plannedMinutes / stats.load).round();
                  final count = slice == null
                      ? 0
                      : {for (final s in slice.timed) s.item.key, for (final i in slice.lane) i.key}.length;
                  return DayHeaderCell(
                    date: d,
                    isToday: d == f.today,
                    format: fmt,
                    compact: f.metrics.pageWidth / page.days.length < 40,
                    showMonth:
                        d.day == 1 ||
                        (i == 0 && page.days.length > 1 && d.plusDays(page.days.length - 1).month != d.month),
                    weekNumber: f.config.showWeekNumbers && (i == 0 || d.weekday == f.weekStart)
                        ? l.pvWeekNumber(d.weekOfYear(f.weekStart).week)
                        : null,
                    stats: stats,
                    loadWarn: f.config.option<double>('loadWarn', 0.8),
                    loadOver: f.config.option<double>('loadOver', 1),
                    showUtilization: utilization,
                    statsText: !widget.showHeaderStats
                        ? null
                        : stats == null || (stats.total == 0 && stats.plannedMinutes == 0)
                        ? ''
                        : l.pvDayStats(
                            fmt.number(stats.done),
                            fmt.number(stats.total),
                            fmt.duration(stats.plannedMinutes),
                          ),
                    semanticsLabel: [
                      l.pvDayHeaderSemantics(fmt.dayLong(d), l.pvItemsCount(count)),
                      if (overbookedMinutes > 0) l.pvDayOverbooked(fmt.duration(overbookedMinutes)),
                    ].join('. '),
                    onTap: () => _openDay(d),
                    onLongPress: () => unawaited(_dayMenu(d)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _lane(BuildContext context, _PageData page, _Frame f) {
    final deps = <Object?>[_laneExpanded, ...page.days, for (final d in page.days) page.slices[d]];
    if (page.lane == null || !const ListEquality<Object?>().equals(page.laneDeps, deps)) {
      page
        ..lane = LaneModel.compute(page.days, page.slices, maxRows: _laneExpanded ? null : 2)
        ..laneDeps = deps;
    }
    return AllDayLane(
      model: page.lane!,
      width: f.metrics.pageWidth,
      height: f.metrics.laneHeight,
      rowExtent: f.metrics.laneRowExtent,
      rtl: f.metrics.rtl,
      colorsOf: f.colors.of,
      semanticsOf: (i) => _semantics(i, f),
      moreLabel: (n) => f.l10n.pvMore('$n'),
      onTapItem: _activate,
      draggingKey: _session?.item?.key,
    );
  }

  PageGeometry _timelineGeometry(_PageData page, _Frame f) {
    final laneCap = laneCapFor(f.metrics.pageWidth / math.max(1, page.days.length), f.config.laneCap);
    final deps = <Object?>[
      f.axis,
      f.ppm,
      f.metrics.pageWidth,
      f.metrics.rtl,
      laneCap,
      widget.tileLayout,
      f.config.overlapStyle,
      ...page.days,
      for (final d in page.days) page.slices[d],
    ];
    final cached = page.timeline;
    if (cached != null && const ListEquality<Object?>().equals(page.timelineDeps, deps)) return cached;
    final geom = PageGeometry.compute(
      days: page.days,
      slices: page.slices,
      axis: f.axis,
      ppm: f.ppm,
      width: f.metrics.pageWidth,
      rtl: f.metrics.rtl,
      laneCap: laneCap,
      layouts: _layouts,
      strategy: widget.tileLayout,
      cascade: f.config.overlapStyle == OverlapStyle.cascade,
    );
    page
      ..timeline = geom
      ..timelineDeps = deps;
    return geom;
  }

  /// Screen-reader nodes for the empty slots of a page (T3.3.24): "Monday 09:00, empty, double-tap
  /// to create". Built only while accessible navigation is on; slots shorter than 24 px are grouped.
  List<Widget> _emptySlotNodes(_PageData page, _Frame f) {
    final days = page.days;
    if (days.isEmpty) return const [];
    final col = f.metrics.pageWidth / days.length;
    final slot = f.config.slotMinutes;
    final group = slot * math.max<int>(1, (24 / (f.ppm * slot)).ceil());
    final window = f.config.dayWindow;
    final out = <Widget>[];
    for (final (i, day) in days.indexed) {
      final items = [for (final s in page.slices[day]?.timed ?? const <DaySegment>[]) s.item];
      for (var m = (window.startMinute ~/ group) * group; m < window.endMinute; m += group) {
        final start = day.atStartOfDay.plusMinutes(m);
        final end = day.atStartOfDay.plusMinutes(math.min(m + group, 1440));
        if (items.any((it) => it.startLocal.isBefore(end) && it.endLocal.isAfter(start))) continue;
        final top = f.axis.yOf(m, ppm: f.ppm);
        final bottom = f.axis.yOf(math.min(m + group, 1440), ppm: f.ppm, end: true);
        if (bottom - top < 1) continue;
        out.add(
          PositionedDirectional(
            start: i * col,
            top: top,
            width: col,
            height: bottom - top,
            child: Semantics(
              label: f.l10n.pvEmptySlotSemantics(f.format.dayLong(day), f.format.timeOf(start)),
              onTap: () => unawaited(_commands.quickCreate(start: start, duration: quickCreateDuration(slot, f.work))),
              child: const SizedBox.expand(),
            ),
          ),
        );
      }
    }
    return out;
  }

  /// Data of the enabled overlays of a page (T3.3.23): point markers and the occupancy heat.
  ({List<OverlayMarker> markers, OccupancyGrid? heat}) _watchOverlays(WidgetRef ref, List<LocalDate> days, _Frame f) {
    if (days.isEmpty) return (markers: const [], heat: null);
    final c = f.config;
    final query = OverlayQuery(
      DayRange(days.first, days.first.daysUntil(days.last) + 1),
      habits: c.overlay('habits'),
      checklistDue: c.overlay('checklistDue'),
    );
    final markers = query.isEmpty ? const <OverlayMarker>[] : ref.watch(plannerOverlayMarkersProvider(query));
    OccupancyGrid? heat;
    if (c.overlay('heat')) {
      final past = DayRange(days.first.plusDays(-28), 28);
      final items = ref.watch(viewItemsProvider(past)).value;
      if (items != null) heat = OccupancyGrid.build(items, start: past.start, days: past.days);
    }
    return (markers: markers, heat: heat);
  }

  Widget _timelineBody(
    BuildContext context,
    int index,
    _PageData page,
    List<DayTimeline> timelines,
    _Frame f, {
    ({List<OverlayMarker> markers, OccupancyGrid? heat}) overlays = (markers: const [], heat: null),
  }) {
    final geom = _timelineGeometry(page, f);
    final config = f.config;
    final now = f.nowLocal;
    final sessionKey = _session?.item?.key;
    final selected = _selectedKey == null ? null : geom.tiles.firstWhereOrNull((t) => t.item.key == _selectedKey);
    final overlayContext = PageOverlayContext(
      days: page.days,
      slices: page.slices,
      axis: f.axis,
      ppm: f.ppm,
      rtl: f.metrics.rtl,
      style: f.style,
    );
    final deviceSpans = config.overlay('deviceCalendars') && page.days.isNotEmpty
        ? ref.watch(deviceEventSpansProvider((page.days.first, page.days.length))).value ?? const <DeviceEventSpan>[]
        : const <DeviceEventSpan>[];
    return TimelinePageBody(
      geometry: geom,
      axis: f.axis,
      scale: f.scale,
      timelines: timelines,
      today: f.today,
      rtl: f.metrics.rtl,
      style: f.style,
      vertical: _vertical,
      viewportHeight: f.metrics.bodyHeight,
      nowUtc: _now,
      shadeWeekends: config.showWeekends,
      workWindow: f.work.hours,
      workDays: f.work.days,
      overlayPainters: [
        if (overlays.heat case final heat?)
          HeatTintPainter(page: overlayContext, grid: heat, color: context.appColors.warning),
        if (config.overlay('occupancy'))
          if (ref.watch(slotOccupancyOverlayProvider(config.slotMinutes)).value case final occ?)
            SlotOccupancyPainter(
              page: overlayContext,
              overlay: occ,
              color: context.colors.primary,
              deadColor: context.appColors.warning,
            ),
        if (deviceSpans.isNotEmpty)
          DeviceEventsPainter(
            page: overlayContext,
            spans: deviceSpans,
            color: context.colors.tertiary,
            textStyle: context.text.labelSmall!.copyWith(color: context.colors.onSurfaceVariant),
          ),
        if (config.overlay('freeSlots'))
          FreeSlotsPainter(
            page: overlayContext,
            color: context.appColors.success,
            openings: freeIntervals(
              items: pageItems(overlayContext),
              days: page.days,
              options: FreeSlotOptions(
                window: f.work.hours,
                workDays: f.work.days,
                minGapMinutes: config.option<int>('minGap', 30),
              ),
              elapsed: (a, b) => elapsedMinutes(ref.read(zoneResolverProvider), f.zone, a, b),
              extraBusy: [
                for (final s in deviceSpans)
                  if (s.busy) (s.start, s.end),
              ],
            ),
          ),
        for (final b in widget.overlayPainters)
          if (b(overlayContext) case final p?) p,
      ],
      tileBuilder: (g) {
        final item = g.item;
        final tile = TaskTile(
          item: item,
          colors: f.colors.of(item),
          timeText: g.variant == TileVariant.chip
              ? f.format.timeOf(item.startLocal)
              : f.format.timeRange(item.startLocal, item.endLocal),
          semanticsLabel: _semantics(item, f),
          variant: g.variant,
          past: item.endLocal.isBefore(now),
          dimPast: config.dimPast,
          selected: item.key == _selectedKey || _selection.containsKey(item.key),
          compactDensity: config.density == Density.compact,
          continuesBefore: g.segment.continuesBefore,
          continuesAfter: g.segment.continuesAfter,
          onTap: () => _activate(item),
          customActions: _semanticActions(item, f),
        );
        return item.key == sessionKey ? Opacity(opacity: 0.35, child: tile) : tile;
      },
      overflowBuilder: (o) => OverflowChip(
        label: f.l10n.pvMore('${o.items.length}'),
        semanticsLabel: f.l10n.pvMoreItems(o.items.length),
        onTap: () => unawaited(_commands.showOverflow(o.items, date: page.days[o.dayIndex])),
      ),
      foreground: [
        if (MediaQuery.accessibleNavigationOf(context)) ..._emptySlotNodes(page, f),
        ...positionedMarkers(
          markers: overlays.markers,
          days: page.days,
          page: overlayContext,
          width: f.metrics.pageWidth,
          builder: (m) => OverlayMarkerChip(
            marker: m,
            timeText: f.format.timeOf(m.day.atStartOfDay.plusMinutes(m.minute)),
            onTap: () => unawaited(openOverlayMarker(context, ref, m)),
          ),
        ),
        if (selected != null && !selected.item.allDay) ...[
          if (!selected.segment.continuesBefore) _resizeHandle(selected, top: true),
          if (!selected.segment.continuesAfter) _resizeHandle(selected, top: false),
        ],
      ],
    );
  }

  Widget _resizeHandle(TileGeom g, {required bool top}) {
    final r = g.rect;
    final center = Offset(r.center.dx, top ? r.top : r.bottom);
    return Positioned.fromRect(
      key: ValueKey('resize-${top ? 'top' : 'bottom'}'),
      rect: Rect.fromCenter(center: center, width: 48, height: 32),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (d) => _startResize(g, top: top, global: d.globalPosition),
        onVerticalDragUpdate: (d) => _updateSessionGlobal(d.globalPosition),
        onVerticalDragEnd: (_) => unawaited(_endSession()),
        onVerticalDragCancel: _cancelSession,
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  TablePageGeometry _tableGeometry(_PageData page, _Frame f) {
    final rows = f.rows!;
    final deps = <Object?>[
      rows,
      f.metrics.pageWidth,
      f.metrics.rtl,
      f.style.chipExtent,
      ...page.days,
      for (final d in page.days) page.slices[d],
    ];
    final cached = page.table;
    if (cached != null && const ListEquality<Object?>().equals(page.tableDeps, deps)) return cached;
    final geom = TablePageGeometry(
      days: page.days,
      width: f.metrics.pageWidth,
      rtl: f.metrics.rtl,
      rows: rows,
      slices: [for (final d in page.days) page.slices[d]],
      buckets: [
        for (final d in page.days)
          if (page.slices[d] case final s?)
            tableBuckets(s, rows.rows)
          else
            [for (var i = 0; i < rows.length; i++) const <Never>[]],
      ],
      chipExtent: f.style.chipExtent,
    );
    page
      ..table = geom
      ..tableDeps = deps;
    return geom;
  }

  Widget _tableBody(BuildContext context, _PageData page, List<DayTimeline> timelines, _Frame f) {
    final geom = _tableGeometry(page, f);
    final hidden = <(int, int), int>{};
    for (var r = 0; r < geom.rows.length; r++) {
      if (geom.rows.rows[r].kind != AxisBandKind.hidden) continue;
      for (var d = 0; d < page.days.length; d++) {
        final n = geom.entries(d, r).length;
        if (n > 0) hidden[(r, d)] = n;
      }
    }
    final sessionKey = _session?.item?.key;
    return TablePageBody(
      geometry: geom,
      vertical: _vertical,
      viewportHeight: f.metrics.bodyHeight,
      style: f.style,
      today: f.today,
      timelines: timelines,
      nowUtc: _now,
      shadeWeekends: f.config.showWeekends,
      workDays: f.work.days,
      hiddenCounts: hidden,
      chipBuilder: (item, isStart, dayIndex) {
        final chip = CellChip(
          item: item,
          colors: f.colors.of(item),
          label: isStart ? '${f.format.timeOf(item.startLocal)} ${item.title}' : item.title,
          semanticsLabel: _semantics(item, f),
          continuation: !isStart,
          past: item.endLocal.isBefore(f.nowLocal),
          dimPast: f.config.dimPast,
          selected: item.key == _selectedKey || _selection.containsKey(item.key),
          fontSize: f.config.density == Density.compact ? 10 : 11,
        );
        return item.key == sessionKey ? Opacity(opacity: 0.35, child: chip) : chip;
      },
      moreBuilder: (count) => OverflowChip(label: f.l10n.pvMore('$count'), semanticsLabel: f.l10n.pvMoreItems(count)),
    );
  }

  WeekListGeometry _weekListGeometry(_PageData page, _Frame f) {
    final deps = <Object?>[
      f.metrics.pageWidth,
      f.metrics.rtl,
      f.style.chipExtent,
      ...page.days,
      for (final d in page.days) page.slices[d],
    ];
    final cached = page.weekList;
    if (cached != null && const ListEquality<Object?>().equals(page.weekListDeps, deps)) return cached;
    final geom = WeekListGeometry(
      days: page.days,
      width: f.metrics.pageWidth,
      rtl: f.metrics.rtl,
      columns: [
        for (final d in page.days)
          if (page.slices[d] case final s?) weekListEntries(s) else const <WeekListEntry>[],
      ],
      chipExtent: f.style.chipExtent + 6,
    );
    page
      ..weekList = geom
      ..weekListDeps = deps;
    return geom;
  }

  Widget _weekListBody(BuildContext context, _PageData page, _Frame f) {
    final geom = _weekListGeometry(page, f);
    final s = _session;
    final sessionKey = s?.item?.key;
    (int, int)? drop;
    if (s != null && s.listMode && s.insertIndex != null) {
      final col = page.days.indexOf(s.refDay);
      if (col >= 0) drop = (col, s.insertIndex!);
    }
    return WeekListPageBody(
      geometry: geom,
      vertical: _vertical,
      viewportHeight: f.metrics.bodyHeight,
      style: f.style,
      today: f.today,
      shadeWeekends: f.config.showWeekends,
      dropIndicator: drop,
      chipBuilder: (entry, dayIndex) {
        final item = entry.item;
        final time = item.allDay ? f.l10n.pvAllDay : f.format.timeOf(item.startLocal);
        final chip = CellChip(
          item: item,
          colors: f.colors.of(item),
          label: entry.continuation ? item.title : '$time · ${item.title}',
          semanticsLabel: _semantics(item, f),
          continuation: entry.continuation,
          past: item.endLocal.isBefore(f.nowLocal),
          dimPast: f.config.dimPast,
          selected: item.key == _selectedKey || _selection.containsKey(item.key),
          fontSize: f.config.density == Density.compact ? 11 : 12,
        );
        return item.key == sessionKey ? Opacity(opacity: 0.35, child: chip) : chip;
      },
    );
  }

  // ------------------------------------------------------------------------- labels & a11y --

  String _semantics(PlannerItem item, _Frame f) {
    final l = f.l10n;
    final fmt = f.format;
    final base = item.allDay
        ? '${item.title}, ${fmt.dayLong(item.startLocal.date)}, ${l.pvAllDay}, ${context.statusLabel(item.status)}'
        : l.pvTileSemantics(
            item.title,
            fmt.dayLong(item.startLocal.date),
            fmt.timeOf(item.startLocal),
            fmt.timeOf(item.endLocal),
            context.statusLabel(item.status),
          );
    return item.isRecurring ? '$base, ${l.pvRepeats}' : base;
  }

  Map<CustomSemanticsAction, VoidCallback> _semanticActions(PlannerItem item, _Frame f) {
    final l = f.l10n;
    final step = math.max(1, math.min(15, f.config.snapMinutes));
    return {
      if (item.trackingMode == TrackingMode.check)
        CustomSemanticsAction(label: item.isDone ? l.pvMarkNotDone : l.pvMarkDone): () =>
            unawaited(_commands.toggleDone(item)),
      CustomSemanticsAction(label: l.pvMoveEarlier(step)): () => unawaited(_nudge(item, -step)),
      CustomSemanticsAction(label: l.pvMoveLater(step)): () => unawaited(_nudge(item, step)),
      CustomSemanticsAction(label: l.pvMovePreviousDay): () => unawaited(_moveDays(item, -1)),
      CustomSemanticsAction(label: l.pvMoveNextDay): () => unawaited(_moveDays(item, 1)),
      CustomSemanticsAction(label: l.pvSelect): () =>
          ref.read(plannerSelectionProvider(widget.viewKey).notifier).toggle(item),
    };
  }

  Future<void> _nudge(PlannerItem item, int minutes) {
    final start = item.startLocal.plusMinutes(minutes);
    return _commands.reschedule(item, start: start, message: context.l10n.pvMovedSnack(_frame!.format.timeOf(start)));
  }

  // ------------------------------------------------------------------------ hit testing --

  RenderBox? get _pagesBox => _pagesKey.currentContext?.findRenderObject() as RenderBox?;

  /// A move session over a grid without all-day items gets a drop strip over the body top (an
  /// overlay, so the layout never shifts under the finger).
  bool get _virtualLane {
    final s = _session;
    return s != null &&
        s.item != null &&
        !s.listMode &&
        s.kind == _SessionKind.move &&
        (_frame?.metrics.laneHeight ?? 0) == 0;
  }

  _Hit? _hitTest(Offset local, {bool session = false}) {
    final f = _frame;
    final paging = _paging;
    final pages = _pages;
    if (f == null || paging == null || pages == null || !pages.hasClients) return null;
    final m = f.metrics;
    final pageW = m.pageWidth;
    if (pageW <= 0) return null;
    final pixels = pages.position.pixels;
    final fromStart = m.rtl ? m.pagesWidth - local.dx : local.dx;
    final index = ((pixels + fromStart) / pageW).floor();
    final startOffset = index * pageW - pixels;
    final pageLeft = m.rtl ? m.pagesWidth - startOffset - pageW : startOffset;
    final x = local.dx - pageLeft;
    final days = paging.daysOfPage(index);
    final n = days.length;
    final physical = (x / (pageW / n)).floor().clamp(0, n - 1);
    final column = m.rtl ? n - 1 - physical : physical;
    final _Region region;
    final double y;
    final laneBottom = m.laneHeight > 0
        ? m.bodyTop
        : (session && _virtualLane ? m.headerHeight + m.laneRowExtent : m.bodyTop);
    if (local.dy < m.headerHeight) {
      region = _Region.header;
      y = local.dy;
    } else if (local.dy < laneBottom) {
      region = _Region.lane;
      y = local.dy - m.headerHeight;
    } else {
      region = _Region.body;
      y = local.dy - m.bodyTop + (_vertical.hasClients ? _vertical.offset : 0);
    }
    return _Hit(page: index, days: days, column: column, region: region, point: Offset(x, y), local: local);
  }

  /// Physical rect of [day]'s column in the pages area (null when not laid out / hidden weekday).
  Rect? _dayColumnRect(LocalDate day) {
    final f = _frame;
    final paging = _paging;
    final pages = _pages;
    if (f == null || paging == null || pages == null || !pages.hasClients) return null;
    final m = f.metrics;
    final index = paging.pageOf(day);
    final days = paging.daysOfPage(index);
    final col = days.indexOf(day);
    if (col < 0) return null;
    final startOffset = index * m.pageWidth - pages.position.pixels;
    final pageLeft = m.rtl ? m.pagesWidth - startOffset - m.pageWidth : startOffset;
    final colW = m.pageWidth / days.length;
    return Rect.fromLTWH(pageLeft + columnX(col, days.length, m.pageWidth, rtl: m.rtl), 0, colW, m.height);
  }

  double _bodyYOfMinute(double minute) {
    final f = _frame!;
    final offset = _vertical.hasClients ? _vertical.offset : 0.0;
    final double y;
    switch (f.renderer) {
      case GridRenderer.timeline:
        y = f.axis.yOf(minute.clamp(0, 1440), ppm: f.ppm, end: minute >= 1440);
      case GridRenderer.table:
        final rows = f.rows!;
        final m = minute.clamp(0.0, 1440.0);
        final r = rows.rowOfWall(m.floor().clamp(0, 1439));
        final row = rows.rows[r];
        y =
            rows.tops[r] +
            (row.minutes <= 0 ? 0 : ((m - row.wallStart) / row.minutes).clamp(0.0, 1.0) * rows.heights[r]);
      case GridRenderer.weekList:
        y = 0;
    }
    return f.metrics.bodyTop + y - offset;
  }

  /// Global position of wall [minute] on [day] in the grid body (tests, keyboard focus).
  @visibleForTesting
  Offset? globalPositionOf(LocalDate day, double minute) {
    final col = _dayColumnRect(day);
    final box = _pagesBox;
    if (col == null || box == null || _frame == null) return null;
    return box.localToGlobal(Offset(col.center.dx, _bodyYOfMinute(minute)));
  }

  /// Global position of the header cell / lane row of [day] (tests).
  @visibleForTesting
  Offset? globalHeaderOf(LocalDate day, {bool lane = false}) {
    final col = _dayColumnRect(day);
    final box = _pagesBox;
    final f = _frame;
    if (col == null || box == null || f == null) return null;
    final y = lane ? f.metrics.headerHeight + f.metrics.laneRowExtent / 2 : f.metrics.headerHeight / 2;
    return box.localToGlobal(Offset(col.center.dx, y));
  }

  /// Vertical axis of the visible days (tests).
  @visibleForTesting
  PageAxis? get debugAxis => _frame?.axis;

  /// Current zoom (px per minute) and the minute at the top of the viewport (tests).
  @visibleForTesting
  (double, double) get debugZoom => (_frame?.ppm ?? 0, _vertical.hasClients ? _minuteAtContent(_vertical.offset) : 0);

  // ------------------------------------------------------------------------------- taps --

  void _onTapUp(TapUpDetails d) {
    if (_pinchedSinceDown || _session != null) return;
    final hit = _hitTest(d.localPosition);
    final f = _frame;
    if (hit == null || f == null) return;
    switch (hit.region) {
      case _Region.header:
        _openDay(hit.day);
      case _Region.lane:
        final lane = _pageData[hit.page]?.lane;
        final row = ((hit.point.dy - 2) / f.metrics.laneRowExtent).floor();
        final item = lane?.itemAt(hit.column, row);
        if (item != null) {
          _activate(item);
        } else if (lane != null &&
            lane.packing.hiddenPerColumn.length > hit.column &&
            lane.packing.hiddenPerColumn[hit.column] > 0) {
          setState(() => _laneExpanded = !_laneExpanded);
        } else {
          unawaited(_commands.quickCreate(start: hit.day.atStartOfDay, duration: 1440, allDay: true));
        }
      case _Region.body:
        switch (f.renderer) {
          case GridRenderer.timeline:
            _tapTimeline(hit, f);
          case GridRenderer.table:
            _tapTable(hit, f);
          case GridRenderer.weekList:
            _tapWeekList(hit, f);
        }
    }
  }

  void _tapTimeline(_Hit hit, _Frame f) {
    final geom = _pageData[hit.page]?.timeline;
    final p = hit.point;
    // "+N" chips are drawn over the tiles.
    final overflow = geom?.overflowAt(p);
    if (overflow != null) {
      unawaited(_commands.showOverflow(overflow.items, date: hit.days[overflow.dayIndex]));
      return;
    }
    final tile = geom?.tileAt(p);
    if (tile != null) {
      final r = tile.rect;
      final fromStart = f.metrics.rtl ? r.right - p.dx : p.dx - r.left;
      _activate(
        tile.item,
        check:
            tile.item.trackingMode == TrackingMode.check &&
            tile.variant != TileVariant.minimal &&
            fromStart <= kTileCheckExtent + 6,
      );
      return;
    }
    final loc = f.axis.locate(p.dy, f.ppm);
    final band = f.axis.bands[loc.bandIndex];
    if (band.kind == AxisBandKind.hidden) {
      setState(
        () => _expandedHidden.add(band.wallStart < f.config.dayWindow.startMinute ? 0 : f.config.dayWindow.endMinute),
      );
      return;
    }
    if (_selectedKey != null) {
      setState(() => _selectedKey = null);
      return;
    }
    final slot = f.config.slotMinutes;
    final minute = (loc.wall ~/ slot) * slot;
    final start = hit.day.atStartOfDay.plusMinutes(minute.clamp(0, 1439));
    _cursor = start;
    unawaited(_commands.quickCreate(start: start, duration: quickCreateDuration(slot, f.work)));
  }

  void _tapTable(_Hit hit, _Frame f) {
    final geom = _pageData[hit.page]?.table;
    final t = geom?.hit(hit.point);
    if (t == null) return;
    if (t.item != null) {
      final cell = geom!.cellRect(t.dayIndex, t.row);
      final fromStart = f.metrics.rtl ? cell.right - hit.point.dx : hit.point.dx - cell.left;
      _activate(t.item!, check: t.isStart && t.item!.trackingMode == TrackingMode.check && fromStart <= 18);
      return;
    }
    if (t.overflow != null) {
      unawaited(_commands.showOverflow(t.overflow!, date: hit.days[t.dayIndex]));
      return;
    }
    final row = geom!.rows.rows[t.row];
    if (row.kind == AxisBandKind.hidden) {
      setState(
        () => _expandedHidden.add(row.wallStart < f.config.dayWindow.startMinute ? 0 : f.config.dayWindow.endMinute),
      );
      return;
    }
    if (_selectedKey != null) {
      setState(() => _selectedKey = null);
      return;
    }
    unawaited(
      _commands.quickCreate(
        start: hit.days[t.dayIndex].atStartOfDay.plusMinutes(row.wallStart.clamp(0, 1439)),
        duration: quickCreateDuration(row.minutes, f.work),
      ),
    );
  }

  void _tapWeekList(_Hit hit, _Frame f) {
    final geom = _pageData[hit.page]?.weekList;
    final h = geom?.hit(hit.point);
    if (h == null) return;
    final (day, index) = h;
    if (index != null) {
      final item = geom!.columns[day][index].item;
      final rect = geom.chipRect(day, index);
      final fromStart = f.metrics.rtl ? rect.right - hit.point.dx : hit.point.dx - rect.left;
      _activate(item, check: item.trackingMode == TrackingMode.check && fromStart <= 22);
      return;
    }
    unawaited(_commands.quickCreate(start: hit.days[day].atStartOfDay, duration: 1440, allDay: true));
  }

  /// Tap on an item: toggles it in selection mode (T3.1.18), else ticks it ([check]) or opens it.
  void _activate(PlannerItem item, {bool check = false}) {
    final selection = ref.read(plannerSelectionProvider(widget.viewKey).notifier);
    if (selection.active) {
      selection.toggle(item);
    } else if (check) {
      unawaited(_commands.toggleDone(item));
    } else {
      ref.read(plannerNavProvider).openTask(context, item);
    }
  }

  // ---------------------------------------------------------------------- keyboard (T3.3.24) --

  /// Items of the visible days in reading order: per day, all-day items then timed by start.
  List<PlannerItem> _keyboardItems() {
    final visible = _paging?.daysOnScreen(_page) ?? const <LocalDate>[];
    final slices = <LocalDate, DaySlice>{for (final p in _pageData.values) ...p.slices};
    final seen = <String>{};
    return [
      for (final d in visible)
        if (slices[d] case final s?)
          for (final i in [...s.lane, for (final seg in s.timed) seg.item])
            if (seen.add(i.key)) i,
    ];
  }

  PlannerItem? get _selectedItem =>
      _selectedKey == null ? null : _keyboardItems().firstWhereOrNull((i) => i.key == _selectedKey);

  void _select(PlannerItem item) {
    setState(() => _selectedKey = item.key);
    if (!item.allDay) scrollToMinute(item.startLocal.time.minuteOfDay.toDouble(), anchorFraction: 1 / 3);
  }

  /// ↑ / ↓: previous / next item of the visible days.
  void _selectAdjacent(int dir) {
    final items = _keyboardItems();
    if (items.isEmpty) return;
    final at = items.indexWhere((i) => i.key == _selectedKey);
    final next = at < 0 ? (dir > 0 ? 0 : items.length - 1) : (at + dir).clamp(0, items.length - 1);
    _select(items[next]);
  }

  /// ← / → with a selection: the nearest item (by start) of the previous / next visible day;
  /// past the first / last day the page turns.
  void _selectInNeighbourDay(PlannerItem from, int dir) {
    final visible = _paging?.daysOnScreen(_page) ?? const <LocalDate>[];
    final items = _keyboardItems();
    var i = visible.indexOf(from.startLocal.date) + dir;
    while (i >= 0 && i < visible.length) {
      final day = visible[i];
      final candidates = [
        for (final it in items)
          if (it.startLocal.date == day) it,
      ];
      if (candidates.isNotEmpty) {
        final minute = from.startLocal.time.minuteOfDay;
        candidates.sort(
          (a, b) =>
              (a.startLocal.time.minuteOfDay - minute).abs().compareTo((b.startLocal.time.minuteOfDay - minute).abs()),
        );
        _select(candidates.first);
        return;
      }
      i += dir;
    }
    unawaited(step(dir));
  }

  Future<void> _moveDays(PlannerItem item, int days) {
    final start = item.startLocal.plusDays(days);
    final f = _frame!;
    return _commands.reschedule(
      item,
      start: start,
      message: context.l10n.pvMovedSnack('${f.format.dayShort(start.date)} ${f.format.timeOf(start)}'),
    );
  }

  /// Where Ctrl/Cmd + V pastes: the hovered / last tapped slot, else right after the selected item,
  /// else the next quarter hour today (or 09:00 on the first visible day).
  LocalDateTime _pasteTarget(_Frame f) {
    if (_cursor case final c?) return c;
    if (_selectedItem case final s?) return s.endLocal;
    final visible = _paging?.daysOnScreen(_page) ?? const <LocalDate>[];
    if (visible.contains(f.today)) {
      final m = f.nowLocal.time.minuteOfDay;
      return f.today.atStartOfDay.plusMinutes(math.min(1425, ((m + 14) ~/ 15) * 15));
    }
    return (visible.firstOrNull ?? f.today).atTime(LocalTime(9, 0));
  }

  /// The slot start under a point of the pages area (timeline and table renderers).
  LocalDateTime? _slotAt(Offset local) {
    final f = _frame;
    final hit = _hitTest(local);
    if (f == null || hit == null || hit.region != _Region.body) return null;
    final slot = f.config.slotMinutes;
    return switch (f.renderer) {
      GridRenderer.timeline => hit.day.atStartOfDay.plusMinutes(
        ((f.axis.locate(hit.point.dy, f.ppm).wall ~/ slot) * slot).clamp(0, 1439),
      ),
      GridRenderer.table => () {
        final row = _pageData[hit.page]?.table?.hit(hit.point)?.row;
        final rows = _pageData[hit.page]?.table?.rows.rows;
        return row == null || rows == null
            ? null
            : hit.day.atStartOfDay.plusMinutes(rows[row].wallStart.clamp(0, 1439));
      }(),
      GridRenderer.weekList => hit.day.atStartOfDay,
    };
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final f = _frame;
    if (f == null || _session != null) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    final shift = keyboard.isShiftPressed;
    final command = keyboard.isControlPressed || keyboard.isMetaPressed;
    final key = event.logicalKey;
    final selected = _selectedItem;
    if (command) {
      if (key == LogicalKeyboardKey.keyC && selected != null) {
        _commands.copy(selected);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyV) {
        unawaited(_commands.paste(_pasteTarget(f)));
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final snap = math.max(1, f.config.snapMinutes);
    // ← / → follow the reading direction (mirrored in RTL).
    final forward = key == LogicalKeyboardKey.arrowRight
        ? !f.metrics.rtl
        : (key == LogicalKeyboardKey.arrowLeft ? f.metrics.rtl : null);
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      final dir = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      if (shift && selected != null) {
        unawaited(_nudge(selected, dir * snap));
      } else {
        _selectAdjacent(dir);
      }
      return KeyEventResult.handled;
    }
    if (forward != null) {
      final dir = forward ? 1 : -1;
      if (shift && selected != null) {
        unawaited(_moveDays(selected, dir));
      } else if (selected != null) {
        _selectInNeighbourDay(selected, dir);
      } else {
        unawaited(step(dir));
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (selected == null) return KeyEventResult.ignored;
      _activate(selected);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      if (selected == null) return KeyEventResult.ignored;
      _activate(selected, check: selected.trackingMode == TrackingMode.check);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_selectedKey == null && _selection.isEmpty) return KeyEventResult.ignored;
      setState(() => _selectedKey = null);
      ref.read(plannerSelectionProvider(widget.viewKey).notifier).clear();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
      zoomBy(1.25);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
      zoomBy(0.8);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown || key == LogicalKeyboardKey.pageUp) {
      unawaited(step(key == LogicalKeyboardKey.pageDown ? 1 : -1));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _openDay(LocalDate day) => ref.read(plannerNavProvider).openView(context, 'day_list', date: day);

  Future<void> _dayMenu(LocalDate day) async {
    final f = _frame;
    if (f == null) return;
    final paging = _paging!;
    final slice = _pageData[paging.pageOf(day)]?.slices[day];
    final items = slice == null
        ? const <PlannerItem>[]
        : {for (final s in slice.timed) s.item.key: s.item, for (final i in slice.lane) i.key: i}.values.toList();
    await _commands.showDayMenu(
      day,
      items,
      now: f.nowLocal,
      load: slice == null || !f.config.overlay('utilization') ? null : DayStats.of(slice, f.work),
      capacityMinutes: f.work.days.contains(day.weekday.iso) ? f.work.minutesPerDay : 0,
    );
  }

  // ---------------------------------------------------------------------------- sessions --

  SnapEngine _snapFor(LocalDate day, LocalDate refDay, {String? exclude}) {
    final f = _frame!;
    final shift = refDay.daysUntil(day) * 1440;
    final targets = <int>[];
    final slice = _pageData[_paging!.pageOf(day)]?.slices[day];
    if (slice != null) {
      for (final s in slice.timed) {
        if (s.item.key == exclude) continue;
        if (!s.continuesBefore) targets.add(s.wallStart + shift);
        if (!s.continuesAfter) targets.add(s.wallEnd + shift);
      }
    }
    if (day == f.today) targets.add(f.nowLocal.time.minuteOfDay + shift);
    return SnapEngine(
      snapMinutes: f.config.snapMinutes,
      pxPerMinute: f.renderer == GridRenderer.table
          ? (f.rows!.length == 0 ? f.ppm : f.rows!.heights.first / math.max(1, f.config.slotMinutes))
          : f.ppm,
      magnetTargets: f.renderer == GridRenderer.timeline ? targets : const [],
      free: _freeSnap || f.config.option<bool>('freeDrag', false),
    );
  }

  void _onLongPressStart(LongPressStartDetails d) {
    if (_pinch != null || _pointers.length > 1) return;
    final hit = _hitTest(d.localPosition);
    final f = _frame;
    if (hit == null || f == null) return;
    _Session? s;
    switch (hit.region) {
      case _Region.header:
        unawaited(_dayMenu(hit.day));
        return;
      case _Region.lane:
        final lane = _pageData[hit.page]?.lane;
        final row = ((hit.point.dy - 2) / f.metrics.laneRowExtent).floor();
        final item = lane?.itemAt(hit.column, row);
        if (item == null) return;
        s = _Session(
          kind: _SessionKind.move,
          item: item,
          refDay: hit.day,
          range: const DragRange(0, 1440),
          pointer: d.localPosition,
          toLane: true,
          fromLane: true,
        );
      case _Region.body:
        s = switch (f.renderer) {
          GridRenderer.timeline => _startTimelineSession(hit, f, d.localPosition),
          GridRenderer.table => _startTableSession(hit, f, d.localPosition),
          GridRenderer.weekList => _startWeekListSession(hit, f, d.localPosition),
        };
    }
    if (s == null) return;
    ref.read(plannerHapticsProvider).lift();
    _beginSession(s);
    final item = s.item;
    if (s.kind == _SessionKind.move && item != null && item.isRecurring && item.seriesId.isNotEmpty) {
      _preview.value = (seriesId: item.seriesId, at: d.localPosition);
    }
  }

  _Session? _startTimelineSession(_Hit hit, _Frame f, Offset local) {
    final geom = _pageData[hit.page]?.timeline;
    final p = hit.point;
    final finger = _minuteAtContent(p.dy);
    if (geom?.overflowAt(p) != null) return null;
    final tile = geom?.tileAt(p, slop: 0);
    if (tile != null) {
      final item = tile.item;
      final day = hit.days[tile.dayIndex];
      final start = day.atStartOfDay.minutesUntil(item.startLocal);
      final range = DragRange(start, start + item.durationMinutes);
      final r = tile.rect;
      final edge = math.min(12, r.height / 4);
      if (p.dy - r.top <= edge && !tile.segment.continuesBefore && r.height >= 24) {
        return _Session(kind: _SessionKind.resizeStart, item: item, refDay: day, range: range, pointer: local);
      }
      if (r.bottom - p.dy <= edge && !tile.segment.continuesAfter && r.height >= 24) {
        return _Session(kind: _SessionKind.resizeEnd, item: item, refDay: day, range: range, pointer: local);
      }
      return _Session(
        kind: _SessionKind.move,
        item: item,
        refDay: day,
        range: range,
        pointer: local,
        grabOffset: (finger - start).round(),
      );
    }
    final band = f.axis.bands[f.axis.locate(p.dy, f.ppm).bandIndex];
    if (band.kind != AxisBandKind.normal) return null;
    final snap = _snapFor(hit.day, hit.day);
    final anchor = snap.snapFloor(finger).minute.clamp(0, 1439);
    return _Session(
      kind: _SessionKind.create,
      refDay: hit.day,
      range: DragRange(anchor, math.min(1440, anchor + quickCreateDuration(f.config.slotMinutes, f.work))),
      pointer: local,
      grabOffset: anchor,
    );
  }

  _Session? _startTableSession(_Hit hit, _Frame f, Offset local) {
    final geom = _pageData[hit.page]?.table;
    final t = geom?.hit(hit.point);
    if (t == null) return null;
    final row = geom!.rows.rows[t.row];
    if (row.kind != AxisBandKind.normal) return null;
    final finger = _minuteAtContent(hit.point.dy);
    final item = t.item;
    if (item != null) {
      final day = hit.days[t.dayIndex];
      final start = day.atStartOfDay.minutesUntil(item.startLocal);
      return _Session(
        kind: _SessionKind.move,
        item: item,
        refDay: day,
        range: DragRange(start, start + item.durationMinutes),
        pointer: local,
        grabOffset: (finger - start).round(),
      );
    }
    if (t.overflow != null) return null;
    return _Session(
      kind: _SessionKind.create,
      refDay: hit.days[t.dayIndex],
      range: DragRange(row.wallStart, row.wallEnd),
      pointer: local,
      grabOffset: row.wallStart,
    );
  }

  _Session? _startWeekListSession(_Hit hit, _Frame f, Offset local) {
    final geom = _pageData[hit.page]?.weekList;
    final h = geom?.hit(hit.point);
    if (h == null || h.$2 == null) return null;
    final item = geom!.columns[h.$1][h.$2!].item;
    return _Session(
      kind: _SessionKind.move,
      item: item,
      refDay: hit.days[h.$1],
      range: DragRange(0, item.durationMinutes),
      pointer: local,
      listMode: true,
      insertIndex: h.$2,
    );
  }

  void _startResize(TileGeom g, {required bool top, required Offset global}) {
    final box = _pagesBox;
    final paging = _paging;
    if (box == null || paging == null || _session != null) return;
    final local = box.globalToLocal(global);
    final hit = _hitTest(local);
    if (hit == null) return;
    final day = hit.days[g.dayIndex];
    final start = day.atStartOfDay.minutesUntil(g.item.startLocal);
    ref.read(plannerHapticsProvider).lift();
    _beginSession(
      _Session(
        kind: top ? _SessionKind.resizeStart : _SessionKind.resizeEnd,
        item: g.item,
        refDay: day,
        range: DragRange(start, start + g.item.durationMinutes),
        pointer: local,
      ),
    );
  }

  void _beginSession(_Session s) {
    _lastSnapMinute = null;
    setState(() => _session = s);
    _publish(s);
    _lastTick = Duration.zero;
    _edgeDir = 0;
    _edgeTicker ??= createTicker(_onEdgeTick);
    if (!_edgeTicker!.isActive) unawaited(_edgeTicker!.start());
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails d) {
    if (_preview.value != null && d.offsetFromOrigin.distance > 8) _preview.value = null;
    _updateSession(d.localPosition);
  }

  void _updateSessionGlobal(Offset global) {
    final box = _pagesBox;
    if (box == null) return;
    _updateSession(box.globalToLocal(global));
  }

  void _updateSession(Offset local) {
    final s = _session;
    final f = _frame;
    if (s == null || f == null) return;
    s.pointer = local;
    if ((local - s.startPointer).distance > 6) s.moved = true;
    final hit = _hitTest(local, session: true);
    if (hit == null) return;
    final item = s.item;
    switch (s.kind) {
      case _SessionKind.create:
        if (hit.region != _Region.body) break;
        final shift = s.refDay.daysUntil(hit.day) * 1440;
        final finger = _minuteAtContent(hit.point.dy) + shift;
        s.range = DragMath.create(s.grabOffset, finger.clamp(0.0, 1440.0), _snapFor(s.refDay, s.refDay));
        if (s.range.end > 1440) s.range = DragRange(s.range.start, 1440);
      case _SessionKind.resizeStart:
      case _SessionKind.resizeEnd:
        if (hit.region != _Region.body) break;
        final shift = s.refDay.daysUntil(hit.day) * 1440;
        final finger = _minuteAtContent(hit.point.dy) + shift;
        s.range = DragMath.resize(
          endEdge: s.kind == _SessionKind.resizeEnd,
          fingerMinute: finger,
          start: s.range.start,
          end: s.range.end,
          snap: _snapFor(hit.day, s.refDay, exclude: item?.key),
        );
      case _SessionKind.move:
        if (s.listMode) {
          s.refDay = hit.day;
          final geom = _pageData[hit.page]?.weekList;
          if (geom != null && hit.region == _Region.body) {
            final col = hit.days.indexOf(hit.day);
            s.insertIndex = geom.insertionIndex(col, hit.point.dy);
          }
          break;
        }
        if (hit.region == _Region.lane || hit.region == _Region.header) {
          s
            ..toLane = true
            ..refDay = hit.day
            ..range = const DragRange(0, 1440);
          break;
        }
        s
          ..toLane = false
          ..refDay = hit.day;
        final finger = _minuteAtContent(hit.point.dy);
        final duration = s.fromLane ? 30 : (item?.durationMinutes ?? 30);
        s.range = DragMath.move(
          finger,
          s.fromLane ? 0 : s.grabOffset,
          duration,
          _snapFor(hit.day, hit.day, exclude: item?.key),
        );
    }
    final edgeMinute = switch (s.kind) {
      _SessionKind.resizeStart => s.range.start,
      _SessionKind.move => s.range.start + s.refDay.epochDay * 1440 + (s.toLane ? 1 : 0),
      _ => s.range.end,
    };
    if (_lastSnapMinute != null && edgeMinute != _lastSnapMinute) ref.read(plannerHapticsProvider).selection();
    _lastSnapMinute = edgeMinute;
    _publish(s);
    if (s.listMode) setState(() {});
  }

  void _publish(_Session s) {
    final f = _frame;
    if (f == null) return;
    _sessionView.value = _SessionView(s, _bubbleText(s, f));
  }

  String _bubbleText(_Session s, _Frame f) {
    final fmt = f.format;
    final l = f.l10n;
    if (s.listMode || s.toLane) return s.toLane ? '${fmt.dayShort(s.refDay)} · ${l.pvAllDay}' : fmt.dayShort(s.refDay);
    final start = s.refDay.atStartOfDay.plusMinutes(s.range.start);
    final end = s.refDay.atStartOfDay.plusMinutes(s.range.end);
    return '${fmt.dayShort(start.date)} ${fmt.timeRange(start, end)} · ${fmt.duration(s.range.duration)}';
  }

  void _onEdgeTick(Duration elapsed) {
    final s = _session;
    final f = _frame;
    if (s == null || f == null) {
      _edgeTicker?.stop();
      return;
    }
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    final m = f.metrics;
    if (_vertical.hasClients && dt > 0) {
      final speed = DragMath.autoScrollSpeed(s.pointer.dy, m.bodyTop, m.height);
      if (speed != 0) {
        final pos = _vertical.position;
        final next = (pos.pixels + speed * dt).clamp(pos.minScrollExtent, pos.maxScrollExtent);
        if (next != pos.pixels) {
          _vertical.jumpTo(next);
          _updateSession(s.pointer);
        }
      }
    }
    final resizing =
        s.kind == _SessionKind.resizeStart || s.kind == _SessionKind.resizeEnd || s.kind == _SessionKind.create;
    final dir = resizing ? 0 : DragMath.pageEdgeDirection(s.pointer.dx, m.pagesWidth, rtl: m.rtl);
    if (dir == 0) {
      _edgeDir = 0;
      return;
    }
    if (dir != _edgeDir) {
      _edgeDir = dir;
      _edgeSince = elapsed;
      return;
    }
    if (!_autoPaging && elapsed - _edgeSince >= const Duration(milliseconds: 400)) {
      _autoPaging = true;
      _edgeSince = elapsed + const Duration(milliseconds: 500);
      unawaited(
        step(dir).whenComplete(() {
          _autoPaging = false;
          if (mounted && _session != null) _updateSession(_session!.pointer);
        }),
      );
    }
  }

  void _onLongPressEnd(LongPressEndDetails d) => unawaited(_endOrHandOff(d.globalPosition));

  Future<void> _endOrHandOff(Offset global) async {
    final s = _session;
    final outside = widget.onDropOutside;
    if (s != null && outside != null && s.kind == _SessionKind.move && s.item != null && s.moved) {
      if (await outside(s.item!, global)) {
        _clearSession();
        return;
      }
    }
    await _endSession();
  }

  /// Start of the slot under a global point and whether it is in the all-day lane (external drops
  /// such as the backlog drawer, T3.7.02); null outside the days.
  @override
  ({LocalDateTime start, bool allDay})? dropSlotAt(Offset global) {
    final box = _pagesBox;
    final f = _frame;
    if (box == null || f == null) return null;
    final local = box.globalToLocal(global);
    if (!(Offset.zero & box.size).contains(local)) return null;
    final hit = _hitTest(local);
    if (hit == null) return null;
    if (hit.region == _Region.lane || hit.region == _Region.header) {
      return (start: hit.day.atStartOfDay, allDay: true);
    }
    final slot = _slotAt(local);
    if (slot == null) return null;
    final snap = f.config.snapMinutes;
    final wall = f.renderer == GridRenderer.timeline
        ? ((f.axis.locate(hit.point.dy, f.ppm).wall / snap).round() * snap).clamp(0, 1439)
        : slot.time.minuteOfDay;
    return (start: hit.day.atStartOfDay.plusMinutes(wall), allDay: false);
  }

  void _clearSession() {
    _edgeTicker?.stop();
    _sessionView.value = null;
    _preview.value = null;
    if (mounted) setState(() => _session = null);
  }

  void _cancelSession() {
    if (_session == null) return;
    _clearSession();
  }

  Future<void> _endSession() async {
    final s = _session;
    final f = _frame;
    if (s == null || f == null) return;
    _clearSession();
    final l = f.l10n;
    final item = s.item;
    switch (s.kind) {
      case _SessionKind.create:
        final step = DragMath.minLength(_snapFor(s.refDay, s.refDay));
        if (s.moved && s.range.start == s.grabOffset && s.range.end == s.grabOffset + step) {
          return; // back to the origin
        }
        final start = s.refDay.atStartOfDay.plusMinutes(s.range.start);
        await _commands.quickCreate(start: start, duration: math.max(1, s.range.duration));
      case _SessionKind.resizeStart:
      case _SessionKind.resizeEnd:
        if (item == null || !s.changed) return;
        final start = s.refDay.atStartOfDay.plusMinutes(s.range.start);
        await _commands.reschedule(
          item,
          start: start,
          duration: s.range.duration,
          message: l.pvResizedSnack(f.format.duration(s.range.duration)),
        );
      case _SessionKind.move:
        if (item == null) return;
        if (!s.moved || !s.changed) {
          if (s.listMode && s.insertIndex != null && s.moved) {
            await _reorderInDay(s, item);
            return;
          }
          if (!s.moved) {
            setState(() => _selectedKey = item.key);
            await _commands.showTileMenu(
              item,
              onSelect: () => ref.read(plannerSelectionProvider(widget.viewKey).notifier).select(item),
            );
          }
          return;
        }
        if (s.listMode) {
          final start = s.refDay.atTime(item.startLocal.time);
          await _commands.reschedule(
            item,
            start: item.allDay ? s.refDay.atStartOfDay : start,
            message: l.pvMovedSnack(f.format.dayShort(s.refDay)),
          );
          return;
        }
        if (s.toLane) {
          await _commands.reschedule(
            item,
            start: s.refDay.atStartOfDay,
            duration: item.allDay ? item.durationMinutes : 1440,
            allDay: true,
            message: l.pvMovedSnack('${f.format.dayShort(s.refDay)} · ${l.pvAllDay}'),
          );
          return;
        }
        final start = s.refDay.atStartOfDay.plusMinutes(s.range.start);
        await _commands.reschedule(
          item,
          start: start,
          duration: item.allDay ? 30 : null,
          allDay: item.allDay ? false : null,
          message: l.pvMovedSnack('${f.format.dayShort(start.date)} ${f.format.timeOf(start)}'),
        );
    }
  }

  Future<void> _reorderInDay(_Session s, PlannerItem item) async {
    final f = _frame!;
    final geom = _pageData[_paging!.pageOf(s.refDay)]?.weekList;
    if (geom == null) return;
    final col = geom.days.indexOf(s.refDay);
    if (col < 0 || !item.allDay) return;
    final entries = geom.columns[col].where((e) => e.item.allDay).toList();
    final from = entries.indexWhere((e) => e.item.key == item.key);
    var to = s.insertIndex!.clamp(0, entries.length);
    if (from < 0 || to == from || to == from + 1) return;
    if (to > from) to--;
    final others = [...entries]..removeAt(from);
    final after = to == 0 ? null : others[to - 1].item.manualSortKey;
    final before = to >= others.length ? null : others[to].item.manualSortKey;
    await _commands.runExtra(
      f.l10n.pvMovedSnack(f.format.dayShort(s.refDay)),
      (a) => a.reorder(item, afterKey: after, beforeKey: before),
    );
  }

  // ------------------------------------------------------------------------------ overlay --

  Widget _dragOverlay(BuildContext context, _SessionView view) {
    final f = _frame;
    if (f == null) return const SizedBox.shrink();
    final s = view.session;
    final m = f.metrics;
    final children = <Widget>[];
    final col = _dayColumnRect(s.refDay);
    final item = s.item;
    final colors = item == null ? null : f.colors.of(item);
    if (_virtualLane) {
      children.add(
        Positioned.fromRect(
          rect: Rect.fromLTWH(0, m.headerHeight, m.pagesWidth, m.laneRowExtent),
          child: DecoratedBox(
            key: const Key('lane-drop'),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.withValues(alpha: 0.92),
              border: Border(bottom: BorderSide(color: context.colors.primary)),
            ),
            child: Center(child: Text(f.l10n.pvAllDay, style: context.text.labelSmall)),
          ),
        ),
      );
    }
    if (col != null && !s.listMode) {
      final Rect ghost;
      if (s.toLane) {
        ghost = Rect.fromLTWH(col.left + 1, m.headerHeight + 2, col.width - 2, m.laneRowExtent - 3);
      } else {
        final top = _bodyYOfMinute(s.range.start.toDouble());
        final bottom = _bodyYOfMinute(math.min(1440, s.range.end).toDouble());
        ghost = Rect.fromLTRB(
          col.left + 1,
          math.max(m.bodyTop, top),
          col.right - 1,
          math.max(math.max(m.bodyTop, top) + 18, bottom),
        );
      }
      children.add(
        Positioned.fromRect(
          rect: ghost,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (colors?.background ?? context.colors.primaryContainer).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(Radii.sm),
              border: Border.all(color: colors?.accent ?? context.colors.primary, width: 2),
              boxShadow: AppShadows.floating,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 2, 2),
              child: Text(
                item?.title ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors?.foreground ?? context.colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      );
    }
    final bubbleWidth = math.min<double>(m.pagesWidth - 8, 240);
    final left = (s.pointer.dx - bubbleWidth / 2).clamp(4.0, math.max(4.0, m.pagesWidth - bubbleWidth - 4)).toDouble();
    final top = (s.pointer.dy - 72).clamp(4.0, math.max(4.0, m.height - 40)).toDouble();
    children.add(
      Positioned.fromRect(
        rect: Rect.fromLTWH(left, top, bubbleWidth, 32),
        child: Center(
          child: DecoratedBox(
            key: const Key('time-bubble'),
            decoration: BoxDecoration(
              color: context.colors.inverseSurface,
              borderRadius: BorderRadius.circular(Radii.pill),
              boxShadow: AppShadows.soft,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
              child: Text(
                view.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge?.copyWith(
                  color: context.colors.onInverseSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Stack(children: children);
  }

  // ------------------------------------------------------------------------------- pinch --

  void _onPointerDown(PointerDownEvent e) {
    if (!_focus.hasFocus) _focus.requestFocus();
    if (_pointers.isEmpty) _pinchedSinceDown = false;
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      if (_session != null) {
        _freeSnap = true;
        return;
      }
      _startPinch();
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    if (_pinch != null) _updatePinch();
  }

  void _onPointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2) {
      _freeSnap = false;
      if (_pinch != null) _endPinch();
    }
  }

  Offset _toBody(Offset global) {
    final box = _pagesBox;
    final f = _frame;
    if (box == null || f == null) return Offset.zero;
    final local = box.globalToLocal(global);
    return Offset(local.dx, local.dy - f.metrics.bodyTop);
  }

  void _startPinch() {
    final f = _frame;
    if (f == null) return;
    final pts = _pointers.values.take(2).toList();
    final a = _toBody(pts[0]);
    final b = _toBody(pts[1]);
    final focalY = ((a.dy + b.dy) / 2).clamp(0.0, f.metrics.bodyHeight);
    final contentY = focalY + (_vertical.hasClients ? _vertical.offset : 0);
    final loc = f.renderer == GridRenderer.timeline
        ? f.axis.locate(contentY, f.ppm)
        : (wall: _minuteAtContent(contentY), repeat: 0, bandIndex: 0);
    _pinchedSinceDown = true;
    setState(() {
      _pinch = _Pinch(
        a: a,
        b: b,
        startPpm: f.ppm,
        startDays: _paging!.daysVisible,
        focalY: focalY,
        focalMinute: loc.wall,
        focalRepeat: loc.repeat,
      );
    });
  }

  void _updatePinch() {
    final p = _pinch;
    final f = _frame;
    if (p == null || f == null || _pointers.length < 2) return;
    final pts = _pointers.values.take(2).toList();
    final a = _toBody(pts[0]);
    final b = _toBody(pts[1]);
    final dy0 = math.max(24, (p.a.dy - p.b.dy).abs());
    final dx0 = math.max(24, (p.a.dx - p.b.dx).abs());
    final vScale = math.max(24, (a.dy - b.dy).abs()) / dy0;
    final hScale = math.max(24, (a.dx - b.dx).abs()) / dx0;
    if (p.lock == null) {
      final rv = math.log(vScale).abs();
      final rh = math.log(hScale).abs();
      if (math.max(rv, rh) < 0.06) return;
      p.lock = rv >= rh ? Axis.vertical : Axis.horizontal;
    }
    if (p.lock == Axis.vertical) {
      if (f.renderer == GridRenderer.weekList) return;
      _zoomTo(p.startPpm * vScale, focalMinute: p.focalMinute, focalRepeat: p.focalRepeat, focalY: p.focalY);
    } else {
      final tablet = MediaQuery.of(context).size.shortestSide >= 600;
      final days = ZoomMath.daysForScale(p.startDays, hScale, maxDays: tablet ? 14 : 7);
      if (days != _paging!.daysVisible) {
        setState(() {
          if (_landscape) {
            _daysLandscape = days;
          } else {
            _daysPortrait = days;
          }
        });
      }
    }
  }

  void _zoomTo(double requestedPpm, {required double focalMinute, int focalRepeat = 0, required double focalY}) {
    final f = _frame!;
    final config = f.config;
    final bodyHeight = f.metrics.bodyHeight;
    var slot = config.slotMinutes;
    var ppm = requestedPpm;
    if (config.zoomMode == ZoomMode.semantic) {
      final next = ZoomMath.semanticSlot(slot, ppm);
      if (next != slot) {
        slot = next;
        ref
            .read(plannerViewConfigProvider(widget.viewKey).notifier)
            .update(config.withSlot(next, keepPxPerMinute: true));
        _showToast(slotLabel(f.format, next));
      }
    }
    ppm = TimeScale.clampPxPerMinute(
      ppm,
      slotMinutes: slot,
      viewportExtent: bodyHeight,
      dayMinutes: math.max(60, f.axis.normalMinutes),
    );
    if ((ppm - f.ppm).abs() < 1e-4) return;
    setState(() => _ppm = ppm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_vertical.hasClients) return;
      final g = _frame!;
      final double contentY;
      if (g.renderer == GridRenderer.timeline) {
        contentY = g.axis.yOf(focalMinute, repeat: focalRepeat, ppm: g.ppm);
      } else {
        contentY = _offsetForMinute(focalMinute) + 0;
      }
      final max = math.max<double>(0, _contentHeight(g) - g.metrics.bodyHeight);
      _vertical.jumpTo(ZoomMath.keepFocal(focalContentY: contentY, focalViewportY: focalY, maxOffset: max));
    });
  }

  void _endPinch() {
    final p = _pinch;
    setState(() => _pinch = null);
    if (p == null) return;
    if (p.lock == Axis.vertical && _ppm != null) {
      _viewState.update((s) => s.copyWith(pxPerMinute: _ppm));
    } else if (p.lock == Axis.horizontal) {
      _viewState.update(
        (s) => _landscape ? s.copyWith(daysLandscape: _daysLandscape) : s.copyWith(daysPortrait: _daysPortrait),
      );
    }
    final pages = _pages;
    if (pages != null && pages.hasClients) {
      final target = pages.page?.round() ?? _page;
      unawaited(pages.animateToPage(target, duration: Motion.fast, curve: Motion.curve));
    }
  }

  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _toast = null);
    });
  }
}

/// One page (a week, or one day in day/free paging): header row, all-day lane and the body.
class _GridPage extends ConsumerWidget {
  const _GridPage({required this.grid, required this.index});

  final TimeGridState grid;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) => grid._buildPage(context, ref, index);
}
