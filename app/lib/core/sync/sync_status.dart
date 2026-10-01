/// Sync engine state shown in the UI (T1.4.13).
enum SyncPhase { localOnly, idle, pushing, pulling, offline, error }

/// Stable error codes surfaced in [SyncStatus.errorCode] (mapped to localized text by the UI).
abstract final class SyncErrorCodes {
  /// The server refuses this build (`unsupported_client`, HTTP 426) → "Please update Everslot".
  static const unsupportedClient = 'unsupported_client';

  /// This device was revoked from Settings › Devices on another device.
  static const deviceRevoked = 'device_revoked';

  /// The session is no longer valid (refresh failed) → re-authenticate, outbox preserved.
  static const notAuthenticated = 'not_authenticated';

  /// Anything else (details in [SyncStatus.lastError]).
  static const unknown = 'unknown';
}

/// An operation group the server rejected as an integrity violation (`integrity_refetch`): its
/// outbox entries were dropped and its rows refetched (local copy = server state), arch §6.6.
/// Features turn it into user-facing notices (e.g. a checklist move cycle, T4.1.05).
class SyncRejection {
  const SyncRejection({required this.opId, required this.rows, required this.messages});

  /// The local operation group (`OpRecord.opId` of the write).
  final String opId;

  /// Table → ids of the rejected rows.
  final Map<String, Set<String>> rows;

  /// Server messages of the group's results (e.g. `checklist_cycle: …`).
  final List<String> messages;

  bool mentions(String prefix) => messages.any((m) => m.startsWith(prefix));

  @override
  String toString() => 'SyncRejection($opId, $rows, $messages)';
}

class SyncStatus {
  const SyncStatus({
    required this.phase,
    this.pendingChanges = 0,
    this.failedChanges = 0,
    this.lastSuccessAt,
    this.lastError,
    this.errorCode,
    this.initialSyncProgress,
  });

  static const localOnly = SyncStatus(phase: SyncPhase.localOnly);

  final SyncPhase phase;
  final int pendingChanges;

  /// Outbox entries the server rejected (Settings › Sync lists them).
  final int failedChanges;
  final DateTime? lastSuccessAt;
  final String? lastError;

  /// See [SyncErrorCodes].
  final String? errorCode;

  /// 0..1 while an initial/full sync is running, else null.
  final double? initialSyncProgress;

  bool get isBusy => phase == SyncPhase.pushing || phase == SyncPhase.pulling;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingChanges,
    int? failedChanges,
    DateTime? lastSuccessAt,
    String? lastError,
    String? errorCode,
    bool clearError = false,
    double? initialSyncProgress,
    bool clearProgress = false,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    pendingChanges: pendingChanges ?? this.pendingChanges,
    failedChanges: failedChanges ?? this.failedChanges,
    lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
    lastError: clearError ? null : (lastError ?? this.lastError),
    errorCode: clearError ? null : (errorCode ?? this.errorCode),
    initialSyncProgress: clearProgress ? null : (initialSyncProgress ?? this.initialSyncProgress),
  );

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.phase == phase &&
      other.pendingChanges == pendingChanges &&
      other.failedChanges == failedChanges &&
      other.lastSuccessAt == lastSuccessAt &&
      other.lastError == lastError &&
      other.errorCode == errorCode &&
      other.initialSyncProgress == initialSyncProgress;

  @override
  int get hashCode =>
      Object.hash(phase, pendingChanges, failedChanges, lastSuccessAt, lastError, errorCode, initialSyncProgress);

  @override
  String toString() => 'SyncStatus(${phase.name}, pending: $pendingChanges, failed: $failedChanges, error: $errorCode)';
}
