-- T7.4.03 — concurrent plan uploads of one user are serialized: a newer plan holding the lock makes an
-- older concurrent upload wait, then answer `stale` (it never overwrites the newer plan). Two dblink
-- sessions act as two devices of the seeded user 1 (committed rows, cleaned up at the end).
begin;
create extension if not exists dblink with schema extensions;
select plan(5);

create temporary table dsn on commit drop as
  select format('host=%s port=%s dbname=%s user=postgres password=postgres',
                host(inet_server_addr()), inet_server_port(), current_database()) as conn;

create function pg_temp.as_user1() returns text language sql as $$
  select $q$select set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated","aud":"authenticated"}', false),
                  set_config('role', 'authenticated', false)$q$
$$;

create function pg_temp.upload(p_device text, p_rev int, p_key text) returns text language sql as $$
  select format($q$select app.replace_notification_jobs(%L, %s, array['task:race'],
      jsonb_build_array(jsonb_build_object('dedupe_key', %L, 'target_key', 'task:race',
                                           'fire_at', now() + interval '1 hour', 'payload', '{}'::jsonb)))::text$q$,
                p_device, p_rev, p_key)
$$;

select extensions.dblink_connect('b', (select conn from dsn));
select extensions.dblink_connect('c', (select conn from dsn));
select count(*) from extensions.dblink('b', pg_temp.as_user1()) as t(a text, b text);
select count(*) from extensions.dblink('c', pg_temp.as_user1()) as t(a text, b text);
select count(*) from extensions.dblink('b', $$select app.register_device('11111111-0000-4000-8000-0000000000e1', 'android', 'Phone', '15', '1.0', 1, 'en', 'UTC')::text$$) as t(r text);
select count(*) from extensions.dblink('c', $$select app.register_device('11111111-0000-4000-8000-0000000000e2', 'android', 'Tablet', '15', '1.0', 1, 'en', 'UTC')::text$$) as t(r text);

-- B uploads the newer plan (rev 200) and keeps its transaction open (lock held).
select extensions.dblink_exec('b', 'begin');
select is((select r from extensions.dblink('b', pg_temp.upload('11111111-0000-4000-8000-0000000000e1', 200, 'race-new')) as t(r text))::jsonb ->> 'status',
          'ok', 'the newer plan is accepted');

-- C uploads an older plan (rev 100) concurrently: it must wait for B.
select extensions.dblink_exec('c', 'begin');
select extensions.dblink_send_query('c', pg_temp.upload('11111111-0000-4000-8000-0000000000e2', 100, 'race-old'));
select pg_sleep(0.5);
select is(extensions.dblink_is_busy('c'), 1, 'the older concurrent upload waits for the first one');

select extensions.dblink_exec('b', 'commit');
select is((select r from extensions.dblink_get_result('c') as t(r text))::jsonb ->> 'status', 'stale',
          'after the newer plan commits, the older upload is rejected as stale');
select count(*) from extensions.dblink_get_result('c') as t(r text);
select extensions.dblink_exec('c', 'commit');

select is((select count(*)::int from private.notification_jobs
            where user_id = '11111111-1111-4111-8111-111111111111' and target_key = 'task:race' and status = 'pending'),
          1, 'exactly one plan is visible');
select is((select dedupe_key from private.notification_jobs
            where user_id = '11111111-1111-4111-8111-111111111111' and target_key = 'task:race'),
          'race-new', 'the newer plan survived');

-- Cleanup (the dblink sessions committed).
select extensions.dblink_exec('b', 'reset role');
select extensions.dblink_exec('b', $$delete from private.notification_jobs where target_key = 'task:race'$$);
select extensions.dblink_exec('b', $$delete from app.devices where id in ('11111111-0000-4000-8000-0000000000e1', '11111111-0000-4000-8000-0000000000e2')$$);
select extensions.dblink_disconnect('b');
select extensions.dblink_disconnect('c');

select * from finish();
rollback;
