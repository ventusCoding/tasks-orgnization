/// Typed access to one `user_settings` namespace (arch §8.5, T8.3.01): defaults for missing or
/// invalid values, versioned upgrades, and unknown keys preserved on write (forward compatibility).
class SettingsCodec<T> {
  const SettingsCodec({
    required this.namespace,
    required this.version,
    required this.decoder,
    required this.encoder,
    this.upgrades = const {},
  });

  final String namespace;

  /// Current JSON version (`"v"`).
  final int version;
  final T Function(SettingsReader r) decoder;
  final Map<String, Object?> Function(T value) encoder;

  /// `fromVersion → upgrade to fromVersion + 1` (a missing `"v"` is version 0).
  final Map<int, Map<String, dynamic> Function(Map<String, dynamic> json)> upgrades;

  /// Decodes [raw] (any stored version). Problems (wrong types, unknown enum values, newer
  /// versions) go to [onWarning]; the affected fields fall back to their defaults.
  T decode(Map<String, dynamic> raw, {void Function(String problem)? onWarning}) {
    var json = Map<String, dynamic>.from(raw);
    var v = (json['v'] is num) ? (json['v'] as num).toInt() : 0;
    if (v > version) onWarning?.call('$namespace: stored v$v is newer than v$version — known keys only');
    while (v < version) {
      final upgrade = upgrades[v];
      if (upgrade != null) json = upgrade(json);
      v++;
    }
    return decoder(SettingsReader(json, namespace, onWarning));
  }

  /// The map to store for [value]: [existing] keys this version doesn't know are kept; the
  /// version never goes down (a newer client's data stays readable by it).
  Map<String, Object?> encode(T value, [Map<String, dynamic> existing = const {}]) {
    final existingV = existing['v'] is num ? (existing['v'] as num).toInt() : 0;
    return {...existing, ...encoder(value), 'v': existingV > version ? existingV : version};
  }

  /// Keys whose stored value differs between [before] and [after] (a minimal patch).
  static Map<String, Object?> diff(Map<String, Object?> before, Map<String, Object?> after) => {
    for (final e in after.entries)
      if (!_deepEquals(before[e.key], e.value)) e.key: e.value,
    for (final k in before.keys)
      if (!after.containsKey(k)) k: null,
  };

  static bool _deepEquals(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final k in a.keys) {
        if (!b.containsKey(k) || !_deepEquals(a[k], b[k])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is num && b is num) return a == b;
    return a == b;
  }
}

/// Lenient typed reads with defaults and warnings.
class SettingsReader {
  SettingsReader(this.json, this.namespace, this._warn);

  final Map<String, dynamic> json;
  final String namespace;
  final void Function(String problem)? _warn;

  void _problem(String key, Object? value, String expected) =>
      _warn?.call('$namespace.$key: expected $expected, got ${value.runtimeType} — default used');

  bool boolean(String key, bool fallback) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is bool) return v;
    _problem(key, v, 'bool');
    return fallback;
  }

  int integer(String key, int fallback, {int? min, int? max}) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is! num) {
      _problem(key, v, 'number');
      return fallback;
    }
    var n = v.toInt();
    if (min != null && n < min) n = min;
    if (max != null && n > max) n = max;
    return n;
  }

  int? optionalInt(String key, {int? min, int? max}) {
    final v = json[key];
    if (v == null) return null;
    if (v is! num) {
      _problem(key, v, 'number');
      return null;
    }
    final n = v.toInt();
    if ((min != null && n < min) || (max != null && n > max)) {
      _problem(key, v, 'number in [$min, $max]');
      return null;
    }
    return n;
  }

  String string(String key, String fallback, {Set<String>? allowed}) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is! String || (allowed != null && !allowed.contains(v))) {
      _problem(key, v, allowed == null ? 'string' : 'one of $allowed');
      return fallback;
    }
    return v;
  }

  E choice<E extends Enum>(String key, List<E> values, E fallback) {
    final v = json[key];
    if (v == null) return fallback;
    for (final e in values) {
      if (e.name == v) return e;
    }
    _problem(key, v, 'one of ${values.map((e) => e.name).toList()}');
    return fallback;
  }

  Set<String> stringSet(String key, Set<String> fallback, {Set<String>? allowed}) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is! List) {
      _problem(key, v, 'list');
      return fallback;
    }
    return {
      for (final e in v)
        if (e is String && (allowed == null || allowed.contains(e))) e,
    };
  }

  Map<String, dynamic> object(String key) {
    final v = json[key];
    if (v == null) return const {};
    if (v is Map) return Map<String, dynamic>.from(v);
    _problem(key, v, 'object');
    return const {};
  }
}
