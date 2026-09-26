import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/checklist_editor.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/application/reset_service.dart';
import 'package:everslot/features/checklists/domain/checklist.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/checklists/domain/reset.dart';
import 'package:everslot/features/checklists/presentation/status_visuals.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/organization/presentation/categories_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// List settings (arch §8.6 + T4.1.03 keys), color, category and repeat (T4.1.09, T4.5.06).
/// Every change is one undoable operation.
Future<void> showChecklistSettings(BuildContext context, {required String checklistId}) => showAppSheet<void>(
  context,
  title: context.l10n.checklistSettings,
  builder: (_) => _ChecklistSettingsSheet(checklistId: checklistId),
);

class _ChecklistSettingsSheet extends ConsumerWidget {
  const _ChecklistSettingsSheet({required this.checklistId});

  final String checklistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = ref.watch(checklistProvider(checklistId)).value;
    if (c == null) return const LoadingState();
    final s = c.settings;
    final editor = ref.read(checklistEditorProvider(checklistId).notifier);
    final repo = ref.read(checklistsRepositoryProvider);
    Future<void> set(ChecklistSettings Function(ChecklistSettings) edit) => editor.updateSettings(edit);
    final category = ref.watch(categoryByIdProvider(c.categoryId));
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Space.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: c.color == null ? const Icon(Icons.palette_outlined) : ColorDot(Color(c.color!), size: 20),
            title: Text(l.listsColor),
            onTap: () async {
              final color = await pickColor(context, selected: c.color, allowNone: true);
              if (color == null) return;
              final r = await repo.update(checklistId, color: color == -1 ? null : color, clearColor: color == -1);
              editor.pushUndo('color', r);
            },
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(l.settingsCategory),
            subtitle: Text(category?.name ?? l.categoryNone),
            onTap: () async {
              final picked = await pickCategory(context, ref, selectedId: c.categoryId);
              if (picked == null) return;
              final r = await repo.update(
                checklistId,
                categoryId: picked.isEmpty ? null : picked,
                clearCategory: picked.isEmpty,
              );
              editor.pushUndo('category', r);
            },
          ),
          const Divider(),
          ListTile(
            title: Text(l.settingsProgressMode),
            trailing: DropdownButton<ProgressMode>(
              value: s.progressMode,
              onChanged: (v) => v == null ? null : set((x) => x.copyWith(progressMode: v)),
              items: [
                DropdownMenuItem(value: ProgressMode.leaves, child: Text(l.settingsProgressLeaves)),
                DropdownMenuItem(value: ProgressMode.children, child: Text(l.settingsProgressChildren)),
              ],
            ),
          ),
          SwitchListTile(
            value: s.autoCompleteParent,
            title: Text(l.settingsAutoComplete),
            onChanged: (v) => set((x) => x.copyWith(autoCompleteParent: v)),
          ),
          ListTile(
            title: Text(l.settingsCompleteChildren),
            trailing: DropdownButton<CascadeChoice>(
              value: s.completeChildrenWithParent,
              onChanged: (v) => v == null ? null : set((x) => x.copyWith(completeChildrenWithParent: v)),
              items: [
                DropdownMenuItem(value: CascadeChoice.ask, child: Text(l.settingsCascadeAsk)),
                DropdownMenuItem(value: CascadeChoice.always, child: Text(l.settingsCascadeAlways)),
                DropdownMenuItem(value: CascadeChoice.never, child: Text(l.settingsCascadeNever)),
              ],
            ),
          ),
          ListTile(
            title: Text(l.settingsRequireReason),
            subtitle: Wrap(
              spacing: Space.sm,
              children: [
                for (final st in const [ItemStatus.waiting, ItemStatus.blocked, ItemStatus.cancelled, ItemStatus.completed])
                  FilterChip(
                    label: Text(StatusStyle.label(context, st)),
                    selected: s.requireReasonFor.contains(st),
                    onSelected: (v) => set(
                      (x) => x.copyWith(requireReasonFor: v ? {...x.requireReasonFor, st} : ({...x.requireReasonFor}..remove(st))),
                    ),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            value: s.sortCompletedToBottom,
            title: Text(l.settingsSortCompleted),
            onChanged: (v) => set((x) => x.copyWith(sortCompletedToBottom: v)),
          ),
          SwitchListTile(
            value: s.hideCheckboxes,
            title: Text(l.settingsHideCheckboxes),
            onChanged: (v) => set((x) => x.copyWith(hideCheckboxes: v)),
          ),
          SwitchListTile(
            value: s.showAttachmentsInPreview,
            title: Text(l.settingsShowAttachments),
            onChanged: (v) => set((x) => x.copyWith(showAttachmentsInPreview: v)),
          ),
          SwitchListTile(
            value: s.showNotesInPreview,
            title: Text(l.settingsShowNotes),
            onChanged: (v) => set((x) => x.copyWith(showNotesInPreview: v)),
          ),
          ListTile(
            title: Text(l.settingsDefaultOpen),
            trailing: SegmentedButton<OpenMode>(
              segments: [
                ButtonSegment(value: OpenMode.edit, label: Text(l.checklistModeEdit)),
                ButtonSegment(value: OpenMode.preview, label: Text(l.checklistModePreview)),
              ],
              selected: {s.defaultOpenMode},
              onSelectionChanged: (v) => set((x) => x.copyWith(defaultOpenMode: v.first)),
            ),
          ),
          ListTile(title: Text(l.settingsStaleDays(s.staleAfterDays))),
          Slider(
            value: s.staleAfterDays.toDouble().clamp(3, 60),
            min: 3,
            max: 60,
            divisions: 57,
            label: '${s.staleAfterDays}',
            onChanged: (_) {},
            onChangeEnd: (v) => set((x) => x.copyWith(staleAfterDays: v.round())),
          ),
          const Divider(),
          _RepeatSection(checklist: c),
        ],
      ),
    );
  }
}

class _RepeatSection extends ConsumerWidget {
  const _RepeatSection({required this.checklist});

  final Checklist checklist;

  String _presetLabel(BuildContext context, ResetPreset? p) {
    final l = context.l10n;
    return switch (p) {
      null => l.repeatNone,
      ResetPreset.daily => l.repeatDaily,
      ResetPreset.weekdays => l.repeatWeekdays,
      ResetPreset.weekly => l.repeatWeekly,
      ResetPreset.monthly => l.repeatMonthly,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final service = ref.read(checklistResetServiceProvider);
    final editor = ref.read(checklistEditorProvider(checklist.id).notifier);
    final schedule = ResetSchedule.fromJson(checklist.resetRule);
    final preset = schedule?.preset;
    final mode = checklist.resetMode ?? ResetMode.completedToTodo;
    final prefs = ref.watch(userPreferencesProvider);
    final zone = ref.watch(deviceZoneProvider);
    final fmt = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final runs = ref.watch(checklistRunsProvider(checklist.id)).value ?? const <ChecklistRun>[];

    LocalDateTime anchorFor(LocalTime time) {
      final today = ref.read(zoneResolverProvider).toLocal(ref.read(clockProvider).nowUtc(), zone).date;
      return today.atTime(time);
    }

    Future<void> configure(ResetPreset? p, {LocalTime? time, ResetMode? newMode}) async {
      final t = time ?? schedule?.anchorStart.time ?? LocalTime(5, 0);
      final next = p == null ? null : ResetSchedule.preset(p, anchorStart: anchorFor(t));
      final r = await service.configure(checklist.id, next, mode: newMode ?? mode);
      editor.pushUndo('repeat', r);
    }

    final nextAt = schedule == null ? null : service.nextReset(schedule);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.repeatTitle),
        ListTile(
          leading: const Icon(Icons.repeat),
          title: Text(schedule != null && preset == null ? l.repeatCustom : _presetLabel(context, preset)),
          subtitle: schedule == null
              ? null
              : Text(
                  l.repeatChip(
                    const RecurrenceDescriber().describe(
                      schedule.rule,
                      schedule.anchor,
                      locale: context.localeName.split('-').first,
                      use24h: prefs.use24h,
                      weekStart: prefs.weekStart,
                    ),
                    nextAt == null ? '—' : fmt.relative(nextAt, ref.read(clockProvider).nowUtc()),
                  ),
                ),
          trailing: DropdownButton<ResetPreset?>(
            value: preset,
            onChanged: (p) => configure(p),
            items: [
              DropdownMenuItem<ResetPreset?>(child: Text(l.repeatNone)),
              for (final p in ResetPreset.values) DropdownMenuItem(value: p, child: Text(_presetLabel(context, p))),
            ],
          ),
        ),
        if (schedule != null) ...[
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l.repeatResetTime),
            trailing: Text(fmt.time(schedule.anchorStart.time)),
            onTap: () async {
              final t = await pickTime(context, initial: schedule.anchorStart.time, use24h: prefs.use24h);
              if (t != null) await configure(preset ?? ResetPreset.daily, time: t);
            },
          ),
          RadioGroup<ResetMode>(
            groupValue: mode,
            onChanged: (m) => m == null ? null : configure(preset ?? ResetPreset.daily, newMode: m),
            child: Column(
              children: [
                RadioListTile<ResetMode>(value: ResetMode.completedToTodo, title: Text(l.repeatModeCompleted)),
                RadioListTile<ResetMode>(value: ResetMode.allToTodo, title: Text(l.repeatModeAll)),
              ],
            ),
          ),
        ],
        ListTile(
          leading: const Icon(Icons.restart_alt),
          title: Text(l.checklistResetNow),
          onTap: () async {
            final r = await service.resetNow(checklist.id);
            if (r != null) editor.pushUndo('reset', r);
            if (context.mounted) showInfoSnackBar(context, l.checklistResetDone);
          },
        ),
        SectionHeader(l.repeatRuns),
        if (runs.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
            child: Text(l.repeatNoRuns, style: context.text.bodySmall),
          ),
        for (final run in runs.take(20))
          ListTile(
            dense: true,
            leading: ProgressRing(progress: run.completionRatio, size: 28, stroke: 3),
            title: Text(fmt.dateTime(ref.read(zoneResolverProvider).toLocal(run.endedAt ?? run.startedAt, zone))),
            trailing: Text(l.repeatRunSummary(run.completedItems ?? 0, run.totalItems ?? 0)),
          ),
      ],
    );
  }
}
