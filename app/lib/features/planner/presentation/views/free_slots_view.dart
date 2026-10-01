import 'dart:async';
import 'dart:math' as math;

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/planner_view_data.dart';
import 'package:everslot/features/planner/presentation/grid/data/work_settings.dart';
import 'package:everslot/features/planner/presentation/grid/engine/free_slots.dart';
import 'package:everslot/features/planner/presentation/grid/grid_commands.dart';
import 'package:everslot/features/planner/presentation/grid/grid_style.dart';
import 'package:everslot/features/planner/presentation/view_config/view_settings_sheet.dart';
import 'package:everslot/features/planner/presentation/views/item_chip.dart';
import 'package:everslot/features/planner/presentation/views/planner_chrome.dart';
import 'package:everslot/features/planner/presentation/views/view_registry.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Day ranges offered by the openings view (`options.days`).
const freeSlotDayChoices = [1, 3, 7, 14];

/// Minimum gaps offered (`options.minGap`, minutes).
const freeSlotGapChoices = [15, 30, 60, 90];

/// Shares availability text (fakeable in tests).
typedef AvailabilitySharer = Future<void> Function(String text);

final availabilitySharerProvider = Provider<AvailabilitySharer>(
  (ref) => (text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  },
);

/// Free-slot finder & openings (T3.7.04): free intervals inside work hours on work days over the
/// next N days (`options.days`), filtered by minimum gap (`options.minGap`), optionally ignoring
/// low-priority items (`options.ignoreLowPriority`). Each opening offers *Fill this gap* (a backlog
/// item that fits) and *Create here*; *Share availability* copies the localized text.
class FreeSlotsView extends ConsumerWidget {
  const FreeSlotsView({required this.args, super.key});

  final PlannerViewArgs args;

  String get _key => args.viewKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final config = ref.watch(plannerViewConfigProvider(_key));
    final prefs = ref.watch(userPreferencesProvider);
    final work = ref.watch(plannerWorkSettingsProvider);
    final now = ref.watch(plannerNowProvider);
    final today = now.date;
    final days = config.option<int>('days', 7).clamp(1, 31);
    final minGap = config.option<int>('minGap', 30).clamp(1, 1440);
    final ignoreLow = config.option<bool>('ignoreLowPriority', false);
    final f = context.plannerFormat(use24h: prefs.use24h);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final zone = ref.watch(plannerZoneProvider);
    final zones = ref.watch(zoneResolverProvider);
    final items = filteredItems(ref, DayRange(today, days), config);
    final notifier = ref.read(plannerViewConfigProvider(_key).notifier);
    final openings = items.whenData(
      (list) => freeIntervals(
        items: list,
        days: [for (var i = 0; i < days; i++) today.plusDays(i)],
        options: FreeSlotOptions(
          window: work.hours,
          workDays: work.days,
          minGapMinutes: minGap,
          ignoreBelowPriority: ignoreLow ? 2 : null,
        ),
        elapsed: (a, b) => elapsedMinutes(zones, zone, a, b),
        notBefore: now,
      ),
    );
    final dayFormat = DateFormat('EEE d MMM', locale);
    String text(List<FreeInterval> list) =>
        availabilityText(list, formatDay: (d) => dayFormat.format(d.toDateTimeUtc()), formatTime: f.timeOf);

    return PlannerViewScaffold(
      viewKey: _key,
      toolbar: SizedBox(
        height: 48,
        child: Row(
          children: [
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                '${l.pvOpenings} · ${l.pvNextDays(days)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            PopupMenuButton<int>(
              key: const Key('free-days'),
              tooltip: l.pvNextDays(days),
              icon: const Icon(Icons.date_range),
              onSelected: (d) => notifier.change((c) => c.withOption('days', d)),
              itemBuilder: (_) => [
                for (final d in freeSlotDayChoices)
                  CheckedPopupMenuItem(value: d, checked: d == days, child: Text(l.pvNextDays(d))),
              ],
            ),
            PopupMenuButton<int>(
              key: const Key('free-min-gap'),
              tooltip: l.pvMinGap,
              icon: const Icon(Icons.timelapse),
              onSelected: (g) => notifier.change((c) => c.withOption('minGap', g)),
              itemBuilder: (_) => [
                for (final g in freeSlotGapChoices)
                  CheckedPopupMenuItem(value: g, checked: g == minGap, child: Text('${l.pvMinGap}: ${f.duration(g)}')),
              ],
            ),
            IconButton(
              key: const Key('free-share'),
              tooltip: l.pvShareAvailability,
              icon: const Icon(Icons.ios_share),
              onPressed: openings.value == null
                  ? null
                  : () => unawaited(ref.read(availabilitySharerProvider)(text(openings.value!))),
            ),
            PlannerMoreMenu(
              viewKey: _key,
              kind: ViewSettingsKind.list,
              extra: [
                (
                  'ignoreLow',
                  '${ignoreLow ? '✓ ' : ''}${l.pvIgnoreLowPriority}',
                  () => notifier.change((c) => c.withOption('ignoreLowPriority', !ignoreLow)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: AsyncValueView<List<FreeInterval>>(
        value: openings,
        data: (list) {
          if (list.isEmpty) return EmptyState(icon: Icons.event_busy, title: l.pvNoOpenings);
          final byDay = <LocalDate, List<FreeInterval>>{};
          for (final o in list) {
            byDay.putIfAbsent(o.day, () => []).add(o);
          }
          return ListView(
            key: const Key('free-list'),
            padding: const EdgeInsetsDirectional.fromSTEB(Space.md, Space.sm, Space.md, 96),
            children: [
              Text(
                '${l.pvWorkHours}: ${f.time(LocalTime.fromMinuteOfDay(work.hours.startMinute))}–'
                '${f.time(LocalTime.fromMinuteOfDay(work.hours.endMinute.clamp(0, 1439)))}',
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              for (final e in byDay.entries) ...[
                SectionHeader(
                  f.dayLong(e.key),
                  padding: const EdgeInsetsDirectional.only(top: Space.md, bottom: Space.xs),
                ),
                for (final o in e.value)
                  _OpeningTile(key: ValueKey('opening-${o.start.toIso()}'), opening: o, format: f, work: work),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OpeningTile extends ConsumerWidget {
  const _OpeningTile({required this.opening, required this.format, required this.work, super.key});

  final FreeInterval opening;
  final AppFormat format;
  final WorkSettings work;

  Future<void> _fill(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final backlog = ref.read(viewBacklogProvider).value ?? const <PlannerItem>[];
    final fitting = [
      for (final b in backlog)
        if ((b.estimateMinutes ?? b.durationMinutes) <= opening.minutes) b,
    ];
    final picked = await showAppSheet<PlannerItem>(
      context,
      title: l.pvFillGap,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          if (fitting.isEmpty) Padding(padding: const EdgeInsets.all(Space.lg), child: Text(l.pvBacklogEmpty)),
          for (final b in fitting)
            ListTile(
              key: ValueKey('fill-${b.taskId}'),
              leading: const Icon(Icons.inbox_outlined),
              title: Text(b.title),
              subtitle: Text(format.duration(b.estimateMinutes ?? b.durationMinutes)),
              onTap: () => Navigator.pop(ctx, b),
            ),
          const SizedBox(height: Space.md),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    final duration = math.min(opening.minutes, picked.estimateMinutes ?? picked.durationMinutes);
    await PlannerCommands(
      context,
      ref,
    ).run(l.pvScheduledSnack, (a) => a.scheduleBacklogItem(picked, opening.start, duration));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    ref.watch(viewBacklogProvider); // kept warm for *Fill this gap*
    final label = '${format.timeRange(opening.start, opening.end)} · ${format.duration(opening.minutes)}';
    return Card(
      margin: const EdgeInsets.only(bottom: Space.xs),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.md, Space.xs, Space.xs, Space.xs),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: l.pvFreeGap(label),
                child: ExcludeSemantics(child: Text(label, style: context.text.bodyLarge)),
              ),
            ),
            TextButton(
              key: ValueKey('fill-gap-${opening.start.toIso()}'),
              onPressed: () => unawaited(_fill(context, ref)),
              child: Text(l.pvFillGap),
            ),
            IconButton(
              key: ValueKey('create-here-${opening.start.toIso()}'),
              tooltip: l.pvCreateHere,
              icon: const Icon(Icons.add),
              onPressed: () => unawaited(
                PlannerCommands(
                  context,
                  ref,
                ).quickCreate(start: opening.start, duration: math.min(opening.minutes, work.defaultDuration)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
