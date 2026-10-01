/// Injectable source of "now" (never call `DateTime.now()` in domain/application code).
abstract class Clock {
  const Clock();

  /// Current instant in UTC.
  DateTime nowUtc();
}

class SystemClock extends Clock {
  const SystemClock({this.offset = Duration.zero});

  /// Debug "time travel" offset (T1.3.16).
  final Duration offset;

  @override
  DateTime nowUtc() => DateTime.now().toUtc().add(offset);
}

/// The app clock: system time plus a debug "time travel" offset (T1.3.16) that can change at run
/// time — every holder of this instance sees the new time at once (no provider rebuild needed).
class TravelClock extends Clock {
  Duration offset = Duration.zero;

  @override
  DateTime nowUtc() => DateTime.now().toUtc().add(offset);
}

/// Deterministic clock for tests.
class FakeClock extends Clock {
  FakeClock(DateTime start) : _now = start.toUtc();

  DateTime _now;

  @override
  DateTime nowUtc() => _now;

  void set(DateTime value) => _now = value.toUtc();
  void advance(Duration by) => _now = _now.add(by);
}
