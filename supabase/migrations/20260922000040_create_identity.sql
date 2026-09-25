-- =====================================================================================================
-- Identity & settings (arch §7.3): app.profiles (T1.5.04), app.user_settings, app.devices (T1.4.05,
-- not synced), the auth.users insert trigger creating the profile + sync head, and the generic
-- same-owner reference check used by child tables.
-- =====================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- Generic reference check: a row may only reference rows owned by the same user.
-- TG_ARGV[0] = referencing column, TG_ARGV[1] = referenced table (schema-qualified).
-- Security definer so it sees rows of other users (RLS would hide them and let the write through).
-- ---------------------------------------------------------------------------------------------------
create or replace function app.tg_check_same_owner()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ref   uuid := (to_jsonb(new) ->> tg_argv[0])::uuid;
  v_owner uuid;
begin
  if v_ref is null then
    return null;
  end if;
  execute format('select user_id from %s where id = $1', tg_argv[1]) into v_owner using v_ref;
  if v_owner is not null and v_owner <> new.user_id then
    raise exception 'owner_mismatch: %.% references a row owned by another user', tg_table_name, tg_argv[0]
      using errcode = 'DL003';
  end if;
  return null;
end
$$;

comment on function app.tg_check_same_owner() is
  'Constraint trigger: TG_ARGV[0] (uuid column) must reference a row of TG_ARGV[1] owned by the same user (DL003).';

-- ---------------------------------------------------------------------------------------------------
-- app.profiles — id = auth user id (also user_id).
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.profiles (
  id                      uuid primary key references auth.users (id) on delete cascade,
  user_id                 uuid not null references auth.users (id) on delete cascade,
  created_at              timestamptz not null,
  updated_at              timestamptz not null,
  deleted_at              timestamptz,
  rev                     bigint not null,
  field_clock             jsonb not null default '{}'::jsonb,
  server_updated_at       timestamptz not null,
  origin_device_id        uuid,
  display_name            text check (char_length(display_name) <= 100),
  avatar_path             text,
  home_time_zone          text not null default 'UTC' check (app.is_valid_time_zone(home_time_zone)),
  current_time_zone       text check (app.is_valid_time_zone(current_time_zone)),
  locale                  text check (char_length(locale) <= 35),
  week_start              smallint not null default 1 check (week_start between 1 and 7),
  time_format             text not null default 'h24' check (time_format in ('h12', 'h24')),
  onboarding_completed_at timestamptz,
  constraint profiles_id_is_user_id check (id = user_id)
);

comment on table app.profiles is 'One row per user (id = user_id = auth.users.id), created by the auth trigger.';
comment on column app.profiles.week_start is 'ISO weekday the week starts on (1 = Monday … 7 = Sunday).';
comment on column app.profiles.home_time_zone is 'IANA zone used for wall-clock values by default.';

select app.enable_sync('app.profiles');

-- ---------------------------------------------------------------------------------------------------
-- app.user_settings — id = uuidv5(user_id || '|' || namespace), versioned JSON per namespace (§8.5).
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.user_settings (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  namespace         text not null check (namespace ~ '^[a-z][a-z_]{0,39}$'),
  value             jsonb not null check (jsonb_typeof(value) = 'object'),
  constraint user_settings_user_id_namespace_key unique (user_id, namespace)
);

comment on table app.user_settings is
  'Per-namespace settings (appearance | planner | checklists | habits | stats | notifications | privacy).';

select app.enable_sync('app.user_settings');

-- ---------------------------------------------------------------------------------------------------
-- app.devices — NOT synced; written via app.register_device / app.report_device_state.
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.devices (
  id                          uuid primary key,
  user_id                     uuid not null references auth.users (id) on delete cascade,
  platform                    text not null check (platform in ('ios', 'android', 'web', 'macos', 'windows', 'linux')),
  device_name                 text check (char_length(device_name) <= 200),
  model                       text,
  os_version                  text,
  app_version                 text,
  app_build                   int,
  locale                      text,
  time_zone                   text,
  push_token                  text,
  push_token_updated_at       timestamptz,
  push_enabled                boolean not null default true,
  local_notifications_enabled boolean not null default true,
  local_coverage_until        timestamptz,
  schedule_rev                bigint,
  capabilities                jsonb not null default '{}'::jsonb check (jsonb_typeof(capabilities) = 'object'),
  local_repeating_rules       uuid[],
  last_nudged_at              timestamptz,
  last_seen_at                timestamptz,
  revoked_at                  timestamptz,
  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now()
);

comment on table app.devices is
  'Device registry (not pulled by sync): push token, capabilities and local notification coverage (arch §6.13).';
comment on column app.devices.last_seen_at is 'Last FOREGROUND time (72-hour coverage rule, last-active policy).';
comment on column app.devices.local_coverage_until is 'Fire time of the last locally scheduled notification.';
comment on column app.devices.schedule_rev is 'sync_heads revision the local schedule was planned from.';
comment on column app.devices.local_repeating_rules is 'Rules covered by repeating local triggers (beyond coverage).';
comment on column app.devices.last_nudged_at is 'Last silent sync push (sync-nudge throttling).';

create index if not exists devices_user_id_idx on app.devices (user_id);
create index if not exists devices_push_token_idx on app.devices (push_token) where push_token is not null;

alter table app.devices enable row level security;

drop policy if exists devices_select_own on app.devices;
create policy devices_select_own on app.devices
  for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists devices_update_own on app.devices;
create policy devices_update_own on app.devices
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on app.devices from anon, authenticated;
grant select on app.devices to authenticated;
grant update (device_name, push_enabled, local_notifications_enabled) on app.devices to authenticated;
grant select, insert, update, delete on app.devices to service_role;

-- ---------------------------------------------------------------------------------------------------
-- auth.users → profile + sync head (T1.5.04).
-- ---------------------------------------------------------------------------------------------------
create or replace function private.tg_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_meta   jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_zone   text := coalesce(v_meta ->> 'time_zone', v_meta ->> 'timeZone');
  v_locale text := left(v_meta ->> 'locale', 35);
begin
  if v_zone is null or not app.is_valid_time_zone(v_zone) then
    v_zone := 'UTC';
  end if;

  insert into app.sync_heads (user_id, head_rev, updated_at)
  values (new.id, 0, now())
  on conflict (user_id) do nothing;

  insert into app.profiles (id, user_id, created_at, updated_at, home_time_zone, current_time_zone, locale, display_name)
  values (new.id, new.id, now(), now(), v_zone, v_zone, v_locale,
          left(coalesce(v_meta ->> 'display_name', v_meta ->> 'full_name', v_meta ->> 'name'), 100))
  on conflict (id) do nothing;

  return new;
end
$$;

comment on function private.tg_handle_new_user() is
  'auth.users AFTER INSERT: creates app.sync_heads + app.profiles (home_time_zone from signup metadata).';

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.tg_handle_new_user();
