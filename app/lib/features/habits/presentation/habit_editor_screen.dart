import 'dart:async';

import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/time/recurrence_service.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_periods.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot/features/habits/domain/schedule_presets.dart';
import 'package:everslot/features/habits/presentation/check_in_sheets.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/features/habits/presentation/manage_habits_screen.dart';
import 'package:everslot/features/habits/presentation/quit/quit_editor.dart';
import 'package:everslot/features/habits/presentation/templates_sheet.dart';
import 'package:everslot/features/notifications/presentation/notification_settings_section.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/presentation/categories_screen.dart' show pickCategory;
import 'package:everslot/features/recurrence_ui/recurrence_ui.dart';
import 'package:everslot_metrics/everslot_metrics.dart' show HabitPeriodKind;
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Full-screen habit editor (T5.1.07, T5.1.08, T5.1.12, T5.1.13) — quit trackers use [QuitEditor]
/// (T5.3.02). Route: `/habit-new?kind=build|quit`, `/habits/:id/edit`.
class HabitEditorScreen extends ConsumerWidget {
  const HabitEditorScreen({this.habitId, this.kind = 'build', this.template, super.key});

  final String? habitId;
  final String kind;

  /// Template key (habit template, or a quit preset key for `kind == 'quit'`).
  final String? template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (habitId == null) {
      return kind == 'quit' ? QuitEditor(presetKey: template) : BuildHabitEditor(templateKey: template);
    }
    final habit = ref.watch(habitByIdProvider(habitId!));
    return AsyncValueView<Habit?>(
      value: habit,
      loading: const Scaffold(body: LoadingState()),
      data: (h) => switch (h) {
        null => Scaffold(appBar: AppBar(), body: EmptyState(title: context.l10n.errorNotFound)),
        final BuildHabit b => BuildHabitEditor(existing: b),
        final QuitHabit q => QuitEditor(existing: q),
      },
    );
  }
}

/// Editor of a build habit.
class BuildHabitEditor extends ConsumerStatefulWidget {
  const BuildHabitEditor({this.existing, this.templateKey, super.key});

  final BuildHabit? existing;
  final String? templateKey;

  @override
  ConsumerState<BuildHabitEditor> createState() => _BuildHabitEditorState();
}

class _BuildHabitEditorState extends ConsumerState<BuildHabitEditor> {
  late final String _id = widget.existing?.id ?? Ids.v7();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _target = TextEditingController();
  final _customUnit = TextEditingController();
  final _reminders = NotificationRulesDraft();

  String? _icon;
  int? _color;
  String? _categoryId;
  String? _sectionId;
  HabitGoalType _goalType = HabitGoalType.count;
  TargetOp _op = TargetOp.gte;
  String? _unit = HabitUnits.reps;
  SchedulePreset _preset = const SchedulePreset.daily();
  late LocalDate _start;
  LocalDate? _end;
  String? _zone;
  SkipPolicy _skipPolicy = SkipPolicy.neutral;
  int _freezes = 0;
  HabitSettings _settings = HabitSettings.defaults;
  bool _initialized = false;
  String? _nameError;
  String? _targetError;
  String? _formError;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _target.dispose();
    _customUnit.dispose();
    _reminders.dispose();
    super.dispose();
  }

  void _init() {
    if (_initialized) return;
    _initialized = true;
    final today = ref.read(habitTodayProvider);
    _start = today;
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _description.text = e.description ?? '';
      _icon = e.icon;
      _color = e.color;
      _categoryId = e.categoryId;
      _sectionId = e.sectionId;
      _goalType = e.goal.type;
      _op = e.goal.op;
      _unit = e.goal.unit;
      if (e.goal.target != null) _target.text = _num(e.goal.target!);
      _preset = SchedulePreset.fromRule(e.schedule, goal: e.goal);
      _start = e.startDate;
      _end = e.endDate;
      _zone = e.timeZone;
      _skipPolicy = e.skipPolicy;
      _freezes = e.freezesPerMonth;
      _settings = e.settings;
      if (_unit != null && !HabitUnits.isCatalog(_unit)) _customUnit.text = _unit!;
      return;
    }
    final t = widget.templateKey == null ? null : HabitTemplate.byKey(widget.templateKey!);
    if (t != null) {
      final l = context.l10n;
      _name.text = l.templateName(t.key);
      _icon = t.icon;
      _color = CategoryPalette.at(t.colorIndex);
      _goalType = t.goal.type;
      _op = t.goal.op;
      _unit = t.goal.unit;
      if (t.goal.target != null) _target.text = _num(t.goal.target!);
      _preset = t.schedule;
      _settings = t.settings;
      if (t.challengeDays != null) {
        _end = today.plusDays(t.challengeDays! - 1);
        _settings = _settings.copyWith(challenge: const ChallengeSettings());
      }
      final sections = ref.read(habitSectionsRepositoryProvider);
      _sectionId = sections.defaultId(t.sectionKey);
    } else {
      _sectionId = ref.read(habitSectionsRepositoryProvider).defaultId(DefaultSections.anytime);
    }
  }

  static String _num(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

  bool get _measurable => _goalType != HabitGoalType.check;

  HabitTarget get _goal => _measurable
      ? HabitTarget(
          type: _goalType,
          target: parseLocalizedDecimal(_target.text),
          op: _op,
          unit: _goalType == HabitGoalType.duration ? HabitUnits.minutes : _unit,
        )
      : const HabitTarget.check();

  BuildHabit _draft() {
    final weekStart = ref.read(userPreferencesProvider).weekStart;
    final goal = _preset.adaptGoal(_goal);
    return BuildHabit(
      id: _id,
      name: _name.text,
      description: _description.text,
      icon: _icon,
      color: _color,
      categoryId: _categoryId,
      sectionId: _sectionId,
      startDate: _start,
      endDate: _end,
      timeZone: _zone,
      sortKey: widget.existing?.sortKey ?? '',
      archivedAt: widget.existing?.archivedAt,
      notifyMode: widget.existing?.notifyMode ?? 'inherit',
      createdAt: widget.existing?.createdAt,
      goal: goal,
      schedule: _preset.toRule(weekStart: weekStart),
      skipPolicy: _skipPolicy,
      freezesPerMonth: _freezes,
      settings: _settings,
    );
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() {
      _nameError = null;
      _targetError = null;
      _formError = null;
    });
    final habit = _draft();
    try {
      habit.validate();
    } on HabitValidationException catch (e) {
      final message = l.validationMessage(e.code);
      setState(() {
        switch (e.field) {
          case 'name':
            _nameError = message;
          case 'target_value':
            _targetError = message;
          default:
            _formError = message;
        }
      });
      return;
    }
    final service = ref.read(habitServiceProvider);
    setState(() => _saving = true);
    try {
      if (_isNew) {
        await service.create(habit, reminders: _reminders);
      } else {
        final existing = widget.existing!;
        var applyFrom = ref.read(habitTodayProvider);
        var scope = RevisionScope.fromDate;
        if (HabitsRepositoryRules.changed(existing, habit)) {
          final choice = await _askApplyFrom();
          if (choice == null) {
            setState(() => _saving = false);
            return;
          }
          (applyFrom, scope) = choice;
        }
        await service.update(habit, applyFrom: applyFrom, scope: scope);
      }
      if (!mounted) return;
      showInfoSnackBar(context, l.habitsSavedSnack);
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// T5.1.13: "Apply from: today (default) / a chosen date / all history".
  Future<(LocalDate, RevisionScope)?> _askApplyFrom() async {
    final l = context.l10n;
    final today = ref.read(habitTodayProvider);
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.habitsApplyTitle),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'today'), child: Text(l.habitsApplyToday)),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'date'), child: Text(l.habitsApplyDate)),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'all'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(l.habitsApplyAll), Text(l.habitsApplyAllWarn, style: ctx.text.bodySmall)],
            ),
          ),
        ],
      ),
    );
    switch (choice) {
      case 'today':
        return (today, RevisionScope.fromDate);
      case 'all':
        return (today, RevisionScope.allHistory);
      case 'date':
        if (!mounted) return null;
        final date = await pickDate(context, initial: today, first: widget.existing!.startDate, last: today);
        return date == null ? null : (date, RevisionScope.fromDate);
    }
    return null;
  }

  Future<void> _pickCustom() async {
    final habit = _draft();
    final rule = await showRecurrencePicker(
      context,
      anchor: RecurrenceAnchor.allDayOn(_start, _zone),
      initial: habit.schedule,
      mode: RecurrencePickerMode.habit,
    );
    if (rule == null || !mounted) return;
    setState(() => _preset = SchedulePreset.fromRule(rule, goal: _preset.adaptGoal(_goal)));
  }

  @override
  Widget build(BuildContext context) {
    _init();
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final fmt = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final category = ref.watch(categoryByIdProvider(_categoryId));
    final sections = ref.watch(allHabitSectionsProvider).value ?? const <HabitSection>[];
    final section = sections.where((s) => s.id == _sectionId).firstOrNull;
    final draft = _draft();
    final slotBased = ScheduleShape.of(draft.schedule) == ScheduleShape.slot;
    final isQuota = ScheduleShape.of(draft.schedule) == ScheduleShape.quota;
    final targetValue = parseLocalizedDecimal(_target.text);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.habitsEditorNewTitle : l.habitsEditorEditTitle),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l.actionSave)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.xxxl),
        children: [
          if (_isNew) ...[
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'build', label: Text(l.habitsTypeBuild), icon: const Icon(Icons.trending_up)),
                ButtonSegment(value: 'quit', label: Text(l.habitsTypeQuit), icon: const Icon(Icons.smoke_free)),
              ],
              selected: const {'build'},
              onSelectionChanged: (s) {
                if (s.first == 'quit') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const QuitEditor()),
                  );
                }
              },
            ),
            const SizedBox(height: Space.lg),
          ],
          TextField(
            controller: _name,
            autofocus: _isNew && widget.templateKey == null,
            maxLength: Habit.maxNameLength,
            decoration: InputDecoration(labelText: l.habitsFieldName, hintText: l.habitsFieldNameHint, errorText: _nameError),
            onChanged: (_) => setState(() {}),
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(IconCatalog.iconFor(_icon, fallback: Icons.check_circle_outline)),
                  title: Text(l.habitsFieldIcon),
                  onTap: () async {
                    final icon = await pickIcon(context, selected: _icon);
                    if (icon != null) setState(() => _icon = icon);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ColorDot(_color == null ? context.colors.outline : Color(_color!), size: 20),
                  title: Text(l.habitsFieldColor),
                  onTap: () async {
                    final c = await pickColor(context, selected: _color, allowNone: true);
                    if (c != null) setState(() => _color = c == -1 ? null : c);
                  },
                ),
              ),
            ],
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.label_outline),
            title: Text(l.habitsFieldCategory),
            subtitle: Text(category?.name ?? l.habitsNone),
            onTap: () async {
              final id = await pickCategory(context, ref, selectedId: _categoryId);
              if (id != null) setState(() => _categoryId = id.isEmpty ? null : id);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.view_agenda_outlined),
            title: Text(l.habitsFieldSection),
            subtitle: Text(section == null ? l.habitsNone : sectionName(context, section)),
            onTap: () async {
              final id = await pickHabitSection(context, ref, selectedId: _sectionId);
              if (id != null) setState(() => _sectionId = id.isEmpty ? null : id);
            },
          ),
          TextField(
            controller: _description,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(labelText: l.habitsFieldDescription),
          ),
          SectionHeader(l.habitsGoalTitle, padding: const EdgeInsetsDirectional.only(top: Space.xl, bottom: Space.sm)),
          _GoalTypePicker(
            value: _goalType,
            onChanged: (t) => setState(() {
              _goalType = t;
              if (t == HabitGoalType.check) _op = TargetOp.gte;
              if (t != HabitGoalType.check && (_unit == null || !unitChoices(t).contains(_unit))) {
                _unit = HabitUnits.defaultFor(t);
              }
            }),
          ),
          if (_measurable) ...[
            const SizedBox(height: Space.md),
            SegmentedButton<TargetOp>(
              segments: [
                for (final op in TargetOp.values) ButtonSegment(value: op, label: Text(l.opLabel(op))),
              ],
              selected: {_op},
              onSelectionChanged: (s) => setState(() => _op = s.first),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.habitsFieldTarget,
                errorText: _targetError,
                suffixText: _goalType == HabitGoalType.duration ? l.habitsUnitMin : l.unitLabel(_unit, targetValue ?? 2),
                helperText: _goalType == HabitGoalType.duration && (targetValue ?? 0) >= 60
                    ? fmt.duration(targetValue!.round())
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_goalType == HabitGoalType.duration)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () async {
                    final minutes = await pickDuration(context, initialMinutes: (targetValue ?? 20).round(), maxMinutes: 1440);
                    if (minutes != null) setState(() => _target.text = '$minutes');
                  },
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(l.habitsPickDuration),
                ),
              ),
            if (_goalType != HabitGoalType.duration) ...[
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.xs,
                children: [
                  for (final u in unitChoices(_goalType))
                    ChoiceChip(label: Text(l.unitLabel(u, 2)), selected: _unit == u, onSelected: (_) => setState(() => _unit = u)),
                  ChoiceChip(
                    label: Text(l.habitsUnitCustom),
                    selected: _unit != null && !HabitUnits.isCatalog(_unit),
                    onSelected: (_) async {
                      final text = await promptText(context, title: l.habitsFieldUnit, initial: _customUnit.text);
                      if (text != null) setState(() => _unit = _customUnit.text = text);
                    },
                  ),
                ],
              ),
            ],
            if (_op == TargetOp.lte && targetValue == 0)
              Card(
                margin: const EdgeInsetsDirectional.only(top: Space.md),
                child: ListTile(
                  leading: const Icon(Icons.smoke_free),
                  title: Text(l.habitsLimitZeroHint),
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const QuitEditor()),
                    ),
                    child: Text(l.habitsCreateQuitInstead),
                  ),
                ),
              ),
          ],
          SectionHeader(l.habitsScheduleTitle, padding: const EdgeInsetsDirectional.only(top: Space.xl, bottom: Space.sm)),
          _ScheduleEditor(
            preset: _preset,
            weekStart: prefs.weekStart,
            use24h: prefs.use24h,
            onChanged: (p) => setState(() => _preset = p),
            onCustom: _pickCustom,
          ),
          const SizedBox(height: Space.md),
          _SchedulePreview(habit: draft),
          SectionHeader(l.habitsDatesTitle, padding: const EdgeInsetsDirectional.only(top: Space.xl, bottom: Space.sm)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.play_arrow_outlined),
            title: Text(l.habitsFieldStart),
            subtitle: Text(fmt.dateMedium(_start)),
            onTap: () async {
              final d = await pickDate(context, initial: _start);
              if (d != null) setState(() => _start = d);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: Text(l.habitsFieldEnd),
            subtitle: Text(_end == null ? l.habitsEndNever : fmt.dateMedium(_end!)),
            trailing: _end == null
                ? TextButton(
                    onPressed: () => setState(() {
                      _end = _start.plusDays(29);
                      _settings = _settings.copyWith(challenge: _settings.challenge ?? const ChallengeSettings());
                    }),
                    child: Text(l.habitsFor30Days),
                  )
                : IconButton(
                    tooltip: l.actionClear,
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _end = null;
                      _settings = _settings.copyWith(challenge: null);
                    }),
                  ),
            onTap: () async {
              final d = await pickDate(context, initial: _end ?? _start.plusDays(29), first: _start);
              if (d != null) setState(() => _end = d);
            },
          ),
          if (_end != null) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.habitsChallengeTitle),
              value: _settings.challenge != null,
              onChanged: (v) => setState(() => _settings = _settings.copyWith(challenge: v ? const ChallengeSettings() : null)),
            ),
            if (_settings.challenge case final challenge?) ...[
              Text(l.habitsChallengeRuleTitle, style: context.text.labelLarge),
              RadioGroup<ChallengeRule>(
                groupValue: challenge.rule,
                onChanged: (v) => setState(
                  () => _settings = _settings.copyWith(
                    challenge: ChallengeSettings(rule: v ?? ChallengeRule.everyDay, minRatio: challenge.minRatio),
                  ),
                ),
                child: Column(
                  children: [
                    RadioListTile(value: ChallengeRule.everyDay, title: Text(l.habitsChallengeEveryDay)),
                    RadioListTile(
                      value: ChallengeRule.minRatio,
                      title: Text(l.habitsChallengeMinRatio(fmt.percent(challenge.minRatio))),
                    ),
                  ],
                ),
              ),
              if (challenge.rule == ChallengeRule.minRatio)
                _IntStepper(
                  label: l.habitsChallengeRuleTitle,
                  value: (challenge.minRatio * 100).round(),
                  min: 50,
                  max: 100,
                  step: 5,
                  format: (v) => fmt.percent(v / 100),
                  onChanged: (v) => setState(
                    () => _settings = _settings.copyWith(challenge: ChallengeSettings(rule: challenge.rule, minRatio: v / 100)),
                  ),
                ),
              if (_measurable) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.habitsProgressionTitle),
                  subtitle: Text(l.habitsProgressionHint),
                  value: _settings.targetProgression != null,
                  onChanged: (v) => setState(
                    () => _settings = _settings.copyWith(
                      targetProgression: v
                          ? TargetProgression(start: targetValue ?? 1, step: 1, everyDays: 1)
                          : null,
                    ),
                  ),
                ),
                if (_settings.targetProgression case final p?) ...[
                  _IntStepper(
                    label: l.habitsProgressionStep,
                    value: p.step.round(),
                    min: 1,
                    max: 100,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(
                        targetProgression: TargetProgression(start: p.start, step: v.toDouble(), everyDays: p.everyDays, max: p.max),
                      ),
                    ),
                  ),
                  _IntStepper(
                    label: l.habitsProgressionEvery,
                    value: p.everyDays,
                    min: 1,
                    max: 30,
                    format: l.habitsDays,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(
                        targetProgression: TargetProgression(start: p.start, step: p.step, everyDays: v, max: p.max),
                      ),
                    ),
                  ),
                  _IntStepper(
                    label: l.habitsProgressionMax,
                    value: (p.max ?? 0).round(),
                    min: 0,
                    max: 10000,
                    step: 5,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(
                        targetProgression: TargetProgression(
                          start: p.start,
                          step: p.step,
                          everyDays: p.everyDays,
                          max: v == 0 ? null : v.toDouble(),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    l.habitsProgressionToday(
                      formatAmount(context, p.targetOn(_start, ref.watch(habitTodayProvider)), _goal.unit),
                    ),
                    style: context.text.bodySmall,
                  ),
                ],
              ],
            ],
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.habitsZoneFixed(prefs.currentTimeZone)),
            subtitle: Text(_zone == null ? l.habitsZoneFloating : l.habitsZoneFixedHint(_zone!)),
            value: _zone != null,
            onChanged: (v) => setState(() => _zone = v ? (widget.existing?.timeZone ?? prefs.currentTimeZone) : null),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l.habitsAdvancedTitle),
            children: [
              Text(l.habitsSkipPolicy, style: context.text.labelLarge),
              RadioGroup<SkipPolicy>(
                groupValue: _skipPolicy,
                onChanged: (v) => setState(() => _skipPolicy = v ?? SkipPolicy.neutral),
                child: Column(
                  children: [
                    RadioListTile(value: SkipPolicy.neutral, title: Text(l.habitsSkipNeutral)),
                    RadioListTile(value: SkipPolicy.breaks, title: Text(l.habitsSkipBreaks)),
                  ],
                ),
              ),
              _IntStepper(
                label: l.habitsFreezes,
                value: _freezes,
                min: 0,
                max: 31,
                onChanged: (v) => setState(() => _freezes = v),
              ),
              if (slotBased) ...[
                _IntStepper(
                  label: l.habitsTolerance,
                  value: _settings.earlyToleranceMinutes,
                  min: 0,
                  max: 120,
                  step: 5,
                  format: (v) => l.habitsMinutesValue(v),
                  onChanged: (v) => setState(() => _settings = _settings.copyWith(earlyToleranceMinutes: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.habitsRollupMinTitle),
                  subtitle: Text(
                    _settings.slotRollup == SlotRollupMode.minSlots
                        ? l.habitsRollupMin(_settings.minSlots ?? 1)
                        : l.habitsRollupAll,
                  ),
                  value: _settings.slotRollup == SlotRollupMode.minSlots,
                  onChanged: (v) => setState(
                    () => _settings = _settings.copyWith(
                      slotRollup: v ? SlotRollupMode.minSlots : SlotRollupMode.allSlots,
                      minSlots: v ? (_settings.minSlots ?? 1) : null,
                    ),
                  ),
                ),
                if (_settings.slotRollup == SlotRollupMode.minSlots)
                  _IntStepper(
                    label: l.habitsRollupMinCount,
                    value: _settings.minSlots ?? 1,
                    min: 1,
                    max: 48,
                    onChanged: (v) => setState(() => _settings = _settings.copyWith(minSlots: v)),
                  ),
              ],
              if (_measurable) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.habitsIncrementStep),
                  trailing: Text(formatValue(context, _settings.incrementStep)),
                  onTap: () async {
                    final v = await showValueSheet(context, draft, initial: _settings.incrementStep, title: l.habitsIncrementStep);
                    if (v != null) setState(() => _settings = _settings.copyWith(incrementStep: v));
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.habitsQuickValues),
                  subtitle: Text(
                    _settings.quickValues.isEmpty
                        ? l.habitsNone
                        : _settings.quickValues.map((v) => formatValue(context, v)).join(' · '),
                  ),
                  onTap: () async {
                    final text = await promptText(
                      context,
                      title: l.habitsQuickValues,
                      hint: l.habitsQuickValuesHint,
                      initial: _settings.quickValues.map(_num).join(' '),
                      allowEmpty: true,
                    );
                    if (text == null) return;
                    final values = [
                      for (final part in text.split(RegExp(r'[\s;]+')))
                        if (parseLocalizedDecimal(part) case final v? when v > 0) v,
                    ];
                    setState(() => _settings = _settings.copyWith(quickValues: values.take(5).toList()));
                  },
                ),
                if (isQuota)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.habitsMinPerDay),
                    trailing: Text(_settings.minPerDay == null ? l.habitsNone : formatValue(context, _settings.minPerDay!)),
                    onTap: () async {
                      final v = await showValueSheet(context, draft, initial: _settings.minPerDay, title: l.habitsMinPerDay);
                      if (v != null) setState(() => _settings = _settings.copyWith(minPerDay: v));
                    },
                  ),
              ],
              if (_measurable && _op == TargetOp.lte)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.habitsRequireExplicit),
                  value: _settings.requireExplicitLog,
                  onChanged: (v) => setState(() => _settings = _settings.copyWith(requireExplicitLog: v)),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.habitsAskNote),
                value: _settings.askNoteAfterCheckIn,
                onChanged: (v) => setState(() => _settings = _settings.copyWith(askNoteAfterCheckIn: v)),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          NotificationSettingsSection(
            targetType: NotificationTargetType.habit,
            targetId: _id,
            section: NotificationSection.habits,
            itemKind: slotBased ? ItemKind.timed : ItemKind.allDay,
            categoryId: _categoryId,
            draft: _isNew ? _reminders : null,
          ),
          if (_formError != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: Space.md),
              child: Text(_formError!, style: TextStyle(color: context.colors.error)),
            ),
          const SizedBox(height: Space.lg),
          FilledButton(onPressed: _saving ? null : _save, child: Text(l.actionSave)),
        ],
      ),
    );
  }
}

/// Rules-change detection exposed to the editor (same rule as the repository).
abstract final class HabitsRepositoryRules {
  static bool changed(Habit before, Habit after) => switch ((before, after)) {
    (final BuildHabit a, final BuildHabit b) => a.schedule != b.schedule || a.goal != b.goal,
    (final QuitHabit a, final QuitHabit b) =>
      a.baselinePerDay != b.baselinePerDay || a.unitCost != b.unitCost || a.dailyLimit != b.dailyLimit,
    _ => true,
  };
}

/// Goal cards with examples: Yes/No, Count, Duration, Numeric.
class _GoalTypePicker extends StatelessWidget {
  const _GoalTypePicker({required this.value, required this.onChanged});

  final HabitGoalType value;
  final ValueChanged<HabitGoalType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const icons = {
      HabitGoalType.check: Icons.check_circle_outline,
      HabitGoalType.count: Icons.tag,
      HabitGoalType.duration: Icons.timer_outlined,
      HabitGoalType.numeric: Icons.straighten,
    };
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth >= 520 ? (c.maxWidth - Space.sm * 3) / 4 : (c.maxWidth - Space.sm) / 2;
        return Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final t in HabitGoalType.values)
              SizedBox(
                width: width,
                child: Semantics(
                  selected: value == t,
                  button: true,
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: value == t ? context.colors.primaryContainer : null,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Radii.md),
                      onTap: () => onChanged(t),
                      child: Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icons[t]),
                            const SizedBox(height: Space.xs),
                            Text(l.goalTypeLabel(t), style: context.text.titleSmall),
                            Text(l.goalTypeExample(t), style: context.text.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Integer stepper row.
class _IntStepper extends StatelessWidget {
  const _IntStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.format,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String Function(int value)? format;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      IconButton(
        tooltip: '−',
        onPressed: value - step >= min ? () => onChanged(value - step) : null,
        icon: const Icon(Icons.remove),
      ),
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 40),
        child: Text(format?.call(value) ?? formatValue(context, value), textAlign: TextAlign.center),
      ),
      IconButton(
        tooltip: '+',
        onPressed: value + step <= max ? () => onChanged(value + step) : null,
        icon: const Icon(Icons.add),
      ),
    ],
  );
}

/// Preset chips + parameters of the "fully free" schedule UI (T5.1.08).
class _ScheduleEditor extends StatelessWidget {
  const _ScheduleEditor({
    required this.preset,
    required this.weekStart,
    required this.use24h,
    required this.onChanged,
    required this.onCustom,
  });

  final SchedulePreset preset;
  final Weekday weekStart;
  final bool use24h;
  final ValueChanged<SchedulePreset> onChanged;
  final VoidCallback onCustom;

  static const _kinds = [
    SchedulePresetKind.daily,
    SchedulePresetKind.weekdays,
    SchedulePresetKind.weekends,
    SchedulePresetKind.specificDays,
    SchedulePresetKind.everyNDays,
    SchedulePresetKind.timesPerWeek,
    SchedulePresetKind.timesPerMonth,
    SchedulePresetKind.timesPerDay,
    SchedulePresetKind.specificTimes,
    SchedulePresetKind.interval,
    SchedulePresetKind.monthlyDay,
    SchedulePresetKind.monthlyWeekday,
    SchedulePresetKind.afterCompletion,
  ];

  SchedulePreset _defaultFor(SchedulePresetKind k) => switch (k) {
    SchedulePresetKind.specificDays => const SchedulePreset(SchedulePresetKind.specificDays, days: [Weekday.monday, Weekday.tuesday]),
    SchedulePresetKind.everyNDays => const SchedulePreset(SchedulePresetKind.everyNDays, n: 2),
    SchedulePresetKind.timesPerWeek => const SchedulePreset(SchedulePresetKind.timesPerWeek, n: 3),
    SchedulePresetKind.timesPerMonth => const SchedulePreset(SchedulePresetKind.timesPerMonth, n: 10),
    SchedulePresetKind.timesPerDay => const SchedulePreset(SchedulePresetKind.timesPerDay, n: 8),
    SchedulePresetKind.specificTimes => SchedulePreset(
      SchedulePresetKind.specificTimes,
      times: [LocalTime(8, 0), LocalTime(20, 0)],
    ),
    SchedulePresetKind.interval => SchedulePreset(
      SchedulePresetKind.interval,
      everyMinutes: 60,
      windowStart: LocalTime(9, 0),
      windowEnd: LocalTime(18, 0),
    ),
    SchedulePresetKind.monthlyDay => const SchedulePreset(SchedulePresetKind.monthlyDay, monthDay: 1),
    SchedulePresetKind.monthlyWeekday => const SchedulePreset(SchedulePresetKind.monthlyWeekday, ordinal: 1),
    SchedulePresetKind.afterCompletion => const SchedulePreset(SchedulePresetKind.afterCompletion, n: 3),
    _ => SchedulePreset(k),
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = AppFormat(context.localeName, use24h: use24h);
    Widget stepper(String label, int value, int min, int max, ValueChanged<int> set) =>
        _IntStepper(label: label, value: value, min: min, max: max, onChanged: set);
    Widget weekdayChips(List<Weekday> days, ValueChanged<List<Weekday>> set, {bool allowEmpty = false}) => Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final w in Weekday.ordered(weekStart))
          FilterChip(
            label: Text(fmt.weekdayShort(w)),
            selected: days.contains(w),
            onSelected: (sel) {
              final next = {...days};
              sel ? next.add(w) : next.remove(w);
              if (next.isEmpty && !allowEmpty) return;
              set(next.toList());
            },
          ),
      ],
    );
    Widget params;
    switch (preset.kind) {
      case SchedulePresetKind.specificDays:
        params = weekdayChips(preset.days, (d) => onChanged(preset.copyWith(days: d)));
      case SchedulePresetKind.everyNDays:
        params = stepper(l.habitsEveryNDays(preset.n), preset.n, 2, 365, (v) => onChanged(preset.copyWith(n: v)));
      case SchedulePresetKind.timesPerWeek:
        params = stepper(l.habitsTimesPerWeek(preset.n), preset.n, 1, 7, (v) => onChanged(preset.copyWith(n: v)));
      case SchedulePresetKind.timesPerMonth:
        params = stepper(l.habitsTimesPerMonth(preset.n), preset.n, 1, 31, (v) => onChanged(preset.copyWith(n: v)));
      case SchedulePresetKind.timesPerDay:
        params = stepper(l.habitsTimesPerDay(preset.n), preset.n, 2, 48, (v) => onChanged(preset.copyWith(n: v)));
      case SchedulePresetKind.specificTimes:
        params = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final t in preset.times)
                  InputChip(
                    label: Text(fmt.time(t)),
                    onDeleted: preset.times.length > 1
                        ? () => onChanged(preset.copyWith(times: [for (final x in preset.times) if (x != t) x]))
                        : null,
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: Text(l.habitsAddTime),
                  onPressed: () async {
                    final t = await pickTime(context, use24h: use24h);
                    if (t != null && !preset.times.contains(t)) {
                      onChanged(preset.copyWith(times: [...preset.times, t]..sort()));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(l.habitsOnlyOn, style: context.text.labelMedium),
            weekdayChips(preset.days, (d) => onChanged(preset.copyWith(days: d)), allowEmpty: true),
          ],
        );
      case SchedulePresetKind.interval:
        params = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final m in const [15, 30, 45, 60, 90, 120, 180, 240])
                  ChoiceChip(
                    label: Text(fmt.duration(m)),
                    selected: preset.everyMinutes == m,
                    onSelected: (_) => onChanged(preset.copyWith(everyMinutes: m)),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.habitsWindowFrom),
                    subtitle: Text(fmt.time(preset.windowStart ?? LocalTime(9, 0))),
                    onTap: () async {
                      final t = await pickTime(context, initial: preset.windowStart, use24h: use24h);
                      if (t != null) onChanged(preset.copyWith(windowStart: t));
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.habitsWindowTo),
                    subtitle: Text(fmt.time(preset.windowEnd ?? LocalTime(18, 0))),
                    onTap: () async {
                      final t = await pickTime(context, initial: preset.windowEnd, use24h: use24h);
                      if (t != null) onChanged(preset.copyWith(windowEnd: t));
                    },
                  ),
                ),
              ],
            ),
            Text(l.habitsOnlyOn, style: context.text.labelMedium),
            weekdayChips(preset.days, (d) => onChanged(preset.copyWith(days: d)), allowEmpty: true),
          ],
        );
      case SchedulePresetKind.monthlyDay:
        params = Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final d in [for (var i = 1; i <= 31; i++) i, -1])
              ChoiceChip(
                label: Text(d == -1 ? l.habitsLastDay : fmt.number(d)),
                selected: preset.monthDay == d,
                onSelected: (_) => onChanged(preset.copyWith(monthDay: d)),
              ),
          ],
        );
      case SchedulePresetKind.monthlyWeekday:
        params = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: Space.xs,
              children: [
                for (final o in const [1, 2, 3, 4, -1])
                  ChoiceChip(
                    label: Text(l.habitsOrdinal(const {1: 'first', 2: 'second', 3: 'third', 4: 'fourth'}[o] ?? 'last')),
                    selected: preset.ordinal == o,
                    onSelected: (_) => onChanged(preset.copyWith(ordinal: o)),
                  ),
              ],
            ),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              children: [
                for (final w in Weekday.ordered(weekStart))
                  ChoiceChip(
                    label: Text(fmt.weekdayShort(w)),
                    selected: preset.weekday == w,
                    onSelected: (_) => onChanged(preset.copyWith(weekday: w)),
                  ),
              ],
            ),
          ],
        );
      case SchedulePresetKind.afterCompletion:
        String amount(int v) => switch (preset.afterUnit) {
          RecurrenceUnit.week => l.quitOffsetWeeks(v),
          RecurrenceUnit.month => l.quitOffsetMonths(v),
          _ => l.habitsDays(v),
        };
        params = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IntStepper(
              label: l.habitsAfterCompletionDueAfter,
              value: preset.n,
              min: 1,
              max: 365,
              format: amount,
              onChanged: (v) => onChanged(preset.copyWith(n: v)),
            ),
            Wrap(
              spacing: Space.xs,
              children: [
                for (final (unit, label) in [
                  (RecurrenceUnit.day, l.habitsAfterUnitDays),
                  (RecurrenceUnit.week, l.habitsAfterUnitWeeks),
                  (RecurrenceUnit.month, l.habitsAfterUnitMonths),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: preset.afterUnit == unit,
                    onSelected: (_) => onChanged(preset.copyWith(afterUnit: unit)),
                  ),
              ],
            ),
          ],
        );
      case SchedulePresetKind.custom:
        params = OutlinedButton.icon(onPressed: onCustom, icon: const Icon(Icons.tune), label: Text(l.habitsEditCustom));
      default:
        params = const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final k in _kinds)
              ChoiceChip(
                label: Text(l.presetLabel(k)),
                selected: preset.kind == k,
                onSelected: (_) => onChanged(_defaultFor(k)),
              ),
            ChoiceChip(
              label: Text(l.presetLabel(SchedulePresetKind.custom)),
              selected: preset.kind == SchedulePresetKind.custom,
              onSelected: (_) => onCustom(),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        params,
      ],
    );
  }
}

/// Live preview: the `describe()` sentence, the next periods and warnings (T5.1.08).
class _SchedulePreview extends ConsumerWidget {
  const _SchedulePreview({required this.habit});

  final BuildHabit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final fmt = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final recurrence = ref.watch(recurrenceServiceProvider);
    final service = ref.watch(habitPeriodServiceProvider);
    final valid = habit.schedule.validate().isValid;
    String sentence;
    try {
      sentence = recurrence.describe(
        habit.schedule,
        RecurrenceAnchor.allDayOn(habit.startDate, habit.timeZone),
        locale: context.localeName,
        use24h: prefs.use24h,
      );
    } on Object {
      sentence = '';
    }
    final today = ref.watch(habitTodayProvider);
    final from = habit.startDate.isAfter(today) ? habit.startDate : today;
    final upcoming = valid ? service.upcoming(habit, const [], from, count: 10) : const [];
    final perDay = valid ? service.maxSlotsPerDay(habit, const [], from) : 0;
    final warnings = [
      if (!valid) l.habitsErrSchedule,
      if (valid && upcoming.isEmpty) l.habitsWarnNeverDue,
      if (perDay > 48) l.habitsWarnManySlots(perDay),
    ];
    String label(dynamic p) {
      final key = p.key as String;
      if (p.kind == HabitPeriodKind.quota) {
        return key.startsWith('month:') ? fmt.monthYear(p.startDate as LocalDate) : l.habitsWeekOf(fmt.dateMedium(p.startDate as LocalDate));
      }
      if (p.kind == HabitPeriodKind.slot) {
        final t = LocalDateTime.tryParse(key);
        return t == null ? key : '${fmt.dayShort(t.date)} ${fmt.time(t.time)}';
      }
      return fmt.dayShort(p.startDate as LocalDate);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.habitsPreviewTitle, style: context.text.labelLarge),
            if (sentence.isNotEmpty) Text(sentence, style: context.text.bodyLarge),
            const SizedBox(height: Space.xs),
            Text(goalSentenceOf(context, habit.goal), style: context.text.bodyMedium),
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: Space.sm),
              Text(l.habitsPreviewNext, style: context.text.labelMedium),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [for (final p in upcoming) Chip(label: Text(label(p)), visualDensity: VisualDensity.compact)],
              ),
            ],
            for (final w in warnings)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: Space.xs),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: context.appColors.warning),
                    const SizedBox(width: Space.xs),
                    Expanded(child: Text(w, style: context.text.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "15 reps · at least" style goal line of the preview.
String goalSentenceOf(BuildContext context, HabitTarget goal) {
  final l = context.l10n;
  if (!goal.isMeasurable) return l.habitsGoalTypeCheck;
  return l.habitsGoalSentence(l.opLabel(goal.op), formatAmount(context, goal.target ?? 0, goal.unit));
}
