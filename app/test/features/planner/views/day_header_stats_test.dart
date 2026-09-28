import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/domain/view_config/day_window.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/planner/presentation/grid/day_header.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_slices.dart';
import 'package:everslot/features/planner/presentation/grid/engine/day_timeline.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';

// Day header stats & load tint (T3.4.11): done/total of check items, planned minutes, load =
// planned ÷ work-hours minutes with thresholds (default 80 % / 100 %).
void main() {
  final mon = LocalDate(2026, 9, 21);
  final sat = LocalDate(2026, 9, 26);
  const work = WorkSettings(hours: DayWindow(9 * 60, 17 * 60));

  DaySlice slice(LocalDate day, List<PlannerItem> items) =>
      sliceItems(items: items, days: [day], timelineOf: DayTimeline.regular).single;

  test('done/total counts check items; planned minutes skip cancelled and skipped', () {
    final s = DayStats.of(
      slice(mon, [
        item('Gym', at(2026, 9, 21, 7), 60, status: OccurrenceStatus.done),
        item('Write', at(2026, 9, 21, 9), 120),
        item('Standup', at(2026, 9, 21, 10), 30, trackingMode: TrackingMode.event),
        item('Skipped', at(2026, 9, 21, 13), 60, status: OccurrenceStatus.skipped),
        item('Cancelled', at(2026, 9, 21, 15), 60, status: OccurrenceStatus.cancelled),
      ]),
      work,
    );
    expect((s.done, s.total), (1, 3));
    expect(s.plannedMinutes, 210);
    expect(s.load, closeTo(210 / 480, 1e-9));
  });

  test('a day off has infinite load as soon as something is planned', () {
    expect(DayStats.of(slice(sat, [item('Brunch', at(2026, 9, 26, 11), 60)]), work).load, double.infinity);
    expect(DayStats.of(slice(sat, const []), work).load, 0);
  });

  testWidgets('tint thresholds: none below warn, warning from warn, danger from over', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final colors = ctx.appColors;
    expect(loadTint(ctx, 0.5), isNull);
    expect(loadTint(ctx, 0.85), colors.warning.withValues(alpha: 0.14));
    expect(loadTint(ctx, 1.2), colors.danger.withValues(alpha: 0.14));
    expect(loadTint(ctx, 0.85, warn: 0.9), isNull, reason: 'configurable thresholds');
    expect(loadTint(ctx, 0.95, warn: 0.9, over: 0.95), colors.danger.withValues(alpha: 0.14));
  });
}
