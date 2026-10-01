import 'package:drift/drift.dart' hide isNull;
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/database/search_index.dart';
import 'package:everslot/core/providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// T2.3.11: the global FTS5 index — every indexed table, multilingual matching (EN, FR accents,
/// AR letter variants and harakat), bm25 + recency ranking, tombstones, rebuild, 20 000 rows.
void main() {
  late TestHarness h;
  late SearchIndex index;
  setUp(() {
    h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 9));
    index = h.read(searchIndexProvider);
  });
  tearDown(() => h.dispose());

  final now = DateTime.utc(2026, 9, 22, 9);
  var seq = 0;
  String id() => 'id-${seq++}';

  Future<String> task(String title, {String? notes, DateTime? updated}) async {
    final i = id();
    await h.db
        .into(h.db.tasks)
        .insert(
          TasksCompanion.insert(
            id: i,
            userId: 'user-1',
            createdAt: now,
            updatedAt: updated ?? now,
            seriesId: i,
            title: title,
            notes: Value(notes),
          ),
        );
    return i;
  }

  Future<String> checklist(String title, {String? body}) async {
    final i = id();
    await h.db
        .into(h.db.checklists)
        .insert(
          ChecklistsCompanion.insert(
            id: i,
            userId: 'user-1',
            createdAt: now,
            updatedAt: now,
            sortKey: 'a0',
            title: Value(title),
            body: Value(body),
          ),
        );
    return i;
  }

  Future<String> item(String checklistId, String text, {String? note}) async {
    final i = id();
    await h.db
        .into(h.db.checklistItems)
        .insert(
          ChecklistItemsCompanion.insert(
            id: i,
            userId: 'user-1',
            createdAt: now,
            updatedAt: now,
            checklistId: checklistId,
            sortKey: 'a0',
            itemText: Value(text),
            note: Value(note),
          ),
        );
    return i;
  }

  Future<String> habit(String name, {String? description}) async {
    final i = id();
    await h.db
        .into(h.db.habits)
        .insert(
          HabitsCompanion.insert(
            id: i,
            userId: 'user-1',
            createdAt: now,
            updatedAt: now,
            kind: 'build',
            name: name,
            startDate: '2026-09-01',
            sortKey: 'a0',
            description: Value(description),
          ),
        );
    return i;
  }

  Future<String> log(String habitId, String note) async {
    final i = id();
    await h.db
        .into(h.db.habitLogs)
        .insert(
          HabitLogsCompanion.insert(
            id: i,
            userId: 'user-1',
            createdAt: now,
            updatedAt: now,
            habitId: habitId,
            kind: 'note',
            loggedAt: now,
            localDate: '2026-09-22',
            note: Value(note),
          ),
        );
    return i;
  }

  Future<List<String>> titles(String query, {Set<String>? types}) async => [
    for (final hit in await index.search(query, entityTypes: types)) hit.title,
  ];

  test('every indexed table, with parents; original titles are returned', () async {
    final t = await task('Call the plumber', notes: 'leaking kitchen sink');
    final c = await checklist('Trip to Lisbon', body: 'packing list');
    final i = await item(c, 'Passport', note: 'check the expiry date');
    final hb = await habit('Morning run', description: 'easy pace along the river');
    final l = await log(hb, 'Felt great by the river');

    final river = await index.search('river');
    expect({for (final hit in river) hit.entityId}, {hb, l});
    expect(river.firstWhere((x) => x.entityId == l).parentId, hb);
    expect((await index.search('pass')).single, isA<SearchMatch>().having((x) => x.entityId, 'id', i));
    expect((await index.search('pass')).single.parentId, c);
    expect((await index.search('sink')).single.entityId, t, reason: 'bodies are indexed');
    expect((await index.search('lisbon packing')).single.entityId, c, reason: 'all words must match');
    expect(await titles('river', types: {'habit'}), ['Morning run']);
    expect(await index.search('   '), isEmpty);
  });

  test('French accents and case are ignored both ways', () async {
    await task('Réunion équipe à Genève');
    await task('Crème brûlée');
    expect(await titles('reunion geneve'), ['Réunion équipe à Genève']);
    expect(await titles('RÉUNION'), ['Réunion équipe à Genève']);
    expect(await titles('creme brulee'), ['Crème brûlée']);
  });

  test('Arabic: alef / ya / ta marbuta variants, tatweel and harakat', () async {
    await task('أحمد في المدرسة');
    await task('مكتبة الجامعة');
    await habit('قراءة القرآن');
    await task('مستشفـــى');
    expect(await titles('احمد'), ['أحمد في المدرسة']);
    expect(await titles('إحمد'), ['أحمد في المدرسة']);
    expect(await titles('مكتبه'), ['مكتبة الجامعة'], reason: 'ta marbuta = ha');
    expect(await titles('قراءه القران'), ['قراءة القرآن']);
    expect(await titles('مستشفي'), ['مستشفـــى'], reason: 'tatweel removed, alef maqsura = ya');
    expect(await titles('مَكْتَبَة'), ['مكتبة الجامعة'], reason: 'harakat dropped from the query');
  });

  test('ranking: title matches beat body matches; recency breaks near-ties', () async {
    await task('Groceries', notes: 'milk eggs bread');
    await task('Buy milk');
    expect((await titles('milk')).first, 'Buy milk', reason: 'title weight 4×');

    await task('Dentist appointment', updated: now.subtract(const Duration(days: 300)));
    await task('Dentist appointment!', updated: now.subtract(const Duration(hours: 1)));
    final hits = await index.search('dentist');
    expect(hits.first.title, 'Dentist appointment!', reason: 'more recent first');
    expect(hits.first.score, greaterThan(hits.last.score));
  });

  test('tombstoned and hard-deleted rows leave the index; edits re-index', () async {
    final t = await task('Renew insurance');
    await (h.db.update(
      h.db.tasks,
    )..where((x) => x.id.equals(t))).write(const TasksCompanion(title: Value('Renew car insurance')));
    expect(await titles('car'), ['Renew car insurance']);
    await (h.db.update(h.db.tasks)..where((x) => x.id.equals(t))).write(TasksCompanion(deletedAt: Value(now)));
    expect(await index.search('insurance'), isEmpty);
    await (h.db.update(h.db.tasks)..where((x) => x.id.equals(t))).write(const TasksCompanion(deletedAt: Value(null)));
    expect(await titles('insurance'), ['Renew car insurance'], reason: 'restored from Trash');
    await (h.db.delete(h.db.tasks)..where((x) => x.id.equals(t))).go();
    expect(await index.count(), 0);
  });

  test('rebuild recreates the index from live rows only', () async {
    await task('Alpha');
    final gone = await task('Beta');
    await (h.db.update(h.db.tasks)..where((x) => x.id.equals(gone))).write(TasksCompanion(deletedAt: Value(now)));
    await h.db.customStatement('DELETE FROM search_index');
    expect(await index.count(), 0);
    await index.rebuild();
    expect(await index.count(), 1);
    expect(await titles('alpha'), ['Alpha']);
    expect(SearchIndexSchema.rebuildStatements.first, 'DELETE FROM search_index');
    expect(AppDatabase.searchIndexStatements, SearchIndexSchema.statements);
  });

  test('20 000 rows are searchable in under 100 ms', () async {
    const words = ['meeting', 'report', 'garden', 'invoice', 'travel', 'réunion', 'مكتبة', 'dentist'];
    await h.db.batch((b) {
      for (var n = 0; n < 20000; n++) {
        b.insert(
          h.db.tasks,
          TasksCompanion.insert(
            id: 'bulk-$n',
            userId: 'user-1',
            createdAt: now,
            updatedAt: now.subtract(Duration(minutes: n)),
            seriesId: 'bulk-$n',
            title: '${words[n % words.length]} $n',
            notes: Value('note ${words[(n * 7) % words.length]}'),
          ),
        );
      }
    });
    expect(await index.count(), 20000);
    await index.search('garden'); // warm-up (statement cache)
    final watch = Stopwatch()..start();
    final hits = await index.search('invoice');
    watch.stop();
    expect(hits, hasLength(50));
    expect(watch.elapsedMilliseconds, lessThan(100), reason: 'took ${watch.elapsedMilliseconds} ms');
  });
}
