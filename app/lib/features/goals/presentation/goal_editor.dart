import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/goals/application/goal_progress.dart';
import 'package:everslot/features/goals/application/goal_service.dart';
import 'package:everslot/features/goals/domain/goal.dart';
import 'package:everslot/features/goals/presentation/goal_ui.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/check_in.dart' show parseLocalizedDecimal;
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Creates or edits a goal of a habit or quit tracker (T5.4.02) — or, with [reward], a savings
/// reward of a quit tracker (T5.3.15: a money-saved goal with a name and a price). Only the
/// measures the habit allows can be chosen; the suggestion offers a round target just above the
/// current pace ("At your pace you'd reach 8 400 — aim for 10 000?"). Works offline.
Future<void> showGoalEditor(BuildContext context, {required String habitId, Goal? existing, bool reward = false}) =>
    showAppSheet<void>(
      context,
      title: existing == null
          ? (reward ? context.l10n.quitRewardAdd : context.l10n.goalsNew)
          : (reward ? context.l10n.quitRewardName : context.l10n.goalsEdit),
      builder: (_) =>
          _GoalEditor(habitId: habitId, existing: existing, reward: reward || (existing?.isReward ?? false)),
    );

class _GoalEditor extends ConsumerStatefulWidget {
  const _GoalEditor({required this.habitId, required this.reward, this.existing});

  final String habitId;
  final Goal? existing;
  final bool reward;

  @override
  ConsumerState<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends ConsumerState<_GoalEditor> {
  late final _target = TextEditingController(text: _num(widget.existing?.target));
  late final _title = TextEditingController(text: widget.existing?.reward ?? widget.existing?.title ?? '');
  GoalMetric? _metric;
  late GoalPeriod _period = widget.existing?.period ?? (widget.reward ? GoalPeriod.allTime : GoalPeriod.month);
  late LocalDate? _start = widget.existing?.startDate;
  late LocalDate? _end = widget.existing?.endDate;
  String? _error;
  bool _saving = false;

  static String _num(double? v) => v == null ? '' : (v == v.roundToDouble() ? '${v.round()}' : '$v');

  @override
  void dispose() {
    _target.dispose();
    _title.dispose();
    super.dispose();
  }

  Goal _draft(GoalMetric metric) => Goal(
    id: widget.existing?.id ?? Ids.v7(),
    scopeType: GoalScopeType.habit,
    scopeId: widget.habitId,
    metric: metric,
    target: parseLocalizedDecimal(_target.text) ?? 0,
    period: _period,
    startDate: _period == GoalPeriod.custom ? _start : null,
    endDate: _period == GoalPeriod.custom ? _end : null,
    title: widget.reward ? null : _title.text,
    reward: widget.reward ? _title.text : null,
    achievedAt: widget.existing?.achievedAt,
  );

  Future<void> _save(Habit habit, GoalMetric metric) async {
    final l = context.l10n;
    final goal = _draft(metric);
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(goalServiceProvider).save(goal, habitKind: goalHabitKindOf(habit), isNew: widget.existing == null);
      if (!mounted) return;
      Navigator.pop(context);
      showInfoSnackBar(context, widget.reward ? l.quitRewardSaved : l.goalsSaved);
    } on GoalValidationException catch (e) {
      if (mounted) setState(() => _error = l.goalValidationMessage(e.code));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final snapshot = ref.watch(habitSnapshotProvider(widget.habitId)).value;
    if (snapshot == null) return const LoadingState();
    final habit = snapshot.habit;
    final metrics = [
      for (final m in GoalMetric.values)
        if (goalMetricsFor(GoalScopeType.habit, habitKind: goalHabitKindOf(habit)).contains(m)) m,
    ];
    final metric = widget.reward
        ? GoalMetric.moneySaved
        : (_metric ??
              widget.existing?.metric ??
              (metrics.contains(GoalMetric.totalValue) ? GoalMetric.totalValue : metrics.first));
    final fmt = AppFormat(context.localeName, l10n: l);

    // Pace suggestion: what the recent rate reaches by the end of the chosen period.
    String? suggestion;
    double? suggested;
    if (!widget.reward && _period != GoalPeriod.allTime && metric != GoalMetric.streakDays) {
      final probe = _draft(metric).copyWith(target: 1);
      final valid = _period != GoalPeriod.custom || (_start != null && _end != null && !_end!.isBefore(_start!));
      if (valid) {
        final e = evaluateHabitGoal(probe, snapshot, weekStart: ref.watch(userPreferencesProvider).weekStart);
        final projected = e.progress.projectedEnd;
        if (projected > 0) {
          suggested = niceTargetAbove(projected);
          suggestion = l.goalsSuggestion(
            goalValueText(context, ref, metric, projected.roundToDouble(), habit),
            goalValueText(context, ref, metric, suggested, habit),
          );
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            maxLength: Goal.maxTitleLength,
            decoration: InputDecoration(labelText: widget.reward ? l.quitRewardName : l.goalsTitleField),
          ),
          if (!widget.reward) ...[
            Text(l.goalsMetric, style: context.text.labelLarge),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final m in metrics)
                  ChoiceChip(
                    label: Text(l.goalMetricLabel(m)),
                    selected: metric == m,
                    onSelected: (_) => setState(() => _metric = m),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
          ],
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: widget.reward ? l.quitRewardPrice : l.goalsTarget),
            onChanged: (_) => setState(() {}),
          ),
          if (suggestion != null && suggested != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: Space.sm),
              child: Row(
                children: [
                  Expanded(child: Text(suggestion, style: context.text.bodySmall)),
                  ActionChip(
                    label: Text(l.goalsUseSuggestion(goalValueText(context, ref, metric, suggested, habit))),
                    onPressed: () => setState(() => _target.text = _num(suggested)),
                  ),
                ],
              ),
            ),
          if (!widget.reward) ...[
            const SizedBox(height: Space.md),
            Text(l.goalsPeriod, style: context.text.labelLarge),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final p in GoalPeriod.values)
                  ChoiceChip(
                    label: Text(l.goalPeriodLabel(p)),
                    selected: _period == p,
                    onSelected: (_) => setState(() {
                      _period = p;
                      if (p == GoalPeriod.custom) {
                        final today = snapshot.today;
                        _start ??= today;
                        _end ??= today.plusDays(29);
                      }
                    }),
                  ),
              ],
            ),
            if (_period == GoalPeriod.custom)
              Row(
                children: [
                  for (final (label, value, isStart) in [(l.goalsFrom, _start, true), (l.goalsTo, _end, false)])
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(label),
                        subtitle: Text(value == null ? '—' : fmt.dateMedium(value)),
                        onTap: () async {
                          final picked = await pickDate(context, initial: value ?? snapshot.today);
                          if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
                        },
                      ),
                    ),
                ],
              ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: Space.sm),
              child: Text(_error!, style: TextStyle(color: context.colors.error)),
            ),
          const SizedBox(height: Space.lg),
          FilledButton(onPressed: _saving ? null : () => _save(habit, metric), child: Text(l.actionSave)),
          if (widget.existing != null)
            TextButton(
              onPressed: () async {
                final record = await ref.read(goalServiceProvider).delete(widget.existing!.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                showUndoSnackBar(context, ref, message: l.goalsDeleted, record: record);
              },
              child: Text(l.goalsDelete),
            ),
        ],
      ),
    );
  }
}
