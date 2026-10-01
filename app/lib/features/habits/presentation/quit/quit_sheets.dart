import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/quit_service.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Usage count per vocabulary value of one log column (`trigger`, `place`, `coping`).
final vocabUsageProvider = FutureProvider.autoDispose.family<Map<String, int>, String>(
  (ref, column) => ref.watch(habitLogsRepositoryProvider).vocabUsage(column),
);

/// Display name of a stored vocabulary value (entry id → current name; free text as typed).
String vocabLabel(List<VocabEntry> vocab, String? value) {
  if (value == null) return '';
  for (final v in vocab) {
    if (v.id == value) return v.name;
  }
  return value;
}

/// Chips of one vocabulary (most-used first) with free-text entry (T5.3.14).
class VocabPicker extends ConsumerWidget {
  const VocabPicker({required this.kind, required this.value, required this.onChanged, required this.label, super.key});

  final VocabKind kind;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;

  static String columnOf(VocabKind kind) => switch (kind) {
    VocabKind.trigger => 'trigger',
    VocabKind.place => 'place',
    VocabKind.coping || VocabKind.distraction => 'coping',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final vocab = ref.watch(habitVocabProvider).value ?? const <VocabEntry>[];
    final usage = ref.watch(vocabUsageProvider(columnOf(kind))).value ?? const <String, int>{};
    final entries =
        [
          for (final v in vocab)
            if (v.kind == kind) v,
        ]..sort((a, b) {
          final c = (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0);
          return c != 0 ? c : a.sortKey.compareTo(b.sortKey);
        });
    final free = value != null && !entries.any((e) => e.id == value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelLarge),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final e in entries.take(12))
              ChoiceChip(
                label: Text(e.name),
                selected: value == e.id,
                onSelected: (sel) => onChanged(sel ? e.id : null),
              ),
            if (free) ChoiceChip(label: Text(value!), selected: true, onSelected: (_) => onChanged(null)),
            ActionChip(
              avatar: const Icon(Icons.edit_outlined, size: 16),
              label: Text(l.quitOther),
              onPressed: () async {
                final text = await promptText(context, title: label);
                if (text != null) onChanged(text);
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Picks a past instant (date + time) in the device zone.
Future<DateTime?> pickPastInstant(BuildContext context, WidgetRef ref, DateTime initial) async {
  final service = ref.read(habitPeriodServiceProvider);
  final zone = service.currentZone;
  final nowUtc = ref.read(clockProvider).nowUtc();
  final local = service.resolver.toLocal(initial, zone);
  final date = await pickDate(context, initial: local.date, last: service.resolver.toLocal(nowUtc, zone).date);
  if (date == null || !context.mounted) return null;
  final time = await pickTime(context, initial: local.time, use24h: ref.read(userPreferencesProvider).use24h);
  if (time == null) return null;
  final picked = service.resolver.resolve(date.atTime(time), zone).utc;
  return picked.isAfter(nowUtc) ? nowUtc : picked;
}

/// Relapse flow (T5.3.06): amount, time (default now, can be in the past), trigger, place, mood,
/// note, then — kindly — *count it as a slip* or *start a new quit attempt*.
Future<void> showRelapseSheet(BuildContext context, WidgetRef ref, QuitHabit habit, {Duration? cleanFor}) =>
    showAppSheet<void>(
      context,
      title: context.l10n.quitRelapseTitle,
      builder: (ctx) => _RelapseSheet(habit: habit, host: context, cleanFor: cleanFor),
    );

class _RelapseSheet extends ConsumerStatefulWidget {
  const _RelapseSheet({required this.habit, required this.host, this.cleanFor});

  final QuitHabit habit;
  final BuildContext host;
  final Duration? cleanFor;

  @override
  ConsumerState<_RelapseSheet> createState() => _RelapseSheetState();
}

class _RelapseSheetState extends ConsumerState<_RelapseSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late DateTime _at = ref.read(clockProvider).nowUtc();
  String? _trigger;
  String? _place;
  int? _mood;
  bool _newAttempt = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final record = await ref
        .read(quitServiceProvider)
        .logRelapse(
          widget.habit,
          at: _at,
          amount: parseLocalizedDecimal(_amount.text),
          trigger: _trigger,
          place: _place,
          mood: _mood,
          note: _note.text,
          newAttempt: _newAttempt,
        );
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.pop(context);
    if (widget.host.mounted) showUndoSnackBar(widget.host, ref, message: l.quitRelapseSaved, record: record);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final fmt = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final service = ref.watch(habitPeriodServiceProvider);
    final local = service.resolver.toLocal(_at, service.currentZone);
    final clean = widget.cleanFor;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (clean != null && clean > const Duration(minutes: 1))
            Card(
              color: context.colors.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Text(l.quitRelapseSupport(fmt.duration(clean.inMinutes)), style: context.text.bodyMedium),
              ),
            ),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.quitRelapseAmount, suffixText: l.unitLabel(widget.habit.unit, 2)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(l.quitWhen),
            subtitle: Text(fmt.dateTime(local)),
            onTap: () async {
              final at = await pickPastInstant(context, ref, _at);
              if (at != null) setState(() => _at = at);
            },
          ),
          VocabPicker(
            kind: VocabKind.trigger,
            value: _trigger,
            label: l.quitTrigger,
            onChanged: (v) => setState(() => _trigger = v),
          ),
          const SizedBox(height: Space.md),
          VocabPicker(
            kind: VocabKind.place,
            value: _place,
            label: l.quitPlace,
            onChanged: (v) => setState(() => _place = v),
          ),
          const SizedBox(height: Space.md),
          Text(l.habitsMoodLabel, style: context.text.labelLarge),
          MoodSelector(value: _mood, onChanged: (m) => setState(() => _mood = m)),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.quitNote),
          ),
          const SizedBox(height: Space.lg),
          Text(l.quitRelapseKindTitle, style: context.text.titleSmall),
          RadioGroup<bool>(
            groupValue: _newAttempt,
            onChanged: (v) => setState(() => _newAttempt = v ?? false),
            child: Column(
              children: [
                RadioListTile(value: false, title: Text(l.quitRelapseSlip)),
                RadioListTile(value: true, title: Text(l.quitRelapseNewAttempt(fmt.dateTime(local)))),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          FilledButton(onPressed: _save, child: Text(l.actionSave)),
        ],
      ),
    );
  }
}

/// Reduce mode: log a custom amount of use with time and context (T5.3.07).
Future<void> showUseSheet(BuildContext context, WidgetRef ref, QuitHabit habit) => showAppSheet<void>(
  context,
  title: context.l10n.quitLogUse,
  builder: (ctx) => _UseSheet(habit: habit, host: context),
);

class _UseSheet extends ConsumerStatefulWidget {
  const _UseSheet({required this.habit, required this.host});

  final QuitHabit habit;
  final BuildContext host;

  @override
  ConsumerState<_UseSheet> createState() => _UseSheetState();
}

class _UseSheetState extends ConsumerState<_UseSheet> {
  final _amount = TextEditingController(text: '1');
  final _note = TextEditingController();
  late DateTime _at = ref.read(clockProvider).nowUtc();
  String? _trigger;
  String? _place;
  int? _mood;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final amount = parseLocalizedDecimal(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = l.habitsValueInvalid);
      return;
    }
    final record = await ref
        .read(quitServiceProvider)
        .logUse(widget.habit, amount: amount, at: _at, trigger: _trigger, place: _place, mood: _mood, note: _note.text);
    if (!mounted) return;
    Navigator.pop(context);
    if (widget.host.mounted) showUndoSnackBar(widget.host, ref, message: l.quitUseLogged, record: record);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h);
    final service = ref.watch(habitPeriodServiceProvider);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.quitAmount,
              suffixText: l.unitLabel(widget.habit.unit, 2),
              errorText: _error,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(l.quitWhen),
            subtitle: Text(fmt.dateTime(service.resolver.toLocal(_at, service.currentZone))),
            onTap: () async {
              final at = await pickPastInstant(context, ref, _at);
              if (at != null) setState(() => _at = at);
            },
          ),
          VocabPicker(
            kind: VocabKind.trigger,
            value: _trigger,
            label: l.quitTrigger,
            onChanged: (v) => setState(() => _trigger = v),
          ),
          const SizedBox(height: Space.md),
          VocabPicker(
            kind: VocabKind.place,
            value: _place,
            label: l.quitPlace,
            onChanged: (v) => setState(() => _place = v),
          ),
          const SizedBox(height: Space.md),
          MoodSelector(value: _mood, onChanged: (m) => setState(() => _mood = m)),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.quitNote),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(onPressed: _save, child: Text(l.actionSave)),
        ],
      ),
    );
  }
}

/// One-tap craving: logs "craving now, intensity 5" and offers *Add details* (T5.3.08, ≤ 2 taps).
Future<void> logQuickCraving(BuildContext context, WidgetRef ref, QuitHabit habit) async {
  final l = context.l10n;
  final result = await ref.read(quitServiceProvider).logCraving(habit);
  await HapticFeedback.selectionClick();
  if (!context.mounted) return;
  ref.read(undoStackProvider).push(l.quitCravingLogged, result.record);
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(l.quitCravingLogged),
      action: SnackBarAction(
        label: l.quitCravingDetails,
        onPressed: () async {
          final entry = await ref.read(habitLogsRepositoryProvider).byId(result.id);
          if (entry != null && context.mounted) await showCravingSheet(context, ref, habit, existing: entry);
        },
      ),
    ),
  );
}

/// Craving detail sheet (T5.3.08): intensity 1–10, trigger, place, mood, coping, resisted (yes / no /
/// not sure), duration, note. With [existing] it edits that craving; otherwise it logs a new one.
Future<void> showCravingSheet(
  BuildContext context,
  WidgetRef ref,
  QuitHabit habit, {
  HabitLogEntry? existing,
  int? durationSeconds,
}) => showAppSheet<void>(
  context,
  title: context.l10n.quitCravingTitle,
  builder: (ctx) => _CravingSheet(habit: habit, existing: existing, host: context, durationSeconds: durationSeconds),
);

class _CravingSheet extends ConsumerStatefulWidget {
  const _CravingSheet({required this.habit, required this.host, this.existing, this.durationSeconds});

  final QuitHabit habit;
  final HabitLogEntry? existing;
  final BuildContext host;
  final int? durationSeconds;

  @override
  ConsumerState<_CravingSheet> createState() => _CravingSheetState();
}

class _CravingSheetState extends ConsumerState<_CravingSheet> {
  late double _intensity = (widget.existing?.intensity ?? 5).toDouble();
  late String? _trigger = widget.existing?.trigger;
  late String? _place = widget.existing?.place;
  late String? _coping = widget.existing?.coping;
  late int? _mood = widget.existing?.mood;
  late bool? _resisted = widget.existing?.resisted;
  late int? _duration = widget.durationSeconds ?? widget.existing?.durationSeconds;
  late final _note = TextEditingController(text: widget.existing?.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  CravingInput get _input => CravingInput(
    intensity: _intensity.round(),
    trigger: _trigger,
    place: _place,
    coping: _coping,
    resisted: _resisted,
    durationSeconds: _duration,
    mood: _mood,
    note: _note.text,
  );

  Future<void> _save() async {
    final l = context.l10n;
    final service = ref.read(quitServiceProvider);
    final record = widget.existing == null
        ? (await service.logCraving(widget.habit, input: _input)).record
        : await service.updateLog(widget.existing!, craving: _input);
    if (!mounted) return;
    Navigator.pop(context);
    if (widget.host.mounted) showUndoSnackBar(widget.host, ref, message: l.quitCravingLogged, record: record);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = AppFormat(context.localeName, l10n: l);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.quitIntensity(_intensity.round()), style: context.text.labelLarge),
          Slider(
            value: _intensity,
            min: 1,
            max: 10,
            divisions: 9,
            label: fmt.number(_intensity.round()),
            onChanged: (v) => setState(() => _intensity = v),
          ),
          Text(l.quitResisted, style: context.text.labelLarge),
          const SizedBox(height: Space.xs),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 1, label: Text(l.quitYes)),
              ButtonSegment(value: 0, label: Text(l.quitNo)),
              ButtonSegment(value: -1, label: Text(l.quitNotSure)),
            ],
            selected: {_resisted == null ? -1 : (_resisted! ? 1 : 0)},
            onSelectionChanged: (s) => setState(() => _resisted = s.first == -1 ? null : s.first == 1),
          ),
          const SizedBox(height: Space.md),
          VocabPicker(
            kind: VocabKind.trigger,
            value: _trigger,
            label: l.quitTrigger,
            onChanged: (v) => setState(() => _trigger = v),
          ),
          const SizedBox(height: Space.md),
          VocabPicker(
            kind: VocabKind.place,
            value: _place,
            label: l.quitPlace,
            onChanged: (v) => setState(() => _place = v),
          ),
          const SizedBox(height: Space.md),
          VocabPicker(
            kind: VocabKind.coping,
            value: _coping,
            label: l.quitCoping,
            onChanged: (v) => setState(() => _coping = v),
          ),
          const SizedBox(height: Space.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timer_outlined),
            title: Text(l.quitDuration),
            subtitle: Text(_duration == null ? l.habitsNone : fmt.duration((_duration! / 60).ceil())),
            onTap: () async {
              final minutes = await pickDuration(
                context,
                initialMinutes: ((_duration ?? 180) / 60).ceil(),
                maxMinutes: 240,
              );
              if (minutes != null) setState(() => _duration = minutes * 60);
            },
          ),
          Text(l.habitsMoodLabel, style: context.text.labelLarge),
          MoodSelector(value: _mood, onChanged: (m) => setState(() => _mood = m)),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l.quitNote),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(onPressed: _save, child: Text(l.actionSave)),
        ],
      ),
    );
  }
}
