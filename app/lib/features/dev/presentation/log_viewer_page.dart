import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/dev/application/dev_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

/// Recent log records (the `AppLog` ring buffer), newest first, filterable by level (T1.3.16).
class LogViewerPage extends ConsumerStatefulWidget {
  const LogViewerPage({super.key});

  @override
  ConsumerState<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends ConsumerState<LogViewerPage> {
  static const _levels = [Level.ALL, Level.INFO, Level.WARNING, Level.SEVERE];
  Level _min = Level.ALL;

  static String line(LogRecord r) =>
      '${r.time.toUtc().toIso8601String()} ${r.level.name} ${r.loggerName}: ${r.message}'
      '${r.error != null ? ' — ${r.error}' : ''}';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final records = [
      for (final r in ref.watch(devLogsProvider).reversed)
        if (r.level >= _min) r,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.devLogs),
        actions: [
          IconButton(
            key: const ValueKey('dev-logs-copy'),
            tooltip: l.devLogsCopy,
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: records.map(line).join('\n')));
              if (context.mounted) showInfoSnackBar(context, l.devCopied);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg, vertical: Space.sm),
            child: Wrap(
              spacing: Space.sm,
              children: [
                for (final level in _levels)
                  ChoiceChip(
                    key: ValueKey('dev-log-level-${level.name}'),
                    label: Text(level == Level.ALL ? l.devLogsAll : level.name),
                    selected: _min == level,
                    onSelected: (_) => setState(() => _min = level),
                  ),
              ],
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? EmptyState(icon: Icons.receipt_long_outlined, title: l.devLogsEmpty)
                : ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, i) {
                      final r = records[i];
                      final color = r.level >= Level.SEVERE
                          ? context.appColors.danger
                          : r.level >= Level.WARNING
                          ? context.appColors.warning
                          : context.colors.onSurfaceVariant;
                      return ListTile(
                        dense: true,
                        leading: Text(r.level.name.substring(0, 1), style: context.text.titleSmall?.copyWith(color: color)),
                        title: Text('${r.loggerName}: ${r.message}'),
                        subtitle: Text(
                          [r.time.toUtc().toIso8601String(), if (r.error != null) '${r.error}'].join('\n'),
                          style: context.text.bodySmall,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
