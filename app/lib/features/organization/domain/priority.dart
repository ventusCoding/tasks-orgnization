/// Priority value object (T2.3.03): `tasks.priority` / `checklist_items.priority` are smallints
/// 0–4 (arch §7.3). Labels, icons and colors live in `PriorityStyle` (design system).
enum Priority {
  none(0),
  low(1),
  medium(2),
  high(3),
  urgent(4);

  const Priority(this.value);

  /// Stored smallint.
  final int value;

  /// Parses a stored value; out-of-range or null values are [none].
  static Priority fromValue(int? value) => switch (value) {
    1 => low,
    2 => medium,
    3 => high,
    4 => urgent,
    _ => none,
  };

  bool get isSet => this != none;

  /// Sort order: most urgent first, [none] last.
  static int compareUrgentFirst(Priority a, Priority b) =>
      b.value.compareTo(a.value);

  /// Same order over stored values.
  static int compareValuesUrgentFirst(int? a, int? b) =>
      compareUrgentFirst(fromValue(a), fromValue(b));
}
