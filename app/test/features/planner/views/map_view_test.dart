import 'package:everslot/features/planner/application/view_config/places.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:everslot/features/planner/domain/task_form.dart';
import 'package:everslot/features/planner/presentation/planner_screen.dart';
import 'package:everslot/features/planner/presentation/views/map_layer.dart';
import 'package:everslot/features/planner/presentation/views/map_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'support/items.dart';
import 'support/planner_harness.dart';

/// Map layer without tiles: one button per pin, and a "tap map" button.
Widget fakeMapLayer(
  BuildContext context, {
  required List<MapPin> pins,
  ({double lat, double lng})? center,
  ValueChanged<MapPin>? onTapPin,
  void Function(double lat, double lng)? onTapMap,
}) => ListView(
  key: const Key('fake-map'),
  children: [
    for (final p in pins)
      TextButton(
        key: ValueKey('pin-${p.id}'),
        onPressed: onTapPin == null ? null : () => onTapPin(p),
        child: Text('pin ${p.lat},${p.lng}'),
      ),
    if (onTapMap != null) TextButton(onPressed: () => onTapMap(45.76, 4.83), child: const Text('tap map')),
  ],
);

class FakeGeocoder implements PlaceGeocoder {
  @override
  Future<List<PlaceCandidate>> search(String query) async =>
      query == 'Louvre' ? const [PlaceCandidate(name: 'Musée du Louvre, Paris', lat: 48.86, lng: 2.34)] : const [];

  @override
  Future<String?> nameAt(double lat, double lng) async => 'Lyon';
}

// Map view & place picker (T3.7.13). Clock: Wed 23 Sep 2026 09:30 UTC.
void main() {
  setUpAll(initializeDateFormatting);

  test('the task form carries coordinates to the task and reports the change', () {
    const form = TaskForm(title: 'Museum', location: 'Louvre');
    final placed = form.copyWith(coordinates: (lat: 48.86, lng: 2.34));
    final task = placed.applyTo(const Task(id: 't', seriesId: 't', title: ''));
    expect((task.locationLat, task.locationLng), (48.86, 2.34));
    expect(placed.diff(form), {'place'});
    expect(TaskForm.fromTask(task).coordinates, (lat: 48.86, lng: 2.34));
  });

  testWidgets('pins for items with a place; tapping a pin shows the item', (tester) async {
    final h = PlannerHarness.create(
      items: [
        item('Museum', at(2026, 9, 24, 14), 120, id: 'museum'),
        item('Gym', at(2026, 9, 24, 7), 60, id: 'gym'),
      ],
      overrides: [
        mapLayerBuilderProvider.overrideWithValue(fakeMapLayer),
        placeTasksProvider.overrideWith(
          (ref) => Stream.value({
            'museum': const Task(
              id: 'museum',
              seriesId: 'museum',
              title: 'Museum',
              locationLat: 48.86,
              locationLng: 2.34,
            ),
          }),
        ),
      ],
    );
    addTearDown(h.dispose);
    await pumpPlanner(tester, h, const PlannerScreen(view: 'map', date: '2026-09-21'));
    await tester.pumpAndSettle();
    expect(find.text('pin 48.86,2.34'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-row-gym|2026-09-24T07:00')), findsNothing, reason: 'no place');
    await tester.tap(find.byKey(const ValueKey('pin-museum|2026-09-24T14:00')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-selected')), findsOneWidget);
  });

  testWidgets('no places: a hint explains how to add one', (tester) async {
    final h = PlannerHarness.create(
      overrides: [
        mapLayerBuilderProvider.overrideWithValue(fakeMapLayer),
        placeTasksProvider.overrideWith((ref) => Stream.value(const {})),
      ],
    );
    addTearDown(h.dispose);
    await pumpPlanner(tester, h, const PlannerScreen(view: 'map'));
    await tester.pumpAndSettle();
    expect(find.textContaining('find a place'), findsOneWidget);
  });

  testWidgets('place picker: search with the geocoder, or drop a pin named by reverse geocoding', (tester) async {
    final h = PlannerHarness.create(
      overrides: [
        mapLayerBuilderProvider.overrideWithValue(fakeMapLayer),
        placeGeocoderProvider.overrideWithValue(FakeGeocoder()),
      ],
    );
    addTearDown(h.dispose);
    PlaceCandidate? picked;
    await pumpPlanner(
      tester,
      h,
      Scaffold(
        body: Builder(
          builder: (context) =>
              TextButton(onPressed: () async => picked = await pickPlace(context), child: const Text('pick')),
        ),
      ),
    );
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('place-search')), 'Louvre');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Musée du Louvre, Paris'), findsWidgets);
    await tester.tap(find.text('tap map'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('place-use')));
    await tester.pumpAndSettle();
    expect(picked, const PlaceCandidate(name: 'Lyon', lat: 45.76, lng: 4.83));
  });
}
