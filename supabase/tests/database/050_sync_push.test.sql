-- T1.4.08 — app.sync_push: insert, per-field LWW, stale/partial, idempotent replay, clamp, allow-lists,
-- operation groups (atomic rejection on integrity violations), min build, revoked device.
begin;
select plan(40);

select tests.create_user('push@test.local', 'e1000000-0000-4000-8000-00000000000e');
select tests.authenticate_as('e1000000-0000-4000-8000-00000000000e');

create temporary table r (k text primary key, v jsonb) on commit drop;
grant all on r to authenticated;

-- ---------------------------------------------------------------------------------------------------
-- Insert
-- ---------------------------------------------------------------------------------------------------
insert into r values ('insert', tests.push(jsonb_build_array(
  tests.chg('i1', 'g1', 'tasks', 'insert', 'e1000000-0000-4000-8000-0000000000f1',
            '{"title": "Plan", "priority": 2, "start_local": "2026-09-22T09:00:00", "time_zone": "Europe/Paris"}',
            now() - interval '10 minutes'))));

select is((select v -> 'results' -> 0 ->> 'status' from r where k = 'insert'), 'applied', 'insert: applied');
select is((select v -> 'results' -> 0 ->> 'id' from r where k = 'insert'), 'i1', 'result carries the change id');
select is((select v -> 'results' -> 0 -> 'stale_fields' from r where k = 'insert'), '[]'::jsonb, 'no stale fields');
select ok((select (v -> 'results' -> 0 -> 'code') = 'null'::jsonb from r where k = 'insert'), 'code is null');
select is((select (v ->> 'head')::bigint from r where k = 'insert'), (select head_rev from app.sync_heads),
          'head = current sync head');
select is((select field_clock ->> 'title' from app.tasks where id = 'e1000000-0000-4000-8000-0000000000f1'),
          tests.clock(now() - interval '10 minutes'), 'insert: field_clock = clock map');
select is((select origin_device_id from app.tasks where id = 'e1000000-0000-4000-8000-0000000000f1'),
          'dddddddd-0000-4000-8000-00000000000a'::uuid, 'origin_device_id = pushing device');
select is((select series_id from app.tasks where id = 'e1000000-0000-4000-8000-0000000000f1'),
          'e1000000-0000-4000-8000-0000000000f1'::uuid, 'column defaults / triggers still apply (series_id = id)');

-- ---------------------------------------------------------------------------------------------------
-- Per-field LWW
-- ---------------------------------------------------------------------------------------------------
insert into r values ('newer', tests.push(jsonb_build_array(
  tests.chg('p1', 'g2', 'tasks', 'patch', 'e1000000-0000-4000-8000-0000000000f1', '{"title": "Plan v2"}',
            now() - interval '5 minutes', 'devB'))));
select is((select v -> 'results' -> 0 ->> 'status' from r where k = 'newer'), 'applied', 'newer clock: applied');
select is((select title from app.tasks where id = 'e1000000-0000-4000-8000-0000000000f1'), 'Plan v2', 'value updated');
select is((select field_clock ->> 'title' from app.tasks where id = 'e1000000-0000-4000-8000-0000000000f1'),
          tests.clock(now() - interval '5 minutes', 0, 'devB'), 'field clock advanced');

create temporary table h (n bigint) on commit drop;
grant all on h to authenticated;
insert into h select head_rev from app.sync_heads;

insert into r values ('older', tests.push(jsonb_build_array(
  tests.chg('p2', 'g3', 'tasks', 'patch', 'e1000000-0000-4000-8000-0000000000f1', '{"title": "old offline edit"}',
            now() - interval '8 minutes', 'devC'))));
select is((select v -> 'results' -> 0 ->> 'status' from r where k = 'older'), 'stale', 'older clock: stale');
select is((select v -> 'results' -> 0 -> 'stale_fields' from r where k = 'older'), '["title"]'::jsonb, 'stale_fields lists it');
select is((select title from app.tasks where id = 'e1000000-0000-4000-8000-0000000000f1'), 'Plan v2',
          'a stale field never overwrites a newer one');
select is((select head_rev from app.sync_heads), (select n from h), 'stale: no revision bump');

insert into r values ('partial', tests.push(jsonb_build_array(jsonb_build_object(
  'id', 'p3', 'g', 'g4', 't', 'tasks', 'op', 'patch', 'row_id', 'e1000000-0000-4000-8000-0000000000f1',
  'fields', jsonb_build_object('title', 'stale title', 'priority', 4),
  'clock', jsonb_build_object('title', tests.clock(now() - interval '9 minutes', 0, 'devC'),
                              'priority', tests.clock(now() - interval '1 minute', 0, 'devC'))))));
select is((select v -> 'results' -> 0 ->> 'status' from r where k = 'partial'), 'partial', 'mixed clocks: partial');
select is((select v -> 'results' -> 0 -> 'stale_fields' from r where k = 'partial'), '["title"]'::jsonb,
          'partial: only the stale field is reported');
select ok((select priority = 4 and title = 'Plan v2' from app.tasks where id = 'e1000000-0000-4000-8000-0000000000f1'),
          'partial: fresh field applied, stale field kept');

-- ---------------------------------------------------------------------------------------------------
-- Idempotent replay
-- ---------------------------------------------------------------------------------------------------
delete from h;
insert into h select head_rev from app.sync_heads;
insert into r values ('replay', tests.push(jsonb_build_array(
  tests.chg('p1', 'g2', 'tasks', 'patch', 'e1000000-0000-4000-8000-0000000000f1', '{"title": "Plan v2"}',
            now() - interval '5 minutes', 'devB'),
  tests.chg('i1', 'g1', 'tasks', 'insert', 'e1000000-0000-4000-8000-0000000000f1',
            '{"title": "Plan", "priority": 2, "start_local": "2026-09-22T09:00:00", "time_zone": "Europe/Paris"}',
            now() - interval '10 minutes'))));
select is((select array_agg(x ->> 'status' order by x ->> 'id') from r, jsonb_array_elements(v -> 'results') x where k = 'replay'),
          array['stale', 'stale'], 'replaying applied changes is a no-op (stale)');
select is((select head_rev from app.sync_heads), (select n from h), 'replay: no revision bump');

-- ---------------------------------------------------------------------------------------------------
-- Clamp (clocks > now() + 5 min)
-- ---------------------------------------------------------------------------------------------------
insert into r values ('clamp', tests.push(jsonb_build_array(
  tests.chg('c1', 'g5', 'tasks', 'patch', 'e1000000-0000-4000-8000-0000000000f1', '{"notes": "from the future"}',
            now() + interval '3 days', 'devF'))));
select is((select field_clock ->> 'notes' from app.tasks where id = 'e1000000-0000-4000-8000-0000000000f1'),
          tests.clock(now() + interval '5 minutes', 0, 'devF'), 'future clocks are clamped to now() + 5 min');
select is((select v -> 'results' -> 0 ->> 'status' from r where k = 'clamp'), 'applied', 'clamped change applied');

-- ---------------------------------------------------------------------------------------------------
-- Allow-lists and validation
-- ---------------------------------------------------------------------------------------------------
insert into r values ('allow', tests.push(jsonb_build_array(
  tests.chg('a1', 'ga1', 'secrets', 'insert', gen_random_uuid(), '{"x": 1}', now()),
  tests.chg('a2', 'ga2', 'tasks', 'patch', 'e1000000-0000-4000-8000-0000000000f1', '{"nope": 1}', now()),
  tests.chg('a3', 'ga3', 'tasks', 'patch', 'e1000000-0000-4000-8000-0000000000f1', '{"user_id": "e1000000-0000-4000-8000-00000000000e"}', now()),
  tests.chg('a4', 'ga4', 'tasks', 'patch', 'e1000000-0000-4000-8000-0000000000f1', '{"rev": 1}', now()),
  jsonb_build_object('id', 'a5', 'g', 'ga5', 't', 'tasks', 'op', 'patch', 'row_id', 'e1000000-0000-4000-8000-0000000000f1',
                     'fields', '{"title": "no clock"}'::jsonb, 'clock', '{}'::jsonb),
  tests.chg('a6', 'ga6', 'tasks', 'upsert', 'e1000000-0000-4000-8000-0000000000f1', '{"title": "x"}', now()))));
select is((select array_agg(x ->> 'code' order by x ->> 'id') from r, jsonb_array_elements(v -> 'results') x where k = 'allow'),
          array['unknown_table', 'unknown_column', 'forbidden_column', 'forbidden_column', 'invalid_clock', 'invalid_change'],
          'allow-lists: unknown table/column, server-managed columns, missing clock, bad op are rejected');
select ok((select bool_and(x ->> 'status' = 'rejected') from r, jsonb_array_elements(v -> 'results') x where k = 'allow'),
          '… all with status rejected');

insert into r values ('badvalue', tests.push(jsonb_build_array(
  tests.chg('b1', 'gb1', 'tasks', 'patch', 'e1000000-0000-4000-8000-0000000000f1', '{"priority": 9}', now()),
  tests.chg('b2', 'gb2', 'tasks', 'patch', 'e1000000-0000-4000-8000-0000000000f1', '{"priority": "high"}', now()))));
select is((select array_agg(x ->> 'code' order by x ->> 'id') from r, jsonb_array_elements(v -> 'results') x where k = 'badvalue'),
          array['integrity_refetch', 'invalid_value'], 'CHECK violation → integrity_refetch, bad cast → invalid_value');

-- ---------------------------------------------------------------------------------------------------
-- Operation groups
-- ---------------------------------------------------------------------------------------------------
select tests.push(jsonb_build_array(
  tests.chg('l1', 'gl', 'checklists', 'insert', 'e1000000-0000-4000-8000-0000000000c1', '{"title": "L1", "sort_key": "a0"}', now() - interval '1 hour'),
  tests.chg('l2', 'gl', 'checklists', 'insert', 'e1000000-0000-4000-8000-0000000000c2', '{"title": "L2", "sort_key": "a1"}', now() - interval '1 hour'),
  tests.chg('l3', 'gl', 'checklist_items', 'insert', 'e1000000-0000-4000-8000-0000000000b1',
            '{"checklist_id": "e1000000-0000-4000-8000-0000000000c1", "sort_key": "a0", "text": "root"}', now() - interval '1 hour'),
  tests.chg('l4', 'gl', 'checklist_items', 'insert', 'e1000000-0000-4000-8000-0000000000b2',
            '{"checklist_id": "e1000000-0000-4000-8000-0000000000c1", "parent_id": "e1000000-0000-4000-8000-0000000000b1", "sort_key": "a0", "text": "child"}', now() - interval '1 hour'),
  tests.chg('l5', 'gl', 'checklist_items', 'insert', 'e1000000-0000-4000-8000-0000000000b3',
            '{"checklist_id": "e1000000-0000-4000-8000-0000000000c1", "parent_id": "e1000000-0000-4000-8000-0000000000b2", "sort_key": "a0", "text": "grandchild"}', now() - interval '1 hour')));
select is((select count(*)::int from app.checklist_items where checklist_id = 'e1000000-0000-4000-8000-0000000000c1'), 3,
          'a group inserting a 3-level tree applies');

-- Cycle: root under its grandchild, in one group together with a valid rename.
insert into r values ('cycle', tests.push(jsonb_build_array(
  tests.chg('y1', 'gy', 'checklist_items', 'patch', 'e1000000-0000-4000-8000-0000000000b1', '{"text": "renamed"}', now() - interval '30 minutes'),
  tests.chg('y2', 'gy', 'checklist_items', 'patch', 'e1000000-0000-4000-8000-0000000000b1',
            '{"parent_id": "e1000000-0000-4000-8000-0000000000b3"}', now() - interval '30 minutes'),
  tests.chg('z1', 'gz', 'checklists', 'patch', 'e1000000-0000-4000-8000-0000000000c2', '{"title": "L2 renamed"}', now() - interval '30 minutes'))));
select is((select array_agg(x ->> 'status' || ':' || coalesce(x ->> 'code', '-') order by x ->> 'id') from r, jsonb_array_elements(v -> 'results') x where k = 'cycle'),
          array['rejected:integrity_refetch', 'rejected:integrity_refetch', 'applied:-'],
          'a cycle rejects every change of its group (integrity_refetch), other groups apply');
select ok((select x ->> 'message' like 'checklist_cycle%' from r, jsonb_array_elements(v -> 'results') x where k = 'cycle' and x ->> 'id' = 'y2'),
          'rejection message names the violated rule');
select ok((select parent_id is null and text = 'root' from app.checklist_items where id = 'e1000000-0000-4000-8000-0000000000b1'),
          'the rejected group left no partial change');
select is((select title from app.checklists where id = 'e1000000-0000-4000-8000-0000000000c2'), 'L2 renamed',
          'the independent group was applied');

-- Subtree move to another checklist, rows written child-first (deferred integrity).
insert into r values ('move', tests.push(jsonb_build_array(
  tests.chg('m3', 'gm', 'checklist_items', 'patch', 'e1000000-0000-4000-8000-0000000000b3', '{"checklist_id": "e1000000-0000-4000-8000-0000000000c2"}', now() - interval '20 minutes'),
  tests.chg('m2', 'gm', 'checklist_items', 'patch', 'e1000000-0000-4000-8000-0000000000b2', '{"checklist_id": "e1000000-0000-4000-8000-0000000000c2"}', now() - interval '20 minutes'),
  tests.chg('m1', 'gm', 'checklist_items', 'patch', 'e1000000-0000-4000-8000-0000000000b1', '{"checklist_id": "e1000000-0000-4000-8000-0000000000c2"}', now() - interval '20 minutes'))));
select ok((select bool_and(x ->> 'status' = 'applied') from r, jsonb_array_elements(v -> 'results') x where k = 'move'),
          'a subtree moved child-first in one group passes the deferred checks');

-- Moving only a child to another checklist breaks the tree → rejected.
insert into r values ('mismatch', tests.push(jsonb_build_array(
  tests.chg('n1', 'gn', 'checklist_items', 'patch', 'e1000000-0000-4000-8000-0000000000b3', '{"checklist_id": "e1000000-0000-4000-8000-0000000000c1"}', now() - interval '10 minutes'))));
select is((select v -> 'results' -> 0 ->> 'code' from r where k = 'mismatch'), 'integrity_refetch',
          'a parent in another checklist is rejected (checklist_parent_mismatch)');

-- A validation error inside a group: the offender gets its code, the others group_rejected, nothing applied.
insert into r values ('grpval', tests.push(jsonb_build_array(
  tests.chg('v1', 'gv', 'tags', 'insert', 'e1000000-0000-4000-8000-0000000000d1', '{"name": "t", "sort_key": "a0"}', now()),
  tests.chg('v2', 'gv', 'tags', 'patch', 'e1000000-0000-4000-8000-0000000000d1', '{"colour": 1}', now()))));
select is((select array_agg(x ->> 'code' order by x ->> 'id') from r, jsonb_array_elements(v -> 'results') x where k = 'grpval'),
          array['group_rejected', 'unknown_column'], 'group validation: offender code + group_rejected');
select is((select count(*)::int from app.tags where id = 'e1000000-0000-4000-8000-0000000000d1'), 0,
          'group validation: earlier change of the group rolled back');

-- ---------------------------------------------------------------------------------------------------
-- Misc
-- ---------------------------------------------------------------------------------------------------
insert into r values ('patchmissing', tests.push(jsonb_build_array(
  tests.chg('q1', 'gq', 'tags', 'patch', 'e1000000-0000-4000-8000-0000000000d2', '{"name": "created by patch", "sort_key": "a0"}', now()))));
select is((select v -> 'results' -> 0 ->> 'status' from r where k = 'patchmissing'), 'applied',
          'a patch for a row the server does not have inserts it');

insert into r values ('order', tests.push(jsonb_build_array(
  tests.chg('o3', 'go3', 'tags', 'patch', 'e1000000-0000-4000-8000-0000000000d2', '{"name": "n3"}', now()),
  tests.chg('o1', 'go1', 'tags', 'patch', 'e1000000-0000-4000-8000-0000000000d2', '{"name": "n1"}', now() + interval '1 second'),
  tests.chg('o2', 'go3', 'tags', 'patch', 'e1000000-0000-4000-8000-0000000000d2', '{"color": 5}', now()))));
select is((select array_agg(x ->> 'id') from r, jsonb_array_elements(v -> 'results') x where k = 'order'),
          array['o3', 'o1', 'o2'], 'results keep the input order');

select throws_ok($$select app.sync_push('dddddddd-0000-4000-8000-00000000000a', 1, 0, '[]')$$, 'PGRST', null,
                 'builds below min_supported_build are refused (unsupported_client)');
select throws_ok(format('select app.sync_push(%L, 1, 1000, %L)', 'dddddddd-0000-4000-8000-00000000000a',
                        (select jsonb_agg(tests.chg('t' || i, 'g' || i, 'tags', 'patch', gen_random_uuid(), '{"name": "x"}', now()))
                         from generate_series(1, 501) i)),
                 'PGRST', null, 'more than 500 changes are refused');
select app.register_device('dddddddd-0000-4000-8000-0000000000ff', 'ios', 'iPhone', '26', '1.0', 1, 'en', 'UTC');
select app.revoke_device('dddddddd-0000-4000-8000-0000000000ff');
select throws_ok($$select app.sync_push('dddddddd-0000-4000-8000-0000000000ff', 1, 1000, '[]')$$, 'PGRST', null,
                 'a revoked device cannot push');
select tests.clear_authentication();
select throws_ok($$select app.sync_push(null, 1, 1000, '[]')$$, '28000', null, 'sync_push requires a user');

select * from finish();
rollback;
