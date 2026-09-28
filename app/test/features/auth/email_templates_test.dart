import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Localized auth e-mail templates (T1.5.15, `supabase/templates`). GoTrue renders them with Go
/// templates; this test evaluates the only constructs they use (locale branches and variables) so
/// each locale's output can be checked without a local stack. Mailpit check: manual (guide.md).
String render(String template, {required String? locale, Map<String, String> vars = const {}}) {
  final l = locale ?? 'en';
  var src = template.replaceAll(RegExp(r'\{\{ \$l := or \.Data\.locale "en" \}\}'), '');
  // Innermost-free, non-nested conditionals: if / else if / else / end.
  final block = RegExp(r'\{\{ if eq \$l "(\w+)" \}\}([\s\S]*?)\{\{ end \}\}');
  src = src.replaceAllMapped(block, (m) {
    final body = '{{ if eq \$l "${m[1]}" }}${m[2]}';
    final branches = RegExp(r'\{\{ (?:if eq \$l "(\w+)"|else if eq \$l "(\w+)"|else) \}\}([\s\S]*?)(?=\{\{ (?:else|end)|$)')
        .allMatches(body);
    for (final b in branches) {
      final cond = b[1] ?? b[2];
      if (cond == null || cond == l) return b[3]!;
    }
    return '';
  });
  for (final v in vars.entries) {
    src = src.replaceAll('{{ .${v.key} }}', v.value);
  }
  return src;
}

void main() {
  final dir = Directory('../supabase/templates');
  const types = ['magic_link', 'confirmation', 'email_change', 'reauthentication'];
  const vars = {'Token': '482913', 'ConfirmationURL': 'https://x.test/verify', 'NewEmail': 'new@example.com'};

  test('every template exists and is wired in config.toml', () {
    final config = File('../supabase/config.toml').readAsStringSync();
    for (final t in types) {
      expect(File('${dir.path}/$t.html').existsSync(), isTrue, reason: t);
      expect(config, contains('[auth.email.template.$t]'));
      expect(config, contains('content_path = "./supabase/templates/$t.html"'));
    }
  });

  test('template tags are balanced and only use the evaluated constructs', () {
    for (final t in types) {
      final src = File('${dir.path}/$t.html').readAsStringSync();
      final tags = RegExp(r'\{\{[^}]*\}\}').allMatches(src).map((m) => m[0]!).toList();
      expect(tags.where((x) => x.startsWith('{{ if ')).length, tags.where((x) => x == '{{ end }}').length, reason: t);
      for (final tag in tags) {
        expect(
          RegExp(r'^\{\{ (\$l := or \.Data\.locale "en"|if eq \$l "(fr|ar)"|else if eq \$l "(fr|ar)"|else|end|\.(Token|ConfirmationURL|NewEmail)) \}\}$').hasMatch(tag),
          isTrue,
          reason: '$t: unexpected tag $tag',
        );
      }
    }
  });

  for (final t in types) {
    test('$t renders in each locale (unknown/missing → English)', () {
      final src = File('${dir.path}/$t.html').readAsStringSync();
      final en = render(src, locale: 'en', vars: vars);
      final fr = render(src, locale: 'fr', vars: vars);
      final ar = render(src, locale: 'ar', vars: vars);
      for (final out in [en, fr, ar]) {
        expect(out, contains('482913'));
        expect(out, isNot(contains('{{')), reason: 'all tags evaluated');
        if (t != 'reauthentication') expect(out, contains('https://x.test/verify'));
        if (t == 'email_change') expect(out, contains('new@example.com'));
      }
      expect(en, contains('lang="en"'));
      expect(fr, contains('lang="fr"'));
      expect(fr, contains('Saisissez ce code'));
      expect(ar, contains('lang="ar" dir="rtl"'));
      expect(ar, contains('أدخل هذا الرمز'));
      expect(ar, contains('dir="ltr" style="font-size:32px'), reason: 'the code stays left-to-right');
      expect(render(src, locale: null, vars: vars), en);
      expect(render(src, locale: 'de', vars: vars), en);
    });
  }
}
