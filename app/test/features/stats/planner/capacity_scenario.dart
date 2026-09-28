/// Capacity scenario (UTC), week Mon 14 – Sun 20 September 2026, work hours 09–17 Mon–Fri:
/// - Wed 16: `w1` 08:00–12:00 and `w2` 12:00–18:00 (10 h planned, both cross the work-hour
///   boundaries: 3 h + 5 h inside);
/// - Thu 17: `off` 16:00–17:00, an event in the unavailable category "Doctor";
/// - Sat 19: `sat` 10:00–11:00 (a weekend day without capacity);
/// - Mon 14: `mon` 10:00–11:00, done with a tracked 50-minute session.
library;

Map<String, Object?> capacitySettings() => {
  'planner': {
    'workHours': {'start': '09:00', 'end': '17:00'},
    'workDays': [1, 2, 3, 4, 5],
  },
};

Map<String, Object?> capacityScenario() {
  Map<String, Object?> task(String id, String start, int minutes, {String mode = 'check', String? category}) => {
    'id': id,
    'series_id': id,
    'title': id,
    'start_local': start,
    'duration_minutes': minutes,
    'time_zone': 'UTC',
    'tracking_mode': mode,
    'category_id': ?category,
    'created_at': '2026-09-10T08:00:00.000Z',
  };
  return {
    'categories': [
      {'id': 'work', 'name': 'Work', 'color': 0xFF3366CC, 'sort_key': 'a'},
      {'id': 'doctor', 'name': 'Doctor', 'color': 0xFF999999, 'sort_key': 'b', 'counts_as_unavailable': true},
    ],
    'tasks': [
      task('w1', '2026-09-16T08:00', 240, category: 'work'),
      task('w2', '2026-09-16T12:00', 360, category: 'work'),
      task('off', '2026-09-17T16:00', 60, mode: 'event', category: 'doctor'),
      task('sat', '2026-09-19T10:00', 60),
      task('mon', '2026-09-14T10:00', 60, mode: 'timer', category: 'work'),
    ],
    'task_occurrences': [
      {'id': 'o-mon', 'task_id': 'mon', 'occurrence_key': '2026-09-14T10:00', 'status': 'done', 'completed_at': '2026-09-14T10:55:00.000Z'},
    ],
    'time_entries': [
      {'id': 'te-mon', 'task_id': 'mon', 'occurrence_key': '2026-09-14T10:00', 'started_at': '2026-09-14T10:05:00.000Z', 'ended_at': '2026-09-14T10:55:00.000Z'},
    ],
  };
}
