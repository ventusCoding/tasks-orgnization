/// Human-readable time-zone labels (pure).
abstract final class ZoneLabels {
  /// `America/Argentina/Buenos_Aires` → `Buenos Aires`.
  static String city(String zone) {
    final last = zone.split('/').last;
    return last.replaceAll('_', ' ');
  }

  /// `America/Argentina/Buenos_Aires` → `America / Argentina`.
  static String region(String zone) {
    final parts = zone.split('/');
    if (parts.length < 2) return '';
    return parts.sublist(0, parts.length - 1).map((p) => p.replaceAll('_', ' ')).join(' / ');
  }

  /// `UTC+05:30`, `UTC−03:00`, `UTC`.
  static String offset(Duration offset) {
    if (offset == Duration.zero) return 'UTC';
    final sign = offset.isNegative ? '−' : '+';
    final minutes = offset.inMinutes.abs();
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return 'UTC$sign$h:$m';
  }

  /// Case- and accent-insensitive match on the zone id, city or region.
  static bool matches(String zone, String query) {
    final q = _fold(query.trim());
    if (q.isEmpty) return true;
    return _fold(zone.replaceAll('_', ' ')).contains(q);
  }

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[àáâãä]'), 'a')
      .replaceAll(RegExp('[èéêë]'), 'e')
      .replaceAll(RegExp('[ìíîï]'), 'i')
      .replaceAll(RegExp('[òóôõö]'), 'o')
      .replaceAll(RegExp('[ùúûü]'), 'u')
      .replaceAll('ç', 'c');

  /// Canonical, selectable zones: `Area/City` ids plus `UTC`, without legacy aliases
  /// (`US/Eastern`, `Etc/GMT+5`, `EST5EDT`…).
  static List<String> selectable(Iterable<String> all) {
    const areas = {
      'Africa',
      'America',
      'Antarctica',
      'Arctic',
      'Asia',
      'Atlantic',
      'Australia',
      'Europe',
      'Indian',
      'Pacific',
    };
    final list = [
      for (final z in all)
        if (z.contains('/') && areas.contains(z.split('/').first)) z,
    ]..sort();
    return ['UTC', ...list];
  }
}
