-- =====================================================================================================
-- Local development seed (T1.2.10) — applied by `supabase db reset` (never on cloud projects).
--
--   test1@everslot.local / password123   (user 1, with sample data)
--   test2@everslot.local / password123   (user 2, empty — for isolation checks)
--
-- The auth.users insert fires private.tg_handle_new_user → app.profiles + app.sync_heads.
-- Sample rows are written as the `postgres` role, so the sync trigger keeps the supplied user_id and
-- assigns revisions exactly as for client writes.
-- =====================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- Users
-- ---------------------------------------------------------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  email_change_token_current, phone_change, phone_change_token, reauthentication_token, is_anonymous)
values
  ('00000000-0000-0000-0000-000000000000', '11111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated',
   'test1@everslot.local', extensions.crypt('password123', extensions.gen_salt('bf')), now(),
   '{"provider": "email", "providers": ["email"]}', '{"display_name": "Test One", "time_zone": "Europe/Paris", "locale": "en"}',
   now(), now(), '', '', '', '', '', '', '', '', false),
  ('00000000-0000-0000-0000-000000000000', '22222222-2222-4222-8222-222222222222', 'authenticated', 'authenticated',
   'test2@everslot.local', extensions.crypt('password123', extensions.gen_salt('bf')), now(),
   '{"provider": "email", "providers": ["email"]}', '{"display_name": "Test Two", "time_zone": "Africa/Tunis", "locale": "fr"}',
   now(), now(), '', '', '', '', '', '', '', '', false)
on conflict (id) do nothing;

insert into auth.identities (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
values
  ('11111111-1111-4111-8111-111111111111', '11111111-1111-4111-8111-111111111111', '11111111-1111-4111-8111-111111111111',
   '{"sub": "11111111-1111-4111-8111-111111111111", "email": "test1@everslot.local", "email_verified": true}',
   'email', now(), now(), now()),
  ('22222222-2222-4222-8222-222222222222', '22222222-2222-4222-8222-222222222222', '22222222-2222-4222-8222-222222222222',
   '{"sub": "22222222-2222-4222-8222-222222222222", "email": "test2@everslot.local", "email_verified": true}',
   'email', now(), now(), now())
on conflict do nothing;

-- ---------------------------------------------------------------------------------------------------
-- Sample data for user 1 (clocks = HLC of the seed instant, so any client edit wins)
-- ---------------------------------------------------------------------------------------------------
do $$
declare
  u      constant uuid := '11111111-1111-4111-8111-111111111111';
  clk    constant text := app.hlc_at(now(), 0, 'seed');
  cat_w  constant uuid := app.uuid_v5(u::text || '|default-category|work');
  cat_p  constant uuid := app.uuid_v5(u::text || '|default-category|personal');
  cat_h  constant uuid := app.uuid_v5(u::text || '|default-category|health');
  t_gym  constant uuid := '0199a000-0000-7000-8000-000000000001';
  t_rep  constant uuid := '0199a000-0000-7000-8000-000000000002';
  t_bl   constant uuid := '0199a000-0000-7000-8000-000000000003';
  cl     constant uuid := '0199a000-0000-7000-8000-000000000010';
  i1     constant uuid := '0199a000-0000-7000-8000-000000000011';
  i2     constant uuid := '0199a000-0000-7000-8000-000000000012';
  i3     constant uuid := '0199a000-0000-7000-8000-000000000013';
  i4     constant uuid := '0199a000-0000-7000-8000-000000000014';
  sec    constant uuid := app.uuid_v5(u::text || '|habit_section|morning');
  h_read constant uuid := '0199a000-0000-7000-8000-000000000020';
  h_quit constant uuid := '0199a000-0000-7000-8000-000000000021';
  today  constant date := (now() at time zone 'Europe/Paris')::date;
begin
  insert into app.user_settings (id, user_id, created_at, updated_at, field_clock, namespace, value) values
    (app.uuid_v5(u::text || '|notifications'), u, now(), now(), jsonb_build_object('value', clk), 'notifications',
     '{"v": 1, "multiDevicePolicy": "all", "latenessMinutes": 30, "maxNagRepeats": 5, "dateOnlyDefaultTime": "09:00"}'),
    (app.uuid_v5(u::text || '|planner'), u, now(), now(), jsonb_build_object('value', clk), 'planner',
     '{"v": 1, "defaultTaskDurationMinutes": 30, "missedGraceMinutes": 60, "rollOverIncomplete": true}')
  on conflict (id) do nothing;

  insert into app.categories (id, user_id, created_at, updated_at, field_clock, name, color, icon, sort_key) values
    (cat_w, u, now(), now(), jsonb_build_object('name', clk, 'color', clk, 'sort_key', clk), 'Work', -14575885, 'work', 'a0'),
    (cat_p, u, now(), now(), jsonb_build_object('name', clk, 'color', clk, 'sort_key', clk), 'Personal', -16738680, 'person', 'a1'),
    (cat_h, u, now(), now(), jsonb_build_object('name', clk, 'color', clk, 'sort_key', clk), 'Health', -1499549, 'favorite', 'a2')
  on conflict (id) do nothing;

  insert into app.tasks (id, user_id, created_at, updated_at, field_clock, series_id, title, category_id, priority,
                         start_local, duration_minutes, time_zone, recurrence, tracking_mode) values
    (t_gym, u, now(), now(), jsonb_build_object('title', clk, 'start_local', clk, 'recurrence', clk), t_gym, 'Gym', cat_h, 2,
     (today::timestamp + time '07:00'), 60, 'Europe/Paris',
     '{"v": 1, "type": "fixed", "freq": "weekly", "interval": 1, "byWeekday": ["MO", "WE", "FR"]}', 'check'),
    (t_rep, u, now(), now(), jsonb_build_object('title', clk, 'start_local', clk), t_rep, 'Write weekly report', cat_w, 3,
     (today::timestamp + time '14:00'), 90, 'Europe/Paris', null, 'timer')
  on conflict (id) do nothing;

  insert into app.tasks (id, user_id, created_at, updated_at, field_clock, series_id, title, category_id, manual_sort_key) values
    (t_bl, u, now(), now(), jsonb_build_object('title', clk), t_bl, 'Book dentist appointment', cat_p, 'a0')
  on conflict (id) do nothing;

  insert into app.task_occurrences (id, user_id, created_at, updated_at, field_clock, task_id, occurrence_key, status,
                                    status_changed_at, completed_at) values
    (app.uuid_v5(t_gym::text || '|' || to_char(today, 'YYYY-MM-DD') || 'T07:00'), u, now(), now(),
     jsonb_build_object('status', clk), t_gym, to_char(today, 'YYYY-MM-DD') || 'T07:00', 'done', now(), now())
  on conflict (id) do nothing;

  insert into app.checklists (id, user_id, created_at, updated_at, field_clock, title, category_id, is_pinned, sort_key) values
    (cl, u, now(), now(), jsonb_build_object('title', clk), 'Trip to Tunis', cat_p, true, 'a0')
  on conflict (id) do nothing;

  insert into app.checklist_items (id, user_id, created_at, updated_at, field_clock, checklist_id, parent_id, sort_key,
                                   text, status, status_note, completed_at) values
    (i1, u, now(), now(), jsonb_build_object('text', clk), cl, null, 'a0', 'Documents', 'ongoing', null, null),
    (i2, u, now(), now(), jsonb_build_object('text', clk), cl, i1, 'a0', 'Passport', 'completed', null, now()),
    (i3, u, now(), now(), jsonb_build_object('text', clk), cl, i1, 'a1', 'Visa appointment', 'waiting', 'Embassy email', null),
    (i4, u, now(), now(), jsonb_build_object('text', clk), cl, null, 'a1', 'Book flights', 'todo', null, null)
  on conflict (id) do nothing;

  insert into app.habit_sections (id, user_id, created_at, updated_at, field_clock, name, sort_key, start_time, end_time) values
    (sec, u, now(), now(), jsonb_build_object('name', clk), 'Morning', 'a0', '05:00', '12:00')
  on conflict (id) do nothing;

  insert into app.habits (id, user_id, created_at, updated_at, field_clock, kind, name, goal_type, target_value, target_op,
                          unit, schedule, start_date, time_zone, section_id, sort_key) values
    (h_read, u, now(), now(), jsonb_build_object('name', clk), 'build', 'Read', 'duration', 30, 'gte', 'min',
     '{"v": 1, "type": "fixed", "freq": "daily", "interval": 1}', today - 14, 'Europe/Paris', sec, 'a0')
  on conflict (id) do nothing;

  insert into app.habits (id, user_id, created_at, updated_at, field_clock, kind, name, quit_mode, quit_substance,
                          quit_started_at, baseline_per_day, unit_cost, currency, start_date, sort_key) values
    (h_quit, u, now(), now(), jsonb_build_object('name', clk), 'quit', 'No cigarettes', 'abstain', 'cigarettes',
     now() - interval '10 days', 12, 0.55, 'EUR', today - 10, 'a1')
  on conflict (id) do nothing;

  insert into app.habit_logs (id, user_id, created_at, updated_at, field_clock, habit_id, occurrence_key, kind, value,
                              logged_at, local_date, source) values
    ('0199a000-0000-7000-8000-000000000030', u, now(), now(), jsonb_build_object('value', clk), h_read,
     to_char(today - 1, 'YYYY-MM-DD'), 'progress', 35, now() - interval '1 day', today - 1, 'manual'),
    ('0199a000-0000-7000-8000-000000000031', u, now(), now(), jsonb_build_object('kind', clk), h_quit,
     null, 'craving', null, now() - interval '2 hours', today, 'manual')
  on conflict (id) do nothing;

  update app.habit_logs set intensity = 6, resisted = true where id = '0199a000-0000-7000-8000-000000000031';

  insert into app.notification_profiles (id, user_id, created_at, updated_at, field_clock, code, name, is_builtin, spec, sort_key) values
    (app.uuid_v5(u::text || '|profile|standard'), u, now(), now(), jsonb_build_object('spec', clk), 'standard', 'Standard', true,
     '{"v": 1, "delivery": {"system": true, "inbox": true, "importance": "default"}}', 'a1'),
    (app.uuid_v5(u::text || '|profile|nag'), u, now(), now(), jsonb_build_object('spec', clk), 'nag', 'Nag until done', true,
     '{"v": 1, "repeat": {"everyMinutes": 5, "maxTimes": 6, "until": "completed"}, "delivery": {"importance": "high"}}', 'a2')
  on conflict (id) do nothing;

  insert into app.notification_rules (id, user_id, created_at, updated_at, field_clock, target_type, target_id, section,
                                      profile_id, spec, sort_key) values
    ('0199a000-0000-7000-8000-000000000040', u, now(), now(), jsonb_build_object('spec', clk), 'task', t_gym, 'planner',
     app.uuid_v5(u::text || '|profile|standard'),
     '{"v": 1, "trigger": {"type": "relative", "anchor": "start", "offsetMinutes": -10}, "content": {"title": "{title}"}}', 'a0')
  on conflict (id) do nothing;
end
$$;

-- ---------------------------------------------------------------------------------------------------
-- Optional: let pg_cron call the locally served Edge Functions (push-dispatch every 30 s, sync-nudge).
-- Off by default so a plain local stack stays quiet. From inside the db container the API gateway is
-- reachable as http://kong:8000. Use the same CRON_SECRET in supabase/functions/.env.
-- ---------------------------------------------------------------------------------------------------
-- select vault.create_secret('http://kong:8000/functions/v1', 'functions_base_url');
-- select vault.create_secret('<LOCAL_CRON_SECRET>', 'cron_secret');
