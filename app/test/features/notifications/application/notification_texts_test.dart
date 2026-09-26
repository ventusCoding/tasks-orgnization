import 'package:everslot/features/notifications/application/notification_texts_l10n.dart';
import 'package:everslot/features/notifications/domain/template_engine.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

/// Built-in localized default templates per trigger kind (T7.1.08): every kind renders in EN,
/// FR and AR (ICU plurals, no leftover placeholders), statuses are localized, redaction exists.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const vars = {
    'title': 'Gym',
    'start_time': '08:00',
    'end_time': '09:00',
    'date': '22 Sep 2026',
    'status': 'waiting',
    'status_age': '3 days',
    'status_note': 'Waiting for the quote',
    'done': '1',
    'target': '3',
    'next_milestone': '24 h',
    'kind': 'daily_agenda',
    'summary': '3 tasks',
  };

  for (final locale in const ['en', 'fr', 'ar']) {
    group(locale, () {
      final texts = L10nNotificationTexts.forLocale(locale);

      test('every default content kind renders without placeholders', () {
        for (final kind in DefaultContentKind.values) {
          for (final count in const [0, 1, 2, 3, 11, 100]) {
            final c = texts.defaultContent(kind, vars, count: count);
            expect(c.title, isNotEmpty, reason: '$locale $kind');
            for (final s in [c.title, ?c.body]) {
              expect(
                s,
                isNot(contains('{')),
                reason: '$locale $kind $count: $s',
              );
              expect(
                s,
                isNot(contains('}')),
                reason: '$locale $kind $count: $s',
              );
            }
          }
        }
      });

      test('redaction, merge, saturation and digest texts exist', () {
        expect(texts.redactedTitle, isNotEmpty);
        expect(texts.redactedBody, isNotEmpty);
        expect(texts.mergedTitle(3), contains('3'));
        expect(texts.saturationTitle, isNotEmpty);
        expect(texts.saturationBody, isNotEmpty);
        for (final kind in const [
          'daily_agenda',
          'plan_tomorrow',
          'evening_review',
          'overdue_summary',
          'weekly_review',
          'monthly_report',
        ]) {
          expect(texts.digestTitle(kind), isNotEmpty);
        }
        expect(
          texts.digestSummary(
            'daily_agenda',
            tasks: 2,
            habits: 1,
            items: 0,
            first: 'Gym 08:00',
          ),
          contains('Gym 08:00'),
        );
      });
    });
  }

  test('English sentences read naturally', () {
    final en = L10nNotificationTexts.forLocale('en');
    expect(
      en.defaultContent(DefaultContentKind.beforeStart, vars, count: 10).body,
      'Starts in 10 min · 08:00–09:00',
    );
    expect(
      en.defaultContent(DefaultContentKind.atStart, vars).body,
      'Starting now · 08:00–09:00',
    );
    expect(
      en.defaultContent(DefaultContentKind.followUp, vars).title,
      'Follow up: Gym',
    );
    expect(
      en.defaultContent(DefaultContentKind.streakRisk, vars, count: 1).body,
      'Keep your 1-day streak alive',
    );
    expect(
      en.defaultContent(DefaultContentKind.streakRisk, vars, count: 7).body,
      'Keep your 7-day streak alive',
    );
    expect(
      en.defaultContent(DefaultContentKind.statusAge, {
        ...vars,
        'status': en.status('waiting'),
      }).body,
      'Still waiting · 3 days',
    );
  });

  test('statuses are localized in sentences', () {
    expect(
      L10nNotificationTexts.forLocale('fr').status('waiting'),
      'en attente',
    );
    expect(
      L10nNotificationTexts.forLocale('fr').status('in_progress'),
      'en cours',
    );
    expect(L10nNotificationTexts.forLocale('ar').status('blocked'), 'متوقفًا');
    expect(
      L10nNotificationTexts.forLocale('en').status('custom_status'),
      'custom_status',
    );
    expect(const PlainNotificationTexts().status('in_progress'), 'in progress');
  });

  test('Arabic plurals follow the six CLDR forms', () {
    final ar = L10nNotificationTexts.forLocale('ar');
    final bodies = {
      for (final n in const [0, 1, 2, 3, 11, 100])
        ar.defaultContent(DefaultContentKind.beforeStart, const {
          'title': 'x',
        }, count: n).body,
    };
    expect(bodies, hasLength(greaterThanOrEqualTo(4)));
  });

  test('times follow the 12/24 h preference', () {
    final h12 = L10nNotificationTexts.forLocale('en', use24h: false);
    final h24 = L10nNotificationTexts.forLocale('en');
    final t = LocalDateTime.of(2026, 9, 22, 20, 5);
    expect(h24.time(t), '20:05');
    expect(h12.time(t), matches(RegExp(r'^8:05\sPM$')));
  });
}
