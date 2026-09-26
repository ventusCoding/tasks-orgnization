import 'package:everslot/design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Tablet/landscape foundations (T1.3.19): size classes, two-pane scaffold, keyboard shortcuts.
void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    double width,
    Widget child, {
    TextDirection direction = TextDirection.ltr,
  }) async {
    tester.view
      ..physicalSize = Size(width, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  test('size classes follow the Material 3 breakpoints', () {
    expect(WindowSizeClass.fromWidth(360), WindowSizeClass.compact);
    expect(WindowSizeClass.fromWidth(599.9), WindowSizeClass.compact);
    expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
    expect(WindowSizeClass.fromWidth(839.9), WindowSizeClass.medium);
    expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
    expect(WindowSizeClass.expanded.isTwoPane, isTrue);
    expect(WindowSizeClass.medium.usesRail, isTrue);
    expect(WindowSizeClass.compact.usesRail, isFalse);
    expect(WindowSizeClass.compact.margin, 16);
  });

  testWidgets('window class and adaptive builder at expanded width', (
    tester,
  ) async {
    await pumpAt(
      tester,
      1280,
      Column(
        children: [
          Builder(
            builder: (context) => Text('window ${context.windowSize.name}'),
          ),
          SizedBox(
            width: 500,
            child: AdaptiveBuilder(
              builder: (context, size) => Text('pane ${size.name}'),
            ),
          ),
        ],
      ),
    );
    expect(find.text('window expanded'), findsOneWidget);
    // The builder uses the space it gets, not the window.
    expect(find.text('pane compact'), findsOneWidget);
  });

  group('TwoPaneScaffold', () {
    Widget scaffold({
      Widget? detail,
      bool single = false,
      VoidCallback? onClose,
    }) => TwoPaneScaffold(
      list: const Center(child: Text('list')),
      detail: detail,
      emptyDetail: const Center(child: Text('nothing selected')),
      showDetailWhenSingle: single,
      onCloseDetail: onClose,
    );

    testWidgets('expanded: list and detail side by side, list at the start', (
      tester,
    ) async {
      await pumpAt(
        tester,
        1280,
        scaffold(detail: const Center(child: Text('detail'))),
      );
      expect(find.text('list'), findsOneWidget);
      expect(find.text('detail'), findsOneWidget);
      expect(
        tester.getCenter(find.text('list')).dx,
        lessThan(tester.getCenter(find.text('detail')).dx),
      );
      expect(tester.getSize(find.byType(TwoPaneScaffold)).width, 1280);
    });

    testWidgets('expanded RTL: the list pane is on the right', (tester) async {
      await pumpAt(
        tester,
        1280,
        scaffold(detail: const Center(child: Text('detail'))),
        direction: TextDirection.rtl,
      );
      expect(
        tester.getCenter(find.text('list')).dx,
        greaterThan(tester.getCenter(find.text('detail')).dx),
      );
    });

    testWidgets('expanded without selection shows the empty detail', (
      tester,
    ) async {
      await pumpAt(tester, 1000, scaffold());
      expect(find.text('nothing selected'), findsOneWidget);
    });

    testWidgets('compact: one pane — list, or the detail when asked', (
      tester,
    ) async {
      await pumpAt(tester, 400, scaffold(detail: const Text('detail')));
      expect(find.text('list'), findsOneWidget);
      expect(find.text('detail'), findsNothing);

      var closed = 0;
      await pumpAt(
        tester,
        400,
        scaffold(
          detail: const Text('detail'),
          single: true,
          onClose: () => closed++,
        ),
      );
      expect(find.text('detail'), findsOneWidget);
      expect(find.text('list'), findsNothing);
      // System back closes the detail instead of popping the route.
      final handled = await tester.binding.handlePopRoute();
      await tester.pump();
      expect(handled, isTrue);
      expect(closed, 1);
    });
  });

  group('keyboard shortcuts', () {
    Future<List<String>> pressAll(
      WidgetTester tester,
      List<List<LogicalKeyboardKey>> combos,
    ) async {
      final log = <String>[];
      await pumpAt(
        tester,
        1280,
        AppShortcutScope(
          actions: {
            UndoIntent: CallbackAction<UndoIntent>(
              onInvoke: (_) => log.add('undo'),
            ),
            RedoIntent: CallbackAction<RedoIntent>(
              onInvoke: (_) => log.add('redo'),
            ),
            OpenSearchIntent: CallbackAction<OpenSearchIntent>(
              onInvoke: (_) => log.add('search'),
            ),
            OpenCommandPaletteIntent: CallbackAction<OpenCommandPaletteIntent>(
              onInvoke: (_) => log.add('palette'),
            ),
            NewItemIntent: CallbackAction<NewItemIntent>(
              onInvoke: (_) => log.add('new'),
            ),
          },
          child: const Text('content'),
        ),
      );
      await tester.pump();
      for (final combo in combos) {
        for (final key in combo) {
          await tester.sendKeyDownEvent(key);
        }
        for (final key in combo.reversed) {
          await tester.sendKeyUpEvent(key);
        }
        await tester.pump();
      }
      return log;
    }

    testWidgets('Ctrl and ⌘ variants trigger the app intents', (tester) async {
      final log = await pressAll(tester, [
        [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyZ],
        [
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.shiftLeft,
          LogicalKeyboardKey.keyZ,
        ],
        [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyY],
        [LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyF],
        [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyK],
        [LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyN],
        [LogicalKeyboardKey.keyZ],
      ]);
      expect(log, ['undo', 'redo', 'redo', 'search', 'palette', 'new']);
    });

    testWidgets('a focused text field keeps its own undo', (tester) async {
      final log = <String>[];
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpAt(
        tester,
        1280,
        AppShortcutScope(
          actions: {
            UndoIntent: CallbackAction<UndoIntent>(
              onInvoke: (_) => log.add('undo'),
            ),
          },
          child: TextField(controller: controller),
        ),
      );
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(log, isEmpty, reason: 'the text field handled Ctrl+Z');
    });
  });
}
