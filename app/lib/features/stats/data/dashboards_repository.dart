/// Custom dashboards (T6.7.16): read from Drift, written through [SyncWriter] so they sync across
/// devices (per-field LWW on `name`, `sort_key` and the whole `layout` document).
library;

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/ordering/fractional_index.dart';
import 'package:everslot/core/sync/sync_writer.dart';
import 'package:everslot/features/stats/domain/dashboard.dart';

class DashboardsRepository {
  DashboardsRepository(this._db, this._writer, this._userId);

  final AppDatabase _db;
  final SyncWriter _writer;
  final String Function() _userId;

  static Dashboard map(DashboardRow r) {
    Object? layout;
    try {
      layout = jsonDecode(r.layout);
    } on FormatException {
      layout = null;
    }
    return Dashboard(id: r.id, name: r.name, sortKey: r.sortKey, cards: Dashboard.cardsOf(layout));
  }

  SimpleSelectStatement<$DashboardsTable, DashboardRow> _base() => _db.select(_db.dashboards)
    ..where((d) => d.deletedAt.isNull() & d.userId.equals(_userId()))
    ..orderBy([(d) => OrderingTerm.asc(d.sortKey), (d) => OrderingTerm.asc(d.id)]);

  Stream<List<Dashboard>> watchAll() =>
      _base().watch().map((rows) => rows.map(map).toList()).distinct(const ListEquality<Dashboard>().equals);

  Stream<Dashboard?> watch(String id) => watchAll().map((all) => all.firstWhereOrNull((d) => d.id == id));

  /// Creates a dashboard at the end of the list; returns its id.
  Future<(String, OpRecord)> create(String name, {List<DashboardCard> cards = const []}) async {
    final last = (await _base().get()).lastOrNull;
    final id = Ids.v7();
    final record = await _writer.run(
      (tx) => tx.insert('dashboards', id, {
        'name': name.trim(),
        'sort_key': FractionalIndex.between(last?.sortKey, null),
        'layout': [for (final c in cards) c.toJson()],
      }),
    );
    return (id, record);
  }

  Future<OpRecord> rename(String id, String name) =>
      _writer.run((tx) => tx.update('dashboards', id, {'name': name.trim()}));

  Future<OpRecord> setCards(String id, List<DashboardCard> cards) => _writer.run(
    (tx) => tx.update('dashboards', id, {
      'layout': [for (final c in cards) c.toJson()],
    }),
  );

  Future<OpRecord> delete(String id) => _writer.run((tx) => tx.softDelete('dashboards', id));
}
