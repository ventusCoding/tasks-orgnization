import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/rule_preview.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_validation.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// "Next 5 firings" with reasons (quiet hours, paused, skipped…) and *Send test now* (T7.1.11).
/// Uses the same planner code path as real scheduling.
class RulePreviewList extends ConsumerStatefulWidget {
  const RulePreviewList({required this.rules, required this.targets, this.showNoise = false, this.limit = 5, super.key});

  final List<NotificationRule> rules;
  final List<NotificationTarget> targets;
  final bool showNoise;
  final int limit;

  @override
  ConsumerState<RulePreviewList> createState() => _RulePreviewListState();
}

class _RulePreviewListState extends ConsumerState<RulePreviewList> {
  Future<(List<PreviewEntry>, NoiseEstimate?)>? _future;
  String _signature = '';

  Future<(List<PreviewEntry>, NoiseEstimate?)> _load() async {
    final service = ref.read(rulePreviewServiceProvider);
    final entries = await service.nextFirings(widget.rules, widget.targets, limit: widget.limit);
    NoiseEstimate? noise;
    if (widget.showNoise && widget.rules.length == 1 && widget.targets.isNotEmpty) {
      noise = await service.noise(widget.rules.single, widget.targets.first);
    }
    return (entries, noise);
  }

  @override
  Widget build(BuildContext context) {
    final signature = [
      for (final r in widget.rules) '${r.id}:${r.enabled}:${r.profileId}:${r.spec.encode()}',
      for (final t in widget.targets) '${t.targetKey}:${t.occurrenceKey}:${t.start}',
    ].join('|');
    if (signature != _signature || _future == null) {
      _signature = signature;
      _future = _load();
    }
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final zone = ref.watch(deviceZoneProvider);
    final zones = ref.watch(zoneResolverProvider);
    final now = ref.watch(clockProvider).nowUtc();
    return FutureBuilder<(List<PreviewEntry>, NoiseEstimate?)>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Padding(padding: EdgeInsets.all(Space.lg), child: LinearProgressIndicator());
        final (entries, noise) = snap.data!;
        final ruleById = {for (final r in widget.rules) r.id: r};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
                child: Text(l.notifNoUpcoming, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
              ),
            for (final e in entries)
              ListTile(
                dense: true,
                leading: Icon(e.skipped ? Icons.block : Icons.notifications_active_outlined, size: 20),
                title: Text(
                  '${labels.format.dayShort(zones.toLocal(e.fireAt, zone).date)} · ${labels.format.timeOf(zones.toLocal(e.fireAt, zone))}'
                  ' — ${ruleById[e.ruleId] == null ? '' : labels.trigger(ruleById[e.ruleId]!.spec.trigger)}',
                ),
                subtitle: Text(
                  [
                    labels.format.relative(e.fireAt, now),
                    if (e.skipReason != null) labels.skipReason(e.skipReason!),
                    for (final a in e.planned?.adjustments ?? const {}) labels.adjustment(a),
                  ].join(' · '),
                ),
              ),
            if (noise != null && noise.level != NoiseLevel.ok)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
                child: Text(
                  noise.level == NoiseLevel.blocked ? l.notifNoiseBlocked : l.notifNoiseWarn(noise.firesPerDay.round()),
                  style: context.text.bodySmall?.copyWith(color: context.appColors.warning),
                ),
              ),
            if (noise != null && noise.sameMinuteClusters > 0)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
                child: Text(l.notifNoiseCluster, style: context.text.bodySmall),
              ),
            if (widget.rules.isNotEmpty && widget.targets.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: Space.sm),
                  child: TextButton.icon(
                    icon: const Icon(Icons.send_outlined),
                    label: Text(l.notifSendTest),
                    onPressed: () async {
                      await ref.read(rulePreviewServiceProvider).sendTest(widget.rules.first, widget.targets.first);
                      if (context.mounted) showInfoSnackBar(context, l.notifTestSent);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
