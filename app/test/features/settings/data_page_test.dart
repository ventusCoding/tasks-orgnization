import 'dart:io';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/settings/application/export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../auth/support/widget_helpers.dart';
import 'support/settings_app.dart';

void main() {
  late Directory tmp;
  late List<String> shared;

  TestHarness harness() {
    tmp = Directory.systemTemp.createTempSync('everslot_data_page_');
    shared = [];
    return TestHarness.create(
      overrides: [
        exportDirectoryProvider.overrideWithValue(() async => Directory('${tmp.path}/exports')),
        appVersionLabelProvider.overrideWithValue(() async => '1.0.0+7'),
        shareFileProvider.overrideWithValue((file, {subject}) async => shared.add(file.path)),
      ],
    );
  }

  Future<void> waitForShare(WidgetTester tester) async {
    for (var i = 0; i < 40 && shared.isEmpty; i++) {
      await settle(tester, rounds: 2);
    }
  }

  testWidgets('export JSON, then CSV: files are written and handed to the share sheet (T8.3.07)', (tester) async {
    final h = harness();
    await tester.runAsync(
      () => h
          .read(syncWriterProvider)
          .run((tx) => tx.insert('categories', 'c1', {'name': 'Work', 'color': 1, 'sort_key': 'a0'})),
    );
    await pumpSettingsApp(tester, h, initial: '/settings/data');
    await settle(tester);
    expect(find.text('Everslot backup (JSON)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('export-run')));
    await waitForShare(tester);
    expect(shared, hasLength(1));
    expect(shared.single, endsWith('.json'));
    expect(File(shared.single).existsSync(), isTrue);
    expect(find.textContaining('Export ready'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('export-csv')));
    await tester.pump();
    shared.clear();
    await tester.tap(find.byKey(const ValueKey('export-run')));
    await waitForShare(tester);
    expect(shared.single, endsWith('.zip'));
    await finish(tester, h);
    tmp.deleteSync(recursive: true);
  });
}
