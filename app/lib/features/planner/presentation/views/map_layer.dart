import 'package:everslot/design_system/design_system.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

/// One pin on the map (T3.7.13).
@immutable
class MapPin {
  const MapPin({required this.id, required this.lat, required this.lng, required this.color, required this.label});

  final String id;
  final double lat;
  final double lng;
  final Color color;
  final String label;
}

/// Builds the map surface: pins, optional selected point, taps on pins and on the map.
typedef MapLayerBuilder = Widget Function(
  BuildContext context, {
  required List<MapPin> pins,
  ({double lat, double lng})? center,
  ValueChanged<MapPin>? onTapPin,
  void Function(double lat, double lng)? onTapMap,
});

/// The map layer (OpenStreetMap tiles through `flutter_map`); tests swap in a fake without tiles.
final mapLayerBuilderProvider = Provider<MapLayerBuilder>((ref) => osmMapLayer);

/// `flutter_map` with OSM tiles (User-Agent set per the tile usage policy) and the attribution.
Widget osmMapLayer(
  BuildContext context, {
  required List<MapPin> pins,
  ({double lat, double lng})? center,
  ValueChanged<MapPin>? onTapPin,
  void Function(double lat, double lng)? onTapMap,
}) {
  final initial = center ?? (pins.isEmpty ? (lat: 48.8566, lng: 2.3522) : (lat: pins.first.lat, lng: pins.first.lng));
  return FlutterMap(
    options: MapOptions(
      initialCenter: LatLng(initial.lat, initial.lng),
      initialZoom: pins.length > 1 ? 11 : 13,
      initialCameraFit: pins.length > 1
          ? CameraFit.coordinates(
              coordinates: [for (final p in pins) LatLng(p.lat, p.lng)],
              padding: const EdgeInsets.all(48),
            )
          : null,
      onTap: onTapMap == null ? null : (_, p) => onTapMap(p.latitude, p.longitude),
    ),
    children: [
      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'app.everslot'),
      MarkerLayer(
        markers: [
          for (final p in pins)
            Marker(
              point: LatLng(p.lat, p.lng),
              width: 44,
              height: 44,
              child: Semantics(
                button: onTapPin != null,
                label: p.label,
                child: GestureDetector(
                  onTap: onTapPin == null ? null : () => onTapPin(p),
                  child: Icon(Icons.location_on, size: 40, color: p.color),
                ),
              ),
            ),
        ],
      ),
      RichAttributionWidget(attributions: [TextSourceAttribution(context.l10n.pvMapAttribution)]),
    ],
  );
}
