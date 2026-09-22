-- =====================================================================================================
-- Checklists (arch §7.3, T4.1.01): checklists, checklist_items (infinitely nested), checklist_runs.
-- Tree integrity is enforced by DEFERRABLE INITIALLY DEFERRED constraint triggers so a whole subtree
-- move passes whatever order its rows arrive in; app.sync_push checks them at the end of each
-- operation group (SET CONSTRAINTS ALL IMMEDIATE).
--   DL001 checklist_parent_mismatch — parent missing / in another checklist or of another user
--   DL002 checklist_cycle            — an item would become its own ancestor
-- =====================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- app.checklists
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.checklists (
  id                  uuid primary key,
  user_id             uuid not null references auth.users (id) on delete cascade,
  created_at          timestamptz not null,
  updated_at          timestamptz not null,
  deleted_at          timestamptz,
  rev                 bigint not null,
  field_clock         jsonb not null default '{}'::jsonb,
  server_updated_at   timestamptz not null,
  origin_device_id    uuid,
  title               text not null default '' check (char_length(title) <= 500),
  body                text check (char_length(body) <= 100000),
  color               integer,
  category_id         uuid references app.categories (id) deferrable initially deferred,
  is_pinned           boolean not null default false,
  sort_key            text collate "C" not null,
  archived_at         timestamptz,
  cover_attachment_id uuid,
  due_local           timestamp,
  time_zone           text check (app.is_valid_time_zone(time_zone)),
  reset_rule          jsonb check (reset_rule is null or jsonb_typeof(reset_rule) = 'object'),
  reset_mode          text check (reset_mode in ('all_to_todo', 'completed_to_todo')),
  last_reset_key      text,
  settings            jsonb not null default '{}'::jsonb check (jsonb_typeof(settings) = 'object'),
  is_template         boolean not null default false,
  template_id         uuid,
  notify_mode         text not null default 'inherit' check (notify_mode in ('inherit', 'custom', 'inherit_plus', 'off'))
);

comment on table app.checklists is 'Keep-like checklists (lists board). settings = arch §8.6.';
comment on column app.checklists.reset_rule is 'Recurrence JSON (§8.1) for resettable checklists.';
comment on column app.checklists.template_id is 'Template this list came from.';

create index if not exists checklists_user_pinned_sort_idx
  on app.checklists (user_id, is_pinned, sort_key) where deleted_at is null;

select app.enable_sync('app.checklists');

create constraint trigger tg_checklists_category_owner
  after insert or update of category_id on app.checklists
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('category_id', 'app.categories');

-- tasks.linked_checklist_id → checklists (deferred [4.1] FK, arch §7.3).
alter table app.tasks
  drop constraint if exists tasks_linked_checklist_id_fkey;
alter table app.tasks
  add constraint tasks_linked_checklist_id_fkey
  foreign key (linked_checklist_id) references app.checklists (id) deferrable initially deferred;

create constraint trigger tg_tasks_linked_checklist_owner
  after insert or update of linked_checklist_id on app.tasks
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('linked_checklist_id', 'app.checklists');

-- ---------------------------------------------------------------------------------------------------
-- app.checklist_items
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.checklist_items (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  checklist_id      uuid not null references app.checklists (id) deferrable initially deferred,
  parent_id         uuid references app.checklist_items (id) deferrable initially deferred,
  sort_key          text collate "C" not null check (sort_key ~ '^[0-9A-Za-z]{1,128}$'),
  text              text not null default '' check (char_length(text) <= 10000),
  note              text check (char_length(note) <= 50000),
  status            text not null default 'todo'
                      check (status in ('todo', 'ongoing', 'waiting', 'blocked', 'completed', 'cancelled')),
  status_note       text,
  status_changed_at timestamptz,
  completed_at      timestamptz,
  follow_up_at      timestamptz,
  due_local         timestamp,
  time_zone         text check (app.is_valid_time_zone(time_zone)),
  waiting_on        text,
  priority          smallint not null default 0,
  notify_mode       text not null default 'inherit' check (notify_mode in ('inherit', 'custom', 'inherit_plus', 'off')),
  constraint checklist_items_completed_at_iff_completed check ((completed_at is not null) = (status = 'completed'))
);

comment on table app.checklist_items is 'Nested checklist items (parent_id NULL = top level).';
comment on column app.checklist_items.sort_key is 'Fractional index among siblings (byte order, COLLATE "C").';
comment on column app.checklist_items.waiting_on is 'Who/what a waiting item waits for.';

create index if not exists checklist_items_user_checklist_idx
  on app.checklist_items (user_id, checklist_id) where deleted_at is null;
create index if not exists checklist_items_checklist_parent_sort_idx
  on app.checklist_items (checklist_id, parent_id, sort_key);
create index if not exists checklist_items_parent_id_idx
  on app.checklist_items (parent_id) where parent_id is not null;

select app.enable_sync('app.checklist_items');

create or replace function app.tg_checklist_items_tree_check()
returns trigger
language plpgsql
security definer                   -- must see rows of other users to detect cross-user parents
set search_path = ''
as $$
declare
  v_cur    record;
  v_parent record;
  v_cycle  boolean;
begin
  -- Deferred check: evaluate the row as it is now (it may have changed again since the event).
  select i.id, i.user_id, i.checklist_id, i.parent_id
    into v_cur
  from app.checklist_items i
  where i.id = new.id;

  if not found then
    return null;
  end if;

  if v_cur.parent_id is not null then
    if v_cur.parent_id = v_cur.id then
      raise exception 'checklist_cycle: item % cannot be its own parent', v_cur.id using errcode = 'DL002';
    end if;

    select p.id, p.user_id, p.checklist_id
      into v_parent
    from app.checklist_items p
    where p.id = v_cur.parent_id;

    if not found or v_parent.checklist_id <> v_cur.checklist_id or v_parent.user_id <> v_cur.user_id then
      raise exception 'checklist_parent_mismatch: parent % of item % is not in checklist %',
        v_cur.parent_id, v_cur.id, v_cur.checklist_id
        using errcode = 'DL001';
    end if;

    with recursive ancestors (id, parent_id, depth) as (
      select p.id, p.parent_id, 1
      from app.checklist_items p
      where p.id = v_cur.parent_id
      union all
      select p.id, p.parent_id, a.depth + 1
      from app.checklist_items p
      join ancestors a on p.id = a.parent_id
      where a.depth < 10000 and a.id <> v_cur.id
    )
    select exists (select 1 from ancestors where id = v_cur.id) into v_cycle;

    if v_cycle then
      raise exception 'checklist_cycle: item % would become its own ancestor', v_cur.id using errcode = 'DL002';
    end if;
  end if;

  -- Children always live in the parent's checklist (a moved subtree moves as a whole).
  if exists (
    select 1 from app.checklist_items c
    where c.parent_id = v_cur.id and c.checklist_id <> v_cur.checklist_id
  ) then
    raise exception 'checklist_parent_mismatch: children of item % are not in checklist %', v_cur.id, v_cur.checklist_id
      using errcode = 'DL001';
  end if;

  return null;
end
$$;

comment on function app.tg_checklist_items_tree_check() is
  'Deferred integrity: parent in the same checklist/user (DL001) and no cycles (DL002).';

create constraint trigger tg_checklist_items_tree_check
  after insert or update of parent_id, checklist_id on app.checklist_items
  deferrable initially deferred
  for each row execute function app.tg_checklist_items_tree_check();

create constraint trigger tg_checklist_items_checklist_owner
  after insert or update of checklist_id on app.checklist_items
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('checklist_id', 'app.checklists');

-- ---------------------------------------------------------------------------------------------------
-- app.checklist_runs — id = uuidv5(checklist_id || '|' || occurrence_key)
-- ---------------------------------------------------------------------------------------------------
create table if not exists app.checklist_runs (
  id                uuid primary key,
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        timestamptz not null,
  updated_at        timestamptz not null,
  deleted_at        timestamptz,
  rev               bigint not null,
  field_clock       jsonb not null default '{}'::jsonb,
  server_updated_at timestamptz not null,
  origin_device_id  uuid,
  checklist_id      uuid not null references app.checklists (id) deferrable initially deferred,
  occurrence_key    text not null,
  started_at        timestamptz not null,
  ended_at          timestamptz,
  total_items       int check (total_items >= 0),
  completed_items   int check (completed_items >= 0),
  snapshot          jsonb check (snapshot is null or jsonb_typeof(snapshot) = 'array'),
  constraint checklist_runs_checklist_id_occurrence_key_key unique (checklist_id, occurrence_key)
);

comment on table app.checklist_runs is
  'One run per reset period of a resettable checklist; snapshot = [{itemId, status, completedAt}].';

select app.enable_sync('app.checklist_runs');

create constraint trigger tg_checklist_runs_checklist_owner
  after insert or update of checklist_id on app.checklist_runs
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('checklist_id', 'app.checklists');
