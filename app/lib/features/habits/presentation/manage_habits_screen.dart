import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/habit_routes.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Section name for display (default sections follow the app language until renamed).
String sectionName(BuildContext context, HabitSection s) =>
    s.defaultKey != null && s.name.trim().isEmpty ? context.l10n.defaultSectionName(s.defaultKey!) : s.name;

/// Picks a section; returns its id, '' for none, null on cancel.
Future<String?> pickHabitSection(BuildContext context, WidgetRef ref, {String? selectedId}) => showAppSheet<String>(
  context,
  title: context.l10n.habitsFieldSection,
  builder: (ctx) => Consumer(
    builder: (ctx, ref, _) {
      final sections = ref.watch(habitSectionsProvider).value ?? const <HabitSection>[];
      return ListView(
        shrinkWrap: true,
        children: [
          for (final s in sections)
            ListTile(
              leading: Icon(IconCatalog.iconFor(s.icon, fallback: Icons.schedule)),
              title: Text(sectionName(ctx, s)),
              selected: s.id == selectedId,
              onTap: () => Navigator.pop(ctx, s.id),
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(ctx.l10n.habitsSectionNew),
            onTap: () async {
              await showSectionEditor(ctx, ref);
            },
          ),
        ],
      );
    },
  ),
);

/// "Manage habits" (T5.1.15): every habit (active, paused, archived) with drag-to-reorder, move to
/// another section, archive / unarchive and delete (Trash, with undo); sections are managed from the
/// app bar.
class ManageHabitsScreen extends ConsumerWidget {
  const ManageHabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final all = ref.watch(allHabitsProvider);
    final pauses = ref.watch(habitPausesProvider).value ?? const <PauseSpan>[];
    final today = ref.watch(habitTodayProvider);
    final sections = {for (final s in ref.watch(allHabitSectionsProvider).value ?? const <HabitSection>[]) s.id: s};
    return Scaffold(
      appBar: AppBar(
        title: Text(l.habitsManage),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const SectionsScreen())),
            icon: const Icon(Icons.view_agenda_outlined),
            label: Text(l.habitsSections),
          ),
        ],
      ),
      body: AsyncValueView<List<Habit>>(
        value: all,
        data: (habits) {
          final active = [for (final h in habits) if (!h.isArchived) h];
          final archived = [for (final h in habits) if (h.isArchived) h];
          if (habits.isEmpty) {
            return EmptyState(icon: Icons.self_improvement, title: l.habitsEmptyTitle, message: l.habitsEmptyBody);
          }
          return CustomScrollView(
            slivers: [
              SliverReorderableList(
                itemCount: active.length,
                onReorderItem: (from, to) async {
                  final moved = active[from];
                  final index = to;
                  final record = await ref.read(habitServiceProvider).reorder(moved.id, active, index);
                  if (context.mounted) showUndoSnackBar(context, ref, message: l.habitsReordered, record: record);
                },
                itemBuilder: (ctx, i) {
                  final h = active[i];
                  final paused = pauses.any((p) => p.appliesTo(h.id) && p.covers(today));
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(h.id),
                    index: i,
                    child: _ManageTile(
                      habit: h,
                      subtitle: [
                        if (h.sectionId != null && sections[h.sectionId] != null) sectionName(ctx, sections[h.sectionId]!),
                        if (h.isQuit) l.habitsTypeQuit,
                        if (paused) l.habitsStatusPaused,
                      ].join(' · '),
                    ),
                  );
                },
              ),
              if (archived.isNotEmpty) ...[
                SliverToBoxAdapter(child: SectionHeader(l.habitsArchived)),
                SliverList.list(
                  children: [for (final h in archived) _ManageTile(habit: h, subtitle: l.habitsArchived)],
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          );
        },
      ),
    );
  }
}

class _ManageTile extends ConsumerWidget {
  const _ManageTile({required this.habit, required this.subtitle});

  final Habit habit;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final service = ref.read(habitServiceProvider);
    return ListTile(
      leading: HabitAvatar(habit: habit),
      title: Text(habit.name),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      onTap: () => habit.isQuit ? HabitRoutes.quit(context, habit.id) : HabitRoutes.detail(context, habit.id),
      trailing: PopupMenuButton<String>(
        tooltip: l.actionMore,
        onSelected: (v) async {
          switch (v) {
            case 'edit':
              await HabitRoutes.edit(context, habit.id);
            case 'section':
              final id = await pickHabitSection(context, ref, selectedId: habit.sectionId);
              if (id == null) return;
              final record = await service.moveToSection(habit.id, id.isEmpty ? null : id);
              if (context.mounted) showUndoSnackBar(context, ref, message: l.savedSnack, record: record);
            case 'archive':
              final record = await service.setArchived(habit.id, archived: !habit.isArchived);
              if (context.mounted) {
                showUndoSnackBar(
                  context,
                  ref,
                  message: habit.isArchived ? l.habitsUnarchivedSnack : l.habitsArchivedSnack,
                  record: record,
                );
              }
            case 'delete':
              final ok = await confirmDialog(
                context,
                title: l.habitsDeleteTitle(habit.name),
                body: l.habitsDeleteBody,
                confirmLabel: l.actionDelete,
                destructive: true,
              );
              if (!ok) return;
              final record = await service.delete(habit.id);
              if (context.mounted) showUndoSnackBar(context, ref, message: l.habitsDeletedSnack, record: record);
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(value: 'edit', child: Text(l.actionEdit)),
          PopupMenuItem(value: 'section', child: Text(l.habitsMoveToSection)),
          PopupMenuItem(value: 'archive', child: Text(habit.isArchived ? l.habitsUnarchive : l.actionArchive)),
          PopupMenuItem(value: 'delete', child: Text(l.actionDelete)),
        ],
      ),
    );
  }
}

/// Custom sections (T5.1.15): create, rename, reorder, icon and time window, delete (habits move to
/// Anytime).
class SectionsScreen extends ConsumerWidget {
  const SectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sections = ref.watch(habitSectionsProvider).value ?? const <HabitSection>[];
    final fmt = AppFormat(context.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(l.habitsSections)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSectionEditor(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.habitsSectionNew),
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.only(bottom: 96),
        onReorderItem: (from, to) async {
          final keys = [for (final s in sections) s.sortKey];
          final moved = sections[from];
          final index = to;
          final others = [for (final k in keys) if (k != moved.sortKey) k];
          final after = index == 0 ? null : others[index - 1];
          final before = index >= others.length ? null : others[index];
          await ref.read(habitSectionsRepositoryProvider).move(moved.id, afterKey: after, beforeKey: before);
        },
        children: [
          for (final s in sections)
            ListTile(
              key: ValueKey(s.id),
              leading: Icon(IconCatalog.iconFor(s.icon, fallback: Icons.schedule)),
              title: Text(sectionName(context, s)),
              subtitle: s.hasWindow ? Text('${fmt.time(s.startTime!)} – ${fmt.time(s.endTime!)}') : null,
              onTap: () => showSectionEditor(context, ref, section: s),
            ),
        ],
      ),
    );
  }
}

/// Create or edit a section: name, icon, optional time window; custom sections can be deleted.
Future<void> showSectionEditor(BuildContext context, WidgetRef ref, {HabitSection? section}) =>
    showAppSheet<void>(
      context,
      title: section == null ? context.l10n.habitsSectionNew : context.l10n.habitsSectionEdit,
      builder: (ctx) => _SectionEditor(section: section, host: context),
    );

class _SectionEditor extends ConsumerStatefulWidget {
  const _SectionEditor({required this.section, required this.host});

  final HabitSection? section;
  final BuildContext host;

  @override
  ConsumerState<_SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends ConsumerState<_SectionEditor> {
  late final _name = TextEditingController(text: widget.section == null ? '' : sectionName(widget.host, widget.section!));
  late String? _icon = widget.section?.icon;
  late LocalTime? _start = widget.section?.startTime;
  late LocalTime? _end = widget.section?.endTime;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(habitSectionsRepositoryProvider);
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 40) {
      setState(() => _error = context.l10n.habitsErrSectionName);
      return;
    }
    if (widget.section == null) {
      await repo.create(name: name, icon: _icon, start: _start, end: _end);
    } else {
      await repo.update(widget.section!.id, name: name, icon: _icon, start: _start, end: _end);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = AppFormat(context.localeName);
    final s = widget.section;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: s == null,
            decoration: InputDecoration(labelText: l.habitsFieldName, errorText: _error),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(IconCatalog.iconFor(_icon, fallback: Icons.schedule)),
            title: Text(l.habitsFieldIcon),
            onTap: () async {
              final icon = await pickIcon(context, selected: _icon);
              if (icon != null) setState(() => _icon = icon);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.habitsSectionWindow),
            subtitle: Text(
              _start == null || _end == null ? l.habitsNone : '${fmt.time(_start!)} – ${fmt.time(_end!)}',
            ),
            trailing: _start == null
                ? null
                : IconButton(
                    tooltip: l.actionClear,
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _start = _end = null),
                  ),
            onTap: () async {
              final start = await pickTime(context, initial: _start ?? LocalTime(6, 0));
              if (start == null || !context.mounted) return;
              final end = await pickTime(context, initial: _end ?? LocalTime(12, 0));
              if (end == null) return;
              setState(() {
                _start = start;
                _end = end;
              });
            },
          ),
          const SizedBox(height: Space.md),
          FilledButton(onPressed: _save, child: Text(l.actionSave)),
          if (s != null && s.defaultKey == null) ...[
            const SizedBox(height: Space.sm),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: context.colors.error),
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: l.habitsSectionDeleteTitle,
                  body: l.habitsSectionDeleteBody,
                  confirmLabel: l.actionDelete,
                  destructive: true,
                );
                if (!ok) return;
                final record = await ref.read(habitSectionsRepositoryProvider).delete(s.id);
                if (!mounted) return;
                Navigator.pop(context);
                if (widget.host.mounted) {
                  showUndoSnackBar(widget.host, ref, message: l.habitsSectionDeleted, record: record);
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(l.actionDelete),
            ),
          ],
        ],
      ),
    );
  }
}
