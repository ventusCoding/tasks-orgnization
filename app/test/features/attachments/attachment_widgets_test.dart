import 'dart:io';

import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/attachments/application/attachment_transfers.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/attachments/presentation/attachment_ui.dart';
import 'package:everslot/features/attachments/presentation/attachment_viewer.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/item_row.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'attachment_domain_test.dart' show jpegBytes;
import 'attachment_test_support.dart';

/// Picker returning prepared files (no platform channels).
class FakePicker implements AttachmentPicker {
  FakePicker(this.files);

  List<PickedFileRef> files;
  final sources = <AttachmentSource>[];

  @override
  Future<List<PickedFileRef>> pick(AttachmentSource source, {int? limit}) async {
    sources.add(source);
    return files;
  }
}

void main() {
  late TestHarness h;
  late Directory root;
  late Directory src;
  late FakePicker picker;
  late ProviderContainer c;

  // Synchronous: real async IO never completes inside the widget test's fake-async zone.
  void setUpEnv({bool remote = false, NetworkKind network = NetworkKind.wifi}) {
    h = TestHarness.create();
    root = Directory.systemTemp.createTempSync('att_w_root');
    src = Directory.systemTemp.createTempSync('att_w_src');
    picker = FakePicker([
      for (var i = 0; i < 2; i++)
        PickedFileRef(path: writeSource(src, 'photo$i.jpg', jpegBytes(400 + i, 300)).path, name: 'photo$i.jpg'),
    ]);
    c = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(
          const Env(
            flavor: Flavor.dev,
            supabaseUrl: '',
            supabasePublishableKey: '',
            firebaseEnabled: false,
            featureFlags: {},
          ),
        ),
        appDatabaseProvider.overrideWithValue(h.db),
        clockProvider.overrideWithValue(h.clock),
        deviceIdProvider.overrideWithValue('device-test'),
        attachmentFileStoreProvider.overrideWithValue(tempFileStore(root)),
        imageCodecProvider.overrideWithValue(FakeImageCodec()),
        attachmentPickerProvider.overrideWithValue(picker),
        connectivityProbeProvider.overrideWithValue(FakeConnectivity(network)),
        if (remote) attachmentRemoteStorageProvider.overrideWithValue(FakeRemoteStorage()),
      ],
    );
  }

  tearDown(() async {
    c.dispose();
    await h.dispose();
    await root.delete(recursive: true);
    await src.delete(recursive: true);
  });

  Future<void> pump(WidgetTester tester, Widget child, {bool scaffold = true}) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: scaffold ? Scaffold(body: Center(child: child)) : child,
      ),
    ),
  );

  /// Real IO (file copies, hashing, the database) only progresses inside `runAsync`, and every
  /// awaited IO call needs its own round: alternate short real waits with frames until [until]
  /// holds (bounded, so a missing widget fails fast instead of hanging), then let trailing work
  /// (snackbars, route transitions) finish. Never `pumpAndSettle`: spinners animate forever.
  Future<void> settle(WidgetTester tester, {bool Function()? until, int rounds = 30, int maxRounds = 300}) async {
    Future<void> round() async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
      await tester.pump(const Duration(milliseconds: 16));
    }

    if (until != null) {
      for (var i = 0; i < maxRounds && !until(); i++) {
        await round();
      }
    }
    for (var i = 0; i < rounds; i++) {
      await round();
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  bool tiles(int n) => find.byType(AttachmentTile).evaluate().length == n;

  Future<void> addTwoPhotos(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose photos'));
    await settle(tester, until: () => tiles(2));
  }

  const strip = AttachmentStrip(ownerType: AttachmentOwnerType.checklistItem, ownerId: 'item-1');

  testWidgets(
    'adding photos offline shows them at once from local files; no badge in local-only mode (T2.2.07, T4.4.01)',
    (tester) async {
      setUpEnv();
      await pump(tester, strip);
      await settle(tester);
      await addTwoPhotos(tester);
      expect(picker.sources, [AttachmentSource.photos]);
      expect(find.byType(AttachmentTile), findsNWidgets(2));
      expect(find.text('2 attachments added'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
      late List<Attachment> rows;
      await tester.runAsync(
        () async => rows = await c.read(attachmentsRepositoryProvider).listFor('checklist_item', 'item-1'),
      );
      expect(rows, hasLength(2));
      expect(rows.every((a) => !a.isUploaded), isTrue);
      // Accessible label: kind, position and file name.
      expect(find.bySemanticsLabel(RegExp(r'Photo 1 of 2')), findsOneWidget);
    },
  );

  testWidgets('pending uploads show "waiting for network" badges and the pending indicator (T2.2.09, T4.4.03)', (
    tester,
  ) async {
    setUpEnv(remote: true, network: NetworkKind.offline);
    await pump(tester, const Column(mainAxisSize: MainAxisSize.min, children: [strip, PendingUploadsIndicator()]));
    await settle(tester);
    await addTwoPhotos(tester);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNWidgets(3), reason: 'two badges + the indicator');
    expect(find.text('2 uploads pending'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Waiting for network')), findsNWidgets(2));
  });

  testWidgets('long-press menu: caption, then remove with undo (T2.2.07, T4.4.06)', (tester) async {
    setUpEnv();
    await pump(tester, strip);
    await settle(tester);
    await addTwoPhotos(tester);

    await tester.longPress(find.byType(AttachmentTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit caption'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Receipt');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    late List<Attachment> rows;
    await tester.runAsync(
      () async => rows = await c.read(attachmentsRepositoryProvider).listFor('checklist_item', 'item-1'),
    );
    expect(rows.first.caption, 'Receipt');

    await tester.longPress(find.byType(AttachmentTile).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await settle(tester, until: () => tiles(1));
    expect(find.byType(AttachmentTile), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester, until: () => tiles(2));
    expect(find.byType(AttachmentTile), findsNWidgets(2));
  });

  testWidgets('reorder from the long-press menu updates the sort order (T2.2.07, T4.4.06)', (tester) async {
    setUpEnv();
    await pump(tester, strip);
    await settle(tester);
    await addTwoPhotos(tester);
    Future<List<String>> names() async {
      late List<Attachment> rows;
      await tester.runAsync(
        () async => rows = await c.read(attachmentsRepositoryProvider).listFor('checklist_item', 'item-1'),
      );
      return [for (final a in rows) a.fileName];
    }

    expect(await names(), ['photo0.jpg', 'photo1.jpg']);
    await tester.longPress(find.byType(AttachmentTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Move earlier'), findsNothing, reason: 'already first');
    await tester.tap(find.text('Move later'));
    await settle(tester, until: () => find.bySemanticsLabel(RegExp('^Photo 1 of 2, photo1')).evaluate().isNotEmpty);
    expect(await names(), ['photo1.jpg', 'photo0.jpg']);

    await tester.longPress(find.byType(AttachmentTile).last);
    await tester.pumpAndSettle();
    expect(find.text('Move later'), findsNothing, reason: 'already last');
    await tester.tap(find.text('Move earlier'));
    await settle(tester, until: () => find.bySemanticsLabel(RegExp('^Photo 1 of 2, photo0')).evaluate().isNotEmpty);
    expect(await names(), ['photo0.jpg', 'photo1.jpg']);
  });

  testWidgets('tapping a tile opens the gallery viewer; swiping moves between attachments (T2.2.06)', (tester) async {
    setUpEnv();
    await pump(tester, strip);
    await settle(tester);
    await addTwoPhotos(tester);
    await tester.tap(find.byType(AttachmentTile).first);
    await settle(tester, until: () => find.text('1 / 2').evaluate().isNotEmpty);
    expect(find.byType(AttachmentViewerScreen), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1500);
    await settle(tester, until: () => find.text('2 / 2').evaluate().isNotEmpty);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('attach from a checklist row menu: the row shows its strip (T4.4.01, T4.4.02)', (tester) async {
    setUpEnv();
    late String listId;
    await tester.runAsync(() async {
      listId =
          (await c
                  .read(checklistsRepositoryProvider)
                  .create(
                    title: 'Trip',
                    items: const [NodeSpec(text: 'Passport')],
                  ))
              .id;
    });
    await pump(tester, ChecklistScreen(checklistId: listId, preview: true), scaffold: false);
    await settle(tester);
    // Preview swipe toward the start opens the row menu.
    await tester.drag(
      find.descendant(
        of: find.ancestor(of: find.text('Passport'), matching: find.byType(ItemRow)),
        matching: find.byType(StatusControl),
      ),
      const Offset(-90, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Attach')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose photos'));
    await settle(tester, until: () => tiles(2));
    expect(find.byType(AttachmentTile), findsNWidgets(2));
    // Undo from the app bar in edit mode removes both (one operation).
    await tester.tap(find.byTooltip('Edit'));
    await settle(tester);
    await tester.tap(find.byTooltip('Undo'));
    await settle(tester, until: () => tiles(0));
    expect(find.byType(AttachmentTile), findsNothing);
  });
}
