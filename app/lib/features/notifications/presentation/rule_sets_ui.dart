import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/rule_sets.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_set.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Reads the text of a rule-set file picked by the user (null on cancel; tests override it).
final ruleSetFileReaderProvider = Provider<Future<String?> Function()>(
  (ref) => () async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['json']);
    if (files.isEmpty || files.first.path == null) return null;
    return File(files.first.path!).readAsString();
  },
);

/// What the item sheet did: a set to apply (the host applies it — saved item or draft).
typedef RuleSetChoice = ({RuleSet set, bool replace});

/// The *Rule sets* sheet of an item (T7.1.18): save its own reminders as a set (saved items with
/// reminders) or pick a set of the same kind to apply.
Future<RuleSetChoice?> showItemRuleSets(
  BuildContext context, {
  required NotificationTargetType targetType,
  String? savedTargetId,
}) => showAppSheet<RuleSetChoice>(
  context,
  title: context.l10n.notifRuleSets,
  builder: (_) => _ItemRuleSetsSheet(targetType: targetType, savedTargetId: savedTargetId),
);

class _ItemRuleSetsSheet extends ConsumerWidget {
  const _ItemRuleSetsSheet({required this.targetType, this.savedTargetId});

  final NotificationTargetType targetType;
  final String? savedTargetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sets = [
      for (final s in ref.watch(ruleSetsProvider))
        if (s.targetType == targetType.wire) s,
    ];
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsetsDirectional.only(bottom: Space.lg),
      children: [
        if (savedTargetId != null)
          ListTile(
            key: const ValueKey('rule-set-save'),
            leading: const Icon(Icons.bookmark_add_outlined),
            title: Text(l.notifRuleSetSave),
            onTap: () async {
              final name = await promptText(context, title: l.notifRuleSetName);
              if (name == null || !context.mounted) return;
              final saved = await ref
                  .read(ruleSetsServiceProvider)
                  .saveFromTarget(
                    name: name.length > RuleSet.maxNameLength ? name.substring(0, RuleSet.maxNameLength) : name,
                    type: targetType,
                    targetId: savedTargetId!,
                  );
              if (!context.mounted) return;
              showInfoSnackBar(context, saved == null ? l.notifRuleSetNothing : l.notifRuleSetSaved(saved.name));
              if (saved != null) Navigator.pop(context);
            },
          ),
        if (sets.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.all(Space.lg),
            child: Text(l.notifRuleSetEmpty, style: context.text.bodyMedium),
          ),
        for (final s in sets)
          ListTile(
            key: ValueKey('rule-set-${s.id}'),
            leading: const Icon(Icons.bookmarks_outlined),
            title: Text(s.name),
            subtitle: Text(l.notifRuleSetCount(s.entries.length)),
            onTap: () async {
              final replace = await confirmDialog(
                context,
                title: l.notifRuleSetApplyTitle(s.name),
                body: l.notifRuleSetApplyBody,
                confirmLabel: l.notifRuleSetApply,
              );
              if (!replace || !context.mounted) return;
              Navigator.pop<RuleSetChoice>(context, (set: s, replace: true));
            },
          ),
      ],
    );
  }
}

/// Settings › Notifications › Rule sets: rename, export, delete, import.
class RuleSetsScreen extends ConsumerWidget {
  const RuleSetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sets = ref.watch(ruleSetsProvider);
    final service = ref.read(ruleSetsServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifRuleSets),
        actions: [
          IconButton(
            key: const ValueKey('rule-set-import'),
            tooltip: l.notifRuleSetImport,
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () async {
              final source = await ref.read(ruleSetFileReaderProvider)();
              if (source == null || !context.mounted) return;
              try {
                final set = await service.importFile(source);
                if (context.mounted) showInfoSnackBar(context, l.notifRuleSetImported(set.name));
              } on FormatException {
                if (context.mounted) showInfoSnackBar(context, l.notifRuleSetInvalid);
              }
            },
          ),
        ],
      ),
      body: sets.isEmpty
          ? EmptyState(icon: Icons.bookmarks_outlined, title: l.notifRuleSetEmpty)
          : ListView(
              children: [
                for (final s in sets)
                  ListTile(
                    key: ValueKey('rule-set-row-${s.id}'),
                    leading: const Icon(Icons.bookmarks_outlined),
                    title: Text(s.name),
                    subtitle: Text(l.notifRuleSetCount(s.entries.length)),
                    trailing: PopupMenuButton<String>(
                      tooltip: l.actionMore,
                      onSelected: (action) async {
                        switch (action) {
                          case 'rename':
                            final name = await promptText(context, title: l.notifRuleSetName, initial: s.name);
                            if (name != null) await service.put(s.copyWith(name: name));
                          case 'export':
                            await SharePlus.instance.share(
                              ShareParams(
                                files: [
                                  XFile.fromData(
                                    utf8.encode(s.toFile()),
                                    mimeType: 'application/json',
                                    name: '${s.name}.json',
                                  ),
                                ],
                                title: s.name,
                              ),
                            );
                          case 'delete':
                            if (context.mounted &&
                                await confirmDialog(
                                  context,
                                  title: l.notifRuleSetDeleteTitle(s.name),
                                  confirmLabel: l.actionDelete,
                                  destructive: true,
                                )) {
                              await service.delete(s.id);
                            }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'rename', child: Text(l.notifProfileRename)),
                        PopupMenuItem(value: 'export', child: Text(l.notifRuleSetExport)),
                        PopupMenuItem(value: 'delete', child: Text(l.actionDelete)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
