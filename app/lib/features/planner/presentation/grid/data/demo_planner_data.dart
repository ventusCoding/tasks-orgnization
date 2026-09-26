import 'dart:math';

import 'package:everslot/design_system/tokens.dart';
import 'package:everslot/features/planner/application/planner_contract.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// DEV-ONLY demo data for the planner views (enabled with the `planner_demo` feature flag or from
/// the view menu in dev builds) so the screens are usable before the planner data layer lands.
/// Generated weeks are a pure function of the week; user actions are recorded as edits on top.
@immutable
class DemoPlannerState {
  const DemoPlannerState({this.edits = const {}, this.created = const [], this.backlog = _defaultBacklog, this.history = const []});

  /// Edited generated items by key (null = removed).
  final Map<String, PlannerItem?> edits;
  final List<PlannerItem> created;
  final List<PlannerItem> backlog;
  final List<DemoPlannerState> history;

  static const _defaultBacklog = <PlannerItem>[];

  DemoPlannerState push(DemoPlannerState next) => DemoPlannerState(
    edits: next.edits,
    created: next.created,
    backlog: next.backlog,
    history: [...history.length > 30 ? history.sublist(history.length - 30) : history, this],
  );
}

class DemoPlannerData {
  DemoPlannerData({required this.zone, required this.resolver});

  final String zone;
  final ZoneResolver resolver;

  static const _titles = [
    ('Gym', 'health'),
    ('Deep work', 'work'),
    ('Standup', 'work'),
    ('Email triage', 'work'),
    ('Read', 'study'),
    ('Lunch', 'personal'),
    ('Call mom', 'social'),
    ('Groceries', 'home'),
    ('Spanish lesson', 'study'),
    ('Code review', 'work'),
    ('Walk', 'health'),
    ('Plan week', 'personal'),
  ];

  static const _categoryColors = {
    'work': 0,
    'personal': 4,
    'health': 2,
    'study': 9,
    'home': 3,
    'social': 6,
  };

  PlannerItem make({
    required String id,
    required String title,
    required LocalDateTime start,
    required int minutes,
    String? category,
    OccurrenceStatus status = OccurrenceStatus.scheduled,
    bool allDay = false,
    int priority = 0,
    TrackingMode tracking = TrackingMode.check,
    bool recurring = false,
    String? location,
    String? icon,
  }) {
    final utc = resolver.resolve(start, zone).utc;
    return PlannerItem(
      taskId: id,
      seriesId: recurring ? 'series-$title' : id,
      occurrenceKey: start.toIso(),
      title: title,
      startLocal: start,
      durationMinutes: minutes,
      startUtc: utc,
      endUtc: utc.add(Duration(minutes: minutes)),
      status: status,
      allDay: allDay,
      color: category == null ? null : CategoryPalette.at(_categoryColors[category] ?? 0),
      categoryId: category == null ? null : 'demo-$category',
      priority: priority,
      trackingMode: tracking,
      isRecurring: recurring,
      location: location,
      icon: icon,
    );
  }

  /// Deterministic items of the week starting at [weekStart] (Monday-based seed).
  List<PlannerItem> week(LocalDate weekStart, LocalDate today) {
    final rnd = Random(weekStart.epochDay);
    final items = <PlannerItem>[];
    for (var d = 0; d < 7; d++) {
      final date = weekStart.plusDays(d);
      final past = date.isBefore(today);
      final weekend = date.weekday.isWeekend;
      // Recurring gym Mon/Wed/Fri 07:00.
      if (d.isEven && d < 6) {
        items.add(make(
          id: 'demo-gym-${date.toIso()}',
          title: 'Gym',
          start: date.atTime(LocalTime(7, 0)),
          minutes: 60,
          category: 'health',
          recurring: true,
          status: past ? OccurrenceStatus.done : OccurrenceStatus.scheduled,
          icon: 'fitness',
        ));
      }
      final count = weekend ? 2 + rnd.nextInt(2) : 4 + rnd.nextInt(4);
      for (var i = 0; i < count; i++) {
        final (title, cat) = _titles[rnd.nextInt(_titles.length)];
        final hour = 8 + rnd.nextInt(11);
        final minute = [0, 15, 30, 45][rnd.nextInt(4)];
        final minutes = [15, 30, 45, 60, 90, 120][rnd.nextInt(6)];
        final roll = rnd.nextDouble();
        final status = past
            ? (roll < 0.6 ? OccurrenceStatus.done : roll < 0.75 ? OccurrenceStatus.skipped : OccurrenceStatus.missed)
            : OccurrenceStatus.scheduled;
        items.add(make(
          id: 'demo-${date.toIso()}-$i',
          title: title,
          start: date.atTime(LocalTime(hour, minute)),
          minutes: minutes,
          category: cat,
          status: status,
          priority: rnd.nextInt(5),
          tracking: roll > 0.85 ? TrackingMode.timer : (roll > 0.7 ? TrackingMode.event : TrackingMode.check),
          location: cat == 'social' ? 'Café' : null,
        ));
      }
      if (rnd.nextDouble() < 0.25) {
        items.add(make(id: 'demo-allday-${date.toIso()}', title: 'Birthday', start: date.atStartOfDay, minutes: 1440, allDay: true, category: 'social'));
      }
    }
    // A 3-day trip in the middle of every 4th week.
    if (weekStart.epochDay ~/ 7 % 4 == 0) {
      items.add(make(id: 'demo-trip-${weekStart.toIso()}', title: 'Trip', start: weekStart.plusDays(2).atStartOfDay, minutes: 3 * 1440, allDay: true, category: 'personal'));
    }
    return items;
  }

  static List<PlannerItem> defaultBacklog(DemoPlannerData data, LocalDate today) => [
    for (final (i, (title, cat)) in _titles.take(6).indexed)
      data.make(
        id: 'demo-backlog-$i',
        title: '$title (backlog)',
        start: today.atTime(LocalTime(9, 0)),
        minutes: [30, 45, 60, 90, 25, 15][i],
        category: cat,
        priority: i % 5,
      ),
  ];
}

/// Items of [range] from generated weeks + [state] edits.
List<PlannerItem> demoItemsIn(DemoPlannerData data, DemoPlannerState state, DayRange range, LocalDate today) {
  final firstWeek = range.start.minusDays(1).startOfWeek(Weekday.monday);
  final result = <PlannerItem>[];
  for (var w = firstWeek; w.isBefore(range.endExclusive); w = w.plusDays(7)) {
    for (final item in data.week(w, today)) {
      final edited = state.edits.containsKey(item.key) ? state.edits[item.key] : item;
      if (edited != null && overlapsRange(edited, range)) result.add(edited);
    }
  }
  // Edited items moved into this range from other weeks.
  for (final e in state.edits.values) {
    if (e != null && overlapsRange(e, range) && !result.any((r) => r.key == e.key)) result.add(e);
  }
  for (final c in state.created) {
    if (overlapsRange(c, range)) result.add(c);
  }
  result.sort((a, b) => a.startLocal.compareTo(b.startLocal));
  return result;
}

/// Demo implementation of [PlannerActions] mutating the in-memory demo state.
class DemoPlannerActions implements PlannerActions {
  DemoPlannerActions(this.read, this.write, this.data);

  final DemoPlannerState Function() read;
  final void Function(DemoPlannerState) write;
  final DemoPlannerData data;
  var _seq = 0;

  void _apply(DemoPlannerState Function(DemoPlannerState s) f) {
    final s = read();
    write(s.push(f(s)));
  }

  bool _isCreated(DemoPlannerState s, PlannerItem item) => s.created.any((c) => c.key == item.key);

  DemoPlannerState _replace(DemoPlannerState s, PlannerItem item, PlannerItem next) => _isCreated(s, item)
      ? DemoPlannerState(edits: s.edits, created: [for (final c in s.created) c.key == item.key ? next : c], backlog: s.backlog)
      : DemoPlannerState(edits: {...s.edits, item.key: next}, created: s.created, backlog: s.backlog);

  @override
  Future<String?> createAt(LocalDateTime start, int durationMinutes, {String? title, bool allDay = false}) async {
    final id = 'demo-new-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
    final item = data.make(id: id, title: title ?? 'New task', start: start, minutes: durationMinutes, allDay: allDay, category: 'personal');
    _apply((s) => DemoPlannerState(edits: s.edits, created: [...s.created, item], backlog: s.backlog));
    return id;
  }

  @override
  Future<void> reschedule(
    PlannerItem item, {
    required LocalDateTime newStart,
    int? newDurationMinutes,
    bool? allDay,
    EditScope scope = EditScope.thisOccurrence,
  }) async {
    final utc = data.resolver.resolve(newStart, data.zone).utc;
    final next = copyItem(item, startLocal: newStart, durationMinutes: newDurationMinutes, allDay: allDay, startUtc: utc, isOverridden: true);
    _apply((s) => _replace(s, item, next));
  }

  @override
  Future<void> setStatus(PlannerItem item, OccurrenceStatus status, {String? skipReason}) async {
    _apply((s) => _replace(s, item, copyItem(item, status: status)));
  }

  @override
  Future<void> scheduleBacklogItem(PlannerItem item, LocalDateTime start, int durationMinutes) async {
    final scheduled = data.make(
      id: item.taskId,
      title: item.title.replaceAll(' (backlog)', ''),
      start: start,
      minutes: durationMinutes,
      category: item.categoryId?.replaceFirst('demo-', ''),
      priority: item.priority,
    );
    _apply((s) => DemoPlannerState(
      edits: s.edits,
      created: [...s.created, scheduled],
      backlog: [for (final b in s.backlog) if (b.key != item.key) b],
    ));
  }
}
