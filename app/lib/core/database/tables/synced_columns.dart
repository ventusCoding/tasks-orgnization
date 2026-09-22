import 'package:drift/drift.dart';

/// Common columns of every synced table (arch §7.2). Mirrors the server schema.
///
/// - `id`: UUIDv7 (or UUIDv5 for convergent rows), generated on the device.
/// - `updatedAt`: last edit time (informational; conflicts are resolved per field by `fieldClock`).
/// - `rev`: per-user server revision (0 until the row has been pulled/pushed).
/// - `fieldClock`: JSON map `{column: hlc}` used for per-field last-writer-wins.
mixin SyncedColumns on Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get rev => integer().withDefault(const Constant(0))();
  TextColumn get fieldClock => text().withDefault(const Constant('{}'))();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  TextColumn get originDeviceId => text().nullable()();
}
