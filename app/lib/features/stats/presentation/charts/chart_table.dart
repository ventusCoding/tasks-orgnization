/// "View as table" (T6.2.11): the exact numbers of a chart as a sortable, focusable table.
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/charts/chart_support.dart';
import 'package:material_ui/material_ui.dart';

class ChartDataTable extends StatefulWidget {
  const ChartDataTable(this.table, {super.key, this.onRowTap});

  final ChartTable table;

  /// Row activation (drill-down of the row's first cell).
  final void Function(int row)? onRowTap;

  @override
  State<ChartDataTable> createState() => _ChartDataTableState();
}

class _ChartDataTableState extends State<ChartDataTable> {
  int? _sortColumn;
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final f = statFormatOf(context);
    final table = widget.table;
    if (table.isEmpty) {
      return Padding(padding: const EdgeInsets.all(Space.lg), child: Text(context.l10n.chartsEmpty));
    }
    String cellText(ChartCell c) {
      if (c.label != null) return f.label(c.label!);
      if (c.value == null) return context.l10n.chartsNotApplicable;
      return f.value(c.value!, c.unit);
    }

    final order = List<int>.generate(table.rows.length, (i) => i);
    final sortColumn = _sortColumn;
    if (sortColumn != null) {
      int compare(int a, int b) {
        final ca = table.rows[a][sortColumn];
        final cb = table.rows[b][sortColumn];
        if (ca.value != null || cb.value != null) {
          return (ca.value ?? double.negativeInfinity).compareTo(cb.value ?? double.negativeInfinity);
        }
        return cellText(ca).compareTo(cellText(cb));
      }

      order.sort((a, b) => _ascending ? compare(a, b) : compare(b, a));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: _sortColumn,
        sortAscending: _ascending,
        headingRowHeight: 40,
        dataRowMinHeight: 40,
        dataRowMaxHeight: double.infinity,
        columnSpacing: Space.lg,
        columns: [
          for (var c = 0; c < table.columns.length; c++)
            DataColumn(
              label: Text(f.label(table.columns[c]), style: context.text.labelMedium),
              numeric: c > 0,
              tooltip: context.l10n.chartsTableSort(f.label(table.columns[c])),
              onSort: (i, asc) => setState(() {
                _sortColumn = i;
                _ascending = asc;
              }),
            ),
        ],
        rows: [
          for (final r in order)
            DataRow(
              onSelectChanged: widget.onRowTap == null ? null : (_) => widget.onRowTap!(r),
              cells: [
                for (final cell in table.rows[r])
                  DataCell(
                    Text(cellText(cell), style: context.text.bodySmall?.copyWith(fontFeatures: AppTheme.tabular)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
