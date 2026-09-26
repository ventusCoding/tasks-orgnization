/// Bidi helpers for mixed-direction text (T1.3.14), e.g. a Latin task title inside an Arabic
/// sentence, or a code/number that must keep its left-to-right order in an RTL layout.
///
/// Unicode isolates (UAX #9) keep the wrapped run from reordering its neighbours — unlike
/// embeddings, they never leak direction into the surrounding text. Flutter renders them invisibly.
abstract final class BidiText {
  static const lri = '\u2066'; // LEFT-TO-RIGHT ISOLATE
  static const rli = '\u2067'; // RIGHT-TO-LEFT ISOLATE
  static const fsi = '\u2068'; // FIRST STRONG ISOLATE
  static const pdi = '\u2069'; // POP DIRECTIONAL ISOLATE

  /// A run that must read left-to-right (codes, file names, URLs, "#tag", "v1.2.3").
  static String ltr(String text) => '$lri$text$pdi';

  /// A run that must read right-to-left inside left-to-right text.
  static String rtl(String text) => '$rli$text$pdi';

  /// User content of unknown direction (titles, names) inserted into a localized sentence: its
  /// direction comes from its first strong character and it cannot disturb the sentence.
  static String isolate(String text) => '$fsi$text$pdi';

  /// Removes isolate/embedding/mark controls (for comparisons, search and copy).
  static String strip(String text) => text.replaceAll(_controls, '');

  static final _controls = RegExp('[\u200e\u200f\u202a-\u202e\u2066-\u2069]');

  /// Whether [text] starts (first strong character) right-to-left.
  static bool startsRtl(String text) {
    for (final rune in text.runes) {
      if (_isRtl(rune)) return true;
      if (_isLtr(rune)) return false;
    }
    return false;
  }

  static bool _isRtl(int c) =>
      (c >= 0x0590 &&
          c <= 0x08FF) || // Hebrew, Arabic, Syriac, Thaana, NKo, Arabic ext.
      (c >= 0xFB1D && c <= 0xFDFF) || // Hebrew/Arabic presentation forms A
      (c >= 0xFE70 && c <= 0xFEFF); // Arabic presentation forms B

  static bool _isLtr(int c) =>
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      (c >= 0xC0 &&
          c <= 0x024F &&
          c != 0xD7 &&
          c != 0xF7) || // Latin-1 / Extended letters
      (c >= 0x0370 && c <= 0x058F); // Greek, Cyrillic, Armenian
}
