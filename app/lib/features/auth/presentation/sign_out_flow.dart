import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/application/sign_out_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

enum _PendingChoice { export, signOut }

/// Runs [task] behind a non-dismissible progress dialog.
Future<T> withBlockingProgress<T>(BuildContext context, String message, Future<T> Function() task) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(width: Space.lg),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    if (navigator.mounted) navigator.pop();
  }
}

/// Settings › Account › Sign out (T1.5.07). [revoked]: the device was removed from the account
/// (T1.5.14) — nothing can be pushed any more, so no pending guard, and a new device id.
Future<void> runSignOutFlow(BuildContext context, WidgetRef ref, {bool revoked = false}) async {
  final l = context.l10n;
  final guest = ref.read(sessionProvider)?.isAnonymous ?? false;
  final confirmed = await confirmDialog(
    context,
    title: l.authSignOutTitle,
    body: guest ? l.authSignOutGuestBody : l.authSignOutBody,
    confirmLabel: l.authSignOut,
    destructive: guest || revoked,
  );
  if (!confirmed || !context.mounted) return;
  final service = ref.read(signOutServiceProvider);
  final result = await withBlockingProgress(
    context,
    l.authSignOutSyncing,
    () => service.signOut(force: revoked, rotateDevice: revoked),
  );
  if (!context.mounted) return;
  if (result.outcome == SignOutOutcome.signedOut) {
    showInfoSnackBar(context, l.authSignedOut);
    return;
  }
  final choice = await showDialog<_PendingChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.authSignOutTitle),
      content: Text(l.authSignOutPendingBody(result.pending)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.actionCancel)),
        TextButton(
          key: const ValueKey('sign-out-export'),
          onPressed: () => Navigator.pop(ctx, _PendingChoice.export),
          child: Text(l.authExportFirst),
        ),
        FilledButton(
          key: const ValueKey('sign-out-anyway'),
          style: FilledButton.styleFrom(backgroundColor: ctx.colors.error, foregroundColor: ctx.colors.onError),
          onPressed: () => Navigator.pop(ctx, _PendingChoice.signOut),
          child: Text(l.authSignOutAnyway),
        ),
      ],
    ),
  );
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case _PendingChoice.export:
      unawaited(GoRouter.maybeOf(context)?.push('/settings/data'));
    case _PendingChoice.signOut:
      await withBlockingProgress(context, l.authSignOutSyncing, () => service.endSession(rotateDevice: revoked));
      if (context.mounted) showInfoSnackBar(context, l.authSignedOut);
  }
}
