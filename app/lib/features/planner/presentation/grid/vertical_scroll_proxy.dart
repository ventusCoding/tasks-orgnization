import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// One vertical [Scrollable] shared by every page and the time ruler (T3.3.13).
///
/// It owns the scroll position (drag, fling, overscroll, accessibility scroll actions) but does not
/// translate its [child]: pages and the ruler read [controller]'s offset and translate only their
/// own content (see `ScrolledContent`), so a page change keeps the time on screen and scrolling
/// never rebuilds the pages. Horizontal gestures (the pager) live inside [child] and compete in the
/// same gesture arena.
class VerticalScrollProxy extends StatelessWidget {
  const VerticalScrollProxy({
    required this.controller,
    required this.viewportExtent,
    required this.contentExtent,
    required this.child,
    this.physics,
    super.key,
  });

  final ScrollController controller;

  /// Height of the scrolled body (the part of [child] below pinned headers).
  final double viewportExtent;

  /// Full height of the scrolled content.
  final double contentExtent;
  final ScrollPhysics? physics;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scrollable(
    controller: controller,
    physics: physics,
    viewportBuilder: (context, position) =>
        _ProxyViewport(offset: position, viewportExtent: viewportExtent, contentExtent: contentExtent, child: child),
  );
}

class _ProxyViewport extends SingleChildRenderObjectWidget {
  const _ProxyViewport({
    required this.offset,
    required this.viewportExtent,
    required this.contentExtent,
    required Widget super.child,
  });

  final ViewportOffset offset;
  final double viewportExtent;
  final double contentExtent;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderProxyViewport(offset: offset, viewportExtent: viewportExtent, contentExtent: contentExtent);

  @override
  void updateRenderObject(BuildContext context, _RenderProxyViewport renderObject) {
    renderObject
      ..offset = offset
      ..viewportExtent = viewportExtent
      ..contentExtent = contentExtent;
  }
}

class _RenderProxyViewport extends RenderProxyBox {
  _RenderProxyViewport({required this._offset, required this._viewportExtent, required this._contentExtent});

  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    if (identical(value, _offset)) return;
    _offset = value;
    markNeedsLayout();
  }

  double _viewportExtent;
  set viewportExtent(double value) {
    if (value == _viewportExtent) return;
    _viewportExtent = value;
    markNeedsLayout();
  }

  double _contentExtent;
  set contentExtent(double value) {
    if (value == _contentExtent) return;
    _contentExtent = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    super.performLayout();
    final viewport = math.max<double>(0, _viewportExtent);
    _offset
      ..applyViewportDimension(viewport)
      ..applyContentDimensions(0, math.max(0, _contentExtent - viewport));
  }
}
