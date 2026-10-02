import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/attachments/application/attachment_previews.dart';
import 'package:everslot/features/notifications/application/local_notifications_port.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import 'pipeline_and_actions_test.dart' show gym;

class _FakePreviews extends AttachmentPreviews {
  _FakePreviews(super._ref);

  final images = <String, String>{};
  final asked = <String>[];

  @override
  Future<String?> cachedImage(String ownerType, String ownerId) async {
    asked.add('$ownerType:$ownerId');
    return images['$ownerType:$ownerId'];
  }
}

/// Rich notifications (T7.2.26): cached attachment images, subtitles, redaction.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  late _FakePreviews previews;
  late InMemoryNotificationTargetSource source;
  late InMemoryLocalNotificationsPort port;

  setUp(() async {
    h = TestHarness.create(
      now: DateTime.utc(2026, 9, 22, 6),
      overrides: [attachmentPreviewsProvider.overrideWith((ref) => previews = _FakePreviews(ref))],
    );
    final target = gym();
    source = InMemoryNotificationTargetSource(
      section: 'planner',
      targets: [
        NotificationTarget(
          type: target.type,
          id: target.id,
          section: target.section,
          title: target.title,
          occurrenceKey: target.occurrenceKey,
          start: target.start,
          end: target.end,
          status: target.status,
          guard: target.guard,
          defaultActions: target.defaultActions,
          variables: const {'category': 'Health'},
        ),
      ],
    );
    h.read(notificationRegistryProvider).registerSource(source);
    port = h.read(localNotificationsPortProvider) as InMemoryLocalNotificationsPort;
    await seedNotificationDefaults(h.read);
    h.read(attachmentPreviewsProvider);
  });
  tearDown(() async {
    await source.dispose();
    await h.dispose();
  });

  Future<List<OsNotificationRequest>> replan() async {
    await h.read(notificationPipelineProvider).run('test');
    return port.scheduled.values.toList();
  }

  test('a cached image is attached (looked up once per target) with the category as subtitle', () async {
    previews.images['task:gym'] = '/cache/gym.jpg';
    final requests = await replan();
    expect(requests, hasLength(2));
    expect(requests.map((r) => r.imagePath).toSet(), {'/cache/gym.jpg'});
    expect(requests.map((r) => r.subtitle).toSet(), {'Health'});
    expect(previews.asked.where((k) => k == 'task:gym'), hasLength(1));
  });

  test('no cached file → text only; a thumbnail cached later re-issues the reminders', () async {
    expect((await replan()).map((r) => r.imagePath).toSet(), {null});
    previews.images['task:gym'] = '/cache/gym.jpg';
    final calls = port.platformCalls;
    expect((await replan()).map((r) => r.imagePath).toSet(), {'/cache/gym.jpg'});
    expect(port.platformCalls, greaterThan(calls));
  });

  test('hide content: no image, no subtitle', () async {
    previews.images['task:gym'] = '/cache/gym.jpg';
    await h.read(settingsRepositoryProvider).update(SettingsNs.privacy, {'hideContentInNotifications': true});
    final requests = await replan();
    expect(requests.map((r) => r.imagePath).toSet(), {null});
    expect(requests.map((r) => r.subtitle).toSet(), {null});
  });
}
