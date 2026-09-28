/// Build flavor.
enum Flavor { dev, prod }

/// Compile-time configuration from `--dart-define-from-file=env/<flavor>.json` (T1.1.11).
///
/// Everything here is safe to ship (publishable key only). When Supabase values are missing or
/// still placeholders, the app runs in **local-only mode**: all features work offline on this
/// device and cloud sync/sign-in are disabled (see docs/guide.md to configure them).
class Env {
  const Env({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.firebaseEnabled,
    required this.featureFlags,
  });

  factory Env.fromEnvironment({Flavor? flavor}) {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    const firebase = bool.fromEnvironment('FIREBASE_ENABLED');
    const flags = String.fromEnvironment('FEATURE_FLAGS');
    return Env(
      flavor: flavor ?? (flavorName == 'prod' ? Flavor.prod : Flavor.dev),
      supabaseUrl: url,
      supabasePublishableKey: key,
      firebaseEnabled: firebase,
      featureFlags: flags.isEmpty ? const {} : flags.split(',').map((s) => s.trim()).toSet(),
    );
  }

  /// Compile-time switch for dev tools (debug menu, sync diagnostics, T1.3.16): false in builds
  /// made with `FLAVOR=prod`, so their code is tree-shaken from store builds.
  static const devToolsCompiled = String.fromEnvironment('FLAVOR', defaultValue: 'dev') != 'prod';

  final Flavor flavor;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final bool firebaseEnabled;
  final Set<String> featureFlags;

  bool get isDev => flavor == Flavor.dev;

  /// True when real Supabase credentials were provided (not empty, not a placeholder).
  bool get isSupabaseConfigured =>
      supabaseUrl.startsWith('http') &&
      !supabaseUrl.contains('YOUR_') &&
      supabasePublishableKey.isNotEmpty &&
      !supabasePublishableKey.contains('YOUR_');

  /// Human-readable configuration problems (shown in the dev debug menu).
  List<String> get warnings => [
    if (!isSupabaseConfigured) 'Supabase not configured → local-only mode (no sync, no sign-in).',
    if (!firebaseEnabled) 'Firebase disabled → no push notifications / Crashlytics (local reminders still work).',
  ];
}
