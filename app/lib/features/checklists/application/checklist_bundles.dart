import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/bundle.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/import_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Zip bundles of a list and its item files (T4.4.08): `<title>.md` + `files/…`. Import re-attaches
/// the files through the attachment pipeline (processing, local cache, upload queue).
class ChecklistBundles {
  ChecklistBundles(this._ref);

  final Ref _ref;

  /// The bundle of [checklistId]. Files that are not available on this device (never
  /// downloaded, remote unavailable) stay listed by name only.
  Future<Uint8List> export(String checklistId) async {
    final list = await _ref.read(checklistsRepositoryProvider).byId(checklistId);
    final itemsRepo = _ref.read(checklistItemsRepositoryProvider);
    final tree = ChecklistTree.build(await itemsRepo.items(checklistId));
    final attachments = await itemsRepo.watchChecklistAttachments(checklistId).first;
    final downloader = _ref.read(attachmentDownloaderProvider);
    final archive = Archive();
    final refs = <String, List<String>>{};
    var n = 0;
    for (final a in attachments) {
      if (a.ownerType != AttachmentOwnerType.checklistItem || !tree.contains(a.ownerId)) continue;
      String? path;
      try {
        path = await downloader.ensureOriginal(a);
      } on Object {
        path = null;
      }
      final file = path == null ? null : File(path);
      if (file == null || !file.existsSync()) {
        (refs[a.ownerId] ??= []).add(a.fileName);
        continue;
      }
      final entry = ChecklistBundle.entryPath(n++, a.fileName);
      archive.add(ArchiveFile.bytes(entry, await file.readAsBytes()));
      (refs[a.ownerId] ??= []).add(entry);
    }
    final title = list?.title ?? '';
    final markdown = ChecklistExport.markdown(tree, title: title, attachmentNames: refs);
    archive.add(ArchiveFile.bytes(ChecklistBundle.textName(title), utf8.encode(markdown)));
    return ZipEncoder().encodeBytes(archive);
  }

  /// Creates a new list from a bundle and re-attaches its files (extracted under [scratch], or a
  /// temporary folder removed afterwards). Returns the new list id, or null when the bundle has
  /// no Markdown file.
  Future<String?> import(List<int> bytes, {Directory? scratch, String fallbackTitle = ''}) async {
    final temp = scratch ?? await Directory.systemTemp.createTemp('everslot_bundle');
    try {
      return await _import(bytes, temp, fallbackTitle);
    } finally {
      if (scratch == null && temp.existsSync()) await temp.delete(recursive: true);
    }
  }

  Future<String?> _import(List<int> bytes, Directory scratch, String fallbackTitle) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? text;
    for (final f in archive.files) {
      if (f.isFile && !f.name.contains('/') && f.name.toLowerCase().endsWith('.md')) {
        text = f;
        break;
      }
    }
    if (text == null) return null;
    final result = ChecklistImport.parseText(utf8.decode(text.content), keepAttachments: true);
    final created = await _ref
        .read(checklistsRepositoryProvider)
        .create(title: result.title ?? fallbackTitle, items: result.nodes);
    // Items were created in the parsed preorder: the new tree's order maps them back.
    final order = ChecklistTree.build(await _ref.read(checklistItemsRepositoryProvider).items(created.id)).order;
    final service = _ref.read(attachmentServiceProvider);
    for (var i = 0; i < order.length && i < result.attachmentRefs.length; i++) {
      final files = <PickedFileRef>[];
      for (final ref in result.attachmentRefs[i].where(ChecklistBundle.isEntryPath)) {
        final entry = archive.findFile(ref);
        if (entry == null) continue;
        final name = ChecklistBundle.originalName(ref);
        final out = File('${scratch.path}/${i}_${files.length}_$name');
        await out.writeAsBytes(entry.content, flush: true);
        files.add(PickedFileRef(path: out.path, name: name));
      }
      if (files.isNotEmpty) await service.addFiles(AttachmentOwnerType.checklistItem, order[i], files);
    }
    return created.id;
  }
}

final checklistBundlesProvider = Provider<ChecklistBundles>(ChecklistBundles.new);
