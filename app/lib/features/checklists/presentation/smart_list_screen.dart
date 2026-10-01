import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/board.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/collation.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/item_time.dart';
import 'package:everslot/features/checklists/presentation/checklist_navigation.dart';
import 'package:everslot/features/checklists/presentation/status_sheet.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _SmartSort { age, followUp, list }

/// Cross-list smart views (T4.5.01): a GTD-style "waiting for" register across every
/// non-archived checklist, plus Blocked, Ongoing and due Follow-ups. Rows show the checklist and
/// breadcrumb, the reason note, the age in status and the follow-up (highlighted when overdue).
class SmartListScreen extends ConsumerStatefulWidget {
  const SmartListScreen({required this.kind, super.key});

  /// `waiting | blocked | ongoing | follow_ups` (route parameter).
  final String kind;

  @override
  ConsumerState<SmartListScreen> createState() => _SmartListScreenState();
}

class _SmartListScreenState extends ConsumerState<SmartListScreen> {
  late _SmartSort _sort = SmartKind.parse(widget.kind) == SmartKind.followUps ? _SmartSort.followUp : _SmartSort.age;
  bool _group = false;

  static String label(BuildContext context, SmartKind k) {
    final l = context.l10n;
    return switch (k) {
      SmartKind.waiting => l.smartWaiting,
      SmartKind.blocked => l.smartBlocked,
      SmartKind.ongoing => l.smartOngoing,
      SmartKind.followUps => l.smartFollowUps,
    };
  }

  static int _nullsLast<T extends Comparable<T>>(T? a, T? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  List<SmartItem> _sorted(List<SmartItem> all) {
    final list = [...all];
    int byList(SmartItem a, SmartItem b) {
      final c = Collation.compare(a.checklistTitle, b.checklistTitle);
      if (c != 0) return c;
      final p = Collation.compare(a.path.join(' '), b.path.join(' '));
      return p != 0 ? p : a.item.sortKey.compareTo(b.item.sortKey);
    }

    switch (_sort) {
      case _SmartSort.age:
        list.sort((a, b) {
          final c = _nullsLast(a.item.statusSince, b.item.statusSince);
          return c != 0 ? c : byList(a, b);
        });
      case _SmartSort.followUp:
        list.sort((a, b) {
          final c = _nullsLast(a.item.followUpAt, b.item.followUpAt);
          return c != 0 ? c : byList(a, b);
        });
      case _SmartSort.list:
        list.sort(byList);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final kind = SmartKind.parse(widget.kind);
    if (kind == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.help_outline, title: l.smartUnknown),
      );
    }
    final items = ref.watch(smartItemsProvider(kind));
    final now = ref.read(clockProvider).nowUtc();
    String sortLabel(_SmartSort s) => switch (s) {
      _SmartSort.age => l.smartSortAge,
      _SmartSort.followUp => l.smartSortFollowUp,
      _SmartSort.list => l.smartSortList,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(label(context, kind)),
        actions: [
          PopupMenuButton<_SmartSort>(
            tooltip: sortLabel(_sort),
            icon: const Icon(Icons.sort),
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              for (final s in _SmartSort.values)
                CheckedPopupMenuItem(value: s, checked: s == _sort, child: Text(sortLabel(s))),
            ],
          ),
          IconButton(
            tooltip: l.smartGroupByList,
            isSelected: _group,
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder),
            onPressed: () => setState(() => _group = !_group),
          ),
        ],
      ),
      body: AsyncValueView<List<SmartItem>>(
        value: items,
        data: (all) {
          if (all.isEmpty) return EmptyState(icon: Icons.task_alt, title: l.smartEmpty);
          final sorted = _sorted(all);
          Widget row(SmartItem s) => _SmartRow(key: ValueKey(s.item.id), entry: s, now: now, showList: !_group);
          if (!_group) {
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: Space.xxl),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => row(sorted[i]),
            );
          }
          final groups = <String, List<SmartItem>>{};
          for (final s in sorted) {
            (groups[s.item.checklistId] ??= []).add(s);
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: Space.xxl),
            children: [
              for (final e in groups.entries) ...[
                SectionHeader(e.value.first.checklistTitle.isEmpty ? l.listsUntitled : e.value.first.checklistTitle),
                for (final s in e.value) row(s),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SmartRow extends ConsumerWidget {
  const _SmartRow({required this.entry, required this.now, required this.showList, super.key});

  final SmartItem entry;
  final DateTime now;
  final bool showList;

  ChecklistItem get item => entry.item;

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final checklist = await ref.read(checklistsRepositoryProvider).byId(item.checklistId);
    if (!context.mounted) return;
    final settings = checklist?.settings ?? ChecklistSettings.defaults;
    final choice = await showStatusSheet(context, ref, item: item, settings: settings);
    if (choice == null || !context.mounted) return;
    final service = ref.read(checklistServiceProvider);
    bool? cascade;
    if (choice.status == ItemStatus.completed && settings.completeChildrenWithParent == CascadeChoice.ask) {
      final open = await service.openDescendantCount(item.checklistId, item.id);
      if (open > 0 && context.mounted) {
        cascade = await askCompleteDescendants(context, open);
        if (cascade == null) return;
      }
    }
    final record = await service.changeStatus(
      item.checklistId,
      [item.id],
      choice.status,
      note: choice.note,
      setNote: choice.setNote,
      followUpAt: choice.followUpAt,
      keepFollowUp: choice.keepFollowUp,
      completeOpenDescendants: cascade,
    );
    if (record == null || !context.mounted) return;
    final message = l.statusMarked(StatusStyle.label(context, choice.status));
    announce(context, message);
    showUndoSnackBar(context, ref, message: message, record: record);
  }

  Future<void> _setFollowUp(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(userPreferencesProvider);
    final zone = ref.read(deviceZoneProvider);
    final resolver = ref.read(zoneResolverProvider);
    final current = item.followUpAt == null ? null : resolver.toLocal(item.followUpAt!, zone);
    final date = await pickDate(context, initial: current?.date);
    if (date == null || !context.mounted) return;
    final time = await pickTime(context, initial: current?.time ?? LocalTime(9, 0), use24h: prefs.use24h);
    if (!context.mounted) return;
    final at = resolver.resolve(date.atTime(time ?? LocalTime(9, 0)), zone).utc;
    await _writeFollowUp(context, ref, at);
  }

  Future<void> _writeFollowUp(BuildContext context, WidgetRef ref, DateTime? at) async {
    final record = await ref.read(checklistServiceProvider).setFields(item.checklistId, item.id, {'follow_up_at': at});
    if (record != null && context.mounted) {
      showUndoSnackBar(context, ref, message: context.l10n.savedSnack, record: record);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final overdue = ItemTimeRules.followUpOverdue(item.followUpAt, now);
    final zone = ref.watch(deviceZoneProvider);
    final fmt = AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h, l10n: l);
    final crumbs = [if (showList) entry.checklistTitle.isEmpty ? l.listsUntitled : entry.checklistTitle, ...entry.path];
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    return InkWell(
      onTap: () => openChecklist(context, item.checklistId, itemId: item.id),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.xs, Space.xs, Space.xs, Space.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusControl(
              status: item.status,
              onTap: () => unawaited(_changeStatus(context, ref)),
              onLongPress: () => unawaited(_changeStatus(context, ref)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: Space.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.text.isEmpty ? l.checklistItemHint : item.text, style: context.text.bodyLarge),
                    if (crumbs.isNotEmpty)
                      Row(
                        children: [
                          if (showList && entry.checklistColor != null) ...[
                            ColorDot(Color(entry.checklistColor!), size: 8),
                            const SizedBox(width: Space.xs),
                          ],
                          Expanded(
                            child: Text(crumbs.join(' › '), maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
                          ),
                        ],
                      ),
                    if (item.statusNote != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.xxs),
                        child: Text(item.statusNote!, style: muted?.copyWith(fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(height: Space.xs),
                    Wrap(
                      spacing: Space.xs,
                      runSpacing: Space.xs,
                      children: [
                        ItemStatusPill(status: item.status, since: item.statusSince, now: now),
                        if (item.followUpAt != null)
                          StatusPill(
                            label: overdue
                                ? l.statusFollowUpOverdue
                                : l.statusFollowUpChip(
                                    fmt.dateTime(ref.read(zoneResolverProvider).toLocal(item.followUpAt!, zone)),
                                  ),
                            color: overdue ? context.appColors.danger : context.appColors.info,
                            icon: Icons.notifications_active_outlined,
                            dense: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l.actionMore,
              onSelected: (v) {
                switch (v) {
                  case 'open':
                    unawaited(openChecklist(context, item.checklistId, itemId: item.id));
                  case 'status':
                    unawaited(_changeStatus(context, ref));
                  case 'followUp':
                    unawaited(_setFollowUp(context, ref));
                  case 'clearFollowUp':
                    unawaited(_writeFollowUp(context, ref, null));
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'open', child: Text(l.smartOpenInList)),
                PopupMenuItem(value: 'status', child: Text(l.statusChange)),
                PopupMenuItem(value: 'followUp', child: Text(l.smartSetFollowUp)),
                if (item.followUpAt != null) PopupMenuItem(value: 'clearFollowUp', child: Text(l.smartClearFollowUp)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
