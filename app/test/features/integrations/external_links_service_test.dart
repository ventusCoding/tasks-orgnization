import 'dart:async';

import 'package:everslot/app/app.dart';
import 'package:everslot/app/router.dart';
import 'package:everslot/features/auth/application/auth_binding.dart';
import 'package:everslot/features/integrations/application/external_links_service.dart';
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/application/integration_providers.dart';
import 'package:everslot/features/integrations/domain/external_link.dart';
import 'package:everslot/features/integrations/integrations_startup.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

class FakeLinkSource implements LinkSource {
  FakeLinkSource({this.initial});

  Uri? initial;
  final controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> initialLink() async => initial;

  @override
  Stream<Uri> get links => controller.stream;
}

Future<String> createTask(TestHarness h, {bool deleted = false}) async {
  final repo = h.read(tasksRepositoryProvider);
  final result = await repo.create(
    Task(id: '', seriesId: '', title: 'Gym', startLocal: LocalDateTime.of(2026, 9, 22, 8), durationMinutes: 60),
  );
  if (deleted) await repo.delete(result.taskId);
  return result.taskId;
}

void main() {
  group('ExternalLinksService', () {
    late TestHarness h;
    late FakeLinkSource source;
    late List<IntegrationUiEvent> events;
    late StreamSubscription<IntegrationUiEvent> sub;

    Future<void> boot({Uri? initial}) async {
      source = FakeLinkSource(initial: initial);
      h = TestHarness.create(overrides: [linkSourceProvider.overrideWithValue(source)]);
      events = [];
      sub = h.read(integrationUiEventsProvider).stream.listen(events.add);
    }

    tearDown(() async {
      await sub.cancel();
      await source.controller.close();
      await h.dispose();
    });

    test('cold start opens the launch link', () async {
      await boot(initial: Uri.parse('everslot://habits'));
      await h.read(externalLinksServiceProvider).start();
      await pumpEventQueue();
      expect(events, [const OpenPathUiEvent('/habits', asRoot: true)]);
    });

    test('warm links open once even when reported twice', () async {
      await boot(initial: Uri.parse('everslot://inbox'));
      await h.read(externalLinksServiceProvider).start();
      source.controller.add(Uri.parse('everslot://inbox')); // stream replay of the launch link
      await pumpEventQueue();
      h.clock.advance(const Duration(seconds: 10));
      source.controller.add(Uri.parse('everslot://plan/week?date=2026-09-22'));
      await pumpEventQueue();
      expect(events, [
        const OpenPathUiEvent('/inbox'),
        const OpenPathUiEvent('/plan/week?date=2026-09-22', asRoot: true),
      ]);
    });

    test('a link to a deleted task opens the Trash', () async {
      await boot();
      final id = await createTask(h, deleted: true);
      final decision = await h.read(externalLinksServiceProvider).handle(Uri.parse('everslot://task/$id'));
      await pumpEventQueue();
      expect(decision, OpenPath('/task/$id'));
      expect(events, [const OpenPathUiEvent('/settings/trash'), const NoticeUiEvent(IntegrationNotice.inTrash)]);
    });

    test('a link to a live task opens it', () async {
      await boot();
      final id = await createTask(h);
      await h.read(externalLinksServiceProvider).handle(Uri.parse('everslot://task/$id?occ=2026-09-22T08%3A00'));
      await pumpEventQueue();
      expect(events, [OpenPathUiEvent('/task/$id?occ=2026-09-22T08%3A00')]);
    });

    test('invalid links show a notice; auth callbacks are ignored', () async {
      await boot();
      final service = h.read(externalLinksServiceProvider);
      await service.handle(Uri.parse('everslot://task/../../dev'));
      h.clock.advance(const Duration(seconds: 5));
      await service.handle(Uri.parse('everslot://auth-callback?code=1'));
      await pumpEventQueue();
      expect(events, [const NoticeUiEvent(IntegrationNotice.linkNotFound)]);
    });

    test('commands go to their registered handler', () async {
      await boot();
      final seen = <LinkCommand>[];
      h.read(linkCommandRegistryProvider).register('next', (c) async => seen.add(c));
      await h.read(externalLinksServiceProvider).handle(Uri.parse('everslot://do/next'));
      expect(seen, [const LinkCommand('next')]);
    });

    test('events raised before the UI listens are buffered', () async {
      final bus = BufferedEventBus<int>()
        ..add(1)
        ..add(2);
      final received = <int>[];
      final s = bus.stream.listen(received.add);
      await pumpEventQueue();
      bus.add(3);
      await pumpEventQueue();
      expect(received, [1, 2, 3]);
      await s.cancel();
      await bus.close();
    });
  });

  group('cold start through the router', () {
    Future<void> openFromColdStart(WidgetTester tester, String link, String expected, {bool deletedTask = false}) async {
      final source = FakeLinkSource(initial: Uri.parse(link));
      final h = TestHarness.create(
        overrides: [
          linkSourceProvider.overrideWithValue(source),
          accountStartupProvider.overrideWithValue((_) async {}),
        ],
      );
      if (deletedTask) {
        final id = await tester.runAsync(() => createTask(h, deleted: true));
        source.initial = Uri.parse(link.replaceFirst('{id}', id!));
      }
      await tester.pumpWidget(UncontrolledProviderScope(container: h.container, child: const EverslotApp()));
      await tester.runAsync(() async {
        await startIntegrations(h.container);
        // The launch link may need the database (deleted-item check): wait until it is handled.
        await h.read(externalLinksServiceProvider).start();
      });
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final router = h.read(routerProvider);
      expect(router.state.uri.toString(), expected);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await source.controller.close();
        await h.dispose();
      });
    }

    testWidgets('habits tab', (tester) => openFromColdStart(tester, 'everslot://habits', '/habits'));

    testWidgets('inbox', (tester) => openFromColdStart(tester, 'everslot://inbox', '/inbox'));

    testWidgets(
      'deleted task → Trash',
      (tester) => openFromColdStart(tester, 'everslot://task/{id}', '/settings/trash', deletedTask: true),
    );
  });
}
