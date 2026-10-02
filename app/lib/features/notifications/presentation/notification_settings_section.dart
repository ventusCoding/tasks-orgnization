import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_host_api.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/rule_preview.dart';
import 'package:everslot/features/notifications/domain/effective_rules_resolver.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/advanced_rule_editor.dart';
import 'package:everslot/features/notifications/presentation/mute_menu.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:everslot/features/notifications/presentation/permission_primers.dart';
import 'package:everslot/features/notifications/presentation/rule_preview_list.dart';
import 'package:everslot/features/notifications/presentation/simple_rule_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

export 'package:everslot/features/notifications/application/notification_host_api.dart'
    show NotificationHostApi, NotificationRulesDraft, notificationHostApiProvider;
export 'package:everslot/features/notifications/domain/notification_types.dart'
    show ItemKind, NotificationSection, NotificationTargetType, NotifyMode;

/// The "Notifications" section embedded in every editor (T7.1.09): notify mode (*Use defaults /
/// Custom / Defaults + mine / Off*), the effective rules (inherited ones greyed with their
/// provenance and *Customize*), *Add reminder* (simple editor → advanced editor), per-rule enable
/// toggles, swipe to delete with undo, the mute menu and badge, and the next-firings preview with
/// *Send test notification* (T7.1.11).
///
/// Saved items: `NotificationSettingsSection(targetType:, targetId:, section:)` reads and writes
/// the item's rules and `notify_mode` directly. Unsaved items: pass a [draft] and save it with the
/// item through `NotificationHostApi.saveDraftInTx` (see the feature README).
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
    this.pickCopySource,
    this.cravingCount,
    super.key,
  });

  /// task | checklist | checklistItem | habit.
  final NotificationTargetType targetType;

  /// Id of the item (for a new item: the id it will be saved with).
  final String targetId;

  /// planner | checklists | habits | quit (section defaults and switches).
  final NotificationSection section;

  /// Timed vs all-day vs date-only (tasks, dated items): picks the matching defaults and chips.
  final ItemKind itemKind;

  /// Category of the item (category default rules).
  final String? categoryId;

  /// Checklist of an item (checklist rules applying to its items).
  final String? checklistId;

  /// Ancestor items, nearest first (rules applying to descendants).
  final List<String> ancestorItemIds;

  /// Host-managed notify mode; null = read/write the item's `notify_mode` column (or the draft's).
  final NotifyMode? notifyMode;
  final ValueChanged<NotifyMode>? onNotifyModeChanged;

  /// Pending reminders of an unsaved item.
  final NotificationRulesDraft? draft;

  /// Occurrences used by the preview (null = ask the registered sources, else a sample one).
  final List<NotificationTarget>? previewTargets;

  /// Rules shown before *Show all*.
  final int maxVisible;

  /// *Copy reminders from…* (T7.1.15): the host's item picker (same [targetType]); returns the
  /// chosen item id or null. The action is hidden without it.
  final Future<String?> Function(BuildContext context)? pickCopySource;

  /// Logged cravings of a quit tracker: *Craving support* needs
  /// [QuitRitualTrigger.cravingSupportMinCravings] of them (T7.5.14).
  final int? cravingCount;

  @override
  ConsumerState<NotificationSettingsSection> createState() => _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState extends ConsumerState<NotificationSettingsSection> {
  bool _showAll = false;
  Future<List<NotificationTarget>>? _targets;

  /// Rules swiped away and not yet gone from the stream (a dismissed Dismissible must leave the
  /// tree synchronously).
  final Set<String> _hidden = {};

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
    if (oldWidget.targetId != widget.targetId || oldWidget.targetType != widget.targetType) {
      _targets = null;
    }
  }

  @override
  void dispose() {
    widget.draft?.removeListener(_onDraft);
    super.dispose();
  }

  void _onDraft() {
    if (mounted) setState(() {});
  }

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

  RuleDraft _draftOf(NotificationRuleSpec spec, {String? profileId, String? name, bool enabled = true}) => RuleDraft(
    targetType: _ruleType,
    targetId: widget.targetId,
    section: widget.section,
    spec: spec,
    profileId: profileId,
    name: name,
    enabled: enabled,
  );

  Future<void> _add(NotifyMode mode) async {
    final outcome = await showSimpleRuleEditor(
      context,
      targetType: widget.targetType,
      section: widget.section,
      itemKind: widget.itemKind,
      cravingCount: widget.cravingCount,
    );
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
    final drafts = [for (final r in rules) _draftOf(r.spec, profileId: r.profileId)];
    final draft = widget.draft;
    if (draft != null) {
      drafts.forEach(draft.add);
    } else {
      final record = await ref.read(notificationRulesRepositoryProvider).create(drafts);
      if (mounted) {
        showUndoSnackBar(context, ref, message: context.l10n.notifRuleSaved, record: record);
      }
    }
    // Own reminders are ignored in "Use defaults": switch to "Defaults + mine".
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
    final draft = widget.draft;
    if (draftIndex != null && draft != null) {
      final current = draft.rules[draftIndex];
      draft.replaceAt(
        draftIndex,
        _draftOf(edit.spec, profileId: edit.profileId, name: edit.name, enabled: current.enabled),
      );
      return;
    }
    await ref
        .read(notificationRulesRepositoryProvider)
        .update(
          rule.id,
          spec: edit.spec,
          profileId: edit.profileId,
          clearProfile: edit.profileId == null,
          name: edit.name,
          clearName: edit.name == null,
        );
  }

  Future<void> _toggle(NotificationRule rule, bool enabled, {int? draftIndex}) async {
    final draft = widget.draft;
    if (draftIndex != null && draft != null) {
      draft.replaceAt(draftIndex, draft.rules[draftIndex].copyWith(enabled: enabled));
      return;
    }
    await ref.read(notificationRulesRepositoryProvider).update(rule.id, enabled: enabled);
  }

  Future<void> _delete(NotificationRule rule, {int? draftIndex}) async {
    final draft = widget.draft;
    if (draftIndex != null && draft != null) {
      draft.removeAt(draftIndex);
      return;
    }
    setState(() => _hidden.add(rule.id));
    final l = context.l10n;
    final record = await ref.read(notificationRulesRepositoryProvider).delete(rule.id);
    if (mounted) {
      showUndoSnackBar(context, ref, message: l.notifRuleDeleted, record: record);
    }
  }

  Future<void> _customize(List<EffectiveRule> inherited) async {
    final draft = widget.draft;
    if (draft != null) {
      for (final e in inherited) {
        draft.add(RuleDraft.fromRule(e.rule, targetType: _ruleType, targetId: widget.targetId, isDefault: false));
      }
      await _setMode(NotifyMode.custom);
      return;
    }
    final store = ref.read(notifyModeStoreProvider);
    final record = await ref
        .read(notificationRulesRepositoryProvider)
        .snapshot(
          type: _ruleType,
          targetId: widget.targetId,
          inherited: inherited,
          setNotifyMode: (tx) => store.setInTx(tx, _ruleType, widget.targetId, NotifyMode.custom),
        );
    widget.onNotifyModeChanged?.call(NotifyMode.custom);
    if (mounted) {
      showUndoSnackBar(context, ref, message: context.l10n.notifRuleSaved, record: record);
    }
  }

  /// Copies the own reminders of an item picked by the host into this one (as own rules) and
  /// switches to *Custom* — one undoable command (T7.1.15).
  Future<void> _copyFrom() async {
    final pick = widget.pickCopySource;
    if (pick == null) return;
    final sourceId = await pick(context);
    if (sourceId == null || sourceId == widget.targetId || !mounted) return;
    final host = ref.read(notificationHostApiProvider);
    final rules = await host.rulesOf(widget.targetType, sourceId);
    if (!mounted) return;
    final l = context.l10n;
    if (rules.isEmpty) {
      showInfoSnackBar(context, l.notifCopyNothing);
      return;
    }
    final draft = widget.draft;
    if (draft != null) {
      for (final r in rules) {
        draft.add(RuleDraft.fromRule(r, targetType: _ruleType, targetId: widget.targetId, isDefault: false));
      }
      await _setMode(NotifyMode.custom);
      return;
    }
    final record = await host.setReminders(widget.targetType, [widget.targetId], rules, replace: false);
    widget.onNotifyModeChanged?.call(NotifyMode.custom);
    if (mounted) {
      showUndoSnackBar(context, ref, message: l.notifCopied(rules.length), record: record);
    }
  }

  List<NotificationRule> _ownRules() {
    final draft = widget.draft;
    if (draft != null) {
      return [
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
      ];
    }
    final stored = ref.watch(targetRulesProvider((_ruleType, widget.targetId))).value ?? const <NotificationRule>[];
    _hidden.retainAll({for (final r in stored) r.id});
    return [
      for (final r in stored)
        if (!_hidden.contains(r.id)) r,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final draft = widget.draft;
    final mode =
        widget.notifyMode ??
        draft?.notifyMode ??
        ref.watch(targetNotifyModeProvider((_ruleType, widget.targetId))).value ??
        NotifyMode.inherit;
    final own = _ownRules();
    final allRules = ref.watch(notificationRulesProvider).value ?? const <NotificationRule>[];
    final settings = ref.watch(notificationSettingsProvider);
    final profiles = {
      for (final p in ref.watch(notificationProfilesProvider).value ?? const <NotificationProfile>[]) p.id: p,
    };
    final resolver = EffectiveRulesResolver(RuleIndex(allRules), settings);
    final inherited = mode.usesDefaults ? resolver.inheritedFor(_pseudoTarget(mode)) : const <EffectiveRule>[];
    final effective = [
      ...inherited,
      if (mode.usesOwn)
        for (final r in own)
          if (r.enabled) EffectiveRule(r, RuleProvenance.own),
    ];
    final muted = context.colors.onSurfaceVariant;
    final rows = <Widget>[
      for (final e in inherited)
        _InheritedRuleTile(
          key: ValueKey('inherited-${e.rule.id}'),
          summary: labels.rule(e.rule, profile: profiles[e.rule.profileId]),
          source: l.notifInheritedFrom(labels.provenance(e.provenance)),
        ),
      if (mode != NotifyMode.off)
        for (var i = 0; i < own.length; i++)
          _OwnRuleTile(
            key: ValueKey('rule-${own[i].id}'),
            rule: own[i],
            summary: labels.rule(own[i], profile: profiles[own[i].profileId]),
            active: mode.usesOwn,
            onTap: () => unawaited(_edit(own[i], draftIndex: draft == null ? null : i)),
            onToggle: (v) => unawaited(_toggle(own[i], v, draftIndex: draft == null ? null : i)),
            onDelete: () => unawaited(_delete(own[i], draftIndex: draft == null ? null : i)),
          ),
    ];
    final visible = _showAll ? rows : rows.take(widget.maxVisible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          l.notifSectionTitle,
          trailing: draft == null
              ? MuteMenuButton(targetType: _ruleType.wire, targetId: widget.targetId, section: widget.section)
              : null,
        ),
        if (draft == null) MuteBadge(targetType: _ruleType.wire, targetId: widget.targetId),
        const NotificationPermissionBanner(showExact: false),
        if (!settings.sectionEnabled(widget.section))
          _Hint(icon: Icons.notifications_off_outlined, text: l.notifSectionOffHint(labels.section(widget.section))),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: Wrap(
            spacing: Space.sm,
            runSpacing: Space.xs,
            children: [
              for (final m in NotifyMode.values)
                ChoiceChip(label: Text(labels.mode(m)), selected: mode == m, onSelected: (_) => unawaited(_setMode(m))),
            ],
          ),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
            child: Text(
              mode == NotifyMode.off ? l.notifModeOffHint : l.notifNoReminders,
              style: context.text.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ...visible,
        if (rows.length > widget.maxVisible && !_showAll)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text(l.notifShowAll(rows.length)),
            ),
          ),
        if (mode != NotifyMode.off)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.sm),
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
                if (widget.pickCopySource != null)
                  TextButton.icon(
                    icon: const Icon(Icons.copy_all_outlined),
                    label: Text(l.notifCopyFrom),
                    onPressed: () => unawaited(_copyFrom()),
                  ),
              ],
            ),
          ),
        if (mode != NotifyMode.off && effective.isNotEmpty)
          ExpansionTile(
            title: Text(l.notifNextFirings),
            onExpansionChanged: (open) {
              if (open && _targets == null && widget.previewTargets == null) {
                final targets = ref.read(rulePreviewServiceProvider).targetsOf(widget.targetType, widget.targetId);
                setState(() {
                  _targets = targets;
                });
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
                            ref
                                .read(rulePreviewServiceProvider)
                                .sampleTarget(widget.targetType, widget.section, kind: widget.itemKind),
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

/// An inherited (default) rule: greyed, with where it comes from.
class _InheritedRuleTile extends StatelessWidget {
  const _InheritedRuleTile({required this.summary, required this.source, super.key});

  final String summary;
  final String source;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: 0.6,
    child: ListTile(leading: const Icon(Icons.subdirectory_arrow_right), title: Text(summary), subtitle: Text(source)),
  );
}

/// An own rule: tap to edit, switch to enable, swipe to delete (undo in the snackbar).
class _OwnRuleTile extends StatelessWidget {
  const _OwnRuleTile({
    required this.rule,
    required this.summary,
    required this.active,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });

  final NotificationRule rule;
  final String summary;

  /// False in "Use defaults" mode (own rules are kept but ignored).
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey('dismiss-${rule.id}'),
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
    onDismissed: (_) => onDelete(),
    child: Opacity(
      opacity: active ? 1 : 0.5,
      child: ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: Text(summary),
        subtitle: rule.name == null ? null : Text(rule.name!),
        onTap: onTap,
        trailing: Semantics(
          label: summary,
          child: Switch(value: rule.enabled, onChanged: onToggle),
        ),
      ),
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, Space.sm),
    child: Row(
      children: [
        Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Text(text, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
        ),
      ],
    ),
  );
}
