import 'dart:async';
import 'dart:io';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/integrations/application/ics_service.dart';
import 'package:everslot/features/integrations/domain/ics_mapping.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/settings/application/export_service.dart' show shareFileProvider;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

/// Reads a `.ics` file picked by the user (null on cancel; tests override it).
final icsFileReaderProvider = Provider<Future<String?> Function()>(
  (ref) => () async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['ics', 'ical', 'ifb']);
    if (files.isEmpty || files.first.path == null) return null;
    return File(files.first.path!).readAsString();
  },
);

/// Writes [content] to a temporary `.ics` file and opens the share sheet (T8.2.11).
Future<void> shareIcs(WidgetRef ref, String content, String name) async {
  final dir = await getTemporaryDirectory();
  final safe = name.replaceAll(RegExp(r'[^\p{L}\p{N} _-]', unicode: true), '').trim();
  final file = File('${dir.path}/${safe.isEmpty ? 'everslot' : safe}.ics');
  await file.writeAsString(content);
  await ref.read(shareFileProvider)(file, subject: name);
}

/// Task menu: *Add to calendar (.ics)*.
Future<void> exportTaskToCalendar(WidgetRef ref, String taskId, String title) async =>
    shareIcs(ref, await ref.read(icsServiceProvider).exportTask(taskId), title);

/// Preview and import of a calendar file (T8.2.12).
Future<void> showIcsImport(BuildContext context, String content) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final candidates = await container.read(icsServiceProvider).preview(content);
  if (!context.mounted) return;
  await showAppSheet<void>(
    context,
    title: context.l10n.icsImportTitle,
    builder: (_) => IcsImportSheet(candidates: candidates),
  );
}

class IcsImportSheet extends ConsumerStatefulWidget {
  const IcsImportSheet({required this.candidates, super.key});

  final List<IcsImportCandidate> candidates;

  @override
  ConsumerState<IcsImportSheet> createState() => _IcsImportSheetState();
}

class _IcsImportSheetState extends ConsumerState<IcsImportSheet> {
  late final Set<int> _selected = {
    for (final (i, c) in widget.candidates.indexed)
      if (!c.alreadyImported) i,
  };
  var _busy = false;

  Future<void> _import() async {
    final l = context.l10n;
    setState(() => _busy = true);
    final picked = [for (final i in _selected.toList()..sort()) widget.candidates[i]];
    final count = await ref.read(icsServiceProvider).import(picked);
    if (!mounted) return;
    Navigator.pop(context);
    showInfoSnackBar(context, l.icsImported(count));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final fmt = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final candidates = widget.candidates;
    if (candidates.isEmpty) {
      return Padding(padding: const EdgeInsetsDirectional.all(Space.lg), child: Text(l.icsNothing));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ListView(
            key: const ValueKey('ics-list'),
            shrinkWrap: true,
            children: [
              for (final (i, c) in candidates.indexed)
                CheckboxListTile(
                  key: ValueKey('ics-item-$i'),
                  value: _selected.contains(i),
                  onChanged: (v) => setState(() => v ?? false ? _selected.add(i) : _selected.remove(i)),
                  title: Text(c.task.title),
                  subtitle: Text(
                    [
                      if (c.task.startLocal case final s?)
                        c.task.isAllDay ? fmt.dateMedium(s.date) : '${fmt.dateMedium(s.date)} ${fmt.timeOf(s)}',
                      if (c.task.recurrence != null) l.icsRepeats,
                      if (c.overrides.isNotEmpty) l.icsChanges(c.overrides.length),
                      if (c.alreadyImported) l.icsAlreadyImported,
                      if (c.problem != null) l.icsRepeatUnsupported,
                    ].join(' · '),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.all(Space.lg),
          child: FilledButton(
            key: const ValueKey('ics-import'),
            onPressed: _selected.isEmpty || _busy ? null : () => unawaited(_import()),
            child: Text(l.icsImportCount(_selected.length)),
          ),
        ),
      ],
    );
  }
}

/// Settings › Widgets & integrations › Calendar files: import a `.ics`, export a range / category.
class IcsSettingsSection extends ConsumerWidget {
  const IcsSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.icsSection),
        ListTile(
          key: const ValueKey('ics-import-file'),
          leading: const Icon(Icons.file_open_outlined),
          title: Text(l.icsImportFile),
          subtitle: Text(l.icsImportHint),
          onTap: () async {
            final content = await ref.read(icsFileReaderProvider)();
            if (content != null && context.mounted) await showIcsImport(context, content);
          },
        ),
        ListTile(
          key: const ValueKey('ics-export'),
          leading: const Icon(Icons.ios_share),
          title: Text(l.icsExport),
          subtitle: Text(l.icsExportHint),
          onTap: () =>
              unawaited(showAppSheet<void>(context, title: l.icsExport, builder: (_) => const IcsExportSheet())),
        ),
      ],
    );
  }
}

class IcsExportSheet extends ConsumerStatefulWidget {
  const IcsExportSheet({super.key});

  @override
  ConsumerState<IcsExportSheet> createState() => _IcsExportSheetState();
}

class _IcsExportSheetState extends ConsumerState<IcsExportSheet> {
  var _days = 30;
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Space.sm,
            children: [
              for (final d in const [7, 30, 90, 365])
                ChoiceChip(
                  key: ValueKey('ics-days-$d'),
                  label: Text(l.icsNextDays(d)),
                  selected: _days == d,
                  onSelected: (_) => setState(() => _days = d),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          DropdownButtonFormField<String?>(
            key: const ValueKey('ics-category'),
            initialValue: _categoryId,
            decoration: InputDecoration(labelText: l.searchCategory),
            items: [
              DropdownMenuItem(child: Text(l.searchAny)),
              for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: Space.md),
          FilledButton.icon(
            key: const ValueKey('ics-export-go'),
            icon: const Icon(Icons.ios_share),
            label: Text(l.icsExport),
            onPressed: () async {
              final zones = ref.read(zoneResolverProvider);
              final today = zones.toLocal(ref.read(clockProvider).nowUtc(), ref.read(deviceZoneProvider)).date;
              final content = await ref
                  .read(icsServiceProvider)
                  .exportRange(today, today.plusDays(_days - 1), categoryId: _categoryId);
              if (!context.mounted) return;
              Navigator.pop(context);
              await shareIcs(ref, content, 'Everslot');
            },
          ),
        ],
      ),
    );
  }
}
