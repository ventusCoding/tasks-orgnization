import 'dart:async';

import 'package:meta/meta.dart';

/// Localized notices the integrations surface as snackbars.
enum IntegrationNotice {
  /// An external link could not be opened.
  linkNotFound,

  /// The linked item is in the Trash (the Trash opens instead).
  inTrash,

  /// A widget / Siri / App Actions action could not be applied.
  actionFailed,

  /// A voice / App Actions habit log was recorded.
  habitLogged,

  /// A voice command found no matching habit.
  habitNotFound,

  /// Nothing is planned next.
  nothingNext,

  /// A shortcut logged a craving ([NoticeUiEvent.detail] = tracker name).
  cravingLogged,
}

/// Something the UI layer must do on behalf of an integration (navigation, snackbar, sheet).
@immutable
sealed class IntegrationUiEvent {
  const IntegrationUiEvent();
}

/// Navigate to a router path (`go` for tab roots, `push` otherwise).
final class OpenPathUiEvent extends IntegrationUiEvent {
  const OpenPathUiEvent(this.path, {this.asRoot = false});

  final String path;
  final bool asRoot;

  @override
  bool operator ==(Object other) => other is OpenPathUiEvent && other.path == path && other.asRoot == asRoot;

  @override
  int get hashCode => Object.hash(path, asRoot);

  @override
  String toString() => 'OpenPathUiEvent($path, root: $asRoot)';
}

/// Show a localized notice; [detail] is interpolated where the message has a placeholder.
final class NoticeUiEvent extends IntegrationUiEvent {
  const NoticeUiEvent(this.notice, {this.detail});

  final IntegrationNotice notice;
  final String? detail;

  @override
  bool operator ==(Object other) => other is NoticeUiEvent && other.notice == notice && other.detail == detail;

  @override
  int get hashCode => Object.hash(notice, detail);

  @override
  String toString() => 'NoticeUiEvent(${notice.name}, $detail)';
}

/// Open the universal quick add (shortcut / voice *New task*, T8.2.06); [title] pre-fills it.
final class QuickAddUiEvent extends IntegrationUiEvent {
  const QuickAddUiEvent({this.title});

  final String? title;

  @override
  bool operator ==(Object other) => other is QuickAddUiEvent && other.title == title;

  @override
  int get hashCode => title.hashCode;
}

/// Content shared into Everslot is waiting for a destination (T8.2.07).
final class ShareReceivedUiEvent extends IntegrationUiEvent {
  const ShareReceivedUiEvent();
}

/// An `.ics` file was opened / shared into the app (T8.2.12).
final class IcsReceivedUiEvent extends IntegrationUiEvent {
  const IcsReceivedUiEvent(this.content, {this.fileName});

  final String content;
  final String? fileName;
}

/// Event bus that keeps events until the UI listens (links can arrive before the first frame,
/// when the router does not exist yet). At most [capacity] events are buffered.
class BufferedEventBus<T> {
  BufferedEventBus({this.capacity = 16}) {
    _controller = StreamController<T>.broadcast(onListen: () => scheduleMicrotask(_flush));
  }

  final int capacity;
  late final StreamController<T> _controller;
  final List<T> _pending = [];

  Stream<T> get stream => _controller.stream;

  /// Buffered, not yet delivered events (tests).
  List<T> get pending => List.unmodifiable(_pending);

  void add(T event) {
    if (_controller.isClosed) return;
    if (_controller.hasListener) {
      _controller.add(event);
      return;
    }
    _pending.add(event);
    if (_pending.length > capacity) _pending.removeAt(0);
  }

  void _flush() {
    if (!_controller.hasListener || _controller.isClosed) return;
    final events = [..._pending];
    _pending.clear();
    events.forEach(_controller.add);
  }

  Future<void> close() => _controller.close();
}
