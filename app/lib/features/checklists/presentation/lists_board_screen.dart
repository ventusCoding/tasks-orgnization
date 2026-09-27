import 'dart:async';

import 'package:everslot/app/widgets/app_bar_actions.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart' show Attachment;
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/collation.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart' show NodeSpec;
import 'package:everslot/features/checklists/presentation/archive_templates_screens.dart';
import 'package:everslot/features/checklists/presentation/checklist_card.dart';
import 'package:everslot/features/checklists/presentation/checklist_navigation.dart';
import 'package:everslot/features/checklists/presentation/import_export_ui.dart';
import 'package:everslot/features/checklists/presentation/items_table_screen.dart';
import 'package:everslot/features/checklists/presentation/lists_preferences_sheet.dart';
import 'package:everslot/features/organization/application/providers.dart' show tagsByEntityProvider, tagsProvider;
import 'package:everslot/features/organization/domain/tag.dart';
import 'package:everslot/features/organization/presentation/tag_widgets.dart';
import 'package:everslot/features/organization/presentation/tags_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_ui/material_ui.dart';

/// Quick filters of the board (T4.1.13); they combine with AND.
enum BoardFilter { waitingOrBlocked, attachments, dueDates, repeating, pinned }

/// Checklist labels are tags on `entity_tags` with this entity type (T4.1.12).
const checklistTagType = 'checklist';

/// The Keep-like home of the Lists tab (T4.1.07).
class ListsBoardScreen extends ConsumerStatefulWidget {
  const ListsBoardScreen({super.key});

  @override
  ConsumerState<ListsBoardScreen> createState() => _ListsBoardScreenState();
}

class _ListsBoardScreenState extends ConsumerState<ListsBoardScreen> {
  final _query = TextEditingController();
  bool _searching = false;
  final Set<BoardFilter> _filters = {};
  int? _color;

  /// Label filter from the drawer or the search chips (T4.1.12).
  String? _labelId;
  BoardSearchResult? _results;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _query.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onQuery(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      final r = q.trim().isEmpty ? null : await ref.read(checklistsRepositoryProvider).search(q);
      if (mounted) setState(() => _results = r);
    });
  }

  Future<void> _create({bool note = false}) async {
    final id = Ids.v7();
    ref.read(pendingCardProvider.notifier).set(PendingCard(id: id, note: note));
    await openChecklist(context, id);
  }

  Future<void> _fabMenu() async {
    unawaited(HapticFeedback.mediumImpact());
    final l = context.l10n;
    final choice = await showAppSheet<String>(
      context,
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.checklist),
              title: Text(l.listsNewChecklist),
              onTap: () => Navigator.pop(ctx, 'list'),
            ),
            ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: Text(l.listsNewNote),
              onTap: () => Navigator.pop(ctx, 'note'),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: Text(l.listsFromTemplate),
              onTap: () => Navigator.pop(ctx, 'template'),
            ),
            ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: Text(l.listsImportFile),
              onTap: () => Navigator.pop(ctx, 'import'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'list':
        await _create();
      case 'note':
        await _create(note: true);
      case 'template':
        await Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const TemplatesScreen(pickMode: true)));
      case 'import':
        await importFileAsNewList(context, ref);
    }
  }

  Future<void> _refresh() async {
    ref.read(syncServiceProvider)?.schedulePull(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  List<Checklist> _sorted(List<Checklist> lists, BoardConfig config) => switch (config.sort) {
    BoardSort.manual => lists,
    BoardSort.recentlyEdited => [
      ...lists,
    ]..sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0))),
    BoardSort.title => [...lists]..sort((a, b) => Collation.compare(a.title, b.title)),
  };

  bool _matches(
    Checklist c,
    Map<String, CardSummary> summaries,
    Map<String, Attachment> thumbs,
    Map<String, List<Tag>> labels,
  ) {
    final s = summaries[c.id] ?? CardSummary.empty;
    for (final f in _filters) {
      final ok = switch (f) {
        BoardFilter.waitingOrBlocked => s.rollup.blockedBelow + s.rollup.waitingBelow > 0,
        BoardFilter.attachments => thumbs.containsKey(c.id),
        BoardFilter.dueDates => c.dueLocal != null || s.dueCount > 0,
        BoardFilter.repeating => c.isRecurring,
        BoardFilter.pinned => c.isPinned,
      };
      if (!ok) return false;
    }
    if (_color != null && c.color != _color) return false;
    if (_labelId != null && !(labels[c.id]?.any((t) => t.id == _labelId) ?? false)) return false;
    final r = _results;
    if (_searching && r != null && !r.checklistIds.contains(c.id)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(boardConfigProvider).value ?? BoardConfig.defaults;
    final lists = ref.watch(boardChecklistsProvider);
    final summaries = ref.watch(cardSummariesProvider(false)).value ?? const <String, CardSummary>{};
    final thumbs = ref.watch(cardThumbnailsProvider(false)).value ?? const <String, Attachment>{};
    final counts = ref.watch(smartCountsProvider).value ?? const SmartCounts();
    final labels = ref.watch(tagsByEntityProvider(checklistTagType)).value ?? const <String, List<Tag>>{};
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    final activeLabel = _labelId == null ? null : tags.where((t) => t.id == _labelId).firstOrNull;
    return Scaffold(
      drawer: _LabelsDrawer(
        tags: tags,
        counts: _labelCounts(lists.value ?? const [], labels),
        selected: _labelId,
        onSelected: (id) => setState(() => _labelId = id),
      ),
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _query,
                autofocus: true,
                decoration: InputDecoration(hintText: l.listsSearchHint, border: InputBorder.none),
                onChanged: _onQuery,
              )
            : Text(l.tabLists),
        actions: [
          IconButton(
            tooltip: _searching ? l.actionClose : l.actionSearch,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _query.clear();
                _results = null;
                _filters.clear();
                _color = null;
              }
            }),
          ),
          if (!_searching)
            IconButton(
              tooltip: config.layout == BoardLayout.grid ? l.listsListView : l.listsGridView,
              icon: Icon(config.layout == BoardLayout.grid ? Icons.view_agenda_outlined : Icons.grid_view),
              onPressed: () => ref
                  .read(boardConfigStoreProvider)
                  .save(
                    config.copyWith(layout: config.layout == BoardLayout.grid ? BoardLayout.list : BoardLayout.grid),
                  ),
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'archive':
                  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ArchiveScreen()));
                case 'templates':
                  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TemplatesScreen()));
                case 'table':
                  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ItemsTableScreen()));
                case 'trash':
                  openTrash(context);
                case 'import':
                  await importFileAsNewList(context, ref);
                case 'prefs':
                  await showListsPreferences(context, ref);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'archive', child: Text(l.listsArchive)),
              PopupMenuItem(value: 'templates', child: Text(l.listsTemplates)),
              PopupMenuItem(value: 'table', child: Text(l.itemsTableOpen)),
              PopupMenuItem(value: 'trash', child: Text(l.listsTrash)),
              PopupMenuItem(value: 'import', child: Text(l.listsImportFile)),
              PopupMenuItem(value: 'prefs', child: Text(l.listsPreferences)),
            ],
          ),
          if (!_searching) const AppBarActions(),
        ],
      ),
      floatingActionButton: GestureDetector(
        onLongPress: _fabMenu,
        child: FloatingActionButton(tooltip: l.listsNewChecklist, onPressed: _create, child: const Icon(Icons.add)),
      ),
      body: AsyncValueView<List<Checklist>>(
        value: lists,
        data: (all) {
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.checklist_rtl,
              title: l.listsEmptyTitle,
              message: l.listsEmptyMessage,
              actionLabel: l.listsEmptyAction,
              onAction: _create,
            );
          }
          final visible = _sorted(all, config).where((c) => _matches(c, summaries, thumbs, labels)).toList();
          final pinned = visible.where((c) => c.isPinned).toList();
          final others = visible.where((c) => !c.isPinned).toList();
          final canDrag = config.sort == BoardSort.manual && !_searching;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                if (_searching) SliverToBoxAdapter(child: _filterChips(context, tags, activeLabel)),
                if (!_searching && activeLabel != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
                      child: Semantics(
                        label: l.listsLabelFilterActive(activeLabel.name),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TagChip(tag: activeLabel, onDeleted: () => setState(() => _labelId = null)),
                        ),
                      ),
                    ),
                  ),
                if (!_searching && config.showSmartChips && !counts.isEmpty)
                  SliverToBoxAdapter(child: _SmartChips(counts: counts)),
                if (_searching && _results != null && _results!.items.isNotEmpty)
                  SliverToBoxAdapter(child: _ItemHits(result: _results!)),
                if (pinned.isNotEmpty) ...[
                  SliverToBoxAdapter(child: SectionHeader(l.listsPinned)),
                  _section(pinned, summaries, thumbs, labels, config, canDrag),
                ],
                if (others.isNotEmpty) ...[
                  if (pinned.isNotEmpty) SliverToBoxAdapter(child: SectionHeader(l.listsOthers)),
                  if (pinned.isEmpty) const SliverToBoxAdapter(child: SizedBox(height: Space.md)),
                  _section(others, summaries, thumbs, labels, config, canDrag),
                ],
                if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(icon: Icons.search_off, title: l.listsSearchNoResults),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Live board lists per label id (drawer counts).
  Map<String, int> _labelCounts(List<Checklist> lists, Map<String, List<Tag>> labels) {
    final counts = <String, int>{};
    for (final c in lists) {
      for (final t in labels[c.id] ?? const <Tag>[]) {
        counts[t.id] = (counts[t.id] ?? 0) + 1;
      }
    }
    return counts;
  }

  Widget _filterChips(BuildContext context, List<Tag> tags, Tag? activeLabel) {
    final l = context.l10n;
    Widget chip(BoardFilter f, String label) => FilterChip(
      label: Text(label),
      selected: _filters.contains(f),
      onSelected: (v) => setState(() => v ? _filters.add(f) : _filters.remove(f)),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
      child: Row(
        children: [
          chip(BoardFilter.waitingOrBlocked, l.listsFilterHasBlocked),
          const SizedBox(width: Space.sm),
          chip(BoardFilter.attachments, l.listsFilterHasAttachments),
          const SizedBox(width: Space.sm),
          chip(BoardFilter.dueDates, l.listsFilterHasDue),
          const SizedBox(width: Space.sm),
          chip(BoardFilter.repeating, l.listsFilterRepeating),
          const SizedBox(width: Space.sm),
          chip(BoardFilter.pinned, l.listsFilterPinned),
          const SizedBox(width: Space.sm),
          ActionChip(
            avatar: _color == null ? const Icon(Icons.palette_outlined, size: 18) : ColorDot(Color(_color!), size: 14),
            label: Text(l.listsFilterColor),
            onPressed: () async {
              final c = await pickColor(context, selected: _color, allowNone: true);
              if (c != null) setState(() => _color = c == -1 ? null : c);
            },
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(width: Space.sm),
            ActionChip(
              avatar: activeLabel == null
                  ? const Icon(Icons.label_outline, size: 18)
                  : ColorDot(tagColor(context, activeLabel), size: 12),
              label: Text(activeLabel?.name ?? l.listsFilterLabel),
              onPressed: () async {
                final picked = await _pickLabel(context, tags);
                if (picked != null) setState(() => _labelId = picked.isEmpty ? null : picked);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Single-label picker for the search chips: a tag id, '' for "any label", null when dismissed.
  Future<String?> _pickLabel(BuildContext context, List<Tag> tags) => showAppSheet<String>(
    context,
    title: context.l10n.listsFilterLabel,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.label_off_outlined),
          title: Text(ctx.l10n.listsFilterAnyLabel),
          selected: _labelId == null,
          onTap: () => Navigator.pop(ctx, ''),
        ),
        for (final t in tags)
          ListTile(
            leading: ColorDot(tagColor(ctx, t), size: 12),
            title: Text(t.name),
            selected: _labelId == t.id,
            onTap: () => Navigator.pop(ctx, t.id),
          ),
        const SizedBox(height: Space.md),
      ],
    ),
  );

  Widget _section(
    List<Checklist> cards,
    Map<String, CardSummary> summaries,
    Map<String, Attachment> thumbs,
    Map<String, List<Tag>> labels,
    BoardConfig config,
    bool canDrag,
  ) {
    Widget card(int i) => _BoardCard(
      key: ValueKey(cards[i].id),
      checklist: cards[i],
      summary: summaries[cards[i].id] ?? CardSummary.empty,
      thumbnail: thumbs[cards[i].id],
      labels: labels[cards[i].id] ?? const [],
      config: config,
      siblings: cards,
      index: i,
      draggable: canDrag,
    );
    final padding = const EdgeInsetsDirectional.symmetric(horizontal: Space.md);
    if (config.layout == BoardLayout.list) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
          itemBuilder: (_, i) => card(i),
        ),
      );
    }
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100 ? 4 : (width >= 700 ? 3 : 2);
    return SliverPadding(
      padding: padding,
      sliver: SliverMasonryGrid.count(
        crossAxisCount: columns,
        mainAxisSpacing: Space.sm,
        crossAxisSpacing: Space.sm,
        childCount: cards.length,
        itemBuilder: (_, i) => card(i),
      ),
    );
  }
}

class _SmartChips extends StatelessWidget {
  const _SmartChips({required this.counts});

  final SmartCounts counts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String label(SmartKind k) => switch (k) {
      SmartKind.waiting => l.smartWaiting,
      SmartKind.blocked => l.smartBlocked,
      SmartKind.ongoing => l.smartOngoing,
      SmartKind.followUps => l.smartFollowUps,
    };
    IconData icon(SmartKind k) => switch (k) {
      SmartKind.waiting => Icons.schedule,
      SmartKind.blocked => Icons.block,
      SmartKind.ongoing => Icons.play_circle_outline,
      SmartKind.followUps => Icons.notifications_active_outlined,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
      child: Row(
        children: [
          for (final k in SmartKind.values)
            if (counts.of(k) > 0)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: Space.sm),
                child: ActionChip(
                  avatar: Icon(icon(k), size: 18),
                  label: Text(l.smartChip(label(k), counts.of(k))),
                  onPressed: () => openSmartList(context, k.routeName),
                ),
              ),
        ],
      ),
    );
  }
}

class _ItemHits extends StatelessWidget {
  const _ItemHits({required this.result});

  final BoardSearchResult result;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHeader(context.l10n.listsSearchItems),
      for (final hit in result.items.take(30))
        ListTile(
          dense: true,
          leading: const Icon(Icons.subdirectory_arrow_right),
          title: Text(hit.text, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [hit.checklistTitle.isEmpty ? context.l10n.listsUntitled : hit.checklistTitle, ...hit.path].join(' › '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => openChecklist(context, hit.checklistId, itemId: hit.itemId),
        ),
    ],
  );
}

/// A card with drag-to-reorder (long-press lifts, drop places before the target) and a menu.
class _BoardCard extends ConsumerWidget {
  const _BoardCard({
    required this.checklist,
    required this.summary,
    required this.thumbnail,
    required this.config,
    required this.siblings,
    required this.index,
    required this.draggable,
    super.key,
    this.labels = const [],
  });

  final Checklist checklist;
  final CardSummary summary;
  final Attachment? thumbnail;
  final List<Tag> labels;
  final BoardConfig config;
  final List<Checklist> siblings;
  final int index;
  final bool draggable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ChecklistCard(
      checklist: checklist,
      summary: summary,
      thumbnail: thumbnail,
      labels: labels,
      showBody: config.showBody,
      maxRows: config.rowsPerCard,
      hasReminders: ref.watch(ownReminderTargetsProvider.select((s) => s.contains(checklist.id))),
      onTap: () => openChecklist(context, checklist.id),
      onMenu: () => showCardMenu(context, ref, checklist),
    );
    if (!draggable) return card;
    return LayoutBuilder(
      builder: (context, constraints) => DragTarget<String>(
        onWillAcceptWithDetails: (d) {
          final ok = d.data != checklist.id && siblings.any((c) => c.id == d.data);
          if (ok) unawaited(HapticFeedback.selectionClick());
          return ok;
        },
        onAcceptWithDetails: (d) {
          final list = [...siblings]..removeWhere((c) => c.id == d.data);
          final target = list.indexWhere((c) => c.id == checklist.id);
          final before = target > 0 ? list[target - 1].sortKey : null;
          unawaited(
            ref.read(checklistsRepositoryProvider).move(d.data, afterKey: before, beforeKey: checklist.sortKey),
          );
        },
        builder: (context, candidates, _) => LongPressDraggable<String>(
          data: checklist.id,
          hapticFeedbackOnStart: true,
          onDragStarted: () => unawaited(HapticFeedback.mediumImpact()),
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(Radii.md),
            child: SizedBox(width: constraints.maxWidth, child: card),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: card),
          child: AnimatedContainer(
            duration: Motion.fast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: candidates.isEmpty ? Colors.transparent : context.colors.primary, width: 2),
            ),
            child: card,
          ),
        ),
      ),
    );
  }
}

/// Card context menu (T4.1.10): pin, color, archive, duplicate, delete — all undoable.
Future<void> showCardMenu(BuildContext context, WidgetRef ref, Checklist c) async {
  final l = context.l10n;
  final action = await showAppSheet<String>(
    context,
    title: c.title.isEmpty ? l.listsUntitled : c.title,
    builder: (ctx) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(c.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            title: Text(c.isPinned ? l.listsUnpin : l.listsPin),
            onTap: () => Navigator.pop(ctx, 'pin'),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.listsColor),
            onTap: () => Navigator.pop(ctx, 'color'),
          ),
          ListTile(
            leading: Icon(c.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
            title: Text(c.isArchived ? l.listsUnarchive : l.listsArchiveAction),
            onTap: () => Navigator.pop(ctx, 'archive'),
          ),
          ListTile(
            leading: const Icon(Icons.copy_all_outlined),
            title: Text(l.listsDuplicate),
            onTap: () => Navigator.pop(ctx, 'dup'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: ctx.colors.error),
            title: Text(l.listsDelete),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  final repo = ref.read(checklistsRepositoryProvider);
  switch (action) {
    case 'pin':
      final r = await repo.setPinned(c.id, pinned: !c.isPinned);
      if (context.mounted) showUndoSnackBar(context, ref, message: l.savedSnack, record: r);
    case 'color':
      final color = await pickColor(context, selected: c.color, allowNone: true);
      if (color == null) return;
      final r = await repo.update(c.id, color: color == -1 ? null : color, clearColor: color == -1);
      if (context.mounted) showUndoSnackBar(context, ref, message: l.savedSnack, record: r);
    case 'archive':
      final r = await repo.setArchived(c.id, archived: !c.isArchived);
      if (context.mounted) {
        showUndoSnackBar(context, ref, message: c.isArchived ? l.listsUnarchived : l.listsArchived, record: r);
      }
    case 'dup':
      await duplicateChecklistFlow(context, ref, c);
    case 'delete':
      final r = await repo.delete(c.id);
      if (context.mounted) showUndoSnackBar(context, ref, message: l.listsDeleted, record: r);
  }
}

/// Duplicate with the "reset statuses" option (T4.1.14).
Future<void> duplicateChecklistFlow(BuildContext context, WidgetRef ref, Checklist c, {bool open = false}) async {
  final l = context.l10n;
  var reset = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l.listsDuplicate),
        content: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: reset,
          title: Text(l.listsResetStatusesOption),
          onChanged: (v) => setState(() => reset = v ?? false),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.actionCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.listsDuplicate)),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  final title = l.listsCopyOf(c.title.isEmpty ? l.listsUntitled : c.title);
  final created = await ref.read(checklistsRepositoryProvider).duplicate(c.id, title: title, resetStatuses: reset);
  if (!context.mounted) return;
  showUndoSnackBar(context, ref, message: l.listsDuplicated, record: created.record);
  if (open) await openChecklist(context, created.id);
}

/// Creates a list with [nodes] and opens it (templates, imports).
Future<void> createListAndOpen(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required List<NodeSpec> nodes,
  String? templateId,
}) async {
  final created = await ref
      .read(checklistsRepositoryProvider)
      .create(title: title, items: nodes, templateId: templateId);
  if (context.mounted) await openChecklist(context, created.id);
}

/// Keep-style label drawer (T4.1.12): every label with its number of lists; tapping one filters
/// the board, "Edit labels" opens the shared tag management (rename, merge, delete — [2.3]).
class _LabelsDrawer extends StatelessWidget {
  const _LabelsDrawer({required this.tags, required this.counts, required this.selected, required this.onSelected});

  final List<Tag> tags;
  final Map<String, int> counts;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void pick(String? id) {
      Navigator.of(context).pop();
      onSelected(id);
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.symmetric(vertical: Space.sm),
          children: [
            ListTile(
              leading: const Icon(Icons.checklist_rtl),
              title: Text(l.listsAllLists),
              selected: selected == null,
              onTap: () => pick(null),
            ),
            SectionHeader(l.checklistLabels),
            if (tags.isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg, vertical: Space.sm),
                child: Text(
                  l.listsNoLabels,
                  style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
            for (final t in tags)
              Semantics(
                label: l.listsLabelSemantics(t.name, counts[t.id] ?? 0),
                selected: selected == t.id,
                button: true,
                excludeSemantics: true,
                child: ListTile(
                  leading: Icon(Icons.label_outline, color: tagColor(context, t)),
                  title: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text('${counts[t.id] ?? 0}', style: context.text.labelLarge),
                  selected: selected == t.id,
                  onTap: () => pick(t.id),
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l.listsEditLabels),
              onTap: () {
                Navigator.of(context).pop();
                unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TagsScreen())));
              },
            ),
          ],
        ),
      ),
    );
  }
}
