import 'package:everslot/core/providers.dart';
import 'package:everslot/core/routing/deep_links.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/checklist_notification_targets.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart' show notificationTextsProvider;
import 'package:everslot/features/notifications/notification_contributions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Makes checklists and their items notifiable (`features/notifications/README.md` §2): one
/// target per live list and per relevant item, built from the repositories in one pass (three
/// queries). Registered statically in `notification_contributions.dart`, so it also runs in the
/// background isolate — it only reads database-backed providers, lazily.
class ChecklistsNotificationSource implements NotificationTargetSource {
  ChecklistsNotificationSource(this._ref);

  final Ref _ref;

  @override
  String get section => NotificationSection.checklists.wire;

  /// Writes to `checklists`, `checklist_items` and `checklist_runs` already trigger replans;
  /// targets depend on nothing else.
  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<List<NotificationTarget>> targetsBetween(DateTime fromUtc, DateTime toUtc) async {
    final lists = await _ref.read(checklistsRepositoryProvider).notifiableLists();
    if (lists.isEmpty) return const [];
    final itemsRepo = _ref.read(checklistItemsRepositoryProvider);
    final items = await itemsRepo.notifiableItems();
    final changes = await itemsRepo.recentStatusChanges(fromUtc.subtract(const Duration(days: 1)));
    return ChecklistNotificationTargets.build(
      lists: lists,
      items: items,
      zones: _ref.read(zoneResolverProvider),
      deviceZone: _ref.read(deviceZoneProvider),
      fromUtc: fromUtc,
      toUtc: toUtc,
      statusChanges: [
        for (final (itemId, e) in changes) ItemStatusChange(itemId: itemId, from: e.from, to: e.to, at: e.at),
      ],
      untitled: _untitled(),
    );
  }

  String _untitled() {
    try {
      return _ref.read(notificationTextsProvider).l10n.listsUntitled;
    } on Object {
      return '';
    }
  }

  /// Items: live, still open, in a live non-archived list. Lists: live, not archived and not
  /// entirely completed.
  @override
  Future<bool> guardOpen(NotificationTarget t) async {
    final lists = _ref.read(checklistsRepositoryProvider);
    final items = _ref.read(checklistItemsRepositoryProvider);
    switch (t.type) {
      case NotificationTargetType.checklistItem:
        final item = await items.liveById(t.id);
        if (item == null || !item.status.isOpen) return false;
        final list = await lists.byId(item.checklistId);
        return list != null && !list.isDeleted && !list.isArchived;
      case NotificationTargetType.checklist:
        final list = await lists.byId(t.id);
        if (list == null || list.isDeleted || list.isArchived || list.isTemplate) return false;
        return !ChecklistNotificationTargets.listComplete(list, await items.items(t.id));
      default:
        return true;
    }
  }
}

/// Checklist actions from notifications, banners and inbox rows (README §3): *Done* /
/// *Complete item*, *Mark ongoing*, *Mark waiting*, *Mark blocked*. Writes go through the same
/// status service as the UI (`cause = notification`, cascades included) and are idempotent: the
/// target status is set, never toggled. List-level actions open the list.
class ChecklistNotificationActions implements NotificationActionHandler {
  ChecklistNotificationActions(Ref _);

  @override
  Set<NotificationTargetType> get targetTypes => const {
    NotificationTargetType.checklistItem,
    NotificationTargetType.checklist,
  };

  @override
  Set<String> get actionIds => const {
    NotificationActionIds.done,
    NotificationActionIds.completeItem,
    NotificationActionIds.markOngoing,
    NotificationActionIds.markWaiting,
    NotificationActionIds.markBlocked,
  };

  static ItemStatus? statusFor(String actionId) => switch (actionId) {
    NotificationActionIds.done || NotificationActionIds.completeItem => ItemStatus.completed,
    NotificationActionIds.markOngoing => ItemStatus.ongoing,
    NotificationActionIds.markWaiting => ItemStatus.waiting,
    NotificationActionIds.markBlocked => ItemStatus.blocked,
    _ => null,
  };

  @override
  Future<NotificationActionResult> handle(NotificationActionContext c) async {
    final id = c.targetId;
    if (id == null) return const NotificationActionResult.failed(null);
    if (c.targetType == NotificationTargetType.checklist) {
      return NotificationActionResult(openLink: c.payload.deepLink ?? AppLinks.checklist(id));
    }
    final to = statusFor(c.actionId);
    if (to == null) return NotificationActionResult(openLink: c.payload.deepLink, markActed: false);
    final item = await c.read(checklistItemsRepositoryProvider).liveById(id);
    if (item == null) {
      return NotificationActionResult.failed(c.read(notificationTextsProvider).l10n.checklistNotifItemGone);
    }
    if (item.status != to) {
      await c
          .read(checklistServiceProvider)
          .changeStatus(item.checklistId, [id], to, setNote: false, cause: 'notification');
    }
    return NotificationActionResult.ok;
  }
}
