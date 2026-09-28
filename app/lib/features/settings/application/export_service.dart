import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:everslot/core/database/app_database.dart' show AppDatabase;
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/settings/data/export_source.dart';
import 'package:everslot/features/settings/domain/export_format.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ExportKind { json, csv }

/// Rows read so far / total (encoding and writing happen after 100 %).
typedef ExportProgress = ({int done, int total});

/// Where exports are written (`<documents>/exports`, wiped on sign-out). Overridden in tests.
final exportDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => () async => Directory(p.join((await getApplicationDocumentsDirectory()).path, 'exports')),
);

/// "1.2.0+34" (falls back to the build number when package info is unavailable).
final appVersionLabelProvider = Provider<Future<String> Function()>((ref) {
  final build = ref.watch(appBuildProvider);
  return () async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } on Object {
      return '0.0.0+$build';
    }
  };
});

/// Hands a file to the system share sheet (overridden in tests).
final shareFileProvider = Provider<Future<void> Function(File file, {String? subject})>(
  (ref) => (file, {subject}) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: subject));
  },
);

final exportSourceProvider = Provider<ExportSource>(
  (ref) => ExportSource(ref.watch(appDatabaseProvider), ref.watch(tableRegistryProvider)),
);

final exportServiceProvider = Provider<ExportService>(ExportService.new);

/// Export all data (T8.3.07): works offline from the local database. JSON (`everslot-export-v1`)
/// or a zip of CSV files; with attachments the result is a zip holding the files under
/// `attachments/<id>/`. Encoding runs in a background isolate.
class ExportService {
  ExportService(this._ref);

  final Ref _ref;

  Future<File> export({
    required ExportKind kind,
    bool includeAttachments = false,
    void Function(ExportProgress progress)? onProgress,
  }) async {
    final source = _ref.read(exportSourceProvider);
    final AppDatabase db = _ref.read(appDatabaseProvider);
    final now = _ref.read(clockProvider).nowUtc();
    final counts = await source.counts();
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    var done = 0;
    onProgress?.call((done: 0, total: total));
    final tables = <String, List<Map<String, Object?>>>{};
    for (final t in source.tables) {
      final rows = <Map<String, Object?>>[];
      while (rows.length < counts[t]!) {
        final page = await source.page(t, rows.length);
        if (page.isEmpty) break;
        rows.addAll(page);
        done += page.length;
        onProgress?.call((done: done, total: total));
      }
      tables[t] = rows;
    }
    final files = includeAttachments
        ? await source.attachmentFiles(await _ref.read(attachmentFileStoreProvider).root())
        : const <({String id, String name, String path})>[];
    final columns = {for (final t in source.tables) t: source.columns(t)};
    final job = _ExportJob(
      kind: kind,
      schemaVersion: db.schemaVersion,
      exportedAt: now,
      appVersion: await _ref.read(appVersionLabelProvider)(),
      tables: tables,
      columns: columns,
      files: [for (final f in files) (zipPath: 'attachments/${f.id}/${f.name}', path: f.path)],
    );
    final zipped = kind == ExportKind.csv || job.files.isNotEmpty;
    final bytes = await Isolate.run(job.encode);
    final dir = await _ref.read(exportDirectoryProvider)();
    await dir.create(recursive: true);
    final out = File(p.join(dir.path, ExportFormat.fileName(now, zipped ? 'zip' : 'json')));
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }
}

/// Everything the encoding isolate needs (plain, sendable data).
class _ExportJob {
  const _ExportJob({
    required this.kind,
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.tables,
    required this.columns,
    required this.files,
  });

  final ExportKind kind;
  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;
  final Map<String, List<Map<String, Object?>>> tables;
  final Map<String, List<String>> columns;
  final List<({String zipPath, String path})> files;

  List<int> encode() {
    final document = ExportFormat.document(
      schemaVersion: schemaVersion,
      exportedAt: exportedAt,
      appVersion: appVersion,
      tables: tables,
    );
    if (kind == ExportKind.json && files.isEmpty) return ExportFormat.encodeJson(document);
    final archive = Archive();
    if (kind == ExportKind.json) {
      archive.add(ArchiveFile.bytes('everslot-export.json', ExportFormat.encodeJson(document)));
    } else {
      for (final e in tables.entries) {
        archive.add(ArchiveFile.bytes('${e.key}.csv', utf8.encode(Csv.table(columns[e.key]!, e.value))));
      }
      final manifest = Map<String, Object?>.from(document)..remove('tables');
      archive.add(ArchiveFile.bytes('manifest.json', utf8.encode(jsonEncode(manifest))));
    }
    for (final f in files) {
      final file = File(f.path);
      if (file.existsSync()) archive.add(ArchiveFile.bytes(f.zipPath, file.readAsBytesSync()));
    }
    return ZipEncoder().encodeBytes(archive);
  }
}
