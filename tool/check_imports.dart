// Source boundary checks for `app/lib` (T1.3.01 layer import boundaries, T1.3.14 RTL-safe APIs).
//
// Usage (repo root):  fvm dart run tool/check_imports.dart [--lib app/lib] [--no-rtl]
//
// Prints one line per violation — `path:line: [rule] message` — and exits with code 1 when any
// violation is found (CI step "Import boundaries"). A line can opt out of one check with a trailing
// `// boundary-ok <reason>` (imports) or `// rtl-ok <reason>` (directional APIs) comment.
//
// Layer rules (arch §6.1): a library's layer is the folder right below its module
// (`features/<module>/<layer>/…` or `shared/<module>/<layer>/…`).
//   domain-pure       domain/ may not import Flutter, Drift, Supabase, Firebase or Riverpod.
//   domain-layer      domain/ may not import data/, application/, presentation/, the database,
//                     sync, providers or UI code.
//   presentation-data presentation/ may not import any data/ layer, the database or Drift.
//   foreign-data      a module may not import another module's data/ layer (use its application/).
//   core-independent  core/ and design_system/ never import features/, shared/, app/ or startup/.
// RTL rules (arch §6.14): use EdgeInsetsDirectional, AlignmentDirectional, PositionedDirectional
// and TextAlign.start/end instead of left/right variants (symmetric insets are allowed).
import 'dart:io';

void main(List<String> args) {
  exitCode = run(args, stdout);
}

/// Runs the checks; returns the process exit code (0 = clean, 1 = violations, 2 = usage error).
int run(List<String> args, StringSink out) {
  var libDir = 'app/lib';
  var rtl = true;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--lib' when i + 1 < args.length:
        libDir = args[++i];
      case '--no-rtl':
        rtl = false;
      case '-h' || '--help':
        out.writeln('Usage: dart run tool/check_imports.dart [--lib app/lib] [--no-rtl]');
        return 0;
      default:
        out.writeln('Unknown argument: ${args[i]}');
        return 2;
    }
  }
  final dir = Directory(libDir);
  if (!dir.existsSync()) {
    out.writeln('Directory not found: $libDir (run from the repository root)');
    return 2;
  }
  final result = checkLibDirectory(dir, rtl: rtl);
  for (final v in result.violations) {
    out.writeln(v.format(libDir));
  }
  if (result.violations.isEmpty) {
    out.writeln('Boundaries OK: ${result.files} files checked.');
    return 0;
  }
  out.writeln(
    '${result.violations.length} boundary violation(s) in ${result.files} files — see arch §6.1 / '
    '§6.14 (add `// boundary-ok <reason>` or `// rtl-ok <reason>` only when justified).',
  );
  return 1;
}

/// One rule violation.
class Violation {
  const new(this.path, this.line, this.rule, this.message);

  /// Path relative to `lib/` (forward slashes).
  final String path;
  final int line;
  final String rule;
  final String message;

  String format(String libDir) => '$libDir/$path:$line: [$rule] $message';

  @override
  String toString() => '$path:$line: [$rule] $message';
}

/// Result of checking a directory.
class CheckResult {
  const new(this.files, this.violations);

  final int files;
  final List<Violation> violations;
}

/// Where a library lives inside `lib/`.
class LibLocation {
  const new(this.path, this.area, this.module, this.layer);

  /// Parses a path relative to `lib/` (e.g. `features/planner/domain/task.dart`).
  factory parse(String libPath) {
    final segments = libPath.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return LibLocation(libPath, '', null, null);
    final area = segments.first;
    if ((area == 'features' || area == 'shared') && segments.length > 2) {
      final layer = segments.length > 3 && layers.contains(segments[2]) ? segments[2] : null;
      return LibLocation(libPath, area, segments[1], layer);
    }
    return LibLocation(libPath, area, null, null);
  }

  static const layers = {'domain', 'data', 'application', 'presentation'};

  final String path;

  /// First folder below lib/ (`features`, `shared`, `core`, `design_system`, `app`, …).
  final String area;

  /// Feature / shared module name.
  final String? module;

  /// `domain` | `data` | `application` | `presentation` | null.
  final String? layer;

  bool get isModule => (area == 'features' || area == 'shared') && module != null;

  String get moduleKey => '$area/$module';
}

/// Checks every Dart library under [libDir] (generated files excluded).
CheckResult checkLibDirectory(Directory libDir, {bool rtl = true}) {
  final root = libDir.absolute.path.replaceAll(r'\', '/');
  final files =
      libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && !isGenerated(f.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final violations = <Violation>[];
  for (final file in files) {
    final absolute = file.absolute.path.replaceAll(r'\', '/');
    final relative = absolute.substring(root.length).replaceFirst(RegExp('^/+'), '');
    violations.addAll(checkSource(relative, file.readAsStringSync(), rtl: rtl));
  }
  return CheckResult(files.length, violations);
}

bool isGenerated(String path) {
  final p = path.replaceAll(r'\', '/');
  return p.endsWith('.g.dart') || p.contains('/l10n/generated/') || p.endsWith('.freezed.dart');
}

/// Checks one library given its path relative to `lib/` and its source.
List<Violation> checkSource(String libPath, String source, {bool rtl = true}) {
  final from = LibLocation.parse(libPath);
  final violations = <Violation>[];
  final masked = maskCommentsAndStrings(source);
  final originalLines = source.split('\n');
  final maskedLines = masked.split('\n');

  // Import / export directives (possibly spanning several lines). URIs never contain `//`, so
  // trailing comments are cut per line; the opt-out marker is looked up in the original lines.
  final buffer = StringBuffer();
  var directiveStart = 0;
  var optedOut = false;
  for (var i = 0; i < maskedLines.length; i++) {
    final code = maskedLines[i].trimLeft();
    final startsDirective = buffer.isEmpty && _directive.hasMatch(code);
    if (!startsDirective && buffer.isEmpty) continue;
    if (startsDirective) {
      directiveStart = i;
      optedOut = false;
    }
    buffer.write(' ${originalLines[i].split('//').first}');
    optedOut = optedOut || originalLines[i].contains('boundary-ok');
    if (!maskedLines[i].contains(';')) continue;
    final directive = buffer.toString();
    buffer.clear();
    if (optedOut) continue;
    for (final uri in _uris(directive)) {
      final v = _checkImport(from, uri);
      if (v != null) {
        violations.add(Violation(libPath, directiveStart + 1, v.$1, v.$2));
      }
    }
  }

  if (rtl) {
    for (final hit in _rtlHits(masked)) {
      final first = _lineOf(masked, hit.start);
      final last = _lineOf(masked, hit.end);
      final optedOut = originalLines
          .sublist(first, (last + 1).clamp(first + 1, originalLines.length))
          .any((l) => l.contains('rtl-ok'));
      if (!optedOut) {
        violations.add(Violation(libPath, first + 1, hit.rule, hit.message));
      }
    }
  }
  violations.sort((a, b) => a.line.compareTo(b.line));
  return violations;
}

final _directive = RegExp(r'^(import|export)(\s|$)');

int _lineOf(String text, int offset) => '\n'.allMatches(text.substring(0, offset)).length;

/// Replaces comments and string-literal contents with spaces (line breaks are kept) so that
/// source patterns are only matched in code.
String maskCommentsAndStrings(String source) {
  final out = StringBuffer();
  final n = source.length;
  void blank(int from, int to) {
    for (var k = from; k < to; k++) {
      out.write(source[k] == '\n' ? '\n' : ' ');
    }
  }

  var i = 0;
  while (i < n) {
    final c = source[i];
    if (source.startsWith('//', i)) {
      final end = source.indexOf('\n', i);
      final stop = end < 0 ? n : end;
      blank(i, stop);
      i = stop;
      continue;
    }
    if (source.startsWith('/*', i)) {
      var depth = 1;
      var k = i + 2;
      while (k < n && depth > 0) {
        if (source.startsWith('/*', k)) {
          depth++;
          k += 2;
        } else if (source.startsWith('*/', k)) {
          depth--;
          k += 2;
        } else {
          k++;
        }
      }
      blank(i, k);
      i = k;
      continue;
    }
    if (c == "'" || c == '"') {
      final raw = i > 0 && source[i - 1] == 'r';
      final quote = source.startsWith(c * 3, i) ? c * 3 : c;
      var k = i + quote.length;
      while (k < n) {
        if (!raw && source[k] == r'\') {
          k += 2;
          continue;
        }
        if (source.startsWith(quote, k)) break;
        if (quote.length == 1 && source[k] == '\n') break;
        k++;
      }
      final contentEnd = k.clamp(i + quote.length, n);
      out.write(quote);
      blank(i + quote.length, contentEnd);
      if (k < n && source.startsWith(quote, k)) {
        out.write(quote);
        i = k + quote.length;
      } else {
        i = contentEnd;
      }
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

final _uriPattern = RegExp('''['"]([^'"]+)['"]''');

/// All URIs of a directive (including conditional import alternatives).
Iterable<String> _uris(String directive) => _uriPattern
    .allMatches(directive)
    .map((m) => m.group(1)!)
    .where((u) => u.endsWith('.dart') || u.startsWith('dart:') || u.startsWith('package:'));

/// Resolves [uri] seen in [from] to a lib-relative path for app imports, or returns null for
/// external packages / SDK libraries.
String? resolveAppImport(LibLocation from, String uri) {
  if (uri.startsWith('package:everslot/')) {
    return uri.substring('package:everslot/'.length);
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return null;
  final base = from.path.split('/')..removeLast();
  for (final part in uri.split('/')) {
    if (part == '..') {
      if (base.isNotEmpty) base.removeLast();
    } else if (part != '.') {
      base.add(part);
    }
  }
  return base.join('/');
}

const _domainForbiddenPackages = {
  'flutter',
  'flutter_riverpod',
  'riverpod',
  'material_ui',
  'cupertino_ui',
  'drift',
  'drift_flutter',
  'sqlite3',
  'supabase',
  'supabase_flutter',
  'firebase_core',
  'firebase_messaging',
  'firebase_crashlytics',
  'go_router',
  'path_provider',
};

/// `core/` paths the pure domain layer may not depend on (arch §6.1: core/time, ids, errors and
/// ordering are domain-safe; the database is data-only).
const _domainForbiddenCore = [
  'core/database/',
  'core/sync/',
  'core/session/',
  'core/lifecycle/',
  'core/settings/',
  'core/undo/',
  'core/env/',
  'core/providers.dart',
];

const _upperAreas = {'features', 'shared', 'app', 'startup'};

String? _packageOf(String uri) {
  if (!uri.startsWith('package:')) return null;
  final rest = uri.substring('package:'.length);
  final slash = rest.indexOf('/');
  return slash < 0 ? rest : rest.substring(0, slash);
}

(String, String)? _checkImport(LibLocation from, String uri) {
  if (uri == 'dart:ui' && from.layer == 'domain') {
    return ('domain-pure', 'domain code must be pure Dart: `$uri` is Flutter engine API');
  }
  final package = _packageOf(uri);
  if (package != null && package != 'everslot') {
    if (from.layer == 'domain' && _domainForbiddenPackages.contains(package)) {
      return ('domain-pure', 'domain code must be pure Dart (no Flutter/Drift/Supabase/Riverpod): imports `$uri`');
    }
    if (from.layer == 'presentation' && const {'drift', 'drift_flutter', 'sqlite3'}.contains(package)) {
      return (
        'presentation-data',
        'presentation must not use the database directly (`$uri`); read application providers',
      );
    }
    return null;
  }
  final target = resolveAppImport(from, uri);
  if (target == null) return null;
  final to = LibLocation.parse(target);

  if (from.layer == 'domain') {
    if (to.isModule && to.layer != null && to.layer != 'domain') {
      return ('domain-layer', 'domain may not import the ${to.layer}/ layer (`$target`); depend on domain types only');
    }
    for (final core in _domainForbiddenCore) {
      if (target.startsWith(core)) {
        return ('domain-layer', 'domain may not import `$target` (infrastructure, not domain-safe)');
      }
    }
    if (const {'design_system', 'app', 'startup', 'l10n'}.contains(to.area)) {
      return ('domain-layer', 'domain may not import UI/app code (`$target`)');
    }
  }

  if (from.layer == 'presentation') {
    if (to.isModule && to.layer == 'data') {
      return (
        'presentation-data',
        'presentation may not import a data/ layer (`$target`); go through application providers',
      );
    }
    if (target.startsWith('core/database/')) {
      return ('presentation-data', 'presentation may not import the database (`$target`)');
    }
  }

  if (from.isModule && to.isModule && to.layer == 'data' && from.moduleKey != to.moduleKey) {
    return (
      'foreign-data',
      '${from.moduleKey} may not import ${to.moduleKey}/data (`$target`); use its application/ API',
    );
  }

  if ((from.area == 'core' || from.area == 'design_system') && _upperAreas.contains(to.area)) {
    return ('core-independent', '${from.area}/ must not depend on ${to.area}/ (`$target`)');
  }
  return null;
}

// ------------------------------------------------------------------------------------ RTL --

final _nonDirectionalAlignment = RegExp(
  r'\bAlignment\.(topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight)\b',
);
final _textAlign = RegExp(r'\bTextAlign\.(left|right)\b');
final _fromLtrb = RegExp(r'\bEdgeInsets\.fromLTRB\(');
final _onlyInsets = RegExp(r'\bEdgeInsets\.only\(');
final _positioned = RegExp(r'\bPositioned\(');

/// A non-directional API use found in masked source.
class _RtlHit {
  const new(this.start, this.end, this.rule, this.message);

  final int start;
  final int end;
  final String rule;
  final String message;
}

Iterable<_RtlHit> _rtlHits(String masked) sync* {
  for (final m in _nonDirectionalAlignment.allMatches(masked)) {
    yield _RtlHit(
      m.start,
      m.end,
      'rtl-alignment',
      'use AlignmentDirectional instead of `${m.group(0)}` (mirrors in RTL)',
    );
  }
  for (final m in _textAlign.allMatches(masked)) {
    yield _RtlHit(m.start, m.end, 'rtl-text-align', 'use TextAlign.start/end instead of `${m.group(0)}`');
  }
  for (final m in _fromLtrb.allMatches(masked)) {
    final args = _balancedArgs(masked, m.end);
    final parts = _splitArgs(args);
    if (parts.length == 4 && parts[0] != parts[2]) {
      yield _RtlHit(
        m.start,
        m.end + args.length,
        'rtl-insets',
        'asymmetric EdgeInsets.fromLTRB — use EdgeInsetsDirectional.fromSTEB',
      );
    }
  }
  for (final m in _onlyInsets.allMatches(masked)) {
    final args = _balancedArgs(masked, m.end);
    if (!_symmetricSides(args)) {
      yield _RtlHit(
        m.start,
        m.end + args.length,
        'rtl-insets',
        'EdgeInsets.only(left/right) — use EdgeInsetsDirectional.only(start/end)',
      );
    }
  }
  for (final m in _positioned.allMatches(masked)) {
    final args = _balancedArgs(masked, m.end);
    if (!_symmetricSides(args)) {
      yield _RtlHit(
        m.start,
        m.end + args.length,
        'rtl-positioned',
        'Positioned(left/right) — use PositionedDirectional(start/end)',
      );
    }
  }
}

/// Argument text of a call whose opening parenthesis ends right before [from].
String _balancedArgs(String source, int from) {
  var depth = 1;
  var k = from;
  while (k < source.length && depth > 0) {
    final ch = source[k];
    if (ch == '(' || ch == '[' || ch == '{') depth++;
    if (ch == ')' || ch == ']' || ch == '}') depth--;
    k++;
  }
  return source.substring(from, depth == 0 ? k - 1 : k);
}

/// True when the named arguments either don't use `left:`/`right:` or use both with the same value.
bool _symmetricSides(String args) {
  final parts = _splitArgs(args);
  String? side(String name) {
    for (final p in parts) {
      final m = RegExp('^$name\\s*:\\s*(.+)\$', dotAll: true).firstMatch(p);
      if (m != null) return m.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return null;
  }

  final left = side('left');
  final right = side('right');
  if (left == null && right == null) return true;
  return left != null && left == right;
}

/// Splits top-level comma-separated arguments.
List<String> _splitArgs(String args) {
  final result = <String>[];
  var depth = 0;
  final current = StringBuffer();
  for (var i = 0; i < args.length; i++) {
    final ch = args[i];
    if (ch == '(' || ch == '[' || ch == '{') depth++;
    if (ch == ')' || ch == ']' || ch == '}') depth--;
    if (ch == ',' && depth == 0) {
      result.add(current.toString().trim());
      current.clear();
    } else {
      current.write(ch);
    }
  }
  final last = current.toString().trim();
  if (last.isNotEmpty) result.add(last);
  return result;
}
