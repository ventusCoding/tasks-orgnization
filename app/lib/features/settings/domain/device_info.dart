/// A device registered on the account (`app.devices`, not synced — read from the server).
class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.platform,
    this.name,
    this.model,
    this.osVersion,
    this.appVersion,
    this.lastSeenAt,
    this.pushEnabled = false,
    this.hasPushToken = false,
    this.revokedAt,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> j) => DeviceInfo(
    id: j['id'] as String,
    platform: j['platform'] as String? ?? 'android',
    name: j['device_name'] as String?,
    model: j['model'] as String?,
    osVersion: j['os_version'] as String?,
    appVersion: j['app_version'] as String?,
    lastSeenAt: _instant(j['last_seen_at']),
    pushEnabled: j['push_enabled'] == true,
    // The token itself is never kept on the client — only whether one is registered.
    hasPushToken: j['push_token'] is String && (j['push_token'] as String).isNotEmpty,
    revokedAt: _instant(j['revoked_at']),
  );

  static DateTime? _instant(Object? v) => v is String ? DateTime.tryParse(v)?.toUtc() : null;

  final String id;

  /// ios | android | web | macos | windows | linux
  final String platform;
  final String? name;
  final String? model;
  final String? osVersion;
  final String? appVersion;
  final DateTime? lastSeenAt;
  final bool pushEnabled;
  final bool hasPushToken;
  final DateTime? revokedAt;

  bool get isRevoked => revokedAt != null;

  /// Push notifications effectively reach this device.
  bool get receivesPush => pushEnabled && hasPushToken && !isRevoked;

  /// Best human label: the device name, else the model.
  String? get label => (name?.trim().isNotEmpty ?? false) ? name!.trim() : model;

  @override
  bool operator ==(Object other) =>
      other is DeviceInfo &&
      other.id == id &&
      other.platform == platform &&
      other.name == name &&
      other.model == model &&
      other.osVersion == osVersion &&
      other.appVersion == appVersion &&
      other.lastSeenAt == lastSeenAt &&
      other.pushEnabled == pushEnabled &&
      other.hasPushToken == hasPushToken &&
      other.revokedAt == revokedAt;

  @override
  int get hashCode =>
      Object.hash(id, platform, name, model, osVersion, appVersion, lastSeenAt, pushEnabled, hasPushToken, revokedAt);
}

/// Visible devices: not revoked, this device first, then most recently seen.
List<DeviceInfo> visibleDevices(List<DeviceInfo> all, String thisDeviceId) {
  final list =
      [
        for (final d in all)
          if (!d.isRevoked) d,
      ]..sort((a, b) {
        if (a.id == thisDeviceId) return -1;
        if (b.id == thisDeviceId) return 1;
        final at = a.lastSeenAt;
        final bt = b.lastSeenAt;
        if (at == null && bt == null) return a.id.compareTo(b.id);
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
  return list;
}
