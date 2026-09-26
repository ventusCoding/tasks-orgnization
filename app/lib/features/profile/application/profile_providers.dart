import 'package:everslot/core/providers.dart';
import 'package:everslot/features/profile/data/profile_repository.dart';
import 'package:everslot/features/profile/domain/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profile repository (T1.5.04) — other features use these providers, never the data class.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

/// Live profile of the current user (null until created / pulled).
final profileProvider = StreamProvider<Profile?>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(profileRepositoryProvider).watch();
});
