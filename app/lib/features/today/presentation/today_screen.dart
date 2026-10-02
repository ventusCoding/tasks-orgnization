import 'dart:async';

import 'package:everslot/app/widgets/app_bar_actions.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/settings/presentation/widgets/sync_indicator.dart' show SyncRefresh;
import 'package:everslot/features/today/application/today_overview_provider.dart';
import 'package:everslot/features/today/domain/today_layout.dart';
import 'package:everslot/features/today/domain/today_overview.dart';
import 'package:everslot/features/today/presentation/today_blocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Today (T8.1.02): the day header, then independent blocks in the user's order — each with its
/// own loading / error / empty state. Two columns on wide screens; pull to sync.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static TodaySection sectionOf(TodayBlockId id) => switch (id) {
    TodayBlockId.nowNext || TodayBlockId.agenda => TodaySection.planner,
    TodayBlockId.overdue => TodaySection.overdue,
    TodayBlockId.habits || TodayBlockId.quit => TodaySection.habits,
    TodayBlockId.checklists => TodaySection.checklists,
    TodayBlockId.inbox => TodaySection.inbox,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final overview = ref.watch(todayOverviewProvider);
    final layout = ref.watch(todayLayoutProvider);
    final blocks = <Widget>[
      for (final id in layout.visibleBlocks)
        if (_block(context, overview, layout, id) case final w?) w,
    ];
    final wide = context.windowSize != WindowSizeClass.compact;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabToday),
        actions: [
          IconButton(
            key: const ValueKey('today-customize'),
            tooltip: l.todayCustomize,
            icon: const Icon(Icons.dashboard_customize_outlined),
            onPressed: () => unawaited(showTodayCustomize(context)),
          ),
          const AppBarActions(),
        ],
      ),
      body: SyncRefresh(
        child: ListView(
          key: const ValueKey('today-list'),
          padding: const EdgeInsetsDirectional.only(bottom: Space.xxxl),
          children: [
            if (layout.showHeader) const TodayHeader(),
            if (!layout.hintDismissed('swipe') && (overview.agenda?.isNotEmpty ?? false)) const _SwipeHint(),
            if (!wide)
              ...blocks
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: [for (var i = 0; i < blocks.length; i += 2) blocks[i]])),
                  Expanded(child: Column(children: [for (var i = 1; i < blocks.length; i += 2) blocks[i]])),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget? _block(BuildContext context, TodayOverview o, TodayLayout layout, TodayBlockId id) {
    final block = TodayBlock.of(id);
    final error = o.errors[sectionOf(id)];
    final Widget body;
    if (error != null) {
      body = Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
        child: Text(context.l10n.todayLoadError, style: TextStyle(color: context.colors.error)),
      );
    } else if (block.isLoading(o)) {
      body = const Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: Space.lg, vertical: Space.sm),
        child: LinearProgressIndicator(),
      );
    } else if (block.isEmpty(o)) {
      if (!layout.keepsWhenEmpty(id)) return null;
      body = block.empty(context);
    } else {
      body = block.build(context, o);
    }
    return Column(
      key: ValueKey('today-block-${id.json}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [SectionHeader(block.title(context.l10n)), body],
    );
  }
}

/// Day progress header (T8.1.11): greeting, date and today's numbers; opens Insights.
class TodayHeader extends ConsumerWidget {
  const TodayHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = todayFormat(context, ref);
    final overview = ref.watch(todayOverviewProvider);
    final p = ref.watch(todayProgressProvider);
    final hour = ref
        .watch(zoneResolverProvider)
        .toLocal(ref.watch(clockProvider).nowUtc(), ref.watch(deviceZoneProvider))
        .time
        .hour;
    final greeting = hour < 12
        ? l.todayGreetingMorning
        : (hour < 18 ? l.todayGreetingAfternoon : l.todayGreetingEvening);
    return InkWell(
      key: const ValueKey('today-header'),
      onTap: () => context.go(AppLinks.insights()),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: context.text.headlineSmall),
            Text(fmt.dayLong(overview.date), style: context.text.bodyMedium),
            const SizedBox(height: Space.sm),
            LinearProgressIndicator(value: p.ratio, semanticsLabel: greeting),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.md,
              runSpacing: Space.xs,
              children: [
                Text(l.todayProgressTasks(p.tasksDone, p.tasksPlanned)),
                Text(l.todayProgressHabits(p.habitsDone, p.habitsDue)),
                if (p.itemsCompleted > 0) Text(l.todayProgressItems(p.itemsCompleted)),
                if (p.focusMinutes > 0) Text(l.todayProgressFocus(fmt.duration(p.focusMinutes))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeHint extends ConsumerWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Card(
      key: const ValueKey('today-hint-swipe'),
      margin: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
      color: context.colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.md, Space.sm, Space.sm, Space.sm),
        child: Row(
          children: [
            const Icon(Icons.swipe_outlined),
            const SizedBox(width: Space.md),
            Expanded(child: Text(l.todayHintSwipe)),
            TextButton(
              onPressed: () => unawaited(
                ref.read(todayLayoutWriterProvider)(ref.read(todayLayoutProvider).withHintDismissed('swipe')),
              ),
              child: Text(l.todayHintGotIt),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today customization (T8.1.12): reorder / hide blocks, show-when-empty, header, agenda and
/// overdue options, reset. Saved to the synced `today` settings namespace.
Future<void> showTodayCustomize(BuildContext context) =>
    showAppSheet<void>(context, title: context.l10n.todayCustomize, builder: (_) => const TodayCustomizeSheet());

class TodayCustomizeSheet extends ConsumerWidget {
  const TodayCustomizeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final layout = ref.watch(todayLayoutProvider);
    Future<void> save(TodayLayout next) => ref.read(todayLayoutWriterProvider)(next);
    String swipe(SwipeAction a) => switch (a) {
      SwipeAction.done => l.actionDone,
      SwipeAction.skip => l.actionSkip,
      SwipeAction.none => l.todaySwipeNone,
    };
    final blocks = layout.blocks;
    return ListView(
      shrinkWrap: true,
      children: [
        ReorderableListView(
          key: const ValueKey('today-reorder'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          // onReorderItem gives the index after removal; `moved` takes the pre-removal one.
          onReorderItem: (from, to) => unawaited(save(layout.moved(from, to > from ? to + 1 : to))),
          children: [
            for (var i = 0; i < blocks.length; i++)
              ListTile(
                key: ValueKey('customize-${blocks[i].json}'),
                leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                title: Text(blockTitle(l, blocks[i])),
                subtitle: layout.isHidden(blocks[i])
                    ? Text(l.todayBlockHidden)
                    : CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(l.todayKeepWhenEmpty),
                        value: layout.keepsWhenEmpty(blocks[i]),
                        onChanged: (v) => unawaited(save(layout.withShowWhenEmpty(blocks[i], show: v ?? false))),
                      ),
                trailing: Switch(
                  value: !layout.isHidden(blocks[i]),
                  onChanged: (v) => unawaited(save(layout.withHidden(blocks[i], hidden: !v))),
                ),
              ),
          ],
        ),
        const Divider(),
        SwitchListTile(
          title: Text(l.todayShowHeader),
          value: layout.showHeader,
          onChanged: (v) => unawaited(save(layout.copyWith(showHeader: v))),
        ),
        SwitchListTile(
          title: Text(l.todayShowCompleted),
          value: layout.agendaShowCompleted,
          onChanged: (v) => unawaited(save(layout.copyWith(agendaShowCompleted: v))),
        ),
        for (final (start, label) in [(true, l.todaySwipeStart), (false, l.todaySwipeEnd)])
          ListTile(
            title: Text(label),
            trailing: DropdownButton<SwipeAction>(
              value: start ? layout.swipeStart : layout.swipeEnd,
              items: [for (final a in SwipeAction.values) DropdownMenuItem(value: a, child: Text(swipe(a)))],
              onChanged: (a) => unawaited(save(start ? layout.copyWith(swipeStart: a) : layout.copyWith(swipeEnd: a))),
            ),
          ),
        ListTile(
          title: Text(l.todayLookback),
          trailing: DropdownButton<int>(
            value: ref.watch(todayOverdueLookbackProvider),
            items: [
              for (final d in {1, 3, 7, 14, 30, 60, ref.watch(todayOverdueLookbackProvider)}.toList()..sort())
                DropdownMenuItem(value: d, child: Text('$d')),
            ],
            onChanged: (d) => unawaited(save(layout.copyWith(overdueLookbackDays: d))),
          ),
        ),
        SwitchListTile(
          title: Text(l.todayIncludeRecurring),
          value: layout.overdueIncludeRecurring,
          onChanged: (v) => unawaited(save(layout.copyWith(overdueIncludeRecurring: v))),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.all(Space.lg),
          child: OutlinedButton.icon(
            key: const ValueKey('today-reset'),
            icon: const Icon(Icons.restart_alt),
            label: Text(l.todayResetLayout),
            onPressed: () => unawaited(save(TodayLayout(dismissedHints: layout.dismissedHints))),
          ),
        ),
      ],
    );
  }
}
