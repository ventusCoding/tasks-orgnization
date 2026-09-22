/// CLDR plural categories.
enum PluralCategory { zero, one, two, few, many, other }

/// CLDR cardinal plural category of the integer [n] for [locale]
/// (`en`, `fr`, `ar`; other locales fall back to the English rule).
PluralCategory pluralCategory(String locale, int n) {
  final abs = n.abs();
  switch (_language(locale)) {
    case 'ar':
      if (abs == 0) return PluralCategory.zero;
      if (abs == 1) return PluralCategory.one;
      if (abs == 2) return PluralCategory.two;
      final mod = abs % 100;
      if (mod >= 3 && mod <= 10) return PluralCategory.few;
      if (mod >= 11 && mod <= 99) return PluralCategory.many;
      return PluralCategory.other;
    case 'fr':
      if (abs == 0 || abs == 1) return PluralCategory.one;
      if (abs != 0 && abs % 1000000 == 0) return PluralCategory.many;
      return PluralCategory.other;
    default:
      return abs == 1 ? PluralCategory.one : PluralCategory.other;
  }
}

/// Picks the message for [n] from a map keyed by category name
/// (`zero`, `one`, `two`, `few`, `many`, `other`), falling back to `other`,
/// and substitutes `{n}`.
String selectPlural(String locale, int n, Map<String, String> forms) {
  final category = pluralCategory(locale, n);
  final template = forms[category.name] ?? forms['other']!;
  return template.replaceAll('{n}', '$n');
}

String _language(String locale) => locale.split(RegExp('[-_]')).first.toLowerCase();
