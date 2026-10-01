@Tags(['sync'])
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_server.dart';

/// Randomized multi-device simulations against the fake server (T1.4.15): devices edit offline
/// with skewed clocks, sync in random order and must converge to identical databases.
///
/// `SYNC_SIMULATIONS=1000 fvm flutter test test/core/sync/sync_convergence_test.dart` runs the
/// full campaign of the acceptance criterion; the default keeps CI fast.
void main() {
  final simulations = int.tryParse(Platform.environment['SYNC_SIMULATIONS'] ?? '') ?? 60;

  test('$simulations randomized 3-device simulations converge', () async {
    final watch = Stopwatch()..start();
    for (var seed = 0; seed < simulations; seed++) {
      await _simulate(seed);
    }
    // ignore: avoid_print
    print('sync convergence: $simulations simulations in ${watch.elapsedMilliseconds} ms');
  }, timeout: const Timeout(Duration(minutes: 10)));
}

Future<void> _simulate(int seed) async {
  final rnd = Random(seed);
  final server = FakeSyncServer();
  final devices = [
    for (final name in ['A', 'B', 'C'])
      SimDevice(server, userId: 'u1', deviceId: name, batchSize: 3 + rnd.nextInt(6), pageSize: 2 + rnd.nextInt(5)),
  ];
  // Skewed device clocks (one runs up to 4 min ahead, one behind).
  devices[1].clock.advance(Duration(seconds: rnd.nextInt(240)));
  devices[2].clock.set(devices[2].clock.nowUtc().subtract(Duration(seconds: rnd.nextInt(600))));
  const ids = ['c0', 'c1', 'c2', 'c3', 'c4'];
  try {
    for (var step = 0; step < 40; step++) {
      final d = devices[rnd.nextInt(devices.length)];
      d.clock.advance(Duration(milliseconds: rnd.nextInt(3000)));
      server.now = server.now.add(Duration(milliseconds: rnd.nextInt(2000)));
      final id = ids[rnd.nextInt(ids.length)];
      final exists = (await d.rows('categories', ['name'])).containsKey(id);
      switch (rnd.nextInt(7)) {
        case 0 when !exists:
          await d.writer.run(
            (tx) => tx.insert('categories', id, {
              'name': 'n$step',
              'color': rnd.nextInt(16),
              'sort_key': 'a${rnd.nextInt(9)}',
            }),
          );
        case 1 when exists:
          await d.writer.run((tx) => tx.update('categories', id, {'name': '${d.deviceId}$step'}));
        case 2 when exists:
          await d.writer.run((tx) => tx.update('categories', id, {'color': rnd.nextInt(16)}));
        case 3 when exists:
          await d.writer.run((tx) async {
            await tx.update('categories', id, {'name': 'g$step', 'color': rnd.nextInt(16)});
            final other = ids[rnd.nextInt(ids.length)];
            if (other != id && await tx.exists('categories', other)) {
              await tx.update('categories', other, {'sort_key': 'z${rnd.nextInt(9)}'});
            }
          });
        case 4 when exists:
          await d.writer.run((tx) => tx.softDelete('categories', id));
        case 5 when exists:
          await d.writer.run((tx) => tx.restore('categories', id));
        default:
          d.api.offline = rnd.nextInt(4) == 0;
          await d.sync.syncNow();
      }
    }
    // Everyone back online; sync until quiescent.
    for (final d in devices) {
      d.api.offline = false;
    }
    for (var round = 0; round < 3; round++) {
      for (final d in devices) {
        await d.sync.syncNow();
      }
    }
    const columns = ['name', 'color', 'sort_key', 'deleted_at'];
    final expected = await devices.first.rows('categories', columns);
    for (final d in devices) {
      expect(await d.outbox(), isEmpty, reason: 'seed $seed: ${d.deviceId} has unsynced changes');
      expect(await d.rows('categories', columns), expected, reason: 'seed $seed: ${d.deviceId} diverged');
    }
    final serverRows = server.snapshot('u1', 'categories', columns: columns.toSet());
    expect(
      {
        for (final e in serverRows.entries) e.key: {for (final c in columns) c: e.value[c]},
      },
      expected,
      reason: 'seed $seed: server differs',
    );
  } finally {
    for (final d in devices) {
      await d.dispose();
    }
  }
}
