import 'dart:io';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/import_export.dart';
import 'package:everslot/features/checklists/domain/tree_change.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_navigation.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

String importWarningText(BuildContext context, ImportWarning w) {
  final l = context.l10n;
  return switch (w) {
    ImportWarning.tooManyLines => l.importWarningTooMany,
    ImportWarning.emptyInput => l.importWarningEmpty,
    ImportWarning.malformedOpml => l.importWarningMalformed,
    ImportWarning.attachmentsSkipped => l.importWarningAttachments,
  };
}

/// Reads an import file chosen by the user: its name and text, null on cancel.
typedef ImportFileReader = Future<({String name, String text})?> Function();

/// `.txt`, `.md` or `.opml` through the system file picker (tests override this provider).
final importFileReaderProvider = Provider<ImportFileReader>(
  (ref) => () async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'md', 'markdown', 'opml', 'xml'],
    );
    if (files.isEmpty || files.first.path == null) return null;
    final f = files.first;
    return (name: f.name, text: await File(f.path!).readAsString());
  },
);

/// Picks a `.txt`, `.md` or `.opml` file and parses it (null on cancel / unreadable).
Future<(ImportResult, String)?> pickImportFile(BuildContext context, WidgetRef ref) async {
  try {
    final file = await ref.read(importFileReaderProvider)();
    if (file == null) return null;
    final f = file.name;
    final name = f.contains('.') ? f.substring(0, f.lastIndexOf('.')) : f;
    return (ChecklistImport.parse(file.text), name);
  } on Object {
    if (context.mounted) showInfoSnackBar(context, context.l10n.importWarningMalformed);
    return null;
  }
}

/// The tree an import will create (T4.5.08): indented rows, first [maxLines] shown.
class ImportPreview extends StatelessWidget {
  const ImportPreview({required this.result, super.key, this.maxLines = 12});

  final ImportResult result;
  final int maxLines;

  static List<(int, NodeSpec)> _flatten(List<NodeSpec> nodes, [int depth = 0]) => [
    for (final n in nodes) ...[(depth, n), ..._flatten(n.children, depth + 1)],
  ];

  @override
  Widget build(BuildContext context) {
    final lines = _flatten(result.nodes);
    final muted = context.colors.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (depth, node) in lines.take(maxLines))
          Padding(
            padding: EdgeInsetsDirectional.only(start: depth * 16.0, top: 2, bottom: 2),
            child: Row(
              children: [
                Icon(StatusStyle.icon(node.status), size: 16, color: muted),
                const SizedBox(width: Space.xs),
                Expanded(child: Text(node.text, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        if (lines.length > maxLines)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: Space.xs),
            child: Text(
              context.l10n.importMoreLines(lines.length - maxLines),
              style: context.text.bodySmall?.copyWith(color: muted),
            ),
          ),
      ],
    );
  }
}

/// Import file → new checklist (T4.5.08).
Future<void> importFileAsNewList(BuildContext context, WidgetRef ref) async {
  final picked = await pickImportFile(context, ref);
  if (picked == null || !context.mounted) return;
  final (result, name) = picked;
  if (result.isEmpty) {
    showInfoSnackBar(context, context.l10n.importWarningEmpty);
    return;
  }
  final ok = await _confirmImport(context, result);
  if (ok != true || !context.mounted) return;
  final created = await ref.read(checklistsRepositoryProvider).create(title: result.title ?? name, items: result.nodes);
  if (!context.mounted) return;
  showUndoSnackBar(context, ref, message: context.l10n.importDone(result.count), record: created.record);
  await openChecklist(context, created.id);
}

Future<bool?> _confirmImport(BuildContext context, ImportResult result) => showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(ctx.l10n.importTitle),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ctx.l10n.importItemsCount(result.count)),
        for (final w in result.warnings)
          Text(importWarningText(ctx, w), style: TextStyle(color: ctx.appColors.warning)),
        const SizedBox(height: Space.sm),
        Flexible(
          child: SingleChildScrollView(child: ImportPreview(result: result)),
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.actionCancel)),
      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.importAction)),
    ],
  ),
);

/// Paste / type text to import under [parentId] (or the focus root) of an open checklist.
Future<void> showImportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String checklistId,
  String? parentId,
}) async {
  final text = await showDialog<String>(context: context, builder: (_) => const _ImportTextDialog());
  if (text == null || !context.mounted) return;
  if (identical(text, _chooseFile)) {
    final picked = await pickImportFile(context, ref);
    if (picked == null || !context.mounted) return;
    await _insert(context, ref, checklistId, parentId, picked.$1);
    return;
  }
  await _insert(context, ref, checklistId, parentId, ChecklistImport.parse(text));
}

/// The paste box of the import dialog; it owns its controller so the text field keeps working
/// while the dialog animates out.
class _ImportTextDialog extends StatefulWidget {
  const _ImportTextDialog();

  @override
  State<_ImportTextDialog> createState() => _ImportTextDialogState();
}

class _ImportTextDialogState extends State<_ImportTextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.importTitle),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 6,
              maxLines: 12,
              decoration: InputDecoration(hintText: l.importPasteHint, border: const OutlineInputBorder()),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.file_open_outlined),
                label: Text(l.importChooseFile),
                onPressed: () => Navigator.pop(context, _chooseFile),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: Text(l.importAction)),
      ],
    );
  }
}

/// Sentinel returned by the import dialog's "Choose file" button.
const _chooseFile = '\u0000file';

Future<void> _insert(
  BuildContext context,
  WidgetRef ref,
  String checklistId,
  String? parentId,
  ImportResult result,
) async {
  if (result.isEmpty) {
    showInfoSnackBar(context, context.l10n.importWarningEmpty);
    return;
  }
  final record = await ref
      .read(checklistEditorProvider(checklistId).notifier)
      .insertNodes(result.nodes, parentId: parentId);
  if (record != null && context.mounted) {
    showInfoSnackBar(
      context,
      [
        context.l10n.importDone(result.count),
        for (final w in result.warnings) importWarningText(context, w),
      ].join('\n'),
    );
  }
}

/// Multi-line paste into a row (T4.2.09 / T4.5.08): split into items (keeping nesting) or keep
/// as one item. Returns true when the paste was handled as items.
Future<bool> handleMultilinePaste(
  BuildContext context,
  WidgetRef ref, {
  required String checklistId,
  required String itemId,
  required String pasted,
}) async {
  final result = ChecklistImport.parse(pasted);
  if (result.count < 2) return false;
  final l = context.l10n;
  final split = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.importItemsCount(result.count)),
      content: SingleChildScrollView(child: ImportPreview(result: result)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.importKeepOne)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.importSplitCount(result.count))),
      ],
    ),
  );
  if (split != true) return false;
  final tree = ref.read(checklistTreeProvider(checklistId));
  await ref
      .read(checklistEditorProvider(checklistId).notifier)
      .run(
        'import',
        (t, ctx, _) => TreeOps.insertNodes(t, ctx, result.nodes, parentId: t.parentOf(itemId), afterId: itemId),
        cause: 'import',
        focusResult: false,
      );
  return tree != null;
}

/// Keep's "show checkboxes": each body line becomes an item, indentation becomes nesting; the
/// body is cleared in the same operation (T4.5.08).
Future<void> convertBodyToItems(BuildContext context, WidgetRef ref, Checklist checklist) async {
  final body = checklist.body;
  if (body == null || body.trim().isEmpty) return;
  final result = ChecklistImport.parseText(body);
  if (result.isEmpty) return;
  await ref
      .read(checklistEditorProvider(checklist.id).notifier)
      .run(
        'import',
        (t, ctx, _) => TreeOps.insertNodes(t, ctx, result.nodes).merge(
          TreeChange(
            writes: [
              RowWrite.update('checklists', checklist.id, {'body': null}),
            ],
          ),
        ),
        cause: 'import',
        focusResult: false,
      );
}

enum ExportFormat { markdown, plain, opml }

/// Share / export sheet (T4.5.09): whole list or the focused branch; clipboard or share sheet.
Future<void> showExportSheet(
  BuildContext context,
  WidgetRef ref, {
  required Checklist checklist,
  required ChecklistTree tree,
  String? branchRootId,
}) async {
  final names = await ref.read(checklistItemsRepositoryProvider).attachmentNames(checklist.id);
  if (!context.mounted) return;
  await showAppSheet<void>(
    context,
    title: context.l10n.exportTitle,
    builder: (ctx) =>
        _ExportSheet(checklist: checklist, tree: tree, branchRootId: branchRootId, attachmentNames: names),
  );
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.checklist, required this.tree, required this.attachmentNames, this.branchRootId});

  final Checklist checklist;
  final ChecklistTree tree;
  final String? branchRootId;
  final Map<String, List<String>> attachmentNames;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  ExportFormat _format = ExportFormat.markdown;
  bool _branch = false;

  String _text() {
    final root = _branch ? widget.branchRootId : null;
    final title = root == null ? widget.checklist.title : widget.tree[root]?.text ?? widget.checklist.title;
    return switch (_format) {
      ExportFormat.markdown => ChecklistExport.markdown(
        widget.tree,
        title: title,
        rootId: root,
        attachmentNames: widget.attachmentNames,
      ),
      ExportFormat.plain => ChecklistExport.plainText(widget.tree, title: title, rootId: root),
      ExportFormat.opml => ChecklistExport.opml(widget.tree, title: title, rootId: root),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<ExportFormat>(
            segments: [
              ButtonSegment(value: ExportFormat.markdown, label: Text(l.exportMarkdown)),
              ButtonSegment(value: ExportFormat.plain, label: Text(l.exportPlain)),
              ButtonSegment(value: ExportFormat.opml, label: Text(l.exportOpml)),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          if (widget.branchRootId != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _branch,
              title: Text(l.exportBranchOnly),
              onChanged: (v) => setState(() => _branch = v),
            ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: Text(l.exportCopy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _text()));
                    if (context.mounted) {
                      Navigator.pop(context);
                      showInfoSnackBar(context, l.exportCopied);
                    }
                  },
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l.exportShare),
                  onPressed: () async {
                    final text = _text();
                    Navigator.pop(context);
                    await SharePlus.instance.share(ShareParams(text: text, title: widget.checklist.title));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
