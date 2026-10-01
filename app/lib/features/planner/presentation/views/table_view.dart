import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:everslot/features/organization/domain/tag.dart';
import 'package:everslot/features/organization/presentation/categories_screen.dart' show pickCategory;
import 'package:everslot/features/planner/application/view_config/view_actions.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/engine/table_rows.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

const double _rowExtent = 48;
const double _headerExtent = 48;

/// Table (spreadsheet) view (T3.7.05, Notion / ClickUp style): occurrences of a date range
/// (`options.rangeDays`) or one row per task (`options.rows`); columns chosen and resized
/// (`options.columns`, `options.columnWidths`), header and title column pinned (`TableView`); tap a
/// header to sort (`options.sortBy` / `sortAsc`), group by day / category / status; title, date,
/// time, status, category and priority edit inline through the same scope logic as the editor.
class PlannerTableView extends ConsumerStatefulWidget {
  const PlannerTableView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<PlannerTableView> createState() => _PlannerTableViewState();
}

class _PlannerTableViewState extends ConsumerState<PlannerTableView> {
  late LocalDate _start;

  /// Widths being dragged (written to the config when the drag ends).
  final Map<TableColumn, double> _dragWidths = {};

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    _start =
        widget.args.date ??
        ref.read(plannerAnchorProvider) ??
        ref.read(plannerViewStateProvider(_key))?.anchor ??
        ref.read<LocalDate>(plannerTodayProvider);
  }

  void _go(LocalDate d) {
    setState(() => _start = d);
    ref.read(plannerAnchorProvider.notifier).set(d);
    ref.read(plannerViewStateProvider(_key).notifier).update((s) => s.copyWith(anchor: d));
  }

  ViewConfigController get _config => ref.read(plannerViewConfigProvider(_key).notifier);

  Map<TableColumn, double> _widths(PlannerViewConfig config) {
    final stored = config.option<Map<Object?, Object?>>('columnWidths', const {});
    return {
      for (final c in TableColumn.values)
        c: _dragWidths[c] ?? (stored[c.name] is num ? (stored[c.name]! as num).toDouble() : c.defaultWidth),
    };
  }

  void _commitWidth(TableColumn c) {
    final w = _dragWidths.remove(c);
    if (w == null) return;
    _config.change((cfg) {
      final stored = Map<String, Object?>.from(cfg.option<Map<Object?, Object?>>('columnWidths', const {}));
      stored[c.name] = w.roundToDouble();
      return cfg.withOption('columnWidths', stored);
    });
  }

  Future<void> _chooseColumns(List<TableColumn> current) async {
    final l = context.l10n;
    final result = await showAppSheet<List<TableColumn>>(
      context,
      title: l.pvColumns,
      builder: (ctx) => _ColumnChooser(current: current, label: (c) => columnLabel(ctx, c)),
    );
    if (result == null) return;
    _config.change((c) => c.withOption('columns', [for (final col in result) col.name]));
  }

  Future<void> _pick() async {
    final weekStart = ref.read(userPreferencesProvider).weekStart;
    final picked = await showMiniMonth(context, initial: _start, weekStart: weekStart, highlight: [_start]);
    if (picked != null) _go(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final today = ref.watch(plannerTodayProvider);
    final f = context.plannerFormat(use24h: prefs.use24h);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final days = config.option<int>('rangeDays', 14).clamp(1, 92);
    final rows = config.option<String>('rows', 'occurrences') == 'tasks' ? TableRows.tasks : TableRows.occurrences;
    final group = TableGroup.values.firstWhere(
      (g) => g.name == config.option<String>('groupBy', 'none'),
      orElse: () => TableGroup.none,
    );
    final sortBy = TableColumn.parse(config.option<String>('sortBy', 'start')) ?? TableColumn.start;
    final ascending = config.option<bool>('sortAsc', true);
    final columns = tableColumns(config.option<List<Object?>>('columns', const []));
    final widths = _widths(config);
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final categoryById = {for (final c in categories) c.id: c};
    final tags = ref.watch(tagsByEntityProvider('task')).value ?? const <String, List<Tag>>{};
    String tagNames(PlannerItem i) => [for (final t in tags[i.taskId] ?? const <Tag>[]) t.name].join(', ');
    final items = filteredItems(ref, DayRange(_start, days), config);
    final list = items.value ?? const <PlannerItem>[];
    final shown = rows == TableRows.tasks ? tableTaskRows(list) : [...list];
    shown.sort(
      tableComparator(
        sortBy,
        ascending: ascending,
        categoryName: (id) => categoryById[id]?.name ?? '',
        tagNames: tagNames,
      ),
    );
    final lines = tableLines(shown, group);
    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: DatePagedToolbar(
        title: rangeTitle(locale, _start, _start.plusDays(days - 1)),
        onPrevious: () => _go(_start.plusDays(-days)),
        onNext: () => _go(_start.plusDays(days)),
        onToday: () => _go(today),
        onTitleTap: () => unawaited(_pick()),
        previousLabel: l.pvPrevious,
        nextLabel: l.pvNext,
        trailing: [
          PopupMenuButton<String>(
            key: const Key('table-options'),
            tooltip: l.pvDisplay,
            icon: const Icon(Icons.table_chart_outlined),
            onSelected: (v) {
              switch (v) {
                case 'rows':
                  _config.change((c) => c.withOption('rows', rows == TableRows.tasks ? 'occurrences' : 'tasks'));
                case 'columns':
                  unawaited(_chooseColumns(columns));
                default:
                  _config.change((c) => c.withOption('groupBy', v.substring('group:'.length)));
              }
            },
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: 'rows', checked: rows == TableRows.tasks, child: Text(l.pvRowsTasks)),
              PopupMenuItem(value: 'columns', child: Text(l.pvColumns)),
              const PopupMenuDivider(),
              for (final (g, label) in [
                (TableGroup.none, l.pvGroupNone),
                (TableGroup.day, l.pvGroupDay),
                (TableGroup.category, l.pvGroupCategory),
                (TableGroup.status, l.pvGroupStatus),
              ])
                CheckedPopupMenuItem(
                  value: 'group:${g.name}',
                  checked: g == group,
                  child: Text('${l.pvGroupBy}: $label'),
                ),
            ],
          ),
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
        ],
      ),
      body: Column(
        children: [
          ActiveFilterBar(viewKey: _key),
          Expanded(
            child: AsyncValueView<List<PlannerItem>>(
              value: items,
              data: (_) => lines.isEmpty
                  ? EmptyState(icon: Icons.table_rows_outlined, title: l.pvNoTasks)
                  : TableView.builder(
                      key: const Key('planner-table'),
                      horizontalDetails: ScrollableDetails.horizontal(
                        reverse: Directionality.of(context) == TextDirection.rtl,
                      ),
                      pinnedRowCount: 1,
                      pinnedColumnCount: 1,
                      columnCount: columns.length,
                      rowCount: lines.length + 1,
                      columnBuilder: (i) => TableSpan(extent: FixedTableSpanExtent(widths[columns[i]]!)),
                      rowBuilder: (i) => TableSpan(
                        extent: FixedTableSpanExtent(i == 0 ? _headerExtent : _rowExtent),
                        backgroundDecoration: TableSpanDecoration(
                          color: i == 0 || (i > 0 && lines[i - 1] is TableGroupLine)
                              ? context.colors.surfaceContainer
                              : null,
                          border: TableSpanBorder(trailing: BorderSide(color: context.colors.outlineVariant)),
                        ),
                      ),
                      cellBuilder: (context, v) {
                        final column = columns[v.column];
                        if (v.row == 0) {
                          return TableViewCell(
                            child: _HeaderCell(
                              label: columnLabel(context, column),
                              active: sortBy == column,
                              ascending: ascending,
                              onSort: () => _config.change(
                                (c) => c
                                    .withOption('sortBy', column.name)
                                    .withOption('sortAsc', sortBy == column ? !ascending : true),
                              ),
                              onResize: (dx) => setState(
                                () => _dragWidths[column] = math.max(56, (_dragWidths[column] ?? widths[column]!) + dx),
                              ),
                              onResizeEnd: () => _commitWidth(column),
                              keyName: column.name,
                            ),
                          );
                        }
                        final line = lines[v.row - 1];
                        if (line is TableGroupLine) {
                          return TableViewCell(
                            child: v.column == 0
                                ? Padding(
                                    padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.sm),
                                    child: Align(
                                      alignment: AlignmentDirectional.centerStart,
                                      child: Text(
                                        '${_groupLabel(context, group, line.key, categoryById, f)} · ${line.count}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.text.labelLarge,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          );
                        }
                        final item = (line as TableItemLine).item;
                        return TableViewCell(
                          child: _DataCell(
                            viewKey: _key,
                            item: item,
                            column: column,
                            format: f,
                            category: categoryById[item.categoryId],
                            tags: tagNames(item),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      fab: PlannerFab(start: () => suggestedStart(today, ref.read(plannerNowProvider))),
    );
  }

  String _groupLabel(BuildContext context, TableGroup g, String key, Map<String, Category> categories, AppFormat f) {
    final l = context.l10n;
    return switch (g) {
      TableGroup.day => f.dayLong(LocalDate.parse(key)),
      TableGroup.category => key.isEmpty ? l.pvNoCategory : (categories[key]?.name ?? l.pvNoCategory),
      TableGroup.status => context.statusLabel(OccurrenceStatus.values.byName(key)),
      TableGroup.none => '',
    };
  }
}

/// Localized column name.
String columnLabel(BuildContext context, TableColumn c) {
  final l = context.l10n;
  return switch (c) {
    TableColumn.title => l.pvColTitle,
    TableColumn.date => l.pvColDate,
    TableColumn.start => l.pvColStart,
    TableColumn.end => l.pvColEnd,
    TableColumn.duration => l.pvColDuration,
    TableColumn.status => l.pvColStatus,
    TableColumn.category => l.pvColCategory,
    TableColumn.priority => l.pvColPriority,
    TableColumn.tags => l.pvTags,
    TableColumn.tracking => l.pvColTracking,
    TableColumn.recurrence => l.pvColRecurrence,
    TableColumn.actual => l.pvActualColumn,
    TableColumn.deadline => l.tasksFieldDeadline,
  };
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.active,
    required this.ascending,
    required this.onSort,
    required this.onResize,
    required this.onResizeEnd,
    required this.keyName,
  });

  final String label;
  final bool active;
  final bool ascending;
  final VoidCallback onSort;
  final ValueChanged<double> onResize;
  final VoidCallback onResizeEnd;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: '${context.l10n.pvSortBy}: $label',
            excludeSemantics: true,
            child: InkWell(
              key: ValueKey('table-header-$keyName'),
              onTap: onSort,
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
                    if (active) Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          key: ValueKey('table-resize-$keyName'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) => onResize(rtl ? -d.delta.dx : d.delta.dx),
          onHorizontalDragEnd: (_) => onResizeEnd(),
          child: SizedBox(
            width: 12,
            height: double.infinity,
            child: Center(child: Container(width: 1, height: 20, color: context.colors.outlineVariant)),
          ),
        ),
      ],
    );
  }
}

class _DataCell extends ConsumerWidget {
  const _DataCell({
    required this.viewKey,
    required this.item,
    required this.column,
    required this.format,
    required this.category,
    required this.tags,
  });

  final String viewKey;
  final PlannerItem item;
  final TableColumn column;
  final AppFormat format;
  final Category? category;
  final String tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = format;
    final commands = PlannerCommands(context, ref);
    Future<void> editFields(BacklogEdit edit) async {
      final scope = await commands.askScope(item);
      if (scope == null || !context.mounted) return;
      await commands.runExtra(l.tasksUpdated, (a) => a.editFields(item, edit, scope: scope));
    }

    final (String text, VoidCallback? onTap) = switch (column) {
      TableColumn.title => (
        item.title,
        () async {
          final title = await promptText(context, title: l.pvColTitle, initial: item.title);
          if (title != null && title.trim().isNotEmpty && title != item.title) {
            await editFields(BacklogEdit(title: title.trim()));
          }
        },
      ),
      TableColumn.date => (
        f.dateMedium(item.startLocal.date),
        () async {
          final d = await pickDate(context, initial: item.startLocal.date);
          if (d == null || d == item.startLocal.date || !context.mounted) return;
          await commands.reschedule(
            item,
            start: d.atTime(item.startLocal.time),
            message: l.pvMovedSnack(f.dayShort(d)),
          );
        },
      ),
      TableColumn.start => (
        item.allDay ? l.pvAllDay : f.timeOf(item.startLocal),
        () async {
          final t = await pickTime(context, initial: item.startLocal.time);
          if (t == null || !context.mounted) return;
          final start = item.startLocal.date.atTime(t);
          if (start == item.startLocal && !item.allDay) return;
          await commands.reschedule(
            item,
            start: start,
            duration: item.allDay ? 30 : null,
            allDay: item.allDay ? false : null,
            message: l.pvMovedSnack('${f.dayShort(start.date)} ${f.timeOf(start)}'),
          );
        },
      ),
      TableColumn.end => (item.allDay ? '' : f.timeOf(item.endLocal), null),
      TableColumn.duration => (f.duration(item.durationMinutes), null),
      TableColumn.status => (
        context.statusLabel(item.status),
        () async {
          final status = await showAppSheet<OccurrenceStatus>(
            context,
            title: l.pvColStatus,
            builder: (ctx) => ListView(
              shrinkWrap: true,
              children: [
                for (final s in const [
                  OccurrenceStatus.scheduled,
                  OccurrenceStatus.inProgress,
                  OccurrenceStatus.done,
                  OccurrenceStatus.skipped,
                  OccurrenceStatus.cancelled,
                ])
                  ListTile(
                    key: ValueKey('status-${s.name}'),
                    title: Text(ctx.statusLabel(s)),
                    trailing: s == item.status ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(ctx, s),
                  ),
              ],
            ),
          );
          if (status != null && status != item.status) await commands.setStatus(item, status);
        },
      ),
      TableColumn.category => (
        category?.name ?? l.pvNoCategory,
        () async {
          final id = await pickCategory(context, ref, selectedId: item.categoryId);
          if (id == null || id == (item.categoryId ?? '')) return;
          await editFields(id.isEmpty ? const BacklogEdit(clearCategory: true) : BacklogEdit(categoryId: id));
        },
      ),
      TableColumn.priority => (
        PriorityStyle.label(context, item.priority),
        () async {
          final p = await showAppSheet<int>(
            context,
            title: l.pvColPriority,
            builder: (ctx) => ListView(
              shrinkWrap: true,
              children: [
                for (var p = 0; p <= 4; p++)
                  ListTile(
                    key: ValueKey('priority-$p'),
                    leading: Icon(Icons.flag, color: PriorityStyle.color(p)),
                    title: Text(PriorityStyle.label(ctx, p)),
                    onTap: () => Navigator.pop(ctx, p),
                  ),
              ],
            ),
          );
          if (p != null && p != item.priority) await editFields(BacklogEdit(priority: p));
        },
      ),
      TableColumn.tags => (tags, null),
      TableColumn.tracking => (context.trackingLabel(item.trackingMode), null),
      TableColumn.recurrence => (item.isRecurring ? l.pvRecurring : l.pvOneOff, null),
      TableColumn.actual => (item.trackedSeconds == null ? '' : f.duration((item.trackedSeconds! / 60).round()), null),
      TableColumn.deadline => (item.deadlineLocal == null ? '' : f.dateMedium(item.deadlineLocal!.date), null),
    };
    final content = Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.sm),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: column == TableColumn.title ? FontWeight.w600 : null,
            decoration: column == TableColumn.title && item.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
    if (column == TableColumn.title) {
      return InkWell(
        key: ValueKey('cell-title-${item.key}'),
        onTap: () => ref.read(plannerNavProvider).openTask(context, item),
        onLongPress: onTap,
        child: content,
      );
    }
    if (onTap == null) return content;
    return InkWell(
      key: ValueKey('cell-${column.name}-${item.key}'),
      onTap: () => unawaited(Future(onTap)),
      child: content,
    );
  }
}

/// Column checkboxes (title is always shown).
class _ColumnChooser extends StatefulWidget {
  const _ColumnChooser({required this.current, required this.label});

  final List<TableColumn> current;
  final String Function(TableColumn c) label;

  @override
  State<_ColumnChooser> createState() => _ColumnChooserState();
}

class _ColumnChooserState extends State<_ColumnChooser> {
  late final Set<TableColumn> _on = {...widget.current};

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Flexible(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in TableColumn.values)
              CheckboxListTile(
                key: ValueKey('column-${c.name}'),
                value: _on.contains(c),
                title: Text(widget.label(c)),
                onChanged: c == TableColumn.title
                    ? null
                    : (v) => setState(() => v == true ? _on.add(c) : _on.remove(c)),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(Space.md),
        child: FilledButton(
          key: const Key('columns-save'),
          onPressed: () => Navigator.pop(context, [
            for (final c in TableColumn.values)
              if (_on.contains(c)) c,
          ]),
          child: Text(context.l10n.actionSave),
        ),
      ),
    ],
  );
}
