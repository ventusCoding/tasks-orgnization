import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/domain/quota_summary.dart';
import 'package:material_ui/material_ui.dart';

export 'package:everslot/features/planner/domain/quota_summary.dart' show QuotaSummary, quotaSummaries;

/// "Run · 1/3 this week" / "Run · done for this week" (T3.2.16) — shown by the views in the
/// all-day lane / week header for the quota slots of the visible range (`quotaSummaries`).
class QuotaIndicator extends StatelessWidget {
  const QuotaIndicator(this.summary, {super.key, this.onTap});

  final QuotaSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = summary;
    final label = s.complete
        ? l.tasksQuotaIndicatorDone(s.title, s.unit.name)
        : l.tasksQuotaIndicator(s.title, s.done, s.target, s.unit.name);
    final pill = StatusPill(
      label: label,
      color: s.complete ? context.appColors.completed : context.appColors.todo,
      icon: s.complete ? Icons.check_circle_outline : Icons.repeat,
    );
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      child: onTap == null
          ? pill
          : InkWell(borderRadius: BorderRadius.circular(Radii.pill), onTap: onTap, child: pill),
    );
  }
}
