import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/notification_contributions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sources and handlers registered at runtime are visible after a first read', () async {
    final h = TestHarness.create();
    addTearDown(h.dispose);
    expect(h.read(notificationTargetSourcesProvider), isEmpty);
    expect(h.read(notificationActionHandlersProvider), isEmpty);

    final source = InMemoryNotificationTargetSource(section: 'planner');
    addTearDown(source.dispose);
    final handler = CallbackActionHandler(
      actionIds: {NotificationActionIds.done},
      targetTypes: {NotificationTargetType.task},
      onHandle: (_) async => NotificationActionResult.ok,
    );
    h.read(notificationRegistryProvider)
      ..registerSource(source)
      ..registerActionHandler(handler);
    await Future<void>.delayed(Duration.zero);

    expect(h.read(notificationTargetSourcesProvider), [source]);
    expect(h.read(notificationActionHandlersProvider), [handler]);
    expect(
      findActionHandler(h.read(notificationActionHandlersProvider), 'done', NotificationTargetType.task),
      same(handler),
    );
    expect(findActionHandler(h.read(notificationActionHandlersProvider), 'done', NotificationTargetType.habit), isNull);

    h.read(notificationRegistryProvider).unregisterSource(source);
    await Future<void>.delayed(Duration.zero);
    expect(h.read(notificationTargetSourcesProvider), isEmpty);
  });
}
