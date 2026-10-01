import 'dart:async';

import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/notifications/application/inbox_reconciler.dart';
import 'package:everslot/features/notifications/data/local_schedule_store.dart';
import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/domain/scheduler/schedule_plan.dart';
import 'package:flutter/foundation.dart';

/// One in-app banner (T7.3.05).
@immutable
class BannerItem {
  const BannerItem({
    required this.key,
    required this.title,
    this.body,
    this.section,
    this.link,
    this.actions = const [],
    this.payload,
    this.count = 1,
    this.titles = const [],
    this.importance = NotificationImportance.normal,
  });

  final String key;
  final String title;
  final String? body;
  final NotificationSection? section;
  final String? link;
  final List<String> actions;
  final NotificationPayload? payload;

  /// > 1 for a collapsed burst ("3 reminders").
  final int count;
  final List<String> titles;

  /// Drives the haptic (none for min/low, light for default, stronger for high/urgent).
  final NotificationImportance importance;

  bool get collapsed => count > 1;
}

/// Banner queue: one banner at a time, de-duplicated by dedupe key, bursts collapsed (≥ 2 items
/// within [burstWindow] → one "N reminders" banner). The presenter (presentation layer) listens to
/// [current] and calls [dismissCurrent].
class InAppBannerController {
  InAppBannerController({this.burstWindow = const Duration(milliseconds: 800)});

  final Duration burstWindow;
  final ValueNotifier<BannerItem?> current = ValueNotifier(null);
  final List<BannerItem> _queue = [];
  final List<BannerItem> _burst = [];
  final Set<String> _seen = {};
  Timer? _burstTimer;
  bool enabled = true;

  List<BannerItem> get queued => List.unmodifiable(_queue);

  void show(BannerItem item) {
    if (!enabled || !_seen.add(item.key)) return;
    _burst.add(item);
    _burstTimer ??= Timer(burstWindow, _flushBurst);
  }

  void _flushBurst() {
    _burstTimer = null;
    if (_burst.isEmpty) return;
    final items = List<BannerItem>.of(_burst);
    _burst.clear();
    if (items.length == 1) {
      _enqueue(items.single);
    } else {
      _enqueue(
        BannerItem(
          key: 'burst:${items.first.key}',
          title: items.first.title,
          count: items.length,
          titles: [for (final i in items) i.title],
          link: AppLinks.inbox(),
          importance: items.map((i) => i.importance).reduce((a, b) => a.rank >= b.rank ? a : b),
        ),
      );
    }
  }

  /// Flushes a pending burst immediately (tests / app pause).
  void flushNow() {
    _burstTimer?.cancel();
    _flushBurst();
  }

  void _enqueue(BannerItem item) {
    if (current.value == null) {
      current.value = item;
    } else {
      _queue.add(item);
    }
  }

  void dismissCurrent() {
    current.value = _queue.isEmpty ? null : _queue.removeAt(0);
  }

  void clear() {
    _queue.clear();
    _burst.clear();
    current.value = null;
  }

  void dispose() {
    _burstTimer?.cancel();
    current.dispose();
  }
}

/// While the app is in the foreground, fires at each scheduled instant: writes the inbox row and
/// raises the in-app banner instead of relying on the OS banner (T7.2.17 / T7.3.02).
class ForegroundTicker {
  ForegroundTicker({
    required this.store,
    required this.reconciler,
    required this.banners,
    required this.clock,
    required this.bannerEnabled,
    this.guardOpen,
  });

  final LocalScheduleStore store;
  final InboxReconciler reconciler;
  final InAppBannerController banners;
  final Clock clock;
  final bool Function() bannerEnabled;

  /// Re-checks a target right before showing its banner (sources' `guardOpen`).
  final Future<bool> Function(NotificationPayload payload)? guardOpen;

  Timer? _timer;
  bool _active = false;

  /// Banners only for firings at most this old (older ones just go to the inbox).
  static const freshness = Duration(minutes: 2);

  void start() {
    _active = true;
    unawaited(_arm());
  }

  void stop() {
    _active = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _arm() async {
    _timer?.cancel();
    if (!_active) return;
    final now = clock.nowUtc();
    final next = [
      for (final e in await store.all())
        if (e.fireAt.isAfter(now) && e.reconciledAt == null && e.kind != ScheduleKind.test) e.fireAt,
    ];
    if (next.isEmpty || !_active) return;
    next.sort();
    var delay = next.first.difference(now) + const Duration(milliseconds: 300);
    if (delay > const Duration(hours: 1)) delay = const Duration(hours: 1);
    _timer = Timer(delay, () => unawaited(tick().then((_) => _arm())));
  }

  /// Reconciles due rows and raises banners for the fresh ones. Returns the banners shown.
  Future<List<BannerItem>> tick() async {
    final now = clock.nowUtc();
    final reconciled = await reconciler.reconcile();
    final shown = <BannerItem>[];
    if (!bannerEnabled()) return shown;
    for (final e in reconciled) {
      if (!e.banner || now.difference(e.fireAt) > freshness) continue;
      final c = e.content;
      final payload = NotificationPayload.fromJson({
        'dk': e.dedupeKey,
        'bk': c['bk'],
        'tk': e.targetKey,
        'tt': c['tt'],
        'tid': c['tid'],
        'occ': c['occ'],
        'rid': c['rid'],
        'sec': c['sec'],
        'cat': c['cat'],
        'link': c['link'],
        'acts': c['acts'],
        'snz': c['snz'],
        'uid': c['uid'],
      });
      if (guardOpen != null && !await guardOpen!(payload)) continue;
      final item = BannerItem(
        key: e.dedupeKey,
        title: asString(c['t']) ?? '',
        body: asString(c['b']),
        section: NotificationSection.tryParse(asString(c['sec'])),
        link: asString(c['link']),
        actions: [
          for (final a in asStringList(c['acts']) ?? const <String>[])
            if (a != NotificationActionIds.open) a,
        ].take(2).toList(),
        payload: payload,
        importance: NotificationImportance.tryParse(asString(c['imp'])) ?? NotificationImportance.normal,
      );
      banners.show(item);
      shown.add(item);
    }
    return shown;
  }
}
