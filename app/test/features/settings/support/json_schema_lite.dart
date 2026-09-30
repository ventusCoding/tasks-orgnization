/// Minimal JSON Schema (2020-12 subset) validator for test fixtures: type, const, enum, required,
/// properties, additionalProperties, items, minimum, minLength, pattern, propertyNames/not and
/// local `$ref`s (`#/$defs/…`). Returns the list of violations (empty = valid).
List<String> validateJsonSchema(
  Object? value,
  Map<String, Object?> schema, {
  Map<String, Object?>? root,
  String at = r'$',
}) {
  final top = root ?? schema;
  final errors = <String>[];
  final ref = schema[r'$ref'];
  if (ref is String) {
    final parts = ref.replaceFirst('#/', '').split('/');
    Object? target = top;
    for (final p in parts) {
      target = (target as Map<String, Object?>)[p];
    }
    return validateJsonSchema(
      value,
      target! as Map<String, Object?>,
      root: top,
      at: at,
    );
  }
  bool typeOk(String t) => switch (t) {
    'object' => value is Map,
    'array' => value is List,
    'string' => value is String,
    'integer' => value is int,
    'number' => value is num,
    'boolean' => value is bool,
    'null' => value == null,
    _ => false,
  };
  final type = schema['type'];
  if (type is String && !typeOk(type))
    return ['$at: expected $type, got ${value.runtimeType}'];
  if (type is List && !type.cast<String>().any(typeOk))
    return ['$at: expected one of $type'];
  if (schema.containsKey('const') && schema['const'] != value)
    errors.add('$at: expected const ${schema['const']}');
  final enumValues = schema['enum'];
  if (enumValues is List && !enumValues.contains(value))
    errors.add('$at: not in enum');
  if (value is num &&
      schema['minimum'] is num &&
      value < (schema['minimum']! as num))
    errors.add('$at: below minimum');
  if (value is String) {
    if (schema['minLength'] is int &&
        value.length < (schema['minLength']! as int))
      errors.add('$at: too short');
    if (schema['pattern'] is String &&
        !RegExp(schema['pattern']! as String).hasMatch(value)) {
      errors.add('$at: "$value" does not match ${schema['pattern']}');
    }
  }
  final not = schema['not'];
  if (not is Map<String, Object?> &&
      validateJsonSchema(value, not, root: top, at: at).isEmpty)
    errors.add('$at: matches "not"');
  if (value is Map) {
    final props = (schema['properties'] as Map<String, Object?>?) ?? const {};
    for (final r in (schema['required'] as List?) ?? const []) {
      if (!value.containsKey(r)) errors.add('$at: missing "$r"');
    }
    final names = schema['propertyNames'];
    for (final e in value.entries) {
      final key = '${e.key}';
      if (names is Map<String, Object?>)
        errors.addAll(
          validateJsonSchema(key, names, root: top, at: '$at.$key(name)'),
        );
      final sub = props[key];
      if (sub is Map<String, Object?>) {
        errors.addAll(
          validateJsonSchema(e.value, sub, root: top, at: '$at.$key'),
        );
      } else {
        final extra = schema['additionalProperties'];
        if (extra == false) errors.add('$at: unexpected "$key"');
        if (extra is Map<String, Object?>)
          errors.addAll(
            validateJsonSchema(e.value, extra, root: top, at: '$at.$key'),
          );
      }
    }
  }
  if (value is List && schema['items'] is Map<String, Object?>) {
    for (var i = 0; i < value.length; i++) {
      errors.addAll(
        validateJsonSchema(
          value[i],
          schema['items']! as Map<String, Object?>,
          root: top,
          at: '$at[$i]',
        ),
      );
      if (errors.length > 20) break;
    }
  }
  return errors;
}
