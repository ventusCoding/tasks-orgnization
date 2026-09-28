import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'items.dart';
import 'planner_harness.dart';

/// One golden variant: theme, direction and text scale.
typedef GoldenVariant = ({bool dark, bool rtl, double scale});

const GoldenVariant lightLtr = (dark: false, rtl: false, scale: 1.0);
const GoldenVariant darkRtl = (dark: true, rtl: true, scale: 1.0);
const GoldenVariant darkLtr = (dark: true, rtl: false, scale: 1.0);
const GoldenVariant lightRtl = (dark: false, rtl: true, scale: 1.0);
const GoldenVariant lightLtrLarge = (dark: false, rtl: false, scale: 2.0);

String variantName(GoldenVariant v) =>
    '${v.dark ? 'dark' : 'light'}_${v.rtl ? 'rtl' : 'ltr'}${v.scale == 1.0 ? '' : '_x${v.scale.toStringAsFixed(0)}'}';

/// Pumps [child] at DPR 1 (small images) with the app themes, animations off.
Future<void> pumpGolden(
  WidgetTester tester,
  PlannerHarness h,
  Widget child, {
  required GoldenVariant variant,
  Size size = const Size(420, 860),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: variant.rtl ? const Locale('ar') : const Locale('en'),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: variant.dark ? ThemeMode.dark : ThemeMode.light,
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(variant.scale), disableAnimations: true),
          child: app!,
        ),
        home: child,
      ),
    ),
  );
}

/// A representative week (Mon 21 – Sun 27 Sep 2026; the harness clock is Wed 23 09:30 UTC):
/// statuses, overlaps (three at once on Tuesday), short items, all-day, multi-day and a
/// midnight-crossing item.
List<PlannerItem> goldenWeek() => [
  item('Gym', at(2026, 9, 21, 7), 90, status: OccurrenceStatus.done, color: 0xFF2E7D32),
  item('Standup', at(2026, 9, 21, 9), 30, trackingMode: TrackingMode.event, color: 0xFF1565C0, recurring: true),
  item('Deep work', at(2026, 9, 22, 9), 120, color: 0xFF6A1B9A, priority: 3),
  item('Call Sam', at(2026, 9, 22, 10), 30, color: 0xFFEF6C00),
  item('Review', at(2026, 9, 22, 10, 15), 30, color: 0xFF00838F),
  item('Email', at(2026, 9, 23, 8), 20, color: 0xFF1565C0),
  item('Focus', at(2026, 9, 23, 9), 60, status: OccurrenceStatus.inProgress, color: 0xFF6A1B9A, trackingMode: TrackingMode.timer),
  item('Lunch', at(2026, 9, 23, 12), 60, status: OccurrenceStatus.skipped, color: 0xFF2E7D32),
  item('Workshop', at(2026, 9, 21, 14), 90, status: OccurrenceStatus.missed, color: 0xFFC62828),
  item('Dentist', at(2026, 9, 24, 16), 45, color: 0xFFC62828, location: 'Clinic'),
  item('Trip', at(2026, 9, 26), 2880, allDay: true, color: 0xFF00838F),
  item('Pay rent', at(2026, 9, 25), 1440, allDay: true, color: 0xFFEF6C00),
  item('Night shift', at(2026, 9, 27, 22), 180, color: 0xFF37474F),
];

/// Items around the DST change of [day] in [zone], with their real instants.
List<PlannerItem> goldenDstDay(LocalDate day, String zone) {
  final zones = TzZoneResolver();
  PlannerItem at(String title, int hour, int minute, int minutes, int color) {
    final start = day.atTime(LocalTime(hour, minute));
    return item(title, start, minutes, color: color, startUtc: zones.resolve(start, zone).utc);
  }

  return [
    at('Before', 0, 30, 60, 0xFF1565C0),
    at('Across', 1, 30, 120, 0xFF6A1B9A),
    at('After', 4, 0, 60, 0xFF2E7D32),
  ];
}
