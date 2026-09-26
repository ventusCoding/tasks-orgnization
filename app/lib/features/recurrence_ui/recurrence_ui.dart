/// Reusable recurrence UI (T2.1.15, T2.1.16, T2.1.19): presets picker, advanced editor with
/// live preview and warnings, and the exceptions manager. Used by the planner, habits,
/// checklist resets and notification schedules.
///
/// ```dart
/// final rule = await showRecurrencePicker(
///   context,
///   initial: current,
///   anchor: RecurrenceAnchor(start, zoneId),
///   mode: RecurrencePickerMode.habit,
/// );
/// ```
library;

export 'application/recurrence_preview.dart'
    show RecurrencePreview, RecurrencePreviewer, RecurrenceWarning, RecurrenceWarningKind;
export 'domain/recurrence_exception.dart';
export 'domain/recurrence_presets.dart'
    show
        RecurrenceEndKind,
        RecurrenceEnds,
        RecurrencePickResult,
        RecurrencePickerMode,
        RecurrencePreset,
        RecurrencePresets;
export 'presentation/recurrence_editor_screen.dart' show RecurrenceEditorScreen, showRecurrenceEditor;
export 'presentation/recurrence_exceptions_view.dart';
export 'presentation/recurrence_picker.dart';
export 'presentation/recurrence_presets_sheet.dart';
