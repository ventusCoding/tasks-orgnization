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

  Category copyWith({
    String? name,
    int? color,
    String? icon,
    String? sortKey,
    bool? archived,
    bool? countsAsUnavailable,
  }) => Category(
    id: id,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    sortKey: sortKey ?? this.sortKey,
    archived: archived ?? this.archived,
    countsAsUnavailable: countsAsUnavailable ?? this.countsAsUnavailable,
  );

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

/// Category name rules (T2.3.01): trimmed, inner whitespace collapsed, 1–60 characters, unique per
/// user (case-insensitive) among non-deleted categories — mirrored by the partial unique index
/// `lower(name)` on the server.
abstract final class CategoryNames {
  static const maxLength = 60;

  /// Validation error codes carried by `ValidationException.message` (mapped to l10n in the UI).
  static const errorInvalid = 'category_name_invalid';
  static const errorDuplicate = 'category_name_duplicate';

  static String normalize(String input) => input.trim().replaceAll(RegExp(r'\s+'), ' ');

  static bool isValid(String normalized) => normalized.isNotEmpty && normalized.length <= maxLength;

  /// Case-insensitive comparison key.
  static String key(String name) => normalize(name).toLowerCase();
}

/// Entities that reference a category (`category_id`), by table.
abstract final class CategorizedTables {
  static const entityTypeByTable = {'tasks': 'task', 'habits': 'habit', 'checklists': 'checklist'};
}
