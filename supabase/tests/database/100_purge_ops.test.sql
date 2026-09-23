-- T1.4.16 / T8.3.06 / T2.2.11 — purge_now, purge_tombstones + watermark, storage reference counting;
-- T1.5.12 account deletion (request + cascades); T1.5.16 stale anonymous users; T7.4.16 ops_health;
-- T1.2.12 invoke_edge no-op without Vault secrets.
begin;
select plan(26);

select tests.create_user('purge@test.local', '77000000-0000-4000-8000-000000000077');
select tests.create_user('purge2@test.local', '78000000-0000-4000-8000-000000000078');

-- ---------------------------------------------------------------------------------------------------
-- purge_now (Trash › Delete forever)
-- ---------------------------------------------------------------------------------------------------
select tests.authenticate_as('77000000-0000-4000-8000-000000000077');
insert into app.checklists (id, title, sort_key) values ('77000000-0000-4000-8000-0000000000c1', 'Old list', 'a0');
insert into app.checklist_items (id, checklist_id, parent_id, sort_key, text) values
  ('77000000-0000-4000-8000-0000000000b1', '77000000-0000-4000-8000-0000000000c1', null, 'a0', 'p'),
  ('77000000-0000-4000-8000-0000000000b2', '77000000-0000-4000-8000-0000000000c1', '77000000-0000-4000-8000-0000000000b1', 'a0', 'c'),
  ('77000000-0000-4000-8000-0000000000b3', '77000000-0000-4000-8000-0000000000c1', '77000000-0000-4000-8000-0000000000b2', 'a0', 'gc');
insert into app.attachments (id, owner_type, owner_id, storage_path, file_name, mime_type, byte_size, sort_key) values
  ('77000000-0000-4000-8000-0000000000a1', 'checklist_item', '77000000-0000-4000-8000-0000000000b3',
   '77000000-0000-4000-8000-000000000077/77000000-0000-4000-8000-0000000000a1/photo.jpg', 'photo.jpg', 'image/jpeg', 10, 'a0'),
  ('77000000-0000-4000-8000-0000000000a2', 'checklist_item', '77000000-0000-4000-8000-0000000000b3',
   '77000000-0000-4000-8000-000000000077/shared/doc.pdf', 'doc.pdf', 'application/pdf', 10, 'a1'),
  -- a duplicated item elsewhere still references the shared object
  ('77000000-0000-4000-8000-0000000000a3', 'task', gen_random_uuid(),
   '77000000-0000-4000-8000-000000000077/shared/doc.pdf', 'doc.pdf', 'application/pdf', 10, 'a0');

select is(app.purge_now('checklist', array['77000000-0000-4000-8000-0000000000c1']::uuid[]),
          '{"purged": 0, "skipped": 1}'::jsonb, 'live rows are never purged');

update app.checklists set deleted_at = now() where id = '77000000-0000-4000-8000-0000000000c1';
select is((select count(*)::int from app.attachments where owner_type = 'checklist_item' and deleted_at is not null), 2,
          'the cascade tombstoned the item attachments too');

create temporary table w (rev bigint) on commit drop;
grant all on w to authenticated;
insert into w select max(rev) from app.checklist_items where checklist_id = '77000000-0000-4000-8000-0000000000c1';

select tests.authenticate_as('78000000-0000-4000-8000-000000000078');
select is(app.purge_now('checklist', array['77000000-0000-4000-8000-0000000000c1']::uuid[]) ->> 'purged', '0',
          'another user cannot purge my tombstones');

select tests.authenticate_as('77000000-0000-4000-8000-000000000077');
select is(app.purge_now('checklist', array['77000000-0000-4000-8000-0000000000c1']::uuid[]),
          '{"purged": 6, "skipped": 0}'::jsonb, 'purge_now deletes the checklist, its 3 items and 2 attachments');
select is((select count(*)::int from app.checklist_items where checklist_id = '77000000-0000-4000-8000-0000000000c1'), 0,
          'descendants are gone');
select ok(app.purge_watermark() >= (select rev from w), 'the purge watermark covers the purged revisions');
select is((app.sync_pull(0, 1) ->> 'purge_watermark')::bigint, app.purge_watermark(), 'sync_pull reports the watermark');
select throws_ok($$select app.purge_now('secrets', array[gen_random_uuid()])$$, 'PGRST', null, 'unknown entity types are refused');

select tests.clear_authentication();
select is((select array_agg(path order by path) from private.storage_deletions where path like '77000000-0000-4000-8000-000000000077/%'),
          array['77000000-0000-4000-8000-000000000077/77000000-0000-4000-8000-0000000000a1/photo.jpg'],
          'only objects no remaining row references are queued for deletion');

-- Tasks with occurrences.
select tests.authenticate_as('77000000-0000-4000-8000-000000000077');
insert into app.tasks (id, title, start_local, recurrence) values ('77000000-0000-4000-8000-0000000000f1', 'Old task', '2026-09-01 08:00', '{"v": 1}');
insert into app.task_occurrences (id, task_id, occurrence_key, status)
values (app.uuid_v5('77000000-0000-4000-8000-0000000000f1|2026-09-01T08:00'), '77000000-0000-4000-8000-0000000000f1', '2026-09-01T08:00', 'done');
update app.tasks set deleted_at = now() where id = '77000000-0000-4000-8000-0000000000f1';
select is(app.purge_now('task', array['77000000-0000-4000-8000-0000000000f1']::uuid[]) ->> 'purged', '2',
          'purging a task removes its tombstoned occurrences');

-- ---------------------------------------------------------------------------------------------------
-- purge_tombstones (daily, 90 days)
-- ---------------------------------------------------------------------------------------------------
insert into app.categories (id, name, color, sort_key) values
  ('77000000-0000-4000-8000-0000000000e1', 'old', 1, 'a0'),
  ('77000000-0000-4000-8000-0000000000e2', 'recent', 1, 'a1'),
  ('77000000-0000-4000-8000-0000000000e3', 'referenced', 1, 'a2'),
  ('77000000-0000-4000-8000-0000000000e4', 'live', 1, 'a3');
insert into app.tasks (id, title, category_id) values ('77000000-0000-4000-8000-0000000000f2', 'uses e3', '77000000-0000-4000-8000-0000000000e3');
set constraints all immediate;
set constraints all deferred;
select tests.clear_authentication();
update app.categories set deleted_at = now() - interval '100 days'
 where id in ('77000000-0000-4000-8000-0000000000e1', '77000000-0000-4000-8000-0000000000e3');
update app.categories set deleted_at = now() - interval '10 days' where id = '77000000-0000-4000-8000-0000000000e2';

create temporary table w2 on commit drop as select rev from app.categories where id = '77000000-0000-4000-8000-0000000000e1';
create temporary table pt on commit drop as select private.purge_tombstones(90) as v;
select is((select array_agg(name order by name) from app.categories where user_id = '77000000-0000-4000-8000-000000000077'),
          array['live', 'recent', 'referenced'], 'tombstones older than 90 days are purged, recent ones and live rows kept');
select ok((select (v -> 'tables' -> 'categories' ->> 'skipped')::int >= 1 from pt),
          'a tombstone still referenced by a live row is skipped, not an error');
select ok((select (value #>> '{}')::bigint from private.sync_meta where key = 'purge_watermark:77000000-0000-4000-8000-000000000077')
            >= (select rev from w2),
          'purge_tombstones raises the per-user watermark to the purged revision');

-- ---------------------------------------------------------------------------------------------------
-- Account deletion
-- ---------------------------------------------------------------------------------------------------
select tests.authenticate_as('77000000-0000-4000-8000-000000000077');
select app.register_device('77000000-0000-4000-8000-0000000000d1', 'android', 'P', '16', '1', 1, 'en', 'UTC');
select app.report_device_state('77000000-0000-4000-8000-0000000000d1', '{"push_token": "tok-purge"}');
select app.replace_notification_jobs('77000000-0000-4000-8000-0000000000d1', 1, array['task:1'],
  jsonb_build_array(jsonb_build_object('dedupe_key', 'k1', 'target_key', 'task:1', 'fire_at', now() + interval '1 hour', 'payload', '{}'::jsonb)));
select is(app.request_account_deletion(), '{"status": "requested"}'::jsonb, 'request_account_deletion');

select tests.clear_authentication();
select ok(exists (select 1 from private.account_deletion_requests where user_id = '77000000-0000-4000-8000-000000000077'),
          'the request is recorded for retries');
select ok((select push_token is null from app.devices where id = '77000000-0000-4000-8000-0000000000d1')
            and (select status = 'cancelled' from private.notification_jobs where dedupe_key = 'k1'),
          'pushes stop immediately (token cleared, jobs cancelled)');

select tests.authenticate_as_service_role();
select is(app.account_delete_prepare('77000000-0000-4000-8000-000000000077'), '{"jobs": 1, "devices": 1}'::jsonb,
          'account_delete_prepare removes devices and jobs');
select tests.clear_authentication();
delete from auth.users where id = '77000000-0000-4000-8000-000000000077';
select is((select sum(n)::int from (
             select count(*) as n from app.profiles where user_id = '77000000-0000-4000-8000-000000000077'
             union all select count(*) from app.tasks where user_id = '77000000-0000-4000-8000-000000000077'
             union all select count(*) from app.categories where user_id = '77000000-0000-4000-8000-000000000077'
             union all select count(*) from app.attachments where user_id = '77000000-0000-4000-8000-000000000077'
             union all select count(*) from app.sync_heads where user_id = '77000000-0000-4000-8000-000000000077'
             union all select count(*) from private.account_deletion_requests where user_id = '77000000-0000-4000-8000-000000000077') s),
          0, 'deleting the auth user cascades every app row');
select lives_ok('set constraints all immediate', 'the cascade leaves no dangling references');

-- ---------------------------------------------------------------------------------------------------
-- Stale anonymous users, ops helpers
-- ---------------------------------------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, created_at, updated_at, last_sign_in_at, is_anonymous)
values ('00000000-0000-0000-0000-000000000000', '76000000-0000-4000-8000-000000000076', 'authenticated', 'authenticated',
        now() - interval '200 days', now() - interval '200 days', now() - interval '120 days', true);
select is(array(select private.stale_anonymous_users(90)), array['76000000-0000-4000-8000-000000000076'::uuid],
          'inactive anonymous users are selected (and only them)');
select is(private.delete_stale_anonymous_users(90), 1, '… and deleted');

select is(private.invoke_edge('push-dispatch'), null, 'invoke_edge is a no-op without Vault secrets');
select ok((private.run_minutely() ? 'released') and exists (select 1 from private.ops_heartbeats where name = 'lease_reaper'),
          'minutely job runs the reaper and writes a heartbeat');
select lives_ok('select private.daily_maintenance()', 'daily maintenance runs');
select ok(exists (select 1 from private.ops_heartbeats where name = 'daily_maintenance'), 'daily maintenance heartbeat');

select tests.authenticate_as_service_role();
select ok(app.ops_health() ?& array['dispatcher_lag_seconds', 'jobs', 'heartbeats', 'invalid_token_rate_last_hour'],
          'ops_health reports lag, jobs, heartbeats, token health');

select * from finish();
rollback;
