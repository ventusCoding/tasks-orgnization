import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/settings/application/export_service.dart';
import 'package:everslot/features/settings/domain/export_format.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import 'support/json_schema_lite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late TestHarness h;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('everslot_export_');
    h = TestHarness.create(
      overrides: [
        exportDirectoryProvider.overrideWithValue(() async => Directory('${tmp.path}/exports')),
        appVersionLabelProvider.overrideWithValue(() async => '1.0.0+7'),
        attachmentFileStoreProvider.overrideWithValue(AttachmentFileStore(() async => Directory('${tmp.path}/attachments'))),
      ],
    );
  });

  tearDown(() async {
    await h.dispose();
    tmp.deleteSync(recursive: true);
  });

  Future<void> seed() => h.read(syncWriterProvider).run((tx) async {
    await tx.insert('categories', 'c1', {'name': 'Work, "deep" focus', 'color': 1, 'sort_key': 'a0'});
    await tx.insert('categories', 'c2', {'name': 'عمل\nالمنزل', 'color': 2, 'sort_key': 'a1'});
    await tx.insert('categories', 'gone', {'name': 'Deleted', 'color': 3, 'sort_key': 'a2'});
    await tx.softDelete('categories', 'gone');
    await tx.insert('checklists', 'L', {'title': '=SUM(A1)', 'sort_key': 'a0', 'settings': {'v': 1, 'progressMode': 'leaves'}});
    await tx.insert('tasks', 'T', {'series_id': 'T', 'title': 'Call mom', 'is_all_day': true});
  });

  group('CSV (T8.3.07)', () {
    test('commas, quotes, newlines, RTL text and formulas are escaped', () {
      expect(Csv.cell('plain'), 'plain');
      expect(Csv.cell('a,b'), '"a,b"');
      expect(Csv.cell('say "hi"'), '"say ""hi"""');
      expect(Csv.cell('line1\nline2'), '"line1\nline2"');
      expect(Csv.cell('مرحبا، عالم'), 'مرحبا، عالم', reason: 'the Arabic comma is not a separator');
      expect(Csv.cell('مرحبا, عالم'), '"مرحبا, عالم"');
      expect(Csv.cell('=HYPERLINK("x")'), '"\'=HYPERLINK(""x"")"');
      expect(Csv.cell('-3'), "'-3", reason: 'a text cell that looks like a formula');
      expect(Csv.cell(-3), '-3', reason: 'numbers are numbers');
      expect(Csv.cell(true), 'true');
      expect(Csv.cell(null), '');
      expect(Csv.cell({'a': 1}), '"{""a"":1}"');
      final csv = Csv.encode(['ID', 'Name'], [
        ['1', 'x'],
        ['2', 'y,z'],
      ]);
      expect(csv, '﻿ID,Name\r\n1,x\r\n2,"y,z"\r\n');
    });

    test('human column names', () {
      expect(Csv.humanize('id'), 'ID');
      expect(Csv.humanize('start_local'), 'Start local');
      expect(Csv.humanize('checklist_id'), 'Checklist ID');
    });
  });

  test('JSON export validates against fixtures/schemas/export-v1.json', () async {
    await seed();
    final progress = <({int done, int total})>[];
    final file = await h.read(exportServiceProvider).export(kind: ExportKind.json, onProgress: progress.add);
    expect(file.path, endsWith('.json'));
    final doc = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    final schema = jsonDecode(File('../fixtures/schemas/export-v1.json').readAsStringSync()) as Map<String, Object?>;
    expect(validateJsonSchema(doc, schema), isEmpty);
    expect(doc['format'], 'everslot-export-v1');
    expect(doc['app_version'], '1.0.0+7');
    final tables = doc['tables']! as Map<String, Object?>;
    final categories = (tables['categories']! as List).cast<Map<String, Object?>>();
    expect([for (final c in categories) c['id']], ['c1', 'c2'], reason: 'tombstones are not exported');
    expect(categories.first.keys, isNot(contains('field_clock')));
    final task = (tables['tasks']! as List).single as Map<String, Object?>;
    expect(task['is_all_day'], isTrue, reason: 'booleans as booleans');
    final list = (tables['checklists']! as List).single as Map<String, Object?>;
    expect(list['settings'], {'v': 1, 'progressMode': 'leaves'}, reason: 'JSON columns as objects');
    expect((doc['counts']! as Map)['categories'], 2);
    expect(progress.last.done, progress.last.total);
    expect(progress.last.total, greaterThanOrEqualTo(4));
  });

  test('CSV export: one file per table, human headers, escaped cells', () async {
    await seed();
    final file = await h.read(exportServiceProvider).export(kind: ExportKind.csv);
    expect(file.path, endsWith('.zip'));
    final zip = ZipDecoder().decodeBytes(await file.readAsBytes());
    final names = [for (final f in zip.files) f.name];
    expect(names, containsAll(['categories.csv', 'tasks.csv', 'checklists.csv', 'manifest.json']));
    final raw = zip.findFile('categories.csv')!.content as List<int>;
    expect(raw.take(3), [0xEF, 0xBB, 0xBF], reason: 'UTF-8 BOM for spreadsheets');
    final categories = utf8.decode(raw);
    expect(categories.split('\r\n').first, startsWith('ID,Created at,Updated at,Deleted at,'));
    expect(categories, contains('"Work, ""deep"" focus"'));
    expect(categories, contains('"عمل\nالمنزل"'));
    final lists = utf8.decode(zip.findFile('checklists.csv')!.content as List<int>);
    expect(lists, contains("'=SUM(A1)"));
  });

  test('attachments can be included (zip with the local files)', () async {
    await seed();
    await h.read(syncWriterProvider).run(
      (tx) => tx.insert('attachments', 'att1', {
        'owner_type': 'checklist',
        'owner_id': 'L',
        'storage_path': 'u/att1/photo.jpg',
        'file_name': 'photo.jpg',
        'mime_type': 'image/jpeg',
        'byte_size': 3,
        'sort_key': 'a0',
      }),
    );
    File('${tmp.path}/attachments/att1/photo.jpg')
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    File('${tmp.path}/attachments/att1/thumb.jpg').writeAsBytesSync([9]);
    final file = await h.read(exportServiceProvider).export(kind: ExportKind.json, includeAttachments: true);
    final zip = ZipDecoder().decodeBytes(await file.readAsBytes());
    expect([for (final f in zip.files) f.name]..sort(), ['attachments/att1/photo.jpg', 'everslot-export.json']);
    expect(zip.findFile('attachments/att1/photo.jpg')!.content, [1, 2, 3]);
  });

  test('100 000 rows export in under 20 s with progress', () async {
    final db = h.db;
    await db.transaction(() async {
      for (var chunk = 0; chunk < 100; chunk++) {
        final values = [
          for (var i = 0; i < 1000; i++)
            "('p${chunk}_$i', 'user-1', '2026-09-22T09:00:00.000Z', '2026-09-22T09:00:00.000Z', 'Category $chunk $i', ${i % 12}, 'a$i')",
        ].join(',');
        await db.customStatement(
          'INSERT INTO categories (id, user_id, created_at, updated_at, name, color, sort_key) VALUES $values',
        );
      }
    });
    final watch = Stopwatch()..start();
    var updates = 0;
    final file = await h.read(exportServiceProvider).export(kind: ExportKind.json, onProgress: (_) => updates++);
    watch.stop();
    expect(watch.elapsed, lessThan(const Duration(seconds: 20)));
    expect(updates, greaterThan(50), reason: 'progress per page');
    final doc = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    expect(((doc['tables']! as Map)['categories']! as List).length, 100000);
    // ignore: avoid_print
    print('export of 100000 rows: ${watch.elapsedMilliseconds} ms');
  }, timeout: const Timeout(Duration(seconds: 120)));
}
