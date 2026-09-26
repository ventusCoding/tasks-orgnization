/// The device moved to another time zone (T1.5.06). Consumed by Today, planner views (floating
/// tasks re-resolve) and notification re-planning.
class TimeZoneChanged {
  const TimeZoneChanged({required this.from, required this.to, required this.at});

  final String from;
  final String to;

  /// Detection instant (UTC).
  final DateTime at;

  @override
  bool operator ==(Object other) => other is TimeZoneChanged && other.from == from && other.to == to && other.at == at;

  @override
  int get hashCode => Object.hash(from, to, at);

  @override
  String toString() => 'TimeZoneChanged($from → $to at $at)';
}
