// Per-state widget tests of the attachment strip (T2.2.07, T2.2.09, T4.4.02, T4.4.03): every
// transfer state has its badge and spoken status, failed tiles retry on tap, "+N" opens the
// viewer at the first hidden attachment, and the strip mirrors in RTL.
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/domain/transfer.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/attachments/presentation/attachment_viewer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

Attachment att(int i, {String mime = 'image/jpeg', String? name}) => Attachment(
  id: 'a$i',
  ownerType: AttachmentOwnerType.checklistItem,
  ownerId: 'item-1',
  storagePath: 'user-1/a$i/file',
  fileName: name ?? 'photo$i.jpg',
  mimeType: mime,
  byteSize: 1000 * (i + 1),
  sortKey: 'a$i',
);

/// Transfer state, badge finder and spoken status of each visible state.
final cases = <(AttachmentTransfer, Finder Function(), String?)>[
  (AttachmentTransfer.ready, () => find.byType(Icon), null),
  (
    const AttachmentTransfer(status: TransferStatus.processing),
    () => find.byType(CircularProgressIndicator),
    'Processing',
  ),
  (
    const AttachmentTransfer(status: TransferStatus.waitingForNetwork),
    () => find.byIcon(Icons.cloud_upload_outlined),
    'Waiting for network',
  ),
  (
    const AttachmentTransfer(status: TransferStatus.uploading, progress: 0.4),
    () => find.byWidgetPredicate((w) => w is CircularProgressIndicator && w.value == 0.4),
    'Uploading 40 %',
  ),
  (
    const AttachmentTransfer(status: TransferStatus.uploading),
    () => find.byWidgetPredicate((w) => w is CircularProgressIndicator && w.value == null),
    'Uploading',
  ),
  (
    const AttachmentTransfer(status: TransferStatus.failed, error: 'network down'),
    () => find.byIcon(Icons.error_outline),
    'Upload failed — tap to retry',
  ),
  (
    const AttachmentTransfer(status: TransferStatus.notDownloaded),
    () => find.byIcon(Icons.cloud_download_outlined),
    'Not downloaded — tap to fetch',
  ),
  (
    const AttachmentTransfer(status: TransferStatus.downloading),
    () => find.byWidgetPredicate((w) => w is CircularProgressIndicator && w.value == null),
    'Downloading',
  ),
];

void main() {
  late TestHarness h;

  /// A harness whose strip shows [items] with fixed transfer states (no files, no queue).
  TestHarness harness(List<Attachment> items, Map<String, AttachmentTransfer> transfers) => TestHarness.create(
    overrides: [
      attachmentsForOwnerProvider.overrideWith((ref, owner) => Stream.value(items)),
      attachmentLocalProvider.overrideWith((ref, id) => Stream.value(const AttachmentLocal())),
      attachmentTransferProvider.overrideWith((ref, a) => transfers[a.id] ?? AttachmentTransfer.ready),
    ],
  );

  tearDown(() async => h.dispose());

  Future<void> pumpStrip(WidgetTester tester, {int maxVisible = 4, Locale locale = const Locale('en')}) async {
    await pumpInApp(
      tester,
      h,
      Scaffold(
        body: Center(
          child: AttachmentStrip(
            ownerType: AttachmentOwnerType.checklistItem,
            ownerId: 'item-1',
            maxVisible: maxVisible,
          ),
        ),
      ),
      locale: locale,
    );
    // Spinners animate forever: bounded pumps only.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Finder tile(int i) => find.byType(AttachmentTile).at(i);

  testWidgets('every transfer state shows its badge and speaks its status (T2.2.09, T4.4.03)', (tester) async {
    final items = [for (var i = 0; i < cases.length; i++) att(i)];
    h = harness(items, {for (var i = 0; i < cases.length; i++) 'a$i': cases[i].$1});
    await pumpStrip(tester, maxVisible: cases.length);
    expect(find.byType(AttachmentTile), findsNWidgets(cases.length));
    for (var i = 0; i < cases.length; i++) {
      final (transfer, badge, spoken) = cases[i];
      final badgeFinder = find.descendant(of: tile(i), matching: find.byType(TransferBadge));
      if (transfer.status == TransferStatus.ready) {
        expect(
          find.descendant(of: badgeFinder, matching: find.byType(Icon)),
          findsNothing,
          reason: 'ready tiles carry no badge',
        );
        expect(find.descendant(of: badgeFinder, matching: find.byType(CircularProgressIndicator)), findsNothing);
      } else {
        expect(
          find.descendant(of: badgeFinder, matching: badge()),
          findsOneWidget,
          reason: '${transfer.status}',
        );
      }
      final label = ['Photo ${i + 1} of ${cases.length}', 'photo$i.jpg', ?spoken].join(', ');
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('a failed tile retries on tap instead of opening the viewer (T2.2.09, T4.4.03)', (tester) async {
    h = harness([att(0)], {'a0': const AttachmentTransfer(status: TransferStatus.failed, error: 'boom')});
    await tester.runAsync(
      () => h
          .read(attachmentCacheStoreProvider)
          .putLocal('a0', originalRel: null, thumbRel: null, bytes: 1000, uploadState: UploadState.failed),
    );
    await pumpStrip(tester);
    await tester.tap(tile(0));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(AttachmentViewerScreen), findsNothing);
    final row = await tester.runAsync(() => h.read(attachmentCacheStoreProvider).get('a0'));
    expect(row!.uploadState, UploadState.pending.name);
    expect(row.uploadError, isNull);
  });

  testWidgets('"+N" beyond maxVisible opens the viewer at the first hidden attachment (T4.4.02)', (tester) async {
    h = harness([for (var i = 0; i < 6; i++) att(i)], const {});
    await pumpStrip(tester);
    expect(find.byType(AttachmentTile), findsNWidgets(4));
    expect(find.text('+2'), findsOneWidget);
    expect(find.bySemanticsLabel('2 attachments'), findsOneWidget);
    await tester.tap(find.text('+2'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(AttachmentViewerScreen), findsOneWidget);
    expect(find.text('5 / 6'), findsOneWidget);
  });

  testWidgets('file chips show the name and size; images are square thumbnails (T4.4.02)', (tester) async {
    h = harness([att(0), att(1, mime: 'application/pdf', name: 'Invoice.pdf')], const {});
    await pumpStrip(tester);
    expect(find.text('Invoice.pdf'), findsOneWidget);
    expect(find.textContaining('KB'), findsOneWidget);
    final image = tester.getSize(tile(0));
    final file = tester.getSize(tile(1));
    expect(image.width, image.height);
    expect(file.width, greaterThan(file.height));
    expect(find.bySemanticsLabel('PDF 2 of 2, Invoice.pdf'), findsOneWidget);
  });

  testWidgets('the strip mirrors in RTL: the first attachment sits at the start (right) edge (T2.2.07)', (
    tester,
  ) async {
    h = harness([att(0), att(1)], const {});
    await pumpStrip(tester, locale: const Locale('ar'));
    final first = tester.getTopLeft(tile(0)).dx;
    final second = tester.getTopLeft(tile(1)).dx;
    expect(first, greaterThan(second));
    final add = tester.getTopLeft(find.byIcon(Icons.add_photo_alternate_outlined)).dx;
    expect(add, lessThan(second), reason: '"+ add" comes last, at the end (left) edge');
  });
}
