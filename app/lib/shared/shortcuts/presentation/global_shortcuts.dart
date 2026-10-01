import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// App-wide keyboard shortcuts (T1.3.19) mounted once at the app root:
/// Ctrl/⌘+Z undo and Ctrl/⌘+Shift+Z / Ctrl+Y redo on the app's undo stack (T2.3.06), Ctrl/⌘+F
/// search, Ctrl/⌘+K command palette, Ctrl/⌘+N new item. Text fields keep their own editing keys.
class GlobalShortcuts extends ConsumerWidget {
  const GlobalShortcuts({required this.child, super.key, this.onSearch, this.onCommandPalette, this.onNewItem});

  final Widget child;
  final VoidCallback? onSearch;
  final VoidCallback? onCommandPalette;
  final VoidCallback? onNewItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppShortcutScope(
    actions: {
      UndoIntent: CallbackAction<UndoIntent>(onInvoke: (_) => undoWithFeedback(context, ref)),
      RedoIntent: CallbackAction<RedoIntent>(onInvoke: (_) => redoWithFeedback(context, ref)),
      if (onSearch != null) OpenSearchIntent: CallbackAction<OpenSearchIntent>(onInvoke: (_) => onSearch!()),
      if (onCommandPalette != null)
        OpenCommandPaletteIntent: CallbackAction<OpenCommandPaletteIntent>(onInvoke: (_) => onCommandPalette!()),
      if (onNewItem != null) NewItemIntent: CallbackAction<NewItemIntent>(onInvoke: (_) => onNewItem!()),
    },
    child: child,
  );
}

/// Undoes the last command of the app's undo stack and offers "Redo" (T2.3.06).
Future<void> undoWithFeedback(BuildContext context, WidgetRef ref) async {
  final stack = ref.read(undoStackProvider);
  final l = context.l10n;
  final label = stack.undoLabel;
  final done = await stack.undo();
  if (!context.mounted) return;
  final message = done && label != null ? l.undoDoneSnack(label) : l.undoNothing;
  _feedback(
    context,
    message,
    action: done ? SnackBarAction(label: l.actionRedo, onPressed: () => redoWithFeedback(context, ref)) : null,
  );
}

/// Redoes the last undone command and offers "Undo" again.
Future<void> redoWithFeedback(BuildContext context, WidgetRef ref) async {
  final stack = ref.read(undoStackProvider);
  final l = context.l10n;
  final label = stack.redoLabel;
  final done = await stack.redo();
  if (!context.mounted) return;
  final message = done && label != null ? l.redoDoneSnack(label) : l.redoNothing;
  _feedback(
    context,
    message,
    action: done ? SnackBarAction(label: l.actionUndo, onPressed: () => undoWithFeedback(context, ref)) : null,
  );
}

void _feedback(BuildContext context, String message, {SnackBarAction? action}) {
  announce(context, message);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}
