-- T1.2.05 / T1.5.04 — sync trigger semantics: revisions, forced/immutable owner, immutable id/created_at,
-- no-op updates, server writers, Broadcast once per statement, profile auto-creation.
begin;
select plan(20);

select tests.create_user('trg@test.local', 'c1000000-0000-4000-8000-00000000000c',
                         '{"time_zone": "America/New_York", "display_name": "Trig"}');
select tests.create_user('trg2@test.local', 'c2000000-0000-4000-8000-00000000000c');

-- Profile + sync head created by the auth trigger.
select is((select count(*)::int from app.profiles where id = 'c1000000-0000-4000-8000-00000000000c'), 1,
          'a new auth user gets exactly one profile');
select is((select home_time_zone from app.profiles where id = 'c1000000-0000-4000-8000-00000000000c'),
          'America/New_York', 'home_time_zone comes from signup metadata');
select ok((select user_id = id from app.profiles where id = 'c1000000-0000-4000-8000-00000000000c'),
          'profiles.id = profiles.user_id');
select is((select head_rev from app.sync_heads where user_id = 'c1000000-0000-4000-8000-00000000000c'),
          (select rev from app.profiles where id = 'c1000000-0000-4000-8000-00000000000c'),
          'the profile insert went through the sync trigger');

-- Client inserts: owner forced, revisions strictly increasing.
select tests.authenticate_as('c1000000-0000-4000-8000-00000000000c');
insert into app.tags (id, user_id, name, sort_key, rev, server_updated_at)
values ('c1000000-0000-4000-8000-0000000000a1', 'c2000000-0000-4000-8000-00000000000c', 't1', 'a0', 999999, '2000-01-01');
insert into app.tags (id, name, sort_key) values ('c1000000-0000-4000-8000-0000000000a2', 't2', 'a1');

select is((select user_id from app.tags where id = 'c1000000-0000-4000-8000-0000000000a1'),
          'c1000000-0000-4000-8000-00000000000c'::uuid, 'insert: user_id forced to auth.uid()');
select ok((select rev < 999999 from app.tags where id = 'c1000000-0000-4000-8000-0000000000a1'),
          'insert: client-supplied rev is ignored');
select ok((select server_updated_at > '2000-01-02' from app.tags where id = 'c1000000-0000-4000-8000-0000000000a1'),
          'insert: server_updated_at is set by the server');
select ok((select b.rev = a.rev + 1 from app.tags a, app.tags b
            where a.id = 'c1000000-0000-4000-8000-0000000000a1' and b.id = 'c1000000-0000-4000-8000-0000000000a2'),
          'revisions are strictly increasing per user');
select is((select head_rev from app.sync_heads), (select max(rev) from app.tags), 'sync head = highest revision');
select is((select field_clock from app.tags where id = 'c1000000-0000-4000-8000-0000000000a2'), '{}'::jsonb,
          'field_clock defaults to {}');

-- Updates: immutable columns silently kept.
update app.tags
   set user_id = 'c2000000-0000-4000-8000-00000000000c', created_at = '2000-01-01', rev = 1, name = 't1b'
 where id = 'c1000000-0000-4000-8000-0000000000a1';
select is((select user_id from app.tags where id = 'c1000000-0000-4000-8000-0000000000a1'),
          'c1000000-0000-4000-8000-00000000000c'::uuid, 'update: user_id is immutable');
select ok((select created_at > '2000-01-02' from app.tags where id = 'c1000000-0000-4000-8000-0000000000a1'),
          'update: created_at is immutable');
select is((select rev from app.tags where id = 'c1000000-0000-4000-8000-0000000000a1'),
          (select head_rev from app.sync_heads), 'update: rev is the new head, not the client value');

-- No-op update keeps the revision.
create temporary table t_head on commit drop as select head_rev from app.sync_heads;
grant select on t_head to authenticated;
update app.tags set name = 't1b' where id = 'c1000000-0000-4000-8000-0000000000a1';
select is((select head_rev from app.sync_heads), (select head_rev from t_head), 'a no-op update does not bump the head');

-- Broadcast: exactly one message per statement (2-row insert → 1 message).
select set_config('realtime.topic', 'user:c1000000-0000-4000-8000-00000000000c', true);
create temporary table t_msgs on commit drop as select count(*) as n from realtime.messages;
grant select on t_msgs to authenticated;
insert into app.tags (id, name, sort_key) values
  ('c1000000-0000-4000-8000-0000000000a3', 't3', 'a2'),
  ('c1000000-0000-4000-8000-0000000000a4', 't4', 'a3');
select is((select count(*) from realtime.messages) - (select n from t_msgs), 1::bigint,
          'a multi-row statement sends one Broadcast');
select is((select (payload ->> 'rev')::bigint from realtime.messages order by inserted_at desc, (payload ->> 'rev')::bigint desc limit 1),
          (select head_rev from app.sync_heads), 'the Broadcast carries the new head revision');

-- Server writers.
select tests.authenticate_as_service_role();
insert into app.tags (id, user_id, name, sort_key)
values ('c2000000-0000-4000-8000-0000000000a1', 'c2000000-0000-4000-8000-00000000000c', 'server', 'a0');
select is((select user_id from app.tags where id = 'c2000000-0000-4000-8000-0000000000a1'),
          'c2000000-0000-4000-8000-00000000000c'::uuid, 'service_role keeps a supplied user_id');

select tests.clear_authentication();
select throws_ok($$insert into app.tags (id, name, sort_key) values (gen_random_uuid(), 'x', 'a0')$$,
                 '23502', null, 'a server insert without user_id is refused');
select lives_ok($$insert into app.tags (id, user_id, name, sort_key)
                  values (gen_random_uuid(), 'c2000000-0000-4000-8000-00000000000c', 'cron', 'a1')$$,
                'postgres (cron / migrations) can write for a user');
select is((select head_rev from app.sync_heads where user_id = 'c2000000-0000-4000-8000-00000000000c'),
          (select max(rev) from app.tags where user_id = 'c2000000-0000-4000-8000-00000000000c'),
          'server writes advance the owner''s head');

select * from finish();
rollback;
