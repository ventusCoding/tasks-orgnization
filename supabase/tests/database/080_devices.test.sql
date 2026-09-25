-- T1.4.05 / T7.4.02 — device registry RPCs: ownership, state reporting, token hygiene, revocation.
begin;
select plan(17);

select tests.create_user('dev-a@test.local', 'aa000000-0000-4000-8000-0000000000aa');
select tests.create_user('dev-b@test.local', 'bb000000-0000-4000-8000-0000000000bb');

select tests.authenticate_as('aa000000-0000-4000-8000-0000000000aa');
select is(app.register_device('aa000000-0000-4000-8000-0000000000d1', 'android', 'Pixel 9', '16', '1.0.0', 10, 'fr', 'Europe/Paris', 'Phone'),
          '{"revoked": false}'::jsonb, 'register_device → {"revoked": false}');
select ok((select user_id = 'aa000000-0000-4000-8000-0000000000aa' and app_build = 10 and last_seen_at is not null
             from app.devices where id = 'aa000000-0000-4000-8000-0000000000d1'), 'device row owned by the caller');
select throws_ok($$select app.register_device('aa000000-0000-4000-8000-0000000000d2', 'symbian', null, null, null, null, null, null)$$,
                 'PGRST', null, 'unknown platforms are refused');

select is(app.report_device_state('aa000000-0000-4000-8000-0000000000d1', jsonb_build_object(
            'push_token', 'tok-1', 'capabilities', '{"exactAlarm": true, "notifications": true}'::jsonb,
            'local_coverage_until', '2026-10-01T00:00:00Z', 'schedule_rev', 42, 'time_zone', 'Europe/Berlin',
            'local_repeating_rules', '["aa000000-0000-4000-8000-0000000000e1"]'::jsonb, 'push_enabled', true,
            'last_seen_at', now() + interval '1 day')),
          '{"revoked": false}'::jsonb, 'report_device_state → {"revoked": false}');
select ok((select push_token = 'tok-1' and push_token_updated_at is not null and schedule_rev = 42
                  and local_coverage_until = '2026-10-01T00:00:00Z' and time_zone = 'Europe/Berlin'
                  and capabilities ->> 'exactAlarm' = 'true'
                  and local_repeating_rules = array['aa000000-0000-4000-8000-0000000000e1']::uuid[]
             from app.devices where id = 'aa000000-0000-4000-8000-0000000000d1'), 'reported keys are stored');
select ok((select last_seen_at <= now() from app.devices where id = 'aa000000-0000-4000-8000-0000000000d1'),
          'last_seen_at cannot be in the future');
select app.report_device_state('aa000000-0000-4000-8000-0000000000d1', '{"schedule_rev": 43}');
select is((select push_token from app.devices where id = 'aa000000-0000-4000-8000-0000000000d1'), 'tok-1',
          'absent keys are left untouched');
select is(app.report_device_state('aa000000-0000-4000-8000-0000000000ff', '{}'),
          '{"revoked": false, "registered": false}'::jsonb, 'unknown device → registered: false');

-- B cannot touch A's device.
select tests.authenticate_as('bb000000-0000-4000-8000-0000000000bb');
select is(app.report_device_state('aa000000-0000-4000-8000-0000000000d1', '{"push_token": "evil"}'),
          '{"revoked": false, "registered": false}'::jsonb, 'another user cannot report state for A''s device');
select throws_ok($$select app.revoke_device('aa000000-0000-4000-8000-0000000000d1')$$, 'PGRST', null,
                 'another user cannot revoke A''s device');

-- Token hygiene: the same FCM token registered on another device row moves there.
select app.register_device('bb000000-0000-4000-8000-0000000000d1', 'android', 'Pixel 9', '16', '1.0.0', 10, 'en', 'UTC');
select app.report_device_state('bb000000-0000-4000-8000-0000000000d1', '{"push_token": "tok-1"}');
select tests.authenticate_as('aa000000-0000-4000-8000-0000000000aa');
select is((select push_token from app.devices where id = 'aa000000-0000-4000-8000-0000000000d1'), null,
          'a token reported by another device row is removed from the old row');

-- Revocation.
select is(app.revoke_device('aa000000-0000-4000-8000-0000000000d1'), '{"revoked": true}'::jsonb, 'revoke_device');
select is(app.register_device('aa000000-0000-4000-8000-0000000000d1', 'android', 'Pixel 9', '16', '1.0.1', 11, 'fr', 'Europe/Paris'),
          '{"revoked": true}'::jsonb, 'a revoked device learns it on register');
select is(app.report_device_state('aa000000-0000-4000-8000-0000000000d1', '{"push_token": "tok-2"}'),
          '{"revoked": true}'::jsonb, '… and on report_device_state (state not stored)');
select is((select push_token from app.devices where id = 'aa000000-0000-4000-8000-0000000000d1'), null,
          'revoked devices keep no push token');

-- Account switch on the same install: the device id is handed over without the previous state.
select tests.authenticate_as('bb000000-0000-4000-8000-0000000000bb');
select app.report_device_state('bb000000-0000-4000-8000-0000000000d1', '{"schedule_rev": 7, "local_coverage_until": "2026-10-01T00:00:00Z"}');
select tests.authenticate_as('aa000000-0000-4000-8000-0000000000aa');
select is(app.register_device('bb000000-0000-4000-8000-0000000000d1', 'android', 'Pixel 9', '16', '1.0.0', 10, 'en', 'UTC'),
          '{"revoked": false}'::jsonb, 'a device id used by another account is transferred on register');
select ok((select user_id = 'aa000000-0000-4000-8000-0000000000aa' and push_token is null and schedule_rev is null
             from app.devices where id = 'bb000000-0000-4000-8000-0000000000d1'), '… without the previous account''s state');

select * from finish();
rollback;
