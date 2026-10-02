import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/notifications/application/notification_providers.dart';
import 'package:everslot/features/notifications/application/notification_registry.dart';
import 'package:everslot/features/notifications/application/notifications_engine.dart';
import 'package:everslot/features/notifications/domain/inbox_item.dart';
import 'package:everslot/features/notifications/domain/notification_actions.dart';
import 'package:everslot/features/notifications/domain/notification_rule.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot/features/notifications/presentation/mute_menu.dart';
import 'package:everslot/features/notifications/presentation/notification_labels.dart';
import 'package:everslot/features/notifications/presentation/notification_link_opener.dart';
import 'package:everslot/features/notifications/presentation/notifications_settings_page.dart';
import 'package:everslot/features/notifications/presentation/snooze_picker.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Notification center (T7.3.03): rows grouped by day, nag chains collapsed, filters, swipe
/// read/dismiss with undo, snoozed section, inline actions, pull-to-refresh; search, rule / item
/// filters and multi-select (read · dismiss · mute the rules) — T7.3.11.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _searching = false;
  final _search = TextEditingController();
  Timer? _debounce;

  /// Selected chains (base keys) in multi-select mode.
  final Set<String> _selected = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _setQuery(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final filter = ref.read(inboxFilterProvider);
      ref.read(inboxFilterProvider.notifier).set(filter.copyWith(query: text.trim()));
    });
  }

  void _toggle(InboxItem item) => setState(() {
    if (!_selected.remove(item.baseKey)) _selected.add(item.baseKey);
  });

  List<InboxItem> _selectedRows(List<InboxItem> rows) => [
    for (final r in rows)
      if (_selected.contains(r.baseKey)) r,
  ];

  Future<void> _markRead(List<InboxItem> rows) async {
    await ref.read(inboxRepositoryProvider).markRead([for (final r in _selectedRows(rows)) r.id]);
    setState(_selected.clear);
  }

  Future<void> _dismiss(List<InboxItem> rows) async {
    final ids = [for (final r in _selectedRows(rows)) r.id];
    final record = await ref.read(inboxRepositoryProvider).dismissMany(ids);
    if (!mounted) return;
    setState(_selected.clear);
    showUndoSnackBar(context, ref, message: context.l10n.notifInboxDismissedMany(ids.length), record: record);
  }

  Future<void> _muteRules(List<InboxItem> rows, MuteFor choice) async {
    final rules = {
      for (final r in _selectedRows(rows))
        if (r.ruleId != null) r.ruleId!,
    };
    final mutes = ref.read(notificationMutesRepositoryProvider);
    final until = MuteMenuButton.untilFor(ref, choice);
    for (final id in rules) {
      await mutes.mute(targetType: 'rule', targetId: id, until: until, reason: 'user');
    }
    if (!mounted) return;
    setState(_selected.clear);
    showInfoSnackBar(context, context.l10n.notifInboxRulesMuted(rules.length));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final filter = ref.watch(inboxFilterProvider);
    final items = ref.watch(inboxItemsProvider);
    final snoozed = ref.watch(snoozedInboxProvider).value ?? const <InboxItem>[];
    final rows = items.value ?? const <InboxItem>[];
    final selecting = _selected.isNotEmpty;
    final selectedHasRules = _selectedRows(rows).any((r) => r.ruleId != null);
    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && selecting) setState(_selected.clear);
      },
      child: Scaffold(
        appBar: selecting
            ? AppBar(
                leading: IconButton(
                  tooltip: l.actionCancel,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_selected.clear),
                ),
                title: Text(l.notifInboxSelected(_selected.length)),
                actions: [
                  IconButton(
                    key: const ValueKey('inbox-bulk-read'),
                    tooltip: l.notifInboxMarkRead,
                    icon: const Icon(Icons.mark_email_read_outlined),
                    onPressed: () => unawaited(_markRead(rows)),
                  ),
                  IconButton(
                    key: const ValueKey('inbox-bulk-dismiss'),
                    tooltip: l.notifInboxDismiss,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => unawaited(_dismiss(rows)),
                  ),
                  if (selectedHasRules)
                    PopupMenuButton<MuteFor>(
                      key: const ValueKey('inbox-bulk-mute'),
                      tooltip: l.notifInboxMuteRules,
                      icon: const Icon(Icons.notifications_paused_outlined),
                      onSelected: (m) => unawaited(_muteRules(rows, m)),
                      itemBuilder: (_) => [
                        for (final m in MuteFor.values) PopupMenuItem(value: m, child: Text(muteForLabel(l, m))),
                      ],
                    ),
                ],
              )
            : AppBar(
                title: Text(l.notifInboxTitle),
                actions: [
                  IconButton(
                    key: const ValueKey('inbox-search-toggle'),
                    tooltip: l.notifInboxSearch,
                    icon: Icon(_searching ? Icons.search_off : Icons.search),
                    onPressed: () => setState(() {
                      _searching = !_searching;
                      if (!_searching) {
                        _search.clear();
                        ref.read(inboxFilterProvider.notifier).set(filter.copyWith(query: ''));
                      }
                    }),
                  ),
                  IconButton(
                    tooltip: l.notifInboxMarkAllRead,
                    icon: const Icon(Icons.done_all),
                    onPressed: () => unawaited(ref.read(inboxRepositoryProvider).markAllRead(section: filter.section)),
                  ),
                  IconButton(
                    tooltip: l.notifSettingsTitle,
                    icon: const Icon(Icons.tune),
                    onPressed: () => unawaited(
                      Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => const NotificationsSettingsPage())),
                    ),
                  ),
                ],
              ),
        body: Column(
          children: [
            if (_searching)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, 0),
                child: TextField(
                  key: const ValueKey('inbox-search'),
                  controller: _search,
                  autofocus: true,
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.notifInboxSearchHint),
                  onChanged: _setQuery,
                ),
              ),
            _Filters(filter: filter),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(syncServiceProvider)?.syncNow();
                  await ref.read(notificationReplanServiceProvider).flush();
                },
                child: AsyncValueView<List<InboxItem>>(
                  value: items,
                  data: (rows) => _InboxList(
                    rows: rows,
                    snoozed: filter == InboxFilter.all ? snoozed : const [],
                    filter: filter,
                    selected: _selected,
                    onToggle: _toggle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters({required this.filter});

  final InboxFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    void set(InboxFilter f) => ref.read(inboxFilterProvider.notifier).set(f);
    final sections = [
      NotificationSection.planner,
      NotificationSection.checklists,
      NotificationSection.habits,
      NotificationSection.quit,
      NotificationSection.system,
    ];
    final rules = ref.watch(notificationRulesProvider).value ?? const <NotificationRule>[];
    final rule = filter.ruleId == null ? null : rules.where((r) => r.id == filter.ruleId).firstOrNull;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.sm),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l.notifInboxFilterAll),
            selected: filter == InboxFilter.all,
            onSelected: (_) => set(InboxFilter.all),
          ),
          const SizedBox(width: Space.sm),
          FilterChip(
            label: Text(l.notifInboxFilterUnread),
            selected: filter.unreadOnly,
            onSelected: (v) => set(filter.copyWith(unreadOnly: v)),
          ),
          if (filter.ruleId != null) ...[
            const SizedBox(width: Space.sm),
            InputChip(
              key: const ValueKey('inbox-rule-chip'),
              label: Text(rule == null ? l.notifInboxDeletedRule : labels.rule(rule)),
              selected: true,
              onDeleted: () => set(filter.copyWith(clearRule: true)),
            ),
          ],
          if (filter.sourceId != null) ...[
            const SizedBox(width: Space.sm),
            InputChip(
              key: const ValueKey('inbox-source-chip'),
              label: Text(l.notifInboxOneItem),
              selected: true,
              onDeleted: () => set(filter.copyWith(clearSource: true)),
            ),
          ],
          const SizedBox(width: Space.sm),
          ActionChip(
            key: const ValueKey('inbox-more-filters'),
            avatar: const Icon(Icons.filter_list),
            label: Text(l.notifInboxNoisiest),
            onPressed: () => unawaited(_showNoisiest(context, ref, filter)),
          ),
          for (final s in sections) ...[
            const SizedBox(width: Space.sm),
            FilterChip(
              label: Text(labels.section(s)),
              selected: filter.section == s,
              onSelected: (v) => set(v ? filter.copyWith(section: s) : filter.copyWith(clearSection: true)),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Rules that fired most this week" + the busiest items (T7.3.11): pick one to filter by it.
Future<void> _showNoisiest(BuildContext context, WidgetRef ref, InboxFilter filter) async {
  final now = ref.read(clockProvider).nowUtc();
  final week = await ref
      .read(inboxRepositoryProvider)
      .inbox(filter: InboxFilter(from: now.subtract(const Duration(days: 7))), limit: 2000);
  final byRule = <String, int>{};
  final bySource = <(String, String), (int, String)>{};
  for (final r in week) {
    if (r.ruleId != null) byRule[r.ruleId!] = (byRule[r.ruleId!] ?? 0) + 1;
    final type = r.sourceType;
    final id = r.sourceId;
    if (type != null && id != null) {
      final current = bySource[(type, id)];
      bySource[(type, id)] = ((current?.$1 ?? 0) + 1, current?.$2 ?? r.title);
    }
  }
  final topRules = byRule.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final topSources = bySource.entries.toList()..sort((a, b) => b.value.$1.compareTo(a.value.$1));
  if (!context.mounted) return;
  final rules = {for (final r in ref.read(notificationRulesProvider).value ?? const <NotificationRule>[]) r.id: r};
  final picked = await showAppSheet<InboxFilter>(
    context,
    title: context.l10n.notifInboxNoisiest,
    builder: (sheet) {
      final l = sheet.l10n;
      final labels = NotificationLabels.of(sheet);
      return ListView(
        shrinkWrap: true,
        children: [
          if (topRules.isEmpty && topSources.isEmpty)
            Padding(padding: const EdgeInsetsDirectional.all(Space.lg), child: Text(l.notifInboxNoneThisWeek)),
          if (topRules.isNotEmpty) SectionHeader(l.notifInboxTopRules),
          for (final e in topRules.take(10))
            ListTile(
              key: ValueKey('noisy-rule-${e.key}'),
              title: Text(rules[e.key] == null ? l.notifInboxDeletedRule : labels.rule(rules[e.key]!)),
              trailing: Text(l.notifInboxTimes(e.value)),
              onTap: () => Navigator.pop(sheet, filter.copyWith(ruleId: e.key, clearSource: true)),
            ),
          if (topSources.isNotEmpty) SectionHeader(l.notifInboxTopItems),
          for (final e in topSources.take(10))
            ListTile(
              key: ValueKey('noisy-source-${e.key.$2}'),
              title: Text(e.value.$2),
              trailing: Text(l.notifInboxTimes(e.value.$1)),
              onTap: () => Navigator.pop(sheet, filter.copyWith(source: e.key, clearRule: true)),
            ),
        ],
      );
    },
  );
  if (picked != null) ref.read(inboxFilterProvider.notifier).set(picked);
}

/// A displayed row: the newest row of a nag chain plus the chain size.
class _Row {
  _Row(this.item, this.count);

  final InboxItem item;
  final int count;
}

class _InboxList extends ConsumerWidget {
  const _InboxList({
    required this.rows,
    required this.snoozed,
    required this.filter,
    this.selected = const {},
    this.onToggle,
  });

  final List<InboxItem> rows;
  final List<InboxItem> snoozed;
  final InboxFilter filter;
  final Set<String> selected;
  final ValueChanged<InboxItem>? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider).nowUtc();
    final zone = ref.watch(deviceZoneProvider);
    final zones = ref.watch(zoneResolverProvider);
    final format = AppFormat(context.localeName, use24h: MediaQuery.alwaysUse24HourFormatOf(context), l10n: l);
    final visible = [
      for (final r in rows)
        if (!r.isSnoozedAt(now)) r,
    ];
    // Collapse nag chains into their newest row.
    final chains = <String, _Row>{};
    final order = <String>[];
    for (final r in visible) {
      final key = r.baseKey;
      final existing = chains[key];
      if (existing == null) {
        chains[key] = _Row(r, 1);
        order.add(key);
      } else {
        chains[key] = _Row(existing.item, existing.count + 1);
      }
    }
    final grouped = <LocalDate, List<_Row>>{};
    for (final key in order) {
      final row = chains[key]!;
      final day = zones.toLocal(row.item.fireAt, zone).date;
      (grouped[day] ??= []).add(row);
    }
    if (grouped.isEmpty && snoozed.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: Space.xxxl),
          EmptyState(
            icon: filter.unreadOnly ? Icons.done_all : Icons.notifications_none,
            title: filter.unreadOnly || rows.isNotEmpty ? l.notifInboxCaughtUp : l.notifInboxEmpty,
            message: filter.unreadOnly || rows.isNotEmpty ? null : l.notifInboxEmptyBody,
          ),
        ],
      );
    }
    final today = zones.toLocal(now, zone).date;
    String dayLabel(LocalDate d) =>
        d == today ? l.notifInboxToday : (d == today.minusDays(1) ? l.notifInboxYesterday : format.dayLong(d));
    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: Space.xxl),
      children: [
        if (snoozed.isNotEmpty) ...[
          SectionHeader(l.notifInboxSnoozed),
          for (final s in snoozed) _SnoozedTile(item: s, format: format, now: now),
        ],
        for (final e in grouped.entries) ...[
          SectionHeader(dayLabel(e.key)),
          for (final r in e.value)
            InboxTile(
              item: r.item,
              chainCount: r.count,
              format: format,
              now: now,
              selectionMode: selected.isNotEmpty,
              selected: selected.contains(r.item.baseKey),
              onSelect: onToggle == null ? null : () => onToggle!(r.item),
            ),
        ],
      ],
    );
  }
}

/// One inbox row (also used by the per-item history).
class InboxTile extends ConsumerWidget {
  const InboxTile({
    required this.item,
    required this.format,
    required this.now,
    this.chainCount = 1,
    this.dense = false,
    this.selectionMode = false,
    this.selected = false,
    this.onSelect,
    super.key,
  });

  final InboxItem item;
  final int chainCount;
  final AppFormat format;
  final DateTime now;
  final bool dense;

  /// Multi-select (T7.3.11): a long press starts it, then a tap toggles the row.
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelect;

  static IconData iconFor(NotificationSection? s, InboxCategory c) => switch (c) {
    InboxCategory.digest => Icons.summarize_outlined,
    InboxCategory.milestone => Icons.emoji_events_outlined,
    InboxCategory.streak => Icons.local_fire_department_outlined,
    InboxCategory.system => Icons.info_outline,
    _ => switch (s) {
      NotificationSection.planner => Icons.calendar_view_week_outlined,
      NotificationSection.checklists => Icons.checklist,
      NotificationSection.habits => Icons.repeat,
      NotificationSection.quit => Icons.smoke_free,
      _ => Icons.notifications_none,
    },
  };

  NotificationPayload get payload => NotificationPayload.fromJson({
    ...item.payload,
    'dk': item.dedupeKey,
    'rid': item.payload['rid'] ?? item.ruleId,
    'tt': item.payload['tt'] ?? item.sourceType,
    'tid': item.payload['tid'] ?? item.sourceId,
    'occ': item.payload['occ'] ?? item.occurrenceKey,
    'sec': item.payload['sec'] ?? item.section?.wire,
  });

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(notificationActionDispatcherProvider).handleTap(payload, origin: ActionOrigin.inbox);
    if (!context.mounted) return;
    if (result.alreadyDone) {
      showInfoSnackBar(context, context.l10n.notifInboxAlreadyDone);
    }
    final link = result.openLink;
    if (link != null) openNotificationLink(Navigator.of(context), link);
  }

  Future<void> _act(BuildContext context, WidgetRef ref, String action) async {
    final dispatcher = ref.read(notificationActionDispatcherProvider);
    if (action == NotificationActionIds.snooze) {
      final minutes = await pickSnooze(context, ref, options: item.snoozeOptions);
      if (minutes == null) return;
      final result = await dispatcher.snooze(payload, minutes: minutes);
      if (!context.mounted) return;
      if (result.message != null) showInfoSnackBar(context, result.message!);
      return;
    }
    final result = await dispatcher.handleAction(action, payload, origin: ActionOrigin.inbox);
    if (!context.mounted) return;
    if (result.message != null) showInfoSnackBar(context, result.message!);
    if (result.openLink != null) {
      openNotificationLink(Navigator.of(context), result.openLink!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final labels = NotificationLabels.of(context);
    final unread = item.isUnreadAt(now);
    final actions = [
      for (final a in item.actions)
        if (a != NotificationActionIds.open && item.actedAt == null) a,
    ].take(2).toList();
    // *Remind me again…* on past rows that aren't snoozed and offer no snooze chip (T7.3.08).
    final snoozedNow = item.snoozedUntil != null && item.snoozedUntil!.isAfter(now);
    final remindAgain =
        !dense &&
        item.category != InboxCategory.system &&
        !snoozedNow &&
        !item.fireAt.isAfter(now) &&
        !actions.contains(NotificationActionIds.snooze);
    // One sentence for screen readers: "Unread reminder, Gym, Starts in 10 min, 5 minutes ago".
    final semanticLabel = [
      if (unread) l.notifInboxUnreadSemantics(item.title) else item.title,
      if (item.body != null && item.body!.isNotEmpty) item.body!,
      format.relative(item.fireAt, now),
      if (chainCount > 1) l.notifInboxNagCount(chainCount),
      if (item.late) l.notifInboxLate,
      if (item.action != null) labels.action(item.action!),
    ].join(', ');
    final tile = InkWell(
      onTap: selectionMode ? onSelect : () => unawaited(_open(context, ref)),
      onLongPress: onSelect,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          Space.lg,
          dense ? Space.sm : Space.md,
          Space.lg,
          dense ? Space.sm : Space.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectionMode)
              Checkbox(value: selected, onChanged: (_) => onSelect?.call(), semanticLabel: item.title)
            else
              CircleAvatar(
                radius: 18,
                backgroundColor: context.colors.secondaryContainer,
                child: Icon(iconFor(item.section, item.category), size: 18, color: context.colors.onSecondaryContainer),
              ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    button: true,
                    label: semanticLabel,
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (chainCount > 1) ...[
                              const SizedBox(width: Space.xs),
                              StatusPill(
                                label: l.notifInboxNagCount(chainCount),
                                color: context.colors.tertiary,
                                dense: true,
                              ),
                            ],
                            if (item.late) ...[
                              const SizedBox(width: Space.xs),
                              StatusPill(label: l.notifInboxLate, color: context.appColors.warning, dense: true),
                            ],
                          ],
                        ),
                        if (item.body != null && item.body!.isNotEmpty) ...[
                          const SizedBox(height: Space.xxs),
                          Text(
                            item.body!,
                            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ],
                        const SizedBox(height: Space.xxs),
                        Text(
                          [
                            format.relative(item.fireAt, now),
                            labels.category(item.category),
                            if (item.action != null) labels.action(item.action!),
                          ].join(' · '),
                          style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty || remindAgain) ...[
                    const SizedBox(height: Space.xs),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.xs,
                      children: [
                        for (final a in actions)
                          ActionChip(label: Text(labels.action(a)), onPressed: () => unawaited(_act(context, ref, a))),
                        // T7.3.08: a snooze instance even for rows never snoozed.
                        if (remindAgain)
                          ActionChip(
                            avatar: const Icon(Icons.alarm_add_outlined),
                            label: Text(l.notifInboxRemindAgain),
                            onPressed: () => unawaited(_act(context, ref, NotificationActionIds.snooze)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (unread)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: Space.sm, top: Space.xs),
                child: ColorDot(context.colors.primary),
              ),
          ],
        ),
      ),
    );
    if (dense || selectionMode) return tile;
    return Dismissible(
      key: ValueKey('inbox-${item.id}'),
      background: _SwipeBackground(
        icon: unread ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
        alignment: AlignmentDirectional.centerStart,
        color: context.colors.primaryContainer,
      ),
      secondaryBackground: _SwipeBackground(
        icon: Icons.delete_outline,
        alignment: AlignmentDirectional.centerEnd,
        color: context.colors.errorContainer,
      ),
      confirmDismiss: (direction) async {
        final repo = ref.read(inboxRepositoryProvider);
        if (direction == DismissDirection.startToEnd) {
          if (unread) {
            await repo.markRead([item.id]);
            if (context.mounted) {
              showInfoSnackBar(context, l.notifInboxMarkedRead);
            }
          } else {
            await repo.markUnread(item.id);
            if (context.mounted) {
              showInfoSnackBar(context, l.notifInboxMarkedUnread);
            }
          }
          return false;
        }
        final record = await repo.dismiss(item.id);
        if (context.mounted) {
          showUndoSnackBar(context, ref, message: l.notifInboxDismissed, record: record);
        }
        return true;
      },
      child: tile,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({required this.icon, required this.alignment, required this.color});

  final IconData icon;
  final AlignmentGeometry alignment;
  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        child: Icon(icon),
      ),
    ),
  );
}

class _SnoozedTile extends ConsumerWidget {
  const _SnoozedTile({required this.item, required this.format, required this.now});

  final InboxItem item;
  final AppFormat format;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final zone = ref.watch(deviceZoneProvider);
    final zones = ref.watch(zoneResolverProvider);
    final until = zones.toLocal(item.snoozedUntil!, zone);
    return ListTile(
      leading: const Icon(Icons.snooze),
      title: Text(item.title),
      subtitle: Text('${l.notifInboxSnoozedUntil(format.timeOf(until))} · ${format.relative(item.snoozedUntil!, now)}'),
      trailing: Wrap(
        spacing: Space.xs,
        children: [
          IconButton(
            tooltip: l.notifInboxChangeSnooze,
            icon: const Icon(Icons.edit_calendar_outlined),
            onPressed: () async {
              final minutes = await pickSnooze(context, ref, options: item.snoozeOptions);
              if (minutes == null) return;
              final dispatcher = ref.read(notificationActionDispatcherProvider);
              await dispatcher.wakeNow(item.dedupeKey);
              await dispatcher.snooze(
                NotificationPayload.fromJson({...item.payload, 'dk': item.dedupeKey}),
                minutes: minutes,
              );
            },
          ),
          TextButton(
            onPressed: () => unawaited(ref.read(notificationActionDispatcherProvider).wakeNow(item.dedupeKey)),
            child: Text(l.notifInboxWakeNow),
          ),
        ],
      ),
    );
  }
}
