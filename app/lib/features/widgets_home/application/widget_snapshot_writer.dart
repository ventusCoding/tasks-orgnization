import 'dart:async';

import 'package:everslot/core/logging/log.dart';
import 'package:everslot/features/widgets_home/data/home_widget_bridge.dart';
import 'package:everslot/features/widgets_home/domain/widget_snapshot.dart';

/// Debounced snapshot writer (T8.2.02): coalesces bursts of changes ([debounce], 2 s by default),
/// skips writes whose content did not change — unless the stored copy is getting old — and asks
/// the widgets to reload after each write.
class WidgetSnapshotWriter {
  WidgetSnapshotWriter(this._bridge, {this.debounce = const Duration(seconds: 2), DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final WidgetBridge _bridge;
  final Duration debounce;
  final DateTime Function() _now;
  static final _log = AppLog.get('widgets');

  /// Unchanged content is still rewritten after this, so widgets never look stale.
  static const rewriteAfter = Duration(hours: 6);

  Timer? _timer;
  WidgetSnapshot? _pending;
  String? _lastContent;
  DateTime? _lastWrite;
  var _writes = 0;

  int get writes => _writes;

  void schedule(WidgetSnapshot? snapshot) {
    if (snapshot == null) return;
    _pending = snapshot;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(flush()));
  }

  /// Writes the pending snapshot now (also used by background actions).
  Future<void> flush() async {
    _timer?.cancel();
    final s = _pending;
    _pending = null;
    if (s == null) return;
    final json = s.toJson()..remove('generatedAt');
    final content = json.toString();
    final last = _lastWrite;
    if (content == _lastContent && last != null && _now().difference(last) < rewriteAfter) return;
    try {
      await _bridge.save(s.encode());
      await _bridge.reloadAll();
      _lastContent = content;
      _lastWrite = _now();
      _writes++;
    } on Object catch (e, st) {
      _log.warning('widget snapshot write failed', e, st);
    }
  }

  void dispose() => _timer?.cancel();
}
