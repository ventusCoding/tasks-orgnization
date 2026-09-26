import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/recurrence_ui/domain/recurrence_presets.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Multi-select weekday chips ordered by the user's week start.
class WeekdayChips extends StatelessWidget {
  const WeekdayChips({
    required this.selected,
    required this.onChanged,
    required this.weekStart,
    required this.format,
    super.key,
    this.keyPrefix = 'recur-day',
  });

  final Set<Weekday> selected;
  final ValueChanged<Set<Weekday>> onChanged;
  final Weekday weekStart;
  final AppFormat format;

  /// Chips get `ValueKey('$keyPrefix-MO')`… for tests.
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.xs,
    runSpacing: Space.xs,
    children: [
      for (final day in Weekday.ordered(weekStart))
        FilterChip(
          key: ValueKey('$keyPrefix-${day.code}'),
          label: Text(format.weekdayShort(day), semanticsLabel: format.weekdayLong(day)),
          selected: selected.contains(day),
          showCheckmark: false,
          onSelected: (on) => onChanged(on ? {...selected, day} : ({...selected}..remove(day))),
        ),
    ],
  );
}

/// Integer input: − [value] + with a numeric text field for large values (every 90 minutes).
class NumberStepper extends StatefulWidget {
  const NumberStepper({
    required this.value,
    required this.onChanged,
    super.key,
    this.min = 1,
    this.max = 9999,
    this.label,
    this.fieldKey,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// Semantics label of the field ("Every", "How many times"…).
  final String? label;
  final Key? fieldKey;

  @override
  State<NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<NumberStepper> {
  late final TextEditingController _controller = TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(NumberStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (int.tryParse(_controller.text) != widget.value) {
      _controller.value = TextEditingValue(
        text: '${widget.value}',
        selection: TextSelection.collapsed(offset: '${widget.value}'.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(int value) {
    final clamped = value.clamp(widget.min, widget.max);
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: '−',
        onPressed: widget.value > widget.min ? () => _set(widget.value - 1) : null,
        icon: const Icon(Icons.remove),
      ),
      SizedBox(
        width: 72,
        child: Semantics(
          label: widget.label,
          child: TextField(
            key: widget.fieldKey,
            controller: _controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: InputDecoration(isDense: true, hintText: '${widget.min}'),
            style: context.text.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            onChanged: (text) {
              final parsed = int.tryParse(text);
              if (parsed != null) _set(parsed);
            },
            onEditingComplete: () {
              _controller.text = '${widget.value}';
              FocusScope.of(context).unfocus();
            },
          ),
        ),
      ),
      IconButton(
        tooltip: '+',
        onPressed: widget.value < widget.max ? () => _set(widget.value + 1) : null,
        icon: const Icon(Icons.add),
      ),
    ],
  );
}

/// *Ends: never / on date / after N times* (T2.1.15).
class RecurrenceEndsEditor extends StatelessWidget {
  const RecurrenceEndsEditor({
    required this.ends,
    required this.onChanged,
    required this.firstDate,
    required this.format,
    super.key,
  });

  final RecurrenceEnds ends;
  final ValueChanged<RecurrenceEnds> onChanged;

  /// Series start (earliest end date offered).
  final LocalDate firstDate;
  final AppFormat format;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final until = ends.until;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.xs,
          children: [
            for (final (kind, label) in [
              (RecurrenceEndKind.never, l.recurEndsNever),
              (RecurrenceEndKind.onDate, l.recurEndsOn),
              (RecurrenceEndKind.afterCount, l.recurEndsAfter),
            ])
              ChoiceChip(
                key: ValueKey('recur-ends-${kind.name}'),
                label: Text(label),
                selected: ends.kind == kind,
                onSelected: (_) {
                  if (ends.kind == kind) return;
                  onChanged(switch (kind) {
                    RecurrenceEndKind.never => const RecurrenceEnds.never(),
                    RecurrenceEndKind.onDate => RecurrenceEnds.onDate(firstDate.plusMonths(1)),
                    RecurrenceEndKind.afterCount => const RecurrenceEnds.after(10),
                  });
                },
              ),
          ],
        ),
        if (until != null)
          ListTile(
            key: const ValueKey('recur-ends-date'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(format.dateMedium(until.date)),
            onTap: () async {
              final picked = await pickDate(context, initial: until.date, first: firstDate);
              if (picked != null) onChanged(RecurrenceEnds.onDate(picked));
            },
          ),
        if (ends.kind == RecurrenceEndKind.afterCount)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: Space.xs),
            child: Row(
              children: [
                NumberStepper(
                  fieldKey: const ValueKey('recur-ends-count'),
                  value: ends.count ?? 1,
                  max: 9999,
                  label: l.recurEndsAfter,
                  onChanged: (v) => onChanged(RecurrenceEnds.after(v)),
                ),
                const SizedBox(width: Space.sm),
                Flexible(child: Text(l.recurEndsCount(ends.count ?? 1))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Editable list of times of day (several times a day).
class TimeListEditor extends StatelessWidget {
  const TimeListEditor({
    required this.times,
    required this.onChanged,
    required this.format,
    required this.use24h,
    super.key,
    this.initialNewTime,
  });

  final List<LocalTime> times;
  final ValueChanged<List<LocalTime>> onChanged;
  final AppFormat format;
  final bool use24h;
  final LocalTime? initialNewTime;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final t in times)
          InputChip(
            key: ValueKey('recur-time-${t.toIso()}'),
            label: Text(format.time(t)),
            onPressed: () async {
              final picked = await pickTime(context, initial: t, use24h: use24h);
              if (picked == null) return;
              onChanged(({...times.where((x) => x != t), picked}.toList()..sort()));
            },
            onDeleted: () => onChanged([...times.where((x) => x != t)]),
            deleteButtonTooltipMessage: l.recurRemoveTime(format.time(t)),
          ),
        ActionChip(
          key: const ValueKey('recur-time-add'),
          avatar: const Icon(Icons.add),
          label: Text(l.recurAddTime),
          onPressed: () async {
            final seed = times.isEmpty ? initialNewTime : times.last.plusMinutesWrapped(60);
            final picked = await pickTime(context, initial: seed, use24h: use24h);
            if (picked == null) return;
            onChanged(({...times, picked}.toList()..sort()));
          },
        ),
      ],
    );
  }
}

/// Section title + content used by the sheet and the editor.
class RecurrenceSection extends StatelessWidget {
  const RecurrenceSection({required this.title, required this.child, super.key, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: context.text.titleSmall?.copyWith(color: context.colors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: Space.xs),
        child,
      ],
    ),
  );
}
