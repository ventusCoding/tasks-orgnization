import 'dart:async';

import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/profile/data/profile_repository.dart';
import 'package:everslot/features/profile/domain/zone_change.dart';
import 'package:everslot/features/settings/application/settings_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the device time zone (T1.5.06): compares it with the last zone this device saw
/// (kept locally, so two devices in different zones don't flip-flop), emits [TimeZoneChanged],
/// records `profiles.current_time_zone` (throttled) and offers to make the new zone "home".
class ZoneTracker {
  ZoneTracker({
    required ProfileRepository profiles,
    required AppDatabase db,
    required Clock clock,
    this.throttle = const Duration(minutes: 10),
    bool Function()? autoHome,
  }) : _profiles = profiles,
       _db = db,
       _clock = clock,
       _autoHome = autoHome ?? _never;

  final ProfileRepository _profiles;
  final AppDatabase _db;
  final Clock _clock;
  final Duration throttle;

  /// Settings › Regional › "Follow this device": new zones become home without asking.
  final bool Function() _autoHome;

  static bool _never() => false;

  static const lastZoneKey = 'last_device_zone';
  static const promptAnsweredKey = 'zone_prompt_answered';
  static final _log = AppLog.get('zone');

  final _changes = StreamController<TimeZoneChanged>.broadcast();

  /// Zone the user may want as home (null = nothing to ask).
  final ValueNotifier<String?> prompt = ValueNotifier(null);

  DateTime? _lastWriteAt;
  String? _pendingWrite;
  Timer? _timer;
  Future<void> _queue = Future.value();

  Stream<TimeZoneChanged> get changes => _changes.stream;

  /// Serialized so rapid zone flips are processed in order.
  Future<void> observe(String zone) {
    final next = _queue.then((_) => _observe(zone)).catchError((Object e, StackTrace st) {
      _log.warning('zone tracking failed', e, st);
    });
    return _queue = next;
  }

  Future<void> _observe(String zone) async {
    if (zone.isEmpty) return;
    final last = await _readKv(lastZoneKey);
    final profile = await _profiles.read();
    if (last == zone) {
      if (profile != null && profile.currentTimeZone != zone) await _record(zone);
      return;
    }
    await _writeKv(lastZoneKey, zone);
    if (last != null) {
      _changes.add(TimeZoneChanged(from: last, to: zone, at: _clock.nowUtc()));
      if (profile != null && profile.homeTimeZone != zone && _autoHome()) {
        prompt.value = null;
        await _profiles.update(homeTimeZone: zone, cause: 'auto');
      } else {
        final answered = await _readKv(promptAnsweredKey);
        if (profile != null && profile.homeTimeZone != zone && answered != zone) prompt.value = zone;
        if (profile != null && profile.homeTimeZone == zone) prompt.value = null;
      }
    }
    if (profile != null) await _record(zone);
  }

  /// Writes `current_time_zone` at most once per [throttle]; the latest zone wins.
  Future<void> _record(String zone) async {
    final now = _clock.nowUtc();
    final last = _lastWriteAt;
    if (last != null && now.difference(last) < throttle && !now.isBefore(last)) {
      _pendingWrite = zone;
      _timer ??= Timer(throttle - now.difference(last), () => unawaited(flush()));
      return;
    }
    _pendingWrite = null;
    _lastWriteAt = now;
    await _profiles.update(currentTimeZone: zone, cause: 'auto');
  }

  /// Writes a throttled zone now (timer, tests).
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final zone = _pendingWrite;
    if (zone == null) return;
    _pendingWrite = null;
    _lastWriteAt = _clock.nowUtc();
    await _profiles.update(currentTimeZone: zone, cause: 'auto');
  }

  /// "Keep home" (don't ask again for this zone) or "make it home".
  Future<void> answerPrompt({required bool makeHome}) async {
    final zone = prompt.value;
    if (zone == null) return;
    prompt.value = null;
    await _writeKv(promptAnsweredKey, zone);
    if (makeHome) await _profiles.update(homeTimeZone: zone);
  }

  Future<String?> _readKv(String key) async {
    final row = await _db
        .customSelect('SELECT value FROM local_kv WHERE key = ?', variables: [Variable<String>(key)])
        .getSingleOrNull();
    return row?.data['value'] as String?;
  }

  Future<void> _writeKv(String key, String value) => _db.customStatement(
    'INSERT INTO local_kv(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    [key, value],
  );

  void dispose() {
    _timer?.cancel();
    unawaited(_changes.close());
    prompt.dispose();
  }
}

/// The zone tracker of the current session; starts observing the device zone immediately.
final zoneTrackerProvider = Provider<ZoneTracker>((ref) {
  final tracker = ZoneTracker(
    profiles: ref.watch(profileRepositoryProvider),
    db: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    autoHome: () => ref.read(regionalSettingsProvider).homeZoneAuto,
  );
  ref
    ..listen<String>(deviceZoneProvider, (_, zone) => unawaited(tracker.observe(zone)), fireImmediately: true)
    ..listen<String>(currentUserIdProvider, (previous, next) {
      if (next.isNotEmpty && next != previous) unawaited(tracker.observe(ref.read(deviceZoneProvider)));
    })
    ..onDispose(tracker.dispose);
  return tracker;
});

/// Zone changes (T1.5.06) for Today, planner views and notification re-planning.
final zoneChangesProvider = StreamProvider<TimeZoneChanged>((ref) => ref.watch(zoneTrackerProvider).changes);

/// Pending "make this zone home?" question (null when nothing to ask).
final zonePromptProvider = Provider<String?>((ref) {
  final tracker = ref.watch(zoneTrackerProvider);
  void listener() => ref.invalidateSelf();
  tracker.prompt.addListener(listener);
  ref.onDispose(() {
    try {
      tracker.prompt.removeListener(listener);
    } on Object {
      // The tracker was disposed first (container teardown).
    }
  });
  return tracker.prompt.value;
});

/// Startup task (registered in `startup/startup_tasks.dart`): keeps the tracker alive.
Future<void> startZoneTracking(ProviderContainer container) async {
  container.read(zoneTrackerProvider);
}
