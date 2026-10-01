import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/planner/application/planner_settings.dart';
import 'package:everslot/features/planner/data/planner_queries.dart';
import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/occurrence_resolver.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// A resolved viewer range.
@immutable
class ResolvedRange {
  const ResolvedRange({
    required this.items,
    required this.occurrences,
    required this.truncated,
    required this.dataVersion,
    required this.resolvedAt,
  });

  static final empty = ResolvedRange(
    items: const [],
    occurrences: const [],
    truncated: false,
    dataVersion: -1,
    resolvedAt: DateTime.utc(1970),
  );

  /// Contract items, sorted (stable instances for unchanged occurrences).
  final List<PlannerItem> items;
  final List<ResolvedOccurrence> occurrences;

  /// The hard cap was hit: the UI says "Too many occurrences to display — zoom in".
  final bool truncated;
  final int dataVersion;
  final DateTime resolvedAt;
}

/// Minimal changes between two emissions, by `(taskId, key)`.
@immutable
class OccurrenceDiff {
  const OccurrenceDiff({this.added = const [], this.removed = const [], this.changed = const []});

  final List<PlannerItem> added;
  final List<PlannerItem> removed;
  final List<PlannerItem> changed;

  bool get isEmpty => added.isEmpty && removed.isEmpty && changed.isEmpty;

  /// Task ids touched by the diff.
  Set<String> get taskIds => {
    for (final i in [...added, ...removed, ...changed]) i.taskId,
  };
}

OccurrenceDiff diffItems(List<PlannerItem> before, List<PlannerItem> after) {
  final old = {for (final i in before) i.key: i};
  final added = <PlannerItem>[];
  final changed = <PlannerItem>[];
  for (final i in after) {
    final o = old.remove(i.key);
    if (o == null) {
      added.add(i);
    } else if (o != i) {
      changed.add(i);
    }
  }
  return OccurrenceDiff(added: added, removed: old.values.toList(), changed: changed);
}

/// Reuses the previous instance of every unchanged item (renderers skip identical widgets).
List<PlannerItem> stabilize(List<PlannerItem> previous, List<PlannerItem> next) {
  if (previous.isEmpty) return next;
  final old = {for (final i in previous) i.key: i};
  return [
    for (final i in next)
      if (old[i.key] case final o? when o == i) o else i,
  ];
}

/// Range pre-filter + resolver + memoization + background execution (T3.2.02).
///
/// Results are cached per `(range, zone, dataVersion, minute)`; `dataVersion` changes on every
/// relevant Drift table update. Resolution runs in an isolate when more than
/// [isolateThreshold] occurrences are expected. [watch] re-emits on data changes, on explicit
/// [refresh] and (when [autoRefresh]) at the next status boundary (an occurrence starting,
/// ending or becoming missed), so `isCurrent`/`missed` stay fresh without polling.
class OccurrenceRangeService {
  OccurrenceRangeService({
    required this.queries,
    required this.resolver,
    required this.clock,
    required this.viewerZone,
    this.settings = PlannerSettings.defaults,
    this.isolateThreshold = 2000,
    this.useIsolate = true,
    this.autoRefresh = false,
    this.cacheSize = 24,
  });

  final PlannerQueries queries;
  final OccurrenceResolver resolver;
  final Clock clock;
  final String viewerZone;
  final PlannerSettings settings;
  final int isolateThreshold;
  final bool useIsolate;
  final bool autoRefresh;
  final int cacheSize;

  int _version = 0;
  int get dataVersion => _version;
  StreamSubscription<Object?>? _changesSub;
  final _versions = StreamController<int>.broadcast();
  final LinkedHashMap<String, ResolvedRange> _cache = LinkedHashMap();
  int isolateRuns = 0;
  int resolutions = 0;

  void _ensureListening() {
    _changesSub ??= queries.changes().listen((_) {
      _version++;
      _versions.add(_version);
    });
  }

  /// Forces a re-emission of every watcher (e.g. settings changed, app resumed).
  void refresh() {
    _version++;
    _versions.add(_version);
  }

  void dispose() {
    unawaited(_changesSub?.cancel());
    unawaited(_versions.close());
  }

  /// Resolution of `[from, to)` (viewer wall clock).
  ///
  /// One-shot callers always read fresh data. Watchers pass [useCache]: their cache key carries
  /// the data version, which advances (asynchronously) on every relevant table update and then
  /// re-triggers them — so a cached result is never served after the change was observed.
  Future<ResolvedRange> resolveRange(LocalDateTime from, LocalDateTime to, {bool useCache = false}) async {
    final now = clock.nowUtc();
    final minute = now.millisecondsSinceEpoch ~/ 60000;
    final key = '$from|$to|$viewerZone|$_version|$minute|${settings.hashCode}';
    if (useCache) {
      final cached = _cache.remove(key);
      if (cached != null) {
        _cache[key] = cached;
        return cached;
      }
    }
    final version = _version;
    final data = await queries.loadRange(from, to);
    final result = await _resolve(data, from, to, now);
    resolutions++;
    final items = [
      for (final o in result.occurrences)
        o.toPlannerItem(
          categoryColor: data.categoryColors[o.task.categoryId],
          categoryIcon: data.categoryIcons[o.task.categoryId],
        ),
    ];
    final range = ResolvedRange(
      items: List.unmodifiable(items),
      occurrences: result.occurrences,
      truncated: result.truncated,
      dataVersion: version,
      resolvedAt: now,
    );
    _cache[key] = range;
    while (_cache.length > cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    return range;
  }

  Future<ResolveResult> _resolve(RangeData data, LocalDateTime from, LocalDateTime to, DateTime now) {
    final offload =
        useIsolate &&
        resolver.zones is TzZoneResolver &&
        estimateOccurrenceCount(data.tasks, from, to) > isolateThreshold;
    if (!offload) {
      return Future.value(
        resolver.resolve(
          tasks: data.tasks,
          records: data.records,
          from: from,
          to: to,
          viewerZone: viewerZone,
          now: now,
          settings: settings.resolver,
        ),
      );
    }
    isolateRuns++;
    final request = ResolveRequest(data.tasks, data.records, from, to, viewerZone, now, settings.resolver);
    return Isolate.run(() => resolveInIsolate(request));
  }

  /// Items of the local days of [range], re-emitted on relevant changes.
  Stream<ResolvedRange> watch(DayRange range) => watchLocal(range.start.atStartOfDay, range.endExclusive.atStartOfDay);

  /// Like [watch] for an arbitrary wall-clock range.
  Stream<ResolvedRange> watchLocal(LocalDateTime from, LocalDateTime to) {
    _ensureListening();
    late StreamController<ResolvedRange> controller;
    StreamSubscription<int>? sub;
    Timer? boundary;
    var previous = const <PlannerItem>[];
    var first = true;
    var truncated = false;
    var running = false;
    var pending = false;

    Future<void> emit() async {
      if (running) {
        pending = true;
        return;
      }
      running = true;
      try {
        do {
          pending = false;
          final result = await resolveRange(from, to, useCache: true);
          if (controller.isClosed) return;
          final stable = stabilize(previous, result.items);
          final changed =
              first ||
              previous.length != stable.length ||
              !_sameInstances(previous, stable) ||
              truncated != result.truncated;
          first = false;
          previous = stable;
          truncated = result.truncated;
          if (changed) {
            controller.add(
              ResolvedRange(
                items: stable,
                occurrences: result.occurrences,
                truncated: result.truncated,
                dataVersion: result.dataVersion,
                resolvedAt: result.resolvedAt,
              ),
            );
          }
          if (autoRefresh) {
            boundary?.cancel();
            final next = nextStatusBoundary(result.occurrences, clock.nowUtc(), settings.missedGraceMinutes);
            if (next != null) {
              boundary = Timer(next.difference(clock.nowUtc()) + const Duration(seconds: 1), () => unawaited(emit()));
            }
          }
        } while (pending && !controller.isClosed);
      } on Object catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      } finally {
        running = false;
      }
    }

    controller = StreamController<ResolvedRange>(
      onListen: () {
        sub = _versions.stream.listen((_) => unawaited(emit()));
        unawaited(emit());
      },
      onCancel: () async {
        boundary?.cancel();
        await sub?.cancel();
      },
    );
    return controller.stream;
  }

  static bool _sameInstances(List<PlannerItem> a, List<PlannerItem> b) {
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }
}

/// Next instant at which a derived status/flag changes (start, end, end + grace).
DateTime? nextStatusBoundary(List<ResolvedOccurrence> occurrences, DateTime now, int graceMinutes) {
  DateTime? best;
  void consider(DateTime t) {
    if (t.isAfter(now) && (best == null || t.isBefore(best!))) best = t;
  }

  for (final o in occurrences) {
    if (o.status != OccurrenceStatus.scheduled && o.status != OccurrenceStatus.inProgress) continue;
    consider(o.startInstant);
    consider(o.endInstant);
    consider(o.dueEnd.add(Duration(minutes: graceMinutes)));
  }
  return best;
}

/// Isolate payload (plain immutable domain objects).
class ResolveRequest {
  const ResolveRequest(this.tasks, this.records, this.from, this.to, this.zone, this.now, this.settings);

  final List<Task> tasks;
  final List<TaskOccurrenceRecord> records;
  final LocalDateTime from;
  final LocalDateTime to;
  final String zone;
  final DateTime now;
  final ResolverSettings settings;
}

bool _tzReady = false;

/// Isolate entry point of the resolver (initializes the tz database once per isolate).
ResolveResult resolveInIsolate(ResolveRequest r) {
  if (!_tzReady) {
    tzdata.initializeTimeZones();
    _tzReady = true;
  }
  return OccurrenceResolver(RecurrenceEngine(TzZoneResolver())).resolve(
    tasks: r.tasks,
    records: r.records,
    from: r.from,
    to: r.to,
    viewerZone: r.zone,
    now: r.now,
    settings: r.settings,
  );
}
