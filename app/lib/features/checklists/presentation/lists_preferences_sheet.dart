import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/presentation/attachment_ui.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/application/swipe_actions.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Lists (board layout, smart chips, swipe mappings, attachments) — T4.1.16 / T4.2.10.
Future<void> showListsPreferences(BuildContext context, WidgetRef ref) =>
    showAppSheet<void>(context, title: context.l10n.listsPreferences, builder: (_) => const _ListsPreferences());

class _ListsPreferences extends ConsumerWidget {
  const _ListsPreferences();

  String _swipeLabel(BuildContext context, SwipeAction a) {
    final l = context.l10n;
    return switch (a) {
      SwipeAction.indent => l.settingsSwipeIndent,
      SwipeAction.outdent => l.settingsSwipeOutdent,
      SwipeAction.complete => l.settingsSwipeComplete,
      SwipeAction.menu => l.settingsSwipeMenu,
      SwipeAction.none => l.settingsSwipeNone,
    };
  }

  Widget _swipeTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    SwipeAction value,
    List<SwipeAction> options,
    SwipeActions Function(SwipeAction) apply,
  ) => ListTile(
    title: Text(title),
    trailing: DropdownButton<SwipeAction>(
      value: value,
      onChanged: (v) {
        if (v != null) unawaited(saveSwipeActions(ref, apply(v)));
      },
      items: [for (final o in options) DropdownMenuItem(value: o, child: Text(_swipeLabel(context, o)))],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final config = ref.watch(boardConfigProvider).value ?? BoardConfig.defaults;
    final swipes = ref.watch(swipeActionsProvider);
    final store = ref.read(boardConfigStoreProvider);
    const editOptions = [
      SwipeAction.indent,
      SwipeAction.outdent,
      SwipeAction.complete,
      SwipeAction.menu,
      SwipeAction.none,
    ];
    const previewOptions = [
      SwipeAction.complete,
      SwipeAction.menu,
      SwipeAction.indent,
      SwipeAction.outdent,
      SwipeAction.none,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            value: config.showSmartChips,
            title: Text(l.listsShowSmartChips),
            onChanged: (v) => store.save(config.copyWith(showSmartChips: v)),
          ),
          SwitchListTile(
            value: config.showBody,
            title: Text(l.listsShowBody),
            onChanged: (v) => store.save(config.copyWith(showBody: v)),
          ),
          ListTile(
            title: Text(l.listsBoardSort),
            trailing: DropdownButton<BoardSort>(
              value: config.sort,
              onChanged: (v) {
                if (v != null) unawaited(store.save(config.copyWith(sort: v)));
              },
              items: [
                DropdownMenuItem(value: BoardSort.manual, child: Text(l.listsBoardSortManual)),
                DropdownMenuItem(value: BoardSort.recentlyEdited, child: Text(l.listsBoardSortRecent)),
                DropdownMenuItem(value: BoardSort.title, child: Text(l.listsBoardSortTitle)),
              ],
            ),
          ),
          SectionHeader(l.settingsSwipeTitle),
          _swipeTile(
            context,
            ref,
            l.settingsSwipeEditRight,
            swipes.editRight,
            editOptions,
            (v) => swipes.copyWith(editRight: v),
          ),
          _swipeTile(
            context,
            ref,
            l.settingsSwipeEditLeft,
            swipes.editLeft,
            editOptions,
            (v) => swipes.copyWith(editLeft: v),
          ),
          _swipeTile(
            context,
            ref,
            l.settingsSwipePreviewRight,
            swipes.previewRight,
            previewOptions,
            (v) => swipes.copyWith(previewRight: v),
          ),
          _swipeTile(
            context,
            ref,
            l.settingsSwipePreviewLeft,
            swipes.previewLeft,
            previewOptions,
            (v) => swipes.copyWith(previewLeft: v),
          ),
          const AttachmentSettingsSection(),
        ],
      ),
    );
  }
}
