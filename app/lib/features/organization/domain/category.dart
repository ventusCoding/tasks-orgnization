import 'package:meta/meta.dart';

/// A user category (T2.3.01): colors planner tasks, habits and checklists; drives time-allocation stats.
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.sortKey,
    this.icon,
    this.archived = false,
    this.countsAsUnavailable = false,
  });

  final String id;
  final String name;

  /// ARGB color from the category palette.
  final int color;
  final String? icon;
  final String sortKey;
  final bool archived;

  /// Time in this category is excluded from capacity stats (e.g. Sleep, Time off).
  final bool countsAsUnavailable;

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.color == color &&
      other.icon == icon &&
      other.sortKey == sortKey &&
      other.archived == archived &&
      other.countsAsUnavailable == countsAsUnavailable;

  @override
  int get hashCode => Object.hash(id, name, color, icon, sortKey, archived, countsAsUnavailable);
}
