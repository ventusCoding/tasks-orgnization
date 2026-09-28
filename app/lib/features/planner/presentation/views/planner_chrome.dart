import 'dart:async';

import 'package:everslot/app/widgets/app_bar_actions.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/planner_selection.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Title of a date range in the locale's order: "21–27 sept. 2026" / "Sep 21–27, 2026",
/// "28 Sep – 4 Oct 2026" / "Sep 28 – Oct 4, 2026", across years both full dates; one day = its
/// long date.
String rangeTitle(String locale, LocalDate first, LocalDate last) {
  final a = first.toDateTimeUtc();
  final b = last.toDateTimeUtc();
  if (first == last) return DateFormat.yMMMEd(locale).format(a);
  if (first.year == last.year && first.month == last.month) {
    final dayFirst = DateFormat.MMMd(locale).pattern!.trimLeft().startsWith('d');
    return dayFirst
        ? '${DateFormat.d(locale).format(a)}–${DateFormat.yMMMd(locale).format(b)}'
        : '${DateFormat.MMMd(locale).format(a)}–${DateFormat.d(locale).format(b)}, ${DateFormat.y(locale).format(b)}';
  }
  if (first.year == last.year) return '${DateFormat.MMMd(locale).format(a)} – ${DateFormat.yMMMd(locale).format(b)}';
  return '${DateFormat.yMMMd(locale).format(a)} – ${DateFormat.yMMMd(locale).format(b)}';
}

/// Common scaffold of every planner view (T3.4.01 / T3.6.01): the view switcher in the app bar,
/// the tab-root actions, a view-specific toolbar row and an optional FAB.
class PlannerViewScaffold extends ConsumerWidget {
  const PlannerViewScaffold({
    required this.viewKey,
    required this.body,
    this.toolbar,
    this.fab,
    this.endDrawer,
    super.key,
  });

  final String viewKey;
  final Widget body;
  final Widget? toolbar;
  final Widget? fab;
  final Widget? endDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selection mode (T3.1.18) replaces the view toolbar with the selection bar.
    final selecting = ref.watch(plannerSelectionProvider(viewKey).select((s) => s.isNotEmpty));
    final bar = selecting ? SelectionToolbar(viewKey: viewKey) : toolbar;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: Space.sm,
        title: PlannerViewSwitcher(viewKey: viewKey),
        actions: const [AppBarActions()],
        bottom: bar == null ? null : PreferredSize(preferredSize: const Size.fromHeight(48), child: bar),
      ),
      endDrawer: endDrawer,
      body: body,
      floatingActionButton: selecting ? null : fab,
    );
  }
}

/// The view switcher (T3.6.01): current view icon + name; tap → view picker, long-press → saved
/// views.
class PlannerViewSwitcher extends ConsumerWidget {
  const PlannerViewSwitcher({required this.viewKey, super.key});

  final String viewKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(plannerViewRegistryProvider);
    final saved = ref.watch(plannerSavedViewsProvider).value ?? const <SavedView>[];
    final l = context.l10n;
    final savedId = ViewKeys.savedIdOf(viewKey);
    final savedView = savedId == null ? null : saved.where((v) => v.id == savedId).firstOrNull;
    final entry = savedView != null ? registry.forType(savedView.type) : registry.byId(viewKey);
    final name = savedView?.name ?? entry?.label(l) ?? viewKey;
    return Semantics(
      button: true,
      label: '${l.pvViewSwitcher}: $name',
      onLongPress: () => unawaited(showSavedViewsSheet(context, ref, currentKey: viewKey)),
      child: ExcludeSemantics(
        child: InkWell(
          key: const Key('planner-view-switcher'),
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () => unawaited(showViewPicker(context, ref, currentKey: viewKey)),
          onLongPress: () => unawaited(showSavedViewsSheet(context, ref, currentKey: viewKey)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: Space.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(entry?.icon ?? Icons.view_week_outlined, size: 20),
                const SizedBox(width: Space.xs),
                Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Picker of the available views (registry entries gated by feature flags, then saved views).
Future<void> showViewPicker(BuildContext context, WidgetRef ref, {required String currentKey}) async {
  final registry = ref.read(plannerViewRegistryProvider);
  final env = ref.read(envProvider);
  final flags = ref.read(featureFlagsProvider);
  final saved = ref.read(plannerSavedViewsProvider).value ?? const <SavedView>[];
  final userId = ref.read(currentUserIdProvider);
  final l = context.l10n;
  final entries = registry.available(flags, dev: env.isDev);
  final custom = [for (final v in saved) if (!registry.isEntryRow(v.id, userId)) v];
  final picked = await showAppSheet<String>(
    context,
    title: l.pvViewSwitcher,
    builder: (ctx) => ListView(
      shrinkWrap: true,
      children: [
        for (final group in PlannerViewGroup.values) ...[
          if (entries.any((e) => e.group == group))
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, Space.sm, Space.xl, Space.xs),
              child: Text(group.label(l), style: ctx.text.labelLarge?.copyWith(color: ctx.colors.primary)),
            ),
          for (final e in entries.where((e) => e.group == group))
            ListTile(
              key: Key('view-${e.id}'),
              leading: Icon(e.icon),
              title: Text(e.label(l)),
              trailing: e.id == currentKey ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, e.id),
            ),
        ],
        if (custom.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, Space.sm, Space.xl, Space.xs),
            child: Text(l.pvSavedViews, style: ctx.text.labelLarge?.copyWith(color: ctx.colors.primary)),
          ),
          for (final v in custom)
            ListTile(
              leading: Icon(registry.forType(v.type)?.icon ?? Icons.bookmark_outline),
              title: Text(v.name),
              subtitle: v.isDefault ? Text(l.pvDefaultBadge) : null,
              trailing: ViewKeys.saved(v.id) == currentKey ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, ViewKeys.saved(v.id)),
            ),
        ],
        ListTile(
          leading: const Icon(Icons.bookmarks_outlined),
          title: Text(l.pvSavedViews),
          onTap: () => Navigator.pop(ctx, '__saved__'),
        ),
        const SizedBox(height: Space.md),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  if (picked == '__saved__') {
    await showSavedViewsSheet(context, ref, currentKey: currentKey);
    return;
  }
  if (picked == currentKey) return;
  ref.read(plannerNavProvider).openView(context, picked, date: ref.read(plannerAnchorProvider) ?? ref.read(plannerTodayProvider));
}

/// Saved views management (T3.6.02): open, rename, duplicate, delete, set default, reorder, and
/// *Save view as…* for the current view.
Future<void> showSavedViewsSheet(BuildContext context, WidgetRef ref, {required String currentKey}) async {
  await showAppSheet<void>(
    context,
    title: context.l10n.pvSavedViews,
    builder: (ctx) => _SavedViewsList(currentKey: currentKey, outerContext: context),
  );
}

class _SavedViewsList extends ConsumerWidget {
  const _SavedViewsList({required this.currentKey, required this.outerContext});

  final String currentKey;
  final BuildContext outerContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final registry = ref.watch(plannerViewRegistryProvider);
    final userId = ref.watch(currentUserIdProvider);
    final saved = ref.watch(plannerSavedViewsProvider).value ?? const <SavedView>[];
    final custom = [for (final v in saved) if (!registry.isEntryRow(v.id, userId)) v];
    final repo = ref.read(savedViewsRepositoryProvider);
    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          key: const Key('save-view-as'),
          leading: const Icon(Icons.bookmark_add_outlined),
          title: Text(l.pvSaveViewAs),
          onTap: () async {
            final config = ref.read(plannerViewConfigProvider(currentKey));
            final name = await promptText(context, title: l.pvSaveViewAs, hint: l.pvViewName);
            if (name == null) return;
            final id = await repo.create(name, config);
            if (!context.mounted) return;
            Navigator.pop(context);
            if (outerContext.mounted) {
              showInfoSnackBar(outerContext, l.pvViewSaved);
              ref.read(plannerNavProvider).openView(outerContext, ViewKeys.saved(id), date: ref.read(plannerAnchorProvider));
            }
          },
        ),
        if (custom.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Text(l.pvNoSavedViews, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          ),
        for (final (i, v) in custom.indexed)
          ListTile(
            leading: Icon(registry.forType(v.type)?.icon ?? Icons.bookmark_outline),
            title: Text(v.name),
            subtitle: v.isDefault ? Text(l.pvDefaultBadge) : null,
            onTap: () {
              Navigator.pop(context);
              ref.read(plannerNavProvider).openView(outerContext, ViewKeys.saved(v.id), date: ref.read(plannerAnchorProvider));
            },
            trailing: PopupMenuButton<String>(
              tooltip: l.pvViewSettings,
              onSelected: (action) async {
                switch (action) {
                  case 'rename':
                    final name = await promptText(context, title: l.pvRenameView, initial: v.name);
                    if (name != null) await repo.rename(v.id, name);
                  case 'duplicate':
                    await repo.duplicate(v.id, l.pvCopySuffix(v.name));
                  case 'default':
                    await repo.setDefault(v.id);
                  case 'up':
                    await repo.move(v.id, afterKey: i >= 2 ? custom[i - 2].sortKey : null, beforeKey: custom[i - 1].sortKey);
                  case 'down':
                    await repo.move(v.id, afterKey: custom[i + 1].sortKey, beforeKey: i + 2 < custom.length ? custom[i + 2].sortKey : null);
                  case 'delete':
                    if (await confirmDialog(context, title: l.pvDeleteView, body: v.name, destructive: true, confirmLabel: l.actionDelete)) {
                      await repo.delete(v.id);
                    }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'rename', child: Text(l.pvRenameView)),
                PopupMenuItem(value: 'duplicate', child: Text(l.pvDuplicateView)),
                if (!v.isDefault) PopupMenuItem(value: 'default', child: Text(l.pvSetDefaultView)),
                if (i > 0) PopupMenuItem(value: 'up', child: Text(l.pvMoveUp)),
                if (i < custom.length - 1) PopupMenuItem(value: 'down', child: Text(l.pvMoveDown)),
                PopupMenuItem(value: 'delete', child: Text(l.pvDeleteView)),
              ],
            ),
          ),
        const SizedBox(height: Space.md),
      ],
    );
  }
}

/// Toolbar of date-paged views: previous / title (→ mini-month) / next, Today and trailing actions.
class DatePagedToolbar extends StatelessWidget {
  const DatePagedToolbar({
    required this.title,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.previousLabel,
    required this.nextLabel,
    this.onTitleTap,
    this.onTodayLongPress,
    this.trailing = const [],
    super.key,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback? onTodayLongPress;
  final VoidCallback? onTitleTap;
  final String previousLabel;
  final String nextLabel;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // A fixed 48-dp bar: text grows up to 1.4× here (the title ellipsizes beyond that).
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            key: const Key('planner-previous'),
            tooltip: previousLabel,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Semantics(
              button: onTitleTap != null,
              label: '$title, ${l.pvJumpToDate}',
              child: ExcludeSemantics(
                child: InkWell(
                  key: const Key('planner-title'),
                  onTap: onTitleTap,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.sm),
                    child: LayoutBuilder(
                      builder: (context, box) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (onTitleTap != null && box.maxWidth >= 48) const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('planner-next'),
            tooltip: nextLabel,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
          GestureDetector(
            onLongPress: onTodayLongPress,
            child: IconButton(
              key: const Key('planner-today'),
              tooltip: l.actionToday,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.today_outlined),
              onPressed: onToday,
            ),
          ),
          ...trailing,
        ],
      ),
      ),
    );
  }
}

/// Slot-size button showing the current size ("30 min").
class SlotSizeButton extends StatelessWidget {
  const SlotSizeButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: Space.xs),
    child: Semantics(
      button: true,
      label: '${context.l10n.pvSlotSize}: $label',
      child: ExcludeSemantics(
        child: ActionChip(
          key: const Key('slot-size-button'),
          visualDensity: VisualDensity.compact,
          label: Text(label),
          onPressed: onPressed,
        ),
      ),
    ),
  );
}

/// Contextual "+" (T3.4.01): the full editor prefilled with the next sensible start.
class PlannerFab extends ConsumerWidget {
  const PlannerFab({required this.start, super.key});

  /// Suggested start (null = the editor's default).
  final LocalDateTime? Function() start;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FloatingActionButton(
    key: const Key('planner-fab'),
    tooltip: context.l10n.pvAddTask,
    onPressed: () {
      final work = ref.read(plannerWorkSettingsProvider);
      ref.read(plannerNavProvider).newTask(context, start: start(), duration: work.defaultDuration);
    },
    child: const Icon(Icons.add),
  );
}

/// Next quarter hour on [day] when it is today, else 09:00.
LocalDateTime suggestedStart(LocalDate day, LocalDateTime now) {
  if (day != now.date) return day.atTime(LocalTime(9, 0));
  final m = now.time.minuteOfDay;
  final next = ((m + 14) ~/ 15) * 15;
  return next >= 1440 ? day.atTime(LocalTime(23, 45)) : day.atStartOfDay.plusMinutes(next);
}

/// Active-filter chips with *Clear* (T3.4.10).
class ActiveFilterBar extends ConsumerWidget {
  const ActiveFilterBar({required this.viewKey, super.key});

  final String viewKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(plannerViewConfigProvider(viewKey));
    final f = config.filters;
    if (!f.isActive) return const SizedBox.shrink();
    final l = context.l10n;
    final notifier = ref.read(plannerViewConfigProvider(viewKey).notifier);
    final chips = <Widget>[
      if (f.categories.isNotEmpty)
        InputChip(
          label: Text('${l.pvCategories} · ${f.categories.length}'),
          onDeleted: () => notifier.change((c) => c.copyWith(filters: c.filters.copyWith(categories: const []))),
        ),
      if (f.tags.isNotEmpty)
        InputChip(
          label: Text('#${f.tags.length}'),
          onDeleted: () => notifier.change((c) => c.copyWith(filters: c.filters.copyWith(tags: const []))),
        ),
      if (f.priorities.isNotEmpty)
        InputChip(
          label: Text('${l.pvPriorities} · ${f.priorities.length}'),
          onDeleted: () => notifier.change((c) => c.copyWith(filters: c.filters.copyWith(priorities: const []))),
        ),
      if (f.statuses.isNotEmpty)
        InputChip(
          label: Text('${l.pvStatuses} · ${f.statuses.length}'),
          onDeleted: () => notifier.change((c) => c.copyWith(filters: c.filters.copyWith(statuses: const []))),
        ),
      if (f.trackingModes.isNotEmpty)
        InputChip(
          label: Text('${l.pvTrackingModes} · ${f.trackingModes.length}'),
          onDeleted: () => notifier.change((c) => c.copyWith(filters: c.filters.copyWith(trackingModes: const []))),
        ),
      if (f.text?.isNotEmpty ?? false)
        InputChip(
          label: Text('“${f.text}”'),
          onDeleted: () => notifier.change((c) => c.copyWith(filters: c.filters.copyWith(clearText: true))),
        ),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
        children: [
          for (final c in chips) Padding(padding: const EdgeInsetsDirectional.only(end: Space.xs), child: c),
          TextButton(
            key: const Key('clear-filters'),
            onPressed: () => notifier.change((c) => c.copyWith(filters: const ViewFilters())),
            child: Text(l.pvClearFilters),
          ),
        ],
      ),
    );
  }
}

/// Filter button with the number of active filter groups.
class PlannerFilterButton extends ConsumerWidget {
  const PlannerFilterButton({required this.viewKey, super.key});

  final String viewKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(plannerViewConfigProvider(viewKey).select((c) => c.filters.activeCount));
    return IconButton(
      key: const Key('planner-filter'),
      tooltip: context.l10n.pvFilter,
      visualDensity: VisualDensity.compact,
      icon: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.filter_list)),
      onPressed: () => unawaited(showFilterSheet(context, ref, viewKey: viewKey)),
    );
  }
}

/// Overflow menu of a view: settings, filters, saved views, *Save view as…*, Plan default.
class PlannerMoreMenu extends ConsumerWidget {
  const PlannerMoreMenu({required this.viewKey, this.kind = ViewSettingsKind.timeGrid, this.extra = const [], super.key});

  final String viewKey;
  final ViewSettingsKind kind;

  /// View-specific entries: (value, label, action).
  final List<(String, String, VoidCallback)> extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return PopupMenuButton<String>(
      key: const Key('planner-more'),
      tooltip: l.actionMore,
      onSelected: (v) async {
        switch (v) {
          case 'settings':
            await showViewSettingsSheet(context, ref, viewKey: viewKey, kind: kind);
          case 'filters':
            await showFilterSheet(context, ref, viewKey: viewKey);
          case 'saved':
            await showSavedViewsSheet(context, ref, currentKey: viewKey);
          case 'default':
            await setPlanDefaultView(ref, viewKey);
            if (context.mounted) showInfoSnackBar(context, l.pvViewSaved);
          default:
            for (final e in extra) {
              if (e.$1 == v) e.$3();
            }
        }
      },
      itemBuilder: (_) => [
        for (final e in extra) PopupMenuItem(value: e.$1, child: Text(e.$2)),
        PopupMenuItem(value: 'settings', child: Text(l.pvViewSettings)),
        PopupMenuItem(value: 'filters', child: Text(l.pvFilters)),
        PopupMenuItem(value: 'saved', child: Text(l.pvSavedViews)),
        PopupMenuItem(value: 'default', child: Text(l.pvSetAsPlanDefault)),
      ],
    );
  }
}

/// Marks [viewKey] as the view the Plan tab opens on (T3.6.02 *set as default*).
Future<void> setPlanDefaultView(WidgetRef ref, String viewKey) async {
  final repo = ref.read(savedViewsRepositoryProvider);
  final savedId = ViewKeys.savedIdOf(viewKey);
  if (savedId != null) {
    await repo.setDefault(savedId);
    return;
  }
  final userId = ref.read(currentUserIdProvider);
  await repo.saveEntry(viewKey, viewKey, ref.read(plannerViewConfigProvider(viewKey)));
  await repo.setDefault(entryViewId(userId, viewKey));
}
