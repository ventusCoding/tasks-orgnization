/// Canonical in-app locations (arch §6.4) and the single deep-link parser (T1.3.07).
///
/// External links use the `everslot://` scheme: `everslot://task/<id>?occ=<key>` maps to the
/// router path `/task/<id>?occ=<key>`. Notification payloads, widgets, search and shortcuts all
/// use [AppLinks] builders so they round-trip through [DeepLinkParser].
abstract final class AppLinks {
  static const scheme = 'everslot';

  static String today() => '/today';
  static String planWeek({String? date}) => _q('/plan/week', {'date': date});
  static String planDay({String? date}) => _q('/plan/day', {'date': date});
  static String planView(String type, {String? date}) => _q('/plan/view/$type', {'date': date});
  static String task(String id, {String? occurrenceKey, bool reschedule = false}) =>
      _q('/task/$id', {'occ': occurrenceKey, 'reschedule': reschedule ? '1' : null});
  static String taskEdit(String id) => '/task/$id/edit';
  static String taskNew({String? start, int? duration, bool allDay = false}) =>
      _q('/task-new', {'start': start, 'duration': duration?.toString(), 'allDay': allDay ? '1' : null});
  static String lists() => '/lists';
  static String checklist(String id, {String? itemId, bool preview = false}) =>
      _q('/lists/$id', {'item': itemId, 'mode': preview ? 'preview' : null});
  static String checklistItem(String checklistId, String itemId) => checklist(checklistId, itemId: itemId);
  static String smartList(String kind) => '/lists/smart/$kind';
  static String habits() => '/habits';
  static String habit(String id) => '/habits/$id';
  static String habitNew({String kind = 'build'}) => _q('/habit-new', {'kind': kind});
  static String habitEdit(String id) => '/habits/$id/edit';
  static String quit(String id) => '/quit/$id';
  static String insights() => '/insights';
  static String insightsScope(String scope, [String? id]) => id == null ? '/insights/$scope' : '/insights/$scope/$id';
  static String inbox() => '/inbox';
  static String search({String? query}) => _q('/search', {'q': query});
  static String settings([String? page]) => page == null ? '/settings' : '/settings/$page';
  static String trash() => '/settings/trash';
  static String categories() => '/settings/categories';
  static String tags() => '/settings/tags';
  static String signIn() => '/auth/sign-in';
  static String onboarding() => '/onboarding';
  static String debug() => '/dev';

  /// Location of an entity by its `entity_type` (activity events, search hits, links, notification
  /// targets). Items need their checklist and habit-log notes their habit as [parentId]; returns
  /// null for types without a screen or a missing parent.
  static String? forEntity(String entityType, String id, {String? parentId, String? occurrenceKey}) =>
      switch (entityType) {
        'task' => task(id, occurrenceKey: occurrenceKey),
        'task_occurrence' when parentId != null => task(parentId, occurrenceKey: occurrenceKey),
        'checklist' => checklist(id),
        'checklist_item' when parentId != null => checklistItem(parentId, id),
        'habit' => habit(id),
        'habit_log' when parentId != null => habit(parentId),
        'category' => categories(),
        'tag' => tags(),
        _ => null,
      };

  /// External URI for a router path.
  static Uri external(String path) => Uri.parse('$scheme:/$path');

  static String _q(String path, Map<String, String?> params) {
    final p = {
      for (final e in params.entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    return p.isEmpty ? path : Uri(path: path, queryParameters: p).toString();
  }
}

/// Parses external URIs (`everslot://…`, `https://everslot.app/…`) into router paths.
abstract final class DeepLinkParser {
  static const _maxLength = 2048;
  static final _allowedRoots = {
    'today',
    'plan',
    'task',
    'task-new',
    'lists',
    'habits',
    'habit-new',
    'quit',
    'insights',
    'inbox',
    'search',
    'settings',
    'auth',
    'onboarding',
    'dev',
  };

  /// Returns a router path or null when the link is invalid/unknown. Never throws: malformed
  /// percent-encoding (decoded lazily by [Uri]) makes the link invalid.
  static String? parse(Uri uri) {
    try {
      return _parse(uri);
    } on FormatException {
      return null;
    }
  }

  static String? _parse(Uri uri) {
    final raw = uri.toString();
    if (raw.length > _maxLength) return null;
    List<String> segments;
    if (uri.scheme == AppLinks.scheme) {
      segments = [if (uri.host.isNotEmpty) uri.host, ...uri.pathSegments];
    } else if (uri.scheme == 'https' || uri.scheme == 'http') {
      segments = uri.pathSegments;
    } else if (uri.scheme.isEmpty) {
      segments = uri.pathSegments;
    } else {
      return null;
    }
    segments = segments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '/today';
    if (!_allowedRoots.contains(segments.first)) return null;
    if (segments.any((s) => s.length > 200 || s.contains('..'))) return null;
    final query = {
      for (final e in uri.queryParameters.entries)
        if (e.key.length <= 32 && e.value.length <= 256) e.key: e.value,
    };
    final path = '/${segments.join('/')}';
    return query.isEmpty ? path : Uri(path: path, queryParameters: query).toString();
  }
}
