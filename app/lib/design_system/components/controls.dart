import 'dart:async';

import 'package:everslot/design_system/l10n_x.dart';
import 'package:everslot/design_system/tokens.dart';
import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

/// Button variants of the design system (T1.3.10).
enum AppButtonVariant { primary, secondary, text, destructive }

/// Labelled button with an optional leading icon and a busy state. Always ≥ 48 dp tall; while
/// [busy] it shows a spinner, ignores taps and announces itself as disabled.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.busy = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool busy;

  /// Fills the available width (sheet actions, forms).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final onTap = busy ? null : onPressed;
    final child = busy
        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(label, overflow: TextOverflow.ellipsis);
    final leading = busy || icon == null ? null : Icon(icon, size: 18);
    const minSize = Size(64, 48);
    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton.icon(
        onPressed: onTap,
        icon: leading,
        label: child,
        style: FilledButton.styleFrom(minimumSize: minSize),
      ),
      AppButtonVariant.destructive => FilledButton.icon(
        onPressed: onTap,
        icon: leading,
        label: child,
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          backgroundColor: context.colors.error,
          foregroundColor: context.colors.onError,
        ),
      ),
      AppButtonVariant.secondary => OutlinedButton.icon(
        onPressed: onTap,
        icon: leading,
        label: child,
        style: OutlinedButton.styleFrom(minimumSize: minSize),
      ),
      AppButtonVariant.text => TextButton.icon(
        onPressed: onTap,
        icon: leading,
        label: child,
        style: TextButton.styleFrom(minimumSize: minSize),
      ),
    };
    final semantic = Semantics(label: busy ? label : null, enabled: onTap != null, child: button);
    return expand ? SizedBox(width: double.infinity, child: semantic) : semantic;
  }
}

/// Icon-only button: a [tooltip] is required (it is also the semantics label).
class AppIconButton extends StatelessWidget {
  const AppIconButton({required this.icon, required this.tooltip, required this.onPressed, super.key, this.badge});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Optional count shown as a [CountBadge] (0 hides it).
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final count = badge ?? 0;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: count > 0 ? Badge(label: Text(CountBadge.format(count)), child: Icon(icon)) : Icon(icon),
    );
  }
}

/// Search input with a clear button; [onChanged] fires per keystroke.
class AppSearchField extends StatefulWidget {
  const AppSearchField({required this.onChanged, super.key, this.hint, this.initial, this.autofocus = false});

  final ValueChanged<String> onChanged;
  final String? hint;
  final String? initial;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    autofocus: widget.autofocus,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.search),
      hintText: widget.hint ?? context.l10n.actionSearch,
      suffixIcon: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _controller.text.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
                tooltip: context.l10n.actionClear,
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              ),
      ),
    ),
    onChanged: widget.onChanged,
  );
}

/// Bottom-sheet body: scrollable content above sticky actions, padded above the keyboard.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({required this.child, super.key, this.actions = const []});

  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
              child: child,
            ),
          ),
          if (actions.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final (i, a) in actions.indexed) ...[
                      if (i > 0) const SizedBox(width: Space.sm),
                      Flexible(child: a),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single-choice segmented control over [segments] (value → label, optional icon).
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({required this.segments, required this.selected, required this.onChanged, super.key});

  final List<(T value, String label, IconData? icon)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<T>(
    showSelectedIcon: false,
    segments: [
      for (final s in segments)
        ButtonSegment<T>(value: s.$1, label: Text(s.$2), icon: s.$3 == null ? null : Icon(s.$3)),
    ],
    selected: {selected},
    onSelectionChanged: (v) => onChanged(v.first),
  );
}

/// One swipe action of a [SwipeRow].
class RowSwipeAction {
  const RowSwipeAction({required this.label, required this.icon, required this.color, required this.onTriggered});

  final String label;
  final IconData icon;
  final Color color;

  /// Returns true to let the row be dismissed (e.g. delete); false snaps it back.
  final FutureOr<bool> Function() onTriggered;
}

/// List row with a start-to-end ([start]) and an end-to-start ([end]) swipe action. Directions
/// follow the reading direction, so RTL mirrors them. Actions are also offered to screen readers
/// as custom semantics actions (swipes are not discoverable there).
class SwipeRow extends StatelessWidget {
  const SwipeRow({required this.id, required this.child, super.key, this.start, this.end});

  final Object id;
  final Widget child;
  final RowSwipeAction? start;
  final RowSwipeAction? end;

  @override
  Widget build(BuildContext context) {
    final startAction = start;
    final endAction = end;
    Widget background(RowSwipeAction a, AlignmentDirectional align) => ColoredBox(
      color: a.color,
      child: Align(
        alignment: align,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          child: Icon(a.icon, color: CategoryColors.onBackground(a.color), semanticLabel: a.label),
        ),
      ),
    );
    return Semantics(
      customSemanticsActions: {
        if (startAction != null) CustomSemanticsAction(label: startAction.label): startAction.onTriggered,
        if (endAction != null) CustomSemanticsAction(label: endAction.label): endAction.onTriggered,
      },
      child: Dismissible(
        key: ValueKey(id),
        // Dismissible directions already follow the reading direction (startToEnd = towards the end).
        direction: switch ((startAction != null, endAction != null)) {
          (true, true) => DismissDirection.horizontal,
          (true, false) => DismissDirection.startToEnd,
          (false, true) => DismissDirection.endToStart,
          (false, false) => DismissDirection.none,
        },
        background: startAction == null
            ? const SizedBox.shrink()
            : background(startAction, AlignmentDirectional.centerStart),
        secondaryBackground: endAction == null ? null : background(endAction, AlignmentDirectional.centerEnd),
        confirmDismiss: (direction) async {
          final action = direction == DismissDirection.startToEnd ? startAction : endAction;
          if (action == null) return false;
          return action.onTriggered();
        },
        child: child,
      ),
    );
  }
}

/// Round avatar with up to two initials (or [icon]) on a tinted background.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.name, this.icon, this.radius = 20, this.colorArgb});

  final String? name;
  final IconData? icon;
  final double radius;

  /// Optional category color; defaults to the theme's primary container.
  final int? colorArgb;

  static String initials(String? source) {
    final parts = (source ?? '').trim().split(RegExp(r'[\s@._-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = String.fromCharCodes(parts.first.runes.take(1));
    final second = parts.length > 1 ? String.fromCharCodes(parts[1].runes.take(1)) : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final argb = colorArgb;
    final bg = argb == null
        ? context.colors.primaryContainer
        : CategoryColors.background(argb, context.theme.brightness);
    final fg = argb == null ? context.colors.onPrimaryContainer : CategoryColors.onBackground(bg);
    final iconData = icon;
    return Semantics(
      label: name,
      image: true,
      child: ExcludeSemantics(
        child: CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          foregroundColor: fg,
          child: iconData != null
              ? Icon(iconData, size: radius)
              : Text(
                  initials(name),
                  style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}

/// Small numeric badge ("99+" above 99); hidden at 0.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});

  final int count;

  static String format(int count) => count > 99 ? '99+' : '$count';

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Badge(label: Text(format(count)));
  }
}
