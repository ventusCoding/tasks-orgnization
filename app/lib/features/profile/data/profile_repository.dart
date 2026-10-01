import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/profile/domain/profile.dart';
import 'package:timezone/timezone.dart' as tz;

const Object _unset = Object();

/// Profile of the current user (T1.5.04): reads the Drift mirror, writes through [SyncWriter]
/// (per-field patches, so edits on two devices merge field by field).
class ProfileRepository {
  ProfileRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  Stream<Profile?> watch() {
    final id = _userId();
    return (_db.select(_db.profiles)..where((p) => p.id.equals(id))).watchSingleOrNull().map(_map);
  }

  Future<Profile?> read() async {
    final id = _userId();
    return _map(await (_db.select(_db.profiles)..where((p) => p.id.equals(id))).getSingleOrNull());
  }

  static Profile? _map(ProfileRow? r) => r == null
      ? null
      : Profile(
          id: r.id,
          displayName: r.displayName,
          avatarPath: r.avatarPath,
          homeTimeZone: r.homeTimeZone,
          currentTimeZone: r.currentTimeZone,
          locale: r.locale,
          weekStart: r.weekStart,
          timeFormat: TimeFormat.fromJson(r.timeFormat),
          onboardingCompletedAt: r.onboardingCompletedAt?.toUtc(),
        );

  /// Patches the profile; only the given fields are written (and pushed). Creates the row when it
  /// doesn't exist yet (local-only first run). [cause] `auto` marks automatic bookkeeping (zone
  /// tracking) in activity/diagnostics; [scheduledAt] stamps automatic writes (arch §6.6).
  Future<OpRecord> update({
    Object? displayName = _unset,
    Object? avatarPath = _unset,
    String? homeTimeZone,
    Object? currentTimeZone = _unset,
    Object? locale = _unset,
    int? weekStart,
    TimeFormat? timeFormat,
    Object? onboardingCompletedAt = _unset,
    String cause = 'user',
    DateTime? scheduledAt,
  }) {
    final changes = <String, Object?>{};
    if (displayName != _unset) changes['display_name'] = ProfileRules.normalizeDisplayName(displayName as String?);
    if (avatarPath != _unset) changes['avatar_path'] = avatarPath as String?;
    if (homeTimeZone != null) changes['home_time_zone'] = _zone(homeTimeZone, 'homeTimeZone');
    if (currentTimeZone != _unset) {
      final zone = currentTimeZone as String?;
      changes['current_time_zone'] = zone == null ? null : _zone(zone, 'currentTimeZone');
    }
    if (locale != _unset) {
      final code = locale as String?;
      if (!ProfileRules.isValidLocale(code)) throw ValidationException('unsupported locale $code', field: 'locale');
      changes['locale'] = code;
    }
    if (weekStart != null) {
      if (!ProfileRules.isValidWeekStart(weekStart)) {
        throw const ValidationException('week start must be 1..7', field: 'weekStart');
      }
      changes['week_start'] = weekStart;
    }
    if (timeFormat != null) changes['time_format'] = timeFormat.name;
    if (onboardingCompletedAt != _unset) {
      changes['onboarding_completed_at'] = (onboardingCompletedAt as DateTime?)?.toUtc();
    }
    final id = _userId();
    if (id.isEmpty) throw const AuthException('no user');
    return _writer.run(
      (tx) async {
        if (await tx.exists('profiles', id)) {
          await tx.update('profiles', id, changes);
        } else {
          await tx.insert('profiles', id, {'home_time_zone': 'UTC', 'week_start': 1, 'time_format': 'h24', ...changes});
        }
      },
      cause: cause,
      scheduledAt: scheduledAt,
    );
  }

  static String _zone(String zone, String field) {
    try {
      tz.getLocation(zone);
      return zone;
    } on Object {
      if (zone == 'UTC') return zone;
      throw ValidationException('unknown time zone $zone', field: field);
    }
  }
}
