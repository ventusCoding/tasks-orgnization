import 'dart:async';
import 'dart:io';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/data/share_source.dart';
import 'package:everslot/features/integrations/domain/shared_content.dart';
import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Share into Everslot (T8.2.07): keeps what was shared until the user picks a destination —
/// a new task, items in a checklist (optionally under an item) or attachments of an existing item.
/// Files are attached locally and queued for upload (offline-safe).
class ShareIntakeService {
  ShareIntakeService(this._ref, this._source, this._events);

  final Ref _ref;
  final ShareSource _source;
  final BufferedEventBus<IntegrationUiEvent> _events;
  StreamSubscription<SharedContent>? _sub;
  static final _log = AppLog.get('integrations.share');

  /// The content waiting for a destination.
  SharedContent? pending;

  Future<void> start() async {
    if (_sub != null) return;
    _sub = _source.incoming.listen(receive);
    try {
      final initial = await _source.initial();
      if (initial != null) receive(initial);
    } on Object catch (e) {
      _log.info('share intake unavailable: $e');
    }
  }

  void receive(SharedContent content) {
    if (content.isEmpty) return;
    // A calendar file opens the ICS import preview instead (T8.2.12).
    final ics = content.files.where((f) => RegExp(r'\.(ics|ical)$', caseSensitive: false).hasMatch(f.path)).firstOrNull;
    if (ics != null) {
      unawaited(_receiveIcs(ics));
      return;
    }
    pending = content;
    _events.add(const ShareReceivedUiEvent());
  }

  Future<void> _receiveIcs(SharedFile file) async {
    try {
      final content = await File(file.path).readAsString();
      _events.add(IcsReceivedUiEvent(content, fileName: file.name));
    } on Object catch (e) {
      _log.info('shared calendar file unreadable: $e');
      _events.add(const NoticeUiEvent(IntegrationNotice.actionFailed));
    }
    await finish();
  }

  /// Clears the pending content (after saving or cancelling).
  Future<void> finish() async {
    pending = null;
    try {
      await _source.reset();
    } on Object {
      // Nothing to reset on this platform.
    }
  }

  /// New unscheduled task: first line = title, the rest = notes; files become its attachments.
  Future<String> createTask(SharedContent content, {String? title}) async {
    final l10n = _ref.read(plannerL10nProvider);
    final result = await _ref
        .read(plannerServiceProvider)
        .createTask(
          Task(
            id: '',
            seriesId: '',
            title: (title ?? content.taskTitle ?? l10n.shareFilesTitle(content.files.length)).trim(),
            notes: title == null
                ? content.taskNotes
                : content.text.trim().isEmpty
                ? null
                : content.text.trim(),
          ),
          source: 'share',
        );
    await _attach(AttachmentOwnerType.task, result.taskId, content.files);
    return result.taskId;
  }

  /// Items in [checklistId] (under [parentId]); returns the first new item, which carries the files.
  Future<String?> addToChecklist(SharedContent content, String checklistId, {String? parentId}) async {
    final l10n = _ref.read(plannerL10nProvider);
    final nodes = ShareIntake.itemsFor(content, filesTitle: l10n.shareFilesTitle(content.files.length));
    if (nodes.isEmpty) return null;
    final items = _ref.read(checklistItemsRepositoryProvider);
    final before = {for (final i in await items.items(checklistId)) i.id};
    await _ref
        .read(checklistServiceProvider)
        .run(checklistId, (tree, ctx, _) => TreeOps.insertNodes(tree, ctx, nodes, parentId: parentId), cause: 'share');
    final added = [
      for (final i in await items.items(checklistId))
        if (!before.contains(i.id) && i.parentId == parentId) i,
    ]..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    final first = added.firstOrNull?.id;
    if (first != null) await _attach(AttachmentOwnerType.checklistItem, first, content.files);
    return first;
  }

  /// A new list (title + items from the text, see [ShareIntake.newList]); files go on the list.
  Future<String> createChecklist(SharedContent content) async {
    final l10n = _ref.read(plannerL10nProvider);
    final spec = ShareIntake.newList(content, fallbackTitle: l10n.shareFilesTitle(content.files.length));
    final created = await _ref.read(checklistsRepositoryProvider).create(title: spec.title, items: spec.items);
    await _attach(AttachmentOwnerType.checklist, created.id, content.files);
    return created.id;
  }

  /// Files of [content] attached to an existing task / checklist item.
  Future<int> attachTo(SharedContent content, String ownerType, String ownerId) =>
      _attach(ownerType, ownerId, content.files);

  Future<int> _attach(String ownerType, String ownerId, List<SharedFile> files) async {
    if (files.isEmpty) return 0;
    final result = await _ref.read(attachmentServiceProvider).addFiles(ownerType, ownerId, [
      for (final f in files) PickedFileRef(path: f.path, name: f.name, mimeType: f.mimeType),
    ]);
    return result.added.length;
  }

  Future<void> dispose() async => _sub?.cancel();
}
