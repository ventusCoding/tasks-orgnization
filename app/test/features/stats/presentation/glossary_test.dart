// Metric glossary (T6.1.21): search, pre-filtered entry from an explain sheet, and navigation from
// every explain sheet through the router.
import 'package:everslot/features/stats/application/metric_registry.dart';
import 'package:everslot/features/stats/presentation/glossary_screen.dart';
import 'package:everslot/features/stats/presentation/scope_stats_screen.dart';
import 'package:everslot/features/stats/presentation/widgets/explain_sheet.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../support/stats_harness.dart';

final en = lookupAppLocalizations(const Locale('en'));

void main() {
  testWidgets('lists every metric and filters by words', (tester) async {
    final h = StatsHarness.create();
    addTearDown(h.dispose);
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpStats(tester, h, const GlossaryScreen());
    await tester.pump();
    expect(find.text(en.statsGlossaryCount(MetricRegistry.instance.all.length)), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'adherence');
    await tester.pump();
    expect(find.text(en.statsMetricPlS03Title), findsOneWidget);
    expect(find.text(en.statsMetricQt07Title), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzzz nothing');
    await tester.pump();
    expect(find.text(en.statsGlossaryEmpty('zzzz nothing')), findsOneWidget);
  });

  testWidgets('a metric id query opens its entry expanded', (tester) async {
    final h = StatsHarness.create();
    addTearDown(h.dispose);
    await pumpStats(tester, h, const GlossaryScreen(initialQuery: 'PL-X-01'));
    await tester.pump();
    expect(find.text(en.statsMetricPlX01Title), findsOneWidget);
    expect(find.text(en.statsMetricPlX01Formula), findsOneWidget);
  });

  testWidgets('every explain sheet opens the glossary on its metric', (tester) async {
    final h = StatsHarness.create();
    addTearDown(h.dispose);
    final def = MetricRegistry.instance.byId('HB-H-05')!;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showExplainSheet(context, def: def),
                child: const Text('explain'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/insights/:scope',
          builder: (_, s) => ScopeStatsScreen(scope: s.pathParameters['scope']!, query: s.uri.queryParameters),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp.router(
          routerConfig: router,
          supportedLocales: const [Locale('en')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        ),
      ),
    );
    await tester.tap(find.text('explain'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text(en.statsExplainGlossary));
    await tester.tap(find.text(en.statsExplainGlossary));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(GlossaryScreen), findsOneWidget);
    expect(find.text(en.statsMetricHbH05Formula), findsOneWidget);
  });
}
