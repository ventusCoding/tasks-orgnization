import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/rule_preview.dart';
import 'package:everslot/features/notifications/domain/default_rules.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/rule_validation.dart';
import 'package:everslot/features/notifications/domain/template_engine.dart';
import 'package:everslot/features/notifications/presentation/delivery_fields.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:everslot/features/notifications/presentation/rule_preview_list.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Result of the advanced editor.
typedef RuleEdit = ({NotificationRuleSpec spec, String? profileId, String? name});

/// Opens the advanced editor (T7.1.12). Saving without edits returns the original spec object
/// (unknown keys and key order survive).
Future<RuleEdit?> showAdvancedRuleEditor(
  BuildContext context, {
  required NotificationTargetType targetType,
  required NotificationSection section,
  required NotificationRuleSpec spec,
  String? profileId,
  String? name,
  ItemKind itemKind = ItemKind.timed,
  NotificationTarget? previewTarget,
  bool showItemKind = false,
}) => Navigator.of(context).push<RuleEdit>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => AdvancedRuleEditorScreen(
      targetType: targetType,
      section: section,
      spec: spec,
      profileId: profileId,
      name: name,
      itemKind: itemKind,
      previewTarget: previewTarget,
      showItemKind: showItemKind,
    ),
  ),
);

class AdvancedRuleEditorScreen extends ConsumerStatefulWidget {
  const AdvancedRuleEditorScreen({
    required this.targetType,
    required this.section,
    required this.spec,
    this.profileId,
    this.name,
    this.itemKind = ItemKind.timed,
    this.previewTarget,
    this.showItemKind = false,
    super.key,
  });

  final NotificationTargetType targetType;
  final NotificationSection section;
  final NotificationRuleSpec spec;
  final String? profileId;
  final String? name;
  final ItemKind itemKind;
  final NotificationTarget? previewTarget;
  final bool showItemKind;

  @override
  ConsumerState<AdvancedRuleEditorScreen> createState() => _AdvancedRuleEditorScreenState();
}

class _AdvancedRuleEditorScreenState extends ConsumerState<AdvancedRuleEditorScreen> {
  late NotificationRuleSpec _spec = widget.spec;
  late String? _profileId = widget.profileId;
  late final _name = TextEditingController(text: widget.name ?? '');
  late final _title = TextEditingController(text: widget.spec.content.title ?? '');
  late final _body = TextEditingController(text: widget.spec.content.body ?? '');
  TextEditingController? _focusedTemplate;
  bool _dirty = false;

  static const _statuses = [
    'scheduled',
    'in_progress',
    'todo',
    'ongoing',
    'waiting',
    'blocked',
    'completed',
    'done',
    'skipped',
  ];

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _update(NotificationRuleSpec next) => setState(() {
    _spec = next;
    _dirty = true;
  });

  NotificationTarget get _target =>
      widget.previewTarget ??
      ref.read(rulePreviewServiceProvider).sampleTarget(widget.targetType, widget.section, kind: widget.itemKind);

  NotificationRule get _rule => NotificationRule(
    id: 'editor',
    targetType: RuleTargetType.forTarget(widget.targetType) ?? RuleTargetType.section,
    targetId: 'editor',
    section: widget.section,
    profileId: _profileId,
    spec: _spec,
  );

  Future<void> _save() async {
    final l = context.l10n;
    if (!_dirty && _profileId == widget.profileId && _name.text == (widget.name ?? '')) {
      Navigator.pop(context, (spec: widget.spec, profileId: _profileId, name: widget.name));
      return;
    }
    final noise = await ref.read(rulePreviewServiceProvider).noise(_rule, _target);
    if (!mounted) return;
    if (noise.level == NoiseLevel.blocked) {
      showInfoSnackBar(context, l.notifNoiseBlocked);
      return;
    }
    if (noise.level == NoiseLevel.confirm) {
      final ok = await confirmDialog(context, title: l.notifNoiseConfirm(noise.firesPerDay.round()));
      if (!ok || !mounted) return;
    }
    final name = _name.text.trim();
    Navigator.pop(context, (spec: _spec, profileId: _profileId, name: name.isEmpty ? null : name));
  }

  void _insertVariable(String name) {
    final c = _focusedTemplate ?? _body;
    final text = c.text;
    final sel = c.selection;
    final at = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    c.value = TextEditingValue(
      text: text.replaceRange(at, end, '{$name}'),
      selection: TextSelection.collapsed(offset: at + name.length + 2),
    );
    _onContentChanged();
  }

  void _onContentChanged() {
    final title = _title.text;
    final body = _body.text;
    _update(
      _spec.copyWith(
        content: ContentSpec(
          title: title.isEmpty ? null : title,
          body: body.isEmpty ? null : body,
          variants: _spec.content.variants,
          raw: _spec.content.raw,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final profiles = [
      for (final p in ref.watch(notificationProfilesProvider).value ?? const <NotificationProfile>[])
        if (!p.hidden) p,
    ];
    final issues = NotificationRuleValidator.validate(
      _spec,
      targetType: widget.targetType,
      itemKind: widget.itemKind,
      acceptExtraActions: true,
    );
    final errors = [
      for (final i in issues)
        if (i.isError) i,
    ];
    // Warnings (noise, Doze, extra actions) inform but never block saving (T7.1.04).
    final warnings = [
      for (final i in issues)
        if (!i.isError) i,
    ];
    final profileName = profiles.where((p) => p.id == _profileId).map(labels.profileName).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifAdvancedTitle),
        actions: [TextButton(onPressed: errors.isEmpty ? () => unawaited(_save()) : null, child: Text(l.actionSave))],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxxl),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l.notifProfileName),
                ),
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
              ],
            ),
          ),
          for (final e in errors)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
              child: Text(labels.issue(e), style: context.text.bodySmall?.copyWith(color: context.colors.error)),
            ),
          for (final w in warnings)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
              child: Text(
                labels.issue(w),
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(l.notifTrigger),
            subtitle: Text(labels.trigger(_spec.trigger)),
            childrenPadding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.md),
            children: [
              _TriggerEditor(spec: _spec, targetType: widget.targetType, itemKind: widget.itemKind, onChanged: _update),
            ],
          ),
          ExpansionTile(
            title: Text(l.notifRepeat),
            childrenPadding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.md),
            children: [_RepeatEditor(spec: _spec, onChanged: _update)],
          ),
          ExpansionTile(
            title: Text(l.notifConditions),
            childrenPadding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.md),
            children: [
              _ConditionsEditor(
                conditions: _spec.conditions,
                statuses: _statuses,
                showItemKind: widget.showItemKind,
                onChanged: (c) => _update(_spec.copyWith(conditions: c)),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(l.notifDelivery),
            childrenPadding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.md),
            children: [
              DeliveryFieldsEditor(
                value: _spec.delivery,
                inheritedFrom: profileName ?? builtinFallbackName(labels),
                onChanged: (d) => _update(_spec.copyWith(delivery: d)),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(l.notifContent),
            childrenPadding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.md),
            children: [
              Focus(
                onFocusChange: (f) => f ? _focusedTemplate = _title : null,
                child: TextField(
                  controller: _title,
                  decoration: InputDecoration(labelText: l.notifContentTitle),
                  onChanged: (_) => _onContentChanged(),
                ),
              ),
              Focus(
                onFocusChange: (f) => f ? _focusedTemplate = _body : null,
                child: TextField(
                  controller: _body,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(labelText: l.notifContentBody),
                  onChanged: (_) => _onContentChanged(),
                ),
              ),
              const SizedBox(height: Space.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(l.notifVariables, style: context.text.labelLarge),
              ),
              Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  for (final v in TemplateVariables.forTarget(widget.targetType))
                    ActionChip(label: Text('{${v.name}}'), onPressed: () => _insertVariable(v.name)),
                ],
              ),
              const SizedBox(height: Space.md),
              _ContentPreview(spec: _spec, targetType: widget.targetType),
            ],
          ),
          const Divider(),
          SectionHeader(l.notifNextFirings),
          RulePreviewList(rules: [_rule], targets: [_target], showNoise: true),
        ],
      ),
    );
  }

  String builtinFallbackName(NotificationLabels labels) => labels.l.notifProfileStandard;
}

// ------------------------------------------------------------------------------------ trigger --

class _TriggerEditor extends StatelessWidget {
  const _TriggerEditor({required this.spec, required this.targetType, required this.itemKind, required this.onChanged});

  final NotificationRuleSpec spec;
  final NotificationTargetType targetType;
  final ItemKind itemKind;
  final ValueChanged<NotificationRuleSpec> onChanged;

  NotificationTrigger _defaultFor(TriggerType type) => switch (type) {
    TriggerType.relative => RelativeTrigger(anchor: anchorsFor(targetType, kind: itemKind).first, offsetMinutes: 0),
    TriggerType.absolute => AbsoluteTrigger(at: LocalDateTime.of(2026, 1, 1, 9)),
    TriggerType.schedule => const ScheduleTrigger(
      recurrence: {
        'v': 1,
        'type': 'fixed',
        'freq': 'daily',
        'interval': 1,
        'times': ['09:00'],
      },
    ),
    TriggerType.notDoneBy => NotDoneByTrigger(anchor: 'time', atTime: LocalTime(21, 0)),
    TriggerType.statusAge => const StatusAgeTrigger(statuses: ['waiting', 'blocked'], afterMinutes: 2880),
    // No delay = the planner's missed grace (T7.5.03).
    TriggerType.overdue => const OverdueTrigger(),
    TriggerType.streakRisk => StreakRiskTrigger(atTime: LocalTime(21, 0), minStreak: 3),
    TriggerType.quotaBehind => QuotaBehindTrigger(atTime: LocalTime(20, 0)),
    TriggerType.milestone => const MilestoneTrigger(metric: 'clean_days'),
    TriggerType.inactivity => const InactivityTrigger(afterDays: 3),
    TriggerType.digest => DefaultRules.digestSpec('daily_agenda', LocalTime(7, 7)).trigger,
    TriggerType.statusChange => const StatusChangeTrigger(to: 'blocked'),
    TriggerType.childrenComplete => const ChildrenCompleteTrigger(),
    TriggerType.childOverdue => const ChildOverdueTrigger(),
    TriggerType.stale => const StaleTrigger(afterDays: 7),
    TriggerType.upNext => const UpNextTrigger(),
    TriggerType.timerEnd => const TimerEndTrigger(),
  };

  void _set(NotificationTrigger t) => onChanged(spec.copyWith(trigger: t));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final trigger = spec.trigger;
    Future<void> pickAt(LocalTime? initial, void Function(LocalTime t) apply) async {
      final t = await pickTime(context, initial: initial, use24h: use24h);
      if (t != null) apply(t);
    }

    Widget timeTile(String label, LocalTime? value, void Function(LocalTime t) apply) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value == null ? '—' : labels.time(value)),
      onTap: () => unawaited(pickAt(value, apply)),
    );

    Widget intField(String label, int value, void Function(int v) apply, {bool signed = false}) => TextFormField(
      initialValue: '$value',
      keyboardType: TextInputType.numberWithOptions(signed: signed),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(signed ? '[-0-9]' : '[0-9]'))],
      decoration: InputDecoration(labelText: label),
      onChanged: (text) {
        final v = int.tryParse(text);
        if (v != null) apply(v);
      },
    );

    final params = switch (trigger) {
      RelativeTrigger(:final anchor, :final offsetMinutes, :final dayOffset, :final atTime, :final usesDayForm) => [
        DropdownButtonFormField<TriggerAnchor>(
          initialValue: anchor,
          decoration: InputDecoration(labelText: l.notifAnchorStart),
          onChanged: (a) => _set(
            RelativeTrigger(anchor: a ?? anchor, offsetMinutes: offsetMinutes, dayOffset: dayOffset, atTime: atTime),
          ),
          items: [for (final a in TriggerAnchor.values) DropdownMenuItem(value: a, child: Text(labels.anchor(a)))],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.notifFieldDayForm),
          value: usesDayForm,
          onChanged: (v) => _set(
            v
                ? RelativeTrigger(anchor: anchor, dayOffset: -1, atTime: LocalTime(20, 0))
                : RelativeTrigger(anchor: anchor, offsetMinutes: 0),
          ),
        ),
        if (usesDayForm) ...[
          intField(
            l.notifFieldDayOffset,
            dayOffset ?? 0,
            (v) => _set(RelativeTrigger(anchor: anchor, dayOffset: v, atTime: atTime)),
            signed: true,
          ),
          timeTile(
            l.notifFieldAtTime,
            atTime,
            (t) => _set(RelativeTrigger(anchor: anchor, dayOffset: dayOffset, atTime: t)),
          ),
        ] else
          intField(
            l.notifFieldOffset,
            offsetMinutes ?? 0,
            (v) => _set(RelativeTrigger(anchor: anchor, offsetMinutes: v)),
            signed: true,
          ),
      ],
      AbsoluteTrigger(:final at, :final timeZone) => [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.notifFieldDateTime),
          trailing: Text(labels.format.dateTime(at)),
          onTap: () async {
            final d = await pickDate(context, initial: at.date);
            if (d == null || !context.mounted) return;
            final t = await pickTime(context, initial: at.time, use24h: use24h);
            _set(AbsoluteTrigger(at: LocalDateTime(d, t ?? at.time), timeZone: timeZone));
          },
        ),
      ],
      ScheduleTrigger(:final recurrence) => [
        _ScheduleFields(
          recurrence: recurrence,
          onChanged: (r) => _set(ScheduleTrigger(recurrence: r)),
        ),
      ],
      NotDoneByTrigger(anchor: final a, :final offsetMinutes, :final atTime) => [
        DropdownButtonFormField<String>(
          initialValue: a,
          decoration: InputDecoration(labelText: l.notifAnchorEnd),
          onChanged: (v) =>
              _set(NotDoneByTrigger(anchor: v ?? a, offsetMinutes: offsetMinutes, atTime: atTime ?? LocalTime(21, 0))),
          items: [
            DropdownMenuItem(value: 'time', child: Text(l.notifFieldAtTime)),
            DropdownMenuItem(value: 'period_end', child: Text(l.notifAnchorPeriodEnd)),
            DropdownMenuItem(value: 'end', child: Text(l.notifAnchorEnd)),
          ],
        ),
        if (a == 'time')
          timeTile(
            l.notifFieldAtTime,
            atTime,
            (t) => _set(NotDoneByTrigger(anchor: a, offsetMinutes: offsetMinutes, atTime: t)),
          )
        else
          intField(
            l.notifFieldOffset,
            offsetMinutes ?? 0,
            (v) => _set(NotDoneByTrigger(anchor: a, offsetMinutes: v)),
            signed: true,
          ),
      ],
      StatusAgeTrigger(:final statuses, :final afterMinutes) => [
        Wrap(
          spacing: Space.xs,
          children: [
            for (final s in const ['waiting', 'blocked', 'ongoing', 'todo'])
              FilterChip(
                label: Text(labels.status(s)),
                selected: statuses.contains(s),
                onSelected: (v) => _set(
                  StatusAgeTrigger(
                    statuses: v
                        ? [...statuses, s]
                        : [
                            for (final x in statuses)
                              if (x != s) x,
                          ],
                    afterMinutes: afterMinutes,
                  ),
                ),
              ),
          ],
        ),
        intField(
          l.notifFieldAfterMinutes,
          afterMinutes,
          (v) => _set(StatusAgeTrigger(statuses: statuses, afterMinutes: v)),
        ),
      ],
      OverdueTrigger(:final effectiveAfter) => [
        intField(l.notifFieldAfterMinutes, effectiveAfter, (v) => _set(OverdueTrigger(afterMinutes: v))),
      ],
      StreakRiskTrigger(:final atTime, :final effectiveMinStreak) => [
        timeTile(l.notifFieldAtTime, atTime, (t) => _set(StreakRiskTrigger(atTime: t, minStreak: effectiveMinStreak))),
        intField(
          l.notifFieldMinStreak,
          effectiveMinStreak,
          (v) => _set(StreakRiskTrigger(atTime: atTime, minStreak: v)),
        ),
      ],
      QuotaBehindTrigger(:final atTime) => [
        timeTile(l.notifFieldAtTime, atTime, (t) => _set(QuotaBehindTrigger(atTime: t))),
      ],
      MilestoneTrigger(:final metric, :final thresholds) => [
        DropdownButtonFormField<String>(
          initialValue: metric,
          decoration: InputDecoration(labelText: l.notifFieldMetric),
          onChanged: (m) => _set(MilestoneTrigger(metric: m ?? metric, thresholds: thresholds)),
          items: [
            DropdownMenuItem(value: 'clean_days', child: Text(l.notifMetricCleanDays)),
            DropdownMenuItem(value: 'streak', child: Text(l.notifMetricStreak)),
            DropdownMenuItem(value: 'total_value', child: Text(l.notifMetricTotal)),
            DropdownMenuItem(value: 'money_saved', child: Text(l.notifMetricMoney)),
            DropdownMenuItem(value: 'units_avoided', child: Text(l.notifMetricUnits)),
          ],
        ),
        TextFormField(
          initialValue: thresholds?.join(', ') ?? '',
          decoration: InputDecoration(labelText: l.notifFieldThresholds),
          onChanged: (text) {
            final values = [for (final p in text.split(',')) ?num.tryParse(p.trim())];
            _set(MilestoneTrigger(metric: metric, thresholds: text.trim().isEmpty ? null : values));
          },
        ),
      ],
      InactivityTrigger(:final afterDays, :final atTime) => [
        intField(l.notifFieldAfterDays, afterDays, (v) => _set(InactivityTrigger(afterDays: v, atTime: atTime))),
        timeTile(l.notifFieldAtTime, atTime, (t) => _set(InactivityTrigger(afterDays: afterDays, atTime: t))),
      ],
      StaleTrigger(:final afterDays, :final atTime) => [
        intField(l.notifFieldAfterDays, afterDays, (v) => _set(StaleTrigger(afterDays: v, atTime: atTime))),
        timeTile(l.notifFieldAtTime, atTime, (t) => _set(StaleTrigger(afterDays: afterDays, atTime: t))),
      ],
      DigestTrigger(:final kind, :final schedule) => [
        DropdownButtonFormField<String>(
          initialValue: kind,
          decoration: InputDecoration(labelText: l.notifFieldDigestKind),
          onChanged: (k) => _set(DigestTrigger(kind: k ?? kind, schedule: schedule)),
          items: [for (final k in DigestTrigger.kinds) DropdownMenuItem(value: k, child: Text(labels.digestTitle(k)))],
        ),
        _ScheduleFields(
          recurrence: schedule,
          onChanged: (r) => _set(DigestTrigger(kind: kind, schedule: r)),
        ),
      ],
      StatusChangeTrigger(:final from, :final to, :final atTime) => [
        TextFormField(
          initialValue: to,
          decoration: InputDecoration(labelText: l.notifFieldToStatus),
          onChanged: (v) => _set(StatusChangeTrigger(from: from, to: v.trim(), atTime: atTime)),
        ),
        timeTile(l.notifFieldAtTime, atTime, (t) => _set(StatusChangeTrigger(from: from, to: to, atTime: t))),
      ],
      UpNextTrigger(:final beforeMinutes) => [
        intField(
          l.notifFieldBeforeNextMinutes,
          beforeMinutes ?? 0,
          (v) => _set(UpNextTrigger(beforeMinutes: v <= 0 ? null : v)),
        ),
      ],
      ChildrenCompleteTrigger() || ChildOverdueTrigger() || TimerEndTrigger() || UnknownTrigger() => const <Widget>[],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<TriggerType?>(
          initialValue: trigger.type,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.notifTrigger),
          onChanged: (t) {
            if (t != null && t != trigger.type) _set(_defaultFor(t));
          },
          items: [
            for (final t in TriggerType.values)
              if (t != TriggerType.digest || targetType == NotificationTargetType.digest || trigger is DigestTrigger)
                DropdownMenuItem(value: t, child: Text(labels.triggerType(t))),
          ],
        ),
        ...params,
      ],
    );
  }
}

/// Minimal recurrence builder (daily / weekly weekdays / monthly day + times) for schedule and
/// digest triggers; the full §8.1 builder lives in [2.1].
class _ScheduleFields extends StatelessWidget {
  const _ScheduleFields({required this.recurrence, required this.onChanged});

  final Map<String, Object?> recurrence;
  final ValueChanged<Map<String, Object?>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final freq = recurrence['freq'] as String? ?? 'daily';
    final times = [for (final t in (recurrence['times'] as List?) ?? const <Object?>[]) ?LocalTime.tryParse('$t')];
    // §8.1 form `{"day": "MO"}` (the short form `"MO"` is read too).
    final weekdays = {
      for (final d in (recurrence['byWeekday'] as List?) ?? const <Object?>[])
        if (d is String)
          Weekday.fromCode(d).iso
        else if (d is Map && d['day'] is String)
          Weekday.fromCode(d['day'] as String).iso,
    };
    Map<String, Object?> with_(Map<String, Object?> patch) {
      final next = {...recurrence, ...patch};
      next.removeWhere((_, v) => v == null);
      return next;
    }

    // Schedules built elsewhere (recurrence builder: hourly, minutely, windows…) are kept as is.
    if (!const ['daily', 'weekly', 'monthly'].contains(freq)) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.event_repeat),
        title: Text(l.notifSumSchedule),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: freq,
          onChanged: (f) => onChanged(
            with_({
              'freq': f,
              'byWeekday': f == 'weekly'
                  ? [
                      {'day': 'MO'},
                    ]
                  : null,
              'byMonthDay': f == 'monthly' ? [1] : null,
            }),
          ),
          decoration: InputDecoration(labelText: l.notifFieldRepeats),
          items: [
            DropdownMenuItem(value: 'daily', child: Text(l.notifFreqDaily)),
            DropdownMenuItem(value: 'weekly', child: Text(l.notifFreqWeekly)),
            DropdownMenuItem(value: 'monthly', child: Text(l.notifFreqMonthly)),
          ],
        ),
        if (freq == 'weekly')
          WeekdayChips(
            selected: weekdays,
            onChanged: (days) => onChanged(
              with_({
                'byWeekday': [
                  for (final d in days.toList()..sort()) {'day': Weekday.fromIso(d).code},
                ],
              }),
            ),
          ),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final t in times)
              InputChip(
                label: Text(labels.time(t)),
                onDeleted: times.length > 1
                    ? () => onChanged(
                        with_({
                          'times': [
                            for (final x in times)
                              if (x != t) x.toIso(),
                          ],
                        }),
                      )
                    : null,
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(l.notifFieldAtTime),
              onPressed: () async {
                final t = await pickTime(
                  context,
                  initial: LocalTime(9, 0),
                  use24h: MediaQuery.alwaysUse24HourFormatOf(context),
                );
                if (t == null) return;
                onChanged(
                  with_({
                    'times': [
                      ...{
                        for (final x in [...times, t]) x.toIso(),
                      },
                    ]..sort(),
                  }),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------------------------ repeat --

class _RepeatEditor extends StatelessWidget {
  const _RepeatEditor({required this.spec, required this.onChanged});

  final NotificationRuleSpec spec;
  final ValueChanged<NotificationRuleSpec> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repeat = spec.repeat;
    final mode = repeat != null ? 2 : (spec.repeatDisabled ? 1 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 0, label: Text(l.notifInherit)),
            ButtonSegment(value: 1, label: Text(l.notifDisable)),
            ButtonSegment(value: 2, label: Text(l.notifModeCustom)),
          ],
          selected: {mode},
          onSelectionChanged: (s) => onChanged(switch (s.first) {
            0 => spec.copyWith(clearRepeat: true),
            1 => spec.copyWith(clearRepeat: true, repeatDisabled: true),
            _ => spec.copyWith(repeat: const RepeatSpec(everyMinutes: 5, maxTimes: 5), repeatDisabled: false),
          }),
        ),
        if (repeat != null) ...[
          TextFormField(
            initialValue: '${repeat.everyMinutes}',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l.notifFieldEveryMinutes),
            onChanged: (v) =>
                onChanged(spec.copyWith(repeat: repeat.copyWith(everyMinutes: int.tryParse(v) ?? repeat.everyMinutes))),
          ),
          TextFormField(
            initialValue: '${repeat.maxTimes}',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l.notifFieldMaxTimes),
            onChanged: (v) =>
                onChanged(spec.copyWith(repeat: repeat.copyWith(maxTimes: int.tryParse(v) ?? repeat.maxTimes))),
          ),
          DropdownButtonFormField<RepeatUntil>(
            initialValue: repeat.until,
            decoration: InputDecoration(labelText: l.notifFieldUntil),
            onChanged: (u) => onChanged(spec.copyWith(repeat: repeat.copyWith(until: u))),
            items: [
              DropdownMenuItem(value: RepeatUntil.acknowledged, child: Text(l.notifUntilAcknowledged)),
              DropdownMenuItem(value: RepeatUntil.completed, child: Text(l.notifUntilCompleted)),
              DropdownMenuItem(value: RepeatUntil.max, child: Text(l.notifUntilMax)),
            ],
          ),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------------------------- conditions --

class _ConditionsEditor extends StatelessWidget {
  const _ConditionsEditor({
    required this.conditions,
    required this.statuses,
    required this.showItemKind,
    required this.onChanged,
  });

  final ConditionsSpec conditions;
  final List<String> statuses;
  final bool showItemKind;
  final ValueChanged<ConditionsSpec> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final only = conditions.onlyIfStatusIn ?? const <String>[];
    final window = conditions.timeWindow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.notifOnlyIfStatus, style: context.text.labelLarge),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final s in statuses)
              FilterChip(
                label: Text(labels.status(s)),
                selected: only.contains(s),
                onSelected: (v) {
                  final next = v
                      ? [...only, s]
                      : [
                          for (final x in only)
                            if (x != s) x,
                        ];
                  onChanged(
                    next.isEmpty
                        ? conditions.copyWith(clearOnlyIfStatusIn: true)
                        : conditions.copyWith(onlyIfStatusIn: next),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Text(l.notifWeekdays, style: context.text.labelLarge),
        WeekdayChips(
          selected: {...?conditions.weekdays},
          onChanged: (days) => onChanged(
            days.isEmpty
                ? conditions.copyWith(clearWeekdays: true)
                : conditions.copyWith(weekdays: days.toList()..sort()),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.notifTimeWindow),
          value: window != null,
          onChanged: (v) => onChanged(
            v
                ? conditions.copyWith(
                    timeWindow: TimeWindowSpec(from: LocalTime(8, 0), to: LocalTime(22, 0)),
                  )
                : conditions.copyWith(clearTimeWindow: true),
          ),
        ),
        if (window != null) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.notifFrom),
            trailing: Text(labels.time(window.from)),
            onTap: () async {
              final t = await pickTime(
                context,
                initial: window.from,
                use24h: MediaQuery.alwaysUse24HourFormatOf(context),
              );
              if (t != null) {
                onChanged(
                  conditions.copyWith(
                    timeWindow: TimeWindowSpec(from: t, to: window.to, outside: window.outside),
                  ),
                );
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.notifTo),
            trailing: Text(labels.time(window.to)),
            onTap: () async {
              final t = await pickTime(
                context,
                initial: window.to,
                use24h: MediaQuery.alwaysUse24HourFormatOf(context),
              );
              if (t != null) {
                onChanged(
                  conditions.copyWith(
                    timeWindow: TimeWindowSpec(from: window.from, to: t, outside: window.outside),
                  ),
                );
              }
            },
          ),
          DropdownButtonFormField<OutsideWindow>(
            initialValue: window.outside,
            onChanged: (o) => onChanged(
              conditions.copyWith(
                timeWindow: TimeWindowSpec(from: window.from, to: window.to, outside: o ?? window.outside),
              ),
            ),
            items: [
              DropdownMenuItem(value: OutsideWindow.drop, child: Text(l.notifOutsideDrop)),
              DropdownMenuItem(value: OutsideWindow.shiftStart, child: Text(l.notifOutsideShiftStart)),
              DropdownMenuItem(value: OutsideWindow.shiftEnd, child: Text(l.notifOutsideShiftEnd)),
            ],
          ),
        ],
        InheritDropdown<bool>(
          label: l.notifRespectQuiet,
          value: conditions.respectQuietHours,
          options: const [true, false],
          optionLabel: (v) => v ? l.notifYes : l.notifNo,
          onChanged: (v) => onChanged(
            v == null ? conditions.copyWith(clearRespectQuietHours: true) : conditions.copyWith(respectQuietHours: v),
          ),
        ),
        if (showItemKind)
          InheritDropdown<String>(
            label: l.notifItemKind,
            value: conditions.itemKind,
            options: [for (final k in ItemKind.values) k.wire],
            optionLabel: (w) => switch (ItemKind.tryParse(w)) {
              ItemKind.timed => l.notifItemKindTimed,
              ItemKind.allDay => l.notifItemKindAllDay,
              ItemKind.dateOnly => l.notifItemKindDateOnly,
              _ => l.notifItemKindAny,
            },
            onChanged: (v) =>
                onChanged(v == null ? conditions.copyWith(clearItemKind: true) : conditions.copyWith(itemKind: v)),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------------- content --

class _ContentPreview extends ConsumerWidget {
  const _ContentPreview({required this.spec, required this.targetType});

  final NotificationRuleSpec spec;
  final NotificationTargetType targetType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final hide = ref.watch(notificationSettingsProvider).hideContent;
    final sample = <String, String>{
      'title': 'Gym',
      'start_time': '08:00',
      'end_time': '09:00',
      'date': AppFormat(context.localeName).dateMedium(LocalDate(2026, 9, 22)),
      'weekday': AppFormat(context.localeName).weekdayShort(Weekday.tuesday),
      'minutes_until': '10',
      'duration': '1 h',
      'category': 'Health',
      'streak': '7',
      'item_text': 'Buy milk',
      'checklist_title': 'Groceries',
    };
    final rtl = context.isRtl;
    final title = spec.content.title == null
        ? ''
        : TemplateEngine.render(spec.content.title!, sample, rtl: rtl, maxLength: TemplateEngine.titleMax);
    final body = spec.content.body == null
        ? ''
        : TemplateEngine.render(spec.content.body!, sample, rtl: rtl, maxLength: TemplateEngine.bodyMax);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.visibility_outlined),
        title: Text(title.isEmpty ? l.notifPreview : title),
        subtitle: Text(
          [if (body.isNotEmpty) body, if (hide) '${l.notifHideContent}: ${l.notifRedactedTitle}'].join('\n'),
        ),
      ),
    );
  }
}
