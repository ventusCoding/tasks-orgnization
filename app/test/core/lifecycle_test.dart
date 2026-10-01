import 'dart:async';

import 'package:everslot/core/lifecycle/app_lifecycle.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// T1.3.04: lifecycle service (debounced resume, raw states, time away).
void main() {
  late FakeClock clock;
  late AppLifecycleService service;
  late List<String> events;
  late List<StreamSubscription<Object?>> subs;

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  void go(AppLifecycleState state) => service.didChangeAppLifecycleState(state);

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    clock = FakeClock(DateTime.utc(2026, 9, 22, 9));
    service = AppLifecycleService(clock: clock);
    events = [];
    subs = [
      service.onResume.listen((_) => events.add('resume')),
      service.onPause.listen((_) => events.add('pause')),
      service.onDetached.listen((_) => events.add('detached')),
      service.states.listen((s) => events.add('state:${s.name}')),
      service.onReturn.listen((d) => events.add('return:${d.inSeconds}')),
    ];
  });

  tearDown(() async {
    for (final s in subs) {
      await s.cancel();
    }
    service.dispose();
  });

  test('starts in the foreground', () {
    expect(service.isForeground, isTrue);
    expect(service.awayFor, Duration.zero);
    expect(service.backgroundedAt, isNull);
  });

  test('pause and resume are delivered, with every distinct raw state', () async {
    go(AppLifecycleState.inactive);
    go(AppLifecycleState.hidden);
    go(AppLifecycleState.paused);
    clock.advance(const Duration(seconds: 30));
    go(AppLifecycleState.resumed);
    await flush();
    expect(events, ['state:inactive', 'state:hidden', 'state:paused', 'pause', 'state:resumed', 'return:30', 'resume']);
    expect(service.isForeground, isTrue);
  });

  test('duplicate states are ignored', () async {
    go(AppLifecycleState.resumed); // already resumed
    go(AppLifecycleState.paused);
    go(AppLifecycleState.paused);
    await flush();
    expect(events, ['state:paused', 'pause']);
  });

  test('resume is debounced (at most once per 2 s) but onReturn always reports the away time', () async {
    go(AppLifecycleState.paused);
    clock.advance(const Duration(seconds: 10));
    go(AppLifecycleState.resumed);
    // A permission dialog: paused/resumed again within a second.
    clock.advance(const Duration(milliseconds: 500));
    go(AppLifecycleState.paused);
    clock.advance(const Duration(milliseconds: 500));
    go(AppLifecycleState.resumed);
    await flush();
    expect(events.where((e) => e == 'resume'), hasLength(1));
    expect(events.where((e) => e.startsWith('return:')), ['return:10', 'return:0']);
    clock.advance(const Duration(seconds: 3));
    go(AppLifecycleState.paused);
    clock.advance(const Duration(seconds: 3));
    go(AppLifecycleState.resumed);
    await flush();
    expect(events.where((e) => e == 'resume'), hasLength(2), reason: 'a later resume fires again');
  });

  test('time away: backgrounding starts at the first hidden/paused, inactive alone does not count', () async {
    go(AppLifecycleState.inactive);
    clock.advance(const Duration(seconds: 5));
    expect(service.backgroundedAt, isNull);
    expect(service.awayFor, Duration.zero);
    go(AppLifecycleState.hidden);
    final since = clock.nowUtc();
    clock.advance(const Duration(seconds: 20));
    go(AppLifecycleState.paused);
    clock.advance(const Duration(seconds: 40));
    expect(service.backgroundedAt, since, reason: 'hidden → paused keeps the first timestamp');
    expect(service.awayFor, const Duration(seconds: 60));
    go(AppLifecycleState.resumed);
    expect(service.backgroundedAt, isNull);
    expect(service.awayFor, Duration.zero);
    await flush();
    expect(events.last, 'resume');
    expect(events, contains('return:60'));
  });

  test('inactive → resumed (a system dialog) reports zero time away', () async {
    go(AppLifecycleState.inactive);
    clock.advance(const Duration(minutes: 5));
    go(AppLifecycleState.resumed);
    await flush();
    expect(events, contains('return:0'));
  });

  test('detached is reported', () async {
    go(AppLifecycleState.detached);
    await flush();
    expect(events, ['state:detached', 'detached']);
  });

  test('dispose unregisters from the binding and closes the streams', () async {
    service.dispose();
    var done = 0;
    for (final s in [service.onResume, service.onPause, service.onDetached, service.states, service.onReturn]) {
      unawaited(s.listen((_) {}).asFuture<void>().then((_) => done++));
    }
    await flush();
    expect(done, 5);
  });
}
