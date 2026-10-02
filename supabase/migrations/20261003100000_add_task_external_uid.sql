-- ICS import (T8.2.12): tasks remember the UID of the calendar event they came from, so a second
-- import of the same file updates instead of duplicating. Additive: the sync triggers of
-- app.enable_sync cover new columns (per-field clocks are keyed by column name).

alter table app.tasks add column if not exists external_uid text
  check (external_uid is null or (length(external_uid) between 1 and 255));

comment on column app.tasks.external_uid is 'UID of the imported calendar event (ICS VEVENT UID, T8.2.12).';

create index if not exists tasks_user_external_uid_idx
  on app.tasks (user_id, external_uid) where external_uid is not null;
