-- =====================================================================================================
-- T1.4.08 / T1.4.09 / T1.4.11 — Sync RPCs: app.sync_push, app.sync_pull, app.fetch_rows.
-- Contracts are documented in supabase/README.md ("RPC contracts") — keep both in sync.
--
-- HLC strings (client clocks) are fixed width and sort with COLLATE "C":
--   "<15-digit zero-padded unix ms>:<5-digit counter>:<device id>"
-- =====================================================================================================

-- HLC string for an instant (server stamps, tests): '<ms>:<counter>:<node>'.
create or replace function app.hlc_at(p_at timestamptz, p_counter int default 0, p_node text default 'server')
returns text
language sql
immutable
parallel safe
set search_path = ''
as $$
  select lpad(floor(extract(epoch from p_at) * 1000)::bigint::text, 15, '0')
         || ':' || lpad(greatest(p_counter, 0)::text, 5, '0')
         || ':' || p_node
$$;

comment on function app.hlc_at(timestamptz, int, text) is
  'Fixed-width HLC string "<15-digit ms>:<5-digit counter>:<node>" for an instant (server-stamped writes).';

grant execute on function app.hlc_at(timestamptz, int, text) to authenticated, service_role;

-- Caller's purge watermark (highest revision hard-deleted by the purge jobs). Cursor below it → resync.
create or replace function app.purge_watermark()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select (m.value #>> '{}')::bigint from private.sync_meta m where m.key = 'purge_watermark:' || auth.uid()::text),
    0)
$$;

comment on function app.purge_watermark() is 'Purge watermark of the calling user (0 when nothing was purged).';

grant execute on function app.purge_watermark() to authenticated;

-- Raise the purge watermark of each user in p_watermarks ({"<user_id>": <rev>, …}).
create or replace function private.bump_purge_watermarks(p_watermarks jsonb)
returns void
language sql
set search_path = ''
as $$
  insert into private.sync_meta as m (key, value)
  select 'purge_watermark:' || w.key, w.value
  from jsonb_each(coalesce(p_watermarks, '{}'::jsonb)) w
  where jsonb_typeof(w.value) = 'number'
  on conflict (key) do update
    set value = to_jsonb(greatest((m.value #>> '{}')::bigint, (excluded.value #>> '{}')::bigint))
$$;

grant execute on function private.bump_purge_watermarks(jsonb) to service_role;

-- ---------------------------------------------------------------------------------------------------
-- app.sync_push
-- ---------------------------------------------------------------------------------------------------
create or replace function app.sync_push(p_device_id uuid, p_schema int, p_build int, p_changes jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  c_max_changes constant int := 500;
  c_forbidden   constant text[] := array['user_id', 'rev', 'server_updated_at', 'field_clock'];
  c_hlc_pattern constant text := '^[0-9]{15}:[0-9]{5}:.+$';
  v_uid         uuid;
  v_max_ms      text;                 -- clamp limit: now() + 5 min as 15-digit ms
  v_columns     jsonb;                -- {"<table>": {"<column>": true}}
  v_results     jsonb := '{}'::jsonb; -- result key → result
  v_group       record;
  v_group_res   jsonb;
  v_item        record;
  v_change      jsonb;
  v_key_res     text;
  v_change_id   text;
  v_table       text;
  v_op          text;
  v_row_id      uuid;
  v_fields      jsonb;
  v_clock_in    jsonb;
  v_clock       jsonb;
  v_field       text;
  v_hlc         text;
  v_existing    text;
  v_cur         jsonb;
  v_new         jsonb;
  v_apply       text[];
  v_stale       text[];
  v_cols        text;
  v_set         text;
  v_applied_clk jsonb;
  v_status      text;
  v_bad_key     text;
  v_state       text;
  v_msg         text;
  v_code        text;
  v_head        bigint;
begin
  v_uid := app.current_user_id();
  perform app.assert_client_supported(p_build);
  -- p_schema = client payload schema version; v1 is the only one so far (reserved for evolution, T9.2.08).
  if p_schema is not null and p_schema > 1 then
    raise log 'sync_push: client payload schema % (server knows 1)', p_schema;
  end if;

  if p_changes is null or jsonb_typeof(p_changes) <> 'array' then
    perform app.raise_api_error('invalid_request', 'p_changes must be a JSON array', 400);
  end if;
  if jsonb_array_length(p_changes) > c_max_changes then
    perform app.raise_api_error('too_many_changes', format('At most %s changes per call', c_max_changes), 413,
                                jsonb_build_object('max', c_max_changes));
  end if;
  if p_device_id is not null
     and exists (select 1 from app.devices d where d.id = p_device_id and d.revoked_at is not null) then
    perform app.raise_api_error('device_revoked', 'This device has been revoked; sign in again on a new device id', 403);
  end if;

  v_max_ms := lpad(floor(extract(epoch from now() + interval '5 minutes') * 1000)::bigint::text, 15, '0');

  -- Column allow-list per synced table (catalog; server-managed columns are refused below).
  select coalesce(jsonb_object_agg(t.relname, t.cols), '{}'::jsonb)
    into v_columns
  from (
    select c.relname, jsonb_object_agg(a.attname, true) as cols
    from pg_catalog.pg_class c
    join pg_catalog.pg_namespace n on n.oid = c.relnamespace
    join pg_catalog.pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
    where n.nspname = 'app' and c.relname in (select s from app.synced_tables() s)
    group by c.relname
  ) t;

  -- Operation groups in order of first appearance; changes of a group in array order.
  for v_group in
    select s.g
    from (
      select coalesce(nullif(x.e ->> 'g', ''), x.e ->> 'id', '#' || x.ord) as g, x.ord
      from jsonb_array_elements(p_changes) with ordinality as x (e, ord)
    ) s
    group by s.g
    order by min(s.ord)
  loop
    v_group_res := '{}'::jsonb;
    v_bad_key := null;

    begin
      set constraints all deferred;

      for v_item in
        select x.e, coalesce(x.e ->> 'id', '#' || x.ord) as k
        from jsonb_array_elements(p_changes) with ordinality as x (e, ord)
        where coalesce(nullif(x.e ->> 'g', ''), x.e ->> 'id', '#' || x.ord) = v_group.g
        order by x.ord
      loop
        v_change    := v_item.e;
        v_key_res   := v_item.k;
        v_bad_key   := v_item.k;
        v_change_id := v_change ->> 'id';
        v_table     := v_change ->> 't';
        v_op        := v_change ->> 'op';
        v_fields    := coalesce(v_change -> 'fields', '{}'::jsonb);
        v_clock_in  := coalesce(v_change -> 'clock', '{}'::jsonb);

        -- ---- validation ------------------------------------------------------------------------
        if jsonb_typeof(v_change) <> 'object' or v_change_id is null then
          raise exception 'each change needs an "id"' using errcode = 'ES004';
        end if;
        if v_table is null or not (v_columns ? v_table) then
          raise exception 'unknown table "%"', v_table using errcode = 'ES001';
        end if;
        if v_op is null or v_op not in ('insert', 'patch') then
          raise exception 'op must be insert or patch, got "%"', v_op using errcode = 'ES004';
        end if;
        if coalesce(v_change ->> 'row_id', '') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
          raise exception 'row_id must be a uuid' using errcode = 'ES004';
        end if;
        v_row_id := (v_change ->> 'row_id')::uuid;
        if jsonb_typeof(v_fields) <> 'object' or jsonb_typeof(v_clock_in) <> 'object' then
          raise exception 'fields and clock must be JSON objects' using errcode = 'ES004';
        end if;
        if v_fields ? 'id' then
          if (v_fields ->> 'id') is distinct from v_row_id::text then
            raise exception 'fields.id must equal row_id' using errcode = 'ES004';
          end if;
          v_fields := v_fields - 'id';
        end if;
        -- origin_device_id is always the pushing device
        v_fields := v_fields - 'origin_device_id';

        v_clock := '{}'::jsonb;
        for v_field in select jsonb_object_keys(v_fields)
        loop
          if v_field = any (c_forbidden) then
            raise exception 'column "%" is server-managed', v_field using errcode = 'ES003';
          end if;
          if not ((v_columns -> v_table) ? v_field) then
            raise exception 'unknown column "%.%"', v_table, v_field using errcode = 'ES002';
          end if;
          v_hlc := v_clock_in ->> v_field;
          if v_hlc is null or v_hlc !~ c_hlc_pattern then
            raise exception 'missing or malformed clock for field "%"', v_field using errcode = 'ES005';
          end if;
          if left(v_hlc, 15) collate "C" > v_max_ms collate "C" then
            v_hlc := v_max_ms || substr(v_hlc, 16);          -- clamp clocks > now() + 5 min
          end if;
          v_clock := v_clock || jsonb_build_object(v_field, v_hlc);
        end loop;

        -- ---- apply -----------------------------------------------------------------------------
        execute format('select to_jsonb(t) from app.%I t where t.id = $1 for update', v_table)
          into v_cur
          using v_row_id;

        v_stale := array[]::text[];

        if v_cur is null then
          -- Insert (op insert, or a patch that arrives before/without its row): field_clock = clocks.
          v_new := v_fields || jsonb_build_object('id', v_row_id, 'origin_device_id', p_device_id, 'field_clock', v_clock);
          select string_agg(format('%I', k), ', ') into v_cols from jsonb_object_keys(v_new) k;
          execute format(
            'insert into app.%I (%s) select %s from jsonb_populate_record(null::app.%I, $1)',
            v_table, v_cols, v_cols, v_table)
            using v_new;
          v_status := 'applied';
        else
          -- Per-field last-writer-wins.
          execute format('select to_jsonb(r) from jsonb_populate_record(null::app.%I, $1) r', v_table)
            into v_new
            using v_fields;

          v_apply := array[]::text[];
          for v_field in select jsonb_object_keys(v_fields)
          loop
            v_hlc := v_clock ->> v_field;
            v_existing := coalesce(v_cur -> 'field_clock' ->> v_field, '');
            if v_hlc collate "C" > v_existing collate "C" then
              v_apply := v_apply || v_field;
            elsif v_hlc = v_existing then
              -- Same clock: a replay (same value) is a no-op; a different value cannot normally happen.
              if (v_new -> v_field) is distinct from (v_cur -> v_field) then
                v_apply := v_apply || v_field;
              end if;
            else
              v_stale := v_stale || v_field;
            end if;
          end loop;

          if cardinality(v_apply) = 0 then
            v_status := 'stale';                                  -- no update → no revision bump
          else
            select string_agg(format('%I = r.%I', f, f), ', '), jsonb_object_agg(f, v_clock -> f)
              into v_set, v_applied_clk
            from unnest(v_apply) f;
            execute format(
              'update app.%I t set %s, field_clock = t.field_clock || $2, origin_device_id = $3 '
              'from jsonb_populate_record(null::app.%I, $1) r where t.id = $4',
              v_table, v_set, v_table)
              using v_fields, v_applied_clk, p_device_id, v_row_id;
            v_status := case when cardinality(v_stale) = 0 then 'applied' else 'partial' end;
          end if;
        end if;

        v_group_res := v_group_res || jsonb_build_object(v_key_res, jsonb_build_object(
          'id', v_change_id, 'status', v_status, 'stale_fields', to_jsonb(v_stale), 'code', null, 'message', null));
      end loop;

      -- Deferred integrity (tree checks, deferred FKs, owner checks) for this group only.
      v_bad_key := null;
      set constraints all immediate;

      v_results := v_results || v_group_res;
    exception
      when serialization_failure or deadlock_detected or query_canceled or lock_not_available
           or admin_shutdown or insufficient_resources then
        raise;                                                    -- transient: the client retries
      when others then
        get stacked diagnostics v_state = returned_sqlstate, v_msg = message_text;
        v_code := case
          when v_state like '23%' or v_state like 'DL%' then 'integrity_refetch'
          when v_state = 'ES001' then 'unknown_table'
          when v_state = 'ES002' then 'unknown_column'
          when v_state = 'ES003' then 'forbidden_column'
          when v_state = 'ES004' then 'invalid_change'
          when v_state = 'ES005' then 'invalid_clock'
          when v_state like '22%' then 'invalid_value'
          when v_state = '42501' then 'forbidden'
          else 'server_error'
        end;
        -- Every change of the group is rejected; integrity violations tell the client to refetch them.
        select v_results || coalesce(jsonb_object_agg(s.k, jsonb_build_object(
                 'id', s.e ->> 'id',
                 'status', 'rejected',
                 'stale_fields', '[]'::jsonb,
                 'code', case
                           when v_code = 'integrity_refetch' then v_code
                           when v_bad_key is null or s.k = v_bad_key then v_code
                           else 'group_rejected'
                         end,
                 'message', case
                              when v_code = 'integrity_refetch' or v_bad_key is null or s.k = v_bad_key then v_msg
                              else 'another change of the same operation group was rejected'
                            end)), '{}'::jsonb)
          into v_results
        from (
          select x.e, coalesce(x.e ->> 'id', '#' || x.ord) as k
          from jsonb_array_elements(p_changes) with ordinality as x (e, ord)
          where coalesce(nullif(x.e ->> 'g', ''), x.e ->> 'id', '#' || x.ord) = v_group.g
        ) s;
    end;
  end loop;

  select h.head_rev into v_head from app.sync_heads h where h.user_id = v_uid;

  return jsonb_build_object(
    'results', coalesce((
      select jsonb_agg(v_results -> coalesce(x.e ->> 'id', '#' || x.ord) order by x.ord)
      from jsonb_array_elements(p_changes) with ordinality as x (e, ord)), '[]'::jsonb),
    'head', coalesce(v_head, 0));
end
$$;

comment on function app.sync_push(uuid, int, int, jsonb) is
  'Applies ≤ 500 patches ({id,g,t,op,row_id,fields,clock}) with per-field HLC LWW, one savepoint per '
  'operation group ending with SET CONSTRAINTS ALL IMMEDIATE. Returns {results:[{id,status,stale_fields,'
  'code,message}], head}. See supabase/README.md.';

grant execute on function app.sync_push(uuid, int, int, jsonb) to authenticated;

-- ---------------------------------------------------------------------------------------------------
-- app.sync_pull
-- ---------------------------------------------------------------------------------------------------
create or replace function app.sync_pull(p_since bigint, p_limit int default 1000)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_uid   uuid := app.current_user_id();
  v_since bigint := greatest(coalesce(p_since, 0), 0);
  v_limit int := least(greatest(coalesce(p_limit, 1000), 1), 5000);
  v_union text;
  v_rows  jsonb;
  v_count bigint;
  v_next  bigint;
begin
  select string_agg(format(
           '(select %L::text as t, r.rev, to_jsonb(r) as j from app.%I r '
           'where r.user_id = $1 and r.rev > $2 order by r.rev limit $3)', s, s), ' union all ')
    into v_union
  from app.synced_tables() s;

  execute format(
    'select coalesce(jsonb_agg(jsonb_build_object(''t'', x.t, ''r'', x.j) order by x.rev) filter (where x.n <= $4), ''[]''::jsonb), '
    '       count(*), max(x.rev) filter (where x.n <= $4) '
    'from (select u.t, u.rev, u.j, row_number() over (order by u.rev) as n '
    '      from (%s) u order by u.rev limit $3) x',
    v_union)
    into v_rows, v_count, v_next
    using v_uid, v_since, v_limit + 1, v_limit;

  return jsonb_build_object(
    'changes', v_rows,
    'next', coalesce(v_next, v_since),
    'more', v_count > v_limit,
    'purge_watermark', app.purge_watermark());
end
$$;

comment on function app.sync_pull(bigint, int) is
  'Paged pull across all synced tables by per-user revision: {changes:[{t,r}], next, more, purge_watermark}.';

grant execute on function app.sync_pull(bigint, int) to authenticated;

-- ---------------------------------------------------------------------------------------------------
-- app.fetch_rows — targeted refetch (after an integrity_refetch rejection).
-- ---------------------------------------------------------------------------------------------------
create or replace function app.fetch_rows(p_table text, p_ids uuid[])
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_uid     uuid := app.current_user_id();
  v_rows    jsonb;
  v_missing jsonb;
begin
  if p_table is null or not exists (select 1 from app.synced_tables() s where s = p_table) then
    perform app.raise_api_error('unknown_table', format('Unknown synced table "%s"', p_table), 400);
  end if;
  if coalesce(cardinality(p_ids), 0) > 1000 then
    perform app.raise_api_error('too_many_ids', 'At most 1000 ids per call', 413);
  end if;

  execute format(
    'select coalesce(jsonb_agg(to_jsonb(r) order by r.rev), ''[]''::jsonb) from app.%I r '
    'where r.user_id = $1 and r.id = any ($2)', p_table)
    into v_rows
    using v_uid, coalesce(p_ids, '{}'::uuid[]);

  select coalesce(jsonb_agg(i), '[]'::jsonb)
    into v_missing
  from unnest(coalesce(p_ids, '{}'::uuid[])) i
  where not exists (select 1 from jsonb_array_elements(v_rows) r where (r ->> 'id')::uuid = i);

  return jsonb_build_object('t', p_table, 'rows', v_rows, 'missing', v_missing);
end
$$;

comment on function app.fetch_rows(text, uuid[]) is
  'Returns {t, rows:[row json], missing:[ids not on the server]} for the caller''s rows of a synced table.';

grant execute on function app.fetch_rows(text, uuid[]) to authenticated;
