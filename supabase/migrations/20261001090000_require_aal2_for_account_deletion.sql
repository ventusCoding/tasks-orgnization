-- =====================================================================================================
-- T1.5.17 — Optional TOTP multi-factor authentication: once a user has a verified factor, account
-- deletion needs a session stepped up to aal2 (the account-delete Edge Function checks it too).
-- =====================================================================================================

create or replace function private.requires_aal2(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from auth.mfa_factors f where f.user_id = p_user_id and f.status = 'verified')
     and coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2'
$$;

comment on function private.requires_aal2(uuid) is
  'True when the user has a verified MFA factor but the current JWT is not aal2 (step-up needed).';

create or replace function app.request_account_deletion()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := app.current_user_id();
begin
  if private.requires_aal2(v_uid) then
    raise exception using errcode = '42501', message = 'aal2_required',
                          hint = 'Verify your authenticator code before deleting the account.';
  end if;

  insert into private.account_deletion_requests (user_id) values (v_uid)
  on conflict (user_id) do update set requested_at = now();

  -- Stop every push immediately.
  update app.devices d set push_token = null, push_token_updated_at = null, updated_at = now()
   where d.user_id = v_uid and d.push_token is not null;
  update private.notification_jobs j set status = 'cancelled', lease_until = null, last_error = 'account_deletion'
   where j.user_id = v_uid and j.status in ('pending', 'claimed');

  perform private.invoke_edge('account-delete', jsonb_build_object('user_id', v_uid));
  return jsonb_build_object('status', 'requested');
end
$$;

comment on function app.request_account_deletion() is
  'Marks the caller''s account for deletion (aal2 when MFA is on), stops pushes, and triggers the account-delete Edge Function.';

grant execute on function app.request_account_deletion() to authenticated;
