import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/application/account_service.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/presentation/account_flows.dart';
import 'package:everslot/features/auth/presentation/auth_messages.dart';
import 'package:everslot/features/auth/presentation/sign_out_flow.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/profile/presentation/zone_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Account — the profile screen (T1.5.13): who is signed in, display name, e-mail,
/// sign-in methods (link / unlink), guest upgrade (T1.5.11), home & current zone, regional
/// settings, sign-out and account deletion (T1.5.12). Local-only devices are invited to sign in
/// (their data comes along, ADR-017).
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final profile = ref.watch(profileProvider).value;
    final issues = ref.watch(sessionIssuesProvider);
    final now = ref.watch(clockProvider).nowUtc();
    final router = GoRouter.maybeOf(context);
    final cloud = session != null && session.isCloud;
    final guest = session?.isAnonymous ?? false;
    final revoked = issues.contains(SessionIssue.deviceRevoked);

    return Scaffold(
      appBar: AppBar(title: Text(l.authProfileTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Space.xxl),
        children: [
          if (revoked) _RevokedCard(onSignOut: () => runSignOutFlow(context, ref, revoked: true)),
          _Header(name: profile?.displayName, email: session?.email, guest: guest, cloud: cloud),
          if (!cloud)
            _LocalOnlyCard(
              canSignIn: ref.watch(cloudAuthAvailableProvider),
              onSignIn: () => router?.push(AppLinks.signIn()),
            )
          else if (guest)
            const _GuestUpgradeCard()
          else ...[
            SectionHeader(l.authLinkedAccounts),
            const _SignInMethods(),
          ],
          SectionHeader(l.authProfileTitle),
          ListTile(
            key: const ValueKey('account-display-name'),
            leading: const Icon(Icons.badge_outlined),
            title: Text(l.authDisplayName),
            subtitle: Text(profile?.displayName ?? l.authDisplayNameHint),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final name = await promptText(
                context,
                title: l.authDisplayName,
                initial: profile?.displayName,
                hint: l.authDisplayNameHint,
                allowEmpty: true,
              );
              if (name == null) return;
              await ref.read(profileRepositoryProvider).update(displayName: name);
              final repo = ref.read(authRepositoryProvider);
              if (cloud) unawaited(repo?.updateDisplayName(name.isEmpty ? null : name).catchError((Object _) {}));
            },
          ),
          ListTile(
            key: const ValueKey('account-home-zone'),
            leading: const Icon(Icons.home_outlined),
            title: Text(l.authHomeZone),
            subtitle: Text(zoneDisplay(profile?.homeTimeZone ?? ref.watch(deviceZoneProvider), now)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => router?.push(AppLinks.settings('regional')),
          ),
          ListTile(
            key: const ValueKey('account-current-zone'),
            leading: const Icon(Icons.public),
            title: Text(l.authCurrentZone),
            subtitle: Text(zoneDisplay(ref.watch(deviceZoneProvider), now)),
          ),
          ListTile(
            key: const ValueKey('account-regional'),
            leading: const Icon(Icons.tune),
            title: Text(l.authRegionalSettings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => router?.push(AppLinks.settings('regional')),
          ),
          if (cloud) ...[
            const Divider(),
            ListTile(
              key: const ValueKey('account-sign-out'),
              leading: const Icon(Icons.logout),
              title: Text(l.authSignOut),
              onTap: () => runSignOutFlow(context, ref, revoked: revoked),
            ),
            ListTile(
              key: const ValueKey('account-delete'),
              leading: Icon(Icons.delete_forever_outlined, color: context.colors.error),
              title: Text(l.authDeleteAccount, style: TextStyle(color: context.colors.error)),
              onTap: () =>
                  runDeleteAccountFlow(context, ref, webUrl: ref.read(authConfigProvider).accountDeletionWebUrl),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.email, required this.guest, required this.cloud});

  final String? name;
  final String? email;
  final bool guest;
  final bool cloud;

  static String initials(String? source) {
    final parts = (source ?? '').trim().split(RegExp(r'[\s@._-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = String.fromCharCodes(parts.first.runes.take(1));
    final second = parts.length > 1 ? String.fromCharCodes(parts[1].runes.take(1)) : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final subtitle = !cloud
        ? l.authLocalOnlyAccount
        : guest
        ? l.authGuestAccount
        : l.authSignedInAs(email ?? '');
    return ListTile(
      key: const ValueKey('account-identity'),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, Space.md),
      leading: CircleAvatar(radius: 28, child: Text(initials(name ?? email), style: context.text.titleMedium)),
      title: Text(name ?? l.settingsAccount, style: context.text.titleLarge),
      subtitle: Text(subtitle),
    );
  }
}

class _GuestUpgradeCard extends ConsumerWidget {
  const _GuestUpgradeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final repo = ref.watch(authRepositoryProvider);
    Future<void> link(Future<Object?> Function() run, String provider) async {
      try {
        final linked = await run();
        if (linked != false && context.mounted) showInfoSnackBar(context, l.authUpgradeDone);
      } on AuthFailure catch (e) {
        if (e.code != AuthFailureCode.cancelled && context.mounted) {
          showInfoSnackBar(context, authFailureMessage(context, e.code));
        }
      }
    }

    final service = ref.read(accountServiceProvider);
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Card(
        key: const ValueKey('account-upgrade'),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: context.colors.primary),
                  const SizedBox(width: Space.md),
                  Expanded(child: Text(l.authUpgradeTitle, style: context.text.titleMedium)),
                ],
              ),
              const SizedBox(height: Space.sm),
              Text(l.authUpgradeBody),
              const SizedBox(height: Space.md),
              FilledButton.icon(
                key: const ValueKey('account-upgrade-email'),
                onPressed: () => runEmailUpgradeFlow(context, ref),
                icon: const Icon(Icons.mail_outline),
                label: Text(l.authUpgradeEmail),
              ),
              if (repo?.googleAvailable ?? false) ...[
                const SizedBox(height: Space.sm),
                OutlinedButton(
                  key: const ValueKey('account-upgrade-google'),
                  onPressed: () => link(service.linkGoogle, 'google'),
                  child: Text(l.authContinueGoogle),
                ),
              ],
              if (repo?.appleAvailable ?? false) ...[
                const SizedBox(height: Space.sm),
                OutlinedButton.icon(
                  key: const ValueKey('account-upgrade-apple'),
                  onPressed: () => link(service.linkApple, 'apple'),
                  icon: const Icon(Icons.apple),
                  label: Text(l.authContinueApple),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInMethods extends ConsumerWidget {
  const _SignInMethods();

  static IconData _icon(String provider) => switch (provider) {
    'google' => Icons.g_mobiledata,
    'apple' => Icons.apple,
    _ => Icons.mail_outline,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final identities = ref.watch(identitiesProvider);
    final repo = ref.watch(authRepositoryProvider);
    final service = ref.read(accountServiceProvider);

    Future<void> guarded(Future<void> Function() run, {String? done}) async {
      try {
        await run();
        if (done != null && context.mounted) showInfoSnackBar(context, done);
      } on AuthFailure catch (e) {
        if (e.code != AuthFailureCode.cancelled && context.mounted) {
          showInfoSnackBar(context, authFailureMessage(context, e.code));
        }
      }
    }

    return identities.when(
      loading: () => const Padding(padding: EdgeInsets.all(Space.lg), child: LinearProgressIndicator()),
      error: (e, _) => ListTile(
        key: const ValueKey('account-identities-offline'),
        leading: const Icon(Icons.cloud_off),
        title: Text(e is AuthFailure ? authFailureMessage(context, e.code) : l.authErrorOffline),
        trailing: IconButton(
          tooltip: l.actionRetry,
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(identitiesProvider),
        ),
      ),
      data: (list) {
        final linked = {for (final i in list) i.provider};
        return Column(
          children: [
            for (final i in list)
              ListTile(
                key: ValueKey('identity-${i.provider}'),
                leading: Icon(_icon(i.provider)),
                title: Text(providerLabel(context, i.provider)),
                subtitle: i.email == null ? null : Text(i.email!),
                trailing: list.length > 1
                    ? TextButton(
                        key: ValueKey('unlink-${i.provider}'),
                        onPressed: () async {
                          final label = providerLabel(context, i.provider);
                          final ok = await confirmDialog(
                            context,
                            title: l.authUnlinkConfirm(label),
                            confirmLabel: l.authUnlink,
                            destructive: true,
                          );
                          if (ok) await guarded(() => service.unlink(i));
                        },
                        child: Text(l.authUnlink),
                      )
                    : null,
              ),
            if ((repo?.googleAvailable ?? false) && !linked.contains('google'))
              ListTile(
                key: const ValueKey('link-google'),
                leading: Icon(_icon('google')),
                title: Text(l.authProviderGoogle),
                trailing: TextButton(
                  onPressed: () => guarded(service.linkGoogle, done: l.authLinked(l.authProviderGoogle)),
                  child: Text(l.authLink),
                ),
              ),
            if ((repo?.appleAvailable ?? false) && !linked.contains('apple'))
              ListTile(
                key: const ValueKey('link-apple'),
                leading: Icon(_icon('apple')),
                title: Text(l.authProviderApple),
                trailing: TextButton(
                  onPressed: () => guarded(() async {
                    if (await service.linkApple() && context.mounted) {
                      showInfoSnackBar(context, l.authLinked(l.authProviderApple));
                    }
                  }),
                  child: Text(l.authLink),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LocalOnlyCard extends StatelessWidget {
  const _LocalOnlyCard({required this.canSignIn, required this.onSignIn});

  final bool canSignIn;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.authLocalOnlyAccount, style: context.text.titleMedium),
              const SizedBox(height: Space.sm),
              Text(canSignIn ? l.authLocalOnlyAccountBody : l.localOnlyBanner),
              if (canSignIn) ...[
                const SizedBox(height: Space.md),
                FilledButton(
                  key: const ValueKey('account-sign-in'),
                  onPressed: onSignIn,
                  child: Text(l.authSignInToSync),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RevokedCard extends StatelessWidget {
  const _RevokedCard({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.lg, Space.lg, 0),
      child: Card(
        color: context.colors.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.authDeviceRevokedTitle, style: context.text.titleMedium),
              const SizedBox(height: Space.sm),
              Text(l.authDeviceRevokedBody),
              const SizedBox(height: Space.md),
              Wrap(
                spacing: Space.sm,
                children: [
                  OutlinedButton(
                    onPressed: () => GoRouter.maybeOf(context)?.push(AppLinks.settings('data')),
                    child: Text(l.authExportFirst),
                  ),
                  FilledButton(
                    key: const ValueKey('account-revoked-sign-out'),
                    onPressed: onSignOut,
                    child: Text(l.authSignOut),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
