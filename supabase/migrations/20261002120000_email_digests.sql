-- =====================================================================================================
-- T7.4.18 — opt-in email delivery of digests. Users opt in with `user_settings.notifications.emailDigests`
-- = {enabled: true, kinds?: [...]}; push-dispatch emails digest jobs to the account address through a
-- transactional provider (never individual reminders). Hard bounces / complaints suppress the address;
-- every email carries a signed one-click unsubscribe link.
-- =====================================================================================================

alter table private.push_deliveries drop constraint if exists push_deliveries_outcome_check;
alter table private.push_deliveries add constraint push_deliveries_outcome_check
  check (outcome in ('sent', 'skipped_local', 'skipped_policy', 'skipped_stale_token', 'expired', 'failed',
                     'token_invalid', 'email_sent', 'email_failed'));

create table if not exists private.email_suppressions (
  email      text primary key check (char_length(email) between 3 and 320),
  user_id    uuid references auth.users (id) on delete cascade,
  reason     text not null check (reason in ('bounce', 'complaint', 'unsubscribe')),
  created_at timestamptz not null default now()
);

comment on table private.email_suppressions is 'Addresses that must never receive digest emails (bounce, complaint).';

revoke all on private.email_suppressions from public, anon, authenticated;
grant select, insert, update, delete on private.email_suppressions to service_role;

-- Opted-in recipients of [p_user_ids]: {user_id: {email, locale, kinds}} (confirmed, not suppressed).
create or replace function app.dispatch_email_targets(p_user_ids uuid[])
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_object_agg(u.id, jsonb_build_object(
           'email', u.email,
           'locale', coalesce(p.locale, 'en'),
           'kinds', coalesce(s.value -> 'emailDigests' -> 'kinds', '[]'::jsonb))), '{}'::jsonb)
    from auth.users u
    join app.user_settings s on s.user_id = u.id and s.namespace = 'notifications' and s.deleted_at is null
    left join app.profiles p on p.id = u.id
   where u.id = any (p_user_ids)
     and u.email is not null and u.email_confirmed_at is not null and not coalesce(u.is_anonymous, false)
     and (s.value -> 'emailDigests' ->> 'enabled')::boolean is true
     and not exists (select 1 from private.email_suppressions e where lower(e.email) = lower(u.email))
$$;

comment on function app.dispatch_email_targets(uuid[]) is 'Service role only (push-dispatch): digest email recipients.';

-- One-click unsubscribe: turns emailDigests off (server HLC stamp so the change syncs to devices).
create or replace function app.email_unsubscribe(p_user uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_clock text := app.hlc_at(now());
begin
  update app.user_settings s
     set value = jsonb_set(s.value, '{emailDigests}',
                           coalesce(s.value -> 'emailDigests', '{}'::jsonb) || '{"enabled": false}'::jsonb),
         updated_at = now(),
         field_clock = s.field_clock || jsonb_build_object('value', v_clock)
   where s.user_id = p_user and s.namespace = 'notifications' and s.deleted_at is null;
  return found;
end
$$;

comment on function app.email_unsubscribe(uuid) is 'Service role only (email links): disable digest emails.';

-- Provider events: hard bounces and complaints suppress the address.
create or replace function app.email_suppress(p_email text, p_reason text)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into private.email_suppressions (email, user_id, reason)
  values (lower(p_email), (select u.id from auth.users u where lower(u.email) = lower(p_email) limit 1), p_reason)
  on conflict (email) do nothing
$$;

comment on function app.email_suppress(text, text) is 'Service role only (email-events): suppress an address.';

revoke execute on function app.dispatch_email_targets(uuid[]) from public, anon, authenticated;
revoke execute on function app.email_unsubscribe(uuid) from public, anon, authenticated;
revoke execute on function app.email_suppress(text, text) from public, anon, authenticated;
grant execute on function app.dispatch_email_targets(uuid[]) to service_role;
grant execute on function app.email_unsubscribe(uuid) to service_role;
grant execute on function app.email_suppress(text, text) to service_role;

-- Emailed digests count as delivered for the email channel (never re-sent on a retry) and are final.
create or replace function app.dispatch_claim(p_limit int default 100, p_lease_seconds int default 120)
returns jsonb
language sql
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(
           to_jsonb(j) || jsonb_build_object('sent_device_ids', coalesce(
             (select jsonb_agg(d.device_id) from private.push_deliveries d where d.job_id = j.id and d.outcome in ('sent', 'email_sent')),
             '[]'::jsonb))
           order by j.fire_at), '[]'::jsonb)
  from private.claim_notification_jobs(p_limit, p_lease_seconds) j
$$;

create or replace function app.dispatch_complete(p_results jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_r       jsonb;
  v_job     record;
  v_status  text;
  v_updated int := 0;
begin
  for v_r in select e from jsonb_array_elements(coalesce(p_results, '[]'::jsonb)) e
  loop
    insert into private.push_deliveries as d (job_id, device_id, outcome, fcm_message_id, error_code)
    select (v_r ->> 'job_id')::uuid, (x ->> 'device_id')::uuid, x ->> 'outcome', x ->> 'fcm_message_id', x ->> 'error_code'
    from jsonb_array_elements(coalesce(v_r -> 'deliveries', '[]'::jsonb)) x
    on conflict (job_id, device_id) do update
      set outcome = excluded.outcome,
          fcm_message_id = coalesce(excluded.fcm_message_id, d.fcm_message_id),
          error_code = excluded.error_code,
          created_at = now()
      where d.outcome not in ('sent', 'email_sent');  -- a sent delivery is final

    update app.devices dv
       set push_token = null, push_token_updated_at = null, updated_at = now()
     where dv.id in (select x::uuid from jsonb_array_elements_text(coalesce(v_r -> 'invalid_device_ids', '[]'::jsonb)) x);

    v_status := v_r ->> 'status';
    if v_status = 'retry' then
      update private.notification_jobs j
         set status        = case when j.attempts + 1 >= 5 then 'failed' else 'pending' end,
             attempts      = j.attempts + 1,
             next_retry_at = now() + make_interval(secs => greatest(coalesce((v_r ->> 'retry_after_seconds')::int, 60), 1)),
             lease_until   = null,
             claimed_at    = null,
             last_error    = v_r ->> 'reason'
       where j.id = (v_r ->> 'job_id')::uuid and j.status = 'claimed'
      returning j.user_id, j.dedupe_key into v_job;
    elsif v_status in ('sent', 'skipped', 'expired', 'failed', 'cancelled') then
      update private.notification_jobs j
         set status      = v_status,
             sent_at     = case when v_status = 'sent' then now() else j.sent_at end,
             lease_until = null,
             last_error  = v_r ->> 'reason'
       where j.id = (v_r ->> 'job_id')::uuid and j.status = 'claimed'
      returning j.user_id, j.dedupe_key into v_job;
    else
      continue;
    end if;

    if found then
      v_updated := v_updated + 1;
      if coalesce((v_r ->> 'pushed')::boolean, false) then
        update app.notifications n
           set delivered_via = (select array_agg(distinct v order by v)
                                from unnest(coalesce(n.delivered_via, '{}'::text[]) || array['push']) v),
               field_clock = n.field_clock || jsonb_build_object('delivered_via',
                               greatest(coalesce(n.field_clock ->> 'delivered_via', '') collate "C",
                                        app.hlc_at(n.fire_at) collate "C"))
         where n.user_id = v_job.user_id and n.dedupe_key = v_job.dedupe_key
           and not (coalesce(n.delivered_via, '{}'::text[]) @> array['push']);
      end if;
    end if;
  end loop;
  return jsonb_build_object('updated', v_updated);
end
$$;
