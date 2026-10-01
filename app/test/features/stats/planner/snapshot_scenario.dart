/// Plan-snapshot scenario (UTC) for the week Mon 14 – Sun 20 September 2026:
/// - `m1` planned Mon 14 10:00, moved on Tue 15 to Mon 21 10:00 (moved out during the period);
/// - `d1` planned Tue 15 09:00, done;
/// - `p1` planned Sun 13 11:00, moved on Sat 12 to Wed 16 11:00 (move before the period), done;
/// - `u1` created Wed 16 for Thu 17 14:00 (unplanned addition), done;
/// - `r` daily 07:00 Mon 14 – Sun 20, all done except Wed 16, cancelled on Sun 13.
library;

Map<String, Object?> snapshotScenario() {
  final occurrences = <Map<String, Object?>>[
    {
      'id': 'o-d1',
      'task_id': 'd1',
      'occurrence_key': '2026-09-15T09:00',
      'status': 'done',
      'completed_at': '2026-09-15T09:30:00.000Z',
    },
    {
      'id': 'o-p1',
      'task_id': 'p1',
      'occurrence_key': '2026-09-16T11:00',
      'status': 'done',
      'completed_at': '2026-09-16T11:30:00.000Z',
    },
    {
      'id': 'o-u1',
      'task_id': 'u1',
      'occurrence_key': '2026-09-17T14:00',
      'status': 'done',
      'completed_at': '2026-09-17T14:20:00.000Z',
    },
  ];
  for (var day = 14; day <= 20; day++) {
    final key = '2026-09-${day}T07:00';
    occurrences.add(
      day == 16
          ? {
              'id': 'o-r$day',
              'task_id': 'r',
              'occurrence_key': key,
              'status': 'cancelled',
              'is_cancelled': true,
              'status_changed_at': '2026-09-13T12:00:00.000Z',
            }
          : {
              'id': 'o-r$day',
              'task_id': 'r',
              'occurrence_key': key,
              'status': 'done',
              'completed_at': '2026-09-${day}T07:10:00.000Z',
            },
    );
  }
  Map<String, Object?> task(
    String id,
    String start, {
    String created = '2026-09-10T08:00:00.000Z',
    String? recurrence,
  }) => {
    'id': id,
    'series_id': id,
    'title': id,
    'start_local': start,
    'duration_minutes': 30,
    'time_zone': 'UTC',
    'created_at': created,
    'recurrence': ?recurrence,
  };
  return {
    'tasks': [
      task('m1', '2026-09-21T10:00'),
      task('d1', '2026-09-15T09:00'),
      task('p1', '2026-09-16T11:00'),
      task('u1', '2026-09-17T14:00', created: '2026-09-16T08:00:00.000Z'),
      task(
        'r',
        '2026-09-14T07:00',
        recurrence: '{"v":1,"type":"fixed","freq":"daily","interval":1,"until":"2026-09-20T23:59"}',
      ),
    ],
    'task_occurrences': occurrences,
    'activity_events': [
      {
        'id': 'ev-m1',
        'entity_type': 'task',
        'entity_id': 'm1',
        'event_type': 'rescheduled',
        'occurred_at': '2026-09-15T09:00:00.000Z',
        'payload': {
          'occurrenceKey': '2026-09-14T10:00',
          'fromStart': '2026-09-14T10:00',
          'toStart': '2026-09-21T10:00',
          'fromDuration': 30,
          'toDuration': 30,
        },
      },
      {
        'id': 'ev-p1',
        'entity_type': 'task',
        'entity_id': 'p1',
        'event_type': 'rescheduled',
        'occurred_at': '2026-09-12T09:00:00.000Z',
        'payload': {
          'occurrenceKey': '2026-09-13T11:00',
          'fromStart': '2026-09-13T11:00',
          'toStart': '2026-09-16T11:00',
          'fromDuration': 30,
          'toDuration': 30,
        },
      },
    ],
  };
}
