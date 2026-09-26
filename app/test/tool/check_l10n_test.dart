import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/check_l10n.dart' as checker;

/// CI localization check (T1.3.13): missing keys, placeholder mismatches and ICU syntax.
void main() {
  String arb(Map<String, Object?> m) => jsonEncode(m);

  final en = {
    'itemsCount': '{count, plural, =1{1 item} other{{count} items}}',
    '@itemsCount': {
      'placeholders': {
        'count': {'type': 'int'},
      },
    },
    'hello': 'Hello {name}',
    '@hello': {
      'placeholders': {
        'name': {'type': 'String'},
      },
    },
    'plain': "It isn't used",
  };
  final fr = {
    'itemsCount': '{count, plural, =1{1 élément} other{{count} éléments}}',
    'hello': 'Bonjour {name}',
    'plain': "Ce n'est pas utilisé",
  };
  final ar = {
    'itemsCount': '{count, plural, =0{لا شيء} =1{عنصر واحد} =2{عنصران} few{{count} عناصر} many{{count} عنصرًا} other{{count} عنصر}}',
    'hello': 'مرحبًا {name}',
    'plain': 'غير مستخدم',
  };

  Map<String, String> parts({
    Map<String, Object?>? enPart,
    Map<String, Object?>? frPart,
    Map<String, Object?>? arPart,
  }) => {
    'demo_en.arb': arb(enPart ?? en),
    'demo_fr.arb': arb(frPart ?? fr),
    'demo_ar.arb': arb(arPart ?? ar),
  };

  test('a complete, consistent set passes', () {
    expect(checker.checkParts(parts()), isEmpty);
  });

  test('missing and extra translations are reported', () {
    final problems = checker.checkParts(
      parts(frPart: {...fr}..remove('hello'), arPart: {...ar, 'stale': 'قديم'}),
    );
    expect(problems, [
      'demo_fr.arb: missing translation of "hello"',
      'demo_ar.arb: "stale" is not in the EN template',
    ]);
  });

  test('a missing locale file is reported', () {
    final files = parts()..remove('demo_ar.arb');
    expect(checker.checkParts(files), [
      'demo: missing demo_ar.arb (3 untranslated keys)',
    ]);
  });

  test('keys must be unique across areas', () {
    final files = {
      ...parts(),
      'other_en.arb': arb({'plain': 'x'}),
      'other_fr.arb': arb({'plain': 'x'}),
      'other_ar.arb': arb({'plain': 'x'}),
    };
    expect(checker.checkParts(files), [
      'other: key "plain" is already defined by demo',
    ]);
  });

  test('placeholder mismatches are reported', () {
    final problems = checker.checkParts(
      parts(
        frPart: {...fr, 'hello': 'Bonjour {nom}'},
        arPart: {...ar, 'itemsCount': '{count} عنصر'},
      ),
    );
    expect(problems, [
      'demo_fr.arb: "hello" uses placeholder "nom" unknown to the EN template',
      'demo_ar.arb: "itemsCount" must keep the plural argument "count"',
    ]);
  });

  test('undeclared template placeholders are reported', () {
    final problems = checker.checkParts(
      parts(enPart: {...en, 'plain': 'Used by {who}'}),
    );
    expect(problems, [
      'demo_en.arb: "plain" uses undeclared placeholder(s) who',
    ]);
  });

  group('ICU syntax', () {
    test('valid messages', () {
      expect(checker.IcuMessage.arguments('No args'), isEmpty);
      expect(checker.IcuMessage.arguments('{a} and {b}'), {
        'a': 'simple',
        'b': 'simple',
      });
      expect(
        checker.IcuMessage.arguments(
          '{n, plural, =0{none} other{{n} by {who}}}',
        ),
        {'n': 'plural', 'who': 'simple'},
      );
      expect(
        checker.IcuMessage.arguments(
          '{g, select, male{il} female{elle} other{iel}}',
        ),
        {'g': 'select'},
      );
      expect(checker.IcuMessage.arguments('{d, date, yMd}'), {'d': 'simple'});
    });

    for (final bad in [
      'Unclosed {name',
      'Stray } brace',
      '{n, plural, =1{one}}',
      '{n, plural, =1{one} =1{again} other{x}}',
      '{n, plural}',
      '{1bad}',
      '{n, bogus, x}',
      '{n, plural, other{unclosed}',
    ]) {
      test('rejects "$bad"', () {
        expect(() => checker.IcuMessage.arguments(bad), throwsFormatException);
      });
    }

    test('invalid ICU in a part is reported with its file and key', () {
      final problems = checker.checkParts(
        parts(frPart: {...fr, 'plain': 'Oups {'}),
      );
      expect(
        problems.single,
        startsWith('demo_fr.arb: "plain" is not valid ICU'),
      );
    });
  });

  group('runner', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('l10n_check'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('exit codes', () {
      for (final e in parts().entries) {
        File('${tmp.path}/${e.key}').writeAsStringSync(e.value);
      }
      final ok = StringBuffer();
      expect(checker.run(['--parts', tmp.path], ok), 0);
      expect(ok.toString(), contains('Localizations OK: 3 ARB parts checked.'));

      File('${tmp.path}/demo_ar.arb').deleteSync();
      final failed = StringBuffer();
      expect(checker.run(['--parts', tmp.path], failed), 1);
      expect(failed.toString(), contains('1 localization problem(s)'));

      expect(checker.run(['--bogus'], StringBuffer()), 2);
      expect(
        checker.run(['--parts', '${tmp.path}/missing'], StringBuffer()),
        2,
      );
    });
  });

  test('the app ARB parts are complete and consistent (EN/FR/AR)', () {
    final out = StringBuffer();
    final code = checker.run(['--parts', 'lib/l10n/parts'], out);
    expect(code, 0, reason: out.toString());
  });
}
