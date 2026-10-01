-- T9.1.06 — RLS / sync wiring completeness. Adding an `app` table without RLS, policies or
-- `app.enable_sync(...)` makes this file fail.
begin;

create temporary table t_app_tables on commit drop as
  select c.oid as oid, c.relname::text as name
  from pg_class c
  where c.relnamespace = 'app'::regnamespace and c.relkind in ('r', 'p');

-- A table is "synced" when it carries the per-user revision columns.
create temporary table t_synced on commit drop as
  select t.oid, t.name
  from t_app_tables t
  where exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attname = 'rev' and not a.attisdropped)
    and exists (select 1 from pg_attribute a where a.attrelid = t.oid and a.attname = 'user_id' and not a.attisdropped);

select plan((select count(*)::int * 2 from t_app_tables) + (select count(*)::int * 6 from t_synced) + 12);

-- ---------------------------------------------------------------------------------------------------
-- Every app table
-- ---------------------------------------------------------------------------------------------------
select ok(c.relrowsecurity, format('RLS enabled on app.%s', t.name))
from t_app_tables t join pg_class c on c.oid = t.oid order by t.name;

select ok(exists (select 1 from pg_policies p where p.schemaname = 'app' and p.tablename = t.name),
          format('app.%s has policies', t.name))
from t_app_tables t order by t.name;

-- ---------------------------------------------------------------------------------------------------
-- Every synced table
-- ---------------------------------------------------------------------------------------------------
select ok(exists (select 1 from pg_trigger g where g.tgrelid = t.oid and g.tgname = 'tg_sync_before_write'
                    and g.tgenabled = 'O' and g.tgfoid = 'app.tg_sync_before_write()'::regprocedure),
          format('app.%s: tg_sync_before_write attached', t.name))
from t_synced t order by t.name;

select ok((select count(*) from pg_trigger g where g.tgrelid = t.oid
             and g.tgname in ('tg_sync_broadcast_insert', 'tg_sync_broadcast_update')
             and g.tgfoid = 'app.tg_sync_broadcast()'::regprocedure) = 2,
          format('app.%s: statement broadcast triggers attached', t.name))
from t_synced t order by t.name;

select ok(exists (
            select 1 from pg_index i
            where i.indrelid = t.oid
              and i.indkey[0] = (select attnum from pg_attribute where attrelid = t.oid and attname = 'user_id')
              and i.indkey[1] = (select attnum from pg_attribute where attrelid = t.oid and attname = 'rev')),
          format('app.%s: (user_id, rev) index', t.name))
from t_synced t order by t.name;

select ok((select count(*) from pg_policies p
            where p.schemaname = 'app' and p.tablename = t.name and p.cmd in ('SELECT', 'INSERT', 'UPDATE')
              and 'authenticated' = any (p.roles)
              and coalesce(p.qual, p.with_check) like '%user_id = ( SELECT auth.uid()%') = 3,
          format('app.%s: select/insert/update own-row policies', t.name))
from t_synced t order by t.name;

select ok(not exists (select 1 from pg_policies p where p.schemaname = 'app' and p.tablename = t.name
                        and p.cmd in ('DELETE', 'ALL')),
          format('app.%s: no delete policy (soft deletes only)', t.name))
from t_synced t order by t.name;

select ok(not has_table_privilege('authenticated', t.oid, 'DELETE') and not has_table_privilege('anon', t.oid, 'SELECT')
            and not has_table_privilege('anon', t.oid, 'INSERT'),
          format('app.%s: no DELETE for authenticated, nothing for anon', t.name))
from t_synced t order by t.name;

-- ---------------------------------------------------------------------------------------------------
-- Global checks
-- ---------------------------------------------------------------------------------------------------
select set_eq(
  'select * from app.synced_tables()',
  array['achievements', 'activity_events', 'attachments', 'categories', 'checklist_items', 'checklist_runs',
        'checklists', 'dashboards', 'entity_tags', 'goals', 'habit_logs', 'habit_pauses', 'habit_revisions',
        'habit_sections', 'habit_vocab', 'habits', 'notification_mutes', 'notification_profiles',
        'notification_rules', 'notifications', 'profiles', 'saved_views', 'tags', 'task_occurrences', 'tasks',
        'time_entries', 'user_settings'],
  'every arch §7.3 synced table is wired with app.enable_sync');

select set_eq(
  'select name from t_app_tables except select name from t_synced',
  array['app_config', 'devices', 'sync_heads'],
  'the only non-synced app tables are app_config, devices, sync_heads');

select set_eq(
  $$select p.proname::text from pg_proc p
    where p.pronamespace = 'app'::regnamespace and has_function_privilege('anon', p.oid, 'execute')$$,
  array['assert_client_supported', 'everslot_ns', 'is_valid_time_zone'],
  'anon can only execute the public helpers');

select ok(not bool_or(has_function_privilege('authenticated', p.oid, 'execute')),
          'service-only RPCs are not executable by authenticated users')
from pg_proc p
where p.pronamespace = 'app'::regnamespace
  and p.proname in ('dispatch_claim', 'dispatch_guards', 'dispatch_upsert_inbox', 'dispatch_devices',
                    'dispatch_complete', 'ops_health', 'ops_heartbeat', 'account_delete_prepare',
                    'storage_purge_claim', 'storage_purge_done', 'enable_sync');

select ok(not has_schema_privilege('authenticated', 'private', 'usage')
            and not has_schema_privilege('anon', 'private', 'usage'),
          'clients have no access to schema private');

select ok(not bool_or(has_table_privilege('authenticated', c.oid, 'select')), 'private tables are not client readable')
from pg_class c where c.relnamespace = 'private'::regnamespace and c.relkind = 'r';

select ok(has_table_privilege('authenticated', 'app.sync_heads', 'select')
            and not has_table_privilege('authenticated', 'app.sync_heads', 'insert')
            and not has_table_privilege('authenticated', 'app.sync_heads', 'update'),
          'sync_heads is read-only for clients');

select ok(not has_table_privilege('authenticated', 'app.devices', 'insert')
            and not has_table_privilege('authenticated', 'app.devices', 'delete')
            and not has_column_privilege('authenticated', 'app.devices', 'user_id', 'update')
            and has_column_privilege('authenticated', 'app.devices', 'push_enabled', 'update'),
          'devices: clients only update their preferences (writes via RPCs)');

select ok(exists (select 1 from storage.buckets b
                  where b.id = 'attachments' and not b.public and b.file_size_limit = 52428800
                    and 'video/mp4' = any(b.allowed_mime_types) and 'audio/mp4' = any(b.allowed_mime_types)
                    and not 'application/x-msdownload' = any(b.allowed_mime_types)),
          'attachments bucket is private, 50 MB (videos; 25 MB for other files in the app), MIME allow-list');

select is((select count(*)::int from pg_policies p
           where p.schemaname = 'storage' and p.tablename = 'objects' and p.policyname like 'attachments_%_own'
             and p.cmd in ('SELECT', 'INSERT', 'UPDATE', 'DELETE')), 4,
          'storage.objects has select/insert/update/delete policies for the attachments bucket');

select ok(exists (select 1 from pg_policies p
                  where p.schemaname = 'realtime' and p.tablename = 'messages'
                    and p.policyname = 'everslot_user_channel_read' and p.cmd = 'SELECT'),
          'realtime.messages authorization policy for user:<uid>');

select ok(not exists (select 1 from pg_policies p
                      where p.schemaname = 'realtime' and p.tablename = 'messages'
                        and p.policyname like 'everslot%' and p.cmd in ('INSERT', 'ALL')),
          'clients cannot send on the sync channel');

select * from finish();
rollback;
