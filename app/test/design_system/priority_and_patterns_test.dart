import 'dart:ui' as ui;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/domain/priority.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Priorities (T2.3.03) and color-blind-safe category patterns (T2.3.04).
void main() {
  group('Priority value object', () {
    test('parses stored values and clamps unknown ones to none', () {
      expect(Priority.fromValue(0), Priority.none);
      expect(Priority.fromValue(4), Priority.urgent);
      expect(Priority.fromValue(null), Priority.none);
      expect(Priority.fromValue(9), Priority.none);
      expect(Priority.values.map((p) => p.value), [0, 1, 2, 3, 4]);
      expect(Priority.high.isSet, isTrue);
      expect(Priority.none.isSet, isFalse);
    });

    test('sorts most urgent first, none last', () {
      final sorted = [
        Priority.low,
        Priority.none,
        Priority.urgent,
        Priority.medium,
      ]..sort(Priority.compareUrgentFirst);
      expect(sorted, [
        Priority.urgent,
        Priority.medium,
        Priority.low,
        Priority.none,
      ]);
      final values = [0, 3, null, 4]..sort(Priority.compareValuesUrgentFirst);
      expect(values, [4, 3, 0, null]);
    });
  });

  group('priority widgets', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create());
    tearDown(() => h.dispose());

    for (final locale in ['en', 'fr', 'ar']) {
      testWidgets(
        'badges pair icon + label with an accessible name ($locale)',
        (tester) async {
          final handle = tester.ensureSemantics();
          final l = lookupAppLocalizations(Locale(locale));
          await pumpInApp(
            tester,
            h,
            Scaffold(
              body: Column(
                children: [
                  for (var p = 0; p <= 4; p++)
                    PriorityBadge(p, showLabel: true),
                ],
              ),
            ),
            locale: Locale(locale),
          );
          final labels = [
            l.priorityNone,
            l.priorityLow,
            l.priorityMedium,
            l.priorityHigh,
            l.priorityUrgent,
          ];
          for (var p = 0; p <= 4; p++) {
            expect(find.bySemanticsLabel(labels[p]), findsWidgets);
            expect(find.byIcon(PriorityStyle.icon(p)), findsWidgets);
          }
          // Color is never the only signal: urgent has its own icon.
          expect(PriorityStyle.icon(4), isNot(PriorityStyle.icon(3)));
          expect(PriorityStyle.icon(0), isNot(PriorityStyle.icon(1)));
          handle.dispose();
        },
      );
    }

    testWidgets('a "none" badge is hidden unless labelled', (tester) async {
      await pumpInApp(tester, h, const Scaffold(body: PriorityBadge(0)));
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('selector picks a priority', (tester) async {
      var value = 0;
      await pumpInApp(
        tester,
        h,
        Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PrioritySelector(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'High'));
      await tester.pump();
      expect(value, 3);
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'High'),
      );
      expect(chip.selected, isTrue);
      final semantics = tester.getSemantics(
        find.widgetWithText(ChoiceChip, 'High'),
      );
      expect(semantics.flagsCollection.isSelected, ui.Tristate.isTrue);
    });

    testWidgets('dark theme uses lighter, readable priority colors', (
      tester,
    ) async {
      Color labelColor(Brightness b) {
        final context = tester.element(find.byType(PriorityBadge));
        expect(Theme.of(context).brightness, b);
        return tester.widget<Text>(find.text('Medium')).style!.color!;
      }

      Future<void> pump(ThemeData theme) => pumpInApp(
        tester,
        h,
        Theme(
          data: theme,
          child: const Scaffold(body: PriorityBadge(2, showLabel: true)),
        ),
      );
      await pump(AppTheme.light());
      final light = labelColor(Brightness.light);
      await pump(AppTheme.dark());
      final dark = labelColor(Brightness.dark);
      expect(dark.computeLuminance(), greaterThan(light.computeLuminance()));
    });
  });

  group('category patterns', () {
    test('the 16 palette colors get 16 distinct textures', () {
      final textures = {
        for (final c in CategoryPalette.colors) CategoryPatterns.forColor(c),
      };
      expect(textures, hasLength(16));
      // Custom colors are stable.
      expect(
        CategoryPatterns.forColor(0xFF123456),
        CategoryPatterns.forColor(0xFF123456),
      );
    });

    test('every pattern paints within its bounds', () {
      for (final pattern in CategoryPattern.values) {
        for (final dense in [false, true]) {
          final recorder = ui.PictureRecorder();
          final painter = CategoryPatternPainter(
            pattern: pattern,
            color: const Color(0x55000000),
            dense: dense,
          );
          final canvas = Canvas(recorder);
          painter
            ..paint(canvas, const Size(120, 48))
            ..paint(canvas, Size.zero);
          final picture = recorder.endRecording();
          expect(
            picture.approximateBytesUsed,
            greaterThan(0),
            reason: '$pattern',
          );
          picture.dispose();
          expect(painter.shouldRepaint(painter), isFalse);
          expect(
            painter.shouldRepaint(
              CategoryPatternPainter(
                pattern: pattern,
                color: const Color(0x55FFFFFF),
              ),
            ),
            isTrue,
          );
        }
      }
    });

    test('the pattern color follows the readable foreground of the tile', () {
      final tile = CategoryColors.background(
        CategoryPalette.at(0),
        Brightness.light,
      );
      final painter = CategoryPatternPainter.forCategory(
        CategoryPalette.at(0),
        tile,
      );
      expect(painter.color.a, closeTo(0.22, 0.01));
      expect(painter.pattern, CategoryPattern.diagonal);
    });
  });
}
