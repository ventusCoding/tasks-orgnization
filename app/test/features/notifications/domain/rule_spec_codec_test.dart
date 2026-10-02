import 'dart:convert';

import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String roundTrip(String json) =>
      NotificationRuleSpec.fromJson(Map<String, Object?>.from(jsonDecode(json) as Map)).encode();

  group('arch §8.2 example', () {
    const example =
        '{"v":1,"trigger":{"type":"relative","anchor":"start","offsetMinutes":-10,"dayOffset":null,"atTime":null},'
        '"repeat":{"everyMinutes":5,"maxTimes":6,"until":"acknowledged"},'
        '"conditions":{"onlyIfStatusIn":["scheduled","in_progress"],"weekdays":null,'
        '"timeWindow":{"from":"08:00","to":"22:00","outside":"drop"},"respectQuietHours":true,"devices":"all"},'
        '"delivery":{"system":true,"inbox":true,"banner":true,"importance":"default","sound":"default",'
        '"vibration":"default","sticky":false,"alarmStyle":false,"actions":["done","snooze","skip"],'
        '"snoozeOptionsMinutes":[5,10,30,60]},'
        '"content":{"title":"{title}","body":"Starts in {minutes_until} min · {start_time}–{end_time}"}}';

    test('round-trips byte-identically', () => expect(roundTrip(example), example));

    test('decodes every field', () {
      final spec = NotificationRuleSpec.fromJson(Map<String, Object?>.from(jsonDecode(example) as Map));
      final trigger = spec.trigger as RelativeTrigger;
      expect(trigger.anchor, TriggerAnchor.start);
      expect(trigger.offsetMinutes, -10);
      expect(spec.repeat!.everyMinutes, 5);
      expect(spec.repeat!.until, RepeatUntil.acknowledged);
      expect(spec.conditions.onlyIfStatusIn, ['scheduled', 'in_progress']);
      expect(spec.conditions.timeWindow!.outside, OutsideWindow.drop);
      expect(spec.conditions.devices, isNull);
      expect(spec.delivery.actions, ['done', 'snooze', 'skip']);
      expect(spec.content.body, contains('{minutes_until}'));
    });
  });

  group('every trigger variant round-trips', () {
    const triggers = [
      '{"type":"relative","anchor":"end","offsetMinutes":-5}',
      '{"type":"relative","anchor":"start","dayOffset":-1,"atTime":"20:00"}',
      '{"type":"absolute","at":"2026-10-01T09:00","timeZone":null}',
      '{"type":"absolute","at":"2026-10-01T09:00","timeZone":"Europe/Paris"}',
      '{"type":"schedule","recurrence":{"v":1,"type":"fixed","freq":"weekly","interval":1,"byWeekday":["MO"],"times":["09:00"]}}',
      '{"type":"not_done_by","anchor":"time","offsetMinutes":0,"atTime":"21:00"}',
      '{"type":"status_age","statuses":["waiting","blocked"],"afterMinutes":2880}',
      '{"type":"overdue","afterMinutes":0}',
      '{"type":"streak_risk","atTime":"21:00","minStreak":3}',
      '{"type":"quota_behind","atTime":"20:00"}',
      '{"type":"milestone","metric":"clean_days","thresholds":"auto"}',
      '{"type":"milestone","metric":"money_saved","thresholds":[10,50,100]}',
      '{"type":"inactivity","afterDays":3}',
      '{"type":"digest","kind":"daily_agenda","schedule":{"v":1,"type":"fixed","freq":"daily","times":["07:07"]}}',
      '{"type":"status_change","from":"ongoing","to":"blocked","atTime":"18:00"}',
      '{"type":"children_complete"}',
      '{"type":"child_overdue"}',
      '{"type":"stale","afterDays":7}',
      '{"type":"up_next","beforeMinutes":5}',
      '{"type":"timer_end"}',
      '{"type":"list_reset","atTime":"07:00"}',
      '{"type":"quit_ritual","kind":"craving_support","minutesBefore":15}',
      '{"type":"event","name":"started_late","atTime":"18:00"}',
    ];
    for (final t in triggers) {
      test(t, () {
        final json = '{"v":1,"trigger":$t}';
        expect(roundTrip(json), json);
        final spec = NotificationRuleSpec.tryDecode(json)!;
        expect(spec.trigger, isNot(isA<UnknownTrigger>()));
      });
    }
  });

  test('sealed union is exhaustive over TriggerType', () {
    String kind(NotificationTrigger t) => switch (t) {
      RelativeTrigger() => 'relative',
      AbsoluteTrigger() => 'absolute',
      ScheduleTrigger() => 'schedule',
      NotDoneByTrigger() => 'not_done_by',
      StatusAgeTrigger() => 'status_age',
      OverdueTrigger() => 'overdue',
      StreakRiskTrigger() => 'streak_risk',
      QuotaBehindTrigger() => 'quota_behind',
      MilestoneTrigger() => 'milestone',
      InactivityTrigger() => 'inactivity',
      DigestTrigger() => 'digest',
      StatusChangeTrigger() => 'status_change',
      ChildrenCompleteTrigger() => 'children_complete',
      ChildOverdueTrigger() => 'child_overdue',
      StaleTrigger() => 'stale',
      UpNextTrigger() => 'up_next',
      TimerEndTrigger() => 'timer_end',
      ListResetTrigger() => 'list_reset',
      QuitRitualTrigger() => 'quit_ritual',
      EventTrigger() => 'event',
      UnknownTrigger() => 'unknown',
    };
    for (final type in TriggerType.values) {
      final trigger = NotificationTrigger.fromJson({'type': type.wire});
      expect(kind(trigger), type.wire);
      expect(trigger.type, type);
    }
  });

  test('unknown future fields and trigger types survive decode → encode', () {
    const json =
        '{"v":1,"trigger":{"type":"geofence","radius":50},"future":{"x":1},'
        '"delivery":{"sound":"none","newField":true},"content":{"title":"Hi","variants":[{"body":"a"}]},'
        '"scope":{"appliesTo":"items","extra":1}}';
    expect(roundTrip(json), json);
    final spec = NotificationRuleSpec.tryDecode(json)!;
    expect(spec.trigger, isA<UnknownTrigger>());
    expect(spec.appliesTo, AppliesTo.items);
    expect(spec.content.variants, hasLength(1));
  });

  test('repeat false sentinel round-trips and means disabled', () {
    const json = '{"v":1,"trigger":{"type":"relative","anchor":"start","offsetMinutes":0},"repeat":false}';
    expect(roundTrip(json), json);
    final spec = NotificationRuleSpec.tryDecode(json)!;
    expect(spec.repeatDisabled, isTrue);
    expect(spec.repeat, isNull);
  });

  test('specs built in code encode canonically and are equal after decode', () {
    const spec = NotificationRuleSpec(
      trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -15),
      delivery: DeliverySpec(sound: 'none', actions: []),
    );
    final decoded = NotificationRuleSpec.tryDecode(spec.encode())!;
    expect(decoded, spec);
    expect(decoded.delivery.actions, isEmpty);
    expect(
      spec.encode(),
      '{"v":1,"trigger":{"type":"relative","anchor":"start","offsetMinutes":-15},'
      '"delivery":{"sound":"none","actions":[]}}',
    );
  });

  test('delivery copyWith clear makes a field absent (inherit)', () {
    const d = DeliverySpec(sound: 'none', importance: 'high');
    final cleared = d.copyWith(clear: {'sound'});
    expect(cleared.sound, isNull);
    expect(cleared.importance, 'high');
    expect(cleared.toJson().containsKey('sound'), isFalse);
  });

  test('profile spec round-trips and detects channel changes', () {
    const p = ProfileSpec(
      delivery: DeliverySpec(importance: 'low', sound: 'none'),
      respectQuietHours: false,
    );
    final decoded = ProfileSpec.tryDecode(p.encode());
    expect(decoded, p);
    expect(
      p.channelChanged(
        p.copyWith(
          delivery: const DeliverySpec(importance: 'high', sound: 'none'),
        ),
      ),
      isTrue,
    );
    expect(
      p.channelChanged(
        p.copyWith(
          delivery: const DeliverySpec(importance: 'low', sound: 'none', actions: ['done']),
        ),
      ),
      isFalse,
    );
  });

  test('tryDecode returns null for garbage', () {
    expect(NotificationRuleSpec.tryDecode('not json'), isNull);
    expect(NotificationRuleSpec.tryDecode(''), isNull);
    expect(NotificationRuleSpec.tryDecode('[1]'), isNull);
  });
}
