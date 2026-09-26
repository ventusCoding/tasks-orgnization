import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:everslot/features/notifications/application/capabilities_service.dart';
import 'package:everslot/features/notifications/application/local_scheduler.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notification_texts_l10n.dart';
import 'package:everslot/features/notifications/domain/digest_composer.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_settings.dart';
import 'package:everslot/features/notifications/domain/notification_target.dart';
import 'package:everslot/features/notifications/domain/planner/notification_planner.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:meta/meta.dart';

typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Outcome of one replan (diagnostics screen, T7.2.21).
@immutable
class ReplanReport {
  const ReplanReport({
    required this.at,
    required this.duration,
    required this.reason,
    required this.planned,
    required this.skipped,
    required this.targets,
    required this.scheduler,
    this.next = const [],
    this.error,
  });

  final DateTime at;
  final Duration duration;
  final String reason;
  final int planned;
  final int skipped;
  final int targets;
  final SchedulerReport scheduler;

  /// Next 20 firings (all channels).
  final List<PlannedNotification> next;
  final String? error;
}

/// Loads every planning input, runs the pure planner and applies the result (T7.2.06–T7.2.12).
class NotificationPipeline {
  NotificationPipeline(this.read);

  final ProviderReader read;
  static final _log = AppLog.get('notifications.pipeline');

  /// Latest full plan (all instances, not only the local top-K) — uploaded as server jobs.
  PlanResult? lastPlan;
  PlanningContext? lastContext;
  String _channelSignature = '';

  /// Extra window around the horizon so occurrences whose reminders fall inside it are loaded.
  static ({Duration before, Duration after}) window(
    List<NotificationRule> rules,
  ) {
    var before = 1440;
    var after = 1440;
    for (final r in rules) {
      switch (r.spec.trigger) {
        case RelativeTrigger(:final offsetMinutes, :final dayOffset):
          if (dayOffset != null) {
            final minutes = (dayOffset.abs() + 1) * 1440;
            if (dayOffset < 0) {
              before = minutes > before ? minutes : before;
            } else {
              after = minutes > after ? minutes : after;
            }
          } else if (offsetMinutes != null) {
            if (offsetMinutes < 0 && -offsetMinutes > before)
              before = -offsetMinutes;
            if (offsetMinutes > 0 && offsetMinutes > after)
              after = offsetMinutes;
          }
        case OverdueTrigger(:final effectiveAfter):
          if (effectiveAfter > after) after = effectiveAfter;
        case NotDoneByTrigger(:final effectiveOffset):
          if (effectiveOffset > after) after = effectiveOffset;
        default:
          break;
      }
    }
    const cap = 31 * 1440;
    return (
      before: Duration(minutes: before > cap ? cap : before),
      after: Duration(minutes: after > cap ? cap : after),
    );
  }

  /// Builds the planning context from the database, settings and registered sources.
  Future<PlanningContext> buildContext({
    List<NotificationRule>? rulesOverride,
    List<NotificationTarget>? targetsOverride,
    bool applyCaps = true,
  }) async {
    final now = read(clockProvider).nowUtc();
    final settingsRepo = read(settingsRepositoryProvider);
    final settings = NotificationSettings.fromMaps(
      await settingsRepo.read(SettingsNs.notifications),
      await settingsRepo.read(SettingsNs.privacy),
    );
    final rules =
        rulesOverride ?? await read(notificationRulesRepositoryProvider).all();
    final profiles = await read(notificationProfilesRepositoryProvider).all();
    final mutes = await read(notificationMutesRepositoryProvider).all();
    final db = read(appDatabaseProvider);
    final userId = read(currentUserIdProvider);
    final profile = await (db.select(
      db.profiles,
    )..where((p) => p.id.equals(userId))).getSingleOrNull();
    final texts = L10nNotificationTexts.forLocale(
      profile?.locale,
      use24h: (profile?.timeFormat ?? 'h24') == 'h24',
    );
    final zone = read(deviceZoneProvider);
    final zones = read(zoneResolverProvider);
    final horizon = Duration(days: settings.horizonDays);

    var targets = targetsOverride;
    if (targets == null) {
      final w = window(rules);
      final from = now
          .subtract(w.after)
          .subtract(Duration(minutes: settings.latenessMinutes));
      final to = now.add(horizon).add(w.before);
      targets = <NotificationTarget>[];
      for (final source in read(notificationTargetSourcesProvider)) {
        try {
          targets.addAll(await source.targetsBetween(from, to));
        } on Object catch (e, st) {
          _log.warning('source ${source.section} failed', e, st);
        }
      }
    }
    final digests = DigestComposer.compose(
      rules: rules,
      targets: targets,
      now: now,
      horizonDays: settings.horizonDays,
      zone: zone,
      zones: zones,
      texts: texts,
    );
    final acknowledged = await read(inboxRepositoryProvider)
        .acknowledgedKeys(since: now.subtract(const Duration(days: 2)));
    final caps = read(notificationCapabilitiesProvider);
    return PlanningContext(
      now: now,
      deviceZone: zone,
      zones: zones,
      settings: settings,
      rules: rules,
      targets: [...targets, ...digests],
      profiles: profiles,
      mutes: mutes,
      texts: texts,
      acknowledgedKeys: acknowledged,
      deviceId: read(deviceIdProvider),
      userId: userId,
      timeSensitiveAllowed: !caps.determined || caps.timeSensitive,
      applyCaps: applyCaps,
    );
  }

  /// Full replan: plan → OS schedule → delivered cleanup. Never throws (errors are reported).
  Future<ReplanReport> run(String reason, {bool foreground = true}) async {
    final watch = Stopwatch()..start();
    final at = read(clockProvider).nowUtc();
    try {
      final ctx = await buildContext();
      final result = NotificationPlanner.plan(ctx);
      final scheduler = read(localSchedulerProvider);
      final signature = [
        for (final p in ctx.profiles)
          '${p.id}:${p.spec.channelVersion}:${p.name}',
        ctx.texts.localeTag,
      ].join('|');
      if (signature != _channelSignature) {
        await scheduler.ensureChannels(ctx.profiles);
        _channelSignature = signature;
      }
      final caps = read(notificationCapabilitiesProvider);
      final report = await scheduler.apply(
        result.planned,
        exactAllowed: caps.exactAlarm || !caps.determined,
        foreground: foreground,
        bannerInApp: ctx.settings.bannerInApp,
        horizonEnd: ctx.now.add(ctx.effectiveHorizon),
        authenticationRequired: ctx.settings.hideContent,
      );
      await scheduler.removeDelivered({
        for (final t in ctx.targets)
          if (!t.isOpen) '${t.targetKey}|${t.occurrenceKey ?? ''}',
      });
      lastPlan = result;
      lastContext = ctx;
      return ReplanReport(
        at: at,
        duration: watch.elapsed,
        reason: reason,
        planned: result.planned.length,
        skipped: result.skipped.length,
        targets: ctx.targets.length,
        scheduler: report,
        next: [
          for (final p in result.planned)
            if (!p.fireAt.isBefore(ctx.now)) p,
        ].take(20).toList(),
      );
    } on Object catch (e, st) {
      _log.warning('replan failed ($reason)', e, st);
      return ReplanReport(
        at: at,
        duration: watch.elapsed,
        reason: reason,
        planned: 0,
        skipped: 0,
        targets: 0,
        scheduler: SchedulerReport.empty,
        error: e.toString(),
      );
    }
  }
}

/// Single-flight, debounced replan orchestrator (T7.2.12). Requests arriving while a run is in
/// progress coalesce into one follow-up run.
class NotificationReplanService {
  NotificationReplanService({
    required this.runner,
    this.debounce = const Duration(milliseconds: 1500),
  });

  final Future<ReplanReport> Function(String reason) runner;
  final Duration debounce;

  Timer? _timer;
  Completer<ReplanReport>? _running;
  final Set<String> _pendingReasons = {};
  final _reports = StreamController<ReplanReport>.broadcast();
  bool _disposed = false;
  int runs = 0;

  ReplanReport? last;

  Stream<ReplanReport> get reports => _reports.stream;

  bool get isRunning => _running != null;

  /// Debounced request (1.5 s); [immediate] skips the debounce.
  void request(String reason, {bool immediate = false}) {
    if (_disposed) return;
    _pendingReasons.add(reason);
    _timer?.cancel();
    if (immediate) {
      unawaited(flush());
    } else {
      _timer = Timer(debounce, () => unawaited(flush()));
    }
  }

  /// Runs now (or joins the running replan and schedules one more pass).
  Future<ReplanReport?> flush() async {
    if (_disposed) return null;
    _timer?.cancel();
    if (_running != null) {
      // Coalesce: another pass runs after the current one.
      await _running!.future;
      if (_pendingReasons.isEmpty) return last;
      return flush();
    }
    final reason = _pendingReasons.isEmpty
        ? 'manual'
        : (_pendingReasons.toList()..sort()).join('+');
    _pendingReasons.clear();
    final completer = _running = Completer<ReplanReport>();
    try {
      final report = await runner(reason);
      runs++;
      last = report;
      if (!_reports.isClosed) _reports.add(report);
      completer.complete(report);
      return report;
    } on Object catch (e) {
      completer.future.ignore();
      completer.completeError(e);
      rethrow;
    } finally {
      _running = null;
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_reports.close());
  }
}
