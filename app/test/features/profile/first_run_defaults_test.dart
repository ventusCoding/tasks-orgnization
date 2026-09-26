import 'package:everslot/features/profile/domain/first_run_defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('week start per CLDR (T1.5.05)', () {
    test('en_US → Sunday, fr_FR → Monday, ar_TN → Monday, ar_EG → Saturday', () {
      expect(FirstRunDefaults.weekStartFor('en', 'US'), 7);
      expect(FirstRunDefaults.weekStartFor('fr', 'FR'), 1);
      expect(FirstRunDefaults.weekStartFor('ar', 'TN'), 1);
      expect(FirstRunDefaults.weekStartFor('ar', 'EG'), 6);
    });

    test('other regions follow the territory, not the language', () {
      expect(FirstRunDefaults.weekStartFor('en', 'GB'), 1);
      expect(FirstRunDefaults.weekStartFor('fr', 'CA'), 7);
      expect(FirstRunDefaults.weekStartFor('ar', 'SA'), 7);
      expect(FirstRunDefaults.weekStartFor('ar', 'MA'), 1);
      expect(FirstRunDefaults.weekStartFor('ar', 'DZ'), 6);
      expect(FirstRunDefaults.weekStartFor('dv', 'MV'), 5);
      expect(FirstRunDefaults.weekStartFor('fr', 'be'), 1, reason: 'case-insensitive');
    });

    test('a bare language uses its likely region', () {
      expect(FirstRunDefaults.weekStartFor('en'), 7);
      expect(FirstRunDefaults.weekStartFor('fr'), 1);
      expect(FirstRunDefaults.weekStartFor('ar'), 6);
      expect(FirstRunDefaults.weekStartFor('xx'), 1, reason: 'world default (001) is Monday');
    });
  });

  group('clock format', () {
    test('locale conventions', () {
      expect(FirstRunDefaults.prefers24h('en', 'US'), isFalse);
      expect(FirstRunDefaults.prefers24h('en', 'GB'), isTrue);
      expect(FirstRunDefaults.prefers24h('fr', 'FR'), isTrue);
      expect(FirstRunDefaults.prefers24h('ar', 'EG'), isFalse);
      expect(FirstRunDefaults.prefers24h('ar', 'TN'), isTrue);
      expect(FirstRunDefaults.prefers24h('ar'), isFalse);
    });

    test('the device 24-hour switch wins', () {
      expect(FirstRunDefaults.prefers24h('en', 'US', true), isTrue);
      expect(FirstRunDefaults.prefers24h('fr', 'FR', false), isTrue, reason: 'off = locale default');
    });
  });

  test('interface language falls back to English', () {
    expect(FirstRunDefaults.languageFor('FR'), 'fr');
    expect(FirstRunDefaults.languageFor('ar'), 'ar');
    expect(FirstRunDefaults.languageFor('de'), 'en');
  });
}
