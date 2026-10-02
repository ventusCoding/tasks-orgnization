import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/domain/default_rules.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/presentation/defaults_screen.dart';
import 'package:everslot/features/notifications/presentation/delivery_fields.dart';
import 'package:everslot/features/notifications/presentation/diagnostics_screen.dart';
import 'package:everslot/features/notifications/presentation/mute_menu.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:everslot/features/notifications/presentation/permission_primers.dart';
import 'package:everslot/features/notifications/presentation/profiles_screen.dart';
import 'package:everslot/features/notifications/presentation/rule_sets_ui.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Notifications (T7.5.15): global controls that keep free configuration humane.
/// Embeddable (no route needed): `Navigator.push(MaterialPageRoute(builder: (_) => const
/// NotificationsSettingsPage()))` or as the body of the settings feature's page.
class NotificationsSettingsPage extends ConsumerWidget {
  const NotificationsSettingsPage({super.key, this.embedded = false});

  /// When true, renders only the list (the host provides the Scaffold/AppBar).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const list = _SettingsList();
    if (embedded) return list;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notifSettingsTitle)),
      body: list,
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList();

  Future<void> _patch(WidgetRef ref, Map<String, Object?> patch) => ref.read(notificationSettingsWriterProvider)(patch);

  Map<String, dynamic> _raw(WidgetRef ref) => ref.read(settingsProvider(SettingsNs.notifications)).value ?? const {};

  Future<void> _patchSection(WidgetRef ref, NotificationSection section, Map<String, Object?> values) {
    final per = Map<String, Object?>.from((_raw(ref)['perSection'] as Map?) ?? const {});
    final current = Map<String, Object?>.from((per[section.wire] as Map?) ?? const {});
    per[section.wire] = {...current, ...values};
    return _patch(ref, {'perSection': per});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final settings = ref.watch(notificationSettingsProvider);
    final profiles = [
      for (final p in ref.watch(notificationProfilesProvider).value ?? const <NotificationProfile>[])
        if (!p.hidden) p,
    ];
    final now = ref.watch(clockProvider).nowUtc();
    final zone = ref.watch(deviceZoneProvider);
    final zones = ref.watch(zoneResolverProvider);
    final deviceId = ref.watch(deviceIdProvider);
    final mutes = [
      for (final m in ref.watch(notificationMutesProvider).value ?? const <NotificationMute>[])
        if (m.activeAt(now)) m,
    ];
    final rules = ref.watch(notificationRulesProvider).value ?? const <NotificationRule>[];
    final userId = ref.watch(currentUserIdProvider);

    Future<DateTime?> pickInstant() async {
      final today = zones.toLocal(now, zone);
      final d = await pickDate(context, initial: today.date, first: today.date);
      if (d == null || !context.mounted) return null;
      final t = await pickTime(context, initial: today.time, use24h: MediaQuery.alwaysUse24HourFormatOf(context));
      if (t == null) return null;
      return zones.resolve(LocalDateTime(d, t), zone).utc;
    }

    void push(Widget page) => unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)));

    final paused = settings.pausedAt(now);
    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xxxl),
      children: [
        const NotificationPermissionBanner(),
        // ---- Pause all
        SectionHeader(l.notifPauseAll),
        if (paused)
          ListTile(
            leading: const Icon(Icons.pause_circle_outline),
            title: Text(l.notifPausedUntil(labels.format.dateTime(zones.toLocal(settings.pausedUntil!, zone)))),
            trailing: FilledButton.tonal(
              onPressed: () => unawaited(_patch(ref, {'pausedUntil': null})),
              child: Text(l.notifResume),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Wrap(
              spacing: Space.sm,
              children: [
                ActionChip(
                  label: Text(l.notifPause1h),
                  onPressed: () =>
                      unawaited(_patch(ref, {'pausedUntil': now.add(const Duration(hours: 1)).toIso8601String()})),
                ),
                ActionChip(
                  label: Text(l.notifPauseTomorrow),
                  onPressed: () {
                    final tomorrow = zones.toLocal(now, zone).date.plusDays(1);
                    final until = zones.resolve(LocalDateTime(tomorrow, LocalTime(8, 0)), zone).utc;
                    unawaited(_patch(ref, {'pausedUntil': until.toIso8601String()}));
                  },
                ),
                ActionChip(
                  label: Text(l.notifPauseCustom),
                  onPressed: () async {
                    final until = await pickInstant();
                    if (until != null) {
                      await _patch(ref, {'pausedUntil': until.toIso8601String()});
                    }
                  },
                ),
              ],
            ),
          ),
        // ---- Sections
        SectionHeader(l.notifSettingsSections),
        for (final section in NotificationSection.itemSections)
          SwitchListTile(
            title: Text(labels.section(section)),
            subtitle: Text(
              '${l.notifDefaultProfile}: ${profiles.where((p) => p.id == settings.sectionDefaultProfileId(section)).map(labels.profileName).firstOrNull ?? l.notifProfileStandard}',
            ),
            value: settings.sectionEnabled(section),
            onChanged: (v) => unawaited(_patchSection(ref, section, {'enabled': v})),
            secondary: PopupMenuButton<String?>(
              tooltip: l.notifDefaultProfile,
              icon: const Icon(Icons.tune),
              onSelected: (id) => unawaited(_patchSection(ref, section, {'defaultProfileId': id})),
              itemBuilder: (_) => [
                PopupMenuItem<String?>(child: Text(l.notifProfileNone)),
                for (final p in profiles) PopupMenuItem<String?>(value: p.id, child: Text(labels.profileName(p))),
              ],
            ),
          ),
        // ---- Quiet hours
        SectionHeader(
          l.notifQuietHours,
          trailing: IconButton(
            tooltip: l.notifQuietAdd,
            icon: const Icon(Icons.add),
            onPressed: () async {
              final w = await showQuietHoursEditor(context, null);
              if (w != null) {
                await _patch(ref, {
                  'quietHours': [for (final x in settings.quietHours) x.toJson(), w.toJson()],
                });
              }
            },
          ),
        ),
        if (settings.quietHours.isEmpty)
          ListTile(
            title: Text(
              l.notifQuietNone,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
        for (var i = 0; i < settings.quietHours.length; i++)
          ListTile(
            leading: const Icon(Icons.bedtime_outlined),
            title: Text(
              l.notifQuietWindow(labels.time(settings.quietHours[i].from), labels.time(settings.quietHours[i].to)),
            ),
            subtitle: Text(
              '${[for (final d in settings.quietHours[i].days) labels.format.weekdayShort(Weekday.fromIso(d))].join(' ')} · '
              '${switch (settings.quietHours[i].mode) {
                QuietHoursMode.defer => l.notifQuietDefer,
                QuietHoursMode.silent => l.notifQuietSilent,
                QuietHoursMode.drop => l.notifQuietDrop,
              }}',
            ),
            onTap: () async {
              final w = await showQuietHoursEditor(context, settings.quietHours[i]);
              if (w == null) return;
              final next = [...settings.quietHours]..[i] = w;
              await _patch(ref, {
                'quietHours': [for (final x in next) x.toJson()],
              });
            },
            trailing: IconButton(
              tooltip: l.actionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                final next = [...settings.quietHours]..removeAt(i);
                unawaited(
                  _patch(ref, {
                    'quietHours': [for (final x in next) x.toJson()],
                  }),
                );
              },
            ),
          ),
        // ---- Delivery defaults
        SectionHeader(l.notifDelivery),
        SwitchListTile(
          title: Text(l.notifBannerInApp),
          value: settings.bannerInApp,
          onChanged: (v) => unawaited(_patch(ref, {'bannerInApp': v})),
        ),
        ListTile(
          title: Text(l.notifSnoozePresets),
          subtitle: Text(settings.snoozePresets.map(l.notifMinutesValue).join(', ')),
          onTap: () async {
            final text = await promptText(
              context,
              title: l.notifSnoozePresets,
              initial: settings.snoozePresets.join(', '),
            );
            if (text == null) return;
            final values = [for (final p in text.split(',')) ?int.tryParse(p.trim())]
                .where((v) => v > 0 && v <= 10080)
                .toList();
            if (values.isNotEmpty) await _patch(ref, {'snoozePresets': values});
          },
        ),
        ListTile(
          title: Text(l.notifDefaultLateness),
          trailing: DropdownButton<int>(
            value: const [15, 30, 60, 120].contains(settings.latenessMinutes) ? settings.latenessMinutes : 30,
            onChanged: (v) => unawaited(_patch(ref, {'latenessMinutes': v})),
            items: [
              for (final m in const [15, 30, 60, 120]) DropdownMenuItem(value: m, child: Text(l.notifMinutesValue(m))),
            ],
          ),
        ),
        ListTile(
          title: Text(l.notifMaxNag),
          subtitle: Slider(
            value: settings.maxNagRepeats.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '${settings.maxNagRepeats}',
            onChanged: (v) => unawaited(_patch(ref, {'maxNagRepeats': v.round()})),
          ),
        ),
        ListTile(
          title: Text(l.notifDateOnlyTime),
          trailing: Text(labels.time(settings.effectiveDateOnlyTime)),
          onTap: () async {
            final t = await pickTime(
              context,
              initial: settings.effectiveDateOnlyTime,
              use24h: MediaQuery.alwaysUse24HourFormatOf(context),
            );
            if (t != null) {
              await _patch(ref, {'dateOnlyDefaultTime': t.toIso()});
            }
          },
        ),
        // ---- Digests
        SectionHeader(l.notifDigests),
        for (final kind in DigestTrigger.kinds) _DigestTile(kind: kind, rules: rules, userId: userId),
        SwitchListTile(
          key: const ValueKey('email-digests'),
          secondary: const Icon(Icons.mail_outline),
          title: Text(l.notifEmailDigests),
          subtitle: Text(l.notifEmailDigestsHint),
          value: settings.emailDigests,
          onChanged: (v) => unawaited(
            _patch(ref, {
              'emailDigests': {'enabled': v},
            }),
          ),
        ),
        // ---- Devices
        SectionHeader(l.notifMultiDevice),
        RadioGroup<MultiDevicePolicy>(
          groupValue: settings.multiDevicePolicy,
          onChanged: (v) => unawaited(_patch(ref, {'multiDevicePolicy': v?.wire})),
          child: Column(
            children: [
              for (final p in MultiDevicePolicy.values)
                RadioListTile<MultiDevicePolicy>(
                  value: p,
                  title: Text(switch (p) {
                    MultiDevicePolicy.all => l.notifDeviceAll,
                    MultiDevicePolicy.primary => l.notifDevicePrimary,
                    MultiDevicePolicy.lastActive => l.notifDeviceLastActive,
                  }),
                ),
            ],
          ),
        ),
        if (settings.multiDevicePolicy == MultiDevicePolicy.primary)
          ListTile(
            leading: const Icon(Icons.phone_android),
            title: Text(settings.primaryDeviceId == deviceId ? l.notifThisDeviceIsPrimary : l.notifMakePrimary),
            onTap: settings.primaryDeviceId == deviceId
                ? null
                : () => unawaited(_patch(ref, {'primaryDeviceId': deviceId})),
          ),
        // ---- Badge & privacy
        ListTile(
          title: Text(l.notifBadgePolicy),
          trailing: DropdownButton<String>(
            value: const ['off', 'unread', 'due'].contains(settings.badgePolicy) ? settings.badgePolicy : 'unread',
            onChanged: (v) => unawaited(_patch(ref, {'badgePolicy': v})),
            items: [
              DropdownMenuItem(value: 'off', child: Text(l.notifBadgeOff)),
              DropdownMenuItem(value: 'unread', child: Text(l.notifBadgeUnread)),
              DropdownMenuItem(value: 'due', child: Text(l.notifBadgeDue)),
            ],
          ),
        ),
        SwitchListTile(
          title: Text(l.notifHideContent),
          value: settings.hideContent,
          // Written under the arch §8.5 key and its alias so both readers agree.
          onChanged: (v) => unawaited(
            ref.read(settingsRepositoryProvider).update(SettingsNs.privacy, {
              'hideContentInNotifications': v,
              'hideNotificationContent': v,
            }),
          ),
        ),
        // ---- Mutes
        SectionHeader(l.notifMutes),
        if (mutes.isEmpty)
          ListTile(
            title: Text(
              l.notifMutesNone,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
        for (final m in mutes) MuteTile(mute: m, title: _muteTitle(labels, m)),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.rule),
          title: Text(l.notifDefaultsEntry),
          onTap: () => push(const NotificationDefaultsScreen()),
        ),
        ListTile(
          key: const ValueKey('rule-sets-screen'),
          leading: const Icon(Icons.bookmarks_outlined),
          title: Text(l.notifRuleSets),
          onTap: () => push(const RuleSetsScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.style_outlined),
          title: Text(l.notifProfilesEntry),
          onTap: () => push(const NotificationProfilesScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.monitor_heart_outlined),
          title: Text(l.notifDiagnostics),
          onTap: () => push(const NotificationDiagnosticsScreen()),
        ),
      ],
    );
  }

  static String _muteTitle(NotificationLabels labels, NotificationMute m) => switch (m.targetType) {
    'section' => labels.section(NotificationSection.parse(m.section ?? m.targetId)),
    'rule' => labels.l.notifInboxMuteRule,
    _ => labels.l.notifMuted,
  };
}

class _DigestTile extends ConsumerWidget {
  const _DigestTile({required this.kind, required this.rules, required this.userId});

  final String kind;
  final List<NotificationRule> rules;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final id = DefaultRules.digestRuleId(userId, kind);
    final rule = rules.where((r) => r.id == id).firstOrNull;
    final trigger = rule?.spec.trigger;
    final times = trigger is DigestTrigger ? (trigger.schedule['times'] as List?) : null;
    final time = times == null || times.isEmpty
        ? DefaultRules.digestDefaultTimeFor(userId, kind)
        : (LocalTime.tryParse('${times.first}') ?? DefaultRules.digestDefaultTimeFor(userId, kind));
    final enabled = rule?.enabled ?? false;
    Future<void> save({required bool on, LocalTime? at}) => ref
        .read(notificationRulesRepositoryProvider)
        .setDigest(kind: kind, enabled: on, spec: DefaultRules.digestSpec(kind, at ?? time));
    return SwitchListTile(
      title: Text(labels.digestTitle(kind)),
      subtitle: InkWell(
        onTap: () async {
          final t = await pickTime(context, initial: time, use24h: MediaQuery.alwaysUse24HourFormatOf(context));
          if (t != null) await save(on: true, at: t);
        },
        child: Text(l.notifDigestAt(labels.time(time))),
      ),
      value: enabled,
      onChanged: (v) => unawaited(save(on: v)),
    );
  }
}

/// Quiet-hours window editor (days, from, to, mode).
Future<QuietHoursWindow?> showQuietHoursEditor(BuildContext context, QuietHoursWindow? initial) =>
    showAppSheet<QuietHoursWindow>(
      context,
      title: context.l10n.notifQuietHours,
      builder: (_) => _QuietHoursEditor(
        initial:
            initial ?? QuietHoursWindow(days: const [1, 2, 3, 4, 5, 6, 7], from: LocalTime(22, 0), to: LocalTime(7, 0)),
      ),
    );

class _QuietHoursEditor extends StatefulWidget {
  const _QuietHoursEditor({required this.initial});

  final QuietHoursWindow initial;

  @override
  State<_QuietHoursEditor> createState() => _QuietHoursEditorState();
}

class _QuietHoursEditorState extends State<_QuietHoursEditor> {
  late QuietHoursWindow _w = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WeekdayChips(
            selected: _w.days.toSet(),
            onChanged: (d) => setState(() => _w = _w.copyWith(days: d.toList()..sort())),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.notifFrom),
            trailing: Text(labels.time(_w.from)),
            onTap: () async {
              final t = await pickTime(context, initial: _w.from, use24h: use24h);
              if (t != null) setState(() => _w = _w.copyWith(from: t));
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.notifTo),
            trailing: Text(labels.time(_w.to)),
            onTap: () async {
              final t = await pickTime(context, initial: _w.to, use24h: use24h);
              if (t != null) setState(() => _w = _w.copyWith(to: t));
            },
          ),
          DropdownButtonFormField<QuietHoursMode>(
            initialValue: _w.mode,
            decoration: InputDecoration(labelText: l.notifQuietMode),
            onChanged: (m) => setState(() => _w = _w.copyWith(mode: m)),
            items: [
              DropdownMenuItem(value: QuietHoursMode.defer, child: Text(l.notifQuietDefer)),
              DropdownMenuItem(value: QuietHoursMode.silent, child: Text(l.notifQuietSilent)),
              DropdownMenuItem(value: QuietHoursMode.drop, child: Text(l.notifQuietDrop)),
            ],
          ),
          const SizedBox(height: Space.lg),
          FilledButton(onPressed: _w.days.isEmpty ? null : () => Navigator.pop(context, _w), child: Text(l.actionSave)),
        ],
      ),
    );
  }
}
