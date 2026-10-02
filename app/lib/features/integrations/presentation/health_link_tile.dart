import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart' show HealthMetric;
import 'package:everslot/features/integrations/application/health_sync_service.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

String healthMetricLabel(AppLocalizations l, HealthMetric m) => switch (m) {
  HealthMetric.steps => l.healthSteps,
  HealthMetric.workout => l.healthWorkout,
  HealthMetric.mindful => l.healthMindful,
  HealthMetric.sleep => l.healthSleep,
  HealthMetric.water => l.healthWater,
};

/// Habit editor: *Log automatically from Health* (T8.2.14). Hidden where health data is not
/// available; linking shows a primer, then the system permission prompt.
class HealthLinkTile extends ConsumerWidget {
  const HealthLinkTile({required this.value, required this.onChanged, super.key});

  final HealthMetric? value;
  final ValueChanged<HealthMetric?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (!(ref.watch(healthAvailableProvider).value ?? false)) return const SizedBox.shrink();
    return ListTile(
      key: const ValueKey('habit-health-link'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.favorite_border),
      title: Text(l.healthLink),
      subtitle: Text(value == null ? l.habitsNone : healthMetricLabel(l, value!)),
      onTap: () async {
        final picked = await showAppSheet<(HealthMetric?,)>(
          context,
          title: l.healthLink,
          builder: (sheet) => ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: Text(l.habitsNone), onTap: () => Navigator.pop(sheet, (null,))),
              for (final m in HealthMetric.values)
                ListTile(
                  key: ValueKey('health-metric-${m.json}'),
                  title: Text(healthMetricLabel(l, m)),
                  subtitle: Text(m.unit),
                  selected: m == value,
                  onTap: () => Navigator.pop(sheet, (m,)),
                ),
            ],
          ),
        );
        if (picked == null || !context.mounted) return;
        final metric = picked.$1;
        if (metric == null) {
          onChanged(null);
          return;
        }
        final ok = await confirmDialog(
          context,
          title: l.healthPrimerTitle,
          body: l.healthPrimerBody(healthMetricLabel(l, metric)),
          confirmLabel: l.healthPrimerContinue,
        );
        if (!ok || !context.mounted) return;
        final granted = await ref.read(healthSourceProvider).requestAccess({metric});
        if (!context.mounted) return;
        if (granted) {
          onChanged(metric);
        } else {
          showInfoSnackBar(context, l.healthDenied);
        }
      },
    );
  }
}
