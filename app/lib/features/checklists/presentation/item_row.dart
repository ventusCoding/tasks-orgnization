import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart' show AttachmentOwnerType;
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:everslot/features/checklists/domain/visible_list.dart';
import 'package:everslot/features/checklists/presentation/checklist_card.dart' show statusSegments;
import 'package:everslot/features/checklists/presentation/markdown_lite.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Layout constants of the outline.
abstract final class RowMetrics {
  static const indent = 16.0;
  static const maxIndentLevels = 8;
  static const chevronWidth = 32.0;
  static const statusWidth = 44.0;
  static const handleWidth = 40.0;
  static const minHeight = 48.0;
  static const swipeThreshold = 56.0;

  static double indentFor(int depth) => (depth > maxIndentLevels ? maxIndentLevels : depth) * indent;
}

/// Everything a row needs besides its [VisibleRow] (comparable, so unchanged rows are reused).
@immutable
class RowContext {
  const RowContext({
    required this.preview,
    required this.hideCheckboxes,
    required this.showNotes,
    required this.showAttachments,
    required this.siblingIndex,
    required this.siblingCount,
    required this.now,
    this.selecting = false,
    this.selected = false,
    this.collapsedRollup,
    this.attachmentCount = 0,
    this.highlighted = false,
    this.canRestructure = true,
    this.staleAfterDays = 14,
    this.dueState,
    this.dimmed = false,
    this.hasReminder = false,
  });

  final bool preview;
  final bool hideCheckboxes;
  final bool showNotes;
  final bool showAttachments;
  final int siblingIndex;
  final int siblingCount;

  /// Coarse "now" (minute precision) for ages.
  final DateTime now;
  final bool selecting;
  final bool selected;
  final Rollup? collapsedRollup;
  final int attachmentCount;
  final bool highlighted;
  final bool canRestructure;
  final int staleAfterDays;
  final DueState? dueState;

  /// Row being dragged.
  final bool dimmed;

  /// The item has its own reminder rules (bell icon).
  final bool hasReminder;

  @override
  bool operator ==(Object other) =>
      other is RowContext &&
      other.preview == preview &&
      other.hideCheckboxes == hideCheckboxes &&
      other.showNotes == showNotes &&
      other.showAttachments == showAttachments &&
      other.siblingIndex == siblingIndex &&
      other.siblingCount == siblingCount &&
      other.now == now &&
      other.selecting == selecting &&
      other.selected == selected &&
      other.collapsedRollup == collapsedRollup &&
      other.attachmentCount == attachmentCount &&
      other.highlighted == highlighted &&
      other.canRestructure == canRestructure &&
      other.staleAfterDays == staleAfterDays &&
      other.dueState == dueState &&
      other.dimmed == dimmed &&
      other.hasReminder == hasReminder;

  @override
  int get hashCode => Object.hash(
    preview,
    hideCheckboxes,
    showNotes,
    showAttachments,
    siblingIndex,
    siblingCount,
    now,
    selecting,
    selected,
    collapsedRollup,
    attachmentCount,
    highlighted,
    canRestructure,
    staleAfterDays,
    dueState,
    dimmed,
    hasReminder,
  );
}

/// Callbacks from rows to the screen (one stable instance per screen).
abstract class RowActions {
  String get checklistId;
  void toggleCollapse(String id);
  void setSubtreeCollapsed(String id, {required bool collapsed});
  void toggleComplete(String id);
  void openStatusSheet(ChecklistItem item);
  void openDetails(ChecklistItem item);
  void openMenu(ChecklistItem item);
  void zoom(String id);
  void toggleSelected(String id);

  /// Selects every visible row from the last toggled one to [id] (range selection).
  void selectRangeTo(String id);
  void enter(String id, String text, int cursor);
  void backspaceAtStart(String id, String text);
  Future<bool> multilinePaste(String id, String pasted);
  void focusNeighbor(String id, int direction);
  void indent(String id);
  void outdent(String id);
  void moveUp(String id);
  void moveDown(String id);
  void undo();
  void redo();
  void swipe(ChecklistItem item, {required bool towardEnd});
  void dragStart(String id, Offset global);
  void dragUpdate(Offset global);
  void dragEnd();
  void registerRow(String id, BuildContext? context);
}

/// Text controller keeping an invisible sentinel at offset 0 so Backspace at the start of a row
/// is observable even on soft keyboards (which send no key event on an empty field).
class RowTextController extends TextEditingController {
  RowTextController(String plain) : super(text: sentinel + plain);

  static const sentinel = '​';

  String get plain => text.startsWith(sentinel) ? text.substring(1) : text;

  /// Caret in plain-text coordinates.
  int get plainCursor => (selection.baseOffset - 1).clamp(0, plain.length);

  void setPlain(String value, {int? cursor}) {
    final c = (cursor ?? value.length).clamp(0, value.length);
    this.value = TextEditingValue(
      text: sentinel + value,
      selection: TextSelection.collapsed(offset: c + 1),
    );
  }

  void setCursor(int? cursor) {
    final c = (cursor ?? plain.length).clamp(0, plain.length);
    selection = TextSelection.collapsed(offset: c + 1);
  }
}

/// Inserts a line break at the caret of the row built with [rowContext] (keyboard toolbar).
bool insertRowLineBreak(BuildContext? rowContext) {
  if (rowContext is! StatefulElement || !rowContext.mounted) return false;
  final state = rowContext.state;
  if (state is! _ItemRowState || state._controller == null) return false;
  state._insertLineBreak();
  return true;
}

/// Keeps the sentinel, detects Backspace-at-start, Enter-as-newline and multi-line pastes.
class _SentinelFormatter extends TextInputFormatter {
  _SentinelFormatter({required this.onBackspaceAtStart, required this.onEnter, required this.onPaste});

  final VoidCallback onBackspaceAtStart;
  final void Function(String textBefore, String textAfter) onEnter;
  final void Function(String pasted) onPaste;
  static const s = RowTextController.sentinel;

  static TextRange _shift(TextRange r, int by) => r.isValid ? TextRange(start: r.start + by, end: r.end + by) : r;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var value = newValue;
    if (!value.text.startsWith(s)) {
      final wasAtStart =
          oldValue.text.startsWith(s) &&
          oldValue.selection.isCollapsed &&
          oldValue.selection.baseOffset == 1 &&
          value.text == oldValue.text.substring(1);
      if (wasAtStart) {
        scheduleMicrotask(onBackspaceAtStart);
        return oldValue;
      }
      value = value.copyWith(
        text: s + value.text,
        selection: TextSelection(
          baseOffset: value.selection.baseOffset + 1,
          extentOffset: value.selection.extentOffset + 1,
        ),
        composing: _shift(value.composing, 1),
      );
    }
    // A newline typed by a soft keyboard means Enter; a multi-line chunk means paste.
    final oldNl = '\n'.allMatches(oldValue.text).length;
    final newNl = '\n'.allMatches(value.text).length;
    if (newNl > oldNl && value.text.length > oldValue.text.length) {
      final inserted = value.text.length - oldValue.text.length;
      final at = value.selection.baseOffset - inserted;
      if (at >= 1 && at <= value.text.length) {
        final chunk = value.text.substring(at, (at + inserted).clamp(0, value.text.length));
        if (chunk == '\n') {
          final plain = value.text.substring(1);
          final cut = at - 1;
          scheduleMicrotask(() => onEnter(plain.substring(0, cut), plain.substring(cut + 1)));
          return oldValue;
        }
        if (chunk.trim().contains('\n')) {
          scheduleMicrotask(() => onPaste(chunk));
          return oldValue;
        }
      }
    }
    final sel = value.selection;
    if (sel.isValid && (sel.start < 1 || sel.end < 1)) {
      value = value.copyWith(
        selection: TextSelection(
          baseOffset: sel.baseOffset < 1 ? 1 : sel.baseOffset,
          extentOffset: sel.extentOffset < 1 ? 1 : sel.extentOffset,
        ),
      );
    }
    return value;
  }
}

/// One outline row (T4.2.08) in edit or preview variant.
class ItemRow extends ConsumerStatefulWidget {
  const ItemRow({required this.row, required this.ctx, required this.actions, super.key});

  final VisibleRow row;
  final RowContext ctx;
  final RowActions actions;

  @override
  ConsumerState<ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends ConsumerState<ItemRow> {
  RowTextController? _controller;
  FocusNode? _focus;
  double _dx = 0;
  bool _thresholdHaptic = false;

  ChecklistItem get item => widget.row.item;
  bool get _editing => !widget.ctx.preview && !widget.ctx.selecting;

  @override
  void initState() {
    super.initState();
    _ensureEditing();
  }

  @override
  void didUpdateWidget(ItemRow old) {
    super.didUpdateWidget(old);
    _ensureEditing();
    final c = _controller;
    if (c != null && !(_focus?.hasFocus ?? false)) {
      final draft = ref.read(checklistEditorProvider(widget.actions.checklistId).notifier).draftOf(item.id);
      final text = draft ?? item.text;
      if (c.plain != text) c.setPlain(text);
    }
  }

  void _ensureEditing() {
    if (_editing && _controller == null) {
      final draft = ref.read(checklistEditorProvider(widget.actions.checklistId).notifier).draftOf(item.id);
      _controller = RowTextController(draft ?? item.text);
      _focus = FocusNode(debugLabel: 'row-${item.id}')..addListener(_onFocus);
    } else if (!_editing && _controller != null) {
      _disposeEditing();
    }
  }

  void _disposeEditing() {
    final f = _focus;
    final c = _controller;
    _focus = null;
    _controller = null;
    if (f != null) {
      if (f.hasFocus) {
        unawaited(
          ref
              .read(checklistEditorProvider(widget.actions.checklistId).notifier)
              .onFocusChanged(item.id, focused: false),
        );
      }
      f
        ..removeListener(_onFocus)
        ..dispose();
    }
    c?.dispose();
  }

  void _onFocus() {
    final f = _focus;
    if (f == null || !mounted) return;
    unawaited(
      ref
          .read(checklistEditorProvider(widget.actions.checklistId).notifier)
          .onFocusChanged(item.id, focused: f.hasFocus),
    );
  }

  @override
  void dispose() {
    widget.actions.registerRow(item.id, null);
    _disposeEditing();
    super.dispose();
  }

  void _applyFocusRequest(FocusRequest? request) {
    if (request == null || request.itemId != item.id || _controller == null || _focus == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _focus == null) return;
      _focus!.requestFocus();
      _controller!.setCursor(request.cursor);
      ref.read(checklistEditorProvider(widget.actions.checklistId).notifier).consumeFocusRequest(request);
      Scrollable.ensureVisible(context, alignment: 0.3, duration: context.reduceMotion ? Duration.zero : Motion.fast);
    });
  }

  bool _isOnFirstLine() {
    final c = _controller!;
    return !c.text.substring(0, c.selection.baseOffset.clamp(0, c.text.length)).contains('\n');
  }

  bool _isOnLastLine() {
    final c = _controller!;
    return !c.text.substring(c.selection.baseOffset.clamp(0, c.text.length)).contains('\n');
  }

  void _insertLineBreak() {
    final c = _controller!;
    final sel = c.selection;
    final start = sel.start < 1 ? 1 : sel.start;
    final end = sel.end < 1 ? 1 : sel.end;
    final text = c.text.replaceRange(start, end, '\n');
    c.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + 1),
    );
    ref.read(checklistEditorProvider(widget.actions.checklistId).notifier).onTextChanged(item.id, c.plain);
  }

  Map<ShortcutActivator, VoidCallback> _shortcuts() {
    final a = widget.actions;
    final id = item.id;
    return {
      const SingleActivator(LogicalKeyboardKey.tab): () => a.indent(id),
      const SingleActivator(LogicalKeyboardKey.tab, shift: true): () => a.outdent(id),
      const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () => a.moveUp(id),
      const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): () => a.moveDown(id),
      const SingleActivator(LogicalKeyboardKey.enter, control: true): () => a.toggleComplete(id),
      const SingleActivator(LogicalKeyboardKey.enter, meta: true): () => a.toggleComplete(id),
      const SingleActivator(LogicalKeyboardKey.period, control: true): () => a.toggleCollapse(id),
      const SingleActivator(LogicalKeyboardKey.period, meta: true): () => a.toggleCollapse(id),
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true): a.undo,
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): a.undo,
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): a.redo,
      const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): a.redo,
      const SingleActivator(LogicalKeyboardKey.enter, shift: true): _insertLineBreak,
      const SingleActivator(LogicalKeyboardKey.arrowUp): () {
        if (_isOnFirstLine()) {
          a.focusNeighbor(id, -1);
        } else {
          _moveCaretVertically(-1);
        }
      },
      const SingleActivator(LogicalKeyboardKey.arrowDown): () {
        if (_isOnLastLine()) {
          a.focusNeighbor(id, 1);
        } else {
          _moveCaretVertically(1);
        }
      },
    };
  }

  void _moveCaretVertically(int direction) {
    final c = _controller!;
    final text = c.text;
    final pos = c.selection.baseOffset.clamp(1, text.length);
    if (direction < 0) {
      final lineStart = text.lastIndexOf('\n', pos - 1);
      final prevStart = lineStart <= 0 ? 1 : text.lastIndexOf('\n', lineStart - 1) + 1;
      final col = pos - (lineStart + 1);
      c.selection = TextSelection.collapsed(offset: (prevStart + col).clamp(1, lineStart < 1 ? 1 : lineStart));
    } else {
      final nextNl = text.indexOf('\n', pos);
      if (nextNl < 0) return;
      final lineStart = text.lastIndexOf('\n', pos - 1) + 1;
      final col = pos - (lineStart < 1 ? 1 : lineStart);
      final nextEnd = text.indexOf('\n', nextNl + 1);
      c.selection = TextSelection.collapsed(
        offset: (nextNl + 1 + col).clamp(nextNl + 1, nextEnd < 0 ? text.length : nextEnd),
      );
    }
  }

  // ------------------------------------------------------------------ swipe (T4.2.10)

  void _onSwipeUpdate(DragUpdateDetails d) {
    setState(() => _dx = (_dx + d.delta.dx).clamp(-96.0, 96.0));
    final past = _dx.abs() >= RowMetrics.swipeThreshold;
    if (past != _thresholdHaptic) {
      _thresholdHaptic = past;
      if (past) unawaited(HapticFeedback.selectionClick());
    }
  }

  void _onSwipeEnd(DragEndDetails _) {
    final dx = _dx;
    setState(() {
      _dx = 0;
      _thresholdHaptic = false;
    });
    if (dx.abs() < RowMetrics.swipeThreshold) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final towardEnd = rtl ? dx < 0 : dx > 0;
    unawaited(HapticFeedback.mediumImpact());
    widget.actions.swipe(item, towardEnd: towardEnd);
  }

  // ------------------------------------------------------------------ build

  String _semantics(BuildContext context) {
    final l = context.l10n;
    final r = widget.row;
    final parts = <String>[
      l.checklistRowSemantics(
        item.text.isEmpty ? l.checklistItemHint : item.text,
        r.depth + 1,
        widget.ctx.siblingIndex + 1,
        widget.ctx.siblingCount,
      ),
      if (r.hasChildren && r.collapsed) l.checklistCollapsedState,
      if (r.hasChildren) l.checklistSubItems(r.childCount),
      if (item.status != ItemStatus.todo)
        item.statusSince == null
            ? StatusStyle.label(context, item.status)
            : l.statusWithAge(
                StatusStyle.label(context, item.status),
                formatAge(context, item.statusSince!, widget.ctx.now),
              ),
      if (item.statusNote != null) item.statusNote!,
    ];
    return parts.join(', ');
  }

  Map<CustomSemanticsAction, VoidCallback> _semanticActions(BuildContext context) {
    final l = context.l10n;
    final a = widget.actions;
    return {
      if (widget.ctx.canRestructure) CustomSemanticsAction(label: l.checklistIndent): () => a.indent(item.id),
      if (widget.ctx.canRestructure) CustomSemanticsAction(label: l.checklistOutdent): () => a.outdent(item.id),
      if (widget.ctx.canRestructure) CustomSemanticsAction(label: l.checklistMoveUp): () => a.moveUp(item.id),
      if (widget.ctx.canRestructure) CustomSemanticsAction(label: l.checklistMoveDown): () => a.moveDown(item.id),
      if (widget.row.hasChildren)
        CustomSemanticsAction(label: widget.row.collapsed ? l.checklistExpand : l.checklistCollapse): () =>
            a.toggleCollapse(item.id),
      CustomSemanticsAction(label: l.statusChange): () => a.openStatusSheet(item),
      CustomSemanticsAction(label: l.checklistFocus): () => a.zoom(item.id),
      CustomSemanticsAction(label: l.checklistDetails): () => a.openDetails(item),
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(checklistEditorProvider(widget.actions.checklistId).select((s) => s.focusRequest), (_, next) {
      _applyFocusRequest(next);
    });
    final pending = ref.read(checklistEditorProvider(widget.actions.checklistId)).focusRequest;
    if (pending?.itemId == item.id) _applyFocusRequest(pending);
    widget.actions.registerRow(item.id, context);

    final ctx = widget.ctx;
    final row = widget.row;
    final a = widget.actions;
    final done = item.status == ItemStatus.completed;
    final cancelled = item.status == ItemStatus.cancelled;
    final baseStyle = (ctx.preview ? context.text.bodyLarge : context.text.bodyLarge) ?? const TextStyle();
    // T4.3.04: completed = struck through (still readable); cancelled = struck through + muted;
    // context rows (ancestors shown by filters) are muted.
    final textStyle = baseStyle.copyWith(
      decoration: done || cancelled ? TextDecoration.lineThrough : null,
      color: cancelled || row.isContext
          ? context.colors.onSurface.withValues(alpha: 0.55)
          : (done ? context.colors.onSurfaceVariant : null),
    );

    final leading = <Widget>[
      SizedBox(
        width: RowMetrics.chevronWidth,
        height: RowMetrics.minHeight,
        child: row.hasChildren
            ? Semantics(
                button: true,
                label: row.collapsed ? context.l10n.checklistExpand : context.l10n.checklistCollapse,
                child: InkResponse(
                  radius: 20,
                  onTap: () => a.toggleCollapse(item.id),
                  onLongPress: () => a.setSubtreeCollapsed(item.id, collapsed: !row.collapsed),
                  child: AnimatedRotation(
                    turns: row.collapsed ? (Directionality.of(context) == TextDirection.rtl ? 0.25 : -0.25) : 0,
                    duration: context.reduceMotion ? Duration.zero : Motion.fast,
                    child: Icon(Icons.expand_more, size: 22, color: context.colors.onSurfaceVariant),
                  ),
                ),
              )
            : null,
      ),
      if (ctx.selecting)
        SizedBox(
          width: RowMetrics.statusWidth,
          height: RowMetrics.minHeight,
          child: Checkbox(value: ctx.selected, onChanged: (_) => a.toggleSelected(item.id)),
        )
      else
        SizedBox(
          width: RowMetrics.statusWidth,
          child: StatusControl(
            status: item.status,
            bullet: ctx.hideCheckboxes,
            onTap: ctx.hideCheckboxes && !ctx.preview ? () => a.zoom(item.id) : () => a.toggleComplete(item.id),
            onLongPress: () => a.openStatusSheet(item),
          ),
        ),
    ];

    Widget text;
    final controller = _controller;
    if (_editing && controller != null && _focus != null) {
      text = CallbackShortcuts(
        bindings: _shortcuts(),
        child: TextField(
          controller: controller,
          focusNode: _focus,
          style: textStyle,
          maxLines: null,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: context.l10n.checklistItemHint,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
          inputFormatters: [
            _SentinelFormatter(
              onBackspaceAtStart: () => a.backspaceAtStart(item.id, controller.plain),
              onEnter: (before, after) => a.enter(item.id, before + after, before.length),
              onPaste: (pasted) async {
                final handled = await a.multilinePaste(item.id, pasted);
                if (!handled && mounted && _controller != null) {
                  final c = _controller!;
                  final sel = c.selection;
                  c.value = TextEditingValue(
                    text: c.text.replaceRange(sel.start < 1 ? 1 : sel.start, sel.end < 1 ? 1 : sel.end, pasted),
                    selection: TextSelection.collapsed(offset: (sel.start < 1 ? 1 : sel.start) + pasted.length),
                  );
                  ref.read(checklistEditorProvider(a.checklistId).notifier).onTextChanged(item.id, c.plain);
                }
              },
            ),
          ],
          onChanged: (_) =>
              ref.read(checklistEditorProvider(a.checklistId).notifier).onTextChanged(item.id, controller.plain),
          onSubmitted: (_) => a.enter(item.id, controller.plain, controller.plainCursor),
        ),
      );
    } else {
      text = Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: item.text.isEmpty
            ? Text(context.l10n.checklistItemHint, style: textStyle.copyWith(color: context.colors.outline))
            : MarkdownLite(item.text, style: textStyle),
      );
    }

    final meta = _MetaLine(item: item, row: row, ctx: ctx);
    final showStrip = ctx.attachmentCount > 0 && !row.collapsed && (ctx.preview ? ctx.showAttachments : true);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        text,
        if (meta.hasContent) meta,
        if (ctx.preview && ctx.showNotes && item.hasNote)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: MarkdownLite(
              item.note!,
              maxLines: 6,
              autoDirection: true,
              style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
        if (showStrip)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: AttachmentStrip(
              ownerType: AttachmentOwnerType.checklistItem,
              ownerId: item.id,
              compact: !ctx.preview,
              editable: !ctx.preview,
              showAddButton: false,
              onOperation: (label, record) =>
                  ref.read(checklistEditorProvider(a.checklistId).notifier).pushUndo(label, record),
            ),
          ),
      ],
    );

    final depthBadge = row.depth > RowMetrics.maxIndentLevels
        ? Padding(
            padding: const EdgeInsetsDirectional.only(top: 14, end: Space.xs),
            child: Text(
              context.l10n.checklistDepthBadge(row.depth + 1),
              style: context.text.labelSmall?.copyWith(color: context.colors.outline),
            ),
          )
        : null;

    Widget body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IndentGuides(depth: row.depth),
        ...leading,
        Expanded(child: content),
        ?depthBadge,
        if (!ctx.preview && !ctx.selecting && ctx.canRestructure)
          _DragHandle(onStart: (g) => a.dragStart(item.id, g), onUpdate: a.dragUpdate, onEnd: a.dragEnd),
        if (ctx.preview || ctx.selecting) const SizedBox(width: Space.sm),
      ],
    );

    if (ctx.preview && !ctx.selecting) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => a.openDetails(item),
        onLongPressStart: ctx.canRestructure ? (d) => a.dragStart(item.id, d.globalPosition) : null,
        onLongPressMoveUpdate: ctx.canRestructure ? (d) => a.dragUpdate(d.globalPosition) : null,
        onLongPressEnd: ctx.canRestructure ? (_) => a.dragEnd() : null,
        child: body,
      );
    } else if (ctx.selecting) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => a.toggleSelected(item.id),
        onLongPress: () => a.selectRangeTo(item.id),
        child: body,
      );
    }

    final swipeEnabled = !ctx.selecting && (ctx.preview || ctx.canRestructure);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final hint = _dx == 0
        ? null
        : Positioned.fill(
            child: Align(
              alignment: (_dx > 0) != rtl ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                child: Icon(
                  _dx.abs() >= RowMetrics.swipeThreshold ? Icons.check_circle : Icons.swipe,
                  color: context.colors.primary,
                ),
              ),
            ),
          );

    return MergeSemantics(
      child: Semantics(
        label: _semantics(context),
        customSemanticsActions: _semanticActions(context),
        selected: ctx.selected,
        child: AnimatedOpacity(
          opacity: ctx.dimmed ? 0.35 : 1,
          duration: context.reduceMotion ? Duration.zero : Motion.fast,
          child: Container(
            constraints: const BoxConstraints(minHeight: RowMetrics.minHeight),
            color: ctx.highlighted
                ? context.colors.primaryContainer.withValues(alpha: 0.45)
                : (ctx.selected ? context.colors.secondaryContainer.withValues(alpha: 0.5) : null),
            child: Stack(
              children: [
                ?hint,
                GestureDetector(
                  onHorizontalDragUpdate: swipeEnabled ? _onSwipeUpdate : null,
                  onHorizontalDragEnd: swipeEnabled ? _onSwipeEnd : null,
                  child: Transform.translate(offset: Offset(_dx, 0), child: body),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndentGuides extends StatelessWidget {
  const _IndentGuides({required this.depth});

  final int depth;

  @override
  Widget build(BuildContext context) {
    if (depth == 0) return const SizedBox.shrink();
    final levels = depth > RowMetrics.maxIndentLevels ? RowMetrics.maxIndentLevels : depth;
    return SizedBox(
      width: RowMetrics.indentFor(depth),
      height: RowMetrics.minHeight,
      child: CustomPaint(painter: _GuidePainter(levels, context.colors.outlineVariant, Directionality.of(context))),
    );
  }
}

class _GuidePainter extends CustomPainter {
  _GuidePainter(this.levels, this.color, this.direction);

  final int levels;
  final Color color;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 0; i < levels; i++) {
      final x = RowMetrics.indent * i + RowMetrics.chevronWidth / 2;
      final dx = direction == TextDirection.rtl ? size.width - x : x;
      if (dx < 0 || dx > size.width) continue;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) => old.levels != levels || old.color != color || old.direction != direction;
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.onStart, required this.onUpdate, required this.onEnd});

  final void Function(Offset global) onStart;
  final void Function(Offset global) onUpdate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.checklistDragHandle,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (d) => onStart(d.globalPosition),
      onLongPressMoveUpdate: (d) => onUpdate(d.globalPosition),
      onLongPressEnd: (_) => onEnd(),
      onLongPressCancel: onEnd,
      child: SizedBox(
        width: RowMetrics.handleWidth,
        height: RowMetrics.minHeight,
        child: Icon(Icons.drag_indicator, color: context.colors.outline, size: 20),
      ),
    ),
  );
}

/// Pills and chips under the text: status with age, reason, follow-up, due, stale, collapsed
/// progress, descendant badges, paperclip count.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.item, required this.row, required this.ctx});

  final ChecklistItem item;
  final VisibleRow row;
  final RowContext ctx;

  bool get _showStatusPill =>
      item.status == ItemStatus.ongoing ||
      item.status == ItemStatus.waiting ||
      item.status == ItemStatus.blocked ||
      item.status == ItemStatus.cancelled;

  bool get hasContent =>
      _showStatusPill ||
      item.statusNote != null ||
      item.followUpAt != null ||
      item.dueLocal != null ||
      row.isOrphan ||
      ctx.hasReminder ||
      ItemTimeRules.isStale(item, ctx.now, ctx.staleAfterDays) ||
      (ctx.collapsedRollup != null && ctx.collapsedRollup!.descendants > 0) ||
      (ctx.attachmentCount > 0 && (row.collapsed || (ctx.preview && !ctx.showAttachments)));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = ctx.collapsedRollup;
    final muted = context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant);
    final followOverdue = ItemTimeRules.followUpOverdue(item.followUpAt, ctx.now);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Wrap(
        spacing: Space.xs,
        runSpacing: Space.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (row.isOrphan)
            StatusPill(label: l.checklistRecovered, color: context.appColors.warning, icon: Icons.healing, dense: true),
          if (_showStatusPill) ItemStatusPill(status: item.status, since: item.statusSince, now: ctx.now),
          if (item.statusNote != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                item.statusNote!,
                maxLines: ctx.preview ? 3 : 1,
                overflow: TextOverflow.ellipsis,
                style: muted?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          if (item.followUpAt != null && item.status.isOpen)
            StatusPill(
              label: followOverdue
                  ? l.statusFollowUpOverdue
                  : l.statusFollowUpChip(
                      AppFormat(context.localeName).dateMedium(LocalDate.fromDateTime(item.followUpAt!.toLocal())),
                    ),
              color: followOverdue ? context.appColors.danger : context.appColors.info,
              icon: Icons.notifications_active_outlined,
              dense: true,
            ),
          if (item.dueLocal != null)
            StatusPill(
              label: switch (ctx.dueState) {
                DueState.overdue => l.itemDueOverdue,
                DueState.today => l.itemDueToday,
                DueState.tomorrow => l.itemDueTomorrow,
                _ => AppFormat(context.localeName).dateMedium(item.dueLocal!.date),
              },
              color: ctx.dueState == DueState.overdue ? context.appColors.danger : context.appColors.info,
              icon: Icons.event,
              dense: true,
            ),
          if (ItemTimeRules.isStale(item, ctx.now, ctx.staleAfterDays))
            Icon(Icons.hourglass_empty, size: 14, color: context.appColors.skipped, semanticLabel: l.statusStale),
          if (ctx.hasReminder)
            Icon(
              Icons.notifications_active_outlined,
              size: 14,
              color: context.colors.onSurfaceVariant,
              semanticLabel: l.checklistHasReminders,
            ),
          if (r != null && r.leafCountable > 0) ...[
            Text(l.listsCardProgress(r.leafCompleted, r.leafCountable), style: muted),
            SizedBox(width: 48, child: SegmentedBar(segments: statusSegments(context, r), height: 4)),
          ],
          if (r != null && r.blockedBelow + r.waitingBelow > 0)
            Text(l.checklistBelowBadges(r.blockedBelow, r.waitingBelow), style: muted),
          if (ctx.attachmentCount > 0 && (row.collapsed || (ctx.preview && !ctx.showAttachments)))
            AttachmentCountBadge(count: ctx.attachmentCount),
        ],
      ),
    );
  }
}
