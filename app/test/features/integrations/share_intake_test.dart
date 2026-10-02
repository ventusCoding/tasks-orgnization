import 'dart:async';
import 'dart:io';

import 'package:everslot/features/attachments/application/attachment_transfers.dart' show NetworkKind;
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/application/integration_providers.dart';
import 'package:everslot/features/integrations/data/share_source.dart';
import 'package:everslot/features/integrations/domain/shared_content.dart';
import 'package:everslot/features/planner/application/planner_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../attachments/attachment_domain_test.dart' show pngBytes;
import '../attachments/attachment_test_support.dart';
import '../today/today_test_support.dart';

class FakeShareSource implements ShareSource {
  SharedContent? first;
  final controller = StreamController<SharedContent>.broadcast();
  int resets = 0;

  @override
  Future<SharedContent?> initial() async => first;

  @override
  Stream<SharedContent> get incoming => controller.stream;

  @override
  Future<void> reset() async => resets++;
}

/// T8.2.07: share into Everslot — text → items, destinations, attachments queued offline.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShareIntake (pure)', () {
    test('lines become items, indentation nests, task boxes and bullets are understood', () {
      final nodes = ShareIntake.itemsFor(
        const SharedContent(text: 'Trip\n  - Passport\n  - [x] Tickets\nGroceries'),
        filesTitle: 'files',
      );
      expect(nodes.map((n) => n.text), ['Trip', 'Groceries']);
      expect(nodes.first.children.map((n) => n.text), ['Passport', 'Tickets']);
    });

    test('files alone make one item carrying them; nothing shared → nothing', () {
      final photos = [for (var i = 0; i < 5; i++) SharedFile(path: '/p$i.jpg', kind: SharedFileKind.image)];
      expect(ShareIntake.itemsFor(SharedContent(files: photos), filesTitle: '5 files').single.text, '5 files');
      expect(ShareIntake.itemsFor(const SharedContent(), filesTitle: 'x'), isEmpty);
      expect(SharedContent(files: photos).imageCount, 5);
    });

    test('new list: a heading with nested lines, or first line + the rest', () {
      final nested = ShareIntake.newList(const SharedContent(text: 'Groceries\n  Milk\n  Eggs'), fallbackTitle: 'f');
      expect(nested.title, 'Groceries');
      expect(nested.items.map((n) => n.text), ['Milk', 'Eggs']);
      final flat = ShareIntake.newList(const SharedContent(text: 'Packing\nSocks\nHat'), fallbackTitle: 'f');
      expect(flat.title, 'Packing');
      expect(flat.items.map((n) => n.text), ['Socks', 'Hat']);
      expect(ShareIntake.newList(const SharedContent(), fallbackTitle: '2 files').title, '2 files');
    });

    test('task title / notes; URLs', () {
      const c = SharedContent(text: 'Read this\nhttps://example.com\nlater');
      expect((c.taskTitle, c.taskNotes), ('Read this', 'https://example.com\nlater'));
      expect(const SharedContent(text: 'https://example.com/a').isUrl, isTrue);
      expect(c.isUrl, isFalse);
      expect(SharedContent(text: 'x' * 200).taskTitle!.length, 120);
      expect(
        const SharedContent(
          files: [SharedFile(path: '/a/b/c.pdf', kind: SharedFileKind.file)],
        ).files.single.name,
        'c.pdf',
      );
    });
  });

  group('ShareIntakeService', () {
    late Directory root;
    late Directory sources;
    late TestHarness h;
    late FakeShareSource source;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('share_root');
      sources = await Directory.systemTemp.createTemp('share_src');
      source = FakeShareSource();
      h = TestHarness.create(
        now: DateTime.utc(2026, 9, 22, 10),
        overrides: [
          shareSourceProvider.overrideWithValue(source),
          attachmentFileStoreProvider.overrideWithValue(tempFileStore(root)),
          imageCodecProvider.overrideWithValue(FakeImageCodec()),
          connectivityProbeProvider.overrideWithValue(FakeConnectivity(NetworkKind.offline)),
        ],
      );
    });
    tearDown(() async {
      await h.dispose();
      await root.delete(recursive: true);
      await sources.delete(recursive: true);
    });

    List<SharedFile> photos(int n) => [
      for (var i = 0; i < n; i++)
        SharedFile(path: writeSource(sources, 'p$i.png', pngBytes(40 + i, 30)).path, kind: SharedFileKind.image),
    ];

    test('content waiting at launch or arriving later raises the destination sheet', () async {
      source.first = const SharedContent(text: 'Milk');
      final events = <IntegrationUiEvent>[];
      final sub = h.read(integrationUiEventsProvider).stream.listen(events.add);
      final service = h.read(shareIntakeServiceProvider);
      await service.start();
      source.controller.add(const SharedContent(text: 'Eggs'));
      await pumpEventQueue();
      expect(events, [const ShareReceivedUiEvent(), const ShareReceivedUiEvent()]);
      expect(service.pending!.text, 'Eggs');
      await service.finish();
      expect((service.pending, source.resets), (null, 1));
      await sub.cancel();
    });

    test('a shared calendar file opens the ICS import instead', () async {
      final ics = writeSource(sources, 'cal.ics', 'BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n'.codeUnits);
      final events = <IntegrationUiEvent>[];
      final sub = h.read(integrationUiEventsProvider).stream.listen(events.add);
      h
          .read(shareIntakeServiceProvider)
          .receive(
            SharedContent(
              files: [SharedFile(path: ics.path, kind: SharedFileKind.file)],
            ),
          );
      await pumpEventQueue();
      expect(events.single, isA<IcsReceivedUiEvent>());
      expect((events.single as IcsReceivedUiEvent).fileName, 'cal.ics');
      expect(source.resets, 1);
      await sub.cancel();
    });

    test('5 photos into a list: one item with 5 attachments queued for upload (offline)', () async {
      final list = await h.checklist('Inspiration');
      final service = h.read(shareIntakeServiceProvider);
      final itemId = await service.addToChecklist(SharedContent(files: photos(5)), list);
      final items = await h.read(checklistItemsRepositoryProvider).items(list);
      expect(items.single.id, itemId);
      expect(items.single.text, '5 files');
      final attachments = await h
          .read(attachmentsRepositoryProvider)
          .listFor(AttachmentOwnerType.checklistItem, itemId!);
      expect(attachments, hasLength(5));
    });

    test('text into a list under an item keeps the outline', () async {
      final list = await h.checklist('Trip', items: ['Documents']);
      final docs = await h.itemId(list, 'Documents');
      await h
          .read(shareIntakeServiceProvider)
          .addToChecklist(const SharedContent(text: 'Passport\n  Photo copy\nVisa'), list, parentId: docs);
      final items = await h.read(checklistItemsRepositoryProvider).items(list);
      final passport = items.firstWhere((i) => i.text == 'Passport');
      expect(passport.parentId, docs);
      expect(items.firstWhere((i) => i.text == 'Photo copy').parentId, passport.id);
      expect(items.firstWhere((i) => i.text == 'Visa').parentId, docs);
    });

    test('new list from shared text, with files on the list', () async {
      final id = await h
          .read(shareIntakeServiceProvider)
          .createChecklist(SharedContent(text: 'Groceries\n  Milk\n  Eggs', files: photos(1)));
      final items = await h.read(checklistItemsRepositoryProvider).items(id);
      expect(items.map((i) => i.text).toSet(), {'Milk', 'Eggs'});
      expect(await h.read(attachmentsRepositoryProvider).listFor(AttachmentOwnerType.checklist, id), hasLength(1));
    });

    test('new task from a link with a photo; attach to an existing item', () async {
      final service = h.read(shareIntakeServiceProvider);
      final taskId = await service.createTask(SharedContent(text: 'Recipe\nhttps://example.com/pie', files: photos(1)));
      final task = (await h.read(plannerQueriesProvider).task(taskId))!;
      expect((task.title, task.notes, task.startLocal), ('Recipe', 'https://example.com/pie', null));
      expect(await h.read(attachmentsRepositoryProvider).listFor(AttachmentOwnerType.task, taskId), hasLength(1));

      final list = await h.checklist('Home', items: ['Fix sink']);
      final sink = await h.itemId(list, 'Fix sink');
      expect(await service.attachTo(SharedContent(files: photos(2)), AttachmentOwnerType.checklistItem, sink), 2);
    });
  });
}
