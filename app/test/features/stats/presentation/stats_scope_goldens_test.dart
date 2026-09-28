// Goldens of the stats scaffold (T6.1.16): light/dark × LTR/RTL and text scale 2.0.
@Tags(['golden'])
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/stats_scope_view.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_executor.dart';
import '../support/stats_harness.dart';
import 'stats_scope_view_test.dart' show plannerResults;

void main() {
  for (final (name, dark, rtl, scale) in [
    ('light_ltr', false, false, 1.0),
    ('dark_ltr', true, false, 1.0),
    ('light_rtl', false, true, 1.0),
    ('dark_rtl', true, true, 1.0),
    ('light_ltr_2x', false, false, 2.0),
  ]) {
    testWidgets('scope scaffold golden $name', (tester) async {
      final h = StatsHarness.create(now: DateTime.utc(2026, 9, 23, 9), executor: FakeStatsExecutor(plannerResults()));
      addTearDown(h.dispose);
      await h.settle();
      tester.view.physicalSize = Size(420, scale == 1 ? 1600 : 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            locale: Locale(rtl ? 'ar' : 'en'),
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
                child: const Scaffold(body: StatsScopeView(scope: MetricScope.planner)),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(find.byType(StatsScopeView), matchesGoldenFile('goldens/scope_scaffold_$name.png'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 61));
    });
  }
}
