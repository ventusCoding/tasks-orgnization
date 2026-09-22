/// Whether the app syncs with a Supabase account or keeps data on this device only.
enum SessionMode { localOnly, cloud }

/// The signed-in (or local) user.
class AppSession {
  const AppSession({
    required this.userId,
    required this.mode,
    this.email,
    this.isAnonymous = false,
  });

  final String userId;
  final SessionMode mode;
  final String? email;

  /// Cloud guest account (anonymous sign-in) that can be upgraded later (T1.5.11).
  final bool isAnonymous;

  bool get isLocalOnly => mode == SessionMode.localOnly;
  bool get isCloud => mode == SessionMode.cloud;

  @override
  bool operator ==(Object other) =>
      other is AppSession &&
      other.userId == userId &&
      other.mode == mode &&
      other.email == email &&
      other.isAnonymous == isAnonymous;

  @override
  int get hashCode => Object.hash(userId, mode, email, isAnonymous);
}
