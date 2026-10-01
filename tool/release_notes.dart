// Prints release notes from conventional commits since the previous tag (T9.2.03).
//
//   dart run tool/release_notes.dart            # Markdown for the GitHub release, HEAD vs previous tag
//   dart run tool/release_notes.dart v1.2.0     # notes for a given tag
//   dart run tool/release_notes.dart --store    # plain text for store "What's new" (≤ 500 chars)
import 'dart:convert';
import 'dart:io';

const _titles = {
  'feat': 'Features',
  'fix': 'Fixes',
  'perf': 'Performance',
  'refactor': 'Internal',
  'docs': 'Documentation',
};
const _storeTypes = {'feat', 'fix', 'perf'};
final _subject = RegExp(r'^(\w+)(?:\(([^)]+)\))?(!)?: (.+)$');

void main(List<String> args) {
  final store = args.contains('--store');
  final to = args.firstWhere((a) => !a.startsWith('--'), orElse: () => 'HEAD');
  final previous = _git(['describe', '--tags', '--abbrev=0', '$to^']);
  final range = previous == null ? to : '$previous..$to';
  final log = _git(['log', '--no-merges', '--format=%s', range]) ?? '';

  final groups = <String, List<String>>{};
  final breaking = <String>[];
  for (final line in const LineSplitter().convert(log)) {
    final match = _subject.firstMatch(line.trim());
    if (match == null) continue;
    final type = match.group(1)!;
    if (!_titles.containsKey(type) || (store && !_storeTypes.contains(type))) continue;
    final scope = match.group(2);
    final text = match.group(4)!;
    final entry = store ? text : (scope == null ? text : '**$scope:** $text');
    groups.putIfAbsent(type, () => []).add(entry);
    if (match.group(3) != null) breaking.add(entry);
  }

  if (store) {
    final lines = [for (final type in _storeTypes) ...?groups[type]].map((e) => '• $e');
    final text = lines.isEmpty ? '• Improvements and fixes.' : lines.join('\n');
    stdout.writeln(text.length <= 500 ? text : '${text.substring(0, 497)}...');
    return;
  }
  final out = StringBuffer();
  if (breaking.isNotEmpty) {
    out
      ..writeln('### ⚠️ Breaking changes')
      ..writeln(breaking.map((e) => '- $e').join('\n'))
      ..writeln();
  }
  for (final MapEntry(key: type, value: title) in _titles.entries) {
    final entries = groups[type];
    if (entries == null) continue;
    out
      ..writeln('### $title')
      ..writeln(entries.map((e) => '- $e').join('\n'))
      ..writeln();
  }
  stdout.write(out.isEmpty ? 'Maintenance release.\n' : out.toString());
}

String? _git(List<String> args) {
  final result = Process.runSync('git', args);
  return result.exitCode == 0 ? (result.stdout as String).trim() : null;
}
