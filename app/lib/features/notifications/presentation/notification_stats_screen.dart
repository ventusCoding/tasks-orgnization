import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_stats_service.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_stats.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/mute_menu.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Notifications › Statistics (T7.5.17): per rule / section / item — delivered,
/// opened, acted, ignored, late, median time to act, effectiveness — and the reminders worth
/// taming ("You ignore 92 % of this reminder").
class NotificationStatsScreen extends ConsumerStatefulWidget {
  const NotificationStatsScreen({super.key});

  @override
  ConsumerState<NotificationStatsScreen> createState() => _NotificationStatsScreenState();
}

class _NotificationStatsScreenState extends ConsumerState<NotificationStatsScreen> {
  int _days = 30;
  StatsGroup _by = StatsGroup.rule;
  late Future<NotificationStatsReport> _report = _load();

  Future<NotificationStatsReport> _load() => ref.read(notificationStatsServiceProvider).load(days: _days, by: _by);

  void _reload() => setState(() => _report = _load());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final rules = {for (final r in ref.watch(notificationRulesProvider).value ?? const <NotificationRule>[]) r.id: r};
    String nameOf(NotificationStatsRow row) => switch (_by) {
      StatsGroup.rule => rules[row.key] == null ? l.notifInboxDeletedRule : labels.rule(rules[row.key]!),
      StatsGroup.section => switch (NotificationSection.tryParse(row.key)) {
        final s? => labels.section(s),
        null => row.key,
      },
      StatsGroup.target => row.label ?? row.key,
    };
    String pct(double? v) => v == null ? '—' : '${(v * 100).round()} %';
    return Scaffold(
      appBar: AppBar(title: Text(l.notifStatsTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Space.xxl),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
            child: SegmentedButton<int>(
              segments: [
                for (final d in const [7, 30, 90, 365]) ButtonSegment(value: d, label: Text(l.notifStatsDays(d))),
              ],
              selected: {_days},
              onSelectionChanged: (s) {
                _days = s.first;
                _reload();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
            child: SegmentedButton<StatsGroup>(
              segments: [
                ButtonSegment(value: StatsGroup.rule, label: Text(l.notifStatsByRule)),
                ButtonSegment(value: StatsGroup.section, label: Text(l.notifStatsBySection)),
                ButtonSegment(value: StatsGroup.target, label: Text(l.notifStatsByItem)),
              ],
              selected: {_by},
              onSelectionChanged: (s) {
                _by = s.first;
                _reload();
              },
            ),
          ),
          FutureBuilder<NotificationStatsReport>(
            future: _report,
            builder: (context, snap) {
              final report = snap.data;
              if (report == null) {
                return const Padding(padding: EdgeInsetsDirectional.all(Space.xl), child: LoadingState());
              }
              if (report.rows.isEmpty) {
                return EmptyState(icon: Icons.insights_outlined, title: l.notifStatsEmpty);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final n in report.noisy)
                    Card(
                      key: ValueKey('noisy-${n.ruleId}'),
                      margin: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, 0),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(Space.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rules[n.ruleId] == null ? l.notifInboxDeletedRule : labels.rule(rules[n.ruleId]!),
                              style: context.text.titleSmall,
                            ),
                            Text(l.notifStatsNoisy((n.ignoreRate * 100).round())),
                            Wrap(
                              spacing: Space.sm,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(notificationMutesRepositoryProvider)
                                        .mute(
                                          targetType: 'rule',
                                          targetId: n.ruleId,
                                          until: MuteMenuButton.untilFor(ref, MuteFor.week),
                                          reason: 'noisy',
                                        );
                                    _reload();
                                  },
                                  child: Text(l.notifStatsMuteWeek),
                                ),
                                if (rules[n.ruleId] != null)
                                  TextButton(
                                    onPressed: () async {
                                      await ref
                                          .read(notificationRulesRepositoryProvider)
                                          .update(n.ruleId, enabled: false);
                                      _reload();
                                    },
                                    child: Text(l.notifStatsTurnOff),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  SectionHeader(l.notifStatsSince(MaterialLocalizations.of(context).formatMediumDate(report.from))),
                  for (final r in report.rows)
                    ListTile(
                      key: ValueKey('stats-${r.key}'),
                      title: Text(nameOf(r)),
                      subtitle: Text(
                        [
                          l.notifStatsDelivered(r.delivered),
                          l.notifStatsOpened(r.opened),
                          l.notifStatsActed(r.acted),
                          '${l.notifStatsIgnored} ${pct(r.ignoreRate)}',
                          if (r.late > 0) '${l.notifStatsLate} ${pct(r.lateRate)}',
                          if (r.deferred > 0) l.notifStatsDeferred(r.deferred),
                          if (r.medianActionMinutes != null) l.notifStatsMedian(r.medianActionMinutes!.round()),
                          if (r.effectiveness != null) '${l.notifStatsEffective} ${pct(r.effectiveness)}',
                        ].join(' · '),
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
