-- Goals (T5.4.01): metric validity per scope, positive targets, custom periods need both dates, and
-- only global goals have no scope id.
begin;
select plan(7);

select tests.create_user('goals@test.local', 'e4000000-0000-4000-8000-0000000000c1');
select tests.authenticate_as('e4000000-0000-4000-8000-0000000000c1');

select lives_ok($$insert into app.goals (id, scope_type, scope_id, metric, target, period)
                  values ('e4000000-0000-4000-8000-00000000d001', 'habit', 'e4000000-0000-4000-8000-00000000a001',
                          'total_value', 10000, 'year')$$,
                'a yearly total for a habit is valid');
select lives_ok($$insert into app.goals (id, scope_type, scope_id, metric, target, period, start_date, end_date)
                  values ('e4000000-0000-4000-8000-00000000d002', 'habit', 'e4000000-0000-4000-8000-00000000a002',
                          'money_saved', 500, 'custom', '2026-09-01', '2026-12-31')$$,
                'a custom savings goal with both dates is valid');
select throws_ok($$insert into app.goals (id, scope_type, scope_id, metric, target, period)
                   values (gen_random_uuid(), 'habit', gen_random_uuid(), 'items_completed', 10, 'month')$$,
                 '23514', null, 'checklist metrics are rejected on habits');
select throws_ok($$insert into app.goals (id, scope_type, scope_id, metric, target, period)
                   values (gen_random_uuid(), 'checklist', gen_random_uuid(), 'streak_days', 10, 'month')$$,
                 '23514', null, 'habit metrics are rejected on checklists');
select throws_ok($$insert into app.goals (id, scope_type, scope_id, metric, target, period)
                   values (gen_random_uuid(), 'habit', gen_random_uuid(), 'completions', 10, 'custom')$$,
                 '23514', null, 'custom periods need start and end dates');
select throws_ok($$insert into app.goals (id, scope_type, scope_id, metric, target, period)
                   values (gen_random_uuid(), 'habit', gen_random_uuid(), 'completions', 0, 'week')$$,
                 '23514', null, 'targets must be positive');
select throws_ok($$insert into app.goals (id, scope_type, scope_id, metric, target, period)
                   values (gen_random_uuid(), 'global', gen_random_uuid(), 'completions', 10, 'week')$$,
                 '23514', null, 'global goals have no scope id');

select * from finish();
rollback;
