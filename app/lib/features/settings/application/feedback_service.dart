import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/device_registrar.dart';
import 'package:everslot/features/settings/domain/feedback_diagnostics.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

/// Device facts for diagnostics (overridden in tests).
final feedbackDeviceInfoProvider = Provider<DeviceInfoLoader>(
  (ref) => platformDeviceInfoLoader(
    deviceId: ref.watch(activeDeviceIdProvider),
    timeZone: () => '',
    locale: () => PlatformDispatcher.instance.locale.toLanguageTag(),
    build: ref.watch(appBuildProvider),
  ),
);

/// Diagnostics attached to feedback (T8.3.17), built on demand.
final feedbackDiagnosticsProvider = FutureProvider.autoDispose<FeedbackDiagnostics>((ref) async {
  final info = await ref.read(feedbackDeviceInfoProvider)();
  final sync = ref.read(syncStatusProvider);
  final cloud = ref.read(syncServiceProvider) != null;
  final env = ref.read(envProvider);
  final codes = <String>[];
  for (final r in AppLog.recent.reversed) {
    if (r.level < Level.SEVERE && r.error == null) continue;
    final code = FeedbackDiagnostics.errorCode(r.loggerName, r.error);
    if (code != null && !codes.contains(code)) codes.add(code);
    if (codes.length == 10) break;
  }
  return FeedbackDiagnostics(
    appVersion: '${FeedbackDiagnostics.token(info.appVersion) ?? '?'}+${info.appBuild}',
    platform: info.platform,
    deviceId: info.id,
    osVersion: FeedbackDiagnostics.token(info.osVersion),
    model: FeedbackDiagnostics.token(info.model),
    locale: FeedbackDiagnostics.token(info.locale),
    flavor: env.flavor.name,
    cloudSync: cloud,
    syncPhase: sync.phase.name,
    pendingChanges: sync.pendingChanges,
    failedChanges: sync.failedChanges,
    lastSyncAt: sync.lastSuccessAt,
    syncErrorCode: FeedbackDiagnostics.token(sync.errorCode),
    errorCodes: codes.reversed.toList(),
  );
});
