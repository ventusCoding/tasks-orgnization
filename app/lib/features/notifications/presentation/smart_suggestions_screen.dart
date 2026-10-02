import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/smart_reminders.dart';
import 'package:everslot/features/notifications/domain/smart_suggestions.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Notifications › Smart suggestions (T7.5.19).
class SmartSuggestionsScreen extends ConsumerStatefulWidget {
  const SmartSuggestionsScreen({super.key});

  @override
  ConsumerState<SmartSuggestionsScreen> createState() => _SmartSuggestionsScreenState();
}

class _SmartSuggestionsScreenState extends ConsumerState<SmartSuggestionsScreen> {
  late Future<(List<ReminderSuggestion>, Map<String, String>)> _data = _load();

  Future<(List<ReminderSuggestion>, Map<String, String>)> _load() async {
    final service = ref.read(smartRemindersProvider);
    return (await service.suggestions(), await service.titles());
  }

  void _reload() => setState(() => _data = _load());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final settings = ref.watch(notificationSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.notifSmartTitle)),
      body: ListView(
        children: [
          SwitchListTile(
            key: const ValueKey('smart-auto'),
            title: Text(l.notifSmartAuto),
            subtitle: Text(l.notifSmartAutoHint),
            value: settings.smartAdjust,
            onChanged: (v) => unawaited(ref.read(notificationSettingsWriterProvider)({'smartAdjust': v})),
          ),
          const Divider(),
          FutureBuilder<(List<ReminderSuggestion>, Map<String, String>)>(
            future: _data,
            builder: (context, snap) {
              final data = snap.data;
              if (data == null) {
                return const Padding(padding: EdgeInsetsDirectional.all(Space.xl), child: LoadingState());
              }
              final (suggestions, titles) = data;
              if (suggestions.isEmpty) {
                return EmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: l.notifSmartNone,
                  message: l.notifSmartNoneBody,
                );
              }
              return Column(
                children: [
                  for (final s in suggestions)
                    Card(
                      key: ValueKey('smart-${s.ruleId}'),
                      margin: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(Space.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.notifSmartSuggestion(
                                titles[s.targetKey] ?? l.notifSmartThisItem,
                                labels.time(s.usual),
                                labels.time(s.proposed),
                              ),
                            ),
                            Text(
                              l.notifSmartCurrent(labels.time(s.current), s.samples),
                              style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                            Wrap(
                              spacing: Space.sm,
                              children: [
                                FilledButton.tonal(
                                  key: ValueKey('smart-apply-${s.ruleId}'),
                                  onPressed: () async {
                                    await ref.read(smartRemindersProvider).apply(s);
                                    _reload();
                                  },
                                  child: Text(l.notifSmartApply),
                                ),
                                TextButton(
                                  key: ValueKey('smart-dismiss-${s.ruleId}'),
                                  onPressed: () async {
                                    await ref.read(smartRemindersProvider).dismiss(s);
                                    _reload();
                                  },
                                  child: Text(l.notifSmartDismiss),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
