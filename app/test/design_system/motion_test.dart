import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Motion & transitions (T1.3.18) and the reduce-motion setting (T1.3.15).
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Widget probe() => Builder(
    builder: (context) => Text(
      'reduced=${AppMotion.reduced(context)} '
      'ctx=${context.reduceMotion} '
      'duration=${AppMotion.duration(context).inMilliseconds}',
    ),
  );

  testWidgets('the in-app setting joins the OS reduce-motion flag', (
    tester,
  ) async {
    await pumpInApp(tester, h, ReduceMotionScope(child: probe()));
    await tester.pump();
    expect(find.text('reduced=false ctx=false duration=220'), findsOneWidget);

    await tester.runAsync(
      () => h.read(settingsRepositoryProvider).update(SettingsNs.appearance, {
        'reduceMotion': true,
      }),
    );
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump();
    }
    expect(find.text('reduced=true ctx=true duration=0'), findsOneWidget);
  });

  testWidgets('the OS flag alone also reduces motion', (tester) async {
    await pumpInApp(
      tester,
      h,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: ReduceMotionScope(child: probe()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('reduced=true ctx=true duration=0'), findsOneWidget);
  });

  Future<void> pushWith(
    WidgetTester tester,
    Route<void> Function(WidgetBuilder builder) route, {
    required bool reduced,
  }) async {
    await tester.pumpWidget(const SizedBox()); // fresh navigator
    await tester.pumpWidget(
      MaterialApp(
        // Above the navigator, so pushed routes see it too.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context)
                  .push(route((_) => const Scaffold(body: Text('next page')))),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    // Mid-transition.
    await tester.pump(const Duration(milliseconds: 180));
  }

  /// A translating or scaling [Transform] above [text] (x/y scale: z stays 1).
  Finder movementOf(String text) => find.ancestor(
    of: find.text(text),
    matching: find.byWidgetPredicate((w) {
      if (w is! Transform) return false;
      final m = w.transform;
      final t = m.getTranslation();
      return t.x != 0 || t.y != 0 || m.entry(0, 0) != 1 || m.entry(1, 1) != 1;
    }),
  );

  group('shared axis', () {
    testWidgets('moves the incoming page horizontally', (tester) async {
      await pushWith(tester, AppMotion.sharedAxisRoute<void>, reduced: false);
      expect(movementOf('next page'), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('next page'), findsOneWidget);
    });

    testWidgets('reduced motion: cross-fade only, no movement', (tester) async {
      await pushWith(tester, AppMotion.sharedAxisRoute<void>, reduced: true);
      expect(movementOf('next page'), findsNothing);
      expect(
        find.ancestor(
          of: find.text('next page'),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );
      await tester.pumpAndSettle();
      expect(find.text('next page'), findsOneWidget);
    });

    testWidgets('mirrors its direction in RTL', (tester) async {
      Offset midOffset(TextDirection direction) {
        final transform = tester.widget<Transform>(
          find
              .ancestor(
                of: find.text('next page'),
                matching: find.byWidgetPredicate(
                  (w) => w is Transform && w.transform.getTranslation().x != 0,
                ),
              )
              .first,
        );
        final t = transform.transform.getTranslation();
        return Offset(t.x, t.y);
      }

      await pushWith(tester, AppMotion.sharedAxisRoute<void>, reduced: false);
      final ltr = midOffset(TextDirection.ltr);
      expect(
        ltr.dx,
        greaterThan(0),
        reason: 'enters from the end (right) in LTR',
      );
      await tester.pumpWidget(const SizedBox());

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(
            builder: (context, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    AppMotion.sharedAxisRoute<void>(
                      (_) => const Scaffold(body: Text('next page')),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(
        midOffset(TextDirection.rtl).dx,
        lessThan(0),
        reason: 'enters from the left in RTL',
      );
    });
  });

  group('fade through and container', () {
    testWidgets('fade-through scales in; reduced motion does not', (
      tester,
    ) async {
      await pushWith(tester, AppMotion.fadeThroughRoute<void>, reduced: false);
      expect(movementOf('next page'), findsWidgets);
      await tester.pumpAndSettle();

      await pushWith(tester, AppMotion.fadeThroughRoute<void>, reduced: true);
      expect(movementOf('next page'), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('container route grows the item; reduced motion does not', (
      tester,
    ) async {
      await pushWith(tester, AppMotion.containerRoute<void>, reduced: false);
      expect(movementOf('next page'), findsWidgets);
      await tester.pumpAndSettle();

      await pushWith(tester, AppMotion.containerRoute<void>, reduced: true);
      expect(movementOf('next page'), findsNothing);
      await tester.pumpAndSettle();
    });
  });

  testWidgets('FadeThroughSwitcher is instant when motion is reduced', (
    tester,
  ) async {
    Future<void> pumpSwitcher(bool reduced, int value) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: FadeThroughSwitcher(
            child: Text('v$value', key: ValueKey(value)),
          ),
        ),
      ),
    );

    await pumpSwitcher(false, 1);
    await pumpSwitcher(false, 2);
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.text('v1'),
      findsOneWidget,
      reason: 'old child still fading out',
    );
    await tester.pumpAndSettle();
    expect(find.text('v1'), findsNothing);

    await pumpSwitcher(true, 3);
    expect(
      find.text('v2'),
      findsNothing,
      reason: 'no transition with reduced motion',
    );
    expect(find.text('v3'), findsOneWidget);
    await pumpSwitcher(true, 4);
    expect(find.text('v3'), findsNothing);
    expect(find.text('v4'), findsOneWidget);
  });

  test(
    'page transition builder and go_router pages use the same transitions',
    () {
      const builder = SharedAxisPageTransitionsBuilder();
      expect(builder.axis, SharedAxis.horizontal);
      final page = AppMotion.sharedAxisPage<void>(
        key: const ValueKey('p'),
        child: const SizedBox(),
      );
      expect(page.key, const ValueKey('p'));
      final fade = AppMotion.fadeThroughPage<void>(
        key: const ValueKey('f'),
        child: const SizedBox(),
      );
      expect(fade.key, const ValueKey('f'));
    },
  );
}
