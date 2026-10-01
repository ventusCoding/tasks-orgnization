/// "Customize cards" sheet (T6.1.22): reorder (drag handle; assistive technologies get the built-in
/// move up / down / to start / to end actions), pin and hide the cards of one Insights scope. Edits
/// are kept in the sheet and saved to `user_settings.stats.layouts` when it closes (Done, swipe or
/// back), so the customization survives restarts and syncs to the user's other devices. "Reset to
/// default" drops the customization.
library;

import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/layouts.dart';
import 'package:everslot/features/stats/application/stats_layout_store.dart';
import 'package:everslot/features/stats/domain/stats_layout.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the editor of [scope]'s layout ([base] defaults to the scope's default layout).
Future<void> showLayoutEditor(BuildContext context, {required MetricScope scope, StatsLayout? base}) =>
    showAppSheet<void>(
      context,
      title: context.l10n.statsLayoutEdit,
      builder: (_) => LayoutEditorSheet(scope: scope, base: base ?? defaultLayoutOf(scope)),
    );

class LayoutEditorSheet extends ConsumerStatefulWidget {
  const LayoutEditorSheet({required this.scope, required this.base, super.key});

  final MetricScope scope;

  /// The scope's default layout — every card the user can arrange.
  final StatsLayout base;

  @override
  ConsumerState<LayoutEditorSheet> createState() => _LayoutEditorSheetState();
}

class _LayoutEditorSheetState extends ConsumerState<LayoutEditorSheet> {
  // Captured up front: `ref` is unsafe to use in dispose, where the edits are saved on dismissal.
  late final StatsLayoutStore _store;
  late final LayoutPrefs _initial;
  late LayoutPrefs _prefs;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _store = ref.read(statsLayoutStoreProvider);
    _initial = ref.read(statsLayoutPrefsProvider(widget.scope));
    _prefs = _initial;
  }

  void _edit(LayoutPrefs next) => setState(() => _prefs = next);

  /// Saves once (idempotent); a default customization removes the stored entry.
  void _persist() {
    if (_saved) return;
    _saved = true;
    if (_prefs != _initial) unawaited(_store.save(widget.scope, _prefs).catchError((Object _) {}));
  }

  @override
  void dispose() {
    _persist();
    super.dispose();
  }

  Map<String, StatsLayoutItem> get _items => {
    for (final s in widget.base.sections)
      for (final i in s.items) i.metricId: i,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = _items;
    final pinned = [
      for (final id in _prefs.pinned)
        if (items.containsKey(id)) id,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, 0, Space.xl, Space.sm),
          child: Text(
            l.statsLayoutHint,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        Flexible(
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              if (pinned.isNotEmpty)
                _Group(
                  key: const ValueKey('group/pinned'),
                  title: l.statsSectionPinned,
                  ids: pinned,
                  prefs: _prefs,
                  onReorder: (from, to) => _edit(_prefs.movePinned(from, to)),
                  onPin: (id) => _edit(_prefs.togglePinned(id)),
                  onHide: (id) => _edit(_prefs.toggleHidden(id)),
                ),
              for (final section in widget.base.sections)
                if (_prefs.visibleOrder(widget.base, section.id).isNotEmpty)
                  _Group(
                    key: ValueKey('group/${section.id}'),
                    title: sectionText(l, section.id) ?? section.id,
                    ids: _prefs.visibleOrder(widget.base, section.id),
                    prefs: _prefs,
                    onReorder: (from, to) => _edit(_prefs.moveInSection(widget.base, section.id, from, to)),
                    onPin: (id) => _edit(_prefs.togglePinned(id)),
                    onHide: (id) => _edit(_prefs.toggleHidden(id)),
                  ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, Space.sm, Space.xl, Space.lg),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              TextButton.icon(
                onPressed: _prefs.isDefault ? null : () => _edit(LayoutPrefs.none),
                icon: const Icon(Icons.restart_alt),
                label: Text(l.statsLayoutReset),
              ),
              FilledButton(
                onPressed: () {
                  _persist();
                  Navigator.of(context).pop();
                },
                child: Text(l.statsLayoutDone),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One titled, reorderable group of cards.
class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.ids,
    required this.prefs,
    required this.onReorder,
    required this.onPin,
    required this.onHide,
    super.key,
  });

  final String title;
  final List<String> ids;
  final LayoutPrefs prefs;
  final void Function(int from, int to) onReorder;
  final ValueChanged<String> onPin;
  final ValueChanged<String> onHide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, Space.md, Space.xl, Space.xs),
            child: Semantics(
              header: true,
              child: Text(title, style: context.text.titleSmall?.copyWith(color: context.colors.primary)),
            ),
          ),
        ),
        SliverReorderableList(
          itemCount: ids.length,
          // `onReorderItem` already adjusts the target index for the removed item.
          onReorderItem: onReorder,
          itemBuilder: (context, index) {
            final id = ids[index];
            final name = metricTitle(l, id) ?? id;
            final pinned = prefs.isPinned(id);
            final hidden = prefs.isHidden(id);
            return Material(
              key: ValueKey('card/$id'),
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.md),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: Semantics(
                        label: l.statsLayoutReorder(name),
                        child: const SizedBox.square(dimension: 48, child: Icon(Icons.drag_indicator)),
                      ),
                    ),
                    Expanded(
                      child: Opacity(
                        opacity: hidden ? 0.5 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: context.text.bodyLarge?.copyWith(
                                decoration: hidden ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hidden)
                              Text(
                                l.statsLayoutHiddenTag,
                                style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: pinned ? l.statsLayoutUnpin(name) : l.statsLayoutPin(name),
                      isSelected: pinned,
                      icon: const Icon(Icons.push_pin_outlined),
                      selectedIcon: const Icon(Icons.push_pin),
                      onPressed: () => onPin(id),
                    ),
                    IconButton(
                      tooltip: hidden ? l.statsLayoutShow(name) : l.statsLayoutHide(name),
                      icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => onHide(id),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
