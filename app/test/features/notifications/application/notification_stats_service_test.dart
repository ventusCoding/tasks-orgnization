import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_stats_service.dart';
import 'package:everslot/features/notifications/data/inbox_repository.dart';
import 'package:everslot/features/notifications/domain/notification_stats.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/notification_stats_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 9, 22, 12);
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: now));
  tearDown(() => h.dispose());

  Future<void> deliver(int count, {required String rule, DateTime? from, bool dismiss = false}) async {
    final repo = h.read(inboxRepositoryProvider);
    for (var i = 0; i < count; i++) {
      final dk = '$rule-$i-${from?.day ?? 0}';
      await repo.upsertDelivered(
        InboxDelivery(
          dedupeKey: dk,
          category: InboxCategory.reminder,
          title: 'Water',
          fireAt: (from ?? now).subtract(Duration(hours: 2 + i)),
          ruleId: rule,
          sourceType: 'habit',
          sourceId: 'water',
          section: NotificationSection.habits,
        ),
      );
      if (dismiss) {
        final row = (await repo.statsRows(from: now.subtract(const Duration(days: 400))))
            .firstWhere((r) => r.dedupeKey == dk);
        await repo.dismiss(row.id);
      }
    }
  }

  test('load: dismissed rows count, noisy rules surface, old days come from the rollup', () async {
    await deliver(12, rule: 'noisy');
    await deliver(2, rule: 'calm', dismiss: true);
    // 85 days ago: older than the rollup threshold (rolled up on the first load).
    await deliver(3, rule: 'calm', from: now.subtract(const Duration(days: 85)));
    final service = h.read(notificationStatsServiceProvider);
    var report = await service.load(days: 30, by: StatsGroup.rule);
    expect({for (final r in report.rows) r.key: r.delivered}, {'noisy': 12, 'calm': 2});
    expect(report.rows.firstWhere((r) => r.key == 'calm').dismissed, 2);
    expect(report.noisy.map((n) => n.ruleId), ['noisy']);

    final rollup = await service.rollUp();
    expect(rollup.through, isNotNull);
    report = await service.load(days: 90, by: StatsGroup.rule);
    expect(report.rows.firstWhere((r) => r.key == 'calm').delivered, 5, reason: '2 live + 3 rolled up');
    expect((await service.readRollup()).days, isNotEmpty, reason: 'persisted in local_kv');
  });

  testWidgets('the statistics screen lists rules and the noisy-rule card', (tester) async {
    await tester.runAsync(() => deliver(12, rule: 'noisy'));
    await pumpInApp(tester, h, const NotificationStatsScreen());
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('noisy-noisy')), findsOneWidget);
    expect(find.textContaining('You ignore 100 %'), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-noisy')), findsOneWidget);
  });
}
