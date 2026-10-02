import 'package:drift/drift.dart' hide isNull;
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/database/search_index.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/search/application/search_providers.dart';
import 'package:everslot/features/search/domain/search_models.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../today/today_test_support.dart';

/// T8.1.14–15: enriched global search — breadcrumbs, links, inbox entries, snippets, filters data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  final now = DateTime.utc(2026, 9, 22, 9);
  setUp(() => h = TestHarness.create(now: now));
  tearDown(() => h.dispose());

  Future<List<SearchResult>> search(String q, {Set<SearchKind>? kinds}) =>
      h.read(globalSearchQueriesProvider).search(q, kinds: kinds);

  Future<void> inbox(String id, String title, {String? body, String? link, bool read = false}) => h.db
      .into(h.db.notifications)
      .insert(
        NotificationsCompanion.insert(
          id: id,
          userId: userOf(h),
          createdAt: now,
          updatedAt: now,
          dedupeKey: id,
          category: 'reminder',
          title: title,
          body: Value(body),
          payload: Value(link == null ? '{}' : '{"link":"$link"}'),
          fireAt: DateTime.utc(2026, 9, 21, 7),
          readAt: Value(read ? now : null),
        ),
      );

  test('checklist items carry the list title and ancestor path, and open the item', () async {
    final trip =
        (await h
                .read(checklistsRepositoryProvider)
                .create(
                  title: 'Trip',
                  items: [
                    const NodeSpec(
                      text: 'Documents',
                      children: [
                        NodeSpec(
                          text: 'Visa',
                          children: [NodeSpec(text: 'Passport photo')],
                        ),
                      ],
                    ),
                  ],
                ))
            .id;
    final photo = await h.itemId(trip, 'Passport photo');
    final r = (await search('passport')).single;
    expect(r.kind, SearchKind.item);
    expect(r.breadcrumb, ['Trip', 'Documents', 'Visa']);
    expect(r.parentId, trip);
    expect(r.link, '/lists/$trip?item=$photo');
    expect(r.closed, isFalse);
    await h.setItemStatus(trip, photo, ItemStatus.completed);
    expect((await search('passport')).single.closed, isTrue);
  });

  test('every kind is found and links where it lives; quit trackers open the quit screen', () async {
    final task = await h.task('Dentist appointment', start: at(2026, 9, 25, 10));
    final list = await h.checklist('Dentist questions');
    await h.habit('Dentist floss', start: LocalDate(2026, 9, 1));
    await h.quitTracker('Dentist candy', quitAt: DateTime.utc(2026, 9, 1), start: LocalDate(2026, 9, 1));
    await inbox('n1', 'Dentist reminder', link: '/task/$task');
    final results = await search('dentist');
    final byKind = {for (final r in results) r.title: r};
    expect(
      byKind.keys,
      containsAll(['Dentist appointment', 'Dentist questions', 'Dentist floss', 'Dentist candy', 'Dentist reminder']),
    );
    expect(byKind['Dentist appointment']!.link, startsWith('/task/$task'));
    expect(byKind['Dentist appointment']!.day, LocalDate(2026, 9, 25), reason: 'tasks: start day');
    expect(byKind['Dentist questions']!.link, '/lists/$list');
    expect(byKind['Dentist floss']!.link, '/habits/habit-Dentist floss');
    expect(byKind['Dentist candy']!.link, '/quit/quit-Dentist candy');
    expect(byKind['Dentist candy']!.quit, isTrue);
    expect(byKind['Dentist reminder']!.kind, SearchKind.inbox);
    expect(byKind['Dentist reminder']!.link, '/task/$task');
    expect(byKind['Dentist reminder']!.day, LocalDate(2026, 9, 21), reason: 'inbox: fire day');
    expect(await search('dentist', kinds: {SearchKind.habit}), hasLength(2));
  });

  test('inbox entries without a link fall back to their source, then the inbox; read = closed', () async {
    await inbox('n2', 'Weekly digest', body: 'Your week in numbers', read: true);
    final r = (await search('numbers')).single;
    expect(r.link, '/inbox');
    expect(r.closed, isTrue);
    expect(r.snippet, contains('${SearchMatch.snippetStart}numbers${SearchMatch.snippetEnd}'));
  });

  test('body matches return a marked snippet; title-only matches none', () async {
    final list = await h.checklist('Groceries');
    await h.db.customStatement("UPDATE checklists SET body = 'Buy oat milk and bread' WHERE id = '$list'");
    final hit = (await search('oat')).single;
    expect(snippetSpans(hit.snippet!).where((s) => s.$2).map((s) => s.$1), ['oat']);
    expect((await search('groceries')).single.snippet, isNull);
  });

  test('tags and categories are attached for filtering', () async {
    final task = await h.task('Pay invoice', start: at(2026, 9, 22, 9));
    final tag = (await h.read(tagsRepositoryProvider).create(name: 'work')).id;
    final cat = (await h.read(categoriesRepositoryProvider).add(name: 'Admin', color: 1)).id;
    await h.read(tagsRepositoryProvider).setTags('task', task, {tag});
    await h.db.customStatement("UPDATE tasks SET category_id = '$cat' WHERE id = '$task'");
    final r = (await search('invoice')).single;
    expect(r.tagIds, {tag});
    expect(r.categoryId, cat);
    expect(SearchFilters(tagId: tag).matches(r), isTrue);
    expect(const SearchFilters(categoryId: 'other').matches(r), isFalse);
  });

  test('20 000 indexed rows: enriched results in under 100 ms', () async {
    await h.db.batch((b) {
      for (var n = 0; n < 20000; n++) {
        b.insert(
          h.db.tasks,
          TasksCompanion.insert(
            id: 'bulk-$n',
            userId: userOf(h),
            createdAt: now,
            updatedAt: now.subtract(Duration(minutes: n)),
            seriesId: 'bulk-$n',
            title: '${n.isEven ? 'garden' : 'invoice'} $n',
          ),
        );
      }
    });
    await search('garden'); // warm-up (statement cache)
    final watch = Stopwatch()..start();
    final hits = await search('invoice');
    watch.stop();
    expect(hits, hasLength(200));
    expect(watch.elapsedMilliseconds, lessThan(100), reason: 'took ${watch.elapsedMilliseconds} ms');
  });
}
