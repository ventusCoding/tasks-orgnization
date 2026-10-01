import 'dart:async';

import 'package:everslot/core/preferences/user_preferences.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/components/dialogs.dart';
import 'package:everslot/design_system/formatting.dart';
import 'package:everslot/design_system/icon_catalog.dart';
import 'package:everslot/design_system/l10n_x.dart';
import 'package:everslot/design_system/pickers/time_input.dart';
import 'package:everslot/design_system/tokens.dart';
import 'package:everslot/design_system/typography.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

export 'time_input.dart';

/// Pickers (T1.3.11). Each one is a bottom sheet built on the design-system tokens, honours the
/// user's week start and 12/24 h preference, and is usable with a screen reader (every wheel has a
/// keyboard/text alternative, every cell a semantics label).

/// The user's preferences when the picker runs under a ProviderScope, defaults otherwise.
UserPreferences _prefs(BuildContext context) {
  try {
    return ProviderScope.containerOf(context, listen: false).read(userPreferencesProvider);
  } on Object {
    return UserPreferences.defaults;
  }
}

/// Today in the device zone (from the injected clock when available).
LocalDate _today(BuildContext context) {
  DateTime now;
  try {
    now = ProviderScope.containerOf(context, listen: false).read(clockProvider).nowUtc().toLocal();
  } on Object {
    now = DateTime.now(); // no ProviderScope (isolated widget tests)
  }
  return LocalDate(now.year, now.month, now.day);
}

AppFormat _format(BuildContext context, UserPreferences prefs) =>
    AppFormat(context.localeName, use24h: prefs.use24h, l10n: context.l10n, arabicDigits: prefs.useArabicDigits);

// ------------------------------------------------------------------------------------- date --

/// Date picker: quick chips (today / tomorrow / next week) above a month grid that starts on the
/// user's week start ([weekStart] overrides it). Tapping a day returns it.
Future<LocalDate?> pickDate(
  BuildContext context, {
  LocalDate? initial,
  LocalDate? first,
  LocalDate? last,
  Weekday? weekStart,
}) {
  final prefs = _prefs(context);
  final today = _today(context);
  return showAppSheet<LocalDate>(
    context,
    title: context.l10n.pickerDate,
    builder: (ctx) => DatePickerPanel(
      initial: initial ?? today,
      today: today,
      weekStart: weekStart ?? prefs.weekStart,
      first: first ?? LocalDate(2000, 1, 1),
      last: last ?? LocalDate(2100, 12, 31),
      format: _format(ctx, prefs),
      onSelected: (d) => Navigator.pop(ctx, d),
    ),
  );
}

/// The date picker's content (also usable inline).
class DatePickerPanel extends StatefulWidget {
  const DatePickerPanel({
    required this.initial,
    required this.today,
    required this.weekStart,
    required this.first,
    required this.last,
    required this.format,
    required this.onSelected,
    super.key,
  });

  final LocalDate initial;
  final LocalDate today;
  final Weekday weekStart;
  final LocalDate first;
  final LocalDate last;
  final AppFormat format;
  final ValueChanged<LocalDate> onSelected;

  @override
  State<DatePickerPanel> createState() => _DatePickerPanelState();
}

class _DatePickerPanelState extends State<DatePickerPanel> {
  late LocalDate _month = LocalDate(widget.initial.year, widget.initial.month, 1);

  bool _inRange(LocalDate d) => !d.isBefore(widget.first) && !d.isAfter(widget.last);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = widget.format;
    final today = widget.today;
    final quick = <(String, LocalDate)>[
      (l.actionToday, today),
      (l.pickerTomorrow, today.plusDays(1)),
      (l.pickerNextWeek, today.startOfWeek(widget.weekStart).plusDays(7)),
    ];
    final gridStart = _month.startOfWeek(widget.weekStart);
    final weekdays = [for (var i = 0; i < 7; i++) gridStart.plusDays(i).weekday];
    final prevOk = !_month.plusDays(-1).isBefore(widget.first);
    final nextOk = !_month.plusMonths(1).isAfter(widget.last);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: Space.sm,
            children: [
              for (final (label, date) in quick)
                ActionChip(
                  key: ValueKey('date-quick-${date.toIso()}'),
                  label: Text(label),
                  onPressed: _inRange(date) ? () => widget.onSelected(date) : null,
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              IconButton(
                tooltip: l.pickerPreviousMonth,
                onPressed: prevOk ? () => setState(() => _month = _month.plusMonths(-1)) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(f.monthYear(_month), textAlign: TextAlign.center, style: context.text.titleMedium),
              ),
              IconButton(
                tooltip: l.pickerNextMonth,
                onPressed: nextOk ? () => setState(() => _month = _month.plusMonths(1)) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      f.weekdayShort(w),
                      textAlign: TextAlign.center,
                      style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                ),
            ],
          ),
          for (var week = 0; week < 6; week++)
            Row(
              children: [
                for (var i = 0; i < 7; i++) Expanded(child: _dayCell(context, gridStart.plusDays(week * 7 + i))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dayCell(BuildContext context, LocalDate d) {
    final inMonth = d.month == _month.month;
    final selected = d == widget.initial;
    final isToday = d == widget.today;
    final enabled = _inRange(d);
    final colors = context.colors;
    final fg = selected
        ? colors.onPrimary
        : !enabled
        ? colors.onSurface.withValues(alpha: Opacities.disabled)
        : inMonth
        ? colors.onSurface
        : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: widget.format.dayLong(d),
      excludeSemantics: true,
      child: InkResponse(
        key: ValueKey('date-${d.toIso()}'),
        onTap: enabled ? () => widget.onSelected(d) : null,
        radius: 24,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? colors.primary : null,
                border: isToday && !selected ? Border.all(color: colors.primary) : null,
              ),
              child: Text(
                widget.format.number(d.day),
                style: AppTypography.tabular(context.text.bodyMedium)?.copyWith(color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------- time --

/// Time picker with 1-minute precision: wheels plus a text field that accepts typed times
/// ("07:03", "703", "7:03 pm"). [use24h] defaults to the user's preference.
Future<LocalTime?> pickTime(BuildContext context, {LocalTime? initial, bool? use24h}) {
  final prefs = _prefs(context);
  return showAppSheet<LocalTime>(
    context,
    title: context.l10n.pickerTime,
    builder: (ctx) => _TimePickerSheet(initial: initial ?? LocalTime(9, 0), use24h: use24h ?? prefs.use24h),
  );
}

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({required this.initial, required this.use24h});

  final LocalTime initial;
  final bool use24h;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late LocalTime _value = widget.initial;
  late final _field = TextEditingController(text: _text(widget.initial));
  bool _invalid = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  String _text(LocalTime t) {
    final m = MaterialLocalizations.of(context);
    return formatTimeInput(t, use24h: widget.use24h, am: m.anteMeridiemAbbreviation, pm: m.postMeridiemAbbreviation);
  }

  void _typed(String text) {
    final t = parseTimeInput(text);
    setState(() {
      _invalid = t == null && text.trim().isNotEmpty;
      if (t != null) _value = t;
    });
  }

  void _wheel(LocalTime t) {
    setState(() {
      _value = t;
      _invalid = false;
    });
    _field.text = _text(t);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('time-input'),
            controller: _field,
            keyboardType: TextInputType.datetime,
            textDirection: TextDirection.ltr,
            style: AppTypography.tabular(context.text.titleLarge),
            decoration: InputDecoration(
              labelText: l.pickerTypeTime,
              errorText: _invalid ? l.pickerTimeInvalid : null,
              prefixIcon: const Icon(Icons.schedule),
            ),
            onChanged: _typed,
            onSubmitted: (_) {
              if (!_invalid) Navigator.pop(context, _value);
            },
          ),
          const SizedBox(height: Space.md),
          // Wheels are a visual shortcut; screen readers use the field above.
          ExcludeSemantics(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TimeWheels(value: _value, use24h: widget.use24h, onChanged: _wheel),
            ),
          ),
          const SizedBox(height: Space.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('time-apply'),
              onPressed: _invalid ? null : () => Navigator.pop(context, _value),
              child: Text(l.actionApply),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hour / minute (/ AM-PM) wheels with 1-minute steps; follows external [value] changes.
class TimeWheels extends StatefulWidget {
  const TimeWheels({required this.value, required this.use24h, required this.onChanged, super.key});

  final LocalTime value;
  final bool use24h;
  final ValueChanged<LocalTime> onChanged;

  @override
  State<TimeWheels> createState() => _TimeWheelsState();
}

class _TimeWheelsState extends State<TimeWheels> {
  late final _hours = FixedExtentScrollController(initialItem: _hourIndex(widget.value));
  late final _minutes = FixedExtentScrollController(initialItem: widget.value.minute);
  late final _period = FixedExtentScrollController(initialItem: widget.value.hour < 12 ? 0 : 1);

  int _hourIndex(LocalTime t) => widget.use24h ? t.hour : (t.hour % 12 == 0 ? 11 : t.hour % 12 - 1);

  /// True while the wheels follow an external value (their notifications are not user input).
  bool _syncing = false;

  @override
  void didUpdateWidget(TimeWheels oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    // Jumping notifies listeners: do it after this frame, and don't echo it back.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void sync(FixedExtentScrollController c, int item) {
        if (c.hasClients && c.selectedItem != item) c.jumpToItem(item);
      }

      _syncing = true;
      sync(_hours, _hourIndex(widget.value));
      sync(_minutes, widget.value.minute);
      sync(_period, widget.value.hour < 12 ? 0 : 1);
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _period.dispose();
    super.dispose();
  }

  void _emit() {
    if (_syncing) return;
    final hi = _hours.selectedItem;
    final minute = _minutes.selectedItem;
    final int hour;
    if (widget.use24h) {
      hour = hi;
    } else {
      final h12 = hi + 1; // 1…12
      final pm = _period.selectedItem == 1;
      hour = h12 % 12 + (pm ? 12 : 0);
    }
    final t = LocalTime(hour, minute);
    if (t != widget.value) widget.onChanged(t);
  }

  Widget _wheel(FixedExtentScrollController c, int count, String Function(int) label, Key key) => SizedBox(
    width: 72,
    height: 160,
    child: ListWheelScrollView.useDelegate(
      key: key,
      controller: c,
      itemExtent: 40,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.004,
      onSelectedItemChanged: (_) => _emit(),
      childDelegate: ListWheelChildLoopingListDelegate(
        children: [
          for (var i = 0; i < count; i++)
            Center(child: Text(label(i), style: AppTypography.tabular(context.text.titleLarge))),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final m = MaterialLocalizations.of(context);
    String two(int v) => v.toString().padLeft(2, '0');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _wheel(
          _hours,
          widget.use24h ? 24 : 12,
          (i) => widget.use24h ? two(i) : '${i + 1}',
          const ValueKey('wheel-hours'),
        ),
        Text(':', style: context.text.titleLarge),
        _wheel(_minutes, 60, two, const ValueKey('wheel-minutes')),
        if (!widget.use24h)
          SizedBox(
            width: 72,
            height: 160,
            child: ListWheelScrollView(
              key: const ValueKey('wheel-period'),
              controller: _period,
              itemExtent: 40,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (_) => _emit(),
              children: [
                for (final p in [m.anteMeridiemAbbreviation, m.postMeridiemAbbreviation])
                  Center(child: Text(p, style: context.text.titleMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

// --------------------------------------------------------------------------------- duration --

/// Duration picker (1 minute … 365 days) with quick presets, labelled per locale. Returns minutes.
Future<int?> pickDuration(BuildContext context, {int initialMinutes = 30, int maxMinutes = 525600}) {
  final prefs = _prefs(context);
  return showAppSheet<int>(
    context,
    title: context.l10n.pickerDuration,
    builder: (ctx) => _DurationPicker(initial: initialMinutes, max: maxMinutes, format: _format(ctx, prefs)),
  );
}

class _DurationPicker extends StatefulWidget {
  const _DurationPicker({required this.initial, required this.max, required this.format});

  final int initial;
  final int max;
  final AppFormat format;

  @override
  State<_DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<_DurationPicker> {
  late int _days = widget.initial ~/ 1440;
  late int _hours = (widget.initial % 1440) ~/ 60;
  late int _minutes = widget.initial % 60;

  int get _total => (_days * 1440 + _hours * 60 + _minutes).clamp(1, widget.max);

  static const presets = [5, 15, 30, 45, 60, 90, 120, 180, 240, 480, 1440];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget stepper(String label, int value, int max, ValueChanged<int> onChanged) => Column(
      children: [
        Text(label, style: context.text.labelMedium),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '$label −1',
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 40,
              child: Text(
                widget.format.number(value),
                textAlign: TextAlign.center,
                style: AppTypography.tabular(context.text.titleLarge),
              ),
            ),
            IconButton(
              tooltip: '$label +1',
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        children: [
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final p in presets)
                if (p <= widget.max)
                  ChoiceChip(
                    key: ValueKey('duration-$p'),
                    label: Text(widget.format.duration(p)),
                    selected: _total == p,
                    onSelected: (_) => setState(() {
                      _days = p ~/ 1440;
                      _hours = (p % 1440) ~/ 60;
                      _minutes = p % 60;
                    }),
                  ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: Space.md,
            children: [
              stepper(l.pickerDays, _days, widget.max ~/ 1440, (v) => setState(() => _days = v)),
              stepper(l.pickerHours, _hours, 23, (v) => setState(() => _hours = v)),
              stepper(l.pickerMinutes, _minutes, 59, (v) => setState(() => _minutes = v)),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(widget.format.duration(_total), style: context.text.titleMedium),
          const SizedBox(height: Space.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('duration-apply'),
              onPressed: () => Navigator.pop(context, _total),
              child: Text(l.actionApply),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------------- time range --

/// Start + duration of a time range (minutes, 1…1440; an end before the start crosses midnight).
typedef TimeRangeValue = ({LocalTime start, int minutes});

/// Time-range picker: start and end (or start and a duration preset).
Future<TimeRangeValue?> pickTimeRange(
  BuildContext context, {
  required LocalTime start,
  required int minutes,
  bool? use24h,
}) {
  final prefs = _prefs(context);
  return showAppSheet<TimeRangeValue>(
    context,
    title: context.l10n.pickerTimeRange,
    builder: (ctx) => _TimeRangePicker(
      start: start,
      minutes: minutes.clamp(1, 1440),
      format: _format(ctx, use24h == null ? prefs : prefs.copyWith(use24h: use24h)),
      use24h: use24h ?? prefs.use24h,
    ),
  );
}

class _TimeRangePicker extends StatefulWidget {
  const _TimeRangePicker({required this.start, required this.minutes, required this.format, required this.use24h});

  final LocalTime start;
  final int minutes;
  final AppFormat format;
  final bool use24h;

  @override
  State<_TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<_TimeRangePicker> {
  late LocalTime _start = widget.start;
  late int _minutes = widget.minutes;

  LocalTime get _end => LocalTime.fromMinuteOfDay((_start.minuteOfDay + _minutes) % 1440);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = widget.format;
    Widget row(String key, String label, LocalTime value, ValueChanged<LocalTime> onPicked) => ListTile(
      key: ValueKey(key),
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(f.time(value), style: AppTypography.tabular(context.text.titleMedium)),
      onTap: () async {
        final t = await pickTime(context, initial: value, use24h: widget.use24h);
        if (t != null) onPicked(t);
      },
    );
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row('range-start', l.pickerStart, _start, (t) => setState(() => _start = t)),
          row('range-end', l.pickerEnd, _end, (t) {
            final diff = (t.minuteOfDay - _start.minuteOfDay) % 1440;
            setState(() => _minutes = diff == 0 ? 1440 : diff);
          }),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final p in _DurationPickerState.presets.where((p) => p <= 1440))
                ChoiceChip(
                  label: Text(f.duration(p)),
                  selected: _minutes == p,
                  onSelected: (_) => setState(() => _minutes = p),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(f.duration(_minutes), style: context.text.titleMedium),
          const SizedBox(height: Space.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('range-apply'),
              onPressed: () => Navigator.pop<TimeRangeValue>(context, (start: _start, minutes: _minutes)),
              child: Text(l.actionApply),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------------------ color --

/// Parses "#3B82F6" / "3b82f6" into an opaque ARGB int.
int? parseHexColor(String input) {
  final hex = input.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return 0xFF000000 | int.parse(hex, radix: 16);
}

/// Color picker: the category palette, optionally "no color", and a custom hex color with a
/// contrast warning (below 3:1 against the surface). Returns the ARGB int (-1 = no color).
Future<int?> pickColor(BuildContext context, {int? selected, bool allowNone = false}) => showAppSheet<int>(
  context,
  title: context.l10n.pickerColor,
  builder: (ctx) => _ColorPicker(selected: selected, allowNone: allowNone),
);

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({required this.selected, required this.allowNone});

  final int? selected;
  final bool allowNone;

  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late final _hex = TextEditingController(
    text: widget.selected == null || CategoryPalette.colors.contains(widget.selected)
        ? ''
        : (widget.selected! & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase(),
  );

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final custom = parseHexColor(_hex.text);
    final lowContrast = custom != null && CategoryColors.contrastRatio(Color(custom), context.colors.surface) < 3;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.md,
            runSpacing: Space.md,
            children: [
              if (widget.allowNone)
                _Swatch(
                  color: context.colors.surfaceContainerHighest,
                  selected: widget.selected == null,
                  label: l.pickerNoColor,
                  onTap: () => Navigator.pop(context, -1),
                  icon: Icons.block,
                ),
              for (final c in CategoryPalette.colors)
                _Swatch(
                  color: Color(c),
                  selected: widget.selected == c,
                  label: '#${c.toRadixString(16).substring(2).toUpperCase()}',
                  onTap: () => Navigator.pop(context, c),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Text(l.pickerCustomColor, style: context.text.titleSmall),
          const SizedBox(height: Space.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('color-hex'),
                  controller: _hex,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                  decoration: InputDecoration(
                    labelText: l.pickerHex,
                    prefixText: '#',
                    errorText: _hex.text.isNotEmpty && custom == null ? l.pickerHexInvalid : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: Space.md),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: custom == null ? null : Color(custom),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.outlineVariant),
                ),
              ),
            ],
          ),
          if (lowContrast) ...[
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Icon(Icons.warning_amber, color: context.appColors.warning, size: 18),
                const SizedBox(width: Space.xs),
                Expanded(child: Text(l.pickerLowContrast, key: const ValueKey('color-low-contrast'))),
              ],
            ),
          ],
          const SizedBox(height: Space.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('color-apply'),
              onPressed: custom == null ? null : () => Navigator.pop(context, custom),
              child: Text(l.actionApply),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.label, required this.onTap, this.icon});

  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? context.colors.onSurface : Colors.transparent, width: 3),
        ),
        child: selected
            ? Icon(Icons.check, color: CategoryColors.onBackground(color))
            : (icon == null ? null : Icon(icon, size: 18)),
      ),
    ),
  );
}

// ------------------------------------------------------------------------------------- icon --

/// Icon picker with search (EN/FR/AR keywords). Returns the icon key.
Future<String?> pickIcon(BuildContext context, {String? selected}) => showAppSheet<String>(
  context,
  title: context.l10n.pickerIcon,
  builder: (ctx) => _IconPicker(selected: selected),
);

class _IconPicker extends StatefulWidget {
  const _IconPicker({this.selected});

  final String? selected;

  @override
  State<_IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<_IconPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final icons = IconCatalog.search(_query);
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.l10n.pickerSearchIcons),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: Space.md),
          Flexible(
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 6,
              children: [
                for (final i in icons)
                  IconButton(
                    tooltip: i.key,
                    isSelected: i.key == widget.selected,
                    onPressed: () => Navigator.pop(context, i.key),
                    icon: Icon(i.icon),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
