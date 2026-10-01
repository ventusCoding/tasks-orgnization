import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show Variable;
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/notifications/application/channel_catalog.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/planner/planned_notification.dart';
import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of `app.replace_notification_jobs` (supabase/README.md).
@immutable
class JobUploadResult {
  const JobUploadResult({
    required this.status,
    this.staleTargets = const [],
    this.errorCode,
    this.replaced = 0,
    this.upserted = 0,
  });

  /// ok | stale | error
  final String status;
  final List<String> staleTargets;
  final String? errorCode;
  final int replaced;
  final int upserted;

  bool get ok => status == 'ok';
  bool get stale => status == 'stale';
}

/// Server RPC used to upload planned jobs (T7.4.04).
abstract interface class NotificationJobsApi {
  Future<JobUploadResult> replaceJobs({
    required String deviceId,
    required int sourceRev,
    required List<String> targetKeys,
    required List<Map<String, Object?>> jobs,
  });
}

class SupabaseNotificationJobsApi implements NotificationJobsApi {
  SupabaseNotificationJobsApi(this.client);

  final SupabaseClient client;

  @override
  Future<JobUploadResult> replaceJobs({
    required String deviceId,
    required int sourceRev,
    required List<String> targetKeys,
    required List<Map<String, Object?>> jobs,
  }) async {
    try {
      final res = await client
          .schema('app')
          .rpc<dynamic>(
            'replace_notification_jobs',
            params: {'p_device_id': deviceId, 'p_source_rev': sourceRev, 'p_target_keys': targetKeys, 'p_jobs': jobs},
          );
      final map = res is Map ? Map<String, Object?>.from(res) : const <String, Object?>{};
      return JobUploadResult(
        status: map['status'] as String? ?? 'ok',
        staleTargets: [for (final t in (map['stale_targets'] as List?) ?? const <Object?>[]) t.toString()],
        replaced: (map['replaced'] as num?)?.toInt() ?? 0,
        upserted: (map['upserted'] as num?)?.toInt() ?? 0,
      );
    } on PostgrestException catch (e) {
      return JobUploadResult(status: 'error', errorCode: e.code ?? e.message);
    }
  }
}

/// Uploads the device's plan as server jobs after each successful sync push (T7.4.04):
/// persistent dirty-target set (survives restarts), ≤ 200 targets per call, `stale` → pull →
/// replan → re-upload, retries with backoff. Content is already rendered, localized and redacted.
class JobUploader {
  JobUploader({required this.db, required this.clock, required this.deviceId, this.onStale});

  static final _log = AppLog.get('notifications.jobs');
  static const kvKey = 'notif_jobs_dirty';
  static const maxTargetsPerCall = 200;
  static const maxPayloadBytes = 3400;
  static const horizon = Duration(days: 14);

  final AppDatabase db;
  final Clock clock;
  final String deviceId;
  final void Function()? onStale;
  int _failures = 0;
  DateTime? _retryAfter;
  DateTime? lastUploadAt;
  JobUploadResult? lastResult;

  Future<Set<String>> dirty() async {
    final row = await (db.select(db.localKv)..where((k) => k.key.equals(kvKey))).getSingleOrNull();
    if (row == null) return {};
    try {
      return {for (final k in jsonDecode(row.value) as List) k.toString()};
    } on Object {
      return {};
    }
  }

  Future<void> _saveDirty(Set<String> keys) => db.customStatement(
    'INSERT INTO local_kv(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    [kvKey, jsonEncode(keys.toList()..sort())],
  );

  /// Marks targets whose jobs must be (re)uploaded; `'*'` = everything.
  Future<void> markDirty(Iterable<String> targetKeys) async {
    final keys = {...await dirty(), ...targetKeys};
    await _saveDirty(keys.contains('*') ? {'*'} : keys);
  }

  /// Server job for a planned instance (supabase/README.md "Job payload").
  static Map<String, Object?> jobFor(PlannedNotification p) {
    Map<String, Object?> payload(String? body) => {
      'type': p.category.wire,
      'title': p.title,
      'body': ?body,
      'section': p.section.wire,
      'sourceType': p.targetType.wire,
      'sourceId': p.targetId,
      'deepLink': AppLinks.external(p.deepLink).toString(),
      'actions': p.actions.take(3).toList(),
      'channel': p.channelId,
      'group': p.threadId,
      'iosCategory': ChannelCatalog.categoryIdFor(p.actions, nag: p.isNag),
      'sound': p.sound,
      'interruptionLevel': switch (p.interruptionLevel) {
        InterruptionLevel.passive => 'passive',
        InterruptionLevel.active => 'active',
        InterruptionLevel.timeSensitive => 'time-sensitive',
      },
      'relevance': p.relevance,
      'system': p.deliverSystem,
      'inbox': p.deliverInbox,
      'latenessMinutes': p.expiresAt.difference(p.fireAt).inMinutes,
      'data': p.payload,
    };
    var body = p.body;
    var map = payload(body);
    // Payload budget (≤ 3.5 KB): shorten the body first.
    while (body != null && utf8.encode(jsonEncode(map)).length > maxPayloadBytes && body.isNotEmpty) {
      body = body.length <= 10 ? null : '${body.substring(0, body.length * 3 ~/ 4)}…';
      map = payload(body);
    }
    return {
      'dedupe_key': p.dedupeKey,
      'target_key': p.targetKey,
      'fire_at': p.fireAt.toUtc().toIso8601String(),
      'expires_at': p.expiresAt.toUtc().toIso8601String(),
      'payload': map,
      'guard': p.guard.toServerJson(),
      'rule_id': p.ruleId,
      'occurrence_key': p.occurrenceKey.isEmpty ? null : p.occurrenceKey,
      'target_devices': p.targetDevices,
      'importance': p.importance.wire,
    };
  }

  /// Sync cursor the plan was computed from (`schedule_rev` / `source_rev`).
  Future<int> sourceRev(String userId) async {
    final row = await db
        .customSelect('SELECT cursor FROM sync_state WHERE user_id = ?', variables: [Variable<String>(userId)])
        .getSingleOrNull();
    return (row?.data['cursor'] as int?) ?? 0;
  }

  /// Uploads dirty targets of [plan]. Returns false when nothing could be uploaded now.
  Future<bool> upload(NotificationJobsApi api, PlanResult plan, {required int sourceRev}) async {
    final now = clock.nowUtc();
    if (_retryAfter != null && now.isBefore(_retryAfter!)) return false;
    final dirtyKeys = await dirty();
    if (dirtyKeys.isEmpty) return true;
    final wildcard = dirtyKeys.contains('*');
    final jobsByTarget = <String, List<Map<String, Object?>>>{};
    for (final p in plan.planned) {
      if (!(p.deliverSystem || p.deliverInbox) || !p.fireAt.isAfter(now)) {
        continue;
      }
      if (p.fireAt.isAfter(now.add(horizon))) continue;
      if (!wildcard && !dirtyKeys.contains(p.targetKey)) continue;
      (jobsByTarget[p.targetKey] ??= []).add(jobFor(p));
    }
    final batches = <(List<String>, List<Map<String, Object?>>)>[];
    if (wildcard) {
      batches.add((['*'], [for (final jobs in jobsByTarget.values) ...jobs]));
    } else {
      final keys = dirtyKeys.toList()..sort();
      for (var i = 0; i < keys.length; i += maxTargetsPerCall) {
        final chunk = keys.sublist(i, min(i + maxTargetsPerCall, keys.length));
        batches.add((chunk, [for (final k in chunk) ...?jobsByTarget[k]]));
      }
    }
    final remaining = {...dirtyKeys};
    for (final (targets, jobs) in batches) {
      final result = await api.replaceJobs(deviceId: deviceId, sourceRev: sourceRev, targetKeys: targets, jobs: jobs);
      lastResult = result;
      if (result.ok) {
        remaining.removeAll(targets);
        _failures = 0;
        _retryAfter = null;
        lastUploadAt = now;
      } else if (result.stale) {
        _log.info('stale plan for ${result.staleTargets.length} targets → pull & replan');
        onStale?.call();
        break;
      } else {
        _failures++;
        final backoff = Duration(seconds: min(900, pow(2, _failures).toInt() * 15));
        _retryAfter = now.add(backoff);
        _log.warning('job upload failed (${result.errorCode}), retry in ${backoff.inSeconds}s');
        break;
      }
    }
    await _saveDirty(remaining);
    return remaining.isEmpty;
  }
}
