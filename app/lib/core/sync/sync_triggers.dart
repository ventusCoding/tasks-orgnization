import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:everslot/core/logging/log.dart';
import 'package:everslot/core/sync/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// `syncOnlineChangesProvider` (online/offline transitions from the shared connectivity service,
// T1.4.10 / T1.3.04) lives with the other core providers; re-exported for the sync code and its tests.
export 'package:everslot/core/providers.dart' show syncOnlineChangesProvider;

/// Joins the private Broadcast channel of the user; [onSync] receives the payload of every `sync`
/// event. Returns a function leaving the channel.
typedef BroadcastSubscriber =
    Future<void> Function() Function(void Function(Map<String, dynamic> payload) onSync);

/// External triggers of the sync engine (T1.4.10 connectivity regain, T1.4.12 Broadcast,
/// T1.4.13 resume): Broadcast is joined only while the app is in the foreground (arch §6.6 —
/// never relied upon alone: resume, connectivity and the periodic timer pull too).
class SyncTriggers {
  SyncTriggers({
    required this.service,
    required Stream<void> onResume,
    required Stream<void> onPause,
    Stream<bool>? onlineChanges,
    this.subscribeBroadcast,
    this.onResumed,
  }) : _onResume = onResume,
       _onPause = onPause,
       _onlineChanges = onlineChanges;

  final SyncService service;
  final BroadcastSubscriber? subscribeBroadcast;

  /// Extra work on resume (device registration refresh).
  final void Function()? onResumed;

  final Stream<void> _onResume;
  final Stream<void> _onPause;
  final Stream<bool>? _onlineChanges;
  final _subs = <StreamSubscription<Object?>>[];
  Future<void> Function()? _leave;
  bool? _online;
  bool _disposed = false;

  static final _log = AppLog.get('sync.triggers');

  /// Whether the Broadcast channel is currently joined.
  bool get broadcastJoined => _leave != null;

  void start({bool foreground = true}) {
    _subs
      ..add(_onResume.listen((_) {
        service.schedulePull(Duration.zero);
        _join();
        onResumed?.call();
      }))
      ..add(_onPause.listen((_) => _leaveChannel()));
    final online = _onlineChanges;
    if (online != null) {
      _subs.add(
        online.listen(
          (isOnline) {
            final wasOffline = _online == false;
            _online = isOnline;
            // Connectivity regained: push what queued up while offline, then pull.
            if (isOnline && wasOffline) service.schedulePush(Duration.zero);
          },
          onError: (Object e) => _log.fine('connectivity stream error: $e'),
        ),
      );
    }
    if (foreground) _join();
  }

  void _join() {
    if (_disposed || _leave != null || subscribeBroadcast == null) return;
    try {
      _leave = subscribeBroadcast!(service.onBroadcast);
    } on Object catch (e) {
      _log.info('broadcast subscribe failed: $e');
    }
  }

  void _leaveChannel() {
    final leave = _leave;
    _leave = null;
    if (leave != null) unawaited(leave().catchError((Object _) {}));
  }

  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    _leaveChannel();
  }
}

/// [BroadcastSubscriber] over Supabase Realtime (private channel `user:<uid>`, event `sync`).
BroadcastSubscriber supabaseBroadcastSubscriber(SupabaseClient client, String userId) => (onSync) {
  final channel = client
      .channel('user:$userId', opts: const RealtimeChannelConfig(private: true))
      .onBroadcast(
        event: 'sync',
        callback: (payload) {
          final inner = payload['payload'];
          onSync(inner is Map ? Map<String, dynamic>.from(inner) : Map<String, dynamic>.from(payload));
        },
      )
      .subscribe();
  return () async {
    await client.removeChannel(channel);
  };
};

/// Online/offline stream from `connectivity_plus` (errors — e.g. no plugin in tests — are ignored).
Stream<bool> connectivityOnlineChanges([Connectivity? connectivity]) {
  try {
    final c = connectivity ?? Connectivity();
    return c.onConnectivityChanged
        .map((r) => r.any((e) => e != ConnectivityResult.none))
        .handleError((Object _) {});
  } on Object {
    return const Stream<bool>.empty();
  }
}
