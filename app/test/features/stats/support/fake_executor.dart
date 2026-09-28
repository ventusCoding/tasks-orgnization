import 'package:everslot/features/stats/application/stats_compute_service.dart';
import 'package:everslot/features/stats/domain/metric_definition.dart';
import 'package:everslot/features/stats/domain/stats_inputs.dart';
import 'package:everslot_metrics/everslot_metrics.dart';

/// A stats executor returning canned results (missing ids → "no data"), recording every job.
class FakeStatsExecutor implements StatsExecutor {
  FakeStatsExecutor([Map<String, MetricResult>? results]) : results = results ?? {};

  final Map<String, MetricResult> results;
  final jobs = <StatsJob>[];

  /// Results per period key, when a test checks that a period change updates the cards.
  final Map<String, Map<String, MetricResult>> byPeriod = {};

  @override
  Future<Map<String, MetricResult>> run(StatsJob job) async {
    jobs.add(job);
    final period = byPeriod[job.request.selection.period.key] ?? const {};
    return {
      for (final id in job.metricIds)
        id: period[id] ?? results[id] ?? MetricResult(id, value: const NotApplicable<double>(Reasons.noData)),
    };
  }
}
