import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/core/sync/sync_writer.dart' show OpRecord;
import 'package:everslot/features/notifications/application/notification_host_api.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/domain/effective_rules_resolver.dart';
import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_set.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `user_settings` namespace holding the rule sets: `{"v": 1, "sets": {"<id>": RuleSet}}`.
const ruleSetsNamespace = 'notification_rule_sets';

/// Rule sets (T7.1.18): save an item's reminders under a name, apply them to any item of the
/// same kind, export / import them as JSON files.
class RuleSets {
  RuleSets(this._ref);

  final Ref _ref;

  SettingsRepository get _settings => _ref.read(settingsRepositoryProvider);
  NotificationHostApi get _host => _ref.read(notificationHostApiProvider);

  static List<RuleSet> parse(Map<String, dynamic> value) {
    final sets = asJsonMap(value['sets']) ?? const {};
    return [
      for (final e in sets.entries)
        if (asJsonMap(e.value) != null) RuleSet.fromJson(asJsonMap(e.value)!, id: e.key),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<List<RuleSet>> all() async => parse(await _settings.read(ruleSetsNamespace));

  Future<void> put(RuleSet set) async {
    final value = await _settings.read(ruleSetsNamespace);
    final sets = {...?asJsonMap(value['sets']), set.id: set.toJson()};
    await _settings.update(ruleSetsNamespace, {'sets': sets});
  }

  Future<void> delete(String id) async {
    final value = await _settings.read(ruleSetsNamespace);
    final sets = {...?asJsonMap(value['sets'])}..remove(id);
    await _settings.update(ruleSetsNamespace, {'sets': sets});
  }

  /// Saves the own reminders of item [targetId] as [name] (occurrence-only reminders excluded);
  /// null when the item has none.
  Future<RuleSet?> saveFromTarget({
    required String name,
    required NotificationTargetType type,
    required String targetId,
  }) async {
    final rules = [
      for (final r in await _host.rulesOf(type, targetId))
        if (!EffectiveRulesResolver.isOccurrenceScoped(r)) r,
    ];
    if (rules.isEmpty) return null;
    final codes = {
      for (final p in await _ref.read(notificationProfilesRepositoryProvider).all())
        if (p.code != null) p.id: p.code!,
    };
    final set = RuleSet(
      id: Ids.v7(),
      name: name.trim(),
      targetType: type.wire,
      entries: [
        for (final r in rules.take(RuleSet.maxEntries))
          RuleSetEntry(spec: r.spec, profileCode: codes[r.profileId], name: r.name, enabled: r.enabled),
      ],
    );
    await put(set);
    return set;
  }

  /// Gives every item of [targetIds] a copy of [set] as its own reminders (replacing its own
  /// ones unless [replace] is false) and switches them to *Custom* — one undoable command.
  Future<OpRecord> apply(
    RuleSet set, {
    required NotificationTargetType type,
    required List<String> targetIds,
    required NotificationSection section,
    bool replace = true,
  }) async {
    final ids = {
      for (final p in await _ref.read(notificationProfilesRepositoryProvider).all())
        if (p.code != null) p.code!: p.id,
    };
    final ruleType = RuleTargetType.forTarget(type) ?? RuleTargetType.task;
    return _host.setReminders(type, targetIds, [
      for (final e in set.entries)
        NotificationRule(
          id: '',
          targetType: ruleType,
          section: section,
          spec: e.spec,
          enabled: e.enabled,
          name: e.name,
          profileId: e.profileCode == null ? null : ids[e.profileCode],
        ),
    ], replace: replace);
  }

  /// Imports an exported file as a new rule set; throws [FormatException] when invalid.
  Future<RuleSet> importFile(String source) async {
    final set = RuleSet.parseFile(source, id: Ids.v7());
    await put(set);
    return set;
  }
}

final ruleSetsServiceProvider = Provider<RuleSets>(RuleSets.new);

/// Saved rule sets (live), sorted by name.
final ruleSetsProvider = Provider<List<RuleSet>>(
  (ref) => RuleSets.parse(ref.watch(settingsProvider(ruleSetsNamespace)).value ?? const {}),
);
