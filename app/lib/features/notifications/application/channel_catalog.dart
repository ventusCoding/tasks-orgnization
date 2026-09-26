import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notification_texts_l10n.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';

/// Android channels (section × profile, versioned ids) and iOS categories (T7.2.02 / T7.2.03).
abstract final class ChannelCatalog {
  static const foregroundSilent = 'dl.foreground.silent.v1';
  static const quiet = 'dl.quiet.v1';
  static const digest = 'dl.digest.v1';
  static const system = 'dl.system.v1';

  static String groupId(NotificationSection s) => 'dl.group.${s.wire}';

  static List<OsChannelGroup> groups(AppLocalizations l) => [
    for (final s in NotificationSection.values) OsChannelGroup(groupId(s), sectionLabelOf(l, s)),
  ];

  static String channelId(NotificationSection section, String profileKey, int version) =>
      'dl.${section.wire}.$profileKey.v$version';

  /// Every channel the app needs for [profiles] plus the ids of superseded versions to delete.
  static ({List<OsChannel> channels, Set<String> obsolete}) channels(List<NotificationProfile> profiles, AppLocalizations l) {
    final standard = BuiltinProfiles.specs[BuiltinProfiles.standard]!;
    final out = <OsChannel>[];
    final obsolete = <String>{};
    final seen = <String>{};
    void add(OsChannel c) {
      if (seen.add(c.id)) out.add(c);
    }

    final all = [
      ...profiles,
      if (!profiles.any((p) => p.code == BuiltinProfiles.standard))
        NotificationProfile(id: 'standard', code: BuiltinProfiles.standard, name: 'standard', isBuiltin: true, spec: standard),
    ];
    for (final section in NotificationSection.itemSections) {
      for (final p in all) {
        final d = p.spec.delivery;
        final version = p.spec.channelVersion;
        final name = p.isBuiltin && p.code != null ? builtinProfileName(l, p.code!) : p.name;
        add(
          OsChannel(
            id: channelId(section, p.channelKey, version),
            name: l.notifChannelName(sectionLabelOf(l, section), name),
            groupId: groupId(section),
            importance: NotificationImportance.tryParse(d.importance ?? standard.delivery.importance) ??
                NotificationImportance.normal,
            sound: d.sound ?? standard.delivery.sound ?? 'default',
            vibration: d.vibration ?? standard.delivery.vibration ?? 'default',
          ),
        );
        for (var v = 1; v < version; v++) {
          obsolete.add(channelId(section, p.channelKey, v));
        }
      }
    }
    add(OsChannel(id: quiet, name: l.notifChannelQuiet, groupId: groupId(NotificationSection.system), importance: NotificationImportance.low, sound: 'none', vibration: 'none'));
    add(OsChannel(id: digest, name: l.notifChannelDigest, groupId: groupId(NotificationSection.system), importance: NotificationImportance.low, sound: 'none'));
    add(OsChannel(id: system, name: l.notifChannelSystem, groupId: groupId(NotificationSection.system), importance: NotificationImportance.normal));
    add(
      OsChannel(
        id: foregroundSilent,
        name: l.notifChannelForeground,
        groupId: groupId(NotificationSection.system),
        importance: NotificationImportance.low,
        sound: 'none',
        vibration: 'none',
        showBadge: false,
      ),
    );
    return (channels: out, obsolete: obsolete.difference(seen));
  }

  /// iOS category id for an ordered action list (`c.done.snooze.skip`, `c.open.nag`…).
  static String categoryIdFor(List<String> actions, {bool nag = false}) =>
      'c.${actions.isEmpty ? 'none' : actions.join('.')}${nag ? '.nag' : ''}';

  /// Maps action ids to OS actions (Android shows the first 3).
  static List<OsAction> osActions(
    List<String> actions,
    AppLocalizations l, {
    required List<NotificationActionHandler> handlers,
    NotificationTargetType? targetType,
    bool authenticationRequired = false,
  }) => [
    for (final id in actions)
      OsAction(
        id: id,
        title: actionLabelOf(l, id),
        textInput: NotificationActionIds.textInput.contains(id),
        placeholder: NotificationActionIds.textInput.contains(id) ? l.notifActionInputPlaceholder : null,
        buttonTitle: NotificationActionIds.textInput.contains(id) ? l.notifActionSend : null,
        // Open-type actions, and feature actions nobody registered yet, bring the app forward.
        foreground: NotificationActionIds.foreground.contains(id) ||
            (!NotificationActionIds.generic.contains(id) && findActionHandler(handlers, id, targetType) == null),
        authenticationRequired: authenticationRequired && !NotificationActionIds.generic.contains(id),
      ),
  ];

  /// Categories for every action combination in use (+ built-in combos), capped at 50.
  static List<OsCategory> categories(
    Iterable<(List<String> actions, bool nag)> combos,
    AppLocalizations l, {
    required List<NotificationActionHandler> handlers,
  }) {
    final byId = <String, OsCategory>{};
    void add(List<String> actions, bool nag) {
      final id = categoryIdFor(actions, nag: nag);
      byId.putIfAbsent(
        id,
        () => OsCategory(id: id, actions: osActions(actions, l, handlers: handlers), customDismiss: nag),
      );
    }

    for (final spec in BuiltinProfiles.specs.values) {
      final actions = spec.delivery.actions ?? const <String>[];
      add(actions, false);
      add(actions, true);
    }
    add(const [NotificationActionIds.open], false);
    for (final (actions, nag) in combos) {
      if (byId.length >= 50) break;
      add(actions, nag);
    }
    return byId.values.toList();
  }
}
