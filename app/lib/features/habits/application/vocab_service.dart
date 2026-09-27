import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/data/habit_sections_repository.dart';
import 'package:everslot/features/habits/data/habits_repository.dart' show neighboursAt;
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trigger / place / coping / distraction libraries (T5.3.14): add, rename, restyle, archive and
/// reorder entries. Logs store entry ids, so a rename shows everywhere, history included.
class HabitVocabService {
  HabitVocabService(this._repo);

  final HabitVocabRepository _repo;

  Future<OpRecord> add(VocabKind kind, String name, {String? icon, int? color}) =>
      _repo.create(kind, name, icon: icon, color: color);

  Future<OpRecord> rename(String id, String name) => _repo.rename(id, name);

  Future<OpRecord> setArchived(String id, {required bool archived}) => _repo.setArchived(id, archived: archived);

  Future<OpRecord> setIcon(String id, String? icon) => _repo.setLook(id, icon: icon);

  Future<OpRecord> setColor(String id, int? color) => _repo.setLook(id, color: color);

  /// Moves [id] to [index] of [ordered] without it (drag and drop inside one kind).
  Future<OpRecord> reorder(String id, List<VocabEntry> ordered, int index) {
    final keys = [
      for (final e in ordered)
        if (e.id != id) e.sortKey,
    ];
    final n = neighboursAt(keys, index);
    return _repo.move(id, afterKey: n.after, beforeKey: n.before);
  }
}

final habitVocabServiceProvider = Provider<HabitVocabService>(
  (ref) => HabitVocabService(ref.watch(habitVocabRepositoryProvider)),
);

/// Every entry including archived ones (manage screen).
final allHabitVocabProvider = StreamProvider<List<VocabEntry>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(habitVocabRepositoryProvider).watchAll(includeArchived: true);
});
