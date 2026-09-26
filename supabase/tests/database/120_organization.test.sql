-- Organization (T2.3.01): category names are unique per user among live rows, case-insensitively
-- (partial unique index on lower(name)); the name length check applies.
begin;
select plan(4);

select tests.create_user('org@test.local', 'e2000000-0000-4000-8000-0000000000c1');
select tests.create_user('org2@test.local', 'e3000000-0000-4000-8000-0000000000c1');

select has_index('app', 'categories', 'categories_user_id_lower_name_key',
                 'categories have the case-insensitive unique name index');

select tests.authenticate_as('e2000000-0000-4000-8000-0000000000c1');
insert into app.categories (id, name, color, sort_key)
values ('e2000000-0000-4000-8000-00000000c001', 'Work', 1, 'a0');
select throws_ok($$insert into app.categories (id, name, color, sort_key)
                   values ('e2000000-0000-4000-8000-00000000c002', 'WORK', 1, 'a1')$$,
                 '23505', null, 'category names are unique per user, case-insensitively');
select throws_ok($$insert into app.categories (id, name, color, sort_key)
                   values ('e2000000-0000-4000-8000-00000000c003', '', 1, 'a2')$$,
                 '23514', null, 'empty category names are rejected');

select tests.authenticate_as('e3000000-0000-4000-8000-0000000000c1');
select lives_ok($$insert into app.categories (id, name, color, sort_key)
                  values ('e3000000-0000-4000-8000-00000000c004', 'Work', 1, 'a0')$$,
                'another user may use the same name');

select * from finish();
rollback;
