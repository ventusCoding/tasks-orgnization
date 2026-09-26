/// Compile-time auth configuration, read from `--dart-define-from-file=env/<flavor>.json`.
///
/// None of these values is secret (OAuth client ids and CAPTCHA site keys are public
/// identifiers); secrets (Apple sign-in key, Google client secret) live in the Supabase dashboard.
class AuthConfig {
  const AuthConfig({
    this.googleWebClientId = '',
    this.googleIosClientId = '',
    this.appleSignInEnabled = false,
    this.captchaSiteKey = '',
    this.redirectUrl = defaultRedirectUrl,
    this.accountDeletionWebUrl = '',
  });

  factory AuthConfig.fromEnvironment() => const AuthConfig(
    // TODO(config): Google Cloud console → OAuth client "Web application" id — passed to
    // google_sign_in as `serverClientId` and added to Supabase › Auth › Google "Client IDs".
    googleWebClientId: String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    // TODO(config): OAuth client "iOS" id (+ reversed id as URL scheme in ios/Runner/Info.plist).
    googleIosClientId: String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
    // TODO(config): set true once Sign in with Apple is enabled in Supabase (Apple service id,
    // team id, key id and .p8 key live in the Supabase dashboard — the Android web flow uses
    // the service id + `everslot://auth-callback`; the client secret expires every 6 months).
    appleSignInEnabled: bool.fromEnvironment('APPLE_SIGN_IN_ENABLED'),
    // TODO(config): Turnstile/hCaptcha site key when CAPTCHA protection is enabled for
    // anonymous sign-ins in production (Supabase › Auth › Attack protection).
    captchaSiteKey: String.fromEnvironment('CAPTCHA_SITE_KEY'),
    // TODO(config): must be listed in Supabase › Auth › URL configuration › Redirect URLs.
    redirectUrl: String.fromEnvironment('AUTH_REDIRECT_URL', defaultValue: defaultRedirectUrl),
    // TODO(config): public account-deletion page (Google Play requirement, T9.2.09).
    accountDeletionWebUrl: String.fromEnvironment('ACCOUNT_DELETION_URL'),
  );

  static const defaultRedirectUrl = 'everslot://auth-callback';

  final String googleWebClientId;
  final String googleIosClientId;
  final bool appleSignInEnabled;
  final String captchaSiteKey;
  final String redirectUrl;
  final String accountDeletionWebUrl;

  static bool _isReal(String value) => value.isNotEmpty && !value.contains('YOUR_');

  bool get googleConfigured => _isReal(googleWebClientId);
  bool get captchaConfigured => _isReal(captchaSiteKey);
}
