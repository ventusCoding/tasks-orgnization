import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A labelled dropdown whose `null` value means "inherit" (T7.1.12: every field shows
/// Inherit / Set / Disable).
class InheritDropdown<T> extends StatelessWidget {
  const InheritDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
    this.inheritedHint,
    this.badge,
    super.key,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T value) optionLabel;
  final ValueChanged<T?> onChanged;
  final String? inheritedHint;

  /// Platform label (Android / iOS) for platform-specific fields.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: badge == null ? label : '$label · $badge',
          helperText: value == null ? inheritedHint : null,
        ),
        onChanged: onChanged,
        items: [
          DropdownMenuItem<T?>(child: Text(l.notifInherit)),
          for (final o in options) DropdownMenuItem<T?>(value: o, child: Text(optionLabel(o))),
        ],
      ),
    );
  }
}

/// Every field of the `delivery` block with inherit / set / disable semantics.
class DeliveryFieldsEditor extends StatelessWidget {
  const DeliveryFieldsEditor({required this.value, required this.onChanged, this.inheritedFrom, super.key});

  final DeliverySpec value;
  final ValueChanged<DeliverySpec> onChanged;

  /// Name of the profile values are inherited from ("Inherited from Standard").
  final String? inheritedFrom;

  DeliverySpec _set(String field, Object? v) => v == null
      ? value.copyWith(clear: {field})
      : switch (field) {
          'system' => value.copyWith(system: v as bool),
          'inbox' => value.copyWith(inbox: v as bool),
          'banner' => value.copyWith(banner: v as bool),
          'sticky' => value.copyWith(sticky: v as bool),
          'importance' => value.copyWith(importance: v as String),
          'interruptionLevel' => value.copyWith(interruptionLevel: v as String),
          'sound' => value.copyWith(sound: v as String),
          'vibration' => value.copyWith(vibration: v as String),
          _ => value,
        };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final hint = inheritedFrom == null ? null : l.notifInheritedFromProfile(inheritedFrom!);
    String yesNo(bool v) => v ? l.notifYes : l.notifNo;
    Widget boolField(String field, String label, bool? current, {String? badge}) => InheritDropdown<bool>(
      label: label,
      value: current,
      options: const [true, false],
      optionLabel: yesNo,
      inheritedHint: hint,
      badge: badge,
      onChanged: (v) => onChanged(_set(field, v)),
    );
    final actions = value.actions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        boolField('system', l.notifSystemNotification, value.system),
        boolField('inbox', l.notifInboxToggle, value.inbox),
        boolField('banner', l.notifBannerToggle, value.banner),
        InheritDropdown<String>(
          label: l.notifImportance,
          value: value.importance,
          options: [for (final i in NotificationImportance.values) i.wire],
          optionLabel: (w) => labels.importance(NotificationImportance.tryParse(w)!),
          inheritedHint: hint,
          onChanged: (v) => onChanged(_set('importance', v)),
        ),
        InheritDropdown<String>(
          label: l.notifInterruption,
          value: value.interruptionLevel,
          options: [for (final i in InterruptionLevel.values) i.wire],
          optionLabel: (w) => labels.interruption(InterruptionLevel.tryParse(w)!),
          inheritedHint: hint,
          badge: l.notifIosLabel,
          onChanged: (v) => onChanged(_set('interruptionLevel', v)),
        ),
        InheritDropdown<String>(
          label: l.notifSound,
          value: value.sound,
          options: NotificationLabels.curatedSounds,
          optionLabel: labels.sound,
          inheritedHint: hint,
          onChanged: (v) => onChanged(_set('sound', v)),
        ),
        InheritDropdown<String>(
          label: l.notifVibration,
          value: value.vibration,
          options: NotificationLabels.vibrations,
          optionLabel: labels.vibration,
          inheritedHint: hint,
          badge: l.notifAndroidLabel,
          onChanged: (v) => onChanged(_set('vibration', v)),
        ),
        boolField('sticky', l.notifSticky, value.sticky, badge: l.notifAndroidLabel),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Expanded(child: Text(l.notifActions, style: context.text.titleSmall)),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l.notifInherit)),
                ButtonSegment(value: true, label: Text(l.notifModeCustom)),
              ],
              selected: {actions != null},
              onSelectionChanged: (s) => onChanged(s.first ? value.copyWith(actions: const []) : value.copyWith(clear: {'actions'})),
            ),
          ],
        ),
        if (actions != null)
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              for (final a in NotificationActionIds.all)
                FilterChip(
                  label: Text(actions.contains(a) ? '${actions.indexOf(a) + 1}. ${labels.action(a)}' : labels.action(a)),
                  selected: actions.contains(a),
                  onSelected: (v) => onChanged(value.copyWith(actions: v ? [...actions, a] : [for (final x in actions) if (x != a) x])),
                ),
            ],
          ),
        if (actions != null && actions.length > 3)
          Text(l.notifIssueTooManyActions, style: context.text.bodySmall?.copyWith(color: context.appColors.warning)),
        _NumbersField(
          label: l.notifSnoozeOptions,
          values: value.snoozeOptionsMinutes,
          onChanged: (v) => onChanged(v == null ? value.copyWith(clear: {'snoozeOptionsMinutes'}) : value.copyWith(snoozeOptionsMinutes: v)),
        ),
        _NumbersField(
          label: l.notifLateness,
          values: value.latenessMinutes == null ? null : [value.latenessMinutes!],
          single: true,
          onChanged: (v) => onChanged(
            v == null || v.isEmpty ? value.copyWith(clear: {'latenessMinutes'}) : value.copyWith(latenessMinutes: v.first),
          ),
        ),
      ],
    );
  }
}

/// Comma-separated integers (empty = inherit).
class _NumbersField extends StatefulWidget {
  const _NumbersField({required this.label, required this.values, required this.onChanged, this.single = false});

  final String label;
  final List<int>? values;
  final ValueChanged<List<int>?> onChanged;
  final bool single;

  @override
  State<_NumbersField> createState() => _NumbersFieldState();
}

class _NumbersFieldState extends State<_NumbersField> {
  late final _controller = TextEditingController(text: widget.values?.join(', ') ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.xs),
    child: TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(widget.single ? '[0-9]' : '[0-9, ]'))],
      decoration: InputDecoration(labelText: widget.label, hintText: context.l10n.notifInherit),
      onChanged: (text) {
        final parts = [for (final p in text.split(',')) ?int.tryParse(p.trim())];
        widget.onChanged(text.trim().isEmpty ? null : parts);
      },
    ),
  );
}

/// Weekday chips (ISO 1..7) in the user's week order.
class WeekdayChips extends StatelessWidget {
  const WeekdayChips({required this.selected, required this.onChanged, super.key});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final format = AppFormat(context.localeName);
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (var iso = 1; iso <= 7; iso++)
          FilterChip(
            label: Text(format.weekdayShort(Weekday.fromIso(iso))),
            selected: selected.contains(iso),
            onSelected: (v) => onChanged(v ? {...selected, iso} : ({...selected}..remove(iso))),
          ),
      ],
    );
  }
}
