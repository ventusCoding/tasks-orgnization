import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/settings/application/export_service.dart' show appVersionLabelProvider;
import 'package:everslot/features/settings/application/feedback_service.dart';
import 'package:everslot/features/settings/application/review_service.dart';
import 'package:everslot/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens an external link (overridden in tests).
final externalLinkLauncherProvider = Provider<Future<bool> Function(Uri uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Shares text through the system sheet when no support address is configured (tests override).
final feedbackShareProvider = Provider<Future<void> Function(String text, String subject)>(
  (ref) => (text, subject) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  },
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
          key: const ValueKey('about-feedback'),
          leading: const Icon(Icons.feedback_outlined),
          title: Text(l.feedbackTitle),
          subtitle: Text(l.feedbackHint),
          onTap: () =>
              unawaited(showAppSheet<void>(context, title: l.feedbackTitle, builder: (_) => const FeedbackSheet())),
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

/// "Send feedback" (T8.3.17): a message and, if the user keeps it, the diagnostics shown verbatim.
class FeedbackSheet extends ConsumerStatefulWidget {
  const FeedbackSheet({super.key});

  @override
  ConsumerState<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<FeedbackSheet> {
  final _message = TextEditingController();
  var _include = true;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send(String? diagnostics) async {
    final l = context.l10n;
    final body = [
      _message.text.trim(),
      if (_include && diagnostics != null) '---\n$diagnostics',
    ].where((s) => s.isNotEmpty).join('\n\n');
    final support = ref.read(envProvider).support;
    if (support != null) {
      await ref.read(externalLinkLauncherProvider)(
        Uri(
          scheme: 'mailto',
          path: support,
          query: 'subject=${Uri.encodeComponent(l.feedbackSubject)}&body=${Uri.encodeComponent(body)}',
        ),
      );
    } else {
      await ref.read(feedbackShareProvider)(body, l.feedbackSubject);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final diagnostics = ref.watch(feedbackDiagnosticsProvider).value?.toText();
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('feedback-message'),
            controller: _message,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(labelText: l.feedbackMessage, border: const OutlineInputBorder()),
          ),
          SwitchListTile(
            key: const ValueKey('feedback-diagnostics'),
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(l.feedbackIncludeDiagnostics),
            subtitle: Text(l.feedbackDiagnosticsHint),
            value: _include,
            onChanged: (v) => setState(() => _include = v),
          ),
          if (_include && diagnostics != null)
            ExpansionTile(
              key: const ValueKey('feedback-preview'),
              tilePadding: EdgeInsetsDirectional.zero,
              title: Text(l.feedbackPreview),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.all(Space.md),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: SelectableText(
                    diagnostics,
                    key: const ValueKey('feedback-diagnostics-text'),
                    style: context.text.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: Space.md),
          FilledButton.icon(
            key: const ValueKey('feedback-send'),
            onPressed: () => unawaited(_send(diagnostics)),
            icon: const Icon(Icons.send_outlined),
            label: Text(l.feedbackSend),
          ),
        ],
      ),
    );
  }
}
