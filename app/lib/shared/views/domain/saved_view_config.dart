import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Sections that keep view presets in `app.saved_views` (arch §7.3).
abstract final class ViewSections {
  static const planner = 'planner';
  static const checklists = 'checklists';
  static const habits = 'habits';
  static const stats = 'stats';

  static const all = {planner, checklists, habits, stats};
}

/// Versioned codec of one section's view config (T2.3.08, arch §8.3). [decode] upgrades configs
/// written by older versions and must keep keys it does not know (a newer app version wrote them),
/// so that [encode] writes them back untouched.
abstract class ViewConfigCodec<C> {
  const ViewConfigCodec();

  /// `saved_views.section` this codec belongs to.
  String get section;

  /// Version written into `"v"`.
  int get currentVersion;

  /// View type stored in `saved_views.view_type` (a column, so lists can be filtered without parsing).
  String viewTypeOf(C config);

  /// Parses a stored config; [viewType] is the column value (used when the JSON lacks a type).
  C decode(Map<String, Object?> json, {String? viewType});

  Map<String, Object?> encode(C config);
}

/// A view preset of any section.
@immutable
class StoredView<C> {
  const StoredView({
    required this.id,
    required this.section,
    required this.name,
    required this.viewType,
    required this.config,
    required this.isDefault,
    required this.sortKey,
  });

  final String id;
  final String section;
  final String name;
  final String viewType;
  final C config;
  final bool isDefault;
  final String sortKey;

  @override
  bool operator ==(Object other) =>
      other is StoredView<C> &&
      other.id == id &&
      other.section == section &&
      other.name == name &&
      other.viewType == viewType &&
      other.config == config &&
      other.isDefault == isDefault &&
      other.sortKey == sortKey;

  @override
  int get hashCode => Object.hash(id, section, name, viewType, config, isDefault, sortKey);

  @override
  String toString() => 'StoredView($section/$viewType $id, $name)';
}

/// Config of sections without a typed model yet (Lists, Habits, Insights): a JSON map with a type,
/// a version and every other key kept as-is.
@immutable
class JsonViewConfig {
  JsonViewConfig(this.type, [Map<String, Object?> values = const {}]) : values = Map.unmodifiable(values);

  final String type;

  /// Every key except `type` and the version (including keys this version does not know).
  final Map<String, Object?> values;

  T? get<T>(String key) => values[key] is T ? values[key] as T : null;

  JsonViewConfig withValue(String key, Object? value) => JsonViewConfig(type, {...values, key: value});

  JsonViewConfig withType(String type) => JsonViewConfig(type, values);

  static const _deep = DeepCollectionEquality();

  @override
  bool operator ==(Object other) => other is JsonViewConfig && other.type == type && _deep.equals(other.values, values);

  @override
  int get hashCode => Object.hash(type, _deep.hash(values));

  @override
  String toString() => 'JsonViewConfig($type, $values)';
}

/// One upgrade step: turns a config of version `from` into version `from + 1` (mutates the map).
typedef ViewConfigUpgrade = void Function(Map<String, Object?> json);

/// Codec of [JsonViewConfig]: applies the [upgrades] (index `i` upgrades version `i + 1` → `i + 2`;
/// a missing version counts as 1) and never drops keys.
class JsonViewCodec extends ViewConfigCodec<JsonViewConfig> {
  const JsonViewCodec(this.section, {required this.defaultType, this.upgrades = const []});

  @override
  final String section;
  final String defaultType;
  final List<ViewConfigUpgrade> upgrades;

  @override
  int get currentVersion => upgrades.length + 1;

  @override
  String viewTypeOf(JsonViewConfig config) => config.type;

  @override
  JsonViewConfig decode(Map<String, Object?> json, {String? viewType}) {
    final map = Map<String, Object?>.of(json);
    var version = (map['v'] as num?)?.toInt() ?? 1;
    // Configs from a newer version are read as they are (only known keys matter here).
    while (version >= 1 && version < currentVersion) {
      upgrades[version - 1](map);
      version++;
    }
    final type = map['type'] is String ? map['type']! as String : viewType ?? defaultType;
    // A newer version number stays in the values, so writing back never downgrades it.
    if (version <= currentVersion) map.remove('v');
    map.remove('type');
    return JsonViewConfig(type, map);
  }

  @override
  Map<String, Object?> encode(JsonViewConfig config) => {'v': currentVersion, ...config.values, 'type': config.type};
}
