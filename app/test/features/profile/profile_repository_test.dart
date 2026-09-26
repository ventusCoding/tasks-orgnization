import 'dart:convert';

import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/features/profile/data/profile_repository.dart';
import 'package:everslot/features/profile/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../core/sync/support/fake_sync_server.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late FakeSyncServer server;
  final devices = <SimDevice>[];

  SimDevice device(String id) {
    final d = SimDevice(server, userId: 'u1', deviceId: id);
    devices.add(d);
    return d;
  }

  ProfileRepository repo(SimDevice d) => ProfileRepository(d.db, d.writer, () => d.userId);

  setUp(() => server = FakeSyncServer());
  tearDown(() async {
    for (final d in devices) {
      await d.dispose();
    }
    devices.clear();
  });

  test('watch emits the profile once created; update creates the row on first use', () async {
    final d = device('A');
    final r = repo(d);
    expect(await r.watch().first, isNull);
    await r.update(homeTimeZone: 'Africa/Tunis', weekStart: 1, timeFormat: TimeFormat.h24);
    final p = (await r.watch().first)!;
    expect(p.id, 'u1');
    expect(p.homeTimeZone, 'Africa/Tunis');
    expect(p.use24h, isTrue);
    expect(p.onboardingDone, isFalse);
  });

  test('only changed fields are written and pushed', () async {
    final d = device('A');
    final r = repo(d);
    await r.update(homeTimeZone: 'Europe/Paris');
    await d.sync.syncNow();
    await r.update(displayName: '  Anwer   B.  ', weekStart: 6);
    final outbox = await d.outbox();
    expect(outbox, hasLength(1));
    final fields = jsonDecode(outbox.single.fields) as Map<String, dynamic>;
    expect(fields.keys.toSet(), {'display_name', 'week_start', 'updated_at', 'origin_device_id'});
    expect(fields['display_name'], 'Anwer B.');
    expect((await r.read())!.displayName, 'Anwer B.');
    // Same values again → nothing to push.
    await r.update(displayName: 'Anwer B.', weekStart: 6);
    expect(await d.outbox(), hasLength(1));
  });

  test('invalid values are rejected before touching the database', () async {
    final r = repo(device('A'));
    expect(() => r.update(weekStart: 0), throwsA(isA<ValidationException>()));
    expect(() => r.update(weekStart: 8), throwsA(isA<ValidationException>()));
    expect(() => r.update(homeTimeZone: 'Mars/Olympus'), throwsA(isA<ValidationException>()));
    expect(() => r.update(locale: 'de'), throwsA(isA<ValidationException>()));
    expect(await r.read(), isNull);
  });

  test('clearing optional fields writes null (language back to system)', () async {
    final r = repo(device('A'));
    await r.update(locale: 'fr', displayName: 'X');
    await r.update(locale: null, displayName: '   ');
    final p = (await r.read())!;
    expect(p.locale, isNull);
    expect(p.displayName, isNull);
  });

  test('edits of different fields on two devices merge after sync', () async {
    final a = device('A');
    final b = device('B');
    await repo(a).update(homeTimeZone: 'Africa/Tunis');
    await a.sync.syncNow();
    await b.sync.syncNow();
    expect((await repo(b).read())!.homeTimeZone, 'Africa/Tunis');

    // Offline edits of different fields on both devices.
    await repo(a).update(displayName: 'Anwer');
    b.clock.advance(const Duration(seconds: 5));
    await repo(b).update(weekStart: 7, timeFormat: TimeFormat.h12);
    await a.sync.syncNow();
    await b.sync.syncNow();
    await a.sync.syncNow();
    for (final d in [a, b]) {
      final p = (await repo(d).read())!;
      expect(p.displayName, 'Anwer');
      expect(p.weekStart, 7);
      expect(p.timeFormat, TimeFormat.h12);
    }
  });

  test('Profile value semantics', () {
    const p = Profile(id: 'u1', displayName: 'A', weekStart: 6);
    expect(p.copyWith(displayName: null).displayName, isNull);
    expect(p.copyWith(weekStart: 7).weekStart, 7);
    expect(p.copyWith(), p);
    expect(p.hashCode, p.copyWith().hashCode);
    expect(ProfileRules.normalizeDisplayName('x' * 150)!.length, 100);
  });
}
