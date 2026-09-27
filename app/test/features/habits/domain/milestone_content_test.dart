import 'dart:convert';
import 'dart:io';

import 'package:everslot/features/habits/application/milestone_content.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/quit.dart';
import 'package:everslot/features/stats/domain/quit_health_content.dart' as stats;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = File(smokingMilestonesAsset).readAsStringSync();

  group('smoking milestone content (T5.3.11)', () {
    test('parses and passes validation: sources, three languages, disclaimer, clock note', () {
      final content = parseMilestoneContent(source);
      expect(content.validate(), isEmpty);
      expect(content.substance, QuitSubstance.cigarettes.name);
      for (final lang in MilestoneContent.languages) {
        expect(content.disclaimerFor(lang), isNotEmpty);
        expect(content.clockNoteFor(lang), isNotEmpty);
      }
      expect(content.disclaimerFor('en'), contains('Not medical advice'));
      for (final m in content.milestones) {
        expect(m.sources, isNotEmpty, reason: m.id);
        for (final s in m.sources) {
          expect(Uri.parse(s.url).isScheme('https'), isTrue, reason: '${m.id}: ${s.url}');
        }
      }
    });

    test('rows agree with the stats table (ids, offsets) plus one info row', () {
      final content = parseMilestoneContent(source);
      final bars = [
        for (final m in content.milestones)
          if (!m.info) (m.id, m.tMin, m.tMax),
      ];
      expect(bars, [for (final m in stats.smokingHealthMilestones) (m.id, m.tMin, m.tMax)]);
      expect(content.milestones.where((m) => m.info).map((m) => m.id), ['LifeExpectancy']);
      expect(content.progressMilestones, hasLength(stats.smokingHealthMilestones.length));
    });

    test('range rows carry a range note in every language', () {
      final content = parseMilestoneContent(source);
      for (final m in content.milestones.where((m) => m.isRange)) {
        for (final lang in MilestoneContent.languages) {
          expect(m.textFor(lang).range, isNotNull, reason: '${m.id} $lang');
        }
      }
    });

    test('withdrawal phases and life-regained constants with citations', () {
      final content = parseMilestoneContent(source);
      expect(content.withdrawal.map((w) => (w.fromDay, w.toDay)), [(1, 3), (4, 7), (8, 28)]);
      final life = {for (final e in content.lifeEstimates) e.key: e.minutesPerUnit};
      expect(life, {'jackson2025': 20.0, 'bmj2000': 11.0});
      final preset = QuitPreset.of(QuitSubstance.cigarettes);
      expect(preset.lifeMinutesPerUnit, life['jackson2025'], reason: 'the smoking preset uses the 2025 estimate');
      expect(preset.hasHealthContent, isTrue);
      expect(QuitPreset.of(QuitSubstance.alcohol).hasHealthContent, isFalse, reason: 'smoking only');
    });

    test('broken content is rejected with a clear message', () {
      String broken(void Function(Map<String, dynamic> json) mutate) {
        final json = jsonDecode(source) as Map<String, dynamic>;
        mutate(json);
        return jsonEncode(json);
      }

      Map<String, dynamic> row(Map<String, dynamic> json, int i) => (json['milestones'] as List)[i] as Map<String, dynamic>;
      expect(
        () => parseMilestoneContent(broken((j) => row(j, 1)['sources'] = <Object>[])),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Co8h: no source'))),
      );
      expect(
        () => parseMilestoneContent(broken((j) => (row(j, 2)['text'] as Map).remove('ar'))),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Co12h: ar text missing'))),
      );
      expect(
        () => parseMilestoneContent(broken((j) => (j['disclaimer'] as Map)['fr'] = ' ')),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('disclaimer.fr missing'))),
      );
    });

    test('the bundled asset loads through the root bundle', () async {
      final loaded = parseMilestoneContent(await rootBundle.loadString(smokingMilestonesAsset));
      expect(loaded.milestones.first.id, 'Heart20m');
    });
  });
}
