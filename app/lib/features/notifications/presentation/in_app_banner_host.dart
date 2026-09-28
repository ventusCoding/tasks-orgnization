import 'dart:async';

import 'package:everslot/app/router.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/action_dispatcher.dart';
import 'package:everslot/features/notifications/application/in_app_banners.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/inbox_screen.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:everslot/features/notifications/presentation/snooze_picker.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Shows queued in-app banners one at a time (T7.3.05): tap → deep link, swipe to dismiss,
/// auto-dismiss after 5 s (8 s with actions or a screen reader), reduce motion → fade only,
/// haptic by importance. When the banner's target screen is already the current route it
/// shrinks to a subtle compact banner (3 s, no actions); while the keyboard is up and the focused
/// field sits under the top area, the banner moves above the keyboard.
class InAppBannerHost extends ConsumerStatefulWidget {
  const InAppBannerHost({super.key});

  @override
  ConsumerState<InAppBannerHost> createState() => _InAppBannerHostState();
}

class _InAppBannerHostState extends ConsumerState<InAppBannerHost> {
  late final InAppBannerController _controller = ref.read(
    inAppBannerControllerProvider,
  );
  Timer? _timer;
  BannerItem? _shown;
  bool _compact = false;

  @override
  void initState() {
    super.initState();
    _controller.current.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onChanged());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.current.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final item = _controller.current.value;
    if (!mounted || identical(item, _shown)) return;
    final compact = item != null && _targetOnScreen(item);
    setState(() {
      _shown = item;
      _compact = compact;
    });
    _timer?.cancel();
    if (item == null) return;
    final media = MediaQuery.maybeOf(context);
    final long =
        !compact &&
        (item.actions.isNotEmpty || (media?.accessibleNavigation ?? false));
    _timer = Timer(
      Duration(seconds: compact ? 3 : (long ? 8 : 5)),
      _controller.dismissCurrent,
    );
    haptic(item.importance);
    final title = item.collapsed
        ? context.l10n.notifBannerCollapsed(item.count)
        : item.title;
    announce(context, [title, item.body].whereType<String>().join('. '));
  }

  /// The banner's target screen is already the current route (e.g. that task's page).
  bool _targetOnScreen(BannerItem item) {
    final link = item.link;
    if (link == null || item.collapsed) return false;
    final router = GoRouter.maybeOf(context);
    if (router == null) return false;
    try {
      final current = router.routerDelegate.currentConfiguration.uri;
      return current.path == Uri.parse(link).path;
    } on Object {
      return false;
    }
  }

  /// Haptic per importance: silent for Gentle (min/low), light for default, stronger above.
  static void haptic(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.min || NotificationImportance.low:
        return;
      case NotificationImportance.normal:
        unawaited(HapticFeedback.selectionClick());
      case NotificationImportance.high || NotificationImportance.urgent:
        unawaited(HapticFeedback.mediumImpact());
    }
  }

  Future<void> _open(BannerItem item) async {
    _controller.dismissCurrent();
    final engine = ref.read(notificationsEngineProvider);
    final payload = item.payload;
    if (payload == null) {
      if (item.link != null)
        engine.emit(ActionDispatchResult(openLink: item.link));
      return;
    }
    final result = await ref
        .read(notificationActionDispatcherProvider)
        .handleTap(payload, origin: ActionOrigin.banner);
    engine.emit(result);
  }

  Future<void> _act(BannerItem item, String action) async {
    _controller.dismissCurrent();
    final payload = item.payload;
    if (payload == null) return;
    final dispatcher = ref.read(notificationActionDispatcherProvider);
    final engine = ref.read(notificationsEngineProvider);
    if (action == NotificationActionIds.snooze) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) return;
      final minutes = await pickSnooze(
        ctx,
        ref,
        options: payload.snoozeOptions,
      );
      if (minutes == null) return;
      engine.emit(await dispatcher.snooze(payload, minutes: minutes));
      return;
    }
    engine.emit(
      await dispatcher.handleAction(
        action,
        payload,
        origin: ActionOrigin.banner,
      ),
    );
  }

  /// Height below the top inset that a top banner may cover.
  static const _topArea = 160.0;

  @override
  Widget build(BuildContext context) {
    final item = _shown;
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;
    final keyboard = media.viewInsets.bottom;
    final focusTop = FocusManager.instance.primaryFocus?.rect.top;
    final bottom =
        keyboard > 0 &&
        focusTop != null &&
        focusTop < media.padding.top + _topArea;
    return Align(
      alignment: bottom
          ? AlignmentDirectional.bottomCenter
          : AlignmentDirectional.topCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom ? keyboard : 0),
        child: SafeArea(
          bottom: !bottom,
          child: AnimatedSwitcher(
            duration: Motion.normal,
            transitionBuilder: (child, animation) => reduceMotion
                ? FadeTransition(opacity: animation, child: child)
                : SlideTransition(
                    position: Tween(
                      begin: Offset(0, bottom ? 1 : -1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
            child: item == null
                ? const SizedBox.shrink()
                : Dismissible(
                    key: ValueKey('banner-${item.key}'),
                    direction: bottom
                        ? DismissDirection.down
                        : DismissDirection.up,
                    onDismissed: (_) => _controller.dismissCurrent(),
                    child: _BannerCard(
                      item: item,
                      compact: _compact,
                      onTap: () => unawaited(_open(item)),
                      onAction: (a) => unawaited(_act(item, a)),
                      onClose: _controller.dismissCurrent,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.item,
    required this.onTap,
    required this.onAction,
    required this.onClose,
    this.compact = false,
  });

  final BannerItem item;

  /// Subtle variant: one line of body, no actions (target screen already visible).
  final bool compact;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final title = item.collapsed
        ? l.notifBannerCollapsed(item.count)
        : item.title;
    final body = item.collapsed ? item.titles.join(', ') : item.body;
    return Padding(
      padding: const EdgeInsets.all(Space.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Material(
          elevation: compact ? 2 : 6,
          borderRadius: BorderRadius.circular(Radii.lg),
          color: context.colors.surfaceContainerHigh,
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.lg),
            onTap: onTap,
            child: Semantics(
              liveRegion: true,
              label: [title, ?body].join('. '),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  Space.lg,
                  Space.md,
                  Space.xs,
                  Space.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      InboxTile.iconFor(
                        item.section,
                        item.payload?.category ?? InboxCategory.reminder,
                      ),
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: context.text.titleSmall),
                          if (body != null && body.isNotEmpty) ...[
                            const SizedBox(height: Space.xxs),
                            Text(
                              body,
                              style: context.text.bodyMedium,
                              maxLines: compact ? 1 : 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (!compact && item.actions.isNotEmpty) ...[
                            const SizedBox(height: Space.xs),
                            Wrap(
                              spacing: Space.sm,
                              children: [
                                for (final a in item.actions)
                                  TextButton(
                                    onPressed: () => onAction(a),
                                    child: Text(labels.action(a)),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l.notifBannerDismiss,
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Installs the banner overlay above every route and handles notification UI events
/// (navigation to deep links, "Already done" and message snackbars). Called once after the first
/// frame by the notifications startup task — no change to the app shell needed.
abstract final class NotificationOverlay {
  static OverlayEntry? _entry;
  static StreamSubscription<NotificationUiEvent>? _events;

  static void install(ProviderContainer container, {int attempts = 20}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = rootNavigatorKey.currentState?.overlay;
      if (overlay == null) {
        if (attempts > 0) install(container, attempts: attempts - 1);
        return;
      }
      _entry?.remove();
      _entry = OverlayEntry(builder: (_) => const InAppBannerHost());
      overlay.insert(_entry!);
      unawaited(_events?.cancel());
      _events = container
          .read(notificationUiEventsProvider)
          .stream
          .listen((event) => _handle(container, event));
    });
  }

  static void _handle(ProviderContainer container, NotificationUiEvent event) {
    final context = rootNavigatorKey.currentContext;
    switch (event) {
      case OpenLinkEvent(:final link, :final alreadyDone):
        unawaited(container.read(routerProvider).push<void>(link));
        if (alreadyDone && context != null) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(context.l10n.notifInboxAlreadyDone)),
          );
        }
      case MessageEvent(:final message):
        if (context != null)
          ScaffoldMessenger.maybeOf(context)
              ?.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
