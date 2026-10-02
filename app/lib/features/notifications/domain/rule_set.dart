import 'dart:convert';

import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/rule_validation.dart';
import 'package:meta/meta.dart';

/// One reminder of a [RuleSet]: the rule spec plus its profile by *code* (built-in profiles have
/// stable codes; custom profiles are user-specific and fall back to the rule's default).
@immutable
class RuleSetEntry {
  const RuleSetEntry({required this.spec, this.profileCode, this.name, this.enabled = true});

  factory RuleSetEntry.fromJson(Map<String, Object?> json) => RuleSetEntry(
    spec: NotificationRuleSpec.fromJson(asJsonMap(json['spec']) ?? const {}),
    profileCode: asString(json['profile']),
    name: asString(json['name']),
    enabled: asBool(json['enabled']) ?? true,
  );

  final NotificationRuleSpec spec;
  final String? profileCode;
  final String? name;
  final bool enabled;

  Map<String, Object?> toJson() => {
    'spec': spec.toJson(),
    'profile': ?profileCode,
    'name': ?name,
    if (!enabled) 'enabled': false,
  };

  @override
  bool operator ==(Object other) =>
      other is RuleSetEntry &&
      other.spec == spec &&
      other.profileCode == profileCode &&
      other.name == name &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(spec, profileCode, name, enabled);
}

/// A named, reusable bundle of reminders (T7.1.18) — "Meeting style: 1 day before at 20:00,
/// 15 min before, at start" — for one kind of item ([targetType] wire: `task`, `checklist`,
/// `checklist_item`, `habit`). Stored in `user_settings.notification_rule_sets`; exported as a
/// small JSON file (`{"everslot": "rule_set", "v": 1, …}`).
@immutable
class RuleSet {
  const RuleSet({required this.id, required this.name, required this.targetType, required this.entries});

  factory RuleSet.fromJson(Map<String, Object?> json, {String? id}) => RuleSet(
    id: id ?? asString(json['id']) ?? '',
    name: asString(json['name']) ?? '',
    targetType: asString(json['targetType']) ?? 'task',
    entries: [
      for (final e in (json['rules'] as List?) ?? const <Object?>[])
        if (asJsonMap(e) != null) RuleSetEntry.fromJson(asJsonMap(e)!),
    ],
  );

  static const fileTag = 'rule_set';
  static const version = 1;
  static const maxNameLength = 60;
  static const maxEntries = 20;

  final String id;
  final String name;
  final String targetType;
  final List<RuleSetEntry> entries;

  RuleSet copyWith({String? id, String? name}) =>
      RuleSet(id: id ?? this.id, name: name ?? this.name, targetType: targetType, entries: entries);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'targetType': targetType,
    'rules': [for (final e in entries) e.toJson()],
  };

  /// Export file content (pretty JSON, no id — an import gets a fresh one).
  String toFile() => const JsonEncoder.withIndent('  ').convert({
    'everslot': fileTag,
    'v': version,
    'name': name,
    'targetType': targetType,
    'rules': [for (final e in entries) e.toJson()],
  });

  /// Parses an exported file; throws [FormatException] when it isn't a valid rule set (wrong tag,
  /// newer version, no rules, too many, an invalid rule).
  static RuleSet parseFile(String source, {required String id}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('not JSON');
    }
    final json = asJsonMap(decoded);
    if (json == null || json['everslot'] != fileTag) throw const FormatException('not an Everslot rule set');
    if ((asInt(json['v']) ?? 0) > version) throw const FormatException('made by a newer version');
    final set = RuleSet.fromJson(json, id: id);
    final name = set.name.trim();
    if (name.isEmpty || name.length > maxNameLength) throw const FormatException('invalid name');
    if (set.entries.isEmpty || set.entries.length > maxEntries) throw const FormatException('invalid rule count');
    for (final e in set.entries) {
      if (NotificationRuleValidator.validate(e.spec, acceptExtraActions: true).any((i) => i.isError)) {
        throw const FormatException('invalid rule');
      }
    }
    return set.copyWith(name: name);
  }

  @override
  bool operator ==(Object other) =>
      other is RuleSet &&
      other.id == id &&
      other.name == name &&
      other.targetType == targetType &&
      _listEquals(other.entries, entries);

  @override
  int get hashCode => Object.hash(id, name, targetType, Object.hashAll(entries));

  static bool _listEquals(List<RuleSetEntry> a, List<RuleSetEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
