-- T1.2.05 — per-user write serialization (the pull cursor is gap-free because a user's writers are
-- serialized by the row lock on app.sync_heads) while different users never block each other.
-- Uses dblink to open two extra sessions (local stack credentials) and the two seeded users
-- (supabase/seed.sql), which are committed and therefore visible to those sessions.
begin;
create extension if not exists dblink with schema extensions;
select plan(5);

-- Connect through the server's own network address: loopback is `trust` in the local stack, and dblink
-- refuses password-less connections for non-superusers.
create temporary table dsn on commit drop as
  select format('host=%s port=%s dbname=%s user=postgres password=postgres',
                host(inet_server_addr()), inet_server_port(), current_database()) as conn;

-- Session A (this transaction) writes for user 1 and keeps its sync_heads row locked.
insert into app.tags (id, user_id, name, sort_key)
values ('c1000000-0000-4000-8000-0000000000f1', '11111111-1111-4111-8111-111111111111', 'first', 'zz0');

select extensions.dblink_connect('b', (select conn from dsn));
select extensions.dblink_connect('c', (select conn from dsn));
select extensions.dblink_exec('b', 'begin');
select extensions.dblink_exec('c', 'begin');
select extensions.dblink_send_query('b', $$insert into app.tags (id, user_id, name, sort_key)
  values ('c1000000-0000-4000-8000-0000000000f2', '11111111-1111-4111-8111-111111111111', 'second', 'zz1')$$);
select extensions.dblink_send_query('c', $$insert into app.tags (id, user_id, name, sort_key)
  values ('c1000000-0000-4000-8000-0000000000f3', '22222222-2222-4222-8222-222222222222', 'other user', 'zz0')$$);
select pg_sleep(0.5);

select is(extensions.dblink_is_busy('b'), 1, 'a concurrent writer of the same user waits for the first transaction');
select is(extensions.dblink_is_busy('c'), 0, 'a writer of another user is not blocked');
select is((select res from extensions.dblink_get_result('c') as t(res text)), 'INSERT 0 1', 'the other user''s write completed');
-- libpq needs one more (empty) result before the connection accepts a new command.
select count(*) from extensions.dblink_get_result('c') as t(res text);
select extensions.dblink_exec('c', 'rollback');

select is(extensions.dblink_cancel_query('b'), 'OK', 'the blocked writer is cancelled (test cleanup)');
select count(*) from extensions.dblink_get_result('b', false) as t(res text);
select count(*) from extensions.dblink_get_result('b', false) as t(res text);
select extensions.dblink_exec('b', 'rollback');

select ok((select rev from app.tags where id = 'c1000000-0000-4000-8000-0000000000f1') > 0, 'session A''s write got its revision');

select extensions.dblink_disconnect('b');
select extensions.dblink_disconnect('c');

select * from finish();
rollback;
