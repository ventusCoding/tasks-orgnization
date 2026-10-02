import 'dart:async';
import 'dart:io';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/widgets_home/application/widget_actions_runner.dart';
import 'package:everslot/features/widgets_home/application/widget_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

final _canPinProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    return await ref.watch(widgetBridgeProvider).canPin();
  } on Object {
    return false;
  }
});

/// Home-screen widgets in Settings › Widgets & integrations (T8.2.03–08): what exists, *Add to
/// home screen* where the launcher supports it (Android), how to add them otherwise (iOS), and a
/// manual refresh.
class WidgetsSettingsSection extends ConsumerWidget {
  const WidgetsSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final canPin = ref.watch(_canPinProvider).value ?? false;
    final kinds = [
      ('today', Icons.today_outlined, l.widgetKindToday, l.widgetKindTodayHint),
      ('habits', Icons.task_alt, l.widgetKindHabits, l.widgetKindHabitsHint),
      ('quit', Icons.timer_outlined, l.widgetKindQuit, l.widgetKindQuitHint),
      ('checklist', Icons.checklist, l.widgetKindChecklist, l.widgetKindChecklistHint),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.widgetsSection),
        for (final (kind, icon, title, hint) in kinds)
          ListTile(
            key: ValueKey('widget-kind-$kind'),
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(hint),
            trailing: canPin
                ? TextButton(
                    key: ValueKey('widget-pin-$kind'),
                    onPressed: () => unawaited(ref.read(widgetBridgeProvider).pin(kind)),
                    child: Text(l.widgetAdd),
                  )
                : null,
          ),
        if (!canPin)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg, vertical: Space.sm),
            child: Text(Platform.isIOS ? l.widgetHowToIos : l.widgetHowToAndroid, style: context.text.bodySmall),
          ),
        ListTile(
          key: const ValueKey('widget-refresh'),
          leading: const Icon(Icons.refresh),
          title: Text(l.widgetRefresh),
          onTap: () async {
            final container = ProviderScope.containerOf(context, listen: false);
            await refreshWidgetSnapshot(container);
            if (context.mounted) showInfoSnackBar(context, l.widgetRefreshed);
          },
        ),
      ],
    );
  }
}
