import 'package:everslot/core/providers.dart';
import 'package:everslot/shared/activity/application/activity_providers.dart';
import 'package:everslot/shared/activity/data/activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

/// Activity log (T2.3.05): payload builders, typed logger and reads.
void main() {
  group('payload builders', () {
    test('updated keeps sorted unique field names and only time fields before/after', () {
      final p = ActivityPayloads.updated(
        ['title', 'start_local', 'title', 'notes'],
        before: {'start_local': '2026-09-22T08:00', 'title': 'Old title'},
        after: {'start_local': '2026-09-22T09:00', 'notes': 'x'},
      );
      expect(p, {
        'fields': ['notes', 'start_local', 'title'],
        'before': {'start_local': '2026-09-22T08:00'},
        'after': {'start_local': '2026-09-22T09:00'},
      });
      expect(ActivityPayloads.updated(['title']), {
        'fields': ['title'],
      });
    });

    test('status changes clip long notes and omit nulls', () {
      final long = 'x' * 400;
      final p = ActivityPayloads.statusChanged(from: 'waiting', to: 'blocked', note: long);
      expect(p['from'], 'waiting');
      expect(p['to'], 'blocked');
      expect((p['note']! as String).length, ActivityPayloads.maxTextLength);
      expect((p['note']! as String).endsWith('…'), isTrue);
      expect(ActivityPayloads.statusChanged(from: 'a', to: 'b', note: '  '), {'from': 'a', 'to': 'b'});
    });

    test('rescheduled needs exactly one of occurrence key or scope', () {
      expect(
        ActivityPayloads.rescheduled(
          scope: 'series',
          fromStart: '2026-09-22T08:00',
          toStart: '2026-09-22T09:00',
          fromDuration: 30,
          toDuration: 45,
          source: 'drag',
        ),
        {
          'scope': 'series',
          'fromStart': '2026-09-22T08:00',
          'toStart': '2026-09-22T09:00',
          'fromDuration': 30,
          'toDuration': 45,
          'source': 'drag',
        },
      );
      expect(ActivityPayloads.rescheduled, throwsArgumentError);
      expect(() => ActivityPayloads.rescheduled(occurrenceKey: 'k', scope: 'series'), throwsArgumentError);
    });

    test('moves, skips, deletes, restores and attachments', () {
      expect(ActivityPayloads.moved(fromParentId: 'a', toParentId: null), {'fromParentId': 'a', 'toParentId': null});
      expect(ActivityPayloads.skipped(reason: ' sick ', source: 'menu'), {'reason': 'sick', 'source': 'menu'});
      expect(ActivityPayloads.deleted(), isEmpty);
      expect(ActivityPayloads.deleted(count: 3), {'count': 3});
      expect(ActivityPayloads.restored(fromOpId: 'op'), {'fromOpId': 'op'});
      expect(ActivityPayloads.attachment(attachmentId: 'a1', fileName: 'scan.pdf', mimeType: 'application/pdf'), {
        'attachmentId': 'a1',
        'fileName': 'scan.pdf',
        'mimeType': 'application/pdf',
      });
    });

    test('the catalog lists every documented event', () {
      expect(ActivityEventTypes.all, contains('status_changed'));
      expect(ActivityEventTypes.all, contains('attachment_removed'));
      expect(ActivityEventTypes.all, hasLength(29));
    });
  });

  group('logger and repository', () {
    late TestHarness h;
    late ActivityRepository repo;
    setUp(() {
      h = TestHarness.create();
      repo = h.read(activityRepositoryProvider);
    });
    tearDown(() => h.dispose());

    test('events join the operation: same opId and cause', () async {
      final record = await h.read(syncWriterProvider).run((tx) async {
        await tx.activity.created('checklist_item', 'i1', parentId: 'l1');
        await tx.activity.statusChanged(
          'checklist_item',
          'i1',
          from: 'waiting',
          to: 'blocked',
          note: 'supplier',
          parentId: 'l1',
        );
        // No-ops are not logged.
        await tx.activity.statusChanged('checklist_item', 'i1', from: 'x', to: 'x');
        await tx.activity.updated('checklist_item', 'i1', fields: const []);
      }, cause: 'bulk');

      final events = await repo.forEntity('checklist_item', 'i1');
      expect(events.map((e) => e.eventType), ['status_changed', 'created']);
      expect(events.every((e) => e.opId == record.opId), isTrue);
      expect(events.every((e) => e.cause == 'bulk'), isTrue);
      expect(events.first.parentId, 'l1');
      expect(events.first.string('note'), 'supplier');
      expect(await repo.operation(record.opId), hasLength(2));
    });

    test('history can include children and be narrowed to event types', () async {
      final writer = h.read(syncWriterProvider);
      await writer.run((tx) => tx.activity.created('task', 't1'));
      h.clock.advance(const Duration(minutes: 1));
      await writer.run(
        (tx) => tx.activity.rescheduled(
          'task_occurrence',
          'o1',
          occurrenceKey: '2026-09-22T08:00',
          fromStart: '2026-09-22T08:00',
          toStart: '2026-09-22T10:00',
          parentId: 't1',
        ),
      );
      h.clock.advance(const Duration(minutes: 1));
      await writer.run((tx) => tx.activity.completed('task_occurrence', 'o1', parentId: 't1'));

      expect(await repo.forEntity('task', 't1'), hasLength(1));
      final all = await repo.forEntity('task', 't1', includeChildren: true);
      expect(all.map((e) => e.eventType), ['completed', 'rescheduled', 'created']);
      final reschedules = await repo.forEntity('task_occurrence', 'o1', eventTypes: {ActivityEventTypes.rescheduled});
      expect(reschedules.single.string('toStart'), '2026-09-22T10:00');
    });

    test('delete operations are grouped for the Trash', () async {
      final writer = h.read(syncWriterProvider);
      final del = await writer.run((tx) async {
        await tx.activity.deleted('checklist', 'l1', count: 2);
        await tx.activity.deleted('checklist_item', 'i1', parentId: 'l1');
        await tx.activity.deleted('checklist_item', 'i2', parentId: 'l1');
      });
      h.clock.advance(const Duration(minutes: 1));
      await writer.run((tx) => tx.activity.created('task', 't1'));
      h.clock.advance(const Duration(minutes: 1));
      final del2 = await writer.run((tx) => tx.activity.deleted('task', 't1'));

      final ops = await repo.watchDeleteOperations(since: DateTime.utc(2026, 9, 1)).first;
      expect(ops.map((o) => o.opId), [del2.opId, del.opId]);
      expect(ops.last.events, hasLength(3));
      final none = await repo.watchDeleteOperations(since: DateTime.utc(2026, 10, 1)).first;
      expect(none, isEmpty);
    });

    test('attachment events and reads are scoped to the current user', () async {
      final writer = h.read(syncWriterProvider);
      await writer.run((tx) => tx.activity.attachmentAdded('task', 't1', attachmentId: 'a1', fileName: 'plan.pdf'));
      final e = (await repo.forEntity('task', 't1')).single;
      expect(e.eventType, 'attachment_added');
      expect(e.string('fileName'), 'plan.pdf');
      // Another account sees nothing.
      final other = ActivityRepository(h.db, () => 'someone-else');
      expect(await other.forEntity('task', 't1'), isEmpty);
    });
  });
}
