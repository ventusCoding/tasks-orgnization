import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/habits/application/vocab_service.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/presentation/quit/quit_sheets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Trigger, place, coping and distraction libraries (T5.3.14): add, rename, restyle (icon, color),
/// archive/restore and drag to reorder entries of each kind, with how often each was used. Logs
/// keep entry ids, so renaming updates every past craving and relapse too.
class VocabManageScreen extends ConsumerStatefulWidget {
  const VocabManageScreen({super.key, this.initialKind = VocabKind.trigger});

  final VocabKind initialKind;

  @override
  ConsumerState<VocabManageScreen> createState() => _VocabManageScreenState();
}

class _VocabManageScreenState extends ConsumerState<VocabManageScreen> {
  late VocabKind _kind = widget.initialKind;

  String _kindLabel(VocabKind k) {
    final l = context.l10n;
    return switch (k) {
      VocabKind.trigger => l.quitVocabTriggers,
      VocabKind.place => l.quitVocabPlaces,
      VocabKind.coping => l.quitVocabCoping,
      VocabKind.distraction => l.quitVocabDistractions,
    };
  }

  Future<void> _add() async {
    final l = context.l10n;
    final name = await promptText(context, title: l.quitVocabAdd, hint: l.quitVocabName);
    if (name == null || !mounted) return;
    final record = await ref.read(habitVocabServiceProvider).add(_kind, name);
    if (mounted) showUndoSnackBar(context, ref, message: l.quitVocabSaved, record: record);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final all = ref.watch(allHabitVocabProvider).value ?? const <VocabEntry>[];
    final usage = ref.watch(vocabUsageProvider(VocabPicker.columnOf(_kind))).value ?? const <String, int>{};
    final active = [for (final e in all) if (e.kind == _kind && !e.archived) e];
    final archived = [for (final e in all) if (e.kind == _kind && e.archived) e];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.quitVocabTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
              children: [
                for (final k in VocabKind.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.sm),
                    child: ChoiceChip(
                      label: Text(_kindLabel(k)),
                      selected: _kind == k,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(l.quitVocabAdd),
      ),
      body: active.isEmpty && archived.isEmpty
          ? EmptyState(icon: Icons.list_alt, title: _kindLabel(_kind), message: l.quitVocabEmpty)
          : CustomScrollView(
              // Each kind starts at the top.
              key: ValueKey(_kind),
              slivers: [
                SliverReorderableList(
                  itemCount: active.length,
                  onReorderItem: (from, to) {
                    if (from == to) return;
                    unawaited(ref.read(habitVocabServiceProvider).reorder(active[from].id, active, to));
                  },
                  itemBuilder: (ctx, i) => ReorderableDelayedDragStartListener(
                    key: ValueKey(active[i].id),
                    index: i,
                    child: _VocabTile(entry: active[i], uses: usage[active[i].id] ?? 0),
                  ),
                ),
                if (archived.isNotEmpty) ...[
                  SliverToBoxAdapter(child: SectionHeader(l.habitsArchived)),
                  SliverList.list(
                    children: [for (final e in archived) _VocabTile(entry: e, uses: usage[e.id] ?? 0)],
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
    );
  }
}

class _VocabTile extends ConsumerWidget {
  const _VocabTile({required this.entry, required this.uses});

  final VocabEntry entry;
  final int uses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final service = ref.read(habitVocabServiceProvider);
    final color = entry.color == null ? context.colors.primary : Color(entry.color!);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(IconCatalog.iconFor(entry.icon, fallback: Icons.label_outline), color: color),
      ),
      title: Text(entry.name),
      subtitle: Text(l.quitVocabUses(uses)),
      trailing: PopupMenuButton<String>(
        tooltip: l.actionMore,
        onSelected: (v) async {
          switch (v) {
            case 'rename':
              final name = await promptText(context, title: l.quitVocabRename, initial: entry.name);
              if (name == null) return;
              final record = await service.rename(entry.id, name);
              if (context.mounted) showUndoSnackBar(context, ref, message: l.quitVocabSaved, record: record);
            case 'icon':
              final icon = await pickIcon(context, selected: entry.icon);
              if (icon == null) return;
              final record = await service.setIcon(entry.id, icon);
              if (context.mounted) showUndoSnackBar(context, ref, message: l.quitVocabSaved, record: record);
            case 'color':
              final c = await pickColor(context, selected: entry.color, allowNone: true);
              if (c == null) return;
              final record = await service.setColor(entry.id, c == -1 ? null : c);
              if (context.mounted) showUndoSnackBar(context, ref, message: l.quitVocabSaved, record: record);
            default:
              final record = await service.setArchived(entry.id, archived: !entry.archived);
              if (context.mounted) showUndoSnackBar(context, ref, message: l.quitVocabSaved, record: record);
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(value: 'rename', child: Text(l.quitVocabRename)),
          PopupMenuItem(value: 'icon', child: Text(l.habitsFieldIcon)),
          PopupMenuItem(value: 'color', child: Text(l.habitsFieldColor)),
          PopupMenuItem(value: 'archive', child: Text(entry.archived ? l.habitsUnarchive : l.actionArchive)),
        ],
      ),
    );
  }
}
