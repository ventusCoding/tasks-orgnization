import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/check_in_service.dart';
import 'package:everslot/features/habits/application/habit_day_view.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/features/habits/presentation/pause_sheet.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Runs check-in commands from widgets: Undo snackbars, localized refusals, haptics and the optional
/// "note & mood" prompt after a check-in (never blocking the check-in itself).
class CheckInActions {
  CheckInActions(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  CheckInService get _service => ref.read(checkInServiceProvider);

  Future<bool> _run(Future<CheckInResult> Function() action, String Function(CheckInResult r) message, {BuildHabit? promptFor}) async {
    final l = context.l10n;
    try {
      final result = await action();
      await HapticFeedback.selectionClick();
      if (!context.mounted) return true;
      showUndoSnackBar(context, ref, message: message(result), record: result.record);
      if (promptFor != null && promptFor.settings.askNoteAfterCheckIn && context.mounted) {
        unawaited(showNoteMoodSheet(context, ref, promptFor, result.target.key));
      }
      return true;
    } on CheckInException catch (e) {
      if (context.mounted) {
        showInfoSnackBar(context, e.refusal == CheckInRefusal.future ? l.habitsErrorFuture : l.habitsErrorArchived);
      }
      return false;
    }
  }

  Future<bool> setState(BuildHabit habit, String key, CheckInState? state, {String? note, LocalTime? at}) {
    final l = context.l10n;
    return _run(
      () => _service.setState(habit, key, state, note: note, at: at),
      (_) => switch (state) {
        CheckInState.done => l.habitsSnackDone(habit.name),
        CheckInState.notDone => l.habitsSnackNotDone(habit.name),
        CheckInState.skip => l.habitsSnackSkipped(habit.name),
        CheckInState.excuse => l.habitsSnackExcused(habit.name),
        null => l.habitsSnackCleared(habit.name),
      },
      promptFor: state == CheckInState.done ? habit : null,
    );
  }

  Future<bool> addProgress(BuildHabit habit, String key, double value, {int? durationSeconds, LocalTime? at}) {
    final l = context.l10n;
    return _run(
      () => _service.addProgress(habit, key, value, durationSeconds: durationSeconds, at: at),
      (_) => l.habitsSnackLogged(formatAmount(context, value, habit.goal.unit), habit.name),
      promptFor: habit,
    );
  }

  Future<bool> checkNow(BuildHabit habit) =>
      _run(() => _service.checkNow(habit), (_) => context.l10n.habitsSnackDone(habit.name), promptFor: habit);

  /// Asks for an optional reason, then skips / excuses.
  Future<void> skipOrExcuse(BuildHabit habit, String key, CheckInState state) async {
    final l = context.l10n;
    final reason = await promptText(
      context,
      title: state == CheckInState.skip ? l.habitsActionSkip : l.habitsActionExcuse,
      hint: l.habitsReasonOptional,
      allowEmpty: true,
    );
    if (reason == null && !context.mounted) return;
    await setState(habit, key, state, note: reason);
  }
}

/// Long-press menu of a habit on a day (T5.2.03): not done, skip, excuse with reason, note & mood,
/// entries, backfill another day, details, pause, edit.
Future<void> showHabitActionsSheet(BuildContext context, WidgetRef ref, HabitDayView view) {
  final l = context.l10n;
  final habit = view.habit;
  return showAppSheet<void>(
    context,
    title: habit.name,
    builder: (ctx) {
      final actions = CheckInActions(context, ref);
      void close() => Navigator.pop(ctx);
      return ListView(
        shrinkWrap: true,
        children: [
          if (!view.future) ...[
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(l.habitsActionDone),
              onTap: () {
                close();
                unawaited(actions.setState(habit, view.key, CheckInState.done));
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: Text(l.habitsActionNotDone),
              onTap: () {
                close();
                unawaited(actions.setState(habit, view.key, CheckInState.notDone));
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.redo),
            title: Text(l.habitsActionSkip),
            onTap: () {
              close();
              unawaited(actions.skipOrExcuse(habit, view.key, CheckInState.skip));
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_busy),
            title: Text(l.habitsActionExcuse),
            onTap: () {
              close();
              unawaited(actions.skipOrExcuse(habit, view.key, CheckInState.excuse));
            },
          ),
          if (view.explicit != null)
            ListTile(
              leading: const Icon(Icons.backspace_outlined),
              title: Text(l.habitsActionClear),
              onTap: () {
                close();
                unawaited(actions.setState(habit, view.key, null));
              },
            ),
          if (!view.future)
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(l.habitsActionNoteMood),
              onTap: () {
                close();
                unawaited(showNoteMoodSheet(context, ref, habit, view.key));
              },
            ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: Text(l.habitsActionEditEntries),
            onTap: () {
              close();
              unawaited(showDayEditor(context, ref, habit.id, view.date));
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l.habitsActionBackfill),
            onTap: () async {
              close();
              final date = await pickDate(context, initial: view.date.minusDays(1), first: habit.startDate, last: view.snapshot.today);
              if (date != null && context.mounted) await showDayEditor(context, ref, habit.id, date);
            },
          ),
          ListTile(
            leading: const Icon(Icons.pause_circle_outline),
            title: Text(l.habitsActionPause),
            onTap: () {
              close();
              unawaited(showPauseSheet(context, ref, habitId: habit.id));
            },
          ),
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: Text(l.habitsActionDetails),
            onTap: () {
              close();
              unawaited(HabitRoutes.detail(context, habit.id));
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l.habitsActionEdit),
            onTap: () {
              close();
              unawaited(HabitRoutes.edit(context, habit.id));
            },
          ),
        ],
      );
    },
  );
}

/// Numeric entry sheet (T5.2.04): locale decimal separators and Arabic-Indic digits, unit, quick
/// values. Returns the value, or null when cancelled.
Future<double?> showValueSheet(BuildContext context, BuildHabit habit, {double? initial, String? title}) =>
    showAppSheet<double>(
      context,
      title: title ?? context.l10n.habitsValueTitle,
      builder: (ctx) => _ValueSheet(habit: habit, initial: initial),
    );

class _ValueSheet extends StatefulWidget {
  const _ValueSheet({required this.habit, this.initial});

  final BuildHabit habit;
  final double? initial;

  @override
  State<_ValueSheet> createState() => _ValueSheetState();
}

class _ValueSheetState extends State<_ValueSheet> {
  late final _controller = TextEditingController(
    text: widget.initial == null ? '' : widget.initial!.toString().replaceFirst(RegExp(r'\.0$'), ''),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = parseLocalizedDecimal(_controller.text);
    if (value == null || value <= 0) {
      setState(() => _error = context.l10n.habitsValueInvalid);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final goal = widget.habit.goal;
    final quick = widget.habit.settings.quickValues.isNotEmpty
        ? widget.habit.settings.quickValues
        : [widget.habit.settings.incrementStep, 5.0, 10.0].toSet().toList();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.habitsValueHint,
              suffixText: l.unitLabel(goal.unit, 2),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            children: [
              for (final q in quick)
                ActionChip(
                  label: Text('+${formatValue(context, q)}'),
                  onPressed: () => Navigator.pop(context, q),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          FilledButton(onPressed: _submit, child: Text(l.actionSave)),
        ],
      ),
    );
  }
}

/// Optional note & 1–5 mood of a period (T5.2.09) — dismissible, never blocks the check-in.
Future<void> showNoteMoodSheet(BuildContext context, WidgetRef ref, BuildHabit habit, String key) async {
  final snapshot = ref.read(habitSnapshotProvider(habit.id)).value;
  final existing = snapshot?.stateOf(key);
  final noteRow = snapshot?.entriesOf(key).where((e) => e.kind == HabitLogKind.note).firstOrNull;
  final result = await showAppSheet<({String? note, int? mood})>(
    context,
    title: context.l10n.habitsNoteMoodTitle,
    builder: (ctx) => _NoteMoodSheet(
      initialNote: existing?.note ?? noteRow?.note,
      initialMood: existing?.mood ?? noteRow?.mood,
    ),
  );
  if (result == null || !context.mounted) return;
  try {
    final r = await ref.read(checkInServiceProvider).setNoteAndMood(habit, key, note: result.note, mood: result.mood);
    if (context.mounted) showUndoSnackBar(context, ref, message: context.l10n.savedSnack, record: r.record);
  } on CheckInException {
    if (context.mounted) showInfoSnackBar(context, context.l10n.habitsErrorArchived);
  }
}

class _NoteMoodSheet extends StatefulWidget {
  const _NoteMoodSheet({this.initialNote, this.initialMood});

  final String? initialNote;
  final int? initialMood;

  @override
  State<_NoteMoodSheet> createState() => _NoteMoodSheetState();
}

class _NoteMoodSheetState extends State<_NoteMoodSheet> {
  late final _note = TextEditingController(text: widget.initialNote);
  late int? _mood = widget.initialMood;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: InputDecoration(hintText: l.habitsNoteHint),
          ),
          const SizedBox(height: Space.md),
          Text(l.habitsMoodLabel, style: context.text.labelLarge),
          const SizedBox(height: Space.sm),
          MoodSelector(value: _mood, onChanged: (m) => setState(() => _mood = m)),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: () => Navigator.pop(context, (note: _note.text, mood: _mood)),
            child: Text(l.actionSave),
          ),
        ],
      ),
    );
  }
}

/// Day editor (T5.2.08): state, value entries, note & mood of any day — and planned skips/excuses
/// for future days.
Future<void> showDayEditor(BuildContext context, WidgetRef ref, String habitId, LocalDate date) =>
    showAppSheet<void>(
      context,
      title: AppFormat(context.localeName).dayLong(date),
      builder: (ctx) => _DayEditor(habitId: habitId, date: date, host: context),
    );

class _DayEditor extends ConsumerWidget {
  const _DayEditor({required this.habitId, required this.date, required this.host});

  final String habitId;
  final LocalDate date;

  /// Context of the page (snackbars and nested sheets outlive this sheet).
  final BuildContext host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final snapshot = ref.watch(habitSnapshotProvider(habitId)).value;
    final habit = snapshot?.build;
    if (snapshot == null || habit == null) return const LoadingState();
    final view = habitDayView(snapshot, date, ref.watch(habitPeriodServiceProvider));
    if (view == null) {
      return Padding(padding: const EdgeInsets.all(Space.lg), child: Text(l.habitsNotActiveThatDay));
    }
    final actions = CheckInActions(host, ref);
    final keys = view.isSlot ? [for (final s in view.slots) s.key] : [date.toIso()];
    final entries = [
      for (final k in keys) ...snapshot.entriesOf(k),
    ]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final progress = [for (final e in entries) if (e.kind == HabitLogKind.progress) e];
    final fmt = AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h);
    final zone = ref.watch(habitPeriodServiceProvider).zoneOf(habit);
    final resolver = ref.watch(zoneResolverProvider);

    Widget stateChips(String key, {String? label}) {
      final current = snapshot.stateOf(key)?.kind;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) Text(label, style: context.text.labelLarge),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              for (final s in CheckInState.values)
                if (!view.future || s.allowedInFuture)
                  ChoiceChip(
                    label: Text(switch (s) {
                      CheckInState.done => l.habitsActionDone,
                      CheckInState.notDone => l.habitsActionNotDone,
                      CheckInState.skip => l.habitsActionSkip,
                      CheckInState.excuse => l.habitsActionExcuse,
                    }),
                    selected: current == s.kind,
                    onSelected: (sel) => unawaited(actions.setState(habit, key, sel ? s : null)),
                  ),
            ],
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [HabitStatusPill(view.status), const Spacer()]),
          const SizedBox(height: Space.md),
          if (view.future) ...[
            Text(l.habitsFutureOnlyPlanned, style: context.text.bodySmall),
            const SizedBox(height: Space.sm),
          ],
          Text(l.habitsDayStateLabel, style: context.text.titleSmall),
          const SizedBox(height: Space.xs),
          if (view.isSlot)
            for (final s in view.slots)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: Space.sm),
                child: stateChips(
                  s.key,
                  label: fmt.time(LocalDateTime.tryParse(s.key)?.time ?? LocalTime.midnight),
                ),
              )
          else
            stateChips(date.toIso()),
          if (habit.goal.isMeasurable && !view.future) ...[
            const SizedBox(height: Space.lg),
            SectionHeader(
              l.habitsEntries,
              padding: EdgeInsets.zero,
              trailing: TextButton.icon(
                onPressed: () async {
                  final value = await showValueSheet(context, habit);
                  if (value != null) await actions.addProgress(habit, view.key, value);
                },
                icon: const Icon(Icons.add),
                label: Text(l.habitsAddEntry),
              ),
            ),
            Text(
              l.habitsTotalOfTarget(
                formatAmount(context, view.achieved, habit.goal.unit),
                formatAmount(context, view.target, habit.goal.unit),
              ),
              style: context.text.bodyMedium,
            ),
            if (progress.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: Space.sm), child: Text(l.habitsNoEntries))
            else
              for (final e in progress)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatAmount(context, e.value ?? 0, habit.goal.unit)),
                  subtitle: Text(
                    [fmt.timeOf(resolver.toLocal(e.loggedAt, zone)), if (e.note != null) e.note!].join(' · '),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l.habitsEditEntry,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final value = await showValueSheet(context, habit, initial: e.value);
                          if (value == null) return;
                          final record = await ref.read(checkInServiceProvider).updateEntry(e, value: value);
                          if (host.mounted) showUndoSnackBar(host, ref, message: l.savedSnack, record: record);
                        },
                      ),
                      IconButton(
                        tooltip: l.habitsDeleteEntry,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final record = await ref.read(checkInServiceProvider).deleteEntry(e);
                          if (host.mounted) showUndoSnackBar(host, ref, message: l.habitsEntryDeleted, record: record);
                        },
                      ),
                    ],
                  ),
                ),
          ],
          if (!view.future) ...[
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              onPressed: () => unawaited(showNoteMoodSheet(host, ref, habit, view.key)),
              icon: const Icon(Icons.edit_note),
              label: Text(l.habitsActionNoteMood),
            ),
          ],
          for (final e in entries)
            if (e.note != null && e.kind != HabitLogKind.progress)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: Space.sm),
                child: Text(
                  [if (e.mood != null) MoodSelector.emojis[e.mood! - 1], e.note!].join(' '),
                  style: context.text.bodyMedium,
                ),
              ),
        ],
      ),
    );
  }
}

/// Default unit hint for value fields.
String unitHint(BuildContext context, HabitTarget goal) =>
    goal.unit == null ? '' : context.l10n.unitLabel(goal.unit, 2);

/// Unit catalog entries for a goal type.
List<String> unitChoices(HabitGoalType type) => switch (type) {
  HabitGoalType.count => HabitUnits.count,
  HabitGoalType.numeric => HabitUnits.numeric,
  HabitGoalType.duration => const [HabitUnits.minutes],
  HabitGoalType.check => const [],
};
