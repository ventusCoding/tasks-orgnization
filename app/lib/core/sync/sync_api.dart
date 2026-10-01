import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of one change in a push (server contract: supabase/README.md › `app.sync_push`).
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
  const PullPage({required this.changes, required this.next, required this.more, required this.purgeWatermark});

  final List<PullChange> changes;
  final int next;
  final bool more;
  final int purgeWatermark;
}

/// Result of `app.fetch_rows`: current server rows plus the ids the server doesn't have (or that
/// belong to another user) — those must be deleted locally.
class FetchRowsResult {
  const FetchRowsResult({required this.rows, this.missing = const []});

  final List<Map<String, dynamic>> rows;
  final List<String> missing;
}

/// A whole-call refusal of a sync RPC (PostgREST error with a stable `code`, supabase/README.md).
///
/// Codes the engine reacts to: `unsupported_client` (426), `device_revoked` (403),
/// `too_many_changes` (413), `invalid_request` (400), `not_authenticated`.
class SyncApiException implements Exception {
  const SyncApiException(this.code, {this.status, this.message});

  static const unsupportedClient = 'unsupported_client';
  static const deviceRevoked = 'device_revoked';
  static const tooManyChanges = 'too_many_changes';
  static const invalidRequest = 'invalid_request';
  static const notAuthenticated = 'not_authenticated';

  final String code;
  final int? status;
  final String? message;

  @override
  String toString() => 'SyncApiException($code${status == null ? '' : ', $status'}: ${message ?? ''})';
}

/// Parameters of `app.register_device` (exact RPC contract, supabase/README.md › Devices).
class DeviceRegistration {
  const DeviceRegistration({
    required this.id,
    required this.platform,
    this.model,
    this.osVersion,
    this.appVersion,
    this.appBuild,
    this.locale,
    this.timeZone,
    this.deviceName,
  });

  final String id;

  /// ios | android | web | macos | windows | linux
  final String platform;
  final String? model;
  final String? osVersion;
  final String? appVersion;
  final int? appBuild;
  final String? locale;
  final String? timeZone;
  final String? deviceName;

  Map<String, Object?> toParams() => {
    'p_id': id,
    'p_platform': platform,
    'p_model': model,
    'p_os_version': osVersion,
    'p_app_version': appVersion,
    'p_app_build': appBuild,
    'p_locale': locale,
    'p_time_zone': timeZone,
    'p_device_name': deviceName,
  };

  @override
  bool operator ==(Object other) =>
      other is DeviceRegistration &&
      other.id == id &&
      other.platform == platform &&
      other.model == model &&
      other.osVersion == osVersion &&
      other.appVersion == appVersion &&
      other.appBuild == appBuild &&
      other.locale == locale &&
      other.timeZone == timeZone &&
      other.deviceName == deviceName;

  @override
  int get hashCode => Object.hash(id, platform, model, osVersion, appVersion, appBuild, locale, timeZone, deviceName);
}

/// Keys accepted by `app.report_device_state(p_id, p_state)`; only keys present are updated
/// (`push_token: null` clears the token).
abstract final class DeviceStateKeys {
  static const lastSeenAt = 'last_seen_at';
  static const timeZone = 'time_zone';
  static const capabilities = 'capabilities';
  static const pushToken = 'push_token';
  static const pushEnabled = 'push_enabled';
  static const localNotificationsEnabled = 'local_notifications_enabled';
  static const localCoverageUntil = 'local_coverage_until';
  static const scheduleRev = 'schedule_rev';
  static const localRepeatingRules = 'local_repeating_rules';

  static const all = {
    lastSeenAt,
    timeZone,
    capabilities,
    pushToken,
    pushEnabled,
    localNotificationsEnabled,
    localCoverageUntil,
    scheduleRev,
    localRepeatingRules,
  };

  /// Drops unknown keys and serializes instants as ISO-8601 UTC.
  static Map<String, Object?> sanitize(Map<String, Object?> state) => {
    for (final e in state.entries)
      if (all.contains(e.key)) e.key: e.value is DateTime ? (e.value! as DateTime).toUtc().toIso8601String() : e.value,
  };
}

/// Server API used by the sync engine (RPCs in schema `app`, arch §7.5).
abstract interface class SyncApi {
  /// Throws [SyncApiException] for whole-call refusals.
  Future<PushResponse> push({
    required String deviceId,
    required int schema,
    required int build,
    required List<Map<String, Object?>> changes,
  });

  Future<PullPage> pull({required int since, int limit = 1000});

  /// Targeted refetch after an `integrity_refetch` rejection.
  Future<FetchRowsResult> fetchRows(String table, List<String> ids);

  /// Returns true when the device has been revoked.
  Future<bool> registerDevice(DeviceRegistration device);

  /// Returns true when the device has been revoked. [state] keys: [DeviceStateKeys].
  Future<bool> reportDeviceState(String deviceId, Map<String, Object?> state);
}

/// [SyncApi] over Supabase RPCs.
class SupabaseSyncApi implements SyncApi {
  SupabaseSyncApi(this.client);

  final SupabaseClient client;

  SupabaseQuerySchema get _app => client.schema('app');

  Future<T> _call<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PostgrestException catch (e) {
      throw mapPostgrestError(e);
    }
  }

  /// HTTP status of each stable API error code (`app.raise_api_error`).
  static const _statusByCode = {
    SyncApiException.unsupportedClient: 426,
    SyncApiException.deviceRevoked: 403,
    SyncApiException.tooManyChanges: 413,
    SyncApiException.invalidRequest: 400,
    SyncApiException.notAuthenticated: 401,
    'unknown_table': 400,
    'device_not_found': 404,
    'device_not_registered': 404,
  };

  /// Maps a PostgREST error body (`{"code", "message", "details", "hint"}`) to a
  /// [SyncApiException] when it carries one of the API's stable codes; other errors (network,
  /// transient database errors) are returned unchanged so the engine retries them.
  static Exception mapPostgrestError(PostgrestException e) {
    final code = e.code;
    if (code != null && _statusByCode.containsKey(code)) {
      return SyncApiException(code, status: _statusByCode[code], message: e.message);
    }
    if (code == '28000' || code == 'PGRST301' || code == 'PGRST303') {
      return SyncApiException(SyncApiException.notAuthenticated, status: 401, message: e.message);
    }
    return e;
  }

  @override
  Future<PushResponse> push({
    required String deviceId,
    required int schema,
    required int build,
    required List<Map<String, Object?>> changes,
  }) => _call(() async {
    final res = await _app.rpc<Map<String, dynamic>>(
      'sync_push',
      params: {'p_device_id': deviceId, 'p_schema': schema, 'p_build': build, 'p_changes': changes},
    );
    return PushResponse([
      for (final r in (res['results'] as List? ?? const [])) PushResult.fromJson(Map<String, dynamic>.from(r as Map)),
    ], (res['head'] as num?)?.toInt() ?? 0);
  });

  @override
  Future<PullPage> pull({required int since, int limit = 1000}) => _call(() async {
    final res = await _app.rpc<Map<String, dynamic>>('sync_pull', params: {'p_since': since, 'p_limit': limit});
    return parsePullPage(res, since);
  });

  static PullPage parsePullPage(Map<String, dynamic> res, int since) => PullPage(
    changes: [
      for (final c in (res['changes'] as List? ?? const []))
        PullChange((c as Map)['t'] as String, Map<String, dynamic>.from(c['r'] as Map)),
    ],
    next: (res['next'] as num?)?.toInt() ?? since,
    more: res['more'] as bool? ?? false,
    purgeWatermark: (res['purge_watermark'] as num?)?.toInt() ?? 0,
  );

  @override
  Future<FetchRowsResult> fetchRows(String table, List<String> ids) => _call(() async {
    final res = await _app.rpc<dynamic>('fetch_rows', params: {'p_table': table, 'p_ids': ids});
    return parseFetchRows(res);
  });

  /// Parses `{"t": "<table>", "rows": [...], "missing": [...]}` (a bare list is accepted too).
  static FetchRowsResult parseFetchRows(Object? res) {
    final rows = res is List
        ? res
        : (res is Map ? (res['rows'] as List<Object?>? ?? const <Object?>[]) : const <Object?>[]);
    final missing = res is Map ? (res['missing'] as List<Object?>? ?? const <Object?>[]) : const <Object?>[];
    return FetchRowsResult(
      rows: [for (final r in rows) Map<String, dynamic>.from(r! as Map)],
      missing: [for (final m in missing) m.toString()],
    );
  }

  @override
  Future<bool> registerDevice(DeviceRegistration device) => _call(() async {
    final res = await _app.rpc<dynamic>('register_device', params: device.toParams());
    return res is Map && res['revoked'] == true;
  });

  @override
  Future<bool> reportDeviceState(String deviceId, Map<String, Object?> state) => _call(() async {
    final res = await _app.rpc<dynamic>(
      'report_device_state',
      params: {'p_id': deviceId, 'p_state': DeviceStateKeys.sanitize(state)},
    );
    return res is Map && res['revoked'] == true;
  });
}
