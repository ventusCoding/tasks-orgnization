import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/privacy/application/app_lock_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Covers the app while it is locked or in the app switcher (T8.3.09). The lock screen asks for
/// authentication by itself once, then waits for the *Unlock* button.
class AppLockGate extends ConsumerWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Hidden content stays out of the accessibility tree too.
        ExcludeSemantics(excluding: lock.covered, child: child),
        if (lock.ready && lock.locked) const LockScreen() else if (lock.covered) const _PrivacyCover(),
      ],
    );
  }
}

class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('privacy-cover'),
    color: context.colors.surface,
    child: Center(child: Icon(Icons.lock_outline, size: 48, color: context.colors.primary)),
  );
}

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_unlock());
    });
  }

  Future<void> _unlock() => ref.read(appLockProvider.notifier).unlock(context.l10n);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final busy = ref.watch(appLockProvider.select((s) => s.authenticating));
    return Material(
      key: const ValueKey('lock-screen'),
      color: context.colors.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Space.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: context.colors.primary),
                const SizedBox(height: Space.lg),
                Text(l.appLockTitle, style: context.text.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: Space.sm),
                Text(l.appLockBody, textAlign: TextAlign.center),
                const SizedBox(height: Space.xl),
                FilledButton.icon(
                  key: const ValueKey('lock-unlock'),
                  onPressed: busy ? null : () => unawaited(_unlock()),
                  icon: const Icon(Icons.fingerprint),
                  label: Text(l.appLockUnlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
