/// Checklist Insights calculators ([6.4]): per-item flow (CL-I-*), per-checklist flow, CFD,
/// distributions, burn charts, blockers, tree health, due dates and runs (CL-L-*), and the Lists
/// section (CL-X-*).
///
/// Built on the status-interval primitives (T6.1.11). Stage order: created → todo → ongoing →
/// {waiting, blocked} → completed; WIP = ongoing + waiting + blocked; `cancelled` is terminal and
/// excluded from CT/LT, throughput and percentiles.
/// - start(i) = first transition from `todo` into ongoing/waiting/blocked (none when completed
///   directly from todo — "completed without start");
/// - done(i) = last transition into `completed` (only while the item is still completed);
/// - created(i) = the `created` event, or the row's `created_at`;
/// - CT = done − start; LT = done − created.
library;

import 'dart:math' as math;

import 'package:everslot_metrics/src/descriptive.dart';
import 'package:everslot_metrics/src/forecast.dart';
import 'package:everslot_metrics/src/min_data.dart';
import 'package:everslot_metrics/src/period.dart';
import 'package:everslot_metrics/src/rates.dart';
import 'package:everslot_metrics/src/stat.dart';
import 'package:everslot_metrics/src/status_intervals.dart';
import 'package:everslot_metrics/src/streaks.dart';
import 'package:everslot_metrics/src/time.dart';
import 'package:everslot_metrics/src/time_series.dart';
import 'package:everslot_metrics/src/trend.dart';
import 'package:meta/meta.dart';

/// `checklist_items.status`.
enum ItemStatus {
  todo,
  ongoing,
  waiting,
  blocked,
  completed,
  cancelled;

  bool get isWip => this == ongoing || this == waiting || this == blocked;

  bool get isOpen => this != completed && this != cancelled;

  static ItemStatus parse(String value) => ItemStatus.values.byName(value);
}

/// WIP statuses as strings (status-interval primitives work on strings).
const Set<String> wipStatusNames = {'ongoing', 'waiting', 'blocked'};

/// A `checklist_items` row (current state of the tree).
@immutable
final class const ChecklistItemRow(
  final String id, {
  required final String checklistId,
  required final ItemStatus status,
  required final DateTime createdAt,
  final String? parentId,
  final DateTime? completedAt,
  final DateTime? deletedAt,
  final DateTime? dueAt,
  final DateTime? followUpAt,
  final String? waitingOn,
  final String? statusNote,
  final String text = '',
});

/// Per-item fact (T6.4.01).
@immutable
final class ChecklistItemFact {
  const new(
    this.row, {
    required this.timeline,
    required this.depth,
    required this.isLeaf,
    required this.start,
    required this.done,
    required this.lastActivityAt,
  });

  final ChecklistItemRow row;
  final EntityTimeline timeline;
  final int depth;
  final bool isLeaf;

  /// First transition todo → ongoing/waiting/blocked.
  final DateTime? start;

  /// Last transition into completed (null unless currently completed).
  final DateTime? done;

  /// Latest status change, edit, attachment or child change.
  final DateTime lastActivityAt;

  String get id => row.id;
  String get checklistId => row.checklistId;
  DateTime get created => timeline.createdAt;
  ItemStatus get status => row.deletedAt != null ? ItemStatus.values.byName(timeline.currentStatus) : row.status;
  bool get isDeleted => row.deletedAt != null;
  bool get isCountable => row.status != ItemStatus.cancelled;

  int get reopens => timeline.reopenCount();
  int get statusChanges => timeline.statusChangeCount;
  List<StatusInterval> get blockedEpisodes => timeline.episodes('blocked');
  List<StatusInterval> get waitingEpisodes => timeline.episodes('waiting');

  /// Completed without ever having started.
  bool get completedWithoutStart => done != null && start == null;
}

/// Parent → children map of live rows.
Map<String?, List<ChecklistItemRow>> childrenOf(Iterable<ChecklistItemRow> rows) {
  final result = <String?, List<ChecklistItemRow>>{};
  for (final r in rows) {
    if (r.deletedAt != null) continue;
    result.putIfAbsent(r.parentId, () => []).add(r);
  }
  return result;
}

/// Builds item facts from rows and the item event log. [extraActivity] adds edit/attachment/child
/// activity instants per item (used by staleness).
List<ChecklistItemFact> buildChecklistItemFacts(
  List<ChecklistItemRow> rows,
  List<StatusEvent> events, {
  Map<String, DateTime> extraActivity = const {},
}) {
  final timelines = buildTimelines(
    events,
    seeds: [
      for (final r in rows)
        EntitySeed(
          r.id,
          createdAt: r.createdAt,
          containerId: r.checklistId,
          deletedAt: r.deletedAt,
        ),
    ],
  );
  final byId = {for (final r in rows) r.id: r};
  final children = childrenOf(rows);
  int depthOf(ChecklistItemRow r) {
    var depth = 0;
    var parent = r.parentId;
    final seen = <String>{};
    while (parent != null && byId.containsKey(parent) && seen.add(parent)) {
      depth++;
      parent = byId[parent]!.parentId;
    }
    return depth;
  }

  return [
    for (final r in rows)
      () {
        final t = timelines[r.id]!;
        DateTime? start;
        for (final e in t.statusEvents) {
          if (e.from == 'todo' && wipStatusNames.contains(e.to)) {
            start = e.occurredAt;
            break;
          }
        }
        DateTime? done;
        if (t.currentStatus == 'completed') {
          for (final e in t.statusEvents) {
            if (e.to == 'completed') done = e.occurredAt;
          }
          done ??= r.completedAt;
        }
        var last = t.lastEventAt;
        final extra = extraActivity[r.id];
        if (extra != null && extra.isAfter(last)) last = extra;
        for (final c in children[r.id] ?? const <ChecklistItemRow>[]) {
          final ct = timelines[c.id]?.lastEventAt;
          if (ct != null && ct.isAfter(last)) last = ct;
        }
        return ChecklistItemFact(
          r,
          timeline: t,
          depth: depthOf(r),
          isLeaf: (children[r.id] ?? const []).isEmpty,
          start: start,
          done: done,
          lastActivityAt: last,
        );
      }(),
  ];
}

// ---------------------------------------------------------------------------------------------
// Per-item flow (T6.4.02, T6.4.03)
// ---------------------------------------------------------------------------------------------

/// CL-I-01 — Σ time per status until now (or deletion).
Map<ItemStatus, Duration> timeInStatus(ChecklistItemFact f, {required DateTime now}) => {
  for (final e in f.timeline.timeInStatus(now: now).entries)
    ItemStatus.parse(e.key): e.value,
};

/// CL-I-02 — cycle time CT = done − start.
Stat<Duration> cycleTime(ChecklistItemFact f) {
  if (f.done == null) return const NotApplicable<Duration>(Reasons.notDone);
  if (f.start == null) return const NotApplicable<Duration>(Reasons.notStarted);
  return Value<Duration>(f.done!.difference(f.start!));
}

/// CL-I-03 — lead time LT = done − created.
Stat<Duration> leadTimeOf(ChecklistItemFact f) {
  if (f.done == null) return const NotApplicable<Duration>(Reasons.notDone);
  return Value<Duration>(f.done!.difference(f.created));
}

/// Kind of age (CL-I-04).
enum ItemAgeKind { workItem, queue }

/// CL-I-04 — age: open and started → now − start (work-item age); open and not started →
/// now − created (queue age).
Stat<({Duration age, ItemAgeKind kind})> itemAge(ChecklistItemFact f, {required DateTime now}) {
  if (!f.status.isOpen || f.isDeleted) {
    return const NotApplicable<({Duration age, ItemAgeKind kind})>('closed');
  }
  final start = f.start;
  return Value((
    age: now.difference(start ?? f.created),
    kind: start == null ? ItemAgeKind.queue : ItemAgeKind.workItem,
  ));
}

/// CL-I-05 — staleness = now − last activity.
Duration staleness(ChecklistItemFact f, {required DateTime now}) =>
    now.difference(f.lastActivityAt);

/// CL-I-06 — subtree progress of an item (or of a whole list when `rootId` is null).
@immutable
final class const SubtreeProgress({
  required final Stat<double> leafBased,
  required final Stat<double> recursive,
  required final int descendants,
});

/// CL-I-06 — leaf-based = completed countable leaves ÷ countable leaves; recursive = mean of the
/// children's progress (a leaf is 1 when completed, else 0; cancelled children are skipped).
SubtreeProgress subtreeProgress(List<ChecklistItemRow> rows, {String? rootId}) {
  final children = childrenOf(rows);
  var leaves = 0;
  var doneLeaves = 0;
  var descendants = 0;
  void walk(String? id) {
    for (final c in children[id] ?? const <ChecklistItemRow>[]) {
      descendants++;
      final kids = children[c.id] ?? const <ChecklistItemRow>[];
      if (kids.isEmpty && c.status != ItemStatus.cancelled) {
        leaves++;
        if (c.status == ItemStatus.completed) doneLeaves++;
      }
      walk(c.id);
    }
  }

  double? recursive(String? id) {
    final kids = [
      for (final c in children[id] ?? const <ChecklistItemRow>[])
        if (c.status != ItemStatus.cancelled) c,
    ];
    if (kids.isEmpty) return null;
    var total = 0.0;
    for (final c in kids) {
      total += recursive(c.id) ?? (c.status == ItemStatus.completed ? 1 : 0);
    }
    return total / kids.length;
  }

  walk(rootId);
  final r = recursive(rootId);
  return SubtreeProgress(
    leafBased: rate(doneLeaves, leaves),
    recursive: r == null
        ? const NotApplicable<double>(Reasons.zeroDenominator)
        : Value<double>(r),
    descendants: descendants,
  );
}

/// CL-I-07 — status timeline segments (with notes).
List<StatusInterval> statusTimeline(ChecklistItemFact f) => f.timeline.intervals;

/// Episodes summary (CL-I-08, CL-I-09).
@immutable
final class const EpisodeSummary(
  final int count, {
  required final Duration total,
  required final List<String> reasons,
  required final Duration? currentAge,
});

EpisodeSummary _episodes(List<StatusInterval> episodes, DateTime now) {
  final open = episodes.where((e) => e.end == null).firstOrNull;
  return EpisodeSummary(
    episodes.length,
    total: episodes.fold(Duration.zero, (a, e) => a + e.lengthUntil(now)),
    reasons: [
      for (final e in episodes)
        if (e.note != null && e.note!.trim().isNotEmpty) e.note!,
    ],
    currentAge: open?.lengthUntil(now),
  );
}

/// CL-I-08 — blocked episodes: count, total blocked time, share of CT blocked, reasons.
({EpisodeSummary episodes, Stat<double> shareOfCycleTime}) blockedEpisodes(
  ChecklistItemFact f, {
  required DateTime now,
}) {
  final summary = _episodes(f.blockedEpisodes, now);
  final ct = cycleTime(f).valueOrNull;
  return (
    episodes: summary,
    shareOfCycleTime: ct == null
        ? const NotApplicable<double>(Reasons.notDone)
        : safeDivide(summary.total.inSeconds, ct.inSeconds),
  );
}

/// CL-I-09 — waiting episodes: count, total wait, current wait age and the follow-up overdue flag
/// (`follow_up_at` < now while waiting).
({EpisodeSummary episodes, bool followUpOverdue}) waitingEpisodes(
  ChecklistItemFact f, {
  required DateTime now,
}) {
  final summary = _episodes(f.waitingEpisodes, now);
  final follow = f.row.followUpAt;
  return (
    episodes: summary,
    followUpOverdue:
        f.status == ItemStatus.waiting && follow != null && follow.isBefore(now),
  );
}

/// CL-I-10 — flow efficiency = time in ongoing ÷ CT (within [start, done]).
Stat<double> flowEfficiency(ChecklistItemFact f) {
  final ct = cycleTime(f).valueOrNull;
  if (ct == null) return const NotApplicable<double>(Reasons.notDone);
  final ongoing = f.timeline.timeInStatus(now: f.done!, from: f.start, to: f.done)['ongoing'] ??
      Duration.zero;
  return safeDivide(ongoing.inSeconds, ct.inSeconds);
}

/// CL-I-11 — churn: status changes, reopens (completed → other) and ongoing↔waiting loops
/// (ongoing → waiting → ongoing round trips).
({int statusChanges, int reopens, int ongoingWaitingLoops}) churn(ChecklistItemFact f) {
  final events = f.timeline.statusEvents;
  var loops = 0;
  for (var i = 1; i < events.length; i++) {
    if (events[i - 1].from == 'ongoing' &&
        events[i - 1].to == 'waiting' &&
        events[i].from == 'waiting' &&
        events[i].to == 'ongoing') {
      loops++;
    }
  }
  return (statusChanges: events.length, reopens: f.reopens, ongoingWaitingLoops: loops);
}

/// CL-I-12 — time to first action = start − created (queue time).
Stat<Duration> timeToFirstAction(ChecklistItemFact f) {
  if (f.start == null) return const NotApplicable<Duration>(Reasons.notStarted);
  return Value<Duration>(f.start!.difference(f.created));
}

/// An attachment aggregate row (`attachments`).
@immutable
final class const AttachmentFact(
  final String ownerId, {
  required final int byteSize,
  required final String mimeType,
  final String? checklistId,
});

/// Attachment type bucket.
enum AttachmentKind { image, pdf, other }

AttachmentKind attachmentKindOf(String mime) {
  if (mime.startsWith('image/')) return AttachmentKind.image;
  if (mime == 'application/pdf') return AttachmentKind.pdf;
  return AttachmentKind.other;
}

/// CL-I-13 / CL-L-30 / CL-X-11 — count, total size and type mix of attachments.
({int count, int totalBytes, Map<AttachmentKind, int> byKind}) attachmentSummary(
  Iterable<AttachmentFact> attachments,
) {
  final byKind = {for (final k in AttachmentKind.values) k: 0};
  var count = 0;
  var bytes = 0;
  for (final a in attachments) {
    count++;
    bytes += a.byteSize;
    final k = attachmentKindOf(a.mimeType);
    byKind[k] = byKind[k]! + 1;
  }
  return (count: count, totalBytes: bytes, byKind: byKind);
}

/// CL-I-14 — edit activity: number of text edits and the last edit instant.
({int edits, DateTime? lastEdited}) editActivity(Iterable<DateTime> textEditInstants) {
  DateTime? last;
  var n = 0;
  for (final t in textEditInstants) {
    n++;
    if (last == null || t.isAfter(last)) last = t;
  }
  return (edits: n, lastEdited: last);
}

// ---------------------------------------------------------------------------------------------
// Checklist status, throughput, CFD (T6.4.04, T6.4.05)
// ---------------------------------------------------------------------------------------------

/// CL-L-01 — status mix: count per status (live items) and % done leaf-based and node-based
/// (countable = not cancelled).
({Map<ItemStatus, int> counts, Stat<double> doneLeafBased, Stat<double> doneNodeBased})
statusMix(List<ChecklistItemRow> rows) {
  final live = [for (final r in rows) if (r.deletedAt == null) r];
  final counts = {for (final s in ItemStatus.values) s: 0};
  for (final r in live) {
    counts[r.status] = counts[r.status]! + 1;
  }
  final countable = live.where((r) => r.status != ItemStatus.cancelled).toList();
  return (
    counts: counts,
    doneLeafBased: subtreeProgress(rows).leafBased,
    doneNodeBased: rate(
      countable.where((r) => r.status == ItemStatus.completed).length,
      countable.length,
    ),
  );
}

/// Day-end samples of one checklist (or of all lists when [checklistId] is null).
List<BoundaryCounts> dailyCounts(
  List<ChecklistItemFact> facts, {
  required DateRange range,
  required DayBoundaries bounds,
  String? checklistId,
  bool leavesOnly = false,
}) => boundaryCounts(
  [
    for (final f in facts)
      if (!leavesOnly || f.isLeaf) f.timeline,
  ],
  [for (final d in range.dates) bounds.endOf(d)],
  containerId: checklistId,
);

/// CL-L-02 — progress per day: F(d) ÷ (A(d) − cancelled(d)) (leaf-based with [leavesOnly]).
List<SeriesPoint<double?>> progressOverTime(
  List<ChecklistItemFact> facts, {
  required DateRange range,
  required DayBoundaries bounds,
  String? checklistId,
  bool leavesOnly = false,
}) {
  final counts = dailyCounts(
    facts,
    range: range,
    bounds: bounds,
    checklistId: checklistId,
    leavesOnly: leavesOnly,
  );
  final dates = range.dates.toList();
  return [
    for (var i = 0; i < counts.length; i++)
      SeriesPoint(
        dates[i],
        counts[i].arrived - counts[i].cancelled > 0
            ? counts[i].finished / (counts[i].arrived - counts[i].cancelled)
            : null,
      ),
  ];
}

/// Final completion instants (reopened then re-completed items count once, on the final day).
List<DateTime> completionInstants(
  Iterable<ChecklistItemFact> facts, {
  String? checklistId,
}) => [
  for (final f in facts)
    if (f.done != null && !f.isDeleted && (checklistId == null || f.checklistId == checklistId))
      f.done!,
];

/// CL-L-03 / CL-L-25 / CL-X-10 — completions per local day over [range] (exact counts).
List<SeriesPoint<double>> completionsPerDay(
  Iterable<ChecklistItemFact> facts, {
  required DateRange range,
  required DayBoundaries bounds,
  String? checklistId,
}) => bucketSum(
  [for (final t in completionInstants(facts, checklistId: checklistId)) (bounds.dateOf(t), 1)],
  from: range.start,
  to: range.end,
  granularity: Granularity.day,
);

/// CL-L-03 — throughput per week with a 4-week rolling mean.
({List<SeriesPoint<double>> weekly, List<double?> rolling4}) throughput(
  Iterable<ChecklistItemFact> facts, {
  required DateRange range,
  required DayBoundaries bounds,
  String? checklistId,
  Weekday weekStart = Weekday.monday,
}) {
  final weekly = bucketSum(
    [for (final t in completionInstants(facts, checklistId: checklistId)) (bounds.dateOf(t), 1)],
    from: range.start,
    to: range.end,
    granularity: Granularity.week,
    weekStart: weekStart,
  );
  return (weekly: weekly, rolling4: rollingMean([for (final p in weekly) p.value], 4));
}

/// CL-L-04 — WIP (ongoing + waiting + blocked) at each day end.
List<SeriesPoint<int>> wipPerDay(
  List<ChecklistItemFact> facts, {
  required DateRange range,
  required DayBoundaries bounds,
  String? checklistId,
}) {
  final counts = dailyCounts(facts, range: range, bounds: bounds, checklistId: checklistId);
  final dates = range.dates.toList();
  return [for (var i = 0; i < counts.length; i++) SeriesPoint(dates[i], counts[i].wip())];
}

/// Arrival instants into a list: creation in it, or the move into it (moved-in items arrive on the
/// move day).
List<DateTime> arrivalInstants(Iterable<ChecklistItemFact> facts, {String? checklistId}) => [
  for (final f in facts)
    for (final m in f.timeline.memberships)
      if (checklistId == null
          ? m == f.timeline.memberships.first
          : m.containerId == checklistId)
        m.start,
];

/// CL-L-05 / CL-X-02 — arrivals vs departures per week (created or moved in vs completed) and net
/// flow (arrivals − departures).
({
  List<SeriesPoint<double>> arrivals,
  List<SeriesPoint<double>> departures,
  List<SeriesPoint<double>> net,
})
arrivalsVsDepartures(
  Iterable<ChecklistItemFact> facts, {
  required DateRange range,
  required DayBoundaries bounds,
  String? checklistId,
  Weekday weekStart = Weekday.monday,
}) {
  final list = facts.toList();
  List<SeriesPoint<double>> weekly(List<DateTime> instants) => bucketSum(
    [for (final t in instants) (bounds.dateOf(t), 1)],
    from: range.start,
    to: range.end,
    granularity: Granularity.week,
    weekStart: weekStart,
  );
  final a = weekly(arrivalInstants(list, checklistId: checklistId));
  final d = weekly(completionInstants(list, checklistId: checklistId));
  return (
    arrivals: a,
    departures: d,
    net: [for (var i = 0; i < a.length; i++) SeriesPoint(a[i].bucket, a[i].value - d[i].value)],
  );
}

/// CL-L-06 / CL-X-03 — open items with staleness ≥ [staleDays] and the 10 oldest open items (by age).
({List<ChecklistItemFact> stale, List<(ChecklistItemFact, Duration)> oldest}) staleItems(
  Iterable<ChecklistItemFact> facts, {
  required DateTime now,
  int staleDays = 14,
  int oldestCount = 10,
}) {
  final open = [
    for (final f in facts)
      if (f.status.isOpen && !f.isDeleted) f,
  ];
  final oldest = [
    for (final f in open) (f, now.difference(f.created)),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  return (
    stale: [
      for (final f in open)
        if (staleness(f, now: now) >= Duration(days: staleDays)) f,
    ],
    oldest: oldest.take(oldestCount).toList(),
  );
}

/// One day of the cumulative flow diagram.
@immutable
final class const CfdDay(
  final LocalDate date, {
  required final Map<ItemStatus, int> bands,
  required final int arrived,
  required final int started,
  required final int finished,
});

/// CL-L-07 — cumulative flow diagram with annotations.
@immutable
final class const CumulativeFlow(
  final List<CfdDay> days, {
  required final int reopens,
}) {
  /// WIP at day index [i] (vertical distance between the lines).
  int wipAt(int i) =>
      (days[i].bands[ItemStatus.ongoing] ?? 0) +
      (days[i].bands[ItemStatus.waiting] ?? 0) +
      (days[i].bands[ItemStatus.blocked] ?? 0);

  /// Approximate CT at day [i] in days: d − d′ where d′ is the first day with S(d′) ≥ F(d).
  int? approxCycleTimeDays(int i) {
    final f = days[i].finished;
    if (f == 0) return null;
    for (var j = 0; j <= i; j++) {
      if (days[j].started >= f) return i - j;
    }
    return null;
  }

  /// Throughput = OLS slope of F over the last [window] days (items/day).
  Stat<double> throughputSlope({int window = 14}) {
    final tail = days.length <= window ? days : days.sublist(days.length - window);
    return ols(
      [for (var i = 0; i < tail.length; i++) i],
      [for (final d in tail) d.finished],
    ).map((r) => r.slope);
  }
}

/// CL-L-07 — exact CFD from the event log: state(i, d) = the `to` of the last status event at or
/// before d; items created after d or deleted by d are excluded. Bands (bottom → top): completed,
/// blocked, waiting, ongoing, todo; cancelled is included when [includeCancelled]. Reopens are
/// counted separately.
CumulativeFlow cumulativeFlow(
  List<ChecklistItemFact> facts, {
  required DateRange range,
  required DayBoundaries bounds,
  String? checklistId,
  bool includeCancelled = false,
}) {
  final counts = dailyCounts(facts, range: range, bounds: bounds, checklistId: checklistId);
  final dates = range.dates.toList();
  final pStart = bounds.startOf(range.start);
  final pEnd = bounds.endOf(range.end);
  var reopens = 0;
  for (final f in facts) {
    if (checklistId != null && f.checklistId != checklistId) continue;
    reopens += f.timeline.statusEvents
        .where(
          (e) =>
              e.from == 'completed' &&
              e.to != 'completed' &&
              !e.occurredAt.isBefore(pStart) &&
              e.occurredAt.isBefore(pEnd),
        )
        .length;
  }
  return CumulativeFlow(
    [
      for (var i = 0; i < counts.length; i++)
        CfdDay(
          dates[i],
          bands: {
            for (final s in ItemStatus.values)
              if (s != ItemStatus.cancelled || includeCancelled) s: counts[i].byStatus[s.name] ?? 0,
          },
          arrived: counts[i].arrived,
          started: counts[i].started,
          finished: counts[i].finished,
        ),
    ],
    reopens: reopens,
  );
}

// ---------------------------------------------------------------------------------------------
// Cycle-time distribution, SLE, aging WIP (T6.4.06)
// ---------------------------------------------------------------------------------------------

/// CT unit rule: hours when the median CT is under 2 days, else days.
enum CycleTimeUnit { hours, days }

CycleTimeUnit cycleTimeUnitFor(Duration medianCt) =>
    medianCt < const Duration(days: 2) ? CycleTimeUnit.hours : CycleTimeUnit.days;

/// Inclusive local-day count between two instants (same day = 1).
int inclusiveDays(DateTime from, DateTime to, DayBoundaries bounds) =>
    bounds.dateOf(from).daysUntil(bounds.dateOf(to)) + 1;

/// CL-L-08 — CT distribution: CT values (hours), histogram, scatter points (completion instant,
/// CT) and P50/P70/P85/P95 lines (P85 hidden below 10 items, P95 below 20); items completed without
/// a start are excluded and counted.
@immutable
final class const CycleTimeDistribution(
  final List<double> hours, {
  required final Histogram histogram,
  required final List<(DateTime, double)> scatter,
  required final Stat<double> p50,
  required final Stat<double> p70,
  required final Stat<double> p85,
  required final Stat<double> p95,
  required final int completedWithoutStart,
});

CycleTimeDistribution cycleTimeDistribution(
  Iterable<ChecklistItemFact> facts, {
  DateTime? completedFrom,
  DateTime? completedTo,
}) {
  final hours = <double>[];
  final scatter = <(DateTime, double)>[];
  var withoutStart = 0;
  for (final f in facts) {
    final done = f.done;
    if (done == null || f.isDeleted) continue;
    if (completedFrom != null && done.isBefore(completedFrom)) continue;
    if (completedTo != null && !done.isBefore(completedTo)) continue;
    if (f.start == null) {
      withoutStart++;
      continue;
    }
    final h = done.difference(f.start!).inSeconds / 3600;
    hours.add(h);
    scatter.add((done, h));
  }
  return CycleTimeDistribution(
    hours,
    histogram: histogramFreedmanDiaconis(hours),
    scatter: scatter,
    p50: MinDataRules.meanOrMedian.apply(p50(hours)),
    p70: MinDataRules.meanOrMedian.apply(p70(hours)),
    p85: MinDataRules.p85.apply(p85(hours)),
    p95: MinDataRules.p95.apply(p95(hours)),
    completedWithoutStart: withoutStart,
  );
}

/// CL-L-09 — service-level expectation: "85 % of items finish within X" with X = P85 CT (hours)
/// over the rolling 90 days before [now].
Stat<double> serviceLevelExpectation(
  Iterable<ChecklistItemFact> facts, {
  required DateTime now,
  int days = 90,
}) => cycleTimeDistribution(
  facts,
  completedFrom: now.subtract(Duration(days: days)),
  completedTo: now,
).p85;

/// CL-L-10 — aging WIP point.
@immutable
final class const AgingWipPoint(
  final ChecklistItemFact item, {
  required final ItemStatus status,
  required final Duration age,
  required final bool atRisk,
});

/// CL-L-10 — each open started item at (status, age); "at risk" when older than the CT P85
/// ([p85Hours], e.g. from [cycleTimeDistribution]).
List<AgingWipPoint> agingWip(
  Iterable<ChecklistItemFact> facts, {
  required DateTime now,
  double? p85Hours,
}) => [
  for (final f in facts)
    if (f.status.isWip && !f.isDeleted && f.start != null)
      AgingWipPoint(
        f,
        status: f.status,
        age: now.difference(f.start!),
        atRisk: p85Hours != null && now.difference(f.start!).inSeconds / 3600 > p85Hours,
      ),
];

// ---------------------------------------------------------------------------------------------
// Burn charts & scope (T6.4.07)
// ---------------------------------------------------------------------------------------------

/// CL-L-11 / CL-L-12 — burn series per day.
@immutable
final class const BurnChart(
  final List<LocalDate> dates, {
  required final List<int> remaining,
  required final List<int> scope,
  required final List<int> done,
  required final List<int> removed,
  required final List<double>? ideal,
});

/// CL-L-11 — remaining(d) = A(d) − F(d) − cancelled(d), with an ideal line from the first day to
/// [due] when the checklist has a due date. CL-L-12 — scope(d) = A(d) − cancelled(d),
/// done(d) = F(d); deleted items are exposed as removed from scope.
BurnChart burnChart(
  List<ChecklistItemFact> facts, {
  required DateRange range,
  required DayBoundaries bounds,
  String? checklistId,
  LocalDate? due,
}) {
  final counts = dailyCounts(facts, range: range, bounds: bounds, checklistId: checklistId);
  final dates = range.dates.toList();
  final remaining = [for (final c in counts) c.arrived - c.finished - c.cancelled];
  List<double>? ideal;
  if (due != null && remaining.isNotEmpty) {
    final totalDays = range.start.daysUntil(due);
    double idealAt(LocalDate d) => totalDays <= 0
        ? 0
        : math.max(0, remaining.first * (1 - range.start.daysUntil(d) / totalDays)).toDouble();
    ideal = dates.map(idealAt).toList();
  }
  return BurnChart(
    dates,
    remaining: remaining,
    scope: [for (final c in counts) c.arrived - c.cancelled],
    done: [for (final c in counts) c.finished],
    removed: [for (final c in counts) c.removed],
    ideal: ideal,
  );
}

/// CL-L-12 — scope creep = items added after the baseline ÷ items at baseline (baseline = the
/// first status change, or a user-set start).
Stat<double> scopeCreep(
  Iterable<ChecklistItemFact> facts, {
  DateTime? baseline,
  String? checklistId,
}) {
  final list = [
    for (final f in facts)
      if (checklistId == null || f.checklistId == checklistId) f,
  ];
  var base = baseline;
  if (base == null) {
    for (final f in list) {
      for (final e in f.timeline.statusEvents) {
        if (base == null || e.occurredAt.isBefore(base)) base = e.occurredAt;
      }
    }
  }
  if (base == null) return const NotApplicable<double>(Reasons.noData);
  final arrivals = arrivalInstants(list, checklistId: checklistId);
  final atBaseline = arrivals.where((t) => !t.isAfter(base!)).length;
  final added = arrivals.where((t) => t.isAfter(base!)).length;
  return safeDivide(added, atBaseline);
}

/// CL-L-13 — cancelled share (cancelled ÷ total created) and shortcut share ("completed without
/// start" ÷ completed).
({Stat<double> cancelledShare, Stat<double> shortcutShare}) cancelledAndShortcut(
  Iterable<ChecklistItemFact> facts,
) {
  final list = [for (final f in facts) if (!f.isDeleted) f];
  final completed = list.where((f) => f.done != null).toList();
  return (
    cancelledShare: rate(list.where((f) => f.status == ItemStatus.cancelled).length, list.length),
    shortcutShare: rate(completed.where((f) => f.completedWithoutStart).length, completed.length),
  );
}

// ---------------------------------------------------------------------------------------------
// Blocked & waiting analytics (T6.4.08)
// ---------------------------------------------------------------------------------------------

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

final RegExp _waitingPhrases = RegExp(
  r"(?:waiting\s+(?:for|on)\s+|en\s+attente\s+(?:de\s+|d')|بانتظار\s+)([^\s,.;:!?]+)",
  caseSensitive: false,
  unicode: true,
);
final RegExp _atName = RegExp(r'^@([^\s,.;:!?]+)', unicode: true);
final RegExp _colonName = RegExp(r'^([^\s:@]+):', unicode: true);

/// Waiting-for entity (lowercase key) from the explicit `waiting_on` field or the note: a leading
/// `@name`, `name:`, "waiting for X", "en attente de X" or "بانتظار X"; null = "Unspecified".
String? waitingForEntity({String? waitingOn, String? note}) {
  final explicit = waitingOn?.trim();
  if (explicit != null && explicit.isNotEmpty) return explicit.toLowerCase();
  final text = note?.trim();
  if (text == null || text.isEmpty) return null;
  final at = _atName.firstMatch(text);
  if (at != null) return at.group(1)!.toLowerCase();
  final phrase = _waitingPhrases.firstMatch(text);
  if (phrase != null) return phrase.group(1)!.toLowerCase();
  final colon = _colonName.firstMatch(text);
  if (colon != null) return colon.group(1)!.toLowerCase();
  return null;
}

/// Display name for a group: the first variant seen starting with an uppercase letter, else the key
/// capitalized.
String _displayFor(String key, Iterable<String> variants) {
  for (final v in variants) {
    if (v.toLowerCase() == key && v.isNotEmpty && v[0] != v[0].toLowerCase()) return v;
  }
  return _cap(key);
}

const Set<String> _stopwords = {
  // EN
  'a', 'an', 'the', 'on', 'for', 'of', 'to', 'by', 'with', 'from', 'and', 'or', 'is', 'are',
  'waiting', 'blocked', 'in', 'at', 'my', 'our', 'their',
  // FR
  'le', 'la', 'les', 'un', 'une', 'des', 'de', 'du', 'd', 'l', 'en', 'et', 'ou', 'par', 'pour',
  'avec', 'sur', 'attente', 'bloque', 'bloqué',
  // AR
  'في', 'من', 'على', 'إلى', 'عن', 'مع', 'بانتظار', 'و',
};

/// Normalizes a blocker/reason text for clustering (CL-L-26, CL-X-06): lowercase, trim, strip
/// punctuation, remove EN/FR/AR stopwords, light stemming (plural `s`/`es`/`x`, `ing`, `ed`).
String normalizeReason(String text) {
  final cleaned = text
      .toLowerCase()
      .replaceAll(RegExp(r"[^\p{L}\p{N}\s']", unicode: true), ' ')
      .replaceAll("'", ' ');
  final tokens = <String>[];
  for (final raw in cleaned.split(RegExp(r'\s+'))) {
    if (raw.isEmpty || _stopwords.contains(raw)) continue;
    var t = raw;
    if (t.length > 4 && t.endsWith('ing')) {
      t = t.substring(0, t.length - 3);
    } else if (t.length > 3 && t.endsWith('ed')) {
      t = t.substring(0, t.length - 2);
    } else if (t.length > 3 && t.endsWith('es')) {
      t = t.substring(0, t.length - 2);
    } else if (t.length > 2 && (t.endsWith('s') || t.endsWith('x'))) {
      t = t.substring(0, t.length - 1);
    }
    tokens.add(t);
  }
  return tokens.join(' ');
}

/// One reason group of a Pareto.
@immutable
final class const ReasonGroup(
  final String label, {
  required final int episodes,
  required final Duration total,
  required final List<String> itemIds,
});

List<ReasonGroup> _groupReasons(
  Iterable<(String? key, String? rawNote, Duration time, String itemId)> rows, {
  Map<String, String> merges = const {},
}) {
  final episodes = <String, int>{};
  final totals = <String, Duration>{};
  final items = <String, List<String>>{};
  final variants = <String, List<String>>{};
  for (final (rawKey, note, time, id) in rows) {
    final base = rawKey == null || rawKey.isEmpty ? '' : (merges[rawKey] ?? rawKey);
    episodes[base] = (episodes[base] ?? 0) + 1;
    totals[base] = (totals[base] ?? Duration.zero) + time;
    items.putIfAbsent(base, () => []).add(id);
    if (note != null) variants.putIfAbsent(base, () => []).add(note);
  }
  final groups = [
    for (final k in episodes.keys)
      if (k.isNotEmpty)
        ReasonGroup(
          merges.containsValue(k) ? k : _displayFor(k, variants[k] ?? const []),
          episodes: episodes[k]!,
          total: totals[k]!,
          itemIds: items[k]!,
        ),
  ]..sort((a, b) {
      final c = b.episodes.compareTo(a.episodes);
      return c != 0 ? c : b.total.compareTo(a.total);
    });
  if (episodes.containsKey('')) {
    groups.add(
      ReasonGroup(
        'Unspecified',
        episodes: episodes['']!,
        total: totals['']!,
        itemIds: items['']!,
      ),
    );
  }
  return groups;
}

/// CL-L-14 — blocked & waiting now: counts with ages, total blocked time in [from, to) and the top
/// reasons.
({
  int blocked,
  int waiting,
  List<(ChecklistItemFact, Duration)> ages,
  Duration blockedTimeInPeriod,
  List<ReasonGroup> topReasons,
})
blockedAndWaitingNow(
  Iterable<ChecklistItemFact> facts, {
  required DateTime now,
  required DateTime from,
  required DateTime to,
}) {
  final list = [for (final f in facts) if (!f.isDeleted) f];
  final current = [
    for (final f in list)
      if (f.status == ItemStatus.blocked || f.status == ItemStatus.waiting)
        (f, now.difference(f.timeline.intervals.last.start)),
  ];
  var blockedTime = Duration.zero;
  for (final f in list) {
    for (final e in f.blockedEpisodes) {
      blockedTime += e.overlap(from, to, now);
    }
  }
  return (
    blocked: list.where((f) => f.status == ItemStatus.blocked).length,
    waiting: list.where((f) => f.status == ItemStatus.waiting).length,
    ages: current,
    blockedTimeInPeriod: blockedTime,
    topReasons: reasonsPareto(list, now: now),
  );
}

/// CL-X-06 / CL-L-26 — Pareto of blocked and waiting reasons (normalized text), with episode count
/// and total time. [merges] maps normalized keys to user cluster names
/// (`user_settings.stats.blockerClusters`); [statuses] selects blocked and/or waiting episodes.
List<ReasonGroup> reasonsPareto(
  Iterable<ChecklistItemFact> facts, {
  required DateTime now,
  Set<String> statuses = const {'blocked', 'waiting'},
  Map<String, String> merges = const {},
}) => _groupReasons(
  [
    for (final f in facts)
      for (final e in f.timeline.intervals)
        if (statuses.contains(e.status))
          (
            e.note == null ? null : normalizeReason(e.note!),
            e.note,
            e.lengthUntil(now),
            f.id,
          ),
  ],
  merges: merges,
);

/// CL-L-26 — blocker clusters ranked by episodes × total blocked time (Pareto).
List<ReasonGroup> blockerClusters(
  Iterable<ChecklistItemFact> facts, {
  required DateTime now,
  Map<String, String> merges = const {},
}) => reasonsPareto(facts, now: now, statuses: const {'blocked'}, merges: merges)
  ..sort(
    (a, b) => (b.episodes * b.total.inSeconds).compareTo(a.episodes * a.total.inSeconds),
  );

/// CL-L-15 — follow-up discipline among waiting/blocked episodes with `follow_up_at`: on time = an
/// activity on the item by follow-up + 24 h; overdue follow-ups = open items past `follow_up_at`
/// with no activity since.
({Stat<double> onTimeRate, List<ChecklistItemFact> overdue}) followUpDiscipline(
  Iterable<ChecklistItemFact> facts, {
  required DateTime now,
}) {
  var withFollowUp = 0;
  var onTime = 0;
  final overdue = <ChecklistItemFact>[];
  for (final f in facts) {
    final follow = f.row.followUpAt;
    if (follow == null || f.isDeleted) continue;
    final hadEpisode = f.timeline.intervals.any((i) => i.status == 'waiting' || i.status == 'blocked');
    if (!hadEpisode) continue;
    final deadline = follow.add(const Duration(hours: 24));
    final acted = f.timeline.statusEvents.any(
      (e) => !e.occurredAt.isBefore(follow) && !e.occurredAt.isAfter(deadline),
    ) || (!f.lastActivityAt.isBefore(follow) && !f.lastActivityAt.isAfter(deadline));
    if (!deadline.isAfter(now) || acted) {
      withFollowUp++;
      if (acted) onTime++;
    }
    if (f.status.isOpen && follow.isBefore(now) && f.lastActivityAt.isBefore(follow)) {
      overdue.add(f);
    }
  }
  return (onTimeRate: rate(onTime, withFollowUp), overdue: overdue);
}

/// CL-X-07 — waiting-for register row.
@immutable
final class const WaitingForEntry(
  final String entity, {
  required final int openCount,
  required final Duration meanWait,
  required final Duration? longestCurrentWait,
  required final int overdueFollowUps,
});

/// CL-X-07 — waiting episodes grouped by entity (explicit `waiting_on`, else parsed from the note;
/// case-insensitive; unrecognized → "Unspecified").
List<WaitingForEntry> waitingForRegister(
  Iterable<ChecklistItemFact> facts, {
  required DateTime now,
}) {
  final waits = <String, List<Duration>>{};
  final open = <String, int>{};
  final longest = <String, Duration>{};
  final overdue = <String, int>{};
  final variants = <String, List<String>>{};
  for (final f in facts) {
    if (f.isDeleted) continue;
    for (final e in f.waitingEpisodes) {
      final key = waitingForEntity(waitingOn: f.row.waitingOn, note: e.note) ?? '';
      waits.putIfAbsent(key, () => []).add(e.lengthUntil(now));
      final raw = f.row.waitingOn ?? e.note;
      if (raw != null) variants.putIfAbsent(key, () => []).addAll(raw.split(RegExp(r'[\s@:]+')));
      if (e.end == null) {
        open[key] = (open[key] ?? 0) + 1;
        final age = e.lengthUntil(now);
        if (longest[key] == null || age > longest[key]!) longest[key] = age;
        final follow = f.row.followUpAt;
        if (follow != null && follow.isBefore(now)) overdue[key] = (overdue[key] ?? 0) + 1;
      }
    }
  }
  final entries = [
    for (final k in waits.keys)
      WaitingForEntry(
        k.isEmpty ? 'Unspecified' : _displayFor(k, variants[k] ?? const []),
        openCount: open[k] ?? 0,
        meanWait: Duration(
          microseconds: waits[k]!.fold<int>(0, (a, d) => a + d.inMicroseconds) ~/ waits[k]!.length,
        ),
        longestCurrentWait: longest[k],
        overdueFollowUps: overdue[k] ?? 0,
      ),
  ]..sort((a, b) {
      if (a.entity == 'Unspecified') return 1;
      if (b.entity == 'Unspecified') return -1;
      return b.openCount.compareTo(a.openCount);
    });
  return entries;
}

/// CL-X-08 — lists ranked by total blocked time within [from, to).
List<({String checklistId, Duration blocked})> mostBlockedLists(
  Iterable<ChecklistItemFact> facts, {
  required DateTime now,
  required DateTime from,
  required DateTime to,
}) {
  final totals = <String, Duration>{};
  for (final f in facts) {
    for (final e in f.blockedEpisodes) {
      final t = e.overlap(from, to, now);
      if (t > Duration.zero) totals[f.checklistId] = (totals[f.checklistId] ?? Duration.zero) + t;
    }
  }
  return [
    for (final e in totals.entries) (checklistId: e.key, blocked: e.value),
  ]..sort((a, b) => b.blocked.compareTo(a.blocked));
}

// ---------------------------------------------------------------------------------------------
// Tree shape, integrity, branches, due dates (T6.4.09, T6.4.10)
// ---------------------------------------------------------------------------------------------

/// CL-L-16 — tree shape.
@immutable
final class const TreeShape({
  required final int maxDepth,
  required final double meanLeafDepth,
  required final double meanBranchingFactor,
  required final int leaves,
  required final int widestLevel,
  required final int widestLevelSize,
  required final int largestSubtree,
});

/// CL-L-16 — max depth (top level = 1), mean leaf depth, mean branching factor (children per
/// non-leaf), leaves, widest level and largest top-level subtree size.
TreeShape treeShape(List<ChecklistItemRow> rows) {
  final children = childrenOf(rows);
  final levelSizes = <int, int>{};
  final leafDepths = <int>[];
  var nonLeaves = 0;
  var childCount = 0;
  int size(String id) =>
      1 + (children[id] ?? const <ChecklistItemRow>[]).fold<int>(0, (a, c) => a + size(c.id));
  void walk(String? id, int depth) {
    for (final c in children[id] ?? const <ChecklistItemRow>[]) {
      levelSizes[depth] = (levelSizes[depth] ?? 0) + 1;
      final kids = children[c.id] ?? const <ChecklistItemRow>[];
      if (kids.isEmpty) {
        leafDepths.add(depth);
      } else {
        nonLeaves++;
        childCount += kids.length;
      }
      walk(c.id, depth + 1);
    }
  }

  walk(null, 1);
  var widest = 0;
  var widestSize = 0;
  for (final e in levelSizes.entries) {
    if (e.value > widestSize) {
      widest = e.key;
      widestSize = e.value;
    }
  }
  return TreeShape(
    maxDepth: levelSizes.keys.fold(0, math.max),
    meanLeafDepth: leafDepths.isEmpty ? 0 : sum(leafDepths) / leafDepths.length,
    meanBranchingFactor: nonLeaves == 0 ? 0 : childCount / nonLeaves,
    leaves: leafDepths.length,
    widestLevel: widest,
    widestLevelSize: widestSize,
    largestSubtree: (children[null] ?? const <ChecklistItemRow>[]).fold(
      0,
      (a, c) => math.max(a, size(c.id)),
    ),
  );
}

/// Kind of integrity problem (CL-L-17).
enum IntegrityFlag { completedParentWithOpenDescendants, allChildrenDoneParentOpen, missingReason }

/// CL-L-17 — integrity flags: completed parent with open descendants; all children completed but
/// the parent open; waiting/blocked without a reason when reasons are required.
List<(String itemId, IntegrityFlag flag)> integrityFlags(
  List<ChecklistItemRow> rows, {
  Set<ItemStatus> requireReasonFor = const {},
}) {
  final children = childrenOf(rows);
  bool hasOpenDescendant(String id) => (children[id] ?? const <ChecklistItemRow>[]).any(
    (c) => c.status.isOpen || hasOpenDescendant(c.id),
  );
  final flags = <(String, IntegrityFlag)>[];
  for (final r in rows) {
    if (r.deletedAt != null) continue;
    final kids = children[r.id] ?? const <ChecklistItemRow>[];
    if (r.status == ItemStatus.completed && hasOpenDescendant(r.id)) {
      flags.add((r.id, IntegrityFlag.completedParentWithOpenDescendants));
    }
    final countable = kids.where((c) => c.status != ItemStatus.cancelled).toList();
    if (r.status.isOpen &&
        countable.isNotEmpty &&
        countable.every((c) => c.status == ItemStatus.completed)) {
      flags.add((r.id, IntegrityFlag.allChildrenDoneParentOpen));
    }
    if (requireReasonFor.contains(r.status) &&
        (r.statusNote == null || r.statusNote!.trim().isEmpty)) {
      flags.add((r.id, IntegrityFlag.missingReason));
    }
  }
  return flags;
}

/// CL-L-18 — per top-level branch: progress (leaf-based), completions in [from, to) and blocked
/// time in that window.
Map<String, ({Stat<double> progress, int throughput, Duration blocked})> branchContribution(
  List<ChecklistItemRow> rows,
  List<ChecklistItemFact> facts, {
  required DateTime now,
  required DateTime from,
  required DateTime to,
}) {
  final children = childrenOf(rows);
  final factById = {for (final f in facts) f.id: f};
  List<String> subtree(String id) => [
    id,
    for (final c in children[id] ?? const <ChecklistItemRow>[]) ...subtree(c.id),
  ];
  return {
    for (final top in children[null] ?? const <ChecklistItemRow>[])
      top.id: () {
        final ids = subtree(top.id);
        var done = 0;
        var blocked = Duration.zero;
        for (final id in ids) {
          final f = factById[id];
          if (f == null) continue;
          final t = f.done;
          if (t != null && !t.isBefore(from) && t.isBefore(to)) done++;
          for (final e in f.blockedEpisodes) {
            blocked += e.overlap(from, to, now);
          }
        }
        final sub = subtreeProgress(rows, rootId: top.id);
        return (
          progress: sub.descendants == 0
              ? Value<double>(top.status == ItemStatus.completed ? 1 : 0)
              : sub.leafBased,
          throughput: done,
          blocked: blocked,
        );
      }(),
  };
}

/// CL-L-29 — % done per depth level (top level = 1; countable items).
Map<int, Stat<double>> depthLevelProgress(List<ChecklistItemFact> facts) {
  final done = <int, int>{};
  final total = <int, int>{};
  for (final f in facts) {
    if (f.isDeleted || !f.isCountable) continue;
    final level = f.depth + 1;
    total[level] = (total[level] ?? 0) + 1;
    if (f.row.status == ItemStatus.completed) done[level] = (done[level] ?? 0) + 1;
  }
  return {for (final l in total.keys) l: rate(done[l] ?? 0, total[l]!)};
}

/// CL-L-19 — due-date performance among items with a due instant (resolved from `due_local` with
/// the item's zone or as floating): on-time rate = completed with done ≤ due ÷ completed with a
/// due date; open overdue count and ages; mean days late.
({
  Stat<double> onTimeRate,
  List<(ChecklistItemFact, Duration)> openOverdue,
  Stat<double> meanDaysLate,
})
dueDatePerformance(Iterable<ChecklistItemFact> facts, {required DateTime now}) {
  var completedWithDue = 0;
  var onTime = 0;
  final late = <double>[];
  final overdue = <(ChecklistItemFact, Duration)>[];
  for (final f in facts) {
    final due = f.row.dueAt;
    if (due == null || f.isDeleted || f.status == ItemStatus.cancelled) continue;
    final done = f.done;
    if (done != null) {
      completedWithDue++;
      if (!done.isAfter(due)) {
        onTime++;
      } else {
        late.add(done.difference(due).inSeconds / 86400);
      }
    } else if (f.status.isOpen && due.isBefore(now)) {
      overdue.add((f, now.difference(due)));
    }
  }
  return (
    onTimeRate: rate(onTime, completedWithDue),
    openOverdue: overdue..sort((a, b) => b.$2.compareTo(a.$2)),
    meanDaysLate: mean(late),
  );
}

// ---------------------------------------------------------------------------------------------
// Recurring checklist runs (T6.4.11)
// ---------------------------------------------------------------------------------------------

/// One item in a run snapshot.
@immutable
final class const RunItemSnapshot(
  final String itemId, {
  required final ItemStatus status,
  final DateTime? completedAt,
});

/// A `checklist_runs` row.
@immutable
final class const ChecklistRunFact(
  final String occurrenceKey, {
  required final LocalDate date,
  required final DateTime startedAt,
  required final int totalItems,
  required final int completedItems,
  final DateTime? endedAt,
  final List<RunItemSnapshot> snapshot = const [],
}) {
  double get completion => totalItems == 0 ? 0 : completedItems / totalItems;

  bool get isComplete => totalItems > 0 && completedItems >= totalItems;
}

/// CL-L-20 — run completion per run and its mean over the runs given.
({List<(LocalDate, double)> perRun, Stat<double> mean}) runCompletion(
  List<ChecklistRunFact> runs,
) {
  final sorted = [...runs]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final values = [for (final r in sorted) if (r.totalItems > 0) r.completion];
  return (
    perRun: [for (final r in sorted) if (r.totalItems > 0) (r.date, r.completion)],
    mean: mean(values),
  );
}

/// CL-L-21 — streak of fully-completed runs (streak engine, unit = run).
StreakSummary fullyCompletedRunStreak(List<ChecklistRunFact> runs) => computeStreaks([
  for (final r in runs)
    StreakUnit(
      r.occurrenceKey,
      start: r.date,
      end: r.date,
      kind: r.totalItems == 0
          ? StreakUnitKind.neutral
          : (r.isComplete ? StreakUnitKind.success : StreakUnitKind.breaks),
    ),
]);

/// CL-L-22 — time to finish a run (last completedAt − run start) for 100 % runs: median and P85
/// (minutes).
({List<double> minutes, Stat<double> median, Stat<double> p85}) timeToFinishRun(
  List<ChecklistRunFact> runs,
) {
  final minutes = <double>[];
  for (final r in runs) {
    if (!r.isComplete) continue;
    DateTime? last;
    for (final s in r.snapshot) {
      final t = s.completedAt;
      if (t != null && (last == null || t.isAfter(last))) last = t;
    }
    if (last != null) minutes.add(last.difference(r.startedAt).inSeconds / 60);
  }
  return (
    minutes: minutes,
    median: MinDataRules.meanOrMedian.apply(median(minutes)),
    p85: MinDataRules.p85.apply(p85(minutes)),
  );
}

/// CL-L-23 — items most often not completed at reset (count and share of runs they were part of).
List<({String itemId, int missed, double share})> mostSkippedItems(List<ChecklistRunFact> runs) {
  final missed = <String, int>{};
  final seen = <String, int>{};
  for (final r in runs) {
    for (final s in r.snapshot) {
      seen[s.itemId] = (seen[s.itemId] ?? 0) + 1;
      if (s.status != ItemStatus.completed && s.status != ItemStatus.cancelled) {
        missed[s.itemId] = (missed[s.itemId] ?? 0) + 1;
      }
    }
  }
  return [
    for (final e in missed.entries)
      (itemId: e.key, missed: e.value, share: e.value / seen[e.key]!),
  ]..sort((a, b) {
      final c = b.missed.compareTo(a.missed);
      return c != 0 ? c : a.itemId.compareTo(b.itemId);
    });
}

/// CL-L-24 — mean run completion per weekday.
Map<Weekday, Stat<double>> runCompletionByWeekday(List<ChecklistRunFact> runs) {
  final by = <Weekday, List<double>>{};
  for (final r in runs) {
    if (r.totalItems == 0) continue;
    by.putIfAbsent(r.date.weekday, () => []).add(r.completion);
  }
  return {for (final e in by.entries) e.key: mean(e.value)};
}

// ---------------------------------------------------------------------------------------------
// Section overview, benchmarks, calendars (T6.4.12, T6.4.13)
// ---------------------------------------------------------------------------------------------

/// A `checklists` row for the Lists section.
@immutable
final class const ChecklistRow(
  final String id, {
  required final DateTime createdAt,
  final DateTime? archivedAt,
  final bool isTemplate = false,
  final DateTime? deletedAt,
});

/// CL-X-01 — lists overview: total, active, archived and template checklists; stale lists = no
/// activity for ≥ [staleDays] days while holding open items.
({int total, int active, int archived, int templates, List<String> staleListIds}) listsOverview(
  List<ChecklistRow> lists,
  List<ChecklistItemFact> facts, {
  required DateTime now,
  int staleDays = 14,
}) {
  final live = [for (final l in lists) if (l.deletedAt == null) l];
  final lastActivity = <String, DateTime>{};
  final hasOpen = <String>{};
  for (final f in facts) {
    if (f.isDeleted) continue;
    final cur = lastActivity[f.checklistId];
    if (cur == null || f.lastActivityAt.isAfter(cur)) lastActivity[f.checklistId] = f.lastActivityAt;
    if (f.status.isOpen) hasOpen.add(f.checklistId);
  }
  final stale = [
    for (final l in live)
      if (l.archivedAt == null &&
          !l.isTemplate &&
          hasOpen.contains(l.id) &&
          now.difference(lastActivity[l.id] ?? l.createdAt) >= Duration(days: staleDays))
        l.id,
  ];
  return (
    total: live.length,
    active: live.where((l) => l.archivedAt == null && !l.isTemplate).length,
    archived: live.where((l) => l.archivedAt != null).length,
    templates: live.where((l) => l.isTemplate).length,
    staleListIds: stale,
  );
}

/// CL-X-03 — global WIP / blocked / waiting counts across lists (archived lists excluded) and the
/// 10 oldest open items.
({int wip, int blocked, int waiting, List<(ChecklistItemFact, Duration)> oldest}) globalWip(
  List<ChecklistItemFact> facts, {
  required DateTime now,
  Set<String> archivedListIds = const {},
}) {
  final live = [
    for (final f in facts)
      if (!f.isDeleted && !archivedListIds.contains(f.checklistId)) f,
  ];
  return (
    wip: live.where((f) => f.status.isWip).length,
    blocked: live.where((f) => f.status == ItemStatus.blocked).length,
    waiting: live.where((f) => f.status == ItemStatus.waiting).length,
    oldest: staleItems(live, now: now).oldest,
  );
}

/// CL-X-04 — items completed in [period] vs the previous range (archived lists included).
PeriodComparison itemsCompleted(
  Iterable<ChecklistItemFact> facts, {
  required InstantRange period,
  required InstantRange previous,
}) {
  final instants = completionInstants(facts);
  final cur = instants.where(period.contains).length;
  final prev = instants.where(previous.contains).length;
  return compareWithPrevious(Value<double>(cur.toDouble()), Value<double>(prev.toDouble()));
}

/// CL-X-05 — status counts across all lists (live items).
Map<ItemStatus, int> statusDistribution(Iterable<ChecklistItemFact> facts) {
  final counts = {for (final s in ItemStatus.values) s: 0};
  for (final f in facts) {
    if (f.isDeleted) continue;
    counts[f.row.status] = counts[f.row.status]! + 1;
  }
  return counts;
}

/// CL-X-09 — section-wide CT P50/P85 (hours) and the throughput trend slope per week.
({Stat<double> p50, Stat<double> p85, Stat<TrendResult> throughputTrend}) flowBenchmarks(
  List<ChecklistItemFact> facts, {
  required DateRange range,
  required DayBoundaries bounds,
  required math.Random random,
  Weekday weekStart = Weekday.monday,
}) {
  final ct = cycleTimeDistribution(facts);
  final weekly = throughput(facts, range: range, bounds: bounds, weekStart: weekStart).weekly;
  return (
    p50: ct.p50,
    p85: ct.p85,
    throughputTrend: trend([for (final p in weekly) p.value], bucketDays: 7, random: random),
  );
}

/// CL-X-10 / CL-L-25 — current streak of days with ≥ 1 completion (today open).
StreakSummary completionDayStreak(
  List<SeriesPoint<double>> completionsPerDay, {
  required LocalDate today,
}) => computeStreaks([
  for (final p in completionsPerDay)
    StreakUnit(
      p.bucket.toIso(),
      start: p.bucket,
      end: p.bucket,
      kind: p.value >= 1
          ? StreakUnitKind.success
          : (p.bucket == today ? StreakUnitKind.open : StreakUnitKind.breaks),
    ),
]);

/// CL-X-12 — checklists created and archived per month.
({List<SeriesPoint<double>> created, List<SeriesPoint<double>> archived}) listCreationTrend(
  List<ChecklistRow> lists, {
  required DateRange range,
  required DayBoundaries bounds,
}) => (
  created: bucketSum(
    [for (final l in lists) (bounds.dateOf(l.createdAt), 1)],
    from: range.start,
    to: range.end,
    granularity: Granularity.month,
  ),
  archived: bucketSum(
    [
      for (final l in lists)
        if (l.archivedAt != null) (bounds.dateOf(l.archivedAt!), 1),
    ],
    from: range.start,
    to: range.end,
    granularity: Granularity.month,
  ),
);

// ---------------------------------------------------------------------------------------------
// Advanced flow analytics (T6.4.14)
// ---------------------------------------------------------------------------------------------

/// Why the flow is flagged unstable (CL-L-27).
enum FlowInstability { littleRatio, arrivalDepartureRatio, risingWipAge }

/// CL-L-27 — Little's Law diagnostic (never used as a forecast): ratio = mean CT ÷ (mean WIP ÷
/// mean throughput), all in days; unstable when the ratio ∉ [0.7, 1.3], arrivals ÷ departures ∉
/// [0.8, 1.2], or the mean WIP age is rising (positive OLS slope with p < 0.05).
({Stat<double> ratio, Stat<double> arrivalDepartureRatio, List<FlowInstability> flags})
littlesLawDiagnostic({
  required List<double> cycleTimesDays,
  required List<double> dailyWip,
  required List<double> dailyThroughput,
  required int arrivals,
  required int departures,
  List<double> meanWipAgeByDay = const [],
}) {
  final ct = mean(cycleTimesDays).valueOrNull;
  final wip = mean(dailyWip).valueOrNull;
  final tp = mean(dailyThroughput).valueOrNull;
  final Stat<double> ratio;
  if (ct == null || wip == null || tp == null || tp == 0 || wip == 0) {
    ratio = const NotApplicable<double>(Reasons.noData);
  } else {
    ratio = Stat.ofDouble(ct / (wip / tp));
  }
  final ad = safeDivide(arrivals, departures);
  final flags = <FlowInstability>[];
  final r = ratio.valueOrNull;
  if (r != null && (r < 0.7 || r > 1.3)) flags.add(FlowInstability.littleRatio);
  final adv = ad.valueOrNull;
  if (adv != null && (adv < 0.8 || adv > 1.2)) flags.add(FlowInstability.arrivalDepartureRatio);
  if (meanWipAgeByDay.length >= 3) {
    final fit = ols(
      [for (var i = 0; i < meanWipAgeByDay.length; i++) i],
      meanWipAgeByDay,
    ).valueOrNull;
    if (fit != null && fit.slope > 0 && fit.pValue < 0.05) flags.add(FlowInstability.risingWipAge);
  }
  return (ratio: ratio, arrivalDepartureRatio: ad, flags: flags);
}

/// CL-L-28 — Monte Carlo forecast for the remaining items, resampling daily completions of the
/// last [historyDays] days (hidden until ≥ 30 days of history and ≥ 10 completions).
Stat<ForecastWhen> checklistForecast(
  List<ChecklistItemFact> facts, {
  required DateTime now,
  required DayBoundaries bounds,
  required math.Random random,
  String? checklistId,
  int historyDays = 42,
  int trials = monteCarloTrials,
}) {
  final today = bounds.dateOf(now);
  final from = today.minusDays(historyDays);
  final perDay = <LocalDate, int>{};
  for (final t in completionInstants(facts, checklistId: checklistId)) {
    final d = bounds.dateOf(t);
    perDay[d] = (perDay[d] ?? 0) + 1;
  }
  final remaining = facts
      .where(
        (f) =>
            !f.isDeleted &&
            f.status.isOpen &&
            (checklistId == null || f.checklistId == checklistId),
      )
      .length;
  return monteCarloWhen(
    pool: throughputPool(perDay, from: from, to: today.minusDays(1)),
    remaining: remaining,
    random: random,
    trials: trials,
  );
}
