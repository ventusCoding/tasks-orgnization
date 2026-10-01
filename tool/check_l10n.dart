// Localization consistency check (T1.3.13) over the per-feature ARB parts
// (`app/lib/l10n/parts/<area>_<locale>.arb`, merged by `tool/merge_arb.dart`):
//
//  * every area ships EN (template), FR and AR files with exactly the same message keys;
//  * a key is defined by one area only;
//  * every message is valid ICU for gen-l10n (balanced braces, plural/select with `other`);
//  * the EN template declares every placeholder it uses (`@key.placeholders`);
//  * translations use only declared placeholders and keep the template's plural/select arguments.
//
// Usage (repo root):  fvm dart run tool/check_l10n.dart [--parts <dir>]
// Prints one line per problem and exits with 1 when there is any (2 on bad usage).
import 'dart:convert';
import 'dart:io';

const locales = ['en', 'fr', 'ar'];
const template = 'en';

void main(List<String> args) {
  exitCode = run(args, stdout);
}

int run(List<String> args, StringSink out) {
  var partsPath = 'app/lib/l10n/parts';
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--parts' && i + 1 < args.length) {
      partsPath = args[++i];
    } else {
      out.writeln('Usage: dart run tool/check_l10n.dart [--parts <dir>]');
      return 2;
    }
  }
  final dir = Directory(partsPath);
  if (!dir.existsSync()) {
    out.writeln('No ARB parts directory at $partsPath');
    return 2;
  }
  final files = {
    for (final f in dir.listSync().whereType<File>())
      if (f.path.endsWith('.arb')) f.uri.pathSegments.last: f.readAsStringSync(),
  };
  final problems = checkParts(files)..forEach(out.writeln);
  if (problems.isEmpty) {
    out.writeln('Localizations OK: ${files.length} ARB parts checked.');
    return 0;
  }
  out.writeln('${problems.length} localization problem(s) — every key needs EN, FR and AR (ICU plurals).');
  return 1;
}

/// Checks ARB part contents keyed by file name (`<area>_<locale>.arb`).
List<String> checkParts(Map<String, String> files) {
  final problems = <String>[];
  // area → locale → decoded messages.
  final areas = <String, Map<String, Map<String, Object?>>>{};
  for (final e in files.entries) {
    final name = e.key.replaceAll('.arb', '');
    final idx = name.lastIndexOf('_');
    if (idx <= 0) {
      problems.add('${e.key}: file name must be <area>_<locale>.arb');
      continue;
    }
    final area = name.substring(0, idx);
    final locale = name.substring(idx + 1);
    if (!locales.contains(locale)) {
      problems.add('${e.key}: unsupported locale "$locale" (expected ${locales.join('/')})');
      continue;
    }
    Object? decoded;
    try {
      decoded = jsonDecode(e.value);
    } on FormatException catch (err) {
      problems.add('${e.key}: invalid JSON (${err.message})');
      continue;
    }
    if (decoded is! Map) {
      problems.add('${e.key}: top level must be a JSON object');
      continue;
    }
    areas.putIfAbsent(area, () => {})[locale] = Map<String, Object?>.from(decoded);
  }

  final owners = <String, String>{};
  for (final area in areas.keys.toList()..sort()) {
    final byLocale = areas[area]!;
    final en = byLocale[template];
    if (en == null) {
      problems.add('$area: missing template ${area}_$template.arb');
      continue;
    }
    final keys = _messageKeys(en);
    for (final key in keys) {
      final previous = owners[key];
      if (previous != null) {
        problems.add('$area: key "$key" is already defined by $previous');
      }
      owners[key] = area;
    }
    final templateArgs = <String, Map<String, String>>{};
    for (final key in keys) {
      final file = '${area}_$template.arb';
      final value = en[key];
      if (value is! String) {
        problems.add('$file: "$key" must be a string');
        continue;
      }
      final Map<String, String> args;
      try {
        args = IcuMessage.arguments(value);
      } on FormatException catch (err) {
        problems.add('$file: "$key" is not valid ICU (${err.message})');
        continue;
      }
      templateArgs[key] = args;
      final meta = en['@$key'];
      final declared = meta is Map && meta['placeholders'] is Map
          ? (meta['placeholders'] as Map).keys.map((k) => '$k').toSet()
          : <String>{};
      final undeclared = args.keys.toSet().difference(declared);
      if (undeclared.isNotEmpty) {
        problems.add('$file: "$key" uses undeclared placeholder(s) ${undeclared.join(', ')}');
      }
    }
    for (final locale in locales.where((l) => l != template)) {
      final file = '${area}_$locale.arb';
      final translation = byLocale[locale];
      if (translation == null) {
        problems.add('$area: missing $file (${keys.length} untranslated keys)');
        continue;
      }
      final translated = _messageKeys(translation);
      for (final key in keys.where((k) => !translated.contains(k))) {
        problems.add('$file: missing translation of "$key"');
      }
      for (final key in translated.where((k) => !keys.contains(k))) {
        problems.add('$file: "$key" is not in the EN template');
      }
      for (final key in keys.where(translated.contains)) {
        final value = translation[key];
        if (value is! String) {
          problems.add('$file: "$key" must be a string');
          continue;
        }
        final Map<String, String> args;
        try {
          args = IcuMessage.arguments(value);
        } on FormatException catch (err) {
          problems.add('$file: "$key" is not valid ICU (${err.message})');
          continue;
        }
        final expected = templateArgs[key];
        if (expected == null) continue;
        for (final a in args.entries) {
          final kind = expected[a.key];
          if (kind == null) {
            problems.add('$file: "$key" uses placeholder "${a.key}" unknown to the EN template');
          } else if (kind != 'simple' && a.value != 'simple' && kind != a.value) {
            problems.add('$file: "$key" uses "${a.key}" as ${a.value}, the template as $kind');
          }
        }
        for (final e in expected.entries.where((e) => e.value != 'simple')) {
          if (args[e.key] != e.value) {
            problems.add('$file: "$key" must keep the ${e.value} argument "${e.key}"');
          }
        }
      }
    }
  }
  return problems;
}

List<String> _messageKeys(Map<String, Object?> arb) => [
  for (final k in arb.keys)
    if (!k.startsWith('@')) k,
];

/// Minimal ICU MessageFormat reader (gen-l10n dialect without escaping): validates the syntax and
/// returns the arguments of a message with their kind (`simple`, `plural`, `select`, …).
abstract final class IcuMessage {
  static const _complex = {'plural', 'select', 'selectordinal'};
  static const _simpleTypes = {'number', 'date', 'time'};

  static Map<String, String> arguments(String message) {
    final result = <String, String>{};
    final end = _message(message, 0, result, nested: false);
    if (end != message.length) throw FormatException('unexpected "}" at $end');
    return result;
  }

  /// Reads text and arguments until an unmatched `}` (nested) or the end. Returns the index.
  static int _message(String s, int from, Map<String, String> out, {required bool nested}) {
    var i = from;
    while (i < s.length) {
      final c = s[i];
      if (c == '{') {
        i = _argument(s, i + 1, out);
      } else if (c == '}') {
        if (nested) return i;
        throw FormatException('unbalanced "}" at $i');
      } else {
        i++;
      }
    }
    if (nested) throw const FormatException('unclosed "{"');
    return i;
  }

  /// Reads an argument after its `{`; returns the index after its closing `}`.
  static int _argument(String s, int from, Map<String, String> out) {
    final close = _indexOfAny(s, from, const ['}', ',', '{']);
    if (close < 0) throw const FormatException('unclosed "{"');
    final name = s.substring(from, close).trim();
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name)) {
      throw FormatException('invalid argument name "$name"');
    }
    if (s[close] == '}') {
      _record(out, name, 'simple');
      return close + 1;
    }
    if (s[close] == '{') throw FormatException('unexpected "{" after "$name"');
    // "name, type" or "name, type, style…"
    final typeEnd = _indexOfAny(s, close + 1, const [',', '}']);
    if (typeEnd < 0) throw FormatException('unclosed argument "$name"');
    final type = s.substring(close + 1, typeEnd).trim();
    if (_simpleTypes.contains(type)) {
      final end = s.indexOf('}', typeEnd);
      if (end < 0) throw FormatException('unclosed argument "$name"');
      _record(out, name, 'simple');
      return end + 1;
    }
    if (!_complex.contains(type)) {
      throw FormatException('unknown argument type "$type"');
    }
    if (s[typeEnd] != ',') {
      throw FormatException('$type "$name" has no branches');
    }
    _record(out, name, type == 'selectordinal' ? 'plural' : type);
    var i = typeEnd + 1;
    final selectors = <String>{};
    while (true) {
      while (i < s.length && s[i].trim().isEmpty) {
        i++;
      }
      if (i >= s.length) throw FormatException('unclosed $type "$name"');
      if (s[i] == '}') break;
      final open = s.indexOf('{', i);
      if (open < 0) {
        throw FormatException('branch without message in $type "$name"');
      }
      final selector = s.substring(i, open).trim();
      if (selector.isEmpty || selector.contains('}')) {
        throw FormatException('invalid selector in $type "$name"');
      }
      if (!selector.startsWith('offset:') && !selectors.add(selector)) {
        throw FormatException('duplicate selector "$selector" in $type "$name"');
      }
      final branchEnd = _message(s, open + 1, out, nested: true);
      i = branchEnd + 1;
    }
    if (!selectors.contains('other')) {
      throw FormatException('$type "$name" has no "other" branch');
    }
    return i + 1;
  }

  static void _record(Map<String, String> out, String name, String kind) {
    final previous = out[name];
    if (previous == null || previous == 'simple') out[name] = kind;
  }

  static int _indexOfAny(String s, int from, List<String> chars) {
    for (var i = from; i < s.length; i++) {
      if (chars.contains(s[i])) return i;
    }
    return -1;
  }
}
