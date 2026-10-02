-- Imported calendar UIDs on tasks (T8.2.12): stored, bounded and private.
begin;
select plan(4);

select tests.create_user('uida@test.local', 'e6000000-0000-4000-8000-0000000000a1');
select tests.create_user('uidb@test.local', 'e6000000-0000-4000-8000-0000000000b1');

select tests.authenticate_as('e6000000-0000-4000-8000-0000000000a1');
select lives_ok($$insert into app.tasks (id, title, external_uid)
                  values ('e6000000-0000-4000-8000-00000000d001', 'Dentist', '040000008200E00074C5B7101A82E008@google.com')$$,
                'a task keeps the UID of its calendar event');
select throws_ok($$insert into app.tasks (id, title, external_uid) values (gen_random_uuid(), 'x', '')$$,
                 '23514', null, 'an empty UID is rejected');
select throws_ok($$insert into app.tasks (id, title, external_uid) values (gen_random_uuid(), 'x', repeat('u', 256))$$,
                 '23514', null, 'UIDs are at most 255 characters');

select tests.authenticate_as('e6000000-0000-4000-8000-0000000000b1');
select is((select count(*) from app.tasks where external_uid is not null)::int, 0, 'other users never see the UID');

select * from finish();
rollback;
