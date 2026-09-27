import 'dart:async';

import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart' show AttachmentOwnerType;
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/attachments/presentation/attachment_ui.dart';
import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/application/checklist_service.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_card.dart' show statusSegments;
import 'package:everslot/features/checklists/presentation/checklist_navigation.dart';
import 'package:everslot/features/checklists/presentation/markdown_lite.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Title + note of the checklist (T4.1.09). Edit mode edits in place (debounced, one undo step per
/// field session); a pending new card is created on the first character typed.
class ChecklistTitleBody extends ConsumerStatefulWidget {
  const ChecklistTitleBody({
    required this.checklistId,
    required this.checklist,
    required this.preview,
    super.key,
    this.pending,
    this.onCreated,
    this.create,
    this.onTitleSubmitted,
  });

  final String checklistId;
  final Checklist? checklist;
  final bool preview;
  final PendingCard? pending;
  final VoidCallback? onCreated;

  /// Creates the pending card (the screen owns creation so every path creates it exactly once).
  final Future<void> Function(String title, String body)? create;

  /// Enter on the title; return false to fall back to focusing the note field.
  final bool Function()? onTitleSubmitted;

  @override
  ConsumerState<ChecklistTitleBody> createState() => _ChecklistTitleBodyState();
}

class _ChecklistTitleBodyState extends ConsumerState<ChecklistTitleBody> {
  late final _title = TextEditingController(text: widget.checklist?.title ?? '');
  late final _body = TextEditingController(text: widget.checklist?.body ?? '');
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();
  Timer? _debounce;
  final List<OpRecord> _session = [];
  bool _creating = false;
  bool _bodyExpanded = true;

  @override
  void initState() {
    super.initState();
    _titleFocus.addListener(_onBlur);
    _bodyFocus.addListener(_onBlur);
    if (widget.pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        (widget.pending!.note ? _bodyFocus : _titleFocus).requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(ChecklistTitleBody old) {
    super.didUpdateWidget(old);
    final c = widget.checklist;
    if (c == null) return;
    if (old.checklist == null) {
      // Created meanwhile: write what was typed while the row was being created.
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () => unawaited(_flush()));
      return;
    }
    if (!_titleFocus.hasFocus && _title.text != c.title) _title.text = c.title;
    if (!_bodyFocus.hasFocus && _body.text != (c.body ?? '')) _body.text = c.body ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_flush());
    _title.dispose();
    _body.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  void _onBlur() {
    if (_titleFocus.hasFocus || _bodyFocus.hasFocus) return;
    unawaited(_flush().then((_) => _endSession()));
  }

  void _endSession() {
    if (_session.isEmpty || !mounted) return;
    ref.read(checklistEditorProvider(widget.checklistId).notifier).pushUndo('header', mergeRecords(List.of(_session)));
    _session.clear();
  }

  void _changed() {
    _debounce?.cancel();
    if (widget.checklist == null) {
      unawaited(_createIfNeeded());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => unawaited(_flush()));
  }

  Future<void> _createIfNeeded() async {
    if (_creating || widget.checklist != null) return;
    if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) return;
    _creating = true;
    final create = widget.create;
    if (create != null) {
      await create(_title.text, _body.text);
    } else {
      await ref.read(checklistsRepositoryProvider).create(id: widget.checklistId, title: _title.text, body: _body.text);
    }
    widget.onCreated?.call();
  }

  Future<void> _flush() async {
    _debounce?.cancel();
    final c = widget.checklist;
    if (c == null) return;
    final title = ChecklistTitle(_title.text).value;
    final body = ItemText.body(_body.text);
    if (title == c.title && body == c.body) return;
    final record = await ref
        .read(checklistsRepositoryProvider)
        .update(c.id, title: title, body: body, clearBody: body == null);
    if (!record.isEmpty) _session.add(record);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = widget.checklist;
    if (widget.preview) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((c?.title ?? '').isNotEmpty) Text(c!.title, style: context.text.headlineSmall),
            if (c != null && c.hasBody)
              InkWell(
                onTap: () => setState(() => _bodyExpanded = !_bodyExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: MarkdownLite(c.body!, maxLines: _bodyExpanded ? null : 2, autoDirection: true),
                ),
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, 0),
      child: Column(
        children: [
          TextField(
            controller: _title,
            focusNode: _titleFocus,
            style: context.text.headlineSmall,
            maxLength: ChecklistTitle.maxLength,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(hintText: l.checklistTitleHint, border: InputBorder.none),
            onChanged: (_) => _changed(),
            onSubmitted: (_) {
              if (widget.onTitleSubmitted?.call() ?? false) return;
              _bodyFocus.requestFocus();
            },
          ),
          TextField(
            controller: _body,
            focusNode: _bodyFocus,
            minLines: 1,
            maxLines: null,
            style: context.text.bodyLarge,
            decoration: InputDecoration(hintText: l.checklistBodyHint, border: InputBorder.none, isDense: true),
            onChanged: (_) => _changed(),
          ),
          // Formatting toolbar while the body is being edited (T4.1.11).
          ListenableBuilder(
            listenable: _bodyFocus,
            builder: (context, _) => _bodyFocus.hasFocus
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MarkdownFormatBar(controller: _body, onChanged: _changed),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Checklist-level attachments (T4.4.05) and upload status (T4.4.03).
class ChecklistAttachmentsHeader extends ConsumerWidget {
  const ChecklistAttachmentsHeader({required this.checklistId, required this.editable, super.key});

  final String checklistId;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AttachmentStrip(
          ownerType: AttachmentOwnerType.checklist,
          ownerId: checklistId,
          editable: editable,
          showAddButton: false,
          maxVisible: 6,
          onOperation: ref.read(checklistEditorProvider(checklistId).notifier).pushUndo,
        ),
        const PendingUploadsIndicator(dense: true),
      ],
    ),
  );
}

/// Progress header (T4.3.08): x/y, %, status-split bar and blocked/waiting counts.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({required this.rollup, required this.mode, super.key});

  final Rollup rollup;
  final ProgressMode mode;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = rollup.total(mode);
    if (total == 0) return const SizedBox.shrink();
    final done = rollup.done(mode);
    final pct = AppFormat(context.localeName).percent(rollup.progress(mode));
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.xs),
      child: Semantics(
        label: '${l.checklistProgress(done, total)}, $pct',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phone widths and text scale 2.0: both halves wrap instead of overflowing.
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: Space.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(l.checklistProgress(done, total), style: context.text.labelLarge),
                        Text(pct, style: context.text.labelLarge?.copyWith(color: context.colors.primary)),
                      ],
                    ),
                  ),
                  if (rollup.blockedBelow > 0 || rollup.waitingBelow > 0)
                    Flexible(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: Space.xs,
                        runSpacing: Space.xs,
                        children: [
                          if (rollup.blockedBelow > 0)
                            _FittedPill(
                              label: l.listsBadgeBlocked(rollup.blockedBelow),
                              color: StatusStyle.pillColor(context, StatusStyle.color(context, ItemStatus.blocked)),
                            ),
                          if (rollup.waitingBelow > 0)
                            _FittedPill(
                              label: l.listsBadgeWaiting(rollup.waitingBelow),
                              color: StatusStyle.pillColor(context, StatusStyle.color(context, ItemStatus.waiting)),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Space.xs),
              SegmentedBar(segments: statusSegments(context, rollup)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dense pill that scales down instead of overflowing a narrow column (text scale 2.0).
class _FittedPill extends StatelessWidget {
  const _FittedPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: StatusPill(label: label, color: color, dense: true),
  );
}

/// Breadcrumbs "Checklist › A › B" with middle ellipsis (T4.2.13). Tapping a crumb zooms out.
class Breadcrumbs extends StatelessWidget {
  const Breadcrumbs({
    required this.tree,
    required this.focusRootId,
    required this.rootTitle,
    required this.onTap,
    super.key,
  });

  final ChecklistTree tree;
  final String focusRootId;
  final String rootTitle;
  final ValueChanged<String?> onTap;

  @override
  Widget build(BuildContext context) {
    final path = [...tree.ancestors(focusRootId), focusRootId];
    final crumbs = <(String?, String)>[(null, rootTitle), for (final id in path) (id, tree[id]?.text ?? '')];
    // Middle ellipsis: keep the first and the last three crumbs.
    final shown = crumbs.length > 5 ? [crumbs.first, (null, '…'), ...crumbs.sublist(crumbs.length - 3)] : crumbs;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: false,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.md),
        itemCount: shown.length,
        separatorBuilder: (_, _) =>
            Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right, size: 18),
        itemBuilder: (_, i) {
          final (id, label) = shown[i];
          final isLast = i == shown.length - 1;
          final isEllipsis = label == '…' && id == null && i == 1 && crumbs.length > 5;
          return Center(
            child: TextButton(
              onPressed: isLast || isEllipsis ? null : () => onTap(id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(label.isEmpty ? '·' : label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Large header of the focused (zoomed) item: text and note (T4.2.13).
class FocusedItemHeader extends StatelessWidget {
  const FocusedItemHeader({required this.item, required this.onTap, super.key});

  final ChecklistItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(StatusStyle.icon(item.status), color: StatusStyle.color(context, item.status)),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  item.text.isEmpty ? context.l10n.checklistItemHint : item.text,
                  style: context.text.titleLarge?.copyWith(
                    decoration: item.status == ItemStatus.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          if (item.hasNote)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: MarkdownLite(
                item.note!,
                autoDirection: true,
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    ),
  );
}

/// "Sorted by … · Reset" / "Filtered view · Reset" banner (T4.5.11).
class ViewBanner extends StatelessWidget {
  const ViewBanner({required this.state, required this.onReset, super.key});

  final EditorState state;
  final VoidCallback onReset;

  static String sortLabel(BuildContext context, ItemSortBy by) {
    final l = context.l10n;
    return switch (by) {
      ItemSortBy.manual => l.checklistSortManual,
      ItemSortBy.alphabetical => l.checklistSortAlpha,
      ItemSortBy.status => l.checklistSortStatus,
      ItemSortBy.due => l.checklistSortDue,
      ItemSortBy.priority => l.checklistSortPriority,
      ItemSortBy.recent => l.checklistSortRecent,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!state.isSorted && !state.filter.isActive) return const SizedBox.shrink();
    final l = context.l10n;
    final text = [
      if (state.isSorted) l.checklistSortedBy(sortLabel(context, state.sort.by)),
      if (state.filter.isActive) l.checklistFiltered,
    ].join(' · ');
    return MaterialBanner(
      content: Text(text),
      leading: const Icon(Icons.filter_list),
      actions: [TextButton(onPressed: onReset, child: Text(l.checklistResetView))],
    );
  }
}

/// Preview-mode filter chips and controls (T4.3.08).
class PreviewControls extends ConsumerWidget {
  const PreviewControls({required this.checklistId, required this.onNextOpen, super.key});

  final String checklistId;
  final VoidCallback onNextOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(checklistEditorProvider(checklistId));
    final editor = ref.read(checklistEditorProvider(checklistId).notifier);
    final f = state.filter;
    final open = {ItemStatus.todo, ItemStatus.ongoing, ItemStatus.waiting, ItemStatus.blocked};
    Widget chip(String label, Set<ItemStatus> statuses) {
      final selected = f.statuses.length == statuses.length && f.statuses.containsAll(statuses);
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: Space.xs),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => editor.setFilter(f.copyWith(statuses: statuses)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, Space.xs),
      child: Row(
        children: [
          chip(l.checklistFilterAll, const {}),
          chip(l.checklistFilterOpen, open),
          for (final s in const [ItemStatus.ongoing, ItemStatus.waiting, ItemStatus.blocked, ItemStatus.completed])
            chip(StatusStyle.label(context, s), {s}),
          FilterChip(
            label: Text(l.checklistHideCompleted),
            selected: f.hideCompleted,
            onSelected: (v) => editor.setFilter(f.copyWith(hideCompleted: v)),
          ),
          const SizedBox(width: Space.xs),
          ActionChip(
            avatar: const Icon(Icons.skip_next, size: 18),
            label: Text(l.checklistNextOpen),
            onPressed: onNextOpen,
          ),
        ],
      ),
    );
  }
}

/// "List completed" state with Reset / Archive / Keep (T4.3.12).
class CompletedBanner extends StatefulWidget {
  const CompletedBanner({required this.onReset, required this.onArchive, super.key});

  final VoidCallback onReset;
  final VoidCallback onArchive;

  @override
  State<CompletedBanner> createState() => _CompletedBannerState();
}

class _CompletedBannerState extends State<CompletedBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: Motion.slow);
  bool _kept = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.reduceMotion) {
        _anim.value = 1;
      } else {
        unawaited(_anim.forward());
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_kept) return const SizedBox.shrink();
    final l = context.l10n;
    return Semantics(
      liveRegion: true,
      child: Card(
        margin: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.sm),
        color: context.colors.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              ScaleTransition(
                scale: CurvedAnimation(parent: _anim, curve: Curves.elasticOut),
                child: Icon(Icons.celebration, color: context.colors.primary, size: 32),
              ),
              const SizedBox(width: Space.md),
              Expanded(child: Text(l.checklistCompleted, style: context.text.titleMedium)),
              TextButton(onPressed: widget.onReset, child: Text(l.checklistCompletedReset)),
              TextButton(onPressed: widget.onArchive, child: Text(l.checklistCompletedArchive)),
              TextButton(onPressed: () => setState(() => _kept = true), child: Text(l.checklistCompletedKeep)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Add item" row at the end of the outline (edit mode).
class AddItemRow extends StatelessWidget {
  const AddItemRow({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, Space.md),
      child: Row(
        children: [
          Icon(Icons.add, color: context.colors.primary),
          const SizedBox(width: Space.md),
          Text(context.l10n.checklistAddItem, style: context.text.bodyLarge?.copyWith(color: context.colors.primary)),
        ],
      ),
    ),
  );
}

/// Opens the list's reset schedule chip text helper.
String listTitle(BuildContext context, Checklist? c) =>
    (c?.title.trim().isEmpty ?? true) ? context.l10n.listsUntitled : c!.title;

/// Nodes → count, used by the import dialog and templates.
int nodeCount(List<NodeSpec> nodes) => nodes.fold(0, (a, n) => a + n.size);
