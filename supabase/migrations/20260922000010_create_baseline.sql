-- =====================================================================================================
-- T1.2.04 — Baseline: schemas, extensions, grants, helper functions.
--
-- * `app`     — exposed through PostgREST (config.toml `api.schemas = ["app"]`): tables + client RPCs.
-- * `private` — never exposed: server-only tables (jobs, deliveries, sync meta) and internal functions.
--
-- Conventions (supabase/README.md): text + CHECK instead of enums, timestamptz for instants, timestamp
-- for wall-clock values, sort keys `text collate "C"`, every synced table wired with
-- `select app.enable_sync('app.<table>')`, explicit grants (nothing relies on default privileges).
-- =====================================================================================================

create schema if not exists app;
create schema if not exists private;

comment on schema app is 'Everslot application schema (exposed via PostgREST). Synced tables + client RPCs.';
comment on schema private is 'Everslot server-only schema (never exposed). Jobs, deliveries, sync metadata, internals.';

-- ---------------------------------------------------------------------------------------------------
-- Extensions. Guarded so a local reset / a restricted environment never fails on a missing extension.
-- ---------------------------------------------------------------------------------------------------
create extension if not exists pgcrypto with schema extensions;

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
  else
    raise notice 'pg_cron is not available: scheduled jobs are skipped';
  end if;
  if exists (select 1 from pg_available_extensions where name = 'pg_net') then
    create extension if not exists pg_net with schema extensions;
  else
    raise notice 'pg_net is not available: private.invoke_edge() will no-op';
  end if;
end
$$;

-- ---------------------------------------------------------------------------------------------------
-- Grants. Functions are NOT executable by PUBLIC by default: every RPC is granted explicitly.
-- ---------------------------------------------------------------------------------------------------
alter default privileges for role postgres revoke execute on functions from public;

revoke all on schema public from public;
revoke all on schema private from public;

grant usage on schema app to anon, authenticated, service_role;   -- anon: only app.app_config is readable
grant usage on schema private to service_role;

-- ---------------------------------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------------------------------

-- Namespace for deterministic UUIDv5 ids (arch §9.2). Same constant as Dart `EVERSLOT_NS` and TS.
create or replace function app.everslot_ns()
returns uuid
language sql
immutable
parallel safe
set search_path = ''
as $$
  select '6f1c9a52-7c1e-4d3b-9a8e-2b5f0e4c7d11'::uuid
$$;

comment on function app.everslot_ns() is
  'EVERSLOT_NS namespace UUID for UUIDv5 ids (arch §9.2). Must equal the Dart/TS constant.';

-- RFC 4122 §4.3 name-based UUID, version 5: SHA-1(namespace bytes || UTF-8 name), version/variant bits.
create or replace function app.uuid_v5(p_namespace uuid, p_name text)
returns uuid
language sql
immutable
strict
parallel safe
set search_path = ''
as $$
  select encode(
           set_byte(
             set_byte(h, 6, (get_byte(h, 6) & 15) | 80),     -- version 5 (0101xxxx)
             8, (get_byte(h, 8) & 63) | 128),                -- RFC 4122 variant (10xxxxxx)
           'hex')::uuid
  from (
    select substring(
             extensions.digest(uuid_send(p_namespace) || convert_to(p_name, 'UTF8'), 'sha1')
             from 1 for 16) as h
  ) s
$$;

create or replace function app.uuid_v5(p_name text)
returns uuid
language sql
immutable
strict
parallel safe
set search_path = ''
as $$
  select app.uuid_v5(app.everslot_ns(), p_name)
$$;

comment on function app.uuid_v5(text) is
  'UUIDv5 in the EVERSLOT_NS namespace, e.g. task_occurrences.id = uuid_v5(task_id || ''|'' || occurrence_key).';

-- auth.uid() with a clear error when the caller is not authenticated.
create or replace function app.current_user_id()
returns uuid
language plpgsql
stable
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not_authenticated'
      using errcode = '28000', hint = 'Call this function with a user JWT.';
  end if;
  return v_uid;
end
$$;

comment on function app.current_user_id() is 'auth.uid(), raising not_authenticated (28000) when null.';

-- IANA zone validation used by CHECK constraints (NULL = floating, allowed).
-- `pg_timezone_names` scans the tz database on every call (30–90 ms), far too slow for a CHECK: the
-- names are cached in `private.time_zone_names` (refreshed by the daily maintenance job).
create table if not exists private.time_zone_names (
  name text primary key
);

comment on table private.time_zone_names is
  'Cache of pg_timezone_names used by app.is_valid_time_zone (refreshed daily by private.daily_maintenance).';

insert into private.time_zone_names (name)
select name from pg_catalog.pg_timezone_names
on conflict (name) do nothing;

create or replace function app.is_valid_time_zone(p_zone text)
returns boolean
language sql
stable
parallel safe
security definer
set search_path = ''
as $$
  select p_zone is null or exists (select 1 from private.time_zone_names t where t.name = p_zone)
$$;

comment on function app.is_valid_time_zone(text) is 'True when NULL (floating) or a known IANA zone name.';

-- Structured API error for PostgREST (`raise sqlstate 'PGRST'`): the client sees
-- `{"code": p_code, "message": ..., "details": ..., "hint": ...}` with HTTP status p_status.
create or replace function app.raise_api_error(
  p_code text,
  p_message text,
  p_status int default 400,
  p_details jsonb default null,
  p_hint text default null
)
returns void
language plpgsql
volatile
set search_path = ''
as $$
begin
  raise sqlstate 'PGRST'
    using message = json_build_object(
                      'code', p_code, 'message', p_message,
                      'details', p_details, 'hint', p_hint)::text,
          detail  = json_build_object('status', p_status, 'headers', json_build_object())::text;
end
$$;

comment on function app.raise_api_error(text, text, int, jsonb, text) is
  'Raises a PostgREST custom error: body {code,message,details,hint} with the given HTTP status.';

grant execute on function app.everslot_ns() to anon, authenticated, service_role;
grant execute on function app.uuid_v5(uuid, text) to authenticated, service_role;
grant execute on function app.uuid_v5(text) to authenticated, service_role;
grant execute on function app.current_user_id() to authenticated, service_role;
grant execute on function app.is_valid_time_zone(text) to anon, authenticated, service_role;
grant execute on function app.raise_api_error(text, text, int, jsonb, text) to authenticated, service_role;
