import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/planner/presentation/markdown_lite_view.dart';
import 'package:everslot/features/planner/presentation/occurrence_panel.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../../recurrence_ui/recurrence_test_support.dart';
import '../planner_test_support.dart';
import 'planner_ui_support.dart';

/// Occurrence notes & attachments (T3.2.22).
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 12)));
  tearDown(() => h.dispose());

  Finder key(String k) => find.byKey(ValueKey(k));

  testWidgets('an outcome note (markdown-lite) and the occurrence attachments strip', (tester) async {
    final (id, item) = (await tester.runAsync(() async {
      final id = await h.createTask(title: 'Workout', start: '2026-09-20T07:00', duration: 45, rule: RecurrenceRule());
      final items = await h.items(ld('2026-09-22'), 1);
      return (id, items.single);
    }))!;
    await pumpOpener(tester, h, (context) => showOccurrenceSheet(context, item));
    await openAndSettle(tester);

    // Attachments belong to this occurrence (deterministic owner id).
    final strip = tester.widget<AttachmentStrip>(find.byType(AttachmentStrip));
    expect(strip.ownerType, 'task_occurrence');
    expect(strip.ownerId, Ids.taskOccurrence(id, '2026-09-22T07:00'));

    await tester.ensureVisible(key('occurrence-note'));
    await pumpFor(tester, const Duration(milliseconds: 200));
    await tester.tap(key('occurrence-note'));
    await pumpFor(tester);
    await tester.enterText(find.byType(TextField).last, 'Felt **great**, new PR');
    await tester.tap(find.text('Save').last);
    await settle(tester);

    final record = (await tester.runAsync(() => h.records(id)))!.single;
    expect(record.occurrenceKey, '2026-09-22T07:00');
    expect(record.outcomeNote, 'Felt **great**, new PR');
    final note = find.descendant(of: key('occurrence-note'), matching: find.byType(MarkdownLiteView));
    expect(note, findsOneWidget);
    expect(find.textContaining('great', findRichText: true), findsWidgets);

    // Other occurrences keep their own (empty) note.
    final other = (await tester.runAsync(() => h.items(ld('2026-09-23'), 1)))!.single;
    expect(other.occurrenceKey, '2026-09-23T07:00');
    expect(await tester.runAsync(() => h.records(id)), hasLength(1));
  });
}
