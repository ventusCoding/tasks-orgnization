import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Which option groups a view shows.
enum ViewSettingsKind { timeGrid, dayList, calendar, list }

/// View-level display and layout options (T3.3.22, T3.4.03, T3.4.08–T3.4.10, T3.4.19, T3.3.23,
/// T3.3.24, T3.3.26). Changes apply live and persist in the view config (synced) or, for the
/// accessible list, in the local view state.
Future<void> showViewSettingsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String viewKey,
  ViewSettingsKind kind = ViewSettingsKind.timeGrid,
}) => showAppSheet<void>(
  context,
  title: context.l10n.pvViewSettings,
  builder: (ctx) => ViewSettingsSheet(viewKey: viewKey, kind: kind),
);

class ViewSettingsSheet extends ConsumerWidget {
  const ViewSettingsSheet({required this.viewKey, this.kind = ViewSettingsKind.timeGrid, super.key});

  final String viewKey;
  final ViewSettingsKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(viewKey));
    final notifier = ref.read(plannerViewConfigProvider(viewKey).notifier);
    final state = ref.watch(plannerViewStateProvider(viewKey));
    final stateCtl = ref.read(plannerViewStateProvider(viewKey).notifier);
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final maxDays = tablet ? 14 : 7;
    final timeGrid = kind == ViewSettingsKind.timeGrid;
    final env = ref.watch(envProvider);
    void change(PlannerViewConfig Function(PlannerViewConfig c) fn) => notifier.change(fn);
    Widget header(String text) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, Space.lg, Space.xl, Space.xs),
      child: Text(text, style: context.text.labelLarge?.copyWith(color: context.colors.primary)),
    );
    final window = config.dayWindow;
    final windowText = window.isFull
        ? l.pvVisibleHoursAll
        : '${f.time(LocalTime.fromMinuteOfDay(window.startMinute))} – ${f.time(LocalTime.fromMinuteOfDay(window.endMinute))}';
    return ListView(
      shrinkWrap: true,
      children: [
        header(l.pvDisplay),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          child: DropdownButtonFormField<ColorBy>(
            key: const Key('settings-color-by'),
            initialValue: config.colorBy,
            decoration: InputDecoration(labelText: l.pvColorBy, isDense: true),
            items: [
              DropdownMenuItem(value: ColorBy.category, child: Text(l.pvColorByCategory)),
              DropdownMenuItem(value: ColorBy.priority, child: Text(l.pvColorByPriority)),
              DropdownMenuItem(value: ColorBy.status, child: Text(l.pvColorByStatus)),
              DropdownMenuItem(value: ColorBy.task, child: Text(l.pvColorByTask)),
            ],
            onChanged: (v) => change((c) => c.copyWith(colorBy: v)),
          ),
        ),
        const SizedBox(height: Space.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          child: SegmentedButton<Density>(
            segments: [
              ButtonSegment(value: Density.comfortable, label: Text(l.pvDensityComfortable)),
              ButtonSegment(value: Density.compact, label: Text(l.pvDensityCompact)),
            ],
            selected: {config.density},
            onSelectionChanged: (s) => change((c) => c.copyWith(density: s.first)),
          ),
        ),
        SwitchListTile(
          key: const Key('settings-show-completed'),
          title: Text(l.pvShowCompleted),
          value: config.showCompleted,
          onChanged: (v) => change((c) => c.copyWith(showCompleted: v)),
        ),
        SwitchListTile(
          title: Text(l.pvShowCancelled),
          value: config.showCancelled,
          onChanged: (v) => change((c) => c.copyWith(showCancelled: v)),
        ),
        SwitchListTile(
          title: Text(l.pvDimPast),
          value: config.dimPast,
          onChanged: (v) => change((c) => c.copyWith(dimPast: v)),
        ),
        if (timeGrid)
          _LoadThresholds(
            warn: config.option<double>('loadWarn', 0.8),
            over: config.option<double>('loadOver', 1.0),
            onChanged: (warn, over) => change((c) => c.withOption('loadWarn', warn).withOption('loadOver', over)),
          ),
        if (kind != ViewSettingsKind.list)
          SwitchListTile(
            title: Text(l.pvWeekNumbers),
            value: config.showWeekNumbers,
            onChanged: (v) => change((c) => c.copyWith(showWeekNumbers: v)),
          ),
        if (timeGrid) ...[
          header(l.pvLayout),
          _DaysSlider(
            label: l.pvDaysVisible,
            value: config.daysVisible.clamp(1, maxDays),
            max: maxDays,
            onChanged: (v) {
              change((c) => c.copyWith(daysVisible: v));
              stateCtl.update((s) => s.withoutDays());
            },
          ),
          _DaysSlider(
            label: l.pvDaysVisibleLandscape,
            value: config.daysVisibleLandscape.clamp(1, maxDays),
            max: maxDays,
            onChanged: (v) {
              change((c) => c.copyWith(daysVisibleLandscape: v));
              stateCtl.update((s) => s.withoutDays());
            },
          ),
          SwitchListTile(
            key: const Key('settings-weekends'),
            title: Text(l.pvShowWeekends),
            value: config.showWeekends,
            onChanged: (v) => change((c) => c.copyWith(showWeekends: v)),
          ),
          SwitchListTile(
            title: Text(l.pvWorkDaysOnly),
            value: config.option<bool>('workWeek', false),
            onChanged: (v) => change((c) => c.withOption('workWeek', v)),
          ),
          ListTile(
            title: Text(l.pvPagingMode),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: SegmentedButton<PagingMode>(
                segments: [
                  ButtonSegment(value: PagingMode.week, label: Text(l.pvPagingWeek)),
                  ButtonSegment(value: PagingMode.day, label: Text(l.pvPagingDay)),
                  ButtonSegment(value: PagingMode.free, label: Text(l.pvPagingFree)),
                ],
                selected: {config.paging},
                onSelectionChanged: (s) => change((c) => c.copyWith(paging: s.first)),
              ),
            ),
          ),
        ],
        if (timeGrid || kind == ViewSettingsKind.dayList) ...[
          ListTile(
            key: const Key('settings-visible-hours'),
            title: Text(l.pvVisibleHours),
            subtitle: Text(windowText),
            trailing: window.isFull
                ? null
                : IconButton(
                    tooltip: l.pvVisibleHoursAll,
                    icon: const Icon(Icons.restart_alt),
                    onPressed: () =>
                        change((c) => c.copyWith(dayWindow: DayWindow.full).withOption('followWorkHours', false)),
                  ),
            onTap: () => unawaited(_pickWindow(context, ref, config)),
          ),
          SwitchListTile(
            title: Text(l.pvAutoScrollNow),
            value: config.autoScrollToNow,
            onChanged: (v) => change((c) => c.copyWith(autoScrollToNow: v)),
          ),
        ],
        if (timeGrid) ...[
          _DaysSlider(
            label: l.pvLaneCap,
            value: config.laneCap.clamp(1, 6),
            max: 6,
            onChanged: (v) => change((c) => c.copyWith(laneCap: v)),
          ),
          ListTile(
            title: Text(l.pvOverlapStyle),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: SegmentedButton<OverlapStyle>(
                segments: [
                  ButtonSegment(value: OverlapStyle.columns, label: Text(l.pvOverlapColumns)),
                  ButtonSegment(value: OverlapStyle.cascade, label: Text(l.pvOverlapCascade)),
                ],
                selected: {config.overlapStyle},
                onSelectionChanged: (s) => change((c) => c.copyWith(overlapStyle: s.first)),
              ),
            ),
          ),
        ],
        if (kind == ViewSettingsKind.dayList) ...[
          SwitchListTile(
            key: const Key('settings-hide-empty'),
            title: Text(l.pvHideEmptySlots),
            value: config.hideEmptySlots,
            onChanged: (v) => change((c) => c.copyWith(hideEmptySlots: v)),
          ),
          ListTile(
            title: Text(l.pvDisplay),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'slots', label: Text(l.pvSlotsStyle)),
                  ButtonSegment(value: 'ribbon', label: Text(l.pvRibbonStyle)),
                ],
                selected: {config.option<String>('style', 'slots')},
                onSelectionChanged: (s) => change((c) => c.withOption('style', s.first)),
              ),
            ),
          ),
        ],
        if (timeGrid || kind == ViewSettingsKind.dayList) ...[
          header(l.pvOverlays),
          for (final (key, label) in [
            ('habits', l.pvOverlayHabits),
            ('checklistDue', l.pvOverlayChecklistDue),
            ('freeSlots', l.pvOverlayFreeSlots),
            ('heat', l.pvOverlayHeat),
            ('deviceCalendars', l.pvOverlayDeviceCalendars),
          ])
            SwitchListTile(
              title: Text(label),
              value: config.overlay(key),
              onChanged: (v) => change((c) => c.copyWith(overlays: {...c.overlays, key: v})),
            ),
        ],
        if (timeGrid) ...[
          header(l.pvExtraZones),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xl),
            child: Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final z in config.extraTimeZones)
                  InputChip(
                    label: Text(z),
                    onDeleted: () => change(
                      (c) => c.copyWith(
                        extraTimeZones: [
                          for (final x in c.extraTimeZones)
                            if (x != z) x,
                        ],
                      ),
                    ),
                  ),
                if (config.extraTimeZones.length < 3)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(l.pvAddZone),
                    onPressed: () => unawaited(_addZone(context, ref, config)),
                  ),
              ],
            ),
          ),
        ],
        header(l.pvListMode),
        SwitchListTile(
          key: const Key('settings-list-mode'),
          title: Text(l.pvListMode),
          value: state?.extra['listMode'] == true,
          onChanged: (v) => stateCtl.update((s) => s.withExtra('listMode', v)),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.restart_alt),
          title: Text(l.pvResetView),
          onTap: () {
            notifier.reset();
            stateCtl.update((s) => s.withoutDays().withoutZoom());
          },
        ),
        if (env.isDev)
          SwitchListTile(
            title: Text(l.pvDemoData),
            value: ref.watch(plannerDemoModeProvider),
            onChanged: (v) => ref.read(plannerDemoModeProvider.notifier).set(v),
          ),
        const SizedBox(height: Space.lg),
      ],
    );
  }

  Future<void> _pickWindow(BuildContext context, WidgetRef ref, PlannerViewConfig config) async {
    final use24h = ref.read(userPreferencesProvider).use24h;
    final start = await pickTime(
      context,
      initial: LocalTime.fromMinuteOfDay(config.dayWindow.startMinute.clamp(0, 1439)),
      use24h: use24h,
    );
    if (start == null || !context.mounted) return;
    final endInitial = config.dayWindow.endMinute >= 1440
        ? LocalTime(23, 55)
        : LocalTime.fromMinuteOfDay(config.dayWindow.endMinute);
    final end = await pickTime(context, initial: endInitial, use24h: use24h);
    if (end == null || !context.mounted) return;
    int round5(int m) => (m / 5).round() * 5;
    final s = round5(start.minuteOfDay).clamp(0, 1435);
    var e = round5(end.minuteOfDay);
    if (e == 0 || e >= 1435) e = 1440;
    if (e <= s) return;
    ref
        .read(plannerViewConfigProvider(viewKey).notifier)
        .change((c) => c.copyWith(dayWindow: DayWindow(s, e)).withOption('followWorkHours', false));
  }

  Future<void> _addZone(BuildContext context, WidgetRef ref, PlannerViewConfig config) async {
    final l = context.l10n;
    final zone = await promptText(context, title: l.pvAddZone, hint: l.pvZoneHint);
    if (zone == null) return;
    try {
      ref.read(zoneResolverProvider).offsetMinutesAt(DateTime.utc(2026), zone);
    } on Object {
      if (context.mounted) showInfoSnackBar(context, l.pvZoneHint);
      return;
    }
    ref
        .read(plannerViewConfigProvider(viewKey).notifier)
        .change((c) => c.copyWith(extraTimeZones: [...c.extraTimeZones, zone]));
  }
}

/// Load tint thresholds of the day headers (T3.4.11): warning and over-capacity, 50–150 %.
class _LoadThresholds extends StatelessWidget {
  const _LoadThresholds({required this.warn, required this.over, required this.onChanged});

  final double warn;
  final double over;
  final void Function(double warn, double over) onChanged;

  @override
  Widget build(BuildContext context) {
    final f = context.plannerFormat();
    final values = RangeValues(warn.clamp(0.5, 1.5), over.clamp(0.5, 1.5));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      child: Row(
        children: [
          Expanded(child: Text(context.l10n.pvLoadThresholds)),
          Text('${f.percent(values.start)} · ${f.percent(values.end)}'),
          SizedBox(
            width: 160,
            child: RangeSlider(
              key: const Key('load-thresholds'),
              min: 0.5,
              max: 1.5,
              divisions: 20,
              values: values,
              labels: RangeLabels(f.percent(values.start), f.percent(values.end)),
              onChanged: (v) => onChanged((v.start * 100).round() / 100, (v.end * 100).round() / 100),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaysSlider extends StatelessWidget {
  const _DaysSlider({required this.label, required this.value, required this.max, required this.onChanged});

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.xl),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(context.plannerFormat().number(value)),
        SizedBox(
          width: 180,
          child: Slider(
            min: 1,
            max: max.toDouble(),
            divisions: max - 1,
            value: value.toDouble(),
            label: '$value',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    ),
  );
}

/// Filter sheet (T3.4.10): categories, tags, priorities, statuses, tracking modes and text.
Future<void> showFilterSheet(BuildContext context, WidgetRef ref, {required String viewKey}) => showAppSheet<void>(
  context,
  title: context.l10n.pvFilters,
  builder: (ctx) => _FilterSheet(viewKey: viewKey),
);

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.viewKey});

  final String viewKey;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ViewFilters _draft;
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(plannerViewConfigProvider(widget.viewKey)).filters;
    _text = TextEditingController(text: _draft.text ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  List<T> _toggle<T>(List<T> list, T value) => list.contains(value)
      ? [
          for (final v in list)
            if (v != value) v,
        ]
      : [...list, value];

  void _apply() {
    final text = _text.text.trim();
    final filters = text.isEmpty ? _draft.copyWith(clearText: true) : _draft.copyWith(text: text);
    ref.read(plannerViewConfigProvider(widget.viewKey).notifier).change((c) => c.copyWith(filters: filters));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final categories = ref.watch(allCategoriesProvider).value ?? const [];
    final tags = ref.watch(tagsProvider).value ?? const [];
    Widget section(String title, List<Widget> chips) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, Space.md, Space.xl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.labelLarge),
          const SizedBox(height: Space.xs),
          Wrap(spacing: Space.xs, runSpacing: Space.xs, children: chips),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.xl),
                child: TextField(
                  key: const Key('filter-text'),
                  controller: _text,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l.pvTextFilterHint,
                    isDense: true,
                  ),
                ),
              ),
              section(l.pvCategories, [
                for (final c in categories.where((c) => !c.archived))
                  FilterChip(
                    avatar: ColorDot(Color(c.color)),
                    label: Text(c.name),
                    selected: _draft.categories.contains(c.id),
                    onSelected: (_) =>
                        setState(() => _draft = _draft.copyWith(categories: _toggle(_draft.categories, c.id))),
                  ),
                FilterChip(
                  label: Text(l.pvNoCategory),
                  selected: _draft.categories.contains(''),
                  onSelected: (_) =>
                      setState(() => _draft = _draft.copyWith(categories: _toggle(_draft.categories, ''))),
                ),
              ]),
              if (tags.isNotEmpty)
                section(l.pvTags, [
                  for (final t in tags)
                    FilterChip(
                      label: Text('#${t.name}'),
                      selected: _draft.tags.contains(t.id),
                      onSelected: (_) => setState(() => _draft = _draft.copyWith(tags: _toggle(_draft.tags, t.id))),
                    ),
                ]),
              section(l.pvPriorities, [
                for (var p = 4; p >= 0; p--)
                  FilterChip(
                    avatar: Icon(PriorityStyle.icon(p), size: 16, color: PriorityStyle.color(p)),
                    label: Text(PriorityStyle.label(context, p)),
                    selected: _draft.priorities.contains(p),
                    onSelected: (_) =>
                        setState(() => _draft = _draft.copyWith(priorities: _toggle(_draft.priorities, p))),
                  ),
              ]),
              section(l.pvStatuses, [
                for (final s in OccurrenceStatus.values)
                  FilterChip(
                    label: Text(context.statusLabel(s)),
                    selected: _draft.statuses.contains(s.name),
                    onSelected: (_) =>
                        setState(() => _draft = _draft.copyWith(statuses: _toggle(_draft.statuses, s.name))),
                  ),
              ]),
              section(l.pvTrackingModes, [
                for (final m in TrackingMode.values)
                  FilterChip(
                    label: Text(context.trackingLabel(m)),
                    selected: _draft.trackingModes.contains(m.name),
                    onSelected: (_) =>
                        setState(() => _draft = _draft.copyWith(trackingModes: _toggle(_draft.trackingModes, m.name))),
                  ),
              ]),
              const SizedBox(height: Space.md),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.md),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  _text.clear();
                  setState(() => _draft = const ViewFilters());
                },
                child: Text(l.pvClearFilters),
              ),
              const Spacer(),
              FilledButton(key: const Key('filter-apply'), onPressed: _apply, child: Text(l.actionApply)),
            ],
          ),
        ),
      ],
    );
  }
}
