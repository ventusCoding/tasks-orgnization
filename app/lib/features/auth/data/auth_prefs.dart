import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';

/// Device-local auth UI preferences (`local_kv`, never synced).
class AuthPrefs {
  AuthPrefs(this._db);

  final AppDatabase _db;

  static const guestBannerDismissedKey = 'auth_guest_banner_dismissed_at';

  /// When the guest-account banner was last dismissed on this device (UTC), or null.
  Future<DateTime?> guestBannerDismissedAt() async {
    final row = await _db
        .customSelect(
          'SELECT value FROM local_kv WHERE key = ?',
          variables: [const Variable<String>(guestBannerDismissedKey)],
        )
        .getSingleOrNull();
    final raw = row?.data['value'] as String?;
    return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> dismissGuestBanner(DateTime at) => _db.customStatement(
    'INSERT INTO local_kv(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    [guestBannerDismissedKey, at.toUtc().toIso8601String()],
  );
}
