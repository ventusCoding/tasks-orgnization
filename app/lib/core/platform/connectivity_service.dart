import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:everslot/core/logging/log.dart';

/// Kind of network link the OS reports.
enum ConnectionType { none, wifi, cellular, other }

/// The OS view of the network link (`connectivity_plus`); replaced by a fake in tests.
abstract interface class LinkSource {
  Future<ConnectionType> current();

  Stream<ConnectionType> get changes;
}

class PlatformLinkSource implements LinkSource {
  PlatformLinkSource([Connectivity? connectivity]) : _connectivity = connectivity;

  final Connectivity? _connectivity;

  Connectivity get _c => _connectivity ?? Connectivity();

  static ConnectionType typeOf(List<ConnectivityResult> results) {
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) return ConnectionType.none;
    if (results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.ethernet)) {
      return ConnectionType.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) return ConnectionType.cellular;
    return ConnectionType.other;
  }

  @override
  Future<ConnectionType> current() async {
    try {
      return typeOf(await _c.checkConnectivity());
    } on Object {
      // No plugin (tests, unsupported platform): assume there is a link and let reachability decide.
      return ConnectionType.other;
    }
  }

  @override
  Stream<ConnectionType> get changes {
    try {
      return _c.onConnectivityChanged.map(typeOf).handleError((Object _) {});
    } on Object {
      return const Stream<ConnectionType>.empty();
    }
  }
}

/// Can the backend host be reached? (`true` = yes).
typedef Reachability = Future<bool> Function(Uri backend);

/// Reachability by opening a TCP connection to the backend's host and port (no HTTP request, no
/// credentials): a link that has no route to the server — airplane-mode wifi, a dead hotspot,
/// blocked DNS — is reported as offline even though the OS says "connected".
Reachability tcpReachability({Duration timeout = const Duration(seconds: 3)}) => (backend) async {
  final port = backend.hasPort ? backend.port : (backend.scheme == 'http' ? 80 : 443);
  try {
    final socket = await Socket.connect(backend.host, port, timeout: timeout);
    socket.destroy();
    return true;
  } on Object {
    return false;
  }
};

/// Online/offline state of the app (T1.3.04): the OS link **and**, when a backend is configured, a
/// real reachability check of that host. Sync, notification re-planning and Today listen here.
///
///  * link none → offline, no probing;
///  * link up, no backend (local-only mode) → online;
///  * link up, backend configured → online only if the host answers; while it doesn't, the probe
///    repeats every [recheckInterval] (a captive portal or a flaky hotspot recovers without any OS event).
///
/// Link flapping is debounced ([debounce]); [onlineChanges] only emits real transitions.
class ConnectivityService {
  ConnectivityService({
    required this._source,
    this.backend,
    Reachability? reachability,
    this.debounce = const Duration(milliseconds: 500),
    this.recheckInterval = const Duration(seconds: 20),
  }) : _reachability = reachability ?? tcpReachability();

  final LinkSource _source;

  /// The host to probe (the Supabase URL), or null in local-only mode.
  final Uri? backend;
  final Reachability _reachability;
  final Duration debounce;
  final Duration recheckInterval;

  final _changes = StreamController<bool>.broadcast();
  StreamSubscription<ConnectionType>? _subscription;
  Timer? _debounceTimer;
  Timer? _recheckTimer;
  var _evaluation = 0;
  var _disposed = false;

  bool _online = true;
  ConnectionType _type = ConnectionType.other;

  /// Optimistic until the first check finishes: an unknown network is not treated as offline.
  bool get isOnline => _online;

  /// The OS link kind (Wi-Fi vs cellular, for "Wi-Fi only" transfers).
  ConnectionType get type => _type;

  /// Distinct online/offline transitions (`true` = online again).
  Stream<bool> get onlineChanges => _changes.stream;

  /// Reads the link and starts listening. Idempotent.
  Future<void> start() async {
    if (_subscription != null || _disposed) return;
    _subscription = _source.changes.listen(_onLink);
    _type = await _source.current();
    await _evaluate();
  }

  /// Re-reads the link and probes the host right now (pull-to-refresh, "Retry" buttons).
  Future<bool> checkNow() async {
    _debounceTimer?.cancel();
    _type = await _source.current();
    await _evaluate();
    return _online;
  }

  void _onLink(ConnectionType type) {
    if (_disposed) return;
    _type = type;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(_evaluate()));
  }

  Future<void> _evaluate() async {
    final generation = ++_evaluation;
    _recheckTimer?.cancel();
    _recheckTimer = null;
    if (_type == ConnectionType.none) {
      _set(online: false);
      return;
    }
    final host = backend;
    if (host == null) {
      _set(online: true);
      return;
    }
    var reachable = false;
    try {
      reachable = await _reachability(host);
    } on Object catch (e) {
      AppLog.get('connectivity').fine('reachability probe failed (${e.runtimeType})');
    }
    if (_disposed || generation != _evaluation) return; // superseded by a newer link event
    _set(online: reachable);
    if (!reachable) _recheckTimer = Timer(recheckInterval, () => unawaited(_evaluate()));
  }

  void _set({required bool online}) {
    if (online == _online) return;
    _online = online;
    if (!_changes.isClosed) _changes.add(online);
  }

  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _recheckTimer?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_changes.close());
  }
}
