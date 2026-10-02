import 'package:everslot/features/integrations/domain/shared_content.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Content shared into the app (system share sheet / Android intents); faked in tests.
abstract interface class ShareSource {
  /// Content that launched the app, if any.
  Future<SharedContent?> initial();

  /// Content shared while the app runs.
  Stream<SharedContent> get incoming;

  /// Forgets the handled content (so a restart does not replay it).
  Future<void> reset();
}

/// `receive_sharing_intent` implementation (Android intent filters, iOS share extension writing to
/// the App Group).
class ReceiveSharingIntentSource implements ShareSource {
  final _plugin = ReceiveSharingIntent.instance;

  @override
  Future<SharedContent?> initial() async => _map(await _plugin.getInitialMedia());

  @override
  Stream<SharedContent> get incoming =>
      _plugin.getMediaStream().map(_map).where((c) => c != null).cast<SharedContent>();

  @override
  Future<void> reset() async => _plugin.reset();

  static SharedContent? _map(List<SharedMediaFile> media) {
    if (media.isEmpty) return null;
    final text = <String>[];
    final files = <SharedFile>[];
    for (final m in media) {
      switch (m.type) {
        case SharedMediaType.text || SharedMediaType.url:
          text.add(m.path);
        case SharedMediaType.image:
          files.add(SharedFile(path: m.path, kind: SharedFileKind.image, mimeType: m.mimeType));
        case SharedMediaType.video:
          files.add(SharedFile(path: m.path, kind: SharedFileKind.video, mimeType: m.mimeType));
        case SharedMediaType.file:
          files.add(SharedFile(path: m.path, kind: SharedFileKind.file, mimeType: m.mimeType));
      }
      if (m.message case final message? when message.trim().isNotEmpty && !text.contains(message)) {
        text.insert(0, message);
      }
    }
    final content = SharedContent(text: text.join('\n'), files: files);
    return content.isEmpty ? null : content;
  }
}
