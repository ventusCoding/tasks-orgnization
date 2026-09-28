@Tags(['sync'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_server.dart';

/// T1.4.19: automatic (time-triggered) writes are stamped with the scheduled instant, so a user
/// edit made after that instant wins on every device, whichever device ran the automation.
void main() {
  for (final automationOn in ['A', 'B', 'both']) {
    test('user edit after an automated reset wins (automation ran on $automationOn)', () async {
      final server = FakeSyncServer();
      final a = SimDevice(server, userId: 'u1', deviceId: 'A');
      final b = SimDevice(server, userId: 'u1', deviceId: 'B');
      await a.writer.run((tx) => tx.insert('categories', 'c1', {'name': 'Start', 'color': 1, 'sort_key': 'a0'}));
      await a.sync.syncNow();
      await b.sync.syncNow();

      // The reset was due one hour ago; the devices only run it now (app opened late).
      final scheduled = a.clock.nowUtc().subtract(const Duration(hours: 1));
      Future<void> automate(SimDevice d) =>
          d.writer.runAutomatic(scheduled, (tx) => tx.update('categories', 'c1', {'name': 'Reset'}), cause: 'reset');

      // Meanwhile (after the scheduled instant) the user renamed it on A.
      a.clock.advance(const Duration(minutes: 1));
      await a.writer.run((tx) => tx.update('categories', 'c1', {'name': 'User'}));
      await a.sync.syncNow();

      if (automationOn != 'A') await automate(b);
      if (automationOn != 'B') await automate(a);
      for (var i = 0; i < 2; i++) {
        await a.sync.syncNow();
        await b.sync.syncNow();
      }
      expect(server.row('categories', 'c1')!.values['name'], 'User');
      expect((await a.rows('categories', ['name']))['c1']!['name'], 'User');
      expect((await b.rows('categories', ['name']))['c1']!['name'], 'User');
      await a.dispose();
      await b.dispose();
    });
  }
}
