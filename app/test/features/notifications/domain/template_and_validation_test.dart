import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:everslot/features/notifications/domain/rule_validation.dart';
import 'package:everslot/features/notifications/domain/template_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TemplateEngine', () {
    test('substitutes known variables and keeps unknown ones literally', () {
      expect(
        TemplateEngine.render('{title} starts in {minutes_until} min {bogus}', {'title': 'Gym', 'minutes_until': '10'}),
        'Gym starts in 10 min {bogus}',
      );
      expect(TemplateEngine.unknownIn('{title} {bogus}'), {'bogus'});
      expect(TemplateEngine.variablesIn('{a} {b} {a}'), {'a', 'b'});
    });

    test('bidi-isolates user text in RTL locales only', () {
      final rtl = TemplateEngine.render('يبدأ {title} الآن', {'title': 'Gym'}, rtl: true);
      expect(rtl, 'يبدأ \u2068Gym\u2069 الآن');
      expect(TemplateEngine.render('{minutes_until}', {'minutes_until': '5'}, rtl: true), '5');
      expect(TemplateEngine.render('{title}', {'title': 'Gym'}), 'Gym');
    });

    test('truncates with an ellipsis and keeps isolates balanced', () {
      final long = 'x' * 100;
      final out = TemplateEngine.render('{title}', {'title': long}, maxLength: TemplateEngine.titleMax);
      expect(out.runes.length, TemplateEngine.titleMax);
      expect(out.endsWith('…'), isTrue);
      final rtl = TemplateEngine.render('{title}', {'title': long}, rtl: true, maxLength: 20);
      expect('\u2068'.allMatches(rtl).length, '\u2069'.allMatches(rtl).length);
    });

    test('every variable declares its providers', () {
      expect(TemplateVariables.forTarget(NotificationTargetType.habit).map((v) => v.name), contains('streak'));
      expect(TemplateVariables.forTarget(NotificationTargetType.task).map((v) => v.name), isNot(contains('streak')));
    });
  });

  group('NotificationRuleValidator', () {
    List<NotificationIssueCode> codes(
      NotificationRuleSpec spec, {
      NotificationTargetType? type,
      bool accept = false,
    }) => [
      for (final i in NotificationRuleValidator.validate(spec, targetType: type, acceptExtraActions: accept)) i.code,
    ];

    test('valid rule has no issues', () {
      expect(
        codes(
          const NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -10)),
          type: NotificationTargetType.task,
        ),
        isEmpty,
      );
    });
    test('anchor not available for the target type', () {
      expect(
        codes(
          const NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.due)),
          type: NotificationTargetType.task,
        ),
        [NotificationIssueCode.anchorUnavailable],
      );
    });
    test('offset beyond ±30 days', () {
      expect(
        codes(const NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -43201))),
        [NotificationIssueCode.offsetOutOfRange],
      );
      expect(
        codes(const NotificationRuleSpec(trigger: RelativeTrigger(anchor: TriggerAnchor.start, offsetMinutes: -43200))),
        isEmpty,
      );
    });
    test('repeat max > 10 and interval < 1', () {
      expect(
        codes(const NotificationRuleSpec(trigger: OverdueTrigger(), repeat: RepeatSpec(everyMinutes: 0, maxTimes: 11))),
        [NotificationIssueCode.repeatMaxTooHigh, NotificationIssueCode.repeatIntervalInvalid],
      );
    });
    test('repeats under 10 min warn about Doze without blocking', () {
      final issues = NotificationRuleValidator.validate(
        const NotificationRuleSpec(trigger: OverdueTrigger(), repeat: RepeatSpec(everyMinutes: 5, maxTimes: 5)),
      );
      expect(issues.map((i) => i.code), [NotificationIssueCode.repeatMayBeDelayed]);
      expect(issues.single.severity, NotificationIssueSeverity.warning);
      expect(
        codes(const NotificationRuleSpec(trigger: OverdueTrigger(), repeat: RepeatSpec(everyMinutes: 10, maxTimes: 5))),
        isEmpty,
      );
    });
    test('escalation steps ascend from repeat 1 and name a profile (T7.2.23)', () {
      NotificationRuleSpec spec(List<EscalationStep> steps) => NotificationRuleSpec(
        trigger: const OverdueTrigger(),
        repeat: RepeatSpec(everyMinutes: 10, maxTimes: 5, escalation: steps),
      );
      expect(
        codes(
          spec(const [
            EscalationStep(fromRepeat: 2, profile: 'nag'),
            EscalationStep(fromRepeat: 4, profile: 'alarm', allDevices: true),
          ]),
        ),
        isEmpty,
      );
      for (final bad in [
        const [EscalationStep(fromRepeat: 0, profile: 'nag')],
        const [EscalationStep(fromRepeat: 3, profile: 'nag'), EscalationStep(fromRepeat: 3, profile: 'alarm')],
        const [EscalationStep(fromRepeat: 11, profile: 'alarm')],
        const [EscalationStep(fromRepeat: 2, profile: '')],
      ]) {
        expect(codes(spec(bad)), [NotificationIssueCode.escalationInvalid]);
      }
      final json = spec(const [EscalationStep(fromRepeat: 2, profile: 'alarm', allDevices: true)]).toJson();
      expect(NotificationRuleSpec.fromJson(json).repeat!.stepFor(3)!.allDevices, isTrue);
      expect(NotificationRuleSpec.fromJson(json).repeat!.stepFor(1), isNull);
    });
    test('more than 3 actions is an error unless accepted (then a warning)', () {
      const spec = NotificationRuleSpec(
        trigger: OverdueTrigger(),
        delivery: DeliverySpec(actions: ['done', 'snooze', 'skip', 'open']),
      );
      expect(NotificationRuleValidator.validate(spec).single.isError, isTrue);
      expect(
        NotificationRuleValidator.validate(spec, acceptExtraActions: true).single.severity,
        NotificationIssueSeverity.warning,
      );
    });
    test('unknown or unavailable template variables and empty title', () {
      expect(
        codes(
          const NotificationRuleSpec(
            trigger: OverdueTrigger(),
            content: ContentSpec(body: '{nope}'),
          ),
        ),
        [NotificationIssueCode.unknownVariable],
      );
      expect(
        codes(
          const NotificationRuleSpec(
            trigger: OverdueTrigger(),
            content: ContentSpec(body: '{streak}'),
          ),
          type: NotificationTargetType.task,
        ),
        [NotificationIssueCode.unknownVariable],
      );
      expect(
        codes(
          const NotificationRuleSpec(
            trigger: OverdueTrigger(),
            content: ContentSpec(title: '  '),
          ),
        ),
        [NotificationIssueCode.emptyContent],
      );
    });
    test('invalid schedule delegates to the recurrence validator', () {
      expect(codes(const NotificationRuleSpec(trigger: ScheduleTrigger(recurrence: {'freq': 'fortnightly'}))), [
        NotificationIssueCode.scheduleInvalid,
      ]);
    });
    test('lateness < 1 min and no delivery channel', () {
      expect(codes(const NotificationRuleSpec(trigger: OverdueTrigger(), delivery: DeliverySpec(latenessMinutes: 0))), [
        NotificationIssueCode.latenessTooSmall,
      ]);
      expect(
        codes(
          const NotificationRuleSpec(
            trigger: OverdueTrigger(),
            delivery: DeliverySpec(system: false, inbox: false, banner: false),
          ),
        ),
        [NotificationIssueCode.noDeliveryChannel],
      );
    });
  });
}
