/// Helpers for the versioned JSON value objects of the notification system.
///
/// Every object keeps the map it was decoded from so that encoding preserves key order, explicit
/// `null`s and unknown (future) keys — `decode → encode` is byte-identical for canonical input
/// (T7.1.03).
library;

/// Merges freshly encoded [known] fields into the original [raw] map.
///
/// - keys of [raw] keep their position; known keys take the new value, known keys that are now
///   absent are dropped (unless the raw value was an explicit `null`, which is preserved);
/// - unknown keys of [raw] survive untouched;
/// - known keys missing from [raw] are appended in [known] order.
Map<String, Object?> mergeOrdered(
  Map<String, Object?>? raw,
  Map<String, Object?> known,
  Set<String> knownKeys,
) {
  final result = <String, Object?>{};
  if (raw != null) {
    for (final e in raw.entries) {
      if (knownKeys.contains(e.key)) {
        if (known.containsKey(e.key)) {
          result[e.key] = known[e.key];
        } else if (e.value == null) {
          result[e.key] = null;
        }
      } else {
        result[e.key] = e.value;
      }
    }
  }
  for (final e in known.entries) {
    if (!result.containsKey(e.key)) result[e.key] = e.value;
  }
  return result;
}

Map<String, Object?>? asJsonMap(Object? value) {
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return null;
}

String? asString(Object? value) => value is String ? value : null;

int? asInt(Object? value) => value is num ? value.toInt() : (value is String ? int.tryParse(value) : null);

num? asNum(Object? value) => value is num ? value : (value is String ? num.tryParse(value) : null);

bool? asBool(Object? value) => value is bool ? value : null;

List<String>? asStringList(Object? value) =>
    value is List ? [for (final v in value) if (v != null) v.toString()] : null;

List<int>? asIntList(Object? value) =>
    value is List ? [for (final v in value) if (asInt(v) != null) asInt(v)!] : null;

/// Deep equality for JSON-like values (maps, lists, scalars).
bool jsonEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !jsonEquals(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!jsonEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Hash consistent with [jsonEquals].
int jsonHash(Object? value) {
  if (value is Map) {
    var h = 0;
    for (final e in value.entries) {
      h ^= Object.hash(e.key, jsonHash(e.value));
    }
    return h;
  }
  if (value is List) return Object.hashAll(value.map(jsonHash));
  return value.hashCode;
}
