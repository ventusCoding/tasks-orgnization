import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/delivery_fields.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _ProfileAction { rename, duplicate, delete }

/// Custom profiles (T7.1.13): create, rename, duplicate, delete (built-ins can be duplicated,
/// not deleted), edit delivery/repeat defaults with the same field widgets as the rule editor.
class NotificationProfilesScreen extends ConsumerWidget {
  const NotificationProfilesScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    NotificationProfile profile,
    List<NotificationProfile> all,
  ) async {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final repo = ref.read(notificationProfilesRepositoryProvider);
    final used = await repo.rulesUsing(profile.id);
    if (!context.mounted) return;
    String? target;
    if (used > 0) {
      final choice = await showAppSheet<({String? id})>(
        context,
        title: l.notifProfileDelete,
        builder: (ctx) => ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Text(l.notifProfileDeleteBody(used)),
            ),
            ListTile(
              title: Text(l.notifProfileNone),
              onTap: () => Navigator.pop(ctx, (id: null)),
            ),
            for (final p in all)
              if (p.id != profile.id)
                ListTile(
                  title: Text(labels.profileName(p)),
                  onTap: () => Navigator.pop(ctx, (id: p.id)),
                ),
          ],
        ),
      );
      if (choice == null) return;
      target = choice.id;
    } else {
      final ok = await confirmDialog(
        context,
        title: l.notifProfileDelete,
        destructive: true,
      );
      if (!ok) return;
    }
    await repo.delete(profile.id, moveRulesTo: target);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final profiles = ref.watch(notificationProfilesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.notifProfilesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l.notifProfileNew),
        onPressed: () async {
          final name = await promptText(context, title: l.notifProfileNew);
          if (name != null)
            await ref
                .read(notificationProfilesRepositoryProvider)
                .create(name: name, spec: const ProfileSpec());
        },
      ),
      body: AsyncValueView<List<NotificationProfile>>(
        value: profiles,
        data: (all) {
          final visible = [
            for (final p in all)
              if (!p.hidden) p,
          ];
          // Drag handles reorder the list (sort keys; hidden profiles keep their place).
          return ReorderableListView(
            padding: const EdgeInsets.only(bottom: Space.xxxl * 2),
            header: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Text(
                l.notifProfileChannelWarning,
                style: context.text.bodySmall,
              ),
            ),
            // `onReorderItem` already adjusts [to] for the removed item.
            onReorderItem: (oldIndex, to) {
              if (to == oldIndex) return;
              final rest = [...visible]..removeAt(oldIndex);
              unawaited(
                ref
                    .read(notificationProfilesRepositoryProvider)
                    .reorder(
                      visible[oldIndex].id,
                      afterId: to == 0 ? null : rest[to - 1].id,
                    ),
              );
            },
            children: [
              for (final p in visible)
                ListTile(
                  key: ValueKey('profile-${p.id}'),
                  leading: Icon(
                    p.isBuiltin
                        ? Icons.verified_outlined
                        : Icons.style_outlined,
                  ),
                  title: Text(labels.profileName(p)),
                  subtitle: Text(
                    [
                      if (p.isBuiltin) l.notifProfileBuiltin,
                      labels.importance(
                        NotificationImportance.tryParse(
                              p.spec.delivery.importance,
                            ) ??
                            NotificationImportance.normal,
                      ),
                      labels.sound(p.spec.delivery.sound ?? 'default'),
                    ].join(' · '),
                  ),
                  onTap: () => unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProfileEditorScreen(profile: p),
                      ),
                    ),
                  ),
                  trailing: PopupMenuButton<_ProfileAction>(
                    onSelected: (a) async {
                      final repo = ref.read(
                        notificationProfilesRepositoryProvider,
                      );
                      switch (a) {
                        case _ProfileAction.rename:
                          final name = await promptText(
                            context,
                            title: l.notifProfileRename,
                            initial: labels.profileName(p),
                          );
                          if (name != null) await repo.update(p.id, name: name);
                        case _ProfileAction.duplicate:
                          await repo.duplicate(
                            p.id,
                            '${labels.profileName(p)} 2',
                          );
                        case _ProfileAction.delete:
                          if (context.mounted)
                            await _delete(context, ref, p, visible);
                      }
                    },
                    itemBuilder: (_) => [
                      if (!p.isBuiltin)
                        PopupMenuItem(
                          value: _ProfileAction.rename,
                          child: Text(l.notifProfileRename),
                        ),
                      PopupMenuItem(
                        value: _ProfileAction.duplicate,
                        child: Text(l.notifProfileDuplicate),
                      ),
                      if (!p.isBuiltin)
                        PopupMenuItem(
                          value: _ProfileAction.delete,
                          child: Text(l.notifProfileDelete),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Edits a profile's delivery and repeat defaults.
class ProfileEditorScreen extends ConsumerStatefulWidget {
  const ProfileEditorScreen({required this.profile, super.key});

  final NotificationProfile profile;

  @override
  ConsumerState<ProfileEditorScreen> createState() =>
      _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends ConsumerState<ProfileEditorScreen> {
  late ProfileSpec _spec = widget.profile.spec;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final repeat = _spec.repeat;
    final repeatMode = repeat != null ? 2 : (_spec.repeatDisabled ? 1 : 0);
    return Scaffold(
      appBar: AppBar(
        title: Text(labels.profileName(widget.profile)),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(notificationProfilesRepositoryProvider)
                  .update(widget.profile.id, spec: _spec);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l.actionSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          Text(l.notifProfileChannelWarning, style: context.text.bodySmall),
          const SizedBox(height: Space.md),
          DeliveryFieldsEditor(
            value: _spec.delivery,
            inheritedFrom: l.notifProfileStandard,
            onChanged: (d) =>
                setState(() => _spec = _spec.copyWith(delivery: d)),
          ),
          const SizedBox(height: Space.lg),
          Text(l.notifRepeat, style: context.text.titleSmall),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(l.notifInherit)),
              ButtonSegment(value: 1, label: Text(l.notifDisable)),
              ButtonSegment(value: 2, label: Text(l.notifModeCustom)),
            ],
            selected: {repeatMode},
            onSelectionChanged: (s) => setState(
              () => _spec = switch (s.first) {
                0 => _spec.copyWith(clearRepeat: true, repeatDisabled: false),
                1 => _spec.copyWith(clearRepeat: true, repeatDisabled: true),
                _ => _spec.copyWith(
                  repeat: const RepeatSpec(everyMinutes: 5, maxTimes: 5),
                  repeatDisabled: false,
                ),
              },
            ),
          ),
          if (repeat != null) ...[
            TextFormField(
              initialValue: '${repeat.everyMinutes}',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l.notifFieldEveryMinutes),
              onChanged: (v) => setState(
                () => _spec = _spec.copyWith(
                  repeat: repeat.copyWith(
                    everyMinutes: int.tryParse(v) ?? repeat.everyMinutes,
                  ),
                ),
              ),
            ),
            TextFormField(
              initialValue: '${repeat.maxTimes}',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l.notifFieldMaxTimes),
              onChanged: (v) => setState(
                () => _spec = _spec.copyWith(
                  repeat: repeat.copyWith(
                    maxTimes: (int.tryParse(v) ?? repeat.maxTimes).clamp(
                      1,
                      RepeatSpec.hardMaxTimes,
                    ),
                  ),
                ),
              ),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.notifRespectQuiet),
            value: _spec.respectQuietHours ?? true,
            onChanged: (v) =>
                setState(() => _spec = _spec.copyWith(respectQuietHours: v)),
          ),
        ],
      ),
    );
  }
}
