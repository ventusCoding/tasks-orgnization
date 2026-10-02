-- Siri / App Actions (T8.2.15): habit logs recorded by voice keep their own source.
alter table app.habit_logs drop constraint if exists habit_logs_source_check;
alter table app.habit_logs add constraint habit_logs_source_check
  check (source in ('manual', 'notification', 'widget', 'auto', 'import', 'voice'));
