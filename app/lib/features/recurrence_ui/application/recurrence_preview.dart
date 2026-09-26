import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Non-blocking findings shown under a rule (T2.1.16).
enum RecurrenceWarningKind {
  /// More than [RecurrencePreviewer.perDayWarning] occurrences on some day ("288 per day").
  tooManyPerDay,

  /// No occurrence in the next 5 years.
  neverOccurs,

  /// Some wall-clock times fall in a DST gap and are shifted forward.
  dstShift,

  /// An all-day anchor with a minutely/hourly rule.
  allDaySubDaily,
}

@immutable
class RecurrenceWarning {
  const RecurrenceWarning(this.kind, {this.count});

  final RecurrenceWarningKind kind;

  /// Occurrences per day for [RecurrenceWarningKind.tooManyPerDay].
  final int? count;

  @override
  bool operator ==(Object other) => other is RecurrenceWarning && other.kind == kind && other.count == count;

  @override
  int get hashCode => Object.hash(kind, count);

  @override
  String toString() => 'RecurrenceWarning(${kind.name}${count == null ? '' : ' $count'})';
}

/// Everything the builder shows for a rule: validation, the anchor aligned to the first
/// occurrence, the next occurrences, a 60-day calendar, quota periods and warnings.
@immutable
class RecurrencePreview {
  const RecurrencePreview({
    required this.rule,
    required this.anchor,
    required this.alignedAnchor,
    required this.validation,
    this.next = const [],
    this.calendarStart,
    this.calendarLength = 0,
    this.occurrenceDays = const {},
    this.periods = const [],
    this.warnings = const [],
  });

  final RecurrenceRule rule;

  /// The anchor passed in.
  final RecurrenceAnchor anchor;

  /// [anchor] moved to the rule's first occurrence (e.g. to Tuesday for "weekly on Tuesday").
  final RecurrenceAnchor alignedAnchor;
  final ValidationResult validation;

  /// Next occurrences from now (or from the start when it is later).
  final List<Occurrence> next;

  /// First day of the mini calendar (null when not shown: quota / after completion / invalid).
  final LocalDate? calendarStart;
  final int calendarLength;

  /// Calendar days (viewer zone) holding at least one occurrence.
  final Set<LocalDate> occurrenceDays;

  /// Upcoming quota periods (quota rules).
  final List<Period> periods;
  final List<RecurrenceWarning> warnings;

  bool get isValid => validation.isValid;

  /// Whether the anchor had to move to match the rule.
  bool get anchorMoved => alignedAnchor.start != anchor.start;

  bool hasWarning(RecurrenceWarningKind kind) => warnings.any((w) => w.kind == kind);
}

/// Computes [RecurrencePreview]s through the app facade (T2.1.14). Bounded work only: the
/// calendar asks one day at a time with `limit: 1`, so minutely rules stay cheap (< 50 ms).
class RecurrencePreviewer {
  const RecurrencePreviewer(
    this.service, {
    this.count = 10,
    this.calendarDays = 60,
    this.perDayWarning = 24,
    this.neverYears = 5,
    this.dstScanDays = 366,
  });

  final RecurrenceService service;

  /// Number of upcoming occurrences listed.
  final int count;
  final int calendarDays;

  /// Warn when some day has more occurrences than this.
  final int perDayWarning;
  final int neverYears;

  /// Days scanned for DST transitions affecting the rule.
  final int dstScanDays;

  RecurrencePreview preview(RecurrenceRule rule, RecurrenceAnchor anchor) {
    final validation = service.validate(rule, anchor);
    final warnings = <RecurrenceWarning>[
      if (validation.issues.any(
        (i) => !i.isError && i.code == RuleIssueCode.unsupportedCombo && i.params['allDay'] == true,
      ))
        const RecurrenceWarning(RecurrenceWarningKind.allDaySubDaily),
    ];
    if (!validation.isValid) {
      return RecurrencePreview(
        rule: rule,
        anchor: anchor,
        alignedAnchor: anchor,
        validation: validation,
        warnings: warnings,
      );
    }
    final aligned = service.alignAnchor(rule, anchor);
    List<Occurrence> next;
    try {
      next = rule.type == RuleType.quota ? const [] : service.nextOccurrences(rule, aligned, count: count);
    } on Object {
      next = const [];
    }
    switch (rule.type) {
      case RuleType.quota:
        return RecurrencePreview(
          rule: rule,
          anchor: anchor,
          alignedAnchor: aligned,
          validation: validation,
          periods: _periods(rule, aligned),
          warnings: warnings,
        );
      case RuleType.afterCompletion:
        return RecurrencePreview(
          rule: rule,
          anchor: anchor,
          alignedAnchor: aligned,
          validation: validation,
          next: next,
          warnings: warnings,
        );
      case RuleType.fixed:
        final start = LocalDate.max(service.today, aligned.start.date);
        final days = _calendar(rule, aligned, start);
        final now = service.nowUtc;
        final horizon = now.add(Duration(days: 365 * neverYears + neverYears ~/ 4 + 1));
        if (next.isEmpty || next.first.startUtc.isAfter(horizon)) {
          warnings.add(const RecurrenceWarning(RecurrenceWarningKind.neverOccurs));
        } else {
          final perDay = _maxPerDay(rule, aligned);
          if (perDay > perDayWarning) {
            warnings.add(RecurrenceWarning(RecurrenceWarningKind.tooManyPerDay, count: perDay));
          }
          if (next.any((o) => o.resolutionKind == ResolutionKind.shiftedForward) ||
              _dstShiftAhead(rule, aligned, start)) {
            warnings.add(const RecurrenceWarning(RecurrenceWarningKind.dstShift));
          }
        }
        return RecurrencePreview(
          rule: rule,
          anchor: anchor,
          alignedAnchor: aligned,
          validation: validation,
          next: next,
          calendarStart: start,
          calendarLength: calendarDays,
          occurrenceDays: days,
          warnings: warnings,
        );
    }
  }

  Set<LocalDate> _calendar(RecurrenceRule rule, RecurrenceAnchor anchor, LocalDate start) {
    final out = <LocalDate>{};
    final zone = service.currentZone;
    try {
      for (var i = 0; i < calendarDays; i++) {
        final day = start.plusDays(i);
        final hit = service.engine
            .between(
              rule,
              anchor,
              day.atStartOfDay,
              day.plusDays(1).atStartOfDay,
              evalZone: zone,
              durationMinutes: 0,
              limit: 1,
            )
            .isNotEmpty;
        if (hit) out.add(day);
      }
    } on Object {
      // An unexpandable rule shows an empty calendar; validation reports why.
    }
    return out;
  }

  int _maxPerDay(RecurrenceRule rule, RecurrenceAnchor anchor) {
    try {
      return service.maxPerDay(rule, anchor);
    } on Object {
      return 0;
    }
  }

  /// Whether a DST gap in the next [dstScanDays] days shifts one of the rule's times.
  bool _dstShiftAhead(RecurrenceRule rule, RecurrenceAnchor anchor, LocalDate start) {
    if (anchor.allDay) return false;
    final zone = service.zoneOf(anchor);
    final resolver = service.resolver;
    int offsetAt(LocalDate day) => resolver.offsetMinutesAt(resolver.resolve(day.atStartOfDay, zone).utc, zone);
    try {
      var day = start;
      var offset = offsetAt(day);
      for (var i = 0; i < dstScanDays; i++) {
        final next = day.plusDays(1);
        final nextOffset = offsetAt(next);
        if (nextOffset > offset) {
          // Spring forward during `day`: look for a shifted occurrence that day.
          final shifted = service.engine
              .between(
                rule,
                anchor,
                day.atStartOfDay,
                next.atStartOfDay,
                evalZone: zone,
                durationMinutes: 0,
                limit: 1440,
              )
              .any((o) => o.resolutionKind == ResolutionKind.shiftedForward);
          if (shifted) return true;
        }
        day = next;
        offset = nextOffset;
      }
    } on Object {
      return false;
    }
    return false;
  }

  List<Period> _periods(RecurrenceRule rule, RecurrenceAnchor anchor) {
    final per = rule.quota?.per ?? PeriodUnit.week;
    final from = LocalDate.max(service.today, anchor.start.date);
    final to = switch (per) {
      PeriodUnit.day => from.plusDays(6),
      PeriodUnit.week => from.plusDays(27),
      PeriodUnit.month => from.plusMonths(2),
      PeriodUnit.year => from.plusYears(1),
    };
    try {
      return service.periods(rule, anchor, from, to);
    } on Object {
      return const [];
    }
  }
}
