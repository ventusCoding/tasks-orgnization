import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/features/settings/domain/device_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Devices of the account (T8.3.04): `app.devices` (RLS: own rows, select only) and
/// `app.revoke_device` (supabase/README.md › Devices).
abstract interface class DevicesRepository {
  Future<List<DeviceInfo>> list();

  /// Revokes [id]: push stops at once, the device is signed out on its next contact.
  Future<void> revoke(String id);
}

class SupabaseDevicesRepository implements DevicesRepository {
  SupabaseDevicesRepository(this._client);

  final SupabaseClient _client;

  static const columns =
      'id, platform, device_name, model, os_version, app_version, last_seen_at, push_enabled, push_token, revoked_at';

  @override
  Future<List<DeviceInfo>> list() async {
    try {
      final rows = await _client.schema('app').from('devices').select(columns).order('last_seen_at', ascending: false);
      return [for (final r in rows) DeviceInfo.fromJson(Map<String, dynamic>.from(r))];
    } on PostgrestException catch (e) {
      throw SupabaseSyncApi.mapPostgrestError(e);
    }
  }

  @override
  Future<void> revoke(String id) async {
    try {
      await _client.schema('app').rpc<dynamic>('revoke_device', params: {'p_id': id});
    } on PostgrestException catch (e) {
      throw SupabaseSyncApi.mapPostgrestError(e);
    }
  }
}
