import 'dart:math';

import 'package:drift/drift.dart' show Variable;
import 'package:everslot/shared/filters/data/entity_filter_sql.dart';
import 'package:everslot/shared/filters/domain/entity_filter.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

/// Property test (T2.3.09): for generated data and generated filters, the pure predicate and the
/// SQL builder select exactly the same entities.
void main() {
  const vocabulary = [
    'Report',
    'report',
    'REPORT draft',
    'Café',
    'café au lait',
    'ÉTÉ',
    'été',
    'Straße',
    'أحمد',
    'احمد',
    'إسلام',
    'مدرسة',
    'مدرسه',
    'كتـاب',
    'كتاب',
    'مستشفى',
    'مستشفي',
    'gym',
    'Gym 7pm',
    'groceries',
    'x',
    '',
    'naïve',
    'Ünïcode',
  ];
  const needles = [
    'rep',
    'REP',
    'port d',
    'caf',
    'CAFÉ',
    'été',
    'ÉTÉ',
    'ss',
    'احمد',
    'أحمد',
    'اسلام',
    'مدرسة',
    'مدرسه',
    'كتاب',
    'كتـاب',
    'مستشفى',
    'gym',
    'GYM 7',
    'z',
    'ï',
    'Ü',
    ' ',
  ];
  const categories = ['cat-a', 'cat-b', 'cat-c'];
  const tags = ['tag-1', 'tag-2', 'tag-3', 'tag-4'];

  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  LocalDate? randomDate(Random r) => r.nextInt(5) == 0 ? null : LocalDate(2026, 9, 1).plusDays(r.nextInt(60));

  T pick<T>(Random r, List<T> values) => values[r.nextInt(values.length)];

  Set<T> subset<T>(Random r, List<T> values) => {
    for (final v in values)
      if (r.nextBool()) v,
  };

  EntityFilter randomFilter(Random r, List<String> statusValues) {
    bool on() => r.nextInt(3) == 0;
    final from = on() ? randomDate(r) : null;
    final to = on() ? randomDate(r) : null;
    return EntityFilter(
      categoryIds: on() ? subset(r, [...categories, EntityFilter.noCategory]) : const {},
      tagIds: on() ? subset(r, tags) : const {},
      priorities: on() ? subset(r, [0, 1, 2, 3, 4]) : const {},
      statuses: on() ? subset(r, statusValues) : const {},
      text: on() ? pick(r, needles) : null,
      dateFrom: from,
      dateTo: to,
      hasAttachments: on() ? r.nextBool() : null,
      recurring: on() ? r.nextBool() : null,
    );
  }

  /// Generated rows for one table + the matching subjects.
  Future<Map<String, FilterSubject>> seed(Random r, String table, String entityType, int count) async {
    final subjects = <String, FilterSubject>{};
    await h.db.transaction(() async {
      for (var i = 0; i < count; i++) {
        final id = '$table-$i';
        final hasCategory = table != 'checklist_items';
        final categoryId = hasCategory && r.nextInt(4) > 0 ? pick(r, categories) : null;
        final priority = r.nextInt(5);
        final date = randomDate(r);
        final title = pick(r, vocabulary);
        final notes = r.nextBool() ? pick(r, vocabulary) : null;
        final recurring = r.nextBool();
        final archived = r.nextInt(4) == 0;
        final linked = subset(r, tags);
        final deletedLinks = subset(r, tags).difference(linked);
        final attachments = r.nextInt(3);
        final liveAttachment = attachments == 1;
        String? status;
        switch (table) {
          case 'tasks':
            status = pick(r, ['active', 'paused', 'archived']);
            await h.db.customInsert(
              'INSERT INTO tasks (id, user_id, created_at, updated_at, series_id, title, notes, '
              'category_id, priority, status, start_local, recurrence) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              variables: [
                for (final v in <Object?>[
                  id,
                  'user-1',
                  '2026-09-01T00:00:00.000Z',
                  '2026-09-01T00:00:00.000Z',
                  id,
                  title,
                  notes,
                  categoryId,
                  priority,
                  status,
                  date == null ? null : '${date.toIso()}T0${r.nextInt(10)}:30',
                  recurring ? '{"v":1}' : null,
                ])
                  Variable<Object>(v),
              ],
            );
          case 'checklist_items':
            status = pick(r, ['todo', 'ongoing', 'waiting', 'blocked', 'completed', 'cancelled']);
            await h.db.customInsert(
              'INSERT INTO checklist_items (id, user_id, created_at, updated_at, checklist_id, '
              'sort_key, text, note, status, priority, due_local) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              variables: [
                for (final v in <Object?>[
                  id,
                  'user-1',
                  '2026-09-01T00:00:00.000Z',
                  '2026-09-01T00:00:00.000Z',
                  'l1',
                  'a$i',
                  title,
                  notes,
                  status,
                  priority,
                  date == null ? null : '${date.toIso()}T09:00',
                ])
                  Variable<Object>(v),
              ],
            );
          case 'habits':
            status = archived ? 'archived' : 'active';
            await h.db.customInsert(
              'INSERT INTO habits (id, user_id, created_at, updated_at, kind, name, description, '
              'category_id, schedule, start_date, sort_key, archived_at) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              variables: [
                for (final v in <Object?>[
                  id,
                  'user-1',
                  '2026-09-01T00:00:00.000Z',
                  '2026-09-01T00:00:00.000Z',
                  'build',
                  title,
                  notes,
                  categoryId,
                  recurring ? '{"v":1}' : null,
                  (date ?? LocalDate(2026, 9, 1)).toIso(),
                  'a$i',
                  archived ? '2026-09-02T00:00:00.000Z' : null,
                ])
                  Variable<Object>(v),
              ],
            );
          case 'checklists':
            status = archived ? 'archived' : 'active';
            await h.db.customInsert(
              'INSERT INTO checklists (id, user_id, created_at, updated_at, title, body, '
              'category_id, sort_key, archived_at, due_local, reset_rule) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              variables: [
                for (final v in <Object?>[
                  id,
                  'user-1',
                  '2026-09-01T00:00:00.000Z',
                  '2026-09-01T00:00:00.000Z',
                  title,
                  notes,
                  categoryId,
                  'a$i',
                  archived ? '2026-09-02T00:00:00.000Z' : null,
                  date == null ? null : '${date.toIso()}T18:00',
                  recurring ? '{"v":1}' : null,
                ])
                  Variable<Object>(v),
              ],
            );
        }
        var n = 0;
        for (final (tag, deleted) in [for (final t in linked) (t, false), for (final t in deletedLinks) (t, true)]) {
          await h.db.customInsert(
            'INSERT INTO entity_tags (id, user_id, created_at, updated_at, deleted_at, tag_id, '
            'entity_type, entity_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            variables: [
              for (final v in <Object?>[
                '$id-link-${n++}',
                'user-1',
                '2026-09-01T00:00:00.000Z',
                '2026-09-01T00:00:00.000Z',
                deleted ? '2026-09-02T00:00:00.000Z' : null,
                tag,
                entityType,
                id,
              ])
                Variable<Object>(v),
            ],
          );
        }
        if (attachments > 0) {
          await h.db.customInsert(
            'INSERT INTO attachments (id, user_id, created_at, updated_at, deleted_at, owner_type, '
            'owner_id, storage_path, file_name, mime_type, byte_size, sort_key) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            variables: [
              for (final v in <Object?>[
                '$id-att',
                'user-1',
                '2026-09-01T00:00:00.000Z',
                '2026-09-01T00:00:00.000Z',
                liveAttachment ? null : '2026-09-02T00:00:00.000Z',
                entityType,
                id,
                'p',
                'f.png',
                'image/png',
                10,
                'a0',
              ])
                Variable<Object>(v),
            ],
          );
        }
        subjects[id] = FilterSubject(
          categoryId: categoryId,
          tagIds: linked,
          priority: table == 'tasks' || table == 'checklist_items' ? priority : null,
          status: status,
          texts: [title, notes],
          // habits.start_date is NOT NULL.
          date: table == 'habits' ? (date ?? LocalDate(2026, 9, 1)) : date,
          hasAttachments: liveAttachment,
          isRecurring: (table != 'checklist_items') && recurring,
        );
      }
    });
    return subjects;
  }

  final specs = <(String, String, FilterColumns, List<String>)>[
    ('tasks', 'task', FilterColumns.tasks('t'), ['active', 'paused', 'archived', 'done']),
    (
      'checklist_items',
      'checklist_item',
      FilterColumns.checklistItems('t'),
      ['todo', 'waiting', 'blocked', 'completed'],
    ),
    ('habits', 'habit', FilterColumns.habits('t'), ['active', 'archived']),
    ('checklists', 'checklist', FilterColumns.checklists('t'), ['active', 'archived']),
  ];

  for (final (table, entityType, columns, statuses) in specs) {
    for (final seedValue in [7, 2026]) {
      test('predicate and SQL agree on $table (seed $seedValue)', () async {
        final r = Random(seedValue);
        final subjects = await seed(r, table, entityType, 120);
        var nonTrivial = 0;
        for (var i = 0; i < 250; i++) {
          final filter = randomFilter(r, statuses);
          final expected = {
            for (final e in subjects.entries)
              if (filter.matches(e.value)) e.key,
          };
          final where = EntityFilterSql.where(filter, columns);
          final rows = await h.db
              .customSelect('SELECT t.id AS id FROM $table t WHERE ${where.sql}', variables: where.variables)
              .get();
          final actual = {for (final row in rows) row.read<String>('id')};
          expect(actual, expected, reason: 'filter: $filter\nsql: ${where.sql}\nargs: ${where.args}');
          if (expected.isNotEmpty && expected.length < subjects.length) {
            nonTrivial++;
          }
        }
        // The generator must exercise selective filters, not only "all" / "none".
        expect(nonTrivial, greaterThan(50));
      });
    }
  }
}
