import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_stats_service.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/smart_suggestions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Smart reminder suggestions (T7.5.19): move an item's reminder just before the time the user
/// usually does it, on request or automatically once a week (with an inbox summary).
class SmartReminders {
  SmartReminders(this._ref);

  final Ref _ref;

  static const dismissedKey = 'notifications.smartDismissed';
  static const lastAutoKey = 'notifications.smartLastAuto';

  /// Activity looked at.
  static const window = Duration(days: 28);

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  DateTime get _now => _ref.read(clockProvider).nowUtc();

  Future<String?> _kv(String key) async =>
      (await _db
              .customSelect('SELECT value FROM local_kv WHERE key = ?', variables: [Variable<String>(key)])
              .getSingleOrNull())
          ?.read<String>('value');

  Future<void> _setKv(String key, String value) =>
      _db.customStatement('INSERT OR REPLACE INTO local_kv (key, value) VALUES (?, ?)', [key, value]);

  Future<Set<String>> _dismissed() async {
    final raw = await _kv(dismissedKey);
    if (raw == null) return {};
    try {
      return {for (final v in jsonDecode(raw) as List) '$v'};
    } on Object {
      return {};
    }
  }

  /// Current suggestions for the own, enabled, fixed-time reminders of habits and tasks.
  Future<List<ReminderSuggestion>> suggestions() async {
    final now = _now;
    final rules = [
      for (final r in await _ref.read(notificationRulesRepositoryProvider).all())
        if (r.enabled &&
            r.targetId != null &&
            (r.targetType == RuleTargetType.task || r.targetType == RuleTargetType.habit) &&
            SmartSuggestions.adjustableTime(r.spec.trigger) != null)
          r,
    ];
    if (rules.isEmpty) return const [];
    final activity = await _ref.read(notificationStatsServiceProvider).activity(now.subtract(window), now);
    final zones = _ref.read(zoneResolverProvider);
    final zone = _ref.read(deviceZoneProvider);
    final dismissed = await _dismissed();
    final out = <ReminderSuggestion>[];
    for (final rule in rules) {
      final key = '${rule.targetType.wire}:${rule.targetId}';
      final times = activity[key];
      if (times == null) continue;
      final s = SmartSuggestions.suggest(
        rule: rule,
        targetKey: key,
        minutes: [for (final t in times) zones.toLocal(t, zone).time.minuteOfDay],
      );
      if (s != null && !dismissed.contains(s.id)) out.add(s);
    }
    return out;
  }

  /// Item titles by target key, from recent notifications (titles live in the sections).
  Future<Map<String, String>> titles() async {
    final rows = await _ref.read(inboxRepositoryProvider).statsRows(from: _now.subtract(window));
    rows.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return {
      for (final r in rows)
        if (r.sourceType != null && r.sourceId != null) '${r.sourceType}:${r.sourceId}': r.title,
    };
  }

  Future<void> apply(ReminderSuggestion s) async {
    final repo = _ref.read(notificationRulesRepositoryProvider);
    final rule = (await repo.all()).where((r) => r.id == s.ruleId).firstOrNull;
    if (rule == null) return;
    await repo.update(
      rule.id,
      spec: rule.spec.copyWith(trigger: SmartSuggestions.withTime(rule.spec.trigger, s.proposed)),
    );
  }

  /// Never suggest this move again.
  Future<void> dismiss(ReminderSuggestion s) async {
    final all = {...await _dismissed(), s.id};
    await _setKv(dismissedKey, jsonEncode(all.toList()..sort()));
  }

  /// Automatic adjustment (Settings › Notifications › *Adjust automatically*): at most weekly,
  /// applies every suggestion and files a summary in the inbox. Returns the applied ones.
  Future<List<ReminderSuggestion>> autoAdjustIfDue() async {
    if (!_ref.read(notificationSettingsProvider).smartAdjust) return const [];
    final now = _now;
    final last = DateTime.tryParse(await _kv(lastAutoKey) ?? '');
    if (last != null && now.difference(last) < const Duration(days: 7)) return const [];
    await _setKv(lastAutoKey, now.toIso8601String());
    final applied = await suggestions();
    if (applied.isEmpty) return const [];
    for (final s in applied) {
      await apply(s);
    }
    final l = _ref.read(notificationTextsProvider).l10n;
    final names = await titles();
    final lines = [
      for (final s in applied)
        l.notifSmartSummaryLine(names[s.targetKey] ?? s.targetKey, s.current.toIso(), s.proposed.toIso()),
    ];
    final key = 'smart:${now.toIso8601String().substring(0, 10)}';
    await _ref
        .read(inboxRepositoryProvider)
        .upsertDelivered(
          InboxDelivery(
            dedupeKey: key,
            category: InboxCategory.system,
            title: l.notifSmartSummaryTitle(applied.length),
            body: lines.join('\n'),
            fireAt: now,
            section: NotificationSection.system,
            sourceType: 'system',
            sourceId: 'smart_adjust',
            payload: {'v': 1, 'dk': key, 'kind': 'notice'},
            via: 'inbox_only',
          ),
        );
    return applied;
  }
}

final smartRemindersProvider = Provider<SmartReminders>(SmartReminders.new);
