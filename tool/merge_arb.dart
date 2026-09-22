// Merges per-feature ARB parts (app/lib/l10n/parts/<area>_<locale>.arb) into
// app/lib/l10n/arb/app_<locale>.arb so features can add strings in parallel without conflicts.
//
// Usage (repo root):  fvm dart run tool/merge_arb.dart && (cd app && fvm flutter gen-l10n)
// Fails on duplicate keys across parts and prints keys missing in fr/ar.
import 'dart:convert';
import 'dart:io';

void main() {
  final partsDir = Directory('app/lib/l10n/parts');
  final outDir = Directory('app/lib/l10n/arb')..createSync(recursive: true);
  final byLocale = <String, Map<String, Object?>>{};
  final owner = <String, String>{};
  var failed = false;

  final files = partsDir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.arb', '');
    final idx = name.lastIndexOf('_');
    final locale = name.substring(idx + 1);
    final area = name.substring(0, idx);
    final Map<String, Object?> content;
    try {
      content = Map<String, Object?>.from(jsonDecode(file.readAsStringSync()) as Map);
    } on FormatException catch (e) {
      stderr.writeln('Invalid JSON in ${file.path}: $e');
      failed = true;
      continue;
    }
    final target = byLocale.putIfAbsent(locale, () => {'@@locale': locale});
    for (final e in content.entries) {
      if (e.key == '@@locale') continue;
      final ownerKey = '$locale:${e.key}';
      if (owner.containsKey(ownerKey)) {
        stderr.writeln('Duplicate key "${e.key}" ($locale) in $area and ${owner[ownerKey]}');
        failed = true;
        continue;
      }
      owner[ownerKey] = area;
      target[e.key] = e.value;
    }
  }

  final en = byLocale['en'] ?? {};
  for (final entry in byLocale.entries) {
    final sorted = <String, Object?>{'@@locale': entry.key};
    final keys = entry.value.keys.where((k) => k != '@@locale').toList()..sort();
    for (final k in keys) {
      sorted[k] = entry.value[k];
    }
    File('${outDir.path}/app_${entry.key}.arb')
        .writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(sorted)}\n');
    if (entry.key != 'en') {
      final missing = en.keys.where((k) => !k.startsWith('@') && !entry.value.containsKey(k)).toList();
      if (missing.isNotEmpty) {
        stdout.writeln('[${entry.key}] ${missing.length} untranslated keys (fall back to English)');
      }
    }
  }
  if (failed) exit(1);
  stdout.writeln('Merged ${files.length} ARB parts into ${byLocale.length} locales.');
}
