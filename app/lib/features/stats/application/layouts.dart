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
      StatsLayoutItem('PL-T-17', span: _half),
      StatsLayoutItem('PL-T-18', span: _half),
    ]),
    StatsLayoutSection('planning', [
      StatsLayoutItem('PL-T-11'),
      StatsLayoutItem('PL-T-08'),
      StatsLayoutItem('PL-T-09', span: _half),
      StatsLayoutItem('PL-T-10', span: _half),
      StatsLayoutItem('PL-T-12', span: _half),
      StatsLayoutItem('PL-T-13', span: _half),
      StatsLayoutItem('PL-T-14', span: _half),
    ]),
    StatsLayoutSection('focus', [StatsLayoutItem('PL-T-15'), StatsLayoutItem('PL-T-16')]),
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
    StatsLayoutSection('quality', [
      StatsLayoutItem('PL-S-14'),
      StatsLayoutItem('PL-S-12', span: _half),
      StatsLayoutItem('PL-S-10', span: _half),
      StatsLayoutItem('PL-S-11'),
      StatsLayoutItem('PL-S-15'),
      StatsLayoutItem('PL-S-18'),
      StatsLayoutItem('PL-S-13'),
      StatsLayoutItem('PL-S-19'),
    ]),
    StatsLayoutSection('patterns', [
      StatsLayoutItem('PL-S-16'),
      StatsLayoutItem('PL-S-17'),
      StatsLayoutItem('PL-S-20'),
      StatsLayoutItem('PL-S-21', span: _half),
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
      StatsLayoutItem('PL-X-19'),
      StatsLayoutItem('PL-X-16'),
      StatsLayoutItem('PL-X-17'),
      StatsLayoutItem('PL-X-18'),
      StatsLayoutItem('PL-X-20'),
    ]),
    StatsLayoutSection('planningQuality', [
      StatsLayoutItem('PL-X-21', span: _half),
      StatsLayoutItem('PL-X-22', span: _half),
      StatsLayoutItem('PL-X-23', span: _half),
      StatsLayoutItem('PL-X-25', span: _half),
      StatsLayoutItem('PL-X-24'),
      StatsLayoutItem('PL-X-26'),
    ]),
    StatsLayoutSection('timing', [
      StatsLayoutItem('PL-X-27', span: _half),
      StatsLayoutItem('PL-X-29', span: _half),
      StatsLayoutItem('PL-X-31', span: _half),
      StatsLayoutItem('PL-X-30', span: _half),
      StatsLayoutItem('PL-X-28'),
      StatsLayoutItem('PL-X-32'),
    ]),
    StatsLayoutSection('patterns', [
      StatsLayoutItem('PL-X-33'),
      StatsLayoutItem('PL-X-34'),
      StatsLayoutItem('PL-X-37'),
      StatsLayoutItem('PL-X-35'),
      StatsLayoutItem('PL-X-36'),
    ]),
    StatsLayoutSection('focus', [
      StatsLayoutItem('PL-X-42'),
      StatsLayoutItem('PL-X-38'),
      StatsLayoutItem('PL-X-39'),
      StatsLayoutItem('PL-X-40'),
      StatsLayoutItem('PL-X-41', span: _half),
    ]),
    StatsLayoutSection('advanced', [
      StatsLayoutItem('PL-X-43'),
      StatsLayoutItem('PL-X-44'),
      StatsLayoutItem('PL-X-45'),
      StatsLayoutItem('PL-X-46'),
    ]),
  ],
);

/// Item insights panel (T6.4.15).
const itemLayout = StatsLayout(
  MetricScope.checklistItem,
  kpis: ['CL-I-02', 'CL-I-03', 'CL-I-04', 'CL-I-05'],
  sections: [
    StatsLayoutSection('item', [StatsLayoutItem('CL-I-07'), StatsLayoutItem('CL-I-01'), StatsLayoutItem('CL-I-06')]),
    StatsLayoutSection('blockers', [
      StatsLayoutItem('CL-I-08'),
      StatsLayoutItem('CL-I-09'),
      StatsLayoutItem('CL-I-10', span: _half),
      StatsLayoutItem('CL-I-12', span: _half),
      StatsLayoutItem('CL-I-11'),
    ]),
    StatsLayoutSection('attachments', [StatsLayoutItem('CL-I-13'), StatsLayoutItem('CL-I-14', span: _half)]),
  ],
);

/// Checklist Insights screen (T6.4.16).
const checklistLayout = StatsLayout(
  MetricScope.checklist,
  kpis: ['CL-L-01', 'CL-L-03', 'CL-L-04', 'CL-L-06'],
  sections: [
    StatsLayoutSection('status', [StatsLayoutItem('CL-L-01')]),
    StatsLayoutSection('flow', [
      StatsLayoutItem('CL-L-07'),
      StatsLayoutItem('CL-L-02'),
      StatsLayoutItem('CL-L-03'),
      StatsLayoutItem('CL-L-04'),
      StatsLayoutItem('CL-L-05'),
      StatsLayoutItem('CL-L-25'),
    ]),
    StatsLayoutSection('cycleTime', [
      StatsLayoutItem('CL-L-09', span: _half),
      StatsLayoutItem('CL-L-13', span: _half),
      StatsLayoutItem('CL-L-08'),
      StatsLayoutItem('CL-L-10'),
    ]),
    StatsLayoutSection('burn', [StatsLayoutItem('CL-L-11'), StatsLayoutItem('CL-L-12'), StatsLayoutItem('CL-L-28')]),
    StatsLayoutSection('blockers', [
      StatsLayoutItem('CL-L-14'),
      StatsLayoutItem('CL-L-15'),
      StatsLayoutItem('CL-L-26'),
    ]),
    StatsLayoutSection('stale', [StatsLayoutItem('CL-L-06'), StatsLayoutItem('CL-L-19')]),
    StatsLayoutSection('tree', [
      StatsLayoutItem('CL-L-16'),
      StatsLayoutItem('CL-L-17'),
      StatsLayoutItem('CL-L-18'),
      StatsLayoutItem('CL-L-29'),
    ]),
    StatsLayoutSection('runs', [
      StatsLayoutItem('CL-L-20'),
      StatsLayoutItem('CL-L-21'),
      StatsLayoutItem('CL-L-22'),
      StatsLayoutItem('CL-L-23'),
      StatsLayoutItem('CL-L-24'),
    ]),
    StatsLayoutSection('advanced', [StatsLayoutItem('CL-L-27'), StatsLayoutItem('CL-L-30')]),
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
    StatsLayoutSection('flow', [StatsLayoutItem('CL-X-09'), StatsLayoutItem('CL-X-10')]),
    StatsLayoutSection('blockers', [
      StatsLayoutItem('CL-X-06'),
      StatsLayoutItem('CL-X-07'),
      StatsLayoutItem('CL-X-08'),
    ]),
    StatsLayoutSection('advanced', [StatsLayoutItem('CL-X-11'), StatsLayoutItem('CL-X-12')]),
  ],
);

/// Habit Insights screen (T6.5.16).
const habitLayout = StatsLayout(
  MetricScope.habit,
  kpis: ['HB-H-01', 'HB-H-02', 'HB-H-03', 'HB-H-05', 'HB-H-09'],
  sections: [
    StatsLayoutSection('strength', [StatsLayoutItem('HB-H-01'), StatsLayoutItem('HB-H-24', span: _half)]),
    StatsLayoutSection('calendar', [StatsLayoutItem('HB-H-08')]),
    StatsLayoutSection('history', [StatsLayoutItem('HB-H-07')]),
    StatsLayoutSection('targetVolume', [
      StatsLayoutItem('HB-H-26'),
      StatsLayoutItem('HB-H-10'),
      StatsLayoutItem('HB-H-11'),
      StatsLayoutItem('HB-H-12'),
      StatsLayoutItem('HB-H-13'),
      StatsLayoutItem('HB-H-14'),
      StatsLayoutItem('HB-H-15'),
      StatsLayoutItem('HB-H-16'),
    ]),
    StatsLayoutSection('streaks', [StatsLayoutItem('HB-H-04'), StatsLayoutItem('HB-H-22'), StatsLayoutItem('HB-H-23')]),
    StatsLayoutSection('outcomes', [
      StatsLayoutItem('HB-H-06'),
      StatsLayoutItem('HB-H-05'),
      StatsLayoutItem('HB-H-17'),
    ]),
    StatsLayoutSection('timing', [
      StatsLayoutItem('HB-H-18'),
      StatsLayoutItem('HB-H-19'),
      StatsLayoutItem('HB-H-20', span: _half),
      StatsLayoutItem('HB-H-21'),
    ]),
    StatsLayoutSection('advanced', [
      StatsLayoutItem('HB-H-27'),
      StatsLayoutItem('HB-H-28', span: _half),
      StatsLayoutItem('HB-H-29'),
      StatsLayoutItem('HB-H-30'),
    ]),
    StatsLayoutSection('dataQuality', [StatsLayoutItem('HB-H-25')]),
  ],
);

/// Habits section Insights screen (T6.5.17).
const habitsLayout = StatsLayout(
  MetricScope.habits,
  kpis: ['HB-X-01', 'HB-X-02', 'HB-X-04'],
  sections: [
    StatsLayoutSection('habitTable', [StatsLayoutItem('HB-X-01', variant: 'habitTable'), StatsLayoutItem('HB-X-07')]),
    StatsLayoutSection('trend', [StatsLayoutItem('HB-X-04'), StatsLayoutItem('HB-X-03'), StatsLayoutItem('HB-X-02')]),
    StatsLayoutSection('strength', [StatsLayoutItem('HB-X-06'), StatsLayoutItem('HB-X-09')]),
    StatsLayoutSection('patterns', [
      StatsLayoutItem('HB-X-08'),
      StatsLayoutItem('HB-X-11'),
      StatsLayoutItem('HB-X-10'),
    ]),
    StatsLayoutSection('quitTrackers', [StatsLayoutItem('HB-X-05')]),
    StatsLayoutSection('advanced', [StatsLayoutItem('HB-X-13'), StatsLayoutItem('HB-X-14')]),
    StatsLayoutSection('dataQuality', [StatsLayoutItem('HB-X-12')]),
  ],
);

/// Quit Insights screen (T6.6.13).
const quitLayout = StatsLayout(
  MetricScope.quit,
  kpis: ['QT-02', 'QT-07', 'QT-06', 'QT-10'],
  sections: [
    StatsLayoutSection('milestones', [StatsLayoutItem('QT-25'), StatsLayoutItem('QT-11')]),
    StatsLayoutSection('money', [
      StatsLayoutItem('QT-07'),
      StatsLayoutItem('QT-06'),
      StatsLayoutItem('QT-08', span: _half),
      StatsLayoutItem('QT-10', span: _half),
      StatsLayoutItem('QT-21'),
      StatsLayoutItem('QT-23'),
      StatsLayoutItem('QT-22', span: _half),
      StatsLayoutItem('QT-09'),
    ]),
    StatsLayoutSection('abstinence', [
      StatsLayoutItem('QT-01', span: _half),
      StatsLayoutItem('QT-03', span: _half),
      StatsLayoutItem('QT-04', span: _half),
      StatsLayoutItem('QT-05', span: _half),
      StatsLayoutItem('QT-24', span: _half),
      StatsLayoutItem('QT-18'),
      StatsLayoutItem('QT-20'),
      StatsLayoutItem('QT-26'),
    ]),
    StatsLayoutSection('reduction', [StatsLayoutItem('QT-12'), StatsLayoutItem('QT-19')]),
    StatsLayoutSection('cravings', [
      StatsLayoutItem('QT-15', span: _half),
      StatsLayoutItem('QT-28'),
      StatsLayoutItem('QT-13'),
      StatsLayoutItem('QT-14'),
      StatsLayoutItem('QT-16'),
      StatsLayoutItem('QT-17'),
      StatsLayoutItem('QT-27'),
    ]),
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
const reviewLayout = StatsLayout(
  MetricScope.global,
  sections: [
    StatsLayoutSection('review', [StatsLayoutItem('GL-03')]),
  ],
);

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
