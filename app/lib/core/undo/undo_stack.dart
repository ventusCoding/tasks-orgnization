import 'package:everslot/core/sync/sync_writer.dart';
import 'package:flutter/foundation.dart';

/// An undoable user command (T2.3.06).
class UndoEntry {
  UndoEntry({required this.label, required this.record});

  final String label;
  OpRecord record;
}

/// In-memory, per-session undo/redo stack built on [SyncWriter.revert].
class UndoStack extends ChangeNotifier {
  UndoStack(this._writer, {this.maxDepth = 50});

  final SyncWriter _writer;
  final int maxDepth;
  final List<UndoEntry> _undo = [];
  final List<UndoEntry> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  String? get undoLabel => _undo.isEmpty ? null : _undo.last.label;
  String? get redoLabel => _redo.isEmpty ? null : _redo.last.label;

  void push(String label, OpRecord record) {
    if (record.isEmpty) return;
    _undo.add(UndoEntry(label: label, record: record));
    if (_undo.length > maxDepth) _undo.removeAt(0);
    _redo.clear();
    notifyListeners();
  }

  /// Merges the last [count] entries into one labelled [label] (a bulk command made of several
  /// operations undoes in one step). Their changes are reverted together, newest first.
  void squash(int count, String label) {
    final n = count.clamp(0, _undo.length);
    if (n < 2) {
      if (n == 1) _undo.last = UndoEntry(label: label, record: _undo.last.record);
      return;
    }
    final entries = _undo.sublist(_undo.length - n);
    _undo.removeRange(_undo.length - n, _undo.length);
    _undo.add(
      UndoEntry(
        label: label,
        record: OpRecord(
          opId: entries.last.record.opId,
          changes: [for (final e in entries) ...e.record.changes],
          cause: entries.last.record.cause,
        ),
      ),
    );
    notifyListeners();
  }

  /// The server rejected operation [opId] and the local rows were overwritten with the server
  /// state (T4.1.05): undoing it would write stale "before" values, so its entry becomes a no-op
  /// marker labelled [label] (undo/redo of a marker changes nothing). Returns whether an entry
  /// matched.
  bool neutralize(String opId, String label) {
    var found = false;
    for (final list in [_undo, _redo]) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].record.opId != opId) continue;
        list[i] = UndoEntry(
          label: label,
          record: OpRecord(opId: opId, changes: const [], cause: 'conflict'),
        );
        found = true;
      }
    }
    if (found) notifyListeners();
    return found;
  }

  Future<OpRecord> _revert(OpRecord record) async => record.isEmpty ? record : _writer.revert(record);

  Future<bool> undo() async {
    if (_undo.isEmpty) return false;
    final entry = _undo.removeLast();
    final inverse = await _revert(entry.record);
    _redo.add(UndoEntry(label: entry.label, record: inverse));
    notifyListeners();
    return true;
  }

  Future<bool> redo() async {
    if (_redo.isEmpty) return false;
    final entry = _redo.removeLast();
    final inverse = await _revert(entry.record);
    _undo.add(UndoEntry(label: entry.label, record: inverse));
    notifyListeners();
    return true;
  }

  void clear() {
    _undo.clear();
    _redo.clear();
    notifyListeners();
  }
}
