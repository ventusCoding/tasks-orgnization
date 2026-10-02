/// Custom dashboards wiring (T6.7.16).
library;

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/stats/data/dashboards_repository.dart';
import 'package:everslot/features/stats/domain/dashboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardsRepositoryProvider = Provider<DashboardsRepository>(
  (ref) => DashboardsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

final dashboardsProvider = StreamProvider.autoDispose<List<Dashboard>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(dashboardsRepositoryProvider).watchAll();
});

final dashboardProvider = StreamProvider.autoDispose.family<Dashboard?, String>((ref, id) {
  ref.watch(currentUserIdProvider);
  return ref.watch(dashboardsRepositoryProvider).watch(id);
});
