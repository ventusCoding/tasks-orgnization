import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot/startup/bootstrap_runner.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Recoverable startup error screen (T1.3.02): shown instead of the app when a required startup
/// step failed. Self-contained — no providers, no router — because the app never started. Prod:
/// friendly message + retry; dev flavor ([showDetails]): the failing step, the error and the stack.
class BootstrapErrorApp extends StatefulWidget {
  const BootstrapErrorApp({required this.failure, required this.onRetry, super.key, this.showDetails = false});

  final BootstrapFailure failure;

  /// Runs startup again from the failed step; the app replaces this screen when it succeeds.
  final Future<void> Function() onRetry;

  final bool showDetails;

  @override
  State<BootstrapErrorApp> createState() => _BootstrapErrorAppState();
}

class _BootstrapErrorAppState extends State<BootstrapErrorApp> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  String get _details => 'step: ${widget.failure.step}\n${widget.failure.error}\n\n${widget.failure.stack}';

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => AppLocalizations.of(context).appName,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
    localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
    home: Builder(
      builder: (context) {
        final l = context.l10n;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(Space.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.error_outline, size: 56, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: Space.lg),
                      Semantics(
                        liveRegion: true,
                        header: true,
                        child: Text(
                          l.bootstrapErrorTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      Text(l.bootstrapErrorBody, textAlign: TextAlign.center),
                      const SizedBox(height: Space.xl),
                      if (_retrying)
                        const Center(child: CircularProgressIndicator())
                      else
                        FilledButton.icon(
                          key: const ValueKey('bootstrap-retry'),
                          onPressed: () => unawaited(_retry()),
                          icon: const Icon(Icons.refresh),
                          label: Text(l.actionRetry),
                        ),
                      if (widget.showDetails) ...[
                        const SizedBox(height: Space.xl),
                        Text(l.bootstrapErrorDetails, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: Space.sm),
                        Container(
                          padding: const EdgeInsetsDirectional.all(Space.md),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                          // Developer text: always LTR, selectable.
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: SelectableText(
                              key: const ValueKey('bootstrap-details'),
                              _details,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              maxLines: 12,
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            onPressed: () => unawaited(Clipboard.setData(ClipboardData(text: _details))),
                            icon: const Icon(Icons.copy),
                            label: Text(l.bootstrapErrorCopy),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
