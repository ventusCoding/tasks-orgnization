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

  void push(String label, OpRecord record) {
    if (record.isEmpty) return;
    _undo.add(UndoEntry(label: label, record: record));
    if (_undo.length > maxDepth) _undo.removeAt(0);
    _redo.clear();
    notifyListeners();
  }

  Future<bool> undo() async {
    if (_undo.isEmpty) return false;
    final entry = _undo.removeLast();
    final inverse = await _writer.revert(entry.record);
    _redo.add(UndoEntry(label: entry.label, record: inverse));
    notifyListeners();
    return true;
  }

  Future<bool> redo() async {
    if (_redo.isEmpty) return false;
    final entry = _redo.removeLast();
    final inverse = await _writer.revert(entry.record);
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
