import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/view_config/day_window.dart';
import 'package:everslot/features/planner/domain/view_config/item_filter.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

export 'package:everslot/features/planner/domain/view_config/day_window.dart';
export 'package:everslot/features/planner/domain/view_config/item_filter.dart';

/// Horizontal paging of time-based views (arch §6.9 `ColumnsSpec.paging`).
enum PagingMode { week, day, free }

/// Default snap = min(slot, 15), clamped to 1–60 (T3.3.17).
int defaultSnapMinutes(int slotMinutes) => math.min(slotMinutes, 15).clamp(1, 60);

/// View types of arch §8.3.
enum PlannerViewType {
  weekTable('week_table'),
  dayList('day_list'),
  nDay('n_day'),
  weekList('week_list'),
  month('month'),
  multiWeek('multi_week'),
  quarter('quarter'),
  year('year'),
  agenda('agenda'),
  ribbon('ribbon'),
  timeline('timeline'),
  swimlanes('swimlanes'),
  loadHeatmap('load_heatmap'),
  kanban('kanban'),
  matrix('matrix'),
  radial('radial'),
  focus('focus'),
  routine('routine'),
  backlog('backlog'),
  freeSlots('free_slots'),
  table('table'),
  planVsActual('plan_vs_actual'),
  horizons('horizons'),
  countdown('countdown'),
  map('map');

  PlannerViewType(this.id);

  final String id;

  static PlannerViewType? tryParse(String? id) => values.firstWhereOrNull((t) => t.id == id);
}

enum ZoomMode { fixed, semantic }

enum RenderMode { auto, timeline, table }

enum ColorBy { category, priority, status, task }

enum Density { comfortable, compact }

enum OverlapStyle { columns, cascade }

/// Shared filter model of a view (arch §8.3 `filters`).
@immutable
class ViewFilters {
  const ViewFilters({
    this.categories = const [],
    this.tags = const [],
    this.priorities = const [],
    this.statuses = const [],
    this.trackingModes = const [],
    this.text,
  });

  factory ViewFilters.fromJson(Object? json) {
    if (json is! Map) return const ViewFilters();
    List<T> list<T>(Object? v) => v is List ? v.whereType<T>().toList() : <T>[];
    final text = json['text'];
    return ViewFilters(
      categories: list<String>(json['categories']),
      tags: list<String>(json['tags']),
      priorities: [for (final p in list<num>(json['priorities'])) p.toInt().clamp(0, 4)],
      statuses: list<String>(json['statuses']).where((s) => _status(s) != null).toList(),
      trackingModes: list<String>(json['trackingModes']).where((s) => _tracking(s) != null).toList(),
      text: text is String && text.isNotEmpty ? text : null,
    );
  }

  final List<String> categories;
  final List<String> tags;
  final List<int> priorities;
  final List<String> statuses;
  final List<String> trackingModes;
  final String? text;

  bool get isActive =>
      categories.isNotEmpty ||
      tags.isNotEmpty ||
      priorities.isNotEmpty ||
      statuses.isNotEmpty ||
      trackingModes.isNotEmpty ||
      (text?.isNotEmpty ?? false);

  int get activeCount =>
      (categories.isNotEmpty ? 1 : 0) +
      (tags.isNotEmpty ? 1 : 0) +
      (priorities.isNotEmpty ? 1 : 0) +
      (statuses.isNotEmpty ? 1 : 0) +
      (trackingModes.isNotEmpty ? 1 : 0) +
      ((text?.isNotEmpty ?? false) ? 1 : 0);

  Map<String, Object?> toJson() => {
    'categories': categories,
    'tags': tags,
    'priorities': priorities,
    'statuses': statuses,
    if (trackingModes.isNotEmpty) 'trackingModes': trackingModes,
    'text': text,
  };

  ViewFilters copyWith({
    List<String>? categories,
    List<String>? tags,
    List<int>? priorities,
    List<String>? statuses,
    List<String>? trackingModes,
    String? text,
    bool clearText = false,
  }) => ViewFilters(
    categories: categories ?? this.categories,
    tags: tags ?? this.tags,
    priorities: priorities ?? this.priorities,
    statuses: statuses ?? this.statuses,
    trackingModes: trackingModes ?? this.trackingModes,
    text: clearText ? null : (text ?? this.text),
  );

  static OccurrenceStatus? _status(String s) => OccurrenceStatus.values.firstWhereOrNull((e) => e.name == s);
  static TrackingMode? _tracking(String s) => TrackingMode.values.firstWhereOrNull((e) => e.name == s);

  ItemFilter toItemFilter({required bool showCompleted, required bool showCancelled}) => ItemFilter(
    showCompleted: showCompleted,
    showCancelled: showCancelled,
    categories: categories.toSet(),
    priorities: priorities.toSet(),
    statuses: {for (final s in statuses) ?_status(s)},
    trackingModes: {for (final s in trackingModes) ?_tracking(s)},
    text: text,
  );

  static const _eq = ListEquality<Object?>();

  @override
  bool operator ==(Object other) =>
      other is ViewFilters &&
      _eq.equals(other.categories, categories) &&
      _eq.equals(other.tags, tags) &&
      _eq.equals(other.priorities, priorities) &&
      _eq.equals(other.statuses, statuses) &&
      _eq.equals(other.trackingModes, trackingModes) &&
      other.text == text;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(categories),
    Object.hashAll(tags),
    Object.hashAll(priorities),
    Object.hashAll(statuses),
    Object.hashAll(trackingModes),
    text,
  );
}

/// Versioned view configuration (arch §8.3, T3.3.01). Unknown keys are preserved in [extra];
/// type-specific settings live in [options].
@immutable
class PlannerViewConfig {
  const PlannerViewConfig({
    required this.type,
    this.slotMinutes = 30,
    this.slotExtentPx = 48,
    this.zoomMode = ZoomMode.fixed,
    this.renderMode = RenderMode.auto,
    this.autoTableThresholdMinutes = 120,
    this.snapMinutes = 15,
    this.daysVisible = 7,
    this.firstDay = 'week_start',
    this.paging = PagingMode.week,
    this.dayWindow = DayWindow.full,
    this.showWeekends = true,
    this.showCompleted = true,
    this.showCancelled = false,
    this.hideEmptySlots = false,
    this.overlays = const {'habits': false, 'checklistDue': true, 'deviceCalendars': false},
    this.filters = const ViewFilters(),
    this.colorBy = ColorBy.category,
    this.density = Density.comfortable,
    this.daysVisibleLandscape = 7,
    this.laneCap = 2,
    this.overlapStyle = OverlapStyle.columns,
    this.dimPast = true,
    this.showWeekNumbers = false,
    this.extraTimeZones = const [],
    this.autoScrollToNow = true,
    this.maxChipsPerCell = 3,
    this.options = const {},
    this.extra = const {},
  });

  static const currentVersion = 1;
  static final _log = Logger('planner.view_config');

  /// Per-type defaults (T3.4.02: week table = 7 days × 30-min rows × 24 h, 48 px rows, fixed zoom,
  /// auto render mode with table from 120 min, snap 15, paging week).
  factory PlannerViewConfig.defaultsFor(PlannerViewType type) => switch (type) {
    PlannerViewType.weekTable => const PlannerViewConfig(type: PlannerViewType.weekTable),
    PlannerViewType.dayList => const PlannerViewConfig(
      type: PlannerViewType.dayList,
      slotExtentPx: 56,
      daysVisible: 1,
      daysVisibleLandscape: 1,
      paging: PagingMode.day,
      laneCap: 4,
      options: {'style': 'slots'},
    ),
    PlannerViewType.nDay => const PlannerViewConfig(
      type: PlannerViewType.nDay,
      daysVisible: 3,
      daysVisibleLandscape: 7,
      paging: PagingMode.day,
      firstDay: 'today',
      options: {'rolling': true},
    ),
    PlannerViewType.weekList => const PlannerViewConfig(
      type: PlannerViewType.weekList,
      slotMinutes: 1440,
      snapMinutes: 15,
    ),
    PlannerViewType.month => const PlannerViewConfig(
      type: PlannerViewType.month,
      slotMinutes: 1440,
      options: {'monthMode': 'titles', 'listBelow': false, 'swipe': 'vertical', 'tapAction': 'open_day'},
    ),
    PlannerViewType.multiWeek => const PlannerViewConfig(
      type: PlannerViewType.multiWeek,
      slotMinutes: 1440,
      options: {'weeks': 4},
    ),
    PlannerViewType.quarter => const PlannerViewConfig(
      type: PlannerViewType.quarter,
      slotMinutes: 1440,
      options: {'monthMode': 'dots'},
    ),
    PlannerViewType.year => const PlannerViewConfig(
      type: PlannerViewType.year,
      slotMinutes: 1440,
      options: {'heatMetric': 'planned'},
    ),
    PlannerViewType.agenda => const PlannerViewConfig(
      type: PlannerViewType.agenda,
      slotMinutes: 1440,
      options: {'showEmptyDays': false, 'showNotes': false, 'ticker': true},
    ),
    PlannerViewType.ribbon => const PlannerViewConfig(
      type: PlannerViewType.ribbon,
      daysVisible: 1,
      paging: PagingMode.day,
      options: {'scope': 'day'},
    ),
    PlannerViewType.timeline => const PlannerViewConfig(
      type: PlannerViewType.timeline,
      options: {'groupBy': 'task', 'scale': 'days'},
    ),
    PlannerViewType.swimlanes => const PlannerViewConfig(
      type: PlannerViewType.swimlanes,
      daysVisible: 1,
      paging: PagingMode.day,
      laneCap: 2,
      options: {'lanes': <String>[]},
    ),
    PlannerViewType.loadHeatmap => const PlannerViewConfig(
      type: PlannerViewType.loadHeatmap,
      options: {'weeks': 4, 'metric': 'planned'},
    ),
    PlannerViewType.kanban => const PlannerViewConfig(
      type: PlannerViewType.kanban,
      options: {'groupBy': 'status', 'rangeDays': 7},
    ),
    PlannerViewType.matrix => const PlannerViewConfig(
      type: PlannerViewType.matrix,
      options: {'importanceThreshold': 3, 'urgencyDays': 2},
    ),
    PlannerViewType.radial => const PlannerViewConfig(
      type: PlannerViewType.radial,
      options: {'hours': 24, 'zoomHours': 0},
    ),
    PlannerViewType.focus => const PlannerViewConfig(type: PlannerViewType.focus, options: {'keepScreenOn': false}),
    PlannerViewType.routine => const PlannerViewConfig(type: PlannerViewType.routine, options: {'autoAdvance': true}),
    PlannerViewType.backlog => const PlannerViewConfig(type: PlannerViewType.backlog, options: {'groupBy': 'none'}),
    PlannerViewType.freeSlots => const PlannerViewConfig(
      type: PlannerViewType.freeSlots,
      options: {'days': 7, 'minGap': 30, 'ignoreLowPriority': false},
    ),
    PlannerViewType.table => const PlannerViewConfig(
      type: PlannerViewType.table,
      options: {
        'rows': 'occurrences',
        'groupBy': 'none',
        'sortBy': 'start',
        'sortAsc': true,
        'rangeDays': 14,
        'columns': [
          'title',
          'date',
          'start',
          'end',
          'duration',
          'status',
          'category',
          'priority',
          'tracking',
          'recurrence',
        ],
      },
    ),
    PlannerViewType.planVsActual => const PlannerViewConfig(
      type: PlannerViewType.planVsActual,
      daysVisible: 1,
      paging: PagingMode.day,
    ),
    PlannerViewType.horizons => const PlannerViewConfig(type: PlannerViewType.horizons),
    PlannerViewType.countdown => const PlannerViewConfig(type: PlannerViewType.countdown, options: {'aheadDays': 365}),
    PlannerViewType.map => const PlannerViewConfig(type: PlannerViewType.map),
  };

  /// Parses and upgrades a stored config. Out-of-range values clamp (with a warning); unknown keys are
  /// kept in [extra].
  factory PlannerViewConfig.fromJson(Map<String, Object?> input, {PlannerViewType? fallbackType}) {
    final json = upgrade(input);
    final type = PlannerViewType.tryParse(json['type'] as String?) ?? fallbackType ?? PlannerViewType.weekTable;
    final d = PlannerViewConfig.defaultsFor(type);

    int intOf(String key, int fallback, int min, int max) {
      final v = json[key];
      if (v is! num) return fallback;
      final i = v.round();
      if (i < min || i > max) {
        _log.warning('view config: $key=$v clamped to [$min, $max]');
        return i.clamp(min, max);
      }
      return i;
    }

    double doubleOf(String key, double fallback, double min, double max) {
      final v = json[key];
      if (v is! num) return fallback;
      final x = v.toDouble();
      if (x < min || x > max || x.isNaN) {
        _log.warning('view config: $key=$v clamped to [$min, $max]');
        return x.isNaN ? fallback : x.clamp(min, max);
      }
      return x;
    }

    bool boolOf(String key, bool fallback) => json[key] is bool ? json[key]! as bool : fallback;

    T enumOf<T extends Enum>(String key, List<T> values, T fallback) =>
        values.firstWhereOrNull((e) => e.name == json[key]) ?? fallback;

    final slot = intOf('slotMinutes', d.slotMinutes, 1, 1440);
    final firstDay = json['firstDay'];
    final overlays = json['overlays'];
    final extraZones = json['extraTimeZones'];
    final options = json['options'];
    const knownKeys = _knownKeys;
    return PlannerViewConfig(
      type: type,
      slotMinutes: slot,
      slotExtentPx: doubleOf('slotExtentPx', d.slotExtentPx, 8, 400),
      zoomMode: enumOf('zoomMode', ZoomMode.values, d.zoomMode),
      renderMode: enumOf('renderMode', RenderMode.values, d.renderMode),
      autoTableThresholdMinutes: intOf('autoTableThresholdMinutes', d.autoTableThresholdMinutes, 1, 1440),
      snapMinutes: intOf(
        'snapMinutes',
        json.containsKey('snapMinutes') ? d.snapMinutes : defaultSnapMinutes(slot),
        1,
        60,
      ),
      daysVisible: intOf('daysVisible', d.daysVisible, 1, 14),
      firstDay: firstDay is String && _validFirstDay(firstDay) ? firstDay : d.firstDay,
      paging: enumOf('paging', PagingMode.values, d.paging),
      dayWindow: _windowFromJson(json['dayWindow']) ?? d.dayWindow,
      showWeekends: boolOf('showWeekends', d.showWeekends),
      showCompleted: boolOf('showCompleted', d.showCompleted),
      showCancelled: boolOf('showCancelled', d.showCancelled),
      hideEmptySlots: boolOf('hideEmptySlots', d.hideEmptySlots),
      overlays: overlays is Map
          ? {
              for (final e in overlays.entries)
                if (e.key is String && e.value is bool) e.key as String: e.value as bool,
            }
          : d.overlays,
      filters: ViewFilters.fromJson(json['filters']),
      colorBy: enumOf('colorBy', ColorBy.values, d.colorBy),
      density: enumOf('density', Density.values, d.density),
      daysVisibleLandscape: intOf('daysVisibleLandscape', d.daysVisibleLandscape, 1, 14),
      laneCap: intOf('laneCap', d.laneCap, 1, 8),
      overlapStyle: enumOf('overlapStyle', OverlapStyle.values, d.overlapStyle),
      dimPast: boolOf('dimPast', d.dimPast),
      showWeekNumbers: boolOf('showWeekNumbers', d.showWeekNumbers),
      extraTimeZones: extraZones is List ? extraZones.whereType<String>().take(3).toList() : d.extraTimeZones,
      autoScrollToNow: boolOf('autoScrollToNow', d.autoScrollToNow),
      maxChipsPerCell: intOf('maxChipsPerCell', d.maxChipsPerCell, 1, 20),
      options: options is Map ? {...d.options, ...Map<String, Object?>.from(options)} : d.options,
      extra: {
        for (final e in json.entries)
          if (!knownKeys.contains(e.key)) e.key: e.value,
      },
    );
  }

  /// Upgrades older JSON versions to v1. v0 (pre-release) used `slot`, `rowHeight`, `days` and
  /// `hours: [start, end]`.
  static Map<String, Object?> upgrade(Map<String, Object?> input) {
    final json = Map<String, Object?>.from(input);
    final v = (json['v'] as num?)?.toInt() ?? 0;
    if (v < 1) {
      void rename(String from, String to) {
        if (json.containsKey(from) && !json.containsKey(to)) json[to] = json.remove(from);
      }

      rename('slot', 'slotMinutes');
      rename('rowHeight', 'slotExtentPx');
      rename('days', 'daysVisible');
      final hours = json.remove('hours');
      if (hours is List && hours.length == 2 && hours.every((h) => h is num)) {
        json['dayWindow'] = {
          'start': _hhmm(((hours[0] as num) * 60).round()),
          'end': _hhmm(((hours[1] as num) * 60).round()),
        };
      }
      json['v'] = 1;
    }
    return json;
  }

  static const _knownKeys = {
    'v',
    'type',
    'slotMinutes',
    'slotExtentPx',
    'zoomMode',
    'renderMode',
    'autoTableThresholdMinutes',
    'snapMinutes',
    'daysVisible',
    'firstDay',
    'paging',
    'dayWindow',
    'showWeekends',
    'showCompleted',
    'showCancelled',
    'hideEmptySlots',
    'overlays',
    'filters',
    'colorBy',
    'density',
    'daysVisibleLandscape',
    'laneCap',
    'overlapStyle',
    'dimPast',
    'showWeekNumbers',
    'extraTimeZones',
    'autoScrollToNow',
    'maxChipsPerCell',
    'options',
  };

  static bool _validFirstDay(String s) =>
      s == 'week_start' || s == 'today' || const ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'].contains(s);

  static DayWindow? _windowFromJson(Object? json) {
    if (json is! Map) return null;
    final s = _parseHhmm(json['start']);
    final e = _parseHhmm(json['end']);
    if (s == null || e == null) return null;
    if (s >= e) {
      _log.warning('view config: dayWindow start >= end, using full day');
      return DayWindow.full;
    }
    return DayWindow(s, e);
  }

  static int? _parseHhmm(Object? v) {
    if (v is! String) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(v.trim());
    if (m == null) return null;
    final minutes = int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
    return minutes.clamp(0, 1440);
  }

  static String _hhmm(int minutes) {
    final m = minutes.clamp(0, 1440);
    return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  }

  final PlannerViewType type;
  final int slotMinutes;
  final double slotExtentPx;
  final ZoomMode zoomMode;
  final RenderMode renderMode;
  final int autoTableThresholdMinutes;
  final int snapMinutes;
  final int daysVisible;

  /// 'week_start' | 'today' | 'MO'…'SU'.
  final String firstDay;
  final PagingMode paging;
  final DayWindow dayWindow;
  final bool showWeekends;
  final bool showCompleted;
  final bool showCancelled;
  final bool hideEmptySlots;
  final Map<String, bool> overlays;
  final ViewFilters filters;
  final ColorBy colorBy;
  final Density density;
  final int daysVisibleLandscape;
  final int laneCap;
  final OverlapStyle overlapStyle;
  final bool dimPast;
  final bool showWeekNumbers;
  final List<String> extraTimeZones;
  final bool autoScrollToNow;
  final int maxChipsPerCell;
  final Map<String, Object?> options;

  /// Unknown top-level keys (written by newer app versions) — preserved on save.
  final Map<String, Object?> extra;

  double get pxPerMinute => slotExtentPx / slotMinutes;

  /// Effective renderer for the current slot size (T3.4.06).
  bool get usesTable => switch (renderMode) {
    RenderMode.table => true,
    RenderMode.timeline => false,
    RenderMode.auto => slotMinutes >= autoTableThresholdMinutes,
  };

  bool get isWeekListMode => usesTable && slotMinutes >= 1440;

  bool overlay(String key) => overlays[key] ?? false;

  T option<T>(String key, T fallback) {
    final v = options[key];
    if (v is T) return v;
    if (T == int && v is num) return v.toInt() as T;
    if (T == double && v is num) return v.toDouble() as T;
    return fallback;
  }

  ItemFilter get itemFilter => filters.toItemFilter(showCompleted: showCompleted, showCancelled: showCancelled);

  Map<String, Object?> toJson() => {
    ...extra,
    'v': currentVersion,
    'type': type.id,
    'slotMinutes': slotMinutes,
    'slotExtentPx': slotExtentPx,
    'zoomMode': zoomMode.name,
    'renderMode': renderMode.name,
    'autoTableThresholdMinutes': autoTableThresholdMinutes,
    'snapMinutes': snapMinutes,
    'daysVisible': daysVisible,
    'firstDay': firstDay,
    'paging': paging.name,
    'dayWindow': {'start': _hhmm(dayWindow.startMinute), 'end': _hhmm(dayWindow.endMinute)},
    'showWeekends': showWeekends,
    'showCompleted': showCompleted,
    'showCancelled': showCancelled,
    'hideEmptySlots': hideEmptySlots,
    'overlays': overlays,
    'filters': filters.toJson(),
    'colorBy': colorBy.name,
    'density': density.name,
    'daysVisibleLandscape': daysVisibleLandscape,
    'laneCap': laneCap,
    'overlapStyle': overlapStyle.name,
    'dimPast': dimPast,
    'showWeekNumbers': showWeekNumbers,
    'extraTimeZones': extraTimeZones,
    'autoScrollToNow': autoScrollToNow,
    'maxChipsPerCell': maxChipsPerCell,
    'options': options,
  };

  PlannerViewConfig copyWith({
    PlannerViewType? type,
    int? slotMinutes,
    double? slotExtentPx,
    ZoomMode? zoomMode,
    RenderMode? renderMode,
    int? autoTableThresholdMinutes,
    int? snapMinutes,
    int? daysVisible,
    String? firstDay,
    PagingMode? paging,
    DayWindow? dayWindow,
    bool? showWeekends,
    bool? showCompleted,
    bool? showCancelled,
    bool? hideEmptySlots,
    Map<String, bool>? overlays,
    ViewFilters? filters,
    ColorBy? colorBy,
    Density? density,
    int? daysVisibleLandscape,
    int? laneCap,
    OverlapStyle? overlapStyle,
    bool? dimPast,
    bool? showWeekNumbers,
    List<String>? extraTimeZones,
    bool? autoScrollToNow,
    int? maxChipsPerCell,
    Map<String, Object?>? options,
  }) => PlannerViewConfig(
    type: type ?? this.type,
    slotMinutes: (slotMinutes ?? this.slotMinutes).clamp(1, 1440),
    slotExtentPx: (slotExtentPx ?? this.slotExtentPx).clamp(8, 400),
    zoomMode: zoomMode ?? this.zoomMode,
    renderMode: renderMode ?? this.renderMode,
    autoTableThresholdMinutes: (autoTableThresholdMinutes ?? this.autoTableThresholdMinutes).clamp(1, 1440),
    snapMinutes: (snapMinutes ?? this.snapMinutes).clamp(1, 60),
    daysVisible: (daysVisible ?? this.daysVisible).clamp(1, 14),
    firstDay: firstDay ?? this.firstDay,
    paging: paging ?? this.paging,
    dayWindow: dayWindow ?? this.dayWindow,
    showWeekends: showWeekends ?? this.showWeekends,
    showCompleted: showCompleted ?? this.showCompleted,
    showCancelled: showCancelled ?? this.showCancelled,
    hideEmptySlots: hideEmptySlots ?? this.hideEmptySlots,
    overlays: overlays ?? this.overlays,
    filters: filters ?? this.filters,
    colorBy: colorBy ?? this.colorBy,
    density: density ?? this.density,
    daysVisibleLandscape: (daysVisibleLandscape ?? this.daysVisibleLandscape).clamp(1, 14),
    laneCap: (laneCap ?? this.laneCap).clamp(1, 8),
    overlapStyle: overlapStyle ?? this.overlapStyle,
    dimPast: dimPast ?? this.dimPast,
    showWeekNumbers: showWeekNumbers ?? this.showWeekNumbers,
    extraTimeZones: extraTimeZones == null ? this.extraTimeZones : extraTimeZones.take(3).toList(),
    autoScrollToNow: autoScrollToNow ?? this.autoScrollToNow,
    maxChipsPerCell: (maxChipsPerCell ?? this.maxChipsPerCell).clamp(1, 20),
    options: options ?? this.options,
    extra: extra,
  );

  /// Sets one option key.
  PlannerViewConfig withOption(String key, Object? value) => copyWith(options: {...options, key: value});

  /// Changes the slot size, keeping snap ≤ slot and the px/min when [keepPxPerMinute].
  PlannerViewConfig withSlot(int minutes, {bool keepPxPerMinute = false}) {
    final slot = minutes.clamp(1, 1440);
    final extent = keepPxPerMinute ? (pxPerMinute * slot).clamp(8.0, 400.0) : slotExtentPx;
    final wasDefault = snapMinutes == defaultSnapMinutes(slotMinutes);
    final snap = wasDefault ? defaultSnapMinutes(slot) : math.min(snapMinutes, math.max(1, math.min(slot, 60)));
    return copyWith(slotMinutes: slot, slotExtentPx: extent, snapMinutes: snap);
  }

  static const _deep = DeepCollectionEquality();

  @override
  bool operator ==(Object other) => other is PlannerViewConfig && _deep.equals(other.toJson(), toJson());

  @override
  int get hashCode => _deep.hash(toJson());
}
