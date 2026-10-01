import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/domain/default_rules.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/rule_validation.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:everslot/features/notifications/presentation/schedule_picker.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Result of the simple editor: rules to create, or a request to open the advanced editor with
/// the first selection as a starting point.
class SimpleEditorOutcome {
  const SimpleEditorOutcome(this.rules, {this.openAdvanced = false});

  final List<({NotificationRuleSpec spec, String? profileId})> rules;
  final bool openAdvanced;
}

/// Quick chips for the target (T7.1.10). Multiple selections create multiple rules at once.
Future<SimpleEditorOutcome?> showSimpleRuleEditor(
  BuildContext context, {
  required NotificationTargetType targetType,
  required NotificationSection section,
  ItemKind itemKind = ItemKind.timed,
}) => showAppSheet<SimpleEditorOutcome>(
  context,
  title: context.l10n.notifEditorTitle,
  builder: (_) => SimpleRuleEditor(targetType: targetType, section: section, itemKind: itemKind),
);

class _Choice {
  _Choice(this.id, this.label, this.build, {this.time});

  final String id;
  final String Function(NotificationLabels labels, LocalTime? time) label;
  final NotificationRuleSpec Function(LocalTime? time) build;

  /// Editable time of the choice (tap the chip's clock to change it).
  LocalTime? time;
}

/// Quick chips per target (tasks: at start / N min before / 1 day before at… / at end; all-day:
/// on the day / 1 day before / last day at…; lists & items: at due / follow-up / every day at…;
/// habits: at slot / every day / if not done by / streak at risk; quit: every day / milestones),
/// plus *At a time…* (absolute), *Repeat…* (recurrence picker) and *Custom…* (any offset from
/// 1 minute to 30 days before or after any available anchor, or N days before/after at a time).
class SimpleRuleEditor extends ConsumerStatefulWidget {
  const SimpleRuleEditor({required this.targetType, required this.section, this.itemKind = ItemKind.timed, super.key});

  final NotificationTargetType targetType;
  final NotificationSection section;
  final ItemKind itemKind;

  @override
  ConsumerState<SimpleRuleEditor> createState() => _SimpleRuleEditorState();
}

enum _Unit { minutes, hours, days, weeks }

class _SimpleRuleEditorState extends ConsumerState<SimpleRuleEditor> {
  late final List<_Choice> _choices = _choicesFor();
  final Set<String> _selected = {};

  /// *At a time…* (absolute date-time) and *Repeat…* (schedule) selections.
  LocalDateTime? _absolute;
  Map<String, Object?>? _schedule;

  bool _custom = false;
  bool _dayForm = false;
  final _amount = TextEditingController(text: '20');
  _Unit _unit = _Unit.minutes;
  bool _before = true;
  LocalTime _dayTime = LocalTime(20, 0);
  late TriggerAnchor _anchor = _anchors.first;

  String? _profileId;
  bool _sound = true;
  bool _system = true;
  bool _inbox = true;

  List<TriggerAnchor> get _anchors => anchorsFor(widget.targetType, kind: widget.itemKind).toList();

  bool get _isDigest =>
      widget.targetType == NotificationTargetType.digest || widget.targetType == NotificationTargetType.custom;

  /// Standalone reminders (absolute, repeating) make sense for everything but tasks and digests.
  bool get _offersStandalone => !_isDigest && widget.targetType != NotificationTargetType.task;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  static NotificationRuleSpec _rel(TriggerAnchor a, int offset) => NotificationRuleSpec(
    trigger: RelativeTrigger(anchor: a, offsetMinutes: offset),
  );

  static NotificationRuleSpec _day(TriggerAnchor a, int dayOffset, LocalTime t) => NotificationRuleSpec(
    trigger: RelativeTrigger(anchor: a, dayOffset: dayOffset, atTime: t),
  );

  static NotificationRuleSpec _daily(LocalTime t) => NotificationRuleSpec(
    trigger: ScheduleTrigger(
      recurrence: {
        'v': 1,
        'type': 'fixed',
        'freq': 'daily',
        'interval': 1,
        'times': [t.toIso()],
      },
    ),
  );

  String _every(NotificationLabels lb, LocalTime t) =>
      '${lb.l.notifChipEvery.replaceAll('…', '').trim()} ${lb.time(t)}';

  List<_Choice> _choicesFor() {
    final l = context.l10n;
    final dayTime = ref.read(notificationSettingsProvider).effectiveDateOnlyTime;
    final nine = LocalTime(9, 0);
    final evening = LocalTime(20, 0);
    switch (widget.targetType) {
      case NotificationTargetType.task when widget.itemKind == ItemKind.timed:
        return [
          _Choice('start', (_, _) => l.notifChipAtStart, (_) => _rel(TriggerAnchor.start, 0)),
          for (final m in const [5, 10, 15, 30, 60])
            _Choice('b$m', (_, _) => l.notifChipBefore(m), (_) => _rel(TriggerAnchor.start, -m)),
          _Choice(
            'day',
            (lb, t) => l.notifChipDayBeforeAt(lb.time(t!)),
            (t) => _day(TriggerAnchor.start, -1, t!),
            time: evening,
          ),
          _Choice('end', (_, _) => l.notifChipAtEnd, (_) => _rel(TriggerAnchor.end, 0)),
        ];
      case NotificationTargetType.task:
        return [
          _Choice(
            'onday',
            (lb, t) => l.notifChipOnDayAt(lb.time(t!)),
            (t) => _day(TriggerAnchor.start, 0, t!),
            time: dayTime,
          ),
          _Choice(
            'day',
            (lb, t) => l.notifChipDayBeforeAt(lb.time(t!)),
            (t) => _day(TriggerAnchor.start, -1, t!),
            time: evening,
          ),
          if (widget.itemKind == ItemKind.allDay)
            _Choice(
              'lastday',
              (lb, t) => l.notifChipLastDayAt(lb.time(t!)),
              (t) => _day(TriggerAnchor.end, 0, t!),
              time: LocalTime(18, 0),
            ),
        ];
      case NotificationTargetType.checklist || NotificationTargetType.checklistItem:
        return [
          _Choice('due', (_, _) => l.notifChipAtDue, (_) => _rel(TriggerAnchor.due, 0)),
          if (widget.targetType == NotificationTargetType.checklistItem)
            _Choice('followup', (_, _) => l.notifChipAtFollowUp, (_) => _rel(TriggerAnchor.followUp, 0)),
          _Choice(
            'daybefore',
            (lb, t) => l.notifChipDayBeforeAt(lb.time(t!)),
            (t) => _day(TriggerAnchor.due, -1, t!),
            time: evening,
          ),
          _Choice('every', (lb, t) => _every(lb, t!), (t) => _daily(t!), time: nine),
        ];
      case NotificationTargetType.habit when widget.section == NotificationSection.quit:
        return [
          _Choice('every', (lb, t) => _every(lb, t!), (t) => _daily(t!), time: nine),
          _Choice(
            'milestones',
            (_, _) => l.notifChipMilestones,
            (_) => const NotificationRuleSpec(trigger: MilestoneTrigger(metric: 'clean_days')),
          ),
        ];
      case NotificationTargetType.habit:
        return [
          _Choice('slot', (_, _) => l.notifChipAtSlot, (_) => _rel(TriggerAnchor.slot, 0)),
          _Choice('every', (lb, t) => _every(lb, t!), (t) => _daily(t!), time: nine),
          _Choice(
            'notdone',
            (lb, t) => '${l.notifChipIfNotDoneBy.replaceAll('…', '').trim()} ${lb.time(t!)}',
            (t) => NotificationRuleSpec(
              trigger: NotDoneByTrigger(anchor: 'time', atTime: t),
            ),
            time: LocalTime(21, 0),
          ),
          _Choice(
            'streak',
            (_, _) => l.notifChipStreakRisk,
            (_) => NotificationRuleSpec(trigger: StreakRiskTrigger(atTime: LocalTime(21, 0), minStreak: 3)),
          ),
        ];
      case NotificationTargetType.digest || NotificationTargetType.custom:
        return [
          for (final e in DefaultRules.digestDefaultTimes.entries)
            _Choice(
              e.key,
              (lb, t) => '${lb.digestTitle(e.key)} ${lb.time(t!)}',
              (t) => DefaultRules.digestSpec(e.key, t!),
              time: e.value,
            ),
        ];
    }
  }

  NotificationRuleSpec? _customSpec() {
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null || amount < 0) return null;
    if (_dayForm) return _day(_anchor, _before ? -amount : amount, _dayTime);
    final minutes =
        amount *
        switch (_unit) {
          _Unit.minutes => 1,
          _Unit.hours => 60,
          _Unit.days => 1440,
          _Unit.weeks => 10080,
        };
    return _rel(_anchor, _before ? -minutes : minutes);
  }

  NotificationRuleSpec _withDelivery(NotificationRuleSpec spec) {
    var d = spec.delivery;
    if (!_sound) d = d.copyWith(sound: 'none');
    if (!_system) d = d.copyWith(system: false);
    if (!_inbox) d = d.copyWith(inbox: false);
    return spec.copyWith(delivery: d);
  }

  List<NotificationRuleSpec> get _specs => [
    for (final c in _choices)
      if (_selected.contains(c.id)) _withDelivery(c.build(c.time)),
    if (_absolute != null) _withDelivery(NotificationRuleSpec(trigger: AbsoluteTrigger(at: _absolute!))),
    if (_schedule != null) _withDelivery(NotificationRuleSpec(trigger: ScheduleTrigger(recurrence: _schedule!))),
    if (_custom && _customSpec() != null) _withDelivery(_customSpec()!),
  ];

  bool get _use24h => MediaQuery.alwaysUse24HourFormatOf(context);

  Future<void> _pickAbsolute() async {
    final now = ref.read(clockProvider).nowUtc();
    final local = ref.read(zoneResolverProvider).toLocal(now, ref.read(deviceZoneProvider));
    final initial = _absolute ?? LocalDateTime(local.date.plusDays(1), LocalTime(9, 0));
    final date = await pickDate(context, initial: initial.date, first: local.date);
    if (date == null || !mounted) return;
    final time = await pickTime(context, initial: initial.time, use24h: _use24h);
    if (time == null || !mounted) return;
    setState(() => _absolute = LocalDateTime(date, time));
  }

  Future<void> _pickSchedule() async {
    final schedule = await pickReminderSchedule(context, ref, initial: _schedule);
    if (schedule != null && mounted) setState(() => _schedule = schedule);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final profiles = [
      for (final p in ref.watch(notificationProfilesProvider).value ?? const <NotificationProfile>[])
        if (!p.hidden) p,
    ];
    final specs = _specs;
    final issues = {
      for (final s in specs)
        for (final i in NotificationRuleValidator.validate(s, targetType: widget.targetType, itemKind: widget.itemKind))
          if (i.isError) labels.issue(i),
    };
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final c in _choices)
                FilterChip(
                  label: Text(c.label(labels, c.time)),
                  selected: _selected.contains(c.id),
                  onSelected: (v) => setState(() => v ? _selected.add(c.id) : _selected.remove(c.id)),
                  deleteIcon: c.time == null ? null : const Icon(Icons.schedule, size: 18),
                  deleteButtonTooltipMessage: l.notifChipChangeTime,
                  onDeleted: c.time == null
                      ? null
                      : () async {
                          final t = await pickTime(context, initial: c.time, use24h: _use24h);
                          if (t != null && mounted) {
                            setState(() {
                              c.time = t;
                              _selected.add(c.id);
                            });
                          }
                        },
                ),
              if (_offersStandalone) ...[
                FilterChip(
                  label: Text(_absolute == null ? l.notifChipAtTime : labels.trigger(AbsoluteTrigger(at: _absolute!))),
                  selected: _absolute != null,
                  onSelected: (v) => v ? _pickAbsolute() : setState(() => _absolute = null),
                ),
                FilterChip(
                  label: Text(
                    _schedule == null ? l.notifChipRepeat : labels.trigger(ScheduleTrigger(recurrence: _schedule!)),
                  ),
                  selected: _schedule != null,
                  onSelected: (v) => v ? _pickSchedule() : setState(() => _schedule = null),
                ),
              ],
              if (!_isDigest)
                FilterChip(
                  label: Text(l.notifChipCustom),
                  selected: _custom,
                  onSelected: (v) => setState(() => _custom = v),
                ),
            ],
          ),
          if (_custom) ..._customFields(context, labels),
          const SizedBox(height: Space.lg),
          DropdownButtonFormField<String?>(
            initialValue: _profileId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.notifProfile),
            onChanged: (v) => setState(() => _profileId = v),
            items: [
              DropdownMenuItem<String?>(child: Text(l.notifProfileNone)),
              for (final p in profiles) DropdownMenuItem(value: p.id, child: Text(labels.profileName(p))),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(l.notifSound),
            value: _sound,
            onChanged: (v) => setState(() => _sound = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(l.notifSystemNotification),
            value: _system,
            onChanged: (v) => setState(() => _system = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(l.notifInboxToggle),
            value: _inbox,
            onChanged: (v) => setState(() => _inbox = v),
          ),
          for (final issue in issues)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: Space.xs),
              child: Text(issue, style: context.text.bodySmall?.copyWith(color: context.colors.error)),
            ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  SimpleEditorOutcome([
                    (spec: specs.isEmpty ? _rel(_anchors.first, 0) : specs.first, profileId: _profileId),
                  ], openAdvanced: true),
                ),
                child: Text(l.notifAdvanced),
              ),
              const Spacer(),
              Flexible(
                child: FilledButton(
                  onPressed: specs.isEmpty || issues.isNotEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          SimpleEditorOutcome([for (final s in specs) (spec: s, profileId: _profileId)]),
                        ),
                  child: Text(l.notifCreateCount(specs.length), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Custom offset: amount + unit + before/after + anchor, or "N days before/after at HH:MM".
  List<Widget> _customFields(BuildContext context, NotificationLabels labels) {
    final l = labels.l;
    return [
      SwitchListTile(
        contentPadding: EdgeInsetsDirectional.zero,
        title: Text(l.notifFieldDayForm),
        value: _dayForm,
        onChanged: (v) => setState(() {
          _dayForm = v;
          _amount.text = v ? '1' : '20';
        }),
      ),
      Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: TextField(
              key: const ValueKey('notif-custom-amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: _dayForm ? l.notifUnitDays : l.notifOffsetAmount),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (!_dayForm)
            DropdownButton<_Unit>(
              value: _unit,
              onChanged: (u) => setState(() => _unit = u ?? _unit),
              items: [
                DropdownMenuItem(value: _Unit.minutes, child: Text(l.notifUnitMinutes)),
                DropdownMenuItem(value: _Unit.hours, child: Text(l.notifUnitHours)),
                DropdownMenuItem(value: _Unit.days, child: Text(l.notifUnitDays)),
                DropdownMenuItem(value: _Unit.weeks, child: Text(l.notifUnitWeeks)),
              ],
            ),
          DropdownButton<bool>(
            value: _before,
            onChanged: (v) => setState(() => _before = v ?? _before),
            items: [
              DropdownMenuItem(value: true, child: Text(l.notifBefore)),
              DropdownMenuItem(value: false, child: Text(l.notifAfter)),
            ],
          ),
          DropdownButton<TriggerAnchor>(
            value: _anchor,
            onChanged: (a) => setState(() => _anchor = a ?? _anchor),
            items: [for (final a in _anchors) DropdownMenuItem(value: a, child: Text(labels.anchor(a)))],
          ),
          if (_dayForm)
            ActionChip(
              avatar: const Icon(Icons.schedule, size: 18),
              label: Text(labels.time(_dayTime)),
              tooltip: l.notifChipChangeTime,
              onPressed: () async {
                final t = await pickTime(context, initial: _dayTime, use24h: _use24h);
                if (t != null && mounted) setState(() => _dayTime = t);
              },
            ),
        ],
      ),
    ];
  }
}
