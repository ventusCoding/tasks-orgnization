import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/occurrence_overrides.dart';
import 'package:everslot/features/notifications/domain/effective_rules_resolver.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:everslot/features/notifications/presentation/simple_rule_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "Reminders for this occurrence" (T7.1.16): the reminders of one occurrence with a switch each
/// (off = for this occurrence only) and *Add for this occurrence only*.
Future<void> showOccurrenceReminders(
  BuildContext context, {
  required NotificationTargetType targetType,
  required String targetId,
  required NotificationSection section,
  required String occurrenceKey,
  ItemKind itemKind = ItemKind.timed,
  String? categoryId,
}) => showAppSheet<void>(
  context,
  title: context.l10n.notifOccurrenceReminders,
  builder: (_) => OccurrenceRemindersSheet(
    targetType: targetType,
    targetId: targetId,
    section: section,
    occurrenceKey: occurrenceKey,
    itemKind: itemKind,
    categoryId: categoryId,
  ),
);

class OccurrenceRemindersSheet extends ConsumerWidget {
  const OccurrenceRemindersSheet({
    required this.targetType,
    required this.targetId,
    required this.section,
    required this.occurrenceKey,
    this.itemKind = ItemKind.timed,
    this.categoryId,
    super.key,
  });

  final NotificationTargetType targetType;
  final String targetId;
  final NotificationSection section;
  final String occurrenceKey;
  final ItemKind itemKind;
  final String? categoryId;

  RuleTargetType get _ruleType => RuleTargetType.forTarget(targetType) ?? RuleTargetType.task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final mode = ref.watch(targetNotifyModeProvider((_ruleType, targetId))).value ?? NotifyMode.inherit;
    final rules = ref.watch(notificationRulesProvider).value ?? const <NotificationRule>[];
    final resolver = EffectiveRulesResolver(RuleIndex(rules), ref.watch(notificationSettingsProvider));
    final target = NotificationTarget(
      type: targetType,
      id: targetId,
      section: section,
      title: '',
      categoryId: categoryId,
      itemKind: itemKind,
      notifyMode: mode,
      occurrenceKey: occurrenceKey,
    );
    final active = resolver.forTarget(target);
    // Switched off for this occurrence: own rules excluding it, disabled occurrence overrides.
    final off = [
      for (final r in rules)
        if (r.targetType == _ruleType &&
            r.targetId == targetId &&
            ((r.spec.conditions.excludeOccurrenceKeys?.contains(occurrenceKey) ?? false) ||
                (!r.enabled && (r.spec.conditions.occurrenceKeys?.contains(occurrenceKey) ?? false))))
          r,
    ];
    final overrides = ref.read(occurrenceOverridesProvider);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsetsDirectional.only(bottom: Space.lg),
      children: [
        if (active.isEmpty && off.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.all(Space.lg),
            child: Text(l.notifOccurrenceNone, style: context.text.bodyMedium),
          ),
        for (final e in active)
          SwitchListTile(
            key: ValueKey('occ-on-${e.rule.id}'),
            title: Text(labels.rule(e.rule)),
            subtitle: e.provenance == RuleProvenance.occurrence ? Text(l.notifOccurrenceOnly) : null,
            value: true,
            onChanged: (_) => unawaited(
              overrides.switchOff(
                rule: e.rule,
                type: _ruleType,
                targetId: targetId,
                section: section,
                key: occurrenceKey,
              ),
            ),
          ),
        for (final r in off)
          SwitchListTile(
            key: ValueKey('occ-off-${r.id}'),
            title: Text(labels.rule(r)),
            subtitle: Text(l.notifOccurrenceOff),
            value: false,
            onChanged: (_) => unawaited(overrides.restore(rule: r, key: occurrenceKey)),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
          child: OutlinedButton.icon(
            key: const ValueKey('occ-add'),
            icon: const Icon(Icons.add_alert_outlined),
            label: Text(l.notifOccurrenceAdd),
            onPressed: () async {
              final outcome = await showSimpleRuleEditor(
                context,
                targetType: targetType,
                section: section,
                itemKind: itemKind,
              );
              if (outcome == null) return;
              for (final r in outcome.rules) {
                await overrides.add(
                  type: _ruleType,
                  targetId: targetId,
                  section: section,
                  key: occurrenceKey,
                  spec: r.spec,
                  profileId: r.profileId,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
