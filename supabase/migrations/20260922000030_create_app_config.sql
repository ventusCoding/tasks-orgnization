-- =====================================================================================================
-- T1.2.11 / T9.2.07 — App config (public read) & minimum supported build gate.
-- =====================================================================================================

create table if not exists app.app_config (
  key   text primary key,
  value jsonb not null
);

comment on table app.app_config is
  'Public, read-only client configuration: min_supported_build, recommended_build, maintenance_message.';
comment on column app.app_config.value is 'JSON value (numbers for builds, string/null for messages).';

alter table app.app_config enable row level security;

drop policy if exists app_config_public_read on app.app_config;
create policy app_config_public_read on app.app_config
  for select to anon, authenticated
  using (true);

revoke all on app.app_config from anon, authenticated;
grant select on app.app_config to anon, authenticated;
grant select, insert, update, delete on app.app_config to service_role;

insert into app.app_config (key, value) values
  ('min_supported_build', '1'::jsonb),
  ('recommended_build', '1'::jsonb),
  ('maintenance_message', 'null'::jsonb)
on conflict (key) do nothing;

-- Raises `unsupported_client` (HTTP 426) when the client build is below min_supported_build.
create or replace function app.assert_client_supported(p_build int)
returns void
language plpgsql
stable
set search_path = ''
as $$
declare
  v_min int;
begin
  select (c.value #>> '{}')::int into v_min from app.app_config c where c.key = 'min_supported_build';
  v_min := coalesce(v_min, 0);
  if p_build is null or p_build < v_min then
    perform app.raise_api_error(
      'unsupported_client',
      format('Client build %s is below the minimum supported build %s', coalesce(p_build::text, 'null'), v_min),
      426,
      jsonb_build_object('min_supported_build', v_min, 'build', p_build),
      'Update the app to continue syncing.');
  end if;
end
$$;

comment on function app.assert_client_supported(int) is
  'Raises PostgREST error {code: unsupported_client} (HTTP 426) when p_build < app_config.min_supported_build.';

grant execute on function app.assert_client_supported(int) to anon, authenticated, service_role;
