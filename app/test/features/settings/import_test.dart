import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/data/attachment_cache_store.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/settings/application/export_service.dart';
import 'package:everslot/features/settings/application/import_service.dart';
import 'package:everslot/features/settings/domain/import_plan.dart';
import 'package:everslot/features/settings/presentation/pages/data_page.dart';
import 'package:everslot/features/settings/presentation/pages/import_section.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../today/today_test_support.dart';

/// Columns that legitimately differ after a round trip (written by the importing device).
const _volatile = {'updated_at', 'origin_device_id'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Two devices (databases) per test.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory tmp;
  final harnesses = <TestHarness>[];
  final userA = Ids.v7();
  final userB = Ids.v7();

  setUp(() => tmp = Directory.systemTemp.createTempSync('everslot_import_'));

  tearDown(() async {
    for (final h in harnesses) {
      await h.dispose();
    }
    harnesses.clear();
    tmp.deleteSync(recursive: true);
  });

  TestHarness harness(String user, String name, {List<Override> extra = const []}) {
    final h = TestHarness.create(
      userId: user,
      overrides: [
        exportDirectoryProvider.overrideWithValue(() async => Directory('${tmp.path}/$name/exports')),
        appVersionLabelProvider.overrideWithValue(() async => '1.0.0+7'),
        attachmentFileStoreProvider.overrideWithValue(
          AttachmentFileStore(() async => Directory('${tmp.path}/$name/attachments')),
        ),
        importScratchDirectoryProvider.overrideWithValue(() async => Directory('${tmp.path}/$name/scratch')),
        ...extra,
      ],
    );
    harnesses.add(h);
    return h;
  }

  final habitId = Ids.v7();

  /// A bit of everything, with the deterministic ids the features write.
  Future<String> seed(TestHarness h) async {
    final taskId = await h.task('Standup', start: at(2026, 9, 22, 9), rule: RecurrenceRule());
    await h.read(occurrencesRepositoryProvider).skip(taskId, '2026-09-23T09:00', reason: 'holiday');
    await h.read(settingsRepositoryProvider).update(SettingsNs.privacy, {'crashReporting': false});
    final user = h.read(currentUserIdProvider);
    await h.read(syncWriterProvider).run((tx) async {
      await tx.insert('categories', Ids.v7(), {'name': 'Work', 'color': 1, 'sort_key': 'a0'});
      await tx.insert('tags', 'tag-1', {'name': 'focus', 'sort_key': 'a0'});
      await tx.insert('entity_tags', Ids.entityTag('tag-1', 'task', taskId), {
        'tag_id': 'tag-1',
        'entity_type': 'task',
        'entity_id': taskId,
      });
      await tx.insert('habits', habitId, {
        'kind': 'build',
        'name': 'Water',
        'start_date': '2026-09-01',
        'sort_key': 'a0',
        'schedule': {'v': 1},
        'settings': {'v': 1},
      });
      await tx.insert('habit_logs', Ids.habitDayState(habitId, '2026-09-22'), {
        'habit_id': habitId,
        'occurrence_key': '2026-09-22',
        'kind': 'done',
        'logged_at': DateTime.utc(2026, 9, 22, 8),
        'local_date': '2026-09-22',
      });
      await tx.insert('notifications', Ids.inbox('task|$taskId|2026-09-22T09:00|start'), {
        'dedupe_key': 'task|$taskId|2026-09-22T09:00|start',
        'section': 'planner',
        'title': 'Standup',
        'fire_at': DateTime.utc(2026, 9, 22, 9),
        'category': 'reminder',
        'source_type': 'task',
        'source_id': taskId,
        'payload': {'v': 1, 'taskId': taskId},
      });
      await tx.insert('saved_views', Ids.v5('$user|saved_view|planner|week'), {
        'section': 'planner',
        'name': 'Week',
        'view_type': 'week',
        'config': {'v': 1},
        'sort_key': 'a0',
      });
    });
    await h.read(syncWriterProvider).run((tx) => tx.insert('profiles', user, {'display_name': 'A'}));
    return taskId;
  }

  Future<Map<String, Object?>> exportJson(TestHarness h) async {
    final file = await h.read(exportServiceProvider).export(kind: ExportKind.json);
    return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  }

  Map<String, List<Map<String, Object?>>> normalized(Map<String, Object?> doc) => {
    for (final e in (doc['tables']! as Map).entries)
      e.key as String: [
        for (final r in e.value as List)
          {
            for (final c in (r as Map).entries)
              if (!_volatile.contains(c.key)) c.key as String: c.value,
          },
      ],
  };

  Future<ImportBundle> open(TestHarness h, TestHarness from) async =>
      h.read(importServiceProvider).open(await from.read(exportServiceProvider).export(kind: ExportKind.json));

  group('restore (T8.3.08)', () {
    test('export → wipe → import yields identical data', () async {
      final a = harness(userA, 'a');
      await seed(a);
      final before = await exportJson(a);

      final fresh = harness(userA, 'fresh');
      final bundle = await open(fresh, a);
      final preview = await fresh.read(importServiceProvider).preview(bundle, ImportMode.restore);
      expect(preview.sameAccount, isTrue);
      expect(preview.total.added, bundle.document.rowCount);
      await fresh.read(importServiceProvider).apply(bundle, ImportMode.restore);

      final after = await exportJson(fresh);
      expect(normalized(after), normalized(before));
      final outbox = await fresh.db.select(fresh.db.syncOutbox).get();
      expect(outbox, hasLength(bundle.document.rowCount), reason: 'every row is pushed');
    });

    test('per-row last writer wins; "replace newer" overrides; identical rows are left alone', () async {
      final a = harness(userA, 'a');
      final taskId = await seed(a);
      final bundle = await open(a, a);
      a.clock.advance(const Duration(minutes: 5));
      await a.read(syncWriterProvider).run((tx) => tx.update('tasks', taskId, {'title': 'Daily standup'}));
      await a.read(syncWriterProvider).run((tx) => tx.softDelete('tags', 'tag-1'));

      final service = a.read(importServiceProvider);
      final keep = await service.preview(bundle, ImportMode.restore);
      expect(keep.tables['tasks'], const ImportTableCounts(keptLocal: 1));
      expect(keep.tables['tags'], const ImportTableCounts(keptLocal: 1));
      expect(keep.tables['categories'], const ImportTableCounts(unchanged: 1));
      await service.apply(bundle, ImportMode.restore);
      expect((await a.db.select(a.db.tasks).getSingle()).title, 'Daily standup');

      final replace = await service.apply(bundle, ImportMode.restore, replaceNewer: true);
      expect(replace.tables['tasks'], const ImportTableCounts(updated: 1));
      expect((await a.db.select(a.db.tasks).getSingle()).title, 'Standup');
      expect((await a.db.select(a.db.tags).getSingle()).deletedAt, isNull, reason: 'deleted row restored');
    });

    test('older local rows are updated from the export', () async {
      final a = harness(userA, 'a');
      final taskId = await seed(a);
      final copy = harness(userA, 'b');
      final bundle = await open(copy, a);
      await copy.read(importServiceProvider).apply(bundle, ImportMode.restore);
      // The export is newer than this device's edit.
      a.clock.advance(const Duration(minutes: 5));
      await a.read(syncWriterProvider).run((tx) => tx.update('tasks', taskId, {'title': 'Renamed'}));
      final newer = await open(copy, a);
      final preview = await copy.read(importServiceProvider).preview(newer, ImportMode.restore);
      expect(preview.tables['tasks'], const ImportTableCounts(updated: 1));
    });

    test('restore of another account is refused', () async {
      final a = harness(userA, 'a');
      await seed(a);
      final b = harness(userB, 'b');
      final bundle = await open(b, a);
      expect(b.read(importServiceProvider).sameAccount(bundle), isFalse);
      expect(() => b.read(importServiceProvider).preview(bundle, ImportMode.restore), throwsStateError);
    });
  });

  group('copy (T8.3.08)', () {
    test('new ids, references rewritten, deterministic ids re-derived, nothing collides', () async {
      final a = harness(userA, 'a');
      final oldTask = await seed(a);
      final b = harness(userB, 'b');
      final ownTask = await b.task('Mine');
      await b.read(settingsRepositoryProvider).update(SettingsNs.privacy, {'appLockEnabled': true});
      final bundle = await open(b, a);

      final preview = await b.read(importServiceProvider).preview(bundle, ImportMode.copy);
      expect(preview.sameAccount, isFalse);
      expect(preview.tables['profiles'], const ImportTableCounts(skipped: 1));
      expect(preview.tables['saved_views'], const ImportTableCounts(skipped: 1), reason: 'built-in view');
      expect(preview.tables['user_settings'], const ImportTableCounts(updated: 1), reason: 'merged with mine');
      await b.read(importServiceProvider).apply(bundle, ImportMode.copy);

      final tasks = await b.db.select(b.db.tasks).get();
      expect(tasks, hasLength(2));
      final copied = tasks.firstWhere((t) => t.id != ownTask);
      expect(copied.id, isNot(oldTask));
      expect(copied.seriesId, copied.id, reason: 'self reference rewritten');
      expect(copied.userId, userB);

      final occ = await b.db.select(b.db.taskOccurrences).getSingle();
      expect(occ.taskId, copied.id);
      expect(occ.id, Ids.taskOccurrence(copied.id, '2026-09-23T09:00'));

      final link = await b.db.select(b.db.entityTags).getSingle();
      expect(link.entityId, copied.id);
      expect(link.id, Ids.entityTag(link.tagId, 'task', copied.id));

      final log = await b.db.select(b.db.habitLogs).getSingle();
      expect(log.habitId, isNot(habitId));
      expect(log.id, Ids.habitDayState(log.habitId, '2026-09-22'));

      final inbox = await b.db.select(b.db.notifications).getSingle();
      expect(inbox.dedupeKey, 'task|${copied.id}|2026-09-22T09:00|start');
      expect(inbox.id, Ids.inbox(inbox.dedupeKey));
      expect(inbox.sourceId, copied.id);
      expect(jsonDecode(inbox.payload), {'v': 1, 'taskId': copied.id}, reason: 'ids inside JSON');

      final settings = await b.db.select(b.db.userSettings).get();
      final privacy = settings.singleWhere((s) => s.namespace == SettingsNs.privacy);
      expect(privacy.id, Ids.userSetting(userB, SettingsNs.privacy));
      expect(jsonDecode(privacy.value), containsPair('crashReporting', false));

      // Copying the same export again duplicates the data under fresh ids.
      await b.read(importServiceProvider).apply(await open(b, a), ImportMode.copy);
      expect(await b.db.select(b.db.tasks).get(), hasLength(3));
      expect(await b.db.select(b.db.taskOccurrences).get(), hasLength(2));
    });
  });

  group('IdRemapper', () {
    ExportDocument doc(Map<String, List<Map<String, Object?>>> tables) =>
        ExportDocument(schemaVersion: 6, exportedAt: null, appVersion: '', tables: tables);

    test('reference cycles fall back to new ids; unknown ids stay', () {
      var n = 0;
      final r = IdRemapper(
        document: doc({
          'x': [
            {'id': 'a', 'ref': 'b'},
            {'id': 'b', 'ref': 'a'},
          ],
        }),
        oldUser: 'old',
        newUser: 'new',
        recipes: {
          'x': (row, ref, u) => [ref('${row['ref']}')],
        },
        v5: (name) => 'v5:$name',
        v7: () => 'n${n++}',
      );
      final a = r.idOf('a');
      expect(a, isNot('a'));
      expect(r.idOf('a'), a, reason: 'stable');
      expect(r.idOf('zzz'), 'zzz');
      expect(r.idOf('old'), 'new');
      expect(
        r.remapValue({
          'list': ['old', 'b', 7],
        }),
        {
          'list': ['new', r.idOf('b'), 7],
        },
      );
    });
  });

  group('opening files', () {
    test('a CSV export, junk or another format are rejected with a reason', () async {
      final h = harness(userA, 'a');
      Future<String?> reason(List<int> bytes) async {
        final f = File('${tmp.path}/in.bin')..writeAsBytesSync(bytes);
        try {
          await h.read(importServiceProvider).open(f);
          return null;
        } on FormatException catch (e) {
          return e.message;
        }
      }

      final csvZip = ZipEncoder().encodeBytes(Archive()..add(ArchiveFile.bytes('manifest.json', utf8.encode('{}'))));
      expect(await reason(csvZip), 'csv_export');
      expect(await reason(utf8.encode('hello')), 'not_an_export');
      expect(await reason(utf8.encode('{"format":"other"}')), 'unsupported_format');
    });

    test('a zip export brings its attachment files back', () async {
      final a = harness(userA, 'a');
      await seed(a);
      final attId = Ids.v7();
      await a
          .read(syncWriterProvider)
          .run(
            (tx) => tx.insert('attachments', attId, {
              'owner_type': 'habit',
              'owner_id': habitId,
              'storage_path': '$userA/$attId/photo.jpg',
              'file_name': 'photo.jpg',
              'mime_type': 'image/jpeg',
              'byte_size': 3,
              'sort_key': 'a0',
              'uploaded_at': DateTime.utc(2026, 9, 22),
            }),
          );
      final store = a.read(attachmentFileStoreProvider);
      await store.writeBytes('$attId/photo.jpg', Uint8List.fromList([1, 2, 3]));
      final zip = await a.read(exportServiceProvider).export(kind: ExportKind.json, includeAttachments: true);

      final b = harness(userB, 'b');
      final bundle = await b.read(importServiceProvider).open(zip);
      expect(bundle.files, hasLength(1));
      await b.read(importServiceProvider).apply(bundle, ImportMode.copy);
      final att = await b.db.select(b.db.attachments).getSingle();
      expect(att.id, isNot(attId));
      expect(att.storagePath, '$userB/${att.id}/photo.jpg');
      expect(att.uploadedAt, isNull, reason: 'uploaded again to the new account');
      expect(await b.read(attachmentFileStoreProvider).exists('${att.id}/photo.jpg'), isTrue);
      final cached = await b.read(attachmentCacheStoreProvider).get(att.id);
      expect(cached?.uploadState, 'pending');
    });
  });

  group('UI', () {
    testWidgets('pick → preview → copy into another account', (tester) async {
      late File file;
      late TestHarness b;
      await tester.runAsync(() async {
        final a = harness(userA, 'a');
        await seed(a);
        file = await a.read(exportServiceProvider).export(kind: ExportKind.json);
        b = harness(userB, 'b', extra: [importFilePickerProvider.overrideWithValue(() async => file)]);
      });
      await pumpInApp(tester, b, const DataPage());
      Future<void> settle() async {
        for (var i = 0; i < 30; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await tester.scrollUntilVisible(find.byKey(const ValueKey('import-pick')), 200);
      await tester.tap(find.byKey(const ValueKey('import-pick')));
      await settle();
      expect(find.byKey(const ValueKey('import-preview')), findsOneWidget);
      final restore = tester.widget<RadioListTile<ImportMode>>(find.byKey(const ValueKey('import-restore')));
      expect(restore.enabled, isFalse, reason: 'another account');
      expect(find.text('Only for backups of this account.'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('import-run')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('import-run')));
      await settle();
      expect(find.byKey(const ValueKey('import-preview')), findsNothing);
      expect(find.textContaining('items imported'), findsOneWidget);
      final tasks = await tester.runAsync(() => b.db.select(b.db.tasks).get());
      expect(tasks, hasLength(1));
    });
  });
}
