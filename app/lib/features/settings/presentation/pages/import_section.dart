import 'dart:async';
import 'dart:io';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/settings/application/external_import_service.dart';
import 'package:everslot/features/settings/application/import_service.dart';
import 'package:everslot/features/settings/domain/external_import.dart';
import 'package:everslot/features/settings/domain/import_plan.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Picks an export file (null on cancel; tests override it).
final importFilePickerProvider = Provider<Future<File?> Function()>(
  (ref) => () async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['json', 'zip']);
    final path = files.isEmpty ? null : files.first.path;
    return path == null ? null : File(path);
  },
);

/// Settings › Export & import › Import (T8.3.08).
class ImportSection extends ConsumerStatefulWidget {
  const ImportSection({super.key});

  @override
  ConsumerState<ImportSection> createState() => _ImportSectionState();
}

class _ImportSectionState extends ConsumerState<ImportSection> {
  var _opening = false;

  Future<void> _pick() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final file = await ref.read(importFilePickerProvider)();
    if (file == null || !mounted) return;
    setState(() => _opening = true);
    try {
      final bundle = await ref.read(importServiceProvider).open(file);
      if (!mounted) return;
      setState(() => _opening = false);
      await showAppSheet<void>(
        context,
        title: l.dataImportTitle,
        builder: (_) => ImportSheet(bundle: bundle),
      );
    } on FormatException catch (e) {
      if (mounted) setState(() => _opening = false);
      messenger?.showSnackBar(SnackBar(content: Text(importErrorText(l, e.message))));
    } on Object {
      if (mounted) setState(() => _opening = false);
      messenger?.showSnackBar(SnackBar(content: Text(l.dataImportFailed)));
    }
  }

  Future<void> _external() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final source = await showAppSheet<ExternalSource>(
      context,
      title: l.extImportTitle,
      builder: (ctx) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in ExternalSource.values)
              ListTile(
                key: ValueKey('ext-source-${s.name}'),
                leading: Icon(_sourceIcon(s)),
                title: Text(externalSourceName(l, s)),
                subtitle: Text(externalSourceHint(l, s)),
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await ref.read(externalFilePickerProvider)();
    if (file == null || !mounted) return;
    setState(() => _opening = true);
    try {
      final bundle = await ref.read(externalImportServiceProvider).open(file, source);
      if (!mounted) return;
      setState(() => _opening = false);
      if (bundle.plan.isEmpty) {
        messenger?.showSnackBar(SnackBar(content: Text(l.extImportNothing)));
        return;
      }
      await showAppSheet<void>(
        context,
        title: externalSourceName(l, source),
        builder: (_) => ExternalImportSheet(bundle: bundle),
      );
    } on Object {
      if (mounted) setState(() => _opening = false);
      messenger?.showSnackBar(SnackBar(content: Text(l.extImportWrongFile(externalSourceName(l, source)))));
    }
  }

  static IconData _sourceIcon(ExternalSource s) => switch (s) {
    ExternalSource.loop => Icons.local_fire_department_outlined,
    ExternalSource.keep => Icons.sticky_note_2_outlined,
    ExternalSource.todoist || ExternalSource.tickTick => Icons.task_alt,
    ExternalSource.text => Icons.notes,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.dataImportTitle),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
          child: Text(l.dataImportBody, style: context.text.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.md),
          child: _opening
              ? const LinearProgressIndicator()
              : OutlinedButton.icon(
                  key: const ValueKey('import-pick'),
                  onPressed: () => unawaited(_pick()),
                  icon: const Icon(Icons.file_open_outlined),
                  label: Text(l.dataImportPick),
                ),
        ),
        // Other apps (T8.3.14).
        ListTile(
          key: const ValueKey('import-external'),
          leading: const Icon(Icons.move_to_inbox_outlined),
          title: Text(l.extImportTitle),
          subtitle: Text(l.extImportSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => unawaited(_external()),
        ),
      ],
    );
  }
}

/// Picks any file for an import from another app (tests override it).
final externalFilePickerProvider = Provider<Future<File?> Function()>(
  (ref) => () async {
    final files = await FilePicker.pickFiles();
    final path = files.isEmpty ? null : files.first.path;
    return path == null ? null : File(path);
  },
);

String externalSourceName(AppLocalizations l, ExternalSource s) => switch (s) {
  ExternalSource.loop => 'Loop Habit Tracker',
  ExternalSource.keep => 'Google Keep',
  ExternalSource.todoist => 'Todoist',
  ExternalSource.tickTick => 'TickTick',
  ExternalSource.text => l.extSourceText,
};

String externalSourceHint(AppLocalizations l, ExternalSource s) => switch (s) {
  ExternalSource.loop => l.extSourceLoopHint,
  ExternalSource.keep => l.extSourceKeepHint,
  ExternalSource.todoist => l.extSourceTodoistHint,
  ExternalSource.tickTick => l.extSourceTickTickHint,
  ExternalSource.text => l.extSourceTextHint,
};

/// Preview and apply of an import from another app (T8.3.14).
class ExternalImportSheet extends ConsumerStatefulWidget {
  const ExternalImportSheet({required this.bundle, super.key});

  final ExternalBundle bundle;

  @override
  ConsumerState<ExternalImportSheet> createState() => _ExternalImportSheetState();
}

class _ExternalImportSheetState extends ConsumerState<ExternalImportSheet> {
  double? _progress;

  Future<void> _apply() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _progress = 0);
    try {
      final r = await ref
          .read(externalImportServiceProvider)
          .apply(
            widget.bundle,
            onProgress: (v) {
              if (mounted) setState(() => _progress = v);
            },
          );
      if (!mounted) return;
      Navigator.pop(context);
      messenger?.showSnackBar(SnackBar(content: Text(l.extImportDone(r.habits + r.lists + r.tasks))));
    } on Object {
      if (mounted) setState(() => _progress = null);
      messenger?.showSnackBar(SnackBar(content: Text(l.dataImportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final plan = widget.bundle.plan;
    final busy = _progress != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ListView(
            key: const ValueKey('ext-preview'),
            shrinkWrap: true,
            children: [
              if (plan.habits.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.local_fire_department_outlined),
                  title: Text(l.extCountHabits(plan.habits.length)),
                  subtitle: Text(l.extCountCheckIns(plan.checkCount)),
                ),
              if (plan.lists.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.checklist_outlined),
                  title: Text(l.extCountLists(plan.lists.length)),
                  subtitle: Text(l.extCountItems(plan.itemCount)),
                ),
              if (plan.tasks.isNotEmpty)
                ListTile(leading: const Icon(Icons.task_alt), title: Text(l.extCountTasks(plan.tasks.length))),
              for (final e in plan.notes.entries)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.info_outline),
                  title: Text(switch (e.key) {
                    ImportNote.frequencyApproximated => l.extNoteFrequency(e.value),
                    ImportNote.repeatNotUnderstood => l.extNoteRepeat(e.value),
                    ImportNote.completedSkipped => l.extNoteCompleted(e.value),
                    ImportNote.trashedSkipped => l.extNoteTrashed(e.value),
                    ImportNote.attachmentMissing => l.extNoteAttachment(e.value),
                  }),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, Space.lg),
          child: busy
              ? LinearProgressIndicator(value: _progress)
              : FilledButton.icon(
                  key: const ValueKey('ext-run'),
                  onPressed: () => unawaited(_apply()),
                  icon: const Icon(Icons.download_done),
                  label: Text(l.extImportRun),
                ),
        ),
      ],
    );
  }
}

String importErrorText(AppLocalizations l, String reason) => switch (reason) {
  'csv_export' => l.dataImportErrorCsv,
  'unsupported_format' => l.dataImportErrorVersion,
  _ => l.dataImportErrorNotExport,
};

/// Dry run, mode choice and apply.
class ImportSheet extends ConsumerStatefulWidget {
  const ImportSheet({required this.bundle, super.key});

  final ImportBundle bundle;

  @override
  ConsumerState<ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<ImportSheet> {
  late final bool _sameAccount = ref.read(importServiceProvider).sameAccount(widget.bundle);
  late ImportMode _mode = _sameAccount ? ImportMode.restore : ImportMode.copy;
  var _replaceNewer = false;
  Future<ImportPreview>? _preview;
  double? _progress;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() =>
      _preview = ref.read(importServiceProvider).preview(widget.bundle, _mode, replaceNewer: _replaceNewer);

  Future<void> _apply() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _progress = 0);
    try {
      final done = await ref
          .read(importServiceProvider)
          .apply(
            widget.bundle,
            _mode,
            replaceNewer: _replaceNewer,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p.total == 0 ? 1 : p.done / p.total);
            },
          );
      if (!mounted) return;
      Navigator.pop(context);
      messenger?.showSnackBar(SnackBar(content: Text(l.dataImportDone(done.total.added + done.total.updated))));
    } on Object {
      if (mounted) setState(() => _progress = null);
      messenger?.showSnackBar(SnackBar(content: Text(l.dataImportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final busy = _progress != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RadioGroup<ImportMode>(
                  groupValue: _mode,
                  onChanged: (v) {
                    if (busy || v == null) return;
                    setState(() {
                      _mode = v;
                      _refresh();
                    });
                  },
                  child: Column(
                    children: [
                      RadioListTile<ImportMode>(
                        key: const ValueKey('import-restore'),
                        value: ImportMode.restore,
                        enabled: _sameAccount,
                        title: Text(l.dataImportRestore),
                        subtitle: Text(_sameAccount ? l.dataImportRestoreHint : l.dataImportRestoreOtherAccount),
                      ),
                      RadioListTile<ImportMode>(
                        key: const ValueKey('import-copy'),
                        value: ImportMode.copy,
                        title: Text(l.dataImportCopy),
                        subtitle: Text(l.dataImportCopyHint),
                      ),
                    ],
                  ),
                ),
                if (_mode == ImportMode.restore)
                  SwitchListTile(
                    key: const ValueKey('import-replace-newer'),
                    title: Text(l.dataImportReplaceNewer),
                    subtitle: Text(l.dataImportReplaceNewerHint),
                    value: _replaceNewer,
                    onChanged: busy
                        ? null
                        : (v) => setState(() {
                            _replaceNewer = v;
                            _refresh();
                          }),
                  ),
                FutureBuilder<ImportPreview>(
                  future: _preview,
                  builder: (context, snap) {
                    final p = snap.data;
                    if (p == null) {
                      return const Padding(
                        padding: EdgeInsetsDirectional.all(Space.lg),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _PreviewTable(preview: p);
                  },
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.md, Space.lg, Space.lg),
          child: busy
              ? LinearProgressIndicator(key: const ValueKey('import-progress'), value: _progress)
              : FilledButton.icon(
                  key: const ValueKey('import-run'),
                  onPressed: () => unawaited(_apply()),
                  icon: const Icon(Icons.download_done),
                  label: Text(_mode == ImportMode.restore ? l.dataImportRunRestore : l.dataImportRunCopy),
                ),
        ),
      ],
    );
  }
}

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.preview});

  final ImportPreview preview;

  /// Tables people recognize; everything else is summed under "Other data".
  static String? _label(AppLocalizations l, String table) => switch (table) {
    'tasks' => l.dataImportKindTasks,
    'task_occurrences' || 'time_entries' => l.dataImportKindOccurrences,
    'checklists' => l.dataImportKindLists,
    'checklist_items' => l.dataImportKindItems,
    'habits' => l.dataImportKindHabits,
    'habit_logs' => l.dataImportKindHabitLogs,
    'categories' || 'tags' => l.dataImportKindCategories,
    'attachments' => l.dataImportKindAttachments,
    'notifications' => l.dataImportKindInbox,
    'user_settings' => l.dataImportKindSettings,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final groups = <String, ImportTableCounts>{};
    for (final e in preview.tables.entries) {
      final label = _label(l, e.key) ?? l.dataImportKindOther;
      groups[label] = (groups[label] ?? const ImportTableCounts()) + e.value;
    }
    final total = preview.total;
    return Column(
      key: const ValueKey('import-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in groups.entries)
          if (e.value.total > 0) ListTile(dense: true, title: Text(e.key), subtitle: Text(_line(l, e.value))),
        const Divider(),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: Text(_line(l, total), key: const ValueKey('import-total'), style: context.text.titleSmall),
        ),
        if (total.keptLocal > 0)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.xs, Space.lg, 0),
            child: Text(l.dataImportConflictsHint(total.keptLocal), style: context.text.bodySmall),
          ),
      ],
    );
  }

  static String _line(AppLocalizations l, ImportTableCounts c) => [
    if (c.added > 0) l.dataImportCountNew(c.added),
    if (c.updated > 0) l.dataImportCountUpdated(c.updated),
    if (c.unchanged > 0) l.dataImportCountUnchanged(c.unchanged),
    if (c.keptLocal > 0) l.dataImportCountKept(c.keptLocal),
    if (c.skipped > 0) l.dataImportCountSkipped(c.skipped),
  ].join(' · ');
}
