/// Kind of recurrence rule (arch §8.1 `type`).
enum RuleType {
  /// Calendar-driven occurrences (RFC 5545 semantics plus windows and times).
  fixed('fixed'),

  /// Next due = last completion + an amount of time.
  afterCompletion('after_completion'),

  /// N completions per period, on any (eligible) days.
  quota('quota');

  new(this.json);

  /// JSON spelling.
  final String json;

  /// Parses the JSON spelling; throws [FormatException] when unknown.
  static RuleType fromJson(Object? value) => enumFromJson(values, value, 'type', (e) => e.json);
}

/// Base frequency of a fixed rule (RFC 5545 `FREQ`, without `SECONDLY`).
enum Frequency {
  minutely,
  hourly,
  daily,
  weekly,
  monthly,
  yearly;

  /// JSON spelling (lower case).
  String get json => name;

  /// RFC 5545 spelling (upper case).
  String get rrule => name.toUpperCase();

  /// True for [minutely] and [hourly].
  bool get isSubDaily => this == minutely || this == hourly;

  /// Parses the JSON spelling; throws [FormatException] when unknown.
  static Frequency fromJson(Object? value) => enumFromJson(values, value, 'freq', (e) => e.name);
}

/// How `count` is interpreted.
enum CountMode {
  /// RFC 5545: the first N generated occurrences (exdates do not extend the series).
  occurrences,

  /// The series ends after N completions (evaluated by the caller with completion data).
  completions;

  /// Parses the JSON spelling; throws [FormatException] when unknown.
  static CountMode fromJson(Object? value) => enumFromJson(values, value, 'countMode', (e) => e.name);
}

/// How a minutely/hourly rule is aligned inside its daily window.
enum WindowAnchor {
  /// Each matching day restarts at the window start (08:00, 09:30, …).
  windowStart('window_start'),

  /// One continuous chain from the series start, filtered by the window (RRULE behaviour).
  seriesStart('series_start');

  new(this.json);

  /// JSON spelling.
  final String json;

  /// Parses the JSON spelling; throws [FormatException] when unknown.
  static WindowAnchor fromJson(Object? value) => enumFromJson(values, value, 'window.anchor', (e) => e.json);
}

/// Unit of an after-completion delay.
enum RecurrenceUnit {
  minute,
  hour,
  day,
  week,
  month,
  year;

  /// True for units counted in whole days or more (the anchor's time of day is kept).
  bool get isDayBased => index >= day.index;

  /// Parses the JSON spelling; throws [FormatException] when unknown.
  static RecurrenceUnit fromJson(Object? value) => enumFromJson(values, value, 'afterCompletion.unit', (e) => e.name);
}

/// Period of a quota rule.
enum PeriodUnit {
  day,
  week,
  month,
  year;

  /// Parses the JSON spelling; throws [FormatException] when unknown.
  static PeriodUnit fromJson(Object? value) => enumFromJson(values, value, 'quota.per', (e) => e.name);
}

/// Looks up an enum value by its JSON spelling.
T enumFromJson<T extends Enum>(List<T> values, Object? value, String field, String Function(T) spelling) {
  if (value is String) {
    for (final v in values) {
      if (spelling(v) == value) return v;
    }
  }
  throw FormatException('Invalid value for "$field"', value);
}
