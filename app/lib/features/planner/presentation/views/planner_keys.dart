import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Hardware-keyboard navigation of the date-paged planner views (tablets, T3.5.09 / T3.3.24):
/// ←/→ move to the previous / next page (mirrored in RTL, so the arrow follows the reading
/// direction), Home / T jumps to today. Grid-specific keys (selection, nudging, zoom) are handled by
/// the time grid itself.
class PlannerKeys extends StatelessWidget {
  const PlannerKeys({
    required this.child,
    required this.onPrevious,
    required this.onNext,
    this.onToday,
    super.key,
  });

  final Widget child;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): rtl
            ? onNext
            : onPrevious,
        const SingleActivator(LogicalKeyboardKey.arrowRight): rtl
            ? onPrevious
            : onNext,
        const SingleActivator(LogicalKeyboardKey.pageUp): onPrevious,
        const SingleActivator(LogicalKeyboardKey.pageDown): onNext,
        if (onToday != null) ...{
          const SingleActivator(LogicalKeyboardKey.home): onToday!,
          const SingleActivator(LogicalKeyboardKey.keyT): onToday!,
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
