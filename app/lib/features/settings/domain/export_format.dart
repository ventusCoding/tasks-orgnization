import 'dart:convert';

/// Everslot data export, format v1 (T8.3.07; schema: `fixtures/schemas/export-v1.json`).
///
/// ```json
/// {"format": "everslot-export-v1", "schema_version": 1, "exported_at": "…Z", "app_version": "1.0.0+1",
///  "counts": {"tasks": 2, …}, "tables": {"tasks": [{"id": "…", …}], …}}
/// ```
/// One array per synced table, live rows only, values in the server JSON representation
/// (instants as UTC ISO-8601, JSON columns as objects, booleans as booleans). Sync internals
/// (`user_id`, `rev`, `field_clock`, `server_updated_at`) are left out.
abstract final class ExportFormat {
  static const id = 'everslot-export-v1';
  static const version = 1;

  /// Columns never exported (account / sync internals).
  static const internalColumns = {'user_id', 'rev', 'field_clock', 'server_updated_at'};

  static Map<String, Object?> document({
    required int schemaVersion,
    required DateTime exportedAt,
    required String appVersion,
    required Map<String, List<Map<String, Object?>>> tables,
  }) => {
    'format': id,
    'schema_version': schemaVersion,
    'exported_at': exportedAt.toUtc().toIso8601String(),
    'app_version': appVersion,
    'counts': {for (final e in tables.entries) e.key: e.value.length},
    'tables': tables,
  };

  /// Pretty enough to diff, compact enough for 100 000 rows.
  static List<int> encodeJson(Map<String, Object?> document) => utf8.encode(jsonEncode(document));

  /// File name for an export made at [at] (`everslot-export-20260928-1405.json`).
  static String fileName(DateTime at, String extension) {
    String two(int v) => v.toString().padLeft(2, '0');
    final t = at.toUtc();
    return 'everslot-export-${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}.$extension';
  }
}

/// RFC 4180 CSV for spreadsheets (T8.3.07): UTF-8 with BOM (Excel reads Arabic correctly),
/// CRLF line ends, quotes doubled, and cells that a spreadsheet would run as a formula
/// (`=`, `+`, `-`, `@`, tab, CR at the start) prefixed with `'`.
abstract final class Csv {
  static const bom = '﻿';

  static String cell(Object? value) {
    if (value == null) return '';
    var s = switch (value) {
      final String v => v,
      final bool v => v ? 'true' : 'false',
      final num v => v.toString(),
      final Map<Object?, Object?> v => jsonEncode(v),
      final List<Object?> v => jsonEncode(v),
      _ => value.toString(),
    };
    if (value is String && s.isNotEmpty && const {'=', '+', '-', '@', '\t', '\r'}.contains(s[0])) {
      s = "'$s";
    }
    final needsQuotes =
        s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r') ||
        s.startsWith(' ') ||
        s.endsWith(' ');
    return needsQuotes ? '"${s.replaceAll('"', '""')}"' : s;
  }

  static String encode(List<String> header, Iterable<List<Object?>> rows) {
    final b = StringBuffer(bom)..write(header.map(cell).join(','));
    for (final r in rows) {
      b
        ..write('\r\n')
        ..write(r.map(cell).join(','));
    }
    b.write('\r\n');
    return b.toString();
  }

  /// `start_local` → `Start local`, `id` → `ID`, `checklist_id` → `Checklist ID`.
  static String humanize(String column) {
    final words = column.split('_').where((w) => w.isNotEmpty).map((w) => w == 'id' ? 'ID' : w).toList();
    if (words.isEmpty) return column;
    final first = words.first == 'ID' ? 'ID' : '${words.first[0].toUpperCase()}${words.first.substring(1)}';
    return [first, ...words.skip(1)].join(' ');
  }

  /// A table as CSV: human headers in [columns] order.
  static String table(List<String> columns, List<Map<String, Object?>> rows) => encode(
    [for (final c in columns) humanize(c)],
    [
      for (final r in rows) [for (final c in columns) r[c]],
    ],
  );
}
