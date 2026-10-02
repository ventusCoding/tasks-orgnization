import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/core/sync/background_sync.dart' show scheduleBackgroundSync;
import 'package:everslot/features/attachments/application/providers.dart' show startAttachmentUploads;
import 'package:everslot/features/checklists/application/reset_service.dart' show runChecklistResets;
import 'package:everslot/features/habits/habits_startup.dart';
import 'package:everslot/features/integrations/integrations_startup.dart';
import 'package:everslot/features/notifications/notifications_startup.dart';
import 'package:everslot/features/profile/application/zone_tracker.dart';
import 'package:everslot/features/widgets_home/widgets_startup.dart';
import 'package:everslot/startup/profile_bootstrap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hooks run once at startup (after providers exist, before the first frame).
///
/// Features register idempotent tasks here (e.g. seed defaults, schedule notifications,
/// run due checklist resets). Every task must be fast (< 200 ms) or run unawaited.
typedef StartupTask = Future<void> Function(ProviderContainer container);

final List<StartupTask> startupTasks = [
  ensureProfileAndDefaults,
  startNotifications,
  startZoneTracking,
  startAttachmentUploads, // resumes queued attachment uploads (T2.2.04)
  runChecklistResets, // due checklist resets at start, on resume and after pulls (T4.5.06)
  startIntegrations, // external links, widgets, shortcuts, share intake, timers, health (8.2)
  startHomeWidgets, // home / lock-screen widget snapshot + interactive actions (T8.2.02)
  startHabits, // default habit sections & trigger/place/coping libraries (T5.1.11, T5.3.14)
  scheduleBackgroundSync, // periodic background push/pull for cloud sessions (T1.4.17)
];

Future<void> runStartupTasks(ProviderContainer container) async {
  final log = AppLog.get('startup');
  final session = container.read(sessionProvider);
  if (session == null) return;
  for (final task in startupTasks) {
    try {
      await task(container);
    } on Object catch (e, st) {
      log.warning('startup task failed', e, st);
    }
  }
  // Keep session-dependent singletons alive.
  if (session.mode == SessionMode.cloud) {
    unawaited(Future<void>.microtask(() => container.read(syncServiceProvider)));
  }
}
