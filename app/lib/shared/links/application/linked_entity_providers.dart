import 'package:everslot/core/providers.dart';
import 'package:everslot/shared/links/data/linked_entity_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:everslot/shared/links/data/linked_entity_store.dart' show LinkedEntity;

/// A reference to an entity of any type.
typedef EntityRef = ({String type, String id});

final linkedEntityStoreProvider = Provider<LinkedEntityStore>(
  (ref) => LinkedEntityStore(ref.watch(appDatabaseProvider)),
);

/// Live title/status of a linked entity (T2.3.12).
final linkedEntityProvider = StreamProvider.autoDispose.family<LinkedEntity, EntityRef>((ref, e) {
  ref.watch(currentUserIdProvider);
  return ref.watch(linkedEntityStoreProvider).watch(e.type, e.id);
});
