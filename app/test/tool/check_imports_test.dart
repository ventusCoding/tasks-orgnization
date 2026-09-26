import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/check_imports.dart' as checker;

List<String> _rules(String path, String source) => [
  for (final v in checker.checkSource(path, source)) v.rule,
];

void main() {
  group('layer locations', () {
    test('parses feature and shared layers', () {
      final l = checker.LibLocation.parse('features/planner/domain/task.dart');
      expect((l.area, l.module, l.layer), ('features', 'planner', 'domain'));
      final s = checker.LibLocation.parse(
        'shared/filters/presentation/filter_bar.dart',
      );
      expect(
        (s.area, s.module, s.layer),
        ('shared', 'filters', 'presentation'),
      );
      final c = checker.LibLocation.parse('core/time/clock.dart');
      expect((c.area, c.module, c.layer), ('core', null, null));
    });

    test('resolves relative imports', () {
      final from = checker.LibLocation.parse(
        'features/tags/presentation/screen.dart',
      );
      expect(
        checker.resolveAppImport(from, '../data/repo.dart'),
        'features/tags/data/repo.dart',
      );
      expect(
        checker.resolveAppImport(from, 'package:everslot/core/ids/ids.dart'),
        'core/ids/ids.dart',
      );
      expect(
        checker.resolveAppImport(from, 'package:drift/drift.dart'),
        isNull,
      );
      expect(checker.resolveAppImport(from, 'dart:async'), isNull);
    });
  });

  group('domain rules', () {
    test('domain must be pure Dart', () {
      expect(
        _rules(
          'features/a/domain/x.dart',
          "import 'package:flutter/widgets.dart';",
        ),
        ['domain-pure'],
      );
      expect(
        _rules(
          'features/a/domain/x.dart',
          "import 'package:material_ui/material_ui.dart';",
        ),
        ['domain-pure'],
      );
      expect(
        _rules(
          'features/a/domain/x.dart',
          "import 'package:drift/drift.dart';",
        ),
        ['domain-pure'],
      );
      expect(
        _rules(
          'shared/f/domain/x.dart',
          "import 'package:flutter_riverpod/flutter_riverpod.dart';",
        ),
        ['domain-pure'],
      );
      expect(_rules('features/a/domain/x.dart', "import 'dart:ui';"), [
        'domain-pure',
      ]);
    });

    test('domain may use pure packages and domain-safe core', () {
      const source = '''
import 'dart:math';
import 'package:meta/meta.dart';
import 'package:collection/collection.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/b/domain/other.dart';
''';
      expect(_rules('features/a/domain/x.dart', source), isEmpty);
    });

    test('domain may not reach outer layers or infrastructure', () {
      expect(
        _rules('features/a/domain/x.dart', "import '../data/repo.dart';"),
        ['domain-layer'],
      );
      expect(
        _rules(
          'features/a/domain/x.dart',
          "import 'package:everslot/features/b/application/p.dart';",
        ),
        ['domain-layer'],
      );
      expect(
        _rules(
          'features/a/domain/x.dart',
          "import 'package:everslot/core/database/app_database.dart';",
        ),
        ['domain-layer'],
      );
      expect(
        _rules(
          'features/a/domain/x.dart',
          "import 'package:everslot/core/providers.dart';",
        ),
        ['domain-layer'],
      );
      expect(
        _rules(
          'features/a/domain/x.dart',
          "import 'package:everslot/design_system/tokens.dart';",
        ),
        ['domain-layer'],
      );
    });
  });

  group('presentation & cross-module rules', () {
    test('presentation may not import data layers or the database', () {
      expect(
        _rules('features/a/presentation/s.dart', "import '../data/repo.dart';"),
        ['presentation-data'],
      );
      expect(
        _rules(
          'features/a/presentation/s.dart',
          "import 'package:everslot/shared/f/data/r.dart';",
        ),
        ['presentation-data'],
      );
      expect(
        _rules(
          'features/a/presentation/s.dart',
          "import 'package:drift/drift.dart';",
        ),
        ['presentation-data'],
      );
      expect(
        _rules(
          'features/a/presentation/s.dart',
          "import 'package:everslot/core/database/app_database.dart';",
        ),
        ['presentation-data'],
      );
      expect(
        _rules(
          'features/a/presentation/s.dart',
          "import 'package:everslot/features/a/application/p.dart';",
        ),
        isEmpty,
      );
      expect(
        _rules(
          'features/a/presentation/s.dart',
          "import 'package:everslot/features/b/presentation/w.dart';",
        ),
        isEmpty,
      );
    });

    test('modules may not import another module data layer', () {
      expect(
        _rules(
          'features/a/application/p.dart',
          "import 'package:everslot/features/b/data/repo.dart';",
        ),
        ['foreign-data'],
      );
      expect(
        _rules(
          'shared/search/application/p.dart',
          "import 'package:everslot/features/b/data/repo.dart';",
        ),
        ['foreign-data'],
      );
      expect(
        _rules(
          'features/a/application/p.dart',
          "import 'package:everslot/features/a/data/repo.dart';",
        ),
        isEmpty,
      );
      expect(
        _rules(
          'features/a/data/r.dart',
          "import 'package:everslot/features/b/application/p.dart';",
        ),
        isEmpty,
      );
    });

    test('core and design_system stay independent of features', () {
      expect(
        _rules(
          'core/x.dart',
          "import 'package:everslot/features/a/application/p.dart';",
        ),
        ['core-independent'],
      );
      expect(
        _rules(
          'design_system/x.dart',
          "import 'package:everslot/shared/f/domain/d.dart';",
        ),
        ['core-independent'],
      );
      expect(
        _rules(
          'design_system/x.dart',
          "import 'package:everslot/core/providers.dart';",
        ),
        isEmpty,
      );
      expect(
        _rules(
          'app/router.dart',
          "import 'package:everslot/features/a/presentation/s.dart';",
        ),
        isEmpty,
      );
    });
  });

  group('directive parsing', () {
    test('multi-line and conditional directives are checked', () {
      const source = '''
import 'package:everslot/core/ids/ids.dart'
    if (dart.library.io) '../data/io_repo.dart';
export
  'package:flutter/widgets.dart';
''';
      final violations = checker.checkSource(
        'features/a/domain/x.dart',
        source,
      );
      expect(
        [for (final v in violations) (v.line, v.rule)],
        [(1, 'domain-layer'), (3, 'domain-pure')],
      );
    });

    test('comments and opt-outs are ignored', () {
      const source = '''
// import 'package:flutter/widgets.dart';
/* import 'package:drift/drift.dart'; */
import 'package:flutter/foundation.dart'; // boundary-ok: kDebugMode only
''';
      expect(_rules('features/a/domain/x.dart', source), isEmpty);
    });
  });

  group('RTL rules', () {
    String wrap(String body) => 'Widget build() => $body;';

    test('flags non-directional APIs', () {
      expect(
        _rules(
          'features/a/presentation/s.dart',
          wrap('Padding(padding: EdgeInsets.only(left: 8))'),
        ),
        ['rtl-insets'],
      );
      expect(
        _rules(
          'features/a/presentation/s.dart',
          wrap('Padding(padding: EdgeInsets.fromLTRB(8, 0, 4, 0))'),
        ),
        ['rtl-insets'],
      );
      expect(
        _rules(
          'features/a/presentation/s.dart',
          wrap('Align(alignment: Alignment.centerLeft)'),
        ),
        ['rtl-alignment'],
      );
      expect(
        _rules(
          'features/a/presentation/s.dart',
          wrap("Text('x', textAlign: TextAlign.right)"),
        ),
        ['rtl-text-align'],
      );
      expect(
        _rules(
          'features/a/presentation/s.dart',
          wrap('Positioned(left: 0, top: 0, child: x)'),
        ),
        ['rtl-positioned'],
      );
    });

    test('multi-line calls are inspected as a whole', () {
      const source = '''
final p = EdgeInsets.only(
  top: 4,
  right: Space.md,
);
''';
      final violations = checker.checkSource(
        'shared/x/presentation/w.dart',
        source,
      );
      expect(
        [for (final v in violations) (v.line, v.rule)],
        [(1, 'rtl-insets')],
      );
    });

    test('allows symmetric and directional variants, strings, comments and opt-outs', () {
      const source = '''
final a = EdgeInsets.only(bottom: 96);
final b = EdgeInsets.only(left: Space.md, right: Space.md);
final c = EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl);
final d = EdgeInsetsDirectional.only(start: 8);
final e = AlignmentDirectional.centerStart;
final f = Positioned(left: 0, right: 0, child: x);
final g = Positioned.fill(child: x);
final h = 'Alignment.centerLeft in a string';
// TextAlign.left in a comment
final i = EdgeInsets.only(left: 2); // rtl-ok: physical ruler edge
final j = TextAlign.start;
''';
      expect(_rules('features/a/presentation/s.dart', source), isEmpty);
    });

    test('masking keeps line structure', () {
      const source = "a('x // y');\n// c\nb(\"\"\"q\nr\"\"\");";
      final masked = checker.maskCommentsAndStrings(source);
      expect(masked.split('\n'), hasLength(source.split('\n').length));
      expect(masked, isNot(contains('//')));
      expect(masked, contains("a('")); // quotes kept, content blanked
    });
  });

  group('runner', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('boundaries'));
    tearDown(() => tmp.deleteSync(recursive: true));

    void write(String path, String content) => File('${tmp.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    test(
      'fails with file, line and rule for a deliberate forbidden import',
      () {
        write(
          'features/a/domain/entity.dart',
          "import 'package:flutter/widgets.dart';\n",
        );
        write(
          'features/a/data/repo.dart',
          "import 'package:drift/drift.dart';\n",
        );
        write(
          'features/a/application/providers.dart.g.dart',
          "import 'package:flutter/widgets.dart';\n",
        );
        final out = StringBuffer();
        final code = checker.run(['--lib', tmp.path], out);
        expect(code, 1);
        expect(
          out.toString(),
          contains('features/a/domain/entity.dart:1: [domain-pure]'),
        );
        expect(out.toString(), contains('1 boundary violation(s) in 2 files'));
      },
    );

    test('passes on a clean tree and rejects unknown arguments', () {
      write(
        'features/a/domain/entity.dart',
        "import 'package:meta/meta.dart';\n",
      );
      final out = StringBuffer();
      expect(checker.run(['--lib', tmp.path], out), 0);
      expect(out.toString(), contains('Boundaries OK: 1 files checked.'));
      expect(checker.run(['--bogus'], StringBuffer()), 2);
      expect(checker.run(['--lib', '${tmp.path}/missing'], StringBuffer()), 2);
    });

    test('the app source tree respects every boundary', () {
      final result = checker.checkLibDirectory(Directory('lib'));
      expect(result.files, greaterThan(50));
      expect(result.violations.map((v) => v.toString()), isEmpty);
    });
  });
}
