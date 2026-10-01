import 'dart:convert';

import 'package:everslot/core/providers.dart';
import 'package:everslot/features/planner/application/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/data/view_config/saved_views_repository.dart';
import 'package:everslot/shared/views/application/saved_views_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

/// T2.3.08: saved views of every section — versioned codecs (round-trip, upgrades, unknown keys
/// from newer versions kept), repository operations, reset to defaults, sync rows.
void main() {
  group('JsonViewCodec', () {
    final codec = JsonViewCodec(
      'checklists',
      defaultType: 'board',
      upgrades: [
        // v1 → v2: "dense" became "density".
        (json) => json['density'] = json.remove('dense') == true ? 'compact' : 'comfortable',
      ],
    );

    test('round-trips type, values and the version', () {
      final config = JsonViewConfig('table', const {
        'sort': 'title',
        'filters': {
          'tags': ['a'],
        },
      });
      final json = codec.encode(config);
      expect(json['v'], 2);
      expect(json['type'], 'table');
      expect(codec.decode(jsonDecode(jsonEncode(json)) as Map<String, Object?>), config);
    });

    test('upgrades old versions step by step', () {
      final config = codec.decode({'type': 'board', 'dense': true});
      expect(config.get<String>('density'), 'compact');
      expect(config.values.containsKey('dense'), isFalse);
    });

    test('keeps unknown keys and a newer version number when written back', () {
      final fromNewer = codec.decode({'v': 7, 'type': 'kanban', 'futureKey': 42, 'density': 'compact'});
      expect(fromNewer.get<int>('futureKey'), 42);
      final written = codec.encode(fromNewer.withValue('density', 'comfortable'));
      expect(written['v'], 7, reason: 'never downgraded');
      expect(written['futureKey'], 42);
      expect(written['density'], 'comfortable');
    });

    test('the view_type column is the fallback type', () {
      expect(codec.decode(const {}, viewType: 'table').type, 'table');
      expect(codec.decode(const {}).type, 'board');
    });
  });

  group('SavedViewsStore', () {
    late TestHarness h;
    setUp(() => h = TestHarness.create());
    tearDown(() => h.dispose());

    SavedViewsStore<JsonViewConfig> store(String section) => h.read(sectionViewsStoreProvider(section));
    final builtIns = <String, BuiltInView<JsonViewConfig>>{
      'board': (config: JsonViewConfig('board', const {'density': 'comfortable'}), name: 'Board'),
      'table': (config: JsonViewConfig('table'), name: 'Table'),
    };

    test('built-ins are seeded once with deterministic ids; the default is flagged', () async {
      final lists = store('checklists');
      await lists.ensureDefaults(builtIns, defaultEntry: 'board');
      await lists.ensureDefaults(builtIns, defaultEntry: 'board');
      final views = await lists.all();
      expect(views.map((v) => v.name), ['Board', 'Table']);
      expect(views.first.id, SavedViewsStore.builtInId('user-1', 'checklists', 'board'));
      expect((await lists.defaultView())!.name, 'Board');
      expect(await store('habits').all(), isEmpty, reason: 'sections are separate');
    });

    test('create, rename, save config, duplicate, reorder, set default, delete', () async {
      final lists = store('checklists');
      await lists.ensureDefaults(builtIns, defaultEntry: 'board');
      final id = await lists.create('  Groceries  ', JsonViewConfig('table', const {'sort': 'due'}));
      expect((await lists.byId(id))!.name, 'Groceries');
      await lists.rename(id, 'Shop');
      await lists.saveConfig(id, JsonViewConfig('board', const {'sort': 'due'}));
      final saved = (await lists.byId(id))!;
      expect(saved.viewType, 'board');
      expect(saved.config.get<String>('sort'), 'due');

      final copy = (await lists.duplicate(id, 'Shop 2'))!;
      expect((await lists.byId(copy))!.config, saved.config);

      final views = await lists.all();
      await lists.move(copy, beforeKey: views.first.sortKey);
      expect((await lists.all()).first.id, copy);

      await lists.setDefault(id);
      expect((await lists.all()).where((v) => v.isDefault).map((v) => v.id), [id]);

      await lists.delete(copy);
      expect(await lists.byId(copy), isNull);
    });

    test('rows go to the outbox (presets sync) with the encoded config', () async {
      await store('stats').create('Mine', JsonViewConfig('overview', const {'range': '30d'}));
      final rows = await h.db.select(h.db.savedViews).get();
      expect(rows.single.section, 'stats');
      expect(jsonDecode(rows.single.config), {'v': 1, 'range': '30d', 'type': 'overview'});
      final outbox = await h.db.select(h.db.syncOutbox).get();
      expect(outbox.where((e) => e.tableName_ == 'saved_views'), hasLength(1));
    });

    test('reset to defaults: own views deleted, built-ins restored, one undoable operation', () async {
      final lists = store('checklists');
      await lists.ensureDefaults(builtIns, defaultEntry: 'board');
      final board = SavedViewsStore.builtInId('user-1', 'checklists', 'board');
      final table = SavedViewsStore.builtInId('user-1', 'checklists', 'table');
      await lists.saveConfig(board, JsonViewConfig('board', const {'density': 'compact'}));
      await lists.rename(board, 'My board');
      await lists.delete(table);
      final own = await lists.create('Mine', JsonViewConfig('table'));
      await lists.setDefault(own);

      final op = await lists.resetToDefaults(builtIns, defaultEntry: 'board');
      final views = await lists.all();
      expect(views.map((v) => v.name), ['Board', 'Table']);
      expect(views.first.config, builtIns['board']!.config);
      expect(views.first.isDefault, isTrue);
      expect(await lists.byId(own), isNull);

      await h.read(syncWriterProvider).revert(op);
      final undone = await lists.all();
      expect(undone.map((v) => v.id), containsAll([board, own]));
      expect(undone.map((v) => v.id), isNot(contains(table)));
      expect(undone.firstWhere((v) => v.id == board).name, 'My board');
    });

    test('the planner keeps its typed views on the same table', () async {
      final repo = h.read(savedViewsRepositoryProvider);
      await repo.ensureDefaults({'week_table': (PlannerViewConfig.defaultsFor(PlannerViewType.weekTable), 'Week')});
      expect(repo.store.section, 'planner');
      final id = SavedViewsRepository.entryViewId('user-1', 'week_table');
      expect((await repo.byId(id))!.config.type, PlannerViewType.weekTable);
      expect(await store('checklists').all(), isEmpty);
    });
  });
}
