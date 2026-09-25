import 'package:everslot/core/sync/hlc.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 22, 9);

  test('encoding is fixed width and sorts like the timestamps', () {
    final a = Hlc.format(5, 0, 'dev');
    final b = Hlc.format(5, 1, 'dev');
    final c = Hlc.format(1700000000000, 0, 'dev');
    expect(a, '000000000000005:00000:dev');
    expect(a.compareTo(b), lessThan(0));
    expect(b.compareTo(c), lessThan(0));
    final parsed = Hlc.tryParse(c)!;
    expect(parsed.ms, 1700000000000);
    expect(parsed.counter, 0);
    expect(parsed.device, 'dev');
    expect(Hlc.tryParse('garbage'), isNull);
  });

  test('many events in one millisecond increase the counter', () {
    final clock = FakeClock(t0);
    final hlc = Hlc(deviceId: 'd', clock: clock);
    final stamps = [for (var i = 0; i < 1000; i++) hlc.now()];
    for (var i = 1; i < stamps.length; i++) {
      expect(stamps[i].compareTo(stamps[i - 1]), greaterThan(0));
    }
  });

  test('monotonic when the device clock jumps backwards', () {
    final clock = FakeClock(t0);
    final hlc = Hlc(deviceId: 'd', clock: clock);
    final before = hlc.now();
    clock.set(t0.subtract(const Duration(hours: 2)));
    final after = hlc.now();
    expect(after.compareTo(before), greaterThan(0));
  });

  test('observing a server clock from the near future makes later stamps greater', () {
    final clock = FakeClock(t0);
    final hlc = Hlc(deviceId: 'b', clock: clock);
    final remote = Hlc.format(t0.add(const Duration(minutes: 4)).millisecondsSinceEpoch, 3, 'a');
    hlc.observe(remote);
    expect(hlc.now().compareTo(remote), greaterThan(0));
  });

  test('a device whose clock runs 10 min late still adopts server clocks', () {
    final clock = FakeClock(t0.subtract(const Duration(minutes: 10)));
    final hlc = Hlc(deviceId: 'late', clock: clock);
    final remote = Hlc.format(t0.millisecondsSinceEpoch, 0, 'a');
    hlc.observe(remote);
    expect(hlc.now().compareTo(remote), greaterThan(0));
  });

  test('absurd future clocks (corrupted values) are ignored', () {
    final clock = FakeClock(t0);
    final hlc = Hlc(deviceId: 'b', clock: clock);
    hlc.observe(Hlc.format(t0.add(const Duration(days: 3)).millisecondsSinceEpoch, 0, 'a'));
    expect(Hlc.tryParse(hlc.now())!.ms, t0.millisecondsSinceEpoch);
  });

  test('state survives a restart (initialState)', () {
    final clock = FakeClock(t0);
    final first = Hlc(deviceId: 'd', clock: clock);
    first.observe(Hlc.format(t0.add(const Duration(minutes: 1)).millisecondsSinceEpoch, 7, 'x'));
    final restored = Hlc(deviceId: 'd', clock: FakeClock(t0), initialState: first.state);
    expect(restored.now().compareTo(first.state), greaterThan(0));
  });

  test('automatic writes use the scheduled instant and never advance the clock', () {
    final clock = FakeClock(t0);
    final hlc = Hlc(deviceId: 'd', clock: clock);
    final scheduled = t0.subtract(const Duration(hours: 1));
    final auto = hlc.at(scheduled);
    expect(Hlc.tryParse(auto)!.ms, scheduled.millisecondsSinceEpoch);
    expect(hlc.now().compareTo(auto), greaterThan(0));
  });
}
