import 'dart:async';

import 'package:everslot/core/sync/sync_service.dart';
import 'package:everslot/core/sync/sync_triggers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_server.dart';

/// Records trigger calls instead of running timers.
class _SpyService extends SyncService {
  _SpyService(SimDevice d)
    : super(
        db: d.db,
        registry: d.registry,
        api: d.api,
        hlc: d.hlc,
        clock: d.clock,
        userId: () => d.userId,
        deviceId: d.deviceId,
        appBuild: 1,
      );

  final calls = <String>[];

  @override
  void schedulePull([Duration delay = const Duration(milliseconds: 400)]) =>
      calls.add('pull:${delay.inMilliseconds}');

  @override
  void schedulePush([Duration delay = const Duration(milliseconds: 1500)]) =>
      calls.add('push:${delay.inMilliseconds}');
}

void main() {
  late FakeSyncServer server;
  late SimDevice device;
  late _SpyService spy;
  late StreamController<void> resume;
  late StreamController<void> pause;
  late StreamController<bool> online;
  late List<String> channel;
  void Function(Map<String, dynamic>)? onSync;

  BroadcastSubscriber subscriber() => (callback) {
    channel.add('join');
    onSync = callback;
    return () async => channel.add('leave');
  };

  setUp(() {
    server = FakeSyncServer();
    device = SimDevice(server, userId: 'u1', deviceId: 'A');
    spy = _SpyService(device);
    resume = StreamController<void>.broadcast(sync: true);
    pause = StreamController<void>.broadcast(sync: true);
    online = StreamController<bool>.broadcast(sync: true);
    channel = [];
    onSync = null;
  });

  tearDown(() async {
    spy.dispose();
    await device.dispose();
  });

  SyncTriggers triggers({bool foreground = true, void Function()? onResumed}) => SyncTriggers(
    service: spy,
    onResume: resume.stream,
    onPause: pause.stream,
    onlineChanges: online.stream,
    subscribeBroadcast: subscriber(),
    onResumed: onResumed,
  )..start(foreground: foreground);

  group('Broadcast (T1.4.12)', () {
    test('joined in the foreground, left on pause, re-joined on resume with a pull', () async {
      var resumed = 0;
      final t = triggers(onResumed: () => resumed++);
      expect(channel, ['join']);
      expect(t.broadcastJoined, isTrue);
      pause.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(channel, ['join', 'leave']);
      expect(t.broadcastJoined, isFalse);
      resume.add(null);
      expect(channel, ['join', 'leave', 'join']);
      expect(spy.calls, ['pull:0']);
      expect(resumed, 1);
      t.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(channel.last, 'leave');
    });

    test('not joined while started in the background', () {
      final t = triggers(foreground: false);
      expect(channel, isEmpty);
      expect(t.broadcastJoined, isFalse);
      t.dispose();
    });

    test('a nudge schedules a pull unless its revision is already pulled', () async {
      final t = triggers();
      onSync!({'rev': 3});
      expect(spy.calls, ['pull:400'], reason: 'cursor unknown yet → pull');
      // After a pull the service knows its cursor.
      await device.writer.run((tx) => tx.insert('categories', 'c1', {'name': 'W', 'color': 1, 'sort_key': 'a0'}));
      await device.sync.syncNow();
      final pulled = SimDevice(server, userId: 'u1', deviceId: 'B');
      final service = _SpyService(pulled);
      await service.syncNow();
      final cursor = service.knownCursor!;
      expect(cursor, server.head('u1'));
      service.onBroadcast({'rev': cursor});
      service.onBroadcast({'rev': cursor - 1});
      expect(service.calls, isEmpty);
      service.onBroadcast({'rev': cursor + 1});
      service.onBroadcast(const {});
      expect(service.calls, ['pull:400', 'pull:400']);
      service.dispose();
      await pulled.dispose();
      t.dispose();
    });
  });

  group('connectivity (T1.4.10)', () {
    test('regaining the network pushes immediately; staying online does not', () {
      final t = triggers();
      online.add(true);
      expect(spy.calls, isEmpty, reason: 'first reading is not a transition');
      online.add(false);
      online.add(true);
      expect(spy.calls, ['push:0']);
      online.add(true);
      expect(spy.calls, ['push:0']);
      t.dispose();
    });

    test('connectivity stream errors are ignored', () {
      final t = triggers();
      online.addError(StateError('no plugin'));
      online.add(false);
      online.add(true);
      expect(spy.calls, ['push:0']);
      t.dispose();
    });
  });

  test('end to end: a nudge makes another device pull the new rows', () async {
    final b = SimDevice(server, userId: 'u1', deviceId: 'B');
    await b.sync.syncNow();
    await device.writer.run((tx) => tx.insert('categories', 'c9', {'name': 'Home', 'color': 2, 'sort_key': 'a0'}));
    await device.sync.syncNow();
    b.sync.onBroadcast({'rev': server.head('u1')});
    await Future<void>.delayed(const Duration(milliseconds: 700));
    while (b.sync.isRunning) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect((await b.rows('categories', ['name']))['c9']?['name'], 'Home');
    await b.dispose();
  });
}
