import 'package:collection/collection.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/foundation.dart';

/// Implemented by the grid state (and other date-paged views) to receive navigation commands.
abstract interface class GridNavigator {
  Future<void> jumpToDate(LocalDate date, {bool animate = true, double? minute});

  Future<void> step(int pages);

  void scrollToMinute(double minute, {bool animate = true});

  void zoomBy(double factor);
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

  Future<void> jumpTo(LocalDate date, {bool animate = true, double? minute}) async =>
      _navigator?.jumpToDate(date, animate: animate, minute: minute);

  Future<void> next() async => _navigator?.step(1);

  Future<void> previous() async => _navigator?.step(-1);

  void scrollToMinute(double minute, {bool animate = true}) => _navigator?.scrollToMinute(minute, animate: animate);

  void zoomBy(double factor) => _navigator?.zoomBy(factor);
}
