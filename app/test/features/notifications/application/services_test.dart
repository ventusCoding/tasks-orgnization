import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_api.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/notifications/application/in_app_banners.dart';
import 'package:everslot/features/notifications/application/local_scheduler.dart';
import 'package:everslot/features/notifications/application/notification_pipeline.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/application/push/job_uploader.dart';
import 'package:everslot/features/notifications/application/push/push_messaging_port.dart';
import 'package:everslot/features/notifications/application/push/push_service.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/planner/notification_planner.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

NotificationRule ruleFor(String id, int offset, {bool nag = false}) => NotificationRule(
  id: id,
  targetType: RuleTargetType.task,
  targetId: 't1',
  section: NotificationSection.planner,
  spec: NotificationRuleSpec(
    trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: offset),
    repeat: nag ? const RepeatSpec(everyMinutes: 5, maxTimes: 2) : null,
  ),
);

ReplanReport _report(String reason) => ReplanReport(
  at: DateTime.utc(2026),
  duration: Duration.zero,
  reason: reason,
  planned: 0,
  skipped: 0,
  targets: 0,
  scheduler: SchedulerReport.empty,
);

class _FakeJobsApi implements NotificationJobsApi {
  final List<({List<String> targets, List<Map<String, Object?>> jobs, int rev})> calls = [];
  JobUploadResult Function(List<String> targets) respond = (_) => const JobUploadResult(status: 'ok');

  @override
  Future<JobUploadResult> replaceJobs({
    required String deviceId,
    required int sourceRev,
    required List<String> targetKeys,
    required List<Map<String, Object?>> jobs,
  }) async {
    calls.add((targets: targetKeys, jobs: jobs, rev: sourceRev));
    return respond(targetKeys);
  }
}

class _FakeSyncApi implements SyncApi {
  final List<Map<String, Object?>> reports = [];

  @override
  Future<bool> reportDeviceState(String deviceId, Map<String, Object?> state) async {
    reports.add(state);
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationReplanService (T7.2.12)', () {
    test('debounces bursts into one run', () async {
      final reasons = <String>[];
      final service = NotificationReplanService(
        runner: (r) async {
          reasons.add(r);
          return _report(r);
        },
        debounce: const Duration(milliseconds: 30),
      );
      addTearDown(service.dispose);
      service
        ..request('write')
        ..request('write')
        ..request('source:planner');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(reasons, ['source:planner+write']);
    });

    test('single flight: requests during a run coalesce into one follow-up', () async {
      final gate = Completer<void>();
      final reasons = <String>[];
      final service = NotificationReplanService(
        runner: (r) async {
          reasons.add(r);
          if (reasons.length == 1) await gate.future;
          return _report(r);
        },
        debounce: const Duration(milliseconds: 10),
      );
      addTearDown(service.dispose);
      final first = service.flush();
      service
        ..request('a', immediate: true)
        ..request('b', immediate: true);
      gate.complete();
      await first;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(reasons.first, 'manual');
      expect(reasons.length, 2);
      expect(reasons.last, 'a+b');
      expect(service.runs, 2);
    });
  });

  group('JobUploader (T7.4.04)', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6)));
    tearDown(() => h.dispose());

    PlanResult plan() {
      final ctx = PlanningContext(
        now: h.clock.nowUtc(),
        deviceZone: 'UTC',
        zones: h.read(zoneResolverProvider),
        settings: h.read(notificationSettingsProvider),
        rules: [ruleFor('before', -10), ruleFor('nag', 0, nag: true)],
        targets: [
          NotificationTarget(
            type: NotificationTargetType.task,
            id: 't1',
            section: NotificationSection.planner,
            title: 'Gym',
            occurrenceKey: '2026-09-22T08:00',
            start: DateTime.utc(2026, 9, 22, 8),
            notifyMode: NotifyMode.custom,
            guard: NotificationGuard.taskOccurrenceOpen('t1', '2026-09-22T08:00'),
          ),
        ],
        userId: 'user-1',
      );
      return NotificationPlanner.plan(ctx);
    }

    test('job JSON follows the server contract (flat guards, nag guard array, deep link, importance)', () {
      final p = plan().planned;
      final base = JobUploader.jobFor(p.firstWhere((x) => x.ruleId == 'before'));
      expect(base['target_key'], 'task:t1');
      expect(base['guard'], {'kind': 'task_occurrence_open', 'taskId': 't1', 'occurrenceKey': '2026-09-22T08:00'});
      expect(base['importance'], 'default');
      final payload = base['payload']! as Map<String, Object?>;
      expect(payload['deepLink'], startsWith('everslot://task/t1'));
      expect(payload['type'], 'reminder');
      expect(payload['interruptionLevel'], 'active');
      expect((payload['data']! as Map)['dk'], base['dedupe_key']);
      final nag = JobUploader.jobFor(p.firstWhere((x) => x.repeatIdx == 1));
      expect(nag['guard'], isA<List<Object?>>());
      expect((nag['guard']! as List).last, {
        'kind': 'inbox_not_acted',
        'dedupeKey': p.firstWhere((x) => x.ruleId == 'nag').dedupeKey,
      });
      expect((nag['payload']! as Map)['type'], 'nag');
    });

    test('uploads dirty targets, clears them on ok, keeps them on stale and asks for a pull', () async {
      var staleCalls = 0;
      final uploader = JobUploader(db: h.db, clock: h.clock, deviceId: 'device-test', onStale: () => staleCalls++);
      final api = _FakeJobsApi();
      await uploader.markDirty({'task:t1', 'task:gone'});
      expect(await uploader.upload(api, plan(), sourceRev: 42), isTrue);
      expect(api.calls.single.targets, ['task:gone', 'task:t1']);
      expect(api.calls.single.rev, 42);
      expect(api.calls.single.jobs.every((j) => j['target_key'] == 'task:t1'), isTrue);
      expect(await uploader.dirty(), isEmpty);

      api.respond = (_) => const JobUploadResult(status: 'stale', staleTargets: ['task:t1']);
      await uploader.markDirty({'task:t1'});
      expect(await uploader.upload(api, plan(), sourceRev: 41), isFalse);
      expect(staleCalls, 1);
      expect(await uploader.dirty(), {'task:t1'});
    });

    test("'*' uploads everything in one call; errors back off", () async {
      final uploader = JobUploader(db: h.db, clock: h.clock, deviceId: 'device-test');
      final api = _FakeJobsApi()
        ..respond = (_) => const JobUploadResult(status: 'error', errorCode: 'job_cap_exceeded');
      await uploader.markDirty({'task:a'});
      await uploader.markDirty({'*'});
      expect(await uploader.dirty(), {'*'});
      expect(await uploader.upload(api, plan(), sourceRev: 1), isFalse);
      expect(api.calls.single.targets, ['*']);
      expect(await uploader.upload(api, plan(), sourceRev: 1), isFalse);
      expect(api.calls, hasLength(1), reason: 'backoff window');
      h.clock.advance(const Duration(minutes: 5));
      api.respond = (_) => const JobUploadResult(status: 'ok');
      expect(await uploader.upload(api, plan(), sourceRev: 1), isTrue);
    });

    test('more than 200 targets are split into batches', () async {
      final uploader = JobUploader(db: h.db, clock: h.clock, deviceId: 'device-test');
      final api = _FakeJobsApi();
      await uploader.markDirty([for (var i = 0; i < 450; i++) 'task:$i']);
      await uploader.upload(api, PlanResult.empty, sourceRev: 1);
      expect(api.calls.map((c) => c.targets.length), [200, 200, 50]);
    });
  });

  group('PushService (T7.4.01 / T7.4.10)', () {
    test('reports the token and its refreshes, routes sync / foreground / opened messages, signs out', () async {
      final port = FakePushMessagingPort();
      final api = _FakeSyncApi();
      final reporter = DeviceStateReporter(api: () => api, deviceId: 'd', clock: FakeClock(DateTime.utc(2026)));
      var syncs = 0;
      final foreground = <PushMessage>[];
      final opened = <PushMessage>[];
      port.initial = const PushMessage(data: {'type': 'reminder', 'dk': 'k0', 'deepLink': 'everslot://inbox'});
      final service = PushService(
        port: port,
        reporter: reporter,
        onSync: () => syncs++,
        onForegroundReminder: (m) async => foreground.add(m),
        onOpened: (m) async => opened.add(m),
      );
      await service.start(bannerInApp: true);
      await Future<void>.delayed(Duration.zero);
      expect(port.presentation, (alert: false, badge: true, sound: false));
      expect(api.reports.first, {'push_token': 'fake-token', 'push_enabled': true});
      expect(opened.single.dedupeKey, 'k0');
      port.refresh.add('new-token');
      port.messages
        ..add(const PushMessage(data: {'type': 'sync', 'head': '12'}))
        ..add(const PushMessage(data: {'type': 'reminder', 'dk': 'k1'}, title: 'Gym'));
      await Future<void>.delayed(Duration.zero);
      await reporter.flush();
      expect(syncs, 1);
      expect(foreground.single.title, 'Gym');
      expect(api.reports.any((r) => r['push_token'] == 'new-token'), isTrue);
      await service.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(port.deleted, isTrue);
      expect(api.reports.last, {'push_token': null, 'push_enabled': false});
      await service.dispose();
      reporter.dispose();
    });

    test('push is unavailable without Firebase configuration', () {
      final h = TestHarness.create();
      addTearDown(h.dispose);
      expect(h.read(pushAvailableProvider), isFalse);
      expect(h.read(pushMessagingPortProvider), isNull);
    });
  });

  group('In-app banners (T7.3.05)', () {
    test('de-duplicates by key and collapses bursts into one banner', () async {
      final c = InAppBannerController(burstWindow: const Duration(milliseconds: 20));
      addTearDown(c.dispose);
      for (var i = 0; i < 5; i++) {
        c.show(BannerItem(key: 'k$i', title: 'R$i'));
      }
      c.show(const BannerItem(key: 'k0', title: 'dup'));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(c.current.value!.count, 5);
      expect(c.current.value!.titles, ['R0', 'R1', 'R2', 'R3', 'R4']);
      c
        ..dismissCurrent()
        ..show(const BannerItem(key: 'solo', title: 'Solo'))
        ..flushNow();
      expect(c.current.value!.title, 'Solo');
      expect(c.current.value!.collapsed, isFalse);
    });

    test('foreground ticker writes inbox rows and raises banners for fresh firings only', () async {
      final h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 6));
      addTearDown(h.dispose);
      final source = InMemoryNotificationTargetSource(
        section: 'planner',
        targets: [
          NotificationTarget(
            type: NotificationTargetType.task,
            id: 'gym',
            section: NotificationSection.planner,
            title: 'Gym',
            occurrenceKey: '2026-09-22T08:00',
            start: DateTime.utc(2026, 9, 22, 8),
          ),
        ],
      );
      addTearDown(source.dispose);
      h.read(notificationRegistryProvider).registerSource(source);
      await seedNotificationDefaults(h.read);
      await h.read(notificationPipelineProvider).run('test');
      final banners = InAppBannerController(burstWindow: Duration.zero);
      addTearDown(banners.dispose);
      final ticker = ForegroundTicker(
        store: h.read(localScheduleStoreProvider),
        reconciler: h.read(inboxReconcilerProvider),
        banners: banners,
        clock: h.clock,
        bannerEnabled: () => true,
      );
      h.clock.set(DateTime.utc(2026, 9, 22, 7, 50, 30));
      final shown = await ticker.tick();
      expect(shown.single.title, 'Gym');
      expect(shown.single.actions, ['start', 'snooze']);
      expect(await h.read(inboxRepositoryProvider).inbox(), hasLength(1));
      h.clock.set(DateTime.utc(2026, 9, 22, 8, 30));
      expect(await ticker.tick(), isEmpty, reason: 'stale firings only go to the inbox');
      expect(await h.read(inboxRepositoryProvider).inbox(), hasLength(2));
    });
  });
}
