import 'package:uuid/uuid.dart';

/// Identifier helpers (arch §9.2).
///
/// New rows get UUIDv7 (time-ordered). Rows that several devices may create independently
/// get deterministic UUIDv5 ids in the Everslot namespace so they converge instead of duplicating.
abstract final class Ids {
  /// Everslot UUIDv5 namespace — identical to SQL `app.everslot_ns()`.
  static const everslotNamespace = '6f1c9a52-7c1e-4d3b-9a8e-2b5f0e4c7d11';

  static const _uuid = Uuid();

  /// New random time-ordered id.
  static String v7() => _uuid.v7();

  /// Deterministic id for [name] in the Everslot namespace.
  static String v5(String name) => _uuid.v5(everslotNamespace, name);

  // Deterministic ids used across the app (keep in sync with arch §9.2).
  static String taskOccurrence(String taskId, String occurrenceKey) => v5('$taskId|$occurrenceKey');
  static String habitDayState(String habitId, String key) => v5('$habitId|$key|state');
  static String habitPledge(String habitId, String day) => v5('$habitId|$day|pledge');
  static String inbox(String dedupeKey) => v5(dedupeKey);
  static String userSetting(String userId, String namespace) => v5('$userId|$namespace');
  static String entityTag(String tagId, String entityType, String entityId) =>
      v5('$tagId|$entityType|$entityId');
  static String checklistRun(String checklistId, String key) => v5('$checklistId|$key');
  static String defaultCategory(String userId, String key) => v5('$userId|default-category|$key');
  static String habitSection(String userId, String key) => v5('$userId|habit_section|$key');
  static String achievement(String code, String? scopeType, String? scopeId) =>
      v5('$code|${scopeType ?? ''}|${scopeId ?? ''}');
  static String rollover(String taskId, String date) => v5('$taskId|rollover|$date');
  static String builtinProfile(String userId, String code) => v5('$userId|notification_profile|$code');
  static String review(String userId, String periodKey) => v5('$userId|review|$periodKey');
}
