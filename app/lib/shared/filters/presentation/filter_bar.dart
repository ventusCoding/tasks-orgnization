import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/day_utils.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:everslot/features/organization/domain/tag.dart';
import 'package:everslot/shared/filters/domain/entity_filter.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Criteria a [FilterBar] can offer.
enum FilterField { category, tag, priority, status, date, attachments, recurring, text }

/// A selectable value (the host screen supplies its status options).
@immutable
class FilterOption<T> {
  const FilterOption(this.value, this.label, {this.icon, this.color});

  final T value;
  final String label;
  final IconData? icon;
  final Color? color;
}

/// Reusable filter bar (T2.3.09): one chip per criterion, active-filter count and "clear all".
/// Used by planner views, the lists board, habits and stats with their own [fields] and
/// [statusOptions]; the value is a plain [EntityFilter] the host applies (predicate or SQL).
class FilterBar extends ConsumerWidget {
  const FilterBar({
    required this.value,
    required this.onChanged,
    super.key,
    this.fields = const [FilterField.category, FilterField.tag, FilterField.priority, FilterField.date],
    this.statusOptions = const [],
    this.padding = const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
  });

  final EntityFilter value;
  final ValueChanged<EntityFilter> onChanged;
  final List<FilterField> fields;
  final List<FilterOption<String>> statusOptions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final count = value.activeCount;
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    // The count badge and "Clear all" stay pinned; only the chips scroll. No fixed height, so
    // large text scales grow the bar instead of clipping it.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Semantics(
              label: l.filterActiveCount(count),
              excludeSemantics: true,
              child: Badge(isLabelVisible: count > 0, label: Text('$count'), child: const Icon(Icons.filter_list)),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final field in fields)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: Space.sm),
                        child: _chip(context, ref, field, categories, tags),
                      ),
                  ],
                ),
              ),
            ),
            if (count > 0) TextButton(onPressed: () => onChanged(EntityFilter.empty), child: Text(l.filterClearAll)),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, WidgetRef ref, FilterField field, List<Category> categories, List<Tag> tags) {
    final l = context.l10n;
    final (label, active, clear) = switch (field) {
      FilterField.category => (
        _summary(context, l.filterCategory, [
          for (final id in value.categoryIds)
            id == EntityFilter.noCategory
                ? l.filterNoCategory
                : categories.where((c) => c.id == id).map((c) => c.name).firstOrNull ?? '?',
        ]),
        value.categoryIds.isNotEmpty,
        value.copyWith(categoryIds: const {}),
      ),
      FilterField.tag => (
        _summary(context, l.filterTag, [
          for (final id in value.tagIds) tags.where((t) => t.id == id).map((t) => t.name).firstOrNull ?? '?',
        ]),
        value.tagIds.isNotEmpty,
        value.copyWith(tagIds: const {}),
      ),
      FilterField.priority => (
        _summary(context, l.filterPriority, [
          for (final p in value.priorities.toList()..sort()) PriorityStyle.label(context, p),
        ]),
        value.priorities.isNotEmpty,
        value.copyWith(priorities: const {}),
      ),
      FilterField.status => (
        _summary(context, l.filterStatus, [
          for (final s in value.statuses) statusOptions.where((o) => o.value == s).map((o) => o.label).firstOrNull ?? s,
        ]),
        value.statuses.isNotEmpty,
        value.copyWith(statuses: const {}),
      ),
      FilterField.date => (
        value.hasDateRange ? l.filterChipValue(l.filterDate, _dateRange(context)) : l.filterDate,
        value.hasDateRange,
        value.copyWith(clearDates: true),
      ),
      FilterField.attachments => (
        switch (value.hasAttachments) {
          true => l.filterWithAttachments,
          false => l.filterWithoutAttachments,
          null => l.filterAttachments,
        },
        value.hasAttachments != null,
        value.copyWith(clearHasAttachments: true),
      ),
      FilterField.recurring => (
        switch (value.recurring) {
          true => l.filterRecurringOnly,
          false => l.filterOneOffOnly,
          null => l.filterRecurring,
        },
        value.recurring != null,
        value.copyWith(clearRecurring: true),
      ),
      FilterField.text => (
        value.effectiveText == null ? l.filterText : l.filterChipValue(l.filterText, '“${value.effectiveText}”'),
        value.effectiveText != null,
        value.copyWith(clearText: true),
      ),
    };
    return FilterChip(
      label: Text(label),
      selected: active,
      showCheckmark: false,
      onSelected: (_) => _edit(context, ref, field, categories, tags),
      onDeleted: active ? () => onChanged(clear) : null,
      deleteButtonTooltipMessage: l.filterClear(label),
    );
  }

  static String _summary(BuildContext context, String field, List<String> values) {
    final l = context.l10n;
    if (values.isEmpty) return field;
    if (values.length == 1) return l.filterChipValue(field, values.single);
    return l.filterChipCount(field, values.length);
  }

  String _dateRange(BuildContext context) {
    final f = AppFormat(context.localeName, l10n: context.l10n);
    final from = value.dateFrom == null ? '…' : f.dateMedium(value.dateFrom!);
    final to = value.dateTo == null ? '…' : f.dateMedium(value.dateTo!);
    return '$from – $to';
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    FilterField field,
    List<Category> categories,
    List<Tag> tags,
  ) async {
    final l = context.l10n;
    switch (field) {
      case FilterField.category:
        final picked = await _pickMany<String>(context, l.filterCategory, value.categoryIds, [
          FilterOption(EntityFilter.noCategory, l.filterNoCategory, icon: Icons.block),
          for (final c in categories)
            FilterOption(
              c.id,
              c.name,
              icon: IconCatalog.iconFor(c.icon),
              color: CategoryColors.accent(c.color, Theme.of(context).brightness),
            ),
        ]);
        if (picked != null) onChanged(value.copyWith(categoryIds: picked));
      case FilterField.tag:
        final picked = await _pickMany<String>(context, l.filterTag, value.tagIds, [
          for (final t in tags)
            FilterOption(
              t.id,
              t.name,
              icon: Icons.sell_outlined,
              color: t.color == null ? null : CategoryColors.accent(t.color!, Theme.of(context).brightness),
            ),
        ]);
        if (picked != null) onChanged(value.copyWith(tagIds: picked));
      case FilterField.priority:
        final picked = await _pickMany<int>(context, l.filterPriority, value.priorities, [
          for (var p = 4; p >= 0; p--)
            FilterOption(
              p,
              PriorityStyle.label(context, p),
              icon: PriorityStyle.icon(p),
              color: PriorityStyle.foregroundOf(context, p),
            ),
        ]);
        if (picked != null) onChanged(value.copyWith(priorities: picked));
      case FilterField.status:
        final picked = await _pickMany<String>(context, l.filterStatus, value.statuses, statusOptions);
        if (picked != null) onChanged(value.copyWith(statuses: picked));
      case FilterField.date:
        // "Today" comes from the injected clock (debug time travel) in the device zone.
        final today = DayUtils.nowLocal(
          ref.read(clockProvider).nowUtc(),
          ref.read(deviceZoneProvider),
          ref.read(zoneResolverProvider),
        ).date;
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDateRange: value.dateFrom != null && value.dateTo != null
              ? DateTimeRange(start: value.dateFrom!.toDateTimeUtc(), end: value.dateTo!.toDateTimeUtc())
              : null,
          currentDate: DateTime(today.year, today.month, today.day),
        );
        if (range != null) {
          onChanged(
            value.copyWith(
              dateFrom: LocalDate(range.start.year, range.start.month, range.start.day),
              dateTo: LocalDate(range.end.year, range.end.month, range.end.day),
            ),
          );
        }
      case FilterField.attachments:
        final choice = await _pickTriState(context, l.filterAttachments, value.hasAttachments, (
          l.filterWithAttachments,
          l.filterWithoutAttachments,
        ));
        if (choice != null) {
          onChanged(choice.$1 ? value.copyWith(clearHasAttachments: true) : value.copyWith(hasAttachments: choice.$2));
        }
      case FilterField.recurring:
        final choice = await _pickTriState(context, l.filterRecurring, value.recurring, (
          l.filterRecurringOnly,
          l.filterOneOffOnly,
        ));
        if (choice != null) {
          onChanged(choice.$1 ? value.copyWith(clearRecurring: true) : value.copyWith(recurring: choice.$2));
        }
      case FilterField.text:
        final text = await promptText(
          context,
          title: l.filterTextPrompt,
          initial: value.effectiveText,
          allowEmpty: true,
        );
        if (text != null) {
          onChanged(text.isEmpty ? value.copyWith(clearText: true) : value.copyWith(text: text));
        }
    }
  }

  static Future<Set<T>?> _pickMany<T>(
    BuildContext context,
    String title,
    Set<T> selected,
    List<FilterOption<T>> options,
  ) => showAppSheet<Set<T>>(
    context,
    title: title,
    builder: (ctx) => _MultiSelectSheet<T>(options: options, initial: selected),
  );

  /// Returns (isAny, value) — null when dismissed.
  static Future<(bool, bool)?> _pickTriState(
    BuildContext context,
    String title,
    bool? current,
    (String, String) labels,
  ) => showAppSheet<(bool, bool)>(
    context,
    title: title,
    builder: (ctx) => RadioGroup<int>(
      groupValue: switch (current) {
        null => 0,
        true => 1,
        false => 2,
      },
      onChanged: (v) => Navigator.pop(ctx, (v == 0, v == 1)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<int>(value: 0, title: Text(ctx.l10n.filterAny)),
          RadioListTile<int>(value: 1, title: Text(labels.$1)),
          RadioListTile<int>(value: 2, title: Text(labels.$2)),
          const SizedBox(height: Space.lg),
        ],
      ),
    ),
  );
}

class _MultiSelectSheet<T> extends StatefulWidget {
  const _MultiSelectSheet({required this.options, required this.initial});

  final List<FilterOption<T>> options;
  final Set<T> initial;

  @override
  State<_MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

class _MultiSelectSheetState<T> extends State<_MultiSelectSheet<T>> {
  late final Set<T> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final o in widget.options)
                CheckboxListTile(
                  value: _selected.contains(o.value),
                  secondary: o.icon == null ? null : Icon(o.icon, color: o.color),
                  title: Text(o.label),
                  onChanged: (v) => setState(() {
                    if (v ?? false) {
                      _selected.add(o.value);
                    } else {
                      _selected.remove(o.value);
                    }
                  }),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              TextButton(onPressed: () => Navigator.pop(context, <T>{}), child: Text(l.actionClear)),
              const Spacer(),
              FilledButton(onPressed: () => Navigator.pop(context, _selected), child: Text(l.actionApply)),
            ],
          ),
        ),
      ],
    );
  }
}
