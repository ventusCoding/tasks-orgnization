import 'package:everslot/core/preferences/user_preferences.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/recurrence_ui/application/recurrence_preview.dart';
import 'package:everslot/features/recurrence_ui/domain/recurrence_presets.dart';
import 'package:everslot/features/recurrence_ui/presentation/recurrence_editor_screen.dart';
import 'package:everslot/features/recurrence_ui/presentation/recurrence_inputs.dart';
import 'package:everslot/features/recurrence_ui/presentation/recurrence_labels.dart';
import 'package:everslot/features/recurrence_ui/presentation/recurrence_preview_view.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Bottom-sheet body of the recurrence picker (T2.1.15): presets for the [mode], inline inputs
/// for the parameterized ones, *Ends*, a live description and the anchor note. *Custom…*
/// opens the advanced editor (T2.1.16). Pops a [RecurrencePickResult].
class RecurrencePresetsSheet extends ConsumerStatefulWidget {
  const RecurrencePresetsSheet({required this.anchor, super.key, this.initial, this.mode = RecurrencePickerMode.task});

  final RecurrenceAnchor anchor;
  final RecurrenceRule? initial;
  final RecurrencePickerMode mode;

  @override
  ConsumerState<RecurrencePresetsSheet> createState() => _RecurrencePresetsSheetState();
}

class _RecurrencePresetsSheetState extends ConsumerState<RecurrencePresetsSheet> {
  late RecurrencePreset _preset;
  late PresetParams _params;
  late RecurrenceEnds _ends;
  RecurrenceRule? _custom;

  /// False until the user changes something: Done then returns the initial rule untouched.
  late bool _dirty;

  RecurrencePreview? _preview;
  RecurrenceService? _previewService;

  RecurrenceAnchor get _anchor => widget.anchor;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _preset = RecurrencePresets.detect(initial, _anchor, mode: widget.mode);
    _dirty = false;
    if (_preset == RecurrencePreset.none && !widget.mode.allowsNone) {
      _preset = RecurrencePreset.daily;
      _dirty = true;
    }
    _params = PresetParams.initial(_anchor, initial);
    _ends = RecurrenceEnds.of(initial);
    _custom = _preset == RecurrencePreset.custom ? initial : null;
  }

  /// The rule the sheet currently describes (null = does not repeat).
  RecurrenceRule? get _rule {
    if (!_dirty) return widget.initial;
    if (_preset == RecurrencePreset.none) return null;
    final base = _preset == RecurrencePreset.custom ? _custom : RecurrencePresets.build(_preset, _anchor, _params);
    if (base == null) return null;
    var rule = _ends.applyTo(base);
    final initial = widget.initial;
    if (initial != null && _preset != RecurrencePreset.custom) {
      // Presets don't edit exceptions, week start or count mode: keep them.
      rule = rule.copyWith(
        exdates: initial.exdates,
        rdates: initial.rdates,
        wkst: initial.wkst,
        countMode: initial.countMode,
      );
    }
    return rule;
  }

  void _update(void Function() change) => setState(() {
    change();
    _dirty = true;
  });

  RecurrencePreview? _previewFor(RecurrenceService service, RecurrenceRule? rule) {
    if (rule == null) return null;
    final cached = _preview;
    if (cached != null && identical(service, _previewService) && cached.rule == rule) return cached;
    _previewService = service;
    return _preview = RecurrencePreviewer(service, count: 3, calendarDays: 0).preview(rule, _anchor);
  }

  Future<void> _openCustom() async {
    final result = await showRecurrenceEditor(
      context,
      anchor: _anchor,
      initial: _rule ?? RecurrencePresets.defaultCustomRule,
      mode: widget.mode,
    );
    if (result == null || !mounted) return;
    Navigator.of(context).pop(result);
  }

  void _select(RecurrencePreset? preset) {
    if (preset == null) return;
    if (preset == RecurrencePreset.custom) {
      _openCustom();
      return;
    }
    if (preset == _preset && _dirty) return;
    _update(() => _preset = preset);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = ref.watch(recurrenceServiceProvider);
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final rule = _rule;
    final preview = _previewFor(service, rule);
    String describe(RecurrenceRule r, RecurrenceAnchor a) {
      try {
        return service.describe(r, a, locale: context.localeName, use24h: prefs.use24h);
      } on Object {
        return '';
      }
    }

    final description = rule == null ? null : describe(rule, preview?.alignedAnchor ?? _anchor);
    final canSave = rule == null || (preview?.isValid ?? false);
    final presets = RecurrencePresets.available(widget.mode, _anchor);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Capped so the presets stay reachable at large text scales (the card scrolls itself).
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.3),
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
            child: RecurrenceSummary(description: description, preview: preview, format: format, nextCount: 3),
          ),
        ),
        Flexible(
          child: ListView(
            key: const ValueKey('recur-sheet-list'),
            shrinkWrap: true,
            children: [
              RadioGroup<RecurrencePreset>(
                groupValue: _preset,
                onChanged: _select,
                child: Column(children: [for (final p in presets) ..._tile(context, p, format, prefs, describe)]),
              ),
              if (_preset != RecurrencePreset.none && _preset != RecurrencePreset.custom)
                RecurrenceSection(
                  title: l.recurEnds,
                  child: RecurrenceEndsEditor(
                    ends: _ends,
                    firstDate: _anchor.start.date,
                    format: format,
                    onChanged: (e) => _update(() => _ends = e),
                  ),
                ),
              const SizedBox(height: Space.md),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.sm),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: Space.sm,
            overflowSpacing: Space.xs,
            children: [
              TextButton(
                key: const ValueKey('recur-cancel'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.actionCancel),
              ),
              FilledButton(
                key: const ValueKey('recur-done'),
                onPressed: canSave
                    ? () => Navigator.of(
                        context,
                      ).pop(RecurrencePickResult(rule: rule, anchor: rule == null ? _anchor : preview!.alignedAnchor))
                    : null,
                child: Text(l.actionDone),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _tile(
    BuildContext context,
    RecurrencePreset preset,
    AppFormat format,
    UserPreferences prefs,
    String Function(RecurrenceRule, RecurrenceAnchor) describe,
  ) {
    final l = context.l10n;
    final selected = _preset == preset;
    final title = switch (preset) {
      RecurrencePreset.none => l.recurPresetNone,
      RecurrencePreset.specificDays => l.recurPresetSpecificDays,
      RecurrencePreset.everyNDays => l.recurPresetEveryNDays,
      RecurrencePreset.intraday => l.recurPresetIntraday,
      RecurrencePreset.timesPerDay => l.recurPresetTimesPerDay,
      RecurrencePreset.quota => l.recurPresetQuota,
      RecurrencePreset.afterCompletion => l.recurPresetAfterCompletion,
      RecurrencePreset.custom => l.recurPresetCustom,
      _ => describe(RecurrencePresets.build(preset, _anchor, _params)!, _anchor),
    };
    final custom = _custom;
    return [
      RadioListTile<RecurrencePreset>(
        key: ValueKey('recur-preset-${preset.name}'),
        value: preset,
        dense: true,
        title: Text(title),
        subtitle: preset == RecurrencePreset.custom && selected && custom != null
            ? Text(describe(custom, _anchor))
            : null,
        secondary: preset == RecurrencePreset.custom ? const Icon(Icons.tune) : null,
      ),
      if (selected && preset.hasParams)
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.xxxl + Space.sm, 0, Space.lg, Space.sm),
          child: _paramsEditor(context, preset, format, prefs),
        ),
    ];
  }

  Widget _paramsEditor(BuildContext context, RecurrencePreset preset, AppFormat format, UserPreferences prefs) {
    final l = context.l10n;
    final p = _params;
    void set(PresetParams next) => _update(() => _params = next);
    switch (preset) {
      case RecurrencePreset.specificDays:
        return WeekdayChips(
          selected: p.days,
          weekStart: prefs.weekStart,
          format: format,
          onChanged: (days) => set(p.copyWith(days: days)),
        );
      case RecurrencePreset.everyNDays:
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Space.xs,
          children: [
            Text(l.recurInterval),
            NumberStepper(
              fieldKey: const ValueKey('recur-every-days'),
              value: p.everyDays,
              min: 2,
              max: 999,
              label: l.recurInterval,
              onChanged: (v) => set(p.copyWith(everyDays: v)),
            ),
            Text(l.recurUnitDay),
          ],
        );
      case RecurrencePreset.intraday:
        final window = p.window;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final step in PresetParams.quickSteps)
                  ChoiceChip(
                    key: ValueKey('recur-step-$step'),
                    label: Text(format.duration(step)),
                    selected: p.stepMinutes == step,
                    onSelected: (_) => set(p.copyWith(stepMinutes: step)),
                  ),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.xs,
              children: [
                Text(l.recurInterval),
                NumberStepper(
                  fieldKey: const ValueKey('recur-step-minutes'),
                  value: p.stepMinutes,
                  max: 1440,
                  label: l.recurInterval,
                  onChanged: (v) => set(p.copyWith(stepMinutes: v)),
                ),
                Text(l.recurUnitMinute),
              ],
            ),
            SwitchListTile(
              key: const ValueKey('recur-window-switch'),
              contentPadding: EdgeInsets.zero,
              title: Text(window == null ? l.recurWindowNone : l.recurWindow),
              value: window != null,
              onChanged: (on) => set(p.copyWith(window: on ? PresetParams.defaultWindow : null)),
            ),
            if (window != null)
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.xs,
                children: [
                  ActionChip(
                    key: const ValueKey('recur-window-start'),
                    avatar: const Icon(Icons.schedule),
                    label: Text('${l.recurWindowStart} ${format.time(window.start)}'),
                    onPressed: () async {
                      final t = await pickTime(context, initial: window.start, use24h: prefs.use24h);
                      if (t != null && mounted) set(p.copyWith(window: window.copyWith(start: t)));
                    },
                  ),
                  ActionChip(
                    key: const ValueKey('recur-window-end'),
                    avatar: const Icon(Icons.schedule),
                    label: Text('${l.recurWindowEnd} ${format.time(window.end)}'),
                    onPressed: () async {
                      final t = await pickTime(
                        context,
                        initial: window.end.isEndOfDay ? LocalTime.midnight : window.end,
                        use24h: prefs.use24h,
                      );
                      if (t == null || !mounted) return;
                      set(p.copyWith(window: window.copyWith(end: t == LocalTime.midnight ? LocalTime.endOfDay : t)));
                    },
                  ),
                ],
              ),
          ],
        );
      case RecurrencePreset.timesPerDay:
        return TimeListEditor(
          times: p.times,
          format: format,
          use24h: prefs.use24h,
          initialNewTime: _anchor.start.time,
          onChanged: (t) => set(p.copyWith(times: t)),
        );
      case RecurrencePreset.quota:
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            NumberStepper(
              fieldKey: const ValueKey('recur-quota-times'),
              value: p.quotaTimes,
              max: 999,
              label: l.recurQuotaTimes,
              onChanged: (v) => set(p.copyWith(quotaTimes: v)),
            ),
            Text(l.recurQuotaPer),
            for (final unit in PeriodUnit.values)
              ChoiceChip(
                key: ValueKey('recur-quota-per-${unit.name}'),
                label: Text(l.recurPeriodUnit(unit)),
                selected: p.quotaPer == unit,
                onSelected: (_) => set(p.copyWith(quotaPer: unit)),
              ),
          ],
        );
      case RecurrencePreset.afterCompletion:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.xs,
              children: [
                NumberStepper(
                  fieldKey: const ValueKey('recur-after-amount'),
                  value: p.afterAmount,
                  max: 9999,
                  label: l.recurTypeAfter,
                  onChanged: (v) => set(p.copyWith(afterAmount: v)),
                ),
                DropdownButton<RecurrenceUnit>(
                  key: const ValueKey('recur-after-unit'),
                  value: p.afterUnit,
                  onChanged: (u) {
                    if (u != null) set(p.copyWith(afterUnit: u));
                  },
                  items: [
                    for (final u in RecurrenceUnit.values)
                      if (!_anchor.allDay || u.isDayBased || u == p.afterUnit)
                        DropdownMenuItem(value: u, child: Text(l.recurDelayUnit(u))),
                  ],
                ),
              ],
            ),
            Text(l.recurAfterHint, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        );
      case RecurrencePreset.none:
      case RecurrencePreset.daily:
      case RecurrencePreset.weekdays:
      case RecurrencePreset.weekly:
      case RecurrencePreset.monthlyOnDay:
      case RecurrencePreset.monthlyOnNthWeekday:
      case RecurrencePreset.monthlyOnLastWeekday:
      case RecurrencePreset.lastDayOfMonth:
      case RecurrencePreset.yearly:
      case RecurrencePreset.custom:
        return const SizedBox.shrink();
    }
  }
}
