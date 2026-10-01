/// Drill-down (T6.1.16, T6.2.10): the occurrences, items or logs behind a chart element, each
/// opening its entity.
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/domain/chart_data.dart';
import 'package:everslot/features/stats/presentation/stats_navigation.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the refs behind a chart element; the chosen entity opens from the caller's context (which
/// outlives the sheet).
Future<void> showDrillSheet(BuildContext context, {required String title, required List<DrillRef> refs}) async {
  final chosen = await showAppSheet<DrillRef>(
    context,
    builder: (context) => DrillSheet(title: title, refs: refs),
  );
  if (chosen != null && context.mounted) openDrillRef(context, chosen);
}

class DrillSheet extends StatelessWidget {
  const DrillSheet({required this.title, required this.refs, super.key});

  final String title;
  final List<DrillRef> refs;

  IconData _icon(DrillKind kind) => switch (kind) {
    DrillKind.task || DrillKind.occurrence => Icons.event_note_outlined,
    DrillKind.checklist || DrillKind.item => Icons.checklist,
    DrillKind.habit || DrillKind.day => Icons.repeat,
    DrillKind.quit => Icons.smoke_free,
    DrillKind.category => Icons.label_outline,
  };

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.statsDrillTitle,
                style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              Text(title, style: context.text.titleMedium),
            ],
          ),
        ),
        if (refs.isEmpty)
          Padding(padding: const EdgeInsets.all(Space.lg), child: Text(context.l10n.statsDrillEmpty))
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: refs.length,
              itemBuilder: (context, i) {
                final r = refs[i];
                final path = drillPath(r);
                return ListTile(
                  leading: Icon(_icon(r.kind)),
                  title: Text(r.title ?? r.id, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: r.subtitle == null ? null : Text(r.subtitle!),
                  trailing: path == null ? null : const Icon(Icons.chevron_right),
                  onTap: path == null ? null : () => Navigator.of(context).pop(r),
                );
              },
            ),
          ),
      ],
    ),
  );
}
