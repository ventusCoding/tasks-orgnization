-- =====================================================================================================
-- Planner (arch §7.3, T3.1.01 / T3.1.02): tasks, task_occurrences, time_entries.
-- =====================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- app.tasks
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.tasks (
  id                     uuid primary key,
  user_id                uuid not null references auth.users (id) on delete cascade,
  created_at             timestamptz not null,
  updated_at             timestamptz not null,
  deleted_at             timestamptz,
  rev                    bigint not null,
  field_clock            jsonb not null default '{}'::jsonb,
  server_updated_at      timestamptz not null,
  origin_device_id       uuid,
  series_id              uuid not null,
  title                  text not null check (char_length(title) between 1 and 300),
  notes                  text,
  category_id            uuid references app.categories (id) deferrable initially deferred,
  color                  integer,
  priority               smallint not null default 0 check (priority between 0 and 4),
  tracking_mode          text not null default 'check' check (tracking_mode in ('check', 'event', 'timer')),
  is_all_day             boolean not null default false,
  start_local            timestamp,
  duration_minutes       integer check (duration_minutes between 0 and 525600),
  time_zone              text check (app.is_valid_time_zone(time_zone)),
  recurrence             jsonb check (recurrence is null or (jsonb_typeof(recurrence) = 'object' and recurrence ? 'v')),
  recurrence_until_local timestamp,
  estimate_minutes       integer check (estimate_minutes >= 0),
  location               text,
  url                    text,
  icon                   text,
  deadline_local         timestamp,
  linked_checklist_id    uuid,
  manual_sort_key        text collate "C",
  is_template            boolean not null default false,
  notify_mode            text not null default 'inherit' check (notify_mode in ('inherit', 'custom', 'inherit_plus', 'off')),
  status                 text not null default 'active' check (status in ('active', 'paused', 'archived')),
  -- all-day rows start at 00:00 and last whole days
  constraint tasks_all_day_shape check (
    not is_all_day
    or start_local is null
    or (start_local::time = '00:00'::time and (duration_minutes is null or duration_minutes % 1440 = 0))),
  -- unscheduled (backlog) rows cannot repeat
  constraint tasks_unscheduled_not_recurring check (start_local is not null or recurrence is null)
);

comment on table app.tasks is 'Planner tasks (one-off or recurring series, arch §8.1 recurrence JSON).';
comment on column app.tasks.series_id is 'Id of the original task; shared by "this & following" splits. Defaults to id.';
comment on column app.tasks.start_local is 'Wall-clock start (NULL = unscheduled backlog), paired with time_zone.';
comment on column app.tasks.time_zone is 'IANA zone; NULL = floating (user''s current zone).';
comment on column app.tasks.recurrence_until_local is 'Denormalized last possible start (NULL = open-ended).';
comment on column app.tasks.linked_checklist_id is 'Checklist linked to the task (FK added with app.checklists).';
comment on column app.tasks.manual_sort_key is 'Manual order in the backlog and among untimed items of a day.';

create index if not exists tasks_user_start_idx on app.tasks (user_id, start_local) where deleted_at is null;
create index if not exists tasks_user_series_idx on app.tasks (user_id, series_id);
create index if not exists tasks_user_recurrence_until_idx on app.tasks (user_id, recurrence_until_local);
create index if not exists tasks_category_id_idx on app.tasks (category_id) where category_id is not null;

select app.enable_sync('app.tasks');

create or replace function app.tg_tasks_defaults()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.series_id := coalesce(new.series_id, new.id);
  return new;
end
$$;

-- BEFORE triggers fire in name order: this one runs after tg_sync_before_write.
create trigger tg_tasks_defaults
  before insert on app.tasks
  for each row execute function app.tg_tasks_defaults();

create constraint trigger tg_tasks_category_owner
  after insert or update of category_id on app.tasks
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('category_id', 'app.categories');

-- ---------------------------------------------------------------------------------------------------
-- app.task_occurrences — id = uuidv5(task_id || '|' || occurrence_key); only touched occurrences.
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.task_occurrences (
  id                        uuid primary key,
  user_id                   uuid not null references auth.users (id) on delete cascade,
  created_at                timestamptz not null,
  updated_at                timestamptz not null,
  deleted_at                timestamptz,
  rev                       bigint not null,
  field_clock               jsonb not null default '{}'::jsonb,
  server_updated_at         timestamptz not null,
  origin_device_id          uuid,
  task_id                   uuid not null references app.tasks (id) deferrable initially deferred,
  occurrence_key            text not null check (
                              occurrence_key ~ '^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}(:\d{2})?)?$'
                              or occurrence_key ~ '^(day|week|month|year):[0-9A-Za-z-]+#\d+$'),
  override_start_local      timestamp,
  override_duration_minutes integer check (override_duration_minutes between 0 and 525600),
  override_title            text check (char_length(override_title) <= 300),
  override_notes            text,
  is_cancelled              boolean not null default false,
  status                    text not null default 'scheduled'
                              check (status in ('scheduled', 'in_progress', 'done', 'skipped', 'missed', 'cancelled')),
  status_changed_at         timestamptz,
  completed_at              timestamptz,
  actual_start_at           timestamptz,
  actual_end_at             timestamptz,
  tracked_seconds           integer check (tracked_seconds >= 0),
  completion_percent        smallint check (completion_percent between 0 and 100),
  skip_reason               text check (char_length(skip_reason) <= 200),
  rating                    smallint check (rating between 1 and 5),
  outcome_note              text,
  constraint task_occurrences_task_id_occurrence_key_key unique (task_id, occurrence_key)
);

comment on table app.task_occurrences is
  'Touched occurrences of a task (overrides, status, actuals). id = uuid_v5(task_id || ''|'' || occurrence_key).';
comment on column app.task_occurrences.occurrence_key is 'Original local start (RECURRENCE-ID) or quota slot key.';

select app.enable_sync('app.task_occurrences');

create or replace function app.tg_validate_task_occurrence()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and (new.task_id <> old.task_id or new.occurrence_key <> old.occurrence_key) then
    raise exception 'task_occurrences.task_id and occurrence_key are immutable'
      using errcode = 'DL006';
  end if;
  if new.id <> app.uuid_v5(new.task_id::text || '|' || new.occurrence_key) then
    raise exception 'occurrence_id_mismatch: id % must equal app.uuid_v5(task_id || ''|'' || occurrence_key) = %',
      new.id, app.uuid_v5(new.task_id::text || '|' || new.occurrence_key)
      using errcode = 'DL005';
  end if;
  return new;
end
$$;

create trigger tg_validate_task_occurrence
  before insert or update of id, task_id, occurrence_key on app.task_occurrences
  for each row execute function app.tg_validate_task_occurrence();

create constraint trigger tg_task_occurrences_task_owner
  after insert or update of task_id on app.task_occurrences
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('task_id', 'app.tasks');

-- ---------------------------------------------------------------------------------------------------
-- app.time_entries
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.time_entries (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  task_id           uuid not null references app.tasks (id) deferrable initially deferred,
  occurrence_key    text,
  started_at        timestamptz not null,
  ended_at          timestamptz,
  note              text,
  constraint time_entries_end_after_start check (ended_at is null or ended_at >= started_at)
);

comment on table app.time_entries is 'Timer / tracked time sessions of a task (occurrence_key = the occurrence).';

create index if not exists time_entries_user_task_started_idx on app.time_entries (user_id, task_id, started_at);
create index if not exists time_entries_task_id_idx on app.time_entries (task_id);

select app.enable_sync('app.time_entries');

create constraint trigger tg_time_entries_task_owner
  after insert or update of task_id on app.time_entries
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('task_id', 'app.tasks');
