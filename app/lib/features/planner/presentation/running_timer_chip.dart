import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/presentation/occurrence_panel.dart' show LiveElapsed;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Global running-timer chip for the app bar (T3.2.19): the most recently started timer's
/// title and live elapsed time (+N when several run under the `multiple` policy); tap opens
/// its occurrence. Invisible when no timer runs.
class RunningTimerChip extends ConsumerWidget {
  const RunningTimerChip({super.key, this.onOpen});

  /// Opens [timer]'s occurrence (default: the task details for that occurrence).
  final void Function(BuildContext context, RunningTimer timer)? onOpen;

  static void _defaultOpen(BuildContext context, RunningTimer timer) => unawaited(
    GoRouter.of(context).push(AppLinks.task(timer.entry.taskId, occurrenceKey: timer.entry.occurrenceKey)),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timers = ref.watch(runningTimersProvider).value ?? const <RunningTimer>[];
    if (timers.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final latest = timers.reduce((a, b) => b.entry.startedAt.isAfter(a.entry.startedAt) ? b : a);
    final elapsed = ref.read(clockProvider).nowUtc().difference(latest.entry.startedAt);
    final more = timers.length - 1;
    final label = l.tasksRunningTimer(latest.title, AppFormat.counter(elapsed.isNegative ? Duration.zero : elapsed));
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.xxs),
        child: ActionChip(
          key: const ValueKey('running-timer-chip'),
          tooltip: label,
          avatar: Icon(Icons.fiber_manual_record, size: 14, color: context.appColors.danger),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(latest.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: Space.xs),
              LiveElapsed(since: latest.entry.startedAt, style: context.text.labelLarge),
              if (more > 0) Text(' +$more'),
            ],
          ),
          onPressed: () => (onOpen ?? _defaultOpen)(context, latest),
        ),
      ),
    );
  }
}
