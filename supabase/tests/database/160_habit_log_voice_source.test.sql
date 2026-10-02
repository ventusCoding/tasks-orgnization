-- Voice-logged habit entries (T8.2.15).
begin;
select plan(2);

select tests.create_user('voice@test.local', 'e7000000-0000-4000-8000-0000000000a1');
select tests.authenticate_as('e7000000-0000-4000-8000-0000000000a1');
insert into app.habits (id, kind, name, start_date, sort_key)
  values ('e7000000-0000-4000-8000-00000000d001', 'build', 'Push-ups', '2026-09-01', 'a0');

select lives_ok($$insert into app.habit_logs (id, habit_id, kind, logged_at, local_date, value, source)
                  values (gen_random_uuid(), 'e7000000-0000-4000-8000-00000000d001', 'progress', now(), '2026-09-22', 15, 'voice')$$,
                'a voice log is accepted');
select throws_ok($$insert into app.habit_logs (id, habit_id, kind, logged_at, local_date, value, source)
                   values (gen_random_uuid(), 'e7000000-0000-4000-8000-00000000d001', 'progress', now(), '2026-09-22', 1, 'telepathy')$$,
                 '23514', null, 'unknown sources are rejected');

select * from finish();
rollback;
