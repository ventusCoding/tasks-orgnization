import 'dart:convert';

import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/planner/presentation/grid/engine/page_axis.dart';
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

  /// Scroll offset showing [minute] at the top (or at [anchorFraction] of the viewport).
  static double offsetForMinute(
    PageAxis axis,
    double ppm,
    double minute, {
    double viewportExtent = 0,
    double anchorFraction = 0,
  }) {
    final y = axis.yOf(minute, ppm: ppm) - viewportExtent * anchorFraction;
    final max = axis.height(ppm) - viewportExtent;
    return y.clamp(0.0, max < 0 ? 0.0 : max);
  }

  /// Minute of day at scroll [offset] (+ [viewportExtent] × [anchorFraction]).
  static double minuteAtOffset(PageAxis axis, double ppm, double offset, {double viewportExtent = 0, double anchorFraction = 0}) =>
      axis.locate(offset + viewportExtent * anchorFraction, ppm).wall;

  @override
  bool operator ==(Object other) => other is ViewState && jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

/// Reads/writes [ViewState] rows (local only, never synced).
class ViewStateRepository {
  ViewStateRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  Future<ViewState?> read(String viewId) async {
    final row = await (_db.select(_db.uiViewState)..where((s) => s.viewId.equals(viewId))).getSingleOrNull();
    if (row == null) return null;
    try {
      final decoded = jsonDecode(row.json);
      return decoded is Map ? ViewState.fromJson(Map<String, Object?>.from(decoded)) : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String viewId, ViewState state) => _db
      .into(_db.uiViewState)
      .insertOnConflictUpdate(
        UiViewStateCompanion.insert(viewId: viewId, json: jsonEncode(state.toJson()), updatedAt: _clock.nowUtc()),
      );

  Future<void> update(String viewId, ViewState Function(ViewState current) change) async {
    final current = await read(viewId) ?? const ViewState();
    await write(viewId, change(current));
  }
}
