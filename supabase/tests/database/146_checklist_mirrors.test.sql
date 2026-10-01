-- Checklist item mirrors (T4.5.16): column, same-owner link and the no-mirror-in-own-subtree guard.
begin;
select plan(7);

select tests.create_user('mira@test.local', 'e6000000-0000-4000-8000-0000000000a1');
select tests.create_user('mirb@test.local', 'e6000000-0000-4000-8000-0000000000b1');

select tests.authenticate_as('e6000000-0000-4000-8000-0000000000a1');
insert into app.checklists (id, title, sort_key) values
  ('e6000000-0000-4000-8000-00000000c001', 'Home', 'a0'),
  ('e6000000-0000-4000-8000-00000000c002', 'Today', 'a1');
-- Home: O (original) > K (child)
insert into app.checklist_items (id, checklist_id, parent_id, sort_key, text) values
  ('e6000000-0000-4000-8000-00000000c101', 'e6000000-0000-4000-8000-00000000c001', null, 'a0', 'Groceries'),
  ('e6000000-0000-4000-8000-00000000c102', 'e6000000-0000-4000-8000-00000000c001', 'e6000000-0000-4000-8000-00000000c101', 'a0', 'Milk');

select has_column('app', 'checklist_items', 'mirror_of_id', 'checklist_items.mirror_of_id exists');

select lives_ok($q$do $x$ begin
                  insert into app.checklist_items (id, checklist_id, sort_key, text, mirror_of_id)
                    values ('e6000000-0000-4000-8000-00000000c201', 'e6000000-0000-4000-8000-00000000c002', 'a0', 'Groceries',
                            'e6000000-0000-4000-8000-00000000c101');
                  set constraints all immediate;
                end $x$ $q$, 'a mirror in another list');

select lives_ok($q$do $x$ begin
                  insert into app.checklist_items (id, checklist_id, sort_key, text, mirror_of_id)
                    values ('e6000000-0000-4000-8000-00000000c202', 'e6000000-0000-4000-8000-00000000c001', 'b0', 'Groceries',
                            'e6000000-0000-4000-8000-00000000c101');
                  set constraints all immediate;
                end $x$ $q$, 'a mirror next to its original in the same list');

select throws_ok($q$do $x$ begin
                   insert into app.checklist_items (id, checklist_id, parent_id, sort_key, text, mirror_of_id)
                     values (gen_random_uuid(), 'e6000000-0000-4000-8000-00000000c001', 'e6000000-0000-4000-8000-00000000c102', 'a0', 'Loop',
                             'e6000000-0000-4000-8000-00000000c101');
                   set constraints all immediate;
                 end $x$ $q$, 'DL003', null, 'a mirror cannot be created inside its original''s subtree');

select throws_ok($q$do $x$ begin
                   update app.checklist_items set parent_id = 'e6000000-0000-4000-8000-00000000c101'
                     where id = 'e6000000-0000-4000-8000-00000000c202';
                   set constraints all immediate;
                 end $x$ $q$, 'DL003', null, 'a mirror cannot be moved under its original');

select throws_ok($q$do $x$ begin
                   update app.checklist_items set mirror_of_id = id where id = 'e6000000-0000-4000-8000-00000000c102';
                   set constraints all immediate;
                 end $x$ $q$, 'DL003', null, 'an item cannot mirror itself');

select tests.authenticate_as('e6000000-0000-4000-8000-0000000000b1');
insert into app.checklists (id, title, sort_key) values ('e6000000-0000-4000-8000-00000000c003', 'Mine', 'a0');
select throws_ok($q$do $x$ begin
                   insert into app.checklist_items (id, checklist_id, sort_key, text, mirror_of_id)
                     values (gen_random_uuid(), 'e6000000-0000-4000-8000-00000000c003', 'a0', 'Steal',
                             'e6000000-0000-4000-8000-00000000c101');
                   set constraints all immediate;
                 end $x$ $q$, null, null, 'a mirror cannot point at another user''s item');

select * from finish();
rollback;
