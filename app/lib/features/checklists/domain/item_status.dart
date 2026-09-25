/// Status of a checklist item (T4.3.01, arch §7.3 CHECK).
enum ItemStatus {
  todo,
  ongoing,
  waiting,
  blocked,
  completed,
  cancelled;

  static ItemStatus parse(String? value) {
    for (final s in values) {
      if (s.name == value) return s;
    }
    return ItemStatus.todo;
  }

  /// Not finished and not cancelled.
  bool get isOpen => this == todo || this == ongoing || this == waiting || this == blocked;

  /// Counts toward progress (cancelled is excluded).
  bool get isCountable => this != cancelled;

  /// No more work expected.
  bool get isTerminal => this == completed || this == cancelled;

  bool get isDone => this == completed;

  /// Statuses whose reason sheet opens by default.
  bool get promptsReason => this == waiting || this == blocked;

  /// Statuses that keep a follow-up date.
  bool get keepsFollowUp => this == waiting || this == blocked;

  /// Sort rank for "sort by status" (most urgent first).
  int get urgencyRank => switch (this) {
    blocked => 0,
    waiting => 1,
    ongoing => 2,
    todo => 3,
    completed => 4,
    cancelled => 5,
  };
}
