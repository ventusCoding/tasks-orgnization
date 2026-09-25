import 'package:meta/meta.dart';

/// A user tag (T2.3.10): a cross-cutting label attached to tasks, checklists, checklist items and
/// habits through `entity_tags` rows with deterministic ids (`Ids.entityTag`).
@immutable
class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.sortKey,
    this.color,
  });

  final String id;
  final String name;

  /// ARGB color from the category palette, or null for a neutral tag.
  final int? color;
  final String sortKey;

  Tag copyWith({
    String? name,
    int? color,
    bool clearColor = false,
    String? sortKey,
  }) => Tag(
    id: id,
    name: name ?? this.name,
    color: clearColor ? null : (color ?? this.color),
    sortKey: sortKey ?? this.sortKey,
  );

  @override
  bool operator ==(Object other) =>
      other is Tag &&
      other.id == id &&
      other.name == name &&
      other.color == color &&
      other.sortKey == sortKey;

  @override
  int get hashCode => Object.hash(id, name, color, sortKey);

  @override
  String toString() => 'Tag($id, $name)';
}

/// Entity types that can carry tags (check constraint of `app.entity_tags`, arch §7.3).
abstract final class TaggableType {
  static const task = 'task';
  static const checklist = 'checklist';
  static const checklistItem = 'checklist_item';
  static const habit = 'habit';

  static const all = {task, checklist, checklistItem, habit};

  static bool isValid(String type) => all.contains(type);
}

/// A tagged entity (family key for providers).
typedef TaggedEntity = ({String type, String id});

/// Tag name rules: trimmed, inner whitespace collapsed, leading `#` dropped, 1–40 characters,
/// unique per user (case-insensitive) among non-deleted tags.
abstract final class TagNames {
  static const maxLength = 40;

  /// Validation error codes carried by `ValidationException.message` (mapped to l10n in the UI).
  static const errorInvalid = 'tag_name_invalid';
  static const errorDuplicate = 'tag_name_duplicate';

  static String normalize(String input) => input
      .trim()
      .replaceFirst(RegExp(r'^#+'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  static bool isValid(String normalized) =>
      normalized.isNotEmpty && normalized.length <= maxLength;

  /// Case-insensitive comparison key.
  static String key(String name) => normalize(name).toLowerCase();
}
