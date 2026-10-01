import 'dart:math';

import 'package:everslot/features/integrations/domain/external_link.dart';
import 'package:flutter_test/flutter_test.dart';

/// External link policy (T8.2.01): canonical paths of arch §6.4 open, everything else is
/// rejected (and never throws).
void main() {
  const task = '0190b3c4-8a1e-7d33-9a8e-2b5f0e4c7d11';
  const list = '0190b3c4-8a1e-7d33-9a8e-2b5f0e4c7d12';
  const item = '0190b3c4-8a1e-7d33-9a8e-2b5f0e4c7d13';
  const habit = '0190b3c4-8a1e-7d33-9a8e-2b5f0e4c7d14';
  const hosts = {'everslot.example'};

  ExternalLinkDecision decide(String link) => ExternalLinkPolicy.decide(Uri.parse(link), webHosts: hosts);

  group('canonical paths open', () {
    final cases = <String, OpenPath>{
      'everslot://today': const OpenPath('/today', asRoot: true),
      'everslot://': const OpenPath('/today', asRoot: true),
      'everslot://plan/week?date=2026-09-22': const OpenPath('/plan/week?date=2026-09-22', asRoot: true),
      'everslot://plan/day?date=2026-09-22': const OpenPath('/plan/day?date=2026-09-22', asRoot: true),
      'everslot://plan/view/month?date=2026-09-01': const OpenPath('/plan/view/month?date=2026-09-01', asRoot: true),
      'everslot://task/$task?occ=2026-09-22T08%3A00': const OpenPath('/task/$task?occ=2026-09-22T08%3A00'),
      'everslot://task/$task?occ=week%3A2026-09-21%232': const OpenPath('/task/$task?occ=week%3A2026-09-21%232'),
      'everslot://task/$task/edit': const OpenPath('/task/$task/edit'),
      'everslot://task-new?start=2026-09-22T08%3A00&duration=30': const OpenPath(
        '/task-new?start=2026-09-22T08%3A00&duration=30',
      ),
      'everslot://lists': const OpenPath('/lists', asRoot: true),
      'everslot://lists/$list?item=$item': const OpenPath('/lists/$list?item=$item'),
      'everslot://lists/smart/waiting': const OpenPath('/lists/smart/waiting'),
      'everslot://habits': const OpenPath('/habits', asRoot: true),
      'everslot://habits/$habit': const OpenPath('/habits/$habit'),
      'everslot://habit-new?kind=quit': const OpenPath('/habit-new?kind=quit'),
      'everslot://quit/$habit': const OpenPath('/quit/$habit'),
      'everslot://insights': const OpenPath('/insights', asRoot: true),
      'everslot://insights/habit/$habit': const OpenPath('/insights/habit/$habit'),
      'everslot://insights/planner': const OpenPath('/insights/planner'),
      'everslot://inbox': const OpenPath('/inbox'),
      'everslot://search?q=report': const OpenPath('/search?q=report'),
      'everslot://settings': const OpenPath('/settings'),
      'everslot://settings/notifications': const OpenPath('/settings/notifications'),
      'https://everslot.example/habits/$habit': const OpenPath('/habits/$habit'),
      'https://everslot.example/today': const OpenPath('/today', asRoot: true),
    };
    for (final e in cases.entries) {
      test(e.key, () => expect(decide(e.key), e.value));
    }
  });

  group('invalid or unsafe links are rejected', () {
    final cases = [
      'everslot://admin/users',
      'everslot://task/not-a-uuid',
      'everslot://task/$task?occ=${'x' * 60}',
      'everslot://task/$task/delete',
      'everslot://lists/$list?item=../../etc',
      'everslot://plan/week?date=tomorrow',
      'everslot://plan/view/Month',
      'everslot://task-new?duration=-5',
      'everslot://task-new?start=yesterday',
      'everslot://habit-new?kind=evil',
      'everslot://insights/Habit',
      'everslot://settings/a/b',
      'everslot://dev',
      'everslot://onboarding',
      'everslot://auth/sign-in',
      'https://evil.example/habits/$habit',
      'http://everslot.example.evil.com/today',
      'mailto:someone@example.com',
      'javascript:alert(1)',
      'file:///etc/passwd',
      'everslot://search?q=${'a' * 2100}',
    ];
    for (final link in cases) {
      test(link.length > 80 ? '${link.substring(0, 80)}…' : link, () {
        expect(decide(link), isA<RejectLink>());
      });
    }
  });

  test('Supabase auth callbacks are left to the auth SDK', () {
    expect(decide('everslot://auth-callback?code=abc'), const IgnoreLink('auth'));
    expect(decide('everslot://login-callback#access_token=x'), const IgnoreLink('auth'));
  });

  group('commands', () {
    test('share', () => expect(decide('everslot://share'), const LinkCommand('share')));
    test('habit log by id and value', () {
      expect(
        decide('everslot://do/habit-log?habit=$habit&value=15'),
        const LinkCommand('habit-log', {'habit': habit, 'value': '15'}),
      );
    });
    test('habit log by spoken name', () {
      expect(
        decide('everslot://do/habit-log?name=push-ups&value=2,5'),
        const LinkCommand('habit-log', {'name': 'push-ups', 'value': '2,5'}),
      );
    });
    test('next / focus', () {
      expect(decide('everslot://do/next'), const LinkCommand('next'));
      expect(decide('everslot://do/focus'), const LinkCommand('focus'));
    });
    test('bad commands are rejected', () {
      expect(decide('everslot://do/format-disk'), isA<RejectLink>());
      expect(decide('everslot://do/habit-log?value=15'), isA<RejectLink>());
      expect(decide('everslot://do/habit-log?habit=$habit&value=-1'), isA<RejectLink>());
      expect(decide('everslot://do/habit-log?habit=$habit&value=NaN'), isA<RejectLink>());
      expect(decide('everslot://do/habit-log?habit=$habit&value=1e9'), isA<RejectLink>());
      expect(decide('everslot://do/next/extra'), isA<RejectLink>());
    });
  });

  test('entity refs for the deleted-item check', () {
    expect(const OpenPath('/task/$task?occ=2026-09-22').entity, const EntityRef('task', task));
    expect(const OpenPath('/lists/$list').entity, const EntityRef('checklist', list));
    expect(const OpenPath('/habits/$habit/edit').entity, const EntityRef('habit', habit));
    expect(const OpenPath('/quit/$habit').entity, const EntityRef('habit', habit));
    expect(const OpenPath('/lists/smart/waiting').entity, isNull);
    expect(const OpenPath('/inbox').entity, isNull);
  });

  test('fuzzed input never throws and never opens internal screens', () {
    final random = Random(8201);
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789-_/?&=#%:.@!~*()[]{}<>"\' ';
    final prefixes = ['everslot://', 'everslot:/', 'https://everslot.example/', 'https://', '', 'intent://'];
    for (var i = 0; i < 3000; i++) {
      final length = random.nextInt(120);
      final body = String.fromCharCodes([
        for (var j = 0; j < length; j++) alphabet.codeUnitAt(random.nextInt(alphabet.length)),
      ]);
      final raw = prefixes[random.nextInt(prefixes.length)] + body;
      final uri = Uri.tryParse(raw);
      if (uri == null) continue;
      final decision = ExternalLinkPolicy.decide(uri, webHosts: hosts);
      if (decision is OpenPath) {
        final path = Uri.parse(decision.path).path;
        expect(
          path.startsWith('/dev') || path.startsWith('/auth') || path.startsWith('/onboarding'),
          isFalse,
          reason: raw,
        );
        expect(ExternalLinkPolicy.validatePath(decision.path), isNull, reason: raw);
      }
    }
  });
}
