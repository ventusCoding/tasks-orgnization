import 'dart:convert';

import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
import 'package:everslot/features/planner/presentation/grid/engine/paging.dart';
import 'package:everslot/features/planner/presentation/view_config/planner_view_config.dart';
import 'package:everslot/features/planner/presentation/view_config/saved_views_repository.dart';
import 'package:everslot/features/planner/presentation/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/view_config/view_state.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  group('PlannerViewConfig', () {
    test('week table defaults: 7 days × 30-min rows × 24 h', () {
      final c = PlannerViewConfig.defaultsFor(PlannerViewType.weekTable);
      expect(c.daysVisible, 7);
      expect(c.slotMinutes, 30);
      expect(c.slotExtentPx, 48);
      expect(c.zoomMode, ZoomMode.fixed);
      expect(c.renderMode, RenderMode.auto);
      expect(c.autoTableThresholdMinutes, 120);
      expect(c.snapMinutes, 15);
      expect(c.dayWindow, DayWindow.full);
      expect(c.paging, PagingMode.week);
      expect(c.usesTable, isFalse);
      expect(c.withSlot(120).usesTable, isTrue);
      expect(c.withSlot(1440).isWeekListMode, isTrue);
    });

    test('every type has defaults that round-trip losslessly', () {
      for (final type in PlannerViewType.values) {
        final c = PlannerViewConfig.defaultsFor(type);
        expect(c.type, type);
        final back = PlannerViewConfig.fromJson(jsonDecode(jsonEncode(c.toJson())) as Map<String, Object?>);
        expect(back, c, reason: type.id);
      }
    });

    test('a customized config round-trips', () {
      final c = PlannerViewConfig.defaultsFor(PlannerViewType.weekTable).copyWith(
        slotMinutes: 7,
        slotExtentPx: 30,
        zoomMode: ZoomMode.semantic,
        renderMode: RenderMode.table,
        snapMinutes: 5,
        daysVisible: 5,
        firstDay: 'SA',
        paging: PagingMode.free,
        dayWindow: const DayWindow(360, 1320),
        showWeekends: false,
        filters: const ViewFilters(categories: ['c1'], priorities: [3], statuses: ['done'], text: 'gym'),
        colorBy: ColorBy.priority,
        density: Density.compact,
        extraTimeZones: ['Asia/Tokyo', 'America/New_York', 'UTC', 'Europe/Paris'],
        options: {'monthMode': 'dots'},
      );
      expect(c.extraTimeZones, hasLength(3));
      final back = PlannerViewConfig.fromJson(jsonDecode(jsonEncode(c.toJson())) as Map<String, Object?>);
      expect(back, c);
      expect(back.itemFilter.statuses, {OccurrenceStatus.done});
    });

    test('out-of-range values clamp', () {
      final c = PlannerViewConfig.fromJson(const {
        'v': 1,
        'type': 'week_table',
        'slotMinutes': 0,
        'slotExtentPx': 1000,
        'snapMinutes': 90,
        'daysVisible': 30,
        'dayWindow': {'start': '10:00', 'end': '08:00'},
        'maxChipsPerCell': 0,
      });
      expect(c.slotMinutes, 1);
      expect(c.slotExtentPx, 400);
      expect(c.snapMinutes, 60);
      expect(c.daysVisible, 14);
      expect(c.dayWindow, DayWindow.full);
      expect(c.maxChipsPerCell, 1);
      expect(PlannerViewConfig.fromJson(const {'type': 'week_table', 'slotMinutes': 5000}).slotMinutes, 1440);
    });

    test('an older (v0) fixture upgrades', () {
      final c = PlannerViewConfig.fromJson(const {'type': 'week_table', 'slot': 15, 'rowHeight': 40, 'days': 5, 'hours': [6, 22]});
      expect(c.slotMinutes, 15);
      expect(c.slotExtentPx, 40);
      expect(c.daysVisible, 5);
      expect(c.dayWindow, const DayWindow(360, 1320));
      expect(c.toJson()['v'], 1);
    });

    test('unknown keys are preserved', () {
      final c = PlannerViewConfig.fromJson(const {'v': 1, 'type': 'month', 'futureKey': {'a': 1}});
      expect(c.extra['futureKey'], {'a': 1});
      expect(c.toJson()['futureKey'], {'a': 1});
      expect(c.copyWith(slotMinutes: 60).toJson()['futureKey'], {'a': 1});
    });

    test('withSlot keeps a default snap in step with the slot', () {
      final c = PlannerViewConfig.defaultsFor(PlannerViewType.weekTable);
      expect(c.withSlot(5).snapMinutes, 5);
      expect(c.withSlot(5).withSlot(60).snapMinutes, 15);
      expect(c.copyWith(snapMinutes: 10).withSlot(5).snapMinutes, 5);
      expect(c.withSlot(60, keepPxPerMinute: true).slotExtentPx, 96);
    });

    test('work-week entry is an N-day preset without weekends', () {
      final c = ViewKeys.defaultsForEntry('work_week');
      expect(c.type, PlannerViewType.nDay);
      expect(c.showWeekends, isFalse);
      expect(c.daysVisible, 5);
      expect(ViewKeys.savedIdOf('saved:abc'), 'abc');
      expect(ViewKeys.savedIdOf('month'), isNull);
    });
  });

  group('persistence', () {
    late TestHarness h;
    setUp(() {
      h = TestHarness.create();
      ViewConfigController.saveDelay = Duration.zero;
    });
    tearDown(() => h.dispose());

    test('defaults are created once with deterministic ids', () async {
      final repo = h.read(savedViewsRepositoryProvider);
      final entries = {
        'week_table': (PlannerViewConfig.defaultsFor(PlannerViewType.weekTable), 'Week table'),
        'day_list': (PlannerViewConfig.defaultsFor(PlannerViewType.dayList), 'Day list'),
      };
      await repo.ensureDefaults(entries);
      await repo.ensureDefaults(entries);
      final views = await repo.all();
      expect(views, hasLength(2));
      expect(views.first.id, SavedViewsRepository.entryViewId('user-1', 'week_table'));
      expect(views.first.isDefault, isTrue);
      expect(views.first.config.slotMinutes, 30);
    });

    test('config edits persist and reload (sync through saved_views)', () async {
      final notifier = h.read(plannerViewConfigProvider('week_table').notifier);
      notifier.update(h.read(plannerViewConfigProvider('week_table')).withSlot(7));
      await notifier.flush();
      final stored = await h.read(savedViewsRepositoryProvider).all();
      expect(stored.single.config.slotMinutes, 7);
      final outbox = await h.db.customSelect("SELECT COUNT(*) AS c FROM sync_outbox WHERE table_name = 'saved_views'").getSingle();
      expect(outbox.data['c'], greaterThan(0));
    });

    test('saved views: create, rename, duplicate, set default, reorder, delete', () async {
      final repo = h.read(savedViewsRepositoryProvider);
      final a = await repo.create('Deep work · 5 min', PlannerViewConfig.defaultsFor(PlannerViewType.weekTable).withSlot(5));
      final b = await repo.create('Night shift', PlannerViewConfig.defaultsFor(PlannerViewType.weekTable));
      await repo.rename(b, 'Night shift 18:00–06:00');
      final c = await repo.duplicate(a, 'Copy');
      await repo.setDefault(b);
      var views = await repo.all();
      expect(views.map((v) => v.name), ['Deep work · 5 min', 'Night shift 18:00–06:00', 'Copy']);
      expect(views.where((v) => v.isDefault).single.id, b);
      expect(views.last.config.slotMinutes, 5);
      await repo.move(c!, beforeKey: views.first.sortKey);
      await repo.delete(a);
      views = await repo.all();
      expect(views.map((v) => v.name), ['Copy', 'Night shift 18:00–06:00']);
    });

    test('local view state: minute ↔ offset and persistence', () async {
      final axis = PageAxis.regular();
      final offset = ViewState.offsetForMinute(axis, 1.6, 540, viewportExtent: 600, anchorFraction: 1 / 3);
      expect(offset, 540 * 1.6 - 200);
      expect(ViewState.minuteAtOffset(axis, 1.6, offset, viewportExtent: 600, anchorFraction: 1 / 3), closeTo(540, 1e-9));
      // Zoom change keeps the minute at the viewport centre.
      final centre = ViewState.minuteAtOffset(axis, 1.6, 400, viewportExtent: 600, anchorFraction: 0.5);
      final zoomed = ViewState.offsetForMinute(axis, 3.2, centre, viewportExtent: 600, anchorFraction: 0.5);
      expect(ViewState.minuteAtOffset(axis, 3.2, zoomed, viewportExtent: 600, anchorFraction: 0.5), closeTo(centre, 1e-9));

      final repo = h.read(viewStateRepositoryProvider);
      await repo.write('week_table', ViewState(anchor: LocalDate(2026, 9, 21), scrollMinute: 480, pxPerMinute: 2));
      await repo.update('week_table', (s) => s.copyWith(daysPortrait: 3));
      final back = await repo.read('week_table');
      expect(back!.anchor, LocalDate(2026, 9, 21));
      expect(back.scrollMinute, 480);
      expect(back.daysPortrait, 3);
      expect(await repo.read('missing'), isNull);
    });
  });
}
