import 'package:everslot/features/checklists/domain/collation.dart';

/// Command palette matching (T8.1.18): every query word must hit the title or a keyword — a word
/// start scores highest, then a keyword, then any substring, then the letters in order
/// ("nwtsk" → *New task*). Case, French accents and Arabic letter variants are ignored.
abstract final class CommandMatching {
  static final _split = RegExp(r'[\s›>/·:,.-]+');

  /// Relevance of [query] for a command (higher is better); null when it does not match.
  /// An empty query matches everything with score 0.
  static double? score(String query, String title, {List<String> keywords = const []}) {
    final words = [
      for (final w in Collation.key(query).split(_split))
        if (w.isNotEmpty) w,
    ];
    if (words.isEmpty) return 0;
    final t = Collation.key(title);
    final titleWords = t.split(_split).where((w) => w.isNotEmpty).toList();
    final keys = [for (final k in keywords) Collation.key(k)];
    var total = 0.0;
    for (final w in words) {
      final double hit;
      if (titleWords.any((tw) => tw.startsWith(w))) {
        hit = 3;
      } else if (keys.any((k) => k.startsWith(w))) {
        hit = 2;
      } else if (t.contains(w) || keys.any((k) => k.contains(w))) {
        hit = 1;
      } else if (_subsequence(w, t.replaceAll(' ', ''))) {
        hit = 0.5;
      } else {
        return null;
      }
      total += hit;
    }
    // Prefer titles that start with the first word, then shorter titles.
    if (t.startsWith(words.first)) total += 1;
    return total - t.length / 1000;
  }

  /// [items] matching [query], best first (stable for equal scores).
  static List<T> rank<T>(
    String query,
    List<T> items, {
    required String Function(T item) title,
    List<String> Function(T item)? keywords,
  }) {
    final scored = <(T, double, int)>[];
    for (final (i, item) in items.indexed) {
      final s = score(query, title(item), keywords: keywords?.call(item) ?? const []);
      if (s != null) scored.add((item, s, i));
    }
    if (query.trim().isEmpty) return [for (final s in scored) s.$1];
    scored.sort((a, b) => b.$2 != a.$2 ? b.$2.compareTo(a.$2) : a.$3.compareTo(b.$3));
    return [for (final s in scored) s.$1];
  }

  static bool _subsequence(String needle, String hay) {
    var i = 0;
    for (var j = 0; j < hay.length && i < needle.length; j++) {
      if (hay[j] == needle[i]) i++;
    }
    return i == needle.length;
  }
}
