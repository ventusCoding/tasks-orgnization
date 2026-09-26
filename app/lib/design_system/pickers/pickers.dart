import 'package:everslot/design_system/components/dialogs.dart';
import 'package:everslot/design_system/icon_catalog.dart';
import 'package:everslot/design_system/l10n_x.dart';
import 'package:everslot/design_system/tokens.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:material_ui/material_ui.dart';

/// Date picker returning a [LocalDate] (T1.3.11).
Future<LocalDate?> pickDate(
  BuildContext context, {
  LocalDate? initial,
  LocalDate? first,
  LocalDate? last,
}) async {
  final now = DateTime.now();
  final init = initial?.toDateTimeUtc() ?? DateTime(now.year, now.month, now.day);
  final result = await showDatePicker(
    context: context,
    initialDate: DateTime(init.year, init.month, init.day),
    firstDate: first?.toDateTimeUtc() ?? DateTime(2000),
    lastDate: last?.toDateTimeUtc() ?? DateTime(2100),
  );
  return result == null ? null : LocalDate(result.year, result.month, result.day);
}

/// Time picker with 1-minute precision, honouring the user's 12/24 h preference.
Future<LocalTime?> pickTime(BuildContext context, {LocalTime? initial, bool use24h = true}) async {
  final init = initial ?? LocalTime(9, 0);
  final result = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: init.hour, minute: init.minute),
    builder: (ctx, child) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: use24h),
      child: child!,
    ),
  );
  return result == null ? null : LocalTime(result.hour, result.minute);
}

/// Duration picker (1 minute … 365 days) with quick presets. Returns minutes.
Future<int?> pickDuration(BuildContext context, {int initialMinutes = 30, int maxMinutes = 525600}) =>
    showAppSheet<int>(
      context,
      title: context.l10n.pickerDuration,
      builder: (ctx) => _DurationPicker(initial: initialMinutes, max: maxMinutes),
    );

class _DurationPicker extends StatefulWidget {
  const _DurationPicker({required this.initial, required this.max});

  final int initial;
  final int max;

  @override
  State<_DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<_DurationPicker> {
  late int _days = widget.initial ~/ 1440;
  late int _hours = (widget.initial % 1440) ~/ 60;
  late int _minutes = widget.initial % 60;

  int get _total => (_days * 1440 + _hours * 60 + _minutes).clamp(1, widget.max);

  static const _presets = [5, 10, 15, 30, 45, 60, 90, 120, 180, 240, 480, 1440];

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
              tooltip: '−',
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: context.text.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
            IconButton(
              tooltip: '+',
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
              for (final p in _presets)
                if (p <= widget.max)
                  ChoiceChip(
                    label: Text(_label(p)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              stepper(l.pickerDays, _days, widget.max ~/ 1440, (v) => setState(() => _days = v)),
              stepper(l.pickerHours, _hours, 23, (v) => setState(() => _hours = v)),
              stepper(l.pickerMinutes, _minutes, 59, (v) => setState(() => _minutes = v)),
            ],
          ),
          const SizedBox(height: Space.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _total),
              child: Text(l.actionApply),
            ),
          ),
        ],
      ),
    );
  }

  String _label(int m) => m >= 1440 ? '${m ~/ 1440}d' : (m >= 60 ? (m % 60 == 0 ? '${m ~/ 60}h' : '${m ~/ 60}h${m % 60}') : '${m}m');
}

/// Color picker over the category palette. Returns the ARGB int (or -1 for "no color").
Future<int?> pickColor(BuildContext context, {int? selected, bool allowNone = false}) =>
    showAppSheet<int>(
      context,
      title: context.l10n.pickerColor,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Wrap(
          spacing: Space.md,
          runSpacing: Space.md,
          children: [
            if (allowNone)
              _Swatch(
                color: ctx.colors.surfaceContainerHighest,
                selected: selected == null,
                label: ctx.l10n.pickerNoColor,
                onTap: () => Navigator.pop(ctx, -1),
                icon: Icons.block,
              ),
            for (final c in CategoryPalette.colors)
              _Swatch(
                color: Color(c),
                selected: selected == c,
                label: '#${c.toRadixString(16).substring(2).toUpperCase()}',
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );

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
          border: Border.all(
            color: selected ? context.colors.onSurface : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? Icon(Icons.check, color: CategoryColors.onBackground(color))
            : (icon == null ? null : Icon(icon, size: 18)),
      ),
    ),
  );
}

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
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: context.l10n.pickerSearchIcons,
            ),
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
