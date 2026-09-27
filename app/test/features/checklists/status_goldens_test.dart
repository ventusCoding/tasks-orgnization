// Golden matrix of item statuses in preview mode (T4.3.04): every status with its icon, pill, age,
// reason note and strike-through — light/dark × LTR/RTL, plus text scale 2.0 in both directions.
@Tags(['golden'])
library;

import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';
import 'status_gallery_support.dart';

void main() {
  const variants = [
    (dark: false, rtl: false, scale: 1.0),
    (dark: false, rtl: true, scale: 1.0),
    (dark: true, rtl: false, scale: 1.0),
    (dark: true, rtl: true, scale: 1.0),
    (dark: false, rtl: false, scale: 2.0),
    (dark: true, rtl: true, scale: 2.0),
  ];
  for (final v in variants) {
    final name = '${v.dark ? 'dark' : 'light'}_${v.rtl ? 'rtl' : 'ltr'}_${v.scale == 1 ? '1x' : '2x'}';
    testWidgets('status gallery golden $name', (tester) async {
      tester.view.physicalSize = const Size(400, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = TestHarness.create(now: galleryNow);
      addTearDown(h.dispose);
      final id = await seedStatusGallery(tester, h);
      await pumpGallery(
        tester,
        h,
        ChecklistScreen(checklistId: id, preview: true),
        dark: v.dark,
        rtl: v.rtl,
        scale: v.scale,
      );
      await expectLater(find.byType(ChecklistScreen), matchesGoldenFile('goldens/status_gallery_$name.png'));
      await tester.pumpWidget(const SizedBox());
    });
  }
}
