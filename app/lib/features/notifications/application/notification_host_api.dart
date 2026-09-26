import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/data/notification_rules_repository.dart';
import 'package:everslot/features/notifications/data/notify_mode_store.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:everslot/features/notifications/domain/rule_draft.dart';

/// Reminders of an item that isn't saved yet (T7.1.09 "works for unsaved drafts"). The host
/// editor creates one, passes it to `NotificationSettingsSection(draft: …)` and saves it with the
/// item in ONE transaction through [NotificationHostApi.saveDraftInTx].
class NotificationRulesDraft extends ChangeNotifier {
  NotificationRulesDraft({
    NotifyMode notifyMode = NotifyMode.inherit,
    List<RuleDraft> rules = const [],
  }) : _notifyMode = notifyMode,
       _rules = [...rules];

  final List<RuleDraft> _rules;
  NotifyMode _notifyMode;

  List<RuleDraft> get rules => List.unmodifiable(_rules);
  NotifyMode get notifyMode => _notifyMode;
  bool get isEmpty => _rules.isEmpty && _notifyMode == NotifyMode.inherit;

  set notifyMode(NotifyMode value) {
    if (value == _notifyMode) return;
    _notifyMode = value;
    notifyListeners();
  }

  void add(RuleDraft draft) {
    _rules.add(draft);
    notifyListeners();
  }

  void replaceAt(int index, RuleDraft draft) {
    _rules[index] = draft;
    notifyListeners();
  }

  void removeAt(int index) {
    _rules.removeAt(index);
    notifyListeners();
  }

  /// The pending rules bound to [targetId] (ids are assigned on save).
  List<RuleDraft> boundTo(String targetId) => [
    for (final d in _rules) d.copyWith(targetId: targetId),
  ];
}

/// What other features need to persist reminders together with their own items (T7.1.02
/// cascades, T7.1.09 drafts, T7.1.15 copies). Every method runs inside the HOST's `SyncWriter`
/// transaction so the item and its reminders form one operation (one undo, one atomic push).
class NotificationHostApi {
  NotificationHostApi(this._rules, this._mutes, this._modes);

  final NotificationRulesRepository _rules;
  final NotificationMutesRepository _mutes;
  final NotifyModeStore _modes;

  static RuleTargetType _ruleType(NotificationTargetType type) =>
      RuleTargetType.forTarget(type) ??
      (throw ArgumentError.value(type, 'type', 'not an item target type'));

  /// Saves [draft] for the item [targetId] (call it AFTER inserting the item row in the same
  /// transaction): inserts the rules and writes the item's `notify_mode`. Returns the rule ids.
  Future<List<String>> saveDraftInTx(
    WriteTx tx,
    NotificationRulesDraft draft, {
    required NotificationTargetType type,
    required String targetId,
  }) async {
    final ruleType = _ruleType(type);
    final ids = await _rules.insertInTx(tx, [
      for (final d in draft.rules)
        d.copyWith(targetType: ruleType, targetId: targetId, isDefault: false),
    ]);
    if (draft.notifyMode != NotifyMode.inherit)
      await _modes.setInTx(tx, ruleType, targetId, draft.notifyMode);
    return ids;
  }

  /// Cascade for item deletion: soft-deletes the item's own rules and mutes in the host's delete
  /// transaction (restoring the item restores nothing here — reminders are re-added by the user).
  Future<void> deleteForTargetInTx(
    WriteTx tx,
    NotificationTargetType type,
    String targetId,
  ) async {
    await _rules.softDeleteForTargetInTx(tx, _ruleType(type), targetId);
    await _mutes.softDeleteForTargetInTx(tx, type.wire, targetId);
  }

  /// "Duplicate item": copies the own rules of [fromId] to [toId] (as own, non-default rules).
  Future<List<String>> copyRulesInTx(
    WriteTx tx,
    NotificationTargetType type, {
    required String fromId,
    required String toId,
  }) async {
    final ruleType = _ruleType(type);
    final source = await _rules.forTarget(ruleType, fromId);
    return _rules.insertInTx(tx, [
      for (final r in source)
        RuleDraft.fromRule(
          r,
          targetType: ruleType,
          targetId: toId,
          isDefault: false,
        ),
    ]);
  }
}

final notificationHostApiProvider = Provider<NotificationHostApi>(
  (ref) => NotificationHostApi(
    ref.watch(notificationRulesRepositoryProvider),
    ref.watch(notificationMutesRepositoryProvider),
    ref.watch(notifyModeStoreProvider),
  ),
);
