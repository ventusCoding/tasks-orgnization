-- =====================================================================================================
-- Notifications (arch §7.3, T7.1.01, T7.5.16, T7.4.03, T7.4.16): synced notification_profiles,
-- notification_rules, notifications (inbox), notification_mutes; server-only private.notification_jobs,
-- private.push_deliveries, private.ops_heartbeats.
-- =====================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- app.notification_profiles — built-ins use uuidv5(user_id || '|profile|' || code)
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.notification_profiles (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  code              text check (code ~ '^[a-z][a-z0-9_]{0,39}$'),
  name              text not null check (char_length(name) between 1 and 100),
  is_builtin        boolean not null default false,
  spec              jsonb not null check (jsonb_typeof(spec) = 'object'),
  sort_key          text collate "C" not null
);

comment on table app.notification_profiles is 'Delivery presets (Gentle, Standard, Nag-until-done, Alarm, custom).';
comment on column app.notification_profiles.code is 'Built-ins: gentle | standard | nag | alarm (unique per user); NULL for custom.';

create unique index if not exists notification_profiles_user_code_key
  on app.notification_profiles (user_id, code) where code is not null;

select app.enable_sync('app.notification_profiles');

-- ---------------------------------------------------------------------------------------------------
-- app.notification_rules — spec = arch §8.2
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.notification_rules (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  target_type       text not null check (target_type in ('task', 'checklist', 'checklist_item', 'habit', 'category', 'section', 'global')),
  target_id         uuid,
  section           text not null check (section in ('planner', 'checklists', 'habits', 'quit', 'system')),
  is_default        boolean not null default false,
  enabled           boolean not null default true,
  name              text,
  profile_id        uuid references app.notification_profiles (id) deferrable initially deferred,
  spec              jsonb not null check (jsonb_typeof(spec) = 'object'),
  sort_key          text collate "C" not null,
  constraint notification_rules_target_id_presence check ((target_id is null) = (target_type in ('section', 'global')))
);

comment on table app.notification_rules is 'Notification rules attached to a target or acting as defaults (spec §8.2).';

create index if not exists notification_rules_user_target_idx
  on app.notification_rules (user_id, target_type, target_id) where deleted_at is null;

select app.enable_sync('app.notification_rules');

create constraint trigger tg_notification_rules_profile_owner
  after insert or update of profile_id on app.notification_rules
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('profile_id', 'app.notification_profiles');

-- ---------------------------------------------------------------------------------------------------
-- app.notifications — in-app inbox; id = uuidv5(dedupe_key)
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.notifications (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  dedupe_key        text not null check (char_length(dedupe_key) between 1 and 200),
  rule_id           uuid,
  source_type       text,
  source_id         uuid,
  occurrence_key    text,
  category          text not null check (category in ('reminder', 'nag', 'digest', 'milestone', 'streak', 'system')),
  title             text not null,
  body              text,
  payload           jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
  section           text check (section in ('planner', 'checklists', 'habits', 'quit', 'system')),
  fire_at           timestamptz not null,
  delivered_at      timestamptz,
  delivered_via     text[] check (delivered_via <@ array['local', 'push', 'inbox', 'inbox_only']::text[]),
  late              boolean not null default false,
  opened_at         timestamptz,
  read_at           timestamptz,
  dismissed_at      timestamptz,
  acted_at          timestamptz,
  action            text,
  snoozed_until     timestamptz,
  constraint notifications_user_id_dedupe_key_key unique (user_id, dedupe_key)
);

comment on table app.notifications is
  'In-app inbox (record of truth). id = uuid_v5(dedupe_key). Delivery fields written by the server, user state by devices.';
comment on column app.notifications.delivered_via is 'Channels that delivered it: local, push, inbox/inbox_only.';

create index if not exists notifications_user_fire_at_idx on app.notifications (user_id, fire_at desc);
create index if not exists notifications_user_unread_idx
  on app.notifications (user_id) where read_at is null and deleted_at is null;

select app.enable_sync('app.notifications');

-- ---------------------------------------------------------------------------------------------------
-- app.notification_mutes — "mute this rule / list / item subtree / habit / section until …"
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.notification_mutes (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  target_type       text not null check (target_type in ('rule', 'task', 'series', 'checklist', 'checklist_item', 'habit',
                                                         'category', 'section', 'global')),
  target_id         uuid,
  section           text check (section in ('planner', 'checklists', 'habits', 'quit', 'system')),
  until             timestamptz,
  reason            text
);

comment on table app.notification_mutes is 'Active mutes (until NULL = until unmuted). Evaluated by planner and dispatcher guards.';

create index if not exists notification_mutes_user_target_idx
  on app.notification_mutes (user_id, target_type, target_id) where deleted_at is null;

select app.enable_sync('app.notification_mutes');

-- =====================================================================================================
-- Server-only tables (schema private, service role only)
-- =====================================================================================================

create table if not exists private.notification_jobs (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users (id) on delete cascade,
  dedupe_key        text not null check (char_length(dedupe_key) between 1 and 200),
  target_key        text not null check (char_length(target_key) between 1 and 200),
  fire_at           timestamptz not null,
  payload           jsonb not null check (jsonb_typeof(payload) = 'object'),
  guard             jsonb,
  source_rev        bigint not null,
  rule_id           uuid,
  occurrence_key    text,
  target_devices    uuid[],
  planned_by_device uuid,
  importance        text check (importance in ('min', 'low', 'default', 'high', 'urgent')),
  status            text not null default 'pending'
                      check (status in ('pending', 'claimed', 'sent', 'skipped', 'failed', 'cancelled', 'expired')),
  attempts          smallint not null default 0,
  last_error        text,
  next_retry_at     timestamptz,
  claimed_at        timestamptz,
  lease_until       timestamptz,
  sent_at           timestamptz,
  expires_at        timestamptz,
  created_at        timestamptz not null default now(),
  constraint notification_jobs_user_id_dedupe_key_key unique (user_id, dedupe_key)
);

comment on table private.notification_jobs is
  'Planned notifications uploaded by devices (app.replace_notification_jobs) and dispatched by push-dispatch.';
comment on column private.notification_jobs.target_key is 'Unit of replacement, e.g. ''task:<id>''.';
comment on column private.notification_jobs.source_rev is 'sync head the plan was computed from (monotonic guard).';
comment on column private.notification_jobs.target_devices is 'Rule conditions.devices (NULL = all devices).';
comment on column private.notification_jobs.expires_at is 'Lateness policy: never deliver after this instant.';

create index if not exists notification_jobs_pending_fire_at_idx
  on private.notification_jobs (fire_at) where status = 'pending';
create index if not exists notification_jobs_pending_user_target_idx
  on private.notification_jobs (user_id, target_key) where status = 'pending';
create index if not exists notification_jobs_claimed_lease_idx
  on private.notification_jobs (lease_until) where status = 'claimed';
create index if not exists notification_jobs_created_at_idx
  on private.notification_jobs (created_at);

create table if not exists private.push_deliveries (
  id             uuid primary key default gen_random_uuid(),
  job_id         uuid,
  device_id      uuid,
  outcome        text not null check (outcome in ('sent', 'skipped_local', 'skipped_policy', 'skipped_stale_token',
                                                  'expired', 'failed', 'token_invalid')),
  fcm_message_id text,
  error_code     text,
  created_at     timestamptz not null default now(),
  constraint push_deliveries_job_id_device_id_key unique (job_id, device_id)
);

comment on table private.push_deliveries is 'Per job × device dispatch decision / FCM result (log, 30-day retention).';

create index if not exists push_deliveries_created_at_idx on private.push_deliveries (created_at);

create table if not exists private.ops_heartbeats (
  name        text primary key,
  last_run_at timestamptz not null,
  details     jsonb
);

comment on table private.ops_heartbeats is 'Monitoring heartbeats of cron jobs and Edge Functions (app.ops_health).';

create table if not exists private.account_deletion_requests (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  requested_at timestamptz not null default now(),
  attempts     int not null default 0,
  last_attempt_at timestamptz
);

comment on table private.account_deletion_requests is
  'Accounts waiting for the account-delete Edge Function (row disappears with the auth user).';

revoke all on private.notification_jobs, private.push_deliveries, private.ops_heartbeats,
  private.account_deletion_requests from public, anon, authenticated;
grant select, insert, update, delete on private.notification_jobs, private.push_deliveries,
  private.ops_heartbeats, private.account_deletion_requests to service_role;
