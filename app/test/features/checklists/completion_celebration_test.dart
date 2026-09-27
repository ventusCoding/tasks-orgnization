// Completion celebration and the "List completed" state (T4.3.12): shown once every countable item
// is done, with Reset / Archive / Keep, a haptic tap, and no animation under reduce-motion.
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/tree_ops.dart';
import 'package:everslot/features/checklists/presentation/checklist_header.dart';
import 'package:everslot/features/checklists/presentation/checklist_screen.dart';
import 'package:everslot/features/checklists/presentation/item_row.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_app.dart';

void main() {
  late TestHarness h;
  late List<String> haptics;
  setUp(() {
    h = TestHarness.create();
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
        return null;
      },
    );
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
    await h.dispose();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<String> seed(WidgetTester tester) async {
    late String id;
    await tester.runAsync(() async {
      id =
          (await h
                  .read(checklistsRepositoryProvider)
                  .create(
                    title: 'Packing',
                    items: const [
                      NodeSpec(text: 'Socks', status: ItemStatus.completed),
                      NodeSpec(text: 'Charger'),
                    ],
                  ))
              .id;
    });
    return id;
  }

  Future<void> pumpScreen(WidgetTester tester, String id, {bool reduceMotion = false, double scale = 1}) async {
    await pumpInApp(
      tester,
      h,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion, textScaler: TextScaler.linear(scale)),
          child: ChecklistScreen(checklistId: id, preview: true),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> completeCharger(WidgetTester tester) async {
    final row = find.ancestor(of: find.text('Charger'), matching: find.byType(ItemRow));
    await tester.tap(find.descendant(of: row, matching: find.byType(StatusControl)));
    await settle(tester);
  }

  Future<List<ChecklistItem>> items(WidgetTester tester, String id) async {
    late List<ChecklistItem> out;
    await tester.runAsync(() async => out = await h.read(checklistItemsRepositoryProvider).items(id));
    return out;
  }

  testWidgets('completing the last item celebrates once; Keep dismisses the state', (tester) async {
    final id = await seed(tester);
    await pumpScreen(tester, id);
    expect(find.byType(CompletedBanner), findsNothing);

    await completeCharger(tester);
    expect(find.text('List completed!'), findsOneWidget);
    // The tap itself ticks (medium); the celebration adds one heavy impact.
    expect(haptics.where((h) => h == 'HapticFeedbackType.heavyImpact'), hasLength(1));
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);

    await tester.tap(find.text('Keep'));
    await settle(tester);
    expect(find.text('List completed!'), findsNothing);
    expect(
      haptics.where((h) => h == 'HapticFeedbackType.heavyImpact'),
      hasLength(1),
      reason: 'no second celebration while the list stays complete',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Reset unchecks every item of a one-off list', (tester) async {
    final id = await seed(tester);
    await pumpScreen(tester, id);
    await completeCharger(tester);
    await tester.tap(find.text('Reset'));
    await settle(tester);
    expect((await items(tester, id)).map((i) => i.status).toSet(), {ItemStatus.todo});
    expect(find.text('List completed!'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduce motion: the celebration appears without animating', (tester) async {
    final id = await seed(tester);
    await pumpScreen(tester, id, reduceMotion: true);
    await completeCharger(tester);
    final scale = tester.widget<ScaleTransition>(
      find.descendant(of: find.byType(CompletedBanner), matching: find.byType(ScaleTransition)),
    );
    expect(scale.scale.value, 1);
    expect(scale.scale.status, AnimationStatus.completed);
    expect(scale.scale.isAnimating, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with motion the badge pops in', (tester) async {
    final id = await seed(tester);
    await pumpScreen(tester, id);
    final row = find.ancestor(of: find.text('Charger'), matching: find.byType(ItemRow));
    await tester.tap(find.descendant(of: row, matching: find.byType(StatusControl)));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final anim = tester
        .widget<ScaleTransition>(
          find.descendant(of: find.byType(CompletedBanner), matching: find.byType(ScaleTransition)),
        )
        .scale;
    expect(anim.value, lessThan(1), reason: 'still animating shortly after completion');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the completed state fits a phone at text scale 2.0', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final id = await seed(tester);
    await pumpScreen(tester, id, reduceMotion: true, scale: 2);
    await completeCharger(tester);
    expect(find.byType(CompletedBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
