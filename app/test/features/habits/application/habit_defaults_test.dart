import 'package:drift/drift.dart' show Value;
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/features/habits/application/habit_defaults.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  late TestHarness h;
  setUp(() => h = TestHarness.create());
  tearDown(() => h.dispose());

  Future<int> opCount() async => (await h.db.select(h.db.syncOutbox).get()).length;

  test('seeds localized default sections and libraries once, with deterministic ids (T5.1.11, T5.3.14)', () async {
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(await h.read(habitDefaultsProvider).ensure(fr), isTrue);

    final sections = await h.read(habitSectionsRepositoryProvider).all();
    expect(sections.map((s) => s.id).toSet(), {for (final d in DefaultSections.all) Ids.habitSection('user-1', d.$1)});
    expect(sections.map((s) => s.name), contains(fr.habitsSectionMorning));
    final vocab = await h.read(habitVocabRepositoryProvider).all();
    expect(vocab, hasLength(28));
    expect(vocab.map((v) => v.name), containsAll([fr.quitTriggerStress, fr.quitPlaceHome, fr.quitCopingWalk]));
    // Every default has a localized name (no raw keys leak into the UI).
    expect(vocab.where((v) => v.name.contains('_')), isEmpty);

    final ops = await opCount();
    expect(await h.read(habitDefaultsProvider).ensure(fr), isTrue);
    expect(await opCount(), ops, reason: 'a second run writes nothing');
  });

  test('cloud accounts wait for their first pull before seeding', () async {
    final repo = h.read(habitSectionsRepositoryProvider);
    expect(await repo.firstPullDone(), isFalse);
    final waiting = HabitDefaults(
      sections: repo,
      vocab: h.read(habitVocabRepositoryProvider),
      canSeed: repo.firstPullDone,
    );
    expect(await waiting.ensure(lookupAppLocalizations(const Locale('en'))), isFalse);
    expect(await repo.all(), isEmpty);

    await h.db
        .into(h.db.syncState)
        .insert(SyncStateCompanion.insert(userId: 'user-1', lastPullAt: Value(DateTime.utc(2026, 9, 22, 8))));
    expect(await repo.firstPullDone(), isTrue);
    expect(await waiting.ensure(lookupAppLocalizations(const Locale('ar'))), isTrue);
    expect(
      (await repo.all()).map((s) => s.name),
      contains(lookupAppLocalizations(const Locale('ar')).habitsSectionAnytime),
    );
  });
}
