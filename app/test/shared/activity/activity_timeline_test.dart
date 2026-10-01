import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/shared/activity/application/activity_providers.dart';
import 'package:everslot/shared/activity/presentation/activity_timeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

/// History timeline widget (T2.3.05): localized sentences from events.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 12)));
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  /// Seeds a realistic history for task t1 at increasing times.
  Future<void> seed(WidgetTester tester) => tester.runAsync(() async {
    final writer = h.read(syncWriterProvider);
    Future<void> step(Future<void> Function(ActivityLogger log) body, {String cause = 'user'}) async {
      await writer.run((tx) => body(tx.activity), cause: cause);
      h.clock.advance(const Duration(minutes: 10));
    }

    h.clock.set(DateTime.utc(2026, 9, 1, 8));
    await step((log) => log.created('task', 't1'));
    h.clock.set(DateTime.utc(2026, 9, 22, 9));
    await step((log) => log.updated('task', 't1', fields: const ['title', 'notes', 'unknown_col']));
    await step((log) => log.statusChanged('task', 't1', from: 'waiting', to: 'blocked', note: 'Supplier late'));
    await step(
      (log) => log.rescheduled(
        'task',
        't1',
        scope: 'series',
        fromStart: '2026-09-22T08:00',
        toStart: '2026-09-22T09:30',
        source: 'drag',
      ),
    );
    await step((log) => log.attachmentAdded('task', 't1', attachmentId: 'a1', fileName: 'plan.pdf'));
    await step((log) => log.log('task', 't1', 'rollover'), cause: 'auto');
    await step((log) => log.deleted('task', 't1', count: 3));
    h.clock.set(DateTime.utc(2026, 9, 22, 12));
  });

  testWidgets('renders every event as an English sentence, newest first', (tester) async {
    await seed(tester);
    await pumpInApp(
      tester,
      h,
      const Scaffold(
        body: SingleChildScrollView(
          child: ActivityTimeline(entityType: 'task', entityId: 't1'),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('History'), findsOneWidget);
    final texts = [
      'Deleted with 3 items',
      'Rolled over',
      'Attachment added: \u2068plan.pdf\u2069',
      'Moved from 08:00 to 09:30',
      'Status changed from Waiting to Blocked',
      'Changed title, notes',
      'Created',
    ];
    for (final t in texts) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    // Newest first.
    final ys = [for (final t in texts) tester.getTopLeft(find.text(t)).dy];
    expect(ys, [...ys]..sort());
    // Details and metadata.
    expect(find.text('“Supplier late”'), findsOneWidget);
    expect(find.text('All occurrences'), findsOneWidget);
    expect(find.textContaining('Automatic'), findsOneWidget);
    expect(find.textContaining('hours ago'), findsWidgets);
    // Older than a week: absolute date in the device zone.
    expect(find.text('Sep 1, 2026 · 08:00'), findsOneWidget);
  });

  testWidgets('Arabic sentences', (tester) async {
    await seed(tester);
    await pumpInApp(
      tester,
      h,
      const Scaffold(
        body: SingleChildScrollView(
          child: ActivityTimeline(entityType: 'task', entityId: 't1'),
        ),
      ),
      locale: const Locale('ar'),
    );
    await settle(tester);
    expect(find.text('السجل'), findsOneWidget);
    expect(find.text('تغيّرت الحالة من في الانتظار إلى محظور'), findsOneWidget);
    expect(find.text('حُذف مع 3 عناصر'), findsOneWidget);
    expect(find.text('«Supplier late»'), findsOneWidget);
    expect(find.text('تم الإنشاء'), findsOneWidget);
  });

  testWidgets('empty history and child events', (tester) async {
    await tester.runAsync(() async {
      await h.read(syncWriterProvider).run((tx) => tx.activity.completed('task_occurrence', 'o1', parentId: 't2'));
    });
    await pumpInApp(
      tester,
      h,
      const Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              ActivityTimeline(entityType: 'task', entityId: 'none', showTitle: false),
              ActivityTimeline(entityType: 'task', entityId: 't2', includeChildren: true),
            ],
          ),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('No history yet'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('sentences for the rest of the catalog', (tester) async {
    late BuildContext ctx;
    await pumpInApp(
      tester,
      h,
      Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox();
        },
      ),
    );
    final format = AppFormatForTest.of(ctx);
    ActivityLine line(String type, [Map<String, Object?> payload = const {}]) => ActivitySentences.describe(
      ctx,
      ActivityEvent(
        id: 'e',
        entityType: 'checklist_item',
        entityId: 'i',
        eventType: type,
        occurredAt: DateTime.utc(2026),
        payload: payload,
      ),
      format,
    );
    expect(
      line('updated', {
        'fields': ['tags'],
      }).text,
      'Tags updated',
    );
    expect(
      line('updated', {
        'fields': ['sort_key'],
      }).text,
      'Edited',
    );
    expect(line('status_changed', {'to': 'completed'}).text, 'Status set to Completed');
    expect(line('moved', {'fromChecklistId': 'a', 'toChecklistId': 'b'}).text, 'Moved to another list');
    expect(line('moved', {'fromParentId': 'a', 'toParentId': 'b'}).text, 'Moved');
    expect(line('skipped', {'reason': 'Sick'}).text, 'Skipped: Sick');
    expect(line('created', {'fromTemplateId': 't'}).text, 'Created from a template');
    expect(line('created', {'duplicatedFrom': 'x'}).text, 'Created as a copy');
    expect(line('items_added', {'count': 2}).text, '2 items added');
    expect(
      line('rescheduled', {'occurrenceKey': 'k', 'fromStart': '2026-09-22T08:00', 'toStart': '2026-09-23T08:00'}).text,
      'Moved from Tue 22 08:00 to Wed 23 08:00',
    );
    expect(
      line('rescheduled', {'scope': 'this', 'fromDuration': 30, 'toDuration': 45}).text,
      'Duration changed from 30 min to 45 min',
    );
    expect(line('mystery').text, 'Changed');
    for (final type in ActivityEventTypes.all) {
      expect(line(type).text, isNotEmpty, reason: type);
    }
  });
}

/// English 24 h formatter for sentence tests.
abstract final class AppFormatForTest {
  static AppFormat of(BuildContext context) => AppFormat('en', l10n: context.l10n);
}
