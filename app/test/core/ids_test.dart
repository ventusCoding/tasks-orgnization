import 'dart:convert';
import 'dart:io';

import 'package:everslot/core/ids/ids.dart';
import 'package:flutter_test/flutter_test.dart';

/// T1.3.03: UUIDv7 / UUIDv5 helpers (arch §9.2). The v5 vectors are shared with the SQL side
/// (`supabase/tests/database/010_helpers.test.sql` checks the same file's values against
/// `app.uuid_v5(text)`), so a drift between Dart and Postgres fails one of the two suites.
void main() {
  final fixture = jsonDecode(File('../fixtures/ids/uuid_v5.json').readAsStringSync()) as Map<String, Object?>;
  final cases = [
    for (final c in (fixture['cases']! as List<Object?>).cast<Map<String, Object?>>())
      (name: c['name']! as String, uuid: c['uuid']! as String),
  ];

  group('UUIDv5 (EVERSLOT_NS)', () {
    test('namespace constant matches the fixture (and SQL app.everslot_ns())', () {
      expect(Ids.everslotNamespace, fixture['namespace']);
    });

    test('${cases.length} shared vectors, incl. empty, RTL and emoji names', () {
      expect(cases.length, greaterThanOrEqualTo(19));
      for (final c in cases) {
        expect(Ids.v5(c.name), c.uuid, reason: 'name: "${c.name}"');
      }
    });

    test('version 5, RFC 4122 variant, deterministic', () {
      final id = Ids.v5('anything');
      expect(id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      expect(Ids.v5('anything'), id);
      expect(Ids.v5('anything else'), isNot(id));
    });
  });

  group('deterministic ids follow arch §9.2', () {
    const u = '11111111-1111-4111-8111-111111111111';
    const task = '0199a000-0000-7000-8000-000000000001';

    String fx(String name) => cases.firstWhere((c) => c.name == name, orElse: () => fail('no fixture "$name"')).uuid;

    test('helpers reproduce the SQL-verified vectors', () {
      expect(Ids.taskOccurrence(task, '2026-09-22T07:00'), fx('$task|2026-09-22T07:00'));
      expect(Ids.taskOccurrence(task, 'week:2026-W39#2'), fx('$task|week:2026-W39#2'));
      expect(Ids.userSetting(u, 'notifications'), fx('$u|notifications'));
      expect(Ids.defaultCategory(u, 'work'), fx('$u|default-category|work'));
      expect(Ids.habitSection(u, 'morning'), fx('$u|habit_section|morning'));
      expect(
        Ids.habitDayState('0199a000-0000-7000-8000-000000000020', '2026-09-22'),
        fx('0199a000-0000-7000-8000-000000000020|2026-09-22|state'),
      );
      expect(
        Ids.habitPledge('0199a000-0000-7000-8000-000000000021', '2026-09-22'),
        fx('0199a000-0000-7000-8000-000000000021|2026-09-22|pledge'),
      );
      expect(
        Ids.entityTag('0199a0aa-0000-7000-8000-000000000001', 'task', '0199a000-0000-7000-8000-000000000003'),
        fx('0199a0aa-0000-7000-8000-000000000001|task|0199a000-0000-7000-8000-000000000003'),
      );
      expect(
        Ids.checklistRun('0199a000-0000-7000-8000-000000000010', '2026-09-21'),
        fx('0199a000-0000-7000-8000-000000000010|2026-09-21'),
      );
      expect(
        Ids.achievement('first_checkin', 'habit', '0199a000-0000-7000-8000-000000000020'),
        fx('first_checkin|habit|0199a000-0000-7000-8000-000000000020'),
      );
      expect(
        Ids.rollover('0199a000-0000-7000-8000-000000000002', '2026-09-22'),
        fx('0199a000-0000-7000-8000-000000000002|rollover|2026-09-22'),
      );
    });

    test('built-in notification profiles converge with the server seed (user|profile|code)', () {
      // supabase/seed.sql and the notifications migration derive `uuid_v5(user_id || '|profile|' || code)`.
      expect(Ids.builtinProfile(u, 'standard'), fx('$u|profile|standard'));
    });

    test('achievements without a scope use empty segments; inbox ids are v5(dedupe key)', () {
      expect(Ids.achievement('streak_7', null, null), Ids.v5('streak_7||'));
      expect(Ids.inbox('reminder:abc:2026-09-22T07:00'), Ids.v5('reminder:abc:2026-09-22T07:00'));
      expect(Ids.review(u, '2026-W39'), Ids.v5('$u|review|2026-W39'));
    });

    test('different rows never collide on the same key (per-owner scoping)', () {
      expect(Ids.userSetting('user-a', 'planner'), isNot(Ids.userSetting('user-b', 'planner')));
      expect(Ids.taskOccurrence('t1', 'k'), isNot(Ids.taskOccurrence('t2', 'k')));
    });
  });

  group('UUIDv7', () {
    final v7 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

    test('version 7, RFC 4122 variant', () {
      for (var i = 0; i < 50; i++) {
        expect(Ids.v7(), matches(v7));
      }
    });

    test('unique across 20 000 ids', () {
      final ids = {for (var i = 0; i < 20000; i++) Ids.v7()};
      expect(ids.length, 20000);
    });

    test('time-ordered: the 48-bit millisecond prefix never goes backwards', () {
      int prefix(String id) => int.parse(id.replaceAll('-', '').substring(0, 12), radix: 16);
      var last = 0;
      for (var i = 0; i < 5000; i++) {
        final p = prefix(Ids.v7());
        expect(p, greaterThanOrEqualTo(last));
        last = p;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      expect((last - now).abs(), lessThan(5000), reason: 'the prefix is the current unix time in ms');
    });
  });
}
