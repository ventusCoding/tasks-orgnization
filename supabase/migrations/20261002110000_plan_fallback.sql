-- =====================================================================================================
-- T7.4.17 — server-side planning fallback: a daily Edge Function (`plan-fallback`) plans reminders for
-- users whose devices stopped uploading plans (> 5 days), from their rules, tasks and habits. Server jobs
-- carry planned_by_device = NULL and payload.plannedBy = 'server'; they never replace a device plan.
-- =====================================================================================================

-- Users to plan for: at least one live push-capable device, enabled rules, and no device-planned job
-- inserted for [p_inactive] (every device upload re-inserts its future jobs, so created_at = last upload).
create or replace function app.fallback_candidates(p_inactive interval default interval '5 days', p_limit int default 200)
returns table (user_id uuid)
language sql
stable
security definer
set search_path = ''
as $$
  select u.id
    from auth.users u
   where exists (select 1 from app.devices d
                  where d.user_id = u.id and d.revoked_at is null and d.push_enabled and d.push_token is not null)
     and exists (select 1 from app.notification_rules r
                  where r.user_id = u.id and r.enabled and r.deleted_at is null)
     and coalesce((select max(j.created_at) from private.notification_jobs j
                    where j.user_id = u.id and j.planned_by_device is not null), '-infinity'::timestamptz)
         < now() - p_inactive
   order by u.id
   limit greatest(1, least(p_limit, 1000))
$$;

comment on function app.fallback_candidates(interval, int) is
  'Service role only (plan-fallback): users whose devices have not uploaded a plan for p_inactive.';

-- Everything the fallback planner needs for one user (rules, active tasks, build habits, zone, locale,
-- sync head).
create or replace function app.fallback_load(p_user uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'user_id', p_user,
    'head_rev', coalesce((select h.head_rev from app.sync_heads h where h.user_id = p_user), 0),
    'zone', coalesce((select coalesce(p.current_time_zone, p.home_time_zone) from app.profiles p where p.id = p_user), 'UTC'),
    'locale', (select p.locale from app.profiles p where p.id = p_user),
    'settings', coalesce((select s.value from app.user_settings s
                           where s.user_id = p_user and s.namespace = 'notifications' and s.deleted_at is null), '{}'::jsonb),
    'rules', coalesce((
      select jsonb_agg(jsonb_build_object('id', r.id, 'target_type', r.target_type, 'target_id', r.target_id,
                                          'section', r.section, 'is_default', r.is_default, 'spec', r.spec)
                       order by r.sort_key)
        from app.notification_rules r
       where r.user_id = p_user and r.enabled and r.deleted_at is null), '[]'::jsonb),
    'tasks', coalesce((
      select jsonb_agg(jsonb_build_object('id', t.id, 'title', t.title, 'start_local', t.start_local,
                                          'duration_minutes', t.duration_minutes, 'time_zone', t.time_zone,
                                          'is_all_day', t.is_all_day, 'recurrence', t.recurrence,
                                          'notify_mode', t.notify_mode, 'category_id', t.category_id))
        from app.tasks t
       where t.user_id = p_user and t.deleted_at is null and t.status = 'active' and not t.is_template
         and t.start_local is not null and t.notify_mode <> 'off'
         and (t.recurrence is not null or t.start_local > (now() at time zone 'UTC') - interval '1 day')), '[]'::jsonb),
    'habits', coalesce((
      select jsonb_agg(jsonb_build_object('id', h.id, 'name', h.name, 'kind', h.kind, 'goal_type', h.goal_type,
                                          'target_value', h.target_value, 'target_op', h.target_op,
                                          'schedule', h.schedule, 'start_date', h.start_date, 'end_date', h.end_date,
                                          'time_zone', h.time_zone, 'notify_mode', h.notify_mode))
        from app.habits h
       where h.user_id = p_user and h.deleted_at is null and h.archived_at is null and h.kind = 'build'
         and h.notify_mode <> 'off'), '[]'::jsonb)
  )
$$;

comment on function app.fallback_load(uuid) is 'Service role only (plan-fallback): planning inputs of one user.';

-- Replaces the user's pending server-planned jobs with [p_jobs]; targets holding a pending device plan
-- computed from a newer (or equal) revision are left to the device.
create or replace function app.fallback_replace_jobs(p_user uuid, p_source_rev bigint, p_jobs jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_deleted  int;
  v_inserted int;
begin
  if jsonb_typeof(coalesce(p_jobs, '[]'::jsonb)) <> 'array' then
    raise exception 'p_jobs must be a JSON array';
  end if;
  -- Same per-user lock as device uploads.
  perform pg_advisory_xact_lock(hashtextextended('everslot.notification_jobs:' || p_user::text, 0));

  delete from private.notification_jobs j
   where j.user_id = p_user and j.status = 'pending' and j.planned_by_device is null
     and j.payload ->> 'plannedBy' = 'server' and j.fire_at > now();
  get diagnostics v_deleted = row_count;

  insert into private.notification_jobs (user_id, dedupe_key, target_key, fire_at, expires_at, payload, guard,
                                         source_rev, rule_id, occurrence_key, importance)
  select distinct on (e ->> 'dedupe_key')
         p_user, e ->> 'dedupe_key', e ->> 'target_key', (e ->> 'fire_at')::timestamptz,
         (e ->> 'expires_at')::timestamptz,
         coalesce(e -> 'payload', '{}'::jsonb) || '{"plannedBy": "server"}'::jsonb,
         nullif(e -> 'guard', 'null'::jsonb), p_source_rev, nullif(e ->> 'rule_id', '')::uuid,
         e ->> 'occurrence_key', 'default'
    from jsonb_array_elements(coalesce(p_jobs, '[]'::jsonb)) e
   where (e ->> 'fire_at')::timestamptz > now()
     and (e ->> 'fire_at')::timestamptz <= now() + interval '15 days'
     and not exists (select 1 from private.notification_jobs d
                      where d.user_id = p_user and d.status = 'pending' and d.planned_by_device is not null
                        and d.target_key = e ->> 'target_key' and d.source_rev >= p_source_rev)
   order by e ->> 'dedupe_key'
  on conflict (user_id, dedupe_key) do nothing;
  get diagnostics v_inserted = row_count;

  return jsonb_build_object('replaced', v_deleted, 'inserted', v_inserted);
end
$$;

comment on function app.fallback_replace_jobs(uuid, bigint, jsonb) is
  'Service role only (plan-fallback): swap the user''s pending server-planned jobs; device plans win.';

revoke execute on function app.fallback_candidates(interval, int) from public, anon, authenticated;
revoke execute on function app.fallback_load(uuid) from public, anon, authenticated;
revoke execute on function app.fallback_replace_jobs(uuid, bigint, jsonb) from public, anon, authenticated;
grant execute on function app.fallback_candidates(interval, int) to service_role;
grant execute on function app.fallback_load(uuid) to service_role;
grant execute on function app.fallback_replace_jobs(uuid, bigint, jsonb) to service_role;

-- Daily at 02:30 UTC (before the 03:00 maintenance).
do $$
begin
  if not exists (select 1 from pg_extension where extname = 'pg_cron') then
    raise notice 'pg_cron is not installed: plan-fallback schedule skipped';
    return;
  end if;
  perform cron.schedule('everslot-plan-fallback', '30 2 * * *',
                        $cmd$select private.invoke_edge('plan-fallback', '{}'::jsonb)$cmd$);
end
$$;
