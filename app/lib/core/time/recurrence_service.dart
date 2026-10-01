import 'dart:collection';
import 'dart:isolate';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// App-side facade over `everslot_recurrence` (T2.1.14).
///
/// Injects the [Clock], the user's current zone (floating rules), week start and day start.
/// Range expansion is memoized (LRU by rule + anchor + range + zone) and offloaded to an isolate
/// when more than [isolateThreshold] occurrences are expected. Planner, Habits, checklist resets
/// and the notification planner use only this facade. A new instance is built whenever the
/// device zone or the preferences change (see [recurrenceServiceProvider]), which drops the
/// cache — floating rules never serve stale instants.
class RecurrenceService {
  RecurrenceService({
    required this.clock,
    required this.resolver,
    required this.currentZone,
    this.weekStart = Weekday.monday,
    this.dayStartMinutes = 0,
    this.cacheSize = 128,
    this.isolateThreshold = 1000,
    this.useIsolates = true,
  }) : engine = RecurrenceEngine(resolver);

  final Clock clock;
  final ZoneResolver resolver;

  /// IANA zone of the device; floating rules resolve here.
  final String currentZone;
  final Weekday weekStart;

  /// Minutes after midnight when the user's logical day starts (habits, arch §9.1).
  final int dayStartMinutes;
  final int cacheSize;
  final int isolateThreshold;

  /// Allows [betweenAsync] to spawn isolates (only with the tz-database resolver).
  final bool useIsolates;

  final RecurrenceEngine engine;
  late final OverrideMerger merger = OverrideMerger(engine);
  late final SeriesSplitter splitter = SeriesSplitter(engine);
  static const describer = RecurrenceDescriber();

  final LinkedHashMap<String, List<Occurrence>> _cache = LinkedHashMap();
  int _hits = 0;
  int _misses = 0;

  /// Cache statistics (tests / diagnostics).
  int get cacheHits => _hits;
  int get cacheMisses => _misses;
  int get cacheLength => _cache.length;

  DateTime get nowUtc => clock.nowUtc();

  /// Wall-clock now in the current zone.
  LocalDateTime get nowLocal => resolver.toLocal(nowUtc, currentZone);

  /// Logical today (honours the day-start setting).
  LocalDate get today {
    final local = nowLocal;
    return local.time.minuteOfDay < dayStartMinutes ? local.date.minusDays(1) : local.date;
  }

  /// Zone used to evaluate [anchor] (its own, or the current zone when floating).
  String zoneOf(RecurrenceAnchor anchor) => anchor.zoneId ?? currentZone;

  /// Occurrences in `[from, to)` (current-zone wall clock), memoized.
  List<Occurrence> between(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    LocalDateTime from,
    LocalDateTime to, {
    int? durationMinutes,
    int? limit,
    String? evalZone,
  }) {
    final zone = evalZone ?? currentZone;
    final key = _key(rule, anchor, from, to, zone, durationMinutes, limit);
    final cached = _cache.remove(key);
    if (cached != null) {
      _hits++;
      _cache[key] = cached;
      return cached;
    }
    _misses++;
    final result = List<Occurrence>.unmodifiable(
      engine.between(rule, anchor, from, to, evalZone: zone, durationMinutes: durationMinutes, limit: limit),
    );
    _put(key, result);
    return result;
  }

  /// Like [between]; runs in a background isolate when more than [isolateThreshold]
  /// occurrences are expected (minutely rules, long ranges).
  Future<List<Occurrence>> betweenAsync(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    LocalDateTime from,
    LocalDateTime to, {
    int? durationMinutes,
    int? limit,
    String? evalZone,
  }) async {
    final zone = evalZone ?? currentZone;
    final key = _key(rule, anchor, from, to, zone, durationMinutes, limit);
    final cached = _cache[key];
    if (cached != null) {
      _hits++;
      return cached;
    }
    if (!shouldOffload(rule, anchor, from, to)) {
      return between(rule, anchor, from, to, durationMinutes: durationMinutes, limit: limit, evalZone: zone);
    }
    _misses++;
    final request = _ExpandRequest(rule.encode(), anchor, from, to, zone, durationMinutes, limit);
    final result = List<Occurrence>.unmodifiable(await Isolate.run(() => expandInIsolate(request)));
    _put(key, result);
    return result;
  }

  /// Whether [betweenAsync] would use an isolate.
  bool shouldOffload(RecurrenceRule rule, RecurrenceAnchor anchor, LocalDateTime from, LocalDateTime to) =>
      useIsolates && resolver is TzZoneResolver && estimateCount(rule, from, to) > isolateThreshold;

  /// Rough occurrence count over `[from, to)` (no expansion).
  int estimateCount(RecurrenceRule rule, LocalDateTime from, LocalDateTime to) {
    final days = (from.minutesUntil(to) / 1440).ceil().clamp(1, 1 << 20);
    if (rule.type != RuleType.fixed) return days;
    final interval = rule.interval < 1 ? 1 : rule.interval;
    final times = rule.times.isEmpty ? 1 : rule.times.length;
    switch (rule.freq) {
      case Frequency.minutely:
      case Frequency.hourly:
        final w = rule.window;
        final span = w == null ? 1440 : (w.end.minuteOfDay - w.start.minuteOfDay + 1).clamp(1, 1440);
        final step = interval * (rule.freq == Frequency.hourly ? 60 : 1);
        return (span / step).ceil() * days;
      case Frequency.daily:
        return (days * times / interval).ceil();
      case Frequency.weekly:
        return (days * times * (rule.byWeekday?.length ?? 1) / 7 / interval).ceil();
      case Frequency.monthly:
      case Frequency.yearly:
        return (days * times / 28).ceil();
    }
  }

  /// The next [count] occurrences starting at or after [after] (default: now, or the anchor when
  /// it is later). After-completion rules return their next due (never completed).
  List<Occurrence> nextOccurrences(RecurrenceRule rule, RecurrenceAnchor anchor, {int count = 10, DateTime? after}) {
    if (rule.type == RuleType.afterCompletion) {
      final due = engine.nextDue(rule, anchor, null, evalZone: currentZone);
      return due == null ? const [] : [due];
    }
    final zone = zoneOf(anchor);
    final startInstant = resolver.resolve(anchor.start, zone).utc;
    final from = after ?? (nowUtc.isAfter(startInstant) ? nowUtc : startInstant);
    final fromLocal = resolver.toLocal(from, currentZone);
    final out = <Occurrence>[];
    // Expand in growing windows so sparse rules (yearly) and dense ones (minutely) both stay cheap.
    var windowDays = 31;
    var cursor = fromLocal;
    final horizon = fromLocal.date.plusYears(50).atStartOfDay;
    while (out.length < count && cursor.isBefore(horizon)) {
      final end = LocalDateTime.min(cursor.plusDays(windowDays), horizon);
      for (final o in engine.between(
        rule,
        anchor,
        cursor,
        end,
        evalZone: currentZone,
        durationMinutes: 0,
        limit: count - out.length,
      )) {
        if (!o.startUtc.isBefore(from)) out.add(o);
      }
      cursor = end;
      windowDays = (windowDays * 4).clamp(31, 3660);
    }
    return out;
  }

  Occurrence? nextAfter(RecurrenceRule rule, RecurrenceAnchor anchor, {DateTime? instant, bool inclusive = false}) =>
      engine.nextAfter(rule, anchor, instant ?? nowUtc, evalZone: currentZone, inclusive: inclusive);

  Occurrence? previousBefore(
    RecurrenceRule rule,
    RecurrenceAnchor anchor, {
    DateTime? instant,
    bool inclusive = false,
  }) => engine.previousBefore(rule, anchor, instant ?? nowUtc, evalZone: currentZone, inclusive: inclusive);

  /// After-completion: when the series is next due after [lastCompletion].
  Occurrence? nextDue(RecurrenceRule rule, RecurrenceAnchor anchor, DateTime? lastCompletion, {int? durationMinutes}) =>
      engine.nextDue(rule, anchor, lastCompletion, evalZone: currentZone, durationMinutes: durationMinutes);

  bool occurs(RecurrenceRule rule, RecurrenceAnchor anchor, String key) => engine.occurs(rule, anchor, key);

  Occurrence? occurrenceForKey(RecurrenceRule rule, RecurrenceAnchor anchor, String key) =>
      engine.occurrenceForKey(rule, anchor, key, evalZone: currentZone);

  /// Quota periods (week start from the user's preferences).
  List<Period> periods(RecurrenceRule rule, RecurrenceAnchor anchor, LocalDate from, LocalDate to) =>
      engine.periods(rule, anchor, from, to, weekStart: weekStart);

  /// Localized description ("Every Monday and Tuesday at 08:00").
  String describe(RecurrenceRule rule, RecurrenceAnchor anchor, {String locale = 'en', bool use24h = true}) {
    final lang = locale.split(RegExp('[-_]')).first;
    return describer.describe(rule, anchor, locale: lang, use24h: use24h, weekStart: weekStart);
  }

  ValidationResult validate(RecurrenceRule rule, RecurrenceAnchor anchor) => rule.validate(anchor: anchor);

  /// Moves a fixed rule's anchor to its first occurrence at or after the anchor start
  /// (e.g. "Weekly on Tuesday" picked on a Monday). Other rule types are returned unchanged.
  RecurrenceAnchor alignAnchor(RecurrenceRule rule, RecurrenceAnchor anchor) {
    if (rule.type != RuleType.fixed || !rule.validate(anchor: anchor).isValid) return anchor;
    try {
      final first = engine
          .between(
            rule,
            anchor,
            anchor.start,
            anchor.start.date.plusYears(10).atStartOfDay,
            evalZone: zoneOf(anchor),
            durationMinutes: 0,
            limit: 1,
          )
          .firstOrNull;
      if (first == null || first.startLocal == anchor.start) return anchor;
      return anchor.copyWith(start: anchor.allDay ? first.startLocal.date.atStartOfDay : first.startLocal);
    } on Object {
      return anchor;
    }
  }

  /// "This and following" split helper.
  SeriesSplit split(RecurrenceRule rule, RecurrenceAnchor anchor, String key) => splitter.split(rule, anchor, key);

  /// Maximum occurrences on one day over the next [days] days (density warnings).
  int maxPerDay(RecurrenceRule rule, RecurrenceAnchor anchor, {int days = 7}) {
    if (rule.type != RuleType.fixed) {
      return rule.type == RuleType.quota && rule.quota?.per == PeriodUnit.day ? rule.quota!.times : 1;
    }
    var max = 0;
    final start = LocalDateTime.max(anchor.start, nowLocal).date;
    for (var i = 0; i < days; i++) {
      final day = start.plusDays(i);
      final n = engine.countBetween(
        rule,
        anchor,
        day.atStartOfDay,
        day.plusDays(1).atStartOfDay,
        evalZone: currentZone,
        durationMinutes: 0,
      );
      if (n > max) max = n;
    }
    return max;
  }

  /// Whether the rule produces no occurrence in the next [years] years.
  bool neverOccursWithin(RecurrenceRule rule, RecurrenceAnchor anchor, {int years = 5}) {
    if (rule.type != RuleType.fixed) return false;
    final from = LocalDateTime.max(anchor.start, nowLocal);
    try {
      return engine
          .between(
            rule,
            anchor,
            from,
            from.date.plusYears(years).atStartOfDay,
            evalZone: currentZone,
            durationMinutes: 0,
            limit: 1,
          )
          .isEmpty;
    } on Object {
      return true;
    }
  }

  void clearCache() => _cache.clear();

  void _put(String key, List<Occurrence> value) {
    _cache[key] = value;
    while (_cache.length > cacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  static String _key(
    RecurrenceRule rule,
    RecurrenceAnchor anchor,
    LocalDateTime from,
    LocalDateTime to,
    String zone,
    int? duration,
    int? limit,
  ) => '${rule.encode()}|$anchor|${anchor.durationMinutes}|$from|$to|$zone|$duration|$limit';
}

class _ExpandRequest {
  const _ExpandRequest(this.ruleJson, this.anchor, this.from, this.to, this.zone, this.duration, this.limit);

  final String ruleJson;
  final RecurrenceAnchor anchor;
  final LocalDateTime from;
  final LocalDateTime to;
  final String zone;
  final int? duration;
  final int? limit;
}

bool _isolateTzReady = false;

/// Isolate entry point: expands a rule with a fresh tz-database engine.
List<Occurrence> expandInIsolate(Object request) {
  final r = request as _ExpandRequest;
  if (!_isolateTzReady) {
    tzdata.initializeTimeZones();
    _isolateTzReady = true;
  }
  return RecurrenceEngine(TzZoneResolver())
      .between(
        RecurrenceRule.decode(r.ruleJson),
        r.anchor,
        r.from,
        r.to,
        evalZone: r.zone,
        durationMinutes: r.duration,
        limit: r.limit,
      )
      .toList();
}

/// The recurrence facade for the current zone and preferences.
final recurrenceServiceProvider = Provider<RecurrenceService>((ref) {
  final prefs = ref.watch(userPreferencesProvider);
  return RecurrenceService(
    clock: ref.watch(clockProvider),
    resolver: ref.watch(zoneResolverProvider),
    currentZone: ref.watch(deviceZoneProvider),
    weekStart: prefs.weekStart,
    dayStartMinutes: prefs.dayStartMinutes,
  );
});
