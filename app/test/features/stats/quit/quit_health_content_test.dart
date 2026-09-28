// Health milestone content (T6.6.05): the stats table matches the bundled asset of the habits
// feature row by row (ids, times, sources), and every row cites at least one source.
import 'dart:convert';
import 'dart:io';

import 'package:everslot/features/stats/domain/quit_health_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final asset =
      jsonDecode(File('assets/content/quit_milestones_smoking.json').readAsStringSync()) as Map<String, Object?>;
  final rows = (asset['milestones']! as List).cast<Map<String, Object?>>();

  test('every stats milestone has at least one source', () {
    for (final m in [...smokingHealthMilestones, lifeExpectancyInfo]) {
      expect(m.sources, isNotEmpty, reason: m.id);
    }
  });

  test('ids, times and sources match the bundled content', () {
    final byId = {for (final r in rows) r['id']! as String: r};
    expect(byId.keys.toSet(), {...smokingHealthMilestones.map((m) => m.id), lifeExpectancyInfo.id});
    for (final m in smokingHealthMilestones) {
      final r = byId[m.id]!;
      expect(r['tMinMinutes'], m.tMin.inMinutes, reason: m.id);
      expect(r['tMaxMinutes'], m.tMax?.inMinutes, reason: m.id);
      final urls = {for (final s in (r['sources']! as List).cast<Map<String, Object?>>()) s['url']};
      expect(urls, {for (final s in m.sources) s.url}, reason: m.id);
    }
  });

  test('the asset carries the disclaimer and clock note in EN, FR and AR', () {
    for (final key in ['disclaimer', 'clockNote']) {
      final texts = asset[key]! as Map<String, Object?>;
      expect(texts.keys, containsAll(['en', 'fr', 'ar']), reason: key);
    }
  });
}
