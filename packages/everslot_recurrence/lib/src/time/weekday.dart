/// ISO-8601 weekday (Monday = 1 … Sunday = 7) with RFC 5545 two-letter codes.
enum Weekday {
  monday(1, 'MO'),
  tuesday(2, 'TU'),
  wednesday(3, 'WE'),
  thursday(4, 'TH'),
  friday(5, 'FR'),
  saturday(6, 'SA'),
  sunday(7, 'SU');

  new(this.iso, this.code);

  /// ISO number: Monday = 1 … Sunday = 7.
  final int iso;

  /// RFC 5545 code: `MO`, `TU`, …
  final String code;

  static Weekday fromIso(int iso) {
    if (iso < 1 || iso > 7) {
      throw ArgumentError.value(iso, 'iso', 'must be 1..7');
    }
    return Weekday.values[iso - 1];
  }

  static Weekday fromCode(String code) {
    final upper = code.toUpperCase();
    for (final w in Weekday.values) {
      if (w.code == upper) return w;
    }
    throw FormatException('Unknown weekday code', code);
  }

  /// Number of days from [weekStart] to this weekday (0..6).
  int offsetFrom(Weekday weekStart) => (iso - weekStart.iso + 7) % 7;

  /// Weekdays in display order starting at [weekStart].
  static List<Weekday> ordered(Weekday weekStart) => [
    for (var i = 0; i < 7; i++) Weekday.fromIso((weekStart.iso - 1 + i) % 7 + 1),
  ];

  bool get isWeekend => this == Weekday.saturday || this == Weekday.sunday;
}
