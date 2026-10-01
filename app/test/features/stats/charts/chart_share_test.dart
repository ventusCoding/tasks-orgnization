// Share chart as image (T6.2.23) and the dev chart gallery (T6.2.24).
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/charts.dart';
import 'package:everslot/features/stats/presentation/chart_gallery_screen.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeSharer implements ChartImageSharer {
  final shared = <(Uint8List, String)>[];

  @override
  Future<void> share(Uint8List png, {required String title}) async => shared.add((png, title));
}

Widget app(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
  home: home,
);

final _donut = DonutData(const [
  DonutSlice(TextLabel('Running'), 120, color: ArgbColor(0xFF3B82F6)),
  DonutSlice(TextLabel('Reading'), 60, color: ArgbColor(0xFF10B981)),
], unit: StatUnit.minutes);

Future<Uint8List> _rgba(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();

void main() {
  late _FakeSharer sharer;
  setUp(() {
    sharer = _FakeSharer();
    chartImageSharer = sharer;
  });
  tearDown(() => chartImageSharer = const PlatformChartImageSharer());

  testWidgets('the exported PNG is the on-screen card at 3×, pixel for pixel', (tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ChartShareSheet(title: 'Time by habit', subtitle: 'This week', data: _donut),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Made with Everslot'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Share'));
      for (var i = 0; i < 20 && sharer.shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    expect(sharer.shared, hasLength(1));
    expect(sharer.shared.single.$2, 'Time by habit');

    final state = tester.state<ChartShareSheetState>(find.byType(ChartShareSheet));
    final boundary = state.boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(sharer.shared.single.$1);
      final exported = (await codec.getNextFrame()).image;
      final onScreen = await boundary.toImage(pixelRatio: 3);
      expect(exported.width, (boundary.size.width * 3).round());
      expect(exported.height, (boundary.size.height * 3).round());
      expect(await _rgba(exported), await _rgba(onScreen));
      exported.dispose();
      onScreen.dispose();
    });
  });

  testWidgets('"Hide names" replaces user names with Item 1…', (tester) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ChartShareSheet(title: 'Habits', data: _donut),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Running'), findsWidgets);
    await tester.tap(find.text('Hide names'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Running'), findsNothing);
    expect(find.textContaining('Reading'), findsNothing);
    expect(find.textContaining('Item 1'), findsWidgets);
    expect(find.textContaining('Item 2'), findsWidgets);
    expect(anonymousNamesOf(_donut), {'Running': 1, 'Reading': 2});
  });

  testWidgets('a metric chart frame opens the share preview', (tester) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Builder(
            builder: (context) => ChartFrame(
              title: 'Time by habit',
              data: _donut,
              onShare: () => showChartShareSheet(context, title: 'Time by habit', data: _donut),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Share chart'));
    await tester.pumpAndSettle();
    expect(find.byType(ChartShareSheet), findsOneWidget);
  });

  testWidgets('chart gallery lists every chart of the kit and its toggles work', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const ChartGalleryScreen()));
    await tester.pumpAndSettle();
    final kinds = {for (final s in allChartSamples()) s.kind};
    // Every chart family of the kit has a sample.
    for (final k in [
      ChartKind.line,
      ChartKind.groupedBars,
      ChartKind.donut,
      ChartKind.pareto,
      ChartKind.punchCard,
      ChartKind.gantt,
      ChartKind.moveTimeline,
      ChartKind.histogram,
      ChartKind.boxPlot,
      ChartKind.scatter,
      ChartKind.cfd,
      ChartKind.burn,
      ChartKind.radar,
      ChartKind.rose,
      ChartKind.treemap,
      ChartKind.matrix,
      ChartKind.km,
      ChartKind.forecast,
    ]) {
      expect(kinds, contains(k));
    }
    final list = find.byKey(const ValueKey('chart-gallery-list'));
    for (final s in allChartSamples()) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('gallery-${s.kind.name}-${s.title}')),
        300,
        scrollable: find.descendant(of: list, matching: find.byType(Scrollable)),
      );
      expect(tester.takeException(), isNull, reason: s.title);
    }
    await tester.tap(find.text('Dark theme'));
    await tester.tap(find.text('Right to left'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<ColorVision>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deuteranopia').last);
    await tester.pumpAndSettle();
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(colorVisionMatrix(ColorVision.normal), isNull);
    for (final v in ColorVision.values.skip(1)) {
      expect(colorVisionMatrix(v), hasLength(20));
    }
  });
}
