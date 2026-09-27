import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Pause one habit or — without [habitId] — every habit (vacation mode) for a range (T5.1.14):
/// presets today / 3 days / 1 week / until a date / indefinitely, with an optional reason.
Future<void> showPauseSheet(BuildContext context, WidgetRef ref, {String? habitId}) => showAppSheet<void>(
  context,
  title: habitId == null ? context.l10n.habitsVacationTitle : context.l10n.habitsPauseTitle,
  builder: (ctx) => _PauseSheet(habitId: habitId, host: context),
);

enum _PausePreset { today, threeDays, week, until, indefinitely }

class _PauseSheet extends ConsumerStatefulWidget {
  const _PauseSheet({required this.habitId, required this.host});

  final String? habitId;
  final BuildContext host;

  @override
  ConsumerState<_PauseSheet> createState() => _PauseSheetState();
}

class _PauseSheetState extends ConsumerState<_PauseSheet> {
  _PausePreset _preset = _PausePreset.week;
  LocalDate? _until;
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  LocalDate? _end(LocalDate today) => switch (_preset) {
    _PausePreset.today => today,
    _PausePreset.threeDays => today.plusDays(2),
    _PausePreset.week => today.plusDays(6),
    _PausePreset.until => _until ?? today,
    _PausePreset.indefinitely => null,
  };

  Future<void> _save() async {
    final today = ref.read(habitTodayProvider);
    final record = await ref
        .read(habitServiceProvider)
        .pause(habitId: widget.habitId, start: today, end: _end(today), reason: _reason.text);
    if (!mounted) return;
    Navigator.pop(context);
    if (widget.host.mounted) showUndoSnackBar(widget.host, ref, message: context.l10n.habitsPausedSnack, record: record);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = ref.watch(habitTodayProvider);
    final fmt = AppFormat(context.localeName);
    final active = [
      for (final p in ref.watch(habitPausesProvider).value ?? const <PauseSpan>[])
        if (p.habitId == widget.habitId && (p.end == null || !p.end!.isBefore(today))) p,
    ];
    String label(_PausePreset p) => switch (p) {
      _PausePreset.today => l.habitsPauseToday,
      _PausePreset.threeDays => l.habitsPauseDays(3),
      _PausePreset.week => l.habitsPauseWeek,
      _PausePreset.until => _until == null ? l.habitsPauseUntil : l.habitsPauseUntilDate(fmt.dateMedium(_until!)),
      _PausePreset.indefinitely => l.habitsPauseIndefinitely,
    };
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in active)
            Card(
              child: ListTile(
                leading: const Icon(Icons.pause_circle_outline),
                title: Text(
                  p.end == null ? l.habitsPausedIndefinitely : l.habitsPausedUntil(fmt.dateMedium(p.end!)),
                ),
                subtitle: p.reason == null ? null : Text(p.reason!),
                trailing: TextButton(
                  onPressed: () async {
                    final record = await ref.read(habitServiceProvider).resume(p, today: today);
                    if (widget.host.mounted) {
                      showUndoSnackBar(widget.host, ref, message: l.habitsResumedSnack, record: record);
                    }
                  },
                  child: Text(l.habitsResume),
                ),
              ),
            ),
          Text(l.habitsPauseHint, style: context.text.bodySmall),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              for (final p in _PausePreset.values)
                ChoiceChip(
                  label: Text(label(p)),
                  selected: _preset == p,
                  onSelected: (_) async {
                    if (p == _PausePreset.until) {
                      final picked = await pickDate(context, initial: _until ?? today.plusDays(7), first: today);
                      if (picked == null) return;
                      _until = picked;
                    }
                    setState(() => _preset = p);
                  },
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _reason,
            decoration: InputDecoration(labelText: l.habitsReasonOptional),
          ),
          const SizedBox(height: Space.lg),
          FilledButton(onPressed: _save, child: Text(l.habitsPauseAction)),
        ],
      ),
    );
  }
}

/// Banner "Paused until …" with *Resume* (vacation or one habit).
class PauseBanner extends ConsumerWidget {
  const PauseBanner({required this.pause, super.key});

  final PauseSpan pause;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = AppFormat(context.localeName);
    final text = pause.isGlobal
        ? (pause.end == null ? l.habitsVacationIndefinitely : l.habitsVacationUntil(fmt.dateMedium(pause.end!)))
        : (pause.end == null ? l.habitsPausedIndefinitely : l.habitsPausedUntil(fmt.dateMedium(pause.end!)));
    return MaterialBanner(
      leading: const Icon(Icons.beach_access),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () async {
            final record = await ref.read(habitServiceProvider).resume(pause, today: ref.read(habitTodayProvider));
            if (context.mounted) showUndoSnackBar(context, ref, message: l.habitsResumedSnack, record: record);
          },
          child: Text(l.habitsResume),
        ),
      ],
    );
  }
}
