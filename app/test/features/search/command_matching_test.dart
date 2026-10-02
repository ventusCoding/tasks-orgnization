import 'package:everslot/features/search/domain/command_matching.dart';
import 'package:flutter_test/flutter_test.dart';

/// T8.1.18: command palette matching.
void main() {
  const commands = [
    ('new_task', 'New task', ['add', 'create']),
    ('next_week', 'Go to next week', ['plan', 'calendar']),
    ('pause', 'Pause notifications 1 h', ['mute', 'dnd']),
    ('insights_habits', 'Open Insights › Habits', ['stats']),
    ('insights', 'Open Insights', ['stats']),
    ('fr_week', 'Aller à la semaine prochaine', ['plan']),
  ];
  List<String> rank(String q) =>
      CommandMatching.rank(q, commands, title: (c) => c.$2, keywords: (c) => c.$3).map((c) => c.$1).toList();

  test('empty query lists everything in order', () {
    expect(rank(''), [for (final c in commands) c.$1]);
    expect(rank('   '), hasLength(commands.length));
  });

  test('word starts beat keywords beat substrings beat letter sequences', () {
    expect(rank('next').first, 'next_week');
    expect(rank('mute'), ['pause'], reason: 'keyword');
    expect(rank('ication'), ['pause'], reason: 'substring');
    expect(rank('nwtsk'), ['new_task'], reason: 'letters in order');
    expect(rank('zzz'), isEmpty);
  });

  test('every word must match; more specific titles rank first', () {
    expect(rank('insights habits'), ['insights_habits']);
    expect(rank('open insights'), ['insights', 'insights_habits'], reason: 'shorter title first');
    expect(rank('insights > habits'), ['insights_habits'], reason: 'separators are ignored');
  });

  test('accents and case are ignored', () {
    expect(rank('SEMAINE prochaine'), ['fr_week']);
    expect(rank('aller a la'), ['fr_week']);
    expect(CommandMatching.score('Àller', 'Aller à la semaine prochaine'), isNotNull);
  });

  test('scores: title start bonus, null when missing', () {
    expect(CommandMatching.score('', 'x'), 0);
    expect(CommandMatching.score('new', 'New task'), greaterThan(CommandMatching.score('task', 'New task')!));
    expect(CommandMatching.score('new zzz', 'New task'), isNull);
  });
}
