import 'dart:math';

import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:flutter_test/flutter_test.dart';

/// T1.3.03: fractional indexing (arch §9.4) — reference vectors of the rocicorp
/// `fractional-indexing` library plus property tests.
void main() {
  group('reference vectors (byte-compatible with the JS implementation)', () {
    const between = <(String?, String?, String)>[
      (null, null, 'a0'),
      (null, 'a0', 'Zz'),
      (null, 'Zz', 'Zy'),
      ('a0', null, 'a1'),
      ('a1', null, 'a2'),
      ('a0', 'a1', 'a0V'),
      ('a1', 'a2', 'a1V'),
      ('a0V', 'a1', 'a0l'),
      ('Zz', 'a0', 'ZzV'),
      ('Zz', 'a1', 'a0'),
      (null, 'Y00', 'Xzzz'),
      ('bzz', null, 'c000'),
      ('a0', 'a0V', 'a0G'),
      ('a0', 'a0G', 'a08'),
      ('b125', 'b129', 'b127'),
      ('a0', 'a1V', 'a1'),
      ('Zz', 'a01', 'a0'),
      (null, 'a0V', 'a0'),
      (null, 'b999', 'b99'),
      (null, 'A000000000000000000000000001', 'A000000000000000000000000000V'),
      ('zzzzzzzzzzzzzzzzzzzzzzzzzzy', null, 'zzzzzzzzzzzzzzzzzzzzzzzzzzz'),
      ('zzzzzzzzzzzzzzzzzzzzzzzzzzz', null, 'zzzzzzzzzzzzzzzzzzzzzzzzzzzV'),
    ];
    for (final v in between) {
      test(
        'between(${v.$1}, ${v.$2}) = ${v.$3}',
        () => expect(FractionalIndex.between(v.$1, v.$2), v.$3),
      );
    }

    test('invalid input is rejected', () {
      expect(
        () => FractionalIndex.between(null, 'A00000000000000000000000000'),
        throwsArgumentError,
      );
      expect(
        () => FractionalIndex.between('a00', null),
        throwsArgumentError,
        reason: 'trailing zero',
      );
      expect(() => FractionalIndex.between('a00', 'a1'), throwsArgumentError);
      expect(
        () => FractionalIndex.between('0', '1'),
        throwsArgumentError,
        reason: 'invalid head',
      );
      expect(
        () => FractionalIndex.between('a1', 'a0'),
        throwsArgumentError,
        reason: 'a >= b',
      );
      expect(
        () => FractionalIndex.between('a0', 'a0'),
        throwsArgumentError,
        reason: 'equal keys',
      );
      expect(
        () => FractionalIndex.between('a-', null),
        throwsArgumentError,
        reason: 'charset',
      );
      expect(
        () => FractionalIndex.between('', null),
        throwsArgumentError,
        reason: 'empty',
      );
    });

    test('nBetween', () {
      expect(FractionalIndex.nBetween(null, null, 5), [
        'a0',
        'a1',
        'a2',
        'a3',
        'a4',
      ]);
      expect(FractionalIndex.nBetween('a4', null, 10), [
        'a5',
        'a6',
        'a7',
        'a8',
        'a9',
        'aA',
        'aB',
        'aC',
        'aD',
        'aE',
      ]);
      expect(FractionalIndex.nBetween(null, 'a0', 5), [
        'Zv',
        'Zw',
        'Zx',
        'Zy',
        'Zz',
      ]);
      expect(FractionalIndex.nBetween('a0', 'a1', 1), ['a0V']);
      expect(FractionalIndex.nBetween('a0', 'a1', 0), isEmpty);
    });
  });

  group('validation', () {
    test('valid and invalid keys', () {
      for (final ok in ['a0', 'a0V', 'Zz', 'b127', 'c000', 'a1G']) {
        expect(FractionalIndex.isValid(ok), isTrue, reason: ok);
      }
      for (final bad in [
        '',
        'a00',
        'A00000000000000000000000000',
        '0',
        'a-1',
        'é',
        'a0 ',
        'a',
      ]) {
        expect(FractionalIndex.isValid(bad), isFalse, reason: '"$bad"');
      }
    });

    test('byte order is the order: digits < upper case < lower case, never locale-aware', () {
      expect(FractionalIndex.compare('a0', 'a1'), lessThan(0));
      expect(
        FractionalIndex.compare('Zz', 'a0'),
        lessThan(0),
        reason: 'Z (0x5A) < a (0x61)',
      );
      expect(
        FractionalIndex.compare('a0Z', 'a0a'),
        lessThan(0),
        reason: 'a case-insensitive collation would tie',
      );
      expect(FractionalIndex.compare('a0', 'a0'), 0);
      expect(
        FractionalIndex.compareRows((key: 'a1', id: 'b'), (key: 'a1', id: 'a')),
        greaterThan(0),
        reason: 'equal keys are ordered by id',
      );
      expect(
        FractionalIndex.compareRows((key: 'a0', id: 'z'), (key: 'a1', id: 'a')),
        lessThan(0),
      );
    });

    test('length budget', () {
      expect(FractionalIndex.isOversized('a0'), isFalse);
      expect(FractionalIndex.isOversized('a${'V' * 64}'), isTrue);
    });
  });

  group('properties', () {
    test('10 000 random inserts keep the list strictly sorted, valid, and keys ≤ 64 chars', () {
      final rnd = Random(20260922);
      final keys = <String>[];
      var longest = 0;
      for (var i = 0; i < 10000; i++) {
        // Front, back or a random gap: what user reordering looks like.
        final p = switch (rnd.nextInt(10)) {
          0 => 0,
          1 => keys.length,
          _ => rnd.nextInt(keys.length + 1),
        };
        final a = p == 0 ? null : keys[p - 1];
        final b = p == keys.length ? null : keys[p];
        final k = FractionalIndex.between(a, b);
        expect(
          FractionalIndex.isValid(k),
          isTrue,
          reason: 'between($a, $b) = $k',
        );
        keys.insert(p, k);
        longest = max(longest, k.length);
      }
      for (var i = 1; i < keys.length; i++) {
        expect(
          FractionalIndex.compare(keys[i - 1], keys[i]),
          lessThan(0),
          reason: 'at $i: ${keys[i - 1]} / ${keys[i]}',
        );
      }
      expect(keys.toSet().length, keys.length);
      expect(
        longest,
        lessThanOrEqualTo(FractionalIndex.maxHealthyLength),
        reason: 'longest key: $longest',
      );
    });

    test('1 000 appends and 1 000 prepends stay short and ordered', () {
      var last = FractionalIndex.between(null, null);
      final appended = [last];
      for (var i = 0; i < 1000; i++) {
        last = FractionalIndex.between(last, null);
        appended.add(last);
      }
      var first = appended.first;
      final prepended = <String>[];
      for (var i = 0; i < 1000; i++) {
        first = FractionalIndex.between(null, first);
        prepended.insert(0, first);
      }
      final all = [...prepended, ...appended];
      for (var i = 1; i < all.length; i++) {
        expect(all[i - 1].compareTo(all[i]), lessThan(0));
      }
      expect(all.map((k) => k.length).reduce(max), lessThan(12));
    });

    test('nBetween returns n sorted, distinct keys strictly inside (a, b)', () {
      final rnd = Random(7);
      final pool = <String>[];
      var k = FractionalIndex.between(null, null);
      for (var i = 0; i < 40; i++) {
        pool.add(k);
        k = FractionalIndex.between(k, null);
      }
      for (var round = 0; round < 300; round++) {
        final i = rnd.nextInt(pool.length);
        final j = i + 1 + rnd.nextInt(pool.length - i);
        final a = rnd.nextInt(6) == 0 ? null : pool[i];
        final b = j >= pool.length || rnd.nextInt(6) == 0 ? null : pool[j];
        final n = 1 + rnd.nextInt(40);
        final r = FractionalIndex.nBetween(a, b, n);
        expect(r.length, n);
        for (var x = 0; x < r.length; x++) {
          expect(FractionalIndex.isValid(r[x]), isTrue);
          if (a != null) expect(r[x].compareTo(a), greaterThan(0));
          if (b != null) expect(r[x].compareTo(b), lessThan(0));
          if (x > 0) expect(r[x - 1].compareTo(r[x]), lessThan(0));
        }
      }
    });

    test('inserting always between the same two neighbours grows the key, and isOversized notices', () {
      var a = 'a0';
      const b = 'a1';
      var oversizedAt = -1;
      for (var i = 0; i < 400; i++) {
        final k = FractionalIndex.between(a, b);
        if (FractionalIndex.isOversized(k) && oversizedAt < 0) oversizedAt = i;
        a = k;
      }
      expect(
        oversizedAt,
        greaterThan(50),
        reason: 'a hot spot needs many inserts before it matters',
      );
      // Re-spreading with nBetween restores short keys.
      final respread = FractionalIndex.nBetween(null, null, 200);
      expect(respread.every((k) => k.length <= 3), isTrue);
    });
  });
}
