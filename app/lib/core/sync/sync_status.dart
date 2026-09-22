/// Sync engine state shown in the UI (T1.4.13).
enum SyncPhase { localOnly, idle, pushing, pulling, offline, error }

class SyncStatus {
  const SyncStatus({
    required this.phase,
    this.pendingChanges = 0,
    this.lastSuccessAt,
    this.lastError,
    this.initialSyncProgress,
  });

  static const localOnly = SyncStatus(phase: SyncPhase.localOnly);

  final SyncPhase phase;
  final int pendingChanges;
  final DateTime? lastSuccessAt;
  final String? lastError;

  /// 0..1 while an initial/full sync is running, else null.
  final double? initialSyncProgress;

  bool get isBusy => phase == SyncPhase.pushing || phase == SyncPhase.pulling;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingChanges,
    DateTime? lastSuccessAt,
    String? lastError,
    bool clearError = false,
    double? initialSyncProgress,
    bool clearProgress = false,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    pendingChanges: pendingChanges ?? this.pendingChanges,
    lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
    lastError: clearError ? null : (lastError ?? this.lastError),
    initialSyncProgress: clearProgress ? null : (initialSyncProgress ?? this.initialSyncProgress),
  );
}
