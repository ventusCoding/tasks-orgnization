-- =====================================================================================================
-- T1.2.05 — Sync plumbing (arch §6.6 server side): per-user revision counter, write trigger, statement
-- broadcast, `app.enable_sync(regclass)`.  T1.2.06 — Realtime authorization for `user:<uid>`.
--
-- Invariants
--   * Every write to a synced table goes through `app.tg_sync_before_write()` (server writers too).
--   * The upsert on `app.sync_heads` row-locks the user's counter until commit → a user's write
--     transactions are serialized and `rev` order == commit order (gap-free pull cursor).
--   * Clients learn "something changed" from a private Broadcast `{"rev": head}` on `user:<uid>`;
--     data always comes from `app.sync_pull`.
-- =====================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- app.sync_heads — per-user revision counter (select own row only; never client-writable).
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.sync_heads (
  user_id               uuid primary key references auth.users (id) on delete cascade,
  head_rev              bigint not null default 0 check (head_rev >= 0),
  updated_at            timestamptz not null default now(),
  last_origin_device_id uuid
);

comment on table app.sync_heads is
  'Per-user sync revision counter (arch §6.6). Row lock serializes a user''s writes. Not client-writable.';
comment on column app.sync_heads.head_rev is 'Highest revision assigned to this user''s rows.';
comment on column app.sync_heads.last_origin_device_id is
  'Device that performed the last write (sync-nudge skips it). NULL for server writes.';

alter table app.sync_heads enable row level security;

drop policy if exists sync_heads_select_own on app.sync_heads;
create policy sync_heads_select_own on app.sync_heads
  for select to authenticated
  using (user_id = (select auth.uid()));

revoke all on app.sync_heads from anon, authenticated;
grant select on app.sync_heads to authenticated;
grant select, insert, update, delete on app.sync_heads to service_role;

-- ---------------------------------------------------------------------------------------------------
-- private.sync_meta — server-side key/value metadata (e.g. `purge_watermark:<user_id>`).
-- ---------------------------------------------------------------------------------------------------
create table if not exists private.sync_meta (
  key   text primary key,
  value jsonb not null
);

comment on table private.sync_meta is
  'Server-only sync metadata. Keys: purge_watermark:<user_id> → highest purged revision (number).';

revoke all on private.sync_meta from public, anon, authenticated;
grant select, insert, update, delete on private.sync_meta to service_role;

-- ---------------------------------------------------------------------------------------------------
-- BEFORE INSERT/UPDATE row trigger.
-- ---------------------------------------------------------------------------------------------------
create or replace function app.tg_sync_before_write()
returns trigger
language plpgsql
security definer                   -- writes app.sync_heads, which clients cannot write
set search_path = ''
as $$
declare
  v_uid        uuid := auth.uid();
  -- `role` is the SET ROLE of the caller (PostgREST / tests set it); it is not changed by SECURITY
  -- DEFINER. 'none' = direct connection (postgres, pg_cron, migrations, auth admin).
  v_role       text := coalesce(nullif(current_setting('role', true), ''), 'none');
  v_privileged boolean := v_role not in ('authenticated', 'anon');
  v_rev        bigint;
begin
  if tg_op = 'INSERT' then
    if v_privileged and new.user_id is not null then
      null;                                   -- trusted server writer supplied the owner
    elsif v_uid is not null then
      new.user_id := v_uid;                   -- clients can only write their own rows
    elsif v_privileged then
      raise exception 'user_id is required for server-side inserts into %', tg_table_name
        using errcode = '23502';
    else
      raise exception 'not_authenticated' using errcode = '42501';
    end if;
    new.created_at  := coalesce(new.created_at, now());
    new.updated_at  := coalesce(new.updated_at, new.created_at);
    new.field_clock := coalesce(new.field_clock, '{}'::jsonb);
  else
    -- Immutable columns: silently keep the stored values (a client can never re-own or re-key a row).
    new.id          := old.id;
    new.user_id     := old.user_id;
    new.created_at  := old.created_at;
    new.field_clock := coalesce(new.field_clock, old.field_clock, '{}'::jsonb);
    new.updated_at  := coalesce(new.updated_at, old.updated_at);

    -- A no-op update keeps its revision (idempotent server writers never wake other devices).
    if (to_jsonb(new) - array['rev', 'server_updated_at', 'origin_device_id'])
       = (to_jsonb(old) - array['rev', 'server_updated_at', 'origin_device_id']) then
      new.rev               := old.rev;
      new.server_updated_at := old.server_updated_at;
      new.origin_device_id  := old.origin_device_id;
      return new;
    end if;
  end if;

  insert into app.sync_heads as h (user_id, head_rev, updated_at, last_origin_device_id)
  values (new.user_id, 1, now(), new.origin_device_id)
  on conflict (user_id) do update
    set head_rev              = h.head_rev + 1,
        updated_at            = now(),
        last_origin_device_id = excluded.last_origin_device_id
  returning h.head_rev into v_rev;

  new.rev               := v_rev;
  new.server_updated_at := now();
  return new;
end
$$;

comment on function app.tg_sync_before_write() is
  'Sync row trigger: forces/keeps user_id, keeps id/created_at immutable, assigns the next per-user rev '
  '(sync_heads upsert, row lock = per-user serialization) and server_updated_at.';

-- ---------------------------------------------------------------------------------------------------
-- AFTER statement trigger: one Broadcast per statement and user with the new head revision.
-- ---------------------------------------------------------------------------------------------------
create or replace function app.tg_sync_broadcast()
returns trigger
language plpgsql
security definer                   -- realtime.messages is only readable (never writable) by clients
set search_path = ''
as $$
declare
  r record;
begin
  -- Realtime may be absent (plain Postgres, restricted CI): writes must never fail because of it.
  if to_regprocedure('realtime.send(jsonb, text, text, boolean)') is null then
    return null;
  end if;

  for r in
    select h.user_id, h.head_rev
    from app.sync_heads h
    where h.user_id in (select distinct n.user_id from sync_new_rows n)
  loop
    perform realtime.send(jsonb_build_object('rev', r.head_rev), 'sync', 'user:' || r.user_id::text, true);
  end loop;
  return null;
end
$$;

comment on function app.tg_sync_broadcast() is
  'Statement trigger: realtime.send({"rev": head}, ''sync'', ''user:<uid>'', private) once per statement/user.';

-- ---------------------------------------------------------------------------------------------------
-- app.enable_sync(regclass) — wire a table identically to every other synced table.
-- ---------------------------------------------------------------------------------------------------
create or replace function app.enable_sync(p_table regclass)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_schema   text;
  v_table    text;
  v_problems text[] := array[]::text[];
  v_pk       text[];
  c          record;
  -- column → (type, not null required)
  v_expected constant jsonb := jsonb_build_object(
    'id',                jsonb_build_array('uuid', true),
    'user_id',           jsonb_build_array('uuid', true),
    'created_at',        jsonb_build_array('timestamp with time zone', true),
    'updated_at',        jsonb_build_array('timestamp with time zone', true),
    'deleted_at',        jsonb_build_array('timestamp with time zone', false),
    'rev',               jsonb_build_array('bigint', true),
    'field_clock',       jsonb_build_array('jsonb', true),
    'server_updated_at', jsonb_build_array('timestamp with time zone', true),
    'origin_device_id',  jsonb_build_array('uuid', false));
begin
  select n.nspname, cl.relname
    into v_schema, v_table
  from pg_catalog.pg_class cl
  join pg_catalog.pg_namespace n on n.oid = cl.relnamespace
  where cl.oid = p_table;

  if v_schema is distinct from 'app' then
    raise exception 'enable_sync: % must live in schema app', p_table;
  end if;

  for c in select key as col, value ->> 0 as typ, (value ->> 1)::boolean as req from jsonb_each(v_expected)
  loop
    if not exists (
      select 1
      from pg_catalog.pg_attribute a
      where a.attrelid = p_table
        and a.attname = c.col
        and not a.attisdropped
        and pg_catalog.format_type(a.atttypid, a.atttypmod) = c.typ
        and (not c.req or a.attnotnull)
    ) then
      v_problems := v_problems || format('%s %s%s', c.col, c.typ, case when c.req then ' not null' else '' end);
    end if;
  end loop;

  if not exists (
    select 1 from pg_catalog.pg_attrdef d
    join pg_catalog.pg_attribute a on a.attrelid = d.adrelid and a.attnum = d.adnum
    where d.adrelid = p_table and a.attname = 'field_clock'
      and pg_catalog.pg_get_expr(d.adbin, d.adrelid) like '''{}''::jsonb%'
  ) then
    v_problems := v_problems || 'field_clock default ''{}''::jsonb'::text;
  end if;

  select array_agg(a.attname::text order by a.attnum)
    into v_pk
  from pg_catalog.pg_index i
  join pg_catalog.pg_attribute a on a.attrelid = i.indrelid and a.attnum = any (i.indkey)
  where i.indrelid = p_table and i.indisprimary;

  if v_pk is distinct from array['id'] then
    v_problems := v_problems || 'primary key (id)'::text;
  end if;

  if cardinality(v_problems) > 0 then
    raise exception 'enable_sync(%): missing or invalid common columns: %', p_table, array_to_string(v_problems, '; ');
  end if;

  -- Pull index.
  execute format('create index if not exists %I on %s (user_id, rev)', v_table || '_user_id_rev_idx', p_table);

  -- RLS: select/insert/update own rows. No delete policy (soft deletes; purge is privileged).
  execute format('alter table %s enable row level security', p_table);
  execute format('drop policy if exists %I on %s', v_table || '_select_own', p_table);
  execute format('drop policy if exists %I on %s', v_table || '_insert_own', p_table);
  execute format('drop policy if exists %I on %s', v_table || '_update_own', p_table);
  execute format(
    'create policy %I on %s for select to authenticated using (user_id = (select auth.uid()))',
    v_table || '_select_own', p_table);
  execute format(
    'create policy %I on %s for insert to authenticated with check (user_id = (select auth.uid()))',
    v_table || '_insert_own', p_table);
  execute format(
    'create policy %I on %s for update to authenticated using (user_id = (select auth.uid())) '
    'with check (user_id = (select auth.uid()))',
    v_table || '_update_own', p_table);

  -- Triggers.
  execute format('drop trigger if exists tg_sync_before_write on %s', p_table);
  execute format(
    'create trigger tg_sync_before_write before insert or update on %s '
    'for each row execute function app.tg_sync_before_write()', p_table);
  -- Transition tables require one event per trigger → one statement trigger for INSERT, one for UPDATE.
  execute format('drop trigger if exists tg_sync_broadcast_insert on %s', p_table);
  execute format(
    'create trigger tg_sync_broadcast_insert after insert on %s '
    'referencing new table as sync_new_rows for each statement execute function app.tg_sync_broadcast()',
    p_table);
  execute format('drop trigger if exists tg_sync_broadcast_update on %s', p_table);
  execute format(
    'create trigger tg_sync_broadcast_update after update on %s '
    'referencing new table as sync_new_rows for each statement execute function app.tg_sync_broadcast()',
    p_table);

  -- Grants: clients write through app.sync_push (security invoker) → need insert/update; never delete.
  execute format('revoke all on %s from anon, authenticated', p_table);
  execute format('grant select, insert, update on %s to authenticated', p_table);
  execute format('grant select, insert, update, delete on %s to service_role', p_table);
end
$$;

comment on function app.enable_sync(regclass) is
  'Validates the common synced columns (arch §7.2) and attaches the (user_id, rev) index, RLS policies '
  '(select/insert/update own rows, no delete), tg_sync_before_write, tg_sync_broadcast_insert/_update '
  '(statement-level) and grants.';

revoke execute on function app.enable_sync(regclass) from public, anon, authenticated;

-- Helper for other server code: the set of synced tables = app tables carrying the sync trigger.
create or replace function app.synced_tables()
returns setof text
language sql
stable
set search_path = ''
as $$
  select c.relname::text
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_class c on c.oid = t.tgrelid
  join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'app' and t.tgname = 'tg_sync_before_write' and not t.tgisinternal
  order by 1
$$;

comment on function app.synced_tables() is 'Names of the app tables wired with app.enable_sync (sync trigger attached).';

grant execute on function app.synced_tables() to authenticated, service_role;

-- ---------------------------------------------------------------------------------------------------
-- T1.2.06 — Realtime Authorization: a user may only receive Broadcasts of `user:<own uid>`.
-- Clients never write to the channel (no insert policy): only tg_sync_broadcast sends.
-- ---------------------------------------------------------------------------------------------------
do $$
begin
  if to_regclass('realtime.messages') is not null then
    drop policy if exists everslot_user_channel_read on realtime.messages;
    create policy everslot_user_channel_read on realtime.messages
      for select to authenticated
      using (
        realtime.messages.extension = 'broadcast'
        and (select realtime.topic()) = 'user:' || (select auth.uid())::text
      );
  else
    raise notice 'realtime.messages does not exist: Broadcast authorization policy skipped';
  end if;
end
$$;
