-- T7.4.17 — server planning fallback RPCs: candidates, inputs, replacement that never beats a device plan.
begin;
select plan(9);

select tests.create_user('fallback@test.local', '96000000-0000-4000-8000-000000000096');

select ok(not has_function_privilege('authenticated', 'app.fallback_candidates(interval, integer)', 'execute')
            and not has_function_privilege('authenticated', 'app.fallback_load(uuid)', 'execute')
            and not has_function_privilege('authenticated', 'app.fallback_replace_jobs(uuid, bigint, jsonb)', 'execute'),
          'fallback RPCs are service-role only');

-- A push-capable device and an enabled rule, never uploaded a plan.
select tests.authenticate_as('96000000-0000-4000-8000-000000000096');
select app.register_device('96000000-0000-4000-8000-0000000000d1', 'android', 'Phone', '15', '1.0', 1, 'en', 'UTC');
select tests.clear_authentication();
update app.devices set push_token = 'tok', push_enabled = true where id = '96000000-0000-4000-8000-0000000000d1';
insert into app.notification_rules (id, user_id, target_type, section, is_default, enabled, spec, sort_key, created_at, updated_at)
values ('96000000-0000-4000-8000-0000000000a1', '96000000-0000-4000-8000-000000000096', 'section', 'planner', true, true,
        '{"v": 1, "trigger": {"type": "relative", "anchor": "start", "offsetMinutes": -10}}', 'a', now(), now());
insert into app.tasks (id, user_id, series_id, title, start_local, duration_minutes, time_zone, recurrence, created_at, updated_at)
values ('96000000-0000-4000-8000-0000000000b1', '96000000-0000-4000-8000-000000000096', '96000000-0000-4000-8000-0000000000b1',
        'Gym', '2026-09-01T08:00', 60, 'UTC', '{"v": 1, "type": "fixed", "freq": "daily", "interval": 1}', now(), now());

set local role service_role;

select ok('96000000-0000-4000-8000-000000000096'::uuid in (select user_id from app.fallback_candidates()),
          'an inactive user with rules and a push device is a candidate');

select is((select jsonb_array_length(app.fallback_load('96000000-0000-4000-8000-000000000096') -> 'tasks')), 1,
          'the active task is loaded');
select is((select jsonb_array_length(app.fallback_load('96000000-0000-4000-8000-000000000096') -> 'rules')), 1,
          'the enabled rule is loaded');

select is(app.fallback_replace_jobs('96000000-0000-4000-8000-000000000096', 5, jsonb_build_array(
            jsonb_build_object('dedupe_key', 's1', 'target_key', 'task:x', 'fire_at', now() + interval '1 hour',
                               'payload', '{"title": "Gym"}'::jsonb, 'guard', '{"kind": "always"}'::jsonb),
            jsonb_build_object('dedupe_key', 's2', 'target_key', 'task:y', 'fire_at', now() + interval '2 hours',
                               'payload', '{"title": "Read"}'::jsonb))) ->> 'inserted', '2', 'server jobs are inserted');
select is((select payload ->> 'plannedBy' from private.notification_jobs where dedupe_key = 's1'), 'server',
          'server jobs are marked');

-- A device plan for task:y from a newer revision: the next server run leaves task:y to the device.
insert into private.notification_jobs (user_id, dedupe_key, target_key, fire_at, payload, source_rev, planned_by_device)
values ('96000000-0000-4000-8000-000000000096', 'dev-y', 'task:y', now() + interval '3 hours', '{}', 9,
        '96000000-0000-4000-8000-0000000000d1');
select is(app.fallback_replace_jobs('96000000-0000-4000-8000-000000000096', 6, jsonb_build_array(
            jsonb_build_object('dedupe_key', 's1b', 'target_key', 'task:x', 'fire_at', now() + interval '1 hour', 'payload', '{}'::jsonb),
            jsonb_build_object('dedupe_key', 's2b', 'target_key', 'task:y', 'fire_at', now() + interval '2 hours', 'payload', '{}'::jsonb))),
          '{"replaced": 2, "inserted": 1}'::jsonb, 'previous server jobs are replaced; device-planned targets are skipped');

-- The device uploaded recently: no longer a candidate.
select ok('96000000-0000-4000-8000-000000000096'::uuid not in (select user_id from app.fallback_candidates()),
          'a user whose device uploaded recently is not a candidate');
select ok((select count(*) from private.notification_jobs where dedupe_key = 'dev-y') = 1, 'the device plan is untouched');

select * from finish();
rollback;
