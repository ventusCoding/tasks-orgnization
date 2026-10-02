-- T7.4.06 — persisted FCM token cache (service role only, monotonic expiry).
begin;
select plan(6);

select ok(not has_function_privilege('authenticated', 'app.fcm_token_cache_get(text, interval)', 'execute')
            and not has_function_privilege('authenticated', 'app.fcm_token_cache_put(text, text, timestamptz)', 'execute'),
          'token cache RPCs are service-role only');

set local role service_role;

select is((select count(*)::int from app.fcm_token_cache_get('sa|uri')), 0, 'empty cache returns nothing');

select app.fcm_token_cache_put('sa|uri', 'tok-1', now() + interval '1 hour');
select is((select access_token from app.fcm_token_cache_get('sa|uri')), 'tok-1', 'a stored token is returned');

-- An older token minted concurrently never replaces a longer-lived one.
select app.fcm_token_cache_put('sa|uri', 'tok-old', now() + interval '30 minutes');
select is((select access_token from app.fcm_token_cache_get('sa|uri')), 'tok-1', 'shorter-lived token ignored');

select app.fcm_token_cache_put('sa|uri', 'tok-2', now() + interval '2 hours');
select is((select access_token from app.fcm_token_cache_get('sa|uri')), 'tok-2', 'longer-lived token replaces');

-- Tokens about to expire (< 5 min) are not handed out.
select app.fcm_token_cache_put('sa|soon', 'tok-soon', now() + interval '3 minutes');
select is((select count(*)::int from app.fcm_token_cache_get('sa|soon')), 0, 'near-expiry token is not returned');

select * from finish();
rollback;
