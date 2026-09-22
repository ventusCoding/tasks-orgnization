-- =====================================================================================================
-- T1.4.05 / T7.4.02 — Device registry RPCs (security definer, own rows only).
--   app.register_device(...)            → {"revoked": bool}
--   app.report_device_state(id, state)  → {"revoked": bool}   (+ "registered": false when unknown)
--   app.revoke_device(id)               → {"revoked": true}
-- A revoked device id stays revoked: the client signs out and creates a NEW device id.
-- A device id registered by another account on the same install is transferred to the caller with
-- its push token / coverage reset (account switch on one install).
-- =====================================================================================================

create or replace function app.register_device(
  p_id          uuid,
  p_platform    text,
  p_model       text,
  p_os_version  text,
  p_app_version text,
  p_app_build   int,
  p_locale      text,
  p_time_zone   text,
  p_device_name text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := app.current_user_id();
  v_dev record;
begin
  if p_id is null then
    perform app.raise_api_error('invalid_request', 'p_id is required', 400);
  end if;
  if p_platform is null or p_platform not in ('ios', 'android', 'web', 'macos', 'windows', 'linux') then
    perform app.raise_api_error('invalid_request', format('unsupported platform "%s"', p_platform), 400);
  end if;

  select d.user_id, d.revoked_at into v_dev from app.devices d where d.id = p_id for update;

  if found and v_dev.user_id = v_uid and v_dev.revoked_at is not null then
    return jsonb_build_object('revoked', true);
  end if;

  if found and v_dev.user_id <> v_uid then
    -- Account switch on the same install: hand the row over without the previous account's state.
    update app.devices
       set user_id = v_uid, push_token = null, push_token_updated_at = null, local_coverage_until = null,
           schedule_rev = null, local_repeating_rules = null, capabilities = '{}'::jsonb,
           last_nudged_at = null, revoked_at = null
     where id = p_id;
  end if;

  insert into app.devices as d (
    id, user_id, platform, device_name, model, os_version, app_version, app_build, locale, time_zone,
    last_seen_at, created_at, updated_at)
  values (
    p_id, v_uid, p_platform, left(p_device_name, 200), left(p_model, 200), left(p_os_version, 100),
    left(p_app_version, 50), p_app_build, left(p_locale, 35), left(p_time_zone, 64), now(), now(), now())
  on conflict (id) do update
    set platform     = excluded.platform,
        device_name  = coalesce(excluded.device_name, d.device_name),
        model        = excluded.model,
        os_version   = excluded.os_version,
        app_version  = excluded.app_version,
        app_build    = excluded.app_build,
        locale       = excluded.locale,
        time_zone    = excluded.time_zone,
        last_seen_at = now(),
        updated_at   = now();

  return jsonb_build_object('revoked', false);
end
$$;

comment on function app.register_device(uuid, text, text, text, text, int, text, text, text) is
  'Registers/updates the caller''s device (after sign-in, on start). Returns {"revoked": bool}.';

grant execute on function app.register_device(uuid, text, text, text, text, int, text, text, text) to authenticated;

create or replace function app.report_device_state(p_id uuid, p_state jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := app.current_user_id();
  v_s     jsonb := coalesce(p_state, '{}'::jsonb);
  v_dev   record;
  v_token text;
begin
  if jsonb_typeof(v_s) <> 'object' then
    perform app.raise_api_error('invalid_request', 'p_state must be a JSON object', 400);
  end if;

  select d.revoked_at into v_dev from app.devices d where d.id = p_id and d.user_id = v_uid for update;
  if not found then
    return jsonb_build_object('revoked', false, 'registered', false);
  end if;
  if v_dev.revoked_at is not null then
    return jsonb_build_object('revoked', true);
  end if;

  v_token := nullif(v_s ->> 'push_token', '');

  update app.devices d
     set last_seen_at = case when v_s ->> 'last_seen_at' is not null
                             then least((v_s ->> 'last_seen_at')::timestamptz, now()) else d.last_seen_at end,
         time_zone = case when v_s ? 'time_zone' then left(v_s ->> 'time_zone', 64) else d.time_zone end,
         capabilities = case when jsonb_typeof(v_s -> 'capabilities') = 'object'
                             then v_s -> 'capabilities' else d.capabilities end,
         push_token = case when v_s ? 'push_token' then v_token else d.push_token end,
         push_token_updated_at = case when v_s ? 'push_token'
                                      then (case when v_token is null then null else now() end)
                                      else d.push_token_updated_at end,
         push_enabled = case when jsonb_typeof(v_s -> 'push_enabled') = 'boolean'
                             then (v_s ->> 'push_enabled')::boolean else d.push_enabled end,
         local_notifications_enabled = case when jsonb_typeof(v_s -> 'local_notifications_enabled') = 'boolean'
                                            then (v_s ->> 'local_notifications_enabled')::boolean
                                            else d.local_notifications_enabled end,
         local_coverage_until = case when v_s ? 'local_coverage_until'
                                     then (v_s ->> 'local_coverage_until')::timestamptz else d.local_coverage_until end,
         schedule_rev = case when v_s ? 'schedule_rev' then (v_s ->> 'schedule_rev')::bigint else d.schedule_rev end,
         local_repeating_rules = case when v_s ? 'local_repeating_rules'
                                      then (select array_agg(x::uuid)
                                              from jsonb_array_elements_text(
                                                     case when jsonb_typeof(v_s -> 'local_repeating_rules') = 'array'
                                                          then v_s -> 'local_repeating_rules' else '[]'::jsonb end) x)
                                      else d.local_repeating_rules end,
         updated_at = now()
   where d.id = p_id;

  -- Token hygiene: a token belongs to exactly one device row.
  if v_token is not null then
    update app.devices d
       set push_token = null, push_token_updated_at = null, updated_at = now()
     where d.push_token = v_token and d.id <> p_id;
  end if;

  return jsonb_build_object('revoked', false);
end
$$;

comment on function app.report_device_state(uuid, jsonb) is
  'Updates device state keys present in p_state (last_seen_at, time_zone, capabilities, push_token, push_enabled, '
  'local_notifications_enabled, local_coverage_until, schedule_rev, local_repeating_rules). Returns {"revoked": bool}.';

grant execute on function app.report_device_state(uuid, jsonb) to authenticated;

create or replace function app.revoke_device(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := app.current_user_id();
begin
  update app.devices d
     set revoked_at = coalesce(d.revoked_at, now()), push_token = null, push_token_updated_at = null,
         local_coverage_until = null, updated_at = now()
   where d.id = p_id and d.user_id = v_uid;
  if not found then
    perform app.raise_api_error('device_not_found', 'No such device for this account', 404);
  end if;
  return jsonb_build_object('revoked', true);
end
$$;

comment on function app.revoke_device(uuid) is
  'Revokes one of the caller''s devices (no more pushes; the device signs out on next contact).';

grant execute on function app.revoke_device(uuid) to authenticated;
