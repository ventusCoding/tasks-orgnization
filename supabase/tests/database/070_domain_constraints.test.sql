-- Domain integrity: activity_events append-only, occurrence id check, checklist tree triggers,
-- soft-delete cascades, attachment paths, cross-user references, arch §7.3 CHECKs.
begin;
select plan(29);

select tests.create_user('dom@test.local', 'd1000000-0000-4000-8000-00000000000d');
select tests.create_user('dom2@test.local', 'd2000000-0000-4000-8000-00000000000d');
select tests.authenticate_as('d1000000-0000-4000-8000-00000000000d');

-- ---------------------------------------------------------------------------------------------------
-- activity_events: append-only
-- ---------------------------------------------------------------------------------------------------
insert into app.activity_events (id, entity_type, entity_id, event_type, payload, occurred_at)
values ('d1000000-0000-4000-8000-0000000000e1', 'task', gen_random_uuid(), 'created', '{"opId": "x", "cause": "user"}', now());
select throws_ok($$update app.activity_events set payload = '{"forged": true}' where id = 'd1000000-0000-4000-8000-0000000000e1'$$,
                 'DL004', null, 'activity_events payload cannot change');
select throws_ok($$update app.activity_events set event_type = 'deleted' where id = 'd1000000-0000-4000-8000-0000000000e1'$$,
                 'DL004', null, 'activity_events event_type cannot change');
select lives_ok($$update app.activity_events set deleted_at = now(), field_clock = '{"deleted_at": "x"}' where id = 'd1000000-0000-4000-8000-0000000000e1'$$,
                'activity_events may be tombstoned');

-- ---------------------------------------------------------------------------------------------------
-- task_occurrences: deterministic id
-- ---------------------------------------------------------------------------------------------------
insert into app.tasks (id, title, start_local, recurrence)
values ('d1000000-0000-4000-8000-0000000000f1', 'Daily', '2026-09-22 07:00', '{"v": 1, "type": "fixed"}');
select throws_ok($$insert into app.task_occurrences (id, task_id, occurrence_key)
                   values (gen_random_uuid(), 'd1000000-0000-4000-8000-0000000000f1', '2026-09-22T07:00')$$,
                 'DL005', null, 'occurrence id must be uuid_v5(task_id|occurrence_key)');
select lives_ok($$insert into app.task_occurrences (id, task_id, occurrence_key, status)
                  values (app.uuid_v5('d1000000-0000-4000-8000-0000000000f1|2026-09-22T07:00'),
                          'd1000000-0000-4000-8000-0000000000f1', '2026-09-22T07:00', 'done')$$,
                'the deterministic occurrence id is accepted');
select throws_ok($$update app.task_occurrences set occurrence_key = '2026-09-23T07:00'
                   where task_id = 'd1000000-0000-4000-8000-0000000000f1'$$,
                 'DL006', null, 'occurrence keys are immutable');
select throws_ok($$insert into app.task_occurrences (id, task_id, occurrence_key)
                   values (app.uuid_v5('d1000000-0000-4000-8000-0000000000f1|monday'), 'd1000000-0000-4000-8000-0000000000f1', 'monday')$$,
                 '23514', null, 'occurrence key format is checked');

-- ---------------------------------------------------------------------------------------------------
-- tasks CHECKs
-- ---------------------------------------------------------------------------------------------------
select throws_ok($$insert into app.tasks (id, title, recurrence) values (gen_random_uuid(), 'x', '{"v": 1}')$$,
                 '23514', null, 'unscheduled tasks cannot repeat');
select throws_ok($$insert into app.tasks (id, title, is_all_day, start_local, duration_minutes)
                   values (gen_random_uuid(), 'x', true, '2026-09-22 10:00', 1440)$$,
                 '23514', null, 'all-day tasks start at 00:00');
select throws_ok($$insert into app.tasks (id, title, time_zone) values (gen_random_uuid(), 'x', 'Mars/Base')$$,
                 '23514', null, 'time_zone must be an IANA zone');
select throws_ok($$insert into app.tasks (id, title) values (gen_random_uuid(), '')$$, '23514', null, 'title 1..300 chars');

-- ---------------------------------------------------------------------------------------------------
-- checklist tree integrity (deferred)
-- ---------------------------------------------------------------------------------------------------
insert into app.checklists (id, title, sort_key) values
  ('d1000000-0000-4000-8000-0000000000c1', 'A', 'a0'), ('d1000000-0000-4000-8000-0000000000c2', 'B', 'a1');
insert into app.checklist_items (id, checklist_id, parent_id, sort_key, text) values
  ('d1000000-0000-4000-8000-0000000000b1', 'd1000000-0000-4000-8000-0000000000c1', null, 'a0', 'root'),
  ('d1000000-0000-4000-8000-0000000000b2', 'd1000000-0000-4000-8000-0000000000c1', 'd1000000-0000-4000-8000-0000000000b1', 'a0', 'child'),
  ('d1000000-0000-4000-8000-0000000000b3', 'd1000000-0000-4000-8000-0000000000c1', 'd1000000-0000-4000-8000-0000000000b2', 'a0', 'grandchild');
set constraints all immediate;
set constraints all deferred;

select throws_ok($q$do $x$ begin
                   update app.checklist_items set parent_id = 'd1000000-0000-4000-8000-0000000000b3'
                    where id = 'd1000000-0000-4000-8000-0000000000b1';
                   set constraints all immediate;
                 end $x$ $q$, 'DL002', null, 'cycles are rejected (checklist_cycle)');
select throws_ok($q$do $x$ begin
                   update app.checklist_items set checklist_id = 'd1000000-0000-4000-8000-0000000000c2'
                    where id = 'd1000000-0000-4000-8000-0000000000b2';
                   set constraints all immediate;
                 end $x$ $q$, 'DL001', null, 'a parent in another checklist is rejected (checklist_parent_mismatch)');
select lives_ok($q$do $x$ begin
                  update app.checklist_items set checklist_id = 'd1000000-0000-4000-8000-0000000000c2'
                   where id = 'd1000000-0000-4000-8000-0000000000b3';
                  update app.checklist_items set checklist_id = 'd1000000-0000-4000-8000-0000000000c2'
                   where id = 'd1000000-0000-4000-8000-0000000000b2';
                  update app.checklist_items set checklist_id = 'd1000000-0000-4000-8000-0000000000c2'
                   where id = 'd1000000-0000-4000-8000-0000000000b1';
                  set constraints all immediate;
                end $x$ $q$, 'a subtree moved child-first commits');
select throws_ok($$update app.checklist_items set status = 'completed' where id = 'd1000000-0000-4000-8000-0000000000b1'$$,
                 '23514', null, 'completed_at is required iff status = completed');
select throws_ok($$insert into app.checklist_items (id, checklist_id, sort_key) values (gen_random_uuid(), 'd1000000-0000-4000-8000-0000000000c1', 'a-b')$$,
                 '23514', null, 'sort_key must use the fractional-index charset');

-- ---------------------------------------------------------------------------------------------------
-- Soft-delete cascades
-- ---------------------------------------------------------------------------------------------------
update app.checklist_items set status = 'completed', completed_at = now() where id = 'd1000000-0000-4000-8000-0000000000b3';
update app.checklists set deleted_at = now(), field_clock = field_clock || jsonb_build_object('deleted_at', tests.clock(now()))
 where id = 'd1000000-0000-4000-8000-0000000000c2';
select is((select count(*)::int from app.checklist_items where checklist_id = 'd1000000-0000-4000-8000-0000000000c2' and deleted_at is null), 0,
          'deleting a checklist tombstones its items');
select is((select field_clock ->> 'deleted_at' from app.checklist_items where id = 'd1000000-0000-4000-8000-0000000000b3'),
          tests.clock(now()), 'cascaded tombstones carry the parent''s delete clock');

insert into app.checklist_items (id, checklist_id, parent_id, sort_key, text) values
  ('d1000000-0000-4000-8000-0000000000b4', 'd1000000-0000-4000-8000-0000000000c1', null, 'a1', 'p'),
  ('d1000000-0000-4000-8000-0000000000b5', 'd1000000-0000-4000-8000-0000000000c1', 'd1000000-0000-4000-8000-0000000000b4', 'a0', 'c'),
  ('d1000000-0000-4000-8000-0000000000b6', 'd1000000-0000-4000-8000-0000000000c1', 'd1000000-0000-4000-8000-0000000000b5', 'a0', 'gc'),
  ('d1000000-0000-4000-8000-0000000000b7', 'd1000000-0000-4000-8000-0000000000c1', null, 'a2', 'sibling');
update app.checklist_items set deleted_at = now() where id = 'd1000000-0000-4000-8000-0000000000b4';
select is((select count(*)::int from app.checklist_items where id in ('d1000000-0000-4000-8000-0000000000b5', 'd1000000-0000-4000-8000-0000000000b6')
             and deleted_at is not null), 2, 'deleting an item tombstones all its descendants');
select ok((select deleted_at is null from app.checklist_items where id = 'd1000000-0000-4000-8000-0000000000b7'), 'siblings untouched');
update app.checklist_items set deleted_at = null where id = 'd1000000-0000-4000-8000-0000000000b4';
select ok((select deleted_at is not null from app.checklist_items where id = 'd1000000-0000-4000-8000-0000000000b5'),
          'restores are not cascaded (the client restores what was deleted together)');

insert into app.time_entries (id, task_id, started_at) values (gen_random_uuid(), 'd1000000-0000-4000-8000-0000000000f1', now());
update app.tasks set deleted_at = now() where id = 'd1000000-0000-4000-8000-0000000000f1';
select is((select count(*)::int from app.task_occurrences where task_id = 'd1000000-0000-4000-8000-0000000000f1' and deleted_at is null)
          + (select count(*)::int from app.time_entries where task_id = 'd1000000-0000-4000-8000-0000000000f1' and deleted_at is null),
          0, 'deleting a task tombstones its occurrences and time entries');

insert into app.habits (id, kind, name, start_date, sort_key) values ('d1000000-0000-4000-8000-0000000000a1', 'build', 'Walk', '2026-09-01', 'a0');
insert into app.habit_logs (id, habit_id, occurrence_key, kind, logged_at, local_date)
values (gen_random_uuid(), 'd1000000-0000-4000-8000-0000000000a1', '2026-09-22', 'done', now(), '2026-09-22');
update app.habits set deleted_at = now() where id = 'd1000000-0000-4000-8000-0000000000a1';
select is((select count(*)::int from app.habit_logs where habit_id = 'd1000000-0000-4000-8000-0000000000a1' and deleted_at is null), 0,
          'deleting a habit tombstones its logs');

-- ---------------------------------------------------------------------------------------------------
-- Habits CHECKs
-- ---------------------------------------------------------------------------------------------------
select throws_ok($$insert into app.habits (id, kind, name, start_date, sort_key, quit_mode) values (gen_random_uuid(), 'quit', 'Q', '2026-09-01', 'a0', 'abstain')$$,
                 '23514', null, 'a quit tracker needs quit_started_at');
select throws_ok($$insert into app.habits (id, kind, name, start_date, sort_key, goal_type, target_value) values (gen_random_uuid(), 'build', 'B', '2026-09-01', 'a0', 'count', 0)$$,
                 '23514', null, 'measurable build goals need a positive target');
select throws_ok($$insert into app.habit_logs (id, habit_id, occurrence_key, kind, logged_at, local_date)
                   values (gen_random_uuid(), 'd1000000-0000-4000-8000-0000000000a1', 'week:2026-W39#1', 'done', now(), '2026-09-22')$$,
                 '23514', null, 'habit logs never carry quota period keys');

-- ---------------------------------------------------------------------------------------------------
-- Attachments path + cross-user references
-- ---------------------------------------------------------------------------------------------------
select throws_ok($$insert into app.attachments (id, owner_type, owner_id, storage_path, file_name, mime_type, byte_size, sort_key)
                   values (gen_random_uuid(), 'task', gen_random_uuid(), 'd2000000-0000-4000-8000-00000000000d/x/f.jpg', 'f.jpg', 'image/jpeg', 1, 'a0')$$,
                 'DL007', null, 'attachment paths must start with the owner''s uid');

select tests.authenticate_as('d2000000-0000-4000-8000-00000000000d');
insert into app.habits (id, kind, name, start_date, sort_key) values ('d2000000-0000-4000-8000-0000000000a1', 'build', 'Other', '2026-09-01', 'a0');
select tests.authenticate_as('d1000000-0000-4000-8000-00000000000d');
select throws_ok($q$do $x$ begin
                   insert into app.habit_logs (id, habit_id, kind, logged_at, local_date)
                   values (gen_random_uuid(), 'd2000000-0000-4000-8000-0000000000a1', 'note', now(), '2026-09-22');
                   set constraints all immediate;
                 end $x$ $q$, 'DL003', null, 'a log cannot reference another user''s habit');
select throws_ok($$insert into app.notification_rules (id, target_type, target_id, section, spec, sort_key)
                   values (gen_random_uuid(), 'global', gen_random_uuid(), 'system', '{}', 'a0')$$,
                 '23514', null, 'global/section rules have no target_id');

select * from finish();
rollback;
