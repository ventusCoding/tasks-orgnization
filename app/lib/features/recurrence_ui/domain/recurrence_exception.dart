import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Kind of a series exception listed by the exceptions manager (T2.1.19).
enum RecurrenceExceptionKind {
  /// The occurrence was removed ("delete this occurrence").
  cancelled,

  /// The occurrence was moved (and possibly resized).
  moved,

  /// Only its title, notes or duration were overridden.
  edited,

  /// Excluded by the rule's `exdates`.
  excluded,
}

/// One skipped/moved/edited occurrence of a series, identified by its original key.
@immutable
class RecurrenceExceptionEntry {
  const RecurrenceExceptionEntry({required this.key, required this.kind, this.movedTo, this.title});

  /// Original occurrence key (`YYYY-MM-DDTHH:mm`, `YYYY-MM-DD` or a quota slot key).
  final String key;
  final RecurrenceExceptionKind kind;

  /// New start of a moved occurrence (the owner's wall clock).
  final LocalDateTime? movedTo;

  /// Overridden title, when any.
  final String? title;

  /// Original start parsed from [key] (null for quota slot keys).
  LocalDateTime? get originalStart => LocalDateTime.tryParse(key) ?? LocalDate.tryParse(key)?.atStartOfDay;

  /// Whether [key] is a date-only key (all-day series or whole-day exdate).
  bool get isDateKey => LocalDateTime.tryParse(key) == null && LocalDate.tryParse(key) != null;

  /// Sort order: original start, then key.
  static int compare(RecurrenceExceptionEntry a, RecurrenceExceptionEntry b) {
    final sa = a.originalStart;
    final sb = b.originalStart;
    if (sa != null && sb != null && sa != sb) return sa.compareTo(sb);
    return a.key.compareTo(b.key);
  }

  @override
  bool operator ==(Object other) =>
      other is RecurrenceExceptionEntry &&
      other.key == key &&
      other.kind == kind &&
      other.movedTo == movedTo &&
      other.title == title;

  @override
  int get hashCode => Object.hash(key, kind, movedTo, title);

  @override
  String toString() => 'RecurrenceExceptionEntry($key, ${kind.name}${movedTo == null ? '' : ' → $movedTo'})';
}
