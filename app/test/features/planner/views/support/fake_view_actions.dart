import 'package:everslot/features/planner/application/view_config/view_actions.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Records the extra view actions (paste…) instead of writing.
class FakeViewActions implements PlannerViewActions {
  final calls = <String>[];

  @override
  Future<String?> paste(PlannerItem item, LocalDateTime start) async {
    calls.add('paste ${item.title} ${start.toIso()}');
    return 'pasted';
  }

  @override
  Future<void> delete(PlannerItem item, {EditScope scope = EditScope.allOccurrences}) async => calls.add('delete');

  @override
  Future<String?> duplicate(PlannerItem item) async => null;

  @override
  Future<void> reorder(PlannerItem item, {String? afterKey, String? beforeKey}) async =>
      calls.add('reorder ${item.title} after=$afterKey before=$beforeKey');

  @override
  Future<void> unschedule(PlannerItem item) async {}

  @override
  Future<void> startTimer(PlannerItem item) async {}

  @override
  Future<void> pauseTimer(PlannerItem item) async {}

  @override
  Future<void> stopTimer(PlannerItem item) async {}
}
