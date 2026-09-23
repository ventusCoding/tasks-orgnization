-- =====================================================================================================
-- pgTAP harness (T1.2.07). Runs first (files are executed in name order) and installs test helpers in
-- schema `tests` OUTSIDE a transaction, so every later file can use them. The schema only exists on
-- local/CI databases (`supabase db reset` removes it); it is never part of a migration.
--
--   tests.create_user(email, id?, meta?)      → uuid   (fires the auth trigger → profile + sync head)
--   tests.authenticate_as(uid)                          (role authenticated + JWT claims)
--   tests.authenticate_as_service_role()
--   tests.clear_authentication()                        (back to the session user, no claims)
--   tests.clock(ts, counter?, node?)          → text   (HLC string)
--   tests.chg(id, g, t, op, row_id, fields, ts, node?)  → jsonb  (one sync_push change, same clock per field)
--   tests.push(changes, device?)              → jsonb  (app.sync_push with a supported build)
-- =====================================================================================================

create extension if not exists pgtap with schema extensions;

create schema if not exists tests;
grant usage on schema tests to anon, authenticated, service_role;

create or replace function tests.create_user(p_email text, p_id uuid default null, p_meta jsonb default '{}'::jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := coalesce(p_id, gen_random_uuid());
begin
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_anonymous)
  values ('00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated', p_email, '', now(),
          '{"provider": "email", "providers": ["email"]}'::jsonb, coalesce(p_meta, '{}'::jsonb), now(), now(), false);
  return v_id;
end
$$;

create or replace function tests.authenticate_as(p_user_id uuid)
returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', p_user_id, 'role', 'authenticated', 'aud', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', p_user_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  perform set_config('role', 'authenticated', true);
end
$$;

create or replace function tests.authenticate_as_service_role()
returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claim.role', 'service_role', true);
  perform set_config('role', 'service_role', true);
end
$$;

create or replace function tests.clear_authentication()
returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claim.role', '', true);
  perform set_config('role', 'none', true);
end
$$;

create or replace function tests.clock(p_at timestamptz, p_counter int default 0, p_node text default 'devA')
returns text
language sql
immutable
as $$
  select app.hlc_at(p_at, p_counter, p_node)
$$;

create or replace function tests.chg(
  p_id text, p_g text, p_t text, p_op text, p_row_id uuid, p_fields jsonb, p_at timestamptz, p_node text default 'devA'
)
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'id', p_id, 'g', p_g, 't', p_t, 'op', p_op, 'row_id', p_row_id, 'fields', p_fields,
    'clock', coalesce((select jsonb_object_agg(k, tests.clock(p_at, 0, p_node)) from jsonb_object_keys(p_fields) k),
                      '{}'::jsonb))
$$;

create or replace function tests.push(p_changes jsonb, p_device uuid default 'dddddddd-0000-4000-8000-00000000000a')
returns jsonb
language sql
as $$
  select app.sync_push(p_device, 1, 1000, p_changes)
$$;

grant execute on all functions in schema tests to anon, authenticated, service_role;

select plan(1);
select has_function('tests', 'authenticate_as', array['uuid'], 'test helpers are installed');
select * from finish();
