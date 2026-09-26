import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

/// Paging mode *free* (T3.3.13): continuous horizontal scrolling with momentum that settles on a
/// day boundary. [pageFraction] is the page extent as a fraction of the viewport (1 / days).
class SnapToPagePhysics extends ScrollPhysics {
  const SnapToPagePhysics({required this.pageFraction, super.parent});

  final double pageFraction;

  @override
  SnapToPagePhysics applyTo(ScrollPhysics? ancestor) =>
      SnapToPagePhysics(pageFraction: pageFraction, parent: buildParent(ancestor));

  double _pageExtent(ScrollMetrics position) => position.viewportDimension * pageFraction;

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final extent = _pageExtent(position);
    if (extent <= 0) return super.createBallisticSimulation(position, velocity);
    final projected = FrictionSimulation(0.135, position.pixels, velocity).finalX;
    final target = ((projected / extent).round() * extent).clamp(position.minScrollExtent, position.maxScrollExtent);
    final tolerance = toleranceFor(position);
    if ((target - position.pixels).abs() < tolerance.distance && velocity.abs() < tolerance.velocity) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
  }

  @override
  bool get allowImplicitScrolling => false;
}
