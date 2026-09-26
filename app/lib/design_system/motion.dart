import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/design_system/tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The in-app "Reduce motion" setting (`user_settings.appearance.reduceMotion`, arch §8.5).
final reduceMotionSettingProvider = Provider<bool>((ref) {
  final appearance =
      ref.watch(settingsProvider(SettingsNs.appearance)).value ?? const {};
  return appearance['reduceMotion'] == true;
});

/// Applies the in-app setting on top of the OS one (T1.3.15): below this widget
/// `MediaQuery.disableAnimations` — hence `context.reduceMotion` and [AppMotion.reduced] — is true
/// when either asks for less motion. Wrap the app once (app root builder).
class ReduceMotionScope extends ConsumerWidget {
  const ReduceMotionScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(reduceMotionSettingProvider);
    final media = MediaQuery.maybeOf(context);
    if (!setting || media == null || media.disableAnimations) return child;
    return MediaQuery(
      data: media.copyWith(disableAnimations: true),
      child: child,
    );
  }
}

/// Axis of a [SharedAxisTransition].
enum SharedAxis { horizontal, vertical, scaled }

/// Motion helpers (T1.3.18): consistent transitions — shared axis inside a tab, fade-through
/// between tabs, a container-style zoom for opening items — each replaced by a short cross-fade
/// (routes) or no animation (implicit animations) when reduce motion is on.
abstract final class AppMotion {
  /// Cross-fade used instead of movement when motion is reduced.
  static const reducedDuration = Duration(milliseconds: 120);

  /// Whether motion is reduced (OS setting or the in-app one via [ReduceMotionScope]).
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [normal], or zero when motion is reduced (for implicit animations).
  static Duration duration(
    BuildContext context, [
    Duration normal = Motion.normal,
  ]) => reduced(context) ? Duration.zero : normal;

  /// The standard curve, or linear when motion is reduced.
  static Curve curve(BuildContext context) =>
      reduced(context) ? Curves.linear : Motion.curve;

  /// Page route for forward navigation inside a tab (shared axis).
  static Route<T> sharedAxisRoute<T>(
    WidgetBuilder builder, {
    SharedAxis axis = SharedAxis.horizontal,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) => _route<T>(
    builder,
    settings: settings,
    fullscreenDialog: fullscreenDialog,
    transition: (animation, secondary, child) => SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondary,
      axis: axis,
      child: child,
    ),
  );

  /// Page route for switching between unrelated destinations (fade-through).
  static Route<T> fadeThroughRoute<T>(
    WidgetBuilder builder, {
    RouteSettings? settings,
  }) => _route<T>(
    builder,
    settings: settings,
    transition: (animation, secondary, child) => FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondary,
      child: child,
    ),
  );

  /// Page route for opening an item (container-style zoom from the list into the detail).
  static Route<T> containerRoute<T>(
    WidgetBuilder builder, {
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) => _route<T>(
    builder,
    settings: settings,
    fullscreenDialog: fullscreenDialog,
    transition: (animation, secondary, child) => SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondary,
      axis: SharedAxis.scaled,
      child: child,
    ),
  );

  /// go_router page with a shared-axis transition (`pageBuilder:` of a route).
  static Page<T> sharedAxisPage<T>({
    required LocalKey key,
    required Widget child,
    SharedAxis axis = SharedAxis.horizontal,
    bool fullscreenDialog = false,
  }) => CustomTransitionPage<T>(
    key: key,
    child: child,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: Motion.slow,
    reverseTransitionDuration: Motion.normal,
    transitionsBuilder: (context, animation, secondary, child) =>
        SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          axis: axis,
          child: child,
        ),
  );

  /// go_router page with a fade-through transition.
  static Page<T> fadeThroughPage<T>({
    required LocalKey key,
    required Widget child,
  }) => CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: Motion.slow,
    reverseTransitionDuration: Motion.normal,
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondary,
          child: child,
        ),
  );

  static Route<T> _route<T>(
    WidgetBuilder builder, {
    required Widget Function(
      Animation<double> animation,
      Animation<double> secondary,
      Widget child,
    )
    transition,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) => PageRouteBuilder<T>(
    settings: settings,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: Motion.slow,
    reverseTransitionDuration: Motion.normal,
    pageBuilder: (context, _, _) => builder(context),
    transitionsBuilder: (context, animation, secondary, child) =>
        transition(animation, secondary, child),
  );
}

/// Material shared-axis transition: the incoming page slides in (30 dp, or grows from 80 % for
/// [SharedAxis.scaled]) while fading in, the outgoing one moves away while fading out. Horizontal
/// movement follows the reading direction (mirrored in RTL). Reduced motion → cross-fade only.
class SharedAxisTransition extends StatelessWidget {
  const SharedAxisTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    super.key,
    this.axis = SharedAxis.horizontal,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final SharedAxis axis;
  final Widget child;

  static const _distance = 30.0;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    final sign = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(animation.value);
        final s = Curves.easeInOutCubic.transform(secondaryAnimation.value);
        // Incoming: fade in over the last 70 %; outgoing: fade out over the first 30 %.
        final fadeIn = const Interval(0.3, 1).transform(animation.value);
        final fadeOut =
            1 - const Interval(0, 0.3).transform(secondaryAnimation.value);
        Widget result = Opacity(
          opacity: (fadeIn * fadeOut).clamp(0.0, 1.0),
          child: child,
        );
        switch (axis) {
          case SharedAxis.horizontal:
            final dx = (1 - t) * _distance * sign - s * _distance * sign;
            result = Transform.translate(offset: Offset(dx, 0), child: result);
          case SharedAxis.vertical:
            final dy = (1 - t) * _distance - s * _distance;
            result = Transform.translate(offset: Offset(0, dy), child: result);
          case SharedAxis.scaled:
            final scale = (0.8 + 0.2 * t) * (1 + 0.1 * s);
            result = Transform.scale(scale: scale, child: result);
        }
        return result;
      },
    );
  }
}

/// Material fade-through: the outgoing page fades out, then the incoming one fades in while growing
/// from 92 %. Reduced motion → cross-fade only.
class FadeThroughTransition extends StatelessWidget {
  const FadeThroughTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final fadeIn = const Interval(0.35, 1).transform(animation.value);
        final fadeOut =
            1 - const Interval(0, 0.35).transform(secondaryAnimation.value);
        final scale =
            0.92 + 0.08 * Curves.easeOutCubic.transform(fadeIn.clamp(0.0, 1.0));
        return Opacity(
          opacity: (fadeIn * fadeOut).clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}

/// Switches between children (e.g. tab bodies, view modes) with a fade-through; instant when
/// motion is reduced. Give each child a distinct key.
class FadeThroughSwitcher extends StatelessWidget {
  const FadeThroughSwitcher({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => AppMotion.reduced(context)
      ? child
      : AnimatedSwitcher(
          duration: Motion.slow,
          switchInCurve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
          switchOutCurve: const Interval(0, 0.35),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: child,
        );
}

/// [PageTransitionsTheme] builder using [SharedAxisTransition] (honours reduce motion), for
/// `ThemeData.pageTransitionsTheme`.
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder({this.axis = SharedAxis.horizontal});

  final SharedAxis axis;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => SharedAxisTransition(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    axis: axis,
    child: child,
  );
}
