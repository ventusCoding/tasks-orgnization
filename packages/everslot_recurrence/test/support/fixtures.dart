import 'dart:convert';
import 'dart:io';

import 'package:everslot_recurrence/everslot_recurrence.dart';

/// One case of `fixtures/recurrence/*.json` (T2.1.13).
///
/// Format: `{name, rule, anchor: {start, zone, allDay?, durationMinutes?},
/// evalZone, range: {from, to}, expectedKeys, expectedUtc?, durationMinutes?,
/// limit?, completions?, notes?}`.
final class RecurrenceFixture {
  new(this.file, Map<String, Object?> json)
    : name = json['name']! as String,
      ruleJson = (json['rule']! as Map).cast<String, Object?>(),
      anchorJson = (json['anchor']! as Map).cast<String, Object?>(),
      evalZone = json['evalZone'] as String?,
      from = LocalDateTime.parse((json['range']! as Map)['from']! as String),
      to = LocalDateTime.parse((json['range']! as Map)['to']! as String),
      expectedKeys = (json['expectedKeys']! as List).cast<String>(),
      expectedUtc = (json['expectedUtc'] as List?)?.cast<String>(),
      durationMinutes = json['durationMinutes'] as int?,
      limit = json['limit'] as int?,
      completions = (json['completions'] as List?)?.cast<String>();

  final String file;
  final String name;
  final Map<String, Object?> ruleJson;
  final Map<String, Object?> anchorJson;
  final String? evalZone;
  final LocalDateTime from;
  final LocalDateTime to;
  final List<String> expectedKeys;
  final List<String>? expectedUtc;
  final int? durationMinutes;
  final int? limit;
  final List<String>? completions;

  RecurrenceRule get rule => RecurrenceRule.fromJson(ruleJson);

  RecurrenceAnchor get anchor => RecurrenceAnchor(
    LocalDateTime.parse(anchorJson['start']! as String),
    anchorJson['zone'] as String?,
    allDay: anchorJson['allDay'] as bool? ?? false,
    durationMinutes: anchorJson['durationMinutes'] as int?,
  );

  @override
  String toString() => '$file › $name';
}

/// Actual output of a fixture.
typedef FixtureOutput = ({List<String> keys, List<String> utc});

/// Locates `fixtures/recurrence` by walking up from the current directory.
Directory fixturesDirectory() {
  var dir = Directory.current.absolute;
  while (true) {
    final candidate = Directory('${dir.path}/fixtures/recurrence');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'fixtures/recurrence not found above ${Directory.current.path}',
      );
    }
    dir = parent;
  }
}

/// Loads every `*.json` file directly inside [directory] (a list of cases or a single case).
List<RecurrenceFixture> loadFixtures([Directory? directory]) {
  final dir = directory ?? fixturesDirectory();
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final file in files)
      ...switch (jsonDecode(file.readAsStringSync())) {
        final List<Object?> list => [
          for (final item in list)
            RecurrenceFixture(
              file.uri.pathSegments.last,
              (item! as Map).cast(),
            ),
        ],
        final Map<Object?, Object?> single => [
          RecurrenceFixture(file.uri.pathSegments.last, single.cast()),
        ],
        _ => throw FormatException('Unsupported fixture file', file.path),
      },
  ];
}

/// `YYYY-MM-DDTHH:mmZ`.
String formatUtc(DateTime utc) => '${utc.toIso8601String().substring(0, 16)}Z';

/// Runs a fixture through [engine].
FixtureOutput runFixture(RecurrenceEngine engine, RecurrenceFixture fixture) {
  final rule = fixture.rule;
  final anchor = fixture.anchor;
  final completions = fixture.completions;
  final List<Occurrence> occurrences;
  if (completions != null) {
    final zone = engine.zoneFor(anchor, fixture.evalZone);
    occurrences =
        [
              ?engine.nextDue(rule, anchor, null, evalZone: fixture.evalZone),
              for (final c in completions)
                ?engine.nextDue(
                  rule,
                  anchor,
                  engine.resolver.resolve(LocalDateTime.parse(c), zone).utc,
                  evalZone: fixture.evalZone,
                ),
            ]
            .where(
              (o) =>
                  !o.startLocal.isBefore(fixture.from) &&
                  o.startLocal.isBefore(fixture.to),
            )
            .toList();
  } else {
    occurrences = engine
        .between(
          rule,
          anchor,
          fixture.from,
          fixture.to,
          evalZone: fixture.evalZone,
          limit: fixture.limit,
          durationMinutes: fixture.durationMinutes,
        )
        .toList();
  }
  return (
    keys: [for (final o in occurrences) o.key],
    utc: [for (final o in occurrences) formatUtc(o.startUtc)],
  );
}

/// A readable diff of two key lists, or null when they are equal.
String? diffKeys(
  List<String> expected,
  List<String> actual, {
  String label = 'keys',
}) {
  if (expected.length == actual.length) {
    var same = true;
    for (var i = 0; i < expected.length; i++) {
      if (expected[i] != actual[i]) {
        same = false;
        break;
      }
    }
    if (same) return null;
  }
  final expectedSet = expected.toSet();
  final actualSet = actual.toSet();
  final missing = [
    for (final k in expected)
      if (!actualSet.contains(k)) k,
  ];
  final unexpected = [
    for (final k in actual)
      if (!expectedSet.contains(k)) k,
  ];
  final buffer = StringBuffer(
    '$label differ (expected ${expected.length}, got ${actual.length})',
  );
  if (missing.isNotEmpty) buffer.write('\n  missing:    ${_preview(missing)}');
  if (unexpected.isNotEmpty) {
    buffer.write('\n  unexpected: ${_preview(unexpected)}');
  }
  if (missing.isEmpty && unexpected.isEmpty) {
    for (var i = 0; i < expected.length && i < actual.length; i++) {
      if (expected[i] != actual[i]) {
        buffer.write(
          '\n  first difference at #$i: expected ${expected[i]}, got ${actual[i]}',
        );
        break;
      }
    }
    if (expected.length != actual.length) {
      buffer.write('\n  (duplicates differ)');
    }
  }
  return buffer.toString();
}

String _preview(List<String> values) => values.length <= 12
    ? values.join(', ')
    : '${values.take(12).join(', ')} … (+${values.length - 12})';

/// Checks a fixture; returns null when it passes, otherwise a failure message.
String? checkFixture(RecurrenceEngine engine, RecurrenceFixture fixture) {
  final output = runFixture(engine, fixture);
  final keys = diffKeys(fixture.expectedKeys, output.keys);
  if (keys != null) return '$fixture\n$keys';
  final expectedUtc = fixture.expectedUtc;
  if (expectedUtc != null) {
    final utc = diffKeys(expectedUtc, output.utc, label: 'UTC instants');
    if (utc != null) return '$fixture\n$utc';
  }
  return null;
}
