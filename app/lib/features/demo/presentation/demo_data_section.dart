import 'dart:async';

import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/demo/application/demo_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Debug menu › Sample data (T8.3.16).
class DemoDataSection extends ConsumerStatefulWidget {
  const DemoDataSection({super.key});

  @override
  ConsumerState<DemoDataSection> createState() => _DemoDataSectionState();
}

class _DemoDataSectionState extends ConsumerState<DemoDataSection> {
  double? _progress;

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _progress = 0);
    try {
      await action();
      messenger?.showSnackBar(SnackBar(content: Text(done)));
    } finally {
      if (mounted) setState(() => _progress = null);
      ref.invalidate(demoPresentProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = ref.read(demoServiceProvider);
    final present = ref.watch(demoPresentProvider).value ?? false;
    final busy = _progress != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l.demoTitle),
        if (!service.allowed)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
            child: Text(l.demoOnlyLocal, style: context.text.bodySmall),
          )
        else if (busy)
          Padding(
            padding: const EdgeInsetsDirectional.all(Space.lg),
            child: LinearProgressIndicator(value: _progress),
          )
        else if (present)
          ListTile(
            key: const ValueKey('demo-remove'),
            leading: Icon(Icons.delete_sweep_outlined, color: context.colors.error),
            title: Text(l.demoRemove),
            subtitle: Text(l.demoRemoveHint),
            onTap: () => unawaited(_run(service.remove, l.demoRemoved)),
          )
        else
          ListTile(
            key: const ValueKey('demo-generate'),
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(l.demoGenerate),
            subtitle: Text(l.demoGenerateHint),
            onTap: () => unawaited(
              _run(
                () => service.generate(
                  onProgress: (v) {
                    if (mounted) setState(() => _progress = v);
                  },
                ),
                l.demoDone,
              ),
            ),
          ),
      ],
    );
  }
}
