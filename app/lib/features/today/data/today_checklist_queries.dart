import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/today/domain/today_overview.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Read-only checklist queries of the Today screen (T8.1.08). The checklists feature has no
/// "due today" API, so Today reads the rows itself (never writes them).
class TodayChecklistQueries {
  TodayChecklistQueries(this._db, this._userId);

  final AppDatabase _db;
  final String Function() _userId;

  /// Cap on surfaced rows (Today is a summary; the Lists tab has the full views).
  static const limit = 200;

  /// Open items of live, non-archived, non-template lists that are due before [dueBefore]
  /// (wall-clock prefilter — the caller applies the precise zone rules) or waiting / blocked with
  /// a follow-up before [followUpBefore]. Ordered by due value, then follow-up.
  Stream<List<TodayChecklistItem>> watch({required LocalDate dueBefore, required DateTime followUpBefore}) => _db
      .customSelect(
        'SELECT i.id AS id, i.checklist_id AS cid, i.text AS txt, i.status AS status, i.status_note AS note, '
        'i.due_local AS due, i.time_zone AS tz, i.follow_up_at AS fu, i.priority AS prio, '
        'c.title AS ctitle, c.color AS ccolor, p.text AS ptext '
        'FROM checklist_items i '
        'JOIN checklists c ON c.id = i.checklist_id '
        'LEFT JOIN checklist_items p ON p.id = i.parent_id AND p.deleted_at IS NULL '
        'WHERE i.user_id = ? AND i.deleted_at IS NULL AND c.deleted_at IS NULL AND c.archived_at IS NULL '
        "AND c.is_template = 0 AND i.status IN ('todo','ongoing','waiting','blocked') "
        'AND ((i.due_local IS NOT NULL AND i.due_local < ?) '
        "OR (i.status IN ('waiting','blocked') AND i.follow_up_at IS NOT NULL AND i.follow_up_at < ?)) "
        'ORDER BY i.due_local IS NULL, i.due_local, i.follow_up_at, i.sort_key, i.id '
        'LIMIT $limit',
        variables: [
          Variable<String>(_userId()),
          Variable<String>(dueBefore.toIso()),
          Variable<String>(followUpBefore.toUtc().toIso8601String()),
        ],
        readsFrom: {_db.checklistItems, _db.checklists},
      )
      .watch()
      .map((rows) => [for (final r in rows) _map(r)]);

  /// Items completed in `[from, to)` (Today progress header, T8.1.11).
  Stream<int> watchCompletedBetween(DateTime from, DateTime to) => _db
      .customSelect(
        'SELECT COUNT(*) AS n FROM checklist_items i JOIN checklists c ON c.id = i.checklist_id '
        "WHERE i.user_id = ? AND i.deleted_at IS NULL AND c.deleted_at IS NULL AND i.status = 'completed' "
        'AND i.completed_at >= ? AND i.completed_at < ?',
        variables: [
          Variable<String>(_userId()),
          Variable<String>(from.toUtc().toIso8601String()),
          Variable<String>(to.toUtc().toIso8601String()),
        ],
        readsFrom: {_db.checklistItems, _db.checklists},
      )
      .watchSingle()
      .map((r) => r.read<int>('n'));

  static TodayChecklistItem _map(QueryRow r) {
    final due = r.readNullable<String>('due');
    return TodayChecklistItem(
      id: r.read<String>('id'),
      checklistId: r.read<String>('cid'),
      text: r.read<String>('txt'),
      status: ItemStatus.parse(r.read<String>('status')),
      statusNote: r.readNullable<String>('note'),
      dueLocal: due == null ? null : (LocalDateTime.tryParse(due) ?? LocalDate.tryParse(due)?.atStartOfDay),
      timeZone: r.readNullable<String>('tz'),
      followUpAt: r.readNullable<DateTime>('fu')?.toUtc(),
      priority: r.readNullable<int>('prio') ?? 0,
      checklistTitle: r.read<String>('ctitle'),
      checklistColor: r.readNullable<int>('ccolor'),
      parentText: r.readNullable<String>('ptext'),
    );
  }
}
