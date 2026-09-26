import 'package:everslot/features/planner/domain/view_config/planner_view_config.dart';
import 'package:meta/meta.dart';

/// A persisted planner view (`saved_views`, section `planner`).
@immutable
class SavedView {
  const SavedView({
    required this.id,
    required this.name,
    required this.config,
    required this.isDefault,
    required this.sortKey,
  });

  final String id;
  final String name;
  final PlannerViewConfig config;
  final bool isDefault;
  final String sortKey;

  PlannerViewType get type => config.type;

  SavedView copyWith({String? name, PlannerViewConfig? config, bool? isDefault, String? sortKey}) => SavedView(
    id: id,
    name: name ?? this.name,
    config: config ?? this.config,
    isDefault: isDefault ?? this.isDefault,
    sortKey: sortKey ?? this.sortKey,
  );

  @override
  bool operator ==(Object other) =>
      other is SavedView &&
      other.id == id &&
      other.name == name &&
      other.config == config &&
      other.isDefault == isDefault &&
      other.sortKey == sortKey;

  @override
  int get hashCode => Object.hash(id, name, config, isDefault, sortKey);

  @override
  String toString() => 'SavedView($id, $name, ${config.type.id})';
}
