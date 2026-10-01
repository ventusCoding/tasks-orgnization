import 'dart:typed_data';

import 'package:everslot/features/checklists/application/checklist_pdf.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist_tree.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/import_export_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

class _FakeOutput implements PdfOutput {
  final sent = <(String, String, Uint8List)>[];

  @override
  Future<void> print(Uint8List bytes, {required String name}) async => sent.add(('print', name, bytes));

  @override
  Future<void> share(Uint8List bytes, {required String name}) async => sent.add(('share', name, bytes));
}

/// Export sheet › PDF (T4.5.10): options, then print or share the generated file.
void main() {
  for (final action in ['print', 'share']) {
    testWidgets('PDF $action sends a PDF named after the list', (tester) async {
      final output = _FakeOutput();
      final h = TestHarness.create(
        overrides: [
          pdfOutputProvider.overrideWithValue(output),
          checklistPdfServiceProvider.overrideWith(
            (ref) => ChecklistPdfService(attachments: (_) async => const [], thumbPath: (_) async => null),
          ),
        ],
      );
      addTearDown(h.dispose);
      final id = (await tester.runAsync(
        () => h
            .read(checklistsRepositoryProvider)
            .create(
              title: 'Trip',
              items: const [NodeSpec(text: 'Passport', note: 'In the drawer')],
            ),
      ))!.id;
      final checklist = (await tester.runAsync(() => h.read(checklistsRepositoryProvider).byId(id)))!;
      final items = (await tester.runAsync(() => h.read(checklistItemsRepositoryProvider).watchItems(id).first))!;

      await pumpInApp(
        tester,
        h,
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () => showExportSheet(context, ref, checklist: checklist, tree: ChecklistTree.build(items)),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('export-pdf-notes')), findsOneWidget);
      await tester.tap(find.byKey(Key(action == 'print' ? 'export-print' : 'export-share-pdf')));
      for (var i = 0; i < 100 && output.sent.isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
      final (kind, name, bytes) = output.sent.single;
      expect(kind, action);
      expect(name, 'Trip.pdf');
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      await tester.pumpAndSettle();
    });
  }
}
