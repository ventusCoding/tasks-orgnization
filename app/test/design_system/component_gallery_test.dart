import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/dev/presentation/component_gallery_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot/shared/filters/presentation/filter_bar.dart';
import 'package:everslot/shared/status/presentation/entity_status_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Component gallery (T1.3.10 acceptance): every component renders, toggles apply, and each
/// dialog/sheet/picker opens and returns its value.
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  final l = lookupAppLocalizations(const Locale('en'));

  Future<void> pumpGallery(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1000, 16000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpInApp(
      tester,
      h,
      const ComponentGalleryScreen(animateIndicators: false),
    );
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder f) =>
      find.descendant(of: find.byType(AlertDialog), matching: f);
  Finder inSheet(Finder f) =>
      find.descendant(of: find.byType(BottomSheet), matching: f);

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(OutlinedButton, label));
    await tester.pumpAndSettle();
  }

  testWidgets('shows every section and component family', (tester) async {
    await pumpGallery(tester);
    for (final title in [
      l.galleryButtons,
      l.galleryChips,
      l.galleryInputs,
      l.galleryStatuses,
      l.galleryPriorities,
      l.galleryProgress,
      l.galleryColors,
      l.galleryIcons,
      l.galleryStates,
      l.galleryDialogs,
      l.galleryFilters,
      l.galleryMotion,
      l.galleryLayout,
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.byType(EntityStatusPill), findsNWidgets(14));
    expect(find.byType(PriorityBadge), findsNWidgets(5));
    expect(find.byType(PrioritySelector), findsOneWidget);
    expect(find.byType(ProgressRing), findsOneWidget);
    expect(find.byType(SegmentedBar), findsOneWidget);
    expect(find.byType(FilterBar), findsOneWidget);
    expect(find.byType(EmptyState), findsNWidgets(2)); // empty + error
    expect(find.byType(LoadingState), findsOneWidget);
    expect(find.byType(TwoPaneScaffold), findsOneWidget);
  });

  testWidgets('toggles switch theme, direction and text scale', (tester) async {
    await pumpGallery(tester);
    BuildContext probe() => tester.element(find.text(l.galleryButtons));
    expect(Theme.of(probe()).brightness, Brightness.light);

    await tester.tap(find.widgetWithText(SwitchListTile, l.galleryDarkTheme));
    await tester.pumpAndSettle();
    expect(Theme.of(probe()).brightness, Brightness.dark);

    await tester.tap(find.widgetWithText(SwitchListTile, l.galleryRtl));
    await tester.pumpAndSettle();
    expect(Directionality.of(probe()), TextDirection.rtl);

    await tester.tap(find.widgetWithText(SwitchListTile, l.galleryLargeText));
    await tester.pumpAndSettle();
    expect(MediaQuery.textScalerOf(probe()).scale(10), 20);

    await tester.tap(
      find.widgetWithText(SwitchListTile, l.galleryReduceMotion),
    );
    await tester.pumpAndSettle();
    expect(AppMotion.reduced(probe()), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialogs, sheets and pickers open and return values', (
    tester,
  ) async {
    await pumpGallery(tester);

    await tapButton(tester, l.galleryConfirm);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(
      inDialog(find.widgetWithText(FilledButton, l.actionDelete)),
    );
    await tester.pumpAndSettle();
    expect(find.text(l.galleryPicked('true')), findsOneWidget);

    await tapButton(tester, l.galleryPrompt);
    await tester.enterText(inDialog(find.byType(TextField)), 'hello');
    await tester.tap(inDialog(find.widgetWithText(FilledButton, l.actionSave)));
    await tester.pumpAndSettle();
    expect(find.text(l.galleryPicked('hello')), findsOneWidget);

    await tapButton(tester, l.pickerDuration);
    await tester.tap(inSheet(find.widgetWithText(ChoiceChip, '45m')));
    await tester.pump();
    await tester.tap(inSheet(find.widgetWithText(FilledButton, l.actionApply)));
    await tester.pumpAndSettle();
    expect(find.text(l.galleryPicked('45 min')), findsOneWidget);

    await tapButton(tester, l.pickerColor);
    await tester.tap(find.bySemanticsLabel('#3B82F6'));
    await tester.pumpAndSettle();
    expect(find.text(l.galleryPicked('#ff3b82f6')), findsOneWidget);

    await tapButton(tester, l.pickerIcon);
    await tester.tap(find.byTooltip('work'));
    await tester.pumpAndSettle();
    expect(find.text(l.galleryPicked('work')), findsOneWidget);

    await tapButton(tester, l.gallerySheet);
    expect(find.text(l.gallerySheetBody), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text(l.gallerySheetBody), findsNothing);

    await tapButton(tester, l.galleryUndoSnack);
    expect(find.widgetWithText(SnackBarAction, l.actionUndo), findsOneWidget);
  });

  testWidgets('motion demos push pages', (tester) async {
    await pumpGallery(tester);
    for (final label in [
      l.gallerySharedAxis,
      l.galleryFadeThrough,
      l.galleryContainer,
    ]) {
      await tapButton(tester, label);
      expect(find.widgetWithText(AppBar, label), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });
}
