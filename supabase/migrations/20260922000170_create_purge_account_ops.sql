-- =====================================================================================================
-- Retention, trash, account deletion and monitoring:
--   T1.4.16 private.purge_tombstones (+ per-user purge watermark), T8.3.06 app.purge_now,
--   T2.2.11 reference-counted storage purge queue, T1.5.12 app.request_account_deletion,
--   T1.5.16 stale anonymous users, T7.4.16 / T9.2.14 ops_health, arch §7.7 daily maintenance.
-- =====================================================================================================

-- Storage objects are deleted through the Storage API (direct deletes from storage.objects leave the
-- binary behind), so purges enqueue paths here; the `storage-purge` Edge Function drains the queue.
create table if not exists private.storage_deletions (
  id          bigint generated always as identity primary key,
  bucket      text not null,
  path        text not null,
  enqueued_at timestamptz not null default now(),
  attempts    int not null default 0,
  last_error  text,
  constraint storage_deletions_bucket_path_key unique (bucket, path)
);

comment on table private.storage_deletions is
  'Storage objects to delete (no attachment row references them any more). Drained by storage-purge.';

revoke all on private.storage_deletions from public, anon, authenticated;
grant select, insert, update, delete on private.storage_deletions to service_role;

-- Enqueue the objects of hard-deleted attachment rows that no remaining row references.
create or replace function private.enqueue_unreferenced_objects(p_objects jsonb)
returns int
language sql
set search_path = ''
as $$
  with candidates as (
    select distinct o ->> 'bucket' as bucket, p.path
    from jsonb_array_elements(coalesce(p_objects, '[]'::jsonb)) o
    cross join lateral (values (o ->> 'storage_path'), (o ->> 'thumb_path')) as p (path)
    where p.path is not null
  ), ins as (
    insert into private.storage_deletions (bucket, path)
    select c.bucket, c.path
    from candidates c
    where not exists (
      select 1 from app.attachments a
      where a.bucket = c.bucket and (a.storage_path = c.path or a.thumb_path = c.path))
    on conflict (bucket, path) do nothing
    returning 1)
  select count(*)::int from ins
$$;

-- Synced tables in purge order: children before the parents they reference (NO ACTION FKs).
create or replace function private.purge_order()
returns table (table_name text, ord int)
language sql
stable
set search_path = ''
as $$
  with known (table_name, ord) as (
    values ('activity_events', 10), ('attachments', 20), ('entity_tags', 30), ('time_entries', 40),
           ('task_occurrences', 50), ('checklist_runs', 60), ('checklist_items', 70), ('habit_logs', 80),
           ('habit_pauses', 90), ('habit_revisions', 100), ('notifications', 110), ('notification_mutes', 120),
           ('notification_rules', 130), ('tasks', 140), ('checklists', 150), ('habits', 160), ('goals', 170),
           ('achievements', 180), ('dashboards', 190), ('saved_views', 200), ('tags', 210), ('habit_vocab', 220),
           ('habit_sections', 230), ('notification_profiles', 240), ('categories', 250), ('user_settings', 260))
  select s, coalesce(k.ord, 500)
  from app.synced_tables() s
  left join known k on k.table_name = s
  where s <> 'profiles'                               -- profiles live as long as the account
  order by 2, 1
$$;

-- Hard-delete the given tombstoned rows of one table and raise the owners' purge watermarks.
-- Returns {deleted, skipped, objects}. Rows that are still referenced (FK) are skipped.
create or replace function private.hard_delete_tombstones(p_table text, p_ids uuid[])
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  v_deleted int := 0;
  v_skipped int := 0;
  v_objects jsonb := '[]'::jsonb;
  v_part    jsonb;
  v_id      uuid;
  v_sql     text;
begin
  if coalesce(cardinality(p_ids), 0) = 0 then
    return jsonb_build_object('deleted', 0, 'skipped', 0, 'objects', '[]'::jsonb);
  end if;

  -- Deferred FKs must fail here (and be caught), not at commit.
  set constraints all immediate;

  v_sql := format(
    'with d as (delete from app.%I t where t.id = any ($1) and t.deleted_at is not null returning t.*) '
    'select jsonb_build_object('
    '  ''deleted'', (select count(*) from d), '
    '  ''watermarks'', coalesce((select jsonb_object_agg(x.user_id, x.m) '
    '                            from (select d.user_id, max(d.rev) m from d group by d.user_id) x), ''{}''::jsonb), '
    '  ''objects'', %s)',
    p_table,
    case when p_table = 'attachments'
         then '(select coalesce(jsonb_agg(jsonb_build_object(''bucket'', d.bucket, ''storage_path'', d.storage_path, '
              '''thumb_path'', d.thumb_path)), ''[]''::jsonb) from d)'
         else '''[]''::jsonb' end);

  begin
    execute v_sql into v_part using p_ids;
    perform private.bump_purge_watermarks(v_part -> 'watermarks');
    v_deleted := (v_part ->> 'deleted')::int;
    v_objects := v_part -> 'objects';
  exception when foreign_key_violation then
    -- Some rows are still referenced: fall back to one row at a time.
    foreach v_id in array p_ids
    loop
      begin
        execute v_sql into v_part using array[v_id];
        perform private.bump_purge_watermarks(v_part -> 'watermarks');
        v_deleted := v_deleted + (v_part ->> 'deleted')::int;
        v_objects := v_objects || (v_part -> 'objects');
      exception when foreign_key_violation then
        v_skipped := v_skipped + 1;
      end;
    end loop;
  end;

  return jsonb_build_object('deleted', v_deleted, 'skipped', v_skipped, 'objects', v_objects);
end
$$;

-- ---------------------------------------------------------------------------------------------------
-- private.purge_tombstones — daily: hard-delete tombstones older than p_days, in batches.
-- ---------------------------------------------------------------------------------------------------
create or replace function private.purge_tombstones(p_days int default 90, p_batch int default 1000)
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  v_cutoff  timestamptz := now() - make_interval(days => greatest(coalesce(p_days, 90), 1));
  v_batch   int := least(greatest(coalesce(p_batch, 1000), 1), 10000);
  v_t       record;
  v_ids     uuid[];
  v_last    uuid;
  v_part    jsonb;
  v_summary jsonb := '{}'::jsonb;
  v_deleted int;
  v_skipped int;
  v_objects jsonb := '[]'::jsonb;
begin
  for v_t in select p.table_name from private.purge_order() p
  loop
    v_last := '00000000-0000-0000-0000-000000000000';
    v_deleted := 0;
    v_skipped := 0;
    loop
      execute format(
        'select coalesce(array_agg(id order by id), ''{}'') from ('
        '  select t.id from app.%I t where t.deleted_at < $1 and t.id > $2 order by t.id limit $3) s',
        v_t.table_name)
        into v_ids
        using v_cutoff, v_last, v_batch;
      exit when cardinality(v_ids) = 0;

      v_part := private.hard_delete_tombstones(v_t.table_name, v_ids);
      v_objects := v_objects || (v_part -> 'objects');
      v_deleted := v_deleted + (v_part ->> 'deleted')::int;
      v_skipped := v_skipped + (v_part ->> 'skipped')::int;
      v_last := v_ids[cardinality(v_ids)];
      exit when cardinality(v_ids) < v_batch;
    end loop;
    if v_deleted > 0 or v_skipped > 0 then
      v_summary := v_summary || jsonb_build_object(v_t.table_name, jsonb_build_object('deleted', v_deleted, 'skipped', v_skipped));
    end if;
  end loop;

  return jsonb_build_object('cutoff', v_cutoff, 'tables', v_summary,
                            'storage_enqueued', private.enqueue_unreferenced_objects(v_objects));
end
$$;

comment on function private.purge_tombstones(int, int) is
  'Hard-deletes tombstones older than p_days (children first), raises per-user purge watermarks and '
  'enqueues unreferenced storage objects. Referenced rows are skipped.';

-- ---------------------------------------------------------------------------------------------------
-- app.purge_now — Trash › Delete forever (own tombstoned rows only; descendants included).
-- ---------------------------------------------------------------------------------------------------
create or replace function app.purge_now(p_entity_type text, p_ids uuid[])
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid     uuid := app.current_user_id();
  v_table   text;
  v_ids     uuid[];
  v_plan    jsonb := '[]'::jsonb;         -- [{t, ids}] children first
  v_step    jsonb;
  v_part    jsonb;
  v_deleted int := 0;
  v_skipped int := 0;
  v_objects jsonb := '[]'::jsonb;
  v_desc    uuid[];
begin
  v_table := case p_entity_type
    when 'task' then 'tasks'
    when 'checklist' then 'checklists'
    when 'checklist_item' then 'checklist_items'
    when 'habit' then 'habits'
    when 'attachment' then 'attachments'
    else p_entity_type end;

  if v_table is null or v_table = 'profiles' or not exists (select 1 from app.synced_tables() s where s = v_table) then
    perform app.raise_api_error('unknown_entity_type', format('Cannot purge entity type "%s"', p_entity_type), 400);
  end if;
  if coalesce(cardinality(p_ids), 0) = 0 then
    return jsonb_build_object('purged', 0, 'skipped', 0);
  end if;
  if cardinality(p_ids) > 1000 then
    perform app.raise_api_error('too_many_ids', 'At most 1000 ids per call', 413);
  end if;

  -- Only the caller's own tombstones.
  execute format('select coalesce(array_agg(t.id), ''{}'') from app.%I t where t.id = any ($1) and t.user_id = $2 and t.deleted_at is not null', v_table)
    into v_ids using p_ids, v_uid;
  if cardinality(v_ids) = 0 then
    return jsonb_build_object('purged', 0, 'skipped', cardinality(p_ids));
  end if;

  -- Tombstoned descendants go first.
  if v_table = 'tasks' then
    v_plan := jsonb_build_array(
      jsonb_build_object('t', 'attachments', 'ids', (select coalesce(jsonb_agg(a.id), '[]') from app.attachments a
        where a.user_id = v_uid and a.deleted_at is not null and a.owner_type = 'task' and a.owner_id = any (v_ids))),
      jsonb_build_object('t', 'time_entries', 'ids', (select coalesce(jsonb_agg(x.id), '[]') from app.time_entries x
        where x.user_id = v_uid and x.deleted_at is not null and x.task_id = any (v_ids))),
      jsonb_build_object('t', 'task_occurrences', 'ids', (select coalesce(jsonb_agg(o.id), '[]') from app.task_occurrences o
        where o.user_id = v_uid and o.deleted_at is not null and o.task_id = any (v_ids))));
  elsif v_table in ('checklists', 'checklist_items') then
    if v_table = 'checklists' then
      select coalesce(array_agg(i.id), '{}') into v_desc
      from app.checklist_items i where i.user_id = v_uid and i.deleted_at is not null and i.checklist_id = any (v_ids);
    else
      with recursive d (id) as (
        select i.id from app.checklist_items i where i.parent_id = any (v_ids) and i.user_id = v_uid and i.deleted_at is not null
        union
        select i.id from app.checklist_items i join d on i.parent_id = d.id where i.user_id = v_uid and i.deleted_at is not null)
      select coalesce(array_agg(id), '{}') into v_desc from d;
    end if;
    v_plan := jsonb_build_array(
      jsonb_build_object('t', 'attachments', 'ids', (select coalesce(jsonb_agg(a.id), '[]') from app.attachments a
        where a.user_id = v_uid and a.deleted_at is not null
          and ((a.owner_type = 'checklist_item' and a.owner_id = any (v_desc || v_ids))
            or (a.owner_type = 'checklist' and a.owner_id = any (v_ids))))),
      jsonb_build_object('t', 'checklist_runs', 'ids', (select coalesce(jsonb_agg(r.id), '[]') from app.checklist_runs r
        where r.user_id = v_uid and r.deleted_at is not null and r.checklist_id = any (v_ids))),
      -- deepest items first so parents are no longer referenced when deleted
      jsonb_build_object('t', 'checklist_items', 'ids', to_jsonb(v_desc)));
  elsif v_table = 'habits' then
    v_plan := jsonb_build_array(
      jsonb_build_object('t', 'attachments', 'ids', (select coalesce(jsonb_agg(a.id), '[]') from app.attachments a
        where a.user_id = v_uid and a.deleted_at is not null and a.owner_type = 'habit' and a.owner_id = any (v_ids))),
      jsonb_build_object('t', 'habit_logs', 'ids', (select coalesce(jsonb_agg(l.id), '[]') from app.habit_logs l
        where l.user_id = v_uid and l.deleted_at is not null and l.habit_id = any (v_ids))),
      jsonb_build_object('t', 'habit_pauses', 'ids', (select coalesce(jsonb_agg(p.id), '[]') from app.habit_pauses p
        where p.user_id = v_uid and p.deleted_at is not null and p.habit_id = any (v_ids))),
      jsonb_build_object('t', 'habit_revisions', 'ids', (select coalesce(jsonb_agg(r.id), '[]') from app.habit_revisions r
        where r.user_id = v_uid and r.deleted_at is not null and r.habit_id = any (v_ids))));
  end if;
  v_plan := v_plan || jsonb_build_array(jsonb_build_object('t', v_table, 'ids', to_jsonb(v_ids)));

  set constraints all immediate;
  for v_step in select e from jsonb_array_elements(v_plan) e
  loop
    if v_step ->> 't' = 'checklist_items' and v_table in ('checklists', 'checklist_items') then
      -- A subtree: delete one row at a time, children first (a parent is referenced until then).
      declare
        v_pending uuid[] := array(select x::uuid from jsonb_array_elements_text(v_step -> 'ids') x);
        v_round   uuid[];
      begin
        loop
          exit when cardinality(v_pending) = 0;
          select coalesce(array_agg(p), '{}') into v_round
          from unnest(v_pending) p
          where not exists (select 1 from app.checklist_items c where c.parent_id = p);
          exit when cardinality(v_round) = 0;
          v_part := private.hard_delete_tombstones('checklist_items', v_round);
          v_deleted := v_deleted + (v_part ->> 'deleted')::int;
          v_pending := array(select p from unnest(v_pending) p where p <> all (v_round));
        end loop;
        v_skipped := v_skipped + cardinality(v_pending);
      end;
    else
      v_part := private.hard_delete_tombstones(v_step ->> 't',
                  array(select x::uuid from jsonb_array_elements_text(v_step -> 'ids') x));
      v_deleted := v_deleted + (v_part ->> 'deleted')::int;
      v_skipped := v_skipped + (v_part ->> 'skipped')::int;
      v_objects := v_objects || (v_part -> 'objects');
    end if;
  end loop;

  perform private.enqueue_unreferenced_objects(v_objects);

  return jsonb_build_object('purged', v_deleted, 'skipped', v_skipped + (cardinality(p_ids) - cardinality(v_ids)));
end
$$;

comment on function app.purge_now(text, uuid[]) is
  'Trash › Delete forever: hard-deletes the caller''s tombstoned rows (task | checklist | checklist_item | habit '
  '| attachment | <synced table>) and their tombstoned descendants; raises the purge watermark. {purged, skipped}.';

grant execute on function app.purge_now(text, uuid[]) to authenticated;

-- ---------------------------------------------------------------------------------------------------
-- Account deletion (T1.5.12): the client calls app.request_account_deletion(), then the
-- `account-delete` Edge Function (user JWT) — the request row lets cron retry if that call is lost.
-- ---------------------------------------------------------------------------------------------------
create or replace function app.request_account_deletion()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := app.current_user_id();
begin
  insert into private.account_deletion_requests (user_id) values (v_uid)
  on conflict (user_id) do update set requested_at = now();

  -- Stop every push immediately.
  update app.devices d set push_token = null, push_token_updated_at = null, updated_at = now()
   where d.user_id = v_uid and d.push_token is not null;
  update private.notification_jobs j set status = 'cancelled', lease_until = null, last_error = 'account_deletion'
   where j.user_id = v_uid and j.status in ('pending', 'claimed');

  perform private.invoke_edge('account-delete', jsonb_build_object('user_id', v_uid));
  return jsonb_build_object('status', 'requested');
end
$$;

comment on function app.request_account_deletion() is
  'Marks the caller''s account for deletion, stops pushes, and triggers the account-delete Edge Function.';

grant execute on function app.request_account_deletion() to authenticated;

-- Service role (account-delete Edge Function): remove devices and jobs before deleting the auth user.
create or replace function app.account_delete_prepare(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_devices int;
  v_jobs    int;
begin
  delete from app.devices d where d.user_id = p_user_id;
  get diagnostics v_devices = row_count;
  delete from private.notification_jobs j where j.user_id = p_user_id;
  get diagnostics v_jobs = row_count;
  update private.account_deletion_requests r set attempts = r.attempts + 1, last_attempt_at = now()
   where r.user_id = p_user_id;
  return jsonb_build_object('devices', v_devices, 'jobs', v_jobs);
end
$$;

comment on function app.account_delete_prepare(uuid) is 'Service role only (account-delete): delete devices + jobs.';

-- Service role (storage-purge Edge Function): claim / complete queued storage deletions.
create or replace function app.storage_purge_claim(p_limit int default 100)
returns jsonb
language sql
security definer
set search_path = ''
as $$
  with c as (
    update private.storage_deletions s
       set attempts = s.attempts + 1
     where s.id in (select q.id from private.storage_deletions q
                    where q.attempts < 10 order by q.id limit least(greatest(coalesce(p_limit, 100), 1), 1000)
                    for update skip locked)
    returning s.id, s.bucket, s.path)
  select coalesce(jsonb_agg(jsonb_build_object('id', c.id, 'bucket', c.bucket, 'path', c.path) order by c.id), '[]'::jsonb)
  from c
$$;

create or replace function app.storage_purge_done(p_ids bigint[], p_errors jsonb default '{}'::jsonb)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_n int;
begin
  -- A path that got referenced again meanwhile is simply dropped from the queue (object kept).
  delete from private.storage_deletions s
   where s.id = any (coalesce(p_ids, '{}')) and not (coalesce(p_errors, '{}'::jsonb) ? s.id::text);
  get diagnostics v_n = row_count;
  update private.storage_deletions s set last_error = p_errors ->> s.id::text
   where coalesce(p_errors, '{}'::jsonb) ? s.id::text;
  return v_n;
end
$$;

-- ---------------------------------------------------------------------------------------------------
-- T1.5.16 — anonymous users inactive for > p_days with no recent device and no stored files.
-- ---------------------------------------------------------------------------------------------------
create or replace function private.stale_anonymous_users(p_days int default 90, p_limit int default 500)
returns setof uuid
language sql
stable
set search_path = ''
as $$
  select u.id
  from auth.users u
  where u.is_anonymous
    and coalesce(u.last_sign_in_at, u.created_at) < now() - make_interval(days => p_days)
    and not exists (select 1 from app.devices d
                    where d.user_id = u.id and d.last_seen_at >= now() - make_interval(days => p_days))
    and not exists (select 1 from app.attachments a where a.user_id = u.id and a.uploaded_at is not null)
  order by u.created_at
  limit p_limit
$$;

create or replace function private.delete_stale_anonymous_users(p_days int default 90, p_limit int default 500)
returns int
language plpgsql
set search_path = ''
as $$
declare
  v_n int;
begin
  delete from auth.users u where u.id in (select s from private.stale_anonymous_users(p_days, p_limit) s);
  get diagnostics v_n = row_count;
  return v_n;
end
$$;

-- ---------------------------------------------------------------------------------------------------
-- T7.4.16 / T9.2.14 — health
-- ---------------------------------------------------------------------------------------------------
create or replace function private.ops_health()
returns jsonb
language sql
stable
set search_path = ''
as $$
  with jobs as (
    select
      extract(epoch from now() - min(j.fire_at) filter (where j.status = 'pending' and j.fire_at <= now())) as lag,
      count(*) filter (where j.status = 'pending') as pending,
      count(*) filter (where j.status = 'pending' and j.fire_at <= now()) as pending_due,
      count(*) filter (where j.status = 'claimed') as claimed,
      count(*) filter (where j.status = 'sent' and j.sent_at > now() - interval '1 hour') as sent_1h,
      count(*) filter (where j.status = 'failed' and j.created_at > now() - interval '1 hour') as failed_1h,
      count(*) filter (where j.status = 'expired' and j.fire_at > now() - interval '1 hour') as expired_1h,
      count(*) filter (where j.status = 'skipped' and j.fire_at > now() - interval '1 hour') as skipped_1h
    from private.notification_jobs j
  ), deliveries as (
    select
      count(*) filter (where d.outcome in ('sent', 'failed', 'token_invalid')) as attempts,
      count(*) filter (where d.outcome = 'token_invalid') as invalid
    from private.push_deliveries d
    where d.created_at > now() - interval '1 hour'
  )
  select jsonb_build_object(
    'now', now(),
    'dispatcher_lag_seconds', coalesce(round(jobs.lag::numeric, 1), 0),
    'jobs', jsonb_build_object('pending', jobs.pending, 'pending_due', jobs.pending_due, 'claimed', jobs.claimed,
                               'sent_last_hour', jobs.sent_1h, 'failed_last_hour', jobs.failed_1h,
                               'expired_last_hour', jobs.expired_1h, 'skipped_last_hour', jobs.skipped_1h),
    'invalid_token_rate_last_hour', case when deliveries.attempts = 0 then 0
                                         else round(deliveries.invalid::numeric / deliveries.attempts, 4) end,
    'heartbeats', coalesce((select jsonb_object_agg(h.name, jsonb_build_object(
                    'last_run_at', h.last_run_at,
                    'age_seconds', round(extract(epoch from now() - h.last_run_at)::numeric, 1),
                    'details', h.details)) from private.ops_heartbeats h), '{}'::jsonb),
    'account_deletions_pending', (select count(*) from private.account_deletion_requests),
    'storage_deletions_pending', (select count(*) from private.storage_deletions))
  from jobs, deliveries
$$;

comment on function private.ops_health() is
  'Monitoring snapshot: dispatcher lag, job/delivery counts, invalid-token rate, heartbeats.';

create or replace function app.ops_health()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select private.ops_health()
$$;

comment on function app.ops_health() is 'Service role only: private.ops_health() through the API (uptime checks).';

-- ---------------------------------------------------------------------------------------------------
-- Scheduled work (called by pg_cron, see 20260922000180_create_cron_jobs.sql)
-- ---------------------------------------------------------------------------------------------------
create or replace function private.run_minutely()
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  v_released int;
begin
  v_released := private.release_expired_leases();
  perform private.heartbeat('lease_reaper', jsonb_build_object('released', v_released));
  perform private.heartbeat('cron', null);
  return jsonb_build_object('released', v_released);
end
$$;

create or replace function private.daily_maintenance()
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  v_out jsonb := '{}'::jsonb;
  v_n   int;
  v_uid uuid;
begin
  -- Each step is isolated: one failing step never blocks the others.
  begin
    insert into private.time_zone_names (name) select name from pg_catalog.pg_timezone_names on conflict do nothing;
  exception when others then v_out := v_out || jsonb_build_object('time_zones_error', sqlerrm);
  end;

  begin
    v_out := v_out || jsonb_build_object('purge', private.purge_tombstones(90));
  exception when others then v_out := v_out || jsonb_build_object('purge_error', sqlerrm);
  end;

  begin
    delete from private.notification_jobs j
     where j.status in ('sent', 'skipped', 'expired', 'cancelled', 'failed') and j.created_at < now() - interval '14 days';
    get diagnostics v_n = row_count;
    v_out := v_out || jsonb_build_object('jobs_deleted', v_n);
    delete from private.push_deliveries d where d.created_at < now() - interval '30 days';
    get diagnostics v_n = row_count;
    v_out := v_out || jsonb_build_object('deliveries_deleted', v_n);
  exception when others then v_out := v_out || jsonb_build_object('jobs_error', sqlerrm);
  end;

  begin
    update app.devices d set push_token = null, push_token_updated_at = null, updated_at = now()
     where d.push_token is not null and coalesce(d.last_seen_at, d.created_at) < now() - interval '120 days';
    get diagnostics v_n = row_count;
    v_out := v_out || jsonb_build_object('stale_tokens_revoked', v_n);
  exception when others then v_out := v_out || jsonb_build_object('devices_error', sqlerrm);
  end;

  begin
    if to_regclass('cron.job_run_details') is not null then
      execute 'delete from cron.job_run_details where end_time < now() - interval ''7 days''';
      get diagnostics v_n = row_count;
      v_out := v_out || jsonb_build_object('cron_details_deleted', v_n);
    end if;
  exception when others then v_out := v_out || jsonb_build_object('cron_error', sqlerrm);
  end;

  begin
    -- Inbox retention: tombstone notifications older than 90 days (synced like any delete).
    update app.notifications n
       set deleted_at = now(),
           field_clock = n.field_clock || jsonb_build_object('deleted_at', app.hlc_at(now()))
     where n.deleted_at is null and n.fire_at < now() - interval '90 days';
    get diagnostics v_n = row_count;
    v_out := v_out || jsonb_build_object('inbox_tombstoned', v_n);
  exception when others then v_out := v_out || jsonb_build_object('inbox_error', sqlerrm);
  end;

  begin
    v_out := v_out || jsonb_build_object('anonymous_users_deleted', private.delete_stale_anonymous_users(90));
  exception when others then v_out := v_out || jsonb_build_object('anonymous_error', sqlerrm);
  end;

  begin
    -- Retry account deletions whose Edge Function call was lost.
    for v_uid in
      select r.user_id from private.account_deletion_requests r
      where r.requested_at < now() - interval '10 minutes' and r.attempts < 10
    loop
      perform private.invoke_edge('account-delete', jsonb_build_object('user_id', v_uid));
    end loop;
    if exists (select 1 from private.storage_deletions) then
      perform private.invoke_edge('storage-purge', '{}'::jsonb);
    end if;
  exception when others then v_out := v_out || jsonb_build_object('edge_error', sqlerrm);
  end;

  perform private.heartbeat('daily_maintenance', v_out);
  return v_out;
end
$$;

comment on function private.daily_maintenance() is 'Daily 03:00 UTC job (arch §7.7). Returns a summary (also in ops_heartbeats).';

revoke execute on function
  private.enqueue_unreferenced_objects(jsonb), private.purge_order(), private.hard_delete_tombstones(text, uuid[]),
  private.purge_tombstones(int, int), app.account_delete_prepare(uuid), app.storage_purge_claim(int),
  app.storage_purge_done(bigint[], jsonb), private.stale_anonymous_users(int, int),
  private.delete_stale_anonymous_users(int, int), private.ops_health(), app.ops_health(),
  private.run_minutely(), private.daily_maintenance()
  from public, anon, authenticated;

grant execute on function
  private.enqueue_unreferenced_objects(jsonb), private.purge_order(), private.hard_delete_tombstones(text, uuid[]),
  private.purge_tombstones(int, int), app.account_delete_prepare(uuid), app.storage_purge_claim(int),
  app.storage_purge_done(bigint[], jsonb), private.stale_anonymous_users(int, int),
  private.delete_stale_anonymous_users(int, int), private.ops_health(), app.ops_health(),
  private.run_minutely(), private.daily_maintenance()
  to service_role;
