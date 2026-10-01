import 'dart:math' as math;

/// Waveform preview of a voice note (T2.2.13): recorder amplitudes reduced to a fixed number of
/// bar levels in 0..1, drawn on the note's thumbnail so every device shows it.
abstract final class Waveform {
  static const defaultBars = 48;

  /// Quietest level drawn above zero (dBFS); speech sits around −30…−10.
  static const floorDb = -50.0;

  /// Reduces amplitude samples (dBFS, ≤ 0) to [bars] levels: each bar is the peak of its slice,
  /// mapped linearly from [floorDb] → 0 to 0 dBFS → 1. Fewer samples than bars are stretched;
  /// no samples give a flat line.
  static List<double> fromAmplitudes(List<double> dbfs, {int bars = defaultBars}) {
    if (bars <= 0) return const [];
    if (dbfs.isEmpty) return List.filled(bars, 0);
    double level(double db) => db.isNaN ? 0 : ((db - floorDb) / -floorDb).clamp(0.0, 1.0);
    return [
      for (var b = 0; b < bars; b++)
        () {
          final start = (b * dbfs.length / bars).floor();
          final end = math.max(start + 1, ((b + 1) * dbfs.length / bars).floor());
          var peak = 0.0;
          for (var i = start; i < end && i < dbfs.length; i++) {
            peak = math.max(peak, level(dbfs[i]));
          }
          return peak;
        }(),
    ];
  }
}
