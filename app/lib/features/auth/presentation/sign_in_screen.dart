import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/application/account_service.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/application/sign_in_controller.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/domain/auth_redirect.dart';
import 'package:everslot/features/auth/presentation/account_flows.dart';
import 'package:everslot/features/auth/presentation/auth_messages.dart';
import 'package:everslot/features/auth/presentation/sign_out_flow.dart';
import 'package:everslot/features/auth/presentation/widgets/otp_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Sign-in (T1.5.03, T1.5.09–T1.5.11): e-mail code first (the magic link in the same e-mail
/// completes through `everslot://auth-callback`), then Google / Apple, guest mode and "use on
/// this device only". [from] is the location to resume after signing in (deep links, T1.5.02);
/// [mode] = `reauth` re-authenticates the current account (T1.5.14).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.from, this.mode});

  final String? from;
  final String? mode;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  Timer? _ticker;

  bool get _reauth => widget.mode == 'reauth';

  @override
  void initState() {
    super.initState();
    final email = ref.read(sessionProvider)?.email;
    if (_reauth && email != null) {
      _email.text = email;
      // Providers can't be modified while the tree builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(signInControllerProvider.notifier).prefill(email);
      });
    }
    // Re-renders the resend countdown.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && ref.read(signInControllerProvider).step == SignInStep.code) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _email.dispose();
    super.dispose();
  }

  void _done() => unawaited(_finish());

  Future<void> _finish() async {
    if (!mounted) return;
    // Two-step verification (T1.5.17): the authenticator code completes the sign-in; declining
    // signs out again through the usual flow (unsynced-changes guard).
    while (ref.read(accountServiceProvider).mfaStepUpRequired) {
      final verified = await runMfaStepUpFlow(context, ref);
      if (!mounted) return;
      if (verified) break;
      await runSignOutFlow(context, ref);
      // Signed out: stay here. Sign-out cancelled: ask for the code again.
      if (!mounted || ref.read(sessionProvider) == null) return;
    }
    GoRouter.maybeOf(context)?.go(AuthRedirect.safeFrom(widget.from) ?? AuthRedirect.home);
  }

  Future<void> _run(Future<bool> Function() action) async {
    if (await action()) _done();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(signInControllerProvider);
    final available = ref.watch(cloudAuthAvailableProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: Text(_reauth ? l.authReauthTitle : l.appName),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, Space.lg, Space.xl, Space.xxl),
              children: [
                if (!available)
                  _NotConfigured(onContinue: _done)
                else if (state.step == SignInStep.code)
                  _CodeStep(state: state, onVerified: _done)
                else
                  _StartStep(email: _email, state: state, reauth: _reauth, run: _run),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.event_available, size: 48, color: context.colors.primary),
      const SizedBox(height: Space.lg),
      Semantics(header: true, child: Text(title, style: context.text.headlineSmall)),
      const SizedBox(height: Space.sm),
      Text(body, style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant)),
      const SizedBox(height: Space.xl),
    ],
  );
}

class _StartStep extends ConsumerWidget {
  const _StartStep({required this.email, required this.state, required this.reauth, required this.run});

  final TextEditingController email;
  final SignInState state;
  final bool reauth;
  final Future<void> Function(Future<bool> Function()) run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final controller = ref.read(signInControllerProvider.notifier);
    final repo = ref.watch(authRepositoryProvider);
    final session = ref.watch(sessionProvider);
    final busy = state.busy;
    final emailError = state.error == AuthFailureCode.invalidEmail;
    void submit() => unawaited(controller.submitEmail(email.text));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          title: reauth ? l.authReauthTitle : l.authWelcomeTitle,
          body: reauth ? l.authReauthBody : l.authWelcomeBody,
        ),
        AutofillGroup(
          child: TextField(
            key: const ValueKey('sign-in-email'),
            controller: email,
            enabled: busy == null,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: l.authEmailLabel,
              hintText: l.authEmailHint,
              errorText: emailError ? l.authErrorInvalidEmail : null,
            ),
            onSubmitted: (_) => submit(),
          ),
        ),
        const SizedBox(height: Space.md),
        FilledButton(
          key: const ValueKey('sign-in-send-code'),
          onPressed: busy == null ? submit : null,
          child: busy == AuthMethod.email ? const _Spinner() : Text(l.authSendCode),
        ),
        if (state.error != null && !emailError) AuthErrorText(authFailureMessage(context, state.error!)),
        if (state.browserFlowStarted) ...[
          const SizedBox(height: Space.md),
          Text(l.authBrowserFlowStarted, style: context.text.bodyMedium),
        ],
        if ((repo?.googleAvailable ?? false) || (repo?.appleAvailable ?? false)) ...[
          _OrDivider(label: l.authOr),
          if (repo!.appleAvailable)
            OutlinedButton.icon(
              key: const ValueKey('sign-in-apple'),
              onPressed: busy == null ? () => run(controller.signInWithApple) : null,
              icon: busy == AuthMethod.apple ? const _Spinner() : const Icon(Icons.apple),
              label: Text(l.authContinueApple),
            ),
          if (repo.appleAvailable && repo.googleAvailable) const SizedBox(height: Space.sm),
          if (repo.googleAvailable)
            OutlinedButton.icon(
              key: const ValueKey('sign-in-google'),
              onPressed: busy == null ? () => run(controller.signInWithGoogle) : null,
              icon: busy == AuthMethod.google ? const _Spinner() : const Icon(Icons.g_mobiledata),
              label: Text(l.authContinueGoogle),
            ),
        ],
        if (!reauth) ...[
          const SizedBox(height: Space.xl),
          if (session == null || session.isLocalOnly)
            _SecondaryAction(
              key: const ValueKey('sign-in-guest'),
              label: l.authContinueGuest,
              hint: l.authGuestHint,
              busy: busy == AuthMethod.anonymous,
              onPressed: busy == null ? () => run(controller.continueAsGuest) : null,
            ),
          if (session == null)
            _SecondaryAction(
              key: const ValueKey('sign-in-local-only'),
              label: l.authUseLocalOnly,
              hint: l.authUseLocalOnlyHint,
              onPressed: busy == null
                  ? () => run(() async {
                      await controller.useOnThisDeviceOnly();
                      return true;
                    })
                  : null,
            ),
          const SizedBox(height: Space.lg),
          Text(
            l.authLegalNote,
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _CodeStep extends ConsumerWidget {
  const _CodeStep({required this.state, required this.onVerified});

  final SignInState state;
  final VoidCallback onVerified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final controller = ref.read(signInControllerProvider.notifier);
    final now = ref.read(clockProvider).nowUtc();
    final at = state.resendAvailableAt;
    final wait = at == null ? 0 : at.difference(now).inSeconds + (at.difference(now).inMilliseconds % 1000 > 0 ? 1 : 0);
    final codeError = state.error == AuthFailureCode.invalidCode;
    Future<void> verify(String code) async {
      if (await controller.verifyCode(code)) onVerified();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(title: l.authCodeTitle, body: l.authCodeBody(state.email)),
        OtpField(
          key: const ValueKey('sign-in-code'),
          label: l.authCodeLabel,
          enabled: !state.isBusy,
          errorText: codeError ? l.authErrorInvalidCode : null,
          onCompleted: (code) => unawaited(verify(code)),
        ),
        if (state.error != null && !codeError) AuthErrorText(authFailureMessage(context, state.error!)),
        const SizedBox(height: Space.lg),
        if (state.isBusy) const Center(child: _Spinner(size: 28)),
        const SizedBox(height: Space.md),
        TextButton(
          key: const ValueKey('sign-in-resend'),
          onPressed: wait > 0 || state.isBusy
              ? null
              : () async {
                  await controller.resend();
                  if (context.mounted && ref.read(signInControllerProvider).error == null) {
                    showInfoSnackBar(context, l.authCodeResent);
                  }
                },
          child: Text(wait > 0 ? l.authResendIn(wait) : l.authResend),
        ),
        TextButton(
          key: const ValueKey('sign-in-change-email'),
          onPressed: state.isBusy ? null : controller.changeEmail,
          child: Text(l.authChangeEmail),
        ),
      ],
    );
  }
}

class _NotConfigured extends ConsumerWidget {
  const _NotConfigured({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(title: l.authNotConfiguredTitle, body: l.authNotConfiguredBody),
        FilledButton(
          onPressed: () async {
            if (session == null) await ref.read(signInControllerProvider.notifier).useOnThisDeviceOnly();
            onContinue();
          },
          child: Text(l.actionContinue),
        ),
      ],
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.hint,
    required this.onPressed,
    super.key,
    this.busy = false,
  });

  final String label;
  final String hint;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: Space.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(onPressed: onPressed, child: busy ? const _Spinner() : Text(label)),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(vertical: Space.lg),
    child: Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.md),
          child: Text(label, style: context.text.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    ),
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner({this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: const CircularProgressIndicator(strokeWidth: 2));
}
