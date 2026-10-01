import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/live_ticker.dart' show sharedTickerProvider;
import 'package:everslot/features/habits/presentation/quit/live_counter.dart' show counterParts;
import 'package:everslot/features/planner/application/planner_contract.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/application/view_config/countdowns.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart' show CountdownMode;
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:material_ui/material_ui.dart';

/// Countdown / count-up list (T3.7.12, TickTick style): tasks with `countdown_mode` as live
/// counters — "in N days" to an upcoming task or deadline, "N days ago" since a past event — in
/// Pinned (`options.pinned`), Upcoming and Since groups; d · h · m from the quit tracker's counter
/// engine on the shared one-second ticker.
class CountdownView extends ConsumerWidget {
  const CountdownView({required this.args, super.key});

  final PlannerViewArgs args;

  String get _key => args.viewKey;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final today = ref.read(plannerTodayProvider);
    final upcoming = await _firstValue(ref, plannerItemsProvider(DayRange(today.plusDays(-30), 400)));
    final backlog = await _firstValue(ref, backlogItemsProvider);
    if (!context.mounted) return;
    final seen = <String>{};
    final candidates = [
      for (final i in [...upcoming, ...backlog])
        if (seen.add(i.taskId)) i,
    ];
    final picked = await showAppSheet<(PlannerItem, CountdownMode)>(
      context,
      title: l.pvAddCountdown,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          for (final i in candidates)
            ListTile(
              key: ValueKey('countdown-pick-${i.taskId}'),
              title: Text(i.title),
              subtitle: i.isBacklog ? null : Text(ctx.plannerFormat().dateMedium(i.startLocal.date)),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: l.pvCountdownUntil,
                    icon: const Icon(Icons.hourglass_bottom),
                    onPressed: () => Navigator.pop(ctx, (i, CountdownMode.until)),
                  ),
                  IconButton(
                    tooltip: l.pvCountdownSince,
                    icon: const Icon(Icons.history),
                    onPressed: () => Navigator.pop(ctx, (i, CountdownMode.since)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    await _setMode(context, ref, picked.$1.taskId, picked.$2);
  }

  static Future<List<PlannerItem>> _firstValue(WidgetRef ref, ProviderListenable<AsyncValue<List<PlannerItem>>> p) {
    final done = Completer<List<PlannerItem>>();
    final sub = ref.listenManual(p, (_, next) {
      if (next.hasValue && !done.isCompleted) done.complete(next.value);
    }, fireImmediately: true);
    return done.future.timeout(const Duration(seconds: 5), onTimeout: () => const []).whenComplete(sub.close);
  }

  Future<void> _setMode(BuildContext context, WidgetRef ref, String taskId, CountdownMode? mode) async {
    final l = context.l10n;
    await PlannerCommands(context, ref).track(mode == null ? l.pvRemoveCountdown : l.pvAddCountdown, () async {
      final service = ref.read(plannerServiceProvider);
      final task = await service.task(taskId);
      if (task != null) await service.updateTask(task.copyWith(countdownMode: mode), source: 'countdown');
    });
  }

  void _togglePin(WidgetRef ref, String taskId, List<String> pinned) {
    final next = pinned.contains(taskId)
        ? [
            for (final id in pinned)
              if (id != taskId) id,
          ]
        : [...pinned, taskId];
    ref.read(plannerViewConfigProvider(_key).notifier).change((c) => c.withOption('pinned', next));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final pinned = config.option<List<Object?>>('pinned', const []).whereType<String>().toList();
    final entries = ref.watch(countdownEntriesProvider);
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: SizedBox(
        height: 48,
        child: Row(
          children: [
            const SizedBox(width: Space.md),
            Expanded(child: Text(l.pvViewCountdown, style: context.text.titleSmall)),
            IconButton(
              key: const Key('countdown-add'),
              tooltip: l.pvAddCountdown,
              icon: const Icon(Icons.add_alarm),
              onPressed: () => unawaited(_add(context, ref)),
            ),
            PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
          ],
        ),
      ),
      body: AsyncValueView<List<CountdownEntry>>(
        value: entries,
        data: (list) {
          if (list.isEmpty) return EmptyState(icon: Icons.hourglass_empty, title: l.pvNoCountdowns);
          final groups = <(String, List<CountdownEntry>)>[
            (
              l.pvPinned,
              [
                for (final e in list)
                  if (pinned.contains(e.task.id)) e,
              ],
            ),
            (
              l.pvUpcoming,
              [
                for (final e in list)
                  if (!pinned.contains(e.task.id) && e.mode == CountdownMode.until) e,
              ],
            ),
            (
              l.pvSinceGroup,
              [
                for (final e in list.reversed)
                  if (!pinned.contains(e.task.id) && e.mode == CountdownMode.since) e,
              ],
            ),
          ];
          return ListView(
            key: const Key('countdown-list'),
            padding: const EdgeInsets.all(Space.md),
            children: [
              for (final (title, group) in groups)
                if (group.isNotEmpty) ...[
                  SectionHeader(
                    title,
                    padding: const EdgeInsetsDirectional.only(top: Space.sm, bottom: Space.xs),
                  ),
                  for (final e in group)
                    _CountdownRow(
                      key: ValueKey('countdown-${e.task.id}'),
                      entry: e,
                      pinned: pinned.contains(e.task.id),
                      onPin: () => _togglePin(ref, e.task.id, pinned),
                      onRemove: () => unawaited(_setMode(context, ref, e.task.id, null)),
                      onOpen: () => ref.read(plannerNavProvider).openTaskId(context, e.task.id),
                    ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _CountdownRow extends ConsumerStatefulWidget {
  const _CountdownRow({
    required this.entry,
    required this.pinned,
    required this.onPin,
    required this.onRemove,
    required this.onOpen,
    super.key,
  });

  final CountdownEntry entry;
  final bool pinned;
  final VoidCallback onPin;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  ConsumerState<_CountdownRow> createState() => _CountdownRowState();
}

class _CountdownRowState extends ConsumerState<_CountdownRow> {
  late final _ticker = ref.read(sharedTickerProvider);

  @override
  void initState() {
    super.initState();
    _ticker.addListener(_tick);
  }

  @override
  void dispose() {
    _ticker.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = widget.entry;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final now = ref.read(clockProvider).nowUtc();
    final today = ref.watch(plannerTodayProvider);
    final until = e.mode == CountdownMode.until;
    final days = calendarDaysBetween(today, e.targetLocal.date);
    final dayText = until ? l.pvDaysUntil(days.clamp(0, 1 << 30)) : l.pvDaysSince((-days).clamp(0, 1 << 30));
    final p = counterParts(until ? e.target.difference(now) : now.difference(e.target));
    return Card(
      child: ListTile(
        onTap: widget.onOpen,
        leading: Icon(until ? Icons.hourglass_bottom : Icons.history, color: context.colors.primary),
        title: Text(e.task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${f.dateMedium(e.targetLocal.date)} · ${l.pvCounterParts(p.days, p.hours, p.minutes)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(dayText, key: ValueKey('countdown-days-${e.task.id}'), style: context.text.titleSmall),
            PopupMenuButton<String>(
              key: ValueKey('countdown-menu-${e.task.id}'),
              onSelected: (v) => v == 'pin' ? widget.onPin() : widget.onRemove(),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'pin', child: Text(widget.pinned ? l.pvUnpin : l.pvPin)),
                PopupMenuItem(value: 'remove', child: Text(l.pvRemoveCountdown)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
