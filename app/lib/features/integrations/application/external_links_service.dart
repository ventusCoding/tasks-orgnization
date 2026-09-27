import 'dart:async';

import 'package:app_links/app_links.dart' as plugin;
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/integrations/application/integration_events.dart';
import 'package:everslot/features/integrations/data/integration_queries.dart';
import 'package:everslot/features/integrations/domain/external_link.dart';

/// Where external links come from (the `app_links` plugin in the app, a fake in tests).
abstract interface class LinkSource {
  /// The link that launched the app (cold start), if any.
  Future<Uri?> initialLink();

  /// Links received while the app runs (warm start / background).
  Stream<Uri> get links;
}

/// `app_links` (custom scheme, universal links, Android App Links). Flutter's own deep linking is
/// disabled (Info.plist `FlutterDeepLinkingEnabled`, manifest `flutter_deeplinking_enabled`) so
/// every link goes through [ExternalLinkPolicy] exactly once.
class AppLinksSource implements LinkSource {
  AppLinksSource([plugin.AppLinks? links]) : _links = links ?? plugin.AppLinks();

  final plugin.AppLinks _links;

  @override
  Future<Uri?> initialLink() async {
    try {
      return await _links.getInitialLink();
    } on Object {
      return null; // tests / unsupported platforms
    }
  }

  @override
  Stream<Uri> get links => _links.uriLinkStream.handleError((Object _) {});
}

/// Handles an integration command link (`everslot://share`, `everslot://do/…`).
typedef LinkCommandHandler = Future<void> Function(LinkCommand command);

/// Command handlers registered by the integration services (share intake, voice actions).
class LinkCommandRegistry {
  final Map<String, LinkCommandHandler> _handlers = {};

  void register(String name, LinkCommandHandler handler) => _handlers[name] = handler;

  LinkCommandHandler? operator [](String name) => _handlers[name];
}

/// External link entry point (T8.2.01): one [LinkSource] → [ExternalLinkPolicy] → UI events.
///
/// Cold start (initial link), warm start and background links are handled identically; the same
/// link reported twice within [dedupeWindow] (initial link + stream replay) opens once. Links to
/// entities in the Trash open the Trash instead ([8.3]); unknown or unsafe links show a friendly
/// notice and never throw.
class ExternalLinksService {
  ExternalLinksService({
    required this.source,
    required this.queries,
    required this.events,
    required this.clock,
    required this.commands,
    this.webHosts = ExternalLinkPolicy.defaultWebHosts,
    this.dedupeWindow = const Duration(seconds: 3),
  });

  final LinkSource source;
  final IntegrationQueries queries;
  final BufferedEventBus<IntegrationUiEvent> events;
  final Clock clock;
  final LinkCommandRegistry commands;
  final Set<String> webHosts;
  final Duration dedupeWindow;

  static final _log = AppLog.get('integrations.links');

  StreamSubscription<Uri>? _sub;
  String? _lastLink;
  DateTime? _lastAt;
  Future<void>? _starting;

  /// Subscribes to incoming links and handles the launch link. Idempotent: every call returns
  /// the same future, which completes once the launch link (if any) has been handled.
  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    _sub = source.links.listen((uri) => unawaited(handle(uri)));
    final initial = await source.initialLink();
    if (initial != null) await handle(initial);
  }

  /// Handles one link; returns the decision (tests, diagnostics).
  Future<ExternalLinkDecision?> handle(Uri uri) async {
    final raw = uri.toString();
    final now = clock.nowUtc();
    if (_lastLink == raw && _lastAt != null && now.difference(_lastAt!).abs() < dedupeWindow) return null;
    _lastLink = raw;
    _lastAt = now;
    final decision = ExternalLinkPolicy.decide(uri, webHosts: webHosts);
    try {
      switch (decision) {
        case IgnoreLink():
          break;
        case RejectLink(:final reason):
          _log.info('rejected external link ($reason)');
          events.add(const NoticeUiEvent(IntegrationNotice.linkNotFound));
        case LinkCommand(:final name):
          final handler = commands[name];
          if (handler == null) {
            events.add(const NoticeUiEvent(IntegrationNotice.linkNotFound));
          } else {
            await handler(decision);
          }
        case OpenPath(:final path, :final asRoot):
          final entity = decision.entity;
          if (entity != null && await queries.entityState(entity) == EntityState.deleted) {
            events
              ..add(OpenPathUiEvent(AppLinks.trash()))
              ..add(const NoticeUiEvent(IntegrationNotice.inTrash));
          } else {
            events.add(OpenPathUiEvent(path, asRoot: asRoot));
          }
      }
    } on Object catch (e, st) {
      _log.warning('external link failed', e, st);
      events.add(const NoticeUiEvent(IntegrationNotice.linkNotFound));
    }
    return decision;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
