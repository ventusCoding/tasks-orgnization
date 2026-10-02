import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/alarm_window.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The ringing alarm (T7.2.24): opened by an alarm-profile notification (tap or Android
/// full-screen intent), shown above the lock screen while open. *Done* and *Snooze* go through the
/// action dispatcher like the notification buttons; *Stop* just silences it.
class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({required this.payload, super.key});

  final NotificationPayload payload;

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(AlarmWindow.showOnLockScreen(true));
  }

  @override
  void dispose() {
    unawaited(AlarmWindow.showOnLockScreen(false));
    super.dispose();
  }

  int get _snoozeMinutes => widget.payload.snoozeOptions.isEmpty ? 10 : widget.payload.snoozeOptions.first;

  Future<void> _act(String actionId) async {
    if (_busy) return;
    setState(() => _busy = true);
    final dispatcher = ref.read(notificationActionDispatcherProvider);
    final result = await dispatcher.handleAction(
      actionId,
      widget.payload,
      snoozeMinutes: actionId == NotificationActionIds.snooze ? _snoozeMinutes : null,
    );
    if (!mounted) return;
    if (result.message != null) showInfoSnackBar(context, result.message!);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = widget.payload;
    final now = TimeOfDay.now().format(context);
    final canDone = p.actions.contains(NotificationActionIds.done);
    return Scaffold(
      backgroundColor: context.colors.primaryContainer,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.alarm, size: 64, color: context.colors.onPrimaryContainer, semanticLabel: l.notifAlarmRinging),
              const SizedBox(height: Space.lg),
              Text(
                now,
                textAlign: TextAlign.center,
                style: context.text.displayLarge?.copyWith(color: context.colors.onPrimaryContainer),
              ),
              const SizedBox(height: Space.md),
              Text(
                p.title ?? l.notifAlarmRinging,
                textAlign: TextAlign.center,
                style: context.text.headlineSmall?.copyWith(color: context.colors.onPrimaryContainer),
              ),
              if (p.body != null) ...[
                const SizedBox(height: Space.sm),
                Text(
                  p.body!,
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge?.copyWith(color: context.colors.onPrimaryContainer),
                ),
              ],
              const Spacer(),
              if (canDone)
                FilledButton.icon(
                  key: const ValueKey('alarm-done'),
                  icon: const Icon(Icons.check),
                  label: Text(l.notifActionDone),
                  onPressed: _busy ? null : () => unawaited(_act(NotificationActionIds.done)),
                ),
              const SizedBox(height: Space.sm),
              FilledButton.tonalIcon(
                key: const ValueKey('alarm-snooze'),
                icon: const Icon(Icons.snooze),
                label: Text(l.notifAlarmSnooze(_snoozeMinutes)),
                onPressed: _busy ? null : () => unawaited(_act(NotificationActionIds.snooze)),
              ),
              const SizedBox(height: Space.sm),
              OutlinedButton(
                key: const ValueKey('alarm-stop'),
                onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
                child: Text(l.notifAlarmStop),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
