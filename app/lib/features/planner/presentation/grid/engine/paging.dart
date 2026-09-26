import 'package:everslot/features/planner/domain/view_config/planner_view_config.dart' show PagingMode;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

export 'package:everslot/features/planner/domain/view_config/planner_view_config.dart' show PagingMode;

/// Pure date ↔ page mapping for the horizontal pager (T3.3.13).
///
/// - *week* paging: a page is one week (or two when 14 days are visible) starting on [weekStart],
///   filtered to the [visibleWeekdays];
/// - *day* / *free* paging: a page is one day column; the viewport shows [daysVisible] pages
///   (`viewportFraction = 1 / daysVisible`), stepping one (visible) day at a time.
@immutable
class PagingModel {
  PagingModel({
    required this.mode,
    required this.anchor,
    required this.weekStart,
    required this.daysVisible,
    Set<Weekday>? visibleWeekdays,
  }) : visibleWeekdays = (visibleWeekdays == null || visibleWeekdays.isEmpty)
           ? Weekday.values.toSet()
           : visibleWeekdays,
       _visibleOffsets = _offsets(weekStart, visibleWeekdays);

  static const baseIndex = 10000;
  static const pageCount = baseIndex * 2;

  final PagingMode mode;
  final LocalDate anchor;
  final Weekday weekStart;
  final int daysVisible;
  final Set<Weekday> visibleWeekdays;
  final List<int> _visibleOffsets;

  static List<int> _offsets(Weekday weekStart, Set<Weekday>? visible) {
    final all = (visible == null || visible.isEmpty) ? Weekday.values.toSet() : visible;
    return [
      for (final w in Weekday.ordered(weekStart))
        if (all.contains(w)) w.offsetFrom(weekStart),
    ];
  }

  int get visiblePerWeek => _visibleOffsets.length;

  /// Week pages when the viewport shows at least a full (visible) week.
  bool get isWeekPaging => mode == PagingMode.week && daysVisible >= visiblePerWeek;

  int get weeksPerPage => isWeekPaging ? (daysVisible > 7 ? 2 : 1) : 1;

  int get daysPerPage => isWeekPaging ? visiblePerWeek * weeksPerPage : 1;

  /// Columns on screen.
  int get columnsOnScreen => isWeekPaging ? daysPerPage : daysVisible;

  double get viewportFraction => isWeekPaging ? 1 : 1 / daysVisible;

  LocalDate get _anchorWeek => anchor.startOfWeek(weekStart);

  /// Position of [date] in the visible-day sequence relative to the anchor week start
  /// (hidden days map to the next visible day).
  int _sequenceOf(LocalDate date) {
    final week = date.startOfWeek(weekStart);
    final weeks = _anchorWeek.daysUntil(week) ~/ 7;
    final offset = date.weekday.offsetFrom(weekStart);
    var pos = _visibleOffsets.indexWhere((o) => o >= offset);
    var w = weeks;
    if (pos == -1) {
      pos = 0;
      w += 1;
    }
    return w * visiblePerWeek + pos;
  }

  LocalDate _dateAtSequence(int g) {
    final n = visiblePerWeek;
    final weeks = g >= 0 ? g ~/ n : -((-g + n - 1) ~/ n);
    final r = g - weeks * n;
    return _anchorWeek.plusDays(weeks * 7 + _visibleOffsets[r]);
  }

  /// Days of page [index] (visible days only).
  List<LocalDate> daysOfPage(int index) {
    if (isWeekPaging) {
      final start = _anchorWeek.plusDays((index - baseIndex) * 7 * weeksPerPage);
      return [
        for (var w = 0; w < weeksPerPage; w++)
          for (final o in _visibleOffsets) start.plusDays(w * 7 + o),
      ];
    }
    return [_dateAtSequence(_sequenceOf(anchor) + (index - baseIndex))];
  }

  LocalDate firstDayOfPage(int index) => daysOfPage(index).first;

  /// Page showing [date] (for week paging: the page containing it; for day paging: the page whose
  /// column is [date], or the next visible day).
  int pageOf(LocalDate date) {
    if (isWeekPaging) {
      final weeks = _anchorWeek.daysUntil(date.startOfWeek(weekStart)) ~/ 7;
      final pages = weeks >= 0 ? weeks ~/ weeksPerPage : -((-weeks + weeksPerPage - 1) ~/ weeksPerPage);
      return baseIndex + pages;
    }
    return baseIndex + _sequenceOf(date) - _sequenceOf(anchor);
  }

  /// Days visible on screen when the first visible page is [index].
  List<LocalDate> daysOnScreen(int index) => isWeekPaging
      ? daysOfPage(index)
      : [for (var i = 0; i < daysVisible; i++) daysOfPage(index + i).first];

  /// Range from the first to the last day of [pages] (inclusive).
  ({LocalDate start, int days}) spanOf(List<LocalDate> days) {
    final first = days.first;
    return (start: first, days: first.daysUntil(days.last) + 1);
  }

  PagingModel copyWith({PagingMode? mode, LocalDate? anchor, Weekday? weekStart, int? daysVisible, Set<Weekday>? visibleWeekdays}) =>
      PagingModel(
        mode: mode ?? this.mode,
        anchor: anchor ?? this.anchor,
        weekStart: weekStart ?? this.weekStart,
        daysVisible: daysVisible ?? this.daysVisible,
        visibleWeekdays: visibleWeekdays ?? this.visibleWeekdays,
      );

  @override
  bool operator ==(Object other) =>
      other is PagingModel &&
      other.mode == mode &&
      other.anchor == anchor &&
      other.weekStart == weekStart &&
      other.daysVisible == daysVisible &&
      other.visibleWeekdays.length == visibleWeekdays.length &&
      other.visibleWeekdays.containsAll(visibleWeekdays);

  @override
  int get hashCode => Object.hash(mode, anchor, weekStart, daysVisible, Object.hashAllUnordered(visibleWeekdays));
}
