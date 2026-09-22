import 'package:everslot/core/providers.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/design_system/l10n_x.dart';
import 'package:everslot/design_system/tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Modal bottom sheet with Everslot styling (keyboard-safe, scrollable).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  bool isScrollControlled = true,
  bool useSafeArea = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: useSafeArea,
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.xl, 0, Space.xl, Space.md),
            child: Text(title, style: ctx.text.titleLarge),
          ),
        Flexible(child: builder(ctx)),
      ],
    ),
  ),
);

/// Confirmation dialog; returns true when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? body,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.actionCancel)),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: ctx.colors.error,
                  foregroundColor: ctx.colors.onError,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? ctx.l10n.actionConfirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Text input dialog (reason notes, renames…).
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String? initial,
  String? hint,
  int maxLines = 1,
  bool allowEmpty = false,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: maxLines == 1 ? (v) => Navigator.pop(ctx, v) : null,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.actionCancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(ctx.l10n.actionSave),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null) return null;
  if (!allowEmpty && result.trim().isEmpty) return null;
  return result.trim();
}

/// Shows a snackbar with an Undo action and registers [record] on the undo stack (T2.3.06).
void showUndoSnackBar(
  BuildContext context,
  WidgetRef ref, {
  required String message,
  required OpRecord record,
}) {
  final stack = ref.read(undoStackProvider)..push(message, record);
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: SnackBarAction(label: context.l10n.actionUndo, onPressed: () => stack.undo()),
    ),
  );
}

void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
