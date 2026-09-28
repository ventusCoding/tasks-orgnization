@Tags(['sync'])
library;

import 'package:everslot/core/session/local_data_wiper.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_server.dart';

/// Sign-out / account deletion race (T1.5.07, T1.5.12): a pull already downloading when the
/// session ends must never re-insert rows after the local wipe.
void main() {
  test('a page downloaded before cancel is not applied after the wipe', () async {
    final server = FakeSyncServer();
    final other = SimDevice(server, userId: 'u1', deviceId: 'B');
    await other.writer.run((tx) => tx.insert('categories', 'c1', {'name': 'W', 'color': 1, 'sort_key': 'a0'}));
    await other.sync.syncNow();

    final d = SimDevice(server, userId: 'u1', deviceId: 'A');
    d.api.beforePull = () async {
      // The user signs out while the page is on its way.
      d.sync.cancel();
      await LocalDataWiper.wipeDatabase(d.db);
    };
    final run = d.sync.syncNow();
    await d.sync.whenIdle();
    await run;
    expect(await d.rows('categories', ['name']), isEmpty);
    await d.sync.syncNow(); // a cancelled engine never runs again
    expect(await d.rows('categories', ['name']), isEmpty);
    await other.dispose();
    await d.dispose();
  });
}
