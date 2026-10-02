import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/integrations/application/device_calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Widgets & integrations › Device calendars (T8.2.13): access primer, which calendars
/// to show (kept on this device) and where the overlay is turned on.
class DeviceCalendarSection extends ConsumerWidget {
  const DeviceCalendarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (ref.watch(deviceCalendarSourceProvider) == null) return const SizedBox.shrink();
    final access = ref.watch(deviceCalendarAccessProvider).value ?? false;
    final calendars = ref.watch(deviceCalendarsProvider).value ?? const [];
    final selected = ref.watch(deviceCalendarSelectionProvider).value ?? const <String>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.deviceCalSection),
        if (!access)
          ListTile(
            key: const ValueKey('device-cal-allow'),
            leading: const Icon(Icons.event_available_outlined),
            title: Text(l.deviceCalAllow),
            subtitle: Text(l.deviceCalPrimer),
            onTap: () async {
              final granted = await ref.read(deviceCalendarSelectionProvider.notifier).requestAccess();
              if (!granted && context.mounted) showInfoSnackBar(context, l.deviceCalDenied);
            },
          )
        else ...[
          for (final c in calendars)
            CheckboxListTile(
              key: ValueKey('device-cal-${c.id}'),
              value: selected.contains(c.id),
              secondary: Icon(
                Icons.circle,
                color: c.color == null ? null : Color(c.color!),
              ), // color-ok calendar colour
              title: Text(c.name),
              subtitle: c.account == null ? null : Text(c.account!),
              onChanged: (v) =>
                  unawaited(ref.read(deviceCalendarSelectionProvider.notifier).toggle(c.id, selected: v ?? false)),
            ),
          if (calendars.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
              child: Text(l.deviceCalNone),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.sm),
            child: Text(l.deviceCalHint, style: context.text.bodySmall),
          ),
        ],
      ],
    );
  }
}
