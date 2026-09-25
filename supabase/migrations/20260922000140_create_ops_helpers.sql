-- =====================================================================================================
-- T1.2.12 — pg_net + Vault wiring and heartbeats.
--
-- private.invoke_edge(fn, body) POSTs to `<functions_base_url>/<fn>` with the `x-cron-secret` header.
-- Both values come from Vault (never from cron.job definitions or logs):
--   select vault.create_secret('https://<YOUR_PROJECT_REF>.supabase.co/functions/v1', 'functions_base_url');
--   select vault.create_secret('<CRON_SECRET>', 'cron_secret');
-- When pg_net, Vault or one of the secrets is missing the helper is a no-op (returns NULL), so local
-- resets, CI and projects without push configuration keep working.
-- =====================================================================================================

create or replace function private.invoke_edge(p_function text, p_body jsonb default '{}'::jsonb)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_base   text;
  v_secret text;
  v_id     bigint;
begin
  if p_function is null or p_function !~ '^[a-z0-9][a-z0-9_-]{0,62}$' then
    raise exception 'invalid edge function name %', p_function using errcode = '22023';
  end if;
  if to_regprocedure('net.http_post(text, jsonb, jsonb, jsonb, integer)') is null
     or to_regclass('vault.decrypted_secrets') is null then
    return null;
  end if;

  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_base using 'functions_base_url';
  execute 'select decrypted_secret from vault.decrypted_secrets where name = $1' into v_secret using 'cron_secret';
  if coalesce(v_base, '') = '' or coalesce(v_secret, '') = '' then
    return null;
  end if;

  execute 'select net.http_post(url := $1, body := $2, params := ''{}''::jsonb, headers := $3, timeout_milliseconds := 5000)'
    into v_id
    using rtrim(v_base, '/') || '/' || p_function,
          coalesce(p_body, '{}'::jsonb),
          jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', v_secret);
  return v_id;
end
$$;

comment on function private.invoke_edge(text, jsonb) is
  'POST to an Edge Function with the cron secret (Vault: functions_base_url, cron_secret). No-op when unset.';

revoke execute on function private.invoke_edge(text, jsonb) from public, anon, authenticated;
grant execute on function private.invoke_edge(text, jsonb) to service_role;

create or replace function private.heartbeat(p_name text, p_details jsonb default null)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into private.ops_heartbeats (name, last_run_at, details)
  values (p_name, now(), p_details)
  on conflict (name) do update set last_run_at = excluded.last_run_at, details = excluded.details
$$;

comment on function private.heartbeat(text, jsonb) is 'Upserts a monitoring heartbeat (private.ops_heartbeats).';

revoke execute on function private.heartbeat(text, jsonb) from public, anon, authenticated;
grant execute on function private.heartbeat(text, jsonb) to service_role;

-- Service-role RPC used by Edge Functions to report their own heartbeat.
create or replace function app.ops_heartbeat(p_name text, p_details jsonb default null)
returns void
language sql
security definer
set search_path = ''
as $$
  select private.heartbeat(p_name, p_details)
$$;

comment on function app.ops_heartbeat(text, jsonb) is 'Service role only: record an Edge Function heartbeat.';

revoke execute on function app.ops_heartbeat(text, jsonb) from public, anon, authenticated;
grant execute on function app.ops_heartbeat(text, jsonb) to service_role;
