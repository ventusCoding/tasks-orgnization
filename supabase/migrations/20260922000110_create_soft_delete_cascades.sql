-- =====================================================================================================
-- Server-side soft-delete cascades (arch §6.6, §9.3): tombstoning a parent tombstones its descendants
-- in the same transaction, even if a client forgot to send the child patches:
--   checklist      → its items (+ attachments owned by the checklist)
--   checklist item → its descendants (+ their attachments)
--   task           → its occurrences and time entries (+ attachments)
--   habit          → its logs (+ attachments)
-- The children's deleted_at clock is the parent's delete clock, so a later restore (newer clock) wins.
-- Restores are never cascaded (the client restores what was deleted in the same operation, T8.3.06).
-- =====================================================================================================

create or replace function app.tg_cascade_soft_delete()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_clock  text := new.field_clock ->> 'deleted_at';
  v_patch  jsonb := case when new.field_clock ? 'deleted_at'
                         then jsonb_build_object('deleted_at', new.field_clock -> 'deleted_at')
                         else '{}'::jsonb end;
  v_owners uuid[];
begin
  if old.deleted_at is not null or new.deleted_at is null then
    return null;                                           -- not a live → tombstone transition
  end if;

  if tg_table_name = 'checklists' then
    update app.checklist_items i
       set deleted_at = new.deleted_at, field_clock = i.field_clock || v_patch, origin_device_id = new.origin_device_id
     where i.checklist_id = new.id and i.deleted_at is null
       and (v_clock is null or coalesce(i.field_clock ->> 'deleted_at', '') collate "C" <= v_clock collate "C");
    update app.attachments a
       set deleted_at = new.deleted_at, field_clock = a.field_clock || v_patch, origin_device_id = new.origin_device_id
     where a.owner_type = 'checklist' and a.owner_id = new.id and a.deleted_at is null;

  elsif tg_table_name = 'checklist_items' then
    with recursive descendants (id) as (
      select c.id from app.checklist_items c where c.parent_id = new.id and c.deleted_at is null
      union
      select c.id from app.checklist_items c join descendants d on c.parent_id = d.id where c.deleted_at is null
    )
    select array_agg(id) into v_owners from descendants;

    if v_owners is not null then
      update app.checklist_items i
         set deleted_at = new.deleted_at, field_clock = i.field_clock || v_patch, origin_device_id = new.origin_device_id
       where i.id = any (v_owners) and i.deleted_at is null
         and (v_clock is null or coalesce(i.field_clock ->> 'deleted_at', '') collate "C" <= v_clock collate "C");
    end if;
    update app.attachments a
       set deleted_at = new.deleted_at, field_clock = a.field_clock || v_patch, origin_device_id = new.origin_device_id
     where a.owner_type = 'checklist_item' and a.owner_id = any (array_append(coalesce(v_owners, '{}'), new.id))
       and a.deleted_at is null;

  elsif tg_table_name = 'tasks' then
    update app.task_occurrences o
       set deleted_at = new.deleted_at, field_clock = o.field_clock || v_patch, origin_device_id = new.origin_device_id
     where o.task_id = new.id and o.deleted_at is null
       and (v_clock is null or coalesce(o.field_clock ->> 'deleted_at', '') collate "C" <= v_clock collate "C");
    update app.time_entries t
       set deleted_at = new.deleted_at, field_clock = t.field_clock || v_patch, origin_device_id = new.origin_device_id
     where t.task_id = new.id and t.deleted_at is null
       and (v_clock is null or coalesce(t.field_clock ->> 'deleted_at', '') collate "C" <= v_clock collate "C");
    update app.attachments a
       set deleted_at = new.deleted_at, field_clock = a.field_clock || v_patch, origin_device_id = new.origin_device_id
     where a.owner_type = 'task' and a.owner_id = new.id and a.deleted_at is null;

  elsif tg_table_name = 'habits' then
    update app.habit_logs l
       set deleted_at = new.deleted_at, field_clock = l.field_clock || v_patch, origin_device_id = new.origin_device_id
     where l.habit_id = new.id and l.deleted_at is null
       and (v_clock is null or coalesce(l.field_clock ->> 'deleted_at', '') collate "C" <= v_clock collate "C");
    update app.attachments a
       set deleted_at = new.deleted_at, field_clock = a.field_clock || v_patch, origin_device_id = new.origin_device_id
     where a.owner_type = 'habit' and a.owner_id = new.id and a.deleted_at is null;
  end if;

  return null;
end
$$;

comment on function app.tg_cascade_soft_delete() is
  'AFTER UPDATE OF deleted_at: tombstones descendants (items, occurrences, time entries, logs, attachments).';

create trigger tg_cascade_soft_delete
  after update of deleted_at on app.checklists
  for each row execute function app.tg_cascade_soft_delete();

create trigger tg_cascade_soft_delete
  after update of deleted_at on app.checklist_items
  for each row execute function app.tg_cascade_soft_delete();

create trigger tg_cascade_soft_delete
  after update of deleted_at on app.tasks
  for each row execute function app.tg_cascade_soft_delete();

create trigger tg_cascade_soft_delete
  after update of deleted_at on app.habits
  for each row execute function app.tg_cascade_soft_delete();
