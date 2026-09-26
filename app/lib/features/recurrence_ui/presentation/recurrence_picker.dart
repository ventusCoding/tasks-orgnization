import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/recurrence_ui/domain/recurrence_presets.dart';
import 'package:everslot/features/recurrence_ui/presentation/recurrence_presets_sheet.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:material_ui/material_ui.dart';

/// Reusable recurrence picker (T2.1.15) used by task, habit, checklist-reset and reminder
/// editors: a bottom sheet of presets for [mode] with *Ends*, a live description and
/// *Custom…* (advanced editor, T2.1.16).
///
/// Returns the rule the caller should now use:
/// * the picked rule,
/// * `null` when the user picked *Does not repeat* (never offered in [RecurrencePickerMode.habit]),
/// * [initial] unchanged when the sheet is dismissed — so `rule = await showRecurrencePicker(…)`
///   is always safe.
///
/// Presets are synchronized with the [anchor]: e.g. *Specific days → Tue* picked on a Monday
/// starts the series on Tuesday (the sheet shows a note). Callers that own a start date use
/// [showRecurrencePickerDetailed] to also receive the aligned anchor.
Future<RecurrenceRule?> showRecurrencePicker(
  BuildContext context, {
  required RecurrenceAnchor anchor,
  RecurrenceRule? initial,
  RecurrencePickerMode mode = RecurrencePickerMode.task,
}) async {
  final result = await showRecurrencePickerDetailed(context, anchor: anchor, initial: initial, mode: mode);
  return result == null ? initial : result.rule;
}

/// Like [showRecurrencePicker] but returns the rule with the aligned anchor, or null when the
/// sheet is dismissed.
Future<RecurrencePickResult?> showRecurrencePickerDetailed(
  BuildContext context, {
  required RecurrenceAnchor anchor,
  RecurrenceRule? initial,
  RecurrencePickerMode mode = RecurrencePickerMode.task,
}) => showAppSheet<RecurrencePickResult>(
  context,
  title: context.l10n.recurPickerTitle,
  builder: (_) => RecurrencePresetsSheet(anchor: anchor, initial: initial, mode: mode),
);
