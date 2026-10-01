import 'package:collection/collection.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Offset;

/// Implemented by the grid state (and other date-paged views) to receive navigation commands.
abstract interface class GridNavigator {
  Future<void> jumpToDate(LocalDate date, {bool animate = true, double? minute, double anchorFraction = 0});

  Future<void> step(int pages);

  void scrollToMinute(double minute, {bool animate = true, double anchorFraction = 0});

  void zoomBy(double factor);
}

/// Where a view takes an external drop (backlog drawer, T3.7.02): the slot start under a global
/// point and whether it is the all-day lane.
abstract interface class DropSlotSource {
  ({LocalDateTime start, bool allDay})? dropSlotAt(Offset global);
}

/// Host-side handle of a date-paged view (T3.4.01 / T3.4.04): visible days for the title, and
/// Today / previous / next / jump commands.
class PlannerGridController extends ChangeNotifier {
  GridNavigator? _navigator;
  List<LocalDate> _visibleDays = const [];

  List<LocalDate> get visibleDays => _visibleDays;
  LocalDate? get firstVisibleDay => _visibleDays.firstOrNull;
  bool get isAttached => _navigator != null;

  // ignore: use_setters_to_change_properties
  void attach(GridNavigator navigator) => _navigator = navigator;

  void detach(GridNavigator navigator) {
    if (identical(_navigator, navigator)) _navigator = null;
  }

  void updateVisibleDays(List<LocalDate> days) {
    if (const ListEquality<LocalDate>().equals(days, _visibleDays)) return;
    _visibleDays = List.unmodifiable(days);
    notifyListeners();
  }

  /// Shows [date]; with [minute], scrolls so it sits at [anchorFraction] of the viewport.
  Future<void> jumpTo(LocalDate date, {bool animate = true, double? minute, double anchorFraction = 0}) async =>
      _navigator?.jumpToDate(date, animate: animate, minute: minute, anchorFraction: anchorFraction);

  Future<void> next() async => _navigator?.step(1);

  Future<void> previous() async => _navigator?.step(-1);

  void scrollToMinute(double minute, {bool animate = true, double anchorFraction = 0}) =>
      _navigator?.scrollToMinute(minute, animate: animate, anchorFraction: anchorFraction);

  void zoomBy(double factor) => _navigator?.zoomBy(factor);
}
