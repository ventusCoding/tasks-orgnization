import 'dart:async';

import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/domain/attachment.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/integrations/application/integration_providers.dart';
import 'package:everslot/features/integrations/application/share_intake_service.dart';
import 'package:everslot/features/integrations/domain/shared_content.dart';
import 'package:everslot/features/search/application/search_providers.dart';
import 'package:everslot/features/search/domain/search_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Where shared content goes (T8.2.07).
enum ShareDestination { task, list, attach }

/// Dropdown value for "new list".
const _newList = '\u0000new';

/// Opens the destination sheet for the pending shared content (no-op when nothing waits).
Future<void> showShareIntake(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final service = container.read(shareIntakeServiceProvider);
  final content = service.pending;
  if (content == null) return;
  final saved = await showAppSheet<bool>(
    context,
    title: context.l10n.shareTitle,
    builder: (_) => ShareIntakeSheet(content: content),
  );
  if (saved != true) await service.finish();
}

class ShareIntakeSheet extends ConsumerStatefulWidget {
  const ShareIntakeSheet({required this.content, super.key});

  final SharedContent content;

  @override
  ConsumerState<ShareIntakeSheet> createState() => _ShareIntakeSheetState();
}

class _ShareIntakeSheetState extends ConsumerState<ShareIntakeSheet> {
  late ShareDestination _dest = widget.content.text.contains('\n') ? ShareDestination.list : ShareDestination.task;

  /// Multi-line text with no list yet: suggest a new list.
  @override
  void initState() {
    super.initState();
    if (_dest == ShareDestination.list) _checklistId = _newList;
  }

  late final _title = TextEditingController(text: widget.content.taskTitle ?? '');
  final _query = TextEditingController();
  String? _checklistId;
  String? _parentId;
  SearchResult? _target;
  List<SearchResult> _results = const [];
  var _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _query.dispose();
    super.dispose();
  }

  bool get _canSave => switch (_dest) {
    ShareDestination.task => _title.text.trim().isNotEmpty || widget.content.files.isNotEmpty,
    ShareDestination.list => _checklistId != null,
    ShareDestination.attach => _target != null && widget.content.files.isNotEmpty,
  };

  Future<void> _search(String q) async {
    final results = q.trim().isEmpty
        ? const <SearchResult>[]
        : await ref.read(globalSearchQueriesProvider).search(q, kinds: {SearchKind.task, SearchKind.item}, limit: 20);
    if (mounted) setState(() => _results = results);
  }

  Future<void> _save() async {
    final l = context.l10n;
    final service = ref.read(shareIntakeServiceProvider);
    final content = widget.content;
    setState(() => _saving = true);
    String? link;
    try {
      link = await _write(service, content);
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        showInfoSnackBar(context, l.integrationsActionFailed);
      }
      return;
    }
    await service.finish();
    if (!mounted) return;
    final router = GoRouter.maybeOf(context);
    Navigator.pop(context, true);
    showInfoSnackBar(context, l.shareSaved);
    if (link != null) unawaited(router?.push(link));
  }

  Future<String?> _write(ShareIntakeService service, SharedContent content) async {
    String? link;
    switch (_dest) {
      case ShareDestination.task:
        final id = await service.createTask(content, title: _title.text.trim().isEmpty ? null : _title.text.trim());
        link = AppLinks.task(id);
      case ShareDestination.list when _checklistId == _newList:
        link = AppLinks.checklist(await service.createChecklist(content));
      case ShareDestination.list:
        final id = await service.addToChecklist(content, _checklistId!, parentId: _parentId);
        link = id == null ? AppLinks.checklist(_checklistId!) : AppLinks.checklistItem(_checklistId!, id);
      case ShareDestination.attach:
        final t = _target!;
        await service.attachTo(
          content,
          t.kind == SearchKind.task ? AttachmentOwnerType.task : AttachmentOwnerType.checklistItem,
          t.id,
        );
        link = t.link;
    }
    return link;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final content = widget.content;
    final lists = ref.watch(boardChecklistsProvider).value ?? const <Checklist>[];
    final items = _checklistId == null || _checklistId == _newList
        ? const <ChecklistItem>[]
        : (ref.watch(checklistItemsProvider(_checklistId!)).value ?? const <ChecklistItem>[]);
    final itemCount = ShareIntake.itemsFor(
      content,
      filesTitle: l.shareFilesTitle(content.files.length),
    ).fold(0, (n, node) => n + node.size);
    return ListView(
      key: const ValueKey('share-sheet'),
      shrinkWrap: true,
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      children: [
        if (content.text.trim().isNotEmpty)
          Text(content.text.trim(), maxLines: 4, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium),
        if (content.files.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: Space.sm),
            child: Wrap(
              spacing: Space.sm,
              children: [
                Chip(
                  avatar: const Icon(Icons.attach_file, size: 18),
                  label: Text(l.shareFilesTitle(content.files.length)),
                ),
              ],
            ),
          ),
        const SizedBox(height: Space.md),
        SegmentedButton<ShareDestination>(
          segments: [
            ButtonSegment(
              value: ShareDestination.task,
              icon: const Icon(Icons.add_task),
              label: Text(l.shareAsTask, key: const ValueKey('share-dest-task')),
            ),
            ButtonSegment(
              value: ShareDestination.list,
              icon: const Icon(Icons.checklist),
              label: Text(l.shareToList, key: const ValueKey('share-dest-list')),
            ),
            ButtonSegment(
              value: ShareDestination.attach,
              icon: const Icon(Icons.attach_file),
              enabled: content.files.isNotEmpty,
              label: Text(l.shareAttach, key: const ValueKey('share-dest-attach')),
            ),
          ],
          selected: {_dest},
          onSelectionChanged: (s) => setState(() => _dest = s.single),
        ),
        const SizedBox(height: Space.md),
        ...switch (_dest) {
          ShareDestination.task => [
            TextField(
              key: const ValueKey('share-title'),
              controller: _title,
              decoration: InputDecoration(labelText: l.quickAddTitleHint),
              onChanged: (_) => setState(() {}),
            ),
          ],
          ShareDestination.list => [
            DropdownButtonFormField<String>(
              key: const ValueKey('share-list'),
              initialValue: _checklistId,
              decoration: InputDecoration(labelText: l.quickAddPickList),
              items: [
                DropdownMenuItem(
                  value: _newList,
                  child: Text(l.shareNewList(ShareIntake.newList(content, fallbackTitle: '').title)),
                ),
                for (final c in lists) DropdownMenuItem(value: c.id, child: Text(c.title)),
              ],
              onChanged: (v) => setState(() {
                _checklistId = v;
                _parentId = null;
              }),
            ),
            if (_checklistId != null && _checklistId != _newList) ...[
              const SizedBox(height: Space.sm),
              DropdownButtonFormField<String?>(
                key: const ValueKey('share-parent'),
                initialValue: _parentId,
                decoration: InputDecoration(labelText: l.shareUnder),
                items: [
                  DropdownMenuItem(child: Text(l.shareTopLevel)),
                  for (final i in items)
                    if (i.parentId == null) DropdownMenuItem(value: i.id, child: Text(i.text)),
                ],
                onChanged: (v) => setState(() => _parentId = v),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: Space.xs),
                child: Text(l.shareItemCount(itemCount), style: context.text.bodySmall),
              ),
            ],
          ],
          ShareDestination.attach => [
            TextField(
              key: const ValueKey('share-search'),
              controller: _query,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), labelText: l.shareFindItem),
              onChanged: (q) => unawaited(_search(q)),
            ),
            for (final r in _results)
              ListTile(
                key: ValueKey('share-result-${r.id}'),
                leading: Icon(_target?.id == r.id ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text(r.title),
                subtitle: r.breadcrumb.isEmpty ? null : Text(r.breadcrumb.join(' › ')),
                selected: _target?.id == r.id,
                onTap: () => setState(() => _target = r),
              ),
          ],
        },
        const SizedBox(height: Space.md),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton(
            key: const ValueKey('share-save'),
            onPressed: !_canSave || _saving ? null : () => unawaited(_save()),
            child: Text(l.actionSave),
          ),
        ),
      ],
    );
  }
}
