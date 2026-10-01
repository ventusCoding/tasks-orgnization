import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/check_in_sheets.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Timeline of every note and mood across habits (T5.2.15): filter by habit and mood, a mood
/// sparkline of the last 30 entries, tap to jump to the day.
class NotesJournalScreen extends ConsumerStatefulWidget {
  const NotesJournalScreen({super.key});

  @override
  ConsumerState<NotesJournalScreen> createState() => _NotesJournalScreenState();
}

class _NotesJournalScreenState extends ConsumerState<NotesJournalScreen> {
  String? _habitId;
  int? _mood;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final entries = ref.watch(habitJournalProvider).value ?? const <HabitLogEntry>[];
    final habits = {for (final h in ref.watch(allHabitsProvider).value ?? const <Habit>[]) h.id: h};
    final filtered = [
      for (final e in entries)
        if ((_habitId == null || e.habitId == _habitId) &&
            (_mood == null || e.mood == _mood) &&
            habits.containsKey(e.habitId))
          e,
    ];
    final moods = [
      for (final e in filtered.take(30).toList().reversed)
        if (e.mood != null) e.mood!.toDouble(),
    ];
    final fmt = AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h);
    return Scaffold(
      appBar: AppBar(title: Text(l.habitsJournal)),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Space.xxl),
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Space.sm),
                  child: ChoiceChip(
                    label: Text(l.habitsFilterAll),
                    selected: _habitId == null && _mood == null,
                    onSelected: (_) => setState(() {
                      _habitId = null;
                      _mood = null;
                    }),
                  ),
                ),
                for (var m = 5; m >= 1; m--)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.sm),
                    child: ChoiceChip(
                      label: Text('${MoodSelector.emojis[m - 1]} ${l.moodLabel(m)}'),
                      selected: _mood == m,
                      onSelected: (sel) => setState(() => _mood = sel ? m : null),
                    ),
                  ),
                for (final h in habits.values)
                  if (entries.any((e) => e.habitId == h.id))
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: Space.sm),
                      child: ChoiceChip(
                        label: Text(h.name),
                        selected: _habitId == h.id,
                        onSelected: (sel) => setState(() => _habitId = sel ? h.id : null),
                      ),
                    ),
              ],
            ),
          ),
          if (moods.length >= 2)
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Semantics(
                label: l.habitsMoodTrend,
                child: SizedBox(height: 48, child: CustomPaint(painter: _Sparkline(moods, context.colors.primary))),
              ),
            ),
          if (filtered.isEmpty)
            EmptyState(icon: Icons.edit_note, title: l.habitsJournalEmpty, message: l.habitsJournalEmptyBody)
          else
            for (final e in filtered)
              ListTile(
                leading: e.mood == null
                    ? const Icon(Icons.notes)
                    : Text(MoodSelector.emojis[e.mood! - 1], style: context.text.headlineSmall),
                title: Text(e.note ?? l.moodLabel(e.mood ?? 3)),
                subtitle: Text('${habits[e.habitId]?.name ?? ''} · ${fmt.dayLong(e.localDate)}'),
                onTap: () {
                  final habit = habits[e.habitId];
                  if (habit is BuildHabit) unawaited(showDayEditor(context, ref, habit.id, e.localDate));
                },
              ),
        ],
      ),
    );
  }
}

class _Sparkline extends CustomPainter {
  _Sparkline(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - 1) / 4 * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_Sparkline old) => old.values != values || old.color != color;
}
