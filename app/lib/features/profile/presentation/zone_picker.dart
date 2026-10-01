import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/profile/domain/zone_labels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/timezone.dart' as tz;

/// Searchable IANA time-zone picker (T1.5.05, T8.3.03). The device's detected zone is pinned first.
Future<String?> pickTimeZone(
  BuildContext context, {
  required String current,
  required String title,
  String? detected,
}) => showAppSheet<String>(
  context,
  title: title,
  builder: (_) => _ZonePicker(current: current, detected: detected),
);

/// "Tunis · UTC+01:00".
String zoneDisplay(String zone, DateTime nowUtc) {
  final city = zone == 'UTC' ? 'UTC' : ZoneLabels.city(zone);
  try {
    final offset = tz.TZDateTime.from(nowUtc, tz.getLocation(zone)).timeZoneOffset;
    return zone == 'UTC' ? city : '$city · ${ZoneLabels.offset(offset)}';
  } on Object {
    return city;
  }
}

class _ZonePicker extends ConsumerStatefulWidget {
  const _ZonePicker({required this.current, this.detected});

  final String current;
  final String? detected;

  @override
  ConsumerState<_ZonePicker> createState() => _ZonePickerState();
}

class _ZonePickerState extends ConsumerState<_ZonePicker> {
  late final List<String> _all = ZoneLabels.selectable(tz.timeZoneDatabase.locations.keys);
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = ref.watch(clockProvider).nowUtc();
    final detected = widget.detected;
    final filtered = [
      if (detected != null && ZoneLabels.matches(detected, _query)) detected,
      for (final z in _all)
        if (z != detected && ZoneLabels.matches(z, _query)) z,
    ];
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.authZoneSearch),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(icon: Icons.public_off, title: l.authZoneNoMatch)
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final zone = filtered[i];
                      final selected = zone == widget.current;
                      final region = ZoneLabels.region(zone);
                      return ListTile(
                        key: ValueKey('zone-$zone'),
                        selected: selected,
                        leading: zone == detected ? const Icon(Icons.my_location) : const Icon(Icons.public),
                        title: Text(zoneDisplay(zone, now)),
                        subtitle: Text(
                          [if (zone == detected) l.authZoneDetected, if (region.isNotEmpty) region].join(' · '),
                        ),
                        trailing: selected ? const Icon(Icons.check) : null,
                        onTap: () => Navigator.pop(context, zone),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
