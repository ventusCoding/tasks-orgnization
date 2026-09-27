import 'dart:async';
import 'dart:ui' as ui;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/mind_map_layout.dart';
import 'package:everslot/features/checklists/domain/rollup.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Mind map view (T4.5.14): the same tree as the outline, laid out horizontally with curved
/// connectors, status colours and progress rings on parents. Pan and zoom, collapse nodes (the
/// collapse state is shared with the outline), a focused branch dims the others, tapping a node
/// shows it in the outline, and the map exports as an image.
class MindMapView extends ConsumerStatefulWidget {
  const MindMapView({required this.checklistId, required this.onOpenItem, super.key});

  final String checklistId;

  /// Shows the item in the outline.
  final ValueChanged<String> onOpenItem;

  static const nodeWidth = 200.0;
  static const nodeHeight = 52.0;
  static const padding = 24.0;

  @override
  ConsumerState<MindMapView> createState() => _MindMapViewState();
}

class _MindMapViewState extends ConsumerState<MindMapView> {
  final _boundary = GlobalKey();

  Future<void> _export(String title) async {
    final boundary = _boundary.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) return;
    final name = '${title.trim().isEmpty ? 'mind-map' : title.trim()}.png';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png', name: name)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final id = widget.checklistId;
    final tree = ref.watch(checklistTreeProvider(id));
    if (tree == null) return const LoadingState();
    final checklist = ref.watch(checklistProvider(id)).value;
    final collapsed = ref.watch(collapsedNodesProvider(id)).value ?? const <String>{};
    final rollups = ref.watch(checklistRollupsProvider(id));
    final focusRoot = ref.watch(checklistEditorProvider(id).select((s) => s.focusRootId));
    final mode = checklist?.settings.progressMode ?? ProgressMode.leaves;
    final layout = MindMapLayout.compute(
      tree,
      collapsed: collapsed,
      nodeWidth: MindMapView.nodeWidth,
      nodeHeight: MindMapView.nodeHeight,
    );
    final lit = focusRoot == null || !tree.contains(focusRoot)
        ? null
        : {focusRoot, ...tree.descendants(focusRoot), ...tree.ancestors(focusRoot)};
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const pad = MindMapView.padding;
    final title = checklist?.title ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: IconButton(
            tooltip: l.mindMapExport,
            icon: const Icon(Icons.image_outlined),
            onPressed: () => unawaited(_export(title)),
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.25,
            maxScale: 2.5,
            boundaryMargin: const EdgeInsets.all(240),
            child: RepaintBoundary(
              key: _boundary,
              child: ColoredBox(
                color: context.colors.surface,
                child: SizedBox(
                  width: layout.width + pad * 2,
                  height: layout.height + pad * 2,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _EdgesPainter(
                            layout: layout,
                            rtl: rtl,
                            color: context.colors.outlineVariant,
                            dimmed: lit,
                          ),
                        ),
                      ),
                      for (final node in layout.nodes)
                        PositionedDirectional(
                          start: pad + node.x,
                          top: pad + node.y,
                          width: MindMapView.nodeWidth,
                          height: MindMapView.nodeHeight,
                          child: Opacity(
                            opacity: lit == null || node.id == null || lit.contains(node.id) ? 1 : 0.3,
                            child: _Node(
                              node: node,
                              tree: tree,
                              title: title,
                              rollup: node.id == null ? RollupCalculator.root(tree, rollups) : rollups[node.id],
                              mode: mode,
                              collapsed: node.id != null && collapsed.contains(node.id),
                              onTap: node.id == null ? null : () => widget.onOpenItem(node.id!),
                              onToggle: node.id == null
                                  ? null
                                  : () => unawaited(
                                      ref.read(checklistEditorProvider(id).notifier).toggleCollapse(node.id!),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.node,
    required this.tree,
    required this.title,
    required this.rollup,
    required this.mode,
    required this.collapsed,
    required this.onTap,
    required this.onToggle,
  });

  final MindMapNode node;
  final ChecklistTree tree;
  final String title;
  final Rollup? rollup;
  final ProgressMode mode;
  final bool collapsed;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final id = node.id;
    final item = id == null ? null : tree[id];
    final status = item?.status ?? ItemStatus.todo;
    final isRoot = item == null;
    final hasChildren = isRoot ? tree.childIds(null).isNotEmpty : tree.childIds(item.id).isNotEmpty;
    final text = isRoot
        ? (title.trim().isEmpty ? l.listsUntitled : title)
        : (item.text.isEmpty ? l.checklistItemHint : item.text);
    final color = isRoot ? context.colors.primary : StatusStyle.color(context, status);
    final r = rollup;
    final details = [
      if (!isRoot) StatusStyle.label(context, status),
      if (hasChildren) l.checklistSubItems(isRoot ? tree.length : tree.childIds(item.id).length),
      if (collapsed) l.checklistCollapsedState,
    ].join(', ');
    final done = status == ItemStatus.completed || status == ItemStatus.cancelled;
    return Semantics(
      button: onTap != null,
      label: details.isEmpty ? text : '$text, $details',
      excludeSemantics: true,
      customSemanticsActions: {
        if (onToggle != null && hasChildren)
          CustomSemanticsAction(label: collapsed ? l.checklistExpand : l.checklistCollapse): onToggle!,
      },
      child: Material(
        color: isRoot ? context.colors.primaryContainer : context.colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: color, width: isRoot ? 2 : 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              const SizedBox(width: Space.sm),
              if (hasChildren && r != null)
                ProgressRing(progress: r.progress(mode), size: 22, stroke: 3, color: color)
              else
                Icon(StatusStyle.icon(status), size: 18, color: color),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: (isRoot ? context.text.titleSmall : context.text.labelMedium)?.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (node.hiddenChildren > 0) Text(l.mindMapHidden(node.hiddenChildren), style: context.text.labelSmall),
              if (onToggle != null && hasChildren)
                SizedBox(
                  width: 44,
                  height: double.infinity,
                  child: InkResponse(
                    onTap: onToggle,
                    child: Icon(
                      collapsed ? Icons.add_circle_outline : Icons.remove_circle_outline,
                      size: 18,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const SizedBox(width: Space.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Curved connectors from each parent's trailing edge to its children's leading edge.
class _EdgesPainter extends CustomPainter {
  _EdgesPainter({required this.layout, required this.rtl, required this.color, required this.dimmed});

  final MindMapLayout layout;
  final bool rtl;
  final Color color;

  /// When a branch is focused: the ids drawn at full strength.
  final Set<String>? dimmed;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = MindMapView.padding;
    final byId = {for (final n in layout.nodes) n.id: n};
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    double xOf(double x) => rtl ? size.width - x : x;
    for (final n in layout.nodes) {
      if (n.depth == 0) continue;
      final p = byId[n.parentId];
      if (p == null) continue;
      final lit = dimmed == null || (dimmed!.contains(n.id) && (p.id == null || dimmed!.contains(p.id)));
      paint.color = lit ? color : color.withValues(alpha: 0.3);
      final start = Offset(xOf(pad + p.x + layout.nodeWidth), pad + p.y + layout.nodeHeight / 2);
      final end = Offset(xOf(pad + n.x), pad + n.y + layout.nodeHeight / 2);
      final midX = (start.dx + end.dx) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(midX, start.dy, midX, end.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgesPainter old) =>
      old.layout != layout || old.rtl != rtl || old.color != color || old.dimmed != dimmed;
}
