-- =====================================================================================================
-- Habits & quit (arch §7.3, T5.1.01, T5.3.x, T5.4.01, [6.7]): habit_sections, habits, habit_vocab,
-- habit_logs, habit_pauses, habit_revisions, goals, achievements, dashboards.
-- =====================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- app.habit_sections — defaults use uuidv5(user_id || '|habit_section|' || key)
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.habit_sections (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  name              text not null check (char_length(name) between 1 and 100),
  icon              text,
  sort_key          text collate "C" not null,
  start_time        time,
  end_time          time,
  archived_at       timestamptz
);

comment on table app.habit_sections is 'User-defined time-of-day groups of habits (Morning, Evening…).';

select app.enable_sync('app.habit_sections');

-- ---------------------------------------------------------------------------------------------------
-- app.habits — build habits and quit trackers
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.habits (
  id                    uuid primary key,
  user_id               uuid not null references auth.users (id) on delete cascade,
  created_at            timestamptz not null,
  updated_at            timestamptz not null,
  deleted_at            timestamptz,
  rev                   bigint not null,
  field_clock           jsonb not null default '{}'::jsonb,
  server_updated_at     timestamptz not null,
  origin_device_id      uuid,
  kind                  text not null check (kind in ('build', 'quit')),
  name                  text not null check (char_length(name) between 1 and 200),
  description           text,
  icon                  text,
  color                 integer,
  category_id           uuid references app.categories (id) deferrable initially deferred,
  goal_type             text not null default 'check' check (goal_type in ('check', 'count', 'duration', 'numeric')),
  target_value          numeric,
  target_op             text not null default 'gte' check (target_op in ('gte', 'lte', 'eq')),
  unit                  text,
  schedule              jsonb check (schedule is null or (jsonb_typeof(schedule) = 'object' and schedule ? 'v')),
  start_date            date not null,
  end_date              date,
  time_zone             text check (app.is_valid_time_zone(time_zone)),
  skip_policy           text not null default 'neutral' check (skip_policy in ('neutral', 'breaks')),
  freezes_per_month     smallint not null default 0 check (freezes_per_month between 0 and 31),
  quit_mode             text check (quit_mode in ('abstain', 'reduce')),
  quit_substance        text check (quit_substance in ('cigarettes', 'vape', 'alcohol', 'cannabis', 'caffeine', 'sugar',
                                                       'social_media', 'gaming', 'other')),
  quit_started_at       timestamptz,
  daily_limit           numeric,
  baseline_per_day      numeric check (baseline_per_day >= 0),
  unit_cost             numeric check (unit_cost >= 0),
  currency              text check (currency ~ '^[A-Z]{3}$'),
  time_per_unit_minutes numeric check (time_per_unit_minutes >= 0),
  life_minutes_per_unit numeric check (life_minutes_per_unit >= 0),
  auto_success          boolean not null default true,
  motivation            text,
  section_id            uuid references app.habit_sections (id) deferrable initially deferred,
  settings              jsonb not null default '{}'::jsonb check (jsonb_typeof(settings) = 'object'),
  sort_key              text collate "C" not null,
  archived_at           timestamptz,
  notify_mode           text not null default 'inherit' check (notify_mode in ('inherit', 'custom', 'inherit_plus', 'off')),
  constraint habits_build_goal check (kind <> 'build' or goal_type = 'check' or target_value > 0),
  constraint habits_lte_measurable check (target_op <> 'lte' or goal_type <> 'check'),
  constraint habits_quit_fields check (kind <> 'quit' or (quit_mode is not null and quit_started_at is not null)),
  constraint habits_reduce_limit check (quit_mode is distinct from 'reduce' or (daily_limit is not null and daily_limit >= 0)),
  constraint habits_end_after_start check (end_date is null or end_date >= start_date)
);

comment on table app.habits is 'Build habits and quit trackers (goal = goal_type + target_value + target_op + unit, §8.4).';
comment on column app.habits.schedule is 'Recurrence JSON (§8.1); NULL for quit trackers.';
comment on column app.habits.quit_started_at is 'First quit; later attempts start at habit_logs ''restart'' rows.';
comment on column app.habits.life_minutes_per_unit is 'Life-expectancy estimate per unit (NULL = hidden).';

select app.enable_sync('app.habits');

create constraint trigger tg_habits_category_owner
  after insert or update of category_id on app.habits
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('category_id', 'app.categories');

create constraint trigger tg_habits_section_owner
  after insert or update of section_id on app.habits
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('section_id', 'app.habit_sections');

-- ---------------------------------------------------------------------------------------------------
-- app.habit_vocab — triggers / places / coping strategies / distractions
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.habit_vocab (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  kind              text not null check (kind in ('trigger', 'place', 'coping', 'distraction')),
  name              text not null check (char_length(name) between 1 and 100),
  icon              text,
  color             integer,
  sort_key          text collate "C" not null,
  archived_at       timestamptz
);

comment on table app.habit_vocab is 'Reusable vocabularies for craving/relapse logs.';

select app.enable_sync('app.habit_vocab');

-- ---------------------------------------------------------------------------------------------------
-- app.habit_logs
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.habit_logs (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  habit_id          uuid not null references app.habits (id) on delete cascade deferrable initially deferred,
  occurrence_key    text check (occurrence_key ~ '^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2})?$'),
  kind              text not null check (kind in ('done', 'fail', 'progress', 'skip', 'excuse', 'clean', 'relapse', 'craving',
                                                  'note', 'use', 'restart', 'pledge', 'freeze', 'survey')),
  value             numeric check (value >= 0),
  logged_at         timestamptz not null,
  local_date        date not null,
  mood              smallint check (mood between 1 and 5),
  intensity         smallint check (intensity between 1 and 10),
  resisted          boolean,
  "trigger"         text,
  place             text,
  coping            text,
  duration_seconds  integer check (duration_seconds >= 0),
  note              text,
  source            text not null default 'manual' check (source in ('manual', 'notification', 'widget', 'auto', 'import')),
  constraint habit_logs_progress_has_value check (kind <> 'progress' or value is not null),
  constraint habit_logs_intensity_only_craving check (intensity is null or kind = 'craving')
);

comment on table app.habit_logs is 'Habit check-ins and quit events. occurrence_key is a day or slot key, never a quota key.';
comment on column app.habit_logs.local_date is 'Local date computed once at write time (history never shifts).';
comment on column app.habit_logs."trigger" is 'habit_vocab id (or free text).';

create index if not exists habit_logs_user_habit_date_idx on app.habit_logs (user_id, habit_id, local_date);
create index if not exists habit_logs_user_habit_occurrence_idx on app.habit_logs (user_id, habit_id, occurrence_key);
create index if not exists habit_logs_habit_id_idx on app.habit_logs (habit_id);

select app.enable_sync('app.habit_logs');

create constraint trigger tg_habit_logs_habit_owner
  after insert or update of habit_id on app.habit_logs
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('habit_id', 'app.habits');

-- ---------------------------------------------------------------------------------------------------
-- app.habit_pauses — habit_id NULL = all habits (vacation mode)
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.habit_pauses (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  habit_id          uuid references app.habits (id) on delete cascade deferrable initially deferred,
  start_date        date not null,
  end_date          date,
  reason            text,
  constraint habit_pauses_end_after_start check (end_date is null or end_date >= start_date)
);

comment on table app.habit_pauses is 'Pause ranges per habit (habit_id NULL = vacation mode for all habits).';

create index if not exists habit_pauses_user_habit_start_idx on app.habit_pauses (user_id, habit_id, start_date);

select app.enable_sync('app.habit_pauses');

create constraint trigger tg_habit_pauses_habit_owner
  after insert or update of habit_id on app.habit_pauses
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('habit_id', 'app.habits');

-- ---------------------------------------------------------------------------------------------------
-- app.habit_revisions — schedule/goal/economics history
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.habit_revisions (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  habit_id          uuid not null references app.habits (id) on delete cascade deferrable initially deferred,
  effective_from    date not null,
  schedule          jsonb check (schedule is null or jsonb_typeof(schedule) = 'object'),
  goal_type         text check (goal_type in ('check', 'count', 'duration', 'numeric')),
  target_value      numeric,
  target_op         text check (target_op in ('gte', 'lte', 'eq')),
  unit              text,
  baseline_per_day  numeric check (baseline_per_day >= 0),
  unit_cost         numeric check (unit_cost >= 0),
  daily_limit       numeric check (daily_limit >= 0),
  constraint habit_revisions_habit_id_effective_from_key unique (habit_id, effective_from)
);

comment on table app.habit_revisions is 'Versions of schedule/goal/economics so past periods keep their original rules.';

select app.enable_sync('app.habit_revisions');

create constraint trigger tg_habit_revisions_habit_owner
  after insert or update of habit_id on app.habit_revisions
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('habit_id', 'app.habits');

-- ---------------------------------------------------------------------------------------------------
-- app.goals
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.goals (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  scope_type        text not null check (scope_type in ('habit', 'series', 'category', 'checklist', 'global')),
  scope_id          uuid,
  metric            text not null,
  target            numeric not null,
  period            text not null check (period in ('all_time', 'year', 'quarter', 'month', 'week', 'custom')),
  start_date        date,
  end_date          date,
  title             text,
  reward            text,
  achieved_at       timestamptz,
  constraint goals_end_after_start check (end_date is null or start_date is null or end_date >= start_date)
);

comment on table app.goals is 'Goals & challenges over a scope (habit, series, category, checklist, global).';

select app.enable_sync('app.goals');

-- ---------------------------------------------------------------------------------------------------
-- app.achievements — id = uuidv5(code || '|' || scope_type || '|' || scope_id)
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.achievements (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  code              text not null,
  scope_type        text,
  scope_id          uuid,
  unlocked_at       timestamptz not null,
  payload           jsonb
);

comment on table app.achievements is 'Unlocked badges (deterministic ids so devices converge).';

select app.enable_sync('app.achievements');

-- ---------------------------------------------------------------------------------------------------
-- app.dashboards (P2) — custom Insights dashboards
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.dashboards (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  name              text not null check (char_length(name) between 1 and 100),
  sort_key          text collate "C" not null,
  layout            jsonb not null check (jsonb_typeof(layout) = 'array')
);

comment on table app.dashboards is 'Custom Insights dashboards: layout = [{metricId, scopeType, scopeId, period, chartVariant, span}].';

select app.enable_sync('app.dashboards');
