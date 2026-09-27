import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_table.dart';
import 'package:everslot/features/checklists/presentation/checklist_navigation.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart' show LocalDate;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// Spreadsheet-style table of every item across the active lists (T4.5.15): sortable columns,
/// status and text filters, multi-select with a bulk status change. Tapping an item opens it in
/// its list.
class ItemsTableScreen extends ConsumerStatefulWidget {
  const ItemsTableScreen({super.key});

  @override
  ConsumerState<ItemsTableScreen> createState() => _ItemsTableScreenState();
}

class _ItemsTableScreenState extends ConsumerState<ItemsTableScreen> {
  ItemTableQuery _query = const ItemTableQuery();
  final Set<String> _selected = {};

  static const _widths = <double>[56, 220, 150, 180, 150, 90, 130, 130, 90, 80];
  static const _columns = ItemTableColumn.values;

  String _columnLabel(BuildContext context, ItemTableColumn c) {
    final l = context.l10n;
    return switch (c) {
      ItemTableColumn.text => l.itemsColText,
      ItemTableColumn.checklist => l.itemsColChecklist,
      ItemTableColumn.path => l.itemsColPath,
      ItemTableColumn.status => l.itemsColStatus,
      ItemTableColumn.age => l.itemsColAge,
      ItemTableColumn.due => l.itemsColDue,
      ItemTableColumn.followUp => l.itemsColFollowUp,
      ItemTableColumn.priority => l.itemsColPriority,
      ItemTableColumn.attachments => l.itemsColAttachments,
    };
  }

  Future<void> _changeStatus(List<SmartItem> rows) async {
    final l = context.l10n;
    final to = await showAppSheet<ItemStatus>(
      context,
      title: l.statusChange,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in ItemStatus.values)
            ListTile(
              leading: Icon(StatusStyle.icon(s), color: StatusStyle.color(ctx, s)),
              title: Text(StatusStyle.label(ctx, s)),
              onTap: () => Navigator.pop(ctx, s),
            ),
          const SizedBox(height: Space.md),
        ],
      ),
    );
    if (to == null || !mounted) return;
    // One operation per list (the status engine works on one tree at a time).
    final byList = <String, List<String>>{};
    for (final r in rows) {
      if (_selected.contains(r.item.id)) (byList[r.item.checklistId] ??= []).add(r.item.id);
    }
    final service = ref.read(checklistServiceProvider);
    var count = 0;
    for (final e in byList.entries) {
      await service.changeStatus(e.key, e.value, to, setNote: false);
      count += e.value.length;
    }
    if (!mounted) return;
    setState(_selected.clear);
    showInfoSnackBar(context, l.itemsTableStatusChanged(count));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final all = ref.watch(allItemsProvider);
    final attachments = ref.watch(allItemAttachmentCountsProvider).value ?? const <String, int>{};
    final rows = _query.apply(all.value ?? const [], attachments: attachments);
    final selectedShown = rows.where((r) => _selected.contains(r.item.id)).length;
    return Scaffold(
      appBar: AppBar(title: Text(l.itemsTableTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.itemsTableFilterHint,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = _query.copyWith(text: v)),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg, vertical: Space.sm),
            child: Row(
              children: [
                for (final s in ItemStatus.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.xs),
                    child: FilterChip(
                      avatar: Icon(StatusStyle.icon(s), size: 16),
                      label: Text(StatusStyle.label(context, s)),
                      selected: _query.statuses.contains(s),
                      onSelected: (on) => setState(() {
                        final next = {..._query.statuses};
                        on ? next.add(s) : next.remove(s);
                        _query = _query.copyWith(statuses: next);
                      }),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (all) {
              AsyncValue(:final error?) => ErrorState(error: error),
              AsyncValue(hasValue: false) => const LoadingState(),
              _ when rows.isEmpty => EmptyState(icon: Icons.table_rows_outlined, title: l.itemsTableEmpty),
              _ => _table(context, rows, attachments, selectedShown),
            },
          ),
          if (_selected.isNotEmpty)
            SafeArea(
              top: false,
              child: Material(
                color: context.colors.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg, vertical: Space.xs),
                  child: Row(
                    children: [
                      Expanded(child: Text(l.itemsTableSelected(_selected.length))),
                      TextButton(onPressed: () => setState(_selected.clear), child: Text(l.actionCancel)),
                      FilledButton.icon(
                        icon: const Icon(Icons.published_with_changes),
                        label: Text(l.statusChange),
                        onPressed: () => unawaited(_changeStatus(rows)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _table(BuildContext context, List<SmartItem> rows, Map<String, int> attachments, int selectedShown) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final now = ref.read(clockProvider).nowUtc();
    final zone = ref.watch(deviceZoneProvider);
    final fmt = AppFormat(context.localeName);
    LocalDate localDate(DateTime utc) {
      try {
        return ref.read(zoneResolverProvider).toLocal(utc, zone).date;
      } on Object {
        return LocalDate.fromDateTime(utc);
      }
    }

    return TableView.builder(
      horizontalDetails: ScrollableDetails.horizontal(reverse: rtl),
      pinnedRowCount: 1,
      pinnedColumnCount: 2,
      columnCount: _widths.length,
      rowCount: rows.length + 1,
      columnBuilder: (i) => TableSpan(extent: FixedTableSpanExtent(_widths[i])),
      rowBuilder: (i) => TableSpan(
        extent: FixedTableSpanExtent(i == 0 ? 52 : 56),
        backgroundDecoration: TableSpanDecoration(
          color: i == 0 ? context.colors.surfaceContainer : null,
          border: TableSpanBorder(trailing: BorderSide(color: context.colors.outlineVariant)),
        ),
      ),
      cellBuilder: (context, v) {
        if (v.row == 0) return TableViewCell(child: _header(context, v.column, rows, selectedShown));
        final r = rows[v.row - 1];
        return TableViewCell(child: _cell(context, v.column, r, attachments, now, fmt, localDate));
      },
    );
  }

  Widget _header(BuildContext context, int column, List<SmartItem> rows, int selectedShown) {
    final l = context.l10n;
    if (column == 0) {
      final all = rows.isNotEmpty && selectedShown == rows.length;
      return Center(
        child: Checkbox(
          value: all ? true : (selectedShown == 0 ? false : null),
          tristate: true,
          semanticLabel: l.itemsTableSelectAll,
          onChanged: (_) => setState(() {
            if (all) {
              _selected.removeAll(rows.map((r) => r.item.id));
            } else {
              _selected.addAll(rows.map((r) => r.item.id));
            }
          }),
        ),
      );
    }
    final c = _columns[column - 1];
    final label = _columnLabel(context, c);
    final active = _query.sortBy == c;
    return Semantics(
      button: true,
      label: l.itemsTableSortBy(label),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => setState(() => _query = _query.sortedBy(c)),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.sm),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(fontWeight: active ? FontWeight.w700 : null),
                ),
              ),
              if (active) Icon(_query.descending ? Icons.arrow_downward : Icons.arrow_upward, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    int column,
    SmartItem r,
    Map<String, int> attachments,
    DateTime now,
    AppFormat fmt,
    LocalDate Function(DateTime) localDate,
  ) {
    final l = context.l10n;
    final item = r.item;
    if (column == 0) {
      return Center(
        child: Checkbox(
          value: _selected.contains(item.id),
          semanticLabel: l.itemsTableSelectRow(item.text.isEmpty ? l.checklistItemHint : item.text),
          onChanged: (on) => setState(() => on == true ? _selected.add(item.id) : _selected.remove(item.id)),
        ),
      );
    }
    Widget text(String value, {TextStyle? style}) => Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: style),
      ),
    );
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return switch (_columns[column - 1]) {
      ItemTableColumn.text => InkWell(
        onTap: () => unawaited(openChecklist(context, item.checklistId, itemId: item.id)),
        child: text(item.text.isEmpty ? l.checklistItemHint : item.text),
      ),
      ItemTableColumn.checklist => text(r.checklistTitle.isEmpty ? l.listsUntitled : r.checklistTitle),
      ItemTableColumn.path => text(r.path.join(' › '), style: muted),
      ItemTableColumn.status => Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.sm),
        child: Row(
          children: [
            Icon(StatusStyle.icon(item.status), size: 18, color: StatusStyle.color(context, item.status)),
            const SizedBox(width: Space.xs),
            Flexible(child: Text(StatusStyle.label(context, item.status), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      ItemTableColumn.age => text(item.statusSince == null ? '' : formatAge(context, item.statusSince!, now)),
      ItemTableColumn.due => text(item.dueLocal == null ? '' : fmt.dateMedium(item.dueLocal!.date)),
      ItemTableColumn.followUp => text(item.followUpAt == null ? '' : fmt.dateMedium(localDate(item.followUpAt!))),
      ItemTableColumn.priority => text(item.priority == 0 ? '' : '${item.priority}'),
      ItemTableColumn.attachments => text((attachments[item.id] ?? 0) == 0 ? '' : '${attachments[item.id]}'),
    };
  }
}
