-- =====================================================================================================
-- History & files (arch §7.3, T2.2.01): activity_events (append-only), attachments.
-- =====================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- app.activity_events — append-only; only deleted_at (plus sync bookkeeping) may change.
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.activity_events (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  entity_type       text not null,
  entity_id         uuid not null,
  parent_id         uuid,
  event_type        text not null,
  payload           jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
  occurred_at       timestamptz not null
);

comment on table app.activity_events is
  'Append-only history (only deleted_at may change). payload always carries {opId, cause, …}.';
comment on column app.activity_events.parent_id is 'e.g. checklist_id for items, task_id for occurrences.';

create index if not exists activity_events_user_entity_occurred_idx
  on app.activity_events (user_id, entity_type, entity_id, occurred_at);

select app.enable_sync('app.activity_events');

create or replace function app.tg_validate_activity_event_append_only()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_mutable constant text[] := array['deleted_at', 'updated_at', 'rev', 'server_updated_at', 'field_clock', 'origin_device_id'];
begin
  if (to_jsonb(new) - v_mutable) is distinct from (to_jsonb(old) - v_mutable) then
    raise exception 'append_only: activity_events rows are immutable (only deleted_at may change)'
      using errcode = 'DL004';
  end if;
  return new;
end
$$;

-- Runs after tg_sync_before_write (name order), which already restored id/user_id/created_at.
create trigger tg_validate_activity_event_append_only
  before update on app.activity_events
  for each row execute function app.tg_validate_activity_event_append_only();

-- ---------------------------------------------------------------------------------------------------
-- app.attachments — binaries live in Storage `attachments/{user_id}/{attachment_id}/{file}`.
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.attachments (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  owner_type        text not null check (owner_type in ('checklist', 'checklist_item', 'task', 'task_occurrence', 'habit', 'habit_log', 'goal')),
  owner_id          uuid not null,
  bucket            text not null default 'attachments',
  storage_path      text not null,
  thumb_path        text,
  file_name         text not null check (char_length(file_name) between 1 and 255),
  mime_type         text not null,
  byte_size         bigint not null check (byte_size >= 0),
  width             int,
  height            int,
  duration_ms       int,
  sha256            text,
  caption           text,
  sort_key          text collate "C" not null,
  uploaded_at       timestamptz
);

comment on table app.attachments is
  'Attachment rows (polymorphic owner). Duplicated rows may share one storage object (reference-counted purge).';
comment on column app.attachments.storage_path is 'Object path in the bucket; must start with "{user_id}/".';
comment on column app.attachments.uploaded_at is 'Set once the binary is uploaded (NULL = local only).';

create index if not exists attachments_user_owner_idx on app.attachments (user_id, owner_type, owner_id);
create index if not exists attachments_storage_path_idx on app.attachments (bucket, storage_path);

select app.enable_sync('app.attachments');

create or replace function app.tg_validate_attachment_path()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_prefix text := new.user_id::text || '/';
begin
  if left(new.storage_path, length(v_prefix)) <> v_prefix
     or (new.thumb_path is not null and left(new.thumb_path, length(v_prefix)) <> v_prefix)
     or new.storage_path like '%..%' then
    raise exception 'invalid_storage_path: attachment paths must start with "%"', v_prefix
      using errcode = 'DL007';
  end if;
  return new;
end
$$;

-- Runs after tg_sync_before_write (name order) so user_id is already forced to the caller.
create trigger tg_validate_attachment_path
  before insert or update of storage_path, thumb_path on app.attachments
  for each row execute function app.tg_validate_attachment_path();
