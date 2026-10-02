// Goldens of the Today screen (T8.1.02 / T8.1.13): a full day in light/dark × LTR/RTL and the
// empty state. Regenerate with `--update-goldens`.
@Tags(['golden'])
library;

import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/today/presentation/today_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_app.dart';
import '../today_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  setUp(() => h = TestHarness.create(now: DateTime.utc(2026, 9, 22, 10)));
  tearDown(() => h.dispose());

  Future<void> seed() async {
    await h.task('Standup', start: at(2026, 9, 22, 9, 30), duration: 60);
    await h.task('Review', start: at(2026, 9, 22, 14));
    await h.task('Forgotten', start: at(2026, 9, 21, 9));
    await h.habit('Read', start: LocalDate(2026, 9, 1));
    await h.habit(
      'Water',
      start: LocalDate(2026, 9, 1),
      goal: const HabitTarget(type: HabitGoalType.count, target: 8, unit: 'glasses'),
    );
  }

  for (final (dark, rtl) in [(false, false), (true, false), (false, true), (true, true)]) {
    final name = '${dark ? 'dark' : 'light'}_${rtl ? 'rtl' : 'ltr'}';
    testWidgets('today golden $name', (tester) async {
      await tester.runAsync(seed);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpToday(
        tester,
        h,
        const TodayScreen(),
        dark: dark,
        locale: rtl ? const Locale('ar') : const Locale('en'),
        size: const Size(360, 1100),
      );
      await settle(tester, rounds: 10);
      await expectLater(find.byType(TodayScreen), matchesGoldenFile('goldens/today_$name.png'));
    });
  }

  testWidgets('today golden empty', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpToday(tester, h, const TodayScreen(), size: const Size(360, 640));
    await settle(tester, rounds: 10);
    await expectLater(find.byType(TodayScreen), matchesGoldenFile('goldens/today_empty.png'));
  });
}
