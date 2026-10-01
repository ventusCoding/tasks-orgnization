-- Live item mirrors (T4.5.16, arch §7.4): a mirror row shows and edits its original (text, status,
-- children); its own text is a snapshot used when the original is gone. Additive column, covered by
-- the sync triggers of app.enable_sync.

alter table app.checklist_items add column if not exists mirror_of_id uuid;

comment on column app.checklist_items.mirror_of_id is 'Original item this row mirrors (T4.5.16); null for ordinary items.';

alter table app.checklist_items
  add constraint checklist_items_mirror_of_id_fkey
  foreign key (mirror_of_id) references app.checklist_items (id) deferrable initially deferred;

create constraint trigger tg_checklist_items_mirror_owner
  after insert or update of mirror_of_id on app.checklist_items
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('mirror_of_id', 'app.checklist_items');

create index if not exists checklist_items_mirror_of_id_idx
  on app.checklist_items (mirror_of_id) where mirror_of_id is not null;

create or replace function app.tg_checklist_items_mirror_check()
returns trigger
language plpgsql
security definer                   -- reads ancestors regardless of RLS (same user anyway)
set search_path = ''
as $$
declare
  v_bad record;
begin
  -- Deferred check of the row as it is now: no live mirror in its subtree (itself included) may
  -- have its original among its ancestors (or be its own original). Rendering such a mirror
  -- would repeat the original's subtree inside itself forever.
  with recursive sub (id, depth) as (
    select i.id, 0 from app.checklist_items i where i.id = new.id
    union all
    select c.id, s.depth + 1
    from app.checklist_items c
    join sub s on c.parent_id = s.id
    where s.depth < 10000
  ),
  mirrors as (
    select i.id, i.mirror_of_id
    from app.checklist_items i
    join sub s on s.id = i.id
    where i.mirror_of_id is not null and i.deleted_at is null
  ),
  ancestors (mirror_id, original_id, id, depth) as (
    select m.id, m.mirror_of_id, m.id, 0 from mirrors m
    union all
    select a.mirror_id, a.original_id, p.parent_id, a.depth + 1
    from ancestors a
    join app.checklist_items p on p.id = a.id
    where p.parent_id is not null and a.depth < 10000
  )
  select a.mirror_id, a.original_id into v_bad
  from ancestors a
  where a.id = a.original_id
  limit 1;

  if found then
    raise exception 'checklist_mirror_cycle: mirror % is inside the subtree of its original %',
      v_bad.mirror_id, v_bad.original_id
      using errcode = 'DL003';
  end if;
  return null;
end
$$;

comment on function app.tg_checklist_items_mirror_check() is
  'Deferred integrity: a mirror never sits inside its original''s subtree (DL003).';

create constraint trigger tg_checklist_items_mirror_check
  after insert or update of parent_id, mirror_of_id on app.checklist_items
  deferrable initially deferred
  for each row execute function app.tg_checklist_items_mirror_check();
