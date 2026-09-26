import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/notifications/domain/default_rules.dart';
import 'package:everslot/features/notifications/domain/effective_rules_resolver.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/rule_validation.dart';

export 'package:everslot/features/notifications/domain/rule_draft.dart';

/// `notification_rules` (T7.1.02): reads Drift, writes through [SyncWriter] (row + outbox +
/// activity event).
class NotificationRulesRepository {
  NotificationRulesRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  static NotificationRule? mapRow(NotificationRuleRow r) {
    final spec = NotificationRuleSpec.tryDecode(r.spec);
    if (spec == null) return null;
    return NotificationRule(
      id: r.id,
      targetType: RuleTargetType.parse(r.targetType),
      targetId: r.targetId,
      section: NotificationSection.parse(r.section),
      isDefault: r.isDefault,
      enabled: r.enabled,
      name: r.name,
      profileId: r.profileId,
      spec: spec,
      sortKey: r.sortKey,
    );
  }

  SimpleSelectStatement<$NotificationRulesTable, NotificationRuleRow> _base() => _db.select(_db.notificationRules)
    ..where((r) => r.deletedAt.isNull() & r.userId.equals(_userId()))
    ..orderBy([(r) => OrderingTerm.asc(r.sortKey), (r) => OrderingTerm.asc(r.id)]);

  static List<NotificationRule> _mapAll(List<NotificationRuleRow> rows) => [for (final r in rows) ?mapRow(r)];

  Stream<List<NotificationRule>> watchAll() => _base().watch().map(_mapAll);

  Future<List<NotificationRule>> all() async => _mapAll(await _base().get());

  /// Own rules of a target (task, checklist, item, habit, category).
  Stream<List<NotificationRule>> watchForTarget(RuleTargetType type, String id) =>
      (_base()..where((r) => r.targetType.equals(type.wire) & r.targetId.equals(id))).watch().map(_mapAll);

  Future<List<NotificationRule>> forTarget(RuleTargetType type, String id) async =>
      _mapAll(await (_base()..where((r) => r.targetType.equals(type.wire) & r.targetId.equals(id))).get());

  /// Section defaults (`target_type = section`, `is_default`).
  Stream<List<NotificationRule>> watchSectionDefaults(NotificationSection section) => (_base()
        ..where((r) => r.targetType.equals('section') & r.section.equals(section.wire) & r.isDefault.equals(true)))
      .watch()
      .map(_mapAll);

  Stream<List<NotificationRule>> watchCategoryDefaults(String categoryId) =>
      watchForTarget(RuleTargetType.category, categoryId);

  Future<NotificationRule?> byId(String id) async {
    final row = await (_db.select(_db.notificationRules)..where((r) => r.id.equals(id))).getSingleOrNull();
    return row == null || row.deletedAt != null ? null : mapRow(row);
  }

  Future<String?> _lastSortKey() async {
    final row = await (_db.select(_db.notificationRules)
          ..where((r) => r.userId.equals(_userId()))
          ..orderBy([(r) => OrderingTerm.desc(r.sortKey)])
          ..limit(1))
        .getSingleOrNull();
    return row?.sortKey;
  }

  static void _validate(RuleDraft d) {
    final errors = NotificationRuleValidator.validate(d.spec, acceptExtraActions: true).where((i) => i.isError);
    if (errors.isNotEmpty) {
      throw ValidationException('Invalid notification rule: ${errors.map((e) => e.code.name).join(', ')}', field: 'spec');
    }
    final needsId = d.targetType != RuleTargetType.section && d.targetType != RuleTargetType.global;
    if (needsId != (d.targetId != null)) {
      throw const ValidationException('target_id must be set iff target_type is not section/global', field: 'targetId');
    }
  }

  /// Inserts [drafts] inside an existing transaction (host editors saving an item + its rules
  /// in one operation). Returns the new ids.
  Future<List<String>> insertInTx(WriteTx tx, List<RuleDraft> drafts, {List<String>? ids}) async {
    var sortKey = await _lastSortKey();
    final out = <String>[];
    for (var i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      _validate(d);
      final id = ids != null && i < ids.length ? ids[i] : Ids.v7();
      sortKey = FractionalIndex.between(sortKey, null);
      await tx.insert('notification_rules', id, {
        'target_type': d.targetType.wire,
        'target_id': d.targetId,
        'section': d.section.wire,
        'is_default': d.isDefault,
        'enabled': d.enabled,
        'name': d.name,
        'profile_id': d.profileId,
        'spec': d.spec.toJson(),
        'sort_key': sortKey,
      });
      await tx.logEvent(entityType: 'notification_rule', entityId: id, eventType: 'created', payload: {
        'targetType': d.targetType.wire,
        'targetId': ?d.targetId,
      });
      out.add(id);
    }
    return out;
  }

  /// Creates one or several rules as one undoable command.
  Future<OpRecord> create(List<RuleDraft> drafts) => _writer.run((tx) => insertInTx(tx, drafts));

  Future<OpRecord> update(
    String id, {
    NotificationRuleSpec? spec,
    bool? enabled,
    String? profileId,
    bool clearProfile = false,
    String? name,
    bool clearName = false,
  }) => _writer.run((tx) async {
    if (spec != null) {
      final errors = NotificationRuleValidator.validate(spec, acceptExtraActions: true).where((i) => i.isError);
      if (errors.isNotEmpty) throw const ValidationException('Invalid notification rule', field: 'spec');
    }
    final changed = await tx.update('notification_rules', id, {
      if (spec != null) 'spec': spec.toJson(),
      'enabled': ?enabled,
      if (profileId != null || clearProfile) 'profile_id': profileId,
      if (name != null || clearName) 'name': name,
    });
    if (changed) await tx.logEvent(entityType: 'notification_rule', entityId: id, eventType: 'updated');
  });

  Future<OpRecord> delete(String id) => _writer.run((tx) async {
    await tx.softDelete('notification_rules', id);
    await tx.logEvent(entityType: 'notification_rule', entityId: id, eventType: 'deleted');
  });

  /// Cascade helper for feature teams: soft-deletes every own rule of a deleted item inside
  /// their delete transaction (T7.1.02 acceptance: item delete → rules deleted).
  Future<void> softDeleteForTargetInTx(WriteTx tx, RuleTargetType type, String targetId) async {
    final rows = await (_db.select(_db.notificationRules)
          ..where((r) => r.targetType.equals(type.wire) & r.targetId.equals(targetId) & r.deletedAt.isNull()))
        .get();
    for (final r in rows) {
      await tx.softDelete('notification_rules', r.id);
    }
  }

  /// *Customize* (T7.1.15): copies the inherited rules into the item as its own and switches
  /// the item to `custom` in the same operation (via [setNotifyMode]).
  Future<OpRecord> snapshot({
    required RuleTargetType type,
    required String targetId,
    required List<EffectiveRule> inherited,
    required Future<void> Function(WriteTx tx) setNotifyMode,
  }) => _writer.run((tx) async {
    await insertInTx(tx, [
      for (final e in inherited)
        RuleDraft.fromRule(e.rule, targetType: type, targetId: targetId, isDefault: false),
    ]);
    await setNotifyMode(tx);
  });

  /// *Copy reminders from…* / bulk *Set reminders* (T7.1.15): one undoable command.
  Future<OpRecord> copyRules({
    required List<NotificationRule> from,
    required RuleTargetType type,
    required List<String> targetIds,
    bool replace = false,
  }) => _writer.run((tx) async {
    for (final targetId in targetIds) {
      if (replace) await softDeleteForTargetInTx(tx, type, targetId);
      await insertInTx(tx, [
        for (final r in from) RuleDraft.fromRule(r, targetType: type, targetId: targetId, isDefault: false),
      ]);
    }
  }, cause: 'bulk');

  /// Seeds section default rules with deterministic ids so offline devices converge (T7.1.07).
  Future<void> seedDefaults(String Function(String code) profileIdFor) async {
    final userId = _userId();
    if (userId.isEmpty) return;
    await _writer.run((tx) async {
      var sortKey = await _lastSortKey();
      for (final seed in DefaultRules.seeds) {
        final id = Ids.v5('$userId|default-rule|${seed.section.wire}|${seed.code}');
        if (await tx.exists('notification_rules', id)) continue;
        sortKey = FractionalIndex.between(sortKey, null);
        await tx.insert('notification_rules', id, {
          'target_type': 'section',
          'target_id': null,
          'section': seed.section.wire,
          'is_default': true,
          'enabled': true,
          'profile_id': profileIdFor(seed.profileCode),
          'spec': seed.spec.toJson(),
          'sort_key': sortKey,
        });
      }
    }, cause: 'auto');
  }

  /// Deterministic id of the digest rule of [kind] (one per user).
  static String digestRuleId(String userId, String kind) => DefaultRules.digestRuleId(userId, kind);

  /// Enables / updates / disables a digest rule (settings page, T7.5.18).
  Future<OpRecord> setDigest({required String kind, required bool enabled, required NotificationRuleSpec spec}) =>
      _writer.run((tx) async {
        final id = digestRuleId(_userId(), kind);
        if (await tx.exists('notification_rules', id)) {
          await tx.update('notification_rules', id, {'enabled': enabled, 'spec': spec.toJson(), 'deleted_at': null});
        } else {
          await tx.insert('notification_rules', id, {
            'target_type': 'section',
            'target_id': null,
            'section': NotificationSection.system.wire,
            'is_default': false,
            'enabled': enabled,
            'spec': spec.toJson(),
            'sort_key': FractionalIndex.between(await _lastSortKey(), null),
          });
        }
      });
}

/// `notification_profiles` (T7.1.05 / T7.1.13).
class NotificationProfilesRepository {
  NotificationProfilesRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  static NotificationProfile mapRow(NotificationProfileRow r) => NotificationProfile(
    id: r.id,
    code: r.code,
    name: r.name,
    isBuiltin: r.isBuiltin,
    spec: ProfileSpec.tryDecode(r.spec),
    sortKey: r.sortKey,
  );

  SimpleSelectStatement<$NotificationProfilesTable, NotificationProfileRow> _base() => _db.select(_db.notificationProfiles)
    ..where((p) => p.deletedAt.isNull() & p.userId.equals(_userId()))
    ..orderBy([(p) => OrderingTerm.asc(p.sortKey), (p) => OrderingTerm.asc(p.id)]);

  Stream<List<NotificationProfile>> watchAll() => _base().watch().map((rows) => rows.map(mapRow).toList());

  Future<List<NotificationProfile>> all() async => (await _base().get()).map(mapRow).toList();

  String builtinId(String code) => Ids.builtinProfile(_userId(), code);

  /// Built-in profiles with deterministic ids (idempotent, T7.1.07).
  Future<void> seedBuiltins(Map<String, String> localizedNames) async {
    final userId = _userId();
    if (userId.isEmpty) return;
    await _writer.run((tx) async {
      var sortKey = 'a0';
      for (final code in BuiltinProfiles.codes) {
        final id = Ids.builtinProfile(userId, code);
        sortKey = FractionalIndex.between(sortKey, null);
        if (await tx.exists('notification_profiles', id)) continue;
        await tx.insert('notification_profiles', id, {
          'code': code,
          'name': localizedNames[code] ?? code,
          'is_builtin': true,
          'spec': BuiltinProfiles.specs[code]!.toJson(),
          'sort_key': sortKey,
        });
      }
    }, cause: 'auto');
  }

  Future<OpRecord> create({required String name, required ProfileSpec spec}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60) {
      throw const ValidationException('Profile name must be 1–60 characters', field: 'name');
    }
    final last = (await all()).lastOrNull?.sortKey;
    return _writer.run((tx) async {
      final id = Ids.v7();
      await tx.insert('notification_profiles', id, {
        'code': null,
        'name': trimmed,
        'is_builtin': false,
        'spec': spec.toJson(),
        'sort_key': FractionalIndex.between(last, null),
      });
      await tx.logEvent(entityType: 'notification_profile', entityId: id, eventType: 'created');
    });
  }

  /// Updates a profile. Changing importance / sound / vibration bumps `channelVersion` so a new
  /// Android channel is created (channels are immutable, T7.1.13).
  Future<OpRecord> update(String id, {String? name, ProfileSpec? spec}) async {
    final current = (await all()).where((p) => p.id == id).firstOrNull;
    if (current == null) throw NotFoundException('profile $id');
    var next = spec;
    if (next != null && current.spec.channelChanged(next)) {
      next = next.copyWith(channelVersion: current.spec.channelVersion + 1);
    }
    return _writer.run((tx) => tx.update('notification_profiles', id, {
      if (name != null) 'name': name.trim(),
      if (next != null) 'spec': next.toJson(),
    }));
  }

  Future<OpRecord> duplicate(String id, String name) async {
    final source = (await all()).where((p) => p.id == id).firstOrNull;
    if (source == null) throw NotFoundException('profile $id');
    return create(name: name, spec: ProfileSpec.fromJson(source.spec.copyWith().toJson()));
  }

  /// Deletes a custom profile, moving its rules to [moveRulesTo] (null = no profile).
  Future<OpRecord> delete(String id, {String? moveRulesTo}) async {
    final profile = (await all()).where((p) => p.id == id).firstOrNull;
    if (profile == null) throw NotFoundException('profile $id');
    if (profile.isBuiltin) throw const ValidationException('Built-in profiles cannot be deleted');
    return _writer.run((tx) async {
      final rules = await (_db.select(_db.notificationRules)
            ..where((r) => r.profileId.equals(id) & r.deletedAt.isNull()))
          .get();
      for (final r in rules) {
        await tx.update('notification_rules', r.id, {'profile_id': moveRulesTo});
      }
      await tx.softDelete('notification_profiles', id);
      await tx.logEvent(entityType: 'notification_profile', entityId: id, eventType: 'deleted');
    });
  }

  Future<int> rulesUsing(String id) async {
    final count = _db.notificationRules.id.count();
    final row = await (_db.selectOnly(_db.notificationRules)
          ..addColumns([count])
          ..where(_db.notificationRules.profileId.equals(id) & _db.notificationRules.deletedAt.isNull()))
        .getSingle();
    return row.read(count) ?? 0;
  }
}

/// `notification_mutes` (T7.5.16).
class NotificationMutesRepository {
  NotificationMutesRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  static NotificationMute mapRow(NotificationMuteRow r) => NotificationMute(
    id: r.id,
    targetType: r.targetType,
    targetId: r.targetId,
    section: r.section,
    until: r.until?.toUtc(),
    reason: r.reason,
  );

  Stream<List<NotificationMute>> watchAll() => (_db.select(_db.notificationMutes)
        ..where((m) => m.deletedAt.isNull() & m.userId.equals(_userId()))
        ..orderBy([(m) => OrderingTerm.asc(m.until)]))
      .watch()
      .map((rows) => rows.map(mapRow).toList());

  Future<List<NotificationMute>> all() async => (await (_db.select(_db.notificationMutes)
            ..where((m) => m.deletedAt.isNull() & m.userId.equals(_userId())))
          .get())
      .map(mapRow)
      .toList();

  /// Mutes a rule / task / checklist / item subtree / habit / section until [until] (null =
  /// until unmuted).
  Future<OpRecord> mute({
    required String targetType,
    String? targetId,
    String? section,
    DateTime? until,
    String? reason,
  }) => _writer.run((tx) async {
    final id = Ids.v7();
    await tx.insert('notification_mutes', id, {
      'target_type': targetType,
      'target_id': targetId,
      'section': section,
      'until': until?.toUtc(),
      'reason': reason,
    });
  });

  Future<OpRecord> unmute(String id) => _writer.run((tx) => tx.softDelete('notification_mutes', id));

  /// Removes every mute of a target (e.g. *Unmute* on a badge).
  Future<OpRecord> unmuteTarget(String targetType, String? targetId, {String? section}) => _writer.run((tx) async {
    for (final m in await all()) {
      if (m.targetType == targetType && m.targetId == targetId && (section == null || m.section == section)) {
        await tx.softDelete('notification_mutes', m.id);
      }
    }
  });

  /// Cascade helper: soft-deletes the mutes of a deleted target inside the caller's transaction.
  Future<void> softDeleteForTargetInTx(WriteTx tx, String targetType, String targetId) async {
    final rows = await (_db.select(_db.notificationMutes)
          ..where((m) => m.targetType.equals(targetType) & m.targetId.equals(targetId) & m.deletedAt.isNull()))
        .get();
    for (final r in rows) {
      await tx.softDelete('notification_mutes', r.id);
    }
  }

  /// Soft-deletes expired mutes (housekeeping; they are already ignored by the planner).
  Future<void> purgeExpired(DateTime now) async {
    final expired = [for (final m in await all()) if (m.until != null && !m.until!.isAfter(now)) m.id];
    if (expired.isEmpty) return;
    await _writer.run((tx) async {
      for (final id in expired) {
        await tx.softDelete('notification_mutes', id);
      }
    }, cause: 'auto');
  }
}
