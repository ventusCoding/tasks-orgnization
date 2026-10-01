import 'package:everslot_recurrence/src/time/local_time.dart';

/// Strict JSON readers used by the rule codec (all throw [FormatException]).

Map<String, Object?> readMap(Object? json, String field) {
  if (json is Map<String, Object?>) return json;
  if (json is Map) {
    return {for (final e in json.entries) '${e.key}': e.value};
  }
  throw FormatException('"$field" must be an object', json);
}

int readInt(Object? value, String field) {
  if (value is int) return value;
  if (value is double && value == value.truncateToDouble() && value.isFinite) {
    return value.toInt();
  }
  throw FormatException('"$field" must be an integer', value);
}

int? readOptionalInt(Map<String, Object?> map, String key, String field) {
  final value = map[key];
  return value == null ? null : readInt(value, field);
}

List<int> readIntList(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List) throw FormatException('"$field" must be a list', value);
  return [for (final v in value) readInt(v, '$field[]')];
}

List<String> readStringList(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List) throw FormatException('"$field" must be a list', value);
  return [
    for (final v in value)
      if (v is String) v else throw FormatException('"$field[]" must be a string', v),
  ];
}

LocalTime readTime(Object? value, String field, {bool allowEndOfDay = false}) {
  if (value is! String) {
    throw FormatException('"$field" must be a "HH:mm" string', value);
  }
  final time = LocalTime.tryParse(value);
  if (time == null || (time.isEndOfDay && !allowEndOfDay)) {
    throw FormatException('"$field" must be a valid "HH:mm" time', value);
  }
  return time;
}
