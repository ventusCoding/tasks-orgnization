-- Planner P2 columns (arch §7.3): scheduled checklist items (T3.1.21), horizons (T3.7.11),
-- countdowns (T3.7.12), map pins (T3.7.13) and routine step durations (T3.7.07). Additive: the
-- sync triggers of app.enable_sync cover new columns (per-field clocks are keyed by column name).

alter table app.tasks add column if not exists linked_item_id uuid;
alter table app.tasks add column if not exists horizon_key text
  check (horizon_key is null or horizon_key ~ '^(day:\d{4}-\d{2}-\d{2}|week:\d{4}-\d{2}-\d{2}|month:\d{4}-\d{2}|quarter:\d{4}-Q[1-4]|year:\d{4})$');
alter table app.tasks add column if not exists countdown_mode text check (countdown_mode in ('until', 'since'));
alter table app.tasks add column if not exists location_lat double precision check (location_lat between -90 and 90);
alter table app.tasks add column if not exists location_lng double precision check (location_lng between -180 and 180);
alter table app.tasks add constraint tasks_location_pair check ((location_lat is null) = (location_lng is null));

comment on column app.tasks.linked_item_id is 'Checklist item this task schedules (T3.1.21).';
comment on column app.tasks.horizon_key is 'Horizon of an unscheduled intention: day:/week:/month:/quarter:/year: key (T3.7.11).';
comment on column app.tasks.countdown_mode is 'Shown in the countdown list: until (upcoming) or since (past) (T3.7.12).';

alter table app.tasks
  add constraint tasks_linked_item_id_fkey
  foreign key (linked_item_id) references app.checklist_items (id) deferrable initially deferred;

create constraint trigger tg_tasks_linked_item_owner
  after insert or update of linked_item_id on app.tasks
  deferrable initially deferred
  for each row execute function app.tg_check_same_owner('linked_item_id', 'app.checklist_items');

create index if not exists tasks_linked_item_id_idx on app.tasks (linked_item_id) where linked_item_id is not null;

alter table app.checklist_items add column if not exists estimate_minutes integer
  check (estimate_minutes between 0 and 1440);

comment on column app.checklist_items.estimate_minutes is 'Step duration for the routine player (T3.7.07).';
