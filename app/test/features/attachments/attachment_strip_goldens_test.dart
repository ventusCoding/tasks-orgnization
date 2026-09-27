// Golden matrix of the reusable attachment strip (T2.2.07, T4.4.02): light/dark × LTR/RTL ×
// text scale 1.0/2.0 — images, file chips, "+N", "+ add" and every transfer badge.
@Tags(['golden'])
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/domain/transfer.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

Attachment att(int i, String mime, String name) => Attachment(
  id: 'a$i',
  ownerType: AttachmentOwnerType.checklistItem,
  ownerId: 'item-$i',
  storagePath: 'user-1/a$i/file',
  fileName: name,
  mimeType: mime,
  byteSize: 150000 * (i + 1),
  sortKey: 'a$i',
);

final _items = [
  att(0, 'image/jpeg', 'photo.jpg'),
  att(1, 'application/pdf', 'Invoice March.pdf'),
  att(2, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'Contract.docx'),
  att(3, 'application/zip', 'Archive.zip'),
  att(4, 'text/plain', 'notes.txt'),
  att(5, 'image/png', 'screen.png'),
];

const _transfers = {
  'a0': AttachmentTransfer(status: TransferStatus.uploading, progress: 0.4),
  'a1': AttachmentTransfer(status: TransferStatus.waitingForNetwork),
  'a2': AttachmentTransfer(status: TransferStatus.failed),
  'a3': AttachmentTransfer(status: TransferStatus.notDownloaded),
};

Widget _strip(String owner, {int maxVisible = 4, bool compact = false}) => AttachmentStrip(
  ownerType: AttachmentOwnerType.checklistItem,
  ownerId: owner,
  maxVisible: maxVisible,
  compact: compact,
);

void main() {
  for (final dark in [false, true]) {
    for (final rtl in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        final name = '${dark ? 'dark' : 'light'}_${rtl ? 'rtl' : 'ltr'}_${scale == 1 ? '1x' : '2x'}';
        testWidgets('attachment strip golden $name', (tester) async {
          tester.view.physicalSize = const Size(420, 360);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final h = TestHarness.create(
            overrides: [
              // Owner "all" holds every attachment; "one" only the image; "none" nothing.
              attachmentsForOwnerProvider.overrideWith(
                (ref, owner) => Stream.value(switch (owner.id) {
                  'all' => _items,
                  'one' => [_items.first],
                  _ => const <Attachment>[],
                }),
              ),
              attachmentLocalProvider.overrideWith((ref, id) => Stream.value(const AttachmentLocal())),
              attachmentTransferProvider.overrideWith((ref, a) => _transfers[a.id] ?? AttachmentTransfer.ready),
            ],
          );
          addTearDown(h.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: h.container,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: dark ? AppTheme.dark() : AppTheme.light(),
                locale: Locale(rtl ? 'ar' : 'en'),
                supportedLocales: const [Locale('en'), Locale('ar')],
                localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
                home: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
                    child: Scaffold(
                      body: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          _strip('all'),
                          const SizedBox(height: 12),
                          _strip('all', compact: true, maxVisible: 3),
                          const SizedBox(height: 12),
                          _strip('one'),
                          const SizedBox(height: 12),
                          _strip('none'),
                          const SizedBox(height: 12),
                          const AttachmentCountBadge(count: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          // The upload ring is determinate (static); no spinner in this scene.
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
          await expectLater(find.byType(ListView).first, matchesGoldenFile('goldens/attachment_strip_$name.png'));
        });
      }
    }
  }
}
