import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:material_ui/material_ui.dart';

/// Localized text for an auth failure (never shows developer details).
String authFailureMessage(BuildContext context, AuthFailureCode code) {
  final l = context.l10n;
  return switch (code) {
    AuthFailureCode.invalidEmail => l.authErrorInvalidEmail,
    AuthFailureCode.invalidCode => l.authErrorInvalidCode,
    AuthFailureCode.rateLimited => l.authErrorRateLimited,
    AuthFailureCode.offline => l.authErrorOffline,
    AuthFailureCode.cancelled => l.authErrorUnknown,
    AuthFailureCode.emailInUse => l.authErrorEmailInUse,
    AuthFailureCode.identityInUse => l.authErrorIdentityInUse,
    AuthFailureCode.notConfigured => l.authErrorNotConfigured,
    AuthFailureCode.providerNotConfigured => l.authErrorProviderNotConfigured,
    AuthFailureCode.captchaRequired => l.authErrorCaptcha,
    AuthFailureCode.guestDisabled => l.authErrorGuestDisabled,
    AuthFailureCode.sessionExpired => l.authErrorSessionExpired,
    AuthFailureCode.lastIdentity => l.authErrorLastIdentity,
    AuthFailureCode.mfaRequired => l.authErrorMfaRequired,
    AuthFailureCode.unknown => l.authErrorUnknown,
  };
}

/// Display name of an identity provider.
String providerLabel(BuildContext context, String provider) => switch (provider) {
  'google' => context.l10n.authProviderGoogle,
  'apple' => context.l10n.authProviderApple,
  'email' => context.l10n.authProviderEmail,
  _ => provider,
};

/// Inline error line announced to screen readers.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(top: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: context.colors.error),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(message, style: context.text.bodySmall?.copyWith(color: context.colors.error)),
          ),
        ],
      ),
    ),
  );
}
