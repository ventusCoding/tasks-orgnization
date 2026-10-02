import 'package:meta/meta.dart';

/// App lock state (T8.3.09).
@immutable
class AppLockState {
  const AppLockState({this.ready = false, this.locked = false, this.obscured = false, this.authenticating = false});

  /// Privacy settings are known (until then content stays covered when a lock might be on).
  final bool ready;
  final bool locked;

  /// The app is inactive / in the app switcher and its content must be hidden.
  final bool obscured;
  final bool authenticating;

  bool get covered => !ready || locked || obscured;

  AppLockState copyWith({bool? ready, bool? locked, bool? obscured, bool? authenticating}) => AppLockState(
    ready: ready ?? this.ready,
    locked: locked ?? this.locked,
    obscured: obscured ?? this.obscured,
    authenticating: authenticating ?? this.authenticating,
  );

  @override
  bool operator ==(Object other) =>
      other is AppLockState &&
      other.ready == ready &&
      other.locked == locked &&
      other.obscured == obscured &&
      other.authenticating == authenticating;

  @override
  int get hashCode => Object.hash(ready, locked, obscured, authenticating);
}

abstract final class AppLockPolicy {
  /// Lock again after the app really went to the background for at least [timeoutSeconds]
  /// (system dialogs — e.g. the biometric prompt itself — only make it inactive: `away` is zero).
  static bool lockOnReturn({required bool enabled, required int timeoutSeconds, required Duration away}) =>
      enabled && away > Duration.zero && away.inSeconds >= timeoutSeconds;
}
