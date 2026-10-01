import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart' show Attachment, AttachmentOwnerType;
import 'package:everslot/features/attachments/presentation/attachment_ui.dart';
import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/application/checklist_service.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/application/reset_service.dart';
import 'package:everslot/features/checklists/application/swipe_actions.dart';
import 'package:everslot/features/checklists/application/task_links.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/drop_target.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/domain/reset.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:everslot/features/checklists/domain/status_engine.dart';
import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:everslot/features/checklists/presentation/archive_templates_screens.dart';
import 'package:everslot/features/checklists/presentation/checklist_header.dart';
import 'package:everslot/features/checklists/presentation/checklist_navigation.dart';
import 'package:everslot/features/checklists/presentation/checklist_pane_scope.dart';
import 'package:everslot/features/checklists/presentation/checklist_settings_sheet.dart';
import 'package:everslot/features/checklists/presentation/checklist_toolbars.dart';
import 'package:everslot/features/checklists/presentation/checklist_views.dart';
import 'package:everslot/features/checklists/presentation/import_export_ui.dart';
import 'package:everslot/features/checklists/presentation/item_details_sheet.dart';
import 'package:everslot/features/checklists/presentation/item_row.dart';
import 'package:everslot/features/checklists/presentation/lists_board_screen.dart' show duplicateChecklistFlow;
import 'package:everslot/features/checklists/presentation/mind_map_view.dart';
import 'package:everslot/features/checklists/presentation/move_to_sheet.dart';
import 'package:everslot/features/checklists/presentation/split_checklists_screen.dart';
import 'package:everslot/features/checklists/presentation/status_sheet.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/presentation/tag_widgets.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The screen hosting one checklist (T4.2.07): Edit ⇄ Preview outline, kanban and gallery views,
/// focus (zoom) mode with breadcrumbs, drag & drop, keyboard toolbar, selection mode and the list
/// commands. The router's `/lists/:id` route also serves `/lists/archive` and `/lists/templates`.
class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({required this.checklistId, this.focusItemId, this.preview = false, super.key});

  final String checklistId;

  /// Item to open: it becomes the focus root when it has sub-items, otherwise it is shown and
  /// highlighted inside its parent (search hits, smart views, notifications).
  final String? focusItemId;
  final bool preview;

  @override
  Widget build(BuildContext context) => switch (checklistId) {
    'archive' => const ArchiveScreen(),
    'templates' => const TemplatesScreen(),
    _ => _ChecklistPage(checklistId: checklistId, focusItemId: focusItemId, preview: preview),
  };
}

class _ChecklistPage extends ConsumerStatefulWidget {
  const _ChecklistPage({required this.checklistId, required this.focusItemId, required this.preview});

  final String checklistId;
  final String? focusItemId;
  final bool preview;

  @override
  ConsumerState<_ChecklistPage> createState() => _ChecklistPageState();
}

typedef _CachedRow = ({VisibleRow row, RowContext ctx, ItemRow widget});

class _ChecklistPageState extends ConsumerState<_ChecklistPage> implements RowActions {
  final _scroll = ScrollController();
  final _listKey = GlobalKey();
  final Map<String, BuildContext> _rowContexts = {};
  final Map<String, _CachedRow> _rowCache = {};
  Map<String, int> _indexOf = const {};
  List<VisibleRow> _shown = const [];
  late final ChecklistService _service;
  ChecklistEditor? _editorRef;
  PendingCard? _pending;
  Future<void>? _creating;
  bool _initialScrollDone = false;
  bool _routeFocusDone = false;
  bool? _wasComplete;
  int _lastJump = -1;
  String? _lastToggled;
  Timer? _highlightTimer;
  _DragSession? _drag;

  @override
  String get checklistId => widget.checklistId;

  ChecklistEditor get _editor => ref.read(checklistEditorProvider(checklistId).notifier);
  EditorState get _state => ref.read(checklistEditorProvider(checklistId));
  ChecklistTree? get _tree => ref.read(checklistTreeProvider(checklistId));
  Checklist? get _checklist => ref.read(checklistProvider(checklistId)).value;
  ChecklistSettings get _settings => _checklist?.settings ?? ChecklistSettings.defaults;

  @override
  void initState() {
    super.initState();
    _service = ref.read(checklistServiceProvider);
    final pending = ref.read(pendingCardProvider);
    if (pending != null && pending.id == widget.checklistId) _pending = pending;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_init()));
  }

  Future<void> _init() async {
    if (!mounted) return;
    if (_pending != null) ref.read(pendingCardProvider.notifier).set(null);
    final editor = _editor;
    _editorRef = editor;
    await editor.init(preview: widget.preview, focusItemId: widget.focusItemId, forceEdit: _pending != null);
    if (!mounted) return;
    // Due resets run before the list is used (T4.5.06).
    unawaited(ref.read(checklistResetServiceProvider).runDue(onlyChecklistId: checklistId));
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _clearDrag(rebuild: false);
    _scroll.dispose();
    if (_pending != null) {
      // A new card left completely empty is discarded (T4.1.09); drafts are written first.
      final editor = _editorRef;
      final service = _service;
      final id = checklistId;
      unawaited(() async {
        try {
          await editor?.flushForClose();
        } on Object {
          // The editor may already be gone; the check below reads the database anyway.
        }
        await service.discardIfEmpty(id);
      }());
    }
    super.dispose();
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(checklistEditorProvider(checklistId));
    final checklistValue = ref.watch(checklistProvider(checklistId));
    final checklist = checklistValue.value;
    if (checklist == null && _pending == null) {
      if (checklistValue.isLoading || (!checklistValue.hasValue && !checklistValue.hasError)) {
        return Scaffold(appBar: AppBar(), body: const LoadingState());
      }
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.search_off, title: l.checklistNotFound),
      );
    }
    if (checklist != null && checklist.isDeleted) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.delete_outline,
          title: l.checklistInTrash,
          actionLabel: l.checklistOpenTrash,
          onAction: () => openTrash(context),
        ),
      );
    }
    if (!state.ready) return Scaffold(appBar: AppBar(), body: const LoadingState());

    final tree = ref.watch(checklistTreeProvider(checklistId));
    if (tree != null) _resolveRouteFocus(tree);
    final body = switch (state.viewType) {
      ChecklistViewType.kanban => KanbanView(checklistId: checklistId, onOpenItem: openDetails),
      ChecklistViewType.gallery => GalleryView(checklistId: checklistId, onOpenItem: openDetails),
      ChecklistViewType.mindMap => MindMapView(
        checklistId: checklistId,
        onOpenItem: (id) => unawaited(_showInOutline(id)),
      ),
      ChecklistViewType.outline => _outline(context, state: state, checklist: checklist, tree: tree),
    };
    final active = state.activeItemId == null ? null : tree?[state.activeItemId!];
    final showToolbar =
        state.viewType == ChecklistViewType.outline && !state.preview && !state.selecting && active != null;
    return PopScope(
      canPop: state.focusRootId == null && !state.selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_state.selecting) {
          _editor.clearSelection();
        } else {
          unawaited(_editor.zoomOut());
        }
      },
      child: Scaffold(
        appBar: _appBar(context, state, checklist, tree),
        body: Column(
          children: [
            Expanded(child: body),
            if (showToolbar) EditToolbar(actions: _toolbarActions(context, state, active)),
            if (state.selecting && tree != null) SelectionBar(actions: _selectionActions(context, state, tree)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, EditorState state, Checklist? checklist, ChecklistTree? tree) {
    final l = context.l10n;
    if (state.selecting) {
      return AppBar(
        leading: IconButton(tooltip: l.actionClose, icon: const Icon(Icons.close), onPressed: _editor.clearSelection),
        title: Text(l.checklistSelected(state.selection.length)),
        actions: [
          IconButton(
            tooltip: l.checklistSelectAll,
            icon: const Icon(Icons.select_all),
            onPressed: () => _editor.selectAll(_shown),
          ),
        ],
      );
    }
    final outline = state.viewType == ChecklistViewType.outline;
    return AppBar(
      actions: [
        if (outline && !state.preview) ...[
          IconButton(tooltip: l.actionUndo, icon: const Icon(Icons.undo), onPressed: state.canUndo ? undo : null),
          IconButton(tooltip: l.actionRedo, icon: const Icon(Icons.redo), onPressed: state.canRedo ? redo : null),
        ],
        if (outline && checklist != null)
          IconButton(
            tooltip: state.preview ? l.checklistModeEdit : l.checklistModePreview,
            icon: Icon(state.preview ? Icons.edit_outlined : Icons.fact_check_outlined),
            onPressed: () => _editor.setPreview(!state.preview),
          ),
        if (checklist != null) _viewMenu(context, state),
        if (checklist != null) _overflowMenu(context, state, checklist, tree),
      ],
    );
  }

  Widget _viewMenu(BuildContext context, EditorState state) {
    final l = context.l10n;
    IconData icon(ChecklistViewType t) => switch (t) {
      ChecklistViewType.outline => Icons.format_list_bulleted,
      ChecklistViewType.kanban => Icons.view_kanban_outlined,
      ChecklistViewType.gallery => Icons.photo_library_outlined,
      ChecklistViewType.mindMap => Icons.account_tree_outlined,
    };
    String label(ChecklistViewType t) => switch (t) {
      ChecklistViewType.outline => l.checklistViewOutline,
      ChecklistViewType.kanban => l.checklistViewKanban,
      ChecklistViewType.gallery => l.checklistViewGallery,
      ChecklistViewType.mindMap => l.checklistViewMindMap,
    };
    return PopupMenuButton<ChecklistViewType>(
      tooltip: label(state.viewType),
      icon: Icon(icon(state.viewType)),
      initialValue: state.viewType,
      onSelected: (t) => unawaited(_editor.setViewType(t)),
      itemBuilder: (_) => [
        for (final t in ChecklistViewType.values)
          PopupMenuItem(
            value: t,
            child: Row(
              children: [
                Icon(icon(t)),
                const SizedBox(width: Space.md),
                Text(label(t)),
              ],
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ outline

  Widget _outline(
    BuildContext context, {
    required EditorState state,
    required Checklist? checklist,
    required ChecklistTree? tree,
  }) {
    final l = context.l10n;
    final rows = ref.watch(visibleRowsProvider(checklistId));
    final rollups = ref.watch(checklistRollupsProvider(checklistId));
    final counts = ref.watch(itemAttachmentCountsProvider(checklistId)).value ?? const <String, int>{};
    final settings = checklist?.settings ?? ChecklistSettings.defaults;
    final focusRoot = tree != null && tree.contains(state.focusRootId) ? state.focusRootId : null;
    final shown = _whileDragging(rows, tree);
    _shown = shown;
    _indexOf = {for (var i = 0; i < shown.length; i++) shown[i].id: i};
    if (_rowCache.length > shown.length * 2 + 200) {
      _rowCache.removeWhere((id, _) => !_indexOf.containsKey(id));
    }
    final clock = ref.read(clockProvider).nowUtc();
    final now = DateTime.utc(clock.year, clock.month, clock.day, clock.hour, clock.minute);
    final zone = ref.watch(deviceZoneProvider);
    LocalDateTime nowLocal;
    try {
      nowLocal = ref.read(zoneResolverProvider).toLocal(now, zone);
    } on Object {
      nowLocal = LocalDateTime.fromDateTime(now);
    }
    final env = _RowEnv(
      tree: tree,
      rollups: rollups,
      counts: counts,
      reminders: ref.watch(ownReminderTargetsProvider),
      settings: settings,
      state: state,
      now: now,
      nowLocal: nowLocal,
    );
    final rootRollup = tree == null ? Rollup.zero : RollupCalculator.root(tree, rollups, focusRootId: focusRoot);
    final complete = tree != null && !tree.isEmpty && focusRoot == null && rootRollup.isComplete(settings.progressMode);
    _celebrate(complete);
    _restoreScroll(state, tree);
    return NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        if (_scroll.hasClients && _drag == null) _editor.saveScroll(_scroll.offset);
        return false;
      },
      child: CustomScrollView(
        key: _listKey,
        controller: _scroll,
        slivers: [
          if (focusRoot == null)
            SliverToBoxAdapter(
              child: ChecklistTitleBody(
                checklistId: checklistId,
                checklist: checklist,
                preview: state.preview,
                pending: _pending,
                create: (title, body) => _ensureCreated(title: title, body: body),
                onTitleSubmitted: _titleSubmitted,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Breadcrumbs(
                tree: tree!,
                focusRootId: focusRoot,
                rootTitle: listTitle(context, checklist),
                onTap: (id) => unawaited(_editor.zoomTo(id)),
              ),
            ),
            SliverToBoxAdapter(
              child: FocusedItemHeader(item: tree[focusRoot]!, onTap: () => openDetails(tree[focusRoot]!)),
            ),
          ],
          if (focusRoot == null && checklist != null)
            SliverToBoxAdapter(
              child: _HeaderExtras(
                checklist: checklist,
                preview: state.preview,
                onRepeat: () => showChecklistSettings(context, checklistId: checklistId),
              ),
            ),
          if (!settings.hideCheckboxes && tree != null)
            SliverToBoxAdapter(
              child: ProgressHeader(
                rollup: rootRollup,
                mode: settings.progressMode,
                doneThisWeek: _doneThisWeek(tree, nowLocal, zone),
                onInsights: () => openRoute(context, AppLinks.insightsScope('checklist', checklistId)),
              ),
            ),
          if (state.preview)
            SliverToBoxAdapter(
              child: PreviewControls(checklistId: checklistId, onNextOpen: _nextOpen),
            ),
          SliverToBoxAdapter(
            child: ViewBanner(state: state, onReset: _resetView),
          ),
          if (complete && !settings.hideCheckboxes)
            SliverToBoxAdapter(
              child: CompletedBanner(
                key: ValueKey('done-$checklistId'),
                onReset: () => unawaited(_resetCompleted()),
                onArchive: () => unawaited(_archive(checklist)),
              ),
            ),
          if (tree == null)
            const SliverToBoxAdapter(child: LoadingState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _row(shown[i], env),
                childCount: shown.length,
                findChildIndexCallback: (key) => key is ValueKey<String> ? _indexOf[key.value] : null,
              ),
            ),
          if (!state.preview && !state.selecting)
            SliverToBoxAdapter(child: AddItemRow(onTap: () => unawaited(_addItem()))),
          if (state.preview && tree != null && shown.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.checklist,
                title: focusRoot == null ? l.checklistNoItems : l.checklistEmptyFocus,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  List<VisibleRow> _whileDragging(List<VisibleRow> rows, ChecklistTree? tree) {
    final d = _drag;
    if (d == null || tree == null) return rows;
    return [
      for (final r in rows)
        if (!tree.isDescendant(r.id, d.id)) r,
    ];
  }

  /// Rows are memoized: an unchanged `(row, context)` reuses the same widget instance, so a
  /// single-row edit never rebuilds the other rows (T4.2.08 / T4.2.19).
  Widget _row(VisibleRow row, _RowEnv env) {
    final tree = env.tree!;
    final item = row.item;
    final siblings = tree.siblingsOf(row.id);
    final due = item.dueLocal;
    final state = env.state;
    final ctx = RowContext(
      preview: state.preview,
      hideCheckboxes: env.settings.hideCheckboxes,
      showNotes: env.settings.showNotesInPreview,
      showAttachments: env.settings.showAttachmentsInPreview,
      siblingIndex: siblings.indexOf(row.id),
      siblingCount: siblings.length,
      now: env.now,
      selecting: state.selecting,
      selected: state.selection.contains(row.id),
      collapsedRollup: row.hasChildren && row.collapsed ? env.rollups[row.id] : null,
      attachmentCount: env.counts[row.id] ?? 0,
      highlighted: state.highlightId == row.id,
      canRestructure: state.canRestructure,
      staleAfterDays: env.settings.staleAfterDays,
      dueState: due == null ? null : ItemTimeRules.classifyDue(due, env.nowLocal),
      dimmed: _drag?.id == row.id,
      hasReminder: env.reminders.contains(row.id),
    );
    final cached = _rowCache[row.id];
    if (cached != null && cached.row == row && cached.ctx == ctx) return cached.widget;
    final widget = ItemRow(key: ValueKey<String>(row.id), row: row, ctx: ctx, actions: this);
    _rowCache[row.id] = (row: row, ctx: ctx, widget: widget);
    return widget;
  }

  // ------------------------------------------------------------------ open / focus / scroll

  void _resolveRouteFocus(ChecklistTree tree) {
    if (_routeFocusDone) return;
    final target = widget.focusItemId;
    if (target == null) {
      _routeFocusDone = true;
      return;
    }
    if (tree.isEmpty && ref.read(checklistItemsProvider(checklistId)).isLoading) return;
    _routeFocusDone = true;
    if (!tree.contains(target)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (tree.isLeaf(target)) {
        // A leaf has nothing to zoom into: show it in its parent instead.
        await _editor.zoomTo(tree.parentOf(target));
        _editor.highlight(target);
      }
      _scrollToRow(target);
      _scheduleHighlightClear();
    });
  }

  void _restoreScroll(EditorState state, ChecklistTree? tree) {
    if (_initialScrollDone || tree == null) return;
    _initialScrollDone = true;
    final offset = state.initialScroll;
    if (offset == null || offset <= 0 || widget.focusItemId != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final p = _scroll.position;
      _scroll.jumpTo(offset.clamp(p.minScrollExtent, p.maxScrollExtent));
    });
  }

  void _scheduleHighlightClear() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _editor.clearHighlight();
    });
  }

  /// Scrolls a row into view, estimating the offset when it is not built yet.
  void _scrollToRow(String id, {bool retried = false}) {
    final ctx = _rowContexts[id];
    if (ctx != null && ctx.mounted) {
      unawaited(
        Scrollable.ensureVisible(ctx, alignment: 0.3, duration: context.reduceMotion ? Duration.zero : Motion.normal),
      );
      return;
    }
    final index = _indexOf[id];
    if (index == null || retried || !_scroll.hasClients) return;
    final p = _scroll.position;
    _scroll.jumpTo((index * RowMetrics.minHeight).clamp(p.minScrollExtent, p.maxScrollExtent));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToRow(id, retried: true);
    });
  }

  /// Mind map node tapped (T4.5.14): back to the outline with the item revealed and highlighted.
  Future<void> _showInOutline(String id) async {
    await _editor.reveal(id);
    await _editor.setViewType(ChecklistViewType.outline);
    if (!mounted) return;
    _editor.highlight(id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToRow(id);
    });
    _scheduleHighlightClear();
  }

  /// *Open side by side…* (T4.5.17): pick another list for the second pane.
  Future<void> _openSideBySide() async {
    final l = context.l10n;
    final others = [
      for (final c in ref.read(boardChecklistsProvider).value ?? const <Checklist>[])
        if (c.id != checklistId) c,
    ];
    if (others.isEmpty) {
      _info(l.checklistNoOtherLists);
      return;
    }
    final picked = await showAppSheet<String>(
      context,
      title: l.checklistPickSecondList,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.6),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in others)
              ListTile(
                leading: const Icon(Icons.checklist),
                title: Text(c.title.trim().isEmpty ? l.listsUntitled : c.title),
                onTap: () => Navigator.pop(ctx, c.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SplitChecklistsScreen(leftId: checklistId, rightId: picked),
      ),
    );
  }

  /// *Cover image…* (T4.1.17): one of the list's images (list-level or items) shown full-width on
  /// the card; *Automatic* falls back to the first image.
  Future<void> _chooseCover(Checklist c) async {
    final l = context.l10n;
    // The provider may not be watched on this screen: keep it alive until its first value.
    final keepAlive = ref.listenManual(checklistAttachmentsProvider(checklistId), (_, _) {});
    List<Attachment> all;
    try {
      all = await ref.read(checklistAttachmentsProvider(checklistId).future);
    } finally {
      keepAlive.close();
    }
    if (!mounted) return;
    final images = [
      for (final a in all)
        if (a.isImage) a,
    ];
    if (images.isEmpty) {
      _info(l.checklistCoverNoImages);
      return;
    }
    final picked = await showAppSheet<String>(
      context,
      title: l.checklistCover,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.6,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: Text(l.checklistCoverAuto),
                selected: c.coverAttachmentId == null,
                onTap: () => Navigator.pop(ctx, ''),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsetsDirectional.all(Space.md),
              sliver: AttachmentGrid(attachments: images, onTap: (i) => Navigator.pop(ctx, images[i].id)),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final repo = ref.read(checklistsRepositoryProvider);
    final record = picked.isEmpty
        ? await repo.update(c.id, clearCover: true)
        : await repo.update(c.id, coverAttachmentId: picked);
    if (!mounted || record.isEmpty) return;
    _editor.pushUndo('cover', record);
    _undoSnack(l.checklistCoverUpdated, record);
  }

  /// *Link to existing task…* (T4.5.12): pick a planner task; the link is stored on the task.
  Future<void> _linkExistingTask(Checklist c) async {
    final l = context.l10n;
    final picked = await showAppSheet<LinkedTask>(
      context,
      title: l.checklistLinkTaskTitle,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final tasks = ref.watch(plannerTasksForLinksProvider);
          if (tasks.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Text(l.checklistNoTasksToLink, style: ctx.text.bodyMedium),
            );
          }
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.6),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final t in tasks)
                  ListTile(
                    leading: Icon(t.linkedChecklistId == c.id ? Icons.link : Icons.event_outlined),
                    title: Text(t.title),
                    selected: t.linkedChecklistId == c.id,
                    onTap: () => Navigator.pop(ctx, t),
                  ),
              ],
            ),
          );
        },
      ),
    );
    if (picked == null || !mounted) return;
    await ref.read(checklistTaskLinksProvider).link(picked.id, c.id);
    if (!mounted) return;
    _info(l.checklistTaskLinked(picked.title));
  }

  /// Items completed since the start of the user's week (header summary, T4.5.13).
  int _doneThisWeek(ChecklistTree tree, LocalDateTime nowLocal, String zone) {
    final start = nowLocal.date.startOfWeek(ref.read(userPreferencesProvider).weekStart).atStartOfDay;
    DateTime since;
    try {
      since = ref.read(zoneResolverProvider).resolve(start, zone).utc;
    } on Object {
      since = DateTime.utc(start.year, start.month, start.day);
    }
    return ItemTimeRules.completedSince(tree.items, since);
  }

  void _celebrate(bool complete) {
    final was = _wasComplete;
    _wasComplete = complete;
    // TODO(integration): gate on the app's haptics preference once Settings exposes one (T4.3.12);
    // the platform's own haptics setting applies meanwhile.
    if (was == false && complete) unawaited(HapticFeedback.heavyImpact());
  }

  void _nextOpen() {
    final rows = _shown;
    if (rows.isEmpty) return;
    for (var k = 1; k <= rows.length; k++) {
      final i = (_lastJump + k) % rows.length;
      final r = rows[i];
      if (r.item.status.isOpen && !r.isContext) {
        _lastJump = i;
        _editor.highlight(r.id);
        _scrollToRow(r.id);
        _scheduleHighlightClear();
        return;
      }
    }
  }

  Future<void> _resetView() async {
    await _editor.setFilter(ItemFilter.none);
    await _editor.setSort(ItemSort.manual);
  }

  // ------------------------------------------------------------------ creation (T4.1.09)

  Future<void> _ensureCreated({String title = '', String body = ''}) {
    if (_checklist != null) return Future<void>.value();
    return _creating ??= ref
        .read(checklistsRepositoryProvider)
        .create(id: checklistId, title: title, body: body)
        .then((_) {});
  }

  Future<void> _addItem() async {
    await _ensureCreated();
    if (!mounted) return;
    await _editor.addItem();
  }

  /// Enter on the title of a checklist moves to the first item (notes go to the body).
  bool _titleSubmitted() {
    if (_pending?.note ?? false) return false;
    final c = _checklist;
    final tree = _tree;
    if (c != null && c.hasBody && (tree?.isEmpty ?? true)) return false;
    final first = _shown.isEmpty ? null : _shown.first;
    if (first != null) {
      _editor.requestFocus(first.id, cursor: 0);
    } else {
      unawaited(_addItem());
    }
    return true;
  }

  // ------------------------------------------------------------------ feedback

  /// Undo snackbar for destructive / bulk / cascading changes (T4.2.14). It pops the editor's
  /// stack when the record is still on top, and keeps working after the screen closed.
  void _undoSnack(String message, OpRecord record) {
    if (record.isEmpty || !mounted) return;
    final editor = _editor;
    final writer = ref.read(syncWriterProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: context.l10n.actionUndo,
            onPressed: () {
              if (mounted) {
                unawaited(editor.undoRecord(record));
              } else {
                unawaited(writer.revert(record));
              }
            },
          ),
        ),
      );
  }

  void _info(String message) {
    if (mounted) showInfoSnackBar(context, message);
  }

  static int _itemRows(OpRecord record) => {
    for (final c in record.changes)
      if (c.table == 'checklist_items') c.id,
  }.length;

  void _statusFeedback(ItemStatus to, OpRecord record, {bool snack = false}) {
    if (!mounted) return;
    if (to == ItemStatus.completed) unawaited(HapticFeedback.mediumImpact());
    final message = context.l10n.statusMarked(StatusStyle.label(context, to));
    announce(context, message);
    if (snack || _itemRows(record) > 1) _undoSnack(message, record);
  }

  Future<void> _structure(Future<OpRecord?> Function() op) async {
    if (!_state.canRestructure) {
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    final record = await op();
    // Nothing moved (first sibling, root level…): "denied" haptic.
    unawaited(record == null ? HapticFeedback.heavyImpact() : HapticFeedback.selectionClick());
  }

  // ------------------------------------------------------------------ RowActions

  @override
  void toggleCollapse(String id) => unawaited(_editor.toggleCollapse(id));

  @override
  void setSubtreeCollapsed(String id, {required bool collapsed}) =>
      unawaited(_editor.setSubtreeCollapsed(id, collapsed: collapsed));

  @override
  void toggleComplete(String id) => unawaited(_toggleComplete(id));

  Future<void> _toggleComplete(String id, {bool snack = false}) async {
    final item = _tree?[id];
    if (item == null) return;
    final to = item.status == ItemStatus.completed ? ItemStatus.todo : ItemStatus.completed;
    final record = await _editor.toggleComplete(id, ask: (n) => askCompleteDescendants(context, n));
    if (record != null) _statusFeedback(to, record, snack: snack);
  }

  @override
  void openStatusSheet(ChecklistItem item) => unawaited(_statusSheet(item));

  Future<void> _statusSheet(ChecklistItem item) async {
    final settings = _settings;
    final choice = await showStatusSheet(context, ref, item: item, settings: settings);
    if (choice == null || !mounted) return;
    bool? cascade;
    final tree = _tree;
    if (choice.status == ItemStatus.completed &&
        item.status != ItemStatus.completed &&
        settings.completeChildrenWithParent == CascadeChoice.ask &&
        tree != null &&
        tree.contains(item.id)) {
      final open = StatusEngine.openDescendantCount(tree, item.id);
      if (open > 0) {
        cascade = await askCompleteDescendants(context, open);
        if (cascade == null) return;
      }
    }
    final record = await _editor.setStatus(
      [item.id],
      choice.status,
      note: choice.note,
      setNote: choice.setNote,
      followUpAt: choice.followUpAt,
      keepFollowUp: choice.keepFollowUp,
      completeOpenDescendants: cascade,
    );
    if (record != null) _statusFeedback(choice.status, record);
  }

  @override
  void openDetails(ChecklistItem item) => unawaited(_details(item));

  Future<void> _details(ChecklistItem item) async {
    final action = await showItemDetails(context, checklistId: checklistId, itemId: item.id);
    if (action == null || !mounted) return;
    switch (action) {
      case DetailsAction.focus:
        await _editor.zoomTo(item.id);
      case DetailsAction.duplicate:
        await _duplicate([item.id]);
      case DetailsAction.moveTo:
        await _moveTo([item.id]);
      case DetailsAction.promote:
        await _promote(item.id);
      case DetailsAction.delete:
        await _delete([item.id]);
      case DetailsAction.insights:
        // The Insights routes name checklist items `item` (InsightsRoute.item).
        openRoute(context, AppLinks.insightsScope('item', item.id));
    }
  }

  @override
  void openMenu(ChecklistItem item) => unawaited(_rowMenu(item));

  Future<void> _rowMenu(ChecklistItem item) async {
    final l = context.l10n;
    final clip = ref.read(checklistClipboardProvider);
    final state = _state;
    Widget tile(BuildContext ctx, IconData icon, String label, String value, {bool danger = false}) => ListTile(
      leading: Icon(icon, color: danger ? ctx.colors.error : null),
      title: Text(label),
      onTap: () => Navigator.pop(ctx, value),
    );
    final action = await showAppSheet<String>(
      context,
      title: item.text.isEmpty ? l.checklistItemHint : item.text,
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile(ctx, Icons.flag_outlined, l.statusChange, 'status'),
              tile(ctx, Icons.info_outline, l.checklistDetails, 'details'),
              tile(ctx, Icons.center_focus_strong, l.checklistFocus, 'focus'),
              if (!state.preview) tile(ctx, Icons.subdirectory_arrow_right, l.checklistAddSubItem, 'child'),
              tile(ctx, Icons.attach_file, l.checklistAttach, 'attach'),
              if (state.canRestructure) ...[
                tile(ctx, Icons.format_indent_increase, l.checklistIndent, 'indent'),
                tile(ctx, Icons.format_indent_decrease, l.checklistOutdent, 'outdent'),
                tile(ctx, Icons.arrow_upward, l.checklistMoveUp, 'up'),
                tile(ctx, Icons.arrow_downward, l.checklistMoveDown, 'down'),
              ],
              tile(ctx, Icons.drive_file_move_outline, l.checklistMoveTo, 'moveTo'),
              tile(ctx, Icons.copy_all_outlined, l.checklistDuplicateItem, 'duplicate'),
              tile(ctx, Icons.content_copy, l.checklistCopy, 'copy'),
              tile(ctx, Icons.content_cut, l.checklistCut, 'cut'),
              if (clip != null) tile(ctx, Icons.content_paste, l.checklistPasteHere, 'paste'),
              tile(ctx, Icons.checklist, l.checklistSelect, 'select'),
              tile(ctx, Icons.upgrade, l.checklistPromote, 'promote'),
              tile(ctx, Icons.delete_outline, l.checklistDeleteItem, 'delete', danger: true),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;
    final tree = _tree;
    switch (action) {
      case 'status':
        await _statusSheet(item);
      case 'details':
        await _details(item);
      case 'focus':
        await _editor.zoomTo(item.id);
      case 'child':
        await _editor.addChild(item.id);
      case 'attach':
        await _attach(item.id);
      case 'indent':
        await _structure(() => _editor.indent([item.id]));
      case 'outdent':
        await _structure(() => _editor.outdent([item.id]));
      case 'up':
        await _structure(() => _editor.moveUp([item.id]));
      case 'down':
        await _structure(() => _editor.moveDown([item.id]));
      case 'moveTo':
        await _moveTo([item.id]);
      case 'duplicate':
        await _duplicate([item.id]);
      case 'copy' || 'cut':
        if (tree == null) return;
        await _copy(tree, [item.id], cut: action == 'cut');
      case 'paste':
        final content = ref.read(checklistClipboardProvider);
        if (content == null) return;
        final record = await _editor.paste(content, afterId: item.id);
        if (record != null && mounted) _undoSnack(context.l10n.checklistPaste, record);
      case 'select':
        _lastToggled = item.id;
        _editor.startSelection(item.id);
      case 'promote':
        await _promote(item.id);
      case 'delete':
        await _delete([item.id]);
    }
  }

  @override
  void zoom(String id) => unawaited(_editor.zoomTo(id));

  @override
  void toggleSelected(String id) {
    _lastToggled = id;
    _editor.toggleSelected(id);
  }

  @override
  void selectRangeTo(String id) {
    _editor.selectRange(_shown, _lastToggled ?? id, id);
    _lastToggled = id;
  }

  @override
  void enter(String id, String text, int cursor) => unawaited(_editor.enter(id, text: text, cursor: cursor));

  @override
  void backspaceAtStart(String id, String text) {
    final i = _indexOf[id] ?? -1;
    final previous = i > 0 ? _shown[i - 1].id : null;
    unawaited(_editor.backspaceAtStart(id, text: text, previousVisibleId: previous));
  }

  @override
  Future<bool> multilinePaste(String id, String pasted) =>
      handleMultilinePaste(context, ref, checklistId: checklistId, itemId: id, pasted: pasted);

  @override
  void focusNeighbor(String id, int direction) {
    final i = _indexOf[id];
    if (i == null) return;
    final j = i + direction;
    if (j < 0 || j >= _shown.length) return;
    _editor.requestFocus(_shown[j].id, cursor: direction < 0 ? null : 0);
  }

  @override
  void indent(String id) => unawaited(_structure(() => _editor.indent([id])));

  @override
  void outdent(String id) => unawaited(_structure(() => _editor.outdent([id])));

  @override
  void moveUp(String id) => unawaited(_structure(() => _editor.moveUp([id])));

  @override
  void moveDown(String id) => unawaited(_structure(() => _editor.moveDown([id])));

  @override
  void undo() => unawaited(_runUndo(redo: false));

  @override
  void redo() => unawaited(_runUndo(redo: true));

  Future<void> _runUndo({required bool redo}) async {
    final done = redo ? await _editor.redo() : await _editor.undo();
    if (done && mounted) announce(context, redo ? context.l10n.actionRedo : context.l10n.actionUndo);
  }

  @override
  void swipe(ChecklistItem item, {required bool towardEnd}) {
    final action = ref.read(swipeActionsProvider).resolve(preview: _state.preview, towardEnd: towardEnd);
    switch (action) {
      case SwipeAction.indent:
        indent(item.id);
      case SwipeAction.outdent:
        outdent(item.id);
      case SwipeAction.complete:
        unawaited(_toggleComplete(item.id, snack: true));
      case SwipeAction.menu:
        openMenu(item);
      case SwipeAction.none:
        break;
    }
  }

  @override
  void registerRow(String id, BuildContext? context) {
    if (context != null) {
      _rowContexts[id] = context;
      return;
    }
    final existing = _rowContexts[id];
    if (existing != null && !existing.mounted) _rowContexts.remove(id);
  }

  // ------------------------------------------------------------------ commands

  Future<void> _attach(String itemId) async {
    await _ensureCreated();
    if (!mounted) return;
    final result = await pickAndAddAttachments(
      context,
      ref,
      ownerType: AttachmentOwnerType.checklistItem,
      ownerId: itemId,
    );
    final record = result?.record;
    if (record != null) _editor.pushUndo('attach', record);
  }

  Future<void> _pickDue(ChecklistItem item) async {
    final prefs = ref.read(userPreferencesProvider);
    final date = await pickDate(context, initial: item.dueLocal?.date);
    if (date == null || !mounted) return;
    final time = await pickTime(context, initial: item.dueLocal?.time ?? LocalTime(9, 0), use24h: prefs.use24h);
    await _editor.setFields(item.id, {'due_local': date.atTime(time ?? LocalTime.midnight)}, label: 'due');
  }

  Future<void> _duplicate(List<String> ids) async {
    final record = await _editor.duplicate(ids);
    if (record != null && mounted) _undoSnack(context.l10n.checklistItemsDuplicated(_itemRows(record)), record);
  }

  Future<void> _moveTo(List<String> ids) async {
    final target = await showMoveToSheet(context, ref, sourceChecklistId: checklistId, movingIds: ids);
    if (target == null || !mounted) return;
    final record = await _editor.moveToChecklist(
      ids,
      targetChecklistId: target.checklistId,
      targetParentId: target.parentId,
    );
    if (record != null && mounted) {
      _editor.clearSelection();
      _undoSnack(context.l10n.moveDone(target.title), record);
    }
  }

  Future<void> _promote(String itemId) async {
    final newId = await _editor.promote(itemId);
    if (newId == null || !mounted) return;
    final l = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.checklistPromoted),
          action: SnackBarAction(
            label: l.actionOpen,
            onPressed: () {
              if (mounted) unawaited(openChecklist(context, newId));
            },
          ),
        ),
      );
  }

  Future<void> _delete(List<String> ids) async {
    final record = await _editor.delete(ids);
    if (record != null && mounted) {
      _editor.clearSelection();
      _undoSnack(context.l10n.checklistItemsDeleted(_itemRows(record)), record);
    }
  }

  Future<void> _copy(ChecklistTree tree, List<String> ids, {required bool cut}) async {
    final clipboard = ref.read(checklistClipboardProvider.notifier);
    if (cut) {
      clipboard.cut(tree, checklistId, ids);
    } else {
      clipboard.copy(tree, checklistId, ids);
    }
    await Clipboard.setData(ClipboardData(text: ChecklistClipboard.asText(tree, ids)));
    if (!mounted) return;
    _info(context.l10n.checklistCopied);
  }

  Future<void> _bulkStatus(List<String> ids) async {
    final to = await pickStatus(context);
    if (to == null || !mounted) return;
    String? note;
    DateTime? followUp;
    final settings = _settings;
    if (to.promptsReason || settings.requiresReason(to)) {
      final reason = await showReasonSheet(context, ref, status: to, required: settings.requiresReason(to));
      if (reason == null || !mounted) return;
      note = reason.note;
      followUp = reason.followUpAt;
    }
    final record = await _editor.setStatus(
      ids,
      to,
      note: note,
      setNote: note != null,
      followUpAt: followUp,
      cause: 'bulk',
    );
    if (record != null && mounted) _undoSnack(context.l10n.checklistStatusChanged, record);
  }

  Future<void> _resetCompleted() async {
    final c = _checklist;
    if (c == null) return;
    if (c.isRecurring) {
      final record = await ref.read(checklistResetServiceProvider).resetNow(checklistId);
      if (record != null && mounted) {
        _editor.pushUndo('reset', record);
        _undoSnack(context.l10n.checklistResetDone, record);
      }
      return;
    }
    final record = await _editor.uncheckAll();
    if (record != null && mounted) _undoSnack(context.l10n.checklistResetDone, record);
  }

  Future<void> _archive(Checklist? c) async {
    if (c == null) return;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final writer = ref.read(syncWriterProvider);
    final record = await ref.read(checklistsRepositoryProvider).setArchived(c.id, archived: !c.isArchived);
    if (!mounted) return;
    if (c.isArchived) {
      _editor.pushUndo('archive', record);
      _undoSnack(l.listsUnarchived, record);
      return;
    }
    Navigator.of(context).maybePop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.listsArchived),
          action: SnackBarAction(label: l.actionUndo, onPressed: () => unawaited(writer.revert(record))),
        ),
      );
  }

  Future<void> _deleteList(Checklist c) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final writer = ref.read(syncWriterProvider);
    final record = await ref.read(checklistsRepositoryProvider).delete(c.id);
    if (!mounted) return;
    Navigator.of(context).maybePop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.listsDeleted),
          action: SnackBarAction(label: l.actionUndo, onPressed: () => unawaited(writer.revert(record))),
        ),
      );
  }

  // ------------------------------------------------------------------ menus

  Widget _overflowMenu(BuildContext context, EditorState state, Checklist c, ChecklistTree? tree) {
    final l = context.l10n;
    final outline = state.viewType == ChecklistViewType.outline;
    final s = c.settings;
    PopupMenuItem<String> item(String value, String label, IconData icon, {bool danger = false}) => PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: danger ? context.colors.error : null),
          const SizedBox(width: Space.md),
          Flexible(child: Text(label)),
        ],
      ),
    );
    return PopupMenuButton<String>(
      tooltip: l.actionMore,
      onSelected: (v) => unawaited(_onMenu(v, c, tree)),
      itemBuilder: (_) => [
        if (outline) ...[
          item('select', l.checklistSelect, Icons.checklist),
          item('expandAll', l.checklistExpandAll, Icons.unfold_more),
          item('collapseAll', l.checklistCollapseAll, Icons.unfold_less),
          item('expandLevel', l.checklistExpandToLevelMenu, Icons.format_list_numbered),
          item('sortFilter', l.checklistSortFilter, Icons.filter_list),
          if (!state.preview) item('sortChildren', l.checklistSortChildren, Icons.sort_by_alpha),
          const PopupMenuDivider(),
        ],
        item('uncheckAll', l.checklistUncheckAll, Icons.remove_done),
        item('deleteCompleted', l.checklistDeleteCompleted, Icons.delete_sweep_outlined),
        item('resetStatuses', l.checklistResetStatuses, Icons.restart_alt),
        CheckedPopupMenuItem(
          value: 'hideCheckboxes',
          checked: s.hideCheckboxes,
          child: Text(l.checklistHideCheckboxes),
        ),
        CheckedPopupMenuItem(
          value: 'sortCompleted',
          checked: s.sortCompletedToBottom,
          child: Text(l.checklistSortCompletedBottom),
        ),
        if (c.isRecurring) item('resetNow', l.checklistResetNow, Icons.replay),
        const PopupMenuDivider(),
        item('import', l.checklistImport, Icons.playlist_add),
        if (c.hasBody && !state.preview) item('convertBody', l.importConvertBody, Icons.checklist_rtl),
        item('attach', l.checklistAttach, Icons.attach_file),
        if (MediaQuery.sizeOf(context).width >= 700 && ChecklistPaneScope.maybeOf(context) == null)
          item('split', l.checklistOpenSideBySide, Icons.vertical_split_outlined),
        item('attachments', l.checklistAllAttachments, Icons.photo_library_outlined),
        item('cover', l.checklistCover, Icons.wallpaper),
        item('labels', l.checklistLabels, Icons.label_outline),
        item('share', l.checklistShare, Icons.ios_share),
        const PopupMenuDivider(),
        item('settings', l.checklistSettings, Icons.tune),
        item('repeat', l.checklistRepeat, Icons.repeat),
        item('pin', c.isPinned ? l.listsUnpin : l.listsPin, c.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
        item('duplicate', l.checklistDuplicate, Icons.copy_all_outlined),
        if (!c.isTemplate) item('saveTemplate', l.checklistSaveAsTemplate, Icons.dashboard_customize_outlined),
        item('scheduleTask', l.checklistScheduleTask, Icons.event_available),
        item('linkTask', l.checklistLinkTask, Icons.add_link),
        item('insights', l.checklistInsights, Icons.insights_outlined),
        item('archive', c.isArchived ? l.listsUnarchive : l.listsArchiveAction, Icons.archive_outlined),
        item('delete', l.checklistDelete, Icons.delete_outline, danger: true),
      ],
    );
  }

  Future<void> _onMenu(String action, Checklist c, ChecklistTree? tree) async {
    final l = context.l10n;
    final repo = ref.read(checklistsRepositoryProvider);
    switch (action) {
      case 'select':
        _editor.enterSelection();
      case 'expandAll':
        await _editor.expandAll();
      case 'collapseAll':
        await _editor.collapseAll();
      case 'expandLevel':
        final level = await pickExpandLevel(context);
        if (level != null) await _editor.expandToLevel(level);
      case 'sortFilter':
        await showSortFilterSheet(context, checklistId: checklistId);
      case 'sortChildren':
        final pick = await pickChildrenSort(context);
        if (pick == null) return;
        final record = await _editor.sortChildren(_state.focusRootId, pick.by, descending: pick.descending);
        if (record != null && mounted) _undoSnack(l.checklistSortedBy(ViewBanner.sortLabel(context, pick.by)), record);
      case 'uncheckAll':
        final count = tree == null ? 0 : ListCommands.uncheckAllCount(tree);
        if (count == 0) return;
        if (count > 10) {
          final ok = await confirmDialog(
            context,
            title: l.checklistUncheckConfirm(count),
            confirmLabel: l.checklistUncheckAll,
          );
          if (!ok) return;
        }
        final record = await _editor.uncheckAll();
        if (record != null && mounted) _undoSnack(l.checklistUncheckAll, record);
      case 'deleteCompleted':
        final record = await _editor.deleteCompleted();
        if (record != null && mounted) _undoSnack(l.checklistItemsDeleted(_itemRows(record)), record);
      case 'resetStatuses':
        final ok = await confirmDialog(
          context,
          title: l.checklistResetStatuses,
          body: l.checklistResetConfirm,
          confirmLabel: l.checklistResetStatuses,
        );
        if (!ok) return;
        final record = await _editor.resetAllStatuses();
        if (record != null && mounted) _undoSnack(l.checklistResetStatuses, record);
      case 'hideCheckboxes':
        await _editor.updateSettings((s) => s.copyWith(hideCheckboxes: !s.hideCheckboxes));
      case 'sortCompleted':
        await _editor.updateSettings((s) => s.copyWith(sortCompletedToBottom: !s.sortCompletedToBottom));
      case 'resetNow':
        final record = await ref.read(checklistResetServiceProvider).resetNow(checklistId);
        if (record != null && mounted) {
          _editor.pushUndo('reset', record);
          _undoSnack(l.checklistResetDone, record);
        }
      case 'import':
        await showImportDialog(context, ref, checklistId: checklistId, parentId: _state.focusRootId);
      case 'convertBody':
        await convertBodyToItems(context, ref, c);
      case 'attach':
        final result = await pickAndAddAttachments(
          context,
          ref,
          ownerType: AttachmentOwnerType.checklist,
          ownerId: checklistId,
        );
        final record = result?.record;
        if (record != null) _editor.pushUndo('attach', record);
      case 'cover':
        await _chooseCover(c);
      case 'split':
        await _openSideBySide();
      case 'attachments':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChecklistAttachmentsScreen(
              checklistId: checklistId,
              onGoToItem: (itemId) {
                if (!mounted) return;
                Navigator.of(context).pop();
                if (itemId == null) return;
                final t = _tree;
                if (t != null && t.contains(itemId) && t.isLeaf(itemId)) {
                  unawaited(_editor.zoomTo(t.parentOf(itemId)).then((_) => _editor.highlight(itemId)));
                  _scheduleHighlightClear();
                } else {
                  unawaited(_editor.zoomTo(itemId));
                }
              },
            ),
          ),
        );
      case 'labels':
        final current = ref.read(entityTagsProvider((type: 'checklist', id: checklistId))).value ?? const [];
        final picked = await pickTags(context, ref, selected: {for (final t in current) t.id});
        if (picked == null) return;
        final record = await ref.read(tagsRepositoryProvider).setTags('checklist', checklistId, picked);
        if (!record.isEmpty && mounted) {
          _editor.pushUndo('labels', record);
          _undoSnack(l.checklistLabels, record);
        }
      case 'share':
        if (tree == null) return;
        await showExportSheet(context, ref, checklist: c, tree: tree, branchRootId: _state.focusRootId);
      case 'settings' || 'repeat':
        await showChecklistSettings(context, checklistId: checklistId);
      case 'pin':
        final record = await repo.setPinned(c.id, pinned: !c.isPinned);
        if (!mounted) return;
        _editor.pushUndo('pin', record);
        _undoSnack(c.isPinned ? l.listsUnpin : l.listsPin, record);
      case 'duplicate':
        await duplicateChecklistFlow(context, ref, c, open: true);
      case 'saveTemplate':
        final created = await repo.duplicate(
          c.id,
          title: c.title.isEmpty ? l.listsUntitled : c.title,
          resetStatuses: true,
          asTemplate: true,
        );
        if (mounted) _undoSnack(l.checklistTemplateSaved, created.record);
      case 'scheduleTask':
        final taskId = await ref.read(checklistTaskLinksProvider).scheduleAsTask(c, fallbackTitle: l.listsUntitled);
        if (!mounted) return;
        _info(l.checklistTaskScheduled);
        openRoute(context, AppLinks.taskEdit(taskId));
      case 'linkTask':
        await _linkExistingTask(c);
      case 'insights':
        openRoute(context, AppLinks.insightsScope('checklist', checklistId));
      case 'archive':
        await _archive(c);
      case 'delete':
        await _deleteList(c);
    }
  }

  List<ToolbarAction> _toolbarActions(BuildContext context, EditorState state, ChecklistItem item) {
    final l = context.l10n;
    final id = item.id;
    return [
      ToolbarAction(Icons.format_indent_decrease, l.checklistOutdent, () => outdent(id)),
      ToolbarAction(Icons.format_indent_increase, l.checklistIndent, () => indent(id)),
      ToolbarAction(Icons.arrow_upward, l.checklistMoveUp, () => moveUp(id)),
      ToolbarAction(Icons.arrow_downward, l.checklistMoveDown, () => moveDown(id)),
      ToolbarAction(Icons.flag_outlined, l.statusChange, () => openStatusSheet(item)),
      ToolbarAction(Icons.attach_file, l.checklistAttach, () => unawaited(_attach(id))),
      ToolbarAction(Icons.event, l.checklistDue, () => unawaited(_pickDue(item))),
      ToolbarAction(Icons.info_outline, l.checklistDetails, () => openDetails(item)),
      ToolbarAction(Icons.more_horiz, l.actionMore, () => openMenu(item)),
      ToolbarAction(Icons.keyboard_return, l.checklistLineBreak, () => insertRowLineBreak(_rowContexts[id])),
      ToolbarAction(Icons.undo, l.actionUndo, state.canUndo ? undo : null),
      ToolbarAction(Icons.redo, l.actionRedo, state.canRedo ? redo : null),
      ToolbarAction(
        Icons.keyboard_hide_outlined,
        l.checklistHideKeyboard,
        () => FocusManager.instance.primaryFocus?.unfocus(),
      ),
    ];
  }

  List<ToolbarAction> _selectionActions(BuildContext context, EditorState state, ChecklistTree tree) {
    final l = context.l10n;
    final ids = tree.topMost(state.selection);
    final any = ids.isNotEmpty;
    final structure = any && state.canRestructure;
    return [
      ToolbarAction(
        Icons.flag_outlined,
        l.statusChange,
        any ? () => unawaited(_bulkStatus(state.selection.toList())) : null,
      ),
      ToolbarAction(
        Icons.format_indent_increase,
        l.checklistIndent,
        structure ? () => unawaited(_structure(() => _editor.indent(ids))) : null,
      ),
      ToolbarAction(
        Icons.format_indent_decrease,
        l.checklistOutdent,
        structure ? () => unawaited(_structure(() => _editor.outdent(ids))) : null,
      ),
      ToolbarAction(Icons.drive_file_move_outline, l.checklistMoveTo, any ? () => unawaited(_moveTo(ids)) : null),
      ToolbarAction(Icons.copy_all_outlined, l.checklistDuplicateItem, any ? () => unawaited(_duplicate(ids)) : null),
      ToolbarAction(Icons.content_copy, l.checklistCopy, any ? () => unawaited(_copy(tree, ids, cut: false)) : null),
      ToolbarAction(Icons.content_cut, l.checklistCut, any ? () => unawaited(_copy(tree, ids, cut: true)) : null),
      ToolbarAction(
        Icons.notes,
        l.checklistCopyText,
        any
            ? () async {
                await Clipboard.setData(ClipboardData(text: ChecklistClipboard.asText(tree, ids)));
                _info(l.checklistCopied);
              }
            : null,
      ),
      ToolbarAction(
        Icons.account_tree_outlined,
        l.checklistSelectSubtree,
        any
            ? () {
                for (final id in ids) {
                  _editor.selectSubtree(id);
                }
              }
            : null,
      ),
      ToolbarAction(Icons.delete_outline, l.checklistDeleteItem, any ? () => unawaited(_delete(ids)) : null),
    ];
  }

  // ------------------------------------------------------------------ drag & drop (T4.2.11)

  RenderBox? _box(BuildContext? ctx) {
    if (ctx == null || !ctx.mounted) return null;
    final ro = ctx.findRenderObject();
    return ro is RenderBox && ro.attached && ro.hasSize ? ro : null;
  }

  Rect? _listRect() {
    final box = _box(_listKey.currentContext);
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void dragStart(String id, Offset global) {
    final tree = _tree;
    final i = _indexOf[id];
    if (tree == null || i == null || _drag != null || !_state.canRestructure || _state.selecting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(HapticFeedback.mediumImpact());
    final row = _shown[i];
    final session = _DragSession(
      id: id,
      startDepth: row.depth,
      startGlobal: global,
      count: 1 + tree.descendantCount(id),
      label: row.item.text,
    )..pointer = global;
    final overlay = Overlay.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    session.overlay = OverlayEntry(
      builder: (ctx) =>
          _DragOverlay(session: session, listRect: _listRect, overlayBox: () => _box(overlay.context), rtl: rtl),
    );
    overlay.insert(session.overlay!);
    setState(() => _drag = session);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTarget());
  }

  @override
  void dragUpdate(Offset global) {
    final s = _drag;
    if (s == null) return;
    s.pointer = global;
    _updateTarget();
    _updateAutoScroll();
  }

  @override
  void dragEnd() {
    final s = _drag;
    if (s == null) return;
    final target = s.target;
    _clearDrag();
    // In a split view a drop over the other pane moves the item there (T4.5.17).
    final pane = ChecklistPaneScope.maybeOf(context);
    final own = _box(context);
    if (pane != null && own != null && !(own.localToGlobal(Offset.zero) & own.size).contains(s.pointer)) {
      unawaited(pane.onDropOutside(checklistId, s.id, s.pointer));
      return;
    }
    if (target == null) return;
    unawaited(_drop(s.id, target));
  }

  Future<void> _drop(String id, DropTarget target) async {
    final record = await _editor.moveTo([id], parentId: target.parentId, afterId: target.afterId);
    if (record != null && mounted) {
      announce(context, context.l10n.checklistItemsMoved);
      _undoSnack(context.l10n.checklistItemsMoved, record);
    }
  }

  void _clearDrag({bool rebuild = true}) {
    final s = _drag;
    if (s == null) return;
    s.autoScroll?.cancel();
    s.hover?.cancel();
    s.overlay?.remove();
    s.overlay?.dispose();
    s.overlay = null;
    _drag = null;
    if (rebuild && mounted) setState(() {});
  }

  /// Resolves the drop target from the laid-out rows: the vertical position picks the gap, the
  /// horizontal offset the depth (pure resolution in [DropResolver]).
  void _updateTarget() {
    final s = _drag;
    if (s == null || !mounted) return;
    final candidates = [
      for (final r in _shown)
        if (r.id != s.id) r,
    ];
    int? gap;
    double? lineY;
    int? lastLaid;
    double? lastBottom;
    for (var i = 0; i < candidates.length; i++) {
      final box = _box(_rowContexts[candidates[i].id]);
      if (box == null) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final height = box.size.height;
      if (s.pointer.dy < top + height / 2) {
        gap = i;
        lineY = top;
        break;
      }
      lastLaid = i;
      lastBottom = top + height;
    }
    if (gap == null) {
      gap = lastLaid == null ? candidates.length : lastLaid + 1;
      lineY = lastBottom;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final desired = DropResolver.desiredDepth(
      s.startDepth,
      s.pointer.dx - s.startGlobal.dx,
      RowMetrics.indent,
      rtl: rtl,
    );
    final target = DropResolver.resolve(candidates, gap, desired, focusRootId: _state.focusRootId);
    if (s.target != null && s.target!.depth != target.depth) unawaited(HapticFeedback.selectionClick());
    s
      ..target = target
      ..indicatorY = lineY;
    // Hovering a collapsed parent (the row above the gap) for 600 ms expands it.
    final above = gap > 0 && gap <= candidates.length ? candidates[gap - 1] : null;
    final hoverId = above != null && above.hasChildren && above.collapsed ? above.id : null;
    if (hoverId != s.hoverId) {
      s.hover?.cancel();
      s.hoverId = hoverId;
      if (hoverId != null) {
        s.hover = Timer(const Duration(milliseconds: 600), () {
          if (identical(_drag, s)) unawaited(_editor.toggleCollapse(hoverId));
        });
      }
    }
    s.overlay?.markNeedsBuild();
  }

  /// Auto-scroll near the list edges, speed proportional to the proximity.
  void _updateAutoScroll() {
    final s = _drag;
    final rect = _listRect();
    if (s == null || rect == null) return;
    const edge = 64.0;
    const maxSpeed = 18.0;
    var velocity = 0.0;
    if (s.pointer.dy < rect.top + edge) {
      velocity = -((rect.top + edge - s.pointer.dy) / edge).clamp(0.0, 1.0) * maxSpeed;
    } else if (s.pointer.dy > rect.bottom - edge) {
      velocity = ((s.pointer.dy - (rect.bottom - edge)) / edge).clamp(0.0, 1.0) * maxSpeed;
    }
    s.velocity = velocity;
    if (velocity == 0) {
      s.autoScroll?.cancel();
      s.autoScroll = null;
      return;
    }
    s.autoScroll ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!identical(_drag, s) || !_scroll.hasClients) return;
      final p = _scroll.position;
      final next = (p.pixels + s.velocity).clamp(p.minScrollExtent, p.maxScrollExtent);
      if (next != p.pixels) {
        _scroll.jumpTo(next);
        _updateTarget();
      }
    });
  }
}

/// Values shared by every row of one build.
class _RowEnv {
  const _RowEnv({
    required this.tree,
    required this.rollups,
    required this.counts,
    required this.reminders,
    required this.settings,
    required this.state,
    required this.now,
    required this.nowLocal,
  });

  final ChecklistTree? tree;
  final Map<String, Rollup> rollups;
  final Map<String, int> counts;
  final Set<String> reminders;
  final ChecklistSettings settings;
  final EditorState state;
  final DateTime now;
  final LocalDateTime nowLocal;
}

/// Live state of one drag.
class _DragSession {
  _DragSession({
    required this.id,
    required this.startDepth,
    required this.startGlobal,
    required this.count,
    required this.label,
  });

  final String id;
  final int startDepth;
  final Offset startGlobal;

  /// Items carried (the row and its subtree).
  final int count;
  final String label;
  Offset pointer = Offset.zero;
  DropTarget? target;
  double? indicatorY;
  double velocity = 0;
  OverlayEntry? overlay;
  Timer? autoScroll;
  Timer? hover;
  String? hoverId;
}

/// Drag feedback (the lifted row with a count badge) and the drop indicator at the target depth.
class _DragOverlay extends StatelessWidget {
  const _DragOverlay({required this.session, required this.listRect, required this.overlayBox, required this.rtl});

  final _DragSession session;
  final Rect? Function() listRect;
  final RenderBox? Function() overlayBox;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final list = listRect();
    final box = overlayBox();
    if (list == null || box == null) return const SizedBox.shrink();
    Offset local(Offset global) => box.globalToLocal(global);
    final s = session;
    final l = context.l10n;
    final children = <Widget>[];
    final target = s.target;
    final y = s.indicatorY;
    if (target != null && y != null) {
      final indent = RowMetrics.indentFor(target.depth) + RowMetrics.chevronWidth;
      final start = rtl ? list.left + Space.sm : list.left + indent;
      final end = rtl ? list.right - indent : list.right - Space.sm;
      final a = local(Offset(start, y - 1.5));
      children.add(
        Positioned.fromRect(
          rect: Rect.fromLTWH(a.dx, a.dy, (end - start).clamp(8.0, double.infinity), 3),
          child: DecoratedBox(
            decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(Radii.pill)),
          ),
        ),
      );
    }
    final width = (list.width - Space.xxl).clamp(120.0, 600.0);
    final dx = rtl ? -(s.pointer.dx - s.startGlobal.dx) : s.pointer.dx - s.startGlobal.dx;
    final left = rtl ? list.right - width - Space.lg - dx : list.left + Space.lg + dx;
    final topLeft = local(Offset(left, s.pointer.dy - 28));
    children.add(
      Positioned.fromRect(
        rect: Rect.fromLTWH(topLeft.dx, topLeft.dy, width, 56),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(Radii.md),
          color: context.colors.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.md),
            child: Row(
              children: [
                Icon(Icons.drag_indicator, color: context.colors.outline),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    s.label.isEmpty ? l.checklistItemHint : s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyLarge,
                  ),
                ),
                if (s.count > 1)
                  StatusPill(label: l.checklistCarrying(s.count), color: context.colors.primary, dense: true),
              ],
            ),
          ),
        ),
      ),
    );
    return IgnorePointer(child: Stack(children: children));
  }
}

/// Labels, repeat chip and checklist-level attachments under the title (T4.1.12, T4.5.06, T4.4.05).
class _HeaderExtras extends ConsumerWidget {
  const _HeaderExtras({required this.checklist, required this.preview, required this.onRepeat});

  final Checklist checklist;
  final bool preview;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final schedule = ResetSchedule.fromJson(checklist.resetRule);
    final tags = ref.watch(entityTagsProvider((type: 'checklist', id: checklist.id))).value ?? const [];
    final linked = ref.watch(linkedTasksProvider(checklist.id));
    Widget? repeat;
    if (schedule != null) {
      final prefs = ref.watch(userPreferencesProvider);
      final now = ref.read(clockProvider).nowUtc();
      final next = ref.read(checklistResetServiceProvider).nextReset(schedule);
      String rule;
      try {
        rule = const RecurrenceDescriber().describe(
          schedule.rule,
          schedule.anchor,
          locale: context.localeName.split('-').first,
          use24h: prefs.use24h,
          weekStart: prefs.weekStart,
        );
      } on Object {
        rule = l.repeatCustom;
      }
      final when = next == null
          ? '—'
          : AppFormat(context.localeName, use24h: prefs.use24h, l10n: l).relative(next, now);
      repeat = ActionChip(
        avatar: const Icon(Icons.repeat, size: 18),
        label: Text(l.repeatChip(rule, when)),
        onPressed: onRepeat,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tags.isNotEmpty || !preview || repeat != null || linked.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, 0),
            child: Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ?repeat,
                // Planner tasks linked to this list (T4.5.12): tap opens the task.
                for (final t in linked)
                  Semantics(
                    label: l.checklistLinkedTaskSemantics(t.title),
                    button: true,
                    excludeSemantics: true,
                    child: ActionChip(
                      avatar: const Icon(Icons.event_available, size: 18),
                      label: Text(t.title, overflow: TextOverflow.ellipsis),
                      onPressed: () => openRoute(context, AppLinks.task(t.id)),
                    ),
                  ),
                EntityTagChips(entityType: 'checklist', entityId: checklist.id, editable: !preview),
              ],
            ),
          ),
        ChecklistAttachmentsHeader(checklistId: checklist.id, editable: !preview),
      ],
    );
  }
}
