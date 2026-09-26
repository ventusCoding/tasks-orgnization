import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart' show seedNotificationDefaults;
import 'package:everslot/features/notifications/domain/default_rules.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/notifications_settings_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 9)));
  tearDown(() => h.dispose());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  Future<Map<String, dynamic>> settingsOf(WidgetTester tester, String ns) async =>
      await tester.runAsync(() => h.read(settingsRepositoryProvider).read(ns)) ?? const {};

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
  }

  Future<void> pumpPage(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    await tester.runAsync(() => seedNotificationDefaults(h.read));
    await pumpInApp(tester, h, const NotificationsSettingsPage(), locale: locale);
    await settle(tester);
  }

  testWidgets('sections: switches write perSection and the default profile is shown', (tester) async {
    await pumpPage(tester);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Sections'), findsOneWidget);
    for (final label in ['Plan', 'Lists', 'Habits', 'Quit']) {
      expect(find.widgetWithText(SwitchListTile, label), findsOneWidget);
    }
    expect(find.text('Default profile: Standard'), findsNWidgets(4));

    await tester.tap(find.widgetWithText(SwitchListTile, 'Habits'));
    await settle(tester);
    final raw = await settingsOf(tester, SettingsNs.notifications);
    expect((raw['perSection'] as Map)['habits'], {'enabled': false});
    expect(h.read(notificationSettingsProvider).sectionEnabled(NotificationSection.habits), isFalse);
    expect(h.read(notificationSettingsProvider).sectionEnabled(NotificationSection.planner), isTrue);
  });

  testWidgets('pause all for 1 hour, then resume', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.widgetWithText(ActionChip, '1 hour'));
    await settle(tester);
    expect(h.read(notificationSettingsProvider).pausedUntil, DateTime.utc(2026, 9, 22, 10));
    expect(find.textContaining('Paused until'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await settle(tester);
    expect(h.read(notificationSettingsProvider).pausedUntil, isNull);
    expect(find.widgetWithText(ActionChip, '1 hour'), findsOneWidget);
  });

  testWidgets('quiet hours: add a window with the editor, then delete it', (tester) async {
    await pumpPage(tester);
    expect(find.text('No quiet hours'), findsOneWidget);

    await tester.tap(find.byTooltip('Add quiet hours'));
    await settle(tester);
    await tester.tap(find.widgetWithText(DropdownButtonFormField<QuietHoursMode>, 'Defer to the end'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deliver silently').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);

    final windows = h.read(notificationSettingsProvider).quietHours;
    expect(windows, hasLength(1));
    expect(windows.single.days, [1, 2, 3, 4, 5, 6, 7]);
    expect(windows.single.mode, QuietHoursMode.silent);
    expect(windows.single.from.hour, 22);
    expect(windows.single.to.hour, 7);
    expect(find.textContaining('Deliver silently'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    expect(h.read(notificationSettingsProvider).quietHours, isEmpty);
    expect(find.text('No quiet hours'), findsOneWidget);
  });

  testWidgets('delivery defaults: in-app banners and hide content', (tester) async {
    await pumpPage(tester);
    await scrollTo(tester, find.widgetWithText(SwitchListTile, 'In-app banners'));
    await tester.tap(find.widgetWithText(SwitchListTile, 'In-app banners'));
    await settle(tester);
    expect(h.read(notificationSettingsProvider).bannerInApp, isFalse);

    await scrollTo(tester, find.widgetWithText(SwitchListTile, 'Hide content in notifications'));
    await tester.tap(find.widgetWithText(SwitchListTile, 'Hide content in notifications'));
    await settle(tester);
    final privacy = await settingsOf(tester, SettingsNs.privacy);
    expect(privacy['hideContentInNotifications'], isTrue);
    expect(privacy['hideNotificationContent'], isTrue);
    expect(h.read(notificationSettingsProvider).hideContent, isTrue);
  });

  testWidgets('digests: turning the morning agenda on creates its rule', (tester) async {
    await pumpPage(tester);
    await scrollTo(tester, find.widgetWithText(SwitchListTile, 'Today’s agenda'));
    await tester.tap(find.widgetWithText(SwitchListTile, 'Today’s agenda'));
    await settle(tester);
    final id = DefaultRules.digestRuleId('user-1', 'daily_agenda');
    final rule = await tester.runAsync(() => h.read(notificationRulesRepositoryProvider).byId(id));
    expect(rule, isNotNull);
    expect(rule!.enabled, isTrue);
    expect(rule.section, NotificationSection.system);
  });

  testWidgets('multi-device policy: primary device', (tester) async {
    await pumpPage(tester);
    await scrollTo(tester, find.text('Primary device only'));
    await tester.tap(find.text('Primary device only'));
    await settle(tester);
    expect(h.read(notificationSettingsProvider).multiDevicePolicy, MultiDevicePolicy.primary);

    await scrollTo(tester, find.text('Use this device as primary'));
    await tester.tap(find.text('Use this device as primary'));
    await settle(tester);
    expect(h.read(notificationSettingsProvider).primaryDeviceId, 'device-test');
    expect(find.text('This device is the primary device'), findsOneWidget);
  });

  testWidgets('active mutes are listed with Unmute', (tester) async {
    await tester.runAsync(
      () => h.read(notificationMutesRepositoryProvider).mute(
        targetType: 'section',
        section: 'habits',
        until: DateTime.utc(2026, 9, 23, 8),
      ),
    );
    await pumpPage(tester);
    await scrollTo(tester, find.text('Unmute'));
    expect(find.widgetWithText(ListTile, 'Habits'), findsOneWidget);

    await tester.tap(find.text('Unmute'));
    await settle(tester);
    expect(find.text('Nothing is muted'), findsOneWidget);
  });

  testWidgets('entry points open the defaults, profiles and diagnostics screens', (tester) async {
    await pumpPage(tester);
    await scrollTo(tester, find.text('Diagnostics'));
    await tester.tap(find.text('Profiles'));
    await settle(tester);
    expect(find.text('Notification profiles'), findsOneWidget);
    expect(find.text('Gentle'), findsOneWidget);
    expect(find.text('Nag until done'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.text('Default reminders'));
    await settle(tester);
    expect(find.text('Timed items'), findsOneWidget);
    expect(find.text('10 min before start · Standard'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.text('Diagnostics'));
    await settle(tester);
    expect(find.text('Notification diagnostics'), findsOneWidget);
    expect(find.text('Notifications allowed'), findsOneWidget);
  });

  testWidgets('Arabic: localized, right-to-left, no overflow', (tester) async {
    await pumpPage(tester, locale: const Locale('ar'));
    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('إيقاف الكل مؤقتًا'), findsOneWidget);
    expect(find.text('الأقسام'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'العادات'), findsOneWidget);
    expect(find.text('ساعات الهدوء'), findsOneWidget);
    final context = tester.element(find.text('الأقسام'));
    expect(Directionality.of(context), TextDirection.rtl);
    // Scroll through the whole page (every row laid out once in RTL).
    await scrollTo(tester, find.byType(Divider));
    expect(tester.takeException(), isNull);
  });
}
