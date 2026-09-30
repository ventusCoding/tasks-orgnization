import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/platform/connectivity_service.dart';
import 'package:everslot/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLink implements LinkSource {
  FakeLink([this.type = ConnectionType.wifi]);

  ConnectionType type;
  final controller = StreamController<ConnectionType>.broadcast();

  @override
  Future<ConnectionType> current() async => type;

  @override
  Stream<ConnectionType> get changes => controller.stream;

  void emit(ConnectionType t) {
    type = t;
    controller.add(t);
  }
}

const _tick = Duration(milliseconds: 60);

Future<void> pumpEvents([Duration d = _tick]) => Future<void>.delayed(d);

/// T1.3.04: connectivity service (link + real reachability), with fake platform streams.
void main() {
  group('PlatformLinkSource.typeOf', () {
    test('maps connectivity_plus results', () {
      expect(PlatformLinkSource.typeOf(const []), ConnectionType.none);
      expect(PlatformLinkSource.typeOf([ConnectivityResult.none]), ConnectionType.none);
      expect(PlatformLinkSource.typeOf([ConnectivityResult.wifi]), ConnectionType.wifi);
      expect(PlatformLinkSource.typeOf([ConnectivityResult.ethernet]), ConnectionType.wifi);
      expect(PlatformLinkSource.typeOf([ConnectivityResult.mobile]), ConnectionType.cellular);
      expect(PlatformLinkSource.typeOf([ConnectivityResult.mobile, ConnectivityResult.wifi]), ConnectionType.wifi);
      expect(PlatformLinkSource.typeOf([ConnectivityResult.vpn]), ConnectionType.other);
    });

    test('without the plugin (tests) it assumes a link and an empty change stream', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final source = PlatformLinkSource();
      expect(await source.current(), ConnectionType.other);
      expect(source.changes, isA<Stream<ConnectionType>>());
    });
  });

  group('local-only (no backend to probe)', () {
    late FakeLink link;
    late ConnectivityService service;

    setUp(() async {
      link = FakeLink();
      service = ConnectivityService(source: link, debounce: const Duration(milliseconds: 20));
      await service.start();
    });

    tearDown(() async {
      service.dispose();
      await link.controller.close();
    });

    test('online while there is a link; offline and back are emitted once each', () async {
      expect(service.isOnline, isTrue);
      expect(service.type, ConnectionType.wifi);
      final seen = <bool>[];
      final sub = service.onlineChanges.listen(seen.add);
      link.emit(ConnectionType.none);
      await pumpEvents();
      expect(service.isOnline, isFalse);
      link.emit(ConnectionType.none); // same state again: no duplicate event
      await pumpEvents();
      link.emit(ConnectionType.cellular);
      await pumpEvents();
      expect(service.isOnline, isTrue);
      expect(service.type, ConnectionType.cellular);
      expect(seen, [false, true]);
      await sub.cancel();
    });

    test('a link that flaps within the debounce window causes no transition', () async {
      final seen = <bool>[];
      final sub = service.onlineChanges.listen(seen.add);
      link.emit(ConnectionType.none);
      link.emit(ConnectionType.wifi);
      await pumpEvents();
      expect(seen, isEmpty);
      expect(service.isOnline, isTrue);
      await sub.cancel();
    });

    test('start() is idempotent and checkNow re-reads the link', () async {
      await service.start();
      link.type = ConnectionType.none; // changed without an event
      expect(await service.checkNow(), isFalse);
      link.type = ConnectionType.wifi;
      expect(await service.checkNow(), isTrue);
    });
  });

  test('starting with no link reports offline right away', () async {
    final link = FakeLink(ConnectionType.none);
    final service = ConnectivityService(source: link);
    final seen = <bool>[];
    service.onlineChanges.listen(seen.add);
    await service.start();
    await pumpEvents(const Duration(milliseconds: 10));
    expect(service.isOnline, isFalse);
    expect(seen, [false]);
    service.dispose();
    await link.controller.close();
  });

  group('backend reachability', () {
    late FakeLink link;
    late ConnectivityService service;
    late List<bool> answers;
    late int probes;

    Future<ConnectivityService> build() async {
      link = FakeLink();
      probes = 0;
      service = ConnectivityService(
        source: link,
        backend: Uri.parse('https://example.supabase.co'),
        debounce: const Duration(milliseconds: 20),
        recheckInterval: const Duration(milliseconds: 50),
        reachability: (uri) async {
          expect(uri.host, 'example.supabase.co');
          final answer = answers[probes < answers.length ? probes : answers.length - 1];
          probes++;
          return answer;
        },
      );
      await service.start();
      return service;
    }

    tearDown(() async {
      service.dispose();
      await link.controller.close();
    });

    test('a link without a route to the server is offline, and recovers by itself', () async {
      answers = [false, false, true];
      await build();
      expect(service.isOnline, isFalse, reason: 'the OS says connected but the host does not answer');
      final recovered = service.onlineChanges.firstWhere((online) => online);
      expect(await recovered.timeout(const Duration(seconds: 2)), isTrue);
      expect(probes, 3, reason: 'probed again every recheck interval until the host answered');
      await pumpEvents(const Duration(milliseconds: 120));
      expect(probes, 3, reason: 'no more probing while online');
    });

    test('checkNow probes immediately (pull-to-refresh, retry buttons)', () async {
      answers = [true, false, true];
      await build();
      expect(service.isOnline, isTrue);
      expect(await service.checkNow(), isFalse);
      expect(await service.checkNow(), isTrue);
    });

    test('a slow probe superseded by "link lost" never reports online', () async {
      final slow = Completer<bool>();
      link = FakeLink();
      service = ConnectivityService(
        source: link,
        backend: Uri.parse('https://example.supabase.co'),
        debounce: const Duration(milliseconds: 10),
        reachability: (_) => slow.future,
      );
      unawaited(service.start());
      await pumpEvents(const Duration(milliseconds: 20));
      link.emit(ConnectionType.none);
      await pumpEvents(const Duration(milliseconds: 40));
      expect(service.isOnline, isFalse);
      slow.complete(true); // the stale answer arrives late
      await pumpEvents(const Duration(milliseconds: 30));
      expect(service.isOnline, isFalse);
    });

    test('a throwing probe counts as unreachable', () async {
      link = FakeLink();
      service = ConnectivityService(
        source: link,
        backend: Uri.parse('https://example.supabase.co'),
        recheckInterval: const Duration(seconds: 30),
        reachability: (_) async => throw const SocketException('boom'),
      );
      await service.start();
      expect(service.isOnline, isFalse);
    });

    test('dispose stops probing and closes the stream', () async {
      answers = [false];
      await build();
      final done = service.onlineChanges.toList();
      service.dispose();
      expect(await done, isEmpty);
      final before = probes;
      await pumpEvents(const Duration(milliseconds: 150));
      expect(probes, before);
    });
  });

  group('tcpReachability', () {
    test('true for a host that accepts connections, false for a closed port', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final reach = tcpReachability(timeout: const Duration(seconds: 2));
      expect(await reach(Uri.parse('http://127.0.0.1:${server.port}')), isTrue);
      final closedPort = server.port;
      await server.close();
      expect(await reach(Uri.parse('http://127.0.0.1:$closedPort')), isFalse);
    });
  });

  group('providers', () {
    ProviderContainer containerFor(FakeLink link, {String supabaseUrl = ''}) {
      final container = ProviderContainer(
        overrides: [
          envProvider.overrideWithValue(
            Env(
              flavor: Flavor.dev,
              supabaseUrl: supabaseUrl,
              supabasePublishableKey: supabaseUrl.isEmpty ? '' : 'sb_publishable_x',
              firebaseEnabled: false,
              featureFlags: const {},
            ),
          ),
          linkSourceProvider.overrideWithValue(link),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('local-only builds probe nothing: the link decides', () async {
      final link = FakeLink();
      final container = containerFor(link);
      final service = container.read(connectivityServiceProvider);
      expect(service.backend, isNull);
      await pumpEvents(const Duration(milliseconds: 10));
      final seen = <bool>[];
      container.read(syncOnlineChangesProvider).listen(seen.add);
      link.emit(ConnectionType.none);
      await pumpEvents(const Duration(milliseconds: 700));
      expect(seen, [false]);
      await link.controller.close();
    });

    test('a configured Supabase URL becomes the reachability target', () async {
      final container = containerFor(FakeLink(ConnectionType.none), supabaseUrl: 'https://abc.supabase.co');
      expect(container.read(connectivityServiceProvider).backend?.host, 'abc.supabase.co');
    });

    test('isOnlineProvider starts with the current state', () async {
      final container = containerFor(FakeLink());
      final values = <AsyncValue<bool>>[];
      container.listen(isOnlineProvider, (_, next) => values.add(next), fireImmediately: true);
      await pumpEvents(const Duration(milliseconds: 20));
      expect(container.read(isOnlineProvider).value, isTrue);
    });
  });
}
