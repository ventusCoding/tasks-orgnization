import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/places.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/map_layer.dart';
import 'package:everslot/features/planner/presentation/views/mini_month.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Map view (T3.7.13): occurrences of a date range (`options.rangeDays`) whose task has
/// coordinates, as pins colored by category on OpenStreetMap; tap a pin for the item, the list
/// below lists them too.
class MapView extends ConsumerStatefulWidget {
  const MapView({required this.args, super.key});

  final PlannerViewArgs args;

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  late LocalDate _start;
  String? _selected;

  String get _key => widget.args.viewKey;

  @override
  void initState() {
    super.initState();
    _start = widget.args.date ?? ref.read(plannerAnchorProvider) ?? ref.read<LocalDate>(plannerTodayProvider);
  }

  void _go(LocalDate d) {
    setState(() {
      _start = d;
      _selected = null;
    });
    ref.read(plannerAnchorProvider.notifier).set(d);
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
    final today = ref.watch(plannerTodayProvider);
    final days = config.option<int>('rangeDays', 7).clamp(1, 92);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final places = ref.watch(placeTasksProvider).value ?? const <String, Task>{};
    final items = [
      for (final i in filteredItems(ref, DayRange(_start, days), config).value ?? const <PlannerItem>[])
        if (places.containsKey(i.taskId)) i,
    ];
    final colors = viewColors(context, ref, config);
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final pins = [
      for (final i in items)
        MapPin(
          id: i.key,
          lat: places[i.taskId]!.locationLat!,
          lng: places[i.taskId]!.locationLng!,
          color: colors.of(i).accent,
          label: '${i.title}, ${f.dayShort(i.startLocal.date)} ${f.timeOf(i.startLocal)}',
        ),
    ];
    final selected = items.where((i) => i.key == _selected).firstOrNull;
    final layer = ref.watch(mapLayerBuilderProvider);
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
          PlannerFilterButton(viewKey: _key),
          PlannerMoreMenu(viewKey: _key, kind: ViewSettingsKind.list),
        ],
      ),
      body: Column(
        children: [
          ActiveFilterBar(viewKey: _key),
          if (pins.isEmpty)
            Expanded(
              child: EmptyState(icon: Icons.map_outlined, title: l.pvViewMap, message: l.pvMapPlaceholder),
            )
          else ...[
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: layer(context, pins: pins, onTapPin: (p) => setState(() => _selected = p.id)),
                  ),
                  if (selected != null)
                    PositionedDirectional(
                      start: Space.md,
                      end: Space.md,
                      bottom: Space.md,
                      child: PlannerItemChip(
                        key: const Key('map-selected'),
                        viewKey: _key,
                        item: selected,
                        colors: colors.of(selected),
                        showDate: true,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: ListView(
                key: const Key('map-list'),
                padding: const EdgeInsets.all(Space.sm),
                children: [
                  SectionHeader(l.pvWithPlace, padding: const EdgeInsetsDirectional.only(bottom: Space.xs)),
                  for (final i in items)
                    ListTile(
                      key: ValueKey('map-row-${i.key}'),
                      leading: Icon(Icons.location_on, color: colors.of(i).accent),
                      title: Text(i.title),
                      subtitle: Text(
                        ['${f.dayShort(i.startLocal.date)} ${f.timeOf(i.startLocal)}', ?i.location].join(' · '),
                      ),
                      selected: i.key == _selected,
                      onTap: () => setState(() => _selected = i.key),
                      onLongPress: () => ref.read(plannerNavProvider).openTask(context, i),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Place picker of the task editor (T3.7.13): search with the geocoder, or tap the map to drop a
/// pin (named by reverse geocoding). Returns the chosen place.
Future<PlaceCandidate?> pickPlace(BuildContext context, {String initialQuery = '', PlaceCandidate? current}) =>
    showAppSheet<PlaceCandidate>(
      context,
      title: context.l10n.pvPickPlace,
      builder: (ctx) => _PlacePicker(initialQuery: initialQuery, current: current),
    );

class _PlacePicker extends ConsumerStatefulWidget {
  const _PlacePicker({required this.initialQuery, this.current});

  final String initialQuery;
  final PlaceCandidate? current;

  @override
  ConsumerState<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends ConsumerState<_PlacePicker> {
  late final _query = TextEditingController(text: widget.initialQuery);
  List<PlaceCandidate>? _results;
  late PlaceCandidate? _pin = widget.current;
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _busy = true);
    final found = await ref.read(placeGeocoderProvider).search(_query.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _results = found;
      if (found.isNotEmpty) _pin = found.first;
    });
  }

  Future<void> _drop(double lat, double lng) async {
    final l = context.l10n;
    setState(() => _pin = PlaceCandidate(name: l.pvDroppedPin, lat: lat, lng: lng));
    final name = await ref.read(placeGeocoderProvider).nameAt(lat, lng);
    if (!mounted || name == null) return;
    setState(() => _pin = PlaceCandidate(name: name, lat: lat, lng: lng));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final layer = ref.watch(mapLayerBuilderProvider);
    final pin = _pin;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('place-search'),
            controller: _query,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l.pvPlaceSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busy ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()) : null,
            ),
            onSubmitted: (_) => unawaited(_search()),
          ),
          if (_results != null && _results!.isEmpty)
            Padding(padding: const EdgeInsets.all(Space.sm), child: Text(l.pvPlaceNoResults)),
          for (final r in _results ?? const <PlaceCandidate>[])
            ListTile(
              key: ValueKey('place-result-${r.name}'),
              leading: const Icon(Icons.place_outlined),
              title: Text(r.name),
              selected: r == pin,
              onTap: () => setState(() => _pin = r),
            ),
          const SizedBox(height: Space.sm),
          Text(l.pvPlaceTapHint, style: context.text.bodySmall),
          const SizedBox(height: Space.xs),
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: layer(
                context,
                pins: [
                  if (pin != null)
                    MapPin(id: 'pin', lat: pin.lat, lng: pin.lng, color: context.colors.primary, label: pin.name),
                ],
                center: pin == null ? null : (lat: pin.lat, lng: pin.lng),
                onTapMap: (lat, lng) => unawaited(_drop(lat, lng)),
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          FilledButton(
            key: const Key('place-use'),
            onPressed: pin == null ? null : () => Navigator.pop(context, pin),
            child: Text(pin == null ? l.pvUsePlace : '${l.pvUsePlace}: ${pin.name}'),
          ),
        ],
      ),
    );
  }
}
