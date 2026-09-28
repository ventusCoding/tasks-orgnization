import 'package:everslot/features/attachments/presentation/attachment_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import '../auth/support/widget_helpers.dart';

void main() {
  testWidgets('dbg', (tester) async {
    final h = TestHarness.create();
    print('A');
    await pumpInApp(tester, h, const Scaffold(body: SingleChildScrollView(child: AttachmentSettingsSection())));
    print('B');
    await tester.pump(const Duration(milliseconds: 50));
    print('C');
    await settle(tester, rounds: 1);
    print('D');
    await tester.pumpWidget(const SizedBox.shrink());
    print('E');
    await tester.runAsync(h.dispose);
    print('F');
  });
}
