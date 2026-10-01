import 'dart:convert';
import 'dart:io';

import 'package:everslot/features/planner/domain/occurrence_record.dart';
import 'package:everslot/features/planner/domain/occurrence_resolver.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Fixture-driven resolver tests (T3.2.01 / T3.2.03). Each JSON file under
/// `test/features/planner/fixtures/resolver/` holds `defaults` and `cases`; adding a case adds
/// a test without code changes.
void main() {
  tzdata.initializeTimeZones();
  final resolver = OccurrenceResolver(RecurrenceEngine(TzZoneResolver()));
  final dir = Directory('test/features/planner/fixtures/resolver');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  var total = 0;
  final allCases = <ResolverCase>[];

  for (final file in files) {
    final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final defaults = (doc['defaults'] as Map<String, dynamic>?) ?? const {};
    final name = file.uri.pathSegments.last;
    group(name, () {
      for (final raw in (doc['cases'] as List).cast<Map<String, dynamic>>()) {
        final c = ResolverCase.parse({...defaults, ...raw});
        allCases.add(c);
        total++;
        test(c.name, () {
          final result = c.run(resolver);
          final actual = result.occurrences;
          final summary = actual
              .map((o) => '${o.taskId} ${o.occurrenceKey} @ ${o.startLocalViewer} ${o.status.name}')
              .join('\n');
          expect(actual.length, c.expected.length, reason: 'got:\n$summary');
          for (var i = 0; i < actual.length; i++) {
            c.expected[i].verify(actual[i], index: i, summary: summary);
          }
        });
      }
    });
  }

  test('fixture suite has at least 60 cases', () => expect(total, greaterThanOrEqualTo(60)));

  group('properties over every fixture', () {
    test('sorted, unique (taskId, key), all overlapping the range', () {
      for (final c in allCases) {
        final out = c.run(resolver).occurrences;
        final ids = <String>{};
        for (var i = 0; i < out.length; i++) {
          expect(ids.add(out[i].identity), isTrue, reason: '${c.name}: duplicate ${out[i].identity}');
          if (i > 0) expect(compareResolved(out[i - 1], out[i]), lessThanOrEqualTo(0), reason: c.name);
          final o = out[i];
          if (o.isAllDay) {
            expect(o.startLocalViewer.isBefore(c.to) && o.endLocalViewer.isAfter(c.from), isTrue, reason: c.name);
          } else {
            final fromUtc = TzZoneResolver().resolve(c.from, c.viewerZone).utc;
            final toUtc = TzZoneResolver().resolve(c.to, c.viewerZone).utc;
            expect(o.startInstant.isBefore(toUtc), isTrue, reason: '${c.name}: $o starts after range');
            expect(
              o.durationMinutes == 0 ? !o.startInstant.isBefore(fromUtc) : o.endInstant.isAfter(fromUtc),
              isTrue,
              reason: '${c.name}: $o ends before range',
            );
          }
        }
      }
    });

    test('same inputs always produce the same output', () {
      for (final c in allCases) {
        final a = c.run(resolver).occurrences.map((o) => o.toPlannerItem()).toList();
        final b = c.run(resolver).occurrences.map((o) => o.toPlannerItem()).toList();
        expect(a, b, reason: c.name);
      }
    });

    test('input order does not change the output', () {
      for (final c in allCases.where((c) => c.tasks.length > 1)) {
        final forward = c.run(resolver).occurrences.map((o) => o.identity).toList();
        final reversed = c.run(resolver, reverse: true).occurrences.map((o) => o.identity).toList();
        expect(reversed, forward, reason: c.name);
      }
    });
  });
}

class ResolverCase {
  ResolverCase({
    required this.name,
    required this.viewerZone,
    required this.now,
    required this.from,
    required this.to,
    required this.settings,
    required this.tasks,
    required this.records,
    required this.expected,
  });

  factory ResolverCase.parse(Map<String, dynamic> json) {
    final range = json['range'] as Map<String, dynamic>;
    final s = (json['settings'] as Map<String, dynamic>?) ?? const {};
    return ResolverCase(
      name: json['name'] as String,
      viewerZone: json['viewerZone'] as String,
      now: DateTime.parse(json['now'] as String).toUtc(),
      from: LocalDateTime.parse(range['from'] as String),
      to: LocalDateTime.parse(range['to'] as String),
      settings: ResolverSettings(
        missedGraceMinutes: (s['missedGraceMinutes'] as num?)?.toInt() ?? 15,
        overdueLookbackDays: (s['overdueLookbackDays'] as num?)?.toInt() ?? 7,
        showCancelled: s['showCancelled'] as bool? ?? false,
        skipAdvancesAfterCompletion: s['skipAdvancesAfterCompletion'] as bool? ?? true,
      ),
      tasks: [
        for (final t in ((json['tasks'] as List?) ?? const []).cast<Map<String, dynamic>>())
          Task.fromJson({'title': t['id'], ...t})
              .copyWith(pausedAt: t['paused_at'] == null ? null : DateTime.parse(t['paused_at'] as String).toUtc()),
      ],
      records: [
        for (final r in ((json['records'] as List?) ?? const []).cast<Map<String, dynamic>>())
          TaskOccurrenceRecord.fromJson({'id': '${r['task_id']}|${r['occurrence_key']}', ...r}),
      ],
      expected: [
        for (final e in ((json['expected'] as List?) ?? const []).cast<Map<String, dynamic>>()) ExpectedItem(e),
      ],
    );
  }

  final String name;
  final String viewerZone;
  final DateTime now;
  final LocalDateTime from;
  final LocalDateTime to;
  final ResolverSettings settings;
  final List<Task> tasks;
  final List<TaskOccurrenceRecord> records;
  final List<ExpectedItem> expected;

  ResolveResult run(OccurrenceResolver resolver, {bool reverse = false}) => resolver.resolve(
    tasks: reverse ? tasks.reversed : tasks,
    records: reverse ? records.reversed : records,
    from: from,
    to: to,
    viewerZone: viewerZone,
    now: now,
    settings: settings,
  );
}

class ExpectedItem {
  ExpectedItem(this.json);

  final Map<String, dynamic> json;

  void verify(ResolvedOccurrence o, {required int index, required String summary}) {
    final reason = '#$index ${json['task']} ${json['key']}\ngot:\n$summary';
    expect(o.taskId, json['task'], reason: reason);
    expect(o.occurrenceKey, json['key'], reason: reason);
    void check(String field, Object? actual) {
      if (json.containsKey(field)) expect(actual, json[field], reason: '$field of $reason');
    }

    check('start', o.startLocalViewer.toIso());
    check('end', o.endLocalViewer.toIso());
    check('startUtc', o.startInstant.toIso8601String());
    check('status', o.status.name);
    check('allDay', o.isAllDay);
    check('overdue', o.isOverdue);
    check('current', o.isCurrent);
    check('moved', o.isMoved);
    check('overridden', o.isOverridden);
    check('title', o.title);
    check('hasRecord', o.record != null);
    check('quota', o.isQuotaSlot);
    if (json.containsKey('status')) {
      expect(OccurrenceStatus.values.map((s) => s.name), contains(json['status']));
    }
  }
}
