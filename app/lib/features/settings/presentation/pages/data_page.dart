import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/settings/application/export_service.dart';
import 'package:everslot/features/settings/presentation/pages/import_section.dart';
import 'package:everslot/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Settings › Export & import (T8.3.07, T8.3.08, T8.3.14).
class DataPage extends ConsumerWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return SettingsPageScaffold(title: l.settingsDataTitle, children: const [_ExportSection(), ImportSection()]);
  }
}

class _ExportSection extends ConsumerStatefulWidget {
  const _ExportSection();

  @override
  ConsumerState<_ExportSection> createState() => _ExportSectionState();
}

class _ExportSectionState extends ConsumerState<_ExportSection> {
  ExportKind _kind = ExportKind.json;
  bool _attachments = false;
  double? _progress;

  Future<void> _export() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _progress = 0);
    try {
      final file = await ref
          .read(exportServiceProvider)
          .export(
            kind: _kind,
            includeAttachments: _attachments,
            onProgress: (p) {
              if (mounted) {
                setState(() => _progress = p.total == 0 ? 1 : p.done / p.total);
              }
            },
          );
      if (!mounted) return;
      setState(() => _progress = null);
      messenger?.showSnackBar(SnackBar(content: Text(l.settingsExportDone(file.uri.pathSegments.last))));
      await ref.read(shareFileProvider)(file, subject: l.settingsExportShareSubject);
    } on Object {
      if (mounted) setState(() => _progress = null);
      messenger?.showSnackBar(SnackBar(content: Text(l.settingsExportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final busy = _progress != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.settingsExportTitle),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
          child: Text(l.settingsExportBody, style: context.text.bodyMedium),
        ),
        RadioGroup<ExportKind>(
          groupValue: _kind,
          onChanged: (v) {
            if (!busy && v != null) setState(() => _kind = v);
          },
          child: Column(
            children: [
              RadioListTile<ExportKind>(
                key: const ValueKey('export-json'),
                value: ExportKind.json,
                title: Text(l.settingsExportJson),
                subtitle: Text(l.settingsExportJsonHint),
              ),
              RadioListTile<ExportKind>(
                key: const ValueKey('export-csv'),
                value: ExportKind.csv,
                title: Text(l.settingsExportCsv),
                subtitle: Text(l.settingsExportCsvHint),
              ),
            ],
          ),
        ),
        SettingsSwitchTile(
          key: const ValueKey('export-attachments'),
          icon: Icons.attach_file,
          title: l.settingsExportAttachments,
          subtitle: l.settingsExportAttachmentsHint,
          value: _attachments,
          onChanged: busy ? null : (v) => setState(() => _attachments = v),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.md),
          child: busy
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: Space.xs),
                    Text(
                      l.settingsExportProgress(((_progress ?? 0) * 100).round()),
                      key: const ValueKey('export-progress'),
                      style: context.text.bodySmall,
                    ),
                  ],
                )
              : FilledButton.icon(
                  key: const ValueKey('export-run'),
                  onPressed: () => unawaited(_export()),
                  icon: const Icon(Icons.ios_share),
                  label: Text(l.settingsExportButton),
                ),
        ),
      ],
    );
  }
}
