-- T1.5.17 — account deletion needs aal2 once a verified TOTP factor exists.
begin;
select plan(4);

select tests.create_user('mfa@test.local', '79000000-0000-4000-8000-000000000079');

select tests.authenticate_as('79000000-0000-4000-8000-000000000079');
select is(app.request_account_deletion() ->> 'status', 'requested', 'without MFA an aal1 session can request deletion');

select tests.clear_authentication();
delete from private.account_deletion_requests where user_id = '79000000-0000-4000-8000-000000000079';
insert into auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret)
values (gen_random_uuid(), '79000000-0000-4000-8000-000000000079', 'phone', 'totp', 'verified', now(), now(), 'JBSWY3DPEHPK3PXP');

select tests.authenticate_as('79000000-0000-4000-8000-000000000079');
select throws_ok($$select app.request_account_deletion()$$, '42501', 'aal2_required',
                 'with a verified factor an aal1 session is refused');

select set_config('request.jwt.claims',
                  json_build_object('sub', '79000000-0000-4000-8000-000000000079', 'role', 'authenticated',
                                    'aud', 'authenticated', 'aal', 'aal2')::text, true);
select is(app.request_account_deletion() ->> 'status', 'requested', 'an aal2 session can request deletion');

select tests.clear_authentication();
select is((select count(*)::int from private.account_deletion_requests
           where user_id = '79000000-0000-4000-8000-000000000079'), 1, 'the request was recorded once');

select * from finish();
rollback;
