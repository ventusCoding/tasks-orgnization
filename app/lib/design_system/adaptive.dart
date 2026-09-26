import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Material 3 window size classes (T1.3.12 breakpoints, T1.3.19): compact < 600 dp,
/// medium 600–840 dp, expanded ≥ 840 dp.
enum WindowSizeClass {
  compact,
  medium,
  expanded;

  static const mediumMinWidth = 600.0;
  static const expandedMinWidth = 840.0;

  static WindowSizeClass fromWidth(double width) => width < mediumMinWidth
      ? compact
      : (width < expandedMinWidth ? medium : expanded);

  /// Class of the whole window.
  static WindowSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == compact;

  /// List and detail fit side by side.
  bool get isTwoPane => this == expanded;

  /// Navigation rail instead of a bottom bar.
  bool get usesRail => this != compact;

  /// Horizontal page margin for this class.
  double get margin => switch (this) {
    compact => 16,
    medium => 24,
    expanded => 24,
  };
}

extension WindowSizeX on BuildContext {
  WindowSizeClass get windowSize => WindowSizeClass.of(this);
}

/// Builds a layout per size class of the space actually available to it (not the window), so it
/// also works inside panes and dialogs.
class AdaptiveBuilder extends StatelessWidget {
  const AdaptiveBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, WindowSizeClass size) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      return builder(context, WindowSizeClass.fromWidth(width));
    },
  );
}

/// List/detail scaffold: side by side from [breakpoint] (list pane of [listWidth] at the start
/// edge), otherwise one pane — the list, or the detail when [showDetailWhenSingle] (the caller
/// then handles "back" through [onCloseDetail]).
class TwoPaneScaffold extends StatelessWidget {
  const TwoPaneScaffold({
    required this.list,
    super.key,
    this.detail,
    this.emptyDetail,
    this.listWidth = 360,
    this.breakpoint = WindowSizeClass.expandedMinWidth,
    this.showDetailWhenSingle = false,
    this.onCloseDetail,
  });

  final Widget list;
  final Widget? detail;

  /// Shown in the detail pane when nothing is selected (two-pane mode only).
  final Widget? emptyDetail;
  final double listWidth;
  final double breakpoint;
  final bool showDetailWhenSingle;
  final VoidCallback? onCloseDetail;

  /// Whether [TwoPaneScaffold] shows two panes at [width].
  static bool isTwoPaneAt(
    double width, {
    double breakpoint = WindowSizeClass.expandedMinWidth,
  }) => width >= breakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (isTwoPaneAt(constraints.maxWidth, breakpoint: breakpoint)) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: listWidth, child: list),
            const VerticalDivider(width: 1),
            Expanded(child: detail ?? emptyDetail ?? const SizedBox.shrink()),
          ],
        );
      }
      final current = detail;
      if (current != null && showDetailWhenSingle) {
        return PopScope(
          canPop: onCloseDetail == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) onCloseDetail?.call();
          },
          child: current,
        );
      }
      return list;
    },
  );
}

// ------------------------------------------------------------------------ keyboard shortcuts --

/// App-level intents bound to hardware-keyboard shortcuts (tablets/desktops, T1.3.19).
class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

class OpenCommandPaletteIntent extends Intent {
  const OpenCommandPaletteIntent();
}

class NewItemIntent extends Intent {
  const NewItemIntent();
}

/// Default shortcut map: every binding exists with Ctrl (Android/Windows/Linux) and ⌘ (Apple).
abstract final class AppShortcuts {
  static Map<ShortcutActivator, Intent> get defaults => {
    for (final (key, shift, intent) in const [
      (LogicalKeyboardKey.keyZ, false, UndoIntent()),
      (LogicalKeyboardKey.keyZ, true, RedoIntent()),
      (LogicalKeyboardKey.keyY, false, RedoIntent()),
      (LogicalKeyboardKey.keyF, false, OpenSearchIntent()),
      (LogicalKeyboardKey.keyK, false, OpenCommandPaletteIntent()),
      (LogicalKeyboardKey.keyN, false, NewItemIntent()),
    ]) ...{
      SingleActivator(key, control: true, shift: shift): intent,
      SingleActivator(key, meta: true, shift: shift): intent,
    },
  };
}

/// Installs [AppShortcuts.defaults] with the given [actions] around [child]. While a text field
/// has focus the app shortcuts step aside, so the field keeps its own editing keys (Ctrl/⌘+Z
/// undoes typing, Ctrl+K on macOS deletes to the line end…).
class AppShortcutScope extends StatelessWidget {
  const AppShortcutScope({
    required this.actions,
    required this.child,
    super.key,
    this.shortcuts,
  });

  final Map<Type, Action<Intent>> actions;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Widget child;

  /// Whether the primary focus is inside an editable text.
  static bool get isEditingText {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return context.widget is EditableText ||
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: shortcuts ?? AppShortcuts.defaults,
    child: Actions(
      actions: {
        for (final e in actions.entries)
          e.key: _UnlessEditingAction<Intent>(e.value),
      },
      child: Focus(autofocus: true, child: child),
    ),
  );
}

/// Disabled while a text field has focus — a disabled action lets the key event continue to the
/// text-editing shortcuts above.
class _UnlessEditingAction<T extends Intent> extends Action<T> {
  _UnlessEditingAction(this.inner);

  final Action<T> inner;

  @override
  bool isEnabled(T intent) =>
      !AppShortcutScope.isEditingText && inner.isEnabled(intent);

  @override
  Object? invoke(T intent) => inner.invoke(intent);
}
