-- T7.4.03 / T7.4.05 / T7.4.07 / T7.4.08 — job upload (atomic replace + monotonic source_rev guard),
-- claiming + lease reaper, guard catalog + mutes, inbox convergence, dispatcher completion.
begin;
select plan(41);

select tests.create_user('notif@test.local', '99000000-0000-4000-8000-000000000099');
select tests.create_user('notif2@test.local', '98000000-0000-4000-8000-000000000098');

create function pg_temp.job(p_key text, p_target text, p_fire timestamptz, p_extra jsonb default '{}')
returns jsonb language sql as $$
  select jsonb_build_object('dedupe_key', p_key, 'target_key', p_target, 'fire_at', p_fire,
                            'payload', jsonb_build_object('title', 'Reminder ' || p_key, 'body', 'Body', 'section', 'planner'),
                            'guard', jsonb_build_object('kind', 'always'), 'importance', 'default') || p_extra
$$;

-- Evaluates one guard for the user: 'ok' or the failure reason.
create function pg_temp.guard(p_user uuid, p_guard jsonb, p_target text default 'task:none', p_payload jsonb default '{}')
returns text language sql as $$
  select case when g.ok then 'ok' else g.reason end
  from private.notification_guards_ok(jsonb_build_array(jsonb_build_object(
         'id', gen_random_uuid(), 'user_id', p_user, 'target_key', p_target, 'guard', p_guard, 'payload', p_payload))) g
$$;
grant execute on function pg_temp.job(text, text, timestamptz, jsonb) to authenticated;

-- ---------------------------------------------------------------------------------------------------
-- replace_notification_jobs
-- ---------------------------------------------------------------------------------------------------
select tests.authenticate_as('99000000-0000-4000-8000-000000000099');
select throws_ok($$select app.replace_notification_jobs('99000000-0000-4000-8000-0000000000d1', 1, array['task:1'], '[]')$$,
                 'PGRST', null, 'jobs can only be uploaded from a registered device');
select app.register_device('99000000-0000-4000-8000-0000000000d1', 'ios', 'iPhone', '26', '1.0', 1, 'en', 'UTC');

select is(app.replace_notification_jobs('99000000-0000-4000-8000-0000000000d1', 10, array['task:1'],
            jsonb_build_array(pg_temp.job('k-due', 'task:1', now() - interval '1 minute'),
                              pg_temp.job('k-later', 'task:1', now() + interval '1 hour'))),
          '{"status": "ok", "replaced": 0, "upserted": 2}'::jsonb, 'first upload inserts the jobs');

select tests.clear_authentication();
select is((select count(*)::int from private.notification_jobs
            where user_id = '99000000-0000-4000-8000-000000000099' and status = 'pending' and source_rev = 10
              and planned_by_device = '99000000-0000-4000-8000-0000000000d1'), 2, 'jobs are pending with source_rev and planner');

select tests.authenticate_as('99000000-0000-4000-8000-000000000099');
select is(app.replace_notification_jobs('99000000-0000-4000-8000-0000000000d1', 11, array['task:1'],
            jsonb_build_array(pg_temp.job('k-new', 'task:1', now() + interval '2 hours'))),
          '{"status": "ok", "replaced": 1, "upserted": 1}'::jsonb, 'a newer plan replaces the target''s pending future jobs');
select is(app.replace_notification_jobs('99000000-0000-4000-8000-0000000000d1', 5, array['task:1'],
            jsonb_build_array(pg_temp.job('k-stale', 'task:1', now() + interval '3 hours'))),
          '{"status": "stale", "stale_targets": ["task:1"]}'::jsonb, 'an older source_rev is rejected as stale');
select throws_ok(format('select app.replace_notification_jobs(%L, 12, array[''task:1''], %L)', '99000000-0000-4000-8000-0000000000d1',
                        jsonb_build_array(pg_temp.job('k-far', 'task:1', now() + interval '30 days'))),
                 'PGRST', null, 'jobs beyond the 14-day horizon are refused');
select throws_ok(format('select app.replace_notification_jobs(%L, 12, array[''task:1''], %L)', '99000000-0000-4000-8000-0000000000d1',
                        jsonb_build_array(pg_temp.job('k-x', 'task:2', now() + interval '1 hour'))),
                 'PGRST', null, 'a job outside p_target_keys is refused');

select tests.clear_authentication();
select is((select array_agg(dedupe_key order by dedupe_key) from private.notification_jobs
            where user_id = '99000000-0000-4000-8000-000000000099'),
          array['k-due', 'k-new'], 'the due job is kept, the stale upload changed nothing');

-- ---------------------------------------------------------------------------------------------------
-- Claiming, reaper
-- ---------------------------------------------------------------------------------------------------
create temporary table claimed on commit drop as select * from private.claim_notification_jobs(50, 60);
select is((select array_agg(dedupe_key) from claimed where user_id = '99000000-0000-4000-8000-000000000099'), array['k-due'],
          'only due pending jobs are claimed');
select ok((select status = 'claimed' and lease_until > now() from private.notification_jobs where dedupe_key = 'k-due'),
          'claimed jobs carry a lease');
select is((select count(*)::int from private.claim_notification_jobs(50, 60) where user_id = '99000000-0000-4000-8000-000000000099'), 0,
          'a claimed job is not claimed twice');
update private.notification_jobs set lease_until = now() - interval '1 second' where dedupe_key = 'k-due';
select ok(private.release_expired_leases() >= 1, 'the reaper releases expired leases');
select ok((select status = 'pending' and attempts = 1 and lease_until is null from private.notification_jobs where dedupe_key = 'k-due'),
          'released jobs are pending again with attempts + 1');

-- ---------------------------------------------------------------------------------------------------
-- Dispatcher wrappers (service role)
-- ---------------------------------------------------------------------------------------------------
select tests.authenticate_as('99000000-0000-4000-8000-000000000099');
select throws_ok($$select app.dispatch_claim(10, 60)$$, '42501', null, 'clients cannot call dispatcher RPCs');

select tests.authenticate_as_service_role();
create temporary table dj on commit drop as select app.dispatch_claim(10, 60) as v;
select is((select jsonb_array_length(v) from dj), 1, 'dispatch_claim returns the due job');
select is((select v -> 0 -> 'sent_device_ids' from dj), '[]'::jsonb, '… with the devices already pushed to');
select is(app.dispatch_guards((select v from dj)) -> 0 ->> 'ok', 'true', 'dispatch_guards evaluates the batch');

select is((app.dispatch_upsert_inbox(jsonb_build_array(jsonb_build_object('job', (select v -> 0 from dj), 'late', false))) -> 0 ->> 'notification_id')::uuid,
          app.uuid_v5('k-due'), 'inbox row id = uuid_v5(dedupe_key)');
select ok((select title = 'Reminder k-due' and delivered_via = array['inbox'] and not late and category = 'reminder' and section = 'planner'
                  and field_clock ->> 'delivered_at' = app.hlc_at(fire_at)
             from app.notifications where id = app.uuid_v5('k-due')), 'inbox row content + clocks at the fire instant');

-- The user reads it on a device (per-field LWW), then the dispatcher writes delivery info again.
select tests.authenticate_as('99000000-0000-4000-8000-000000000099');
select tests.push(jsonb_build_array(tests.chg('r1', 'gr', 'notifications', 'patch', app.uuid_v5('k-due'),
                                              jsonb_build_object('read_at', now(), 'delivered_via', array['inbox', 'local']), now())));
select tests.authenticate_as_service_role();
select app.dispatch_upsert_inbox(jsonb_build_array(jsonb_build_object('job', (select v -> 0 from dj), 'late', true)));
select ok((select read_at is not null and late and delivered_via = array['inbox', 'local'] from app.notifications where id = app.uuid_v5('k-due')),
          'a second server write keeps the user''s read state and merges delivery fields');
select is((select count(*)::int from app.notifications where dedupe_key = 'k-due'), 1, 'still exactly one inbox row');

select is(app.dispatch_devices(array['99000000-0000-4000-8000-000000000099'::uuid]) -> '99000000-0000-4000-8000-000000000099' -> 'devices' -> 0 ->> 'id',
          '99000000-0000-4000-8000-0000000000d1', 'dispatch_devices lists the user''s devices');

select app.dispatch_complete(jsonb_build_array(jsonb_build_object(
  'job_id', (select v -> 0 ->> 'id' from dj), 'status', 'retry', 'reason', 'unavailable', 'retry_after_seconds', 120,
  'deliveries', jsonb_build_array(jsonb_build_object('device_id', '99000000-0000-4000-8000-0000000000d1', 'outcome', 'failed', 'error_code', 'unavailable')),
  'invalid_device_ids', '[]'::jsonb)));
select tests.clear_authentication();
select ok((select status = 'pending' and attempts = 2 and next_retry_at > now() + interval '100 seconds'
             from private.notification_jobs where dedupe_key = 'k-due'), 'retry → pending with backoff');
select is((select count(*)::int from private.claim_notification_jobs(50, 60) where dedupe_key = 'k-due'), 0,
          'a job waiting for its retry is not claimed');

update private.notification_jobs set next_retry_at = null where dedupe_key = 'k-due';
select tests.authenticate_as_service_role();
select app.dispatch_claim(10, 60);
select app.dispatch_complete(jsonb_build_array(jsonb_build_object(
  'job_id', (select v -> 0 ->> 'id' from dj), 'status', 'sent', 'pushed', true,
  'deliveries', jsonb_build_array(jsonb_build_object('device_id', '99000000-0000-4000-8000-0000000000d1', 'outcome', 'sent', 'fcm_message_id', 'm-1')),
  'invalid_device_ids', '[]'::jsonb)));
select tests.clear_authentication();
select ok((select status = 'sent' and sent_at is not null from private.notification_jobs where dedupe_key = 'k-due'), 'sent → job sent');
select is((select outcome || ':' || fcm_message_id from private.push_deliveries where job_id = (select (v -> 0 ->> 'id')::uuid from dj)),
          'sent:m-1', 'one delivery row per job and device (upserted)');
select ok((select delivered_via @> array['push'] from app.notifications where id = app.uuid_v5('k-due')), 'inbox records the push channel');

-- ---------------------------------------------------------------------------------------------------
-- Guards
-- ---------------------------------------------------------------------------------------------------
select tests.authenticate_as('99000000-0000-4000-8000-000000000099');
insert into app.tasks (id, title, start_local, recurrence) values ('99000000-0000-4000-8000-0000000000f1', 'T', '2026-09-22 08:00', '{"v": 1}');
insert into app.habits (id, kind, name, goal_type, target_value, start_date, sort_key)
values ('99000000-0000-4000-8000-0000000000a1', 'build', 'Water', 'count', 8, '2026-09-01', 'a0');
insert into app.habits (id, kind, name, start_date, sort_key, quit_mode, quit_started_at)
values ('99000000-0000-4000-8000-0000000000a2', 'quit', 'Smoke', '2026-09-01', 'a1', 'abstain', '2026-09-01');
insert into app.checklists (id, title, sort_key) values ('99000000-0000-4000-8000-0000000000c1', 'L', 'a0');
insert into app.checklist_items (id, checklist_id, sort_key, text, status) values
  ('99000000-0000-4000-8000-0000000000b1', '99000000-0000-4000-8000-0000000000c1', 'a0', 'wait for it', 'waiting'),
  ('99000000-0000-4000-8000-0000000000b2', '99000000-0000-4000-8000-0000000000c1', 'a1', 'do it', 'todo');
select tests.clear_authentication();

create temporary table g (k text primary key, guard jsonb) on commit drop;
insert into g values
  ('occ', '{"kind": "task_occurrence_open", "taskId": "99000000-0000-4000-8000-0000000000f1", "occurrenceKey": "2026-09-22T08:00"}'),
  ('habit', '{"kind": "habit_period_open", "habitId": "99000000-0000-4000-8000-0000000000a1", "occurrenceKey": "2026-09-22", "target": 8, "op": "gte"}'),
  ('status', '{"kind": "checklist_item_status_in", "itemId": "99000000-0000-4000-8000-0000000000b1", "statuses": ["waiting", "blocked"]}'),
  ('notdone', '{"kind": "item_not_completed", "itemId": "99000000-0000-4000-8000-0000000000b2"}'),
  ('quit', '{"kind": "quit_no_relapse_since", "habitId": "99000000-0000-4000-8000-0000000000a2", "since": "2026-09-20T00:00:00Z"}'),
  ('acted', '{"kind": "inbox_not_acted", "dedupeKey": "k-due"}');

select is(pg_temp.guard('99000000-0000-4000-8000-000000000099', '{"kind": "always"}'), 'ok', 'guard always');
select is((select array_agg(pg_temp.guard('99000000-0000-4000-8000-000000000099', guard) order by k) from g),
          array['ok', 'ok', 'ok', 'ok', 'ok', 'ok'], 'all guards pass while targets are open');
select is(pg_temp.guard('98000000-0000-4000-8000-000000000098', (select guard from g where k = 'occ')), 'task_inactive',
          'guards only see the job owner''s rows');

-- Close every target.
insert into app.task_occurrences (id, user_id, task_id, occurrence_key, status)
values (app.uuid_v5('99000000-0000-4000-8000-0000000000f1|2026-09-22T08:00'), '99000000-0000-4000-8000-000000000099',
        '99000000-0000-4000-8000-0000000000f1', '2026-09-22T08:00', 'done');
insert into app.habit_logs (id, user_id, habit_id, occurrence_key, kind, value, logged_at, local_date)
select gen_random_uuid(), '99000000-0000-4000-8000-000000000099', '99000000-0000-4000-8000-0000000000a1', '2026-09-22', 'progress', 4, now(), '2026-09-22'
from generate_series(1, 2);
insert into app.habit_logs (id, user_id, habit_id, kind, logged_at, local_date)
values (gen_random_uuid(), '99000000-0000-4000-8000-000000000099', '99000000-0000-4000-8000-0000000000a2', 'relapse', '2026-09-21T10:00:00Z', '2026-09-21');
update app.checklist_items set status = 'ongoing' where id = '99000000-0000-4000-8000-0000000000b1';
update app.checklist_items set status = 'completed', completed_at = now() where id = '99000000-0000-4000-8000-0000000000b2';
update app.notifications set acted_at = now(), action = 'done' where dedupe_key = 'k-due';

select is((select array_agg(pg_temp.guard('99000000-0000-4000-8000-000000000099', guard) order by k) from g),
          array['acted', 'target_reached', 'item_completed', 'occurrence_closed', 'relapsed', 'item_status_changed'],
          'each guard fails once its target is done (acted, habit, notdone, occ, quit, status)');

update app.habit_logs set deleted_at = now() where habit_id = '99000000-0000-4000-8000-0000000000a1';
insert into app.habit_pauses (id, user_id, habit_id, start_date, end_date)
values (gen_random_uuid(), '99000000-0000-4000-8000-000000000099', null, '2026-09-20', '2026-09-25');
select is(pg_temp.guard('99000000-0000-4000-8000-000000000099', (select guard from g where k = 'habit')), 'habit_paused',
          'habit_period_open is false during a pause (vacation mode)');
update app.tasks set status = 'paused' where id = '99000000-0000-4000-8000-0000000000f1';
select is(pg_temp.guard('99000000-0000-4000-8000-000000000099',
            '{"kind": "task_occurrence_open", "taskId": "99000000-0000-4000-8000-0000000000f1", "occurrenceKey": "2026-09-23T08:00"}'),
          'task_inactive', 'task_occurrence_open is false for paused tasks');
select is(pg_temp.guard('99000000-0000-4000-8000-000000000099', '{"kind": "from_the_future"}'), 'ok',
          'unknown guard kinds fail open (logged as unknown_guard_kind)');
select is(pg_temp.guard('99000000-0000-4000-8000-000000000099', '[{"kind": "always"}, {"kind": "item_not_completed", "itemId": "99000000-0000-4000-8000-0000000000b2"}]'),
          'item_completed', 'a guard array passes only when every guard passes');

-- Mutes.
insert into app.notification_mutes (id, user_id, target_type, section, until)
values ('99000000-0000-4000-8000-0000000000e1', '99000000-0000-4000-8000-000000000099', 'section', 'planner', now() + interval '1 day');
select is(pg_temp.guard('99000000-0000-4000-8000-000000000099', '{"kind": "always"}', 'task:x', '{"section": "planner"}'), 'muted',
          'a section mute silences the section');
select is(pg_temp.guard('99000000-0000-4000-8000-000000000099', '{"kind": "always"}', 'task:x', '{"section": "habits"}'), 'ok',
          '… and nothing else');
update app.notification_mutes set until = now() - interval '1 minute' where id = '99000000-0000-4000-8000-0000000000e1';
select is(pg_temp.guard('99000000-0000-4000-8000-000000000099', '{"kind": "always"}', 'task:x', '{"section": "planner"}'), 'ok',
          'expired mutes no longer apply');
insert into app.notification_mutes (id, user_id, target_type, target_id)
values (gen_random_uuid(), '99000000-0000-4000-8000-000000000099', 'checklist', '99000000-0000-4000-8000-0000000000c1');
select is(pg_temp.guard('99000000-0000-4000-8000-000000000099', '{"kind": "always"}', 'checklist_item:99000000-0000-4000-8000-0000000000b1'),
          'muted', 'muting a checklist silences its items');

-- ---------------------------------------------------------------------------------------------------
-- '*' replacement and account-level cancellation
-- ---------------------------------------------------------------------------------------------------
select tests.authenticate_as('99000000-0000-4000-8000-000000000099');
select app.replace_notification_jobs('99000000-0000-4000-8000-0000000000d1', 20, array['habit:1', 'task:9'],
  jsonb_build_array(pg_temp.job('k-h', 'habit:1', now() + interval '1 hour'), pg_temp.job('k-t', 'task:9', now() + interval '1 hour')));
select is(app.replace_notification_jobs('99000000-0000-4000-8000-0000000000d1', 21, array['*'], '[]') ->> 'replaced', '3',
          '''*'' replaces every pending future job of the user');
select tests.clear_authentication();
select is((select count(*)::int from private.notification_jobs where user_id = '99000000-0000-4000-8000-000000000099' and status = 'pending'), 0,
          'no pending jobs left');

select * from finish();
rollback;
