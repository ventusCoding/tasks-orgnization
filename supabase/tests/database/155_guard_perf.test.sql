-- T7.4.05 — batch guard evaluation stays fast: 500 jobs mixing every guard kind < 50 ms.
begin;
select plan(2);

select tests.create_user('guardperf@test.local', '97000000-0000-4000-8000-000000000097');

create temp table perf_jobs as
select jsonb_agg(jsonb_build_object(
         'id', gen_random_uuid(),
         'user_id', '97000000-0000-4000-8000-000000000097',
         'target_key', 'task:' || gen_random_uuid(),
         'payload', jsonb_build_object('section', 'planner'),
         'guard', case i % 7
           when 0 then jsonb_build_object('kind', 'task_occurrence_open', 'taskId', gen_random_uuid(), 'occurrenceKey', '2026-09-22T09:00')
           when 1 then jsonb_build_object('kind', 'habit_period_open', 'habitId', gen_random_uuid(), 'occurrenceKey', '2026-09-22',
                                          'goalType', 'count', 'target', 3, 'op', 'gte')
           when 2 then jsonb_build_object('kind', 'checklist_item_status_in', 'itemId', gen_random_uuid(),
                                          'statuses', jsonb_build_array('waiting', 'blocked'))
           when 3 then jsonb_build_object('kind', 'item_not_completed', 'itemId', gen_random_uuid())
           when 4 then jsonb_build_object('kind', 'quit_no_relapse_since', 'habitId', gen_random_uuid(), 'since', '2026-09-01T00:00:00Z')
           when 5 then jsonb_build_object('kind', 'inbox_not_acted', 'dedupeKey', md5(i::text))
           else jsonb_build_object('kind', 'always')
         end)) as jobs
from generate_series(1, 500) i;

create temp table perf_result as
with t as (select clock_timestamp() as started),
     r as (select count(*) as n from private.notification_guards_ok((select jobs from perf_jobs)))
select r.n, extract(epoch from clock_timestamp() - t.started) * 1000 as ms from r, t;

select is((select n from perf_result)::int, 500, 'every job gets a verdict');
select ok((select ms from perf_result) < 50, 'batch of 500 guards evaluated in < 50 ms (took '
          || round((select ms from perf_result)::numeric, 1) || ' ms)');

select * from finish();
rollback;
