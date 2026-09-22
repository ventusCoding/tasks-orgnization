import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Per-install device id (T1.4.05): UUIDv7 kept in secure storage (falls back to the local DB).
abstract final class DeviceIdentity {
  static const _key = 'everslot_device_id';

  static Future<String> load(AppDatabase db, {FlutterSecureStorage? storage}) async {
    final secure = storage ?? const FlutterSecureStorage();
    try {
      final existing = await secure.read(key: _key);
      if (existing != null && existing.isNotEmpty) return existing;
    } on Object {
      // Secure storage unavailable (tests, some emulators) → local DB fallback below.
    }
    final kv = await (db.select(db.localKv)..where((k) => k.key.equals(_key))).getSingleOrNull();
    final id = kv?.value ?? Ids.v7();
    await db.into(db.localKv).insertOnConflictUpdate(LocalKvRow(key: _key, value: id));
    try {
      await secure.write(key: _key, value: id);
    } on Object {
      // ignore
    }
    return id;
  }
}
