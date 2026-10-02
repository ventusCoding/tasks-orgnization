import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/settings/application/export_service.dart' show appVersionLabelProvider;
import 'package:everslot/features/settings/application/review_service.dart';
import 'package:everslot/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens an external link (overridden in tests).
final externalLinkLauncherProvider = Provider<Future<bool> Function(Uri uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

final _appVersionProvider = FutureProvider.autoDispose<String>((ref) => ref.watch(appVersionLabelProvider)());

/// Settings › About (T8.3.13): version, legal pages, health disclaimer, support, licenses, rating.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final env = ref.watch(envProvider);
    final version = ref.watch(_appVersionProvider).value ?? '';
    final open = ref.read(externalLinkLauncherProvider);
    final privacy = env.sitePage('privacy');
    final terms = env.sitePage('terms');
    final supportPage = env.sitePage('support');
    final support = env.support;
    return SettingsPageScaffold(
      title: l.settingsAbout,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.lg, Space.lg, Space.md),
          child: Column(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 48, color: context.colors.primary),
              const SizedBox(height: Space.sm),
              Text(l.appName, style: context.text.headlineSmall),
              Text(l.aboutTagline, style: context.text.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: Space.xs),
              Text(
                l.aboutVersion(version),
                key: const ValueKey('about-version'),
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SectionHeader(l.aboutLegal),
        if (privacy != null)
          ListTile(
            key: const ValueKey('about-privacy'),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.aboutPrivacyPolicy),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => unawaited(open(privacy)),
          ),
        if (terms != null)
          ListTile(
            key: const ValueKey('about-terms'),
            leading: const Icon(Icons.gavel_outlined),
            title: Text(l.aboutTerms),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => unawaited(open(terms)),
          ),
        ListTile(
          key: const ValueKey('about-licenses'),
          leading: const Icon(Icons.description_outlined),
          title: Text(l.aboutLicenses),
          onTap: () => showLicensePage(
            context: context,
            applicationName: l.appName,
            applicationVersion: version,
            applicationLegalese: l.aboutLegalese,
          ),
        ),
        ExpansionTile(
          key: const ValueKey('about-health'),
          leading: const Icon(Icons.health_and_safety_outlined),
          title: Text(l.aboutHealthTitle),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.md),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(l.aboutHealthBody, key: const ValueKey('about-health-body'))],
        ),
        SectionHeader(l.aboutHelp),
        if (supportPage != null)
          ListTile(
            key: const ValueKey('about-support-page'),
            leading: const Icon(Icons.help_outline),
            title: Text(l.aboutHelpCenter),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => unawaited(open(supportPage)),
          ),
        if (support != null)
          ListTile(
            key: const ValueKey('about-support'),
            leading: const Icon(Icons.mail_outline),
            title: Text(l.aboutContact),
            subtitle: Text(support),
            onTap: () => unawaited(open(Uri(scheme: 'mailto', path: support))),
          ),
        ListTile(
          key: const ValueKey('about-rate'),
          leading: const Icon(Icons.star_outline),
          title: Text(l.aboutRate),
          subtitle: Text(l.aboutRateHint),
          onTap: () => unawaited(ref.read(reviewServiceProvider).rateFromSettings()),
        ),
      ],
    );
  }
}
