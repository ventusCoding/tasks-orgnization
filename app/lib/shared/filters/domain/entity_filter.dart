import 'package:collection/collection.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Shared filter model (T2.3.09) used by planner views, the lists board, habits, stats and search.
///
/// Criteria combine with AND; values inside one criterion combine with OR. The same filter gives
/// identical results through the pure [matches] predicate and the SQL builder
/// (`shared/filters/data/entity_filter_sql.dart`) — a property test keeps them in lock-step.
/// A field an entity doesn't have behaves like NULL: it never matches a set criterion (except
/// [noCategory], which matches entities without a category).
@immutable
class EntityFilter {
  const EntityFilter({
    this.categoryIds = const {},
    this.tagIds = const {},
    this.priorities = const {},
    this.statuses = const {},
    this.text,
    this.dateFrom,
    this.dateTo,
    this.hasAttachments,
    this.recurring,
  });

  /// Decodes the `filters` object of a view config (arch §8.3). Unknown keys are ignored here
  /// (the view config keeps them); malformed values fall back to "no filter".
  factory EntityFilter.fromJson(Object? json) {
    if (json is! Map) return empty;
    Set<String> strings(Object? v) => {
      if (v is List)
        for (final e in v)
          if (e is String && e.isNotEmpty) e,
    };
    return EntityFilter(
      categoryIds: strings(json['categories']),
      tagIds: strings(json['tags']),
      priorities: {
        if (json['priorities'] is List)
          for (final p in json['priorities'] as List)
            if (p is num && p >= 0 && p <= 4) p.toInt(),
      },
      statuses: strings(json['statuses']),
      text: json['text'] is String ? json['text'] as String : null,
      dateFrom: json['dateFrom'] is String ? LocalDate.tryParse(json['dateFrom'] as String) : null,
      dateTo: json['dateTo'] is String ? LocalDate.tryParse(json['dateTo'] as String) : null,
      hasAttachments: json['hasAttachments'] is bool ? json['hasAttachments'] as bool : null,
      recurring: json['recurring'] is bool ? json['recurring'] as bool : null,
    );
  }

  static const empty = EntityFilter();

  /// Pseudo category id matching entities without a category ("Uncategorized").
  static const noCategory = 'none';

  final Set<String> categoryIds;
  final Set<String> tagIds;

  /// Priority levels 0–4.
  final Set<int> priorities;

  /// Status keys of the filtered entity (task status, item status, `active`/`archived`…).
  final Set<String> statuses;

  /// Case-insensitive substring over the entity's text fields (ASCII case folding and Arabic
  /// letter normalization, see [FilterText.fold]).
  final String? text;

  /// Inclusive local-date range on the entity's date (start / due / start date).
  final LocalDate? dateFrom;
  final LocalDate? dateTo;

  /// null = don't care.
  final bool? hasAttachments;

  /// null = don't care; true = recurring only; false = one-off only.
  final bool? recurring;

  /// Trimmed text criterion, or null when blank.
  String? get effectiveText {
    final t = text?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  bool get hasDateRange => dateFrom != null || dateTo != null;

  /// Number of active criteria (filter bar badge).
  int get activeCount => [
    categoryIds.isNotEmpty,
    tagIds.isNotEmpty,
    priorities.isNotEmpty,
    statuses.isNotEmpty,
    effectiveText != null,
    hasDateRange,
    hasAttachments != null,
    recurring != null,
  ].where((active) => active).length;

  bool get isEmpty => activeCount == 0;

  /// Pure predicate — must stay equivalent to the SQL builder.
  bool matches(FilterSubject s) {
    if (categoryIds.isNotEmpty && !categoryIds.contains(s.categoryId ?? noCategory)) {
      return false;
    }
    if (tagIds.isNotEmpty && !s.tagIds.any(tagIds.contains)) return false;
    if (priorities.isNotEmpty && (s.priority == null || !priorities.contains(s.priority))) {
      return false;
    }
    if (statuses.isNotEmpty && (s.status == null || !statuses.contains(s.status))) {
      return false;
    }
    final t = effectiveText;
    if (t != null) {
      final needle = FilterText.fold(t);
      if (!s.texts.any((field) => FilterText.fold(field ?? '').contains(needle))) {
        return false;
      }
    }
    if (hasDateRange) {
      final d = s.date;
      if (d == null) return false;
      if (dateFrom != null && d.isBefore(dateFrom!)) return false;
      if (dateTo != null && d.isAfter(dateTo!)) return false;
    }
    if (hasAttachments != null && s.hasAttachments != hasAttachments) {
      return false;
    }
    if (recurring != null && s.isRecurring != recurring) return false;
    return true;
  }

  EntityFilter copyWith({
    Set<String>? categoryIds,
    Set<String>? tagIds,
    Set<int>? priorities,
    Set<String>? statuses,
    String? text,
    bool clearText = false,
    LocalDate? dateFrom,
    LocalDate? dateTo,
    bool clearDates = false,
    bool? hasAttachments,
    bool clearHasAttachments = false,
    bool? recurring,
    bool clearRecurring = false,
  }) => EntityFilter(
    categoryIds: categoryIds ?? this.categoryIds,
    tagIds: tagIds ?? this.tagIds,
    priorities: priorities ?? this.priorities,
    statuses: statuses ?? this.statuses,
    text: clearText ? null : (text ?? this.text),
    dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
    dateTo: clearDates ? null : (dateTo ?? this.dateTo),
    hasAttachments: clearHasAttachments ? null : (hasAttachments ?? this.hasAttachments),
    recurring: clearRecurring ? null : (recurring ?? this.recurring),
  );

  /// JSON for `saved_views.config.filters` (arch §8.3); inactive criteria are omitted except the
  /// four list keys and `text`, which the schema always carries.
  Map<String, Object?> toJson() => {
    'categories': categoryIds.toList()..sort(),
    'tags': tagIds.toList()..sort(),
    'priorities': priorities.toList()..sort(),
    'statuses': statuses.toList()..sort(),
    'text': effectiveText,
    if (dateFrom != null) 'dateFrom': dateFrom!.toIso(),
    if (dateTo != null) 'dateTo': dateTo!.toIso(),
    if (hasAttachments != null) 'hasAttachments': hasAttachments,
    if (recurring != null) 'recurring': recurring,
  };

  static const _setEq = SetEquality<Object?>();

  @override
  bool operator ==(Object other) =>
      other is EntityFilter &&
      _setEq.equals(other.categoryIds, categoryIds) &&
      _setEq.equals(other.tagIds, tagIds) &&
      _setEq.equals(other.priorities, priorities) &&
      _setEq.equals(other.statuses, statuses) &&
      other.effectiveText == effectiveText &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.hasAttachments == hasAttachments &&
      other.recurring == recurring;

  @override
  int get hashCode => Object.hash(
    _setEq.hash(categoryIds),
    _setEq.hash(tagIds),
    _setEq.hash(priorities),
    _setEq.hash(statuses),
    effectiveText,
    dateFrom,
    dateTo,
    hasAttachments,
    recurring,
  );

  @override
  String toString() => 'EntityFilter(${toJson()})';
}

/// The filterable facts of one entity (task, occurrence, checklist, item, habit…). Fields the
/// entity doesn't have stay null / empty.
@immutable
class FilterSubject {
  const FilterSubject({
    this.categoryId,
    this.tagIds = const {},
    this.priority,
    this.status,
    this.texts = const [],
    this.date,
    this.hasAttachments = false,
    this.isRecurring = false,
  });

  final String? categoryId;

  /// Ids of the entity's live tags.
  final Set<String> tagIds;
  final int? priority;
  final String? status;

  /// Searchable text fields (title, notes…).
  final List<String?> texts;

  /// The entity's reference date (start, due or start date), if any.
  final LocalDate? date;
  final bool hasAttachments;
  final bool isRecurring;
}

/// Text folding shared by the predicate and the SQL builder: ASCII-only lower-casing (exactly what
/// SQLite's built-in `lower()` does) plus Arabic letter normalization (alef variants → ا,
/// ى → ي, ة → ه, tatweel removed — mirrors the search index).
abstract final class FilterText {
  /// Arabic replacements applied before lower-casing, in order.
  static const arabicReplacements = <(String, String)>[
    ('أ', 'ا'),
    ('إ', 'ا'),
    ('آ', 'ا'),
    ('ى', 'ي'),
    ('ة', 'ه'),
    ('ـ', ''),
  ];

  static String fold(String input) {
    var s = input;
    for (final (from, to) in arabicReplacements) {
      s = s.replaceAll(from, to);
    }
    final units = s.codeUnits.toList(growable: false);
    for (var i = 0; i < units.length; i++) {
      final c = units[i];
      if (c >= 0x41 && c <= 0x5A) units[i] = c + 0x20;
    }
    return String.fromCharCodes(units);
  }
}
