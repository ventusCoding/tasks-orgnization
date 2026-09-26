import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Nonce for Sign in with Apple (T1.5.10): Apple receives the SHA-256 of [raw] and embeds it in
/// the ID token; Supabase `signInWithIdToken` receives [raw] and checks the hash — replay-proof.
class AppleNonce {
  const AppleNonce._(this.raw, this.hashed);

  /// Generates a URL-safe random nonce of [length] characters.
  factory AppleNonce.generate({int length = 32, Random? random}) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rnd = random ?? Random.secure();
    final raw = String.fromCharCodes(
      List.generate(length, (_) => charset.codeUnitAt(rnd.nextInt(charset.length))),
    );
    return AppleNonce._(raw, sha256Hex(raw));
  }

  /// Sent to Supabase.
  final String raw;

  /// Sent to Apple (`nonce:` parameter).
  final String hashed;

  static String sha256Hex(String input) => sha256.convert(utf8.encode(input)).toString();
}
