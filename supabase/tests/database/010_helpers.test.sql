-- T1.2.04 / T1.2.11 — helper functions, uuid_v5 fixtures (fixtures/ids/uuid_v5.json), app_config gate.
begin;
select plan(36);

-- ---------------------------------------------------------------------------------------------------
-- Namespace + RFC 4122 v5 (same vectors as fixtures/ids/uuid_v5.json, shared with the Dart tests)
-- ---------------------------------------------------------------------------------------------------
select is(app.everslot_ns(), '6f1c9a52-7c1e-4d3b-9a8e-2b5f0e4c7d11'::uuid, 'EVERSLOT_NS constant');
select is(app.uuid_v5(''), 'd72fe3a1-b05b-5b10-b08e-65f5472c8ab7'::uuid, 'uuid_v5 fixture #0: ');
select is(app.uuid_v5('x'), '6b0c547a-88b6-5eca-84f9-17e5f775d04e'::uuid, 'uuid_v5 fixture #1: x');
select is(app.uuid_v5('hello'), 'd3873750-9359-56e8-811f-8590c8e61855'::uuid, 'uuid_v5 fixture #2: hello');
select is(app.uuid_v5('0199a000-0000-7000-8000-000000000001|2026-09-22T07:00'), 'da87ba0d-dbc5-5876-b8b2-1e5676fab408'::uuid, 'uuid_v5 fixture #3: 0199a000-0000-7000-8000-000000000001|2026-09-22T07');
select is(app.uuid_v5('0199a000-0000-7000-8000-000000000001|2026-03-29T02:30'), 'e2e37a75-fc22-5489-b23f-51287d2863e7'::uuid, 'uuid_v5 fixture #4: 0199a000-0000-7000-8000-000000000001|2026-03-29T02');
select is(app.uuid_v5('0199a000-0000-7000-8000-000000000001|week:2026-W39#2'), 'c3a27530-8055-555a-93ad-ce827283a2d4'::uuid, 'uuid_v5 fixture #5: 0199a000-0000-7000-8000-000000000001|week:2026-W39');
select is(app.uuid_v5('11111111-1111-4111-8111-111111111111|notifications'), '21f3e9cb-8f2d-5afd-8a5d-e38e90ca054d'::uuid, 'uuid_v5 fixture #6: 11111111-1111-4111-8111-111111111111|notifications');
select is(app.uuid_v5('11111111-1111-4111-8111-111111111111|default-category|work'), '1c850c0f-e2ba-56bf-b6eb-4e168efd29c4'::uuid, 'uuid_v5 fixture #7: 11111111-1111-4111-8111-111111111111|default-categ');
select is(app.uuid_v5('11111111-1111-4111-8111-111111111111|habit_section|morning'), 'ffa52c26-f3cb-5e19-b169-3c84347ef663'::uuid, 'uuid_v5 fixture #8: 11111111-1111-4111-8111-111111111111|habit_section');
select is(app.uuid_v5('11111111-1111-4111-8111-111111111111|profile|standard'), 'e77bd9a1-d69e-5233-9c35-dc622ef780cb'::uuid, 'uuid_v5 fixture #9: 11111111-1111-4111-8111-111111111111|profile|stand');
select is(app.uuid_v5('0199a000-0000-7000-8000-000000000020|2026-09-22|state'), '24241c3b-87ae-5d8e-a239-35439502540a'::uuid, 'uuid_v5 fixture #10: 0199a000-0000-7000-8000-000000000020|2026-09-22|st');
select is(app.uuid_v5('0199a000-0000-7000-8000-000000000021|2026-09-22|pledge'), 'cd983175-2e01-50d9-8123-0d94afdbfd14'::uuid, 'uuid_v5 fixture #11: 0199a000-0000-7000-8000-000000000021|2026-09-22|pl');
select is(app.uuid_v5('0199a0aa-0000-7000-8000-000000000001|task|0199a000-0000-7000-8000-000000000003'), '1a0370c1-acde-56c7-b306-5f4b56133647'::uuid, 'uuid_v5 fixture #12: 0199a0aa-0000-7000-8000-000000000001|task|0199a000');
select is(app.uuid_v5('0199a000-0000-7000-8000-000000000010|2026-09-21'), '0ce319fc-aa28-5e99-8095-451c2fa2fee8'::uuid, 'uuid_v5 fixture #13: 0199a000-0000-7000-8000-000000000010|2026-09-21');
select is(app.uuid_v5('first_checkin|habit|0199a000-0000-7000-8000-000000000020'), 'd63bded6-c37f-57e6-848b-2dc563932ccc'::uuid, 'uuid_v5 fixture #14: first_checkin|habit|0199a000-0000-7000-8000-000000');
select is(app.uuid_v5('0199a000-0000-7000-8000-000000000002|rollover|2026-09-22'), '133efb53-da17-5228-b447-caa1b7e2144a'::uuid, 'uuid_v5 fixture #15: 0199a000-0000-7000-8000-000000000002|rollover|2026');
select is(app.uuid_v5('3f786850e387550fdab836ed7e6dc881de23001b'), '09115d24-a949-5d2a-bd0c-6f9a7a3ae06f'::uuid, 'uuid_v5 fixture #16: 3f786850e387550fdab836ed7e6dc881de23001b');
select is(app.uuid_v5('Réunion d''équipe — été'), '0e106f1b-0b95-5629-a215-5db3747ab35c'::uuid, 'uuid_v5 fixture #17: Réunion d''équipe — été');
select is(app.uuid_v5('مراجعة أسبوعية'), '242f490b-9923-5c15-9a36-1534082feead'::uuid, 'uuid_v5 fixture #18: مراجعة أسبوعية');
select is(app.uuid_v5('🎯 focus|日本語'), '202cea3a-5841-51b9-acc9-d218fb4e2b21'::uuid, 'uuid_v5 fixture #19: 🎯 focus|日本語');
select is(app.uuid_v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8'::uuid, 'python.org'),
          '886313e1-3b8a-5372-9b90-0c9aee199e5d'::uuid, 'RFC 4122 reference vector (DNS namespace, python.org)');
select is(substr(app.uuid_v5('anything')::text, 15, 1), '5', 'version nibble is 5');
select ok(substr(app.uuid_v5('anything')::text, 20, 1) in ('8', '9', 'a', 'b'), 'RFC 4122 variant bits');

-- ---------------------------------------------------------------------------------------------------
-- current_user_id / time zones / HLC
-- ---------------------------------------------------------------------------------------------------
select throws_ok('select app.current_user_id()', '28000', 'not_authenticated', 'current_user_id raises without a JWT');
select tests.create_user('helpers@test.local', 'a0000000-0000-4000-8000-000000000001');
select tests.authenticate_as('a0000000-0000-4000-8000-000000000001');
select is(app.current_user_id(), 'a0000000-0000-4000-8000-000000000001'::uuid, 'current_user_id returns auth.uid()');
select tests.clear_authentication();

select ok(app.is_valid_time_zone('Europe/Paris'), 'IANA zone accepted');
select ok(app.is_valid_time_zone(null), 'NULL (floating) accepted');
select ok(not app.is_valid_time_zone('Mars/Olympus'), 'unknown zone rejected');
select is(app.hlc_at('2026-09-22 10:00:00+00', 7, 'dev'), '001790071200000:00007:dev', 'HLC string is fixed width');

-- ---------------------------------------------------------------------------------------------------
-- app_config (public read) + minimum build gate
-- ---------------------------------------------------------------------------------------------------
set local role anon;
select is((select (value #>> '{}')::int from app.app_config where key = 'min_supported_build'), 1,
          'anon can read app_config');
select throws_ok($$insert into app.app_config (key, value) values ('x', '1')$$, '42501', null, 'anon cannot write app_config');
reset role;

select lives_ok('select app.assert_client_supported(1)', 'build = minimum is supported');
select throws_ok('select app.assert_client_supported(0)', 'PGRST', null, 'build below minimum raises unsupported_client');
update app.app_config set value = '42' where key = 'min_supported_build';
select throws_ok('select app.assert_client_supported(41)', 'PGRST', null, 'raising min_supported_build blocks old builds');
select lives_ok('select app.assert_client_supported(42)', 'new minimum accepted');

select * from finish();
rollback;
