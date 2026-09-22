# Everslot — Developer Patterns (read before writing feature code)

This is the practical companion to `architecture.md`: how code is actually written in this repo.
The reference implementation of every pattern is the **Categories** feature
(`app/lib/features/organization/**`) — copy its shape.

## 1. Toolchain

- Flutter **3.47.5** / Dart **3.13.4** via FVM: always `fvm flutter …` / `fvm dart …`.
- Workspace root = repo root (`pubspec.yaml` with `workspace:`); run `fvm dart pub get` there.
- Analyze: `fvm dart analyze app/lib app/test` (must print `No issues found!`).
- Tests: `cd app && fvm flutter test` · pure packages: `cd packages/<pkg> && fvm dart test`.
- Code generation is used **only for Drift** and is run centrally (`cd app && fvm dart run build_runner build`).
  Generated `app_database.g.dart` is committed. Feature code must not need codegen:
  **no freezed, no json_serializable, no riverpod_generator, no go_router_builder** (ADR-016).

## 2. Layers & folders

```text
app/lib/features/<feature>/
  domain/        pure Dart: entities (immutable classes with ==/hashCode/copyWith), value objects,
                 pure services (algorithms). No Flutter/Drift/Supabase imports.
  data/          repositories: read Drift, write through SyncWriter. Map rows → domain entities.
  application/   Riverpod providers + services orchestrating repositories and engines.
  presentation/  screens/widgets. Only talk to application providers.
```

Shared code: `core/` (infrastructure), `design_system/` (tokens, components, pickers, formatting),
`app/` (router, shell), `startup/` (startup tasks).

## 3. Riverpod (v3, manual providers)

```dart
final fooRepositoryProvider = Provider<FooRepository>((ref) => FooRepository(
  ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider), () => ref.read(currentUserIdProvider)));

final foosProvider = StreamProvider<List<Foo>>((ref) {
  ref.watch(currentUserIdProvider);            // re-subscribe on account switch
  return ref.watch(fooRepositoryProvider).watchAll();
});

final fooByIdProvider = StreamProvider.family<Foo?, String>((ref, id) => …);
final fooControllerProvider = NotifierProvider<FooController, FooState>(FooController.new);
```

- Use `Provider.autoDispose` / `StreamProvider.autoDispose.family` for screen-scoped data.
- `ProviderListenable` lives in `package:flutter_riverpod/misc.dart`; `ChangeNotifierProvider` in `legacy.dart` (avoid).
- Time: `ref.read(clockProvider).nowUtc()` — never `DateTime.now()` in domain/application code.
- Zone & preferences: `deviceZoneProvider`, `userPreferencesProvider` (week start, 12/24 h, day start…).

## 4. Reading data (Drift)

```dart
(_db.select(_db.tasks)
  ..where((t) => t.deletedAt.isNull() & t.userId.equals(_userId()))
  ..orderBy([(t) => OrderingTerm.asc(t.startLocal)]))
  .watch()
  .map((rows) => rows.map(_map).toList());
```

- Always filter `deletedAt.isNull()` and `userId.equals(currentUserId)`.
- Row classes are named `XxxRow` (`TaskRow`, `ChecklistItemRow` — note its text column getter is `itemText`).
- Wall-clock columns (`*_local`, `local_date`, `start_date`…) are ISO **text**: parse with
  `LocalDateTime.parse` / `LocalDate.parse` from `package:everslot_recurrence/everslot_recurrence.dart`.
- JSON columns are text: `jsonDecode(row.recurrence!)`.
- Raw SQL is fine for aggregates: `_db.customSelect(sql, variables: [...], readsFrom: {_db.tasks})`.

## 5. Writing data — ALWAYS through `SyncWriter`

```dart
final record = await ref.read(syncWriterProvider).run((tx) async {
  final id = Ids.v7();
  await tx.insert('tasks', id, {'series_id': id, 'title': title, 'start_local': start /* LocalDateTime */});
  await tx.logEvent(entityType: 'task', entityId: id, eventType: 'created');
});
if (context.mounted) showUndoSnackBar(context, ref, message: l10n.savedSnack, record: record);
```

- Table and column names are the **server snake_case names** (arch §7.3).
- Values: `String`, `int`, `double`, `bool`, UTC `DateTime` (instants), `Map`/`List` (JSON columns),
  `LocalDateTime`/`LocalDate`/`LocalTime` (stored via `toString()` = ISO).
- `tx.update(table, id, changes)` writes only changed fields; `tx.upsert` for deterministic ids;
  `tx.softDelete` / `tx.restore`; `tx.readRaw(table, id)` inside the transaction.
- One user command = one `run` = one operation group (atomic push). Cascades go in the same `run`.
- Automatic writes (resets, auto-success…) pass `scheduledAt:` so user edits win (arch §6.6).
- Deterministic ids: `Ids.taskOccurrence`, `Ids.habitDayState`, `Ids.inbox`, `Ids.checklistRun`… (`core/ids/ids.dart`).
- Activity events: payload conventions in arch §7.3 (`from`/`to`/`note`, `rescheduled` fields…); `opId`
  and `cause` are added automatically.
- Ordering: `FractionalIndex.between(prevKey, nextKey)` (`core/ordering`).
- Undo: `showUndoSnackBar(context, ref, message:, record:)`.

## 6. UI

- Import `package:material_ui/material_ui.dart` (not `flutter/material.dart`) and
  `package:everslot/design_system/design_system.dart`.
- Strings: add keys to **your own part files** `app/lib/l10n/parts/<feature>_{en,fr,ar}.arb` (unique,
  feature-prefixed keys, e.g. `plannerSlotSize`), then from the repo root:
  `fvm dart run tool/merge_arb.dart && (cd app && fvm flutter gen-l10n)`. Use `context.l10n.key`.
  Never edit `app/lib/l10n/arb/*` (generated) or other features' parts.
- Components: `EmptyState`, `ErrorState`, `LoadingState`, `AsyncValueView`, `SectionHeader`,
  `StatusPill`, `ProgressRing`, `SegmentedBar`, `ColorDot`, `PriorityBadge`/`PrioritySelector`,
  `showAppSheet`, `confirmDialog`, `promptText`, `showUndoSnackBar`, pickers (`pickDate`, `pickTime`
  (1-min), `pickDuration`, `pickColor`, `pickIcon`), `AppFormat` (dates/times/durations/relative),
  tokens (`Space`, `Radii`, `CategoryPalette`, `CategoryColors`, `context.appColors` status colors),
  `IconCatalog`, `pickCategory(context, ref)` (organization feature).
- RTL: `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end`. Semantics labels on custom widgets.
- Routes already exist in `app/lib/app/router.dart`; builders live in `core/routing/deep_links.dart`
  (`AppLinks.task(id)`…). Placeholder screens exist with the exact class names/constructor params the
  router uses — **replace their body, keep the class name and constructor**.
- Tab root screens show `const AppBarActions()` in their AppBar.

## 7. Startup hooks

Register idempotent startup work in `app/lib/startup/startup_tasks.dart` (`startupTasks` list) — keep
each task fast or unawaited.

## 8. Tests

- `test/support/test_app.dart`: `TestHarness.create(now:, zone:)` gives an in-memory DB, local session,
  `FakeClock`; `h.read(provider)`; `pumpInApp(tester, h, widget, locale:)` for widget tests.
- Put tests under `app/test/features/<feature>/…`. Test repositories against the in-memory DB,
  pure logic with plain unit tests, key screens with widget tests (EN + AR/RTL).

## 9. Working in parallel (agents)

- Only edit files inside the areas your task assigns you. Shared files (`app/pubspec.yaml`,
  `app/lib/app/router.dart`, `core/**`, `design_system/**`, `app_database.dart`) may be changed **only**
  when unavoidable; keep such edits minimal and list them in your final report.
- New dependencies: add to `app/pubspec.yaml` only if essential, and report them.
- The Drift schema is complete (arch §7.3). Don't add tables; if a column is missing, report it.
- Commit often on your branch with conventional commits and `Refs: T…` in the body; tick finished tasks
  in the relevant `docs/tasks_section_*.md` Progress lists (add `**Notes:**` for deviations/placeholders).
