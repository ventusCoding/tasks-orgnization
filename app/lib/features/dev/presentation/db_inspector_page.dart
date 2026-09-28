import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/dev/application/dev_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Local tables with their row counts; a table opens its first rows (T1.3.16).
class DbInspectorPage extends ConsumerWidget {
  const DbInspectorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final counts = ref.watch(devTableCountsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.devDatabase),
        actions: [
          IconButton(
            tooltip: l.actionRetry,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(devTableCountsProvider),
          ),
        ],
      ),
      body: counts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: '$e'),
        data: (tables) => ListView(
          children: [
            for (final t in tables)
              ListTile(
                key: ValueKey('dev-table-${t.table}'),
                dense: true,
                title: Text(t.table),
                trailing: Text(l.devDatabaseRows(t.rows)),
                onTap: t.rows == 0
                    ? null
                    : () => unawaited(
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _TableRowsPage(t.table))),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TableRowsPage extends ConsumerWidget {
  const _TableRowsPage(this.table);

  final String table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final rows = ref.watch(devTableRowsProvider(table));
    return Scaffold(
      appBar: AppBar(title: Text(table)),
      body: rows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: '$e'),
        data: (list) => list.isEmpty
            ? EmptyState(icon: Icons.table_rows_outlined, title: l.devDatabaseEmpty)
            : ListView.separated(
                padding: const EdgeInsets.all(Space.lg),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) => SelectableText(
                  [for (final e in list[i].entries) '${e.key}: ${e.value}'].join('\n'),
                  style: context.text.bodySmall,
                ),
              ),
      ),
    );
  }
}
