import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/features/attachments/application/providers.dart' show startAttachmentUploads;
import 'package:everslot/features/checklists/application/reset_service.dart' show runChecklistResets;
import 'package:everslot/startup/profile_bootstrap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hooks run once at startup (after providers exist, before the first frame).
///
/// Features register idempotent tasks here (e.g. seed defaults, schedule notifications,
/// run due checklist resets). Every task must be fast (< 200 ms) or run unawaited.
typedef StartupTask = Future<void> Function(ProviderContainer container);

final List<StartupTask> startupTasks = [
  ensureProfileAndDefaults,
  startAttachmentUploads, // resumes queued attachment uploads (T2.2.04)
  runChecklistResets, // due checklist resets at start, on resume and after pulls (T4.5.06)
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
