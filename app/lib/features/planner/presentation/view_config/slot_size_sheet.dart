import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/grid/engine/time_scale.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the slot-size sheet of [viewKey] (T3.4.05 / T3.5.04; also double-tap on the ruler).
Future<void> showSlotSizeSheet(BuildContext context, WidgetRef ref, {required String viewKey, bool timeGrid = true}) =>
    showAppSheet<void>(
      context,
      title: context.l10n.pvSlotSize,
      builder: (ctx) => SlotSizeSheet(viewKey: viewKey, timeGrid: timeGrid, outerContext: context),
    );

/// Rows per day and the length of the last (shorter) row for a slot size.
({int rows, int last}) rowsForSlot(int slot) {
  final rows = (kMinutesPerDay + slot - 1) ~/ slot;
  return (rows: rows, last: kMinutesPerDay - (rows - 1) * slot);
}

class SlotSizeSheet extends ConsumerStatefulWidget {
  const SlotSizeSheet({required this.viewKey, required this.outerContext, this.timeGrid = true, super.key});

  final String viewKey;

  /// Time-grid views also show zoom / render / table threshold options.
  final bool timeGrid;
  final BuildContext outerContext;

  @override
  ConsumerState<SlotSizeSheet> createState() => _SlotSizeSheetState();
}

class _SlotSizeSheetState extends ConsumerState<SlotSizeSheet> {
  late PlannerViewConfig _draft;
  final _custom = TextEditingController();
  bool _customInvalid = false;

  static const _snapChoices = [1, 5, 10, 15, 20, 30, 60];

  @override
  void initState() {
    super.initState();
    _draft = ref.read(plannerViewConfigProvider(widget.viewKey));
    if (!SlotPresets.isPreset(_draft.slotMinutes)) _custom.text = '${_draft.slotMinutes}';
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _setSlot(int minutes) => setState(() => _draft = _draft.withSlot(minutes));

  void _onCustom(String text) {
    final parsed = parseSlotMinutes(text);
    setState(() {
      _customInvalid = text.trim().isNotEmpty && parsed == null;
      if (parsed != null) _draft = _draft.withSlot(parsed);
    });
  }

  void _apply() {
    ref.read(plannerViewConfigProvider(widget.viewKey).notifier).update(_draft);
    Navigator.pop(context);
  }

  Future<void> _saveAsNew() async {
    final l = context.l10n;
    final name = await promptText(context, title: l.pvSaveAsNewView, hint: l.pvViewName);
    if (name == null || !mounted) return;
    final id = await ref.read(savedViewsRepositoryProvider).create(name, _draft);
    if (!mounted) return;
    Navigator.pop(context);
    final outer = widget.outerContext;
    if (outer.mounted) {
      showInfoSnackBar(outer, l.pvViewSaved);
      ref.read(plannerNavProvider).openView(outer, ViewKeys.saved(id), date: ref.read(plannerAnchorProvider));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.plannerFormat(use24h: ref.watch(userPreferencesProvider).use24h);
    final slot = _draft.slotMinutes;
    final r = rowsForSlot(slot);
    final preview = r.last != slot && r.rows > 1
        ? '${l.pvRowsPerDay(r.rows)}, ${l.pvLastRowShort(f.duration(r.last))}'
        : l.pvRowsPerDay(r.rows);
    final thresholds = [
      for (final m in SlotPresets.minutes)
        if (m >= 15) m,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, 0, Space.xl, Space.md),
            children: [
              Text(
                l.pvCurrentSize(slotLabel(f, slot)),
                key: const Key('slot-current'),
                style: context.text.titleMedium,
              ),
              const SizedBox(height: Space.md),
              Text(l.pvSlotPresets, style: context.text.labelLarge),
              const SizedBox(height: Space.xs),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  for (final m in SlotPresets.minutes)
                    ChoiceChip(
                      key: Key('slot-preset-$m'),
                      label: Text(slotLabel(f, m)),
                      selected: slot == m,
                      onSelected: (_) {
                        _custom.clear();
                        setState(() => _customInvalid = false);
                        _setSlot(m);
                      },
                    ),
                ],
              ),
              const SizedBox(height: Space.lg),
              Text(l.pvSlotCustom, style: context.text.labelLarge),
              const SizedBox(height: Space.xs),
              TextField(
                key: const Key('slot-custom'),
                controller: _custom,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: l.pvSlotCustomHint,
                  errorText: _customInvalid ? l.pvSlotInvalid : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _onCustom,
              ),
              const SizedBox(height: Space.xs),
              Text(
                preview,
                key: const Key('slot-preview'),
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: Space.lg),
              Row(
                children: [
                  Expanded(child: Text(l.pvRowHeight, style: context.text.labelLarge)),
                  Text(l.pvPixels(_draft.slotExtentPx.round().toString())),
                ],
              ),
              Slider(
                key: const Key('slot-row-height'),
                min: 16,
                max: 160,
                divisions: 36,
                value: _draft.slotExtentPx.clamp(16.0, 160.0),
                label: l.pvPixels(_draft.slotExtentPx.round().toString()),
                onChanged: (v) => setState(() => _draft = _draft.copyWith(slotExtentPx: v.roundToDouble())),
              ),
              if (widget.timeGrid) ...[
                Text(l.pvZoomMode, style: context.text.labelLarge),
                const SizedBox(height: Space.xs),
                SegmentedButton<ZoomMode>(
                  segments: [
                    ButtonSegment(value: ZoomMode.fixed, label: Text(l.pvZoomFixed)),
                    ButtonSegment(value: ZoomMode.semantic, label: Text(l.pvZoomSemantic)),
                  ],
                  selected: {_draft.zoomMode},
                  onSelectionChanged: (s) => setState(() => _draft = _draft.copyWith(zoomMode: s.first)),
                ),
                const SizedBox(height: Space.md),
                Text(l.pvRenderMode, style: context.text.labelLarge),
                const SizedBox(height: Space.xs),
                SegmentedButton<RenderMode>(
                  segments: [
                    ButtonSegment(value: RenderMode.auto, label: Text(l.pvRenderAuto)),
                    ButtonSegment(value: RenderMode.timeline, label: Text(l.pvRenderTimeline)),
                    ButtonSegment(value: RenderMode.table, label: Text(l.pvRenderTable)),
                  ],
                  selected: {_draft.renderMode},
                  onSelectionChanged: (s) => setState(() => _draft = _draft.copyWith(renderMode: s.first)),
                ),
                if (_draft.renderMode == RenderMode.auto)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: DropdownButtonFormField<int>(
                      initialValue: thresholds.contains(_draft.autoTableThresholdMinutes)
                          ? _draft.autoTableThresholdMinutes
                          : 120,
                      decoration: InputDecoration(labelText: l.pvTableThreshold('…'), isDense: true),
                      items: [
                        for (final m in thresholds)
                          DropdownMenuItem(value: m, child: Text(l.pvTableThreshold(slotLabel(f, m)))),
                      ],
                      onChanged: (v) => setState(() => _draft = _draft.copyWith(autoTableThresholdMinutes: v)),
                    ),
                  ),
              ],
              const SizedBox(height: Space.md),
              DropdownButtonFormField<int>(
                key: const Key('slot-snap'),
                initialValue: _snapChoices.contains(_draft.snapMinutes) ? _draft.snapMinutes : null,
                decoration: InputDecoration(labelText: l.pvSnap, isDense: true),
                items: [for (final m in _snapChoices) DropdownMenuItem(value: m, child: Text(f.duration(m)))],
                onChanged: (v) => setState(() => _draft = _draft.copyWith(snapMinutes: v)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.md),
          child: Row(
            children: [
              Flexible(
                child: TextButton(
                  key: const Key('slot-save-new'),
                  onPressed: _customInvalid ? null : () => unawaited(_saveAsNew()),
                  child: Text(l.pvSaveAsNewView, textAlign: TextAlign.center),
                ),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('slot-apply'),
                onPressed: _customInvalid ? null : _apply,
                child: Text(l.pvApplyToView),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
