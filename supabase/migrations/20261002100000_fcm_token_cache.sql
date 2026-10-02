-- =====================================================================================================
-- T7.4.06 — persisted FCM OAuth token cache: cold Edge Function instances reuse the access token minted
-- by another instance instead of signing a new JWT every run. Server-only (schema private); the Edge
-- Functions reach it through two service-role RPCs.
-- =====================================================================================================

create table if not exists private.fcm_token_cache (
  cache_key    text primary key check (char_length(cache_key) between 1 and 300),
  access_token text not null,
  expires_at   timestamptz not null,
  updated_at   timestamptz not null default now()
);

comment on table private.fcm_token_cache is
  'FCM OAuth access tokens per service account (key = client_email|token_uri), reused until ~5 min before expiry.';

revoke all on private.fcm_token_cache from public, anon, authenticated;
grant select, insert, update, delete on private.fcm_token_cache to service_role;

-- Returns the cached token when it is still valid for at least p_min_validity.
create or replace function app.fcm_token_cache_get(p_key text, p_min_validity interval default interval '5 minutes')
returns table (access_token text, expires_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select c.access_token, c.expires_at
    from private.fcm_token_cache c
   where c.cache_key = p_key
     and c.expires_at > now() + p_min_validity
$$;

comment on function app.fcm_token_cache_get(text, interval) is 'Service role only: cached FCM access token.';

create or replace function app.fcm_token_cache_put(p_key text, p_access_token text, p_expires_at timestamptz)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into private.fcm_token_cache (cache_key, access_token, expires_at, updated_at)
  values (p_key, p_access_token, p_expires_at, now())
  on conflict (cache_key) do update
    set access_token = excluded.access_token,
        expires_at   = excluded.expires_at,
        updated_at   = now()
  -- Never replace a longer-lived token with an older one minted concurrently.
  where private.fcm_token_cache.expires_at < excluded.expires_at
$$;

comment on function app.fcm_token_cache_put(text, text, timestamptz) is 'Service role only: store an FCM access token.';

revoke execute on function app.fcm_token_cache_get(text, interval) from public, anon, authenticated;
revoke execute on function app.fcm_token_cache_put(text, text, timestamptz) from public, anon, authenticated;
grant execute on function app.fcm_token_cache_get(text, interval) to service_role;
grant execute on function app.fcm_token_cache_put(text, text, timestamptz) to service_role;
