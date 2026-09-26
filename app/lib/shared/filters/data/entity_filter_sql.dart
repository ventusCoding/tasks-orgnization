import 'package:drift/drift.dart';
import 'package:everslot/shared/filters/domain/entity_filter.dart';
import 'package:meta/meta.dart';

/// SQL expressions describing where each filterable field of an entity lives (T2.3.09).
///
/// Every value is an SQL expression over the caller's query (usually `alias.column`). A null
/// field means the entity has no such field; it then behaves like SQL `NULL`, exactly like a
/// null field of a [FilterSubject] in the pure predicate.
@immutable
class FilterColumns {
  const FilterColumns({
    required this.entityType,
    required this.id,
    this.categoryId,
    this.priority,
    this.status,
    this.texts = const [],
    this.date,
    this.recurrence,
    this.attachmentOwnerType,
  });

  /// SQL expression of the entity type used to join `entity_tags` (e.g. `'task'` or a column).
  final String entityType;

  /// SQL expression of the entity id.
  final String id;
  final String? categoryId;
  final String? priority;
  final String? status;
  final List<String> texts;

  /// Wall-clock / date text column; its first 10 characters are the local date.
  final String? date;

  /// Recurrence JSON column: the entity is recurring when it is not NULL.
  final String? recurrence;

  /// `attachments.owner_type` value for this entity, or null when it can't have attachments.
  final String? attachmentOwnerType;

  /// `tasks` (status = task status active/paused/archived; date = start).
  static FilterColumns tasks([String a = 'tasks']) => FilterColumns(
    entityType: "'task'",
    id: '$a.id',
    categoryId: '$a.category_id',
    priority: '$a.priority',
    status: '$a.status',
    texts: ['$a.title', '$a.notes'],
    date: '$a.start_local',
    recurrence: '$a.recurrence',
    attachmentOwnerType: 'task',
  );

  /// `checklists` (status = active/archived; date = due; recurring = resettable).
  static FilterColumns checklists([String a = 'checklists']) => FilterColumns(
    entityType: "'checklist'",
    id: '$a.id',
    categoryId: '$a.category_id',
    status:
        "CASE WHEN $a.archived_at IS NULL THEN 'active' ELSE 'archived' END",
    texts: ['$a.title', '$a.body'],
    date: '$a.due_local',
    recurrence: '$a.reset_rule',
    attachmentOwnerType: 'checklist',
  );

  /// `checklist_items` (item status; date = due).
  static FilterColumns checklistItems([String a = 'checklist_items']) =>
      FilterColumns(
        entityType: "'checklist_item'",
        id: '$a.id',
        priority: '$a.priority',
        status: '$a.status',
        texts: ['$a.text', '$a.note'],
        date: '$a.due_local',
        attachmentOwnerType: 'checklist_item',
      );

  /// `habits` (status = active/archived; date = start date; recurring = has a schedule).
  static FilterColumns habits([String a = 'habits']) => FilterColumns(
    entityType: "'habit'",
    id: '$a.id',
    categoryId: '$a.category_id',
    status:
        "CASE WHEN $a.archived_at IS NULL THEN 'active' ELSE 'archived' END",
    texts: ['$a.name', '$a.description'],
    date: '$a.start_date',
    recurrence: '$a.schedule',
    attachmentOwnerType: 'habit',
  );
}

/// A WHERE-clause fragment with its positional arguments.
@immutable
class SqlFragment {
  const SqlFragment(this.sql, this.args);

  static const alwaysTrue = SqlFragment('1', []);

  final String sql;
  final List<Object> args;

  List<Variable<Object>> get variables => [
    for (final a in args) Variable<Object>(a),
  ];
}

/// Translates an [EntityFilter] into SQL with the same semantics as [EntityFilter.matches].
abstract final class EntityFilterSql {
  /// WHERE fragment for [filter] over [c] (`1` when the filter is empty). Criteria are ANDed.
  static SqlFragment where(EntityFilter filter, FilterColumns c) {
    final parts = <String>[];
    final args = <Object>[];

    String inList(int n) => List.filled(n, '?').join(', ');

    if (filter.categoryIds.isNotEmpty) {
      final ids =
          filter.categoryIds
              .where((id) => id != EntityFilter.noCategory)
              .toList()
            ..sort();
      final includeNone = filter.categoryIds.contains(EntityFilter.noCategory);
      final col = c.categoryId ?? 'NULL';
      final options = <String>[
        if (ids.isNotEmpty) '$col IN (${inList(ids.length)})',
        if (includeNone) '$col IS NULL',
      ];
      parts.add('(${options.join(' OR ')})');
      args.addAll(ids);
    }

    if (filter.tagIds.isNotEmpty) {
      final ids = filter.tagIds.toList()..sort();
      parts.add(
        'EXISTS (SELECT 1 FROM entity_tags et WHERE et.entity_type = ${c.entityType} '
        'AND et.entity_id = ${c.id} AND et.deleted_at IS NULL '
        'AND et.tag_id IN (${inList(ids.length)}))',
      );
      args.addAll(ids);
    }

    if (filter.priorities.isNotEmpty) {
      final values = filter.priorities.toList()..sort();
      parts.add('(${c.priority ?? 'NULL'}) IN (${inList(values.length)})');
      args.addAll(values);
    }

    if (filter.statuses.isNotEmpty) {
      final values = filter.statuses.toList()..sort();
      parts.add('(${c.status ?? 'NULL'}) IN (${inList(values.length)})');
      args.addAll(values);
    }

    final text = filter.effectiveText;
    if (text != null) {
      if (c.texts.isEmpty) {
        parts.add('0');
      } else {
        final needle = FilterText.fold(text);
        parts.add(
          '(${c.texts.map((t) => 'instr(${foldSql(t)}, ?) > 0').join(' OR ')})',
        );
        for (var i = 0; i < c.texts.length; i++) {
          args.add(needle);
        }
      }
    }

    if (filter.hasDateRange) {
      final day = c.date == null ? 'NULL' : 'substr(${c.date}, 1, 10)';
      if (filter.dateFrom != null) {
        parts.add('$day >= ?');
        args.add(filter.dateFrom!.toIso());
      }
      if (filter.dateTo != null) {
        parts.add('$day <= ?');
        args.add(filter.dateTo!.toIso());
      }
      if (c.date == null) parts.add('0');
    }

    if (filter.hasAttachments != null) {
      final owner = c.attachmentOwnerType;
      final exists = owner == null
          ? '0'
          : 'EXISTS (SELECT 1 FROM attachments att WHERE att.owner_type = ? '
                'AND att.owner_id = ${c.id} AND att.deleted_at IS NULL)';
      parts.add(filter.hasAttachments! ? exists : 'NOT $exists');
      if (owner != null) args.add(owner);
    }

    if (filter.recurring != null) {
      final col = c.recurrence ?? 'NULL';
      parts.add(filter.recurring! ? '$col IS NOT NULL' : '$col IS NULL');
    }

    if (parts.isEmpty) return SqlFragment.alwaysTrue;
    return SqlFragment(parts.map((p) => '($p)').join(' AND '), args);
  }

  /// SQL mirror of [FilterText.fold] applied to [expr].
  static String foldSql(String expr) {
    var s = 'coalesce($expr, \'\')';
    for (final (from, to) in FilterText.arabicReplacements) {
      s = "replace($s, '$from', '$to')";
    }
    return 'lower($s)';
  }
}
