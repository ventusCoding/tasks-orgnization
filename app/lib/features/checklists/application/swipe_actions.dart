import 'package:everslot/core/providers.dart';
import 'package:everslot/core/settings/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// What a horizontal swipe on a row does (T4.2.10).
enum SwipeAction {
  indent,
  outdent,
  complete,
  menu,
  none;

  static SwipeAction parse(Object? v, SwipeAction fallback) {
    for (final a in values) {
      if (a.name == v) return a;
    }
    return fallback;
  }
}

/// `user_settings.checklists.swipeActions` (arch §8.5):
/// `{ "edit": {"right": "indent", "left": "outdent"}, "preview": {"right": "complete", "left": "menu"} }`.
/// Directions are reading-relative: "right" means *toward the reading direction's end* in LTR and
/// is mirrored in RTL.
@immutable
class SwipeActions {
  const SwipeActions({
    this.editRight = SwipeAction.indent,
    this.editLeft = SwipeAction.outdent,
    this.previewRight = SwipeAction.complete,
    this.previewLeft = SwipeAction.menu,
  });

  static const defaults = SwipeActions();

  final SwipeAction editRight;
  final SwipeAction editLeft;
  final SwipeAction previewRight;
  final SwipeAction previewLeft;

  factory SwipeActions.fromSettings(Map<String, dynamic> settings) {
    final raw = settings['swipeActions'];
    if (raw is! Map) return defaults;
    final edit = raw['edit'] is Map ? raw['edit'] as Map<Object?, Object?> : const <Object?, Object?>{};
    final preview = raw['preview'] is Map ? raw['preview'] as Map<Object?, Object?> : const <Object?, Object?>{};
    return SwipeActions(
      editRight: SwipeAction.parse(edit['right'], SwipeAction.indent),
      editLeft: SwipeAction.parse(edit['left'], SwipeAction.outdent),
      previewRight: SwipeAction.parse(preview['right'], SwipeAction.complete),
      previewLeft: SwipeAction.parse(preview['left'], SwipeAction.menu),
    );
  }

  Map<String, Object?> toJson() => {
    'edit': {'right': editRight.name, 'left': editLeft.name},
    'preview': {'right': previewRight.name, 'left': previewLeft.name},
  };

  /// Action for a swipe toward the end (true) or start (false) of the reading direction.
  SwipeAction resolve({required bool preview, required bool towardEnd}) =>
      preview ? (towardEnd ? previewRight : previewLeft) : (towardEnd ? editRight : editLeft);

  SwipeActions copyWith({
    SwipeAction? editRight,
    SwipeAction? editLeft,
    SwipeAction? previewRight,
    SwipeAction? previewLeft,
  }) => SwipeActions(
    editRight: editRight ?? this.editRight,
    editLeft: editLeft ?? this.editLeft,
    previewRight: previewRight ?? this.previewRight,
    previewLeft: previewLeft ?? this.previewLeft,
  );

  @override
  bool operator ==(Object other) =>
      other is SwipeActions &&
      other.editRight == editRight &&
      other.editLeft == editLeft &&
      other.previewRight == previewRight &&
      other.previewLeft == previewLeft;

  @override
  int get hashCode => Object.hash(editRight, editLeft, previewRight, previewLeft);
}

final swipeActionsProvider = Provider<SwipeActions>((ref) {
  final settings = ref.watch(settingsProvider(SettingsNs.checklists)).value ?? const <String, dynamic>{};
  return SwipeActions.fromSettings(settings);
});

Future<void> saveSwipeActions(WidgetRef ref, SwipeActions actions) =>
    ref.read(settingsRepositoryProvider).update(SettingsNs.checklists, {'swipeActions': actions.toJson()});
