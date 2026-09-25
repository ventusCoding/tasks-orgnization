-- =====================================================================================================
-- Notification pipeline, server side (arch §6.13 steps 3–4, T7.4.03, T7.4.05, T7.4.07, T7.4.08):
--   app.replace_notification_jobs      — device uploads its plan (atomic, monotonic source_rev guard)
--   private.claim_notification_jobs    — lease-based claiming (FOR UPDATE SKIP LOCKED)
--   private.notification_guards_ok     — batch guard evaluation (+ mutes)
--   private.release_expired_leases     — lease reaper (every minute)
--   app.dispatch_*                     — service-role-only wrappers used by the push-dispatch Edge
--                                        Function (the private schema is not exposed through the API)
-- =====================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- app.replace_notification_jobs
-- ---------------------------------------------------------------------------------------------------
create or replace function app.replace_notification_jobs(
  p_device_id   uuid,
  p_source_rev  bigint,
  p_target_keys text[],
  p_jobs        jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c_max_pending constant int := 3000;
  c_max_payload constant int := 3584;                    -- 3.5 KB
  c_horizon     constant interval := interval '15 days'; -- 14-day planning horizon + 1 day of slack
  v_uid      uuid := app.current_user_id();
  v_jobs     jsonb := coalesce(p_jobs, '[]'::jsonb);
  v_all      boolean;
  v_dev      record;
  v_job      jsonb;
  v_stale    text[];
  v_deleted  int;
  v_upserted int;
  v_pending  int;
begin
  select d.user_id, d.revoked_at into v_dev from app.devices d where d.id = p_device_id;
  if not found or v_dev.user_id <> v_uid then
    perform app.raise_api_error('device_not_registered', 'Register this device before uploading jobs', 403);
  end if;
  if v_dev.revoked_at is not null then
    perform app.raise_api_error('device_revoked', 'This device has been revoked', 403);
  end if;
  if p_source_rev is null or p_source_rev < 0 then
    perform app.raise_api_error('invalid_request', 'p_source_rev must be >= 0', 400);
  end if;
  if jsonb_typeof(v_jobs) <> 'array' then
    perform app.raise_api_error('invalid_request', 'p_jobs must be a JSON array', 400);
  end if;
  if coalesce(cardinality(p_target_keys), 0) = 0 then
    return jsonb_build_object('status', 'ok', 'replaced', 0, 'upserted', 0);
  end if;
  v_all := '*' = any (p_target_keys);

  for v_job in select e from jsonb_array_elements(v_jobs) e
  loop
    if jsonb_typeof(v_job) <> 'object'
       or coalesce(v_job ->> 'dedupe_key', '') = '' or char_length(v_job ->> 'dedupe_key') > 200
       or coalesce(v_job ->> 'target_key', '') = '' or char_length(v_job ->> 'target_key') > 200
       or v_job ->> 'fire_at' is null then
      perform app.raise_api_error('invalid_job', 'each job needs dedupe_key, target_key and fire_at', 422, v_job);
    end if;
    if not v_all and not ((v_job ->> 'target_key') = any (p_target_keys)) then
      perform app.raise_api_error('invalid_job', format('job target %s is not in p_target_keys', v_job ->> 'target_key'), 422);
    end if;
    if (v_job ->> 'fire_at')::timestamptz > now() + c_horizon then
      perform app.raise_api_error('job_beyond_horizon', 'jobs may be planned at most 14 days ahead', 422,
                                  jsonb_build_object('dedupe_key', v_job ->> 'dedupe_key'));
    end if;
    if octet_length(coalesce(v_job -> 'payload', '{}'::jsonb)::text) > c_max_payload then
      perform app.raise_api_error('job_payload_too_large', 'job payload exceeds 3.5 KB', 413,
                                  jsonb_build_object('dedupe_key', v_job ->> 'dedupe_key'));
    end if;
    if v_job -> 'payload' is not null and jsonb_typeof(v_job -> 'payload') not in ('object', 'null') then
      perform app.raise_api_error('invalid_job', 'job payload must be an object', 422);
    end if;
  end loop;

  -- One replacement at a time per user (atomic under concurrent uploads from several devices).
  perform pg_advisory_xact_lock(hashtextextended('everslot.notification_jobs:' || v_uid::text, 0));

  -- Monotonic guard: never overwrite a plan computed from a newer revision.
  select array_agg(distinct j.target_key order by j.target_key)
    into v_stale
  from private.notification_jobs j
  where j.user_id = v_uid and j.status = 'pending' and j.source_rev > p_source_rev
    and (v_all or j.target_key = any (p_target_keys));

  if v_stale is not null then
    return jsonb_build_object('status', 'stale', 'stale_targets', to_jsonb(v_stale));
  end if;

  delete from private.notification_jobs j
  where j.user_id = v_uid and j.status = 'pending' and j.fire_at > now()
    and (v_all or j.target_key = any (p_target_keys));
  get diagnostics v_deleted = row_count;

  insert into private.notification_jobs as n (
    user_id, dedupe_key, target_key, fire_at, expires_at, payload, guard, source_rev, rule_id,
    occurrence_key, target_devices, planned_by_device, importance)
  select distinct on (e ->> 'dedupe_key')
    v_uid,
    e ->> 'dedupe_key',
    e ->> 'target_key',
    (e ->> 'fire_at')::timestamptz,
    (e ->> 'expires_at')::timestamptz,
    coalesce(nullif(e -> 'payload', 'null'::jsonb), '{}'::jsonb),
    nullif(e -> 'guard', 'null'::jsonb),
    p_source_rev,
    nullif(e ->> 'rule_id', '')::uuid,
    e ->> 'occurrence_key',
    case when jsonb_typeof(e -> 'target_devices') = 'array'
         then (select array_agg(x::uuid) from jsonb_array_elements_text(e -> 'target_devices') x) end,
    p_device_id,
    case when e ->> 'importance' in ('min', 'low', 'default', 'high', 'urgent') then e ->> 'importance' end
  from jsonb_array_elements(v_jobs) with ordinality as x (e, ord)
  order by e ->> 'dedupe_key', ord desc
  on conflict (user_id, dedupe_key) do update
    set target_key        = excluded.target_key,
        fire_at           = excluded.fire_at,
        expires_at        = excluded.expires_at,
        payload           = excluded.payload,
        guard             = excluded.guard,
        source_rev        = excluded.source_rev,
        rule_id           = excluded.rule_id,
        occurrence_key    = excluded.occurrence_key,
        target_devices    = excluded.target_devices,
        planned_by_device = excluded.planned_by_device,
        importance        = excluded.importance,
        attempts          = 0,
        last_error        = null,
        next_retry_at     = null
    where n.status = 'pending';                  -- sent/skipped/expired jobs are never resurrected
  get diagnostics v_upserted = row_count;

  select count(*) into v_pending from private.notification_jobs j where j.user_id = v_uid and j.status = 'pending';
  if v_pending > c_max_pending then
    perform app.raise_api_error('job_cap_exceeded', format('at most %s pending jobs per user', c_max_pending), 429,
                                jsonb_build_object('pending', v_pending));
  end if;

  return jsonb_build_object('status', 'ok', 'replaced', v_deleted, 'upserted', v_upserted);
end
$$;

comment on function app.replace_notification_jobs(uuid, bigint, text[], jsonb) is
  'Atomically replaces the caller''s pending future jobs of p_target_keys (''*'' = all) with p_jobs. Returns '
  '{"status":"ok",replaced,upserted} or {"status":"stale",stale_targets} when a pending job has a higher source_rev.';

grant execute on function app.replace_notification_jobs(uuid, bigint, text[], jsonb) to authenticated;

-- ---------------------------------------------------------------------------------------------------
-- Claiming & lease reaper
-- ---------------------------------------------------------------------------------------------------
create or replace function private.claim_notification_jobs(p_limit int default 100, p_lease_seconds int default 120)
returns setof private.notification_jobs
language sql
set search_path = ''
as $$
  update private.notification_jobs j
     set status = 'claimed',
         claimed_at = now(),
         lease_until = now() + make_interval(secs => greatest(coalesce(p_lease_seconds, 120), 10))
   where j.id in (
     select q.id
     from private.notification_jobs q
     where q.status = 'pending'
       and q.fire_at <= now()
       and (q.next_retry_at is null or q.next_retry_at <= now())
     order by q.fire_at
     limit least(greatest(coalesce(p_limit, 100), 1), 1000)
     for update skip locked)
  returning j.*
$$;

comment on function private.claim_notification_jobs(int, int) is
  'Claims due pending jobs (status claimed + lease_until) with FOR UPDATE SKIP LOCKED.';

create or replace function private.release_expired_leases()
returns int
language sql
set search_path = ''
as $$
  with released as (
    update private.notification_jobs j
       set status      = case when j.attempts + 1 >= 5 then 'failed' else 'pending' end,
           attempts    = j.attempts + 1,
           lease_until = null,
           claimed_at  = null,
           last_error  = 'lease_expired'
     where j.status = 'claimed' and j.lease_until < now()
    returning 1)
  select count(*)::int from released
$$;

comment on function private.release_expired_leases() is
  'Lease reaper: claimed jobs whose lease expired go back to pending (attempts + 1; failed after 5).';

-- ---------------------------------------------------------------------------------------------------
-- Guards
-- ---------------------------------------------------------------------------------------------------
create or replace function private.evaluate_guard(p_user_id uuid, p_guard jsonb)
returns table (ok boolean, reason text)
language plpgsql
stable
set search_path = ''
as $$
declare
  v_kind   text;
  v_g      jsonb;
  v_r      record;
  v_id     uuid;
  v_occ    text;
  v_date   date;
  v_target numeric;
  v_op     text;
  v_sum    numeric;
  v_since  timestamptz;
  v_status text[];
begin
  if p_guard is null or jsonb_typeof(p_guard) = 'null' then
    return query select true, null::text;
    return;
  end if;

  -- An array of guards passes when every guard passes.
  if jsonb_typeof(p_guard) = 'array' then
    for v_g in select e from jsonb_array_elements(p_guard) e
    loop
      select g.ok, g.reason into v_r from private.evaluate_guard(p_user_id, v_g) g;
      if not v_r.ok then
        return query select false, v_r.reason;
        return;
      end if;
    end loop;
    return query select true, null::text;
    return;
  end if;

  v_kind := p_guard ->> 'kind';

  if v_kind = 'always' then
    return query select true, null::text;

  elsif v_kind = 'task_occurrence_open' then
    v_id := (p_guard ->> 'taskId')::uuid;
    v_occ := p_guard ->> 'occurrenceKey';
    if not exists (select 1 from app.tasks t
                   where t.id = v_id and t.user_id = p_user_id and t.deleted_at is null and t.status = 'active') then
      return query select false, 'task_inactive';
    elsif exists (select 1 from app.task_occurrences o
                  where o.task_id = v_id and o.occurrence_key = v_occ and o.user_id = p_user_id
                    and o.deleted_at is null
                    and (o.is_cancelled or o.status in ('done', 'skipped', 'cancelled'))) then
      return query select false, 'occurrence_closed';
    else
      return query select true, null::text;
    end if;

  elsif v_kind = 'habit_period_open' then
    v_id := (p_guard ->> 'habitId')::uuid;
    v_occ := p_guard ->> 'occurrenceKey';
    v_date := case when v_occ ~ '^\d{4}-\d{2}-\d{2}' then left(v_occ, 10)::date end;
    v_target := (p_guard ->> 'target')::numeric;
    v_op := coalesce(p_guard ->> 'op', 'gte');
    if not exists (select 1 from app.habits h
                   where h.id = v_id and h.user_id = p_user_id and h.deleted_at is null and h.archived_at is null) then
      return query select false, 'habit_inactive';
    elsif v_date is not null and exists (
            select 1 from app.habit_pauses p
            where p.user_id = p_user_id and p.deleted_at is null and (p.habit_id = v_id or p.habit_id is null)
              and p.start_date <= v_date and (p.end_date is null or p.end_date >= v_date)) then
      return query select false, 'habit_paused';
    elsif exists (select 1 from app.habit_logs l
                  where l.habit_id = v_id and l.user_id = p_user_id and l.occurrence_key = v_occ
                    and l.deleted_at is null and l.kind in ('done', 'skip', 'excuse', 'fail')) then
      return query select false, 'period_done';
    else
      if v_target is not null and v_op in ('gte', 'eq') then
        select coalesce(sum(l.value), 0) into v_sum
        from app.habit_logs l
        where l.habit_id = v_id and l.user_id = p_user_id and l.occurrence_key = v_occ
          and l.deleted_at is null and l.kind = 'progress';
        if v_sum >= v_target then
          return query select false, 'target_reached';
          return;
        end if;
      end if;
      return query select true, null::text;
    end if;

  elsif v_kind = 'checklist_item_status_in' then
    v_id := (p_guard ->> 'itemId')::uuid;
    v_status := array(select jsonb_array_elements_text(coalesce(p_guard -> 'statuses', '[]'::jsonb)));
    if exists (select 1 from app.checklist_items i
               join app.checklists c on c.id = i.checklist_id
               where i.id = v_id and i.user_id = p_user_id and i.deleted_at is null and c.deleted_at is null
                 and i.status = any (v_status)) then
      return query select true, null::text;
    else
      return query select false, 'item_status_changed';
    end if;

  elsif v_kind = 'item_not_completed' then
    v_id := (p_guard ->> 'itemId')::uuid;
    if exists (select 1 from app.checklist_items i
               join app.checklists c on c.id = i.checklist_id
               where i.id = v_id and i.user_id = p_user_id and i.deleted_at is null and c.deleted_at is null
                 and i.status not in ('completed', 'cancelled')) then
      return query select true, null::text;
    else
      return query select false, 'item_completed';
    end if;

  elsif v_kind = 'quit_no_relapse_since' then
    v_id := (p_guard ->> 'habitId')::uuid;
    v_since := (p_guard ->> 'since')::timestamptz;
    if not exists (select 1 from app.habits h
                   where h.id = v_id and h.user_id = p_user_id and h.deleted_at is null and h.archived_at is null) then
      return query select false, 'habit_inactive';
    elsif exists (select 1 from app.habit_logs l
                  where l.habit_id = v_id and l.user_id = p_user_id and l.deleted_at is null
                    and l.kind in ('relapse', 'restart') and l.logged_at >= v_since) then
      return query select false, 'relapsed';
    else
      return query select true, null::text;
    end if;

  elsif v_kind = 'inbox_not_acted' then
    if exists (select 1 from app.notifications n
               where n.user_id = p_user_id and n.dedupe_key = p_guard ->> 'dedupeKey' and n.deleted_at is null
                 and (n.acted_at is not null or n.dismissed_at is not null)) then
      return query select false, 'acted';
    else
      return query select true, null::text;
    end if;

  else
    -- Unknown kinds (newer clients) fail open and are logged.
    raise log 'notification guard: unknown kind %', v_kind;
    return query select true, 'unknown_guard_kind';
  end if;
end
$$;

comment on function private.evaluate_guard(uuid, jsonb) is
  'Evaluates one guard object (or an array = all) against the user''s current data.';

create or replace function private.job_muted(p_user_id uuid, p_job jsonb)
returns boolean
language plpgsql
stable
set search_path = ''
as $$
declare
  v_type    text := split_part(p_job ->> 'target_key', ':', 1);
  v_id_text text := split_part(p_job ->> 'target_key', ':', 2);
  v_id      uuid;
  v_section text := coalesce(p_job -> 'payload' ->> 'section', p_job ->> 'section');
  v_rule    uuid := nullif(p_job ->> 'rule_id', '')::uuid;
  v_related uuid[] := array[]::uuid[];              -- ancestors / containers of the target
begin
  if v_id_text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    v_id := v_id_text::uuid;
  end if;

  if v_id is not null then
    if v_type = 'checklist_item' then
      with recursive anc (id, parent_id, checklist_id, depth) as (
        select i.id, i.parent_id, i.checklist_id, 0 from app.checklist_items i where i.id = v_id and i.user_id = p_user_id
        union all
        select i.id, i.parent_id, i.checklist_id, a.depth + 1
        from app.checklist_items i join anc a on i.id = a.parent_id
        where a.depth < 1000
      )
      select coalesce(array_agg(a.id), '{}') || coalesce(array_agg(distinct a.checklist_id), '{}')
             || coalesce(array_agg(distinct c.category_id) filter (where c.category_id is not null), '{}')
        into v_related
      from anc a left join app.checklists c on c.id = a.checklist_id;
    elsif v_type = 'task' then
      select array_remove(array[t.series_id, t.category_id], null) into v_related
      from app.tasks t where t.id = v_id and t.user_id = p_user_id;
    elsif v_type = 'habit' then
      select array_remove(array[h.category_id], null) into v_related
      from app.habits h where h.id = v_id and h.user_id = p_user_id;
    elsif v_type = 'checklist' then
      select array_remove(array[c.category_id], null) into v_related
      from app.checklists c where c.id = v_id and c.user_id = p_user_id;
    end if;
  end if;

  return exists (
    select 1
    from app.notification_mutes m
    where m.user_id = p_user_id
      and m.deleted_at is null
      and (m.until is null or m.until > now())
      and (
        m.target_type = 'global'
        or (m.target_type = 'section' and v_section is not null and m.section = v_section)
        or (m.target_type = 'rule' and m.target_id = v_rule)
        or (m.target_id is not null and m.target_id = v_id)
        or (m.target_id is not null and m.target_id = any (coalesce(v_related, '{}')))
      )
  );
end
$$;

comment on function private.job_muted(uuid, jsonb) is
  'True when an active mute covers the job (global, section, rule, target, its series/checklist/ancestors/category).';

create or replace function private.notification_guards_ok(p_jobs jsonb)
returns table (job_id uuid, ok boolean, reason text)
language plpgsql
stable
set search_path = ''
as $$
declare
  v_job jsonb;
  v_r   record;
begin
  for v_job in select e from jsonb_array_elements(coalesce(p_jobs, '[]'::jsonb)) e
  loop
    job_id := (v_job ->> 'id')::uuid;
    begin
      if private.job_muted((v_job ->> 'user_id')::uuid, v_job) then
        ok := false;
        reason := 'muted';
      else
        select g.ok, g.reason into v_r from private.evaluate_guard((v_job ->> 'user_id')::uuid, v_job -> 'guard') g;
        ok := v_r.ok;
        reason := v_r.reason;
      end if;
    exception when others then
      ok := true;                                   -- malformed guards fail open (like unknown kinds)
      reason := 'invalid_guard: ' || sqlerrm;
    end;
    return next;
  end loop;
end
$$;

comment on function private.notification_guards_ok(jsonb) is
  'Batch guard evaluation for claimed jobs ([{id, user_id, guard, target_key, rule_id, payload}]) incl. mutes.';

-- ---------------------------------------------------------------------------------------------------
-- Inbox upsert (arch §6.13, [7.3] convergence rules): insert, or merge delivery fields only.
-- ---------------------------------------------------------------------------------------------------
create or replace function private.upsert_inbox(p_job jsonb, p_late boolean default false)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_payload  jsonb := coalesce(p_job -> 'payload', '{}'::jsonb);
  v_user     uuid := (p_job ->> 'user_id')::uuid;
  v_key      text := p_job ->> 'dedupe_key';
  v_fire_at  timestamptz := coalesce((p_job ->> 'fire_at')::timestamptz, now());
  v_id       uuid := app.uuid_v5(v_key);
  v_clock    text := app.hlc_at(v_fire_at);
  v_category text;
  v_section  text;
  v_source   uuid;
  v_fields   text[] := array['dedupe_key', 'rule_id', 'source_type', 'source_id', 'occurrence_key', 'category',
                             'title', 'body', 'payload', 'section', 'fire_at', 'delivered_at', 'delivered_via', 'late'];
begin
  v_category := case
    when v_payload ->> 'category' in ('reminder', 'nag', 'digest', 'milestone', 'streak', 'system') then v_payload ->> 'category'
    when v_payload ->> 'type' in ('reminder', 'nag', 'digest', 'milestone', 'streak', 'system') then v_payload ->> 'type'
    else 'reminder' end;
  v_section := case when v_payload ->> 'section' in ('planner', 'checklists', 'habits', 'quit', 'system')
                    then v_payload ->> 'section' end;
  if coalesce(v_payload ->> 'sourceId', '') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    v_source := (v_payload ->> 'sourceId')::uuid;
  end if;

  insert into app.notifications as n (
    id, user_id, created_at, updated_at, field_clock, dedupe_key, rule_id, source_type, source_id, occurrence_key,
    category, title, body, payload, section, fire_at, delivered_at, delivered_via, late)
  values (
    v_id, v_user, now(), now(),
    (select jsonb_object_agg(f, v_clock) from unnest(v_fields) f),
    v_key, nullif(p_job ->> 'rule_id', '')::uuid, v_payload ->> 'sourceType', v_source, p_job ->> 'occurrence_key',
    v_category, coalesce(v_payload ->> 'title', ''), v_payload ->> 'body',
    coalesce(v_payload -> 'data', '{}'::jsonb) || jsonb_strip_nulls(jsonb_build_object(
      'deepLink', v_payload -> 'deepLink', 'actions', v_payload -> 'actions', 'target', p_job -> 'target_key')),
    v_section, v_fire_at, now(), array['inbox'], coalesce(p_late, false))
  on conflict (id) do update
    set delivered_at  = least(coalesce(n.delivered_at, excluded.delivered_at), excluded.delivered_at),
        delivered_via = (select array_agg(distinct v order by v)
                         from unnest(coalesce(n.delivered_via, '{}'::text[]) || excluded.delivered_via) v),
        late          = n.late or excluded.late,
        field_clock   = n.field_clock || jsonb_build_object(
                          'delivered_at', greatest(coalesce(n.field_clock ->> 'delivered_at', '') collate "C", v_clock collate "C"),
                          'delivered_via', greatest(coalesce(n.field_clock ->> 'delivered_via', '') collate "C", v_clock collate "C"),
                          'late', greatest(coalesce(n.field_clock ->> 'late', '') collate "C", v_clock collate "C"));
  return v_id;
end
$$;

comment on function private.upsert_inbox(jsonb, boolean) is
  'Writes the inbox row of a job (id = uuid_v5(dedupe_key), clocks = HLC of fire_at); on conflict merges '
  'delivery fields only (earliest delivered_at, union of delivered_via, late) so user state survives.';

-- ---------------------------------------------------------------------------------------------------
-- Service-role wrappers for the push-dispatch Edge Function.
-- ---------------------------------------------------------------------------------------------------
create or replace function app.dispatch_claim(p_limit int default 100, p_lease_seconds int default 120)
returns jsonb
language sql
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(
           to_jsonb(j) || jsonb_build_object('sent_device_ids', coalesce(
             (select jsonb_agg(d.device_id) from private.push_deliveries d where d.job_id = j.id and d.outcome = 'sent'),
             '[]'::jsonb))
           order by j.fire_at), '[]'::jsonb)
  from private.claim_notification_jobs(p_limit, p_lease_seconds) j
$$;

create or replace function app.dispatch_guards(p_jobs jsonb)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object('job_id', g.job_id, 'ok', g.ok, 'reason', g.reason)), '[]'::jsonb)
  from private.notification_guards_ok(p_jobs) g
$$;

create or replace function app.dispatch_upsert_inbox(p_items jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_item jsonb;
  v_out  jsonb := '[]'::jsonb;
  v_id   uuid;
begin
  for v_item in select e from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) e
  loop
    begin
      v_id := private.upsert_inbox(v_item -> 'job', coalesce((v_item ->> 'late')::boolean, false));
      v_out := v_out || jsonb_build_object('job_id', v_item -> 'job' -> 'id', 'notification_id', v_id);
    exception when others then
      v_out := v_out || jsonb_build_object('job_id', v_item -> 'job' -> 'id', 'error', sqlerrm);
    end;
  end loop;
  return v_out;
end
$$;

create or replace function app.dispatch_devices(p_user_ids uuid[])
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_object_agg(u.user_id, jsonb_build_object(
           'policy', coalesce((
             select jsonb_strip_nulls(jsonb_build_object(
                      'multiDevicePolicy', s.value ->> 'multiDevicePolicy',
                      'primaryDeviceId', s.value ->> 'primaryDeviceId',
                      'latenessMinutes', s.value -> 'latenessMinutes'))
             from app.user_settings s
             where s.user_id = u.user_id and s.namespace = 'notifications' and s.deleted_at is null), '{}'::jsonb),
           'devices', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'id', d.id, 'platform', d.platform, 'push_token', d.push_token,
                      'push_token_updated_at', d.push_token_updated_at, 'push_enabled', d.push_enabled,
                      'local_notifications_enabled', d.local_notifications_enabled,
                      'local_coverage_until', d.local_coverage_until, 'schedule_rev', d.schedule_rev,
                      'capabilities', d.capabilities, 'local_repeating_rules', to_jsonb(d.local_repeating_rules),
                      'last_seen_at', d.last_seen_at, 'revoked_at', d.revoked_at) order by d.id)
             from app.devices d
             where d.user_id = u.user_id and d.revoked_at is null), '[]'::jsonb))), '{}'::jsonb)
  from (select distinct unnest(coalesce(p_user_ids, '{}'::uuid[])) as user_id) u
$$;

-- p_results: [{job_id, status: sent|skipped|expired|failed|retry, reason?, retry_after_seconds?, pushed?,
--              deliveries: [{device_id, outcome, fcm_message_id?, error_code?}], invalid_device_ids: [uuid]}]
create or replace function app.dispatch_complete(p_results jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_r       jsonb;
  v_job     record;
  v_status  text;
  v_updated int := 0;
begin
  for v_r in select e from jsonb_array_elements(coalesce(p_results, '[]'::jsonb)) e
  loop
    insert into private.push_deliveries as d (job_id, device_id, outcome, fcm_message_id, error_code)
    select (v_r ->> 'job_id')::uuid, (x ->> 'device_id')::uuid, x ->> 'outcome', x ->> 'fcm_message_id', x ->> 'error_code'
    from jsonb_array_elements(coalesce(v_r -> 'deliveries', '[]'::jsonb)) x
    on conflict (job_id, device_id) do update
      set outcome = excluded.outcome,
          fcm_message_id = coalesce(excluded.fcm_message_id, d.fcm_message_id),
          error_code = excluded.error_code,
          created_at = now()
      where d.outcome <> 'sent';                      -- a sent delivery is final

    update app.devices dv
       set push_token = null, push_token_updated_at = null, updated_at = now()
     where dv.id in (select x::uuid from jsonb_array_elements_text(coalesce(v_r -> 'invalid_device_ids', '[]'::jsonb)) x);

    v_status := v_r ->> 'status';
    if v_status = 'retry' then
      update private.notification_jobs j
         set status        = case when j.attempts + 1 >= 5 then 'failed' else 'pending' end,
             attempts      = j.attempts + 1,
             next_retry_at = now() + make_interval(secs => greatest(coalesce((v_r ->> 'retry_after_seconds')::int, 60), 1)),
             lease_until   = null,
             claimed_at    = null,
             last_error    = v_r ->> 'reason'
       where j.id = (v_r ->> 'job_id')::uuid and j.status = 'claimed'
      returning j.user_id, j.dedupe_key into v_job;
    elsif v_status in ('sent', 'skipped', 'expired', 'failed', 'cancelled') then
      update private.notification_jobs j
         set status      = v_status,
             sent_at     = case when v_status = 'sent' then now() else j.sent_at end,
             lease_until = null,
             last_error  = v_r ->> 'reason'
       where j.id = (v_r ->> 'job_id')::uuid and j.status = 'claimed'
      returning j.user_id, j.dedupe_key into v_job;
    else
      continue;
    end if;

    if found then
      v_updated := v_updated + 1;
      if coalesce((v_r ->> 'pushed')::boolean, false) then
        update app.notifications n
           set delivered_via = (select array_agg(distinct v order by v)
                                from unnest(coalesce(n.delivered_via, '{}'::text[]) || array['push']) v),
               field_clock = n.field_clock || jsonb_build_object('delivered_via',
                               greatest(coalesce(n.field_clock ->> 'delivered_via', '') collate "C",
                                        app.hlc_at(n.fire_at) collate "C"))
         where n.user_id = v_job.user_id and n.dedupe_key = v_job.dedupe_key
           and not (coalesce(n.delivered_via, '{}'::text[]) @> array['push']);
      end if;
    end if;
  end loop;
  return jsonb_build_object('updated', v_updated);
end
$$;

comment on function app.dispatch_claim(int, int) is 'Service role only (push-dispatch): claim due jobs (+ sent_device_ids).';
comment on function app.dispatch_guards(jsonb) is 'Service role only (push-dispatch): [{job_id, ok, reason}].';
comment on function app.dispatch_upsert_inbox(jsonb) is 'Service role only (push-dispatch): [{job, late}] → inbox rows.';
comment on function app.dispatch_devices(uuid[]) is 'Service role only (push-dispatch): {user_id: {policy, devices}}.';
comment on function app.dispatch_complete(jsonb) is 'Service role only (push-dispatch): deliveries, job status, token revocation.';

revoke execute on function
  private.claim_notification_jobs(int, int), private.release_expired_leases(), private.evaluate_guard(uuid, jsonb),
  private.job_muted(uuid, jsonb), private.notification_guards_ok(jsonb), private.upsert_inbox(jsonb, boolean),
  app.dispatch_claim(int, int), app.dispatch_guards(jsonb), app.dispatch_upsert_inbox(jsonb),
  app.dispatch_devices(uuid[]), app.dispatch_complete(jsonb)
  from public, anon, authenticated;

grant execute on function
  private.claim_notification_jobs(int, int), private.release_expired_leases(), private.evaluate_guard(uuid, jsonb),
  private.job_muted(uuid, jsonb), private.notification_guards_ok(jsonb), private.upsert_inbox(jsonb, boolean),
  app.dispatch_claim(int, int), app.dispatch_guards(jsonb), app.dispatch_upsert_inbox(jsonb),
  app.dispatch_devices(uuid[]), app.dispatch_complete(jsonb)
  to service_role;
