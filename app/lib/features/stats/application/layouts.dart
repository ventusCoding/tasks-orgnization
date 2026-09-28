/// Default card layouts per Insights scope (T6.1.16) — the section screens ([6.3]–[6.7]) only
/// declare these; the stats scaffold renders them.
library;

import 'package:everslot/features/stats/domain/stats_layout.dart';
import 'package:everslot/features/stats/domain/stats_types.dart';

const _half = CardSpan.half;

/// Task stats sheet (T6.3.17).
const taskLayout = StatsLayout(
  MetricScope.task,
  kpis: ['PL-T-06', 'PL-T-01', 'PL-T-02', 'PL-T-07'],
  sections: [
    StatsLayoutSection('occurrence', [
      StatsLayoutItem('PL-T-03'),
      StatsLayoutItem('PL-T-04', span: _half),
      StatsLayoutItem('PL-T-05', span: _half),
    ]),
  ],
);

/// Series stats screen (T6.3.18).
const seriesLayout = StatsLayout(
  MetricScope.series,
  kpis: ['PL-S-03', 'PL-S-05', 'PL-S-06', 'PL-S-07'],
  sections: [
    StatsLayoutSection('series', [
      StatsLayoutItem('PL-S-09'),
      StatsLayoutItem('PL-S-03'),
      StatsLayoutItem('PL-S-02'),
      StatsLayoutItem('PL-S-01', span: _half),
      StatsLayoutItem('PL-S-04', span: _half),
      StatsLayoutItem('PL-S-08', span: _half),
      StatsLayoutItem('PL-S-05'),
      StatsLayoutItem('PL-S-06'),
    ]),
  ],
);

/// Planner Insights screen (T6.3.19).
const plannerLayout = StatsLayout(
  MetricScope.planner,
  kpis: ['PL-X-01', 'PL-X-05', 'PL-X-12', 'PL-X-08', 'PL-X-06'],
  sections: [
    StatsLayoutSection('execution', [
      StatsLayoutItem('PL-X-02'),
      StatsLayoutItem('PL-X-03'),
      StatsLayoutItem('PL-X-04'),
      StatsLayoutItem('PL-X-06'),
    ]),
    StatsLayoutSection('capacity', [
      StatsLayoutItem('PL-X-08'),
      StatsLayoutItem('PL-X-07', span: _half),
      StatsLayoutItem('PL-X-11', span: _half),
      StatsLayoutItem('PL-X-09'),
      StatsLayoutItem('PL-X-10'),
      StatsLayoutItem('PL-X-12'),
    ]),
    StatsLayoutSection('allocation', [
      StatsLayoutItem('PL-X-13'),
      StatsLayoutItem('PL-X-14'),
      StatsLayoutItem('PL-X-15'),
    ]),
  ],
);

/// Item insights panel (T6.4.15).
const itemLayout = StatsLayout(
  MetricScope.checklistItem,
  kpis: ['CL-I-02', 'CL-I-03', 'CL-I-04', 'CL-I-05'],
  sections: [
    StatsLayoutSection('item', [
      StatsLayoutItem('CL-I-07'),
      StatsLayoutItem('CL-I-01'),
      StatsLayoutItem('CL-I-06'),
    ]),
  ],
);

/// Checklist Insights screen (T6.4.16).
const checklistLayout = StatsLayout(
  MetricScope.checklist,
  kpis: ['CL-L-01', 'CL-L-03', 'CL-L-04', 'CL-L-06'],
  sections: [
    StatsLayoutSection('status', [StatsLayoutItem('CL-L-01')]),
    StatsLayoutSection('flow', [
      StatsLayoutItem('CL-L-02'),
      StatsLayoutItem('CL-L-03'),
      StatsLayoutItem('CL-L-04'),
      StatsLayoutItem('CL-L-05'),
    ]),
    StatsLayoutSection('stale', [StatsLayoutItem('CL-L-06')]),
  ],
);

/// Lists Insights screen (T6.4.17).
const checklistsLayout = StatsLayout(
  MetricScope.checklists,
  kpis: ['CL-X-04', 'CL-X-03'],
  sections: [
    StatsLayoutSection('lists', [
      StatsLayoutItem('CL-X-01'),
      StatsLayoutItem('CL-X-04'),
      StatsLayoutItem('CL-X-02'),
      StatsLayoutItem('CL-X-03'),
      StatsLayoutItem('CL-X-05'),
    ]),
  ],
);

/// Habit Insights screen (T6.5.16).
const habitLayout = StatsLayout(
  MetricScope.habit,
  kpis: ['HB-H-01', 'HB-H-02', 'HB-H-03', 'HB-H-05', 'HB-H-09'],
  sections: [
    StatsLayoutSection('strength', [StatsLayoutItem('HB-H-01')]),
    StatsLayoutSection('calendar', [StatsLayoutItem('HB-H-08')]),
    StatsLayoutSection('history', [StatsLayoutItem('HB-H-07')]),
    StatsLayoutSection('targetVolume', [StatsLayoutItem('HB-H-10'), StatsLayoutItem('HB-H-11')]),
    StatsLayoutSection('streaks', [StatsLayoutItem('HB-H-04')]),
    StatsLayoutSection('outcomes', [StatsLayoutItem('HB-H-06'), StatsLayoutItem('HB-H-05')]),
    StatsLayoutSection('dataQuality', [StatsLayoutItem('HB-H-25')]),
  ],
);

/// Habits section Insights screen (T6.5.17).
const habitsLayout = StatsLayout(
  MetricScope.habits,
  kpis: ['HB-X-01', 'HB-X-02', 'HB-X-04'],
  sections: [
    StatsLayoutSection('habitTable', [StatsLayoutItem('HB-X-01', variant: 'habitTable')]),
    StatsLayoutSection('trend', [
      StatsLayoutItem('HB-X-04'),
      StatsLayoutItem('HB-X-03'),
      StatsLayoutItem('HB-X-02'),
    ]),
    StatsLayoutSection('quitTrackers', [StatsLayoutItem('HB-X-05')]),
    StatsLayoutSection('dataQuality', [StatsLayoutItem('HB-X-12')]),
  ],
);

/// Quit Insights screen (T6.6.13).
const quitLayout = StatsLayout(
  MetricScope.quit,
  kpis: ['QT-02', 'QT-07', 'QT-06', 'QT-10'],
  sections: [
    StatsLayoutSection('milestones', [StatsLayoutItem('QT-11')]),
    StatsLayoutSection('money', [
      StatsLayoutItem('QT-07'),
      StatsLayoutItem('QT-06'),
      StatsLayoutItem('QT-08', span: _half),
      StatsLayoutItem('QT-10', span: _half),
      StatsLayoutItem('QT-09'),
    ]),
    StatsLayoutSection('abstinence', [
      StatsLayoutItem('QT-01', span: _half),
      StatsLayoutItem('QT-03', span: _half),
      StatsLayoutItem('QT-04', span: _half),
      StatsLayoutItem('QT-05', span: _half),
    ]),
    StatsLayoutSection('reduction', [StatsLayoutItem('QT-12')]),
    StatsLayoutSection('cravings', [StatsLayoutItem('QT-13'), StatsLayoutItem('QT-14')]),
  ],
);

/// Overview segment (T6.7.01).
const overviewLayout = StatsLayout(
  MetricScope.global,
  sections: [
    StatsLayoutSection('today', [StatsLayoutItem('GL-01')]),
    StatsLayoutSection('week', [StatsLayoutItem('GL-02')]),
    StatsLayoutSection('dataQuality', [StatsLayoutItem('GL-10')]),
  ],
);

/// Weekly review (T6.7.02).
const reviewLayout = StatsLayout(MetricScope.global, sections: [StatsLayoutSection('review', [StatsLayoutItem('GL-03')])]);

/// Default layout of a metric scope.
StatsLayout defaultLayoutOf(MetricScope scope) => switch (scope) {
  MetricScope.task => taskLayout,
  MetricScope.series => seriesLayout,
  MetricScope.planner => plannerLayout,
  MetricScope.checklistItem => itemLayout,
  MetricScope.checklist => checklistLayout,
  MetricScope.checklists => checklistsLayout,
  MetricScope.habit => habitLayout,
  MetricScope.habits => habitsLayout,
  MetricScope.quit => quitLayout,
  MetricScope.global => overviewLayout,
};
