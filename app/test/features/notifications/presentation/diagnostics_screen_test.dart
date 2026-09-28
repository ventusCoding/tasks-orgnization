import 'dart:convert';

import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart';
import 'package:everslot/features/notifications/presentation/diagnostics_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

/// Notification diagnostics (T7.2.21).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6)));
  tearDown(() => h.dispose());

  const secretTitle = 'Secret meeting with Sam';
  const secretNote = 'salary talk';

  Future<NotificationDiagnostics> diagnosticsAfterReplan() async {
    final source = InMemoryNotificationTargetSource(
      section: 'planner',
      targets: [
        NotificationTarget(
          type: NotificationTargetType.task,
          id: 'm',
          section: NotificationSection.planner,
          title: secretTitle,
          occurrenceKey: '2026-09-22T08:00',
          start: DateTime.utc(2026, 9, 22, 8),
          end: DateTime.utc(2026, 9, 22, 9),
          status: 'scheduled',
          variables: const {'notes_excerpt': secretNote},
        ),
      ],
    );
    addTearDown(source.dispose);
    h.read(notificationRegistryProvider).registerSource(source);
    await seedNotificationDefaults(h.read);
    final report = await h.read(notificationPipelineProvider).run('test');
    expect(report.next, isNotEmpty);
    expect(report.next.first.inboxTitle, secretTitle);
    return NotificationDiagnostics(
      capabilities: const NotificationCapabilities(
        platform: 'android',
        notifications: true,
      ),
      osPending: 2,
      scheduledOs: 2,
      tracked: 0,
      snoozes: 0,
      mismatches: 0,
      budget: ScheduleBudget.android,
      report: report,
      pushAvailable: false,
    );
  }

  test(
    'the copied export holds ids and counts only — never titles or bodies',
    () async {
      final d = await diagnosticsAfterReplan();
      final json = jsonEncode(d.toJson());
      expect(json, isNot(contains(secretTitle)));
      expect(json, isNot(contains(secretNote)));
      expect(json, isNot(contains('Secret')));
      final map = jsonDecode(json) as Map<String, Object?>;
      expect(map['osPending'], 2);
      expect((map['next']! as List).first, containsPair('section', 'planner'));
    },
  );

  testWidgets(
    'shows capabilities, budget, coverage, next firings; copies without content',
    (tester) async {
      final d = await tester.runAsync(diagnosticsAfterReplan);
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      final scoped = TestHarness.create(
        now: DateTime.utc(2026, 9, 22, 6),
        overrides: [
          notificationDiagnosticsProvider.overrideWith((ref) async => d!),
        ],
      );
      addTearDown(scoped.dispose);
      await pumpInApp(tester, scoped, const NotificationDiagnosticsScreen());
      await tester.pump();
      await tester.pump();
      expect(find.text('Notifications allowed'), findsOneWidget);
      expect(find.text('Exact alarms'), findsOneWidget);
      expect(find.textContaining('Budget'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Copy diagnostics'), 200);
      await tester.tap(find.text('Copy diagnostics'));
      await tester.pump();
      await tester.pump();
      expect(clipboard, isNotNull);
      expect(clipboard, isNot(contains(secretTitle)));
      expect(clipboard, contains('osPending'));
      expect(
        find.text('Diagnostics copied (no content included)'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
