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
    this.siteUrl = '',
    this.supportEmail = '',
  });

  factory Env.fromEnvironment({Flavor? flavor}) {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    const firebase = bool.fromEnvironment('FIREBASE_ENABLED');
    const flags = String.fromEnvironment('FEATURE_FLAGS');
    const site = String.fromEnvironment('SITE_URL');
    const support = String.fromEnvironment('SUPPORT_EMAIL');
    return Env(
      flavor: flavor ?? (flavorName == 'prod' ? Flavor.prod : Flavor.dev),
      supabaseUrl: url,
      supabasePublishableKey: key,
      firebaseEnabled: firebase,
      featureFlags: flags.isEmpty ? const {} : flags.split(',').map((s) => s.trim()).toSet(),
      siteUrl: site,
      supportEmail: support,
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

  /// Public website with the privacy policy, terms and support pages (T9.2.09), e.g.
  /// `https://everslot.example`. Empty or a placeholder hides those links (T8.3.13).
  final String siteUrl;

  /// Support contact address (About › Contact support, feedback e-mails).
  final String supportEmail;

  bool get isDev => flavor == Flavor.dev;

  /// True when real Supabase credentials were provided (not empty, not a placeholder).
  bool get isSupabaseConfigured =>
      supabaseUrl.startsWith('http') &&
      !supabaseUrl.contains('YOUR_') &&
      supabasePublishableKey.isNotEmpty &&
      !supabasePublishableKey.contains('YOUR_');

  /// `<site>/<page>` (privacy, terms, support) or null when the site is not configured.
  Uri? sitePage(String page) {
    final base = siteUrl.trim();
    if (!base.startsWith('https://') || base.contains('YOUR_')) return null;
    return Uri.parse(base.endsWith('/') ? '$base$page' : '$base/$page');
  }

  /// The support address, or null when not configured.
  String? get support {
    final e = supportEmail.trim();
    return e.contains('@') && !e.contains('YOUR_') ? e : null;
  }

  /// Human-readable configuration problems (shown in the dev debug menu).
  List<String> get warnings => [
    if (!isSupabaseConfigured) 'Supabase not configured → local-only mode (no sync, no sign-in).',
    if (!firebaseEnabled) 'Firebase disabled → no push notifications / Crashlytics (local reminders still work).',
  ];
}
