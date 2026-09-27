import 'package:material_ui/material_ui.dart';

/// Called when a row drag ends outside the pane it started in; returns true when the host moved
/// the item into another pane (T4.5.17).
typedef PaneDropHandler = Future<bool> Function(String sourceChecklistId, String itemId, Offset globalPosition);

/// Marks a checklist screen as one pane of a split view, so drags can leave it (T4.5.17).
class ChecklistPaneScope extends InheritedWidget {
  const ChecklistPaneScope({required this.onDropOutside, required super.child, super.key});

  final PaneDropHandler onDropOutside;

  static ChecklistPaneScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ChecklistPaneScope>();

  @override
  bool updateShouldNotify(ChecklistPaneScope oldWidget) => false;
}
