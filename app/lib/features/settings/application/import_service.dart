import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/local_account.dart';
import 'package:everslot/core/sync/table_registry.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/domain/transfer.dart' show UploadState;
import 'package:everslot/features/habits/domain/habit_records.dart' show DefaultSections, DefaultVocab, VocabKind;
import 'package:everslot/features/notifications/domain/default_rules.dart';
import 'package:everslot/features/settings/domain/export_format.dart';
import 'package:everslot/features/settings/domain/import_plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// An opened export: the document and the attachment files extracted from a zip.
class ImportBundle {
  const ImportBundle(this.document, {this.files = const []});

  final ExportDocument document;

  /// `attachments/<id>/<name>` entries of a zip export, extracted to a temporary folder.
  final List<({String id, String name, String path})> files;
}

/// Dry-run result (or what an applied import did).
class ImportPreview {
  const ImportPreview({required this.mode, required this.tables, required this.sameAccount});

  final ImportMode mode;
  final Map<String, ImportTableCounts> tables;

  /// The export was made from the signed-in account (restore is offered only then).
  final bool sameAccount;

  ImportTableCounts get total => tables.values.fold(const ImportTableCounts(), (a, b) => a + b);
}

typedef ImportProgress = ({int done, int total});

/// One planned row write.
class _Step {
  _Step(this.table, this.id, this.values, this.action);

  final String table;
  final String id;
  final Map<String, Object?> values;
  final RowAction action;
}

/// Temporary folder for attachment files of an opened zip (overridden in tests).
final importScratchDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) =>
      () async => Directory(p.join((await getTemporaryDirectory()).path, 'import')),
);

final importServiceProvider = Provider<ImportService>(ImportService.new);

/// Import / restore from an Everslot export (T8.3.08). Rows are written in batches through the
/// [SyncWriter] (outbox + activity cause `import`), so a restore syncs like any edit.
class ImportService {
  ImportService(this._ref);

  final Ref _ref;

  static const batchSize = 400;

  /// Reads a `.json` export or a `.zip` export (JSON + attachments). Throws [FormatException]
  /// (`not_an_export`, `unsupported_format`, `csv_export`) for anything else.
  Future<ImportBundle> open(File file) async {
    final scratch = await _ref.read(importScratchDirectoryProvider)();
    return Isolate.run(() => _decode(file.path, scratch.path));
  }

  static ImportBundle _decode(String path, String scratch) {
    final bytes = File(path).readAsBytesSync();
    final isZip = bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4b;
    if (!isZip) return ImportBundle(ExportDocument.parse(_json(bytes)));
    final archive = ZipDecoder().decodeBytes(bytes);
    final json = archive.findFile('everslot-export.json');
    if (json == null) {
      throw FormatException(archive.findFile('manifest.json') != null ? 'csv_export' : 'not_an_export');
    }
    final document = ExportDocument.parse(_json(json.content));
    final dir = Directory(scratch);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    final files = <({String id, String name, String path})>[];
    for (final f in archive.files) {
      final parts = f.name.split('/');
      if (!f.isFile || parts.length != 3 || parts[0] != 'attachments') continue;
      // Ids and names come from the archive: keep them inside the scratch folder.
      final (id, name) = (parts[1], parts[2]);
      if (!IdRemapper.uuid.hasMatch(id) || id.length != 36 || name.isEmpty || name.startsWith('.')) continue;
      final out = File(p.join(scratch, id, name));
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(f.content);
      files.add((id: id, name: name, path: out.path));
    }
    return ImportBundle(document, files: files);
  }

  static Object? _json(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes, allowMalformed: true));
    } on FormatException {
      throw const FormatException('not_an_export');
    }
  }

  /// Whether [bundle] comes from the signed-in account.
  bool sameAccount(ImportBundle bundle) {
    final user = _ref.read(currentUserIdProvider);
    return user.isNotEmpty && bundle.document.userId == user;
  }

  Future<ImportPreview> preview(ImportBundle bundle, ImportMode mode, {bool replaceNewer = false}) async {
    final (steps, skipped, _) = await _plan(bundle, mode, replaceNewer: replaceNewer);
    return _summary(bundle, mode, steps, skipped);
  }

  /// Applies the import; returns what was done.
  Future<ImportPreview> apply(
    ImportBundle bundle,
    ImportMode mode, {
    bool replaceNewer = false,
    void Function(ImportProgress progress)? onProgress,
  }) async {
    final (steps, skipped, remapper) = await _plan(bundle, mode, replaceNewer: replaceNewer);
    final writes = [
      for (final s in steps)
        if (s.action == RowAction.insert || s.action == RowAction.update) s,
    ];
    final writer = _ref.read(syncWriterProvider);
    onProgress?.call((done: 0, total: writes.length));
    for (var i = 0; i < writes.length; i += batchSize) {
      final batch = writes.sublist(i, (i + batchSize).clamp(0, writes.length));
      await writer.run((tx) async {
        for (final s in batch) {
          if (s.action == RowAction.insert) {
            await tx.insert(s.table, s.id, s.values);
          } else {
            await tx.update(s.table, s.id, s.values);
          }
        }
      }, cause: 'import');
      onProgress?.call((done: i + batch.length, total: writes.length));
    }
    await _restoreFiles(bundle, mode, remapper, {
      for (final s in steps)
        if (s.table == 'attachments' && s.action != RowAction.skip) s.id: s,
    });
    return _summary(bundle, mode, steps, skipped);
  }

  Future<void> _restoreFiles(
    ImportBundle bundle,
    ImportMode mode,
    IdRemapper? remapper,
    Map<String, _Step> attachments,
  ) async {
    if (bundle.files.isEmpty) return;
    final store = _ref.read(attachmentFileStoreProvider);
    final cache = _ref.read(attachmentCacheStoreProvider);
    var queued = false;
    for (final f in bundle.files) {
      final id = remapper?.idOf(f.id) ?? f.id;
      final step = attachments[id];
      if (step == null) continue;
      final rel = p.join(id, f.name);
      final source = File(f.path);
      if (!source.existsSync()) continue;
      if (!await store.exists(rel)) await store.copyFrom(rel, source);
      final uploaded = mode == ImportMode.restore && step.values['uploaded_at'] != null;
      await cache.putLocal(
        id,
        originalRel: rel,
        thumbRel: null,
        bytes: source.lengthSync(),
        uploadState: uploaded ? UploadState.done : UploadState.pending,
      );
      queued |= !uploaded;
    }
    if (queued) _ref.read(attachmentUploadQueueProvider).kick();
  }

  ImportPreview _summary(ImportBundle bundle, ImportMode mode, List<_Step> steps, Map<String, int> skipped) {
    final counts = <String, ImportTableCounts>{
      for (final e in skipped.entries) e.key: ImportTableCounts(skipped: e.value),
    };
    for (final s in steps) {
      final c = switch (s.action) {
        RowAction.insert => const ImportTableCounts(added: 1),
        RowAction.update => const ImportTableCounts(updated: 1),
        RowAction.unchanged => const ImportTableCounts(unchanged: 1),
        RowAction.keepLocal => const ImportTableCounts(keptLocal: 1),
        RowAction.skip => const ImportTableCounts(skipped: 1),
      };
      counts[s.table] = (counts[s.table] ?? const ImportTableCounts()) + c;
    }
    return ImportPreview(mode: mode, tables: counts, sameAccount: sameAccount(bundle));
  }

  Future<(List<_Step>, Map<String, int>, IdRemapper?)> _plan(
    ImportBundle bundle,
    ImportMode mode, {
    required bool replaceNewer,
  }) async {
    final user = _ref.read(currentUserIdProvider);
    if (user.isEmpty) throw StateError('No signed-in user');
    if (mode == ImportMode.restore && !sameAccount(bundle)) {
      throw StateError('Restore needs an export of the signed-in account');
    }
    final registry = _ref.read(tableRegistryProvider);
    final doc = bundle.document;
    final remapper = mode == ImportMode.copy
        ? IdRemapper(
            document: doc,
            oldUser: doc.userId ?? '',
            newUser: user,
            recipes: standardIdRecipes,
            v5: Ids.v5,
            v7: Ids.v7,
          )
        : null;
    final steps = <_Step>[];
    final skipped = <String, int>{};
    // Registry order (parents before children) rather than file order.
    final tables = [
      for (final t in registry.tables)
        if (doc.tables.containsKey(t.name)) t,
    ];
    for (final name in doc.tables.keys) {
      if (!registry.isSynced(name)) skipped[name] = doc.tables[name]!.length;
    }
    for (final t in tables) {
      final rows = doc.tables[t.name]!;
      // The target account keeps its own profile.
      if (mode == ImportMode.copy && t.name == 'profiles') {
        skipped[t.name] = rows.length;
        continue;
      }
      final planned = <({Map<String, Object?> raw, Map<String, Object?> values})>[];
      for (final row in rows) {
        final r = remapper == null ? row : remapper.remapRow(row);
        if (remapper != null && remapper.unmatched.contains(row['id'])) {
          skipped[t.name] = (skipped[t.name] ?? 0) + 1;
          continue;
        }
        planned.add((raw: r, values: _clean(t, r, copy: mode == ImportMode.copy)));
      }
      final local = await _localRows(t, [for (final r in planned) r.raw['id']! as String]);
      for (final (:raw, :values) in planned) {
        final id = raw['id']! as String;
        // Last writer wins on the exported `updated_at` (dropped from the written values).
        final action = ImportRules.decide(raw, local[id], replaceNewer: replaceNewer);
        values.remove('id');
        if (action == RowAction.update && local[id]?['deleted_at'] != null) values['deleted_at'] = null;
        steps.add(_Step(t.name, id, values, action));
      }
    }
    return (steps, skipped, remapper);
  }

  /// Known columns only, writer-managed ones dropped; a copy's attachments upload again.
  static Map<String, Object?> _clean(RegisteredTable t, Map<String, Object?> row, {required bool copy}) => {
    for (final e in row.entries)
      if (t.kinds.containsKey(e.key) &&
          !ExportFormat.internalColumns.contains(e.key) &&
          !ImportRules.managedColumns.contains(e.key))
        e.key: e.value,
    if (copy && t.name == 'attachments') ...{'uploaded_at': null, 'thumb_path': null},
  };

  /// Local rows (server representation, deleted ones included) by id.
  Future<Map<String, Map<String, Object?>>> _localRows(RegisteredTable t, List<String> ids) async {
    final db = _ref.read(appDatabaseProvider);
    final out = <String, Map<String, Object?>>{};
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, (i + 500).clamp(0, ids.length));
      final rows = await db
          .customSelect(
            'SELECT * FROM ${t.name} WHERE id IN (${List.filled(chunk.length, '?').join(', ')})',
            variables: [for (final id in chunk) Variable<String>(id)],
          )
          .get();
      for (final r in rows) {
        out[r.data['id']! as String] = {for (final e in r.data.entries) e.key: t.sqliteToServer(e.key, e.value)};
      }
    }
    return out;
  }
}

/// Deterministic-id formulas of every feature (arch §9.2; `Ids`, `HabitIds`, `DefaultRules`,
/// `LocalAccount.userScopedIdRules`), re-derived for the new owner by a copy import.
final IdRecipes standardIdRecipes = {
  'user_settings': (r, ref, u) => ['$u|${r['namespace']}'],
  'notification_profiles': (r, ref, u) => [if (r['code'] != null) '$u|profile|${r['code']}'],
  'categories': (r, ref, u) => [
    for (final rule in LocalAccount.userScopedIdRules)
      for (final k in rule.keys) '$u|default-category|$k',
  ],
  'habit_sections': (r, ref, u) => [for (final s in DefaultSections.all) '$u|habit_section|${s.$1}'],
  'habit_vocab': (r, ref, u) => [
    for (final k in VocabKind.values.where((k) => k.name == r['kind']).expand(DefaultVocab.keysFor))
      '$u|habit_vocab|${r['kind']}|$k',
  ],
  'notification_rules': (r, ref, u) => [
    for (final s in DefaultRules.seeds) '$u|default-rule|${s.section.wire}|${s.code}',
    for (final kind in DefaultRules.digestDefaultTimes.keys) '$u|digest-rule|$kind',
  ],
  'task_occurrences': (r, ref, u) => ['${ref('${r['task_id']}')}|${r['occurrence_key']}'],
  'entity_tags': (r, ref, u) => ['${ref('${r['tag_id']}')}|${r['entity_type']}|${ref('${r['entity_id']}')}'],
  'checklist_runs': (r, ref, u) => ['${ref('${r['checklist_id']}')}|${r['occurrence_key']}'],
  'habit_logs': (r, ref, u) {
    final h = ref('${r['habit_id']}');
    final keys = {?r['occurrence_key'] as String?, '${r['local_date']}'};
    return [
      for (final k in keys) ...['$h|$k|state', '$h|$k|pledge', '$h|$k|note', '$h|$k|health'],
    ];
  },
  'habit_revisions': (r, ref, u) => ['${ref('${r['habit_id']}')}|${r['effective_from']}|revision'],
  'achievements': (r, ref, u) => [
    '${r['code']}|${r['scope_type'] ?? ''}|${r['scope_id'] == null ? '' : ref('${r['scope_id']}')}',
  ],
  // The inbox id is uuidv5(dedupe_key); the key embeds the ids it is about.
  'notifications': (r, ref, u) => ['${r['dedupe_key']}'.replaceAllMapped(IdRemapper.uuid, (m) => ref(m[0]!))],
  'saved_views': (r, ref, u) => ['$u|saved_view|lists_board'],
};
