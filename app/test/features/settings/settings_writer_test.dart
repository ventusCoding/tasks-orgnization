import 'dart:convert';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:everslot/features/settings/domain/settings_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/fake_sync_server.dart';
import '../../support/test_app.dart';

SettingsRepository _repo(SimDevice d) => SettingsRepository(d.db, d.writer, () => d.userId);

Future<Map<String, dynamic>> _outboxFields(SimDevice d) async =>
    jsonDecode((await d.outbox()).last.fields) as Map<String, dynamic>;

void main() {
  test('a typed update writes only the changed keys and keeps unknown ones', () async {
    final server = FakeSyncServer();
    final d = SimDevice(server, userId: 'u1', deviceId: 'A');
    addTearDown(d.dispose);
    final repo = _repo(d);
    await repo.update('appearance', {'v': 1, 'theme': 'light', 'futureKey': 7});
    final writer = SettingsWriter(repo);
    await writer.update(AppearanceSettings.codec, (s) => s.copyWith(theme: ThemePreference.dark));
    final stored = await repo.read('appearance');
    expect(stored['theme'], 'dark');
    expect(stored['futureKey'], 7);
    expect(stored['haptics'], isTrue, reason: 'defaults are materialized on first typed write');
    // Nothing changes → no new outbox entry.
    final before = (await d.outbox()).length;
    await writer.update(AppearanceSettings.codec, (s) => s.copyWith(theme: ThemePreference.dark));
    expect((await d.outbox()).length, before);
  });

  test('rapid per-field edits are debounced into one write', () async {
    final server = FakeSyncServer();
    final d = SimDevice(server, userId: 'u1', deviceId: 'A');
    addTearDown(d.dispose);
    await d.sync.syncNow();
    final writer = SettingsWriter(_repo(d), debounce: const Duration(milliseconds: 30));
    final futures = [
      for (var m = 0; m <= 300; m += 60) writer.patch('habits', {'dayStartMinutes': m}),
    ];
    await Future.wait(futures);
    expect(await _repo(d).read('habits'), containsPair('dayStartMinutes', 300));
    final outbox = await d.outbox();
    expect(outbox, hasLength(1), reason: 'one row insert, no intermediate values');
    expect((await _outboxFields(d))['value'], containsPair('dayStartMinutes', 300));
  });

  test('a setting changed on device A appears on device B after sync', () async {
    final server = FakeSyncServer();
    final a = SimDevice(server, userId: 'u1', deviceId: 'A');
    final b = SimDevice(server, userId: 'u1', deviceId: 'B');
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    await SettingsWriter(_repo(a)).update(PrivacySettings.codec, (s) => s.copyWith(hideNotificationContent: true));
    await a.sync.syncNow();
    await b.sync.syncNow();
    final onB = PrivacySettings.codec.decode(await _repo(b).read('privacy'));
    expect(onB.hideNotificationContent, isTrue);
    // Deterministic id: both devices address the same row.
    expect((await b.rows('user_settings', ['namespace'])).keys, contains(Ids.userSetting('u1', 'privacy')));
  });

  test('typed providers follow the stored namespace (corrupted JSON → defaults)', () async {
    final h = TestHarness.create();
    addTearDown(h.dispose);
    final sub = h.container.listen(appearanceSettingsProvider, (_, _) {});
    addTearDown(sub.close);
    expect(h.read(appearanceSettingsProvider), AppearanceSettings.defaults);
    await h
        .read(settingsWriterProvider)
        .update(AppearanceSettings.codec, (s) => s.copyWith(density: DensityPreference.compact));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.read(appearanceSettingsProvider).density, DensityPreference.compact);
    // A corrupted row (e.g. written by a buggy build) must not crash anything.
    await h.db.customStatement('UPDATE user_settings SET value = ? WHERE namespace = ?', ['{not json', 'appearance']);
    h.db.notifyUpdates({});
    await h.read(settingsWriterProvider).update(AppearanceSettings.codec, (s) => s.copyWith(sounds: true));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.read(appearanceSettingsProvider).sounds, isTrue);
    expect(h.read(appearanceSettingsProvider).density, DensityPreference.comfortable, reason: 'reset to defaults');
  });
}
