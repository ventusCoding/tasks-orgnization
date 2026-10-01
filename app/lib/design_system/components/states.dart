import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/core/errors/error_mapper.dart';
import 'package:everslot/design_system/l10n_x.dart';
import 'package:everslot/design_system/tokens.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart' show FlutterErrorDetails, kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Centered loading indicator.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: label ?? context.l10n.stateLoading,
      child: const Padding(padding: EdgeInsets.all(Space.xl), child: CircularProgressIndicator()),
    ),
  );
}

/// Friendly empty state with an optional primary action (T8.1.13).
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    super.key,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: context.colors.outline),
          const SizedBox(height: Space.lg),
          Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              message!,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Space.lg),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

/// Error state with retry.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.error, this.onRetry});

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.error_outline,
    title: context.l10n.stateErrorTitle,
    message: messageFor(context, error),
    actionLabel: onRetry == null ? null : context.l10n.actionRetry,
    onAction: onRetry,
  );

  /// Localized message for any error: [AppException]s directly, Supabase / Drift / platform
  /// exceptions through `toAppException` (T1.3.05). Unknown errors get the generic "Please try
  /// again." — never a raw exception text.
  static String messageFor(BuildContext context, Object? error) {
    final l = context.l10n;
    if (error == null) return l.stateErrorBody;
    return switch (toAppException(error).kind) {
      AppErrorKind.network => l.errorNetwork,
      AppErrorKind.auth => l.errorAuth,
      AppErrorKind.validation => l.errorValidation,
      AppErrorKind.conflict => l.errorConflict,
      AppErrorKind.storage => l.errorStorage,
      AppErrorKind.permission => l.errorPermission,
      AppErrorKind.notFound => l.errorNotFound,
      AppErrorKind.unsupportedVersion => l.errorUnsupportedVersion,
      AppErrorKind.notConfigured => l.errorNotConfigured,
      AppErrorKind.unknown => l.stateErrorBody,
    };
  }
}

/// Replaces the grey/red framework error box in release builds: a small, localized placeholder in
/// the space of the widget that failed to build, while the rest of the screen keeps working
/// (T1.3.05). Debug builds keep Flutter's detailed red screen.
class FriendlyErrorWidget extends StatelessWidget {
  const FriendlyErrorWidget({super.key, this.details});

  final FlutterErrorDetails? details;

  /// Installs [FriendlyErrorWidget] as `ErrorWidget.builder` (release builds only unless
  /// [force] is set, which tests use).
  static void install({bool force = false}) {
    if (!force && !kReleaseMode) return;
    ErrorWidget.builder = (details) => FriendlyErrorWidget(details: details);
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold/theme is guaranteed above a failed widget: read localizations defensively.
    final l = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Semantics(
      label: l?.errorWidgetFallback ?? "This part couldn't be shown.",
      child: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Space.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 20),
              const SizedBox(width: Space.sm),
              Flexible(
                child: Text(
                  l?.errorWidgetFallback ?? "This part couldn't be shown.",
                  textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders an [AsyncValue] with shared loading/error widgets.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({required this.value, required this.data, super.key, this.loading, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    data: data,
    loading: () => loading ?? const LoadingState(),
    error: (e, _) => ErrorState(error: e, onRetry: onRetry),
  );
}

/// Placeholder for screens under construction.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: EmptyState(icon: Icons.construction, title: title, message: context.l10n.placeholderScreen),
  );
}
