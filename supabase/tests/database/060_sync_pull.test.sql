-- T1.4.09 / T1.4.11 — app.sync_pull paging (ordered by per-user revision across tables, gap-free
-- cursor, more flag, purge watermark) and app.fetch_rows.
begin;
select plan(18);

select tests.create_user('pull@test.local', 'f1000000-0000-4000-8000-00000000000f');
select tests.create_user('other@test.local', 'f2000000-0000-4000-8000-00000000000f');

-- Other user's data must never appear.
select tests.authenticate_as('f2000000-0000-4000-8000-00000000000f');
insert into app.tags (id, name, sort_key) select gen_random_uuid(), 'other ' || i, 'a' || i from generate_series(1, 5) i;

-- 1 profile (auth trigger) + 3 categories + 3 tags + 3 checklists = 10 rows, interleaved across tables.
select tests.authenticate_as('f1000000-0000-4000-8000-00000000000f');
insert into app.categories (id, name, color, sort_key) values ('f1000000-0000-4000-8000-0000000000c1', 'c1', 1, 'a0');
insert into app.tags (id, name, sort_key) values ('f1000000-0000-4000-8000-0000000000a1', 't1', 'a0');
insert into app.checklists (id, title, sort_key) values ('f1000000-0000-4000-8000-0000000000b1', 'l1', 'a0');
insert into app.categories (id, name, color, sort_key) values ('f1000000-0000-4000-8000-0000000000c2', 'c2', 1, 'a1');
insert into app.tags (id, name, sort_key) values ('f1000000-0000-4000-8000-0000000000a2', 't2', 'a1');
insert into app.checklists (id, title, sort_key) values ('f1000000-0000-4000-8000-0000000000b2', 'l2', 'a1');
insert into app.categories (id, name, color, sort_key) values ('f1000000-0000-4000-8000-0000000000c3', 'c3', 1, 'a2');
insert into app.tags (id, name, sort_key) values ('f1000000-0000-4000-8000-0000000000a3', 't3', 'a2');
insert into app.checklists (id, title, sort_key) values ('f1000000-0000-4000-8000-0000000000b3', 'l3', 'a2');

create temporary table p (k text primary key, v jsonb) on commit drop;
grant all on p to authenticated;
insert into p values ('all', app.sync_pull(0, 1000));

select is((select jsonb_array_length(v -> 'changes') from p where k = 'all'), 10, 'pull returns every own row once');
select ok((select bool_and(x -> 'r' ->> 'user_id' = 'f1000000-0000-4000-8000-00000000000f')
             from p, jsonb_array_elements(v -> 'changes') x where k = 'all'), 'only the caller''s rows');
select is((select array_agg((x -> 'r' ->> 'rev')::int order by o) from p, jsonb_array_elements(v -> 'changes') with ordinality e(x, o) where k = 'all'),
          (select array_agg(g) from generate_series(1, 10) g), 'changes are sorted by rev across tables (1..10)');
select is((select array_agg(x ->> 't' order by o) from p, jsonb_array_elements(v -> 'changes') with ordinality e(x, o) where k = 'all'),
          array['profiles', 'categories', 'tags', 'checklists', 'categories', 'tags', 'checklists', 'categories', 'tags', 'checklists'],
          'each change carries its table name');
select is((select (v ->> 'next')::int from p where k = 'all'), 10, 'next = max rev returned');
select is((select (v ->> 'more')::boolean from p where k = 'all'), false, 'more = false on the last page');
select is((select (v ->> 'purge_watermark')::int from p where k = 'all'), 0, 'purge_watermark = 0 before any purge');
select ok((select v -> 'changes' -> 1 -> 'r' ? 'field_clock' and v -> 'changes' -> 1 -> 'r' ? 'server_updated_at'
             from p where k = 'all'), 'rows are full (snake_case keys incl. field_clock)');

-- Paging with a small limit never skips or repeats a row.
insert into p values ('p1', app.sync_pull(0, 4));
insert into p values ('p2', app.sync_pull((select (v ->> 'next')::bigint from p where k = 'p1'), 4));
insert into p values ('p3', app.sync_pull((select (v ->> 'next')::bigint from p where k = 'p2'), 4));
select is((select array[(select (v ->> 'next')::int from p where k = 'p1'), (select (v ->> 'next')::int from p where k = 'p2'),
                        (select (v ->> 'next')::int from p where k = 'p3')]), array[4, 8, 10], 'cursors advance 4 → 8 → 10');
select is((select array[(select (v ->> 'more')::boolean from p where k = 'p1'), (select (v ->> 'more')::boolean from p where k = 'p2'),
                        (select (v ->> 'more')::boolean from p where k = 'p3')]), array[true, true, false], 'more flags');
select is((select array_agg((x -> 'r' ->> 'rev')::int order by k, o) from p, jsonb_array_elements(v -> 'changes') with ordinality e(x, o)
            where k in ('p1', 'p2', 'p3')),
          (select array_agg(g) from generate_series(1, 10) g), 'pages concatenate to the full ordered set');

-- An update moves the row to the end of the stream.
update app.tags set name = 't1 edited' where id = 'f1000000-0000-4000-8000-0000000000a1';
insert into p values ('after', app.sync_pull(10, 100));
select is((select jsonb_array_length(v -> 'changes') from p where k = 'after'), 1, 'only the edited row after the cursor');
select is((select v -> 'changes' -> 0 -> 'r' ->> 'name' from p where k = 'after'), 't1 edited', 'with its new value');
insert into p values ('empty', app.sync_pull(999, 100));
select is((select v from p where k = 'empty') - 'purge_watermark', '{"changes": [], "next": 999, "more": false}'::jsonb,
          'a cursor beyond the head returns nothing and keeps the cursor');

-- fetch_rows (targeted refetch after integrity_refetch).
insert into p values ('fetch', app.fetch_rows('tags', array['f1000000-0000-4000-8000-0000000000a1',
                                                            'f1000000-0000-4000-8000-0000000000ff']::uuid[]));
select is((select jsonb_array_length(v -> 'rows') from p where k = 'fetch'), 1, 'fetch_rows returns existing rows');
select is((select v -> 'missing' from p where k = 'fetch'), '["f1000000-0000-4000-8000-0000000000ff"]'::jsonb,
          'fetch_rows lists ids unknown to the server');
select throws_ok($$select app.fetch_rows('secrets', array[gen_random_uuid()])$$, 'PGRST', null, 'fetch_rows allow-lists tables');

select tests.authenticate_as('f2000000-0000-4000-8000-00000000000f');
select is(app.fetch_rows('tags', array['f1000000-0000-4000-8000-0000000000a1']::uuid[]) -> 'rows', '[]'::jsonb,
          'fetch_rows never returns another user''s row');

select * from finish();
rollback;
