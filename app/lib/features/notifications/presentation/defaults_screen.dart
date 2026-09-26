import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_draft.dart';
import 'package:everslot/features/notifications/presentation/advanced_rule_editor.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:everslot/features/notifications/presentation/simple_rule_editor.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/domain/category.dart';
import 'package:everslot/features/organization/presentation/categories_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Notifications › Default reminders (T7.1.14): per-section defaults (separate lists
/// for timed / all-day / date-only planner items), default profile, category defaults and an
/// impact preview. Editing a default replans every inheriting target; `custom` items are
/// unaffected (resolver semantics).
class NotificationDefaultsScreen extends ConsumerWidget {
  const NotificationDefaultsScreen({super.key});

  static const sections = [
    NotificationSection.planner,
    NotificationSection.checklists,
    NotificationSection.habits,
    NotificationSection.quit,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = NotificationLabels.of(context);
    return DefaultTabController(
      length: sections.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.notifDefaultsTitle),
          bottom: TabBar(isScrollable: true, tabs: [for (final s in sections) Tab(text: labels.section(s))]),
        ),
        body: TabBarView(children: [for (final s in sections) _SectionDefaults(section: s)]),
      ),
    );
  }
}

class _SectionDefaults extends ConsumerWidget {
  const _SectionDefaults({required this.section});

  final NotificationSection section;

  NotificationTargetType get _targetType => switch (section) {
    NotificationSection.planner => NotificationTargetType.task,
    NotificationSection.checklists => NotificationTargetType.checklistItem,
    NotificationSection.habits || NotificationSection.quit => NotificationTargetType.habit,
    NotificationSection.system => NotificationTargetType.digest,
  };

  Future<void> _add(BuildContext context, WidgetRef ref, {ItemKind kind = ItemKind.timed, String? categoryId}) async {
    final outcome = await showSimpleRuleEditor(context, targetType: _targetType, section: section, itemKind: kind);
    if (outcome == null || !context.mounted) return;
    var rules = outcome.rules;
    if (outcome.openAdvanced) {
      final edit = await showAdvancedRuleEditor(
        context,
        targetType: _targetType,
        section: section,
        spec: rules.first.spec,
        profileId: rules.first.profileId,
        itemKind: kind,
        showItemKind: true,
      );
      if (edit == null) return;
      rules = [(spec: edit.spec, profileId: edit.profileId)];
    }
    final withKind = section == NotificationSection.planner && categoryId == null;
    await ref.read(notificationRulesRepositoryProvider).create([
      for (final r in rules)
        RuleDraft(
          targetType: categoryId == null ? RuleTargetType.section : RuleTargetType.category,
          targetId: categoryId,
          section: section,
          isDefault: true,
          profileId: r.profileId,
          spec: withKind && r.spec.conditions.itemKind == null
              ? r.spec.copyWith(conditions: r.spec.conditions.copyWith(itemKind: kind.wire))
              : r.spec,
        ),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final rules = ref.watch(notificationRulesProvider).value ?? const <NotificationRule>[];
    final profiles = [for (final p in ref.watch(notificationProfilesProvider).value ?? const <NotificationProfile>[]) if (!p.hidden) p];
    final profileById = {for (final p in profiles) p.id: p};
    final settings = ref.watch(notificationSettingsProvider);
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final defaults = [
      for (final r in rules)
        if (r.isDefault && r.targetType == RuleTargetType.section && r.section == section) r,
    ];
    final categoryRules = <String, List<NotificationRule>>{};
    for (final r in rules) {
      if (r.isDefault && r.targetType == RuleTargetType.category && r.section == section && r.targetId != null) {
        (categoryRules[r.targetId!] ??= []).add(r);
      }
    }
    List<NotificationRule> ofKind(ItemKind kind) => [
      for (final r in defaults)
        if (kind == ItemKind.any
            ? r.spec.conditions.itemKind == null || r.spec.conditions.itemKind == 'any'
            : r.spec.conditions.itemKind == kind.wire)
          r,
    ];
    final groups = section == NotificationSection.planner
        ? [
            (l.notifDefaultsTimed, ItemKind.timed),
            (l.notifDefaultsAllDay, ItemKind.allDay),
            (l.notifDefaultsDateOnly, ItemKind.dateOnly),
            (l.notifDefaultsOther, ItemKind.any),
          ]
        : [(labels.section(section), ItemKind.any)];

    Widget ruleTile(NotificationRule r, {ItemKind kind = ItemKind.timed}) => Dismissible(
      key: ValueKey('default-${r.id}'),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: context.colors.errorContainer,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
            child: Icon(Icons.delete_outline, color: context.colors.onErrorContainer),
          ),
        ),
      ),
      // Delete first: the row then leaves the list through the rules stream (a dismissed
      // Dismissible must not stay in the tree).
      confirmDismiss: (_) async {
        try {
          final record = await ref.read(notificationRulesRepositoryProvider).delete(r.id);
          if (context.mounted) showUndoSnackBar(context, ref, message: l.notifRuleDeleted, record: record);
          return true;
        } on Object {
          return false;
        }
      },
      child: ListTile(
        title: Text(labels.rule(r, profile: profileById[r.profileId])),
        onTap: () async {
          final edit = await showAdvancedRuleEditor(
            context,
            targetType: _targetType,
            section: section,
            spec: r.spec,
            profileId: r.profileId,
            name: r.name,
            itemKind: kind,
            showItemKind: true,
          );
          if (edit == null) return;
          await ref.read(notificationRulesRepositoryProvider).update(
            r.id,
            spec: edit.spec,
            profileId: edit.profileId,
            clearProfile: edit.profileId == null,
            name: edit.name,
          );
        },
        trailing: Switch(
          value: r.enabled,
          onChanged: (v) => unawaited(ref.read(notificationRulesRepositoryProvider).update(r.id, enabled: v)),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xxxl),
      children: [
        ListTile(
          title: Text(l.notifDefaultProfile),
          trailing: DropdownButton<String?>(
            value: profiles.any((p) => p.id == settings.sectionDefaultProfileId(section)) ? settings.sectionDefaultProfileId(section) : null,
            onChanged: (id) {
              final raw = ref.read(settingsProvider(SettingsNs.notifications)).value ?? const {};
              final per = Map<String, Object?>.from((raw['perSection'] as Map?) ?? const {});
              per[section.wire] = {...Map<String, Object?>.from((per[section.wire] as Map?) ?? const {}), 'defaultProfileId': id};
              unawaited(ref.read(notificationSettingsWriterProvider)({'perSection': per}));
            },
            items: [
              DropdownMenuItem<String?>(child: Text(l.notifProfileNone)),
              for (final p in profiles) DropdownMenuItem<String?>(value: p.id, child: Text(labels.profileName(p))),
            ],
          ),
        ),
        _ImpactCount(section: section),
        for (final (title, kind) in groups) ...[
          SectionHeader(
            title,
            trailing: IconButton(
              tooltip: l.notifAddReminder,
              icon: const Icon(Icons.add),
              onPressed: () => unawaited(_add(context, ref, kind: kind == ItemKind.any ? ItemKind.timed : kind)),
            ),
          ),
          if (ofKind(kind).isEmpty)
            ListTile(title: Text(l.notifNoReminders, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant))),
          for (final r in ofKind(kind)) ruleTile(r, kind: kind == ItemKind.any ? ItemKind.timed : kind),
        ],
        SectionHeader(
          l.notifDefaultsCategory,
          trailing: IconButton(
            tooltip: l.notifDefaultsAddCategory,
            icon: const Icon(Icons.add),
            onPressed: () async {
              final categoryId = await pickCategory(context, ref);
              if (categoryId != null && context.mounted) await _add(context, ref, categoryId: categoryId);
            },
          ),
        ),
        for (final e in categoryRules.entries) ...[
          ListTile(
            dense: true,
            leading: ColorDot(Color(categories.where((c) => c.id == e.key).firstOrNull?.color ?? 0xFF64748B)),
            title: Text(categories.where((c) => c.id == e.key).firstOrNull?.name ?? e.key, style: context.text.titleSmall),
            trailing: IconButton(
              tooltip: l.notifAddReminder,
              icon: const Icon(Icons.add),
              onPressed: () => unawaited(_add(context, ref, categoryId: e.key)),
            ),
          ),
          for (final r in e.value) ruleTile(r),
        ],
      ],
    );
  }
}

/// "Affects N items that use defaults" (targets of the section in inherit / inherit_plus mode).
class _ImpactCount extends ConsumerWidget {
  const _ImpactCount({required this.section});

  final NotificationSection section;

  Future<int> _count(WidgetRef ref) async {
    final now = ref.read(clockProvider).nowUtc();
    final keys = <String>{};
    for (final source in ref.read(notificationTargetSourcesProvider)) {
      if (source.section != section.wire) continue;
      try {
        for (final t in await source.targetsBetween(now, now.add(const Duration(days: 14)))) {
          if (t.notifyMode.usesDefaults) keys.add(t.targetKey);
        }
      } on Object {
        // ignore failing sources
      }
    }
    return keys.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<int>(
    future: _count(ref),
    builder: (context, snap) => snap.hasData
        ? Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
            child: Text(context.l10n.notifImpact(snap.data!), style: context.text.bodySmall),
          )
        : const SizedBox.shrink(),
  );
}
