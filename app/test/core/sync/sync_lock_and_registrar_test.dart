import 'package:everslot/core/sync/device_registrar.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/sync/sync_lock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'support/fake_sync_server.dart';

void main() {
  late FakeSyncServer server;
  late SimDevice d;

  setUp(() {
    server = FakeSyncServer();
    d = SimDevice(server, userId: 'u1', deviceId: 'A');
  });
  tearDown(() => d.dispose());

  group('SyncLock (cross-isolate mutex, T1.4.17)', () {
    test('only one owner at a time; re-entrant for the same owner', () async {
      final fg = SyncLock(d.db, owner: 'fg-1', clock: d.clock);
      final bg = SyncLock(d.db, owner: 'bg-1', clock: d.clock);
      expect(await fg.tryAcquire(), isTrue);
      expect(await bg.tryAcquire(), isFalse);
      expect(await fg.tryAcquire(), isTrue, reason: 'renewal by the holder');
      expect(await bg.holder(), 'fg-1');
      await bg.release(); // not the holder → no effect
      expect(await bg.tryAcquire(), isFalse);
      await fg.release();
      expect(await bg.tryAcquire(), isTrue);
    });

    test('an expired lease (killed isolate) can be taken over', () async {
      final bg = SyncLock(d.db, owner: 'bg-1', clock: d.clock);
      final fg = SyncLock(d.db, owner: 'fg-1', clock: d.clock);
      expect(await bg.tryAcquire(ttl: const Duration(seconds: 30)), isTrue);
      d.clock.advance(const Duration(seconds: 31));
      expect(await bg.holder(), isNull);
      expect(await fg.tryAcquire(), isTrue);
      expect(await bg.tryAcquire(), isFalse);
    });
  });

  group('DeviceRegistrar (T1.4.05)', () {
    const info = DeviceRegistration(
      id: 'A',
      platform: 'android',
      model: 'Pixel 9',
      osVersion: '16',
      appVersion: '0.1.0',
      appBuild: 1,
      locale: 'fr-FR',
      timeZone: 'Europe/Paris',
      deviceName: 'Pixel',
    );

    DeviceRegistrar registrar() => DeviceRegistrar(
      api: d.api,
      db: d.db,
      clock: d.clock,
      userId: () => 'u1',
      loadInfo: () async => info,
    );

    test('registers once per hour per user', () async {
      final r = registrar();
      expect(await r.maybeRegister(), isFalse);
      expect(await r.maybeRegister(), isNull);
      d.clock.advance(const Duration(minutes: 59));
      expect(await r.maybeRegister(), isNull);
      d.clock.advance(const Duration(minutes: 2));
      expect(await r.maybeRegister(), isFalse);
      expect(d.api.registrations, hasLength(2));
      expect(d.api.registrations.first, info);
      expect(await r.maybeRegister(force: true), isFalse);
      expect(d.api.registrations, hasLength(3));
    });

    test('reports revocation', () async {
      server.revokedDevices.add('A');
      expect(await registrar().maybeRegister(), isTrue);
    });

    test('failures are swallowed and retried next time', () async {
      d.api.offline = true;
      final r = registrar();
      expect(await r.maybeRegister(), isNull);
      d.api.offline = false;
      expect(await r.maybeRegister(), isFalse);
    });

    test('register_device params match the RPC contract exactly', () {
      expect(info.toParams().keys.toSet(), {
        'p_id',
        'p_platform',
        'p_model',
        'p_os_version',
        'p_app_version',
        'p_app_build',
        'p_locale',
        'p_time_zone',
        'p_device_name',
      });
      expect(info.toParams()['p_app_build'], 1);
    });

    test('report_device_state keeps only contract keys and serializes instants', () {
      final state = DeviceStateKeys.sanitize({
        'push_token': null,
        'local_coverage_until': DateTime.utc(2026, 9, 30, 8),
        'schedule_rev': 42,
        'bogus': 1,
      });
      expect(state.keys.toSet(), {'push_token', 'local_coverage_until', 'schedule_rev'});
      expect(state['local_coverage_until'], '2026-09-30T08:00:00.000Z');
      expect(state.containsKey('push_token'), isTrue);
    });
  });

  group('SupabaseSyncApi parsing', () {
    test('fetch_rows returns rows and missing ids', () {
      final r = SupabaseSyncApi.parseFetchRows({
        't': 'categories',
        'rows': [
          {'id': 'a', 'name': 'A'},
        ],
        'missing': ['b', 'c'],
      });
      expect(r.rows.single['name'], 'A');
      expect(r.missing, ['b', 'c']);
      expect(SupabaseSyncApi.parseFetchRows([{'id': 'x'}]).rows, hasLength(1));
    });

    test('PostgREST errors with stable codes map to SyncApiException', () {
      final e = SupabaseSyncApi.mapPostgrestError(
        const PostgrestException(message: 'update the app', code: 'unsupported_client'),
      );
      expect(e, isA<SyncApiException>());
      expect((e as SyncApiException).status, 426);
      expect(
        (SupabaseSyncApi.mapPostgrestError(const PostgrestException(message: 'x', code: 'device_revoked'))
                as SyncApiException)
            .code,
        SyncApiException.deviceRevoked,
      );
      final other = SupabaseSyncApi.mapPostgrestError(const PostgrestException(message: 'deadlock', code: '40P01'));
      expect(other, isA<PostgrestException>(), reason: 'transient errors are retried as-is');
    });

    test('sync_pull page parsing keeps the cursor when empty', () {
      final page = SupabaseSyncApi.parsePullPage({'changes': <Object>[], 'more': false}, 17);
      expect(page.next, 17);
      expect(page.purgeWatermark, 0);
    });
  });
}
