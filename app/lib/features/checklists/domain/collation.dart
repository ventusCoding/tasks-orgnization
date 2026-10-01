/// Locale-tolerant text collation for sorting and filtering (T4.2.04, T4.1.13): case-insensitive,
/// ignores French/Latin diacritics and Arabic letter variants / harakat, so "École" sorts with
/// "ecole" and "أحمد" matches "احمد".
abstract final class Collation {
  static const _latin = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae', //
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ø': 'o',
    'œ': 'oe',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', 'ß': 'ss',
  };

  /// Normalized collation key.
  static String key(String input) {
    final lower = input.toLowerCase();
    final out = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      final latin = _latin[ch];
      if (latin != null) {
        out.write(latin);
        continue;
      }
      // Arabic harakat, tatweel and Quranic marks are ignored.
      if ((rune >= 0x064B && rune <= 0x065F) || rune == 0x0670 || rune == 0x0640) continue;
      // Combining diacritical marks (decomposed accents).
      if (rune >= 0x0300 && rune <= 0x036F) continue;
      switch (rune) {
        case 0x0623 || 0x0625 || 0x0622 || 0x0671:
          out.write('ا');
        case 0x0649:
          out.write('ي');
        case 0x0629:
          out.write('ه');
        case 0x0624:
          out.write('و');
        case 0x0626:
          out.write('ي');
        default:
          out.write(ch);
      }
    }
    return out.toString().trim();
  }

  static int compare(String a, String b) {
    final c = key(a).compareTo(key(b));
    return c != 0 ? c : a.compareTo(b);
  }

  /// Whether [text] contains [query] under collation.
  static bool contains(String text, String query) {
    final q = key(query);
    return q.isEmpty || key(text).contains(q);
  }
}
