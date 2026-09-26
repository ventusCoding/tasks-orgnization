import 'dart:async';

import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/rule_preview.dart';
import 'package:everslot/features/notifications/data/notification_rules_repository.dart';
import 'package:everslot/features/notifications/domain/effective_rules_resolver.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/presentation/advanced_rule_editor.dart';
import 'package:everslot/features/notifications/presentation/mute_menu.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:everslot/features/notifications/presentation/permission_primers.dart';
import 'package:everslot/features/notifications/presentation/rule_preview_list.dart';
import 'package:everslot/features/notifications/presentation/simple_rule_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Rules of an item that isn't saved yet (T7.1.09): the host editor saves them with the item in
/// one transaction via [saveInTx].
class NotificationRulesDraft extends ChangeNotifier {
  NotificationRulesDraft({NotifyMode notifyMode = NotifyMode.inherit}) : _notifyMode = notifyMode;

  final List<RuleDraft> _rules = [];
  NotifyMode _notifyMode;

  List<RuleDraft> get rules => List.unmodifiable(_rules);
  NotifyMode get notifyMode => _notifyMode;

  set notifyMode(NotifyMode value) {
    _notifyMode = value;
    notifyListeners();
  }

  void add(RuleDraft draft) {
    _rules.add(draft);
    notifyListeners();
  }

  void replaceAt(int index, RuleDraft draft) {
    _rules[index] = draft;
    notifyListeners();
  }

  void removeAt(int index) {
    _rules.removeAt(index);
    notifyListeners();
  }

  /// Inserts the pending rules for [targetId] inside the host's transaction. The host writes
  /// `notify_mode` itself (it owns the row).
  Future<void> saveInTx(WriteTx tx, NotificationRulesRepository repository, {required String targetId}) =>
      repository.insertInTx(tx, [
        for (final d in _rules)
          RuleDraft(
            targetType: d.targetType,
            targetId: targetId,
            section: d.section,
            spec: d.spec,
            enabled: d.enabled,
            name: d.name,
            profileId: d.profileId,
          ),
      ]);
}

/// The "Notifications" section embedded in every editor (T7.1.09): notify mode, effective rules
/// (inherited ones greyed with their provenance + *Customize*), *Add reminder*, per-rule toggles,
/// swipe to delete with undo, mute badge, next-firings preview and *Send test*.
class NotificationSettingsSection extends ConsumerStatefulWidget {
  const NotificationSettingsSection({
    required this.targetType,
    required this.targetId,
    required this.section,
    this.itemKind = ItemKind.timed,
    this.categoryId,
    this.checklistId,
    this.ancestorItemIds = const [],
    this.notifyMode,
    this.onNotifyModeChanged,
    this.draft,
    this.previewTargets,
    this.maxVisible = 3,
    super.key,
  });

  final NotificationTargetType targetType;
  final String targetId;
  final NotificationSection section;
  final ItemKind itemKind;
  final String? categoryId;
  final String? checklistId;
  final List<String> ancestorItemIds;

  /// Host-managed notify mode (drafts); null = read/write the item's `notify_mode` column.
  final NotifyMode? notifyMode;
  final ValueChanged<NotifyMode>? onNotifyModeChanged;

  /// Pending rules for an unsaved item.
  final NotificationRulesDraft? draft;

  /// Occurrences to preview (null = ask the registered sources, else a sample occurrence).
  final List<NotificationTarget>? previewTargets;
  final int maxVisible;

  @override
  ConsumerState<NotificationSettingsSection> createState() => _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState extends ConsumerState<NotificationSettingsSection> {
  bool _showAll = false;
  Future<List<NotificationTarget>>? _targets;

  RuleTargetType get _ruleType => RuleTargetType.forTarget(widget.targetType) ?? RuleTargetType.task;

  @override
  void initState() {
    super.initState();
    widget.draft?.addListener(_onDraft);
  }

  @override
  void didUpdateWidget(NotificationSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft != widget.draft) {
      oldWidget.draft?.removeListener(_onDraft);
      widget.draft?.addListener(_onDraft);
    }
  }

  @override
  void dispose() {
    widget.draft?.removeListener(_onDraft);
    super.dispose();
  }

  void _onDraft() => setState(() {});

  NotificationTarget _pseudoTarget(NotifyMode mode) => NotificationTarget(
    type: widget.targetType,
    id: widget.targetId,
    section: widget.section,
    title: '',
    categoryId: widget.categoryId,
    checklistId: widget.checklistId,
    ancestorItemIds: widget.ancestorItemIds,
    itemKind: widget.itemKind,
    notifyMode: mode,
  );

  Future<void> _setMode(NotifyMode mode) async {
    if (widget.onNotifyModeChanged != null) {
      widget.onNotifyModeChanged!(mode);
    } else if (widget.draft != null) {
      widget.draft!.notifyMode = mode;
    } else {
      await ref.read(notifyModeStoreProvider).set(_ruleType, widget.targetId, mode);
    }
  }

  Future<void> _add(NotifyMode mode) async {
    final outcome = await showSimpleRuleEditor(context, targetType: widget.targetType, section: widget.section, itemKind: widget.itemKind);
    if (outcome == null || !mounted) return;
    var rules = outcome.rules;
    if (outcome.openAdvanced) {
      final first = rules.first;
      final edit = await showAdvancedRuleEditor(
        context,
        targetType: widget.targetType,
        section: widget.section,
        spec: first.spec,
        profileId: first.profileId,
        itemKind: widget.itemKind,
      );
      if (edit == null || !mounted) return;
      rules = [(spec: edit.spec, profileId: edit.profileId)];
    }
    final drafts = [
      for (final r in rules)
        RuleDraft(targetType: _ruleType, targetId: widget.targetId, section: widget.section, spec: r.spec, profileId: r.profileId),
    ];
    if (widget.draft != null) {
      drafts.forEach(widget.draft!.add);
    } else {
      await ref.read(notificationRulesRepositoryProvider).create(drafts);
    }
    if (mode == NotifyMode.inherit) await _setMode(NotifyMode.inheritPlus);
    if (mounted) unawaited(showNotificationPrimer(context, ref));
  }

  Future<void> _edit(NotificationRule rule, {int? draftIndex}) async {
    final edit = await showAdvancedRuleEditor(
      context,
      targetType: widget.targetType,
      section: widget.section,
      spec: rule.spec,
      profileId: rule.profileId,
      name: rule.name,
      itemKind: widget.itemKind,
    );
    if (edit == null || !mounted) return;
    if (draftIndex != null) {
      widget.draft!.replaceAt(
        draftIndex,
        RuleDraft(targetType: _ruleType, targetId: widget.targetId, section: widget.section, spec: edit.spec, profileId: edit.profileId, name: edit.name),
      );
      return;
    }
    await ref.read(notificationRulesRepositoryProvider).update(
      rule.id,
      spec: edit.spec,
      profileId: edit.profileId,
      clearProfile: edit.profileId == null,
      name: edit.name,
    );
  }

  Future<void> _customize(List<EffectiveRule> inherited) async {
    if (widget.draft != null) {
      for (final e in inherited) {
        widget.draft!.add(RuleDraft.fromRule(e.rule, targetType: _ruleType, targetId: widget.targetId, isDefault: false));
      }
      await _setMode(NotifyMode.custom);
      return;
    }
    final store = ref.read(notifyModeStoreProvider);
    await ref.read(notificationRulesRepositoryProvider).snapshot(
      type: _ruleType,
      targetId: widget.targetId,
      inherited: inherited,
      setNotifyMode: (tx) => store.setInTx(tx, _ruleType, widget.targetId, NotifyMode.custom),
    );
    widget.onNotifyModeChanged?.call(NotifyMode.custom);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final draft = widget.draft;
    final mode = widget.notifyMode ??
        draft?.notifyMode ??
        ref.watch(targetNotifyModeProvider((_ruleType, widget.targetId))).value ??
        NotifyMode.inherit;
    final own = draft != null
        ? [
            for (var i = 0; i < draft.rules.length; i++)
              NotificationRule(
                id: 'draft-$i',
                targetType: _ruleType,
                targetId: widget.targetId,
                section: widget.section,
                spec: draft.rules[i].spec,
                profileId: draft.rules[i].profileId,
                name: draft.rules[i].name,
                enabled: draft.rules[i].enabled,
              ),
          ]
        : ref.watch(targetRulesProvider((_ruleType, widget.targetId))).value ?? const <NotificationRule>[];
    final allRules = ref.watch(notificationRulesProvider).value ?? const <NotificationRule>[];
    final settings = ref.watch(notificationSettingsProvider);
    final profiles = {for (final p in ref.watch(notificationProfilesProvider).value ?? const <NotificationProfile>[]) p.id: p};
    final resolver = EffectiveRulesResolver(RuleIndex(allRules), settings);
    final inherited = mode.usesDefaults ? resolver.inheritedFor(_pseudoTarget(mode)) : const <EffectiveRule>[];
    final effective = [
      if (mode.usesDefaults) ...inherited,
      if (mode.usesOwn) for (final r in own) EffectiveRule(r, RuleProvenance.own),
    ];
    final rows = <Widget>[
      if (mode.usesDefaults)
        for (final e in inherited)
          Opacity(
            opacity: 0.6,
            child: ListTile(
              leading: const Icon(Icons.subdirectory_arrow_right),
              title: Text(labels.rule(e.rule, profile: profiles[e.rule.profileId])),
              subtitle: Text(l.notifInheritedFrom(labels.provenance(e.provenance))),
            ),
          ),
      if (mode != NotifyMode.off)
        for (var i = 0; i < own.length; i++)
          Dismissible(
            key: ValueKey('rule-${own[i].id}'),
            direction: DismissDirection.endToStart,
            background: ColoredBox(
              color: context.colors.errorContainer,
              child: const Align(alignment: AlignmentDirectional.centerEnd, child: Padding(padding: EdgeInsets.all(Space.lg), child: Icon(Icons.delete_outline))),
            ),
            onDismissed: (_) async {
              if (draft != null) {
                draft.removeAt(i);
                return;
              }
              final record = await ref.read(notificationRulesRepositoryProvider).delete(own[i].id);
              if (context.mounted) showUndoSnackBar(context, ref, message: l.notifRuleDeleted, record: record);
            },
            child: Opacity(
              opacity: mode.usesOwn ? 1 : 0.5,
              child: ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(labels.rule(own[i], profile: profiles[own[i].profileId])),
                subtitle: own[i].name == null ? null : Text(own[i].name!),
                onTap: () => unawaited(_edit(own[i], draftIndex: draft == null ? null : i)),
                trailing: Switch(
                  value: own[i].enabled,
                  onChanged: (v) {
                    if (draft != null) {
                      final d = draft.rules[i];
                      draft.replaceAt(
                        i,
                        RuleDraft(targetType: d.targetType, targetId: d.targetId, section: d.section, spec: d.spec, profileId: d.profileId, name: d.name, enabled: v),
                      );
                    } else {
                      unawaited(ref.read(notificationRulesRepositoryProvider).update(own[i].id, enabled: v));
                    }
                  },
                ),
              ),
            ),
          ),
    ];
    final visible = _showAll ? rows : rows.take(widget.maxVisible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          l.notifSectionTitle,
          trailing: draft == null ? MuteMenuButton(targetType: _ruleType.wire, targetId: widget.targetId, section: widget.section) : null,
        ),
        MuteBadge(targetType: _ruleType.wire, targetId: widget.targetId),
        const NotificationPermissionBanner(showExact: false),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              for (final m in NotifyMode.values)
                ChoiceChip(label: Text(labels.mode(m)), selected: mode == m, onSelected: (_) => unawaited(_setMode(m))),
            ],
          ),
        ),
        if (rows.isEmpty && mode != NotifyMode.off)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
            child: Text(l.notifNoReminders, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          ),
        ...visible,
        if (rows.length > widget.maxVisible && !_showAll)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: () => setState(() => _showAll = true), child: Text(l.notifShowAll(rows.length))),
          ),
        if (mode != NotifyMode.off)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: Wrap(
              spacing: Space.sm,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add_alert_outlined),
                  label: Text(l.notifAddReminder),
                  onPressed: () => unawaited(_add(mode)),
                ),
                if (inherited.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.tune),
                    label: Text(l.notifCustomize),
                    onPressed: () => unawaited(_customize(inherited)),
                  ),
              ],
            ),
          ),
        if (mode != NotifyMode.off && effective.isNotEmpty)
          ExpansionTile(
            title: Text(l.notifNextFirings),
            onExpansionChanged: (open) {
              if (open && _targets == null && widget.previewTargets == null) {
                setState(() => _targets = ref.read(rulePreviewServiceProvider).targetsOf(widget.targetType, widget.targetId));
              }
            },
            children: [
              if (widget.previewTargets != null)
                RulePreviewList(rules: [for (final e in effective) e.rule], targets: widget.previewTargets!)
              else
                FutureBuilder<List<NotificationTarget>>(
                  future: _targets,
                  builder: (context, snap) {
                    if (!snap.hasData) return const LinearProgressIndicator();
                    final targets = snap.data!.isEmpty
                        ? [
                            ref.read(rulePreviewServiceProvider).sampleTarget(widget.targetType, widget.section, kind: widget.itemKind),
                          ]
                        : [for (final t in snap.data!) t.copyWith(notifyMode: NotifyMode.custom)];
                    return RulePreviewList(rules: [for (final e in effective) e.rule], targets: targets);
                  },
                ),
            ],
          ),
      ],
    );
  }
}
