import 'dart:convert';
import 'dart:io';

import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/planner/notification_planner.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../support/fixture_parsing.dart';

/// Planner fixture suite (T7.2.08): every `fixtures/planner/*.json` file holds `cases`; adding a
/// file adds tests. Each case: `{name, now, zone, settings?, privacy?, rules, targets, mutes?,
/// acknowledged?, deviceId?, expected: [{rule, target, fireAtUtc, occ?, repeat?, channel?,
/// category?, system?, local?, silent?, adjust?}] | expectedCount, expectedSkipped?}`.
void main() {
  tzdata.initializeTimeZones();
  final dir = Directory('test/features/notifications/fixtures/planner');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('fixture suite has at least 60 cases', () {
    var count = 0;
    for (final f in files) {
      count += ((jsonDecode(f.readAsStringSync()) as Map)['cases'] as List).length;
    }
    expect(count, greaterThanOrEqualTo(60));
  });

  for (final file in files) {
    final doc = Map<String, Object?>.from(jsonDecode(file.readAsStringSync()) as Map);
    group(file.uri.pathSegments.last, () {
      for (final raw in doc['cases']! as List) {
        final c = asJsonMap(raw)!;
        test(c['name']! as String, () => _runCase(c));
      }
    });
  }
}

void _runCase(Map<String, Object?> c) {
  final ctx = PlanningContext(
    now: parseInstant(c['now'])!,
    deviceZone: asString(c['zone']) ?? 'UTC',
    zones: TzZoneResolver(),
    settings: NotificationSettings.fromMaps(
      Map<String, dynamic>.from(asJsonMap(c['settings']) ?? const {}),
      Map<String, dynamic>.from(asJsonMap(c['privacy']) ?? const {}),
    ),
    rules: [for (final r in (c['rules']! as List)) ruleFromJson(asJsonMap(r)!)],
    targets: [for (final t in (c['targets']! as List)) targetFromJson(asJsonMap(t)!)],
    profiles: builtinProfilesById(),
    mutes: [for (final m in (c['mutes'] as List?) ?? const <Object?>[]) muteFromJson(asJsonMap(m)!)],
    acknowledgedKeys: {
      for (final a in (c['acknowledged'] as List?) ?? const <Object?>[])
        dedupeKeyFor(
          ruleId: asString(asJsonMap(a)!['rule'])!,
          targetId: asString(asJsonMap(a)!['target'])!,
          occurrenceKey: asString(asJsonMap(a)!['occ']) ?? '',
        ),
    },
    deviceId: asString(c['deviceId']) ?? 'device-a',
    userId: 'user-1',
  );
  final result = NotificationPlanner.plan(ctx);
  String describe(PlannedNotification p) =>
      '${p.ruleId}/${p.targetId} ${p.fireAt.toIso8601String()} rep=${p.repeatIdx} ch=${p.channelId} adj=${p.adjustments.map((a) => a.name).toList()}';
  final actual = result.planned.map(describe).join('\n');

  final expectedCount = asInt(c['expectedCount']);
  if (expectedCount != null) {
    expect(result.planned, hasLength(expectedCount), reason: actual);
  }
  final expected = c['expected'] as List?;
  if (expected != null) {
    expect(result.planned, hasLength(expected.length), reason: 'planned:\n$actual');
    for (var i = 0; i < expected.length; i++) {
      final e = asJsonMap(expected[i])!;
      final p = result.planned[i];
      final where = 'expected[$i] vs\n$actual';
      expect(p.ruleId, e['rule'], reason: where);
      expect(p.targetId, e['target'], reason: where);
      expect(p.fireAt, parseInstant(e['fireAtUtc']), reason: where);
      final repeat = asInt(e['repeat']) ?? 0;
      expect(p.repeatIdx, repeat, reason: where);
      if (e['occ'] != null) {
        expect(p.occurrenceKey, e['occ'], reason: where);
        expect(
          p.dedupeKey,
          dedupeKeyFor(ruleId: p.ruleId, targetId: p.targetId, occurrenceKey: e['occ']! as String, repeatIdx: repeat),
          reason: where,
        );
      }
      if (e['channel'] != null) expect(p.channelId, e['channel'], reason: where);
      if (e['category'] != null) expect(p.category.wire, e['category'], reason: where);
      if (e['system'] != null) expect(p.deliverSystem, e['system'], reason: where);
      if (e['local'] != null) expect(p.scheduleLocally, e['local'], reason: where);
      if (e['silent'] != null) expect(p.silent, e['silent'], reason: where);
      if (e['title'] != null) expect(p.inboxTitle, e['title'], reason: where);
      if (e['body'] != null) expect(p.inboxBody, e['body'], reason: where);
      if (e['systemTitle'] != null) expect(p.title, e['systemTitle'], reason: where);
      if (e['adjust'] != null) {
        expect(p.adjustments.map((a) => a.name).toSet(), (e['adjust']! as List).cast<String>().toSet(), reason: where);
      }
    }
  }
  final skipped = c['expectedSkipped'] as List?;
  if (skipped != null) {
    final reasons = result.skipped.map((s) => '${s.ruleId}:${s.reason.name}').toList();
    for (final s in skipped) {
      final m = asJsonMap(s)!;
      expect(reasons, contains('${m['rule']}:${m['reason']}'), reason: reasons.join(', '));
    }
  }
  // Properties: unique keys, sorted, within horizon.
  final keys = result.planned.map((p) => p.dedupeKey).toSet();
  expect(keys, hasLength(result.planned.length));
  for (var i = 1; i < result.planned.length; i++) {
    expect(result.planned[i].fireAt.isBefore(result.planned[i - 1].fireAt), isFalse);
  }
  final horizonEnd = ctx.now.add(ctx.effectiveHorizon);
  for (final p in result.planned) {
    expect(p.fireAt.isAfter(horizonEnd), isFalse);
    expect(p.dedupeKey, matches(RegExp(r'^[0-9a-f]{40}$')));
  }
}
