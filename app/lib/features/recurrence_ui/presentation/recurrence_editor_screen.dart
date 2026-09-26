import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/recurrence_ui/application/recurrence_preview.dart';
import 'package:everslot/features/recurrence_ui/domain/recurrence_presets.dart';
import 'package:everslot/features/recurrence_ui/presentation/recurrence_inputs.dart';
import 'package:everslot/features/recurrence_ui/presentation/recurrence_labels.dart';
import 'package:everslot/features/recurrence_ui/presentation/recurrence_preview_view.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the advanced recurrence editor (T2.1.16) as a full-screen dialog. Returns null when
/// closed without saving.
Future<RecurrencePickResult?> showRecurrenceEditor(
  BuildContext context, {
  required RecurrenceAnchor anchor,
  RecurrenceRule? initial,
  RecurrencePickerMode mode = RecurrencePickerMode.task,
}) => Navigator.of(context).push<RecurrencePickResult>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => RecurrenceEditorScreen(anchor: anchor, initial: initial, mode: mode),
  ),
);

/// Full recurrence editor exposing every field of the rule model (arch §8.1), with a live
/// description, the next 10 occurrences, a 60-day mini calendar, warnings and inline errors.
/// Save is disabled while the rule is invalid.
class RecurrenceEditorScreen extends ConsumerStatefulWidget {
  const RecurrenceEditorScreen({required this.anchor, super.key, this.initial, this.mode = RecurrencePickerMode.task});

  final RecurrenceAnchor anchor;
  final RecurrenceRule? initial;
  final RecurrencePickerMode mode;

  @override
  ConsumerState<RecurrenceEditorScreen> createState() => _RecurrenceEditorScreenState();
}

class _RecurrenceEditorScreenState extends ConsumerState<RecurrenceEditorScreen> {
  late RecurrenceRule _rule;
  final Map<RuleType, RecurrenceRule> _drafts = {};
  late bool _more;
  late bool _fromEnd;

  RecurrencePreview? _preview;
  RecurrenceService? _previewService;

  RecurrenceAnchor get _anchor => widget.anchor;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _rule = initial != null && widget.mode.ruleTypes.contains(initial.type)
        ? initial
        : RecurrencePresets.defaultCustomRule;
    _more = _usesAdvancedFields(_rule);
    _fromEnd = _rule.byMonthDay.isNotEmpty && _rule.byMonthDay.every((d) => d < 0);
  }

  static bool _usesAdvancedFields(RecurrenceRule r) =>
      r.bySetPos.isNotEmpty ||
      r.byHour.isNotEmpty ||
      r.byMinute.isNotEmpty ||
      r.byYearDay.isNotEmpty ||
      r.byWeekNo.isNotEmpty ||
      r.wkst != Weekday.monday ||
      r.monthDayOverflow != MonthOverflow.skip ||
      (r.byMonth.isNotEmpty && r.freq != Frequency.yearly) ||
      (r.byMonthDay.isNotEmpty && r.freq != Frequency.monthly && r.freq != Frequency.yearly);

  void _set(RecurrenceRule rule) => setState(() => _rule = rule);

  RecurrencePreview _previewFor(RecurrenceService service) {
    final cached = _preview;
    if (cached != null && identical(_previewService, service) && cached.rule == _rule) return cached;
    _previewService = service;
    return _preview = RecurrencePreviewer(service).preview(_rule, _anchor);
  }

  // ---------------------------------------------------------------------------
  // Rule transformations

  void _switchType(RuleType type) {
    if (type == _rule.type) return;
    _drafts[_rule.type] = _rule;
    final ends = RecurrenceEnds.of(_rule);
    final next =
        _drafts[type] ??
        switch (type) {
          RuleType.fixed => RecurrencePresets.defaultCustomRule,
          RuleType.afterCompletion => RecurrenceRule.forAfterCompletion(1, RecurrenceUnit.day),
          RuleType.quota => RecurrenceRule.forQuota(3, PeriodUnit.week),
        };
    _set(ends.applyTo(next));
  }

  /// Changes the frequency and drops the fields the new frequency can't use.
  RecurrenceRule _withFreq(Frequency f) {
    final old = _rule.freq;
    var r = _rule.copyWith(freq: f);
    if (!f.isSubDaily) r = r.copyWith(window: null);
    if (f.isSubDaily) {
      r = r.copyWith(times: const []);
      if (!old.isSubDaily && f == Frequency.minutely && r.interval < 5) r = r.copyWith(interval: 15);
    }
    if (f != Frequency.yearly) r = r.copyWith(byWeekNo: const []);
    if (f == Frequency.daily || f == Frequency.weekly || f == Frequency.monthly) {
      r = r.copyWith(byYearDay: const []);
    }
    if (f == Frequency.weekly) r = r.copyWith(byMonthDay: const []);
    final ordinalsOk = (f == Frequency.monthly || f == Frequency.yearly) && r.byWeekNo.isEmpty;
    final weekdays = r.byWeekday;
    if (!ordinalsOk && weekdays != null && weekdays.any((w) => w.n != null)) {
      final plain = {for (final w in weekdays) w.day};
      r = r.copyWith(
        byWeekday: [
          for (final d in Weekday.values)
            if (plain.contains(d)) WeekdayRule(d),
        ],
      );
    }
    return r;
  }

  List<WeekdayRule> get _ordinals => [
    for (final w in _rule.byWeekday ?? const <WeekdayRule>[])
      if (w.n != null) w,
  ];

  /// Plain weekday chips; a weekly rule without days shows its derived (anchor) weekday.
  Set<Weekday> get _plainDays {
    final weekdays = _rule.byWeekday;
    if (weekdays == null) {
      return _rule.freq == Frequency.weekly && _rule.type == RuleType.fixed ? {_anchor.start.date.weekday} : {};
    }
    return {
      for (final w in weekdays)
        if (w.n == null) w.day,
    };
  }

  void _setPlainDays(Set<Weekday> days) {
    final all = [
      for (final d in Weekday.values)
        if (days.contains(d)) WeekdayRule(d),
      ..._ordinals,
    ];
    if (all.isEmpty) {
      _set(_rule.copyWith(byWeekday: _rule.freq == Frequency.weekly ? const <WeekdayRule>[] : null));
    } else {
      _set(_rule.copyWith(byWeekday: all));
    }
  }

  void _removeOrdinal(WeekdayRule entry) {
    final rest = [
      for (final w in _rule.byWeekday ?? const <WeekdayRule>[])
        if (w != entry) w,
    ];
    _set(_rule.copyWith(byWeekday: rest.isEmpty ? null : rest));
  }

  Future<void> _addOrdinal(AppFormat format, Weekday weekStart) async {
    final entry = await showDialog<WeekdayRule>(
      context: context,
      builder: (ctx) => _OrdinalDialog(format: format, weekStart: weekStart, initialDay: _anchor.start.date.weekday),
    );
    if (entry == null || !mounted) return;
    final current = _rule.byWeekday ?? const <WeekdayRule>[];
    if (current.contains(entry)) return;
    _set(_rule.copyWith(byWeekday: [...current, entry]));
  }

  List<int> _toggled(List<int> values, int value) {
    final set = {...values};
    if (!set.remove(value)) set.add(value);
    return set.toList()..sort();
  }

  Future<int?> _promptInt(String title, {int? min, int? max}) async {
    final text = await promptText(context, title: title);
    final value = int.tryParse((text ?? '').replaceAll('−', '-').trim());
    if (value == null) return null;
    if (min != null && value < min) return null;
    if (max != null && value > max) return null;
    return value;
  }

  // ---------------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = ref.watch(recurrenceServiceProvider);
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final preview = _previewFor(service);
    String? description;
    try {
      description = service.describe(_rule, preview.alignedAnchor, locale: context.localeName, use24h: prefs.use24h);
    } on Object {
      description = null;
    }
    final types = widget.mode.ruleTypes;
    final fixed = _rule.type == RuleType.fixed;
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(onPressed: () => Navigator.of(context).maybePop()),
        title: Text(l.recurAdvancedTitle),
        actions: [
          TextButton(
            key: const ValueKey('recur-save'),
            onPressed: preview.isValid
                ? () => Navigator.of(context).pop(RecurrencePickResult(rule: _rule, anchor: preview.alignedAnchor))
                : null,
            child: Text(l.actionSave),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pinned live summary (capped so the fields stay usable at large text scales).
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.25),
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.sm),
              child: RecurrenceSummary(description: description, preview: preview, format: format),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _fields(context, format, prefs.weekStart, prefs.use24h, preview, types, fixed)),
        ],
      ),
    );
  }

  Widget _fields(
    BuildContext context,
    AppFormat format,
    Weekday weekStart,
    bool use24h,
    RecurrencePreview preview,
    List<RuleType> types,
    bool fixed,
  ) {
    final l = context.l10n;
    return ListView(
      key: const ValueKey('recur-editor-list'),
      padding: const EdgeInsetsDirectional.only(bottom: Space.xxxl),
      children: [
        if (types.length > 1)
          RecurrenceSection(
            title: l.recurType,
            child: Wrap(
              spacing: Space.sm,
              runSpacing: Space.xs,
              children: [
                for (final t in types)
                  ChoiceChip(
                    key: ValueKey('recur-type-${t.json}'),
                    label: Text(switch (t) {
                      RuleType.fixed => l.recurTypeFixed,
                      RuleType.afterCompletion => l.recurTypeAfter,
                      RuleType.quota => l.recurTypeQuota,
                    }),
                    selected: _rule.type == t,
                    onSelected: (_) => _switchType(t),
                  ),
              ],
            ),
          ),
        ...switch (_rule.type) {
          RuleType.fixed => _fixedSections(context, format, weekStart, use24h, preview),
          RuleType.afterCompletion => _afterSections(context),
          RuleType.quota => _quotaSections(context, format, weekStart, preview),
        },
        RecurrenceSection(
          title: l.recurEnds,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              RecurrenceEndsEditor(
                ends: RecurrenceEnds.of(_rule),
                firstDate: _anchor.start.date,
                format: format,
                onChanged: (e) => _set(e.applyTo(_rule)),
              ),
              if (_rule.count != null) ...[
                const SizedBox(height: Space.xs),
                Text(l.recurCountMode, style: context.text.labelMedium),
                Wrap(
                  spacing: Space.sm,
                  children: [
                    for (final (mode, label) in [
                      (CountMode.occurrences, l.recurCountOccurrences),
                      (CountMode.completions, l.recurCountCompletions),
                    ])
                      ChoiceChip(
                        key: ValueKey('recur-countmode-${mode.name}'),
                        label: Text(label),
                        selected: _rule.countMode == mode,
                        onSelected: (_) => _set(_rule.copyWith(countMode: mode)),
                      ),
                  ],
                ),
              ],
              ..._issues(context, preview, const {'count', 'until'}),
            ],
          ),
        ),
        if (fixed) ..._exceptionSections(context, format, preview),
        RecurrenceSection(
          title: l.recurPreview,
          child: RecurrenceNextList(preview: preview, format: format),
        ),
        if (fixed && preview.calendarStart != null)
          RecurrenceSection(
            title: l.recurPreviewCalendar,
            child: RecurrenceMiniCalendar(preview: preview, weekStart: weekStart, format: format),
          ),
      ],
    );
  }

  /// Inline errors for the given rule fields.
  List<Widget> _issues(BuildContext context, RecurrencePreview preview, Set<String> fields) => [
    for (final issue in preview.validation.errors)
      if (issue.field != null && fields.any((f) => issue.field == f || issue.field!.startsWith('$f.')))
        Padding(
          padding: const EdgeInsetsDirectional.only(top: Space.xs),
          child: Text(
            context.l10n.recurIssueText(issue),
            style: context.text.bodySmall?.copyWith(color: context.colors.error),
          ),
        ),
  ];

  List<Widget> _fixedSections(
    BuildContext context,
    AppFormat format,
    Weekday weekStart,
    bool use24h,
    RecurrencePreview preview,
  ) {
    final l = context.l10n;
    final freq = _rule.freq;
    final calendarFreq = freq == Frequency.monthly || freq == Frequency.yearly;
    final ordinalsAllowed = calendarFreq && _rule.byWeekNo.isEmpty;
    final window = _rule.window;
    return [
      RecurrenceSection(
        title: l.recurFrequency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.xs,
              children: [
                Text(l.recurInterval),
                NumberStepper(
                  fieldKey: const ValueKey('recur-interval'),
                  value: _rule.interval,
                  max: 9999,
                  label: l.recurInterval,
                  onChanged: (v) => _set(_rule.copyWith(interval: v)),
                ),
                DropdownButton<Frequency>(
                  key: const ValueKey('recur-freq'),
                  value: freq,
                  onChanged: (f) {
                    if (f != null && f != freq) _set(_withFreq(f));
                  },
                  items: [
                    for (final f in Frequency.values)
                      if (!_anchor.allDay || !f.isSubDaily || f == freq)
                        DropdownMenuItem(value: f, child: Text(l.recurFrequencyUnit(f))),
                  ],
                ),
              ],
            ),
            ..._issues(context, preview, const {'interval', 'freq'}),
          ],
        ),
      ),
      RecurrenceSection(
        title: l.recurWeekdays,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            WeekdayChips(selected: _plainDays, onChanged: _setPlainDays, weekStart: weekStart, format: format),
            ..._issues(context, preview, const {'byWeekday'}),
          ],
        ),
      ),
      if (ordinalsAllowed || _ordinals.isNotEmpty)
        RecurrenceSection(
          title: l.recurWeekdayOrdinal,
          child: Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final w in _ordinals)
                InputChip(
                  key: ValueKey('recur-ordinal-${w.toRRule()}'),
                  label: Text(l.recurOrdinalWeekday(l.recurOrdinalLabel(w.n!), format.weekdayLong(w.day))),
                  onDeleted: () => _removeOrdinal(w),
                  deleteButtonTooltipMessage: l.recurRemove(
                    l.recurOrdinalWeekday(l.recurOrdinalLabel(w.n!), format.weekdayLong(w.day)),
                  ),
                ),
              if (ordinalsAllowed)
                ActionChip(
                  key: const ValueKey('recur-ordinal-add'),
                  avatar: const Icon(Icons.add),
                  label: Text(l.recurAddOrdinal),
                  onPressed: () => _addOrdinal(format, weekStart),
                ),
            ],
          ),
        ),
      if (calendarFreq) _monthDaysSection(context, preview),
      if (freq == Frequency.yearly) _monthsSection(context, format),
      if (!freq.isSubDaily && !_anchor.allDay)
        RecurrenceSection(
          title: l.recurTimes,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TimeListEditor(
                times: _rule.times,
                format: format,
                use24h: use24h,
                initialNewTime: _anchor.start.time,
                onChanged: (t) => _set(_rule.copyWith(times: t, byHour: const [], byMinute: const [])),
              ),
              if (_rule.times.isEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: Space.xs),
                  child: Text(
                    l.recurTimesDefault(format.time(_anchor.start.time)),
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ),
              ..._issues(context, preview, const {'times'}),
            ],
          ),
        ),
      if (freq.isSubDaily)
        RecurrenceSection(
          title: l.recurWindow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                key: const ValueKey('recur-window-switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(window == null ? l.recurWindowNone : l.recurWindow),
                value: window != null,
                onChanged: (on) => _set(_rule.copyWith(window: on ? PresetParams.defaultWindow : null)),
              ),
              if (window != null) ...[
                _WindowTimes(
                  window: window,
                  format: format,
                  use24h: use24h,
                  onChanged: (w) => _set(_rule.copyWith(window: w)),
                ),
                RadioGroup<WindowAnchor>(
                  groupValue: window.anchor,
                  onChanged: (a) {
                    if (a != null) _set(_rule.copyWith(window: window.copyWith(anchor: a)));
                  },
                  child: Column(
                    children: [
                      RadioListTile<WindowAnchor>(
                        key: const ValueKey('recur-window-anchor-window'),
                        contentPadding: EdgeInsets.zero,
                        value: WindowAnchor.windowStart,
                        title: Text(l.recurWindowAnchorWindow),
                      ),
                      RadioListTile<WindowAnchor>(
                        key: const ValueKey('recur-window-anchor-series'),
                        contentPadding: EdgeInsets.zero,
                        value: WindowAnchor.seriesStart,
                        title: Text(l.recurWindowAnchorSeries),
                      ),
                    ],
                  ),
                ),
              ],
              ..._issues(context, preview, const {'window'}),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, Space.sm, Space.sm, 0),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('recur-more'),
            onPressed: () => setState(() => _more = !_more),
            icon: Icon(_more ? Icons.expand_less : Icons.expand_more),
            label: Text(_more ? l.recurLess : l.recurMore),
          ),
        ),
      ),
      if (_more) ..._moreSections(context, format, preview),
    ];
  }

  Widget _monthDaysSection(BuildContext context, RecurrencePreview preview) {
    final l = context.l10n;
    final selected = _rule.byMonthDay.toSet();
    return RecurrenceSection(
      title: l.recurMonthDays,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            key: const ValueKey('recur-monthdays-from-end'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.recurMonthDaysFromEnd),
            value: _fromEnd,
            onChanged: (v) => setState(() => _fromEnd = v),
          ),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (var d = 1; d <= 31; d++)
                _ToggleCell(
                  key: ValueKey('recur-monthday-${_fromEnd ? -d : d}'),
                  label: _fromEnd ? '−$d' : '$d',
                  semanticsLabel: _fromEnd ? l.recurMonthDayFromEnd(d) : '$d',
                  selected: selected.contains(_fromEnd ? -d : d),
                  onTap: () => _set(_rule.copyWith(byMonthDay: _toggled(_rule.byMonthDay, _fromEnd ? -d : d))),
                ),
            ],
          ),
          ..._issues(context, preview, const {'byMonthDay'}),
        ],
      ),
    );
  }

  Widget _monthsSection(BuildContext context, AppFormat format) {
    final l = context.l10n;
    final names = DateFormat.MMM(format.locale);
    return RecurrenceSection(
      title: l.recurMonths,
      child: Wrap(
        spacing: Space.xs,
        runSpacing: Space.xs,
        children: [
          for (var m = 1; m <= 12; m++)
            FilterChip(
              key: ValueKey('recur-month-$m'),
              label: Text(names.format(DateTime.utc(2024, m))),
              selected: _rule.byMonth.contains(m),
              showCheckmark: false,
              onSelected: (_) => _set(_rule.copyWith(byMonth: _toggled(_rule.byMonth, m))),
            ),
        ],
      ),
    );
  }

  List<Widget> _moreSections(BuildContext context, AppFormat format, RecurrencePreview preview) {
    final l = context.l10n;
    final freq = _rule.freq;
    final calendarFreq = freq == Frequency.monthly || freq == Frequency.yearly;
    Widget intChips(
      List<int> selected,
      List<int> quick,
      String Function(int) label,
      ValueChanged<List<int>> onChanged, {
      required String keyPrefix,
      required String promptTitle,
      int? min,
      int? max,
    }) {
      final values = {...quick, ...selected}.toList()
        ..sort((a, b) => a.abs() == b.abs() ? a.compareTo(b) : a.abs().compareTo(b.abs()));
      return Wrap(
        spacing: Space.xs,
        runSpacing: Space.xs,
        children: [
          for (final v in values)
            FilterChip(
              key: ValueKey('$keyPrefix-$v'),
              label: Text(label(v)),
              selected: selected.contains(v),
              showCheckmark: false,
              onSelected: (_) => onChanged(_toggled(selected, v)),
            ),
          ActionChip(
            key: ValueKey('$keyPrefix-other'),
            avatar: const Icon(Icons.add),
            label: Text(l.recurCustomValue),
            onPressed: () async {
              final v = await _promptInt(promptTitle, min: min, max: max);
              if (v != null && !selected.contains(v)) onChanged(([...selected, v]..sort()));
            },
          ),
        ],
      );
    }

    return [
      RecurrenceSection(
        title: l.recurSetPos,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.recurSetPosHint, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
            const SizedBox(height: Space.xs),
            intChips(
              _rule.bySetPos,
              recurCommonOrdinals,
              l.recurOrdinalLabel,
              (v) => _set(_rule.copyWith(bySetPos: v)),
              keyPrefix: 'recur-setpos',
              promptTitle: l.recurSetPos,
              min: -366,
              max: 366,
            ),
            ..._issues(context, preview, const {'bySetPos'}),
          ],
        ),
      ),
      if (!_anchor.allDay) ...[
        RecurrenceSection(
          title: l.recurHours,
          child: Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (var h = 0; h < 24; h++)
                FilterChip(
                  key: ValueKey('recur-hour-$h'),
                  label: Text(format.time(LocalTime(h, 0))),
                  selected: _rule.byHour.contains(h),
                  showCheckmark: false,
                  onSelected: (_) => _set(_rule.copyWith(byHour: _toggled(_rule.byHour, h), times: const [])),
                ),
            ],
          ),
        ),
        RecurrenceSection(
          title: l.recurMinutes,
          child: intChips(
            _rule.byMinute,
            const [0, 15, 30, 45],
            (m) => ':${'$m'.padLeft(2, '0')}',
            (v) => _set(_rule.copyWith(byMinute: v, times: const [])),
            keyPrefix: 'recur-minute',
            promptTitle: l.recurMinutes,
            min: 0,
            max: 59,
          ),
        ),
      ],
      if (!calendarFreq && freq != Frequency.weekly) _monthDaysSection(context, preview),
      if (freq != Frequency.yearly) _monthsSection(context, format),
      if (freq == Frequency.yearly) ...[
        RecurrenceSection(
          title: l.recurYearDays,
          child: _IntListField(
            key: const ValueKey('recur-yeardays'),
            values: _rule.byYearDay,
            hint: l.recurNumbersHint,
            onChanged: (v) => _set(_rule.copyWith(byYearDay: v)),
          ),
        ),
        RecurrenceSection(
          title: l.recurWeekNumbers,
          child: _IntListField(
            key: const ValueKey('recur-weeknos'),
            values: _rule.byWeekNo,
            hint: l.recurNumbersHint,
            onChanged: (v) => _set(_withFreqGuard(_rule.copyWith(byWeekNo: v))),
          ),
        ),
      ],
      RecurrenceSection(
        title: l.recurWeekStart,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: DropdownButton<Weekday>(
            key: const ValueKey('recur-wkst'),
            value: _rule.wkst,
            onChanged: (d) {
              if (d != null) _set(_rule.copyWith(wkst: d));
            },
            items: [for (final d in Weekday.values) DropdownMenuItem(value: d, child: Text(format.weekdayLong(d)))],
          ),
        ),
      ),
      if (calendarFreq || _rule.byMonthDay.isNotEmpty)
        RecurrenceSection(
          title: l.recurOverflow,
          child: RadioGroup<MonthOverflow>(
            groupValue: _rule.monthDayOverflow,
            onChanged: (v) {
              if (v != null) _set(_rule.copyWith(monthDayOverflow: v));
            },
            child: Column(
              children: [
                RadioListTile<MonthOverflow>(
                  key: const ValueKey('recur-overflow-skip'),
                  contentPadding: EdgeInsets.zero,
                  value: MonthOverflow.skip,
                  title: Text(l.recurOverflowSkip),
                ),
                RadioListTile<MonthOverflow>(
                  key: const ValueKey('recur-overflow-clamp'),
                  contentPadding: EdgeInsets.zero,
                  value: MonthOverflow.clamp,
                  title: Text(l.recurOverflowClamp),
                ),
              ],
            ),
          ),
        ),
      ..._issues(context, preview, const {'byYearDay', 'byWeekNo', 'byHour', 'byMinute', 'byMonth'}).map(
        (w) => Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: w,
        ),
      ),
    ];
  }

  /// Week numbers disable weekday ordinals (RFC 5545); strip them when week numbers are set.
  RecurrenceRule _withFreqGuard(RecurrenceRule r) {
    if (r.byWeekNo.isEmpty) return r;
    final weekdays = r.byWeekday;
    if (weekdays == null || weekdays.every((w) => w.n == null)) return r;
    final plain = {for (final w in weekdays) w.day};
    return r.copyWith(
      byWeekday: [
        for (final d in Weekday.values)
          if (plain.contains(d)) WeekdayRule(d),
      ],
    );
  }

  List<Widget> _afterSections(BuildContext context) {
    final l = context.l10n;
    final after = _rule.afterCompletion ?? const AfterCompletion(1, RecurrenceUnit.day);
    return [
      RecurrenceSection(
        title: l.recurTypeAfter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.xs,
              children: [
                NumberStepper(
                  fieldKey: const ValueKey('recur-after-amount'),
                  value: after.amount,
                  max: 9999,
                  label: l.recurTypeAfter,
                  onChanged: (v) => _set(_rule.copyWith(afterCompletion: AfterCompletion(v, after.unit))),
                ),
                DropdownButton<RecurrenceUnit>(
                  key: const ValueKey('recur-after-unit'),
                  value: after.unit,
                  onChanged: (u) {
                    if (u != null) _set(_rule.copyWith(afterCompletion: AfterCompletion(after.amount, u)));
                  },
                  items: [
                    for (final u in RecurrenceUnit.values)
                      if (!_anchor.allDay || u.isDayBased || u == after.unit)
                        DropdownMenuItem(value: u, child: Text(l.recurDelayUnit(u))),
                  ],
                ),
              ],
            ),
            Text(l.recurAfterHint, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ),
    ];
  }

  List<Widget> _quotaSections(BuildContext context, AppFormat format, Weekday weekStart, RecurrencePreview preview) {
    final l = context.l10n;
    final quota = _rule.quota ?? const Quota(3, PeriodUnit.week);
    void setQuota(Quota q) => _set(_rule.copyWith(quota: q));
    final days = _rule.byWeekday == null ? Weekday.values.toSet() : {for (final w in _rule.byWeekday!) w.day};
    return [
      RecurrenceSection(
        title: l.recurQuotaTimes,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: NumberStepper(
            fieldKey: const ValueKey('recur-quota-times'),
            value: quota.times,
            max: 999,
            label: l.recurQuotaTimes,
            onChanged: (v) => setQuota(Quota(v, quota.per, minGapDays: quota.minGapDays)),
          ),
        ),
      ),
      RecurrenceSection(
        title: l.recurQuotaPer,
        child: Wrap(
          spacing: Space.sm,
          runSpacing: Space.xs,
          children: [
            for (final p in PeriodUnit.values)
              ChoiceChip(
                key: ValueKey('recur-quota-per-${p.name}'),
                label: Text(l.recurPeriodUnit(p)),
                selected: quota.per == p,
                onSelected: (_) => setQuota(Quota(quota.times, p, minGapDays: quota.minGapDays)),
              ),
          ],
        ),
      ),
      RecurrenceSection(
        title: l.recurQuotaMinGap,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: NumberStepper(
            fieldKey: const ValueKey('recur-quota-gap'),
            value: quota.minGapDays,
            min: 0,
            max: 366,
            label: l.recurQuotaMinGap,
            onChanged: (v) => setQuota(Quota(quota.times, quota.per, minGapDays: v)),
          ),
        ),
      ),
      RecurrenceSection(
        title: l.recurQuotaOnDays,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            WeekdayChips(
              keyPrefix: 'recur-quota-day',
              selected: days,
              weekStart: weekStart,
              format: format,
              onChanged: (d) => _set(
                _rule.copyWith(
                  byWeekday: d.length == 7
                      ? null
                      : [
                          for (final w in Weekday.values)
                            if (d.contains(w)) WeekdayRule(w),
                        ],
                ),
              ),
            ),
            ..._issues(context, preview, const {'quota', 'byWeekday'}),
          ],
        ),
      ),
    ];
  }

  List<Widget> _exceptionSections(BuildContext context, AppFormat format, RecurrencePreview preview) {
    final l = context.l10n;
    String label(String key) {
      final dt = LocalDateTime.tryParse(key);
      if (dt != null) return format.dateTime(dt);
      final d = LocalDate.tryParse(key);
      return d == null ? key : format.dateMedium(d);
    }

    Widget list(
      String kind,
      List<String> values,
      ValueChanged<List<String>> onChanged,
      Future<String?> Function() add,
    ) => Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final v in values)
          InputChip(
            key: ValueKey('recur-$kind-$v'),
            label: Text(label(v)),
            onDeleted: () => onChanged([...values.where((x) => x != v)]),
            deleteButtonTooltipMessage: l.recurRemove(label(v)),
          ),
        ActionChip(
          key: ValueKey('recur-$kind-add'),
          avatar: const Icon(Icons.add),
          label: Text(l.recurAddDate),
          onPressed: () async {
            final key = await add();
            if (!mounted || key == null || values.contains(key)) return;
            onChanged(([...values, key]..sort()));
          },
        ),
      ],
    );

    final prefs = ref.read(userPreferencesProvider);
    return [
      RecurrenceSection(
        title: l.recurExdates,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            list('exdate', _rule.exdates, (v) => _set(_rule.copyWith(exdates: v)), () async {
              final date = await pickDate(context, initial: _anchor.start.date, first: _anchor.start.date);
              return date?.toIso();
            }),
            ..._issues(context, preview, const {'exdates'}),
          ],
        ),
      ),
      RecurrenceSection(
        title: l.recurRdates,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            list('rdate', _rule.rdates, (v) => _set(_rule.copyWith(rdates: v)), () async {
              final date = await pickDate(context, initial: _anchor.start.date);
              if (date == null || !mounted) return null;
              if (_anchor.allDay) return date.toIso();
              final time = await pickTime(context, initial: _anchor.start.time, use24h: prefs.use24h);
              return time == null ? null : date.atTime(time).toIso();
            }),
            ..._issues(context, preview, const {'rdates'}),
          ],
        ),
      ),
    ];
  }
}

/// Window start/end tiles (an end picked at 00:00 means midnight, `24:00`).
class _WindowTimes extends StatelessWidget {
  const _WindowTimes({required this.window, required this.format, required this.use24h, required this.onChanged});

  final DailyWindow window;
  final AppFormat format;
  final bool use24h;
  final ValueChanged<DailyWindow> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          key: const ValueKey('recur-window-start'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.recurWindowStart),
          trailing: Text(format.time(window.start), style: context.text.titleMedium),
          onTap: () async {
            final t = await pickTime(context, initial: window.start, use24h: use24h);
            if (t != null) onChanged(window.copyWith(start: t));
          },
        ),
        ListTile(
          key: const ValueKey('recur-window-end'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.recurWindowEnd),
          trailing: Text(format.time(window.end), style: context.text.titleMedium),
          onTap: () async {
            final t = await pickTime(
              context,
              initial: window.end.isEndOfDay ? LocalTime.midnight : window.end,
              use24h: use24h,
            );
            if (t != null) onChanged(window.copyWith(end: t == LocalTime.midnight ? LocalTime.endOfDay : t));
          },
        ),
      ],
    );
  }
}

/// 48 dp round toggle (month-day grid).
class _ToggleCell extends StatelessWidget {
  const _ToggleCell({
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: semanticsLabel,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? context.colors.primary : null,
          border: Border.all(color: selected ? context.colors.primary : context.colors.outlineVariant),
        ),
        child: Text(label, style: context.text.labelLarge?.copyWith(color: selected ? context.colors.onPrimary : null)),
      ),
    ),
  );
}

/// Comma-separated integers (year days, week numbers); invalid entries are ignored.
class _IntListField extends StatefulWidget {
  const _IntListField({required this.values, required this.onChanged, required this.hint, super.key});

  final List<int> values;
  final ValueChanged<List<int>> onChanged;
  final String hint;

  @override
  State<_IntListField> createState() => _IntListFieldState();
}

class _IntListFieldState extends State<_IntListField> {
  late final TextEditingController _controller = TextEditingController(text: widget.values.join(', '));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    keyboardType: const TextInputType.numberWithOptions(signed: true),
    decoration: InputDecoration(hintText: widget.hint, isDense: true),
    onChanged: (text) {
      final values = <int>{
        for (final part in text.replaceAll('−', '-').split(RegExp(r'[,;\s]+')))
          if (int.tryParse(part) case final v?) v,
      }.toList()..sort();
      widget.onChanged(values);
    },
  );
}

/// Picks one "Nth weekday" entry (1st … 5th, last, 2nd to last × weekday).
class _OrdinalDialog extends StatefulWidget {
  const _OrdinalDialog({required this.format, required this.weekStart, required this.initialDay});

  final AppFormat format;
  final Weekday weekStart;
  final Weekday initialDay;

  @override
  State<_OrdinalDialog> createState() => _OrdinalDialogState();
}

class _OrdinalDialogState extends State<_OrdinalDialog> {
  int _n = 1;
  late Weekday _day = widget.initialDay;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.recurOrdinalPick),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final n in recurCommonOrdinals)
                  ChoiceChip(
                    key: ValueKey('recur-ordinal-n-$n'),
                    label: Text(l.recurOrdinalLabel(n)),
                    selected: _n == n,
                    onSelected: (_) => setState(() => _n = n),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final d in Weekday.ordered(widget.weekStart))
                  ChoiceChip(
                    key: ValueKey('recur-ordinal-day-${d.code}'),
                    label: Text(widget.format.weekdayShort(d), semanticsLabel: widget.format.weekdayLong(d)),
                    selected: _day == d,
                    onSelected: (_) => setState(() => _day = d),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel)),
        FilledButton(
          key: const ValueKey('recur-ordinal-ok'),
          onPressed: () => Navigator.pop(context, WeekdayRule(_day, _n)),
          child: Text(l.actionAdd),
        ),
      ],
    );
  }
}
