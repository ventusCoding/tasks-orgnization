import 'package:everslot/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

void main() {
  testWidgets(
    'the root widget boots in local-only mode and shows the dev marker',
    (tester) async {
      final h = TestHarness.create();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: const EverslotApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Banner), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tear down inside the test body: some app-wide providers keep refresh timers until their
      // container is disposed, and pending timers are checked before tearDown callbacks run.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(h.dispose);
    },
  );
}
