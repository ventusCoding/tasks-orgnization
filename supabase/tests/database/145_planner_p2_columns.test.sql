-- Planner P2 columns (T3.1.21, T3.7.07, T3.7.11–T3.7.13): shapes and the same-owner link.
begin;
select plan(9);

select tests.create_user('p2a@test.local', 'e5000000-0000-4000-8000-0000000000a1');
select tests.create_user('p2b@test.local', 'e5000000-0000-4000-8000-0000000000b1');

select tests.authenticate_as('e5000000-0000-4000-8000-0000000000a1');
insert into app.checklists (id, title, sort_key) values ('e5000000-0000-4000-8000-00000000c001', 'Home', 'a0');
insert into app.checklist_items (id, checklist_id, sort_key, text, estimate_minutes)
  values ('e5000000-0000-4000-8000-00000000c101', 'e5000000-0000-4000-8000-00000000c001', 'a0', 'Fix tap', 30);

select lives_ok($$insert into app.tasks (id, title, linked_item_id, horizon_key, countdown_mode, location_lat, location_lng)
                  values ('e5000000-0000-4000-8000-00000000d001', 'Fix the tap', 'e5000000-0000-4000-8000-00000000c101',
                          'week:2026-09-21', 'until', 48.85, 2.35)$$,
                'a task can link its own item, carry a horizon, a countdown and coordinates');
select throws_ok($$insert into app.tasks (id, title, horizon_key) values (gen_random_uuid(), 'x', 'week:soon')$$,
                 '23514', null, 'horizon keys follow the period formats');
select lives_ok($$insert into app.tasks (id, title, horizon_key) values (gen_random_uuid(), 'q', 'quarter:2026-Q4')$$,
                'quarter horizons are valid');
select throws_ok($$insert into app.tasks (id, title, countdown_mode) values (gen_random_uuid(), 'x', 'later')$$,
                 '23514', null, 'countdown mode is until or since');
select throws_ok($$insert into app.tasks (id, title, location_lat) values (gen_random_uuid(), 'x', 10)$$,
                 '23514', null, 'coordinates come in pairs');
select throws_ok($$insert into app.tasks (id, title, location_lat, location_lng) values (gen_random_uuid(), 'x', 91, 0)$$,
                 '23514', null, 'latitude is within ±90');
select throws_ok($$update app.checklist_items set estimate_minutes = -5 where id = 'e5000000-0000-4000-8000-00000000c101'$$,
                 '23514', null, 'step estimates are not negative');
select is((select estimate_minutes from app.checklist_items where id = 'e5000000-0000-4000-8000-00000000c101'), 30,
          'step estimate stored');

select tests.authenticate_as('e5000000-0000-4000-8000-0000000000b1');
select throws_ok($q$do $x$ begin
                   insert into app.tasks (id, title, linked_item_id)
                     values (gen_random_uuid(), 'steal', 'e5000000-0000-4000-8000-00000000c101');
                   set constraints all immediate;
                 end $x$ $q$, null, null, 'a task cannot link another user''s item');

select * from finish();
rollback;
