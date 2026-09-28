import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/auth/application/auth_providers.dart';
import 'package:everslot/features/auth/domain/auth_models.dart';
import 'package:everslot/features/auth/presentation/sign_out_flow.dart';
import 'package:everslot/features/profile/application/profile_providers.dart';
import 'package:everslot/features/profile/presentation/zone_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Account (T1.5.13): who is signed in, display name, home zone, sign-out; local-only
/// devices are invited to sign in (their data comes along, ADR-017).
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

    return Scaffold(
      appBar: AppBar(title: Text(l.authProfileTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Space.xxl),
        children: [
          if (issues.contains(SessionIssue.deviceRevoked))
            _RevokedCard(onSignOut: () => runSignOutFlow(context, ref, revoked: true)),
          if (session == null || session.isLocalOnly)
            _LocalOnlyCard(canSignIn: ref.watch(cloudAuthAvailableProvider), onSignIn: () => router?.push(AppLinks.signIn()))
          else
            ListTile(
              key: const ValueKey('account-identity'),
              leading: Icon(session.isAnonymous ? Icons.person_outline : Icons.verified_user_outlined),
              title: Text(session.isAnonymous ? l.authGuestAccount : l.authSignedInAs(session.email ?? '')),
            ),
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
              if (session?.isCloud ?? false) unawaited(repo?.updateDisplayName(name.isEmpty ? null : name).catchError((Object _) {}));
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
          if (session != null && session.isCloud) ...[
            const Divider(),
            ListTile(
              key: const ValueKey('account-sign-out'),
              leading: const Icon(Icons.logout),
              title: Text(l.authSignOut),
              onTap: () => runSignOutFlow(context, ref, revoked: issues.contains(SessionIssue.deviceRevoked)),
            ),
          ],
        ],
      ),
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
                  FilledButton(key: const ValueKey('account-revoked-sign-out'), onPressed: onSignOut, child: Text(l.authSignOut)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
