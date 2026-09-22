-- =====================================================================================================
-- Organization (arch §7.3, T2.3.01 / T2.3.08 / T2.3.10): categories, tags, entity_tags, saved_views.
-- =====================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- app.categories
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.categories (
  id                    uuid primary key,
  user_id               uuid not null references auth.users (id) on delete cascade,
  created_at            timestamptz not null,
  updated_at            timestamptz not null,
  deleted_at            timestamptz,
  rev                   bigint not null,
  field_clock           jsonb not null default '{}'::jsonb,
  server_updated_at     timestamptz not null,
  origin_device_id      uuid,
  name                  text not null check (char_length(name) between 1 and 100),
  color                 integer not null,
  icon                  text,
  sort_key              text collate "C" not null,
  archived_at           timestamptz,
  counts_as_unavailable boolean not null default false
);

comment on table app.categories is 'User categories (color-coded) shared by tasks, checklists and habits.';
comment on column app.categories.counts_as_unavailable is 'e.g. Sleep/Time off: excluded from capacity stats.';
comment on column app.categories.color is 'ARGB integer.';
comment on column app.categories.sort_key is 'Fractional index (byte order, COLLATE "C").';

-- T2.3.01: name unique per user among non-deleted rows (case-insensitive).
create unique index if not exists categories_user_id_lower_name_key
  on app.categories (user_id, lower(name)) where deleted_at is null;

select app.enable_sync('app.categories');

-- ---------------------------------------------------------------------------------------------------
-- app.tags
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.tags (
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
  color             integer,
  sort_key          text collate "C" not null
);

comment on table app.tags is 'User tags attached to tasks, checklists, checklist items and habits via entity_tags.';

select app.enable_sync('app.tags');

-- ---------------------------------------------------------------------------------------------------
-- app.entity_tags — id = uuidv5(tag_id || '|' || entity_type || '|' || entity_id)
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.entity_tags (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  tag_id            uuid not null references app.tags (id) deferrable initially deferred,
  entity_type       text not null check (entity_type in ('task', 'checklist', 'checklist_item', 'habit')),
  entity_id         uuid not null
);

comment on table app.entity_tags is 'Tag links; deterministic id uuidv5(tag_id|entity_type|entity_id) so devices converge.';

create index if not exists entity_tags_user_entity_idx on app.entity_tags (user_id, entity_type, entity_id);
create index if not exists entity_tags_tag_id_idx on app.entity_tags (tag_id);

select app.enable_sync('app.entity_tags');

create constraint trigger tg_entity_tags_tag_owner
  after insert or update of tag_id on app.entity_tags
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('tag_id', 'app.tags');

-- ---------------------------------------------------------------------------------------------------
-- app.saved_views
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.saved_views (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  section           text not null check (section in ('planner', 'checklists', 'habits', 'stats')),
  name              text not null check (char_length(name) between 1 and 100),
  view_type         text not null,
  config            jsonb not null check (jsonb_typeof(config) = 'object'),
  is_default        boolean not null default false,
  sort_key          text collate "C" not null
);

comment on table app.saved_views is 'View presets per section; config = versioned JSON (arch §8.3).';

select app.enable_sync('app.saved_views');
