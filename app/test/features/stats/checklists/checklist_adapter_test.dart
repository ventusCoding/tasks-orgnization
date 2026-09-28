// Checklist stats adapter & event normalization (T6.4.01): reopen, cancel, move, delete/restore and
// events with identical timestamps.
import 'package:everslot/features/stats/domain/checklist_resolution.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot/features/stats/domain/zone_snapshot.dart';
import 'package:everslot_metrics/everslot_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime t(int day, int hour) => DateTime.utc(2026, 9, day, hour);

ActivityRecord ev(String item, String type, DateTime at, {Map<String, Object?> payload = const {}, int rev = 0, String list = 'L1'}) =>
    ActivityRecord(entityType: 'checklist_item', entityId: item, parentId: list, eventType: type, occurredAt: at, payload: payload, rev: rev);

ActivityRecord status(String item, String from, String to, DateTime at, {int rev = 0}) =>
    ev(item, 'status_changed', at, payload: {'from': from, 'to': to}, rev: rev);

ChecklistFacts facts() => ChecklistFacts(
  ChecklistInput(
    checklists: [
      ChecklistRecord(id: 'L1', title: 'One', createdAt: t(1, 8)),
      ChecklistRecord(id: 'L2', title: 'Two', createdAt: t(1, 8)),
    ],
    items: [
      ItemRecord(id: 'r', checklistId: 'L1', status: 'cancelled', createdAt: t(1, 9)),
      ItemRecord(id: 'd', checklistId: 'L1', status: 'todo', createdAt: t(1, 9)),
      ItemRecord(id: 's', checklistId: 'L1', status: 'completed', createdAt: t(5, 9), completedAt: t(5, 10)),
      ItemRecord(id: 'm', checklistId: 'L2', status: 'todo', createdAt: t(1, 9)),
    ],
    events: [
      ev('r', 'created', t(1, 9), payload: {'to': 'todo'}),
      status('r', 'todo', 'ongoing', t(1, 10)),
      status('r', 'ongoing', 'completed', t(2, 10)),
      status('r', 'completed', 'ongoing', t(3, 10)),
      status('r', 'ongoing', 'cancelled', t(4, 10)),
      ev('d', 'created', t(1, 9), payload: {'to': 'todo'}),
      ev('d', 'deleted', t(2, 10)),
      ev('d', 'restored', t(3, 10)),
      ev('s', 'created', t(5, 9), payload: {'to': 'todo'}),
      // Same instant: the revision orders them.
      status('s', 'ongoing', 'completed', t(5, 10), rev: 2),
      status('s', 'todo', 'ongoing', t(5, 10), rev: 1),
      ev('m', 'created', t(1, 9), payload: {'to': 'todo'}),
      ev('m', 'moved', t(3, 10), payload: {'fromChecklistId': 'L1', 'toChecklistId': 'L2'}, list: 'L2'),
    ],
  ),
  resolver: LocationZoneResolver(const {}),
  viewerZone: 'UTC',
  now: t(10, 12),
);

void main() {
  final f = facts();
  ChecklistItemFact item(String id) => f.facts.firstWhere((x) => x.id == id);

  test('reopen then cancel: one reopen, no completion, not countable', () {
    final r = item('r');
    expect(r.reopens, 1);
    expect(r.statusChanges, 4);
    expect(r.start, t(1, 10));
    expect(r.done, isNull);
    expect(r.status, ItemStatus.cancelled);
    expect(r.isCountable, isFalse);
    final spent = r.timeline.timeInStatus(now: t(10, 12));
    expect(spent['completed'], const Duration(days: 1));
    expect(spent['ongoing'], const Duration(days: 1, hours: 24));
  });

  test('delete then restore: absent in between, alive again afterwards', () {
    final d = item('d');
    expect(d.timeline.isAliveAt(t(2, 12)), isFalse);
    expect(d.timeline.isAliveAt(t(4, 12)), isTrue);
    expect(d.timeline.deletedAt, isNull);
  });

  test('identical timestamps are ordered by revision', () {
    final s = item('s');
    expect(s.start, t(5, 10));
    expect(s.done, t(5, 10));
    expect(s.status, ItemStatus.completed);
    expect(s.reopens, 0);
  });

  test('a moved item counts in its source list until the move', () {
    final m = item('m');
    expect(m.timeline.containerAt(t(2, 12)), 'L1');
    expect(m.timeline.containerAt(t(4, 12)), 'L2');
    expect(f.factsOf('L1').map((x) => x.id), contains('m'));
    expect(f.factsOf('L2').map((x) => x.id), contains('m'));
    expect(f.rowsOf('L1').map((x) => x.id), isNot(contains('m')));
  });
}
