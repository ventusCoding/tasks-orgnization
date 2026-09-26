import 'dart:math';

import 'package:everslot/core/routing/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deep-link parser (T1.3.07) and builder ↔ parser round-trips (T2.3.12).
void main() {
  group('DeepLinkParser table', () {
    final cases = <String, String?>{
      // Canonical paths of arch §6.4 through the custom scheme.
      'everslot://today': '/today',
      'everslot://plan/week?date=2026-09-22': '/plan/week?date=2026-09-22',
      'everslot://plan/day?date=2026-09-22': '/plan/day?date=2026-09-22',
      'everslot://task/0190b3c4?occ=2026-09-22T08%3A00':
          '/task/0190b3c4?occ=2026-09-22T08%3A00',
      'everslot://lists/l1?item=i1': '/lists/l1?item=i1',
      'everslot://habits/h1': '/habits/h1',
      'everslot://insights/habit/h1': '/insights/habit/h1',
      'everslot://inbox': '/inbox',
      'everslot://settings/notifications': '/settings/notifications',
      'everslot://search?q=report': '/search?q=report',
      // Universal / app links and bare paths.
      'https://everslot.app/habits/h1': '/habits/h1',
      'http://everslot.app/task/t1': '/task/t1',
      '/lists/l1': '/lists/l1',
      // Empty → Today.
      'everslot://': '/today',
      'https://everslot.app/': '/today',
      // Unknown roots, schemes and traversal are rejected.
      'everslot://admin/users': null,
      'mailto:someone@example.com': null,
      'javascript:alert(1)': null,
      'file:///etc/passwd': null,
      // Dot segments are resolved by URI normalization and cannot leave the root.
      'everslot://task/../settings': '/task/settings',
      'https://everslot.app/lists/..%2F..': null,
    };
    for (final e in cases.entries) {
      test('${e.key} → ${e.value}', () {
        expect(DeepLinkParser.parse(Uri.parse(e.key)), e.value);
      });
    }

    test('oversized links and segments are rejected', () {
      expect(
        DeepLinkParser.parse(Uri.parse('everslot://search?q=${'a' * 2100}')),
        isNull,
      );
      expect(
        DeepLinkParser.parse(Uri.parse('everslot://task/${'x' * 201}')),
        isNull,
      );
    });

    test('oversized or odd query parameters are dropped, not trusted', () {
      final long = 'v' * 257;
      expect(
        DeepLinkParser.parse(Uri.parse('everslot://inbox?filter=$long')),
        '/inbox',
      );
      final key = 'k' * 33;
      expect(
        DeepLinkParser.parse(Uri.parse('everslot://inbox?$key=1&a=2')),
        '/inbox?a=2',
      );
    });

    test('empty segments collapse', () {
      expect(
        DeepLinkParser.parse(Uri.parse('everslot://plan//week')),
        '/plan/week',
      );
    });
  });

  group('fuzz', () {
    const alphabet =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        r'-._~:/?#[]@!$&()*+,;=%<> "{}|\^`'
        'éàçعربي\u0000\u200f';

    String randomString(Random r, int maxLength) => String.fromCharCodes([
      for (var i = 0; i < r.nextInt(maxLength); i++)
        alphabet.codeUnitAt(r.nextInt(alphabet.length)),
    ]);

    test('random strings never throw', () {
      final r = Random(1303);
      var parsed = 0;
      for (var i = 0; i < 20000; i++) {
        final prefix = switch (r.nextInt(5)) {
          0 => 'everslot://',
          1 => 'https://everslot.app/',
          2 => '/',
          3 => 'everslot:',
          _ => '',
        };
        final uri = Uri.tryParse(prefix + randomString(r, 80));
        if (uri == null) continue;
        parsed++;
        final result = DeepLinkParser.parse(uri);
        if (result != null) {
          // Whatever is accepted is a rooted router path of an allowed root.
          expect(result, startsWith('/'));
          expect(result.length, lessThanOrEqualTo(2048 + 64));
        }
      }
      expect(parsed, greaterThan(1000));
    });

    test('malformed percent-encoding in the query never throws', () {
      for (final raw in [
        'everslot://search?q=%',
        'everslot://search?q=%E0%A4%A',
        'everslot://search?q=%zz',
        'everslot://search?%ff=1',
        'everslot://task/%C3%28',
      ]) {
        final uri = Uri.tryParse(raw);
        if (uri == null) continue;
        expect(() => DeepLinkParser.parse(uri), returnsNormally, reason: raw);
      }
    });
  });

  group('builders ↔ parser round-trip (property)', () {
    final r = Random(2312);
    const hex = '0123456789abcdef';
    String id() {
      String block(int n) => String.fromCharCodes([
        for (var i = 0; i < n; i++) hex.codeUnitAt(r.nextInt(16)),
      ]);
      return '${block(8)}-${block(4)}-7${block(3)}-8${block(3)}-${block(12)}';
    }

    String date() {
      final d = DateTime.utc(2020).add(Duration(days: r.nextInt(3650)));
      return d.toIso8601String().substring(0, 10);
    }

    String occurrenceKey() =>
        '${date()}T${r.nextInt(24).toString().padLeft(2, '0')}:'
        '${r.nextInt(60).toString().padLeft(2, '0')}';

    String query() {
      const words = [
        'report',
        'café',
        'تقرير',
        'a b',
        'x&y=z',
        '#1',
        'c++',
        '50%',
        '"exact"',
      ];
      return [
        for (var i = 0; i <= r.nextInt(3); i++) words[r.nextInt(words.length)],
      ].join(' ');
    }

    T? maybe<T>(T Function() value) => r.nextBool() ? value() : null;

    final builders = <String Function()>[
      AppLinks.today,
      () => AppLinks.planWeek(date: maybe(date)),
      () => AppLinks.planDay(date: maybe(date)),
      () => AppLinks.planView(
        ['week_table', 'month', 'agenda', 'kanban'][r.nextInt(4)],
        date: maybe(date),
      ),
      () => AppLinks.task(id(), occurrenceKey: maybe(occurrenceKey)),
      () => AppLinks.taskEdit(id()),
      () => AppLinks.taskNew(
        start: maybe(occurrenceKey),
        duration: maybe(() => 1 + r.nextInt(1440)),
        allDay: r.nextBool(),
      ),
      AppLinks.lists,
      () => AppLinks.checklist(id(), itemId: maybe(id), preview: r.nextBool()),
      () => AppLinks.smartList(['waiting', 'blocked', 'due'][r.nextInt(3)]),
      AppLinks.habits,
      () => AppLinks.habit(id()),
      () => AppLinks.habitNew(kind: r.nextBool() ? 'build' : 'quit'),
      () => AppLinks.habitEdit(id()),
      () => AppLinks.quit(id()),
      AppLinks.insights,
      () => AppLinks.insightsScope(
        ['task', 'checklist', 'habit', 'planner'][r.nextInt(4)],
        maybe(id),
      ),
      AppLinks.inbox,
      () => AppLinks.search(query: maybe(query)),
      () => AppLinks.settings(
        maybe(() => ['sync', 'notifications', 'about'][r.nextInt(3)]),
      ),
      AppLinks.trash,
      AppLinks.categories,
      AppLinks.tags,
      AppLinks.signIn,
      AppLinks.onboarding,
      AppLinks.debug,
    ];

    test(
      'every builder output survives the external scheme and the parser',
      () {
        for (var i = 0; i < 3000; i++) {
          final path = builders[i % builders.length]();
          final external = AppLinks.external(path);
          expect(external.scheme, AppLinks.scheme);
          expect(
            DeepLinkParser.parse(external),
            path,
            reason: 'external: $external',
          );
          // In-app paths and universal links parse to the same location.
          expect(DeepLinkParser.parse(Uri.parse(path)), path);
          expect(
            DeepLinkParser.parse(Uri.parse('https://everslot.app$path')),
            path,
          );
        }
      },
    );

    test('query values keep their exact text', () {
      final path = AppLinks.search(query: 'x&y=z café تقرير "a b"');
      final parsed = DeepLinkParser.parse(AppLinks.external(path))!;
      expect(Uri.parse(parsed).queryParameters['q'], 'x&y=z café تقرير "a b"');
      final task = AppLinks.task('t1', occurrenceKey: '2026-09-22T08:00');
      final parsedTask = DeepLinkParser.parse(AppLinks.external(task))!;
      expect(Uri.parse(parsedTask).queryParameters['occ'], '2026-09-22T08:00');
    });
  });
}
