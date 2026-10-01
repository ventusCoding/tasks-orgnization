import 'package:everslot/features/planner/application/planner_service.dart';
import 'package:everslot/features/planner/domain/task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:meta/meta.dart';

/// A place found by search or picked on the map (T3.7.13).
@immutable
class PlaceCandidate {
  const PlaceCandidate({required this.name, required this.lat, required this.lng});

  final String name;
  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      other is PlaceCandidate && other.name == name && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(name, lat, lng);
}

/// Geocoding behind an interface (the platform geocoder in the app, fakes in tests).
abstract interface class PlaceGeocoder {
  /// Places matching [query] (empty when nothing or offline).
  Future<List<PlaceCandidate>> search(String query);

  /// Display name of a point (null when unknown).
  Future<String?> nameAt(double lat, double lng);
}

/// `geocoding` (CLGeocoder on iOS, the Android Geocoder): no API key, results in the device
/// language; failures (offline, no service) return nothing.
class PlatformPlaceGeocoder implements PlaceGeocoder {
  PlatformPlaceGeocoder() : _geo = geo.Geocoding();

  final geo.Geocoding _geo;

  @override
  Future<List<PlaceCandidate>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      final found = await _geo.locationFromAddress(q);
      return [
        for (final l in found.take(5))
          PlaceCandidate(name: await nameAt(l.latitude, l.longitude) ?? q, lat: l.latitude, lng: l.longitude),
      ];
    } on Object {
      return const [];
    }
  }

  @override
  Future<String?> nameAt(double lat, double lng) async {
    try {
      final p = (await _geo.placemarkFromCoordinates(lat, lng)).firstOrNull;
      if (p == null) return null;
      final parts = [p.name, p.locality, p.country].whereType<String>().where((s) => s.trim().isNotEmpty);
      return parts.isEmpty ? null : parts.toSet().join(', ');
    } on Object {
      return null;
    }
  }
}

final placeGeocoderProvider = Provider<PlaceGeocoder>((ref) => PlatformPlaceGeocoder());

/// Task id → map point of every task with coordinates (T3.7.13).
final placeTasksProvider = StreamProvider.autoDispose<Map<String, Task>>(
  (ref) => ref.watch(plannerServiceProvider).queries.watchPlaceTasks().map((tasks) => {for (final t in tasks) t.id: t}),
);
