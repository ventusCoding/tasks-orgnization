import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support/fixtures.dart';

void main() {
  tzdata.initializeTimeZones();
  final engine = RecurrenceEngine(TzZoneResolver());
  final fixtures = loadFixtures();

  test('fixture suite has at least 150 cases', () {
    expect(fixtures.length, greaterThanOrEqualTo(150));
    final names = <String>{};
    for (final f in fixtures) {
      expect(names.add('${f.file}/${f.name}'), isTrue, reason: 'duplicate fixture name ${f.name}');
    }
  });

  group('fixtures', () {
    for (final fixture in fixtures) {
      test(fixture.toString(), () {
        final failure = checkFixture(engine, fixture);
        if (failure != null) fail(failure);
      });
    }
  });

  group('runner', () {
    test('a deliberately broken fixture fails with a readable key diff', () {
      final broken = RecurrenceFixture('broken.json', {
        'name': 'daily, wrong expectation',
        'rule': {'v': 1, 'type': 'fixed', 'freq': 'daily', 'interval': 1},
        'anchor': {'start': '2026-09-21T08:00', 'zone': 'UTC'},
        'evalZone': null,
        'range': {'from': '2026-09-21T00:00', 'to': '2026-09-24T00:00'},
        'expectedKeys': ['2026-09-21T08:00', '2026-09-23T08:00', '2026-09-25T08:00'],
      });
      final failure = checkFixture(engine, broken);
      expect(failure, isNotNull);
      expect(failure, contains('broken.json › daily, wrong expectation'));
      expect(failure, contains('missing:    2026-09-25T08:00'));
      expect(failure, contains('unexpected: 2026-09-22T08:00'));
    });

    test('order and UTC differences are reported', () {
      expect(diffKeys(['a', 'b'], ['b', 'a']), contains('first difference at #0'));
      expect(diffKeys(['a'], ['a', 'a']), contains('duplicates differ'));
      expect(diffKeys(['a', 'b'], ['a', 'b']), isNull);
      final long = [for (var i = 0; i < 20; i++) 'k$i'];
      expect(diffKeys(long, const []), contains('(+8)'));
      final utcBroken = RecurrenceFixture('utc.json', {
        'name': 'utc',
        'rule': {'v': 1, 'type': 'fixed', 'freq': 'daily', 'interval': 1, 'count': 1},
        'anchor': {'start': '2026-09-21T08:00', 'zone': 'Europe/Paris'},
        'evalZone': null,
        'range': {'from': '2026-09-21T00:00', 'to': '2026-09-24T00:00'},
        'expectedKeys': ['2026-09-21T08:00'],
        'expectedUtc': ['2026-09-21T08:00Z'],
      });
      expect(checkFixture(engine, utcBroken), contains('UTC instants differ'));
    });
  });
}
