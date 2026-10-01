/// A compact planner scenario (UTC, now = Wed 2026-09-23 12:00, grace 5 min) covering every outcome
/// class and all three tracking modes:
/// - `a` timer 09:00–10:00 on Mon 21 with sessions 09:07–09:40 and 09:45–10:12, done 10:12 (T6.3.02
///   acceptance: Da 60, Δs +7 late, Δe +12);
/// - `b` check 14:00–14:30, done 14:35 (exactly g → on time); `c` check 16:00–16:30, done 16:36 (g + 1);
/// - `d` check Tue 22 10:00, still open (overdue); `h` check Thu 24 (future);
/// - `e` daily event 08:00 (15 min) from Mon 21; `f` skipped with a reason;
/// - `g` daily check 07:00 from Mon 21: 21 done early, 22 cancelled, 23 in progress.
library;

const _daily = '{"v":1,"type":"fixed","freq":"daily","interval":1}';

Map<String, Object?> plannerScenario() => {
  'tasks': [
    _task('a', '2026-09-21T09:00', 60, mode: 'timer'),
    _task('b', '2026-09-21T14:00', 30),
    _task('c', '2026-09-21T16:00', 30),
    _task('d', '2026-09-22T10:00', 45),
    _task('e', '2026-09-21T08:00', 15, mode: 'event', recurrence: _daily),
    _task('f', '2026-09-22T18:00', 20),
    _task('g', '2026-09-21T07:00', 10, recurrence: _daily),
    _task('h', '2026-09-24T11:00', 30),
  ],
  'task_occurrences': [
    _occ('a', '2026-09-21T09:00', 'done', done: '2026-09-21T10:12:00.000Z'),
    _occ('b', '2026-09-21T14:00', 'done', done: '2026-09-21T14:35:00.000Z'),
    _occ('c', '2026-09-21T16:00', 'done', done: '2026-09-21T16:36:00.000Z'),
    {..._occ('f', '2026-09-22T18:00', 'skipped'), 'skip_reason': 'Too tired'},
    _occ('g', '2026-09-21T07:00', 'done', done: '2026-09-21T06:58:00.000Z'),
    {..._occ('g', '2026-09-22T07:00', 'cancelled'), 'is_cancelled': true},
    _occ('g', '2026-09-23T07:00', 'in_progress'),
  ],
  'time_entries': [
    {
      'id': 'te1',
      'task_id': 'a',
      'occurrence_key': '2026-09-21T09:00',
      'started_at': '2026-09-21T09:07:00.000Z',
      'ended_at': '2026-09-21T09:40:00.000Z',
    },
    {
      'id': 'te2',
      'task_id': 'a',
      'occurrence_key': '2026-09-21T09:00',
      'started_at': '2026-09-21T09:45:00.000Z',
      'ended_at': '2026-09-21T10:12:00.000Z',
    },
  ],
};

Map<String, Object?> _task(String id, String start, int minutes, {String mode = 'check', String? recurrence}) => {
  'id': id,
  'series_id': id,
  'title': 'Task $id',
  'created_at': '2026-09-20T08:00:00.000Z',
  'start_local': start,
  'duration_minutes': minutes,
  'time_zone': 'UTC',
  'tracking_mode': mode,
  'recurrence': ?recurrence,
};

Map<String, Object?> _occ(String task, String key, String status, {String? done}) => {
  'id': 'occ-$task-$key',
  'task_id': task,
  'occurrence_key': key,
  'status': status,
  'completed_at': ?done,
  'status_changed_at': done ?? '2026-09-22T20:00:00.000Z',
};
