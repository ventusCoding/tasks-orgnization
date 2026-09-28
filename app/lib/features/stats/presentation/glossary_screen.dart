/// Metric glossary (T6.1.21): every registered metric with its id, plain-language description and
/// formula, searchable and grouped by section. Every explain sheet links here
/// (`/insights/glossary?q=<metric id>`).
library;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/stats/application/stats_providers.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';
import 'package:everslot/features/stats/presentation/l10n/stats_l10n.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Section of a metric scope in the glossary.
String glossarySection(AppLocalizations l, MetricScope scope) => switch (scope) {
  MetricScope.task || MetricScope.series || MetricScope.planner => l.statsSegmentPlan,
  MetricScope.checklistItem || MetricScope.checklist || MetricScope.checklists => l.statsSegmentLists,
  MetricScope.habit || MetricScope.habits => l.statsSegmentHabits,
  MetricScope.quit => l.statsSegmentQuit,
  MetricScope.global => l.statsSegmentOverview,
};

/// Whether [def] matches the lower-cased [query] (id, title, description or formula).
bool glossaryMatches(AppLocalizations l, MetricDefinition def, String query) {
  if (query.isEmpty) return true;
  final haystack = [
    def.id,
    metricTitle(l, def.id) ?? '',
    metricDescription(l, def.id) ?? '',
    metricFormula(l, def.id) ?? '',
  ].join(' ').toLowerCase();
  return query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).every(haystack.contains);
}

class GlossaryScreen extends ConsumerStatefulWidget {
  const GlossaryScreen({super.key, this.initialQuery});

  /// Pre-filled search (the explain sheet passes the metric id).
  final String? initialQuery;

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  late final TextEditingController _search = TextEditingController(text: widget.initialQuery ?? '');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final registry = ref.watch(metricRegistryProvider);
    final query = _search.text.trim();
    final matches = [
      for (final d in registry.all)
        if (metricTitle(l, d.id) != null && glossaryMatches(l, d, query)) d,
    ];
    final sections = <String, List<MetricDefinition>>{};
    for (final d in matches) {
      sections.putIfAbsent(glossarySection(l, d.scope), () => []).add(d);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.statsGlossaryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.xs),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.statsGlossarySearch,
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l.statsGlossaryCount(matches.length),
                style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? EmptyState(icon: Icons.search_off, title: l.statsGlossaryEmpty(query))
                : ListView(
                    children: [
                      for (final section in sections.entries) ...[
                        SectionHeader(section.key),
                        for (final d in section.value) _GlossaryEntry(def: d, expanded: query == d.id),
                      ],
                      const SizedBox(height: Space.xl),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GlossaryEntry extends StatelessWidget {
  const _GlossaryEntry({required this.def, this.expanded = false});

  final MetricDefinition def;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ExpansionTile(
      initiallyExpanded: expanded,
      title: Text(metricTitle(l, def.id) ?? def.id),
      subtitle: Text(def.id, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
      childrenPadding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.md),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(metricDescription(l, def.id) ?? ''),
        const SizedBox(height: Space.sm),
        Text(l.statsGlossaryFormula, style: context.text.labelMedium),
        Text(metricFormula(l, def.id) ?? '', style: context.text.bodySmall),
      ],
    );
  }
}
