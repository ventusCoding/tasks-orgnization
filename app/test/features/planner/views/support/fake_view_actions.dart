import 'package:everslot/features/planner/application/view_config/view_actions.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';

/// Records the extra view actions (paste…) instead of writing.
class FakeViewActions implements PlannerViewActions {
  final calls = <String>[];

  @override
  Future<String?> createBacklog(String title) async {
    calls.add('createBacklog $title');
    return 'new';
  }

  @override
  Future<void> editFields(PlannerItem item, BacklogEdit edit, {EditScope scope = EditScope.allOccurrences}) async =>
      calls.add('fields ${item.title} title=${edit.title} prio=${edit.priority} cat=${edit.categoryId} ${scope.name}');

  @override
  Future<void> editBacklog(PlannerItem item, BacklogEdit edit) async => calls.add(
    'edit ${item.title} est=${edit.estimateMinutes} prio=${edit.priority} '
    'deadline=${edit.deadline?.toIso()} cat=${edit.categoryId}',
  );

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
  Future<void> unschedule(PlannerItem item, {String source = 'menu'}) async =>
      calls.add('unschedule ${item.title} $source');

  @override
  Future<void> startTimer(PlannerItem item) async => calls.add('start ${item.title}');

  @override
  Future<void> pauseTimer(PlannerItem item) async => calls.add('pause ${item.title}');

  @override
  Future<void> stopTimer(PlannerItem item) async => calls.add('stop ${item.title}');
}
