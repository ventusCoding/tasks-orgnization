-- arch §7.4 / T9.1.06 — cross-user isolation: user B can never read or write user A's rows, devices,
-- sync head, Broadcast channel or storage objects.
begin;
select plan(23);

select tests.create_user('iso-a@test.local', 'a1000000-0000-4000-8000-00000000000a');
select tests.create_user('iso-b@test.local', 'b1000000-0000-4000-8000-00000000000b');

-- A's data (through the real write path).
select tests.authenticate_as('a1000000-0000-4000-8000-00000000000a');
select tests.push(jsonb_build_array(
  tests.chg('c1', 'g1', 'categories', 'insert', 'a1000000-0000-4000-8000-0000000000c1',
            '{"name": "A cat", "color": 1, "sort_key": "a0"}', now() - interval '1 minute'),
  tests.chg('c2', 'g2', 'tasks', 'insert', 'a1000000-0000-4000-8000-0000000000f1',
            '{"title": "A task", "category_id": "a1000000-0000-4000-8000-0000000000c1"}', now() - interval '1 minute'),
  tests.chg('c3', 'g3', 'checklists', 'insert', 'a1000000-0000-4000-8000-0000000000d1',
            '{"title": "A list", "sort_key": "a0"}', now() - interval '1 minute'),
  tests.chg('c4', 'g4', 'notifications', 'insert', app.uuid_v5('dk-a'),
            '{"dedupe_key": "dk-a", "category": "reminder", "title": "t", "fire_at": "2026-09-22T10:00:00Z"}',
            now() - interval '1 minute')));
select app.register_device('a1000000-0000-4000-8000-0000000000e1', 'android', 'Pixel', '16', '1.0.0', 1, 'en', 'Europe/Paris');

select is((select count(*)::int from app.tasks), 1, 'A sees its task');
select is((select count(*)::int from app.profiles), 1, 'A sees exactly its own profile');

-- B's view.
select tests.authenticate_as('b1000000-0000-4000-8000-00000000000b');
select is((select count(*)::int from app.tasks), 0, 'B cannot select A''s tasks');
select is((select count(*)::int from app.categories), 0, 'B cannot select A''s categories');
select is((select count(*)::int from app.checklists), 0, 'B cannot select A''s checklists');
select is((select count(*)::int from app.notifications), 0, 'B cannot select A''s inbox');
select is((select count(*)::int from app.profiles where id = 'a1000000-0000-4000-8000-00000000000a'), 0,
          'B cannot select A''s profile');
select is((select count(*)::int from app.devices), 0, 'B cannot select A''s devices');
select is((select count(*)::int from app.sync_heads), 1, 'B only sees its own sync head');
select is((select user_id from app.sync_heads), 'b1000000-0000-4000-8000-00000000000b'::uuid, '… which is B''s');

-- Writes.
update app.tasks set title = 'hacked' where id = 'a1000000-0000-4000-8000-0000000000f1';
update app.devices set push_enabled = false where id = 'a1000000-0000-4000-8000-0000000000e1';
insert into app.tags (id, user_id, name, sort_key) values
  ('b1000000-0000-4000-8000-0000000000a1', 'a1000000-0000-4000-8000-00000000000a', 'spoofed', 'a0');
select is((select user_id from app.tags where id = 'b1000000-0000-4000-8000-0000000000a1'),
          'b1000000-0000-4000-8000-00000000000b'::uuid, 'an insert claiming A''s user_id is re-owned to B');
select throws_ok($$delete from app.tags$$, '42501', null, 'clients cannot hard-delete synced rows');
select throws_ok($$insert into app.sync_heads (user_id, head_rev) values ('b1000000-0000-4000-8000-00000000000b', 999)$$,
                 '42501', null, 'clients cannot write sync_heads');

-- sync_push by B targeting A's row id: never touches A's row.
select is(tests.push(jsonb_build_array(
            tests.chg('x1', 'gx', 'tasks', 'patch', 'a1000000-0000-4000-8000-0000000000f1', '{"title": "pwned"}',
                      now()))) -> 'results' -> 0 ->> 'status',
          'rejected', 'B pushing a patch on A''s row id is rejected (id collision)');

-- Storage: first folder must be the caller's uid.
select throws_ok($$insert into storage.objects (bucket_id, name, owner_id)
                   values ('attachments', 'a1000000-0000-4000-8000-00000000000a/x/file.jpg', 'b1000000-0000-4000-8000-00000000000b')$$,
                 '42501', null, 'B cannot upload into A''s folder');
select lives_ok($$insert into storage.objects (bucket_id, name, owner_id)
                  values ('attachments', 'b1000000-0000-4000-8000-00000000000b/x/file.jpg', 'b1000000-0000-4000-8000-00000000000b')$$,
                'B can upload into its own folder');

-- Broadcast channel authorization.
select set_config('realtime.topic', 'user:a1000000-0000-4000-8000-00000000000a', true);
select is((select count(*)::int from realtime.messages), 0, 'B cannot read A''s Broadcast channel');

select tests.clear_authentication();
insert into storage.objects (bucket_id, name, owner_id)
values ('attachments', 'a1000000-0000-4000-8000-00000000000a/y/secret.pdf', 'a1000000-0000-4000-8000-00000000000a');

select tests.authenticate_as('b1000000-0000-4000-8000-00000000000b');
select is((select count(*)::int from storage.objects where bucket_id = 'attachments'
             and name like 'a1000000-0000-4000-8000-00000000000a/%'), 0, 'B cannot list A''s objects');
update storage.objects set name = 'b1000000-0000-4000-8000-00000000000b/stolen.pdf'
 where name = 'a1000000-0000-4000-8000-00000000000a/y/secret.pdf';

select tests.authenticate_as('a1000000-0000-4000-8000-00000000000a');
select is((select title from app.tasks where id = 'a1000000-0000-4000-8000-0000000000f1'), 'A task',
          'A''s task is unchanged after B''s attempts');
select ok((select push_enabled from app.devices where id = 'a1000000-0000-4000-8000-0000000000e1'),
          'A''s device is unchanged');
select is((select count(*)::int from storage.objects where name like 'a1000000-0000-4000-8000-00000000000a/%'), 1,
          'A still owns its object (B could not rename it)');
select ok((select count(*) from realtime.messages) > 0, 'A reads its own Broadcast channel');
select is((select count(*)::int from app.tags), 0, 'A does not see B''s tag');

select * from finish();
rollback;
