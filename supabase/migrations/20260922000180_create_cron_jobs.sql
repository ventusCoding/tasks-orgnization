-- =====================================================================================================
-- T1.2.12 / T7.4.08 / T7.4.11 — Schedules and the sync-nudge webhook.
--
--   everslot-push-dispatch   every 30 s   private.invoke_edge('push-dispatch')   (no-op without Vault secrets)
--   everslot-minutely        every minute lease reaper + heartbeats
--   everslot-daily           03:00 UTC    purge, retention, token hygiene, cleanup (arch §7.7)
-- Four concurrent jobs at most (Supabase guidance: ≤ 8, each ≤ 10 min).
-- Guarded: without pg_cron (restricted environments) the schedules are skipped.
-- =====================================================================================================

-- ---------------------------------------------------------------------------------------------------
-- sync-nudge "database webhook": after a user's head revision moves, ask the Edge Function to send a
-- silent sync push to the user's OTHER devices. Queued at most once per transaction and user, only
-- when another push-capable device exists. pg_net sends after commit (its queue is transactional).
-- ---------------------------------------------------------------------------------------------------
create or replace function private.tg_sync_heads_nudge()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_flag text := 'everslot.nudged_' || replace(new.user_id::text, '-', '');
begin
  if tg_op = 'UPDATE' and new.head_rev is not distinct from old.head_rev then
    return null;
  end if;
  if coalesce(current_setting(v_flag, true), '') = '1' then
    return null;                                       -- already queued in this transaction
  end if;
  perform set_config(v_flag, '1', true);

  if not exists (
    select 1 from app.devices d
    where d.user_id = new.user_id and d.revoked_at is null and d.push_enabled and d.push_token is not null
      and d.id is distinct from new.last_origin_device_id
  ) then
    return null;
  end if;

  perform private.invoke_edge('sync-nudge', jsonb_build_object(
    'type', 'sync_head',
    'user_id', new.user_id,
    'head_rev', new.head_rev,
    'origin_device_id', new.last_origin_device_id));
  return null;
end
$$;

comment on function private.tg_sync_heads_nudge() is
  'Webhook to the sync-nudge Edge Function (once per transaction and user; skipped without other devices).';

drop trigger if exists tg_sync_heads_nudge on app.sync_heads;
create trigger tg_sync_heads_nudge
  after insert or update of head_rev on app.sync_heads
  for each row execute function private.tg_sync_heads_nudge();

-- ---------------------------------------------------------------------------------------------------
-- Schedules
-- ---------------------------------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_extension where extname = 'pg_cron') then
    raise notice 'pg_cron is not installed: Everslot schedules skipped';
    return;
  end if;

  perform cron.schedule('everslot-push-dispatch', '30 seconds',
                        $cmd$select private.invoke_edge('push-dispatch', '{}'::jsonb)$cmd$);
  perform cron.schedule('everslot-minutely', '* * * * *',
                        $cmd$select private.run_minutely()$cmd$);
  perform cron.schedule('everslot-daily', '0 3 * * *',
                        $cmd$select private.daily_maintenance()$cmd$);
end
$$;
