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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Shows queued in-app banners one at a time (T7.3.05): tap → deep link, swipe up to dismiss,
/// auto-dismiss after 5 s (8 s with actions or a screen reader), reduce motion → fade only.
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
    setState(() => _shown = item);
    _timer?.cancel();
    if (item == null) return;
    final media = MediaQuery.maybeOf(context);
    final long =
        item.actions.isNotEmpty || (media?.accessibleNavigation ?? false);
    _timer = Timer(Duration(seconds: long ? 8 : 5), _controller.dismissCurrent);
    final title = item.collapsed
        ? context.l10n.notifBannerCollapsed(item.count)
        : item.title;
    announce(context, [title, item.body].whereType<String>().join('. '));
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

  @override
  Widget build(BuildContext context) {
    final item = _shown;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : Motion.normal,
          transitionBuilder: (child, animation) => reduceMotion
              ? FadeTransition(opacity: animation, child: child)
              : SlideTransition(
                  position: Tween(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
          child: item == null
              ? const SizedBox.shrink()
              : Dismissible(
                  key: ValueKey('banner-${item.key}'),
                  direction: DismissDirection.up,
                  onDismissed: (_) => _controller.dismissCurrent(),
                  child: _BannerCard(
                    item: item,
                    onTap: () => unawaited(_open(item)),
                    onAction: (a) => unawaited(_act(item, a)),
                    onClose: _controller.dismissCurrent,
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
  });

  final BannerItem item;
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
          elevation: 6,
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
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (item.actions.isNotEmpty) ...[
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
