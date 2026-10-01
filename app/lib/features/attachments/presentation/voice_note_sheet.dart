import 'dart:async';
import 'dart:io';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/application/providers.dart';
import 'package:everslot/features/attachments/domain/waveform.dart';
import 'package:everslot/features/attachments/presentation/attachment_ui.dart' show showPermissionHelp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Records a voice note (T2.2.13): AAC in an `.m4a`, live level bars, timer, then attach or
/// discard. Returns the recording with its duration and waveform, or null.
Future<PickedFileRef?> recordVoiceNote(BuildContext context) => showAppSheet<PickedFileRef>(
  context,
  title: context.l10n.voiceNoteTitle,
  builder: (_) => const VoiceNoteRecorderSheet(),
);

enum _Phase { idle, recording, recorded }

class VoiceNoteRecorderSheet extends ConsumerStatefulWidget {
  const VoiceNoteRecorderSheet({super.key});

  /// Recordings stop by themselves after this long.
  static const maxDuration = Duration(minutes: 10);
  static const tick = Duration(milliseconds: 200);

  @override
  ConsumerState<VoiceNoteRecorderSheet> createState() => _VoiceNoteRecorderSheetState();
}

class _VoiceNoteRecorderSheetState extends ConsumerState<VoiceNoteRecorderSheet> {
  late final VoiceRecorder _recorder = ref.read(voiceRecorderFactoryProvider)();
  final _levels = <double>[];
  StreamSubscription<double>? _levelSub;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  _Phase _phase = _Phase.idle;
  String? _path;
  bool _kept = false;

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_levelSub?.cancel());
    final phase = _phase;
    final path = _path;
    final kept = _kept;
    unawaited(() async {
      if (phase == _Phase.recording) await _recorder.cancel();
      if (phase == _Phase.recorded && !kept && path != null) {
        final f = File(path);
        if (f.existsSync()) await f.delete();
      }
      await _recorder.dispose();
    }());
    super.dispose();
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      await showPermissionHelp(context);
      if (mounted) navigator.pop();
      return;
    }
    final dir = await Directory.systemTemp.createTemp('voice');
    final path = '${dir.path}/voice.m4a';
    await _recorder.start(path);
    _levelSub = _recorder.levels.listen((db) {
      if (!mounted) return;
      setState(() => _levels.add(db));
    });
    _timer = Timer.periodic(VoiceNoteRecorderSheet.tick, (_) {
      if (!mounted) return;
      setState(() => _elapsed += VoiceNoteRecorderSheet.tick);
      if (_elapsed >= VoiceNoteRecorderSheet.maxDuration) unawaited(_stop());
    });
    if (mounted) {
      setState(() {
        _path = path;
        _phase = _Phase.recording;
      });
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    await _levelSub?.cancel();
    _levelSub = null;
    final path = await _recorder.stop() ?? _path;
    if (!mounted) return;
    setState(() {
      _path = path;
      _phase = path == null ? _Phase.idle : _Phase.recorded;
    });
  }

  void _attach() {
    final path = _path;
    if (path == null) return;
    final l = context.l10n;
    final prefs = ref.read(userPreferencesProvider);
    final fmt = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final time = ref.read(appTimeProvider);
    final now = time.nowLocal();
    _kept = true;
    Navigator.pop(
      context,
      PickedFileRef(
        path: path,
        name: '${l.voiceNoteTitle} ${fmt.dateMedium(now.date)} ${fmt.time(now.time).replaceAll(':', '.')}.m4a',
        mimeType: 'audio/mp4',
        durationMs: _elapsed.inMilliseconds,
        waveform: waveformOf(_levels),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = AppFormat(context.localeName, l10n: l);
    final timer = AppFormat.counter(_elapsed).substring(3); // "mm:ss"
    final recording = _phase == _Phase.recording;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: recording,
              label: recording ? l.voiceNoteRecording(fmt.duration(_elapsed.inMinutes)) : null,
              child: Text(
                _phase == _Phase.idle ? l.voiceNoteHint : timer,
                key: const ValueKey('voice-note-timer'),
                style: _phase == _Phase.idle
                    ? context.text.bodyMedium
                    : AppTypography.tabular(context.text.headlineMedium),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Space.md),
            ExcludeSemantics(
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: CustomPaint(
                  painter: _LevelsPainter(
                    levels: Waveform.fromAmplitudes(
                      _levels.length > 160 ? _levels.sublist(_levels.length - 160) : _levels,
                      bars: 40,
                    ),
                    color: recording ? context.colors.error : context.colors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            switch (_phase) {
              _Phase.idle => AppButton(
                key: const ValueKey('voice-note-record'),
                label: l.voiceNoteRecord,
                icon: Icons.mic,
                onPressed: _start,
              ),
              _Phase.recording => AppButton(
                key: const ValueKey('voice-note-stop'),
                label: l.voiceNoteStop,
                icon: Icons.stop,
                variant: AppButtonVariant.destructive,
                onPressed: _stop,
              ),
              _Phase.recorded => Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    key: const ValueKey('voice-note-discard'),
                    label: l.voiceNoteDiscard,
                    variant: AppButtonVariant.text,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: Space.sm),
                  AppButton(
                    key: const ValueKey('voice-note-save'),
                    label: l.voiceNoteSave,
                    icon: Icons.attach_file,
                    onPressed: _attach,
                  ),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _LevelsPainter extends CustomPainter {
  _LevelsPainter({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;
    final slot = size.width / levels.length;
    final paint = Paint()..color = color;
    for (var i = 0; i < levels.length; i++) {
      final h = (levels[i] * size.height).clamp(3.0, size.height);
      final w = slot * 0.6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * slot + (slot - w) / 2, (size.height - h) / 2, w, h),
          Radius.circular(w / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelsPainter old) => old.levels != levels || old.color != color;
}
