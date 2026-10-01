import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/dev/presentation/component_gallery_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Accessibility baseline (T1.3.15): Flutter's guidelines pass on the component gallery in light
/// and dark themes, left-to-right and right-to-left, and at text scale 2.0.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  final en = lookupAppLocalizations(const Locale('en'));

  Future<void> pumpGallery(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    // Tall enough for every section to be laid out (the gallery is a lazy list).
    tester.view
      ..physicalSize = const Size(1000, 16000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpInApp(tester, h, const ComponentGalleryScreen(animateIndicators: false), locale: locale);
    await tester.pumpAndSettle();
  }

  Future<void> toggle(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(SwitchListTile, label));
    await tester.pumpAndSettle();
  }

  Future<void> expectGuidelines(WidgetTester tester) async {
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  testWidgets('light theme, left-to-right', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpGallery(tester);
    await expectGuidelines(tester);
    handle.dispose();
  });

  testWidgets('dark theme, right-to-left', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpGallery(tester);
    await toggle(tester, en.galleryDarkTheme);
    await toggle(tester, en.galleryRtl);
    expect(Directionality.of(tester.element(find.text(en.galleryButtons))), TextDirection.rtl);
    await expectGuidelines(tester);
    handle.dispose();
  });

  testWidgets('Arabic locale', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpGallery(tester, locale: const Locale('ar'));
    await expectGuidelines(tester);
    handle.dispose();
  });

  testWidgets('text scale 2.0 lays out without clipping errors', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpGallery(tester);
    await toggle(tester, en.galleryLargeText);
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('custom components expose semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpGallery(tester);
    // Progress ring: label + value.
    final ring = tester.getSemantics(find.byType(ProgressRing));
    expect(ring.label, contains(en.galleryProgress));
    expect(ring.value, '66%');
    // Priority badges are named by their label.
    expect(find.bySemanticsLabel(en.priorityUrgent), findsWidgets);
    // Section headers are headers.
    final header = tester.getSemantics(find.text(en.galleryButtons));
    expect(header.flagsCollection.isHeader, isTrue);
    handle.dispose();
  });

  testWidgets('announce() sends a live announcement', (tester) async {
    final messages = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
      message,
    ) async {
      final event = message! as Map;
      if (event['type'] == 'announce') {
        messages.add((event['data'] as Map)['message'] as String);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
        SystemChannels.accessibility,
        null,
      ),
    );
    await pumpInApp(
      tester,
      h,
      Builder(
        builder: (context) => TextButton(onPressed: () => announce(context, 'Task completed'), child: const Text('go')),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(messages, ['Task completed']);
    expect(SemanticsService, isNotNull);
  });
}
