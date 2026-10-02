import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/demo/presentation/demo_data_section.dart';
import 'package:everslot/features/dev/application/dev_providers.dart';
import 'package:everslot/features/dev/domain/dev_models.dart';
import 'package:everslot/features/dev/presentation/component_gallery_screen.dart';
import 'package:everslot/features/dev/presentation/db_inspector_page.dart';
import 'package:everslot/features/dev/presentation/log_viewer_page.dart';
import 'package:everslot/features/dev/presentation/sync_diagnostics_page.dart';
import 'package:everslot/features/profile/presentation/zone_picker.dart';
import 'package:everslot/features/stats/presentation/chart_gallery_screen.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Dev-flavor debug menu (T1.3.16): environment warnings, feature flags, time travel, zone
/// override, logs, local database, sync diagnostics (T1.4.18), component gallery, chart gallery
/// (T6.2.24), reset.
/// Reachable only in dev builds (`/dev`, hidden gesture in Settings › About); [page] = `sync`
/// opens the sync diagnostics directly.
class DebugMenuScreen extends ConsumerWidget {
  const DebugMenuScreen({super.key, this.page});

  final String? page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (page == 'sync') return const SyncDiagnosticsPage();
    final l = context.l10n;
    void open(Widget page) => unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)));
    return Scaffold(
      appBar: AppBar(title: Text(l.devMenu)),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Space.xxl),
        children: [
          SectionHeader(l.devEnvironment),
          const _EnvironmentCard(),
          SectionHeader(l.devTimeTravel),
          const _TimeTravel(),
          SectionHeader(l.devZone),
          const _ZoneOverride(),
          SectionHeader(l.devFlags),
          const _Flags(),
          SectionHeader(l.devTools),
          ListTile(
            key: const ValueKey('dev-logs'),
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(l.devLogs),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const LogViewerPage()),
          ),
          ListTile(
            key: const ValueKey('dev-database'),
            leading: const Icon(Icons.storage_outlined),
            title: Text(l.devDatabase),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const DbInspectorPage()),
          ),
          ListTile(
            key: const ValueKey('dev-sync'),
            leading: const Icon(Icons.sync_alt),
            title: Text(l.devSyncDiagnostics),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const SyncDiagnosticsPage()),
          ),
          ListTile(
            key: const ValueKey('dev-gallery'),
            leading: const Icon(Icons.widgets_outlined),
            title: Text(l.devComponentGallery),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const ComponentGalleryScreen()),
          ),
          ListTile(
            key: const ValueKey('dev-chart-gallery'),
            leading: const Icon(Icons.insert_chart_outlined),
            title: Text(l.chartsGalleryTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const ChartGalleryScreen()),
          ),
          const DemoDataSection(),
          SectionHeader(l.devDangerZone),
          ListTile(
            key: const ValueKey('dev-test-crash'),
            leading: Icon(Icons.bug_report_outlined, color: context.colors.error),
            title: Text(l.devTestCrash),
            subtitle: Text(l.devTestCrashBody),
            // An uncaught async error: logged, and reported to Crashlytics in release builds (T1.2.15).
            onTap: () => Future<void>(() => throw StateError('Everslot test crash (debug menu)')),
          ),
          ListTile(
            key: const ValueKey('dev-reset'),
            leading: Icon(Icons.delete_forever_outlined, color: context.colors.error),
            title: Text(l.devResetData, style: TextStyle(color: context.colors.error)),
            onTap: () => _reset(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.devResetData,
      body: l.devResetDataBody,
      confirmLabel: l.devResetData,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final done = l.devResetDone;
    await ref.read(devToolsProvider).resetLocalData();
    messenger?.showSnackBar(SnackBar(content: Text(done)));
  }
}

class _EnvironmentCard extends ConsumerWidget {
  const _EnvironmentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final env = ref.watch(envProvider);
    final session = ref.watch(sessionProvider);
    final warnings = env.warnings;
    Widget status(String label, bool ok) => Row(
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.warning_amber_outlined,
          size: 18,
          color: ok ? context.appColors.success : context.appColors.warning,
        ),
        const SizedBox(width: Space.sm),
        Expanded(child: Text('$label · ${ok ? l.devConfigured : l.devNotConfigured}')),
      ],
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.devFlavor(env.flavor.name), style: context.text.titleSmall),
              Text(l.devSession(session?.mode.name ?? '—'), style: context.text.bodySmall),
              const SizedBox(height: Space.sm),
              status(l.devSupabase, env.isSupabaseConfigured),
              status(l.devFirebase, env.firebaseEnabled),
              const SizedBox(height: Space.sm),
              if (warnings.isEmpty)
                Text(l.devNoWarnings, style: context.text.bodySmall)
              else
                for (final w in warnings)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: Space.xs),
                    // Configuration hints are developer-facing (English, from Env).
                    child: Text(w, key: const ValueKey('dev-env-warning'), style: context.text.bodySmall),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeTravel extends ConsumerWidget {
  const _TimeTravel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final offset = ref.watch(timeTravelProvider);
    final tools = ref.read(devToolsProvider);
    final prefs = ref.watch(userPreferencesProvider);
    final zone = ref.watch(deviceZoneProvider);
    final resolver = ref.watch(zoneResolverProvider);
    final format = AppFormat(Localizations.localeOf(context).toLanguageTag(), use24h: prefs.use24h, l10n: l);
    final appNow = ref.read(clockProvider).nowUtc();
    final realNow = appNow.subtract(offset);
    String step(Duration d) => '${d.isNegative ? '−' : '+'}${format.duration(d.inMinutes.abs())}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          key: const ValueKey('dev-time-now'),
          leading: const Icon(Icons.schedule),
          title: Text(l.devTimeTravelNow(format.dateTime(resolver.toLocal(appNow, zone)))),
          subtitle: Text(
            offset == Duration.zero ? l.devTimeTravelOff : l.devTimeTravelOffset(format.relative(appNow, realNow)),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
          child: Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final d in TimeTravelSteps.steps)
                ActionChip(
                  key: ValueKey('dev-travel-${d.inMinutes}'),
                  label: Text(step(d)),
                  onPressed: () => tools.travelBy(d),
                ),
              ActionChip(
                key: const ValueKey('dev-travel-pick'),
                avatar: const Icon(Icons.event),
                label: Text(l.devTimeTravelPick),
                onPressed: () => _pick(context, ref, appNow, zone),
              ),
              if (offset != Duration.zero)
                ActionChip(
                  key: const ValueKey('dev-travel-reset'),
                  avatar: const Icon(Icons.restore),
                  label: Text(l.devTimeTravelReset),
                  onPressed: tools.resetTime,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, DateTime appNow, String zone) async {
    final resolver = ref.read(zoneResolverProvider);
    final use24h = ref.read(userPreferencesProvider).use24h;
    final local = resolver.toLocal(appNow, zone);
    final date = await pickDate(context, initial: local.date);
    if (date == null || !context.mounted) return;
    final time = await pickTime(context, initial: local.time, use24h: use24h);
    if (time == null) return;
    final target = resolver.resolve(LocalDateTime(date, time), zone).utc;
    ref.read(devToolsProvider).travelTo(target);
  }
}

class _ZoneOverride extends ConsumerWidget {
  const _ZoneOverride();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final zone = ref.watch(deviceZoneProvider);
    final overridden = ref.read(deviceZoneProvider.notifier).isOverridden;
    final tools = ref.read(devToolsProvider);
    return Column(
      children: [
        ListTile(
          key: const ValueKey('dev-zone'),
          leading: const Icon(Icons.public),
          title: Text(l.devZoneDevice(zone)),
          subtitle: overridden ? Text(l.devZoneOverridden) : null,
          trailing: const Icon(Icons.edit_outlined),
          onTap: () async {
            final picked = await pickTimeZone(context, current: zone, title: l.devZoneOverride);
            if (picked != null) tools.overrideZone(picked);
          },
        ),
        if (overridden)
          ListTile(
            key: const ValueKey('dev-zone-reset'),
            leading: const Icon(Icons.my_location),
            title: Text(l.devZoneReset),
            onTap: () => unawaited(tools.resetZone()),
          ),
      ],
    );
  }
}

class _Flags extends ConsumerWidget {
  const _Flags();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final active = ref.watch(featureFlagsProvider);
    final all = {...DevFlags.known, ...ref.watch(envProvider).featureFlags, ...active}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.sm),
          child: Text(l.devFlagsHint, style: context.text.bodySmall),
        ),
        for (final flag in all)
          SwitchListTile(
            key: ValueKey('dev-flag-$flag'),
            title: Text(flag),
            value: active.contains(flag),
            onChanged: (_) => ref.read(devToolsProvider).toggleFlag(flag),
          ),
      ],
    );
  }
}
