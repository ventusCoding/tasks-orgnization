import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/domain/rule_spec.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// A sum to solve (two 2-digit numbers).
class MathProblem {
  MathProblem(this.a, this.b);

  factory MathProblem.random(math.Random random) => MathProblem(10 + random.nextInt(90), 10 + random.nextInt(90));

  final int a;
  final int b;

  int get answer => a + b;
}

/// Counts shakes from user-acceleration samples: a peak above [threshold] m/s², at most one per
/// [cooldown].
class ShakeCounter {
  ShakeCounter({this.threshold = 12, this.cooldown = const Duration(milliseconds: 300)});

  final double threshold;
  final Duration cooldown;
  int count = 0;
  DateTime? _last;

  /// Returns true when the sample counted as a shake.
  bool add(double x, double y, double z, DateTime at) {
    final magnitude = math.sqrt(x * x + y * y + z * z);
    if (magnitude < threshold) return false;
    if (_last != null && at.difference(_last!) < cooldown) return false;
    _last = at;
    count++;
    return true;
  }
}

/// User-acceleration samples (x, y, z m/s², time); tests feed their own.
final accelerationStreamProvider = Provider<Stream<(double, double, double, DateTime)>>(
  (ref) => userAccelerometerEventStream().map((e) => (e.x, e.y, e.z, e.timestamp)),
);

/// The QR scanner view; calls `onCode` for every code seen (tests replace it).
typedef QrScannerBuilder = Widget Function(BuildContext context, ValueChanged<String> onCode);

final qrScannerBuilderProvider = Provider<QrScannerBuilder>(
  (ref) =>
      (context, onCode) => MobileScanner(
        onDetect: (capture) {
          for (final b in capture.barcodes) {
            final v = b.rawValue;
            if (v != null) onCode(v);
          }
        },
      ),
);

/// The mission that stops a ringing alarm (T7.2.25); [onSolved] once it's done.
class AlarmMissionView extends ConsumerStatefulWidget {
  const AlarmMissionView({required this.mission, required this.onSolved, this.title, this.random, super.key});

  final AlarmMission mission;
  final VoidCallback onSolved;

  /// The text to type for [AlarmMissionType.type].
  final String? title;

  /// Seeded in tests.
  final math.Random? random;

  @override
  ConsumerState<AlarmMissionView> createState() => _AlarmMissionViewState();
}

class _AlarmMissionViewState extends ConsumerState<AlarmMissionView> {
  late final math.Random _random = widget.random ?? math.Random();
  late MathProblem _problem = MathProblem.random(_random);
  final _input = TextEditingController();
  int _done = 0;
  bool _wrong = false;
  final _shakes = ShakeCounter();
  StreamSubscription<(double, double, double, DateTime)>? _sub;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    if (widget.mission.type == AlarmMissionType.shake) {
      _sub = ref.read(accelerationStreamProvider).listen((e) {
        if (_shakes.add(e.$1, e.$2, e.$3, e.$4)) {
          setState(() {});
          if (_shakes.count >= widget.mission.effectiveCount) _solve();
        }
      });
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    _input.dispose();
    super.dispose();
  }

  void _solve() {
    if (_solved) return;
    _solved = true;
    unawaited(_sub?.cancel());
    widget.onSolved();
  }

  void _checkMath() {
    final value = int.tryParse(_input.text.trim());
    if (value != _problem.answer) {
      setState(() => _wrong = true);
      return;
    }
    _input.clear();
    setState(() {
      _wrong = false;
      _done++;
      _problem = MathProblem.random(_random);
    });
    if (_done >= widget.mission.effectiveCount) _solve();
  }

  void _checkTitle() {
    final expected = (widget.title ?? '').trim().toLowerCase();
    if (_input.text.trim().toLowerCase() == expected && expected.isNotEmpty) {
      _solve();
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = widget.mission;
    final error = _wrong ? l.notifMissionWrong : null;
    return switch (m.type) {
      AlarmMissionType.math => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.notifMissionMathProgress(_done + 1, m.effectiveCount), style: context.text.labelLarge),
          const SizedBox(height: Space.sm),
          Text('${_problem.a} + ${_problem.b} = ?', style: context.text.headlineMedium),
          TextField(
            key: const ValueKey('mission-input'),
            controller: _input,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l.notifMissionAnswer, errorText: error),
            onSubmitted: (_) => _checkMath(),
          ),
          TextButton(key: const ValueKey('mission-check'), onPressed: _checkMath, child: Text(l.notifMissionCheck)),
        ],
      ),
      AlarmMissionType.type => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.notifMissionTypeTitle, style: context.text.labelLarge),
          Text(widget.title ?? '', style: context.text.titleLarge),
          TextField(
            key: const ValueKey('mission-input'),
            controller: _input,
            decoration: InputDecoration(labelText: l.notifMissionAnswer, errorText: error),
            onSubmitted: (_) => _checkTitle(),
          ),
          TextButton(key: const ValueKey('mission-check'), onPressed: _checkTitle, child: Text(l.notifMissionCheck)),
        ],
      ),
      AlarmMissionType.shake => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.notifMissionShake(m.effectiveCount), style: context.text.labelLarge),
          const SizedBox(height: Space.sm),
          LinearProgressIndicator(
            value: (_shakes.count / m.effectiveCount).clamp(0, 1),
            semanticsLabel: l.notifMissionShake(m.effectiveCount),
          ),
        ],
      ),
      AlarmMissionType.qr => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.notifMissionQr, style: context.text.labelLarge),
          const SizedBox(height: Space.sm),
          SizedBox(
            height: 220,
            child: ref.read(qrScannerBuilderProvider)(context, (code) {
              if (code == m.code) _solve();
            }),
          ),
        ],
      ),
    };
  }
}
