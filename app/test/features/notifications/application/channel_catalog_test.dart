import 'package:everslot/features/notifications/application/channel_catalog.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fr = lookupAppLocalizations(const Locale('fr'));

  List<NotificationProfile> builtins() => [
    for (final e in BuiltinProfiles.specs.entries)
      NotificationProfile(
        id: 'id-${e.key}',
        code: e.key,
        name: e.key,
        isBuiltin: true,
        spec: e.value,
      ),
  ];

  group('Android channels (T7.2.02)', () {
    test('one channel per section × profile with versioned ids, grouped by section', () {
      final catalog = ChannelCatalog.channels(builtins(), en);
      final ids = {for (final c in catalog.channels) c.id};
      for (final section in NotificationSection.itemSections) {
        for (final code in BuiltinProfiles.codes) {
          expect(ids, contains('dl.${section.wire}.$code.v1'));
        }
      }
      expect(
        ids,
        containsAll([
          ChannelCatalog.system,
          ChannelCatalog.digest,
          ChannelCatalog.quiet,
          ChannelCatalog.foregroundSilent,
        ]),
      );
      final plannerStandard = catalog.channels.firstWhere(
        (c) => c.id == 'dl.planner.standard.v1',
      );
      expect(plannerStandard.groupId, 'dl.group.planner');
      expect(plannerStandard.name, 'Plan · Standard');
      expect(catalog.obsolete, isEmpty);
      expect(ChannelCatalog.groups(en).map((g) => g.id), [
        for (final s in NotificationSection.values) 'dl.group.${s.wire}',
      ]);
    });

    test('a Gentle channel never makes a sound; the quiet and foreground channels are silent', () {
      final channels = {
        for (final c in ChannelCatalog.channels(builtins(), en).channels)
          c.id: c,
      };
      final gentle = channels['dl.habits.gentle.v1']!;
      expect(
        (gentle.sound, gentle.vibration, gentle.importance),
        ('none', 'none', NotificationImportance.low),
      );
      expect(
        channels['dl.planner.nag.v1']!.importance,
        NotificationImportance.high,
      );
      expect(channels[ChannelCatalog.quiet]!.sound, 'none');
      expect(channels[ChannelCatalog.foregroundSilent]!.showBadge, isFalse);
    });

    test('custom profiles get stable keys; a version bump deletes the superseded channel', () {
      final custom = NotificationProfile(
        id: '0192f6c8-aaaa-7bbb-8ccc-dddddddddddd',
        name: 'Loud',
        spec: const ProfileSpec(
          delivery: DeliverySpec(importance: 'high', sound: 'bell'),
          channelVersion: 3,
        ),
      );
      final catalog = ChannelCatalog.channels([...builtins(), custom], en);
      final ids = {for (final c in catalog.channels) c.id};
      expect(custom.channelKey, 'p0192f6c8');
      expect(ids, contains('dl.planner.p0192f6c8.v3'));
      expect(
        catalog.obsolete,
        containsAll([
          'dl.planner.p0192f6c8.v1',
          'dl.planner.p0192f6c8.v2',
          'dl.quit.p0192f6c8.v2',
        ]),
      );
      expect(catalog.obsolete, isNot(contains('dl.planner.p0192f6c8.v3')));
    });

    test('channel names follow the language', () {
      final channels = ChannelCatalog.channels(builtins(), fr).channels;
      expect(
        channels.firstWhere((c) => c.id == ChannelCatalog.system).name,
        fr.notifChannelSystem,
      );
      expect(
        channels.firstWhere((c) => c.id == 'dl.planner.gentle.v1').name,
        fr.notifChannelName(fr.notifSectionPlanner, fr.notifProfileGentle),
      );
    });

    test('the standard channels exist even before profiles are seeded', () {
      final ids = {
        for (final c in ChannelCatalog.channels(const [], en).channels) c.id,
      };
      expect(ids, contains('dl.planner.standard.v1'));
    });
  });

  group('Actions & categories (T7.2.03)', () {
    final done = CallbackActionHandler(
      actionIds: {NotificationActionIds.done, NotificationActionIds.logValue},
      targetTypes: {NotificationTargetType.task, NotificationTargetType.habit},
      onHandle: (_) async => NotificationActionResult.ok,
    );

    test('category ids keep the action order and flag nag chains', () {
      expect(
        ChannelCatalog.categoryIdFor(const ['done', 'snooze', 'skip']),
        'c.done.snooze.skip',
      );
      expect(
        ChannelCatalog.categoryIdFor(const ['snooze', 'done']),
        'c.snooze.done',
      );
      expect(ChannelCatalog.categoryIdFor(const [], nag: true), 'c.none.nag');
    });

    test('text input, foreground and authentication flags', () {
      final actions = {
        for (final a in ChannelCatalog.osActions(
          const ['done', 'log_value', 'open', 'reschedule', 'skip', 'snooze'],
          en,
          handlers: [done],
          targetType: NotificationTargetType.habit,
          authenticationRequired: true,
        ))
          a.id: a,
      };
      expect(actions['log_value']!.textInput, isTrue);
      expect(actions['log_value']!.placeholder, en.notifActionInputPlaceholder);
      expect(actions['log_value']!.buttonTitle, en.notifActionSend);
      expect(
        actions['done']!.foreground,
        isFalse,
        reason: 'handled in the background isolate',
      );
      expect(actions['open']!.foreground, isTrue);
      expect(actions['reschedule']!.foreground, isTrue);
      expect(
        actions['skip']!.foreground,
        isTrue,
        reason: 'no handler registered yet → open the app',
      );
      expect(actions['snooze']!.foreground, isFalse, reason: 'generic action');
      expect(actions['done']!.authenticationRequired, isTrue);
      expect(actions['snooze']!.authenticationRequired, isFalse);
      expect(actions['done']!.title, 'Done');
    });

    test('built-in combinations are registered up front; nag categories get a dismiss callback; cap 50', () {
      final initial = ChannelCatalog.categories(
        const [],
        en,
        handlers: const [],
      );
      final ids = {for (final c in initial) c.id};
      expect(
        ids,
        containsAll(['c.done.snooze.skip', 'c.done.snooze.skip.nag', 'c.open']),
      );
      expect(
        initial
            .firstWhere((c) => c.id == 'c.done.snooze.skip.nag')
            .customDismiss,
        isTrue,
      );
      expect(
        initial.firstWhere((c) => c.id == 'c.done.snooze.skip').customDismiss,
        isFalse,
      );

      final many = [
        for (var i = 0; i < 80; i++) (['done', 'a$i'], false),
      ];
      expect(
        ChannelCatalog.categories(many, en, handlers: const []),
        hasLength(lessThanOrEqualTo(50)),
      );
    });

    test('OS action lists keep every action; the port shows the first three on Android', () {
      final actions = ChannelCatalog.osActions(
        const ['done', 'snooze', 'skip', 'open'],
        en,
        handlers: const [],
      );
      expect(actions.map((a) => a.id), ['done', 'snooze', 'skip', 'open']);
      expect(const OsAction(id: 'x', title: 'X').textInput, isFalse);
    });
  });
}
