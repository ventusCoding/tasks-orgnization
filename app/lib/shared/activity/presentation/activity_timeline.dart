import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/shared/activity/application/activity_providers.dart';
import 'package:everslot/shared/status/presentation/entity_status_style.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The localized rendering of one activity event.
@immutable
class ActivityLine {
  const ActivityLine({required this.icon, required this.text, this.detail});

  final IconData icon;

  /// Main sentence ("Status changed from Waiting to Blocked").
  final String text;

  /// Secondary line (reason note, scope, file name…).
  final String? detail;
}

/// Turns activity events into localized sentences (T2.3.05).
abstract final class ActivitySentences {
  /// Changed-field names → localized labels (unknown fields are left out).
  static String? fieldLabel(BuildContext context, String field) {
    final l = context.l10n;
    return switch (field) {
      'title' => l.activityFieldTitle,
      'notes' || 'note' || 'body' || 'description' => l.activityFieldNotes,
      'category_id' || 'category' => l.activityFieldCategory,
      'priority' => l.activityFieldPriority,
      'tags' => l.activityFieldTags,
      'start_local' || 'is_all_day' || 'time_zone' => l.activityFieldTime,
      'duration_minutes' => l.activityFieldDuration,
      'recurrence' || 'schedule' || 'reset_rule' => l.activityFieldRepeat,
      'color' => l.activityFieldColor,
      'name' => l.activityFieldName,
      'due_local' => l.activityFieldDue,
      'text' => l.activityFieldText,
      'icon' => l.activityFieldIcon,
      _ => null,
    };
  }

  /// Display order of changed fields (most telling first).
  static const _fieldOrder = [
    'title',
    'name',
    'text',
    'start_local',
    'is_all_day',
    'time_zone',
    'duration_minutes',
    'recurrence',
    'schedule',
    'reset_rule',
    'due_local',
    'category_id',
    'category',
    'priority',
    'tags',
    'color',
    'icon',
    'notes',
    'note',
    'body',
    'description',
  ];

  static int _rank(String field) {
    final i = _fieldOrder.indexOf(field);
    return i < 0 ? _fieldOrder.length : i;
  }

  /// Label of a non-user cause, or null.
  static String? causeLabel(BuildContext context, String cause) {
    final l = context.l10n;
    return switch (cause) {
      ActivityCauses.auto ||
      ActivityCauses.autoRollup ||
      ActivityCauses.reset ||
      ActivityCauses.cascade => l.activityCauseAutomatic,
      ActivityCauses.bulk => l.activityCauseBulk,
      ActivityCauses.import => l.activityCauseImport,
      _ => null,
    };
  }

  static ActivityLine describe(
    BuildContext context,
    ActivityEvent e,
    AppFormat format,
  ) {
    final l = context.l10n;
    String status(String? s) =>
        s == null ? '' : EntityStatusStyle.label(context, s);
    String? quoted(String? text) =>
        text == null ? null : l.activityQuoted(text);

    switch (e.eventType) {
      case ActivityEventTypes.created:
        final text = e.string('fromTemplateId') != null
            ? l.activityCreatedFromTemplate
            : (e.string('duplicatedFrom') != null
                  ? l.activityCreatedCopy
                  : l.activityCreated);
        return ActivityLine(icon: Icons.add_circle_outline, text: text);
      case ActivityEventTypes.updated:
        final fields = e.strings('fields');
        if (fields.length == 1 && fields.single == 'tags') {
          return ActivityLine(
            icon: Icons.sell_outlined,
            text: l.activityTagsChanged,
          );
        }
        final ordered = [...fields]
          ..sort((a, b) => _rank(a).compareTo(_rank(b)));
        final labels = <String>[];
        for (final f in ordered) {
          final label = fieldLabel(context, f);
          if (label != null && !labels.contains(label)) labels.add(label);
        }
        return ActivityLine(
          icon: Icons.edit_outlined,
          text: labels.isEmpty
              ? l.activityEdited
              : l.activityChangedFields(labels.join(l.activityListSeparator)),
        );
      case ActivityEventTypes.statusChanged:
        final to = e.string('to');
        final from = e.string('from');
        return ActivityLine(
          icon: EntityStatusStyle.icon(to ?? ''),
          text: from == null
              ? l.activityStatusSet(status(to))
              : l.activityStatusChanged(status(from), status(to)),
          detail: quoted(e.string('note')),
        );
      case ActivityEventTypes.statusNoteChanged:
        return ActivityLine(
          icon: Icons.notes,
          text: l.activityStatusNoteChanged,
          detail: quoted(e.string('note')),
        );
      case ActivityEventTypes.rescheduled:
        return _rescheduled(context, e, format);
      case ActivityEventTypes.scheduled:
        return ActivityLine(
          icon: Icons.event_available,
          text: l.activityScheduled,
        );
      case ActivityEventTypes.unscheduled:
        return ActivityLine(
          icon: Icons.inbox_outlined,
          text: l.activityUnscheduled,
        );
      case ActivityEventTypes.seriesSplit:
        return ActivityLine(
          icon: Icons.call_split,
          text: l.activitySeriesSplit,
        );
      case ActivityEventTypes.started:
        return ActivityLine(icon: Icons.play_arrow, text: l.activityStarted);
      case ActivityEventTypes.stopped:
        return ActivityLine(icon: Icons.stop, text: l.activityStopped);
      case ActivityEventTypes.timeEntryAdded:
        return ActivityLine(
          icon: Icons.timer_outlined,
          text: l.activityTimeLogged,
        );
      case ActivityEventTypes.paused:
        return ActivityLine(
          icon: Icons.pause_circle_outline,
          text: l.activityPaused,
        );
      case ActivityEventTypes.resumed:
        return ActivityLine(
          icon: Icons.play_circle_outline,
          text: l.activityResumed,
        );
      case ActivityEventTypes.rollover:
        return ActivityLine(icon: Icons.redo, text: l.activityRollover);
      case ActivityEventTypes.moved:
        final otherList =
            e.string('toChecklistId') != null &&
            e.string('toChecklistId') != e.string('fromChecklistId');
        return ActivityLine(
          icon: Icons.drive_file_move_outline,
          text: otherList ? l.activityMovedToList : l.activityMoved,
        );
      case ActivityEventTypes.completed:
        return ActivityLine(
          icon: Icons.check_circle_outline,
          text: l.activityCompleted,
        );
      case ActivityEventTypes.reopened:
        return ActivityLine(icon: Icons.replay, text: l.activityReopened);
      case ActivityEventTypes.skipped:
        final reason = e.string('reason');
        return ActivityLine(
          icon: Icons.redo,
          text: reason == null
              ? l.activitySkipped
              : l.activitySkippedReason(reason),
        );
      case ActivityEventTypes.deleted:
        final count = e.integer('count');
        return ActivityLine(
          icon: Icons.delete_outline,
          text: count == null || count == 0
              ? l.activityDeleted
              : l.activityDeletedWithItems(count),
        );
      case ActivityEventTypes.restored:
        return ActivityLine(icon: Icons.restore, text: l.activityRestored);
      case ActivityEventTypes.archived:
        return ActivityLine(
          icon: Icons.archive_outlined,
          text: l.activityArchived,
        );
      case ActivityEventTypes.unarchived:
        return ActivityLine(
          icon: Icons.unarchive_outlined,
          text: l.activityUnarchived,
        );
      case ActivityEventTypes.attachmentAdded:
        return ActivityLine(
          icon: Icons.attach_file,
          text: l.activityAttachmentAdded(
            BidiText.isolate(e.string('fileName') ?? l.activityFile),
          ),
        );
      case ActivityEventTypes.attachmentRemoved:
        return ActivityLine(
          icon: Icons.link_off,
          text: l.activityAttachmentRemoved(
            BidiText.isolate(e.string('fileName') ?? l.activityFile),
          ),
        );
      case ActivityEventTypes.itemsAdded:
        final count = e.integer('count') ?? 1;
        return ActivityLine(
          icon: Icons.playlist_add,
          text: l.activityItemsAdded(count),
        );
      case ActivityEventTypes.sorted:
        return ActivityLine(icon: Icons.sort, text: l.activitySorted);
      case ActivityEventTypes.reset:
        return ActivityLine(icon: Icons.restart_alt, text: l.activityReset);
      case ActivityEventTypes.relapse:
        return ActivityLine(icon: Icons.history, text: l.activityRelapse);
      case ActivityEventTypes.merged:
        return ActivityLine(icon: Icons.merge, text: l.activityMerged);
    }
    return ActivityLine(icon: Icons.history, text: l.activityOther);
  }

  static ActivityLine _rescheduled(
    BuildContext context,
    ActivityEvent e,
    AppFormat format,
  ) {
    final l = context.l10n;
    final from = LocalDateTime.tryParse(e.string('fromStart') ?? '');
    final to = LocalDateTime.tryParse(e.string('toStart') ?? '');
    final fromDuration = e.integer('fromDuration');
    final toDuration = e.integer('toDuration');
    String when(LocalDateTime t, {required bool withDate}) => withDate
        ? '${format.dayShort(t.date)} ${format.timeOf(t)}'
        : format.timeOf(t);
    String text;
    if (from != null && to != null && from != to) {
      final withDate = from.date != to.date;
      text = l.activityRescheduled(
        when(from, withDate: withDate),
        when(to, withDate: withDate),
      );
    } else if (fromDuration != null &&
        toDuration != null &&
        fromDuration != toDuration) {
      text = l.activityDurationChanged(
        format.duration(fromDuration),
        format.duration(toDuration),
      );
    } else {
      text = l.activityMoved;
    }
    final scope = e.string('scope');
    final detail = switch (scope) {
      'series' || 'all' => l.activityScopeSeries,
      'this_and_following' || 'following' => l.activityScopeFollowing,
      _ => null,
    };
    return ActivityLine(icon: Icons.schedule, text: text, detail: detail);
  }
}

/// Reusable history timeline (T2.3.05): the entity's activity events as localized sentences,
/// newest first, with relative or absolute times in the device zone.
class ActivityTimeline extends ConsumerWidget {
  const ActivityTimeline({
    required this.entityType,
    required this.entityId,
    super.key,
    this.includeChildren = false,
    this.limit = 50,
    this.showTitle = true,
  });

  final String entityType;
  final String entityId;

  /// Also shows events of children (occurrences of a task, items of a checklist).
  final bool includeChildren;
  final int limit;
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final events = ref.watch(
      entityActivityProvider((
        entityType: entityType,
        entityId: entityId,
        includeChildren: includeChildren,
      )),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) SectionHeader(l.activityTitle),
        events.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Padding(
            padding: const EdgeInsetsDirectional.all(Space.lg),
            child: Text(ErrorState.messageFor(context, e)),
          ),
          data: (list) => list.isEmpty
              ? Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: Space.lg,
                    vertical: Space.md,
                  ),
                  child: Text(
                    l.activityEmpty,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, e) in list.take(limit).indexed)
                      _ActivityRow(
                        event: e,
                        last: i == list.length - 1 || i == limit - 1,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ActivityRow extends ConsumerWidget {
  const _ActivityRow({required this.event, required this.last});

  final ActivityEvent event;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final format = AppFormat(
      context.localeName,
      use24h: prefs.use24h,
      l10n: context.l10n,
      arabicDigits:
          prefs.useArabicDigits && context.localeName.startsWith('ar'),
    );
    final line = ActivitySentences.describe(context, event, format);
    final when = _when(ref, format);
    final cause = ActivitySentences.causeLabel(context, event.cause);
    final meta = cause == null ? when : '$when · $cause';
    final muted = context.colors.onSurfaceVariant;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, 0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  const SizedBox(height: Space.sm),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: context.colors.surfaceContainerHighest,
                    child: Icon(line.icon, size: 16, color: muted),
                  ),
                  if (!last)
                    Expanded(
                      child: VerticalDivider(
                        width: 28,
                        thickness: 1,
                        color: context.colors.outlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: Space.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.text, style: context.text.bodyMedium),
                      if (line.detail != null)
                        Text(
                          line.detail!,
                          style: context.text.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      Text(
                        meta,
                        style: context.text.labelSmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Relative within a week ("3 hours ago"), otherwise the local date and time.
  String _when(WidgetRef ref, AppFormat format) {
    final now = ref.watch(clockProvider).nowUtc();
    final at = event.occurredAt;
    if (now.difference(at).abs() < const Duration(days: 7)) {
      return format.relative(at, now);
    }
    final local = ref
        .watch(zoneResolverProvider)
        .toLocal(at, ref.watch(deviceZoneProvider));
    return '${format.dateMedium(local.date)} · ${format.timeOf(local)}';
  }
}
