/// Fractional indexing for user-orderable lists (arch §9.4).
///
/// Port of the widely used algorithm by David Greenspan / rocicorp `fractional-indexing`
/// (base-62 digits, variable-length integer part). Keys compare by raw bytes (Dart `compareTo`
/// on ASCII strings, SQLite BINARY, Postgres `COLLATE "C"`).
abstract final class FractionalIndex {
  static const digits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  static const _zero = '0';
  static const _smallestInteger = 'A00000000000000000000000000';

  /// Key strictly between [a] and [b] (either may be null = open end).
  static String between(String? a, String? b) {
    if (a != null) _validateKey(a);
    if (b != null) _validateKey(b);
    if (a != null && b != null && a.compareTo(b) >= 0) {
      throw ArgumentError('$a >= $b');
    }
    if (a == null) {
      if (b == null) return 'a0';
      final ib = _integerPart(b);
      final fb = b.substring(ib.length);
      if (ib == _smallestInteger) return ib + _midpoint('', fb);
      if (ib.compareTo(b) < 0) return ib;
      final res = _decrementInteger(ib);
      if (res == null) throw StateError('cannot decrement any more');
      return res;
    }
    if (b == null) {
      final ia = _integerPart(a);
      final fa = a.substring(ia.length);
      final i = _incrementInteger(ia);
      return i ?? ia + _midpoint(fa, null);
    }
    final ia = _integerPart(a);
    final fa = a.substring(ia.length);
    final ib = _integerPart(b);
    final fb = b.substring(ib.length);
    if (ia == ib) return ia + _midpoint(fa, fb);
    final i = _incrementInteger(ia);
    if (i == null) throw StateError('cannot increment any more');
    if (i.compareTo(b) < 0) return i;
    return ia + _midpoint(fa, null);
  }

  /// [n] keys evenly spread between [a] and [b].
  static List<String> nBetween(String? a, String? b, int n) {
    if (n <= 0) return const [];
    if (n == 1) return [between(a, b)];
    if (b == null) {
      var c = between(a, b);
      final result = [c];
      for (var i = 0; i < n - 1; i++) {
        c = between(c, b);
        result.add(c);
      }
      return result;
    }
    if (a == null) {
      var c = between(a, b);
      final result = [c];
      for (var i = 0; i < n - 1; i++) {
        c = between(a, c);
        result.add(c);
      }
      return result.reversed.toList();
    }
    final mid = n ~/ 2;
    final c = between(a, b);
    return [...nBetween(a, c, mid), c, ...nBetween(c, b, n - mid - 1)];
  }

  static bool isValid(String key) {
    try {
      _validateKey(key);
      return true;
    } on Object {
      return false;
    }
  }

  static String _midpoint(String a, String? b) {
    if (b != null && a.compareTo(b) >= 0) throw ArgumentError('$a >= $b');
    if (a.endsWith(_zero) || (b != null && b.endsWith(_zero))) {
      throw ArgumentError('trailing zero');
    }
    if (b != null) {
      var n = 0;
      while ((n < a.length ? a[n] : _zero) == b[n]) {
        n++;
      }
      if (n > 0) return b.substring(0, n) + _midpoint(a.substring(n), b.substring(n));
    }
    final digitA = a.isNotEmpty ? digits.indexOf(a[0]) : 0;
    final digitB = b != null ? digits.indexOf(b[0]) : digits.length;
    if (digitB - digitA > 1) {
      final midDigit = ((digitA + digitB) / 2).round();
      return digits[midDigit];
    }
    if (b != null && b.length > 1) return b.substring(0, 1);
    return digits[digitA] + _midpoint(a.isNotEmpty ? a.substring(1) : '', null);
  }

  static int _integerLength(String head) {
    final c = head.codeUnitAt(0);
    if (c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0)) {
      return c - 'a'.codeUnitAt(0) + 2;
    }
    if (c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0)) {
      return 'Z'.codeUnitAt(0) - c + 2;
    }
    throw ArgumentError('invalid order key head: $head');
  }

  static String _integerPart(String key) {
    final len = _integerLength(key[0]);
    if (len > key.length) throw ArgumentError('invalid order key: $key');
    return key.substring(0, len);
  }

  static void _validateKey(String key) {
    if (key.isEmpty) throw ArgumentError('empty key');
    if (key == _smallestInteger) throw ArgumentError('invalid order key: $key');
    for (final ch in key.split('')) {
      if (!digits.contains(ch)) throw ArgumentError('invalid character in key: $key');
    }
    final i = _integerPart(key);
    final f = key.substring(i.length);
    if (f.endsWith(_zero)) throw ArgumentError('invalid order key: $key');
  }

  static String? _incrementInteger(String x) {
    final head = x[0];
    final digs = x.substring(1).split('');
    var carry = true;
    for (var i = digs.length - 1; carry && i >= 0; i--) {
      final d = digits.indexOf(digs[i]) + 1;
      if (d == digits.length) {
        digs[i] = _zero;
      } else {
        digs[i] = digits[d];
        carry = false;
      }
    }
    if (carry) {
      if (head == 'Z') return 'a$_zero';
      if (head == 'z') return null;
      final h = String.fromCharCode(head.codeUnitAt(0) + 1);
      if (h.compareTo('a') > 0) {
        digs.add(_zero);
      } else {
        digs.removeLast();
      }
      return h + digs.join();
    }
    return head + digs.join();
  }

  static String? _decrementInteger(String x) {
    final head = x[0];
    final digs = x.substring(1).split('');
    var borrow = true;
    for (var i = digs.length - 1; borrow && i >= 0; i--) {
      final d = digits.indexOf(digs[i]) - 1;
      if (d == -1) {
        digs[i] = digits[digits.length - 1];
      } else {
        digs[i] = digits[d];
        borrow = false;
      }
    }
    if (borrow) {
      if (head == 'a') return 'Z${digits[digits.length - 1]}';
      if (head == 'A') return null;
      final h = String.fromCharCode(head.codeUnitAt(0) - 1);
      if (h.compareTo('Z') < 0) {
        digs.add(digits[digits.length - 1]);
      } else {
        digs.removeLast();
      }
      return h + digs.join();
    }
    return head + digs.join();
  }
}
