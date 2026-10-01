import 'dart:async';

import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/application/account_service.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/presentation/auth_messages.dart';
import 'package:everslot/features/auth/presentation/sign_out_flow.dart';
import 'package:everslot/features/auth/presentation/widgets/otp_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Validates a submitted value: null = accepted (the dialog closes with true), otherwise the error
/// text to show. [_emailInUse] closes the dialog and hands over to the resolution dialog.
typedef _Submit = Future<String?> Function(String value);

const _emailInUse = '\u0000email-in-use';

/// Returned by a deletion submit when the authenticator step must follow (T1.5.17).
const _needsMfa = '\u0000mfa-required';

/// Guest → e-mail upgrade (T1.5.11): e-mail, then the 6-digit confirmation code. The user id and
/// all data stay the same. An e-mail that already has an account gets a resolution dialog.
Future<void> runEmailUpgradeFlow(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final service = ref.read(accountServiceProvider);
  final messenger = ScaffoldMessenger.maybeOf(context);
  var email = '';
  final sent = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ValueDialog(
      key: const ValueKey('upgrade-email-dialog'),
      title: l.authUpgradeEmail,
      body: l.authUpgradeBody,
      confirmLabel: l.authSendCode,
      email: true,
      submit: (value) async {
        email = value.trim().toLowerCase();
        try {
          await service.startEmailUpgrade(email);
          return null;
        } on AuthFailure catch (e) {
          if (e.code == AuthFailureCode.emailInUse) return _emailInUse;
          return ctx.mounted ? authFailureMessage(ctx, e.code) : e.code.name;
        }
      },
    ),
  );
  if (!context.mounted) return;
  if (sent == false) {
    // The e-mail belongs to another account.
    await _emailInUseDialog(context, ref, email);
    return;
  }
  if (sent != true) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ValueDialog(
      key: const ValueKey('upgrade-code-dialog'),
      title: l.authCodeTitle,
      body: l.authCodeBody(email),
      confirmLabel: l.authVerify,
      submit: (code) async {
        try {
          await service.confirmEmailUpgrade(email, code);
          return null;
        } on AuthFailure catch (e) {
          return ctx.mounted ? authFailureMessage(ctx, e.code) : e.code.name;
        }
      },
    ),
  );
  if (confirmed == true) messenger?.showSnackBar(SnackBar(content: Text(l.authUpgradeDone)));
}

Future<void> _emailInUseDialog(BuildContext context, WidgetRef ref, String email) async {
  final l = context.l10n;
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const ValueKey('upgrade-email-in-use'),
      title: Text(l.authUpgradeEmailInUseTitle),
      content: Text(l.authUpgradeEmailInUseBody(email)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.actionCancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, 'export'), child: Text(l.authExportFirst)),
        FilledButton(onPressed: () => Navigator.pop(ctx, 'retry'), child: Text(l.authUpgradeEmail)),
      ],
    ),
  );
  if (!context.mounted) return;
  switch (choice) {
    case 'export':
      unawaited(GoRouter.maybeOf(context)?.push<void>(AppLinks.settings('data')));
    case 'retry':
      await runEmailUpgradeFlow(context, ref);
  }
}

enum _DeleteChoice { export, proceed }

/// Settings › Account › Delete account (T1.5.12): consequences + export offer, explicit
/// acknowledgement, re-authentication with a fresh e-mail code (none for guests), then the
/// server deletion and the local wipe.
Future<void> runDeleteAccountFlow(BuildContext context, WidgetRef ref, {String? webUrl}) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final router = GoRouter.maybeOf(context);
  final choice = await showDialog<_DeleteChoice>(
    context: context,
    builder: (_) => _DeleteIntroDialog(webUrl: webUrl),
  );
  if (!context.mounted || choice == null) return;
  if (choice == _DeleteChoice.export) {
    unawaited(router?.push<void>(AppLinks.settings('data')));
    return;
  }
  final service = ref.read(accountServiceProvider);
  String? email;
  try {
    email = await withBlockingProgress(context, l.authDeleting, service.startDeletion);
  } on AuthFailure catch (e) {
    if (context.mounted) showInfoSnackBar(context, authFailureMessage(context, e.code));
    return;
  }
  if (!context.mounted) return;
  bool? deleted;
  if (email == null) {
    // Guest account: nothing to re-authenticate with.
    try {
      await withBlockingProgress(context, l.authDeleting, service.deleteAccount);
      deleted = true;
    } on AuthFailure catch (e) {
      if (context.mounted) showInfoSnackBar(context, authFailureMessage(context, e.code));
      return;
    }
  } else {
    deleted = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ValueDialog(
        key: const ValueKey('delete-code-dialog'),
        title: l.authDeleteTitle,
        body: l.authDeleteReauthBody(email!),
        confirmLabel: l.authDeleteConfirm,
        destructive: true,
        submit: (code) async {
          try {
            await service.deleteAccount(code: code);
            return null;
          } on AuthFailure catch (e) {
            if (e.code == AuthFailureCode.mfaRequired) return _needsMfa;
            return ctx.mounted ? authFailureMessage(ctx, e.code) : e.code.name;
          }
        },
      ),
    );
    if (deleted == false && context.mounted) {
      // Two-step verification is on: the authenticator code completes the deletion.
      deleted = await showDialog<bool>(
        context: context,
        builder: (ctx) => _ValueDialog(
          key: const ValueKey('delete-mfa-dialog'),
          title: l.authMfaVerifyTitle,
          body: l.authMfaVerifyBody,
          confirmLabel: l.authDeleteConfirm,
          destructive: true,
          submit: (code) async {
            try {
              await service.deleteAccount(mfaCode: code);
              return null;
            } on AuthFailure catch (e) {
              return ctx.mounted ? authFailureMessage(ctx, e.code) : e.code.name;
            }
          },
        ),
      );
    }
  }
  if (deleted ?? false) messenger?.showSnackBar(SnackBar(content: Text(l.authDeleted)));
}

/// After a sign-in, when the account has two-step verification (T1.5.17): asks for the
/// authenticator code. Returns false when the user cancelled (the caller signs out).
Future<bool> runMfaStepUpFlow(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final service = ref.read(accountServiceProvider);
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ValueDialog(
      key: const ValueKey('mfa-step-up-dialog'),
      title: l.authMfaVerifyTitle,
      body: l.authMfaVerifyBody,
      confirmLabel: l.authVerify,
      cancelLabel: l.authSignOut,
      submit: (code) async {
        try {
          await service.verifyMfa(code);
          return null;
        } on AuthFailure catch (e) {
          return ctx.mounted ? authFailureMessage(ctx, e.code) : e.code.name;
        }
      },
    ),
  );
  return ok ?? false;
}

/// Settings › Account › Two-step verification › Set up (T1.5.17): a new key for the authenticator
/// app (copy, or open the `otpauth://` link), then its first code confirms it.
Future<void> runMfaEnrollFlow(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final service = ref.read(accountServiceProvider);
  final TotpEnrollment enrollment;
  try {
    enrollment = await withBlockingProgress(context, l.authMfaTitle, service.startMfaEnrollment);
  } on AuthFailure catch (e) {
    if (context.mounted) showInfoSnackBar(context, authFailureMessage(context, e.code));
    return;
  }
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ValueDialog(
      key: const ValueKey('mfa-enroll-dialog'),
      title: l.authMfaTitle,
      body: l.authMfaEnrollBody,
      confirmLabel: l.authVerify,
      header: _TotpKey(enrollment: enrollment),
      submit: (code) async {
        try {
          await service.confirmMfaEnrollment(enrollment, code);
          return null;
        } on AuthFailure catch (e) {
          return ctx.mounted ? authFailureMessage(ctx, e.code) : e.code.name;
        }
      },
    ),
  );
  if (ok ?? false) messenger?.showSnackBar(SnackBar(content: Text(l.authMfaEnabled)));
}

/// Turns two-step verification off after a current authenticator code.
Future<void> runMfaDisableFlow(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final service = ref.read(accountServiceProvider);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ValueDialog(
      key: const ValueKey('mfa-disable-dialog'),
      title: l.authMfaTitle,
      body: l.authMfaDisableBody,
      confirmLabel: l.authMfaDisable,
      destructive: true,
      submit: (code) async {
        try {
          await service.disableMfa(code);
          return null;
        } on AuthFailure catch (e) {
          return ctx.mounted ? authFailureMessage(ctx, e.code) : e.code.name;
        }
      },
    ),
  );
  if (ok ?? false) messenger?.showSnackBar(SnackBar(content: Text(l.authMfaDisabled)));
}

/// The setup key (selectable, copyable, LTR) and a link that opens the authenticator app.
class _TotpKey extends StatelessWidget {
  const _TotpKey({required this.enrollment});

  final TotpEnrollment enrollment;

  /// "ABCD EFGH …" — easier to type by hand.
  static String grouped(String secret) =>
      [for (var i = 0; i < secret.length; i += 4) secret.substring(i, (i + 4).clamp(0, secret.length))].join(' ');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.authMfaSecret, style: context.text.labelMedium),
        const SizedBox(height: Space.xs),
        SelectableText(
          grouped(enrollment.secret),
          key: const ValueKey('mfa-secret'),
          textDirection: TextDirection.ltr,
          style: context.text.titleMedium?.copyWith(fontFeatures: AppTheme.tabular, letterSpacing: 1.2),
        ),
        Wrap(
          spacing: Space.sm,
          children: [
            TextButton.icon(
              key: const ValueKey('mfa-copy'),
              icon: const Icon(Icons.copy),
              label: Text(l.authMfaCopySecret),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: enrollment.secret));
                if (context.mounted) showInfoSnackBar(context, l.authMfaSecretCopied);
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(l.authMfaOpenApp),
              onPressed: () => unawaited(
                launchUrl(
                  Uri.parse(enrollment.uri),
                  mode: LaunchMode.externalApplication,
                ).catchError((Object _) => false),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
      ],
    );
  }
}

class _DeleteIntroDialog extends StatefulWidget {
  const _DeleteIntroDialog({this.webUrl});

  final String? webUrl;

  @override
  State<_DeleteIntroDialog> createState() => _DeleteIntroDialogState();
}

class _DeleteIntroDialogState extends State<_DeleteIntroDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final url = widget.webUrl;
    return AlertDialog(
      key: const ValueKey('delete-intro'),
      title: Text(l.authDeleteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.authDeleteBody),
            const SizedBox(height: Space.md),
            CheckboxListTile(
              key: const ValueKey('delete-understand'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _understood,
              title: Text(l.authDeleteUnderstand),
              onChanged: (v) => setState(() => _understood = v ?? false),
            ),
            if (url != null && url.isNotEmpty) Text(l.authDeleteWeb(url), style: context.text.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel)),
        TextButton(
          key: const ValueKey('delete-export'),
          onPressed: () => Navigator.pop(context, _DeleteChoice.export),
          child: Text(l.authDeleteExportFirst),
        ),
        FilledButton(
          key: const ValueKey('delete-continue'),
          style: FilledButton.styleFrom(backgroundColor: context.colors.error, foregroundColor: context.colors.onError),
          onPressed: _understood ? () => Navigator.pop(context, _DeleteChoice.proceed) : null,
          child: Text(l.actionContinue),
        ),
      ],
    );
  }
}

/// Dialog asking for one value (an e-mail, or a 6-digit code) validated by [submit].
class _ValueDialog extends StatefulWidget {
  const _ValueDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.submit,
    super.key,
    this.email = false,
    this.destructive = false,
    this.header,
    this.cancelLabel,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final _Submit submit;

  /// An e-mail field; otherwise a one-time-code field.
  final bool email;
  final bool destructive;

  /// Extra content above the field (the TOTP setup key).
  final Widget? header;

  /// Label of the dismiss button (defaults to Cancel).
  final String? cancelLabel;

  @override
  State<_ValueDialog> createState() => _ValueDialogState();
}

class _ValueDialogState extends State<_ValueDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.submit(_controller.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else if (error == _emailInUse || error == _needsMfa) {
      Navigator.pop(context, false);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.body),
            const SizedBox(height: Space.md),
            ?widget.header,
            if (widget.email)
              TextField(
                key: const ValueKey('value-dialog-email'),
                controller: _controller,
                autofocus: true,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l.authEmailLabel, hintText: l.authEmailHint, errorText: _error),
                onSubmitted: (_) => unawaited(_go()),
              )
            else
              OtpField(
                key: const ValueKey('value-dialog-code'),
                controller: _controller,
                enabled: !_busy,
                label: l.authCodeLabel,
                errorText: _error,
                onCompleted: (_) {},
              ),
            if (_busy) ...[const SizedBox(height: Space.md), const LinearProgressIndicator()],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(widget.cancelLabel ?? l.actionCancel),
        ),
        FilledButton(
          key: const ValueKey('value-dialog-confirm'),
          style: widget.destructive
              ? FilledButton.styleFrom(backgroundColor: context.colors.error, foregroundColor: context.colors.onError)
              : null,
          onPressed: _busy ? null : () => unawaited(_go()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
