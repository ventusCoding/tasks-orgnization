/// The entity a scoped Insights screen is about (header name, color, icon). Pure Dart.
library;

import 'package:meta/meta.dart';

@immutable
final class ScopeEntity {
  const ScopeEntity(this.id, this.name, {this.color, this.icon, this.parentId, this.isQuit = false, this.recurring = false});

  final String id;
  final String name;

  /// ARGB color of the entity (task, checklist, habit), if any.
  final int? color;
  final String? icon;

  /// Series of a task / checklist of an item.
  final String? parentId;
  final bool isQuit;

  /// A task that belongs to a recurring series (its sheet links to the series stats).
  final bool recurring;

  @override
  bool operator ==(Object other) =>
      other is ScopeEntity && other.id == id && other.name == name && other.color == color && other.icon == icon;

  @override
  int get hashCode => Object.hash(id, name, color, icon);
}

/// A selectable filter option (category, tag).
@immutable
final class FilterOption {
  const FilterOption(this.id, this.name, {this.color});

  final String id;
  final String name;
  final int? color;
}
