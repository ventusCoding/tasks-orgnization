/// Merge and rename blocked reasons into clusters (T6.4.14, CL-L-26): pick reasons, name the
/// cluster, save. Clusters apply to every list (`user_settings.stats.blockerClusters`).
library;

import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/blocker_clusters_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One raw reason of the sheet (from the CL-L-26 result args).
typedef BlockerReason = ({String key, String label, int episodes, String? cluster});

/// Reasons of a CL-L-26 result.
List<BlockerReason> blockerReasonsOf(Map<String, Object?> args) => [
  for (final r in (args['reasons'] as List?)?.cast<Map<Object?, Object?>>() ?? const <Map<Object?, Object?>>[])
    (
      key: r['key']! as String,
      label: r['label']! as String,
      episodes: (r['episodes']! as num).toInt(),
      cluster: r['cluster'] as String?,
    ),
];

Future<void> showBlockerClustersSheet(BuildContext context, List<BlockerReason> reasons) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => BlockerClustersSheet(reasons: reasons),
);

class BlockerClustersSheet extends ConsumerStatefulWidget {
  const BlockerClustersSheet({required this.reasons, super.key});

  final List<BlockerReason> reasons;

  @override
  ConsumerState<BlockerClustersSheet> createState() => _BlockerClustersSheetState();
}

class _BlockerClustersSheetState extends ConsumerState<BlockerClustersSheet> {
  final _selected = <String>{};
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save({bool unmerge = false}) async {
    await ref.read(blockerClustersStoreProvider).assign(_selected, unmerge ? '' : _name.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canMerge = _selected.isNotEmpty && _name.text.trim().isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: Space.lg,
          end: Space.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + Space.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.statsClustersTitle, style: context.text.titleMedium),
            const SizedBox(height: Space.xs),
            Text(l.statsClustersHint, style: context.text.bodySmall),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final r in widget.reasons)
                    CheckboxListTile(
                      key: ValueKey('cluster-${r.key}'),
                      value: _selected.contains(r.key),
                      title: Text(r.label),
                      subtitle: Text(
                        [
                          l.statsClustersEpisodes(r.episodes),
                          if (r.cluster != null) l.statsClustersIn(r.cluster!),
                        ].join(' · '),
                      ),
                      onChanged: (v) => setState(() => v! ? _selected.add(r.key) : _selected.remove(r.key)),
                    ),
                ],
              ),
            ),
            TextField(
              key: const ValueKey('cluster-name'),
              controller: _name,
              decoration: InputDecoration(labelText: l.statsClustersName),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.md),
            Row(
              children: [
                TextButton(
                  onPressed: _selected.isEmpty ? null : () => unawaited(_save(unmerge: true)),
                  child: Text(l.statsClustersUnmerge),
                ),
                const Spacer(),
                FilledButton(onPressed: canMerge ? () => unawaited(_save()) : null, child: Text(l.statsClustersMerge)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
