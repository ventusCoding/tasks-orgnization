import 'dart:async';
import 'dart:io';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/presentation/attachment_ui.dart' show attachmentIcon;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

/// Playback position of one media file.
@immutable
class PlaybackState {
  const PlaybackState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.completed = false,
    this.aspectRatio = 16 / 9,
    this.ready = false,
  });

  final Duration position;
  final Duration duration;
  final bool playing;
  final bool completed;
  final double aspectRatio;
  final bool ready;

  @override
  bool operator ==(Object other) =>
      other is PlaybackState &&
      other.position == position &&
      other.duration == duration &&
      other.playing == playing &&
      other.completed == completed &&
      other.aspectRatio == aspectRatio &&
      other.ready == ready;

  @override
  int get hashCode => Object.hash(position, duration, playing, completed, aspectRatio, ready);
}

/// A player for one local video or audio file (T2.2.12 / T2.2.13), fakeable in tests.
abstract class MediaPlayback {
  ValueListenable<PlaybackState> get state;

  Future<void> open(String path);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// The video surface (an empty box for audio).
  Widget surface();

  Future<void> dispose();
}

/// `video_player` (AVPlayer / ExoPlayer) — plays clips and voice notes alike.
class VideoPlayerPlayback implements MediaPlayback {
  VideoPlayerController? _controller;
  final _state = ValueNotifier(const PlaybackState());

  @override
  ValueListenable<PlaybackState> get state => _state;

  void _sync() {
    final c = _controller;
    if (c == null) return;
    final v = c.value;
    _state.value = PlaybackState(
      position: v.position,
      duration: v.duration,
      playing: v.isPlaying,
      completed: v.isCompleted,
      aspectRatio: v.isInitialized && v.aspectRatio > 0 ? v.aspectRatio : 16 / 9,
      ready: v.isInitialized,
    );
  }

  @override
  Future<void> open(String path) async {
    final c = VideoPlayerController.file(File(path));
    _controller = c;
    c.addListener(_sync);
    await c.initialize();
    _sync();
  }

  @override
  Future<void> play() async {
    final c = _controller;
    if (c == null) return;
    if (c.value.isCompleted) await c.seekTo(Duration.zero);
    await c.play();
  }

  @override
  Future<void> pause() async => _controller?.pause();

  @override
  Future<void> seek(Duration position) async => _controller?.seekTo(position);

  @override
  Widget surface() {
    final c = _controller;
    return c == null ? const SizedBox.shrink() : VideoPlayer(c);
  }

  @override
  Future<void> dispose() async {
    final c = _controller;
    _controller = null;
    c?.removeListener(_sync);
    await c?.dispose();
    _state.dispose();
  }
}

final mediaPlaybackFactoryProvider = Provider<MediaPlayback Function()>((ref) => VideoPlayerPlayback.new);

/// Inline voice-note playback in attachment strips (T2.2.13): one note at a time; the state is the
/// id of the playing attachment.
final voicePlaybackProvider = NotifierProvider<VoicePlaybackController, String?>(VoicePlaybackController.new);

class VoicePlaybackController extends Notifier<String?> {
  MediaPlayback? _player;

  @override
  String? build() {
    ref.onDispose(() => unawaited(_player?.dispose()));
    return null;
  }

  /// Plays [a] (downloading it first when needed), or stops it when it is the one playing.
  Future<void> toggle(Attachment a) async {
    if (state == a.id) return stop();
    await stop();
    String? path;
    try {
      path = await ref.read(attachmentDownloaderProvider).ensureOriginal(a);
    } on Object {
      path = null;
    }
    if (path == null) return;
    final player = ref.read(mediaPlaybackFactoryProvider)();
    _player = player;
    state = a.id;
    player.state.addListener(() {
      if (player.state.value.completed && identical(_player, player)) unawaited(stop());
    });
    await player.open(path);
    if (identical(_player, player)) await player.play();
  }

  Future<void> stop() async {
    final player = _player;
    _player = null;
    state = null;
    await player?.dispose();
  }
}

/// "0:42", "12:05", "1:02:03".
String formatClipLength(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// Full-screen player of a clip or voice note in the viewer: video surface (or the waveform /
/// type icon), play/pause and a seek bar.
class MediaPlayerView extends ConsumerStatefulWidget {
  const MediaPlayerView({required this.attachment, required this.path, super.key, this.thumbPath});

  final Attachment attachment;
  final String path;
  final String? thumbPath;

  @override
  ConsumerState<MediaPlayerView> createState() => _MediaPlayerViewState();
}

class _MediaPlayerViewState extends ConsumerState<MediaPlayerView> {
  late final MediaPlayback _player = ref.read(mediaPlaybackFactoryProvider)();
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      _player.open(widget.path).catchError((Object _) {
        if (mounted) setState(() => _failed = true);
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = widget.attachment;
    final isVideo = a.kind == AttachmentKind.video;
    return ValueListenableBuilder<PlaybackState>(
      valueListenable: _player.state,
      builder: (context, s, _) {
        final total = s.duration > Duration.zero ? s.duration : Duration(milliseconds: a.durationMs ?? 0);
        final picture = isVideo && s.ready
            ? AspectRatio(aspectRatio: s.aspectRatio, child: _player.surface())
            : widget.thumbPath != null
            ? Image.file(File(widget.thumbPath!), fit: BoxFit.contain, semanticLabel: a.caption ?? a.fileName)
            : Icon(attachmentIcon(a.kind), size: 96, color: context.colors.primary);
        return Column(
          children: [
            Expanded(child: Center(child: picture)),
            if (_failed)
              Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Text(l.attachmentsNoPreview, style: context.text.bodyMedium),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, 0, Space.lg, Space.sm),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('media-play'),
                      tooltip: s.playing ? l.attachmentsPause : l.attachmentsPlay,
                      iconSize: 36,
                      icon: Icon(s.playing ? Icons.pause_circle_filled : Icons.play_circle_fill),
                      onPressed: !s.ready ? null : () => unawaited(s.playing ? _player.pause() : _player.play()),
                    ),
                    Expanded(
                      child: Slider(
                        value: total.inMilliseconds == 0
                            ? 0
                            : (s.position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0),
                        semanticFormatterCallback: (_) =>
                            '${formatClipLength(s.position)} / ${formatClipLength(total)}',
                        onChanged: !s.ready || total == Duration.zero
                            ? null
                            : (v) => unawaited(_player.seek(total * v)),
                      ),
                    ),
                    Text(
                      '${formatClipLength(s.position)} / ${formatClipLength(total)}',
                      style: AppTypography.tabular(context.text.labelMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
