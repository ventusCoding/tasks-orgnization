import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of one change in a push (server contract: supabase/README.md).
class PushResult {
  const PushResult({
    required this.changeId,
    required this.status,
    this.staleFields = const [],
    this.code,
    this.message,
  });

  factory PushResult.fromJson(Map<String, dynamic> json) => PushResult(
    changeId: json['id'] as String,
    status: json['status'] as String,
    staleFields: [for (final f in (json['stale_fields'] as List?) ?? const []) f as String],
    code: json['code'] as String?,
    message: json['message'] as String?,
  );

  final String changeId;

  /// applied | partial | stale | rejected
  final String status;
  final List<String> staleFields;
  final String? code;
  final String? message;
}

class PushResponse {
  const PushResponse(this.results, this.head);

  final List<PushResult> results;
  final int head;
}

class PullChange {
  const PullChange(this.table, this.row);

  final String table;
  final Map<String, dynamic> row;
}

class PullPage {
  const PullPage({
    required this.changes,
    required this.next,
    required this.more,
    required this.purgeWatermark,
  });

  final List<PullChange> changes;
  final int next;
  final bool more;
  final int purgeWatermark;
}

/// Server API used by the sync engine (RPCs in schema `app`, arch §7.5).
abstract interface class SyncApi {
  Future<PushResponse> push({
    required String deviceId,
    required int schema,
    required int build,
    required List<Map<String, Object?>> changes,
  });

  Future<PullPage> pull({required int since, int limit = 1000});

  Future<List<Map<String, dynamic>>> fetchRows(String table, List<String> ids);

  /// Returns true when the device has been revoked.
  Future<bool> registerDevice(Map<String, Object?> info);

  /// Returns true when the device has been revoked.
  Future<bool> reportDeviceState(String deviceId, Map<String, Object?> state);
}

/// [SyncApi] over Supabase RPCs.
class SupabaseSyncApi implements SyncApi {
  SupabaseSyncApi(this.client);

  final SupabaseClient client;

  SupabaseQuerySchema get _app => client.schema('app');

  @override
  Future<PushResponse> push({
    required String deviceId,
    required int schema,
    required int build,
    required List<Map<String, Object?>> changes,
  }) async {
    final res = await _app.rpc<Map<String, dynamic>>(
      'sync_push',
      params: {'p_device_id': deviceId, 'p_schema': schema, 'p_build': build, 'p_changes': changes},
    );
    return PushResponse(
      [
        for (final r in (res['results'] as List? ?? const []))
          PushResult.fromJson(Map<String, dynamic>.from(r as Map)),
      ],
      (res['head'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<PullPage> pull({required int since, int limit = 1000}) async {
    final res = await _app.rpc<Map<String, dynamic>>(
      'sync_pull',
      params: {'p_since': since, 'p_limit': limit},
    );
    return PullPage(
      changes: [
        for (final c in (res['changes'] as List? ?? const []))
          PullChange(
            (c as Map)['t'] as String,
            Map<String, dynamic>.from(c['r'] as Map),
          ),
      ],
      next: (res['next'] as num?)?.toInt() ?? since,
      more: res['more'] as bool? ?? false,
      purgeWatermark: (res['purge_watermark'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRows(String table, List<String> ids) async {
    final res = await _app.rpc<dynamic>('fetch_rows', params: {'p_table': table, 'p_ids': ids});
    final list = res is List ? res : (res is Map ? (res['rows'] as List? ?? const []) : const []);
    return [for (final r in list) Map<String, dynamic>.from(r as Map)];
  }

  @override
  Future<bool> registerDevice(Map<String, Object?> info) async {
    final res = await _app.rpc<dynamic>('register_device', params: {
      for (final e in info.entries) 'p_${e.key}': e.value,
    });
    return res is Map && res['revoked'] == true;
  }

  @override
  Future<bool> reportDeviceState(String deviceId, Map<String, Object?> state) async {
    final res = await _app.rpc<dynamic>(
      'report_device_state',
      params: {'p_id': deviceId, 'p_state': state},
    );
    return res is Map && res['revoked'] == true;
  }
}
