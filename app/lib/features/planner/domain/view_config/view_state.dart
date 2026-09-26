import 'dart:convert';

import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// Transient per-view state kept only on this device (T3.3.02, local table `ui_view_state`).
/// The vertical position is stored as a minute of day so it survives zoom changes.
@immutable
class ViewState {
  const ViewState({
    this.anchor,
    this.scrollMinute,
    this.pxPerMinute,
    this.daysPortrait,
    this.daysLandscape,
    this.extra = const {},
  });

  factory ViewState.fromJson(Map<String, Object?> json) => ViewState(
    anchor: json['anchor'] is String ? LocalDate.tryParse(json['anchor']! as String) : null,
    scrollMinute: (json['scrollMinute'] as num?)?.toDouble(),
    pxPerMinute: (json['pxPerMinute'] as num?)?.toDouble(),
    daysPortrait: (json['daysPortrait'] as num?)?.toInt(),
    daysLandscape: (json['daysLandscape'] as num?)?.toInt(),
    extra: json['extra'] is Map ? Map<String, Object?>.from(json['extra']! as Map) : const {},
  );

  final LocalDate? anchor;

  /// Minute of day at the top of the viewport.
  final double? scrollMinute;
  final double? pxPerMinute;
  final int? daysPortrait;
  final int? daysLandscape;

  /// View-specific local data (ribbon/slots style, collapsed sections, pinned countdowns…).
  final Map<String, Object?> extra;

  bool get isEmpty =>
      anchor == null &&
      scrollMinute == null &&
      pxPerMinute == null &&
      daysPortrait == null &&
      daysLandscape == null &&
      extra.isEmpty;

  Map<String, Object?> toJson() => {
    if (anchor != null) 'anchor': anchor!.toIso(),
    if (scrollMinute != null) 'scrollMinute': scrollMinute,
    if (pxPerMinute != null) 'pxPerMinute': pxPerMinute,
    if (daysPortrait != null) 'daysPortrait': daysPortrait,
    if (daysLandscape != null) 'daysLandscape': daysLandscape,
    if (extra.isNotEmpty) 'extra': extra,
  };

  ViewState copyWith({
    LocalDate? anchor,
    double? scrollMinute,
    double? pxPerMinute,
    int? daysPortrait,
    int? daysLandscape,
    Map<String, Object?>? extra,
  }) => ViewState(
    anchor: anchor ?? this.anchor,
    scrollMinute: scrollMinute ?? this.scrollMinute,
    pxPerMinute: pxPerMinute ?? this.pxPerMinute,
    daysPortrait: daysPortrait ?? this.daysPortrait,
    daysLandscape: daysLandscape ?? this.daysLandscape,
    extra: extra ?? this.extra,
  );

  /// Sets one view-specific local value.
  ViewState withExtra(String key, Object? value) => copyWith(extra: {...extra, key: value});

  @override
  bool operator ==(Object other) => other is ViewState && jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;

  @override
  String toString() => 'ViewState(${toJson()})';
}
