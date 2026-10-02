-- T7.4.18 — digest email recipients, one-click unsubscribe (synced settings write), bounce suppression.
begin;
select plan(7);

select tests.create_user('digest@test.local', '95000000-0000-4000-8000-000000000095');
update auth.users set email_confirmed_at = now() where id = '95000000-0000-4000-8000-000000000095';

select ok(not has_function_privilege('authenticated', 'app.dispatch_email_targets(uuid[])', 'execute')
            and not has_function_privilege('authenticated', 'app.email_unsubscribe(uuid)', 'execute')
            and not has_function_privilege('authenticated', 'app.email_suppress(text, text)', 'execute'),
          'email RPCs are service-role only');

set local role service_role;
select is(app.dispatch_email_targets(array['95000000-0000-4000-8000-000000000095'::uuid]), '{}'::jsonb,
          'not opted in: no recipient');
reset role;

insert into app.user_settings (id, user_id, namespace, value, created_at, updated_at)
values (gen_random_uuid(), '95000000-0000-4000-8000-000000000095', 'notifications',
        '{"emailDigests": {"enabled": true, "kinds": ["weekly_review"]}}', now(), now());

set local role service_role;
select is(app.dispatch_email_targets(array['95000000-0000-4000-8000-000000000095'::uuid])
            -> '95000000-0000-4000-8000-000000000095' ->> 'email', 'digest@test.local', 'opted-in user is a recipient');
select is(app.dispatch_email_targets(array['95000000-0000-4000-8000-000000000095'::uuid])
            -> '95000000-0000-4000-8000-000000000095' -> 'kinds', '["weekly_review"]'::jsonb, 'chosen kinds are returned');

select app.email_suppress('DIGEST@test.local', 'bounce');
select is(app.dispatch_email_targets(array['95000000-0000-4000-8000-000000000095'::uuid]), '{}'::jsonb,
          'a hard-bounced address is never emailed (case-insensitive)');

select ok(app.email_unsubscribe('95000000-0000-4000-8000-000000000095'), 'unsubscribe finds the settings row');
reset role;
select is((select value -> 'emailDigests' ->> 'enabled' from app.user_settings
            where user_id = '95000000-0000-4000-8000-000000000095' and namespace = 'notifications'), 'false',
          'unsubscribe turns digest emails off in the synced settings');

select * from finish();
rollback;
