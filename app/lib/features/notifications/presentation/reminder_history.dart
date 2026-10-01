import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/domain/inbox_item.dart';
import 'package:everslot/features/notifications/presentation/inbox_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "Reminder history" for task / item / habit / quit details (T7.3.09): past inbox rows of one
/// source (fired, opened, acted, snoozed, dismissed).
class ReminderHistory extends ConsumerWidget {
  const ReminderHistory({required this.sourceType, required this.sourceId, this.limit = 20, super.key});

  /// `task`, `checklist_item`, `habit`, …
  final String sourceType;
  final String sourceId;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final rows = ref.watch(inboxHistoryProvider((sourceType, sourceId))).value ?? const <InboxItem>[];
    final now = ref.watch(clockProvider).nowUtc();
    final format = AppFormat(context.localeName, use24h: MediaQuery.alwaysUse24HourFormatOf(context), l10n: l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.notifInboxHistory),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
            child: Text(
              l.notifInboxHistoryEmpty,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
        for (final r in rows.take(limit)) InboxTile(item: r, format: format, now: now, dense: true),
      ],
    );
  }
}
