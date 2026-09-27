import 'package:everslot/core/routing/deep_links.dart';
import 'package:meta/meta.dart';

/// What to do with a link that reached the app from outside (T8.2.01): widgets, shortcuts,
/// Siri / App Actions, other apps, universal links / Android App Links.
@immutable
sealed class ExternalLinkDecision {
  const ExternalLinkDecision();
}

/// Open a router path. [asRoot] = a tab root (`go`, keeps the tab stack) instead of a pushed page.
final class OpenPath extends ExternalLinkDecision {
  const OpenPath(this.path, {this.asRoot = false});

  final String path;
  final bool asRoot;

  /// Entity addressed by [path] (for the deleted → Trash check), if any.
  EntityRef? get entity => EntityRef.ofPath(path);

  @override
  bool operator ==(Object other) => other is OpenPath && other.path == path && other.asRoot == asRoot;

  @override
  int get hashCode => Object.hash(path, asRoot);

  @override
  String toString() => 'OpenPath($path${asRoot ? ', root' : ''})';
}

/// Handled elsewhere (Supabase auth callbacks) — do nothing.
final class IgnoreLink extends ExternalLinkDecision {
  const IgnoreLink(this.reason);

  final String reason;

  @override
  bool operator ==(Object other) => other is IgnoreLink && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'IgnoreLink($reason)';
}

/// Unknown, invalid or unsafe — show a friendly "not found", never crash.
final class RejectLink extends ExternalLinkDecision {
  const RejectLink(this.reason);

  final String reason;

  @override
  bool operator ==(Object other) => other is RejectLink && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'RejectLink($reason)';
}

/// An integration command (`everslot://share`, `everslot://do/…`) rather than a screen.
final class LinkCommand extends ExternalLinkDecision {
  const LinkCommand(this.name, [this.params = const {}]);

  /// `share`, `habit-log`, `next`, `focus`, `craving`.
  final String name;
  final Map<String, String> params;

  @override
  bool operator ==(Object other) =>
      other is LinkCommand &&
      other.name == name &&
      other.params.length == params.length &&
      other.params.entries.every((e) => params[e.key] == e.value);

  @override
  int get hashCode => Object.hash(name, Object.hashAllUnordered(params.entries.map((e) => '${e.key}=${e.value}')));

  @override
  String toString() => 'LinkCommand($name, $params)';
}

/// An entity addressed by a router path.
@immutable
class EntityRef {
  const EntityRef(this.kind, this.id);

  /// `task` | `checklist` | `habit`.
  final String kind;
  final String id;

  static EntityRef? ofPath(String path) {
    final segments = Uri.parse(path).pathSegments;
    if (segments.length < 2) return null;
    final id = segments[1];
    if (!ExternalLinkPolicy.isUuid(id)) return null;
    return switch (segments.first) {
      'task' => EntityRef('task', id),
      'lists' => EntityRef('checklist', id),
      'habits' || 'quit' => EntityRef('habit', id),
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) => other is EntityRef && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'EntityRef($kind, $id)';
}

/// Pure decision logic for external links (shared by app links, widgets, shortcuts and
/// Siri/App Actions). Router paths come from the single [DeepLinkParser]; this layer adds the
/// stricter checks external input deserves: ids must be UUIDs, dates ISO, parameters bounded,
/// and internal-only screens (debug menu, auth, onboarding) cannot be opened from outside.
abstract final class ExternalLinkPolicy {
  /// Universal / App Links domain: `APP_LINKS_DOMAIN` from `--dart-define-from-file=env/<flavor>.json`
  /// — the same value as `EVERSLOT_LINK_DOMAIN` (Xcode build setting → `Runner.entitlements`) and
  /// `appLinksHost` (`android/app/build.gradle.kts`). `YOUR_SITE_DOMAIN` is the placeholder used
  /// until the privacy site has a real domain (docs/guide.md › App links).
  static const linkDomain = String.fromEnvironment('APP_LINKS_DOMAIN', defaultValue: 'YOUR_SITE_DOMAIN');

  /// Hosts accepted for https links.
  static const defaultWebHosts = {linkDomain, 'www.$linkDomain'};

  /// Custom-scheme hosts consumed by other components (Supabase auth redirect).
  static const ignoredHosts = {'auth-callback', 'login-callback'};

  /// Tab roots (navigated with `go`).
  static const shellRoots = {'/today', '/plan', '/lists', '/habits', '/insights'};

  /// Paths that live inside the tab shell (every planner view is a Plan tab page).
  static bool isShellPath(String path) => shellRoots.contains(path) || path.startsWith('/plan/');

  /// Integration commands (`everslot://do/<name>`).
  static const commands = {'habit-log', 'next', 'focus', 'craving', 'new-task'};

  static final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  static final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _localDateTime = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$');
  static final _occurrenceKey = RegExp(r'^[0-9A-Za-z:#\-]{1,48}$');
  static final _slug = RegExp(r'^[a-z][a-z0-9_\-]{0,39}$');

  static bool isUuid(String value) => _uuid.hasMatch(value);

  /// Decides what to do with [uri]. Never throws.
  static ExternalLinkDecision decide(Uri uri, {Set<String> webHosts = defaultWebHosts}) {
    try {
      return _decide(uri, webHosts);
    } on FormatException {
      return const RejectLink('malformed');
    } on ArgumentError {
      return const RejectLink('malformed');
    }
  }

  static ExternalLinkDecision _decide(Uri uri, Set<String> webHosts) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == AppLinks.scheme) {
      final host = uri.host.toLowerCase();
      if (ignoredHosts.contains(host)) return const IgnoreLink('auth');
      if (host == 'share') return const LinkCommand('share');
      if (host == 'do') return _command(uri);
    } else if (scheme == 'https' || scheme == 'http') {
      if (!webHosts.contains(uri.host.toLowerCase())) return const RejectLink('host');
    } else {
      return const RejectLink('scheme');
    }
    final path = DeepLinkParser.parse(uri);
    if (path == null) return const RejectLink('unknown');
    final problem = validatePath(path);
    if (problem != null) return RejectLink(problem);
    return OpenPath(path, asRoot: isShellPath(Uri.parse(path).path));
  }

  static ExternalLinkDecision _command(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 1 || !commands.contains(segments.single)) return const RejectLink('command');
    final params = <String, String>{};
    for (final e in uri.queryParameters.entries) {
      if (e.key.length > 32 || e.value.length > 200) return const RejectLink('param');
      params[e.key] = e.value;
    }
    final name = segments.single;
    if (name == 'habit-log') {
      final value = params['value'];
      if (value != null) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed == null || parsed.isNaN || parsed <= 0 || parsed > 100000) return const RejectLink('value');
      }
      final id = params['habit'];
      final name = params['name'];
      if ((id == null || !isUuid(id)) && (name == null || name.trim().isEmpty)) return const RejectLink('habit');
    }
    return LinkCommand(name, params);
  }

  /// Returns a problem code when a parsed router path must not be opened from outside.
  static String? validatePath(String path) {
    final uri = Uri.parse(path);
    final s = uri.pathSegments;
    final q = uri.queryParameters;
    bool dateOk(String? v) => v == null || _date.hasMatch(v);
    switch (s.first) {
      case 'today' || 'inbox' || 'habits' when s.length == 1:
        return null;
      case 'lists' when s.length == 1:
        return null;
      case 'insights' when s.length == 1:
        return null;
      case 'plan':
        if (s.length == 1) return dateOk(q['date']) ? null : 'date';
        if (s.length == 2 && (s[1] == 'week' || s[1] == 'day')) return dateOk(q['date']) ? null : 'date';
        if (s.length == 3 && s[1] == 'view' && _slug.hasMatch(s[2])) return dateOk(q['date']) ? null : 'date';
        return 'path';
      case 'task':
        if (s.length < 2 || !isUuid(s[1])) return 'id';
        if (s.length == 3 && s[2] == 'edit') return null;
        if (s.length != 2) return 'path';
        final occ = q['occ'];
        return occ == null || _occurrenceKey.hasMatch(occ) ? null : 'occ';
      case 'task-new':
        if (s.length != 1) return 'path';
        final start = q['start'];
        if (start != null && !_localDateTime.hasMatch(start) && !_date.hasMatch(start)) return 'start';
        final duration = q['duration'];
        if (duration != null) {
          final minutes = int.tryParse(duration);
          if (minutes == null || minutes < 0 || minutes > 525600) return 'duration';
        }
        return null;
      case 'lists':
        if (s.length == 3 && s[1] == 'smart') return _slug.hasMatch(s[2]) ? null : 'kind';
        if (s.length != 2 || !isUuid(s[1])) return 'id';
        final item = q['item'];
        return item == null || isUuid(item) ? null : 'item';
      case 'habits':
        if (s.length < 2 || !isUuid(s[1])) return 'id';
        return s.length == 2 || (s.length == 3 && s[2] == 'edit') ? null : 'path';
      case 'habit-new':
        final kind = q['kind'];
        return s.length == 1 && (kind == null || kind == 'build' || kind == 'quit') ? null : 'kind';
      case 'quit':
        return s.length == 2 && isUuid(s[1]) ? null : 'id';
      case 'insights':
        if (!_slug.hasMatch(s[1])) return 'scope';
        if (s.length == 2) return null;
        return s.length == 3 && isUuid(s[2]) ? null : 'id';
      case 'search':
        return s.length == 1 ? null : 'path';
      case 'settings':
        if (s.length == 1) return null;
        return s.length == 2 && _slug.hasMatch(s[1]) ? null : 'page';
      default:
        // `dev`, `auth`, `onboarding`… are internal-only.
        return 'internal';
    }
  }
}
